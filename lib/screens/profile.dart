import 'package:flutter/material.dart';
import 'package:K_Skill/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class UserProfile {
  final String name;
  final String className;
  final String gender;
  final String school;
  final String address;
  final int currentStreak;
  final String currentLevel;
  final List<String> recentLessons;
  final Map<String, double> assessmentScores;

  UserProfile({
    required this.name,
    required this.className,
    required this.gender,
    required this.school,
    required this.address,
    required this.currentStreak,
    required this.currentLevel,
    required this.recentLessons,
    required this.assessmentScores,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final lessons = json['completedLessons'] as List<dynamic>;
    final recentLessons = lessons
        .map((lesson) => lesson['lessonId'] as String)
        .toList();
    final scores = json['assessmentScores'] as Map<String, dynamic>;

    return UserProfile(
      name: json['name'],
      className: json['class'] ?? '',
      gender: json['gender'] ?? '',
      school: json['school'] ?? '',
      address: json['address'] ?? '',
      currentStreak: json['currentStreak'] ?? 0,
      currentLevel: json['currentLevel'] ?? 'Basic',
      recentLessons: recentLessons,
      assessmentScores: scores.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? userId;
  late Future<List<dynamic>> profileFuture;
  late TabController _tabController;

  final Color primaryRed = Colors.red;
  final Color primaryGreen = Colors.green;
  final Color primaryYellow = Colors.orangeAccent;
  final Color primaryBlue = Colors.blue;
  final Color lightBackground = Colors.grey[200]!;

  static String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserIdAndFetchProfile();
  }

  Future<void> _loadUserIdAndFetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    if (userId != null) {
      setState(() {
        profileFuture = _loadProfileWithLessons();
      });
    }
  }

  Future<UserProfile> fetchUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/$userId/profile'));
    if (response.statusCode == 200) {
      return UserProfile.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<Map<String, dynamic>> loadLessonsJson() async {
    final response = await DefaultAssetBundle.of(
      context,
    ).loadString('data/lessons/english_curriculum.json');
    return json.decode(response);
  }

  List<dynamic> extractAllLessonIdsAndTitles(Map<String, dynamic> json) {
    List<String> ids = [];
    Map<String, String> titles = {};
    json.forEach((_, levelData) {
      final modules = levelData['modules'] as Map<String, dynamic>;
      modules.forEach((_, moduleData) {
        final lessons = moduleData['lessons'] as Map<String, dynamic>;
        lessons.forEach((lessonId, lessonData) {
          ids.add(lessonId);
          titles[lessonId] = lessonData['title'];
        });
      });
    });
    return [ids, titles];
  }

  Map<String, int> calculateLevelWiseProgress(
    Map<String, dynamic> json,
    List<String> completedLessons,
  ) {
    Map<String, int> levelProgress = {};
    json.forEach((levelKey, levelData) {
      final modules = levelData['modules'] as Map<String, dynamic>;
      int total = 0;
      int completed = 0;
      modules.forEach((_, moduleData) {
        final lessons = moduleData['lessons'] as Map<String, dynamic>;
        lessons.forEach((lessonId, _) {
          total++;
          if (completedLessons.contains(lessonId)) completed++;
        });
      });
      levelProgress[levelKey] = total == 0
          ? 0
          : ((completed / total) * 100).toInt();
    });
    return levelProgress;
  }

  Future<List<dynamic>> _loadProfileWithLessons() async {
    final profile = await fetchUserProfile(userId!);
    final lessonsJson = await loadLessonsJson();
    final extracted = extractAllLessonIdsAndTitles(lessonsJson);
    return [profile, lessonsJson, extracted[1]];
  }

  Future<void> _logout() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

    // In your logout function
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastRoute');
    await prefs.remove('userId');
    await prefs.setBool('isLoggedIn', false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: lightBackground,
        appBar: AppBar(
          title: Text('Your Profile', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orangeAccent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.red),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard', // or '/home' - whatever your home route is
                (route) => false, // Remove all previous routes
              );
            },
          ),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: profileFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: primaryBlue),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final profile = snapshot.data![0] as UserProfile;
            final allLessonsJson = snapshot.data![1] as Map<String, dynamic>;
            final lessonTitles = snapshot.data![2] as Map<String, String>;

            final totalLessons = lessonTitles.length;
            final completedLessons = profile.recentLessons.length;
            final progressPercent = completedLessons / totalLessons;
            final levelProgress = calculateLevelWiseProgress(
              allLessonsJson,
              profile.recentLessons,
            );

            return Column(
              children: [
                _buildProfileHeader(profile),
                TabBar(
                  controller: _tabController,
                  labelColor: primaryBlue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryBlue,
                  tabs: [
                    Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                    Tab(icon: Icon(Icons.assessment), text: 'Assessment'),
                    Tab(icon: Icon(Icons.stacked_bar_chart), text: 'Levels'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverview(profile, lessonTitles, totalLessons),
                      _buildAssessment(profile),
                      _buildProgress(profile, progressPercent, levelProgress),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenderAvatar(String gender) {
    if (gender.toLowerCase() == 'male') {
      return Image.asset('images/boy.png', width: 100, height: 100);
    } else if (gender.toLowerCase() == 'female') {
      return Image.asset('images/girl.png', width: 100, height: 100);
    } else {
      return Icon(Icons.person, color: Colors.white, size: 36);
    }
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: primaryYellow,
            child: ClipOval(child: _buildGenderAvatar(profile.gender)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(profile.className, style: TextStyle(color: Colors.grey)),
                Text(profile.school, style: TextStyle(color: Colors.grey)),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${profile.currentStreak} day streak',
                      style: TextStyle(color: Colors.orange),
                    ),
                    Spacer(),
                    Chip(
                      label: Text(
                        profile.currentLevel,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: primaryGreen,
                      avatar: Icon(Icons.star, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    UserProfile profile,
    Map<String, String> lessonTitles,
    int totalLessons,
  ) {
    final sortedLessons = profile.recentLessons.reversed.toList();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _overviewCard(
              'Overall Progress',
              '${((profile.recentLessons.length / totalLessons) * 100).toInt()}%',
              primaryGreen,
              Icons.show_chart,
            ),
            SizedBox(width: 10),
            _overviewCard(
              'Lessons Completed',
              '${profile.recentLessons.length}/$totalLessons',
              primaryBlue,
              Icons.menu_book,
            ),
            SizedBox(width: 10),
            _overviewCard(
              'Assessment Score',
              '${_averageScore(profile.assessmentScores)}%',
              primaryYellow,
              Icons.emoji_events,
            ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          '📘 Recent Lessons',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ...sortedLessons.map(
          (id) => Card(
            child: ListTile(
              leading: Icon(Icons.book, color: primaryBlue),
              title: Text(lessonTitles[id] ?? id),
            ),
          ),
        ),
      ],
    );
  }

  Widget _overviewCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // <-- allow shrink
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28), // reduced size
            SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessment(UserProfile profile) {
    final scores = profile.assessmentScores;
    final bool hasTakenAssessment = scores.values.any((score) => score > 0);

    final testList = [
      {
        'title': 'Grammar & Vocabulary',
        'icon': Icons.psychology,
        'key': 'quiz',
      },
      {'title': 'Reading Test', 'icon': Icons.menu_book, 'key': 'reading'},
      {'title': 'Listening Test', 'icon': Icons.headphones, 'key': 'listening'},
    ];

    final totalScore = hasTakenAssessment
        ? scores.values.reduce((a, b) => a + b) / scores.length
        : 0.0;

    String recommendedLevel = 'Basic';
    if (totalScore >= 75) {
      recommendedLevel = 'Advanced';
    } else if (totalScore >= 50) {
      recommendedLevel = 'Intermediate';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'K-Skill Assessment Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Assessment scores and Proficiency level',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          if (!hasTakenAssessment) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                // Navigate to start assessment screen
              },
              child: const Text("Take Assessment"),
            ),
            const SizedBox(height: 16),
          ],

          if (hasTakenAssessment) ...[
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: testList.map((test) {
                final key = test['key']!;
                final score = scores[key] ?? 0;

                final color = score >= 80
                    ? Colors.green
                    : score >= 50
                    ? Colors.orange
                    : Colors.red;

                return Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(test['icon'] as IconData, size: 40, color: color),
                      const SizedBox(height: 8),
                      Text(
                        test['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${score.toInt()}/100',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Overall Assessment Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${totalScore.toInt()}/100',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recommended Level: $recommendedLevel',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProgress(
    UserProfile profile,
    double percent,
    Map<String, int> levelProgress,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation(primaryBlue),
                    ),
                  ),
                  Icon(Icons.bubble_chart, size: 40, color: primaryBlue),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${(percent * 100).toInt()}% Overall Progress',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '🎯 Level-wise Progress',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),

        // 👇 Visual bar for each level
        ...levelProgress.entries.map(
          (e) => Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_border, color: primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key.replaceAll("_", " "),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (e.value / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(primaryGreen),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${e.value}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _averageScore(Map<String, double> scores) {
    if (scores.isEmpty) return 0;
    final total = scores.values.reduce((a, b) => a + b);
    return (total / scores.length).toInt();
  }
}
