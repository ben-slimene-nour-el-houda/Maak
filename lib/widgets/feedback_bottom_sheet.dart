import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../data/crowd_data.dart';

class FeedbackBottomSheet extends StatelessWidget {
  final String office;
  final String day;
  final int slotIndex;

  const FeedbackBottomSheet({
    super.key,
    required this.office,
    required this.day,
    required this.slotIndex,
  });

  void _submit(BuildContext context, int rating) async {
    await FeedbackService.saveFeedback(FeedbackModel(
      office: office,
      day: day,
      timeSlotIndex: slotIndex,
      rating: rating,
      timestamp: DateTime.now(),
    ));
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Merci ! Votre retour améliore les prochaines recommandations.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("C'était comment aujourd'hui ?",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$office · $day à ${timeSlotLabels[slotIndex]}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ratingButton(context, '🟢', 'Calme', 1),
              _ratingButton(context, '🟡', 'Modéré', 2),
              _ratingButton(context, '🔴', 'Chargé', 3),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _ratingButton(BuildContext context, String emoji, String label, int rating) {
    return GestureDetector(
      onTap: () => _submit(context, rating),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
