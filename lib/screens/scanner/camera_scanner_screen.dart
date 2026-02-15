import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/strain_provider.dart';
import '../../theme/theme.dart';

/// Dedikovaná obrazovka kamery pro skenování
///
/// Zobrazuje live preview z kamery s overlay a tlačítkem pro zachycení.
class CameraScannerScreen extends ConsumerStatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  ConsumerState<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends ConsumerState<CameraScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _hasError = false;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Nejprve požádej o oprávnění ke kameře
      final status = await Permission.camera.request();

      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = status.isPermanentlyDenied
                ? 'Přístup ke kameře byl trvale zamítnut. Povol ho v Nastavení.'
                : 'Pro skenování potřebujeme přístup ke kameře';
          });
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Žádná kamera není k dispozici';
        });
        return;
      }

      // Použij zadní kameru
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } on CameraException catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Chyba kamery: ${e.description}';
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Nepodařilo se inicializovat kameru: $e';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Vibrace při focení
      HapticFeedback.mediumImpact();

      final XFile photo = await _controller!.takePicture();

      // Předej fotku do scanneru a spusť analýzu
      final notifier = ref.read(scannerProvider.notifier);

      // Nastav vybraný obrázek
      await notifier.setImageFromFile(photo);

      // Spusť skenování
      await notifier.scan();

      // Zkontroluj výsledek
      final state = ref.read(scannerProvider);
      if (state.hasResult && mounted) {
        context.go('/scanner/result/${state.result!.id}');
      } else if (state.hasError && mounted) {
        _showError(state.errorMessage ?? 'Chyba při analýze');
        setState(() => _isCapturing = false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Nepodařilo se vyfotit: $e');
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _toggleFlash() async {
    if (_controller == null) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }

    await _controller!.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview nebo loading/error
          _buildCameraPreview(),

          // Overlay s rámečkem
          _buildScanOverlay(),

          // Horní lišta
          _buildTopBar(),

          // Spodní ovládání
          _buildBottomControls(),

          // Loading overlay při focení
          if (_isCapturing) _buildCapturingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Chyba kamery',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Zkusit znovu'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text(
              'Inicializuji kameru...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return CameraPreview(_controller!);
  }

  Widget _buildScanOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanOverlayPainter(),
        child: Container(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(180),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Zpět
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),

            // Název
            const Text(
              'AI SKENER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            // Flash
            IconButton(
              onPressed: _isInitialized ? _toggleFlash : null,
              icon: Icon(_getFlashIcon(), color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(200),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instrukce
            Text(
              'Zamiř na rostlinu a vyfoť',
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Tlačítka
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Galerie
                _ControlButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () async {
                    await ref.read(scannerProvider.notifier).pickFromGallery();
                    final scanState = ref.read(scannerProvider);
                    if (scanState.selectedImage != null && mounted) {
                      // Spusť analýzu
                      setState(() => _isCapturing = true);
                      await ref.read(scannerProvider.notifier).scan();
                      final result = ref.read(scannerProvider);
                      if (result.hasResult && mounted) {
                        context.go('/scanner/result/${result.result!.id}');
                      } else if (result.hasError && mounted) {
                        _showError(result.errorMessage ?? 'Chyba při analýze');
                        setState(() => _isCapturing = false);
                      }
                    }
                  },
                ),

                // Capture button
                _CaptureButton(
                  onTap: _isInitialized && !_isCapturing ? _capturePhoto : null,
                  isCapturing: _isCapturing,
                ),

                // Historie
                _ControlButton(
                  icon: Icons.history,
                  label: 'Historie',
                  onTap: () => context.push('/scanner/history'),
                ),
              ],
            ),

            // Quality Check Guide button
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: OutlinedButton.icon(
                onPressed: () => context.push('/quality-check'),
                icon: const Icon(Icons.verified_user, size: 18),
                label: const Text(
                  'Jak poznat kvalitní trávu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withAlpha(100),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analyzuji...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay painter s rámečkem pro skenování
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(100)
      ..style = PaintingStyle.fill;

    // Velikost scan area
    final scanSize = size.width * 0.75;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2 - 40;

    // Rámeček
    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, scanSize, scanSize),
      const Radius.circular(20),
    );

    // Tmavé pozadí s výřezem
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(scanRect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Rohové značky
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const cornerRadius = 20.0;

    // Levý horní roh
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + cornerRadius)
        ..quadraticBezierTo(left, top, left + cornerRadius, top)
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Pravý horní roh
    canvas.drawPath(
      Path()
        ..moveTo(left + scanSize - cornerLength, top)
        ..lineTo(left + scanSize - cornerRadius, top)
        ..quadraticBezierTo(left + scanSize, top, left + scanSize, top + cornerRadius)
        ..lineTo(left + scanSize, top + cornerLength),
      cornerPaint,
    );

    // Levý dolní roh
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanSize - cornerLength)
        ..lineTo(left, top + scanSize - cornerRadius)
        ..quadraticBezierTo(left, top + scanSize, left + cornerRadius, top + scanSize)
        ..lineTo(left + cornerLength, top + scanSize),
      cornerPaint,
    );

    // Pravý dolní roh
    canvas.drawPath(
      Path()
        ..moveTo(left + scanSize - cornerLength, top + scanSize)
        ..lineTo(left + scanSize - cornerRadius, top + scanSize)
        ..quadraticBezierTo(
            left + scanSize, top + scanSize, left + scanSize, top + scanSize - cornerRadius)
        ..lineTo(left + scanSize, top + scanSize - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tlačítko pro zachycení fotky
class _CaptureButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isCapturing;

  const _CaptureButton({
    required this.onTap,
    required this.isCapturing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCapturing ? AppColors.accent.withAlpha(100) : AppColors.accent,
          ),
          child: isCapturing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(
                  Icons.camera,
                  color: Colors.black,
                  size: 36,
                ),
        ),
      ),
    );
  }
}

/// Ovládací tlačítko (galerie, historie)
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
