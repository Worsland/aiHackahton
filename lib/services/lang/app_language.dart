enum AppLanguage {
  english,
  yoruba;

  String get label => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.yoruba => 'Yorùbá',
  };

  bool get isYoruba => this == AppLanguage.yoruba;
}
