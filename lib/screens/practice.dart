import 'dart:convert';

import 'package:K_Skill/screens/levels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:K_Skill/config/api_config.dart';
import 'package:K_Skill/screens/speaking.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  FlutterTts flutterTts = FlutterTts();

  String? token;

  String practiceMode = 'speaking';
  bool isRecording = false;
  bool isPlaying = false;
  final TextEditingController _chatController = TextEditingController();
  late stt.SpeechToText speech;
  List<String> listeningSentences = [];
  List<String> readingPassages = [];
  String? selectedPassage;
  String? selectedListeningSentence;
  final TextEditingController _listeningController = TextEditingController();
  String userTypedText = '';
  bool _showListeningResult = false;
  String _lastStableText = "";
  DateTime _lastUpdate = DateTime.now();

  static const baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

  String spokenText = '';
  bool isListening = false;

  final List<ChatMessage> chatMessages = [
    ChatMessage(
      text:
          "Hello! 👋 I'm your English tutor assistant. I'm here to help you excel in English!\n\n"
          "📚 **What I can help you with:**\n"
          "• Grammar rules and explanations\n"
          "• Vocabulary building & word meanings\n"
          "• Reading comprehension strategies\n"
          "• Writing techniques & essay tips\n"
          "• Literature analysis & themes\n"
          "• Poetry understanding & interpretation\n"
          "• Pronunciation guidance\n"
          "• Language usage & style\n\n"
          "💡 **Just ask me anything about English!**\n"
          "For example: \"Explain the difference between 'affect' and 'effect'\" or \"Help me analyze this poem.\"",
      isUser: false,
      suggestions: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Practice Zone'),
        backgroundColor: Colors.lightGreen,
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              // child: Text(
              //   'Practice Zone 🎯',
              //   style: TextStyle(
              //     fontSize: 26,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.deepPurple,
              //   ),
              // ),
            ),
            _buildPracticeModeSelector(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: _getPracticeContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeModeSelector() {
    final modes = [
      PracticeMode(
        key: 'speaking',
        icon: Icons.mic,
        label: 'Speaking',
        color: Colors.orange,
      ),
      PracticeMode(
        key: 'listening',
        icon: Icons.headphones,
        label: 'Listening',
        color: Colors.green,
      ),
      PracticeMode(
        key: 'reading',
        icon: Icons.menu_book,
        label: 'Reading',
        color: Colors.blue,
      ),
      PracticeMode(
        key: 'conversation',
        icon: Icons.chat_bubble_outline,
        label: 'Chat',
        color: Colors.purpleAccent,
      ),
    ];

    return SizedBox(
      height: 77,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final mode = modes[index];
          final isSelected = practiceMode == mode.key;
          return GestureDetector(
            onTap: () {
              setState(() {
                practiceMode = mode.key;
                if (mode.key == 'reading') {
                  loadReadingPassages();
                }
                if (mode.key == 'listening') {
                  loadListeningSentences();
                }
              });
            },
            child: Container(
              width: 77,
              decoration: BoxDecoration(
                color: isSelected
                    ? mode.color.withOpacity(0.9)
                    : mode.color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(mode.icon, color: Colors.white, size: 30),
                  const SizedBox(height: 6),
                  Text(
                    mode.label,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getPracticeContent() {
    switch (practiceMode) {
      case 'speaking':
        return SpeakingPractice();
      case 'listening':
        return selectedListeningSentence == null
            ? _buildPlaceholder('Loading listening content...')
            : _buildListeningPractice();

      case 'reading':
        return selectedPassage == null
            ? _buildPlaceholder('Loading passage...')
            : _buildReadingPractice();
      case 'conversation':
        return _buildChatUI();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              final msg = chatMessages[index];
              return Align(
                alignment: msg.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: msg.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // 💬 Chat bubble + Suggestions inside
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? Colors.grey[200]
                            : Colors.purpleAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI Response text
                          MarkdownBody(
                            data: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 14,
                                color: msg.isUser ? Colors.black : Colors.white,
                              ),
                            ),
                          ),

                          // 📘 Suggestions inside bubble
                          if (!msg.isUser &&
                              msg.suggestions != null &&
                              msg.suggestions!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              "👉 For more information, refer to these lessons:",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: msg.suggestions!.map((lesson) {
                                return ActionChip(
                                  backgroundColor: Colors.white,
                                  label: Text(
                                    lesson["title"],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LessonDetailScreen(
                                              lessonKey: lesson["lessonId"],
                                              lessonInfo: lesson,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  fillColor: Colors.grey[100],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.purpleAccent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ],
    );
  }

  void _sendMessage() async {
    final userMessage = _chatController.text.trim();

    if (userMessage.isEmpty) return;

    setState(() {
      chatMessages.add(
        ChatMessage(text: userMessage, isUser: true, suggestions: null),
      );
      _chatController.clear();
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/chat"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final responseData = body['data'];
        final aiReply = responseData["response"];

        setState(() {
          chatMessages.add(
            ChatMessage(
              text: aiReply,
              isUser: false,
              suggestions: (responseData["suggestions"] as List?)
                  ?.cast<Map<String, dynamic>>(),
            ),
          );
        });
      } else {
        setState(() {
          chatMessages.add(
            ChatMessage(
              text:
                  "Oops! There was a problem getting a response. Please try again later.",
              isUser: false,
              suggestions: null,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        chatMessages.add(
          ChatMessage(
            text: "Something went wrong: ${e.toString()}",
            isUser: false,
            suggestions: null,
          ),
        );
      });
    }
  }

  Future<void> loadReadingPassages() async {
    final jsonStr = await rootBundle.loadString(
      'data/practice/reading_passages.json',
    );
    final data = json.decode(jsonStr);
    readingPassages = List<String>.from(data['passages']);

    setState(() {
      selectedPassage = (readingPassages..shuffle()).first;
    });
  }

  Future<void> startListening() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }

    bool available = await speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'notListening' && isListening) {
          setState(() => isListening = false);
        }
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        setState(() => isListening = false);
      },
    );

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() {
      isListening = true;
      spokenText = "";
      _lastStableText = "";
      _lastUpdate = DateTime.now();
    });

    speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: false,
      onResult: (result) {
        final current = result.recognizedWords.trim();

        // Ignore if flutter web sends the SAME sentence twice
        if (current == _lastStableText) return;

        // Debounce (avoid processing too fast)
        if (DateTime.now().difference(_lastUpdate).inMilliseconds < 300) return;

        _lastUpdate = DateTime.now();

        // Only append NEW text beyond previous transcript
        String cleanedCurrent = current.toLowerCase();
        String cleanedLast = _lastStableText.toLowerCase();

        if (cleanedCurrent.startsWith(cleanedLast)) {
          // Only add new part
          String newPart = cleanedCurrent.substring(cleanedLast.length).trim();

          if (newPart.isNotEmpty) {
            setState(() {
              spokenText = (_lastStableText + " " + newPart).trim();
              _lastStableText = spokenText;
            });
          }
        } else {
          // If mismatch, overwrite (rare browser glitch)
          setState(() {
            spokenText = cleanedCurrent;
            _lastStableText = cleanedCurrent;
          });
        }
      },
    );
  }

  void stopListening() {
    speech.stop();
    setState(() {
      isListening = false;
      _lastUpdate = DateTime.now();
    });
  }

  double calculateSimilarity(String original, String spoken) {
    return StringSimilarity.compareTwoStrings(
      original.toLowerCase(),
      spoken.toLowerCase(),
    );
  }

  Widget _buildReadingPractice() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Read this aloud:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Text(
              selectedPassage ?? 'Loading...',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isListening ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isListening ? Colors.red[300]! : Colors.green[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isListening
                      ? Icons.fiber_manual_record
                      : Icons.check_circle_outline,
                  color: isListening ? Colors.red : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isListening ? 'Listening...' : 'Ready to listen',
                  style: TextStyle(
                    color: isListening ? Colors.red[700] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  isListening ? stopListening() : startListening();
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening ? Colors.red : Colors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? Colors.red : Colors.blue)
                            .withOpacity(0.3),
                        spreadRadius: isListening ? 8 : 4,
                        blurRadius: 15,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Icon(Icons.mic, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isListening ? 'Tap to Stop' : 'Tap to Start Speaking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isListening ? Colors.red[700] : Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isListening && spokenText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hearing, color: Colors.orange[700], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'What I\'m hearing:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    spokenText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          if (isListening && spokenText.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[25],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Listening for your voice...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (!isListening && spokenText.isNotEmpty) _buildReadingResultCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String getReadingEncouragingMessage(double score) {
    if (score >= 0.9) return "Outstanding! You're reading like a pro! 🌟";
    if (score >= 0.75) return "Great job! Just a little more polish 💪";
    if (score >= 0.5) return "Good effort! Keep practicing! 😊";
    return "Don't worry! Try again and you’ll get better! 🚀";
  }

  Color getScoreColor(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.75) return Colors.lightGreen;
    if (score >= 0.5) return Colors.orange;
    return Colors.redAccent;
  }

  Widget _buildReadingResultCard() {
    final score = calculateSimilarity(selectedPassage ?? '', spokenText);
    final percentage = (score * 100).toStringAsFixed(1);
    final message = getReadingEncouragingMessage(score);
    final color = getScoreColor(score);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Similarity Score: $percentage%",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: score.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    spokenText = '';
                    selectedPassage = (readingPassages..shuffle()).first;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  overlayColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
                label: const Text(
                  "Next",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadListeningSentences() async {
    final jsonStr = await rootBundle.loadString(
      'data/practice/listening_sentences.json',
    );
    final data = json.decode(jsonStr);
    listeningSentences = List<String>.from(data['sentences']);
    setState(() {
      selectedListeningSentence = (listeningSentences..shuffle()).first;
      _listeningController.clear();
      userTypedText = '';
    });
  }

  Future<void> playSentence() async {
    if (selectedListeningSentence != null) {
      await flutterTts.setLanguage("en-IN");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(selectedListeningSentence!);
    }
  }

  double calculateListeningSimilarity(String original, String spoken) {
    return StringSimilarity.compareTwoStrings(
      original.toLowerCase(),
      spoken.toLowerCase(),
    );
  }

  String getListeningEncouragingMessage(double score) {
    if (score >= 0.9) return "Fantastic! Your listening is spot on! 🎧";
    if (score >= 0.75) return "Great job! Just a bit more clarity! 👏";
    if (score >= 0.5) return "Good effort! Listen carefully and try again. 😊";
    return "Keep practicing! You'll improve quickly! 🚀";
  }

  Widget _buildListeningPractice() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap the button to listen to the sentence:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              onPressed: playSentence,
              icon: const Icon(Icons.play_arrow, size: 24, color: Colors.white),
              label: const Text("Play Audio"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _listeningController,
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                userTypedText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Type what you heard...',
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (userTypedText.isNotEmpty)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showListeningResult = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Submit"),
              ),
            ),
          const SizedBox(height: 16),
          if (_showListeningResult) _buildListeningResultCard(),
        ],
      ),
    );
  }

  Widget _buildListeningResultCard() {
    final score = calculateListeningSimilarity(
      selectedListeningSentence ?? '',
      userTypedText,
    );
    final percentage = (score * 100).toStringAsFixed(1);
    final message = getListeningEncouragingMessage(score);
    final color = getScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Similarity Score: $percentage%",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              loadListeningSentences();
              setState(() {
                _showListeningResult = false;
              });
            },

            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              "Practice Again",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PracticeMode {
  final String key;
  final IconData icon;
  final String label;
  final Color color;

  PracticeMode({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<Map<String, dynamic>>? suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.suggestions,
  });
}
