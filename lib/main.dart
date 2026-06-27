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

  List<String> _undoStack = [];
  List<String> _redoStack = [];

  List<ScheduleItem> get schedule => _schedule;
  List<SubjectHomework> get homeworks => _homeworks;
  List<DailyLog> get logs => _logs;

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
            title: "☀️ 启动",
            content: "起床、早餐、醒脑",
            icon: "☀️",
            tag: ""),
        ScheduleItem(
            id: '2',
            timeRange: "09:00 - 11:45",
            title: "🧠 硬核运算",
            content: "物理压轴题 + 化学二模卷",
            icon: "🧠",
            tag: "🔥"),
        ScheduleItem(
            id: '3',
            timeRange: "11:45 - 12:30",
            title: "🍲 能量补给",
            content: "午餐",
            icon: "🍲",
            tag: ""),
        ScheduleItem(
            id: '4',
            timeRange: "12:30 - 13:15",
            title: "🎹 艺术留白",
            content: "钢琴 / 电影 / 课外书",
            icon: "🎹",
            tag: "🎵"),
        ScheduleItem(
            id: '5',
            timeRange: "13:15 - 13:45",
            title: "🔋 快速充电",
            content: "午休（30分钟）",
            icon: "🔋",
            tag: "💤"),
        ScheduleItem(
            id: '6',
            timeRange: "13:45 - 16:15",
            title: "📐 综合逻辑",
            content: "数学几何/函数 + 英语D篇",
            icon: "📐",
            tag: "✍️"),
        ScheduleItem(
            id: '7',
            timeRange: "16:15 - 18:15",
            title: "⚽ 激流勇进",
            content: "足球 / 户外运动",
            icon: "⚽",
            tag: "🏃"),
        ScheduleItem(
            id: '8',
            timeRange: "18:15 - 19:15",
            title: "🍽️ 晚餐调整",
            content: "晚餐 + 家庭聊天",
            icon: "🍽️",
            tag: ""),
        ScheduleItem(
            id: '9',
            timeRange: "19:15 - 20:45",
            title: "📝 输出/复盘",
            content: "文科背诵 + App打卡",
            icon: "📝",
            tag: "🔄"),
        ScheduleItem(
            id: '10',
            timeRange: "20:45 - 21:30",
            title: "🚿 自由洗漱",
            content: "洗澡、准备睡觉",
            icon: "🚿",
            tag: "🌙"),
      ];
    }

    final savedHomework = await _storage.read(StorageService.homeworkKey);
    if (savedHomework != null) {
      Iterable l = json.decode(savedHomework);
      _homeworks =
          List<SubjectHomework>.from(l.map((x) => SubjectHomework.fromJson(x)));
    } else {
      _homeworks = [
        SubjectHomework(subject: "物理", icon: "⚡", items: [
          HomeworkItem(id: 'p1', content: "空中课堂：19个实验视频"),
          HomeworkItem(id: 'p2', content: "寒假指导册 (2.1 提交)"),
          HomeworkItem(id: 'p3', content: "寒假指导册 (2.8 提交)"),
          HomeworkItem(id: 'p4', content: "寒假指导册 (2.15 提交)"),
          HomeworkItem(id: 'p5', content: "寒假指导册 (2.22 提交)"),
          HomeworkItem(id: 'p6', content: "校本：压强/电学压轴题"),
          HomeworkItem(id: 'p7', content: "二模卷八选做"),
        ]),
        SubjectHomework(subject: "数学", icon: "📐", items: [
          HomeworkItem(id: 'm1', content: "寒假指导册 (224篇)"),
          HomeworkItem(id: 'm2', content: "空中课堂查漏补缺"),
          HomeworkItem(id: 'm3', content: "完成 24, 25(1)(2) 巩固"),
          HomeworkItem(id: 'm4', content: "17题巩固"),
        ]),
        SubjectHomework(subject: "英语", icon: "🔤", items: [
          HomeworkItem(id: 'e1', content: "考纲词汇 (全部单词+词组)"),
          HomeworkItem(id: 'e2', content: "22年一模卷 (6张)"),
          HomeworkItem(id: 'e3', content: "22年二模卷 (全部)"),
          HomeworkItem(id: 'e4', content: "作文 (2006年-一模)"),
          HomeworkItem(id: 'e5', content: "C篇 / D篇 专项训练"),
        ]),
        SubjectHomework(subject: "化学", icon: "🧪", items: [
          HomeworkItem(id: 'c1', content: "指导册 P35-38 (2.6发)"),
          HomeworkItem(id: 'c2', content: "指导册 P39-44 (2.13发)"),
          HomeworkItem(id: 'c3', content: "指导册 P51-58 (2.24发)"),
          HomeworkItem(id: 'c4', content: "2025杨浦二模 + 2026虹口一模"),
          HomeworkItem(id: 'c5', content: "选做：静安/徐汇/黄浦二模"),
        ]),
        SubjectHomework(subject: "文综/其他", icon: "📜", items: [
          HomeworkItem(id: 'o1', content: "历史：中国史1-4册笔记"),
          HomeworkItem(id: 'o2', content: "道法：3次作业 (钉钉提交)"),
          HomeworkItem(id: 'o3', content: "地理/生物：核心图册背诵"),
          HomeworkItem(id: 'o4', content: "社会实践：年夜饭/非遗/幸福家书"),
        ]),
        SubjectHomework(subject: "体育", icon: "🏃", items: [
          HomeworkItem(id: 's1', content: "每日足球 1.5-2h"),
          HomeworkItem(id: 's2', content: "俯卧撑 30-50/天"),
          HomeworkItem(id: 's3', content: "仰卧起坐 100-200/天"),
        ]),
      ];
    }

    final savedLogs = await _storage.read(StorageService.logsKey);
    if (savedLogs != null) {
      Iterable l = json.decode(savedLogs);
      _logs = List<DailyLog>.from(l.map((x) => DailyLog.fromJson(x)));
    }
    notifyListeners();
  }

  void _saveSnapshot() {
    String snapshot = json.encode({
      'schedule': json.encode(_schedule),
      'homeworks': json.encode(_homeworks),
      'logs': json.encode(_logs)
    });
    _undoStack.add(snapshot);
    if (_undoStack.length > 20) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  Future<void> _persist() async {
    await _storage.write(StorageService.scheduleKey, json.encode(_schedule));
    await _storage.write(StorageService.homeworkKey, json.encode(_homeworks));
    await _storage.write(StorageService.logsKey, json.encode(_logs));
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
      'logs': json.encode(_logs)
    }));
    _restore(_undoStack.removeLast());
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(json.encode({
      'schedule': json.encode(_schedule),
      'homeworks': json.encode(_homeworks),
      'logs': json.encode(_logs)
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
        'logs': json.encode(_logs)
      });
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/winter_backup_${DateFormat('MMdd_HHmm').format(DateTime.now())}.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], text: '寒假作战数据备份');
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
      title: '凛冬反击',
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
    const HomeworkTab(),
    const SettingsTab()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2), width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _idx,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
          height: 65,
          elevation: 0,
          onDestinationSelected: (i) => setState(() => _idx = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics, color: Color(0xFF007AFF)),
                label: '战况'),
            NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon:
                    Icon(Icons.calendar_today, color: Color(0xFF007AFF)),
                label: '日程'),
            NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist, color: Color(0xFF007AFF)),
                label: '作业'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: Color(0xFF007AFF)),
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

    final targetDate = DateTime(2026, 6, 15);
    final daysLeft = targetDate.difference(DateTime.now()).inDays;

    final winterEnd = DateTime(2026, 2, 27);
    final winterLeft = winterEnd.difference(DateTime.now()).inDays;

    ScheduleItem? currentItem;
    ScheduleItem? nextItem;
    final now = DateTime.now();
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
            const Text("寒假作战指挥部",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("代号：凛冬反击 | Designed by EnochW",
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
            child: Text("距2026中考 $daysLeft 天",
                style: const TextStyle(
                    color: Color(0xFFFF3B30),
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
                      const Text("寒假攻坚期 (2.2 - 2.27)",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(winterLeft > 0 ? "剩余 $winterLeft 天" : "假期已结束",
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
                  child: const Icon(Icons.snowboarding,
                      color: Colors.white, size: 32),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text("综合数据中心",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildChartCard(
              "综合评定曲线 (2.2 - 2.27)", _buildFixedLineChart(state.logs)),

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
                    "总学习时长",
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
    final startDate = DateTime(2026, 2, 2);
    final endDate = DateTime(2026, 2, 27);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text("每日日程表")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.schedule.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final item = state.schedule[i];
          final now = DateTime.now();
          final start = item.getStartTime(now);
          final end = item.getEndTime(now);
          bool isCurrent = false;
          if (start != null && end != null) {
            if (now.isAfter(start) && now.isBefore(end)) isCurrent = true;
          }
          return InkWell(
            onTap: () => _showEditScheduleDialog(context, item),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF007AFF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 10,
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
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12)),
                    child:
                        Text(item.icon, style: const TextStyle(fontSize: 24)),
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
                                    color: isCurrent
                                        ? Colors.white70
                                        : Colors.grey,
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
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(item.tag,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isCurrent
                                            ? Colors.white
                                            : Colors.red)),
                              )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.title,
                            style: TextStyle(
                                color: isCurrent ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 17)),
                        Text(item.content,
                            style: TextStyle(
                                color: isCurrent ? Colors.white70 : Colors.grey,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.play_circle_fill,
                        size: 40,
                        color:
                            isCurrent ? Colors.white : const Color(0xFF007AFF)),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TimerPage(item: item))),
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF007AFF),
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
                            const SnackBar(content: Text("时间格式应为 09:00 - 11:45")));
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

class HomeworkTab extends StatelessWidget {
  const HomeworkTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text("寒假作业总库")),
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
              title: Text("添加 $subject 作业"),
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
                              content: const Text("这将清空所有打卡记录和作业进度，确定吗？"),
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
              child: Text("Version 1.1.0 (Winter Counterattack)",
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
