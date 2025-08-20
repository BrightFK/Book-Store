import 'package:book_store/main.dart';
import 'package:book_store/screens/detailed_book_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/book_model.dart';

enum ExploreView { standard, showAllInterest }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // --- STATE VARIABLES ---
  late Future<void> _initDataFuture;
  List<Book> _interestBooks = [];
  List<Book> _bestsellerBooks = [];
  List<Book> _newestBooks = [];

  ExploreView _currentView = ExploreView.standard;
  int _selectedTabIndex = 0;

  // --- 1. NEW STATE VARIABLES for "Show More/Less" ---
  bool _showAllBestsellers = false;
  bool _showAllNewest = false;

  @override
  void initState() {
    super.initState();
    _initDataFuture = _fetchExploreScreenData();
  }

  Future<void> _fetchExploreScreenData() async {
    // Fetches all data for the screen in parallel
    final responses = await Future.wait([
      supabase.from('books').select().neq('genre', 'Mystery').limit(4),
      supabase.from('books').select().eq('is_bestseller', true),
      supabase.from('books').select().eq('is_new_arrival', true),
    ]);

    if (responses.any((res) => res == null)) {
      throw Exception('Failed to load explore data');
    }

    setState(() {
      _interestBooks = (responses[0] as List)
          .map((json) => Book.fromJson(json))
          .toList();
      _bestsellerBooks = (responses[1] as List)
          .map((json) => Book.fromJson(json))
          .toList();
      _newestBooks = (responses[2] as List)
          .map((json) => Book.fromJson(json))
          .toList();
    });
  }

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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildCurrentView(),
        );
      },
    );
  }

  // --- VIEW ROUTERS & BUILDERS ---

  Widget _buildCurrentView() {
    switch (_currentView) {
      case ExploreView.showAllInterest:
        return _buildShowAllView(
          key: const ValueKey('ShowAll'),
          title: 'Your Interest',
          bookList: _interestBooks,
        );
      case ExploreView.standard:
      default:
        return _buildStandardView(key: const ValueKey('Standard'));
    }
  }

  // --- 2. MODIFIED the Standard View to include the button ---
  Widget _buildStandardView({required Key key}) {
    // Determine which list and which boolean state to use based on the active tab
    final activeGridList = _selectedTabIndex == 0
        ? _bestsellerBooks
        : _newestBooks;
    final isExpanded = _selectedTabIndex == 0
        ? _showAllBestsellers
        : _showAllNewest;

    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Your Interest', () {
              setState(() {
                _currentView = ExploreView.showAllInterest;
              });
            }),
            const SizedBox(height: 16),
            _buildInterestBooksList(_interestBooks),
            const SizedBox(height: 24),
            _buildCategoryTabs(),
            const SizedBox(height: 16),
            // This Column now holds the grid and the button
            Column(
              children: [
                _buildBooksGrid(activeGridList, isExpanded),
                // Only show the button if there are more than 4 books
                if (activeGridList.length > 4)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // Toggle the correct boolean based on the active tab
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
          ],
        ),
      ),
    );
  }

  // --- 3. MODIFIED the Books Grid to respect the "showAll" flag ---
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

  Widget _buildShowAllView({
    required Key key,
    required String title,
    required List<Book> bookList,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() {
                    _currentView = ExploreView.standard;
                  }),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: bookList.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildVerticalBookListItem(bookList[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onShowAllPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onShowAllPressed,
          child: Text(
            'Show All',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestBooksList(List<Book> books) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
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

  Widget _buildVerticalBookListItem(Book book) {
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        book.rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.bookmark_border_outlined,
                color: Colors.grey[600],
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
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
