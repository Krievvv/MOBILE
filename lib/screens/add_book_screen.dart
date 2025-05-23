import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  _AddBookScreenState createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _seriesController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _publishedDateController =
      TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _pagesController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _coverImageUrlController = TextEditingController();
  XFile? _coverImage;
  Uint8List? _coverImageBytes;
  bool _isLoading = false;

  Future<void> _pickCoverImage() async {
    setState(() {
      _isLoading = true;
    });

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
          if (kIsWeb) {
            pickedImage.readAsBytes().then((bytes) {
              setState(() {
                _coverImageBytes = Uint8List.fromList(bytes);
              });
            });
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBook() async {
    try {
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client.from('books').insert({
        'title': _titleController.text.trim(),
        'author': "${_firstnameController.text.trim()} ${_lastnameController.text.trim()}",
        'category': _categoryController.text.trim(),
        'published_date': _publishedDateController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'pages': int.parse(_pagesController.text.trim()), // Convert string to integer
        'isbn': _isbnController.text.trim(),
        'series': _seriesController.text.trim(),
        'description': _summaryController.text.trim(),
        'cover_image_url': _coverImageUrlController.text.trim(),
        'is_read': false,
        'notes': '',
        'user_id': user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding book: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(
          'Pustakasaku',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: textColor),
            onPressed: _saveBook,
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      child: _coverImage != null
                          ? kIsWeb
                              ? (_coverImageBytes != null
                                  ? Image.memory(
                                      _coverImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : const CircularProgressIndicator())
                              : Image.file(
                                  File(_coverImage!.path),
                                  fit: BoxFit.cover,
                                )
                          : const Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(_titleController, 'Title'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          _firstnameController, 'Firstname'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(_lastnameController, 'Lastname'),
                    ),
                  ],
                ),
                _buildTextField(_summaryController, 'Summary', maxLines: 3),
                _buildTextField(_seriesController, 'Series'),
                _buildTextField(_categoryController, 'Category'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          _publishedDateController, 'Published Date'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(_publisherController, 'Publisher'),
                    ),
                  ],
                ),
                _buildTextField(_pagesController, 'Pages',
                    keyboardType: TextInputType.number),
                _buildTextField(_isbnController, 'ISBN'),
                _buildTextField(_coverImageUrlController, 'Cover Image URL'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveBook,
                    child: const Text('OK'),
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: controller.text.trim().isEmpty && (label == 'Title' || label == 'Firstname')
            ? 'This field cannot be empty'
            : null,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
}