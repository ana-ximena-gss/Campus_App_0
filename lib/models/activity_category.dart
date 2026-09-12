import 'package:flutter/material.dart';

/// A category available when a student creates a temporary campus activity.
///
/// [id] is stored in Supabase. Keep it stable if the display label changes.
class ActivityCategory {
  const ActivityCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;

  static const sports = ActivityCategory(
    id: 'sports',
    label: 'Sports',
    icon: Icons.sports_soccer_outlined,
    color: Color(0xFF2E7D32),
  );

  static const physicalGames = ActivityCategory(
    id: 'physical_games',
    label: 'Physical games',
    icon: Icons.sports_basketball_outlined,
    color: Color(0xFF1565C0),
  );

  static const cardBoardGames = ActivityCategory(
    id: 'card_board_games',
    label: 'Card/board games',
    icon: Icons.casino_outlined,
    color: Color(0xFF6A1B9A),
  );

  static const social = ActivityCategory(
    id: 'social',
    label: 'Social',
    icon: Icons.people_outline,
    color: Color(0xFFE65100),
  );

  static const study = ActivityCategory(
    id: 'study',
    label: 'Study',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF00695C),
  );

  static const sellingTrading = ActivityCategory(
    id: 'selling_trading',
    label: 'Selling/trading',
    icon: Icons.swap_horiz_outlined,
    color: Color(0xFFAD1457),
  );

  static const clubsOrganizations = ActivityCategory(
    id: 'clubs_organizations',
    label: 'Clubs/organizations',
    icon: Icons.groups_outlined,
    color: Color(0xFF283593),
  );

  static const general = ActivityCategory(
    id: 'general',
    label: 'General',
    icon: Icons.campaign_outlined,
    color: Color(0xFF455A64),
  );

  static const other = ActivityCategory(
    id: 'other',
    label: 'Other',
    icon: Icons.more_horiz,
    color: Color(0xFF616161),
  );

  static const all = <ActivityCategory>[
    sports,
    physicalGames,
    cardBoardGames,
    social,
    study,
    sellingTrading,
    clubsOrganizations,
    general,
    other,
  ];

  static ActivityCategory fromId(String id) {
    for (final category in all) {
      if (category.id == id) {
        return category;
      }
    }

    return other;
  }
}