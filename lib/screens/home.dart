import 'package:flutter/material.dart';
import 'package:K_Skill/assessment/assessment_screen.dart';
import 'package:K_Skill/screens/widgets/dictionary_widget.dart';
import 'package:K_Skill/screens/widgets/vocabulary_widget.dart';
import 'package:K_Skill/services/shared_prefs.dart';

class WelcomeBanner extends StatelessWidget {
  final String userName;
  final int? currentStreak;
  final VoidCallback? onTakeAssessment;

  const WelcomeBanner({
    Key? key,
    required this.userName,
    this.currentStreak,
    this.onTakeAssessment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop layout for wider screens
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                // Left side - Image
                Expanded(flex: 2, child: _buildImageSection()),
                const SizedBox(width: 24),
                // Right side - Content
                Expanded(flex: 3, child: _buildContentSection()),
              ],
            );
          } else {
            // Mobile layout - Single column
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildImageSection(),
                const SizedBox(height: 16),
                _buildContentSection(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'images/children.jpg',
          errorBuilder: (context, error, stackTrace) {
            // Fallback when image is not found
            return Container(
              // decoration: BoxDecoration(
              //   borderRadius: BorderRadius.circular(8),
              //   gradient: LinearGradient(
              //     colors: [Colors.blue.shade300, Colors.indigo.shade400],
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //   ),
              // ),
              child: const Center(
                child: Icon(Icons.assessment, size: 80, color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First row - Welcome message
        Text(
          'Welcome, $userName',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),

        // Streak indicator
        if (currentStreak != null)
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$currentStreak day streak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),

        // Second row - Subtitle
        Text(
          'Test your skills today',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // Third row - Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTakeAssessment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Take Assessment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// Updated HomeScreen with integrated WelcomeBanner
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  int? currentStreak;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await SharedPrefsService.getUserName();
    final streak = await SharedPrefsService.getUserStreak();
    setState(() {
      userName = name;
      currentStreak = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeBanner(
                userName: userName ?? 'User',
                currentStreak: currentStreak,
                onTakeAssessment: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssessmentScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Dictionary
              const DictionaryWidget(),
              const SizedBox(height: 24),

              // Vocabulary Section Title
              const Text(
                'Vocabulary Topics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Vocabulary Widget (fully responsive, includes its own title)
              VocabularyWidget(),

              const SizedBox(height: 80), // Bottom nav spacing
            ],
          ),
        ),
      ),
    );
  }
}
