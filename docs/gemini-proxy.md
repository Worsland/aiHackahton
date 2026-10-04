# Configuration sécurisée du proxy Gemini

L'application Flutter ne reçoit jamais la clé Gemini. Les requêtes texte et
Live passent par `server/`, un service Cloud Run qui vérifie le jeton Firebase
Authentication, conserve le secret côté serveur et consomme un quota partagé
de 180 secondes. Une seule session IA peut être active à la fois. Le temps
connecté est enregistré dans Firestore chaque seconde ; le quota n'est pas
réinitialisé automatiquement.

## Avant le déploiement

1. Créer une clé API dédiée dans Google Cloud et la restreindre au service
   `generativelanguage.googleapis.com`. La clé Gemini ne doit jamais être
   incluse dans les assets Flutter, même si le fichier source est ignoré par
   Git. Si une ancienne clé a déjà été publiée, la révoquer dans son projet
   d'origine.
2. Dans Firebase Authentication, activer le fournisseur **Anonyme**.
3. Vérifier que Cloud Firestore est créé dans le projet `aihackaton-5120f`.
4. Dans Google Cloud Console, activer la facturation et les API Cloud Run,
   Cloud Build, Artifact Registry, Secret Manager et Cloud Firestore.
5. Créer un secret Secret Manager nommé `gemini-api-key` et ajouter la clé
   comme version du secret. Ne pas l'ajouter au dépôt, à Firestore ni aux
   assets Flutter.

## Droits Firestore

Le service Cloud Run utilise son compte de service pour accéder à Firestore
via Firebase Admin. Les clients peuvent lire le document d'affichage du quota,
mais ne doivent pouvoir modifier ni le quota ni son verrou. Ajouter ces
matches aux règles Firestore existantes, puis vérifier qu'aucune règle
générique plus large ne donne aux clients l'autorisation d'écrire dans ces
chemins :

```javascript
match /iaUsage/{document} {
  allow read: if request.auth != null && document == "global";
  allow write: if false;
}

match /iaUsageLocks/{document} {
  allow read, write: if false;
}
```

Le service crée et met à jour automatiquement :

- `iaUsage/global` : `usedSeconds` (0 à 180), `limitSeconds` (180) et
  `updatedAt`.
- `iaUsageLocks/global` : verrou privé utilisé pour empêcher les sessions
  simultanées et compter le temps côté serveur.

Les règles Firestore sont additives : un `allow write: if false` ne neutralise
pas un autre match qui accorde déjà l'écriture. Examiner et corriger toute
autorisation plus générale avant la mise en production.

## Déployer le proxy

Depuis PowerShell à la racine du dépôt, sélectionner le projet et créer un
compte de service dédié :

```powershell
gcloud config set project aihackaton-5120f
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com firestore.googleapis.com
gcloud iam service-accounts create ilera-ai-proxy
gcloud projects add-iam-policy-binding aihackaton-5120f --member="serviceAccount:ilera-ai-proxy@aihackaton-5120f.iam.gserviceaccount.com" --role="roles/datastore.user"
gcloud secrets add-iam-policy-binding gemini-api-key --member="serviceAccount:ilera-ai-proxy@aihackaton-5120f.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
```

Déployer le service. L'origine Firebase Hosting par défaut est autorisée ; si
vous utilisez un domaine personnalisé, l'ajouter à
`ILERA_ALLOWED_ORIGINS` :

```powershell
gcloud run deploy ilera-ai-proxy --source server --region europe-west1 --allow-unauthenticated --service-account ilera-ai-proxy@aihackaton-5120f.iam.gserviceaccount.com --set-secrets "GEMINI_API_KEY=gemini-api-key:latest" --set-env-vars "^~^FIREBASE_PROJECT_ID=aihackaton-5120f~ILERA_ALLOWED_ORIGINS=https://aihackaton-5120f.web.app,https://aihackaton-5120f.firebaseapp.com" --timeout 240s
```

`--allow-unauthenticated` permet l'établissement de la connexion HTTPS/WSS ;
les routes Gemini refusent tout de même les requêtes sans jeton Firebase valide.
Copier l'URL HTTPS affichée par Cloud Run.

## Construire et publier le site

Depuis la racine du dépôt, remplacer l'URL d'exemple par l'URL Cloud Run
obtenue à l'étape précédente :

```powershell
flutter build web --release --dart-define=ILERA_AI_BACKEND_URL=https://ilera-ai-proxy-1067764995266.europe-west1.run.app
firebase deploy --only hosting --project aihackaton-5120f
```

La compilation doit être refaite avec cette URL à chaque changement de
backend. Une compilation sans `ILERA_AI_BACKEND_URL` conserve la pratique
hors ligne mais ne permet pas les conversations Gemini.

## Quota global

Le compteur `iaUsage/global.usedSeconds` avance côté serveur pendant les
connexions Live et le temps de traitement des appels texte. Lorsqu'il atteint 180 secondes, le proxy
refuse les nouvelles requêtes de tous les visiteurs. Il n'y a pas de remise à
zéro automatique ; un administrateur peut réinitialiser `usedSeconds` à `0`
dans la console Firestore une fois toute session terminée. Les clients ne
doivent jamais recevoir un droit d'écriture sur ce document.
