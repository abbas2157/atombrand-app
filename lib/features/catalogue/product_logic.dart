import '../../core/formatters.dart';
import '../../data/models/product.dart';

enum StockLevel { ok, low, out, hidden }

/// What the stock corner of a product card says.
///
/// Availability is the product's status (`Out of Stock` means buyers can't
/// order), as the Inventory tab treats it. The unit count is extra: 0 only
/// means it isn't tracked, so it is never read as "out of stock".
({StockLevel level, String text}) stockOf(ProductSummary p) {
  if (p.isOutOfStock) return (level: StockLevel.out, text: 'Out of stock');
  if (!p.isLive || p.stock <= 0) return (level: StockLevel.hidden, text: '');
  if (p.stock < 5) return (level: StockLevel.low, text: 'Low · ${p.stock} left');
  return (level: StockLevel.ok, text: '${count(p.stock)} in stock');
}

/// A one-line problem to show on the card without opening the product, or
/// null.
String? problemOf(ProductSummary p) => p.isOutOfStock ? "Out of stock · buyers can't order" : null;

/// Products whose stock the brand can change (the server refuses others
/// with a 409, §8.5).
bool canSetStock(ProductSummary p) => p.isLive || p.isOutOfStock;
