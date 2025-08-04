import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:K_Skill/config/api_config.dart';
import 'package:K_Skill/screens/speaking.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  FlutterTts flutterTts = FlutterTts();

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
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isUser ? Colors.grey[200] : Colors.purpleAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 14,
                        color: msg.isUser ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
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
      chatMessages.add(ChatMessage(text: userMessage, isUser: true));
      _chatController.clear();
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final aiReply = responseData["response"];

        setState(() {
          chatMessages.add(ChatMessage(text: aiReply, isUser: false));
        });
      } else {
        setState(() {
          chatMessages.add(
            ChatMessage(
              text:
                  "Oops! There was a problem getting a response. Please try again later.",
              isUser: false,
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

    print("Loaded passages: $readingPassages");

    setState(() {
      selectedPassage = (readingPassages..shuffle()).first;
    });
  }

  Future<void> startListening() async {
    bool available = await speech.initialize();
    if (available) {
      setState(() => isListening = true);
      speech.listen(
        onResult: (result) {
          setState(() => spokenText = result.recognizedWords);
        },
      );
    }
  }

  void stopListening() {
    setState(() => isListening = false);
    speech.stop();
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              selectedPassage ?? 'Loading...',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: IconButton(
              icon: Icon(
                isListening ? Icons.mic_off : Icons.mic,
                size: 36,
                color: Colors.blue,
              ),
              onPressed: () {
                isListening ? stopListening() : startListening();
              },
            ),
          ),
          const SizedBox(height: 10),

          if (!isListening && spokenText.isNotEmpty) _buildReadingResultCard(),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  "Practice Again",
                  style: TextStyle(fontSize: 14),
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
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
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
              icon: const Icon(Icons.play_arrow, size: 24),
              label: const Text("Play Audio"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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

            icon: const Icon(Icons.refresh),
            label: const Text("Practice Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
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

  ChatMessage({required this.text, required this.isUser});
}

// class TalkTutor extends StatefulWidget {
//   const TalkTutor({Key? key}) : super(key: key);

//   @override
//   State<TalkTutor> createState() => _TalkTutorState();
// }

// class _TalkTutorState extends State<TalkTutor> {
//   final stt.SpeechToText speech = stt.SpeechToText();
//   final FlutterTts tts = FlutterTts();

//   bool isListening = false;
//   bool botSpeaking = false;

//   String conversationContext = "";
//   List<Map<String, String>> conversation = [];
//   String currentBotMessage = "";
//   String currentUserMessage = "";

//   @override
//   void initState() {
//     super.initState();
//     _startSession();
//   }

//   Future<void> _startSession() async {
//     conversation.clear();
//     conversationContext = "";
//     _sendGreeting();
//   }

//   Future<void> _sendGreeting() async {
//     const botGreeting =
//         "Hi there! I'm your English tutor. What's your name and what do you like to do?";

//     await _speakBot(botGreeting); // Only speak the final greeting
//     setState(() {
//       conversation.add({
//         "role": "bot",
//         "message": botGreeting, // Show only the greeting message in UI
//       });
//     });
//   }

//   Future<void> _speakBot(String text) async {
//     setState(() => botSpeaking = true);
//     await tts.setLanguage("en-US");
//     await tts.setSpeechRate(0.5);
//     await tts.speak(text);
//     await Future.delayed(const Duration(milliseconds: 500));
//     setState(() => botSpeaking = false);
//   }

//   Future<void> _startListening() async {
//     var available = await speech.initialize();
//     if (available) {
//       setState(() => isListening = true);
//       speech.listen(
//         onResult: (val) {
//           setState(
//             () => currentUserMessage = val.recognizedWords,
//             //currentUserMessage = "Hi my name is Srivani. I like to play cricket and watch movies.",
//           );
//         },
//       );
//     }
//   }

//   void _stopListening() {
//     speech.stop();
//     setState(() => isListening = false);
//     if (currentUserMessage.trim().isNotEmpty) {
//       conversation.add({"role": "user", "message": currentUserMessage});
//       conversationContext += "Student: $currentUserMessage\n";
//       _getBotResponse(currentUserMessage);
//       currentUserMessage = "";
//     }
//   }

//   Future<void> _getBotResponse(String userInput) async {
//     const conversationPrompt = """
// You are an encouraging English speaking tutor having a natural conversation.

// Conversation so far:
// "{context}"

// The student just said: "{user_text}"

// Your response should:
// 1. If there are grammar errors, gently correct them by saying "You could say..." followed by the correct version
// 2. If the sentence is grammatically correct, acknowledge it positively
// 3. If there are better word choices, suggest them naturally: "Another way to say this would be..."
// 4. Ask a follow-up question to keep the conversation flowing naturally
// 5. Be conversational and supportive, not lecture-like
// 6. Keep response under 70 words for natural speech
// 7. Focus on ONE main correction at a time, don't overwhelm
// """;

//     final prompt = conversationPrompt
//         .replaceAll("{context}", conversationContext)
//         .replaceAll("{user_text}", userInput);

//     try {
//       final response = await http.post(
//         Uri.parse("http://localhost:8080/correct"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"prompt": prompt}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final botReply = data['response'];

//         setState(() {
//           conversation.add({"role": "bot", "message": botReply});
//           conversationContext += "Tutor: $botReply\n";
//         });

//         _speakBot(botReply);
//       } else {
//         setState(() {
//           conversation.add({
//             "role": "bot",
//             "message": "Sorry, I couldn't process that right now.",
//           });
//         });
//       }
//     } catch (e) {
//       conversation.add({
//         "role": "bot",
//         "message": "Error connecting to server: $e",
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   const Text(
//                     "TalkTutor 🤖",
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.deepPurple,
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.stop),
//                     label: const Text("Stop Session"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.redAccent,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: conversation.length,
//                 itemBuilder: (context, index) {
//                   final msg = conversation[index];
//                   final isBot = msg['role'] == "bot";
//                   return Align(
//                     alignment: isBot
//                         ? Alignment.centerLeft
//                         : Alignment.centerRight,
//                     child: Container(
//                       padding: const EdgeInsets.all(12),
//                       margin: const EdgeInsets.symmetric(vertical: 6),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: isBot ? Colors.blue[100] : Colors.green[100],
//                       ),
//                       child: Icon(
//                         isBot ? Icons.smart_toy : Icons.person,
//                         size: 30,
//                         color: isBot ? Colors.blue[800] : Colors.green[800],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Bot Speaking Indicator
//             if (botSpeaking)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 20),
//                 child: Icon(Icons.volume_up, size: 40, color: Colors.blue),
//               ),

//             // Mic Button
//             Padding(
//               padding: const EdgeInsets.only(bottom: 20),
//               child: GestureDetector(
//                 onTap: () => isListening ? _stopListening() : _startListening(),
//                 child: CircleAvatar(
//                   radius: 40,
//                   backgroundColor: isListening ? Colors.red : Colors.blue,
//                   child: Icon(
//                     isListening ? Icons.mic_off : Icons.mic,
//                     size: 30,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
