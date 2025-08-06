import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:string_similarity/string_similarity.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});
  @override
  _ListeningScreenState createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  List<Map<String, String>> _selectedSentences = [];
  int _currentIndex = 0;
  List<double> _scores = [];

  bool _loading = true;
  String? _loadError;
  bool _submitted = false;
  double _finalScore = 0.0;

  // 🎨 Color theme from reference image
  final Color primaryColor = Colors.lightGreen; // Green
  final Color secondaryColor = Colors.green;
  final Color accentColor = const Color(0xFFFFD700); // Bright Yellow
  final Color warningColor = const Color(0xFFEF5B25); // Vivid Orange
  final Color backgroundColor = const Color(0xFFF6F9FF); // Soft Light Blue
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    loadListeningData();
  }

  Future<void> loadListeningData() async {
    try {
      final String response = await rootBundle.loadString(
        'data/assessment/listening_sentence.json',
      );
      final data = json.decode(response);
      final List<dynamic> levels = data['listening_sentences'];

      final random = Random();
      _selectedSentences = levels.map<Map<String, String>>((levelData) {
        final sentences = levelData['sentences'] as List;
        final sentence = sentences[random.nextInt(sentences.length)];
        return {'level': levelData['level'], 'text': sentence['text']};
      }).toList();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load listening data';
        _loading = false;
      });
    }
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  // void _submitText() {
  //   final typed = _controller.text.trim().toLowerCase();
  //   final original = _selectedSentences[_currentIndex]['text']!
  //       .trim()
  //       .toLowerCase();

  //   // You can replace this logic with a better similarity function later
  //   final typedWords = typed.split(RegExp(r'\s+'));
  //   final originalWords = original.split(RegExp(r'\s+'));

  //   int matched = 0;
  //   for (int i = 0; i < originalWords.length && i < typedWords.length; i++) {
  //     if (originalWords[i] == typedWords[i]) matched++;
  //   }

  //   double score = (matched / originalWords.length) * 100;
  //   _scores.add(score);

  //   if (_currentIndex < _selectedSentences.length - 1) {
  //     setState(() {
  //       _currentIndex++;
  //       _controller.clear();
  //       _submitted = false;
  //     });
  //   } else {
  //     setState(() {
  //       _submitted = true;
  //       _finalScore = _scores.reduce((a, b) => a + b) / _scores.length;
  //     });
  //   }
  // }

  void _submitText() {
    final typed = _controller.text.trim().toLowerCase();
    final original = _selectedSentences[_currentIndex]['text']!
        .trim()
        .toLowerCase();

    // Use string similarity instead of word-by-word comparison
    final similarity = StringSimilarity.compareTwoStrings(typed, original);
    final score = similarity * 100; // Scale to percentage

    _scores.add(score);

    if (_currentIndex < _selectedSentences.length - 1) {
      setState(() {
        _currentIndex++;
        _controller.clear();
        _submitted = false;
      });
    } else {
      setState(() {
        _submitted = true;
        _finalScore = _scores.reduce((a, b) => a + b) / _scores.length;
      });
    }
  }

  Widget _buildResultScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 5,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headphones, size: 80, color: accentColor),
                  const SizedBox(height: 20),
                  Text(
                    'Your Listening Score',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    '${_finalScore.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, _finalScore.toInt()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Back to Assessment'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listening Assessment')),
        body: Center(child: Text(_loadError!)),
      );
    }

    if (_submitted) return _buildResultScreen();

    final currentSentence = _selectedSentences[_currentIndex];
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Listening Assessment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Sentence ${_currentIndex + 1} of ${_selectedSentences.length}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _speakText(currentSentence['text']!),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Play Sentence'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '📝 Type what you heard:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: warningColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(14),
                          hintText: 'Type here...',
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _controller.text.trim().isNotEmpty
                          ? _submitText
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                      ),
                      child: Text(
                        _currentIndex < _selectedSentences.length - 1
                            ? 'Next Sentence'
                            : 'Finish Listening',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
