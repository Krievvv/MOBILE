import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../providers/book_provider.dart';
// import '../models/book.dart';
// import 'book_detail_screen.dart';
// import 'dart:io';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  late Future<List<Map<String, dynamic>>> _booksFuture;
  Future<List<Map<String, dynamic>>> _fetchBooks() async {
    try {
      final response =
          await supabase.Supabase.instance.client.from('books').select();

      // Validasi data
      if (response is List) {
        return response.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Unexpected data format');
      }
    } catch (e) {
      // Bisa digunakan untuk logging atau error UI
      throw Exception('Failed to fetch books: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _booksFuture = _fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Koleksi Buku - Pustakasaku',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final books = snapshot.data!;
          if (books.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada buku di koleksi Anda.\nTambahkan buku baru!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book['title'] ?? 'No title'),
                subtitle: Text(book['author'] ?? 'No author'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-book');
          Provider.of<BookProvider>(context, listen: false)
              .fetchBooks(); // Refresh the list after adding a new book
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBookCover(String? coverImageUrl) {
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      return Image.network(
        coverImageUrl,
        width: 50,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.book,
          size: 50,
          color: Colors.grey,
        ),
      );
    } else {
      return const Icon(
        Icons.book,
        size: 50,
        color: Colors.grey,
      );
    }
  }
}
