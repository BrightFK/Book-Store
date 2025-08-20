import 'package:book_store/main.dart';
import 'package:book_store/models/book_model.dart';
import 'package:book_store/screens/detailed_book_screen.dart';
import 'package:flutter/material.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  late Future<List<Book>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _fetchWishlistBooks();
  }

  Future<List<Book>> _fetchWishlistBooks() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }

    final wishlistResponse = await supabase
        .from('wishlist_items')
        .select('book_id')
        .eq('user_id', userId);

    if (wishlistResponse.isEmpty) {
      return [];
    }

    final bookIds = wishlistResponse
        .map((item) => item['book_id'] as String)
        .toList();

    // Now, fetch all book details where the ID is in our list of wishlisted IDs
    final booksResponse = await supabase
        .from('books')
        .select()
        // --- THE CORRECT FIX BASED ON YOUR DOCUMENTATION ---
        .inFilter('id', bookIds);

    return booksResponse.map((json) => Book.fromJson(json)).toList();
  }

  Future<void> _removeFromWishlist(String bookId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('wishlist_items').delete().match({
      'user_id': userId,
      'book_id': bookId,
    });

    setState(() {
      _wishlistFuture = _fetchWishlistBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Book>>(
      future: _wishlistFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Your library is empty.\nStart exploring to add books!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final wishlistedBooks = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: wishlistedBooks.length,
          itemBuilder: (context, index) {
            final book = wishlistedBooks[index];
            return _buildWishlistItem(book);
          },
        );
      },
    );
  }

  Widget _buildWishlistItem(Book book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.imageUrl,
                width: 80,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${book.author}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${book.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.bookmark,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _removeFromWishlist(book.id),
            ),
          ],
        ),
      ),
    );
  }
}
