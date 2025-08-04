import 'package:flutter/material.dart';
import 'package:K_Skill/config/api_config.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpeakingPractice extends StatefulWidget {
  @override
  _SpeakingPracticeState createState() => _SpeakingPracticeState();
}

class _SpeakingPracticeState extends State<SpeakingPractice>
    with TickerProviderStateMixin {
  // Speech and TTS instances
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // State variables
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSessionActive = false;
  bool _isSpeaking = false;
  String _userSpeech = '';
  String _currentResponse = '';
  List<Map<String, String>> _conversationHistory = [];

  // Groq API configurationstatic
  static final String _geminiApiKey = ApiConfig.geminiApiKey;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeTts();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);

    // Set completion handler to know when TTS is done
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    // Add error handler
    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speakText(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isSpeaking = true;
    });

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print("Error speaking text: $e");
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  // Manual start listening
  void _startListening() async {
    bool available = await _speech.initialize(
      onError: (error) {
        print("Speech recognition error: $error");
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech error: ${error.errorMsg}'),
            backgroundColor: Colors.red[400],
          ),
        );
      },
      onStatus: (status) {
        print("Speech recognition status: $status");
        if (status == 'notListening' && _isListening) {
          setState(() {
            _isListening = false;
          });
          _pulseController.stop();
          // Process the speech when listening stops
          if (_userSpeech.trim().isNotEmpty) {
            _processUserInput(_userSpeech);
          }
        }
      },
    );

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech recognition not available'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _userSpeech = '';
    });

    _pulseController.repeat(reverse: true);

    _speech.listen(
      onResult: (val) {
        setState(() {
          _userSpeech = val.recognizedWords;
        });
      },
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  // Manual stop listening
  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
    _pulseController.stop();

    if (_userSpeech.trim().isNotEmpty) {
      _processUserInput(_userSpeech);
    }
  }

  // Generate LLM response with focus on error correction and follow-up
Future<String> _generateLLMResponse(String userInput) async {
  try {
    // Add user input to conversation history
    _conversationHistory.add({'role': 'user', 'content': userInput});
    
    // Keep only last 6 messages to avoid token limits
    if (_conversationHistory.length > 6) {
      _conversationHistory = _conversationHistory.sublist(
        _conversationHistory.length - 6,
      );
    }

    // Prepare the system instruction for Gemini
    String systemInstruction = '''You are an English speaking tutor. Your job is to:
1. Analyze the user's speech for grammar, vocabulary, and pronunciation errors
2. If there are errors, gently correct them by providing the correct version
3. Always ask a follow-up question to continue the conversation
4. Keep responses under 40 words
5. Be encouraging and supportive
6. Focus on practical English improvement
Format your response as:
- First, acknowledge what they said
- Then, if needed, provide gentle corrections like "You could also say: [correct version]"
- Finally, ask an engaging follow-up question''';

    // Convert conversation history to Gemini format
    List<Map<String, dynamic>> geminiContents = [];
    
    for (var message in _conversationHistory) {
      String role = message['role'] == 'assistant' ? 'model' : 'user';
      geminiContents.add({
        'role': role,
        'parts': [
          {'text': message['content']}
        ]
      });
    }

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'contents': geminiContents,
        'generationConfig': {
          'maxOutputTokens': 100,
          'temperature': 0.8,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        String llmResponse = data['candidates'][0]['content']['parts'][0]['text'].trim();
        
        // Add LLM response to conversation history
        _conversationHistory.add({'role': 'assistant', 'content': llmResponse});
        
        return llmResponse;
      } else {
        throw Exception('No response generated from Gemini API');
      }
    } else {
      print('Gemini API Error: ${response.statusCode} - ${response.body}');
      throw Exception(
        'Failed to get response from Gemini API: ${response.statusCode}',
      );
    }
  } catch (e) {
    print('Error generating LLM response: $e');
    return 'Sorry, I encountered an error. Could you please repeat that?';
  }
}
  // Process user input and generate response
  void _processUserInput(String userInput) async {
    if (userInput.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _currentResponse = 'Analyzing your speech...';
    });

    try {
      String llmResponse = await _generateLLMResponse(userInput);

      setState(() {
        _currentResponse = llmResponse;
        _isProcessing = false;
      });

      // Small delay before speaking to ensure UI updates
      await Future.delayed(Duration(milliseconds: 500));

      // Speak the LLM response
      await _speakText(llmResponse);
    } catch (e) {
      print('Error processing user input: $e');
      setState(() {
        _currentResponse = 'Sorry, something went wrong. Please try again.';
        _isProcessing = false;
      });
      await _speakText('Sorry, something went wrong. Please try again.');
    }
  }

  // Start the conversation session
  void _startSession() async {
    setState(() {
      _isSessionActive = true;
      _conversationHistory.clear();
      _currentResponse =
          'Hello! I\'m your English tutor. Let\'s practice speaking together!';
      _userSpeech = '';
    });

    // Speak the welcome message when session starts
    await _speakText(
      'Hello! I\'m your English tutor. Let\'s practice speaking together!',
    );
  }

  // End the conversation session
  void _endSession() {
    setState(() {
      _isSessionActive = false;
      _isListening = false;
      _isProcessing = false;
      _isSpeaking = false;
      _currentResponse = 'Session ended. Tap "Start Session" to begin again.';
      _userSpeech = '';
      _conversationHistory.clear();
    });

    _speech.stop();
    _flutterTts.stop();
    _pulseController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Compact Status Bar
            Container(
              margin: EdgeInsets.all(12),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple[400]!, Colors.deepPurple[600]!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isListening
                              ? Icons.mic
                              : _isProcessing
                              ? Icons.psychology
                              : _isSpeaking
                              ? Icons.volume_up
                              : _isSessionActive
                              ? Icons.mic_none
                              : Icons.play_circle_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (_isSessionActive)
                    GestureDetector(
                      onTap: _endSession,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.stop, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    // User Speech Display (Only show when active)
                    if (_userSpeech.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.blue[700],
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'You:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              _userSpeech,
                              style: TextStyle(fontSize: 12, height: 1.2),
                            ),
                          ],
                        ),
                      ),

                    // AI Response Display
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.smart_toy,
                                  color: Colors.green[700],
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'AI Tutor:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  _currentResponse.isEmpty
                                      ? (!_isSessionActive
                                            ? 'Tap "Start Session" to begin practicing English speaking!'
                                            : 'Ready to help you practice English speaking...')
                                      : _currentResponse,
                                  style: TextStyle(fontSize: 12, height: 1.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Area
            Container(
              padding: EdgeInsets.all(16),
              child: !_isSessionActive
                  ? _buildFloatingStartButton()
                  : _buildFloatingMicButton(),
            ),
          ],
        ),
      ),
    );
  }

  // Floating Start Session Button
  Widget _buildFloatingStartButton() {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _startSession,
        icon: Icon(Icons.play_arrow, size: 20),
        label: Text(
          'Start Session',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[500],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // Optimized Microphone Button
  Widget _buildFloatingMicButton() {
    bool canTap = !(_isSpeaking || _isProcessing);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicators (more compact)
        if (_isListening || _isProcessing || _isSpeaking)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isListening
                  ? Colors.red[100]
                  : _isProcessing
                  ? Colors.orange[100]
                  : Colors.purple[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isListening
                    ? Colors.red[300]!
                    : _isProcessing
                    ? Colors.orange[300]!
                    : Colors.purple[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isListening)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (_isProcessing)
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.orange[700]!,
                      ),
                    ),
                  )
                else
                  Icon(Icons.volume_up, size: 8, color: Colors.purple[700]),
                SizedBox(width: 4),
                Text(
                  _isListening
                      ? 'Listening...'
                      : _isProcessing
                      ? 'Processing...'
                      : 'Speaking...',
                  style: TextStyle(
                    color: _isListening
                        ? Colors.red[700]
                        : _isProcessing
                        ? Colors.orange[700]
                        : Colors.purple[700],
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Main microphone button (smaller)
        GestureDetector(
          onTap: canTap
              ? (_isListening ? _stopListening : _startListening)
              : null,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [Colors.red[400]!, Colors.red[600]!]
                          : canTap
                          ? [Colors.blue[400]!, Colors.blue[600]!]
                          : [Colors.grey[400]!, Colors.grey[500]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isListening
                                    ? Colors.red
                                    : canTap
                                    ? Colors.blue
                                    : Colors.grey)
                                .withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (_isListening) return 'Listening...';
    if (_isProcessing) return 'Processing...';
    if (_isSpeaking) return 'AI Speaking...';
    if (_isSessionActive) return 'Ready to speak';
    return 'Tap Start Session';
  }

  @override
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
    _pulseController.dispose();
    super.dispose();
  }
}
