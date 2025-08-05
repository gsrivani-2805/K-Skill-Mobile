import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:K_Skill/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurriculumData {
  static Map<String, dynamic>? _data;

  static Future<Map<String, dynamic>> loadData() async {
    if (_data == null) {
      String jsonString = await rootBundle.loadString(
        'data/lessons/english_curriculum.json',
      );
      _data = json.decode(jsonString);
    }
    return _data!;
  }
}

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  _LevelsScreenState createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  Map<String, dynamic> curriculumData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCurriculumData();
    _storeCurrentRoute();
  }

  Future<void> _storeCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      await prefs.setString('lastRoute', '/levels');
      print('Stored route: /levels');
    }
  }

  Future<void> loadCurriculumData() async {
    try {
      final data = await CurriculumData.loadData();
      setState(() {
        curriculumData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading curriculum data: $e')),
      );
    }
  }

  // Define colors and icons for different levels
  List<Map<String, dynamic>> getLevelConfigs() {
    return [
      {
        'color': const Color(0xFFFF9800), // Orange
        'borderColor': const Color(0xFFFFB74D),
        'icon': Icons.quiz,
      },
      {
        'color': const Color(0xFF2196F3), // Blue
        'borderColor': const Color(0xFF64B5F6),
        'icon': Icons.library_books,
      },
      {
        'color': const Color(0xFF4CAF50), // Green
        'borderColor': const Color(0xFF81C784),
        'icon': Icons.headphones,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('English Curriculum'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1976D2),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Your Level',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a level to start your English learning journey',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content section
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isDesktop = constraints.maxWidth > 800;

                      if (isDesktop) {
                        // Desktop layout - show cards in rows
                        return _buildDesktopLayout();
                      } else {
                        // Mobile layout - show cards in column
                        return _buildMobileLayout();
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMobileLayout() {
    final levelConfigs = getLevelConfigs();

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: curriculumData.length,
      itemBuilder: (context, index) {
        String levelKey = curriculumData.keys.elementAt(index);
        Map<String, dynamic> level = curriculumData[levelKey];
        int moduleCount = (level['modules'] as Map<String, dynamic>).length;

        final config = levelConfigs[index % levelConfigs.length];

        return _buildLevelCard(
          level: level,
          levelKey: levelKey,
          moduleCount: moduleCount,
          color: config['color'],
          borderColor: config['borderColor'],
          icon: config['icon'],
          isDesktop: false,
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    final levelConfigs = getLevelConfigs();
    final levels = curriculumData.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          for (int i = 0; i < levels.length; i += 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                children: [
                  for (int j = i; j < i + 3 && j < levels.length; j++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: j < i + 2 && j < levels.length - 1 ? 16.0 : 0,
                        ),
                        child: () {
                          final entry = levels[j];
                          final level = entry.value;
                          final levelKey = entry.key;
                          int moduleCount =
                              (level['modules'] as Map<String, dynamic>).length;
                          final config = levelConfigs[j % levelConfigs.length];

                          return _buildLevelCard(
                            level: level,
                            levelKey: levelKey,
                            moduleCount: moduleCount,
                            color: config['color'],
                            borderColor: config['borderColor'],
                            icon: config['icon'],
                            isDesktop: true,
                          );
                        }(),
                      ),
                    ),
                  // Add empty expanded widgets to fill the row if needed
                  for (int k = i + 3; k < i + 3 && levels.length < i + 3; k++)
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required Map<String, dynamic> level,
    required String levelKey,
    required int moduleCount,
    required Color color,
    required Color borderColor,
    required IconData icon,
    required bool isDesktop,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor.withOpacity(0.3), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ModulesScreen(levelKey: levelKey, levelData: level),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, color.withOpacity(0.05)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon and title row
                Row(
                  children: [
                    // Container(
                    //   padding: const EdgeInsets.all(12),
                    //   decoration: BoxDecoration(
                    //     color: color.withOpacity(0.15),
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Icon(
                    //     icon,
                    //     color: color,
                    //     size: 28,
                    //   ),
                    // ),
                    // const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['title'] ?? 'Level Title',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$moduleCount modules',
                              style: TextStyle(
                                fontSize: 12,
                                color: color.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_forward, color: color, size: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  level['focus'] ?? 'Level description',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                  maxLines: isDesktop ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Progress indicator (placeholder)
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor:
                        0.6, // You can replace this with actual progress
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModulesScreen extends StatelessWidget {
  final String levelKey;
  final Map<String, dynamic> levelData;

  const ModulesScreen({
    Key? key,
    required this.levelKey,
    required this.levelData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> modules = Map<String, dynamic>.from(
      levelData['modules'] ?? {},
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(levelData['title'] ?? 'Modules'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          String moduleKey = modules.keys.elementAt(index);
          Map<String, dynamic> module = modules[moduleKey];
          int lessonCount = (module['lessons'] as Map<String, dynamic>).length;

          return Card(
            margin: EdgeInsets.only(bottom: 16.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LessonsScreen(moduleKey: moduleKey, moduleData: module),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.book,
                        color: Colors.green[700],
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module['title'] ?? 'Module',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$lessonCount lessons',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LessonsScreen extends StatefulWidget {
  final String moduleKey;
  final Map<String, dynamic> moduleData;

  const LessonsScreen({
    Key? key,
    required this.moduleKey,
    required this.moduleData,
  }) : super(key: key);

  @override
  _LessonsScreenState createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  Set<String> completedLessons = <String>{};
  static const String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchCompletedLessons();
  }

  Future<void> fetchCompletedLessons() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) return;

    final url = Uri.parse('$baseUrl/$userId/profile');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final completed = data['completedLessons'];

      if (completed is List) {
        setState(() {
          completedLessons = completed
              .map<String>((item) => item['lessonId'].toString())
              .toSet();
        });
      } else if (completed is Map) {
        setState(() {
          completedLessons = completed.keys
              .map<String>((key) => key.toString())
              .toSet();
        });
      }
    }
  }

  void markAsCompleted(String lessonKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/$userId/mark-complete');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'lessonId': lessonKey}),
    );

    if (response.statusCode == 200) {
      setState(() {
        completedLessons.add(lessonKey);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lesson marked as completed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark lesson complete'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void takeQuiz(String lessonKey, Map<String, dynamic> lessonInfo) {
    final quizPath = lessonInfo['quiz_path'];
    if (quizPath != null && quizPath.toString().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonQuiz(
            quizPath: 'data/$quizPath',
            lessonTitle: lessonInfo['title'],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Quiz Not Available'),
            content: Text('No quiz path found for "${lessonInfo['title']}".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void openLesson(String lessonKey, Map<String, dynamic> lessonInfo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LessonDetailScreen(lessonKey: lessonKey, lessonInfo: lessonInfo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> lessons = widget.moduleData['lessons'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moduleData['title'] ?? 'Lessons'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: EdgeInsets.all(16.0),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            String lessonKey = lessons.keys.elementAt(index);
            Map<String, dynamic> lessonInfo = lessons[lessonKey];
            bool isCompleted = completedLessons.contains(lessonKey);

            print(lessonKey);

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => openLesson(lessonKey, lessonInfo),
                child: Container(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : Icons.play_circle_outline,
                              color: isCompleted
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lessonInfo['title'] ?? 'Lesson',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Lesson ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => takeQuiz(lessonKey, lessonInfo),
                              icon: Icon(Icons.quiz),
                              label: Text('Take Quiz'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isCompleted
                                  ? null
                                  : () => markAsCompleted(lessonKey),
                              icon: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                              ),
                              label: Text(
                                isCompleted ? 'Completed' : 'Mark Complete',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCompleted
                                    ? Colors.green[300]
                                    : Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LessonDetailScreen extends StatefulWidget {
  final String lessonKey;
  final Map<String, dynamic> lessonInfo;

  const LessonDetailScreen({
    Key? key,
    required this.lessonKey,
    required this.lessonInfo,
  }) : super(key: key);

  @override
  _LessonDetailScreenState createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  Map<String, dynamic>? lessonContent;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadLessonContent();
  }

  Future<void> loadLessonContent() async {
    try {
      String filePath = widget.lessonInfo['file_path'] ?? '';
      if (filePath.isNotEmpty) {
        String jsonString = await rootBundle.loadString('data/$filePath');
        setState(() {
          lessonContent = json.decode(jsonString);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'No file path specified for this lesson';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading lesson content: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          lessonContent?['lesson_title'] ?? 'Lesson',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.indigo.shade700,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
            ),
            SizedBox(height: 20),
            Text(
              'Loading lesson content...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 48,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loadLessonContent,
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (lessonContent == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, color: Colors.grey.shade400, size: 64),
            SizedBox(height: 16),
            Text(
              'No lesson content available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(),
          _buildObjectives(),
          _buildTopics(),
          SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade200,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  lessonContent!['lesson_title'] ?? 'Lesson',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (lessonContent!['level'] != null &&
                  lessonContent!['level'].toString().isNotEmpty)
                _buildInfoChip(
                  'Level',
                  lessonContent!['level'],
                  Icons.bar_chart,
                ),
              if (lessonContent!['module'] != null &&
                  lessonContent!['module'].toString().isNotEmpty)
                _buildInfoChip(
                  'Module',
                  lessonContent!['module'],
                  Icons.folder,
                ),
              if (lessonContent!['lesson_number'] != null)
                _buildInfoChip(
                  'Lesson',
                  lessonContent!['lesson_number'].toString(),
                  Icons.numbers,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectives() {
    if (lessonContent!['objectives'] == null ||
        (lessonContent!['objectives'] as List).isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.track_changes,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Learning Objectives',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...(lessonContent!['objectives'] as List)
              .asMap()
              .entries
              .map(
                (entry) =>
                    _buildObjectiveItem(entry.value.toString(), entry.key),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildObjectiveItem(String objective, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              objective,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopics() {
    if (lessonContent!['topics'] == null ||
        (lessonContent!['topics'] as List).isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.topic,
                  color: Colors.purple.shade600,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Topics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        ...(lessonContent!['topics'] as List)
            .map((topic) => _buildTopicWidget(topic))
            .toList(),
      ],
    );
  }

  Widget _buildTopicWidget(Map<String, dynamic> topic) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topic['title'] != null && topic['title'].toString().isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Text(
                topic['title'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (topic['subtopics'] != null)
                  ...(topic['subtopics'] as List)
                      .map((subtopic) => _buildSubtopicWidget(subtopic))
                      .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtopicWidget(Map<String, dynamic> subtopic) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtopic['title'] != null &&
              subtopic['title'].toString().isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.subdirectory_arrow_right,
                    color: Colors.indigo.shade600,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtopic['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (subtopic['sections'] != null)
            ...(subtopic['sections'] as List)
                .map((section) => _buildSectionWidget(section))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildSectionWidget(Map<String, dynamic> section) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section['text'] != null && section['text'].toString().isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: MarkdownBody(
                data: section['text'],
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
              ),
            ),

          if (section['text'] != null && section['text'].toString().isNotEmpty)
            SizedBox(height: 16),

          if (section['media'] != null) _buildMedia(section['media']),

          if (section['examples'] != null) _buildExamples(section['examples']),

          if (section['usage_examples'] != null)
            _buildUsageExamples(section['usage_examples']),

          if (section['table'] != null) _buildTable(section['table']),
        ],
      ),
    );
  }

  Widget _buildMedia(Map<String, dynamic> media) {
    final imagePath = media['image'];
    if (imagePath == null || imagePath.toString().isEmpty) {
      return SizedBox.shrink();
    }

    return FutureBuilder(
      future: rootBundle.load(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: 250,
                  ),
                ),
              ],
            ),
          );
        }
        // If loading or asset not found, show nothing
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildExamples(List<dynamic> examples) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange.shade600, size: 18),
              SizedBox(width: 8),
              Text(
                'Examples',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...examples.map((example) => _buildExampleItem(example)).toList(),
        ],
      ),
    );
  }

  Widget _buildExampleItem(Map<String, dynamic> example) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (example['label'] != null &&
              example['label'].toString().isNotEmpty)
            Text(
              example['label'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
                fontSize: 14,
              ),
            ),
          if (example['label'] != null && example['value'] != null)
            SizedBox(height: 4),
          if (example['value'] != null &&
              example['value'].toString().isNotEmpty)
            MarkdownBody(
              data: example['value'],
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    strong: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsageExamples(List<dynamic> usageExamples) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: Colors.teal.shade600, size: 18),
              SizedBox(width: 8),
              Text(
                'Usage Examples',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...usageExamples
              .map((example) => _buildUsageExampleItem(example.toString()))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildUsageExampleItem(String example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Colors.teal.shade300, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote, color: Colors.teal.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: MarkdownBody(
              data: example.replaceAll(
                '\n',
                '  \n',
              ), // <- Force markdown line breaks
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.teal.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    strong: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(Map<String, dynamic> table) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: Colors.indigo.shade600, size: 18),
              SizedBox(width: 8),
              Text(
                table['title'] ?? 'Reference Table',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                if (table['headers'] != null)
                  _buildTableHeader(table['headers']),
                if (table['rows'] != null)
                  ...((table['rows'] as List)
                      .asMap()
                      .entries
                      .map(
                        (entry) =>
                            _buildTableRow(entry.value, entry.key % 2 == 0),
                      )
                      .toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<dynamic> headers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.shade600,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: headers
            .map(
              (header) => Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    header.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTableRow(List<dynamic> row, bool isEven) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.indigo.shade50 : Colors.white,
      ),
      child: Row(
        children: row
            .map(
              (cell) => Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: MarkdownBody(
                    data: cell.toString(),
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                          p: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    shrinkWrap: true,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class LessonQuiz extends StatefulWidget {
  final String quizPath;
  final String lessonTitle;

  const LessonQuiz({
    super.key,
    required this.quizPath,
    required this.lessonTitle,
  });

  @override
  State<LessonQuiz> createState() => _LessonQuizState();
}

class _LessonQuizState extends State<LessonQuiz> {
  Map<String, List<Map<String, dynamic>>> questionsByLevel = {
    'Easy': [],
    'Medium': [],
    'Hard': [],
  };

  List<Map<String, dynamic>> selectedQuestions = [];
  List<String?> userAnswers = [];

  int currentQuestionIndex = 0;
  int score = 0;
  bool isQuizCompleted = false;
  bool isLoading = true;
  String? errorMessage;
  String? selectedOption;

  // Question distribution
  final Map<String, int> questionCounts = {'Easy': 4, 'Medium': 4, 'Hard': 2};

  @override
  void initState() {
    super.initState();
    _loadQuestionsFromJson();
  }

  Future<void> _loadQuestionsFromJson() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final String jsonString = await rootBundle.loadString(widget.quizPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Clear previous data
      questionsByLevel = {'Easy': [], 'Medium': [], 'Hard': []};

      // Extract questions from the grammar_quiz structure
      if (jsonData.containsKey('grammar_quiz')) {
        final List<dynamic> grammarQuiz = jsonData['grammar_quiz'];

        for (var levelData in grammarQuiz) {
          if (levelData is Map<String, dynamic> &&
              levelData.containsKey('level') &&
              levelData.containsKey('questions')) {
            String level = levelData['level'];
            List<dynamic> questions = levelData['questions'];

            if (questionsByLevel.containsKey(level)) {
              for (var question in questions) {
                if (question is Map<String, dynamic>) {
                  // Normalize the question format
                  Map<String, dynamic> normalizedQuestion = {
                    'id': question['id'],
                    'question': question['question'],
                    'options': question['options'],
                    'correctAnswer':
                        question['correct_answer'], // Note: using correct_answer from JSON
                    'level': level,
                    'grammar_type': question['grammar_type'] ?? '',
                  };
                  questionsByLevel[level]!.add(normalizedQuestion);
                }
              }
            }
          }
        }
      }

      // Validate we have enough questions
      for (String level in questionCounts.keys) {
        int available = questionsByLevel[level]!.length;
        int required = questionCounts[level]!;
        if (available < required) {
          throw Exception(
            'Not enough $level questions. Required: $required, Available: $available',
          );
        }
      }

      _selectRandomQuestions();
      setState(() => isLoading = false);
    } catch (e) {
      print("Error loading questions: $e");
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load quiz questions: ${e.toString()}";
      });
    }
  }

  void _selectRandomQuestions() {
    selectedQuestions.clear();
    final rng = Random(DateTime.now().microsecondsSinceEpoch);

    // Select questions from each level in order: Easy -> Medium -> Hard
    List<String> levelOrder = ['Easy', 'Medium', 'Hard'];

    for (String level in levelOrder) {
      List<Map<String, dynamic>> levelQuestions = List.from(
        questionsByLevel[level]!,
      );
      levelQuestions.shuffle(rng);

      int count = questionCounts[level]!;
      selectedQuestions.addAll(levelQuestions.take(count));
    }

    // Do NOT shuffle the final question order - keep Easy -> Medium -> Hard sequence

    // Initialize user answers list
    userAnswers = List.filled(selectedQuestions.length, null);
  }

  void handleAnswerSelected(String selectedAnswer) {
    // Store user's answer
    userAnswers[currentQuestionIndex] = selectedAnswer;

    // Check if answer is correct
    final correct = selectedQuestions[currentQuestionIndex]['correctAnswer'];
    if (selectedAnswer == correct) {
      score++;
    }

    // Move to next question or complete quiz
    if (currentQuestionIndex < selectedQuestions.length - 1) {
      setState(() => currentQuestionIndex++);
    } else {
      setState(() => isQuizCompleted = true);
    }
  }

  void _submitScoreAndExit() {
    Navigator.pop(context, score);
  }

  void _restartQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      isQuizCompleted = false;
    });
    _selectRandomQuestions();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingScreen();
    if (errorMessage != null || selectedQuestions.isEmpty) {
      return _buildErrorScreen();
    }
    if (isQuizCompleted) return _buildResultScreen();

    final current = selectedQuestions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.lessonTitle} - Question ${currentQuestionIndex + 1} of ${selectedQuestions.length}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8A2BE2),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / selectedQuestions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8A2BE2)),
          ),

          // Level indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _getLevelColor(current['level']).withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _getLevelIcon(current['level']),
                  color: _getLevelColor(current['level']),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "${current['level']} Level",
                  style: TextStyle(
                    color: _getLevelColor(current['level']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (current['grammar_type'] != null &&
                    current['grammar_type'].isNotEmpty)
                  Text(
                    current['grammar_type'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current['question'] ?? 'Question not available',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount:
                              (current['options'] as List<dynamic>?)?.length ??
                              0,
                          itemBuilder: (context, index) {
                            final options = current['options'] as List<dynamic>;
                            final option = options[index].toString();

                            final isSelected = selectedOption == option;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 2,
                                color: isSelected
                                    ? const Color(0xFF8A2BE2).withOpacity(0.2)
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: isSelected
                                      ? const BorderSide(
                                          color: Color(0xFF8A2BE2),
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => handleAnswerSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? const Color(0xFF8A2BE2)
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: const Color(0xFF8A2BE2),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              String.fromCharCode(65 + index),
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF8A2BE2),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? const Color(0xFF8A2BE2)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Easy':
        return Icons.sentiment_satisfied;
      case 'Medium':
        return Icons.sentiment_neutral;
      case 'Hard':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.help;
    }
  }

  Widget _buildResultScreen() {
    final percentage = (score / selectedQuestions.length) * 100;
    String feedback;
    Color color;

    if (percentage >= 90) {
      feedback = "Excellent Work!";
      color = Colors.green;
    } else if (percentage >= 70) {
      feedback = "Good Job!";
      color = Colors.blue;
    } else if (percentage >= 50) {
      feedback = "Keep Practicing!";
      color = Colors.orange;
    } else {
      feedback = "Need More Practice!";
      color = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quiz Results",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8A2BE2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final isVerySmallScreen = constraints.maxWidth < 400;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      (MediaQuery.of(context).padding.top +
                          MediaQuery.of(context).padding.bottom +
                          kToolbarHeight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Overall Result Card
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen ? 0 : 8,
                      ),
                      padding: EdgeInsets.all(isVerySmallScreen ? 20 : 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          // Icon
                          // Icon(
                          //   icon, // fallback icon
                          //   size:
                          //       isVerySmallScreen ? 80 : (isSmallScreen ? 90 : 100),
                          //   color: color,
                          // ),
                          // SizedBox(height: isVerySmallScreen ? 8 : 12),

                          // Feedback Text
                          Text(
                            feedback,
                            style: TextStyle(
                              fontSize: isVerySmallScreen
                                  ? 24
                                  : (isSmallScreen ? 28 : 32),
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isVerySmallScreen ? 16 : 24),

                          // Score Display - Responsive Layout
                          if (isVerySmallScreen) ...[
                            Column(
                              children: [
                                Text(
                                  "You scored",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$score",
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8A2BE2),
                                      ),
                                    ),
                                    Text(
                                      " / ",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      "${selectedQuestions.length}",
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8A2BE2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ] else ...[
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "You scored ",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "$score",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 40 : 48,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF8A2BE2),
                                  ),
                                ),
                                Text(
                                  " out of ",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "${selectedQuestions.length}",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 40 : 48,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF8A2BE2),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Percentage Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 16 : 20,
                              vertical: isVerySmallScreen ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${percentage.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isVerySmallScreen ? 32 : 40),

                    // Action Buttons - Responsive Layout
                    if (isVerySmallScreen) ...[
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _restartQuiz,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: const Text(
                                "Try Again",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitScoreAndExit,
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: const Text(
                                "Back to Lesson",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8A2BE2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton.icon(
                                onPressed: _restartQuiz,
                                icon: Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                                label: Text(
                                  "Try Again",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 24,
                                    vertical: isSmallScreen ? 12 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ElevatedButton.icon(
                                onPressed: _submitScoreAndExit,
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                                label: Text(
                                  "Back to Lesson",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8A2BE2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 24,
                                    vertical: isSmallScreen ? 12 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() => Scaffold(
    appBar: AppBar(
      title: Text(
        "Loading ${widget.lessonTitle}",
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF8A2BE2),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A2BE2)),
          ),
          SizedBox(height: 16),
          Text("Loading quiz questions...", style: TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );

  Widget _buildErrorScreen() => Scaffold(
    appBar: AppBar(
      title: const Text("Quiz Error", style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF8A2BE2),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Oops! Something went wrong",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                errorMessage ?? 'Error loading quiz',
                style: TextStyle(fontSize: 14, color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadQuestionsFromJson,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Try Again",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A2BE2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
