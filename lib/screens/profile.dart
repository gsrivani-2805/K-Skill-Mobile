import 'package:K_Skill/assessment/assessment_screen.dart';
import 'package:K_Skill/screens/levels.dart';
import 'package:K_Skill/services/app_usage_tracker.dart';
import 'package:K_Skill/services/shared_prefs.dart';
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
  String name;
  String className;
  final String gender;
  String school;
  final String address;
  final int currentStreak;
  final String currentLevel;
  final List<String> recentLessons;
  final Map<String, double> assessmentScores;
  final List<Map<String, dynamic>> completedLessons;

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
    required this.completedLessons,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final lessons = json['completedLessons'] as List<dynamic>? ?? [];
    final recentLessons = lessons
        .map((lesson) => lesson['lessonId'] as String)
        .toList();

    final scores = json['assessmentScores'] as Map<String, dynamic>? ?? {};

    final completedLessonList = lessons.map((lesson) {
      return {
        'lessonId': lesson['lessonId'] ?? '',
        'score': lesson['score'] ?? 0,
        'totalQuestions': lesson['totalQuestions'] ?? 0,
        'percentage': lesson['percentage'] ?? 0,
      };
    }).toList();

    return UserProfile(
      name: json['name'] ?? '',
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
      completedLessons: List<Map<String, dynamic>>.from(completedLessonList),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? userId;
  String? token;
  late Future<List<dynamic>> profileFuture;
  late TabController _tabController;

  final Color primaryRed = Colors.red;
  final Color primaryGreen = Colors.green;
  final Color primaryYellow = Colors.orangeAccent;
  final Color primaryBlue = Colors.blue;
  final Color lightBackground = Colors.grey[200]!;

  static String baseUrl = ApiConfig.baseUrl;
  final usageTracker = AppUsageTracker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserIdAndFetchProfile();
  }

  Future<void> _loadUserIdAndFetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    token = prefs.getString('token');
    if (userId != null) {
      setState(() {
        profileFuture = _loadProfileWithLessons();
      });
    }
  }

  Future<UserProfile> fetchUserProfile(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/$userId/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final data = body['data'];

      return UserProfile.fromJson(data);
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
    final profile = await fetchUserProfile(userId!, token!);
    final lessonsJson = await loadLessonsJson();
    final extracted = extractAllLessonIdsAndTitles(lessonsJson);
    return [profile, lessonsJson, extracted[1]];
  }

  Future<void> _logout() async {
    await usageTracker.stopTracking();
    await AppUsageTracker.syncUsageToServer();
    await SharedPrefsService.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,

      appBar: AppBar(
        title: const Text(
          'Your Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          },
        ),
      ),

      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
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
                      _buildOverview(
                        profile,
                        lessonTitles,
                        totalLessons,
                        allLessonsJson,
                      ),
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

  Future<void> _updateProfileOnServer(
    String name,
    String className,
    String school,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/$userId/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name, 'class': className, 'school': school}),
      );

      if (response.statusCode == 200) {
        // Profile updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload profile data
        setState(() {
          profileFuture = _loadProfileWithLessons();
        });
      } else {
        final body = jsonDecode(response.body);
        final errorMessage = body['error']?['message'] ?? response.body;

        throw Exception('Failed to update profile: $errorMessage');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLearningSuggestion(String currentLevel) {
    String emoji;
    String message;
    String levelToStart;
    Color backgroundColor;
    Color textColor;

    // Determine content based on current level
    if (currentLevel == 'Basic') {
      emoji = '🌱';
      message = 'Great start! Begin your journey with';
      levelToStart = 'Basic Level';
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (currentLevel == 'Intermediate') {
      emoji = '🚀';
      message = 'You\'re doing well! Continue from';
      levelToStart = 'Intermediate Level';
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else {
      // Advanced level
      emoji = '⭐';
      message = 'Excellent! Challenge yourself with';
      levelToStart = 'Advanced Level';
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamedAndRemoveUntil(context, '/levels', (route) => false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Emoji icon
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),

            // Message text with level highlighted
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: textColor, height: 1.3),
                  children: [
                    TextSpan(text: '$message '),
                    TextSpan(
                      text: levelToStart,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow icon
            Icon(Icons.arrow_forward, color: textColor, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            // Mobile layout
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Avatar with Edit Button
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryYellow,
                      child: ClipOval(
                        child: _buildGenderAvatar(profile.gender),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showEditProfileDialog(context, profile),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Profile Details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      profile.className,
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      profile.school,
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Streak and Level
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                      ],
                    ),
                    Chip(
                      label: Text(
                        profile.currentLevel,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: getColorbyLevel(profile.currentLevel),
                      avatar: Icon(Icons.star, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Web layout
            return Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: primaryYellow,
                          child: ClipOval(
                            child: _buildGenderAvatar(profile.gender),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () =>
                                _showEditProfileDialog(context, profile),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            profile.className,
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            profile.school,
                            style: TextStyle(color: Colors.grey),
                          ),
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
                                backgroundColor: getColorbyLevel(
                                  profile.currentLevel,
                                ),
                                avatar: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    final List<String> classes = [
      'Class 1',
      'Class 2',
      'Class 3',
      'Class 4',
      'Class 5',
      'Class 6',
      'Class 7',
      'Class 8',
      'Class 9',
      'Class 10',
      'Class 11',
      'Class 12',
      'Adult Learner',
    ];

    TextEditingController nameController = TextEditingController(
      text: profile.name,
    );
    TextEditingController schoolController = TextEditingController(
      text: profile.school,
    );

    String selectedClass =
        profile.className.isNotEmpty && classes.contains(profile.className)
        ? profile.className
        : classes[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit Profile'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Dropdown for Class Selection
                    DropdownButtonFormField<String>(
                      value: selectedClass,
                      decoration: InputDecoration(
                        labelText: 'Class',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: classes.map((String className) {
                        return DropdownMenuItem<String>(
                          value: className,
                          child: Text(className),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedClass = newValue;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 16),
                    TextField(
                      controller: schoolController,
                      decoration: InputDecoration(
                        labelText: 'School',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty &&
                        schoolController.text.trim().isNotEmpty) {
                      _updateProfile(
                        nameController.text.trim(),
                        selectedClass, // Use the selected class from dropdown
                        schoolController.text.trim(),
                        profile,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateProfile(
    String name,
    String className,
    String school,
    UserProfile profile,
  ) {
    setState(() {
      profile.name = name;
      profile.className = className;
      profile.school = school;
    });

    _updateProfileOnServer(name, className, school);
  }

  Widget _buildOverview(
    UserProfile profile,
    Map<String, String> lessonTitles,
    int totalLessons,
    Map<String, dynamic> allLessonsData,
  ) {
    final sortedLessons = profile.recentLessons.reversed.toList();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Learning suggestion
        _buildLearningSuggestion(profile.currentLevel),
        SizedBox(height: 12),
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

        ...sortedLessons.map((lessonId) {
          final lessonSearchResult = _findLessonInfo(lessonId, allLessonsData);
          final lessonInfo = lessonSearchResult['lessonInfo'];

          Map<String, dynamic>? completedLesson;
          if (profile.completedLessons.isNotEmpty) {
            completedLesson = profile.completedLessons.firstWhere(
              (l) => l['lessonId'] == lessonId,
              orElse: () => {},
            );
          } else {
            completedLesson = {};
          }

          final hasQuizData = completedLesson.isNotEmpty;
          final score = hasQuizData ? completedLesson['score'] ?? 0 : 0;
          final total = hasQuizData
              ? completedLesson['totalQuestions'] ?? 0
              : 0;
          final percentage = hasQuizData
              ? completedLesson['percentage'] ?? 0
              : 0;

          Color scoreColor;
          if (percentage >= 80) {
            scoreColor = Colors.green;
          } else if (percentage >= 60) {
            scoreColor = Colors.orange;
          } else {
            scoreColor = Colors.redAccent;
          }

          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  lessonInfo != null ? Icons.check_circle : Icons.error_outline,
                  color: lessonInfo != null ? primaryGreen : Colors.red,
                  size: 20,
                ),
              ),
              title: Text(
                lessonTitles[lessonId] ?? lessonId,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonInfo != null
                        ? 'Completed - Tap to view lesson'
                        : 'Lesson data not found',
                    style: TextStyle(
                      color: lessonInfo != null ? primaryGreen : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),

                  // ✅ Quiz score display
                  if (hasQuizData)
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: scoreColor, width: 1),
                          ),
                          child: Text(
                            'Score: $score/$total',
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No quiz taken yet',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: lessonInfo != null ? Colors.grey[400] : Colors.red[300],
              ),
              onTap: lessonInfo != null
                  ? () => _openLessonDetail(lessonId, lessonInfo)
                  : () => _showLessonNotFoundDialog(lessonId),
            ),
          );
        }),

        if (sortedLessons.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No lessons completed yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Start learning to see your progress here',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Map<String, dynamic> _findLessonInfo(
    String lessonId,
    Map<String, dynamic> curriculumData,
  ) {
    // Navigate through the curriculum structure: levels -> modules -> lessons
    for (String levelKey in curriculumData.keys) {
      final levelData = curriculumData[levelKey];

      if (levelData is Map<String, dynamic> &&
          levelData.containsKey('modules')) {
        final modules = levelData['modules'] as Map<String, dynamic>;

        for (String moduleKey in modules.keys) {
          final moduleData = modules[moduleKey];

          if (moduleData is Map<String, dynamic> &&
              moduleData.containsKey('lessons')) {
            final lessons = moduleData['lessons'] as Map<String, dynamic>;

            if (lessons.containsKey(lessonId)) {
              return {
                'lessonInfo': lessons[lessonId] as Map<String, dynamic>,
                'moduleKey': moduleKey,
                'levelKey': levelKey,
              };
            }
          }
        }
      }
    }

    return {'lessonInfo': null, 'moduleKey': null, 'levelKey': null};
  }

  void _openLessonDetail(String lessonKey, Map<String, dynamic> lessonInfo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LessonDetailScreen(lessonKey: lessonKey, lessonInfo: lessonInfo),
      ),
    );
  }

  void _showLessonNotFoundDialog(String lessonId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lesson Not Found'),
          content: Text(
            'Could not find lesson data for "$lessonId". This might be due to outdated data.',
          ),
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

  Widget _overviewCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssessmentScreen()),
                );
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

  Color? getColorbyLevel(String currentLevel) {
    if (currentLevel == 'Basic') {
      return Colors.green;
    } else if (currentLevel == 'Intermediate') {
      return Colors.orange;
    }
    return Colors.red;
  }
}
