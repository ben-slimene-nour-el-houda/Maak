import 'package:flutter/material.dart';
import '../services/optimizer_service.dart';

class RecommendationCard extends StatelessWidget {
  final BestSlot slot;

  const RecommendationCard({super.key, required this.slot});

  String get _waitEstimate {
    if (slot.score < 30) return '~5 min';
    if (slot.score < 50) return '~10 min';
    if (slot.score < 70) return '~20 min';
    return '~30 min+';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D9E75).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF1D9E75), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Color(0xFF1D9E75), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meilleur créneau',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  )),
                const SizedBox(height: 2),
                Text('${slot.day} à ${slot.timeLabel}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  )),
                const SizedBox(height: 2),
                Text('Attente estimée : $_waitEstimate'
                  + (slot.feedbackCount > 0
                    ? ' · basé sur ${slot.feedbackCount} visite(s)'
                    : ' · données historiques'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
