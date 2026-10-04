import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/models/json.dart';
import '../../data/repositories/notifications_repository.dart';

/// Filter chips and icon tints. Only the first three arrive today (§8.10);
/// the rest show up as soon as the server sends them.
enum NotifCategory { orders, leads, payments, stock, products, atomshop }

const categoryLabels = {
  NotifCategory.orders: 'Orders',
  NotifCategory.leads: 'Bulk leads',
  NotifCategory.payments: 'Payments',
  NotifCategory.stock: 'Stock',
  NotifCategory.products: 'Products',
  NotifCategory.atomshop: 'AtomShop',
};

NotifCategory categoryOf(AppNotification n) {
  final t = n.type.toLowerCase();
  if (t.contains('bulk') || n.screen == 'bulk_request') return NotifCategory.leads;
  if (t.contains('instal') || t.contains('payment') || t.contains('recovery')) return NotifCategory.payments;
  if (t.contains('stock')) return NotifCategory.stock;
  if (t.contains('product') || n.screen == 'product') return NotifCategory.products;
  if (t.contains('order') || n.screen == 'order') return NotifCategory.orders;
  return NotifCategory.atomshop;
}

/// Needs action now: overdue money, a product AtomShop took down or turned
/// away, stock that ran out.
bool isUrgent(AppNotification n) {
  final t = n.type.toLowerCase();
  final status = asStr(n.data['status'])?.toLowerCase();
  return t.contains('overdue') ||
      t.contains('rejected') ||
      t.contains('out_of_stock') ||
      (categoryOf(n) == NotifCategory.products && (status == 'on hold' || status == 'closed' || status == 'rejected'));
}

/// The sticky group a notification sits under.
String groupOf(String? createdAt, {DateTime? now}) {
  final d = parseServerDate(createdAt);
  if (d == null) return 'Earlier';
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(d);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return 'This week';
  return 'Earlier';
}

const groupOrder = ['Today', 'Yesterday', 'This week', 'Earlier'];

/// "12:43 PM" today, "Yesterday", then "28 Sep".
String timeLabel(String? createdAt, {DateTime? now}) {
  final d = parseServerDate(createdAt);
  if (d == null) return '';
  final g = groupOf(createdAt, now: now);
  if (g == 'Today') {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }
  if (g == 'Yesterday') return 'Yesterday';
  return formatShortDate(createdAt);
}
