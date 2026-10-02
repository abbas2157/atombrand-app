import 'json.dart';

enum OrderFeed {
  retail,
  instalment;

  String get label => this == retail ? 'Retail' : 'Instalment';
}

class OrderProductRef {
  const OrderProductRef({required this.id, required this.title, this.picture, this.prNumber, this.publicUrl, this.variant});

  factory OrderProductRef.fromJson(Json j) => OrderProductRef(
        id: asInt(j['id']),
        title: asStrOr(j['title']),
        picture: asStr(j['picture']),
        prNumber: asStr(j['pr_number']),
        publicUrl: asStr(j['public_url']),
        variant: asStr(j['variant']),
      );

  final int id;
  final String title;
  final String? picture;
  final String? prNumber;
  final String? publicUrl;
  final String? variant;
}

/// Order list item (§8.6), also used by dashboard `latest_orders`.
class OrderSummary {
  const OrderSummary({
    required this.uuid,
    required this.id,
    required this.status,
    this.totalDealPrice = 0,
    this.advancePrice = 0,
    this.tenure = 1,
    this.isCash = false,
    this.portal,
    this.city,
    this.product,
    this.variant,
    this.createdAt,
    this.quantity,
  });

  factory OrderSummary.fromJson(Json j) => OrderSummary(
        uuid: asStrOr(j['uuid']),
        id: asInt(j['id']),
        status: asStrOr(j['status'], 'Pending'),
        totalDealPrice: asInt(j['total_deal_price']),
        advancePrice: asInt(j['advance_price']),
        tenure: asInt(j['tenure'], 1),
        isCash: asBool(j['is_cash']),
        portal: asStr(j['portal']),
        city: asStr(j['city']),
        product: asMapOrNull(j['product']) == null ? null : OrderProductRef.fromJson(asMap(j['product'])),
        variant: asStr(j['variant']),
        createdAt: asStr(j['created_at']),
        quantity: asIntOrNull(j['quantity']),
      );

  final String uuid;
  final int id;
  final String status;
  final int totalDealPrice;
  final int advancePrice;
  final int tenure;
  final bool isCash;
  final String? portal;
  final String? city;
  final OrderProductRef? product;
  final String? variant;
  final String? createdAt;
  final int? quantity;
}

class OrderDeal {
  const OrderDeal({
    this.totalDealPrice = 0,
    this.advancePrice = 0,
    this.financed = 0,
    this.tenure = 1,
    this.monthly = 0,
    this.paid = 0,
    this.dueLeft = 0,
    this.recoveryPercent = 0,
  });

  factory OrderDeal.fromJson(Json j) => OrderDeal(
        totalDealPrice: asInt(j['total_deal_price']),
        advancePrice: asInt(j['advance_price']),
        financed: asInt(j['financed']),
        tenure: asInt(j['tenure'], 1),
        monthly: asInt(j['monthly']),
        paid: asInt(j['paid']),
        dueLeft: asInt(j['due_left']),
        recoveryPercent: asInt(j['recovery_percent']),
      );

  final int totalDealPrice;
  final int advancePrice;
  final int financed;
  final int tenure;
  final int monthly;
  final int paid;
  final int dueLeft;
  final int recoveryPercent;
}

/// Personal data (CNIC, address). Held in memory only: never cached to disk
/// or logged (§8.6).
class OrderCustomer {
  const OrderCustomer(this._j);
  factory OrderCustomer.fromJson(Json j) => OrderCustomer(j);
  final Json _j;

  String? get name => asStr(_j['name']);
  String? get phone => asStr(_j['phone']);
  String? get email => asStr(_j['email']);
  String? get whatsapp => asStr(_j['whatsapp']);
  String? get customerSince => asStr(_j['customer_since']);
  String? get identifier => asStr(_j['identifier']);
  bool get verified => asBool(_j['verified']);
  String? get fatherName => asStr(_j['father_name']);
  String? get cnic => asStr(_j['cnic_no']);
  String? get alternatePhone => asStr(_j['alternate_phone']);
  String? get address => asStr(_j['address']);
  String? get area => asStr(_j['area']);
  String? get city => asStr(_j['city']);
}

class Instalment {
  const Instalment({
    required this.id,
    this.type,
    this.month,
    this.price = 0,
    this.paidPrice = 0,
    this.date,
    this.paidDate,
    this.paymentMethod,
    this.status,
  });

  factory Instalment.fromJson(Json j) => Instalment(
        id: asInt(j['id']),
        type: asStr(j['type']),
        month: asStr(j['month']),
        price: asInt(j['installment_price']),
        paidPrice: asInt(j['installment_paid_price']),
        date: asStr(j['installment_date']),
        paidDate: asStr(j['installment_paid_date']),
        paymentMethod: asStr(j['payment_method']),
        status: asStr(j['status']),
      );

  final int id;
  final String? type;
  final String? month;
  final int price;
  final int paidPrice;
  final String? date;
  final String? paidDate;
  final String? paymentMethod;
  final String? status;
}

class OrderHistoryEntry {
  const OrderHistoryEntry({required this.status, this.role, this.changedBy, this.payload = const {}, this.createdAt});

  factory OrderHistoryEntry.fromJson(Json j) => OrderHistoryEntry(
        status: asStrOr(j['status']),
        role: asStr(j['role']),
        changedBy: asStr(asMap(j['changed_by'])['name']),
        payload: asMap(j['payload']),
        createdAt: asStr(j['created_at']),
      );

  final String status;
  final String? role;
  final String? changedBy;
  final Json payload;
  final String? createdAt;

  String? get receivedBy => asStr(payload['recieved_by']);
  String? get image => asStr(payload['img']);
  String? get reason => asStr(payload['reason']);
}

/// One entry of the order detail's `actions[]`: drives the status buttons.
class OrderAction {
  const OrderAction({required this.status, required this.label, this.fields = const []});

  factory OrderAction.fromJson(Json j) => OrderAction(
        status: asStrOr(j['status']),
        label: asStrOr(j['label'], asStrOr(j['status'])),
        fields: asStrList(j['fields']),
      );

  final String status;
  final String label;
  final List<String> fields;

  bool get isCancel => status == 'Cancelled';
  bool get isDeliver => status == 'Delivered';
}

class OrderDetail {
  const OrderDetail({
    required this.type,
    required this.order,
    required this.product,
    required this.deal,
    required this.customer,
    required this.instalments,
    required this.history,
    required this.alsoBought,
    required this.locked,
    required this.lockedReason,
    required this.actions,
  });

  factory OrderDetail.fromJson(Json j) => OrderDetail(
        type: asStr(j['type']) == 'instalment' ? OrderFeed.instalment : OrderFeed.retail,
        order: OrderSummary.fromJson(asMap(j['order'])),
        product: asMapOrNull(j['product']) == null ? null : OrderProductRef.fromJson(asMap(j['product'])),
        deal: OrderDeal.fromJson(asMap(j['deal'])),
        customer: asMapOrNull(j['customer']) == null ? null : OrderCustomer.fromJson(asMap(j['customer'])),
        instalments: asList(j['instalments'], Instalment.fromJson),
        history: asList(j['history'], OrderHistoryEntry.fromJson),
        alsoBought: asList(j['also_bought'], OrderSummary.fromJson),
        locked: asBool(j['locked']),
        lockedReason: asStr(j['locked_reason']),
        actions: asList(j['actions'], OrderAction.fromJson),
      );

  final OrderFeed type;
  final OrderSummary order;
  final OrderProductRef? product;
  final OrderDeal deal;
  final OrderCustomer? customer;
  final List<Instalment> instalments;
  final List<OrderHistoryEntry> history;
  final List<OrderSummary> alsoBought;
  final bool locked;
  final String? lockedReason;
  final List<OrderAction> actions;
}
