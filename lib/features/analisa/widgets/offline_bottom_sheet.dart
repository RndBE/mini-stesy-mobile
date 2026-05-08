import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Memunculkan Bottom Sheet pintar yang akan terus mengecek koneksi internet.
/// Saat terhubung kembali, Bottom Sheet akan tertutup otomatis dan memanggil [onRetry].
void showOfflineBottomSheet(BuildContext context, VoidCallback onRetry) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _OfflineBottomSheetContent(onRetry: onRetry);
    },
  );
}

class _OfflineBottomSheetContent extends StatefulWidget {
  final VoidCallback onRetry;

  const _OfflineBottomSheetContent({required this.onRetry});

  @override
  State<_OfflineBottomSheetContent> createState() => _OfflineBottomSheetContentState();
}

class _OfflineBottomSheetContentState extends State<_OfflineBottomSheetContent> {
  Timer? _timer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _startNetworkPolling();
  }

  void _startNetworkPolling() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      bool hasInternet = false;
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          hasInternet = true;
        }
      } catch (_) {
        hasInternet = false;
      }

      if (hasInternet && mounted) {
        // Hentikan timer karena koneksi sudah kembali
        timer.cancel();
        
        setState(() {
          _isConnected = true;
        });

        // Beri waktu 1.5 detik agar user bisa melihat ikon centang hijau
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context);
            widget.onRetry();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _isConnected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey('connected'),
                      color: Colors.green,
                      size: 56,
                    )
                  : const Icon(
                      Icons.wifi_off_rounded,
                      key: ValueKey('disconnected'),
                      color: Colors.red,
                      size: 48,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              _isConnected ? 'Jaringan Terhubung' : 'Koneksi Terputus',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: _isConnected ? Colors.green.shade700 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected 
                  ? 'Sinkronisasi data sedang dilanjutkan...' 
                  : 'Tidak ada koneksi internet. Silakan periksa jaringan Anda dan pastikan perangkat terhubung.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected ? Colors.green : const Color(0xFF1E3A8A),
                  disabledBackgroundColor: _isConnected ? Colors.green : const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: null, // Disable tombol karena kita mau otomatis
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isConnected) ...[
                      const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)
                        )
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _isConnected ? 'Menyinkronkan Data...' : 'Menunggu Jaringan...', 
                      style: TextStyle(
                        color: _isConnected ? Colors.white : Colors.white70, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      )
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8), // Extra space untuk menghindari home indicator
          ],
        ),
      ),
    );
  }
}
