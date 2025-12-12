class Alarm {
  final int id;
  final String title;
  final DateTime time;
  bool isEnabled;

  Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time.millisecondsSinceEpoch,
        'isEnabled': isEnabled,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as int,
        title: json['title'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
        isEnabled: json['isEnabled'] as bool? ?? true,
      );
}