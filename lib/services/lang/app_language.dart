enum AppLanguage {
  english,
  yoruba;

  String get speechLocaleId => switch (this) {
    AppLanguage.english => 'en_US',
    AppLanguage.yoruba => 'yo_NG',
  };

  String get label => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.yoruba => 'Yorùbá',
  };

  bool get isYoruba => this == AppLanguage.yoruba;
}
