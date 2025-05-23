import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import 'edit_book_screen.dart';
// import 'dart:io';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late bool isRead;

  @override
  void initState() {
    super.initState();
    isRead = widget.book.isRead;
  }

  void _toggleReadStatus() {
    setState(() {
      isRead = !isRead;
    });
    Provider.of<BookProvider>(context, listen: false)
        .toggleReadStatus(widget.book.id, isRead); // Add isRead parameter

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRead
            ? 'Buku ditandai sudah dibaca'
            : 'Buku ditandai belum dibaca'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge!.color;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Pustakasaku',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: theme.primaryColor,
          iconTheme: IconThemeData(color: textColor),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBookScreen(book: widget.book),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: textColor,
            labelColor: textColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'INFORMATION'),
              Tab(text: 'NOTES'),
            ],
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: widget.book.coverImageUrl != null && widget.book.coverImageUrl!.isNotEmpty
                            ? Image.network(
                                widget.book.coverImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.book,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(
                                Icons.book,
                                size: 50,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.book.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.book.author,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Categories:', widget.book.category, theme),
                    _buildDetailRow(
                        'Published date:', widget.book.publishedDate, theme),
                    _buildDetailRow('Publisher:', widget.book.publisher, theme),
                    _buildClickableText('${widget.book.pages} pages'),
                    _buildClickableText('ISBN: ${widget.book.isbn}'),
                    _buildDetailRow('Series:', widget.book.series, theme),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRead ? Colors.green : Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _toggleReadStatus,
                      child: Text(
                        isRead ? 'Sudah Dibaca' : 'Belum Dibaca',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Center(
              child: Text(
                'Notes section will be implemented soon.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$label $value',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildClickableText(String text) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
