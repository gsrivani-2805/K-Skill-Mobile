import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:K_Skill/models/quiz_question_model.dart';
import 'package:K_Skill/screens/widgets/quiz_card_widget.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> allQuestions = [];
  List<QuizQuestion> selectedQuestions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isQuizCompleted = false;
  bool isLoading = true;
  String? errorMessage;
  int questionsToSelect = 10;

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

      final String jsonString = await rootBundle.loadString(
        'data/assessment/quiz_questions.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> quizLevels = jsonMap['grammar_quiz'];

      List<QuizQuestion> loadedQuestions = [];

      for (var levelGroup in quizLevels) {
        String level = levelGroup['level'];
        List<dynamic> questions = levelGroup['questions'];

        for (var q in questions) {
          q['level'] = level; // add level info manually
          loadedQuestions.add(QuizQuestion.fromJson(q));
        }
      }

      allQuestions = loadedQuestions;
      _selectRandomQuestions();
      setState(() => isLoading = false);
    } catch (e) {
      print('Error parsing quiz JSON: $e');
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load quiz questions.";
      });
    }
  }

  void _selectRandomQuestions() {
    if (allQuestions.isEmpty) return;

    final Map<String, List<QuizQuestion>> groupedByLevel = {
      'Easy': [],
      'Medium': [],
      'Hard': [],
    };

    for (var q in allQuestions) {
      groupedByLevel[q.level]?.add(q);
    }

    final random = Random();
    List<QuizQuestion> selected = [];

    List<QuizQuestion> pickRandom(List<QuizQuestion> list, int count) {
      list.shuffle(random);
      return list.take(count.clamp(0, list.length)).toList();
    }

    selected.addAll(pickRandom(groupedByLevel['Easy']!, 10));
    selected.addAll(pickRandom(groupedByLevel['Medium']!, 10));
    selected.addAll(pickRandom(groupedByLevel['Hard']!, 5));

    setState(() {
      selectedQuestions = selected;
    });
  }

  void handleAnswerSelected(String selectedAnswer) {
    if (selectedAnswer ==
        selectedQuestions[currentQuestionIndex].correctAnswer) {
      score++;
    }

    if (currentQuestionIndex < selectedQuestions.length - 1) {
      setState(() => currentQuestionIndex++);
    } else {
      setState(() => isQuizCompleted = true);
    }
  }

  void _submitScoreAndExit() {
    Navigator.pop(context, score);
  }

  Widget _buildResultScreen() {
    final percentage = (score / selectedQuestions.length) * 100;
    String message;
    Color color;

    if (percentage >= 90) {
      message = "Excellent! 🌟";
      color = Colors.green;
    } else if (percentage >= 70) {
      message = "Good job! 👍";
      color = Colors.blue;
    } else if (percentage >= 50) {
      message = "Keep practicing! ✍️";
      color = Colors.orange;
    } else {
      message = "Don't give up! 💪";
      color = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Result", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFFA500), // Orange
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "You scored $score / ${selectedQuestions.length}",
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  "Percentage: ${percentage.toStringAsFixed(1)}%",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submitScoreAndExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Back to Assessment",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingScreen();
    if (errorMessage != null) return _buildErrorScreen();
    if (isQuizCompleted) return _buildResultScreen();

    final currentQuestion = selectedQuestions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA500),
        title: Text(
          "Question ${currentQuestionIndex + 1} / ${selectedQuestions.length}",
          style: const TextStyle(color: Colors.white),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16),
        //     child: Center(
        //       child: Text(
        //         "Score: $score",
        //         style: const TextStyle(color: Colors.white),
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / selectedQuestions.length,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA500)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QuizCardWidget(
                question: currentQuestion.question,
                options: currentQuestion.options,
                correctAnswer: currentQuestion.correctAnswer,
                onAnswerSelected: handleAnswerSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Color(0xFFFFA500))),
  );

  Widget _buildErrorScreen() => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Error loading quiz',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadQuestionsFromJson,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
            ),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
