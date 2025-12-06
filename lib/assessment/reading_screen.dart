import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _userSpeech = '';

  List<String> _passages = [];
  int _currentPassageIndex = 0;
  final List<double> _scores = [];

  bool _loading = true;
  String? _loadError;
  bool _finished = false;
  double _finalScore = 0.0;

  final Color primaryColor = const Color(0xFF2196F3);
  final Color accentColor = const Color(0xFF1565C0);
  final Color lightBlue = const Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    loadPassages();
  }

  Future<void> loadPassages() async {
    try {
      final jsonString = await rootBundle.loadString(
        'data/assessment/reading_passage.json',
      );
      final data = json.decode(jsonString);

      final List<dynamic> levels = data['reading_passages'];
      final random = Random();

      List<String> selected = [];

      for (final level in ['Easy', 'Medium', 'Hard']) {
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
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = 'Failed to load reading passages.';
      });
    }
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
          setState(() => _isListening = false);
        }
      },
      onError: (err) => debugPrint('Speech error: $err'),
    );

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

    await _speech.listen(
      onResult: (val) {
        setState(() => _userSpeech = val.recognizedWords.trim());
      },
      partialResults: false,
      cancelOnError: true,
      pauseFor: const Duration(seconds: 5),
      listenMode: stt.ListenMode.dictation,
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _submitCurrentPassage() {
    final original = _passages[_currentPassageIndex]
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .toLowerCase()
        .trim();

    final spoken = _userSpeech
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .toLowerCase()
        .trim();

    final similarity = StringSimilarity.compareTwoStrings(original, spoken);
    _scores.add(similarity);

    if (_currentPassageIndex < _passages.length - 1) {
      setState(() {
        _currentPassageIndex++;
        _userSpeech = '';
        _isListening = false;
      });
    } else {
      final avg = _scores.reduce((a, b) => (a + b)) / _scores.length;
      setState(() {
        _finished = true;
        _finalScore = avg;
      });
    }
  }

  void _submitScoreAndContinue() {
    Navigator.pop(context, {
      "type": "reading",
      "done": true,
      "score": (_finalScore * 100).toInt(),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/listening');
    });
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _finished ? _buildResultScreen() : _buildPassageScreen(),
    );
  }

  Widget _buildPassageScreen() {
    return SingleChildScrollView(
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

          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SingleChildScrollView(
              child: Text(
                _passages[_currentPassageIndex],
                style: const TextStyle(fontSize: 16, height: 1.4),
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
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 150),
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: SingleChildScrollView(
              child: Text(
                _userSpeech.isEmpty ? "Waiting for input..." : _userSpeech,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _userSpeech.isNotEmpty && !_isListening
                ? _submitCurrentPassage
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              _currentPassageIndex < _passages.length - 1
                  ? "Next Passage"
                  : "Finish Assessment",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 80, color: accentColor),
              const SizedBox(height: 20),

              Text(
                'Reading Completed!',
                style: TextStyle(
                  fontSize: 24,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Your Score',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${(_finalScore * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Text(
                      "Next: Listening Practice",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _submitScoreAndContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Continue to Listening"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
