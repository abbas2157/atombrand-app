import 'json.dart';
import 'order.dart';

/// Bulk request list item, §8.7. A request with no status is a `New Lead`.
class BulkRequest {
  const BulkRequest({
    required this.id,
    required this.status,
    required this.fullName,
    this.uuid,
    this.phone,
    this.quantity = 0,
    this.productTitle,
    this.product,
    this.city,
    this.area,
    this.portal,
    this.createdAt,
    this.commentsCount = 0,
    this.address,
    this.reason,
    this.whatsapp,
    this.comments = const [],
  });

  factory BulkRequest.fromJson(Json j) {
    final product = asMapOrNull(j['product']);
    return BulkRequest(
      id: asInt(j['id']),
      uuid: asStr(j['uuid']),
      status: asStrOr(j['status'], 'New Lead'),
      fullName: asStrOr(j['full_name'], 'Unknown buyer'),
      phone: asStr(j['phone']),
      quantity: asInt(j['quantity']),
      productTitle: asStr(j['product_title']) ?? asStr(product?['title']),
      product: product == null ? null : OrderProductRef.fromJson(product),
      city: asStr(j['city']),
      area: asStr(j['area']),
      portal: asStr(j['portal']),
      createdAt: asStr(j['created_at']),
      commentsCount: asInt(j['comments_count']),
      address: asStr(j['address']),
      reason: asStr(j['reason']),
      whatsapp: asStr(j['whatsapp']),
      comments: asList(j['comments'], BulkComment.fromJson),
    );
  }

  final int id;
  final String? uuid;
  final String status;
  final String fullName;
  final String? phone;
  final int quantity;
  final String? productTitle;
  final OrderProductRef? product;
  final String? city;
  final String? area;
  final String? portal;
  final String? createdAt;
  final int commentsCount;
  final String? address;
  final String? reason;
  final String? whatsapp;
  final List<BulkComment> comments;

  String get location => [area, city].whereType<String>().join(', ');
}

class BulkComment {
  const BulkComment({required this.id, this.comments, this.status, this.byName, this.byRole, this.createdAt});

  factory BulkComment.fromJson(Json j) {
    final by = asMap(j['by']);
    return BulkComment(
      id: asInt(j['id']),
      comments: asStr(j['comments']),
      status: asStr(j['status']),
      byName: asStr(by['name']),
      byRole: asStr(by['role']),
      createdAt: asStr(j['created_at']),
    );
  }

  final int id;
  final String? comments;
  final String? status;
  final String? byName;
  final String? byRole;
  final String? createdAt;
}

class BulkRequester {
  const BulkRequester(this._j);
  final Json _j;

  String? get name => asStr(_j['name']);
  String? get phone => asStr(_j['phone']);
  String? get email => asStr(_j['email']);
  String? get customerSince => asStr(_j['customer_since']);
  String? get identifier => asStr(_j['identifier']);
  bool get verified => asBool(_j['verified']);
  String? get city => asStr(_j['city']);
  String? get area => asStr(_j['area']);
  String? get address => asStr(_j['address']);
}

class DossierOrder {
  const DossierOrder({required this.uuid, required this.status, this.totalDealPrice = 0, this.advancePrice = 0, this.product, this.createdAt});

  factory DossierOrder.fromJson(Json j) => DossierOrder(
        uuid: asStrOr(j['uuid']),
        status: asStrOr(j['status']),
        totalDealPrice: asInt(j['total_deal_price']),
        advancePrice: asInt(j['advance_price']),
        product: j['product'] is Map ? asStr((j['product'] as Map)['title']) : asStr(j['product']),
        createdAt: asStr(j['created_at']),
      );

  final String uuid;
  final String status;
  final int totalDealPrice;
  final int advancePrice;
  final String? product;
  final String? createdAt;
}

/// `GET bulk-orders/{id}`. Only the requester's dealings with this brand.
class BulkDossier {
  const BulkDossier({
    required this.request,
    required this.requester,
    required this.otherRequests,
    required this.orders,
    required this.lifetimeValue,
    required this.instalmentsPaid,
    required this.instalmentsUnpaid,
    required this.instalmentsOverdue,
  });

  factory BulkDossier.fromJson(Json j) {
    final inst = asMap(j['instalments']);
    final requester = asMapOrNull(j['requester']);
    return BulkDossier(
      request: BulkRequest.fromJson(asMap(j['request'])),
      requester: requester == null ? null : BulkRequester(requester),
      otherRequests: asList(j['other_requests'], BulkRequest.fromJson),
      orders: asList(j['orders'], DossierOrder.fromJson),
      lifetimeValue: asInt(j['lifetime_value']),
      instalmentsPaid: asInt(inst['paid']),
      instalmentsUnpaid: asInt(inst['unpaid']),
      instalmentsOverdue: asInt(inst['overdue']),
    );
  }

  final BulkRequest request;
  final BulkRequester? requester;
  final List<BulkRequest> otherRequests;
  final List<DossierOrder> orders;
  final int lifetimeValue;
  final int instalmentsPaid;
  final int instalmentsUnpaid;
  final int instalmentsOverdue;
}
