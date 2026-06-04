class ChatAction {
  final String label;
  final String route;
  final String? payload;

  const ChatAction({
    required this.label,
    required this.route,
    this.payload,
  });
}
