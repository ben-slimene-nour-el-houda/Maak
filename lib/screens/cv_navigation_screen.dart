import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/text_recognition_service.dart';
import '../services/ar_navigation_service.dart';
import '../models/detected_text_target.dart';
import '../widgets/ar_arrow_overlay.dart';
import '../widgets/ar_text_detection_overlay.dart';
import '../widgets/ar_analysis_result_panel.dart';

class CVNavigationScreen extends StatefulWidget {
  /// Guichet cible pré-rempli depuis l'optimizer (optionnel)
  final String? targetGuichet;

  /// Numéro de file de l'utilisateur (optionnel)
  final int? userQueueNumber;

  const CVNavigationScreen({
    super.key,
    this.targetGuichet,
    this.userQueueNumber,
  });

  @override
  State<CVNavigationScreen> createState() => _CVNavigationScreenState();
}

class _CVNavigationScreenState extends State<CVNavigationScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ── Camera ──────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isScanning = false;
  Timer? _processingTimer;
  late TextEditingController _searchController;

  // ── Services ────────────────────────────────────────────────────
  late TextRecognitionService _textService;
  late ARNavigationService _arService;

  // ── State ───────────────────────────────────────────────────────
  List<DetectedTextTarget> _detectedTargets = [];
  DetectedTextTarget? _selectedTarget;
  DetectedTextTarget? _actualTarget; // Real detection
  double _smoothX = 0;
  double _smoothY = 0;
  double _smoothAngle = 0;
  DateTime? _lastTargetSeen;
  Ticker? _ticker;
  late String _searchKeyword;

  // ── Animations ──────────────────────────────────────────────────
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _arrowController;
  late AnimationController _radarController;

  // ── Colors (Maak design) ────────────────────────────────────────
  static const Color _maakBlue = Color(0xFF1E40AF);
  static const Color _maakDarkBlue = Color(0xFF1E3A8A);
  static const Color _maakTeal = Color(0xFF1D9E75);
  static const Color _maakLight = Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-fill keyword from optimizer
    _searchKeyword = widget.targetGuichet ?? '';
    _searchController = TextEditingController(text: _searchKeyword);
    _initAnimations();
    _initServices();
    _initTicker();
    _requestPermissionsAndInit();
  }

  void _initTicker() {
    _ticker = createTicker((elapsed) {
      if (_actualTarget != null) {
        setState(() {
          // Lerp position
          final destX = _actualTarget!.centerX;
          final destY = _actualTarget!.centerY;

          if (_smoothX == 0) {
            _smoothX = destX;
            _smoothY = destY;
          } else {
            _smoothX = _smoothX + (destX - _smoothX) * 0.15;
            _smoothY = _smoothY + (destY - _smoothY) * 0.15;
          }

          // Calculate angle for smooth arrow
          const imageWidth = 720.0;
          const imageHeight = 1280.0;
          final size = MediaQuery.of(context).size;
          final tx = (_smoothX / imageWidth) * size.width;
          final ty = (_smoothY / imageHeight) * size.height;
          final dx = tx - (size.width / 2);
          final dy = ty - (size.height / 2);
          final targetAngle = math.atan2(dx, -dy);

          // Smooth angle (handle wrap-around)
          _smoothAngle = _smoothAngle + (targetAngle - _smoothAngle) * 0.1;

          // Hysteresis check
          if (_lastTargetSeen != null &&
              DateTime.now().difference(_lastTargetSeen!).inMilliseconds >
                  1200) {
            _selectedTarget = null;
            _actualTarget = null;
            _smoothX = 0;
            _smoothY = 0;
          } else {
            // Update selected target with smoothed coordinates for the UI
            _selectedTarget = _actualTarget!.copyWith(
              centerX: _smoothX,
              centerY: _smoothY,
            );
          }
        });
      }
    });
    _ticker!.start();
  }

  void _initAnimations() {
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _initServices() {
    _textService = TextRecognitionService();
    _arService = ARNavigationService();
    _arService.startListening();
  }

  Future<void> _requestPermissionsAndInit() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _initCamera();
    } else {
      _showPermissionDialog();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await _cameraController!.initialize();

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _detectedTargets = [];
      _selectedTarget = null;
    });
    _processingTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _captureAndAnalyze();
    });
  }

  void _stopScanning() {
    setState(() => _isScanning = false);
    _processingTimer?.cancel();
  }

  Future<void> _captureAndAnalyze() async {
    if (_isProcessing || _cameraController == null || !_isInitialized) return;
    if (!_cameraController!.value.isInitialized) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      final targets = await _textService.analyzeImage(
        image.path,
        keyword: _searchKeyword,
      );

      if (mounted) {
        setState(() {
          _detectedTargets = targets;
          if (targets.isNotEmpty && _searchKeyword.isNotEmpty) {
            final match = targets.firstWhere(
              (t) => t.isMatch,
              orElse: () => targets.first,
            );
            _actualTarget = match;
            _lastTargetSeen = DateTime.now();
          }
        });
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _selectTarget(DetectedTextTarget target) =>
      setState(() => _selectedTarget = target);

  void _setSearchKeyword(String keyword) {
    setState(() {
      _searchKeyword = keyword;
      _selectedTarget = null;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Permission caméra requise',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'L\'accès à la caméra est nécessaire pour la navigation AR.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _maakTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Ouvrir Paramètres',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null) return;
    if (state == AppLifecycleState.inactive) {
      _stopScanning();
      _isInitialized = false;
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _processingTimer?.cancel();
    _searchController.dispose();
    _isInitialized = false;
    _cameraController?.dispose();
    _textService.dispose();
    _arService.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    _arrowController.dispose();
    _radarController.dispose();
    _ticker?.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ① Camera preview
          if (_isInitialized && _cameraController != null) ...[
            Positioned.fill(child: CameraPreview(_cameraController!)),
            // Data Vision Overlay (Subtle Scanlines)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ScanlinePainter(),
                ),
              ),
            ),
          ] else
            const Center(
              child: CircularProgressIndicator(color: _maakLight),
            ),

          // ② Scan line animation
          if (_isScanning) ...[
            _buildScanLine(),
            _buildRadarHUD(),
            _buildTechnicalTelemetry(),
          ],

          // ③ Detection Stream Log (Rolling telemetry)
          if (_isScanning && _detectedTargets.isNotEmpty)
            _buildDetectionLog(),

          // ③ Corner frame decoration
          _buildCornerFrame(),

          // ④ Text bounding-box overlay
          if (_detectedTargets.isNotEmpty)
            ARTextDetectionOverlay(
              targets: _detectedTargets,
              selectedTarget: _selectedTarget,
              onTargetTap: _selectTarget,
              pulseAnimation: _pulseController,
            ),

          // ⑤ AR Arrow overlay
          if (_selectedTarget != null)
            ARArrowOverlay(
              target: _selectedTarget!,
              arService: _arService,
              arrowAnimation: _arrowController,
              smoothAngle: _smoothAngle,
            ),

          // ⑥ Processing indicator
          if (_isProcessing) _buildProcessingBadge(),

          // ⑦ Bottom control panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlPanel(),
          ),

          // ⑧ Top status bar (with back button)
          _buildTopBar(),
        ],
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _scanLineController,
      builder: (_, __) {
        final screenH = MediaQuery.of(context).size.height;
        final y = _scanLineController.value * screenH * 0.7;
        return Positioned(
          top: y + screenH * 0.1,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                height: 1,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: _maakLight.withValues(alpha: 0.8),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _maakLight.withValues(alpha: 0.15),
                      _maakLight.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadarHUD() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Center Crosshair
            Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _maakLight.withValues(alpha: 0.2), width: 0.5),
                ),
                child: CustomPaint(
                  painter: _CrosshairPainter(
                      color: _maakLight.withValues(alpha: 0.5)),
                ),
              ),
            ),
            // Rotating Radar
            Center(
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (_, __) {
                  return Transform.rotate(
                    angle: _radarController.value * 2 * 3.14159,
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: _RadarPainter(color: _maakLight.withValues(alpha: 0.8)),
                    ),
                  );
                },
              ),
            ),
            // Radar Degree Markers
            Center(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: _RadarMarkerPainter(color: _maakLight.withValues(alpha: 0.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalTelemetry() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _telemetryItem('AZIMUTH', '${(_smoothAngle * 180 / 3.14).toStringAsFixed(1)}°'),
          _telemetryItem('LATENCY', '${_isProcessing ? 142 : 44}ms'),
          _telemetryItem('PITCH', '12.4°'),
          _telemetryItem('YAW', '2.1°'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _maakTeal.withValues(alpha: 0.2),
              border: Border.all(color: _maakTeal.withValues(alpha: 0.5)),
            ),
            child: const Text('STREAM ACTIVE: 60FPS', 
              style: TextStyle(color: _maakTeal, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
  
  Widget _telemetryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label:', style: TextStyle(color: _maakLight.withValues(alpha: 0.5), fontSize: 9, fontFamily: 'monospace')),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(color: _maakLight, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildDetectionLog() {
    return Positioned(
      left: 20,
      bottom: 180,
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 180,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: _maakLight.withValues(alpha: 0.4), width: 1.5)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LOCAL_CV_STREAM_LOG:', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ..._detectedTargets.take(3).map((t) => Text(
              '> DETECTED: ${t.text.toUpperCase()}', 
              style: const TextStyle(color: Colors.white70, fontSize: 8, fontFamily: 'monospace', overflow: TextOverflow.ellipsis),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerFrame() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _CornerFramePainter(
            color: _isScanning ? _maakLight : _maakBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingBadge() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 56,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _maakLight.withValues(alpha: 0.6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _maakLight),
            ),
            SizedBox(width: 8),
            Text('Analyse…',
                style: TextStyle(
                    color: _maakLight, fontSize: 11, fontFamily: 'monospace')),
          ],
        ),
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
          top: MediaQuery.of(context).padding.top + 4,
          left: 8,
          right: 16,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button styled to match Maak
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            // Maak logo dot
            Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: _maakTeal),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Navigation AR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (widget.targetGuichet != null)
                  Text(
                    'Cible : ${widget.targetGuichet}',
                    style: TextStyle(
                        color: _maakLight.withValues(alpha: 0.9), fontSize: 11),
                  ),
              ],
            ),
            const Spacer(),
            // Detected count badge
            if (_detectedTargets.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _maakBlue.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _maakLight.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${_detectedTargets.length} texte(s)',
                  style: const TextStyle(
                      color: _maakLight, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(23),
                        border:
                            Border.all(color: _maakBlue.withValues(alpha: 0.4)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un guichet…',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 13),
                          prefixIcon: const Icon(Icons.search,
                              color: _maakLight, size: 18),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onChanged: _setSearchKeyword,
                        onSubmitted: (_) {
                          if (_isScanning) _captureAndAnalyze();
                        },
                      ),
                    ),
                  ),
                  if (_searchKeyword.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _setSearchKeyword('');
                      },
                      child: Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: _maakBlue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.redAccent, size: 18),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Manual capture
                  _actionButton(
                    icon: Icons.camera_alt,
                    onTap: _captureAndAnalyze,
                    size: 52,
                    color: Colors.white.withValues(alpha: 0.1),
                    borderColor: Colors.white30,
                    iconColor: Colors.white70,
                  ),

                  const SizedBox(width: 24),

                  // Scan toggle (main CTA)
                  GestureDetector(
                    onTap: _isScanning ? _stopScanning : _startScanning,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isScanning
                              ? [
                                  Colors.red.shade700,
                                  Colors.red.shade900,
                                ]
                              : [_maakBlue, _maakDarkBlue],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isScanning ? Colors.red : _maakBlue)
                                .withValues(alpha: 0.45),
                            blurRadius: 22,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isScanning ? Icons.stop : Icons.radar,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Count badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_detectedTargets.length}',
                          style: const TextStyle(
                            color: _maakLight,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text('textes',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 8,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
    required Color color,
    required Color borderColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, color: iconColor, size: size * 0.42),
      ),
    );
  }
}

// ── Corner frame painter (using Maak palette) ─────────────────────────────

class _CornerFramePainter extends CustomPainter {
  final Color color;
  _CornerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 32.0;
    const margin = 20.0;

    // Top-left
    canvas.drawLine(
        Offset(margin, margin + len), Offset(margin, margin), paint);
    canvas.drawLine(
        Offset(margin, margin), Offset(margin + len, margin), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - margin - len, margin),
        Offset(size.width - margin, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin, margin + len), paint);

    // Bottom-left
    canvas.drawLine(Offset(margin, size.height - margin - len),
        Offset(margin, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin + len, size.height - margin), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - margin - len, size.height - margin),
        Offset(size.width - margin, size.height - margin), paint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin - len),
        Offset(size.width - margin, size.height - margin), paint);
  }

  @override
  bool shouldRepaint(_CornerFramePainter old) => old.color != color;
}

// ── Radar painters ───────────────────────────────────────────────────────

class _RadarMarkerPainter extends CustomPainter {
  final Color color;
  _RadarMarkerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 360; i += 30) {
      final angle = i * 3.14159 / 180;
      final x1 = cx + math.cos(angle) * 130;
      final y1 = cy + math.sin(angle) * 130;
      final x2 = cx + math.cos(angle) * 140;
      final y2 = cy + math.sin(angle) * 140;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarPainter extends CustomPainter {
  final Color color;
  _RadarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.2, 0.25, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    // Circular ticks
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, tickPaint);
    canvas.drawCircle(center, radius * 0.6, tickPaint);
    canvas.drawCircle(center, radius * 0.2, tickPaint);

    // Cardinal lines
    for (int i = 0; i < 4; i++) {
      final angle = i * 3.14159 / 2;
      canvas.drawLine(
        center +
            Offset(math.cos(angle) * (radius * 0.9),
                math.sin(angle) * (radius * 0.9)),
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        tickPaint..color = color.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => false;
}

// ── Crosshair Painter ──────────────────────────────────────────────────────

class _CrosshairPainter extends CustomPainter {
  final Color color;
  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    const len = 8.0;
    const gap = 4.0;

    canvas.drawLine(Offset(center.dx, center.dy - gap - len),
        Offset(center.dx, center.dy - gap), paint);
    canvas.drawLine(Offset(center.dx, center.dy + gap),
        Offset(center.dx, center.dy + gap + len), paint);
    canvas.drawLine(Offset(center.dx - gap - len, center.dy),
        Offset(center.dx - gap, center.dy), paint);
    canvas.drawLine(Offset(center.dx + gap, center.dy),
        Offset(center.dx + gap + len, center.dy), paint);
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => false;
}

// ── Scanline Painter ──────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Subtle vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.2),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}
