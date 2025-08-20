import 'package:book_store/main.dart';
import 'package:book_store/screens/detailed_book_screen.dart';
import 'package:flutter/material.dart';

import '../models/book_model.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToExplore;

  const HomeScreen({super.key, required this.onNavigateToExplore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE VARIABLES ---
  late Future<void> _initDataFuture;
  List<Book> _popularBooks = [];
  List<Book> _trendingBooks = [];
  bool _showAllTrending = false;
  Set<String> _wishlistedBookIds = {};

  @override
  void initState() {
    super.initState();
    _initDataFuture = _fetchHomeScreenData();
  }

  // --- DATA FETCHING AND LOGIC METHODS ---

  Future<void> _fetchHomeScreenData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final responses = await Future.wait([
      supabase.from('books').select().eq('is_bestseller', true).limit(5),
      supabase.from('books').select().eq('is_new_arrival', true).limit(8),
      supabase.from('wishlist_items').select('book_id').eq('user_id', userId),
    ]);

    if (responses.any((res) => res == null)) {
      throw Exception('Failed to load book data');
    }

    setState(() {
      _popularBooks = (responses[0] as List)
          .map((json) => Book.fromJson(json))
          .toList();
      _trendingBooks = (responses[1] as List)
          .map((json) => Book.fromJson(json))
          .toList();
      final wishlistResponse = responses[2] as List;
      _wishlistedBookIds = wishlistResponse
          .map((item) => item['book_id'] as String)
          .toSet();
    });
  }

  Future<void> _toggleWishlist(String bookId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isWishlisted = _wishlistedBookIds.contains(bookId);

    if (isWishlisted) {
      await supabase.from('wishlist_items').delete().match({
        'user_id': userId,
        'book_id': bookId,
      });
      setState(() => _wishlistedBookIds.remove(bookId));
    } else {
      await supabase.from('wishlist_items').insert({
        'user_id': userId,
        'book_id': bookId,
      });
      setState(() => _wishlistedBookIds.add(bookId));
    }
  }

  // --- SINGLE, COMPLETE BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}'));
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Popular Now',
                  onShowAll: widget.onNavigateToExplore,
                ),
                const SizedBox(height: 16),
                _buildPopularBooksList(_popularBooks),
                const SizedBox(height: 24),
                _buildSectionHeader('Trending Books'),
                const SizedBox(height: 16),
                _buildTrendingBooksList(_trendingBooks),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- ALL HELPER METHODS ARE NOW CORRECTLY PLACED HERE ---

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search For Books...',
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onShowAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (onShowAll != null)
          TextButton(
            onPressed: onShowAll,
            child: Text(
              'Explore more',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPopularBooksList(List<Book> books) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          // We can add wishlist icons here later if needed
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            ),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      book.imageUrl,
                      height: 160,
                      width: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'By ${book.author}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingBooksList(List<Book> books) {
    final itemCount = _showAllTrending
        ? books.length
        : (books.length > 4 ? 4 : books.length);

    return Column(
      children: [
        ListView.builder(
          itemCount: itemCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final book = books[index];
            return _buildTrendingBookItem(book);
          },
        ),
        const SizedBox(height: 16),
        if (books.length > 4)
          TextButton(
            onPressed: () {
              setState(() {
                _showAllTrending = !_showAllTrending;
              });
            },
            child: Text(
              _showAllTrending ? 'Show Less' : 'Show More',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrendingBookItem(Book book) {
    final isWishlisted = _wishlistedBookIds.contains(book.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.imageUrl,
                width: 70,
                height: 100,
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
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${book.author}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isWishlisted ? Icons.bookmark : Icons.bookmark_border_outlined,
                color: isWishlisted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
              onPressed: () => _toggleWishlist(book.id),
            ),
          ],
        ),
      ),
    );
  }
}
