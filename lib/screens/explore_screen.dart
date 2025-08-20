import 'package:book_store/main.dart';
import 'package:book_store/screens/detailed_book_screen.dart';
import 'package:flutter/material.dart';

import '../models/book_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // --- STATE VARIABLES ---
  late Future<void> _initDataFuture;

  // 1. REPLACED 'interest' list with a map to group books by genre
  Map<String, List<Book>> _booksByGenre = {};
  List<Book> _bestsellerBooks = [];
  List<Book> _newestBooks = [];

  int _selectedTabIndex = 0;
  bool _showAllBestsellers = false;
  bool _showAllNewest = false;

  @override
  void initState() {
    super.initState();
    _initDataFuture = _fetchExploreScreenData();
  }

  // 2. UPDATED data fetching to get all books and group them
  Future<void> _fetchExploreScreenData() async {
    final responses = await Future.wait([
      // Fetch all books to be grouped by genre
      supabase.from('books').select(),
      supabase.from('books').select().eq('is_bestseller', true),
      supabase.from('books').select().eq('is_new_arrival', true),
    ]);

    if (responses.any((res) => res == null)) {
      throw Exception('Failed to load explore data');
    }
    if (!mounted) return;

    // Process the response for all books and group them by genre
    final allBooksResponse = responses[0] as List;
    final allBooks = allBooksResponse
        .map((json) => Book.fromJson(json))
        .toList();

    final groupedBooks = <String, List<Book>>{};
    for (var book in allBooks) {
      // If the genre key doesn't exist, create it with a new list. Then add the book.
      (groupedBooks[book.genre] ??= []).add(book);
    }

    setState(() {
      _booksByGenre = groupedBooks;
      _bestsellerBooks = (responses[1] as List)
          .map((json) => Book.fromJson(json))
          .toList();
      _newestBooks = (responses[2] as List)
          .map((json) => Book.fromJson(json))
          .toList();
    });
  }

  // 3. SIMPLIFIED the build method
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        // Directly build the main view without the AnimatedSwitcher
        return _buildStandardView();
      },
    );
  }

  // --- VIEW BUILDERS ---

  Widget _buildStandardView() {
    final activeGridList = _selectedTabIndex == 0
        ? _bestsellerBooks
        : _newestBooks;
    final isExpanded = _selectedTabIndex == 0
        ? _showAllBestsellers
        : _showAllNewest;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCategoryTabs(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildBooksGrid(activeGridList, isExpanded),
                  if (activeGridList.length > 4)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedTabIndex == 0) {
                            _showAllBestsellers = !_showAllBestsellers;
                          } else {
                            _showAllNewest = !_showAllNewest;
                          }
                        });
                      },
                      child: Text(
                        isExpanded ? 'Show Less' : 'Show More',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildGenreSections(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 5. NEW WIDGET to build all the genre sections dynamically
  Widget _buildGenreSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _booksByGenre.entries.map((entry) {
        final genre = entry.key;
        final booksInGenre = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Text(
                genre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildHorizontalBookList(booksInGenre),
          ],
        );
      }).toList(),
    );
  }

  // 6. NEW GENERIC WIDGET for any horizontal list of books
  Widget _buildHorizontalBookList(List<Book> books) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        // Add left padding for the first item
        padding: const EdgeInsets.only(left: 16, right: 0),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            ),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? const Color(0xFFFBE9E7)
                          : const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(book.imageUrl, fit: BoxFit.cover),
                      ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBooksGrid(List<Book> books, bool showAll) {
    final itemCount = showAll
        ? books.length
        : (books.length > 4 ? 4 : books.length);

    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFFE8F5E9),
                      const Color(0xFFFCE4EC),
                      const Color(0xFFFFFDE7),
                      const Color(0xFFF1F8E9),
                    ][index % 4],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(book.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
              ),
              Text(
                'By ${book.author}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabs() {
    return Row(
      children: [
        _buildTab('Bestseller', 0),
        const SizedBox(width: 24),
        _buildTab('Newest', 1),
      ],
    );
  }

  Widget _buildTab(String text, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTabIndex = index;
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(height: 3, width: 30, color: const Color(0xFF005A5A)),
        ],
      ),
    );
  }
}
