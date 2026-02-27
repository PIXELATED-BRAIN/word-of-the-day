class DailyWord {
  final String word;
  final String pronunciation;
  final String translation;
  final String example;
  final String category;

  DailyWord({
    required this.word,
    required this.pronunciation,
    required this.translation,
    required this.example,
    this.category = 'General',
  });
}
