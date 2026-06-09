import 'package:flutter/material.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/diagnosis_model.dart';
import '../../services/diagnosis_firestore_service.dart';
import '../../services/plant_firestore_service.dart';

class AiScannerPage extends StatefulWidget {
  const AiScannerPage({super.key});

  @override
  State<AiScannerPage> createState() => _AiScannerPageState();
}

class _AiScannerPageState extends State<AiScannerPage>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnim;
  late Animation<double> _pulseAnim;

  _ScanState _scanState = _ScanState.idle;
  DiagnosisModel? _result;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
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
          const Spacer(),
          _TopAction(
            icon: Icons.help_outline_rounded,
            onTap: () => _showHelpSheet(),
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
      child: Column(
        children: [
          const SizedBox(height: 16),
          _ScanInstructions(state: _scanState),
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Viewfinder background (simulated camera)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2E20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
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
                        if (_scanState == _ScanState.scanning)
                          _ScanLineOverlay(animation: _scanLineAnim),
                        if (_scanState == _ScanState.analyzing)
                          const _AnalyzingOverlay(),
                      ],
                    ),
                  ),
                ),
                // Corner brackets
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _ScanBrackets(
                      isActive: _scanState == _ScanState.scanning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2018),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          if (_scanState == _ScanState.idle ||
              _scanState == _ScanState.scanning) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlBtn(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: _pickFromGallery,
                ),
                _ShutterButton(
                  isScanning: _scanState == _ScanState.scanning,
                  onTap: _takeScan,
                ),
                _ControlBtn(
                  icon: Icons.flash_on_rounded,
                  label: 'Flash',
                  onTap: () {},
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _ScanTipRow(),
        ],
      ),
    );
  }

  void _takeScan() {
    if (_scanState == _ScanState.idle) {
      setState(() => _scanState = _ScanState.scanning);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _scanState = _ScanState.analyzing);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _scanState = _ScanState.result;
              _result = DummyData.diagnoses.first;
            });
          }
        });
      });
    }
  }

  void _pickFromGallery() {
    setState(() => _scanState = _ScanState.analyzing);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _scanState = _ScanState.result;
          _result = DummyData.diagnoses.first;
        });
      }
    });
  }

  void _resetScan() => setState(() {
        _scanState = _ScanState.idle;
        _result = null;
      });

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2018),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HelpSheet(),
    );
  }
}

enum _ScanState { idle, scanning, analyzing, result }

class _ScanInstructions extends StatelessWidget {
  final _ScanState state;
  const _ScanInstructions({required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (state) {
      _ScanState.idle => (
          Icons.center_focus_strong_rounded,
          'Fokuskan kamera pada daun yang ingin diperiksa',
          Colors.white70
        ),
      _ScanState.scanning => (
          Icons.document_scanner_rounded,
          'Tahan diam... sedang memindai',
          Colors.greenAccent
        ),
      _ScanState.analyzing => (
          Icons.psychology_rounded,
          'AI sedang menganalisis gambar...',
          Colors.amberAccent
        ),
      _ScanState.result => (
          Icons.check_circle_rounded,
          'Analisis selesai!',
          Colors.greenAccent
        ),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnalyzingOverlay extends StatefulWidget {
  const _AnalyzingOverlay();

  @override
  State<_AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<_AnalyzingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
        // Top-left
        Positioned(
          top: 0,
          left: 0,
          child: _Bracket(color: color),
        ),
        // Top-right
        Positioned(
          top: 0,
          right: 0,
          child: Transform.scale(scaleX: -1, child: _Bracket(color: color)),
        ),
        // Bottom-left
        Positioned(
          bottom: 0,
          left: 0,
          child: Transform.scale(scaleY: -1, child: _Bracket(color: color)),
        ),
        // Bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: Transform.scale(
            scaleX: -1,
            scaleY: -1,
            child: _Bracket(color: color),
          ),
        ),
      ],
    );
  }
}

class _Bracket extends StatelessWidget {
  final Color color;
  const _Bracket({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _BracketPainter(color: color),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  const _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
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
              color: isScanning ? Colors.green : Colors.grey.shade100,
            ),
            child: Center(
              child: Icon(
                isScanning
                    ? Icons.stop_rounded
                    : Icons.camera_alt_rounded,
                color: isScanning ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
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
  const _TopAction({required this.icon, required this.onTap});

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SaveDiagnosisSheet(
        diagnosis: diagnosis,
        onSaved: (plantName) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Diagnosis disimpan ke $plantName'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _ResultPill({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final String icon;
  final Widget child;

  const _ResultSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
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

class _SaveDiagnosisSheet extends StatefulWidget {
  final DiagnosisModel diagnosis;
  final void Function(String plantName) onSaved;

  const _SaveDiagnosisSheet({required this.diagnosis, required this.onSaved});

  @override
  State<_SaveDiagnosisSheet> createState() => _SaveDiagnosisSheetState();
}

class _SaveDiagnosisSheetState extends State<_SaveDiagnosisSheet> {
  final _plantService = PlantFirestoreService();
  final _diagnosisService = DiagnosisFirestoreService();
  bool _saving = false;

  Future<void> _save(dynamic plant) async {
    setState(() => _saving = true);
    try {
      final diagnosis = DiagnosisModel(
        id: '',
        plantId: plant.id,
        plantName: plant.name,
        plantEmoji: plant.emoji,
        diseaseName: widget.diagnosis.diseaseName,
        diseaseNameEn: widget.diagnosis.diseaseNameEn,
        severity: widget.diagnosis.severity,
        diagnosisStatus: DiagnosisStatus.active,
        confidence: widget.diagnosis.confidence,
        description: widget.diagnosis.description,
        solutions: widget.diagnosis.solutions,
        preventionTips: widget.diagnosis.preventionTips,
        diagnosedAt: DateTime.now(),
      );
      await _diagnosisService.addDiagnosis(diagnosis);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved(plant.name);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Simpan ke Tanaman', style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          const Text(
            'Pilih tanaman yang ingin diperbarui statusnya:',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: _plantService.watchPlants(),
            builder: (context, snapshot) {
              final plants = snapshot.data ?? [];
              if (plants.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Belum ada tanaman di kebunmu')),
                );
              }
              return Column(
                children: plants.take(5).map((p) => ListTile(
                  leading: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(p.name, style: AppTextStyles.labelLarge),
                  subtitle: Text(p.type, style: AppTextStyles.bodySmall),
                  trailing: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textHint),
                  onTap: _saving ? null : () => _save(p),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
