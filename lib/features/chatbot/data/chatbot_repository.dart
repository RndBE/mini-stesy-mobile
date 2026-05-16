import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/chatbot_message.dart';

class ChatbotRepository {
  static const int _maxServerTextLength = 650;

  /// Kirim pesan ke chatbot API dan dapatkan response.
  Future<ChatbotResponse> ask(
    String message,
    List<ChatbotMessage> history,
  ) async {
    final historyPayload = history.where((m) => m.id != 'welcome').toList();

    // Ambil 10 pesan terakhir untuk context
    final trimmed = historyPayload.length > 10
        ? historyPayload.sublist(historyPayload.length - 10)
        : historyPayload;

    final response = await ApiClient.instance.post(
      ApiEndpoints.chatbotAsk,
      data: {
        'message': _limitForServer(message),
        'messages': trimmed
            .map((m) => {'role': m.role, 'text': _limitForServer(m.text)})
            .toList(),
      },
      // AI generation bisa butuh 15–30 detik, override timeout khusus chatbot
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    return ChatbotResponse.fromJson(response.data as Map<String, dynamic>);
  }

  String _limitForServer(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= _maxServerTextLength) return trimmed;
    return trimmed.substring(0, _maxServerTextLength);
  }
}
