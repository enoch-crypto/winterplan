import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'models/study_models.dart';
import 'services/storage_service.dart';

// ==========================================
// 1. 数据模型 (Models)
// ==========================================
// 数据模型已拆分到 models/study_models.dart。

// ==========================================
// 2. 状态管理 (Provider)
// ==========================================

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<ScheduleItem> _schedule = [];
  List<SubjectHomework> _homeworks = [];
  List<DailyLog> _logs = [];
  List<TodoItem> _todos = [];
  List<CalendarEvent> _events = [];
  List<FavoritePersona> _favoritePersonas = [];

  List<String> _undoStack = [];
  List<String> _redoStack = [];

  List<ScheduleItem> get schedule => _schedule;
  List<SubjectHomework> get homeworks => _homeworks;
  List<DailyLog> get logs => _logs;
  List<TodoItem> get todos => _todos;
  List<CalendarEvent> get events => _events;
  List<FavoritePersona> get favoritePersonas => _favoritePersonas;

  int get pendingTodoCount => _todos.where((todo) => !todo.isDone).length;
  int get completedTodoCount => _todos.where((todo) => todo.isDone).length;

  List<CalendarEvent> eventsForDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return _events.where((event) => event.date == key).toList();
  }

  bool isPersonaFavorited(String personaId) =>
      _favoritePersonas.any((item) => item.personaId == personaId);

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  AppState() {
    _init();
  }

  void _init() async {
    final savedSchedule = await _storage.read(StorageService.scheduleKey);
    if (savedSchedule != null) {
      Iterable l = json.decode(savedSchedule);
      _schedule =
          List<ScheduleItem>.from(l.map((x) => ScheduleItem.fromJson(x)));
    } else {
      _schedule = [
        ScheduleItem(
            id: '1',
            timeRange: "08:30 - 09:00",
            title: "起床整理",
            content: "洗漱、早餐、准备今天",
            icon: "☀️",
            tag: ""),
        ScheduleItem(
            id: '2',
            timeRange: "09:00 - 11:00",
            title: "上午专注",
            content: "学习、工作或重要任务",
            icon: "🧠",
            tag: ""),
        ScheduleItem(
            id: '3',
            timeRange: "11:00 - 12:00",
            title: "整理复盘",
            content: "记录进度、处理消息",
            icon: "📝",
            tag: ""),
        ScheduleItem(
            id: '4',
            timeRange: "12:00 - 13:00",
            title: "午餐休息",
            content: "吃饭、放松",
            icon: "🍲",
            tag: ""),
        ScheduleItem(
            id: '5',
            timeRange: "13:00 - 14:00",
            title: "午休充电",
            content: "短休息、恢复精力",
            icon: "🔋",
            tag: ""),
        ScheduleItem(
            id: '6',
            timeRange: "14:00 - 17:00",
            title: "下午任务",
            content: "推进当天主要事项",
            icon: "📌",
            tag: ""),
        ScheduleItem(
            id: '7',
            timeRange: "17:00 - 18:30",
            title: "运动放松",
            content: "散步、运动或户外活动",
            icon: "🏃",
            tag: ""),
        ScheduleItem(
            id: '8',
            timeRange: "18:30 - 19:30",
            title: "晚餐",
            content: "吃饭、休息、聊天",
            icon: "🍽️",
            tag: ""),
        ScheduleItem(
            id: '9',
            timeRange: "19:30 - 21:00",
            title: "晚间复盘",
            content: "整理、阅读、打卡",
            icon: "🌙",
            tag: ""),
        ScheduleItem(
            id: '10',
            timeRange: "21:00 - 22:00",
            title: "睡前准备",
            content: "洗漱、收尾、准备睡觉",
            icon: "🛏️",
            tag: ""),
      ];
    }

    final savedHomework = await _storage.read(StorageService.homeworkKey);
    if (savedHomework != null) {
      Iterable l = json.decode(savedHomework);
      _homeworks =
          List<SubjectHomework>.from(l.map((x) => SubjectHomework.fromJson(x)));
    } else {
      _homeworks = [
        SubjectHomework(subject: "健康", icon: "🏃", items: [
          HomeworkItem(id: 'health1', content: "运动 30 分钟"),
          HomeworkItem(id: 'health2', content: "喝水 6 杯"),
          HomeworkItem(id: 'health3', content: "按时睡觉"),
        ]),
        SubjectHomework(subject: "学习/工作", icon: "🧠", items: [
          HomeworkItem(id: 'focus1', content: "完成一个重要任务"),
          HomeworkItem(id: 'focus2', content: "复盘今天进度"),
        ]),
        SubjectHomework(subject: "生活", icon: "🏠", items: [
          HomeworkItem(id: 'life1', content: "整理房间或桌面"),
          HomeworkItem(id: 'life2', content: "准备明天要用的东西"),
        ]),
        SubjectHomework(subject: "兴趣", icon: "🎧", items: [
          HomeworkItem(id: 'fun1', content: "阅读、音乐或放松 20 分钟"),
          HomeworkItem(id: 'fun2', content: "记录一个今天的小收获"),
        ]),
      ];
    }

    final savedLogs = await _storage.read(StorageService.logsKey);
    if (savedLogs != null) {
      Iterable l = json.decode(savedLogs);
      _logs = List<DailyLog>.from(l.map((x) => DailyLog.fromJson(x)));
    }

    final savedTodos = await _storage.read(StorageService.todosKey);
    if (savedTodos != null) {
      Iterable l = json.decode(savedTodos);
      _todos = List<TodoItem>.from(l.map((x) => TodoItem.fromJson(x)));
    }

    final savedEvents = await _storage.read(StorageService.eventsKey);
    if (savedEvents != null) {
      Iterable l = json.decode(savedEvents);
      _events =
          List<CalendarEvent>.from(l.map((x) => CalendarEvent.fromJson(x)));
    }

    final savedFavoritePersonas =
        await _storage.read(StorageService.favoritePersonasKey);
    if (savedFavoritePersonas != null) {
      Iterable l = json.decode(savedFavoritePersonas);
      _favoritePersonas =
          List<FavoritePersona>.from(l.map((x) => FavoritePersona.fromJson(x)));
    }
    notifyListeners();
  }

  void _saveSnapshot() {
    String snapshot = json.encode({
      'schedule': json.encode(_schedule),
      'homeworks': json.encode(_homeworks),
      'logs': json.encode(_logs),
      'todos': json.encode(_todos),
      'events': json.encode(_events),
      'favoritePersonas': json.encode(_favoritePersonas)
    });
    _undoStack.add(snapshot);
    if (_undoStack.length > 20) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  Future<void> _persist() async {
    await _storage.write(StorageService.scheduleKey, json.encode(_schedule));
    await _storage.write(StorageService.homeworkKey, json.encode(_homeworks));
    await _storage.write(StorageService.logsKey, json.encode(_logs));
    await _storage.write(StorageService.todosKey, json.encode(_todos));
    await _storage.write(StorageService.eventsKey, json.encode(_events));
    await _storage.write(
        StorageService.favoritePersonasKey, json.encode(_favoritePersonas));
    notifyListeners();
  }

  // --- Actions ---
  void toggleHomeworkItem(String subject, String itemId) {
    _saveSnapshot();
    var subj = _homeworks.firstWhere((s) => s.subject == subject);
    var item = subj.items.firstWhere((i) => i.id == itemId);
    item.isDone = !item.isDone;
    _persist();
  }

  // 核心打分逻辑 334
  void submitLog(int minutes, double percent, double stars) {
    _saveSnapshot();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. 时长得分 (满分30分，基准360分钟)
    double timeScore = (minutes / 360.0) * 30;
    if (timeScore > 30) timeScore = 30 + (timeScore - 30) * 0.5; // 超出部分稍微加分

    // 2. 进度得分 (满分40分，基准100%)
    double progressScore = (percent / 100.0) * 40;

    // 3. 质量得分 (满分30分，基准5星)
    double qualityScore = (stars / 5.0) * 30;

    double totalScore = timeScore + progressScore + qualityScore;
    if (totalScore > 100) totalScore = 100; // 封顶100

    int idx = _logs.indexWhere((l) => l.date == today);
    if (idx != -1) {
      _logs[idx].minutes += minutes;
      _logs[idx].score = (_logs[idx].score + totalScore) / 2;
      _logs[idx].completionRate = (_logs[idx].completionRate + percent) / 2;
      _logs[idx].avgQuality = (_logs[idx].avgQuality + stars) / 2;
    } else {
      _logs.add(DailyLog(
          date: today,
          score: totalScore,
          minutes: minutes,
          completionRate: percent,
          avgQuality: stars));
    }
    _persist();
  }

  void updateSchedule(List<ScheduleItem> newSchedule) {
    _saveSnapshot();
    _schedule = newSchedule;
    _persist();
  }

  void addTodoItem(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    _saveSnapshot();
    _todos.insert(
      0,
      TodoItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: trimmed,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    _persist();
  }

  void toggleTodoItem(String itemId) {
    _saveSnapshot();
    final item = _todos.firstWhere((todo) => todo.id == itemId);
    item.isDone = !item.isDone;
    _persist();
  }

  void deleteTodoItem(String itemId) {
    _saveSnapshot();
    _todos.removeWhere((todo) => todo.id == itemId);
    _persist();
  }

  void clearCompletedTodos() {
    if (_todos.every((todo) => !todo.isDone)) return;
    _saveSnapshot();
    _todos.removeWhere((todo) => todo.isDone);
    _persist();
  }

  void addCalendarEvent(DateTime date, String title, String note) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;
    _saveSnapshot();
    _events.add(CalendarEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(date),
      title: trimmedTitle,
      note: note.trim(),
    ));
    _events.sort((a, b) => a.date.compareTo(b.date));
    _persist();
  }

  void deleteCalendarEvent(String eventId) {
    _saveSnapshot();
    _events.removeWhere((event) => event.id == eventId);
    _persist();
  }

  void toggleFavoritePersona(String personaId, String title, String note) {
    _saveSnapshot();
    final existing =
        _favoritePersonas.indexWhere((item) => item.personaId == personaId);
    if (existing >= 0) {
      _favoritePersonas.removeAt(existing);
    } else {
      _favoritePersonas.add(FavoritePersona(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        personaId: personaId,
        title: title,
        note: note,
      ));
    }
    _persist();
  }

  void deleteScheduleItem(String itemId) {
    _saveSnapshot();
    _schedule.removeWhere((item) => item.id == itemId);
    _persist();
  }

  void addHomeworkItem(String subject, String content) {
    _saveSnapshot();
    var subj = _homeworks.firstWhere((s) => s.subject == subject);
    subj.items
        .add(HomeworkItem(id: DateTime.now().toString(), content: content));
    _persist();
  }

  void deleteHomeworkItem(String subject, String itemId) {
    _saveSnapshot();
    var subj = _homeworks.firstWhere((s) => s.subject == subject);
    subj.items.removeWhere((i) => i.id == itemId);
    _persist();
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(json.encode({
      'schedule': json.encode(_schedule),
      'homeworks': json.encode(_homeworks),
      'logs': json.encode(_logs),
      'todos': json.encode(_todos),
      'events': json.encode(_events),
      'favoritePersonas': json.encode(_favoritePersonas)
    }));
    _restore(_undoStack.removeLast());
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(json.encode({
      'schedule': json.encode(_schedule),
      'homeworks': json.encode(_homeworks),
      'logs': json.encode(_logs),
      'todos': json.encode(_todos),
      'events': json.encode(_events),
      'favoritePersonas': json.encode(_favoritePersonas)
    }));
    _restore(_redoStack.removeLast());
  }

  void _restore(String snapshot) {
    var map = json.decode(snapshot);
    _schedule = List<ScheduleItem>.from((json.decode(map['schedule']) as List)
        .map((x) => ScheduleItem.fromJson(x)));
    _homeworks = List<SubjectHomework>.from(
        (json.decode(map['homeworks']) as List)
            .map((x) => SubjectHomework.fromJson(x)));
    _logs = List<DailyLog>.from(
        (json.decode(map['logs']) as List).map((x) => DailyLog.fromJson(x)));
    if (map['todos'] != null) {
      _todos = List<TodoItem>.from(
          (json.decode(map['todos']) as List).map((x) => TodoItem.fromJson(x)));
    } else {
      _todos = [];
    }
    if (map['events'] != null) {
      _events = List<CalendarEvent>.from((json.decode(map['events']) as List)
          .map((x) => CalendarEvent.fromJson(x)));
    } else {
      _events = [];
    }
    if (map['favoritePersonas'] != null) {
      _favoritePersonas = List<FavoritePersona>.from(
          (json.decode(map['favoritePersonas']) as List)
              .map((x) => FavoritePersona.fromJson(x)));
    } else {
      _favoritePersonas = [];
    }
    _persist();
  }

  void resetAll() async {
    await _storage.clearWinterPlanData();
    _undoStack.clear();
    _redoStack.clear();
    _init();
  }

  Future<void> exportBackup(BuildContext context) async {
    try {
      final jsonStr = json.encode({
        'schedule': json.encode(_schedule),
        'homeworks': json.encode(_homeworks),
        'logs': json.encode(_logs),
        'todos': json.encode(_todos),
        'events': json.encode(_events),
        'favoritePersonas': json.encode(_favoritePersonas)
      });
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/winter_backup_${DateFormat('MMdd_HHmm').format(DateTime.now())}.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], text: '作息打卡数据备份');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("备份失败: $e")));
    }
  }

  Future<void> importBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        var map = json.decode(content);
        _schedule = List<ScheduleItem>.from(
            (json.decode(map['schedule']) as List)
                .map((x) => ScheduleItem.fromJson(x)));
        _homeworks = List<SubjectHomework>.from(
            (json.decode(map['homeworks']) as List)
                .map((x) => SubjectHomework.fromJson(x)));
        _logs = List<DailyLog>.from((json.decode(map['logs']) as List)
            .map((x) => DailyLog.fromJson(x)));
        if (map['todos'] != null) {
          _todos = List<TodoItem>.from((json.decode(map['todos']) as List)
              .map((x) => TodoItem.fromJson(x)));
        }
        if (map['events'] != null) {
          _events = List<CalendarEvent>.from(
              (json.decode(map['events']) as List)
                  .map((x) => CalendarEvent.fromJson(x)));
        }
        if (map['favoritePersonas'] != null) {
          _favoritePersonas = List<FavoritePersona>.from(
              (json.decode(map['favoritePersonas']) as List)
                  .map((x) => FavoritePersona.fromJson(x)));
        }
        _persist();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("数据恢复成功！")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("恢复失败，文件可能已损坏: $e")));
    }
  }
}

// ==========================================
// 3. UI 主入口
// ==========================================

const _spaceBackground = Color(0xFF11131A);
const _spacePanel = Color(0xFF1A1E28);
const _spaceAmber = Color(0xFFE2B45B);
const _spaceRed = Color(0xFF9B3030);
const _armorWhite = Color(0xFFE8E3D8);

class SpacePersona {
  final String id;
  final String title;
  final String subtitle;
  final String eraLabel;
  final Color armorColor;
  final Color accentColor;
  final Color visorColor;

  const SpacePersona({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.eraLabel,
    required this.armorColor,
    required this.accentColor,
    required this.visorColor,
  });
}

const _dailyPersonas = [
  SpacePersona(
    id: 'phase-line-captain',
    title: '相位线队长',
    subtitle: '适合把今天拆成清晰步骤，稳稳推进。',
    eraLabel: '前传感 / 白甲军团',
    armorColor: _armorWhite,
    accentColor: _spaceRed,
    visorColor: Color(0xFF20242C),
  ),
  SpacePersona(
    id: 'outer-rim-scout',
    title: '外环侦察员',
    subtitle: '适合探索新任务，先观察，再行动。',
    eraLabel: '前传感 / 沙地巡逻',
    armorColor: Color(0xFFD7C29A),
    accentColor: Color(0xFF6E7F58),
    visorColor: Color(0xFF1C2322),
  ),
  SpacePersona(
    id: 'void-deck-trooper',
    title: '星舰甲板兵',
    subtitle: '适合处理杂事、整理空间、保持秩序。',
    eraLabel: '正传感 / 星舰值守',
    armorColor: Color(0xFFDDE1E7),
    accentColor: Color(0xFF4A4F58),
    visorColor: Color(0xFF111318),
  ),
  SpacePersona(
    id: 'twin-sun-guard',
    title: '双日守卫',
    subtitle: '适合长时间专注，慢一点也没关系。',
    eraLabel: '正传感 / 荒漠基地',
    armorColor: Color(0xFFE7D6B5),
    accentColor: Color(0xFFB56A35),
    visorColor: Color(0xFF26201A),
  ),
  SpacePersona(
    id: 'red-stripe-vanguard',
    title: '红纹先锋',
    subtitle: '适合开局困难的一天，用第一步破局。',
    eraLabel: '前传感 / 突击小队',
    armorColor: _armorWhite,
    accentColor: Color(0xFFC14137),
    visorColor: Color(0xFF22252B),
  ),
  SpacePersona(
    id: 'black-bridge-officer',
    title: '黑桥指挥官',
    subtitle: '适合做计划、排优先级、压住节奏。',
    eraLabel: '正传感 / 冷色舰桥',
    armorColor: Color(0xFF2E333D),
    accentColor: _spaceAmber,
    visorColor: Color(0xFF0B0C10),
  ),
];

SpacePersona _personaForDate(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final days = day.difference(DateTime(2026, 1, 1)).inDays.abs();
  return _dailyPersonas[days % _dailyPersonas.length];
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const WinterApp(),
    ),
  );
}

class WinterApp extends StatelessWidget {
  const WinterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '作息打卡',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        primaryColor: const Color(0xFF007AFF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  final _pages = [
    const DashboardTab(),
    const ScheduleTab(),
    const CalendarTab(),
    const HomeworkTab(),
    const TodoTab(),
    const SettingsTab()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _spacePanel,
          border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _idx,
          backgroundColor: _spacePanel,
          indicatorColor: _spaceAmber.withValues(alpha: 0.16),
          height: 65,
          elevation: 0,
          onDestinationSelected: (i) => setState(() => _idx = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics, color: _spaceAmber),
                label: '战况'),
            NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today, color: _spaceAmber),
                label: '日程'),
            NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note, color: _spaceAmber),
                label: '月历'),
            NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist, color: _spaceAmber),
                label: '事项'),
            NavigationDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt, color: _spaceAmber),
                label: '待办'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: _spaceAmber),
                label: '设置'),
          ],
        ),
      ),
    );
  }
}

// ======================= Tab 1: 战况总览 =======================
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    ScheduleItem? currentItem;
    ScheduleItem? nextItem;
    final now = DateTime.now();
    final todayEvents = state.eventsForDate(now);
    for (var item in state.schedule) {
      final start = item.getStartTime(now);
      final end = item.getEndTime(now);
      if (start != null && end != null) {
        if (now.isAfter(start) && now.isBefore(end)) {
          currentItem = item;
          break;
        }
        if (now.isBefore(start) &&
            (nextItem == null || start.isBefore(nextItem.getStartTime(now)!))) {
          nextItem = item;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("日常作息打卡",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("安排、专注、复盘，每天都能微调",
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text("今日 ${DateFormat('M.d').format(now)}",
                style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (currentItem != null || nextItem != null)
            GestureDetector(
              onTap: () {
                if (currentItem != null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TimerPage(item: currentItem!)));
                } else if (nextItem != null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TimerPage(item: nextItem!)));
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: currentItem != null
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF9500),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                        currentItem != null
                            ? Icons.play_circle_fill
                            : Icons.next_plan,
                        color: Colors.white,
                        size: 40),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentItem != null ? "正在进行" : "下一项任务",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text(
                            currentItem != null
                                ? currentItem.title
                                : nextItem!.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text(
                            currentItem != null
                                ? "点击进入计时"
                                : "${nextItem!.timeRange} 开始",
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF0055B3)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("当前阶段",
                          style: TextStyle(color: Colors.white70)),
                      const Text("今日节奏",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                          currentItem != null
                              ? currentItem.title
                              : nextItem != null
                                  ? "下一项：${nextItem.title}"
                                  : "今天的日程已结束",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_motion,
                      color: Colors.white, size: 32),
                )
              ],
            ),
          ),

          if (todayEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("今日特殊安排",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...todayEvents.map((event) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_available,
                              color: Color(0xFF007AFF)),
                          title: Text(event.title),
                          subtitle:
                              event.note.isEmpty ? null : Text(event.note),
                        )),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text("打卡数据中心",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildChartCard("最近 30 天评分曲线", _buildFixedLineChart(state.logs)),

          const SizedBox(height: 12),
          // 🔴 修复溢出：调整宽高比 + 使用 FittedBox
          LayoutBuilder(builder: (ctx, constraints) {
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4, // 从 1.5 改为 1.4，增加高度
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatCard(
                    "总投入时长",
                    "${(state.logs.fold(0, (sum, l) => sum + l.minutes) / 60).toStringAsFixed(1)} h",
                    Icons.timer,
                    Colors.orange),
                _buildStatCard(
                    "平均完成率",
                    "${(state.logs.isEmpty ? 0 : state.logs.fold(0.0, (sum, l) => sum + l.completionRate) / state.logs.length).toStringAsFixed(0)} %",
                    Icons.check_circle,
                    Colors.green),
                _buildStatCard(
                    "平均质量",
                    "${(state.logs.isEmpty ? 0 : state.logs.fold(0.0, (sum, l) => sum + l.avgQuality) / state.logs.length).toStringAsFixed(1)} ★",
                    Icons.star,
                    Colors.purple),
                _buildStatCard("打卡天数", "${state.logs.length} 天",
                    Icons.calendar_today, Colors.blue),
              ],
            );
          }),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey)),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedLineChart(List<DailyLog> logs) {
    List<FlSpot> spots = [];
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 29));
    final endDate = DateTime(today.year, today.month, today.day);
    int totalDays = endDate.difference(startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      DateTime d = startDate.add(Duration(days: i));
      String dStr = DateFormat('yyyy-MM-dd').format(d);
      var log = logs.firstWhere((l) => l.date == dStr,
          orElse: () => DailyLog(
              date: "",
              score: -1,
              minutes: 0,
              completionRate: 0,
              avgQuality: 0));
      if (log.score != -1) {
        spots.add(FlSpot(i.toDouble(), log.score));
      }
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    int idx = val.toInt();
                    if (idx % 5 == 0 && idx < totalDays) {
                      DateTime d = startDate.add(Duration(days: idx));
                      return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text("${d.month}.${d.day}",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)));
                    }
                    return const Text("");
                  },
                  interval: 1,
                  reservedSize: 22)),
          leftTitles: const AxisTitles(
              sideTitles:
                  SideTitles(showTitles: true, reservedSize: 30, interval: 20)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        minX: 0,
        maxX: totalDays.toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF007AFF),
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF007AFF).withValues(alpha: 0.1)),
          )
        ],
      ),
    );
  }

  // 🔴 修复溢出：使用 FittedBox 缩放内容
  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          // 自动缩放，防止溢出
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(val,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ... ScheduleTab, HomeworkTab, TimerPage, SettingsTab 等其他 Tab 保持不变 ...
// (为节省篇幅，且其他部分无改动，此处省略。但在实际粘贴时，请确保main.dart完整包含 ScheduleTab, HomeworkTab, TimerPage, SettingsTab 的类定义)
// ⚠️ 注意：如果你之前的代码是完整的，只需替换 DashboardTab 类和 AppState 类即可。
// 但为了安全起见，我会把后面没变的部分也补全，确保你一键复制不出错。

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final persona = _personaForDate(now);
    return Scaffold(
      backgroundColor: _spaceBackground,
      appBar: AppBar(
        title: const Text("每日任务"),
        backgroundColor: _spaceBackground,
        titleTextStyle: const TextStyle(
            color: _armorWhite, fontWeight: FontWeight.bold, fontSize: 18),
        iconTheme: const IconThemeData(color: _armorWhite),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DailyPersonaCard(
            persona: persona,
            isFavorited: state.isPersonaFavorited(persona.id),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < state.schedule.length; i++) ...[
            _ScheduleSpaceCard(
              item: state.schedule[i],
              now: now,
              persona: persona,
              onEdit: () => _showEditScheduleDialog(context, state.schedule[i]),
            ),
            if (i != state.schedule.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _spaceAmber,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showEditScheduleDialog(context, null),
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, ScheduleItem? item) {
    final titleCtrl = TextEditingController(text: item?.title);
    final contentCtrl = TextEditingController(text: item?.content);
    final timeCtrl =
        TextEditingController(text: item?.timeRange ?? "00:00 - 00:00");
    final iconCtrl = TextEditingController(text: item?.icon ?? "📝");
    final timePattern = RegExp(r'^\d{2}:\d{2}\s*-\s*\d{2}:\d{2}$');
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(item == null ? "新增日程" : "编辑日程"),
              content: SingleChildScrollView(
                  child: Column(children: [
                TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(
                        labelText: "时间段 (如 09:00 - 11:45)")),
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "模块名称")),
                TextField(
                    controller: contentCtrl,
                    decoration: const InputDecoration(labelText: "具体内容")),
                TextField(
                    controller: iconCtrl,
                    decoration: const InputDecoration(labelText: "图标 (Emoji)")),
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("取消")),
                if (item != null)
                  TextButton(
                      onPressed: () {
                        ctx.read<AppState>().deleteScheduleItem(item.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("日程已删除")));
                      },
                      child: const Text("删除",
                          style: TextStyle(color: Colors.red))),
                TextButton(
                    onPressed: () {
                      if (!timePattern.hasMatch(timeCtrl.text.trim())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("时间格式应为 09:00 - 11:45")));
                        return;
                      }
                      if (titleCtrl.text.trim().isEmpty ||
                          contentCtrl.text.trim().isEmpty ||
                          iconCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("请补全模块名称、内容和图标")));
                        return;
                      }
                      final newState = ctx.read<AppState>();
                      var list = List<ScheduleItem>.from(newState.schedule);
                      if (item == null) {
                        list.add(ScheduleItem(
                            id: DateTime.now().toString(),
                            timeRange: timeCtrl.text.trim(),
                            title: titleCtrl.text.trim(),
                            content: contentCtrl.text.trim(),
                            icon: iconCtrl.text.trim(),
                            tag: ""));
                      } else {
                        int idx = list.indexWhere((e) => e.id == item.id);
                        if (idx != -1)
                          list[idx] = ScheduleItem(
                              id: item.id,
                              timeRange: timeCtrl.text.trim(),
                              title: titleCtrl.text.trim(),
                              content: contentCtrl.text.trim(),
                              icon: iconCtrl.text.trim(),
                              tag: item.tag);
                      }
                      list.sort((a, b) => a.timeRange.compareTo(b.timeRange));
                      newState.updateSchedule(list);
                      Navigator.pop(ctx);
                    },
                    child: const Text("保存")),
              ],
            ));
  }
}

class _DailyPersonaCard extends StatelessWidget {
  final SpacePersona persona;
  final bool isFavorited;

  const _DailyPersonaCard({
    required this.persona,
    required this.isFavorited,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF242833),
            persona.accentColor.withValues(alpha: 0.55),
            const Color(0xFF08090D),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StarFieldPainter(accentColor: persona.accentColor),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 0,
            top: 18,
            width: 140,
            child: CustomPaint(
              painter: _PersonaPainter(persona: persona),
            ),
          ),
          Positioned(
            left: 18,
            top: 18,
            right: 128,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  persona.eraLabel,
                  style: const TextStyle(
                    color: _spaceAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  persona.title,
                  style: const TextStyle(
                    color: _armorWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  persona.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isFavorited ? _spaceAmber : Colors.white12,
                    foregroundColor:
                        isFavorited ? const Color(0xFF181818) : _armorWhite,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  ),
                  onPressed: () {
                    context.read<AppState>().toggleFavoritePersona(
                          persona.id,
                          persona.title,
                          persona.subtitle,
                        );
                  },
                  icon: Icon(
                    isFavorited ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                  ),
                  label: Text(isFavorited ? "已记录" : "记录这个形象"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSpaceCard extends StatelessWidget {
  final ScheduleItem item;
  final DateTime now;
  final SpacePersona persona;
  final VoidCallback onEdit;

  const _ScheduleSpaceCard({
    required this.item,
    required this.now,
    required this.persona,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final start = item.getStartTime(now);
    final end = item.getEndTime(now);
    final isCurrent =
        start != null && end != null && now.isAfter(start) && now.isBefore(end);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent ? persona.accentColor : _spacePanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCurrent
                  ? _spaceAmber.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.08)),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                      color: persona.accentColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(item.icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item.timeRange,
                          style: TextStyle(
                              color:
                                  isCurrent ? Colors.white70 : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      const Spacer(),
                      if (item.tag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.white24
                                  : persona.accentColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(item.tag,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isCurrent
                                      ? Colors.white
                                      : persona.accentColor)),
                        )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.title,
                      style: TextStyle(
                          color: isCurrent ? Colors.white : _armorWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  Text(item.content,
                      style: TextStyle(
                          color: isCurrent ? Colors.white70 : Colors.white60,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.play_circle_fill,
                  size: 40, color: isCurrent ? Colors.white : _spaceAmber),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TimerPage(item: item))),
            )
          ],
        ),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final Color accentColor;

  _StarFieldPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final accentPaint = Paint()..color = accentColor.withValues(alpha: 0.35);
    for (var i = 0; i < 34; i++) {
      final x = (i * 47 % size.width.toInt()).toDouble();
      final y = (i * 29 % size.height.toInt()).toDouble();
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.6 : 0.9, starPaint);
    }
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.18), 18,
        accentPaint..color = _spaceAmber.withValues(alpha: 0.2));
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.25), 9,
        accentPaint..color = accentColor.withValues(alpha: 0.24));
    final linePaint = Paint()
      ..color = _spaceAmber.withValues(alpha: 0.28)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width * 0.08, size.height * 0.78),
        Offset(size.width * 0.74, size.height * 0.58), linePaint);
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}

class _PersonaPainter extends CustomPainter {
  final SpacePersona persona;

  _PersonaPainter({required this.persona});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final armor = Paint()..color = persona.armorColor;
    final accent = Paint()..color = persona.accentColor;
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.3);
    final visor = Paint()..color = persona.visorColor;

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(center.dx, size.height * 0.92),
            width: size.width * 0.82,
            height: size.height * 0.18),
        shadow);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.16, size.height * 0.58, size.width * 0.68,
          size.height * 0.36),
      const Radius.circular(18),
    );
    canvas.drawRRect(body, armor);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.45, size.height * 0.58, size.width * 0.1,
            size.height * 0.35),
        accent);

    final helmet = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.12, size.width * 0.56,
          size.height * 0.46),
      const Radius.circular(24),
    );
    canvas.drawRRect(helmet, armor);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.28, size.height * 0.28)
        ..lineTo(size.width * 0.72, size.height * 0.28)
        ..lineTo(size.width * 0.64, size.height * 0.38)
        ..lineTo(size.width * 0.36, size.height * 0.38)
        ..close(),
      visor,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.39)
        ..lineTo(size.width * 0.61, size.height * 0.54)
        ..lineTo(size.width * 0.39, size.height * 0.54)
        ..close(),
      accent,
    );
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.32, size.height * 0.18, size.width * 0.36,
            size.height * 0.05),
        accent);
    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.5), size.width * 0.06, armor);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.5), size.width * 0.06, armor);
  }

  @override
  bool shouldRepaint(covariant _PersonaPainter oldDelegate) =>
      oldDelegate.persona.id != persona.id;
}

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);
    final nextMonth = DateTime(today.year, today.month + 1, 1);
    final daysInMonth = nextMonth.difference(monthStart).inDays;
    final leadingEmptyCount = monthStart.weekday % 7;
    final totalCells = leadingEmptyCount + daysInMonth;
    final selectedEvents = state.eventsForDate(_selectedDate);
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: Text(DateFormat('yyyy年M月').format(today))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: Column(
                children: [
                  Row(
                    children: weekdays
                        .map((day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalCells,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (ctx, index) {
                      if (index < leadingEmptyCount) {
                        return const SizedBox.shrink();
                      }
                      final day = index - leadingEmptyCount + 1;
                      final date = DateTime(today.year, today.month, day);
                      final isSelected =
                          DateUtils.isSameDay(date, _selectedDate);
                      final isToday = DateUtils.isSameDay(date, today);
                      final events = state.eventsForDate(date);
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => _selectedDate = date),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF007AFF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isToday
                                  ? const Color(0xFF007AFF)
                                  : Colors.transparent,
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$day",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: events.isEmpty
                                      ? Colors.transparent
                                      : isSelected
                                          ? Colors.white
                                          : const Color(0xFFFF9500),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  "${DateFormat('M月d日').format(_selectedDate)} 周${weekdays[_selectedDate.weekday % 7]}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showEventDialog(context, _selectedDate),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("添加"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedEvents.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.event_available,
                        color: Colors.grey.withValues(alpha: 0.45), size: 44),
                    const SizedBox(height: 10),
                    const Text("这一天没有特殊安排",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text("点添加按钮安排事件。",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...selectedEvents.map((event) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Color(0xFF007AFF)),
                    title: Text(event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: event.note.isEmpty ? null : Text(event.note),
                    trailing: IconButton(
                      tooltip: "删除",
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => context
                          .read<AppState>()
                          .deleteCalendarEvent(event.id),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  void _showEventDialog(BuildContext context, DateTime date) {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("添加 ${DateFormat('M月d日').format(date)} 安排"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "事件名称"),
                autofocus: true,
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: "备注，可不填"),
                minLines: 1,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              ctx
                  .read<AppState>()
                  .addCalendarEvent(date, titleCtrl.text, noteCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text("添加"),
          ),
        ],
      ),
    );
  }
}

class HomeworkTab extends StatelessWidget {
  const HomeworkTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text("日常事项库")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.homeworks.length,
        itemBuilder: (ctx, i) {
          final subject = state.homeworks[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              shape: const Border(),
              leading: Text(subject.icon, style: const TextStyle(fontSize: 28)),
              title: Text(subject.subject,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: subject.progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            color: subject.progress == 1.0
                                ? Colors.green
                                : const Color(0xFF007AFF))),
                    const SizedBox(height: 4),
                    Text("进度: ${(subject.progress * 100).toInt()}%",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
              children: [
                ...subject.items.map((item) => CheckboxListTile(
                      title: Text(item.content,
                          style: TextStyle(
                              decoration: item.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isDone ? Colors.grey : Colors.black)),
                      value: item.isDone,
                      activeColor: const Color(0xFF007AFF),
                      onChanged: (val) {
                        context
                            .read<AppState>()
                            .toggleHomeworkItem(subject.subject, item.id);
                      },
                      secondary: IconButton(
                          icon: const Icon(Icons.edit,
                              size: 16, color: Colors.grey),
                          onPressed: () =>
                              _editItem(context, subject.subject, item)),
                    )),
                ListTile(
                    leading: const Icon(Icons.add, color: Color(0xFF007AFF)),
                    title: const Text("添加新条目...",
                        style: TextStyle(color: Color(0xFF007AFF))),
                    onTap: () => _addItem(context, subject.subject))
              ],
            ),
          );
        },
      ),
    );
  }

  void _addItem(BuildContext context, String subject) {
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text("添加 $subject 事项"),
              content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(hintText: "请输入具体内容")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("取消")),
                TextButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        ctx
                            .read<AppState>()
                            .addHomeworkItem(subject, ctrl.text);
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text("添加")),
              ],
            ));
  }

  void _editItem(BuildContext context, String subject, HomeworkItem item) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("管理条目"),
              content: Text("确定要删除 '${item.content}' 吗？"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("取消")),
                TextButton(
                    onPressed: () {
                      ctx.read<AppState>().deleteHomeworkItem(subject, item.id);
                      Navigator.pop(ctx);
                    },
                    child:
                        const Text("删除", style: TextStyle(color: Colors.red))),
              ],
            ));
  }
}

class TodoTab extends StatefulWidget {
  const TodoTab({super.key});

  @override
  State<TodoTab> createState() => _TodoTabState();
}

class _TodoTabState extends State<TodoTab> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pending = state.todos.where((todo) => !todo.isDone).toList();
    final completed = state.todos.where((todo) => todo.isDone).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("今日待办"),
        actions: [
          if (completed.isNotEmpty)
            IconButton(
              tooltip: "清除已完成",
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: () => context.read<AppState>().clearCompletedTodos(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${state.pendingTodoCount} 个待完成 · ${state.completedTodoCount} 个已完成",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: "写下一个要完成的事",
                            filled: true,
                            fillColor: const Color(0xFFF5F5F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _addTodo(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        tooltip: "添加",
                        icon: const Icon(Icons.add),
                        onPressed: () => _addTodo(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.todos.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(Icons.task_alt,
                        color: Colors.grey.withValues(alpha: 0.45), size: 48),
                    const SizedBox(height: 12),
                    const Text("还没有待办",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text("在上方输入一件事，然后点加号。",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else ...[
            if (pending.isNotEmpty) ...[
              _sectionTitle("待完成"),
              ...pending.map((todo) => _todoTile(context, todo)),
            ],
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 8),
              _sectionTitle("已完成"),
              ...completed.map((todo) => _todoTile(context, todo)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(title,
          style: const TextStyle(
              color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _todoTile(BuildContext context, TodoItem todo) {
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => context.read<AppState>().deleteTodoItem(todo.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: CheckboxListTile(
          value: todo.isDone,
          activeColor: const Color(0xFF007AFF),
          onChanged: (_) => context.read<AppState>().toggleTodoItem(todo.id),
          title: Text(
            todo.content,
            style: TextStyle(
              fontSize: 16,
              decoration: todo.isDone ? TextDecoration.lineThrough : null,
              color: todo.isDone ? Colors.grey : Colors.black,
            ),
          ),
          secondary: IconButton(
            tooltip: "删除",
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            onPressed: () => context.read<AppState>().deleteTodoItem(todo.id),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  void _addTodo(BuildContext context) {
    context.read<AppState>().addTodoItem(_controller.text);
    _controller.clear();
  }
}

class TimerPage extends StatefulWidget {
  final ScheduleItem item;
  const TimerPage({super.key, required this.item});
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late Timer _timer;
  int _secondsElapsed = 0;
  int _secondsRemaining = 0;
  bool _isOvertime = false;
  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted)
        setState(() {
          _secondsElapsed++;
          if (_secondsRemaining > 0)
            _secondsRemaining--;
          else
            _isOvertime = true;
        });
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final end = widget.item.getEndTime(now);
    if (end != null && end.isAfter(now)) {
      _secondsRemaining = end.difference(now).inSeconds;
    } else {
      _secondsRemaining = 0;
      _isOvertime = true;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fmt(int sec) {
    int h = sec ~/ 3600;
    int m = (sec % 3600) ~/ 60;
    int s = sec % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
                alignment: Alignment.topLeft,
                child: BackButton(color: Colors.black)),
            const Spacer(),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 1),
              builder: (ctx, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7), shape: BoxShape.circle),
                child: Text(widget.item.icon,
                    style: const TextStyle(fontSize: 80)),
              ),
            ),
            const SizedBox(height: 30),
            Text(widget.item.title,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(widget.item.content,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),
            Text(_isOvertime ? "已超时 (加紧收尾)" : "剩余专注时间",
                style:
                    TextStyle(color: _isOvertime ? Colors.red : Colors.grey)),
            Text(
              _isOvertime
                  ? "+${_fmt(_secondsElapsed - (widget.item.getEndTime(DateTime.now())!.difference(widget.item.getStartTime(DateTime.now())!).inSeconds))}"
                  : _fmt(_secondsRemaining),
              style: GoogleFonts.robotoMono(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: _isOvertime ? Colors.red : Colors.black),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _timer.cancel();
                showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => SubmitSheet(seconds: _secondsElapsed));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 8))
                    ]),
                child: const Text("完成并打卡",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SubmitSheet extends StatefulWidget {
  final int seconds;
  const SubmitSheet({super.key, required this.seconds});
  @override
  State<SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<SubmitSheet> {
  double _percent = 100;
  double _stars = 5;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("任务结算",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text("本次投入: ${(widget.seconds / 60).ceil()} 分钟",
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text("完成度 (支持暴击)",
                style: TextStyle(fontWeight: FontWeight.bold))),
        Row(children: [
          Expanded(
              child: Slider(
                  value: _percent,
                  min: 0,
                  max: 150,
                  divisions: 15,
                  activeColor: const Color(0xFF007AFF),
                  onChanged: (v) => setState(() => _percent = v))),
          Text("${_percent.toInt()}%",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF007AFF))),
        ]),
        const SizedBox(height: 20),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text("质量自评", style: TextStyle(fontWeight: FontWeight.bold))),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
                5,
                (i) => IconButton(
                    icon: Icon(i < _stars ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 36),
                    onPressed: () => setState(() => _stars = i + 1.0)))),
        const SizedBox(height: 40),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: const Text("提交数据",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              onPressed: () {
                context
                    .read<AppState>()
                    .submitLog((widget.seconds / 60).ceil(), _percent, _stars);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "打卡成功：${(widget.seconds / 60).ceil()} 分钟，完成度 ${_percent.toInt()}%，质量 ${_stars.toInt()} 星")));
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ))
      ]),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text("系统设置")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("数据控制"),
          Card(
              child: Column(children: [
            ListTile(
                leading: const Icon(Icons.undo, color: Colors.orange),
                title: const Text("撤销 (Undo)"),
                trailing: state.canUndo
                    ? null
                    : const Icon(Icons.block, color: Colors.grey),
                onTap: state.canUndo
                    ? () => context.read<AppState>().undo()
                    : null),
            const Divider(height: 1, indent: 50),
            ListTile(
                leading: const Icon(Icons.redo, color: Colors.blue),
                title: const Text("恢复 (Redo)"),
                trailing: state.canRedo
                    ? null
                    : const Icon(Icons.block, color: Colors.grey),
                onTap: state.canRedo
                    ? () => context.read<AppState>().redo()
                    : null),
          ])),
          const SizedBox(height: 20),
          _buildSectionHeader("备份与安全"),
          Card(
              child: Column(children: [
            ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.green),
                title: const Text("导出备份文件"),
                subtitle: const Text("生成 JSON 文件以供恢复"),
                onTap: () => context.read<AppState>().exportBackup(context)),
            const Divider(height: 1, indent: 50),
            ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text("从备份恢复"),
                subtitle: const Text("选择 JSON 文件覆盖当前数据"),
                onTap: () => context.read<AppState>().importBackup(context)),
          ])),
          const SizedBox(height: 20),
          _buildSectionHeader("危险区域"),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("重置所有数据"),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                              title: const Text("警告"),
                              content: const Text("这将清空所有打卡记录、事项进度和特殊安排，确定吗？"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("取消")),
                                TextButton(
                                    onPressed: () {
                                      context.read<AppState>().resetAll();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text("重置",
                                        style: TextStyle(color: Colors.red)))
                              ],
                            ));
                  })),
          const SizedBox(height: 40),
          const Center(
              child: Text("Version 1.3.0 (Daily Routine)",
                  style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(title,
            style: const TextStyle(color: Colors.grey, fontSize: 13)));
  }
}
