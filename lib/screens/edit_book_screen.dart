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

  bool _isValidImageUrl(String url) {
    if (url.trim().isEmpty) return false;
  
    try {
      final uri = Uri.parse(url.trim());
      // Accept any URL with http or https scheme
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
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

      // Prepare cover image URL - trim whitespace
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
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan URL gambar terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Preview Cover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image Preview Area
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildPreviewImage(url),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // URL Display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'URL:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              url,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Info Message
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jika preview gagal, gambar tetap akan disimpan dan ditampilkan di aplikasi',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close),
                              label: Text('Tutup'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _saveChanges();
                              },
                              icon: Icon(Icons.save),
                              label: Text('Simpan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9,id;q=0.8',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
                SizedBox(height: 16),
                Text(
                  'Memuat gambar...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Image loading error: $error');
        return Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.orange,
              ),
              SizedBox(height: 16),
              Text(
                'Preview tidak tersedia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Gambar mungkin memiliki pembatasan akses atau format khusus',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '✓ URL akan tetap disimpan dan gambar akan ditampilkan di aplikasi',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUrlHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tips URL Gambar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Semua URL gambar akan diterima dan disimpan'),
              SizedBox(height: 8),
              Text('✅ Format yang didukung:'),
              Text('  • .jpg, .jpeg, .png, .gif, .webp, .bmp'),
              Text('  • URL dari berbagai sumber'),
              SizedBox(height: 12),
              Text('ℹ️ Catatan Penting:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Preview mungkin tidak selalu berhasil'),
              Text('• Gambar tetap akan disimpan meskipun preview gagal'),
              Text('• Aplikasi akan mencoba menampilkan gambar saat digunakan'),
              SizedBox(height: 12),
              Text('🔧 Jika preview gagal:'),
              Text('• Pastikan URL lengkap dan benar'),
              Text('• Coba salin-tempel URL dari browser'),
              Text('• Gambar tetap akan tersimpan untuk digunakan'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Buku',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
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
              SizedBox(height: 24),

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
                  SizedBox(width: 12),
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
                  SizedBox(width: 12),
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
              
              // Cover Image URL with preview and help buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _previewCoverImage,
                        icon: Icon(Icons.preview, color: Colors.orangeAccent),
                        tooltip: 'Preview Cover',
                      ),
                      IconButton(
                        onPressed: _showUrlHelp,
                        icon: Icon(Icons.help_outline, color: Colors.grey),
                        tooltip: 'Tips URL',
                      ),
                    ],
                  ),
                  if (_coverImageUrlController.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green[600], size: 16),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '✓ URL akan disimpan dan gambar akan ditampilkan di aplikasi',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Deskripsi',
                icon: Icons.description,
                maxLines: 4,
              ),
              
              SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveChanges,
                  icon: _isLoading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.save),
                  label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Perubahan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
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
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                  SizedBox(height: 8),
                  Text('Memuat...', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                SizedBox(height: 4),
                Text(
                  'Preview tidak\ntersedia',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Gambar tetap\nakan disimpan',
                  style: TextStyle(fontSize: 8, color: Colors.green[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } else if (widget.book.coverImageUrl != null && widget.book.coverImageUrl!.isNotEmpty) {
      return Image.network(
        widget.book.coverImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: Icon(Icons.book, size: 50, color: Colors.grey),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Icon(Icons.book, size: 50, color: Colors.grey),
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
      padding: EdgeInsets.only(bottom: 16.0),
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
            borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
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
