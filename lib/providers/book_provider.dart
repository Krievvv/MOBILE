import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

class BookProvider with ChangeNotifier {
  final List<Book> _books = [];
  List<Book> get books => _books;

  // Toggle read status
  Future<void> toggleReadStatus(String bookId, bool isRead) async {
    try {
      await Supabase.instance.client
          .from('books')
          .update({'is_read': isRead})
          .eq('id', bookId);
      
      final index = _books.indexWhere((book) => book.id == bookId);
      if (index != -1) {
        final updatedBook = Book(
          id: _books[index].id,
          title: _books[index].title,
          author: _books[index].author,
          category: _books[index].category,
          publishedDate: _books[index].publishedDate,
          publisher: _books[index].publisher,
          pages: _books[index].pages,
          isbn: _books[index].isbn,
          series: _books[index].series,
          description: _books[index].description,
          coverImageUrl: _books[index].coverImageUrl,
          isRead: isRead,
          notes: _books[index].notes,
          userId: _books[index].userId,
        );
        _books[index] = updatedBook;
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling read status: $e');
      rethrow;
    }
  }

  // Update book
  Future<void> updateBook(String bookId, Map<String, dynamic> bookData) async {
    try {
      await Supabase.instance.client
          .from('books')
          .update(bookData)
          .eq('id', bookId);
      
      // Update local book list
      await fetchBooks();
      notifyListeners();
    } catch (e) {
      print('Error updating book: $e');
      rethrow;
    }
  }

  // Fetch books
  Future<void> fetchBooks() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('books')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _books.clear();
      _books.addAll(
        (response as List<dynamic>)
            .map((book) => Book.fromJson(book as Map<String, dynamic>))
            .toList(),
      );
      notifyListeners();
    } catch (e) {
      print('Error fetching books: $e');
      rethrow;
    }
  }
}