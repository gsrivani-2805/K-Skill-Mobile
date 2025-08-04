// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:async';

// Models
class VocabularyWord {
  final String word;
  final String pronunciation;
  final String definition;
  final List<String> sentences;

  VocabularyWord({
    required this.word,
    required this.pronunciation,
    required this.definition,
    required this.sentences,
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      word: json['word'],
      pronunciation: json['pronunciation'],
      definition: json['definition'],
      sentences: List<String>.from(json['sentences']),
    );
  }
}

class VocabularyTopic {
  final String title;
  final String icon;
  final List<VocabularyWord> words;

  VocabularyTopic({
    required this.title,
    required this.icon,
    required this.words,
  });

  factory VocabularyTopic.fromJson(Map<String, dynamic> json) {
    return VocabularyTopic(
      title: json['title'],
      icon: json['icon'],
      words: (json['words'] as List)
          .map((word) => VocabularyWord.fromJson(word))
          .toList(),
    );
  }
}

// Vocabulary Widget
class VocabularyWidget extends StatefulWidget {
  @override
  _VocabularyWidgetState createState() => _VocabularyWidgetState();
}

class _VocabularyWidgetState extends State<VocabularyWidget> {
  Map<String, VocabularyTopic> vocabularyData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVocabularyData();
  }

  Future<void> loadVocabularyData() async {
    try {
      final topicKeys = [
        'travel',
        'food',
        'technology',
        'education',
        'health',
        'family',
        'home',
        'shopping',
        'business',
        'science',
        'government',
        'arts',
        'sports',
        'nature',
        'entertainment',
        'transportation',
        'psychology',
        'economics',
        'history',
        'philosophy',
        'climate',
        'space',
        'agriculture',
        'digital',
      ];

      for (String key in topicKeys) {
        final jsonString = await rootBundle.loadString(
          'vocabulary/${key}.json',
        );
        final jsonData = json.decode(jsonString);
        vocabularyData[key] = VocabularyTopic.fromJson(jsonData);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading vocabulary data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.indigo.shade100],
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double screenWidth = constraints.maxWidth;
                        int crossAxisCount;

                        if (screenWidth >= 1000) {
                          crossAxisCount = 4;
                        } else if (screenWidth >= 700) {
                          crossAxisCount = 3;
                        } else {
                          crossAxisCount = 2;
                        }

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio:
                              3 /
                              2, // Responsive card height (adjust if needed)
                          children: vocabularyData.entries.map((entry) {
                            final key = entry.key;
                            final topic = entry.value;

                            return TopicCard(
                              topic: topic,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WordsListPage(
                                      topic: topic,
                                      topicKey: key,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// --- TopicCard ---
class TopicCard extends StatelessWidget {
  final VocabularyTopic topic;
  final VoidCallback onTap;

  const TopicCard({Key? key, required this.topic, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 100,
          maxWidth: isMobile ? 120 : 160,
        ),
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 8 : 12,
          horizontal: isMobile ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: isMobile ? 4 : 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                topic.icon,
                style: TextStyle(fontSize: isMobile ? 26 : 40),
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Flexible(
              child: Text(
                topic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              '${topic.words.length} words',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Words List Page
class WordsListPage extends StatelessWidget {
  final VocabularyTopic topic;
  final String topicKey;

  const WordsListPage({Key? key, required this.topic, required this.topicKey})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.only(
                  top: 12,
                  left: 12,
                  right: 12,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.indigo.shade600,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Spacer(),
                      ],
                    ),
                    Text(topic.icon, style: TextStyle(fontSize: 48)),
                    SizedBox(height: 6),
                    Text(
                      topic.title,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Click on any word to learn more',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Words List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: topic.words.length,
                  itemBuilder: (context, index) {
                    final word = topic.words[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: WordCard(
                        word: word,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordDetailPage(word: word),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WordCard ---
class WordCard extends StatelessWidget {
  final VocabularyWord word;
  final VoidCallback onTap;

  const WordCard({Key? key, required this.word, required this.onTap})
    : super(key: key);

  Future<void> _play(String text) async {
    final flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: isMobile ? 3 : 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Word and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (word.pronunciation.isNotEmpty)
                      Text(
                        word.pronunciation,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 16,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (word.definition.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          word.definition,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 16,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '${word.sentences.length} example sentences →',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 13,
                          color: Colors.indigo.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Volume icon at the right, always colored
              IconButton(
                icon: Icon(
                  Icons.volume_up,
                  color: Colors.indigo.shade600,
                  size: isMobile ? 20 : 25,
                ),
                onPressed: () => _play(word.word),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                tooltip: 'Play pronunciation',
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Word Detail Page
class WordDetailPage extends StatelessWidget {
  final VocabularyWord word;

  const WordDetailPage({Key? key, required this.word}) : super(key: key);

  Future<void> _play(String text) async {
    final flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.pink.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8,
                  vertical: isMobile ? 6 : 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.indigo.shade600,
                        size: isMobile ? 20 : 25,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Back to words',
                      style: TextStyle(
                        color: Colors.indigo.shade600,
                        fontSize: isMobile ? 15 : 22,
                      ),
                    ),
                  ],
                ),
              ),

              // Word Details
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(10),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Word and Pronunciation
                        Text(
                          word.word,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                word.pronunciation,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.volume_up,
                                color: Colors.indigo.shade600,
                                size: 25,
                              ),
                              onPressed: () => _play(word.word),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),

                        // Definition with markdown
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: MarkdownBody(
                            data: word.definition, // <-- supports **bold**
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            shrinkWrap: true,
                          ),
                        ),

                        SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Example Sentences',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),

                        SizedBox(height: 6),

                        ...word.sentences.map(
                          (sentence) => Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: Colors.blue.shade400,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: MarkdownBody(
                              data: sentence, // <-- supports **bold**
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              shrinkWrap: true,
                            ),
                          ),
                        ),
                      ],
                    ),
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
