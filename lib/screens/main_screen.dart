import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../providers/book_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/book_card.dart';
import 'profile_screen.dart';
import '../screens/add_book_screen.dart';

import 'package:peoject_uas/models/book.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final supabaseClient = supabase.Supabase.instance.client;

    final List<Widget> _screens = [
      HomeScreen(bookProvider: bookProvider, onNavigate: _onItemTapped),
      ProfileScreen(
        totalBooks: bookProvider.books.length,
        booksRead: bookProvider.books.where((book) => book.isRead).length,
      ),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final BookProvider bookProvider;
  final Function(int) onNavigate;

  const HomeScreen({
    super.key,
    required this.bookProvider,
    required this.onNavigate,
  });

  Future<List<Map<String, dynamic>>> fetchBooks() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      
      // Get current user ID
      final currentUserId = supabaseClient.auth.currentUser?.id;
      
      if (currentUserId == null) {
        return []; // Return empty list if no user is logged in
      }

      final response = await supabaseClient
          .from('books')
          .select()
          .eq('user_id', currentUserId) // Filter by user_id
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> books = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      return books;
    } catch (error) {
      print('Error fetching books: $error');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pustakasaku"),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: themeProvider.themeMode == ThemeMode.dark
                ? const Icon(Icons.dark_mode)
                : const Icon(Icons.light_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.orangeAccent),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(1);
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            // child: Text(
            //   "${bookProvider.books.length} koleksi buku anda",
            //   style: const TextStyle(color: Colors.grey, fontSize: 14),
            // ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBooks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final booksMap = snapshot.data ?? [];
                final books = booksMap
                    .map((json) => Book.fromJson(json as Map<String, dynamic>))
                    .toList();

                if (books.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada buku!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return isWideScreen
                    ? GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2 / 3,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return BookCard(book: book);
                        },
                      )
                    : ListView.builder(
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index]; // langsung objek Book
                          return BookCard(book: book);
                        },
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBookScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}