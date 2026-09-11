import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';

/// Reads temporary map activities from Supabase.
///
/// Activity creation and editing can be added here later, so database calls do
/// not spread through map widgets.
class ActivityRepository {
  ActivityRepository({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Returns activities that are active at [now]. The database is the source
  /// of truth: cancelled, future, and expired records are excluded here.
  Future<List<Activity>> fetchActiveActivities({
    required String campus,
    DateTime? now,
  }) async {
    final activeAt = (now ?? DateTime.now()).toUtc().toIso8601String();

    final rows = await _supabase
        .from('activities')
        .select()
        .isFilter('cancelled_at', null)
        .eq('campus', campus)
        .lte('starts_at', activeAt)
        .gt('ends_at', activeAt)
        .order('starts_at');

    return (rows as List<dynamic>)
        .map((row) => Activity.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Creates an activity for the currently authenticated Supabase user.
  ///
  /// The activities migration assigns creator_id from auth.uid(), so this
  /// method intentionally never accepts a creator ID from the UI.
  Future<Activity> createActivity(ActivityDraft draft) async {
    if (_supabase.auth.currentUser == null) {
      throw StateError('You must be signed in to create an activity.');
    }

    final row = await _supabase
        .from('activities')
        .insert(draft.toInsertMap())
        .select()
        .single();

    return Activity.fromMap(row);
  }
}
