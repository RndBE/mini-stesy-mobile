import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/chatbot_repository.dart';
import '../models/chatbot_message.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/quick_prompt_chip.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final ChatbotRepository _repo = ChatbotRepository();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String? _error;

  final List<ChatbotMessage> _messages = [
    ChatbotMessage(
      id: 'welcome',
      role: 'assistant',
      text: 'Halo! 👋 Saya STESY Assistant.\n\n'
          'Saya bisa membantu Anda terkait data monitoring, '
          'status logger, informasi pos, dan panduan penggunaan sistem STESY.\n\n'
          'Silakan tanyakan apa saja!',
    ),
  ];

  final List<String> _quickPrompts = [
    'Lihat data pos Pogung',
    'Apa arti logger offline?',
    'Panduan peta lokasi',
    'Status siaga banjir',
    'Cara cek data realtime',
  ];

  late AnimationController _fabAnimCtrl;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimCtrl,
      curve: Curves.easeOutBack,
    );
    _fabAnimCtrl.forward();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _inputCtrl.clear();
    setState(() {
      _error = null;
      _messages.add(ChatbotMessage(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        role: 'user',
        text: trimmed,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _repo.ask(trimmed, _messages);
      if (mounted) {
        setState(() {
          _messages.add(ChatbotMessage(
            id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            text: response.reply,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[Chatbot] Error: $e');
      if (mounted) {
        final fallback = _localFallbackReply(trimmed);
        setState(() {
          _error = 'Koneksi ke server terganggu.';
          _messages.add(ChatbotMessage(
            id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            text: fallback,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  /// Fallback reply lokal jika API unreachable (mirror dari website).
  String _localFallbackReply(String text) {
    final query = text.toLowerCase();

    if (query.contains('real') ||
        query.contains('monitoring') ||
        query.contains('data')) {
      return 'Untuk data real-time, buka menu Realtime Monitoring. Pilih pos atau kategori logger, lalu cek nilai sensor terakhir, waktu update, dan status koneksinya.';
    }
    if (query.contains('offline') ||
        query.contains('putus') ||
        query.contains('status')) {
      return 'Status offline biasanya berarti logger belum mengirim data terbaru atau koneksi perangkat terputus. Cek waktu data terakhir, baterai, dan jaringan di halaman detail perangkat.';
    }
    if (query.contains('peta') ||
        query.contains('lokasi') ||
        query.contains('pos')) {
      return 'Untuk melihat lokasi pos, buka menu Peta Lokasi. Marker menunjukkan posisi logger dan bisa diklik untuk melihat informasi pos terkait.';
    }
    if (query.contains('siaga') ||
        query.contains('banjir') ||
        query.contains('hujan')) {
      return 'Level siaga mengikuti ambang batas yang dikonfigurasi pada data AWLR atau ARR. Cek halaman detail pos untuk melihat klasifikasi dan parameter pendukung.';
    }

    return 'Maaf, saya belum bisa menjawab pertanyaan tersebut saat ini karena koneksi terputus. Coba lagi nanti ya!';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2B3377);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: primaryColor,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _buildHeader(context, primaryColor),

            // ── Messages ────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length +
                      (_isLoading ? 1 : 0) +
                      (_showQuickPrompts ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _messages.length) {
                      return ChatBubble(message: _messages[index]);
                    }
                    if (_showQuickPrompts && index == _messages.length) {
                      return _buildQuickPrompts();
                    }
                    return _buildTypingIndicator();
                  },
                ),
              ),
            ),

            // ── Error banner ────────────────────────────────────
            if (_error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: Icon(Icons.close,
                          size: 16, color: Colors.red.shade400),
                    ),
                  ],
                ),
              ),

            // ── Input area ──────────────────────────────────────
            _buildInputArea(context, primaryColor, bottomPadding),
          ],
        ),
      ),
    );
  }

  bool get _showQuickPrompts => _messages.length == 1 && !_isLoading;

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 8,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STESY Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Beta · Online',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onSelected: (value) {
              if (value == 'clear') {
                setState(() {
                  _messages.clear();
                  _messages.add(ChatbotMessage(
                    id: 'welcome',
                    role: 'assistant',
                    text: 'Halo! 👋 Saya STESY Assistant.\n\n'
                        'Saya bisa membantu Anda terkait data monitoring, '
                        'status logger, informasi pos, dan panduan penggunaan sistem STESY.\n\n'
                        'Silakan tanyakan apa saja!',
                  ));
                  _error = null;
                });
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 18, color: Colors.black54),
                    SizedBox(width: 10),
                    Text('Mulai Ulang Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Padding(
      padding: const EdgeInsets.only(left: 46, top: 4, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _quickPrompts
            .map(
              (prompt) => QuickPromptChip(
                label: prompt,
                onTap: () => _sendMessage(prompt),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    const botColor = Color(0xFF2B3377);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: botColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: botColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
      BuildContext context, Color primaryColor, double bottomPadding) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom:
            12 + (bottomPadding > 0 ? 0 : MediaQuery.of(context).padding.bottom),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => _sendMessage(value),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: 'Tulis pertanyaan...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: _fabScaleAnim,
              child: Container(
                width: 46,
                height: 46,
                margin: const EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading
                        ? null
                        : () => _sendMessage(_inputCtrl.text),
                    child: Icon(
                      _isLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated typing dots indicator.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Smooth sine wave animation
            final t = (_controller.value * 2 * math.pi) - (index * 0.6);
            final bounce = (math.sin(t) + 1) / 2; // maps from 0.0 to 1.0

            return Padding(
              padding: EdgeInsets.only(right: index < 2 ? 6 : 0),
              child: Transform.translate(
                offset: Offset(0, -5 * bounce),
                child: Container(
                  width: 8 + (2 * bounce),
                  height: 8 + (2 * bounce),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B3377)
                        .withValues(alpha: 0.3 + 0.7 * bounce),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B3377)
                            .withValues(alpha: 0.4 * bounce),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
