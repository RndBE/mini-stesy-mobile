import 'package:flutter/material.dart';

class DokumentasiPosScreen extends StatefulWidget {
  final Map<String, dynamic> point;

  const DokumentasiPosScreen({super.key, required this.point});

  @override
  State<DokumentasiPosScreen> createState() => _DokumentasiPosScreenState();
}

class _DokumentasiPosScreenState extends State<DokumentasiPosScreen> {
  int _currentIndex = 0;
  List<String> _fotos = [];

  @override
  void initState() {
    super.initState();
    // Ambil list url dari backend (sudah dimodif untuk mengeluarkan field 'dokumentasi' sebagai array of url string)
    if (widget.point['dokumentasi'] != null) {
      _fotos = List<String>.from(widget.point['dokumentasi']);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimaryDark = Color(0xFF2B3377);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: colorPrimaryDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dokumentasi Pos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _fotos.isEmpty
          ? const Center(
              child: Text(
                'Belum ada foto pos',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Carousel View (PageView)
                SizedBox(
                  height: 300, // Tinggi galeri foto
                  child: PageView.builder(
                    itemCount: _fotos.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _fotos[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Indicators (Dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _fotos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? colorPrimaryDark : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
