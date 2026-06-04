import 'dart:async';
import 'package:flutter/material.dart';
import '../models/detected_text_target.dart';

/// Panneau de résultats d'analyse affiché sous forme de messages clairs
/// Thème adapté au design Maak (bleu/blanc)
class ARAnalysisResultPanel extends StatefulWidget {
  final List<DetectedTextTarget> targets;
  final DetectedTextTarget? selectedTarget;
  final String searchKeyword;
  final bool isProcessing;
  final Function(DetectedTextTarget) onTargetSelected;

  const ARAnalysisResultPanel({
    super.key,
    required this.targets,
    required this.selectedTarget,
    required this.searchKeyword,
    required this.isProcessing,
    required this.onTargetSelected,
  });

  @override
  State<ARAnalysisResultPanel> createState() => _ARAnalysisResultPanelState();
}

class _ARAnalysisResultPanelState extends State<ARAnalysisResultPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<DetectedTextTarget> _previousTargets = [];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    if (widget.targets.isNotEmpty) _entryController.forward();
  }

  @override
  void didUpdateWidget(ARAnalysisResultPanel old) {
    super.didUpdateWidget(old);
    if (widget.targets.length != _previousTargets.length ||
        (widget.targets.isNotEmpty &&
            (old.targets.isEmpty ||
                widget.targets.first.id != old.targets.first.id))) {
      _entryController.forward(from: 0);
    }
    _previousTargets = List.from(widget.targets);
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // Maak colors
  static const Color maakBlue = Color(0xFF1E40AF);
  static const Color maakTeal = Color(0xFF1D9E75);
  static const Color maakLightBlue = Color(0xFF60A5FA);

  @override
  Widget build(BuildContext context) {
    if (widget.isProcessing && widget.targets.isEmpty) {
      return _buildLoadingMessage();
    }
    if (widget.targets.isEmpty) {
      return _buildEmptyMessage();
    }
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _buildResultsMessage(),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maakBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: maakBlue.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.image_search, color: maakLightBlue, size: 17),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analyse en cours…',
                    style: TextStyle(
                        color: maakLightBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                Text('Reconnaissance des textes dans l\'image',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: maakLightBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_off, color: Colors.white38, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aucun texte détecté',
                    style: TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                Text('Pointez la caméra vers un panneau ou un texte',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsMessage() {
    final matches = widget.targets.where((t) => t.isMatch).toList();
    final others = widget.targets.where((t) => !t.isMatch).toList();
    final hasMatch = matches.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasMatch
              ? maakTeal.withValues(alpha: 0.8)
              : maakBlue.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasMatch
                ? maakTeal.withValues(alpha: 0.2)
                : maakBlue.withValues(alpha: 0.1),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(hasMatch, matches.length, others.length),
          const Divider(color: Colors.white10, height: 1),
          
          // Constrained list with rolling animation
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (hasMatch) ...[
                    _buildSectionLabel('🛸  CIBLE IDENTIFIÉE', maakTeal),
                    ...List.generate(matches.length, (i) {
                      return _buildAnimatedTile(matches[i], i, isHighlighted: true);
                    }),
                  ],
                  if (others.isNotEmpty) ...[
                    _buildSectionLabel('📡  DÉTECTIONS SECONDAIRES (${others.length})', maakLightBlue),
                    ...List.generate(others.length.clamp(0, 6), (i) {
                      return _buildAnimatedTile(others[i], i + (hasMatch ? matches.length : 0));
                    }),
                    if (others.length > 6)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          '+ ${others.length - 6} AUTRES FLUX DÉTECTÉS',
                          style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTile(DetectedTextTarget target, int index, {bool isHighlighted = false}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: _buildTargetTile(target, isHighlighted: isHighlighted),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool hasMatch, int matchCount, int otherCount) {
    final total = matchCount + otherCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: hasMatch
                    ? [maakTeal, const Color(0xFF157A5A)]
                    : [maakBlue, const Color(0xFF1E3A8A)],
              ),
            ),
            child: Icon(
              hasMatch ? Icons.check_circle_outline : Icons.text_fields,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasMatch
                      ? '$matchCount correspondance${matchCount > 1 ? 's' : ''} trouvée${matchCount > 1 ? 's' : ''}'
                      : 'Analyse terminée',
                  style: TextStyle(
                    color: hasMatch ? maakTeal : maakLightBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  '$total texte${total > 1 ? 's' : ''} détecté${total > 1 ? 's' : ''} dans l\'image',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatTime(DateTime.now()),
              style: const TextStyle(
                  color: Colors.white38, fontSize: 9, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildTargetTile(DetectedTextTarget target,
      {bool isHighlighted = false}) {
    final isSelected = widget.selectedTarget?.id == target.id;
    final confidence = (target.confidence * 100).toInt();

    Color confidenceColor;
    if (confidence >= 85) {
      confidenceColor = maakTeal;
    } else if (confidence >= 60) {
      confidenceColor = const Color(0xFFFFCC00);
    } else {
      confidenceColor = const Color(0xFFFF6B6B);
    }

    return GestureDetector(
      onTap: () => widget.onTargetSelected(target),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isHighlighted
                  ? maakTeal.withValues(alpha: 0.12)
                  : maakBlue.withValues(alpha: 0.10))
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isHighlighted
                    ? maakTeal.withValues(alpha: 0.5)
                    : maakBlue.withValues(alpha: 0.4))
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isHighlighted ? Icons.verified : Icons.text_snippet_outlined,
              color: isHighlighted ? maakTeal : Colors.white38,
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.text,
                    style: TextStyle(
                      color: isHighlighted ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isHighlighted
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isHighlighted && widget.searchKeyword.isNotEmpty)
                    Text(
                      'Contient: "${widget.searchKeyword}"',
                      style: const TextStyle(color: maakTeal, fontSize: 9),
                    ),
                ],
              ),
            ),
            _buildConfidenceBar(confidence, confidenceColor),
            const SizedBox(width: 6),
            if (isSelected)
              const Icon(Icons.my_location, color: maakLightBlue, size: 13)
            else
              const Icon(Icons.chevron_right, color: Colors.white24, size: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$percent%',
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 32,
            height: 3,
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
