import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../services/activity_repository.dart';

/// Provides a single ActivityRepository instance to the app.
///
/// Widgets and other providers can access this with:
///
/// ref.read(activityRepositoryProvider)
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

/// Retrieves all activities whose ticket_status is currently "Pending".
///
/// This data comes directly from Supabase through ActivityRepository.
///
/// The admin dashboard watches this provider so that it automatically receives:
/// - loading state
/// - error state
/// - pending activity data
final pendingActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final repository = ref.watch(activityRepositoryProvider);

  return repository.fetchPendingActivities();
});
