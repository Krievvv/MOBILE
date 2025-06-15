import 'package:flutter/material.dart';
import '../models/book.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  _EditBookScreenState createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publishedDateController = TextEditingController();
  final _pagesController = TextEditingController();
  final _isbnController = TextEditingController();
  final _seriesController = TextEditingController();
  final _coverImageUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing book data
    _titleController.text = widget.book.title;
    _authorController.text = widget.book.author;
    _descriptionController.text = widget.book.description;
    _categoryController.text = widget.book.category;
    _publisherController.text = widget.book.publisher;
    _publishedDateController.text = widget.book.publishedDate;
    _pagesController.text = widget.book.pages.toString();
    _isbnController.text = widget.book.isbn;
    _seriesController.text = widget.book.series;
    _coverImageUrlController.text = widget.book.coverImageUrl ?? '';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare cover image URL - trim whitespace and validate
      String? coverImageUrl = _coverImageUrlController.text.trim();
      if (coverImageUrl.isEmpty) {
        coverImageUrl = null;
      }

      print('Updating book with cover URL: $coverImageUrl');

      // Update the book in Supabase with user verification
      await Supabase.instance.client
          .from('books')
          .update({
            'title': _titleController.text.trim(),
            'author': _authorController.text.trim(),
            'description': _descriptionController.text.trim(),
            'category': _categoryController.text.trim(),
            'publisher': _publisherController.text.trim(),
            'published_date': _publishedDateController.text.trim(),
            'pages': int.tryParse(_pagesController.text.trim()) ?? 0,
            'isbn': _isbnController.text.trim(),
            'series': _seriesController.text.trim(),
            'cover_image_url': coverImageUrl,
          })
          .eq('id', widget.book.id)
          .eq('user_id', currentUserId); // Ensure user owns this book

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buku berhasil diperbarui ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, {
          'updated': true,
          'book': widget.book,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memperbarui buku: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previewCoverImage() {
    final url = _coverImageUrlController.text.trim();
    if (url.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Preview Cover'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(50),
                    child: Column(
                      children: [
                        const Icon(Icons.error, size: 50, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Gagal memuat gambar:\n$error'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _publisherController.dispose();
    _publishedDateController.dispose();
    _pagesController.dispose();
    _isbnController.dispose();
    _seriesController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Buku',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Preview
              Center(
                child: Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildCoverPreview(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
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
              
              _buildTextFormField(
                controller: _authorController,
                label: 'Penulis',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama penulis tidak boleh kosong';
                  }
                  return null;
                },
              ),
              
              _buildTextFormField(
                controller: _categoryController,
                label: 'Kategori',
                icon: Icons.category,
              ),
              
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
                label: 'Seri',
                icon: Icons.collections_bookmark,
              ),
              
              // Cover Image URL with preview button
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _coverImageUrlController,
                      label: 'URL Gambar Cover',
                      icon: Icons.image,
                      onChanged: (value) {
                        // Trigger rebuild to update preview
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _previewCoverImage,
                    icon: const Icon(Icons.preview, color: Colors.orangeAccent),
                    tooltip: 'Preview Cover',
                  ),
                ],
              ),
              
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Deskripsi',
                icon: Icons.description,
                maxLines: 4,
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveChanges,
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
                  label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Perubahan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPreview() {
    final url = _coverImageUrlController.text.trim();
    
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 30, color: Colors.grey),
              const SizedBox(height: 4),
              Text(
                'URL tidak valid',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (widget.book.coverImageUrl != null && widget.book.coverImageUrl!.isNotEmpty) {
      return Image.network(
        widget.book.coverImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.book, size: 50, color: Colors.grey),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.book, size: 50, color: Colors.grey),
      );
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orangeAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }
}
