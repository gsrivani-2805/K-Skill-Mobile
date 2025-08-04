import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});
  @override
  _ReadingScreenState createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _userSpeech = '';
  List<String> _passages = [];
  int _currentPassageIndex = 0;
  List<double> _scores = [];
  bool _loading = true;
  String? _loadError;
  bool _finished = false;
  double _finalScore = 0.0;

  // UI Theme Colors (matched to your reference image)
  final Color primaryColor = Color(0xFF2196F3); // AppBar blue
  final Color accentColor = Color(0xFF1565C0); // Dark blue
  final Color lightBlue = Color(0xFFE3F2FD); // Light background

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    loadPassages();
  }

  Future<void> loadPassages() async {
    try {
      final String response = await rootBundle.loadString(
        'data/assessment/reading_passage.json',
      );
      final data = json.decode(response);
      final List<dynamic> levels = data['reading_passages'];

      List<String> selected = [];
      final random = Random();

      for (String level in ['Easy', 'Medium', 'Hard']) {
        final levelData = levels.firstWhere(
          (l) => l['level'] == level,
          orElse: () => null,
        );
        if (levelData != null &&
            levelData['paragraphs'] != null &&
            levelData['paragraphs'].isNotEmpty) {
          final paragraphs = levelData['paragraphs'];
          final randomParagraph =
              paragraphs[random.nextInt(paragraphs.length)]['text'];
          selected.add(randomParagraph);
        }
      }

      setState(() {
        _passages = selected;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _loadError = 'Failed to load reading passages.';
      });
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }
    setState(() {
      _isListening = true;
      _userSpeech = '';
    });

    _speech.listen(
      onResult: (val) {
        setState(() => _userSpeech = val.recognizedWords);
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _submitCurrentPassage() {
    final original = _passages[_currentPassageIndex]
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .toLowerCase();

    final spoken = _userSpeech
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .toLowerCase();

    // Use string similarity (returns value from 0 to 1)
    double similarity = StringSimilarity.compareTwoStrings(original, spoken);
    double score = similarity;
    _scores.add(score);

    print("Original: $original");
    print("Spoken: $spoken");
    print("Similarity Score: $score");

    if (_currentPassageIndex < _passages.length - 1) {
      setState(() {
        _currentPassageIndex++;
        _userSpeech = '';
        _isListening = false;
      });
    } else {
      double avg = _scores.reduce((a, b) => a + b) / _scores.length;
      setState(() {
        _finished = true;
        _finalScore = avg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Reading Assessment"),
          backgroundColor: primaryColor,
        ),
        body: Center(child: Text(_loadError!)),
      );
    }

    return Scaffold(
      backgroundColor: lightBlue,
      appBar: AppBar(
        title: Text(_finished ? "Reading Completed" : "Reading Assessment"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: _finished
          ? _buildResultScreen()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passage ${_currentPassageIndex + 1} of ${_passages.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200, // Set desired height
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _passages[_currentPassageIndex],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4, // Better line spacing
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isListening ? "Stop Reading" : "Start Reading",
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '🗣️ You said:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Text(
                      _userSpeech.isNotEmpty
                          ? _userSpeech
                          : 'Waiting for input...',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _userSpeech.isNotEmpty
                        ? _submitCurrentPassage
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      _currentPassageIndex < _passages.length - 1
                          ? 'Next Passage'
                          : 'Finish Assessment',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      backgroundColor: lightBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 100, color: accentColor),
            const SizedBox(height: 20),
            Text(
              'Your Score',
              style: TextStyle(
                fontSize: 24,
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(_finalScore * 100).toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, (_finalScore * 100).toInt()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text('Back to Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}
