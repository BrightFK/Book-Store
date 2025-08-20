import 'dart:async'; // Import for Timer (debouncing)

import 'package:book_store/main.dart';
import 'package:book_store/screens/detailed_book_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Needed for PostgrestFilterBuilder

import '../models/book_model.dart';

// --- ENUM FOR SORTING OPTIONS ---
enum SortOption {
  relevance,
  priceLowToHigh,
  priceHighToLow,
  popularity,
  newest,
}

// Extension to get user-friendly display names for the enum
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.popularity:
        return 'Popularity';
      case SortOption.newest:
        return 'Newest First';
      case SortOption.relevance:
      default:
        return 'Relevance';
    }
  }
}

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

  // --- SEARCH AND FILTER STATE VARIABLES ---
  late final TextEditingController _searchController;
  Timer? _debounce;
  List<Book> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchLoading = false;
  SortOption _currentSortOption = SortOption.relevance; // Default sort option

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initDataFuture = _fetchHomeScreenData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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

    if (!mounted) return;

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

  // ... ( _toggleWishlist method remains unchanged ) ...
  Future<void> _toggleWishlist(String bookId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isWishlisted = _wishlistedBookIds.contains(bookId);

    if (isWishlisted) {
      await supabase.from('wishlist_items').delete().match({
        'user_id': userId,
        'book_id': bookId,
      });
      if (mounted) setState(() => _wishlistedBookIds.remove(bookId));
    } else {
      await supabase.from('wishlist_items').insert({
        'user_id': userId,
        'book_id': bookId,
      });
      if (mounted) setState(() => _wishlistedBookIds.add(bookId));
    }
  }

  // --- SEARCH LOGIC METHODS ---

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        if (!_isSearching) {
          setState(() => _isSearching = true);
        }
        _searchBooks(query);
      } else {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _currentSortOption = SortOption.relevance; // Reset sort on clear
        });
      }
    });
  }

  Future<void> _searchBooks(String query) async {
    if (!mounted) return;
    setState(() => _isSearchLoading = true);

    try {
      // 1. Build the base query with enhanced search criteria (title, author, genre)
      PostgrestTransformBuilder<PostgrestList> queryBuilder = supabase
          .from('books')
          .select()
          .or(
            'title.ilike.%$query%,author.ilike.%$query%,genre.ilike.%$query%',
          );

      // 2. Apply sorting based on the current filter
      switch (_currentSortOption) {
        case SortOption.priceLowToHigh:
          queryBuilder = queryBuilder.order('price', ascending: true);
          break;
        case SortOption.priceHighToLow:
          queryBuilder = queryBuilder.order('price', ascending: false);
          break;
        case SortOption.popularity:
          // Assuming a 'rating' or 'sales_count' column exists for popularity
          queryBuilder = queryBuilder.order('rating', ascending: false);
          break;
        case SortOption.newest:
          // Assuming a 'published_date' column exists for release date
          queryBuilder = queryBuilder.order('published_date', ascending: false);
          break;
        case SortOption.relevance:
        // No specific order is applied, letting the database's full-text search relevance take over.
        default:
          break;
      }

      final response = await queryBuilder;

      if (!mounted) return;

      setState(() {
        _searchResults = (response as List)
            .map((json) => Book.fromJson(json))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching books: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSearchLoading = false);
      }
    }
  }

  // --- UI BUILD METHODS ---

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
                if (_isSearching)
                  _buildSearchResults()
                else
                  _buildDefaultContent(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search title, author, or genre...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min, // Important to keep icons together
          children: [
            // Show clear button only when text is present
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              ),
            // Show filter button only when actively searching
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showSortOptions,
              ),
          ],
        ),
      ),
    );
  }

  // Method to show the sorting options bottom sheet
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...SortOption.values.map((option) {
                    return RadioListTile<SortOption>(
                      title: Text(option.displayName),
                      value: option,
                      groupValue: _currentSortOption,
                      onChanged: (SortOption? value) {
                        if (value != null) {
                          // Update the state for the main screen
                          setState(() {
                            _currentSortOption = value;
                          });
                          // Close the bottom sheet
                          Navigator.pop(context);
                          // Re-run the search with the new sort option
                          _searchBooks(_searchController.text.trim());
                        }
                      },
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    // ... (This method remains unchanged) ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  Widget _buildSearchResults() {
    // ... (This method remains unchanged) ...
    if (_isSearchLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No books found. Try a different search term.'),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return _buildTrendingBookItem(book);
      },
    );
  }

  // ... (All other _build... helper methods remain unchanged) ...
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
    // final isWishlisted = _wishlistedBookIds.contains(book.id); // Not needed here but keeping for context

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
          ],
        ),
      ),
    );
  }
}
