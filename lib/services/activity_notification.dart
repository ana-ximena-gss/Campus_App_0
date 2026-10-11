import 'package:supabase_flutter/supabase_flutter.dart';

enum AppNotificationType {
  startingSoon,
  requestUpdate,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime time;
  final AppNotificationType type;
  final bool isRead;

  // Creates a copy of the current notification only changing isRead
  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      time: time,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ActivityNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AppNotification>> fetchNotifications() async {
    final user = _supabase.auth.currentUser;

    // Nobody is signed in.
    if (user == null) { return []; }

    final notifications = <AppNotification>[];

    // Get the two types of notifications. (add more types here in the future if needed)
    await _getStartingSoonNotifications(
      user.id,
      notifications,
    );

    await _getRequestStatusNotifications(
      user.id,
      notifications,
    );

    // Find what notifications have been read or cleared by the user.
    final states = await _getNotificationStates(user.id);

    final visibleNotifications = <AppNotification>[];

    for (final notification in notifications) {
      final state = states[notification.id];

      // Was never read or cleared
      if (state == null) {
        visibleNotifications.add(notification);
        continue;
      }

      final isCleared = state['is_cleared'] as bool? ?? false;

      // If the notification was cleared, don't show it.
      if (isCleared) { continue; }

      final isRead = state['is_read'] as bool? ?? false;

      visibleNotifications.add(
        notification.copyWith(isRead: isRead),
      );
    }

    // Newest / soonest notifications first.
    visibleNotifications.sort( (a, b) => b.time.compareTo(a.time), );

    return visibleNotifications;
  }

  Future<void> markAsRead(
  String notificationId,
  ) async {
    final user = _supabase.auth.currentUser;

    if (user == null) { return; }

    await _supabase
        .from('notification_states')
        .upsert(  // Insert or update the notification state for this user and notification.
          {
            'user_id': user.id,
            'notification_id': notificationId,
            'is_read': true,
          },
          onConflict: 'user_id,notification_id',
        );
  }

  Future<void> clearNotification(
    List<String> notificationIds,
  ) async {
    final user = _supabase.auth.currentUser;

    if (user == null || notificationIds.isEmpty) { return; }

    final rows = notificationIds.map( (id) {
      return {
        'user_id': user.id,
        'notification_id': id,
        'is_read': true,
        'is_cleared': true,
      };
    }).toList();

    await _supabase
        .from('notification_states')
        .upsert(
          rows,
          onConflict: 'user_id,notification_id',
        );
  }
  // ------------------------------------------------------------
  // ACTIVITIES THE USER JOINED
  // ------------------------------------------------------------
  Future<void> _getStartingSoonNotifications(
    String userId,
    List<AppNotification> notifications,
  ) async {
    final rows = await _supabase
        .from('profiles_activities')
        .select('''
          activity_id,
          activities (
            id,
            title,
            starts_at,
            cancelled_at
          )
        ''')
        .eq('profile_id', userId);

    final now = DateTime.now();
    final fifteenMinutesFromNow = now.add( const Duration(minutes: 15) );

    for (final row in rows) {
      final activity = row['activities'];

      if (activity == null) { continue; }

      // Ignore cancelled activities.
      if (activity['cancelled_at'] != null) { continue; }

      final startsAt = DateTime.parse(
        activity['starts_at'] as String,
      );

      // Activity must be:
      // after right now
      // AND
      // no later than 15 minutes from now
      final startsSoon =
          startsAt.isAfter(now) &&
          !startsAt.isAfter(fifteenMinutesFromNow);

      if (!startsSoon) { continue; }

      final minutesLeft = startsAt.difference(now).inMinutes + 1;

      notifications.add(
        AppNotification(
          id: 'starting-${activity['id']}-${startsAt.toIso8601String()}',
          title: '${activity['title']} starts soon!',
          message: 'Starts in about $minutesLeft minutes.',
          time: startsAt,
          type: AppNotificationType.startingSoon,
        ),
      );
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getNotificationStates(
  String userId,
) async {
  final rows = await _supabase
      .from('notification_states')
      .select(
        'notification_id, is_read, is_cleared',
      )
      .eq('user_id', userId);

  final states = <String, Map<String, dynamic>>{};

  for (final row in rows) {
    states[row['notification_id'] as String] = row;
  }
  return states;
}

  // ------------------------------------------------------------
  // ACTIVITY REQUEST ACCEPTED / DECLINED
  // ------------------------------------------------------------
  Future<void> _getRequestStatusNotifications(
    String userId,
    List<AppNotification> notifications,
  ) async {
    final rows = await _supabase
        .from('activities')
        .select('''
          id,
          title,
          ticket_status,
          updated_at
        ''')
        .eq('creator_id', userId);

    for (final activity in rows) {
      final status = activity['ticket_status'].toString();

      // Pending means no decision has been made yet.
      if (status.toLowerCase() == 'pending') { continue; }

      final updatedAt = DateTime.parse(
        activity['updated_at'] as String,
      );

      notifications.add(
        AppNotification(
          id: 'request-${activity['id']}-${status.toLowerCase()}',
          title: 'Activity request updated',
          message:
              '"${activity['title']}" is now $status.',
          time: updatedAt,
          type: AppNotificationType.requestUpdate,
        ),
      );
    }
  }
  // for the Unread count (show how many notifications are unread on the bell icon)
  Future<int> fetchUnreadCount() async {
  final notifications = await fetchNotifications();

  return notifications
      .where((notification) => !notification.isRead)
      .length;
}
}