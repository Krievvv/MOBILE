import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'edit_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final int totalBooks;
  final int booksRead;

  const ProfileScreen({
    super.key,
    required this.totalBooks,
    required this.booksRead,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  Map<String, int> _bookStats = {'total': 0, 'read': 0, 'unread': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBookStats();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBookStats() async {
    try {
      final stats = await ProfileService.getBookStats();
      if (mounted) {
        setState(() {
          _bookStats = stats;
        });
      }
    } catch (e) {
      print('Error loading book stats: $e');
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentProfile: _userProfile),
      ),
    );

    if (result != null && result is UserProfile) {
      setState(() {
        _userProfile = result;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Use pushNamedAndRemoveUntil to clear the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _navigateToEditProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _userProfile?.avatarUrl != null
                          ? NetworkImage(_userProfile!.avatarUrl!)
                          : null,
                      child: _userProfile?.avatarUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userProfile?.username ?? 'Username',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_userProfile?.fullName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _userProfile!.fullName!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _userProfile!.bio!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Book Statistics
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistik Buku',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Total Buku',
                          _bookStats['total'].toString(),
                          Icons.library_books,
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Sudah Dibaca',
                          _bookStats['read'].toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Belum Dibaca',
                          _bookStats['unread'].toString(),
                          Icons.schedule,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.orangeAccent),
                      title: const Text('Edit Profil'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _navigateToEditProfile,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.grey),
                      title: const Text('Pengaturan'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur pengaturan akan segera hadir!'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: const Text('Apakah Anda yakin ingin keluar?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _signOut();
                                },
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Keluar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
