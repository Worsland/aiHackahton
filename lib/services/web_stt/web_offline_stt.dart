/// Reconnaissance vocale hors ligne pour le navigateur.
///
/// Sur Android/iOS, `speech_to_text` avec `onDevice: true` suffit. Sur le
/// web, il n'expose pas l'API locale de Chrome : ce pont la rappelle
/// directement. Import conditionnel : sur mobile, c'est une version vide.
export 'web_offline_stt_types.dart';
export 'web_offline_stt_stub.dart'
    if (dart.library.js_interop) 'web_offline_stt_web.dart';
