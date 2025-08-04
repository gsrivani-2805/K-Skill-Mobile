import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class StartSessionResponse {
  final bool success;
  final String? sessionId;
  final String message;
  final String? audio;
  final bool sessionActive;
  final String? error;

  StartSessionResponse({
    required this.success,
    this.sessionId,
    required this.message,
    this.audio,
    required this.sessionActive,
    this.error,
  });

  factory StartSessionResponse.fromJson(Map<String, dynamic> json) {
    return StartSessionResponse(
      success: json['success'] ?? false,
      sessionId: json['sessionId'],
      message: json['message'] ?? '',
      audio: json['audio'],
      sessionActive: json['sessionActive'] ?? false,
      error: json['error'],
    );
  }
}

class ProcessSpeechResponse {
  final bool success;
  final String userText;
  final String feedback;
  final String? audio;
  final String? error;

  ProcessSpeechResponse({
    required this.success,
    required this.userText,
    required this.feedback,
    this.audio,
    this.error,
  });

  factory ProcessSpeechResponse.fromJson(Map<String, dynamic> json) {
    return ProcessSpeechResponse(
      success: json['success'] ?? false,
      userText: json['userText'] ?? '',
      feedback: json['feedback'] ?? '',
      audio: json['audio'],
      error: json['error'],
    );
  }
}

class EndSessionResponse {
  final bool success;
  final String summary;
  final String? audio;
  final bool sessionActive;
  final String? error;

  EndSessionResponse({
    required this.success,
    required this.summary,
    this.audio,
    required this.sessionActive,
    this.error,
  });

  factory EndSessionResponse.fromJson(Map<String, dynamic> json) {
    return EndSessionResponse(
      success: json['success'] ?? false,
      summary: json['summary'] ?? '',
      audio: json['audio'],
      sessionActive: json['sessionActive'] ?? false,
      error: json['error'],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final bool isSystemMessage;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.isSystemMessage = false,
  });
}

class SessionStatus {
  final bool sessionActive;
  final int conversationLength;

  SessionStatus({
    required this.sessionActive,
    required this.conversationLength,
  });

  factory SessionStatus.fromJson(Map<String, dynamic> json) {
    return SessionStatus(
      sessionActive: json['sessionActive'] ?? false,
      conversationLength: json['conversationLength'] ?? 0,
    );
  }
}

class ApiService {
  // Replace with your actual server URL
  static const String baseUrl = 'http://localhost:8080'; // For development
  // static const String baseUrl = 'https://your-server.com'; // For production
  
  final http.Client _client = http.Client();

  // Headers for all requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<StartSessionResponse> startSession() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/start_session'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return StartSessionResponse.fromJson(data);
      } else {
        return StartSessionResponse(
          success: false,
          message: '',
          sessionActive: false,
          error: data['error'] ?? 'Failed to start session',
        );
      }
    } catch (e) {
      return StartSessionResponse(
        success: false,
        message: '',
        sessionActive: false,
        error: 'Network error: $e',
      );
    }
  }

  Future<ProcessSpeechResponse> processSpeech(String sessionId, File audioFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/process_speech'),
      );

      // Add session ID
      request.fields['sessionId'] = sessionId;

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          filename: 'audio.wav',
        ),
      );

      // Send request
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return ProcessSpeechResponse.fromJson(data);
      } else {
        return ProcessSpeechResponse(
          success: false,
          userText: '',
          feedback: '',
          error: data['error'] ?? 'Failed to process speech',
        );
      }
    } catch (e) {
      return ProcessSpeechResponse(
        success: false,
        userText: '',
        feedback: '',
        error: 'Network error: $e',
      );
    }
  }

  Future<EndSessionResponse> endSession(String sessionId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/end_session'),
        headers: _headers,
        body: json.encode({
          'sessionId': sessionId,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return EndSessionResponse.fromJson(data);
      } else {
        return EndSessionResponse(
          success: false,
          summary: '',
          sessionActive: false,
          error: data['error'] ?? 'Failed to end session',
        );
      }
    } catch (e) {
      return EndSessionResponse(
        success: false,
        summary: '',
        sessionActive: false,
        error: 'Network error: $e',
      );
    }
  }

  Future<SessionStatus> getSessionStatus(String sessionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/status/$sessionId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return SessionStatus.fromJson(data);
      } else {
        return SessionStatus(
          sessionActive: false,
          conversationLength: 0,
        );
      }
    } catch (e) {
      return SessionStatus(
        sessionActive: false,
        conversationLength: 0,
      );
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}