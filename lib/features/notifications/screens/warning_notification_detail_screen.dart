import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';

class WarningNotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const WarningNotificationDetailScreen({
    super.key,
    required this.data,
  });

  String _text(String key, {String fallback = '-'}) {
    final value = data[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  String _formatTime(String raw) {
    if (raw.isEmpty || raw == '-') return '-';

    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  /// Warna background icon berdasarkan kategori & state
  Color _resolveIconBgColor(String kategori, String state) {
    final s = state.toLowerCase();
    if (kategori.toUpperCase().contains('AWLR')) {
      if (s.contains('siaga 1')) return const Color(0xFFD32F2F); // Merah
      if (s.contains('siaga 2')) return const Color(0xFFF57C00); // Oranye
      if (s.contains('siaga 3')) return const Color(0xFFF9A825); // Kuning
      return AppTheme.primary;
    }
    return AppTheme.primary;
  }

  /// Widget icon berdasarkan kategori & state
  Widget _buildIconWidget(String kategori, String state) {
    final s = state.toLowerCase();

    // AWLR → SVG ikon_awlr dengan warna sesuai siaga
    if (kategori.toUpperCase().contains('AWLR')) {
      Color iconColor = AppTheme.primary;
      if (s.contains('siaga 1')) iconColor = const Color(0xFFD32F2F);
      if (s.contains('siaga 2')) iconColor = const Color(0xFFF57C00);
      if (s.contains('siaga 3')) iconColor = const Color(0xFFF9A825);
      return SvgPicture.asset(
        'assets/images/awlr/ikon_awlr.svg',
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }

    // ARR → PNG dari klasifikasi_hujan
    String pngAsset = 'assets/images/klasifikasi_hujan/tidak_hujan.png';
    if (s.contains('sangat lebat'))   pngAsset = 'assets/images/klasifikasi_hujan/hujan_sangat_lebat.png';
    else if (s.contains('lebat'))     pngAsset = 'assets/images/klasifikasi_hujan/hujan_lebat.png';
    else if (s.contains('sedang'))    pngAsset = 'assets/images/klasifikasi_hujan/hujan_sedang.png';
    else if (s.contains('sangat ringan')) pngAsset = 'assets/images/klasifikasi_hujan/hujan_sangat_ringan.png';
    else if (s.contains('ringan'))    pngAsset = 'assets/images/klasifikasi_hujan/hujan_ringan.png';

    return Image.asset(pngAsset, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final namaPeringatan = _text('nama_peringatan', fallback: _text('title'));
    final waktu = _formatTime(_text('warning_time'));
    final message = _text('message', fallback: _text('body'));
    final kategori = _text('kategori');
    final state = _text('state');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detail Peringatan'),
        backgroundColor: const Color(0xFF2B3377),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _resolveIconBgColor(kategori, state).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: _buildIconWidget(kategori, state),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              namaPeringatan,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(label: kategori, color: AppTheme.primary),
                      _Badge(label: state, color: AppTheme.warning),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _InfoPanel(
              children: [
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Waktu',
                  value: waktu,
                ),
                _InfoRow(
                  icon: Icons.notifications_active_rounded,
                  label: 'Nama Peringatan',
                  value: namaPeringatan,
                ),
                _InfoRow(
                  icon: Icons.sensors_rounded,
                  label: 'Nama Logger',
                  value: _text('nama_logger'),
                ),
                _InfoRow(
                  icon: Icons.place_rounded,
                  label: 'Nama Pos',
                  value: _text('nama_pos'),
                ),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Alamat',
                  value: _text('alamat'),
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (label == '-') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final List<Widget> children;

  const _InfoPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
