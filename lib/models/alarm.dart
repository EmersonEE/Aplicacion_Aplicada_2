class Alarm {
  final int id;
  String title;
  DateTime time;
  bool isEnabled;
  List<int> repeatDays; // 0 = Domingo, 1 = Lunes, ..., 6 = Sábado. [] = sin repetición

  Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.isEnabled = true,
    List<int>? repeatDays,
  }) : repeatDays = repeatDays ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time.millisecondsSinceEpoch,
        'isEnabled': isEnabled,
        'repeatDays': repeatDays,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as int,
        title: json['title'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
        isEnabled: json['isEnabled'] as bool? ?? true,
        repeatDays: (json['repeatDays'] as List<dynamic>?)?.cast<int>() ?? [],
      );
}