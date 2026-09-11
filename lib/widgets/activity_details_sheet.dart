import 'package:campus_app/models/activity.dart';
import 'package:flutter/material.dart';

Future<void> showActivityDetailsSheet(BuildContext context, Activity activity) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ActivityDetailsSheet(activity: activity),
  );
}

class _ActivityDetailsSheet extends StatelessWidget {
  const _ActivityDetailsSheet({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final locationDetails = <String>[
      if (activity.indoorOutdoor != null) activity.indoorOutdoor!,
      if (activity.building != null) activity.building!,
      if (activity.floor != null) 'Floor ${activity.floor}',
      if (activity.roomOrArea != null) activity.roomOrArea!,
    ];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: activity.category.color,
                  child: Icon(activity.category.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activity.category.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              activity.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (activity.description != null) ...[
              const SizedBox(height: 10),
              Text(activity.description!),
            ],
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.schedule_outlined,
              text:
                  '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(activity.startsAt.toLocal()))}'
                  ' – ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(activity.endsAt.toLocal()))}',
            ),
            if (locationDetails.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.location_on_outlined,
                text: locationDetails.join(' · '),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
