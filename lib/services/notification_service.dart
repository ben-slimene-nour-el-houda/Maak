import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<void> showTurnAlert(int peopleAhead) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'queue_channel', 'Queue Alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      0,
      'Votre tour approche',
      'Plus que $peopleAhead personne(s) avant vous — préparez vos documents.',
      details,
    );
  }
}
