import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/chatbot_message.dart';

class ChatbotRepository {
  /// Kirim pesan ke chatbot API dan dapatkan response.
  Future<ChatbotResponse> ask(
    String message,
    List<ChatbotMessage> history,
  ) async {
    final historyPayload = history
        .where((m) => m.id != 'welcome')
        .toList();

    // Ambil 10 pesan terakhir untuk context
    final trimmed = historyPayload.length > 10
        ? historyPayload.sublist(historyPayload.length - 10)
        : historyPayload;

    final response = await ApiClient.instance.post(
      ApiEndpoints.chatbotAsk,
      data: {
        'message': message,
        'messages': trimmed.map((m) => m.toHistoryMap()).toList(),
      },
    );

    return ChatbotResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
