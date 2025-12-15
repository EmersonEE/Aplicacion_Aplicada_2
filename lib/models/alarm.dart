class Alarm {
  final int id;
  String title;
  DateTime time;
  bool isEnabled;
  int grams;
  List<int> repeatDays;  // ← NUEVO: 0=Dom, 1=Lun, ..., 6=Sab. [] = sin repetición

  Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.isEnabled = true,
    this.grams = 40,
    List<int>? repeatDays,
  }) : repeatDays = repeatDays ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time.millisecondsSinceEpoch,
        'isEnabled': isEnabled,
        'grams': grams,
        'repeatDays': repeatDays,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as int,
        title: json['title'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
        isEnabled: json['isEnabled'] as bool? ?? true,
        grams: json['grams'] as int? ?? 40,
        repeatDays: (json['repeatDays'] as List<dynamic>?)?.cast<int>() ?? [],
      );
}