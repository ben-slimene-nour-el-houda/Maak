import '../data/crowd_data.dart';
import 'feedback_service.dart';

class BestSlot {
  final String day;
  final int slotIndex;
  final String timeLabel;
  final double score; // 0–100, lower is better
  final int feedbackCount;

  BestSlot({
    required this.day,
    required this.slotIndex,
    required this.timeLabel,
    required this.score,
    required this.feedbackCount,
  });
}

class OptimizerService {

  // Returns blended score for one slot
  // 60% historical + 40% user feedback (if feedback exists)
  static Future<double> getBlendedScore(
    String office, String day, int slotIndex, String? procedure) async {

    // Base historical score
    double historical = crowdData[office]?[day]?[slotIndex]?.toDouble() ?? 50.0;

    // Apply procedure weight if available
    if (procedure != null && procedureWeights.containsKey(procedure)) {
      final weight = procedureWeights[procedure]?[day] ?? 1.0;
      historical = (historical * weight).clamp(0, 100);
    }

    // Get average user feedback rating for this slot
    // Feedback rating: 1=calm(20), 2=moderate(55), 3=busy(90) → convert to 0–100 score
    final avgRating = await FeedbackService.getAverageRating(office, day, slotIndex);

    if (avgRating == null) return historical; // no feedback yet

    final feedbackScore = (avgRating - 1) / 2 * 100; // 1→0, 2→50, 3→100
    return (historical * 0.6) + (feedbackScore * 0.4);
  }

  // Returns top 3 best slots for a given office and procedure
  static Future<List<BestSlot>> getTopSlots(
    String office, {String? procedure, int top = 3}) async {

    final officeData = crowdData[office];
    if (officeData == null) return [];

    final List<BestSlot> all = [];

    for (final day in days) {
      final slots = officeData[day] ?? [];
      for (int i = 0; i < slots.length; i++) {
        final score = await getBlendedScore(office, day, i, procedure);
        final count = await FeedbackService.getFeedbackCount(office, day, i);
        all.add(BestSlot(
          day: day,
          slotIndex: i,
          timeLabel: timeSlotLabels[i],
          score: score,
          feedbackCount: count,
        ));
      }
    }

    all.sort((a, b) => a.score.compareTo(b.score));
    return all.take(top).toList();
  }

  // Returns ALL scores as a 2D grid [day][slot] for the heatmap
  static Future<Map<String, List<double>>> getHeatmapScores(
    String office, {String? procedure}) async {

    final Map<String, List<double>> result = {};
    final officeData = crowdData[office] ?? {};

    for (final day in days) {
      final slots = officeData[day] ?? List.filled(timeSlotLabels.length, 50);
      final scores = <double>[];
      for (int i = 0; i < slots.length; i++) {
        scores.add(await getBlendedScore(office, day, i, procedure));
      }
      result[day] = scores;
    }
    return result;
  }
}
