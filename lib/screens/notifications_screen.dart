import 'dart:async';

import 'package:campus_app/services/activity_notification.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState(); }

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final ActivityNotificationService _notificationService =
      ActivityNotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _loadNotifications();

    // check once every minute while this screen is open.
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadNotifications(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try { final notifications = await _notificationService.fetchNotifications();

      if (!mounted) { return; }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) { return; }

      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _markAsRead(
    AppNotification notification,
  ) async {
    if (notification.isRead) { return; }

    await _notificationService.markAsRead( notification.id, );

    await _loadNotifications();
  }

  Future<void> _clearAll() async {
    final ids = _notifications
        .map((notification) => notification.id)
        .toList();

    await _notificationService.clearNotification( ids, );

    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),

        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Unable to load notifications.\n$_error',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          'You’re all caught up.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,

      child: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount: _notifications.length,

        separatorBuilder: (_, _) =>
            const SizedBox(height: 8),

        itemBuilder: (context, index) {
          final notification =
              _notifications[index];

          return Card(
            color: notification.isRead
                ? null
                : Theme.of(context)
                    .colorScheme
                    .primaryContainer,

            child: ListTile(
              onTap: () => _markAsRead(notification),
                  
              leading: Icon(
                _iconForNotification(
                  notification.type,
                ),
              ),

              title: Text(
                notification.title,

                style: TextStyle(
                  fontWeight:
                      notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                ),
              ),

              subtitle: Text(
                notification.message,
              ),

              // Small dot = unread.
              trailing: notification.isRead
                  ? null
                  : const Icon(
                      Icons.circle,
                      size: 10,
                    ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForNotification(
    AppNotificationType type,
  ) {
    switch (type) {
      case AppNotificationType.startingSoon:
        return Icons.schedule;

      case AppNotificationType.requestUpdate:
        return Icons.assignment_turned_in;
    }
  }
}