import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/services/lang/app_language.dart';
import '../lib/services/lang/app_language_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selected language is persisted and restored on next app launch',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = AppLanguageController.instance;

      await controller.load();
      expect(controller.language, AppLanguage.english);

      await controller.setLanguage(AppLanguage.yoruba);
      expect(controller.language, AppLanguage.yoruba);

      await controller.load();
      expect(controller.language, AppLanguage.yoruba);
    },
  );
}
