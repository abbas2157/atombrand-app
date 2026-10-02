import 'package:atombrand_app/data/models/account.dart';
import 'package:atombrand_app/data/models/bulk.dart';
import 'package:atombrand_app/data/models/json.dart';
import 'package:atombrand_app/data/models/order.dart';
import 'package:atombrand_app/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lenient readers accept Laravel-style strings and 0/1 flags', () {
    expect(asInt('30000'), 30000);
    expect(asInt('12.6'), 13);
    expect(asInt(null, 7), 7);
    expect(asBool(1), isTrue);
    expect(asBool('1'), isTrue);
    expect(asBool('0'), isFalse);
    expect(asStr(''), isNull);
  });

  test('verified login body parses token, user and brand', () {
    final s = AuthSession.fromJson({
      'verification_required': false,
      'token': '12|xYz',
      'user': {'id': 41, 'name': 'Ali', 'email': 'ali@brand.pk', 'verified': true},
      'brand': {'id': 7, 'title': 'Acme', 'public_url': 'https://atomshop.pk/brand/acme', 'banner': null},
    });
    expect(s.token, '12|xYz');
    expect(s.user.name, 'Ali');
    expect(s.brand.publicUrl, 'https://atomshop.pk/brand/acme');
    expect(s.brand.banner, isNull);
  });

  test('verification challenge keeps masked destinations', () {
    final c = VerificationChallenge.fromJson({
      'verification_required': true,
      'channels': ['whatsapp', 'email'],
      'destinations': {'whatsapp': '0300*****67', 'email': 'a***@brand.pk'},
      'expires_in': 600,
    });
    expect(c.channels, ['whatsapp', 'email']);
    expect(c.destinations['whatsapp'], '0300*****67');
  });

  test('order detail exposes actions with their fields', () {
    final d = OrderDetail.fromJson({
      'type': 'retail',
      'order': {'uuid': 'u1', 'id': 901, 'status': 'Varification', 'is_cash': true, 'total_deal_price': 30000},
      'deal': {'total_deal_price': 30000, 'advance_price': 30000},
      'customer': {'name': 'Bilal', 'cnic_no': '35202-0000000-1'},
      'history': [
        {
          'status': 'Delivered',
          'changed_by': {'name': 'Ali', 'role': 'brand'},
          'payload': {'recieved_by': 'Ahmed', 'img': 'https://x/y.jpg'},
        },
      ],
      'locked': false,
      'actions': [
        {'status': 'Delivered', 'label': 'Mark delivered', 'fields': ['recieved_by', 'delivered_pictrue']},
        {'status': 'Cancelled', 'label': 'Cancel', 'fields': ['reason', 'product_unavailable']},
      ],
    });
    expect(d.order.status, 'Varification');
    expect(d.order.isCash, isTrue);
    expect(d.customer!.cnic, '35202-0000000-1');
    expect(d.history.single.receivedBy, 'Ahmed');
    expect(d.history.single.changedBy, 'Ali');
    expect(d.actions.first.isDeliver, isTrue);
    expect(d.actions.last.isCancel, isTrue);
    expect(d.actions.last.fields, contains('product_unavailable'));
  });

  test('bulk request without a status is a New Lead; guest requester is null', () {
    final d = BulkDossier.fromJson({
      'request': {'id': 3, 'full_name': 'Sara', 'status': null, 'quantity': '50', 'comments': []},
      'requester': null,
      'orders': [
        {'uuid': 'o1', 'status': 'Completed', 'total_deal_price': 30000, 'product': 'Acme X1'},
      ],
      'lifetime_value': 30000,
      'instalments': {'paid': 0, 'unpaid': 0, 'overdue': 0},
    });
    expect(d.request.status, 'New Lead');
    expect(d.request.quantity, 50);
    expect(d.requester, isNull);
    expect(d.orders.single.product, 'Acme X1');
  });

  test('paged list keeps sibling keys', () {
    final p = Paged.fromJson({
      'items': [
        {'id': 5, 'title': 'Acme X1', 'status': 'Published', 'can_manage_stock': true},
      ],
      'pagination': {'current_page': 1, 'last_page': 4, 'per_page': 15, 'total': 52},
      'summary': {'in_stock': 30, 'out_of_stock': 7},
    }, ProductSummary.fromJson);
    expect(p.items.single.isLive, isTrue);
    expect(p.items.single.canManageStock, isTrue);
    expect(p.pagination.hasMore, isTrue);
    expect((p.raw['summary'] as Map)['in_stock'], 30);
  });

  test('form options fall back to the documented variant categories', () {
    final o = ProductFormOptions.fromJson({'categories': [], 'brands': []});
    expect(o.colorCategories, [1, 2, 3]);
    expect(o.memoryCategories, [1, 2]);
    expect(o.sizeCategories, [4]);
  });
}
