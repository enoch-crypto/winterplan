class ScheduleItem {
  String id;
  String timeRange;
  String title;
  String content;
  String icon;
  String tag;

  ScheduleItem({
    required this.id,
    required this.timeRange,
    required this.title,
    required this.content,
    required this.icon,
    required this.tag,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timeRange': timeRange,
        'title': title,
        'content': content,
        'icon': icon,
        'tag': tag,
      };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        id: json['id'],
        timeRange: json['timeRange'],
        title: json['title'],
        content: json['content'],
        icon: json['icon'],
        tag: json['tag'],
      );

  DateTime? getStartTime(DateTime now) {
    try {
      final startStr = timeRange.split("-")[0].trim();
      final parts = startStr.split(":");
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? getEndTime(DateTime now) {
    try {
      final endStr = timeRange.split("-")[1].trim();
      final parts = endStr.split(":");
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }
}

class HomeworkItem {
  String id;
  String content;
  bool isDone;

  HomeworkItem({
    required this.id,
    required this.content,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isDone': isDone,
      };

  factory HomeworkItem.fromJson(Map<String, dynamic> json) => HomeworkItem(
        id: json['id'],
        content: json['content'],
        isDone: json['isDone'],
      );
}

class TodoItem {
  String id;
  String content;
  bool isDone;
  String createdAt;

  TodoItem({
    required this.id,
    required this.content,
    this.isDone = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isDone': isDone,
        'createdAt': createdAt,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'],
        content: json['content'],
        isDone: json['isDone'] ?? false,
        createdAt: json['createdAt'] ?? '',
      );
}

class SubjectHomework {
  String subject;
  String icon;
  List<HomeworkItem> items;

  SubjectHomework({
    required this.subject,
    required this.icon,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'icon': icon,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory SubjectHomework.fromJson(Map<String, dynamic> json) =>
      SubjectHomework(
        subject: json['subject'],
        icon: json['icon'],
        items: (json['items'] as List)
            .map((i) => HomeworkItem.fromJson(i))
            .toList(),
      );

  double get progress =>
      items.isEmpty ? 0.0 : items.where((i) => i.isDone).length / items.length;
}

class DailyLog {
  String date;
  double score;
  int minutes;
  double completionRate;
  double avgQuality;

  DailyLog({
    required this.date,
    required this.score,
    required this.minutes,
    required this.completionRate,
    required this.avgQuality,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'score': score,
        'minutes': minutes,
        'completionRate': completionRate,
        'avgQuality': avgQuality,
      };

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
        date: json['date'],
        score: (json['score'] as num).toDouble(),
        minutes: json['minutes'],
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        avgQuality: (json['avgQuality'] as num?)?.toDouble() ?? 0.0,
      );
}
