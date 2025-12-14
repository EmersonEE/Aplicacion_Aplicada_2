class Alarm {
  final int id;
  String title;
  DateTime time;
  bool isEnabled;
  int portions;  // ← Debe estar aquí

  Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.isEnabled = true,
    this.portions = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time.millisecondsSinceEpoch,
        'isEnabled': isEnabled,
        'portions': portions,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as int,
        title: json['title'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
        isEnabled: json['isEnabled'] as bool? ?? true,
        portions: json['portions'] as int? ?? 1,
      );
}