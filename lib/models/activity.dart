import 'activity_category.dart';

/// A temporary, student-created activity displayed on the campus map.
///
/// This is intentionally separate from a permanent campus location.
class Activity {
  const Activity({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.campus,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.endsAt,
    required this.indoorOutdoor,
    required this.building,
    required this.floor,
    required this.roomOrArea,
    required this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final String categoryId;
  final String campus;
  final double latitude;
  final double longitude;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? indoorOutdoor;
  final String? building;
  final String? floor;
  final String? roomOrArea;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityCategory get category => ActivityCategory.fromId(categoryId);

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as String,
      creatorId: map['creator_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['category'] as String,
      campus: map['campus'] as String,
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      startsAt: DateTime.parse(map['starts_at'] as String),
      endsAt: DateTime.parse(map['ends_at'] as String),
      indoorOutdoor: map['indoor_outdoor'] as String?,
      building: map['building'] as String?,
      floor: map['floor'] as String?,
      roomOrArea: map['room_or_area'] as String?,
      cancelledAt: _asDateTime(map['cancelled_at']),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static DateTime? _asDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value as String);
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.parse(value);
    }

    throw FormatException('Expected a numeric activity coordinate.');
  }
}

/// Validated input for a new temporary activity before it is sent to Supabase.
///
/// The database assigns the activity ID, timestamps, and authenticated creator.
class ActivityDraft {
  const ActivityDraft({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.campus,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.endsAt,
    required this.indoorOutdoor,
    required this.building,
    required this.floor,
    required this.roomOrArea,
  });

  final String title;
  final String? description;
  final String categoryId;
  final String campus;
  final double latitude;
  final double longitude;
  final DateTime startsAt;
  final DateTime endsAt;
  final String indoorOutdoor;
  final String? building;
  final String? floor;
  final String? roomOrArea;

  Map<String, Object?> toInsertMap() {
    return {
      'title': title,
      'description': description,
      'category': categoryId,
      'campus': campus,
      'latitude': latitude,
      'longitude': longitude,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'indoor_outdoor': indoorOutdoor,
      'building': building,
      'floor': floor,
      'room_or_area': roomOrArea,
    };
  }
}
