import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? currentProfile;

  const EditProfileScreen({super.key, this.currentProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  XFile? _pickedImage;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _currentAvatarUrl;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.currentProfile != null) {
      _usernameController.text = widget.currentProfile!.username;
      _fullNameController.text = widget.currentProfile!.fullName ?? '';
      _bioController.text = widget.currentProfile!.bio ?? '';
      _currentAvatarUrl = widget.currentProfile!.avatarUrl;
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.trim().isEmpty) return;
    
    // Don't check if it's the same as current username
    if (widget.currentProfile?.username == username.trim()) {
      setState(() {
        _usernameError = null;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final isAvailable = await ProfileService.checkUsernameAvailable(
        username.trim(),
        excludeUserId: widget.currentProfile?.id,
      );

      if (mounted) {
        setState(() {
          _usernameError = isAvailable ? null : 'Username sudah digunakan';
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameError = 'Error memeriksa username';
          _isCheckingUsername = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        setState(() {
          _pickedImage = pickedImage;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        setState(() {
          _pickedImage = pickedImage;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil foto: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _testStorageConnection() async {
    try {
      final isConnected = await StorageService.testStorageConnection();
      if (!isConnected) {
        _showErrorSnackBar('Storage bucket "avatars" tidak ditemukan. Jalankan script SQL terlebih dahulu.');
      } else {
        _showErrorSnackBar('Koneksi storage berhasil!');
      }
    } catch (e) {
      _showErrorSnackBar('Error testing storage: $e');
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
            ),
            child: Icon(icon, color: Colors.orangeAccent, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameError != null) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl = _currentAvatarUrl;

      // Upload new avatar if selected
      if (_pickedImage != null) {
        print('Uploading new avatar...');
        try {
          avatarUrl = await StorageService.uploadAvatar(_pickedImage!);
          print('Avatar uploaded successfully: $avatarUrl');
        } catch (uploadError) {
          print('Avatar upload failed: $uploadError');
          // Show specific upload error but continue with profile save
          _showErrorSnackBar('Upload foto gagal: ${uploadError.toString()}');
          // Don't return here, continue saving profile without new avatar
        }
      }

      UserProfile? updatedProfile;

      if (widget.currentProfile == null) {
        // Create new profile
        updatedProfile = await ProfileService.createProfile(
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
          avatarUrl: avatarUrl,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        );
      } else {
        // Update existing profile
        updatedProfile = await ProfileService.updateProfile(
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
          avatarUrl: avatarUrl,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        );
      }

      if (updatedProfile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedProfile);
      } else {
        throw Exception('Gagal menyimpan profil');
      }
    } catch (e) {
      print('Profile save error: $e');
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.currentProfile == null ? 'Buat Profil' : 'Edit Profil',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile Picture
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImage() == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Username Field (Required)
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username *',
                  prefixIcon: const Icon(Icons.person, color: Colors.orangeAccent),
                  suffixIcon: _isCheckingUsername 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameError == null && _usernameController.text.isNotEmpty
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  errorText: _usernameError,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  if (value.trim().length < 3) {
                    return 'Username minimal 3 karakter';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Debounce username checking
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_usernameController.text == value) {
                      _checkUsernameAvailability(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Full Name Field (Optional)
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.badge, color: Colors.orangeAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),

              // Bio Field (Optional)
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: const Icon(Icons.info, color: Colors.orangeAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _usernameError != null) ? null : _saveProfile,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Profil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Debug button (remove in production)
              if (kDebugMode)
                TextButton(
                  onPressed: _testStorageConnection,
                  child: const Text('Test Storage Connection'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_pickedImage != null) {
      if (kIsWeb) {
        return NetworkImage(_pickedImage!.path);
      } else {
        return FileImage(File(_pickedImage!.path));
      }
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      return NetworkImage(_currentAvatarUrl!);
    }
    return null;
  }
}
