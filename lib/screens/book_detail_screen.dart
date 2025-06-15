import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import 'edit_book_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late bool isRead;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    isRead = widget.book.isRead;
  }

  Future<void> _toggleReadStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus = !isRead;
      
      // Update in Supabase with user verification
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client
          .from('books')
          .update({'is_read': newStatus})
          .eq('id', widget.book.id)
          .eq('user_id', currentUserId); // Ensure user owns this book

      setState(() {
        isRead = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRead
                ? 'Buku ditandai sudah dibaca ✓'
                : 'Buku ditandai belum dibaca'),
            backgroundColor: isRead ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: const Text('Apakah Anda yakin ingin menghapus buku ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId == null) {
          throw Exception('User not authenticated');
        }

        await Supabase.instance.client
            .from('books')
            .delete()
            .eq('id', widget.book.id)
            .eq('user_id', currentUserId);

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Buku berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error menghapus buku: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
            'Detail Buku',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBookScreen(book: widget.book),
                  ),
                );
                if (result != null && result['updated'] == true) {
                  // Refresh the screen or update the book data
                  setState(() {});
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteBook,
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'INFORMASI'),
              Tab(text: 'CATATAN'),
            ],
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: TabBarView(
          children: [
            _buildInformationTab(theme),
            _buildNotesTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover and Basic Info
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover
                  Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.book.coverImageUrl != null && 
                             widget.book.coverImageUrl!.isNotEmpty
                          ? Image.network(
                              widget.book.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.book,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.book,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Book Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.book.author,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Read Status Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRead ? Colors.green : Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isLoading ? null : _toggleReadStatus,
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(isRead ? Icons.check_circle : Icons.radio_button_unchecked),
                            label: Text(
                              isRead ? 'Sudah Dibaca' : 'Belum Dibaca',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Book Details
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Buku',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Kategori', widget.book.category, Icons.category),
                  _buildDetailRow('Tanggal Terbit', widget.book.publishedDate, Icons.calendar_today),
                  _buildDetailRow('Penerbit', widget.book.publisher, Icons.business),
                  _buildDetailRow('Halaman', '${widget.book.pages} halaman', Icons.description),
                  _buildDetailRow('ISBN', widget.book.isbn, Icons.qr_code),
                  _buildDetailRow('Seri', widget.book.series, Icons.collections_bookmark),
                ],
              ),
            ),
          ),
          
          // Description
          if (widget.book.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deskripsi',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.book.description,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.note_alt, color: Colors.orangeAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Catatan Pribadi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  widget.book.notes.isEmpty 
                      ? 'Belum ada catatan untuk buku ini.\nTambahkan catatan pribadi Anda di sini.'
                      : widget.book.notes,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.book.notes.isEmpty ? Colors.grey : null,
                    fontStyle: widget.book.notes.isEmpty ? FontStyle.italic : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement notes editing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur edit catatan akan segera hadir!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Edit Catatan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
