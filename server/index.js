import crypto from 'node:crypto';
import http from 'node:http';
import express from 'express';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import {
  FieldValue,
  getFirestore,
  Timestamp,
} from 'firebase-admin/firestore';
import WebSocket, { WebSocketServer } from 'ws';

const projectId = process.env.FIREBASE_PROJECT_ID;
const geminiApiKey = process.env.GEMINI_API_KEY;
const allowedOrigins = new Set(
  (process.env.ILERA_ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
);
const quotaSeconds = 180;
const staleLeaseMs = 15_000;
if (!projectId || !geminiApiKey) {
  throw new Error('FIREBASE_PROJECT_ID and GEMINI_API_KEY are required.');
}

const firebaseApp = initializeApp({ projectId });
const auth = getAuth(firebaseApp);
const firestore = getFirestore(firebaseApp);
const usageRef = firestore.doc('iaUsage/global');
const lockRef = firestore.doc('iaUsageLocks/global');
const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({
  noServer: true,
  maxPayload: 2 * 1024 * 1024,
  handleProtocols(protocols) {
    return protocols.has('ilera-live-v1') ? 'ilera-live-v1' : false;
  },
});

app.disable('x-powered-by');
app.use(express.json({ limit: '64kb' }));

app.use((req, res, next) => {
  const origin = req.get('origin');
  if (origin && !allowedOrigins.has(origin)) {
    return res.status(403).json({ error: 'Origin is not allowed.' });
  }
  if (origin) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  }
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  return next();
});

async function verifyBearerToken(header) {
  const match = /^Bearer (.+)$/.exec(header ?? '');
  if (!match) {
    const error = new Error('Authentication is required.');
    error.statusCode = 401;
    throw error;
  }
  try {
    return await auth.verifyIdToken(match[1]);
  } catch {
    const error = new Error('Authentication token is invalid or expired.');
    error.statusCode = 401;
    throw error;
  }
}

async function requireUser(req, res, next) {
  try {
    req.user = await verifyBearerToken(req.get('authorization'));
    return next();
  } catch (error) {
    return res.status(error.statusCode ?? 401).json({ error: error.message });
  }
}

function timestampMillis(value) {
  return value?.toMillis?.() ?? 0;
}

function quotaError(message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

async function usageSnapshot() {
  const snapshot = await usageRef.get();
  const data = snapshot.data() ?? {};
  const usedSeconds = Math.min(
    quotaSeconds,
    Math.max(0, Math.floor(data.usedSeconds ?? 0)),
  );
  return {
    usedSeconds,
    limitSeconds: quotaSeconds,
    remainingSeconds: quotaSeconds - usedSeconds,
    updatedAt: data.updatedAt?.toDate?.().toISOString() ?? null,
  };
}

async function reserveGlobalSession(sessionId) {
  const remainingSeconds = await firestore.runTransaction(async (transaction) => {
    const [usageSnapshotInTransaction, lockSnapshot] = await Promise.all([
      transaction.get(usageRef),
      transaction.get(lockRef),
    ]);
    let usedSeconds = Math.min(
      quotaSeconds,
      Math.max(0, Math.floor(usageSnapshotInTransaction.get('usedSeconds') ?? 0)),
    );
    const now = Date.now();
    const activeSessionId = lockSnapshot.get('activeSessionId');

    if (activeSessionId) {
      const heartbeatAt = timestampMillis(lockSnapshot.get('activeHeartbeatAt'));
      if (now - heartbeatAt <= staleLeaseMs) {
        throw quotaError('Another Ilera user is using the shared AI time.', 409);
      }

      const startedAt = timestampMillis(lockSnapshot.get('activeStartedAt'));
      const alreadyCharged = Math.max(
        0,
        Math.floor(lockSnapshot.get('activeChargedSeconds') ?? 0),
      );
      const elapsed = Math.max(0, Math.floor((now - startedAt) / 1000));
      usedSeconds = Math.min(
        quotaSeconds,
        usedSeconds + Math.max(0, elapsed - alreadyCharged),
      );
    }

    const remainingSeconds = quotaSeconds - usedSeconds;
    if (remainingSeconds <= 0) {
      transaction.set(
        usageRef,
        {
          usedSeconds: quotaSeconds,
          limitSeconds: quotaSeconds,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      transaction.delete(lockRef);
      return 0;
    }

    const startedAt = Timestamp.fromMillis(now);
    transaction.set(
      usageRef,
      {
        usedSeconds,
        limitSeconds: quotaSeconds,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.set(lockRef, {
      activeSessionId: sessionId,
      activeStartedAt: startedAt,
      activeHeartbeatAt: startedAt,
      activeChargedSeconds: 0,
    });
    return remainingSeconds;
  });
  if (remainingSeconds <= 0) {
    throw quotaError('The shared 3-minute Gemini allowance has been used.', 429);
  }
  return remainingSeconds;
}

async function heartbeatGlobalSession(sessionId) {
  return firestore.runTransaction(async (transaction) => {
    const [usageSnapshotInTransaction, lockSnapshot] = await Promise.all([
      transaction.get(usageRef),
      transaction.get(lockRef),
    ]);
    if (lockSnapshot.get('activeSessionId') !== sessionId) {
      return { active: false, remainingSeconds: 0 };
    }

    const usedSeconds = Math.min(
      quotaSeconds,
      Math.max(0, Math.floor(usageSnapshotInTransaction.get('usedSeconds') ?? 0)),
    );
    const startedAt = timestampMillis(lockSnapshot.get('activeStartedAt'));
    const elapsedSeconds = Math.max(
      0,
      Math.floor((Date.now() - startedAt) / 1000),
    );
    const chargedSeconds = Math.max(
      0,
      Math.floor(lockSnapshot.get('activeChargedSeconds') ?? 0),
    );
    const nextUsedSeconds = Math.min(
      quotaSeconds,
      usedSeconds + Math.max(0, elapsedSeconds - chargedSeconds),
    );
    const now = Timestamp.now();
    const remainingSeconds = quotaSeconds - nextUsedSeconds;

    transaction.set(
      usageRef,
      {
        usedSeconds: nextUsedSeconds,
        limitSeconds: quotaSeconds,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    if (remainingSeconds === 0) {
      transaction.delete(lockRef);
    } else {
      transaction.set(
        lockRef,
        {
          activeChargedSeconds: elapsedSeconds,
          activeHeartbeatAt: now,
        },
        { merge: true },
      );
    }
    return { active: remainingSeconds > 0, remainingSeconds };
  });
}

async function releaseGlobalSession(sessionId) {
  return firestore.runTransaction(async (transaction) => {
    const [usageSnapshotInTransaction, lockSnapshot] = await Promise.all([
      transaction.get(usageRef),
      transaction.get(lockRef),
    ]);
    if (lockSnapshot.get('activeSessionId') !== sessionId) return;

    const usedSeconds = Math.min(
      quotaSeconds,
      Math.max(0, Math.floor(usageSnapshotInTransaction.get('usedSeconds') ?? 0)),
    );
    const startedAt = timestampMillis(lockSnapshot.get('activeStartedAt'));
    const elapsedSeconds = Math.max(
      0,
      Math.floor((Date.now() - startedAt) / 1000),
    );
    const chargedSeconds = Math.max(
      0,
      Math.floor(lockSnapshot.get('activeChargedSeconds') ?? 0),
    );
    transaction.set(
      usageRef,
      {
        usedSeconds: Math.min(
          quotaSeconds,
          usedSeconds + Math.max(0, elapsedSeconds - chargedSeconds),
        ),
        limitSeconds: quotaSeconds,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.delete(lockRef);
  });
}

function startAccounting(sessionId, onQuotaExhausted) {
  let heartbeatInFlight = false;
  const timer = setInterval(async () => {
    if (heartbeatInFlight) return;
    heartbeatInFlight = true;
    try {
      const result = await heartbeatGlobalSession(sessionId);
      if (!result.active) onQuotaExhausted();
    } catch (error) {
      console.error('Could not update the Gemini usage quota:', error);
      onQuotaExhausted();
    } finally {
      heartbeatInFlight = false;
    }
  }, 1000);
  timer.unref();
  return () => clearInterval(timer);
}

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.get('/usage', requireUser, async (_req, res) => {
  try {
    return res.json(await usageSnapshot());
  } catch (error) {
    console.error('Could not read the Gemini usage quota:', error);
    return res.status(503).json({ error: 'Usage information is unavailable.' });
  }
});

app.post('/generate', requireUser, async (req, res) => {
  const { systemPrompt, contents } = req.body ?? {};
  if (
    typeof systemPrompt !== 'string' ||
    systemPrompt.length === 0 ||
    systemPrompt.length > 24_000 ||
    !Array.isArray(contents) ||
    contents.length === 0 ||
    contents.length > 40 ||
    contents.some(
      (item) =>
        !item ||
        !['user', 'model'].includes(item.role) ||
        !Array.isArray(item.parts) ||
        item.parts.length === 0 ||
        item.parts.some(
          (part) => typeof part?.text !== 'string' || part.text.length > 8_000,
        ),
    )
  ) {
    return res.status(400).json({ error: 'Invalid Gemini request.' });
  }

  const sessionId = crypto.randomUUID();
  let stopAccounting = () => {};
  const controller = new AbortController();
  try {
    const remainingSeconds = await reserveGlobalSession(sessionId);
    stopAccounting = startAccounting(sessionId, () => controller.abort());
    const upstream = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': geminiApiKey,
        },
        body: JSON.stringify({
          system_instruction: {
            parts: [{ text: systemPrompt }],
          },
          contents,
          generationConfig: { maxOutputTokens: 512 },
        }),
        signal: AbortSignal.any([
          controller.signal,
          AbortSignal.timeout(remainingSeconds * 1000),
        ]),
      },
    );
    const body = await upstream.text();
    res.status(upstream.status).type('application/json').send(body);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ error: error.message });
    }
    if (controller.signal.aborted) {
      return res.status(429).json({
        error: 'The shared 3-minute Gemini allowance has been used.',
      });
    }
    console.error('Gemini text request failed:', error);
    return res.status(502).json({ error: 'Gemini could not complete the request.' });
  } finally {
    stopAccounting();
    try {
      await releaseGlobalSession(sessionId);
    } catch (error) {
      console.error('Could not finalize the Gemini usage quota:', error);
    }
  }
});

function rejectUpgrade(socket, statusCode, message) {
  if (socket.destroyed) return;
  const statusText =
    statusCode === 401 ? 'Unauthorized' :
    statusCode === 403 ? 'Forbidden' :
    statusCode === 409 ? 'Conflict' :
    statusCode === 429 ? 'Too Many Requests' :
    'Bad Request';
  socket.end(
    `HTTP/1.1 ${statusCode} ${statusText}\r\n` +
      'Connection: close\r\n' +
      'Content-Type: text/plain\r\n' +
      `Content-Length: ${Buffer.byteLength(message)}\r\n\r\n${message}`,
  );
}

async function connectToGeminiLive() {
  const url =
    'wss://generativelanguage.googleapis.com/ws/' +
    'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent' +
    `?key=${encodeURIComponent(geminiApiKey)}`;
  const upstream = new WebSocket(url, { perMessageDeflate: false });
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(
      () => reject(new Error('Timed out connecting to Gemini Live.')),
      15_000,
    );
    upstream.once('open', () => {
      clearTimeout(timeout);
      resolve();
    });
    upstream.once('error', (error) => {
      clearTimeout(timeout);
      reject(error);
    });
  });
  return upstream;
}

server.on('upgrade', async (request, socket, head) => {
  let sessionId;
  let upstream;
  try {
    const origin = request.headers.origin;
    if (origin && !allowedOrigins.has(origin)) {
      return rejectUpgrade(socket, 403, 'Origin is not allowed.');
    }

    const protocols = new Set(
      (request.headers['sec-websocket-protocol'] ?? '')
        .split(',')
        .map((protocol) => protocol.trim()),
    );
    const tokenProtocol = [...protocols].find((protocol) =>
      protocol.startsWith('firebase-auth.'),
    );
    if (!protocols.has('ilera-live-v1') || !tokenProtocol) {
      return rejectUpgrade(socket, 401, 'Firebase authentication is required.');
    }
    const idToken = tokenProtocol.slice('firebase-auth.'.length);
    try {
      await auth.verifyIdToken(idToken);
    } catch {
      return rejectUpgrade(socket, 401, 'Firebase authentication is invalid.');
    }

    sessionId = crypto.randomUUID();
    await reserveGlobalSession(sessionId);
    upstream = await connectToGeminiLive();

    wss.handleUpgrade(request, socket, head, (client) => {
      let closed = false;
      const stopAccounting = startAccounting(sessionId, () => {
        client.close(1008, 'Shared Gemini time exhausted.');
        upstream.close(1008, 'Shared Gemini time exhausted.');
      });

      const closeBoth = async (code, reason) => {
        if (closed) return;
        closed = true;
        stopAccounting();
        if (upstream.readyState === WebSocket.OPEN) {
          upstream.close(code, reason.toString().slice(0, 120));
        } else if (upstream.readyState === WebSocket.CONNECTING) {
          upstream.terminate();
        }
        try {
          await releaseGlobalSession(sessionId);
        } catch (error) {
          console.error('Could not finalize the Gemini usage quota:', error);
        }
      };

      client.on('message', (data, isBinary) => {
        if (upstream.readyState === WebSocket.OPEN) {
          upstream.send(data, { binary: isBinary });
        }
      });
      upstream.on('message', (data, isBinary) => {
        if (client.readyState === WebSocket.OPEN) {
          client.send(data, { binary: isBinary });
        }
      });
      client.on('close', (code, reason) => {
        void closeBoth(code, reason);
      });
      upstream.on('close', (code, reason) => {
        if (client.readyState === WebSocket.OPEN) client.close(code, reason);
        void closeBoth(code, reason);
      });
      client.on('error', (error) => {
        console.error('Gemini client WebSocket error:', error.message);
        void closeBoth(1011, 'Connection error.');
      });
      upstream.on('error', (error) => {
        console.error('Gemini upstream WebSocket error:', error.message);
        if (client.readyState === WebSocket.OPEN) {
          client.close(1011, 'Gemini connection error.');
        }
        void closeBoth(1011, 'Gemini connection error.');
      });
    });
  } catch (error) {
    if (upstream && upstream.readyState !== WebSocket.CLOSED) upstream.terminate();
    if (sessionId) {
      try {
        await releaseGlobalSession(sessionId);
      } catch (releaseError) {
        console.error('Could not release a failed Gemini session:', releaseError);
      }
    }
    if (error.statusCode) {
      return rejectUpgrade(socket, error.statusCode, error.message);
    }
    console.error('Could not start Gemini Live:', error);
    return rejectUpgrade(socket, 502, 'Gemini Live is unavailable.');
  }
});

const port = Number(process.env.PORT ?? 8080);

async function startServer() {
  await firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(usageRef);
    if (snapshot.exists) return;
    transaction.create(usageRef, {
      usedSeconds: 0,
      limitSeconds: quotaSeconds,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  server.listen(port, '0.0.0.0', () => {
    console.log(`Ilera Gemini proxy listening on port ${port}.`);
  });
}

startServer().catch((error) => {
  console.error('Could not initialize the Gemini proxy:', error);
  process.exitCode = 1;
});
