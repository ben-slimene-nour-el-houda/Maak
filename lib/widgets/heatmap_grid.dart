import 'package:flutter/material.dart';
import '../data/crowd_data.dart';

class HeatmapGrid extends StatelessWidget {
  final Map<String, List<double>> scores; // day → list of scores
  final Function(String day, int slotIndex) onCellTap;

  const HeatmapGrid({
    super.key,
    required this.scores,
    required this.onCellTap,
  });

  Color _colorFromScore(double score) {
    if (score < 40) return const Color(0xFF4CAF50); // green — calm
    if (score < 70) return const Color(0xFFFFC107); // amber — moderate
    return const Color(0xFFF44336);                  // red — busy
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Time slot header row
        Row(
          children: [
            const SizedBox(width: 72),
            ...timeSlotLabels.map((t) => Expanded(
              child: Center(
                child: Text(t,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            )),
          ],
        ),
        const SizedBox(height: 6),
        // One row per day
        ...days.map((day) {
          final dayScores = scores[day] ?? List.filled(timeSlotLabels.length, 50.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(day,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis),
                ),
                ...List.generate(dayScores.length, (i) => Expanded(
                  child: GestureDetector(
                    onTap: () => onCellTap(day, i),
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _colorFromScore(dayScores[i]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          );
        }),
        // Legend
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(const Color(0xFF4CAF50), 'Calme'),
            const SizedBox(width: 16),
            _legendItem(const Color(0xFFFFC107), 'Modéré'),
            const SizedBox(width: 16),
            _legendItem(const Color(0xFFF44336), 'Chargé'),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) => Row(
    children: [
      Container(width: 12, height: 12,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}
