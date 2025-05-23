import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:provider/provider.dart';
// import '../providers/book_provider.dart';
import '../models/book.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  _EditBookScreenState createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _categoryController;
  late TextEditingController _publishedDateController;
  late TextEditingController _publisherController;
  late TextEditingController _pagesController;
  late TextEditingController _isbnController;
  late TextEditingController _seriesController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverImageUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _categoryController = TextEditingController(text: widget.book.category);
    _publishedDateController =
        TextEditingController(text: widget.book.publishedDate);
    _publisherController = TextEditingController(text: widget.book.publisher);
    _pagesController =
        TextEditingController(text: widget.book.pages.toString());
    _isbnController = TextEditingController(text: widget.book.isbn);
    _seriesController = TextEditingController(text: widget.book.series);
    _descriptionController =
        TextEditingController(text: widget.book.description);
    _coverImageUrlController = TextEditingController(text: widget.book.coverImageUrl);
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => _isLoading = true);
      
      await Supabase.instance.client.from('books').update({
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'category': _categoryController.text.trim(),
        'published_date': _publishedDateController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'pages': _pagesController.text.trim(),
        'isbn': _isbnController.text.trim(),
        'series': _seriesController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cover_image_url': _coverImageUrlController.text.trim(),
      }).eq('id', widget.book.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating book: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickCoverImage() async {
    // Show dialog to input image URL
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: _coverImageUrlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            labelText: 'Image URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {}); // Refresh the UI to show the new image
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _publishedDateController.dispose();
    _publisherController.dispose();
    _pagesController.dispose();
    _isbnController.dispose();
    _seriesController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Buku'),
        backgroundColor: theme.primaryColor,
        titleTextStyle: TextStyle(
          color: theme.textTheme.bodyLarge!.color,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge!.color),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveChanges,
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Column(
                children: [
                  // Book Cover Image Picker and Preview
                  Center(
                    child: GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildCoverImage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_titleController, 'Judul Buku'),
                  _buildTextField(_authorController, 'Penulis'),
                  _buildTextField(_categoryController, 'Kategori'),
                  _buildTextField(_publishedDateController, 'Tanggal Terbit'),
                  _buildTextField(_publisherController, 'Penerbit'),
                  _buildTextField(_pagesController, 'Halaman',
                      keyboardType: TextInputType.number),
                  _buildTextField(_isbnController, 'ISBN'),
                  _buildTextField(_seriesController, 'Seri'),
                  _buildTextField(_descriptionController, 'Deskripsi',
                      maxLines: 3),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Simpan Perubahan'),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (_coverImageUrlController.text.isNotEmpty) {
      return Image.network(
        _coverImageUrlController.text,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image,
          size: 50,
          color: Colors.grey,
        ),
      );
    } else {
      return const Icon(
        Icons.add_a_photo,
        size: 50,
        color: Colors.grey,
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: controller.text.trim().isEmpty && label == 'Judul Buku' || label == 'Penulis'
            ? 'This field cannot be empty'
            : null,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
}