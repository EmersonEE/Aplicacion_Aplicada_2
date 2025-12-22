class Alarm {
  String? key;  // Clave única de Firebase
  String title;
  DateTime time;
  bool isEnabled;
  int grams;
  Map<String, bool> repeatDays;
  int lastTriggered = 0;

  Alarm({
    this.key,
    required this.title,
    required this.time,
    this.isEnabled = true,
    this.grams = 40,
    Map<String, bool>? repeatDays,
    this.lastTriggered = 0,
  }) : repeatDays = repeatDays ?? {
          "sun": false,
          "mon": false,
          "tue": false,
          "wed": false,
          "thu": false,
          "fri": false,
          "sat": false,
        };

  Map<String, dynamic> toJson() => {
        'title': title,
        'time': time.millisecondsSinceEpoch,
        'isEnabled': isEnabled,
        'grams': grams,
        'repeatDays': repeatDays,
        'lastTriggered': lastTriggered,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        title: json['title'] as String? ?? 'Alarma',
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
        isEnabled: json['isEnabled'] as bool? ?? true,
        grams: json['grams'] as int? ?? 40,
        repeatDays: Map<String, bool>.from(
          (json['repeatDays'] as Map<dynamic, dynamic>?)?.map(
                (k, v) => MapEntry(k.toString(), v as bool),
              ) ??
              {},
        ),
        lastTriggered: json['lastTriggered'] as int? ?? 0,
      );
}