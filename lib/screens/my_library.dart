import 'package:book_store/main.dart';
import 'package:book_store/models/book_model.dart';
import 'package:book_store/screens/detailed_book_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Future<void> _removeFromCart(String bookId) async {
    final userId = supabase.auth.currentUser?.id;
    final bookBox = Hive.box<Book>('wishlist_books');
    final quantityBox = Hive.box<int>('cart_quantities');

    await bookBox.delete(bookId);
    await quantityBox.delete(bookId);

    if (userId != null) {
      await supabase.from('wishlist_items').delete().match({
        'user_id': userId,
        'book_id': bookId,
      });
    }
  }

  void _showRemoveConfirmationDialog(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove from Cart?'),
          content: Text(
            'Are you sure you want to remove "${book.title}" from your cart?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _removeFromCart(book.id);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This outer builder correctly listens for when books are added or removed.
      body: ValueListenableBuilder<Box<Book>>(
        valueListenable: Hive.box<Book>('wishlist_books').listenable(),
        builder: (context, bookBox, _) {
          final cartBooks = bookBox.values.toList();

          if (cartBooks.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.\nStart exploring to add books!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: cartBooks.length,
                  itemBuilder: (context, index) {
                    final book = cartBooks[index];
                    return _buildCartItem(context, book);
                  },
                ),
              ),
              // Pass the book list to the summary bar.
              _buildBottomSummaryBar(cartBooks),
            ],
          );
        },
      ),
    );
  }

  // SOLUTION PART 1: Wrap the Bottom Summary Bar in its own builder
  // that listens to the quantity box.
  Widget _buildBottomSummaryBar(List<Book> books) {
    // This builder will now ONLY run when quantities change, which is efficient.
    return ValueListenableBuilder<Box<int>>(
      valueListenable: Hive.box<int>('cart_quantities').listenable(),
      builder: (context, quantityBox, _) {
        final double totalCost = books.fold(0.0, (sum, book) {
          final quantity = quantityBox.get(book.id, defaultValue: 1);
          return sum + (book.price * quantity!);
        });

        final int totalItems = books.fold(0, (sum, book) {
          final quantity = quantityBox.get(book.id, defaultValue: 1);
          return sum + quantity!;
        });

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total (${totalItems} items)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    '\$${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  /* TODO: Implement checkout logic */
                },
                child: const Text('Proceed to Payment'),
              ),
            ],
          ),
        );
      },
    );
  }

  // SOLUTION PART 2: Wrap the Cart Item in its own builder so each
  // item can update its own quantity independently.
  Widget _buildCartItem(BuildContext context, Book book) {
    // This makes each list item reactive to quantity changes for that specific item.
    return ValueListenableBuilder<Box<int>>(
      valueListenable: Hive.box<int>('cart_quantities').listenable(),
      builder: (context, quantityBox, _) {
        final quantity = quantityBox.get(book.id, defaultValue: 1);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: $quantity', // Now this will always be up-to-date
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  tooltip: 'Remove from Cart',
                  onPressed: () => _showRemoveConfirmationDialog(context, book),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
