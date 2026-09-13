import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<String> _collegeOptions = [
    'ART',
    'STEM',
    'Health Science',
  ];

  String? _username;
  String? _email;
  String? _selectedCollege;

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'No user is currently signed in.';
          _isLoading = false;
        });

        return;
      }

      final profile = await _supabase
          .from('profiles')
          .select('username, email, college')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      final savedCollege = profile['college'] as String?;

      setState(() {
        _username = profile['username'] as String?;
        _email = profile['email'] as String?;

        if (savedCollege != null &&
            _collegeOptions.contains(savedCollege)) {
          _selectedCollege = savedCollege;
        } else {
          _selectedCollege = null;
        }

        _isLoading = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCollege() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _errorMessage = 'No user is currently signed in.';
      });

      return;
    }

    if (_selectedCollege == null) {
      setState(() {
        _errorMessage = 'Please select a college.';
        _successMessage = null;
      });

      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _supabase
          .from('profiles')
          .update({
            'college': _selectedCollege,
          })
          .eq('id', user.id);

      if (!mounted) return;

      setState(() {
        _successMessage = 'College saved successfully.';
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _loadUserProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(),
                ),
              ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        const Center(
          child: CircleAvatar(
            radius: 50,
            child: Icon(
              Icons.person,
              size: 60,
            ),
          ),
        ),

        const SizedBox(height: 18),

        Center(
          child: Text(
            _username ?? 'No username',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Center(
          child: Text(
            _email ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),

        const SizedBox(height: 28),

        Card(
          child: ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Username'),
            subtitle: Text(
              _username ?? 'Not available',
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('UTRGV Email'),
            subtitle: Text(
              _email ?? 'Not available',
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'College',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        DropdownButtonFormField<String>(
          value: _selectedCollege,
          decoration: const InputDecoration(
            labelText: 'Select your college',
            prefixIcon: Icon(Icons.school_outlined),
            border: OutlineInputBorder(),
          ),
          items: _collegeOptions.map((college) {
            return DropdownMenuItem<String>(
              value: college,
              child: Text(college),
            );
          }).toList(),
          onChanged: _isSaving
              ? null
              : (value) {
                  setState(() {
                    _selectedCollege = value;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                },
        ),

        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: _isSaving ? null : _saveCollege,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            _isSaving ? 'Saving...' : 'Save college',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),

        if (_successMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _successMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green.shade900,
              ),
            ),
          ),
        ],

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],

        const SizedBox(height: 30),
      ],
    );
  }
}