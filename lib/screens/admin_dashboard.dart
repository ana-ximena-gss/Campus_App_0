import 'package:campus_app/screens/map_screen.dart';
import 'package:campus_app/widgets/logout_button.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<_PlaceholderTicket> _tickets = [
    _PlaceholderTicket(
      id: 'activity-001',
      creatorId: 'user-001',
      title: 'Volleyball at the REC',
      description: 'Looking for students to play volleyball this afternoon.',
      category: 'social',
      campus: 'edinburg',
      latitude: 26.304551,
      longitude: -98.174165,
      startsAt: DateTime.now().add(const Duration(hours: 1)),
      endsAt: DateTime.now().add(const Duration(hours: 3)),
      indoorOutdoor: 'indoor',
      building: 'UREC',
      floor: '1',
      roomOrArea: 'Volleyball Court',
    ),
    _PlaceholderTicket(
      id: 'activity-002',
      creatorId: 'user-002',
      title: 'Computer Science Study Group',
      description: 'Study session before the upcoming exam.',
      category: 'academic',
      campus: 'edinburg',
      latitude: 26.304800,
      longitude: -98.173900,
      startsAt: DateTime.now().add(const Duration(hours: 2)),
      endsAt: DateTime.now().add(const Duration(hours: 4)),
      indoorOutdoor: 'indoor',
      building: 'EENGR',
      floor: '1',
      roomOrArea: '1.300',
    ),
    _PlaceholderTicket(
      id: 'activity-003',
      creatorId: 'user-003',
      title: 'Chess Meetup',
      description: 'Casual meetup. Beginners welcome.',
      category: 'social',
      campus: 'brownsville',
      latitude: 25.892910,
      longitude: -97.489224,
      startsAt: DateTime.now().add(const Duration(hours: 1)),
      endsAt: DateTime.now().add(const Duration(hours: 2)),
      indoorOutdoor: 'indoor',
      building: 'Student Union',
      floor: '1',
      roomOrArea: 'Lobby',
    ),
  ];

  void _onNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _acceptTicket(_PlaceholderTicket ticket) {
    setState(() {
      _tickets.remove(ticket);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ticket.title} accepted'),
      ),
    );
  }

  void _rejectTicket(_PlaceholderTicket ticket) {
    setState(() {
      _tickets.remove(ticket);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ticket.title} rejected'),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final localizations = MaterialLocalizations.of(context);

    return '${localizations.formatMediumDate(value)} '
        '${localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
    )}';
  }

  String _formatCampus(String campus) {
    switch (campus) {
      case 'brownsville':
        return 'Brownsville';
      case 'edinburg':
        return 'Edinburg';
      default:
        return campus;
    }
  }

  String _formatIndoorOutdoor(String? value) {
    switch (value) {
      case 'indoor':
        return 'Indoor';
      case 'outdoor':
        return 'Outdoor';
      default:
        return 'Not provided';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTicketScreen(),
          const MapScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  Widget _buildTicketScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: const [
          LogoutButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Approval Tickets',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_tickets.length} pending',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _tickets.isEmpty
                  ? const _EmptyTicketView()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tickets.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];

                        return _TicketCard(
                          ticket: ticket,
                          formattedCampus: _formatCampus(ticket.campus),
                          formattedStart: _formatDateTime(ticket.startsAt),
                          formattedEnd: _formatDateTime(ticket.endsAt),
                          formattedIndoorOutdoor:
                              _formatIndoorOutdoor(ticket.indoorOutdoor),
                          onAccept: () => _acceptTicket(ticket),
                          onReject: () => _rejectTicket(ticket),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.formattedCampus,
    required this.formattedStart,
    required this.formattedEnd,
    required this.formattedIndoorOutdoor,
    required this.onAccept,
    required this.onReject,
  });

  final _PlaceholderTicket ticket;
  final String formattedCampus;
  final String formattedStart;
  final String formattedEnd;
  final String formattedIndoorOutdoor;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.id,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Chip(
                  avatar: Icon(
                    Icons.schedule,
                    size: 16,
                  ),
                  label: Text('Pending'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              ticket.description ?? 'No description provided.',
            ),

            const SizedBox(height: 20),

            _TicketDetail(
              icon: Icons.person_outline,
              label: 'Creator ID',
              value: ticket.creatorId,
            ),

            const SizedBox(height: 8),

            _TicketDetail(
              icon: Icons.category_outlined,
              label: 'Category',
              value: ticket.category,
            ),

            const SizedBox(height: 8),

            _TicketDetail(
              icon: Icons.school_outlined,
              label: 'Campus',
              value: formattedCampus,
            ),

            const SizedBox(height: 8),

            _TicketDetail(
              icon: Icons.location_on_outlined,
              label: 'Coordinates',
              value:
                  '${ticket.latitude.toStringAsFixed(6)}, '
                  '${ticket.longitude.toStringAsFixed(6)}',
            ),

            const SizedBox(height: 8),

            _TicketDetail(
              icon: Icons.place_outlined,
              label: 'Type',
              value: formattedIndoorOutdoor,
            ),

            if (ticket.building != null) ...[
              const SizedBox(height: 8),
              _TicketDetail(
                icon: Icons.apartment_outlined,
                label: 'Building',
                value: ticket.building!,
              ),
            ],

            if (ticket.floor != null) ...[
              const SizedBox(height: 8),
              _TicketDetail(
                icon: Icons.layers_outlined,
                label: 'Floor',
                value: ticket.floor!,
              ),
            ],

            if (ticket.roomOrArea != null) ...[
              const SizedBox(height: 8),
              _TicketDetail(
                icon: Icons.meeting_room_outlined,
                label: 'Room / Area',
                value: ticket.roomOrArea!,
              ),
            ],

            const SizedBox(height: 8),

            _TicketDetail(
              icon: Icons.schedule_outlined,
              label: 'Starts',
              value: formattedStart,
            ),

            const SizedBox(height: 8),

            _TicketDetail(
              icon: Icons.schedule_outlined,
              label: 'Ends',
              value: formattedEnd,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetail extends StatelessWidget {
  const _TicketDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}

class _EmptyTicketView extends StatelessWidget {
  const _EmptyTicketView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending tickets',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'New student event submissions will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTicket {
  const _PlaceholderTicket({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.category,
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

  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final String category;
  final String campus;
  final double latitude;
  final double longitude;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? indoorOutdoor;
  final String? building;
  final String? floor;
  final String? roomOrArea;
}
