import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  static int _notificationIdFromTaskId(String taskId) => taskId.hashCode;

  static Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    String? body,
    required DateTime scheduledAt,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    final notificationId = _notificationIdFromTaskId(taskId);

    const androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Lembretes de Tarefas',
      channelDescription: 'Notificações para lembrar sobre tarefas pendentes',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) {
      await initialize();
    }

    await _notificationsPlugin.cancel(_notificationIdFromTaskId(taskId));
  }
}
