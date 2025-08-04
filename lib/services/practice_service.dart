import 'dart:convert';
import 'package:http/http.dart' as http;

class SpeakingPracticeService {
  static const String _baseUrl = 'http://localhost:8080'; 
  
  static const Duration _timeout = Duration(seconds: 10);

  /// Analyzes user speech and returns corrections and follow-up response
  static Future<SpeechAnalysisResult> analyzeSpeech({
    required String userInput,
    required List<Map<String, dynamic>> conversationHistory,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/analyze-speech'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'userInput': userInput,
              'conversationHistory': conversationHistory,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SpeechAnalysisResult.fromJson(data);
      } else {
        throw SpeakingPracticeException(
          'Server error: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is SpeakingPracticeException) {
        rethrow;
      }
      throw SpeakingPracticeException(
        'Network error: Unable to connect to the server',
        e.toString(),
      );
    }
  }

  /// Gets dynamic conversation starter based on time of day
  static Future<ConversationStarter> getConversationStarter() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/conversation-starter'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ConversationStarter(
          topic: data['timeOfDay'] ?? 'general',
          question: data['welcomeMessage'] ?? 'How are you today?',
        );
      } else {
        throw SpeakingPracticeException(
          'Server error: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is SpeakingPracticeException) {
        rethrow;
      }
      throw SpeakingPracticeException(
        'Network error: Unable to fetch conversation starter',
        e.toString(),
      );
    }
  }

  /// Analyzes conversation context for insights
  static Future<ConversationContext> analyzeContext({
    required List<Map<String, dynamic>> conversationHistory,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/analyze-context'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'conversationHistory': conversationHistory,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ConversationContext.fromJson(data);
      } else {
        throw SpeakingPracticeException(
          'Server error: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is SpeakingPracticeException) {
        rethrow;
      }
      throw SpeakingPracticeException(
        'Network error: Unable to analyze context',
        e.toString(),
      );
    }
  }

  /// Health check to verify server connectivity
  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Result model for speech analysis with context
class SpeechAnalysisResult {
  final String response;
  final List<SpeechCorrection> corrections;
  final int grammarScore;
  final String overallFeedback;
  final ConversationContextInfo context;
  final String timestamp;

  SpeechAnalysisResult({
    required this.response,
    required this.corrections,
    required this.grammarScore,
    required this.overallFeedback,
    required this.context,
    required this.timestamp,
  });

  factory SpeechAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SpeechAnalysisResult(
      response: json['response'] ?? '',
      corrections: (json['corrections'] as List?)
              ?.map((c) => SpeechCorrection.fromJson(c))
              .toList() ??
          [],
      grammarScore: json['grammarScore'] ?? 0,
      overallFeedback: json['overallFeedback'] ?? '',
      context: ConversationContextInfo.fromJson(json['context'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

/// Context information from the conversation
class ConversationContextInfo {
  final List<String> detectedKeywords;
  final String? emotion;
  final int wordCount;

  ConversationContextInfo({
    required this.detectedKeywords,
    this.emotion,
    required this.wordCount,
  });

  factory ConversationContextInfo.fromJson(Map<String, dynamic> json) {
    return ConversationContextInfo(
      detectedKeywords: (json['detectedKeywords'] as List?)
              ?.map((k) => k.toString())
              .toList() ??
          [],
      emotion: json['emotion'],
      wordCount: json['wordCount'] ?? 0,
    );
  }
}

/// Model for individual speech corrections
class SpeechCorrection {
  final String original;
  final String suggestion;
  final String type;
  final String explanation;

  SpeechCorrection({
    required this.original,
    required this.suggestion,
    required this.type,
    required this.explanation,
  });

  factory SpeechCorrection.fromJson(Map<String, dynamic> json) {
    return SpeechCorrection(
      original: json['original'] ?? '',
      suggestion: json['suggestion'] ?? '',
      type: json['type'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}

/// Model for conversation starters
class ConversationStarters {
  final List<ConversationStarter> starters;
  final String welcomeMessage;

  ConversationStarters({
    required this.starters,
    required this.welcomeMessage,
  });

  factory ConversationStarters.fromJson(Map<String, dynamic> json) {
    return ConversationStarters(
      starters: (json['starters'] as List?)
              ?.map((s) => ConversationStarter.fromJson(s))
              .toList() ??
          [],
      welcomeMessage: json['welcomeMessage'] ?? '',
    );
  }
}

/// Individual conversation starter
class ConversationStarter {
  final String topic;
  final String question;

  ConversationStarter({
    required this.topic,
    required this.question,
  });

  factory ConversationStarter.fromJson(Map<String, dynamic> json) {
    return ConversationStarter(
      topic: json['topic'] ?? '',
      question: json['question'] ?? '',
    );
  }
}

/// Model for conversation context analysis
class ConversationContext {
  final int conversationLength;
  final int userMessages;
  final List<TopicMention> topTopics;
  final List<String> emotions;
  final double averageMessageLength;
  final String timestamp;

  ConversationContext({
    required this.conversationLength,
    required this.userMessages,
    required this.topTopics,
    required this.emotions,
    required this.averageMessageLength,
    required this.timestamp,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      conversationLength: json['conversationLength'] ?? 0,
      userMessages: json['userMessages'] ?? 0,
      topTopics: (json['topTopics'] as List?)
              ?.map((t) => TopicMention.fromJson(t))
              .toList() ??
          [],
      emotions: (json['emotions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      averageMessageLength: (json['averageMessageLength'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

/// Topic mention model
class TopicMention {
  final String topic;
  final int mentions;

  TopicMention({
    required this.topic,
    required this.mentions,
  });

  factory TopicMention.fromJson(Map<String, dynamic> json) {
    return TopicMention(
      topic: json['topic'] ?? '',
      mentions: json['mentions'] ?? 0,
    );
  }
}

/// Custom exception for speaking practice errors
class SpeakingPracticeException implements Exception {
  final String message;
  final String details;

  SpeakingPracticeException(this.message, this.details);

  @override
  String toString() => 'SpeakingPracticeException: $message';
}