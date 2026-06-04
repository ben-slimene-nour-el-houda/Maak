import 'package:flutter/material.dart';

class QueueStatusCard extends StatelessWidget {
  final int currentNumber;
  final int userNumber;

  const QueueStatusCard({
    super.key,
    required this.currentNumber,
    required this.userNumber,
  });

  @override
  Widget build(BuildContext context) {
    final ahead = (userNumber - currentNumber).clamp(0, 999);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('En cours : $currentNumber',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text('Votre numéro : $userNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
              Text(ahead <= 0
                ? "C'est votre tour !"
                : '$ahead personne(s) avant vous',
                style: TextStyle(
                  color: ahead <= 3
                    ? const Color(0xFF4CAF50)
                    : Colors.white70,
                  fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
