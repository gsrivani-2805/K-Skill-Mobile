import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:K_Skill/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DictionaryWidget extends StatefulWidget {
  const DictionaryWidget({Key? key}) : super(key: key);

  @override
  State<DictionaryWidget> createState() => _DictionaryWidgetState();
}

class _DictionaryWidgetState extends State<DictionaryWidget>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final String baseUrl = ApiConfig.baseUrl;
  final FocusNode _focusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  Map<String, dynamic>? _data;
  bool _isLoading = false;
  String? _error;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.orange[400],
      end: Colors.orange[600],
    ).animate(_animationController);

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchWord() async {
    final word = _controller.text.trim();
    if (word.isEmpty) {
      setState(() => _error = "Please enter a word");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _data = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/dictionary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'word': word}),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['error'] != null) {
          setState(() => _error = json['error']);
        } else {
          setState(() => _data = json);
        }
      } else {
        setState(() => _error = "Failed to fetch data");
      }
    } catch (_) {
      setState(() => _error = "Network error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _play(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow[50]!, Colors.orange[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dictionary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    Text(
                      'Search for word meanings & translations',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Enhanced Search Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isFocused
                    ? [Colors.orange[100]!, Colors.yellow[100]!]
                    : [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused ? Colors.orange[400]! : Colors.grey[300]!,
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: _isFocused ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Search Icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.search_rounded,
                    color: _isFocused ? Colors.orange[600] : Colors.grey[500],
                    size: 24,
                  ),
                ),

                // Text Field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _searchWord(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: "Type a word to search...",
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 4,
                      ),
                    ),
                  ),
                ),

                // Clear Button
                if (_controller.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        _controller.clear();
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                // Search Button
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _animationController.forward().then((_) {
                                    _animationController.reverse();
                                  });
                                  _searchWord();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _colorAnimation.value ?? Colors.orange[500],
                            foregroundColor: Colors.white,
                            elevation: _isLoading ? 0 : 4,
                            shadowColor: Colors.orange.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "Search",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Results Section
          if (_error != null)
            _buildErrorCard(_error!)
          else if (_data != null)
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: _buildResultCard(),
            ),
        ],
      ),
    );
  }

  // Widget _buildEmptyState() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[50],
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Colors.grey[200]!),
  //     ),
  //     child: Column(
  //       children: [
  //         Icon(
  //           Icons.search_off_rounded,
  //           size: 48,
  //           color: Colors.grey[400],
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           'Start searching for words',
  //           style: TextStyle(
  //             fontSize: 16,
  //             color: Colors.grey[600],
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           'Enter a word above to get its meaning and translation',
  //           style: TextStyle(
  //             fontSize: 12,
  //             color: Colors.grey[500],
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.pink[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.teal[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word and Sound
          Row(
            children: [
              Expanded(
                child: Text(
                  _data!['word'] ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.green,
                  ),
                  onPressed: () => _play(_data!['word']),
                ),
              ),
            ],
          ),

          if (_data!['type'] != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _data!['type'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Phonetic Representation
          if (_data!['phonetic'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _data!['phonetic'],
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          if (_data!['definition'] != null)
            Text(
              _data!['definition'],
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

          if (_data!['example'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Example:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${_data!['example']}"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Translations
          if (_data!['telugu'] != null || _data!['hindi'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Translations:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (_data!['telugu'] != null)
                  _buildTranslationRow(
                    'Telugu',
                    _data!['telugu'],
                    Colors.purple,
                  ),
                if (_data!['hindi'] != null)
                  _buildTranslationRow('Hindi', _data!['hindi'], Colors.orange),
              ],
            ),

          if (_data!['example_sentence_translation'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telugu Translation:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _data!['example_sentence_translation'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTranslationRow(
    String language,
    String translation,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              language,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              translation,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
