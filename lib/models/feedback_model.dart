class FeedbackModel {
  final int? id;
  final String office;
  final String day;
  final int timeSlotIndex;
  final int rating; // 1 = calm, 2 = moderate, 3 = busy
  final DateTime timestamp;

  FeedbackModel({
    this.id,
    required this.office,
    required this.day,
    required this.timeSlotIndex,
    required this.rating,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'office': office,
    'day': day,
    'time_slot_index': timeSlotIndex,
    'rating': rating,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FeedbackModel.fromMap(Map<String, dynamic> map) => FeedbackModel(
    id: map['id'],
    office: map['office'],
    day: map['day'],
    timeSlotIndex: map['time_slot_index'],
    rating: map['rating'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
