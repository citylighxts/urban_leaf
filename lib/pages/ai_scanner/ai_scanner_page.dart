import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Menggunakan live camera stream
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/diagnosis_model.dart';
import '../../models/plant_model.dart';
import '../../services/ai_scan_service.dart';
import '../../services/plant_firestore_service.dart';
import '../../main.dart'; // Untuk mengakses variabel global 'cameras'

class AiScannerPage extends StatefulWidget {
  const AiScannerPage({super.key});

  @override
  State<AiScannerPage> createState() => _AiScannerPageState();
}

class _AiScannerPageState extends State<AiScannerPage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;

  _ScanState _scanState = _ScanState.idle;
  DiagnosisModel? _result;
  File? _imageFile;

  final AiScanService _aiScanService = AiScanService();
  final PlantFirestoreService _firestoreService = PlantFirestoreService();
  final ImagePicker _galleryPicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Panggil fungsi loadModel() yang baru saja kita buat di atas secara aman
    Future.microtask(() async {
      await _aiScanService.loadModel();
    });

    _initializeLiveCamera(); // Fungsi live preview kameramu

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  // Mengaktifkan lensa kamera utama belakang perangkat secara otomatis
  void _initializeLiveCamera() async {
    if (cameras.isEmpty) {
      print("Tidak ada sensor kamera fisik terdeteksi.");
      return;
    }

    // Gunakan kamera belakang (indeks 0 biasanya kamera belakang utama)
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Gagal menyalakan sensor live preview kamera: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanLineController.dispose();
    _aiScanService.dispose();
    super.dispose();
  }

  // Aksi tombol potret instan dari live preview kamera
  void _takeScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_scanState != _ScanState.idle) return;

    try {
      setState(() => _scanState = _ScanState.scanning);

      // Ambil gambar langsung dari feed kamera yang menyala
      final XFile photo = await _cameraController!.takePicture();
      
      setState(() {
        _imageFile = File(photo.path);
        _scanState = _ScanState.analyzing;
      });

      // Jalankan model inferensi TFLite secara lokal
      final aiResult = await _aiScanService.predictImage(_imageFile!);
      await Future.delayed(const Duration(milliseconds: 500)); // Jedas sirkulasi visual

      if (!mounted) return;

      if (aiResult != null) {
        String dynamicLabel = aiResult['diseaseName'].toString();
        final detailPenyakit = await _getDiseaseDetailsFallback(dynamicLabel);

        setState(() {
          _scanState = _ScanState.result;
          _result = DiagnosisModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            plantId: '',
            plantName: '',
            plantEmoji: '',
            diseaseName: detailPenyakit?['diseaseName'] ?? dynamicLabel,
            diseaseNameEn: detailPenyakit?['diseaseNameEn'] ?? dynamicLabel,
            severity: DiseaseSeverity.moderate,
            diagnosisStatus: DiagnosisStatus.active,
            confidence: aiResult['confidence'] as double,
            description: detailPenyakit?['description'] ?? 'Detail deskripsi tidak tersedia.',
            solutions: List<String>.from(detailPenyakit?['solutions'] ?? ['Amati perkembangan daun tanaman harian.']),
            preventionTips: List<String>.from(detailPenyakit?['preventionTips'] ?? ['Jaga sirkulasi udara media tanam.']),
            diagnosedAt: DateTime.now(),
          );
        });
      } else {
        _resetScan();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Gagal menganalisis daun tanaman. Silakan coba lagi.')),
        );
      }
    } catch (e) {
      _resetScan();
      print("❌ Error saat menjepret gambar: $e");
    }
  }

  // Mengambil berkas pendukung foto lewat galeri lokal
  void _pickFromGallery() async {
    final XFile? photo = await _galleryPicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (photo == null) return;

    setState(() {
      _imageFile = File(photo.path);
      _scanState = _ScanState.analyzing;
    });

    final aiResult = await _aiScanService.predictImage(_imageFile!);
    if (!mounted) return;

    if (aiResult != null) {
      String dynamicLabel = aiResult['diseaseName'].toString();
      final detailPenyakit = await _getDiseaseDetailsFallback(dynamicLabel);

      setState(() {
        _scanState = _ScanState.result;
        _result = DiagnosisModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          plantId: '',
          plantName: '',
          plantEmoji: '',
          diseaseName: detailPenyakit?['diseaseName'] ?? dynamicLabel,
          diseaseNameEn: detailPenyakit?['diseaseNameEn'] ?? dynamicLabel,
          severity: DiseaseSeverity.moderate,
          diagnosisStatus: DiagnosisStatus.active,
          confidence: aiResult['confidence'] as double,
          description: detailPenyakit?['description'] ?? 'Detail deskripsi tidak tersedia.',
          solutions: List<String>.from(detailPenyakit?['solutions'] ?? ['Isolasi pot tanaman segera.']),
          preventionTips: List<String>.from(detailPenyakit?['preventionTips'] ?? ['Hindari kelembapan berlebih.']),
          diagnosedAt: DateTime.now(),
        );
      });
    } else {
      _resetScan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Gagal memproses gambar dari galeri.')),
      );
    }
  }

  void _resetScan() {
    setState(() {
      _scanState = _ScanState.idle;
      _result = null;
      _imageFile = null;
    });
  }

  // Fallback extension method for AiScanService when disease detail lookup is unavailable.
  // This allows existing scan logic to continue using default values.
  // If the service later exposes a real implementation, the instance method will take precedence.
  Future<Map<String, dynamic>?> _getDiseaseDetailsFallback(String diseaseName) async {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A12),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _scanState == _ScanState.result && _result != null
                  ? _DiagnosisResult(
                      diagnosis: _result!,
                      onRescan: _resetScan,
                      firestoreService: _firestoreService,
                    )
                  : _buildScannerUI(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Plant Scanner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Powered by Machine Learning',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerUI() {
    return Column(
      children: [
        Expanded(child: _buildViewfinder()),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildViewfinder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFF1A2E20), borderRadius: BorderRadius.circular(20)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // KONDISI UTAMA: Tampilkan Live Camera Feed jika idle/scanning
              _cameraController != null && _cameraController!.value.isInitialized && (_scanState == _ScanState.idle || _scanState == _ScanState.scanning)
                  ? CameraPreview(_cameraController!)
                  : (_imageFile != null 
                      ? Image.file(_imageFile!, fit: BoxFit.cover) // Tampilkan foto beku pas di-analisis
                      : const Center(child: CircularProgressIndicator(color: Colors.greenAccent))),
              
              // Efek Garis Laser Animasi Pemindaian
              if (_scanState == _ScanState.scanning || _scanState == _ScanState.analyzing)
                AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // Simulated plant image
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🍃',
                                  style: TextStyle(fontSize: 80)),
                              const SizedBox(height: 8),
                              Text(
                                'Arahkan kamera ke daun tanaman',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              if (_scanState == _ScanState.analyzing)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.greenAccent),
                        SizedBox(height: 16),
                        Text('Menganalisis Gejala Daun...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(color: Color(0xFF0F2018), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: Colors.white70, size: 28),
            onPressed: _pickFromGallery,
          ),
          // Tombol Potret Bulat Besar Instan
          GestureDetector(
            onTap: _takeScan,
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: _scanState == _ScanState.scanning 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F2018)))
                    : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 28),
            onPressed: _resetScan,
          ),
        ],
      ),
    );
  }
}

enum _ScanState { idle, scanning, analyzing, result }

// ... Kode Widget Component _DiagnosisResult dan _SaveToPlatButton di bawahnya tetap biarkan utuh ...
class _ScanInstructions extends StatelessWidget {
  final _ScanState state;

  const _ScanInstructions({required this.state});

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      _ScanState.idle => 'Siapkan daun tanaman untuk dipindai',
      _ScanState.scanning => 'Memindai daun... Tetap stabil',
      _ScanState.analyzing => 'Analisis gambar sedang berlangsung',
      _ScanState.result => 'Hasil diagnosis siap ditampilkan',
    };

    final subtitle = switch (state) {
      _ScanState.idle => 'Ketuk tombol scan untuk mengambil foto atau pilih dari galeri.',
      _ScanState.scanning => 'Mengumpulkan detail visual sebelum menganalisis.',
      _ScanState.analyzing => 'Tunggu sebentar, sistem sedang memproses gambar.',
      _ScanState.result => 'Lihat detail dan simpan riwayat penyakit jika diperlukan.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
      ],
    );
  }
}

// ... (Widget _ScanLineOverlay, _AnalyzingOverlay, _ScanBrackets, _Bracket, _BracketPainter, _ShutterButton, _ControlBtn, _ScanTipRow tetap dipertahankan sesuai kode aslimu)

class _DiagnosisResult extends StatelessWidget {
  final DiagnosisModel diagnosis;
  final VoidCallback onRescan;
  final PlantFirestoreService firestoreService; // Menambahkan service di konstruktor

  const _DiagnosisResult({required this.diagnosis, required this.onRescan, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (diagnosis.severity) {
      DiseaseSeverity.mild => AppColors.success,
      DiseaseSeverity.moderate => AppColors.warning,
      DiseaseSeverity.severe => AppColors.danger,
    };

    return Container(
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Bagian Tampilan Hasil Header Atas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🔬', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 4),
                Text(diagnosis.diseaseName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ResultPill(label: 'Akurasi AI: ${(diagnosis.confidence * 100).toStringAsFixed(0)}%', color: Colors.white, bgColor: Colors.white.withOpacity(0.15)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ResultSection(title: 'Deskripsi Penyakit', icon: '📋', child: Text(diagnosis.description, style: AppTextStyles.bodyMedium)),
          const SizedBox(height: 12),
          _ResultSection(
            title: 'Langkah Penanganan',
            icon: '🛠️',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: diagnosis.solutions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value, style: AppTextStyles.bodySmall)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
          
          // TOMBOL SIMPAN RIIL KE FIRESTORE
          _SaveToPlatButton(onTap: () => _showSaveDialog(context)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRescan,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Scan Lagi'),
          ),
        ],
      ),
    );
  }

  // LOGIKA UTAMA: Mengambil list tanaman riil dari Firestore dan memperbaruinya!
  void _showSaveDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2018),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        // Memakai StreamBuilder milik temanmu untuk menarik tanaman riil dari database Firestore
        return StreamBuilder<List<PlantModel>>(
          stream: firestoreService.watchPlants(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Colors.greenAccent)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Kamu belum memiliki tanaman di Kebunku. Silakan tambah tanaman terlebih dahulu di tab Kebunku.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              );
            }

            final livePlants = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Pilih tanaman yang terinfeksi untuk dipasangkan riwayat penyakit:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: livePlants.length,
                      itemBuilder: (context, index) {
                        final plant = livePlants[index];
                        return ListTile(
                          leading: Text(plant.emoji, style: const TextStyle(fontSize: 24)),
                          title: Text(plant.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(plant.type, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                          onTap: () async {
                            // Proses UPDATE dokumen tanaman di Firestore
                            // Masukkan string hasil penyakit ke array lastDiagnosis milik dokumen tanaman tersebut
                            final updatedPlant = plant.copyWith(
                              status: PlantStatus.quarantine, // Otomatis ubah status ke Karantina karena sakit
                              lastDiagnosis: diagnosis.diseaseName,
                            );

                            await firestoreService.updatePlant(updatedPlant);

                            if (context.mounted) {
                              Navigator.pop(ctx); // Tutup Dialog BottomSheet
                              Navigator.pop(context); // Keluar dari halaman Scanner kembali ke Beranda
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Berhasil memperbarui status medis tanaman ${plant.name} ke database!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ScanLineOverlay extends StatelessWidget {
  final Animation<double> animation;

  const _ScanLineOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        return Positioned(
          top: animation.value *
              (MediaQuery.of(context).size.height * 0.4),
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.greenAccent.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnalyzingOverlay extends StatelessWidget {
  const _AnalyzingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _anim,
              builder: (_, child) {
                return Transform.scale(
                  scale: 0.9 + (_anim.value * 0.1),
                  child: child,
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.greenAccent,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text('🧠', style: TextStyle(fontSize: 34)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI menganalisis...',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                color: Colors.greenAccent,
                backgroundColor: Color(0x30AAFF88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanBrackets extends StatelessWidget {
  final bool isActive;

  const _ScanBrackets({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? Colors.greenAccent : Colors.white.withValues(alpha: 0.5);
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: _Bracket(color: color, isLeft: true, isTop: true)),
        Positioned(top: 0, right: 0, child: _Bracket(color: color, isLeft: false, isTop: true)),
        Positioned(bottom: 0, left: 0, child: _Bracket(color: color, isLeft: true, isTop: false)),
        Positioned(bottom: 0, right: 0, child: _Bracket(color: color, isLeft: false, isTop: false)),
      ],
    );
  }
}

class _Bracket extends StatelessWidget {
  final Color color;
  final bool isLeft;
  final bool isTop;

  const _Bracket({required this.color, required this.isLeft, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _BracketPainter(color: color, isLeft: isLeft, isTop: isTop),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  final bool isTop;

  _BracketPainter({required this.color, required this.isLeft, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const double lineLength = 10;

    if (isTop && isLeft) {
      canvas.drawLine(Offset(0, size.height), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(lineLength, 0), paint);
    } else if (isTop && !isLeft) {
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width - lineLength, 0), paint);
    } else if (!isTop && isLeft) {
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(lineLength, size.height), paint);
    } else {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width - lineLength, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShutterButton extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onTap;

  const _ShutterButton({required this.isScanning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isScanning ? Colors.greenAccent : Colors.white,
          boxShadow: [
            BoxShadow(
              color: (isScanning ? Colors.greenAccent : Colors.white)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isScanning ? Colors.white24 : Colors.greenAccent,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            isScanning ? 'Memindai' : 'Potret',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ScanTipRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pastikan gambar daun jelas dan cukup cahaya untuk hasil optimal',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SaveToPlatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

// ─── Diagnosis Result ────────────────────────────────────────────────────────

class _DiagnosisResult extends StatelessWidget {
  final DiagnosisModel diagnosis;
  final VoidCallback onRescan;

  const _DiagnosisResult({
    required this.diagnosis,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    final (severityColor, severityBg) = switch (diagnosis.severity) {
      DiseaseSeverity.mild => (AppColors.success, AppColors.successLight),
      DiseaseSeverity.moderate => (AppColors.warning, AppColors.warningLight),
      DiseaseSeverity.severe => (AppColors.danger, AppColors.dangerLight),
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Result header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🔬',
                    style: TextStyle(
                        fontSize: 40,
                        color: Colors.white)),
                const SizedBox(height: 8),
                const Text(
                  'Hasil Diagnosis AI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diagnosis.diseaseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  diagnosis.diseaseNameEn,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ResultPill(
                      label: 'Keparahan: ${diagnosis.severityLabel}',
                      color: severityColor,
                      bgColor: severityBg.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 8),
                    _ResultPill(
                      label:
                          '${(diagnosis.confidence * 100).toStringAsFixed(0)}% akurasi',
                      color: Colors.white,
                      bgColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ResultSection(
            title: 'Deskripsi Penyakit',
            icon: '📋',
            child: Text(
              diagnosis.description,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          _ResultSection(
            title: 'Langkah Penanganan',
            icon: '🛠️',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: diagnosis.solutions
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.value,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _ResultSection(
            title: 'Tips Pencegahan',
            icon: '🛡️',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: diagnosis.preventionTips
                  .map(
                    (tip) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons
          _SaveToPlatButton(
            onTap: () => _showSaveDialog(context),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRescan,
            icon: const Icon(
                Icons.document_scanner_rounded,
                size: 16),
            label: const Text('Scan Lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final plants = DummyData.plants;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simpan ke Tanaman',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih tanaman yang ingin diperbarui statusnya:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...plants.take(4).map(
                    (p) => ListTile(
                      leading: Text(p.emoji,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(p.name,
                          style: AppTextStyles.labelLarge),
                      subtitle: Text(p.type,
                          style: AppTextStyles.bodySmall),
                      trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textHint),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Diagnosis disimpan ke ${p.name}',
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ResultPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _ResultPill({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final String icon;
  final Widget child;

  const _ResultSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SaveToPlatButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveToPlatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Simpan ke Kebunku',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '📸 Tips Scan Terbaik',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...const [
            ('🌿', 'Fokus pada satu daun yang menunjukkan gejala'),
            ('💡', 'Pastikan pencahayaan cukup dan merata'),
            ('📏', 'Jarak optimal: 15–20 cm dari permukaan daun'),
            ('✋', 'Tahan kamera agar tidak buram'),
            ('🔍', 'Pilih daun dengan gejala paling jelas untuk hasil terbaik'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(item.$1,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
