/// Model untuk satu pesan dalam percakapan chatbot.
class ChatbotMessage {
  final String id;
  final String role; // 'user' atau 'assistant'
  final String text;
  final DateTime timestamp;

  ChatbotMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toHistoryMap() => {'role': role, 'text': text};
}

/// Model response dari API chatbot.
class ChatbotResponse {
  final String reply;
  final String source; // 'ai' atau 'local'
  final bool configured;

  ChatbotResponse({
    required this.reply,
    required this.source,
    required this.configured,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      reply: json['reply']?.toString() ?? 'Tidak ada respons.',
      source: json['source']?.toString() ?? 'local',
      configured: json['configured'] == true,
    );
  }
}
