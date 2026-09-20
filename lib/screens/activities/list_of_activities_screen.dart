import 'package:campus_app/models/activity.dart';
import 'package:campus_app/services/activity_repository.dart';
import 'package:campus_app/widgets/logout_button.dart';
import 'package:flutter/material.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({
    super.key,
    required this.onViewOnMap,
  });

  final ValueChanged<Activity> onViewOnMap;

  @override
  State<ActivityListScreen> createState() =>
      _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final ActivityRepository _activityRepository =
      ActivityRepository();

  late Future<List<Activity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();

    _activitiesFuture = _loadActivities();
  }

  Future<List<Activity>> _loadActivities() {
    return _activityRepository.fetchRecentAndActiveActivities(
      campus: 'edinburg',
    );
  }

  Future<void> _refreshActivities() async {
    final future = _loadActivities();

    setState(() {
      _activitiesFuture = future;
    });

    await future;
  }

  bool _isExpired(Activity activity) {
    return activity.endsAt.toLocal().isBefore(
      DateTime.now(),
    );
  }

  int _daysSinceEnded(Activity activity) {
    final now = DateTime.now();
    final ended = activity.endsAt.toLocal();

    final difference = now.difference(ended);

    return difference.inDays;
  }

  String _endedLabel(Activity activity) {
    final now = DateTime.now();
    final ended = activity.endsAt.toLocal();

    final difference = now.difference(ended);

    if (difference.inHours < 1) {
      return 'Spark ended recently';
    }

    if (difference.inDays == 0) {
      final hours = difference.inHours;

      if (hours == 1) {
        return 'Spark ended 1 hour ago';
      }

      return 'Spark ended $hours hours ago';
    }

    final days = _daysSinceEnded(activity);

    if (days == 1) {
      return 'Spark ended 1 day ago';
    }

    return 'Spark ended $days days ago';
  }

  String _formatTimeRange(Activity activity) {
    final localizations =
        MaterialLocalizations.of(context);

    final start = activity.startsAt.toLocal();
    final end = activity.endsAt.toLocal();

    final startDate =
        localizations.formatMediumDate(start);

    final endDate =
        localizations.formatMediumDate(end);

    final startTime =
        localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(start),
    );

    final endTime =
        localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(end),
    );

    if (startDate == endDate) {
      return '$startDate • $startTime – $endTime';
    }

    return '$startDate $startTime – '
        '$endDate $endTime';
  }

  String _formatLocation(Activity activity) {
    final parts = <String>[
      if (activity.building != null &&
          activity.building!.trim().isNotEmpty)
        activity.building!.trim(),

      if (activity.floor != null &&
          activity.floor!.trim().isNotEmpty)
        'Floor ${activity.floor!.trim()}',

      if (activity.roomOrArea != null &&
          activity.roomOrArea!.trim().isNotEmpty)
        activity.roomOrArea!.trim(),
    ];

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    return '${activity.latitude.toStringAsFixed(5)}, '
        '${activity.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: const [
          LogoutButton(),
          SizedBox(width: 8),
        ],
      ),

      body: FutureBuilder<List<Activity>>(
        future: _activitiesFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .error,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Could not load activities',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: _refreshActivities,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text(
                        'Try again',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final activities =
              snapshot.data ?? const <Activity>[];

          if (activities.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshActivities,

              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(24),

                children: const [
                  SizedBox(height: 120),

                  Icon(
                    Icons.event_busy_outlined,
                    size: 72,
                  ),

                  SizedBox(height: 16),

                  Text(
                    'No activities',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Current activities and activity history '
                    'from the last 3 days will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshActivities,

            child: ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(16),

              itemCount: activities.length,

              separatorBuilder: (_, _) =>
                  const SizedBox(height: 12),

              itemBuilder: (context, index) {
                final activity =
                    activities[index];

                return _buildActivityCard(
                  activity,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(
    Activity activity,
  ) {
    final expired = _isExpired(activity);

    final normalTextColor =
        Theme.of(context).colorScheme.onSurface;

    final textColor = expired
        ? Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.45)
        : normalTextColor;

    final cardColor = expired
        ? Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45)
        : null;

    return Card(
      color: cardColor,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                CircleAvatar(
                  backgroundColor: expired
                      ? Colors.grey
                      : activity.category.color,

                  child: Icon(
                    activity.category.icon,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        activity.title,

                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                              color: textColor,
                            ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        activity.category.label,

                        style: TextStyle(
                          color: textColor,
                        ),
                      ),

                      if (expired) ...[
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: textColor,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              _endedLabel(activity),

                              style: TextStyle(
                                color: textColor,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (activity.description != null &&
                activity.description!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(
                activity.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: textColor,
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 20,
                  color: textColor,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _formatTimeRange(activity),

                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: textColor,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _formatLocation(activity),

                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),

            if (!expired) ...[
              const SizedBox(height: 16),

              Align(
                alignment:
                    Alignment.centerRight,

                child: FilledButton.icon(
                  onPressed: () {
                    widget.onViewOnMap(
                      activity,
                    );
                  },

                  icon: const Icon(
                    Icons.map_outlined,
                  ),

                  label: const Text(
                    'View on map',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}