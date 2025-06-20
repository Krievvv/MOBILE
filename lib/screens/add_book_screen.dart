import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  _AddBookScreenState createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _seriesController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _publishedDateController = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _pagesController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _coverImageUrlController = TextEditingController();
  
  XFile? _coverImage;
  Uint8List? _coverImageBytes;
  String? _uploadedCoverUrl; // Store uploaded cover URL
  bool _isLoading = false;
  bool _isUploadingImage = false;
  int _currentStep = 0;

  final List<String> _categories = [
    'Fiksi',
    'Non-Fiksi',
    'Biografi',
    'Sejarah',
    'Sains',
    'Teknologi',
    'Bisnis',
    'Self-Help',
    'Romance',
    'Mystery',
    'Fantasy',
    'Horror',
    'Komedi',
    'Drama',
    'Lainnya'
  ];

  Future<void> _pickCoverImage() async {
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
          _coverImage = pickedImage;
          _coverImageUrlController.clear(); // Clear URL when file is selected
        });

        // For web, read bytes immediately for preview
        if (kIsWeb) {
          final bytes = await pickedImage.readAsBytes();
          setState(() {
            _coverImageBytes = Uint8List.fromList(bytes);
          });
        }

        // Upload image immediately after selection
        await _uploadCoverImage();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  Future<void> _takeCoverPhoto() async {
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
          _coverImage = pickedImage;
          _coverImageUrlController.clear(); // Clear URL when file is selected
        });

        // For web, read bytes immediately for preview
        if (kIsWeb) {
          final bytes = await pickedImage.readAsBytes();
          setState(() {
            _coverImageBytes = Uint8List.fromList(bytes);
          });
        }

        // Upload image immediately after selection
        await _uploadCoverImage();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil foto: $e');
    }
  }

  Future<void> _uploadCoverImage() async {
    if (_coverImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final uploadedUrl = await StorageService.uploadBookCover(_coverImage!);
      if (uploadedUrl != null) {
        setState(() {
          _uploadedCoverUrl = uploadedUrl;
        });
        _showSuccessSnackBar('Cover berhasil diupload! ✓');
      } else {
        throw Exception('Upload gagal - URL kosong');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal upload cover: $e');
      // Reset image selection on upload failure
      setState(() {
        _coverImage = null;
        _coverImageBytes = null;
      });
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
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
              'Pilih Sumber Gambar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                    _pickCoverImage();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _takeCoverPhoto();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.link,
                  label: 'URL',
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlDialog();
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

  void _showUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masukkan URL Gambar'),
        content: TextField(
          controller: _coverImageUrlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            // Clear file selection when URL is entered
            if (value.isNotEmpty) {
              setState(() {
                _coverImage = null;
                _coverImageBytes = null;
                _uploadedCoverUrl = null;
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Clear file selection when URL is set
                _coverImage = null;
                _coverImageBytes = null;
                _uploadedCoverUrl = null;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            child: Icon(
              icon,
              color: Colors.orangeAccent,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User tidak terautentikasi');
      }

      // Determine which cover URL to use
      String? finalCoverUrl;
      if (_uploadedCoverUrl != null) {
        finalCoverUrl = _uploadedCoverUrl; // Use uploaded file URL
      } else if (_coverImageUrlController.text.trim().isNotEmpty) {
        finalCoverUrl = _coverImageUrlController.text.trim(); // Use manual URL
      }

      await Supabase.instance.client.from('books').insert({
        'title': _titleController.text.trim(),
        'author': "${_firstnameController.text.trim()} ${_lastnameController.text.trim()}".trim(),
        'category': _categoryController.text.trim(),
        'published_date': _publishedDateController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'pages': int.tryParse(_pagesController.text.trim()) ?? 0,
        'isbn': _isbnController.text.trim(),
        'series': _seriesController.text.trim(),
        'description': _summaryController.text.trim(),
        'cover_image_url': finalCoverUrl,
        'is_read': false,
        'notes': '',
        'user_id': user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buku berhasil ditambahkan! 📚'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      _showErrorSnackBar('Error menambahkan buku: $e');
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      // Validasi untuk setiap langkah
      bool canProceed = false;
      
      switch (_currentStep) {
        case 0:
          // Validasi langkah 1: Informasi Dasar
          canProceed = _titleController.text.trim().isNotEmpty &&
                      _firstnameController.text.trim().isNotEmpty;
          if (!canProceed) {
            _showErrorSnackBar('Mohon lengkapi judul buku dan nama penulis');
            return;
          }
          break;
        case 1:
          // Langkah 2 bisa dilanjutkan tanpa validasi khusus
          canProceed = true;
          break;
      }
      
      if (canProceed) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lastnameController.dispose();
    _firstnameController.dispose();
    _summaryController.dispose();
    _seriesController.dispose();
    _categoryController.dispose();
    _publishedDateController.dispose();
    _publisherController.dispose();
    _pagesController.dispose();
    _isbnController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Buku Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
            onPressed: _isLoading ? null : _saveBook,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orangeAccent.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepTapped: (step) {
              // Hanya bisa pindah ke langkah sebelumnya atau yang sudah divalidasi
              if (step <= _currentStep || step == 0) {
                setState(() {
                  _currentStep = step;
                });
              } else if (step == 1 && _titleController.text.trim().isNotEmpty && 
                         _firstnameController.text.trim().isNotEmpty) {
                setState(() {
                  _currentStep = step;
                });
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    if (details.stepIndex < 2)
                      ElevatedButton.icon(
                        onPressed: _nextStep,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Lanjut'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    if (details.stepIndex == 2)
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveBook,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Buku'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    if (details.stepIndex > 0)
                      TextButton.icon(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Kembali'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Informasi Dasar'),
                content: _buildBasicInfoStep(),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Detail Buku'),
                content: _buildBookDetailsStep(),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : 
                       _currentStep == 1 ? StepState.indexed : StepState.disabled,
              ),
              Step(
                title: const Text('Cover & Deskripsi'),
                content: _buildCoverDescriptionStep(),
                isActive: _currentStep >= 2,
                state: _currentStep == 2 ? StepState.indexed : StepState.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Dasar Buku',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _titleController,
              label: 'Judul Buku',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul buku tidak boleh kosong';
                }
                return null;
              },
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _firstnameController,
                    label: 'Nama Depan Penulis',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama depan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextFormField(
                    controller: _lastnameController,
                    label: 'Nama Belakang Penulis',
                    icon: Icons.person_outline,
                  ),
                ),
              ],
            ),
            _buildDropdownField(
              value: _categoryController.text.isEmpty ? null : _categoryController.text,
              label: 'Kategori',
              icon: Icons.category,
              items: _categories,
              onChanged: (value) {
                setState(() {
                  _categoryController.text = value ?? '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookDetailsStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Publikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _publisherController,
                    label: 'Penerbit',
                    icon: Icons.business,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextFormField(
                    controller: _publishedDateController,
                    label: 'Tahun Terbit',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _pagesController,
                    label: 'Jumlah Halaman',
                    icon: Icons.description,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (int.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextFormField(
                    controller: _isbnController,
                    label: 'ISBN',
                    icon: Icons.qr_code,
                  ),
                ),
              ],
            ),
            _buildTextFormField(
              controller: _seriesController,
              label: 'Seri (Opsional)',
              icon: Icons.collections_bookmark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverDescriptionStep() {
    return Column(
      children: [
        // Cover Image Section
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cover Buku',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _showImageSourceDialog,
                    child: Container(
                      width: 150,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildCoverImage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: _isUploadingImage
                      ? const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Mengupload...'),
                          ],
                        )
                      : TextButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Tambah Cover'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                          ),
                        ),
                ),
                if (_uploadedCoverUrl != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Cover berhasil diupload',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Description Section
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deskripsi Buku',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _summaryController,
                  label: 'Ringkasan/Deskripsi',
                  icon: Icons.description,
                  maxLines: 5,
                  hintText: 'Tulis ringkasan atau deskripsi singkat tentang buku ini...',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverImage() {
  // Priority: 1. Uploaded file, 2. Local file preview, 3. URL, 4. Placeholder
  if (_uploadedCoverUrl != null) {
    return Image.network(
      _uploadedCoverUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
              const SizedBox(height: 8),
              const Text('Memuat...', style: TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  } else if (_coverImage != null) {
    // Show local file preview while uploading
    return kIsWeb
        ? (_coverImageBytes != null
            ? Image.memory(
                _coverImageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : const Center(child: CircularProgressIndicator()))
        : Image.file(
            File(_coverImage!.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
  } else if (_coverImageUrlController.text.isNotEmpty) {
    return Image.network(
      _coverImageUrlController.text,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
              const SizedBox(height: 8),
              const Text('Memuat...', style: TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  } else {
    return _buildPlaceholder();
  }
}

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Tambah Cover',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.orangeAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orangeAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
