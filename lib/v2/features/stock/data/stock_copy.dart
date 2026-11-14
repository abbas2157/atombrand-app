import '../../../core/api/api_client.dart';
import 'stock_models.dart';

/// Reads a table of the phone's copy (`SyncStore.rows`).
typedef CopyRows = Future<List<Map<String, dynamic>>> Function(String table);

/// Stock read from the phone's own copy, for a brand with no signal
/// (Offline add-on; docs/brand-app-sync.md tables `warehouses`,
/// `stock_products`, `stock_variants`, `stock_balances`, `stock_units`,
/// `stock_holds`). Counting units is counting rows, which the phone can do;
/// the website figures (live products) are the server's and stay empty.
class StockCopy {
  const StockCopy(this._rows, {this.outletNames = const {}});

  final CopyRows _rows;

  /// Outlet names by id (the session's outlets), for the warehouse lines.
  final Map<int, String> outletNames;

  Future<List<StockWarehouse>> _warehouses({bool scopeOnly = true}) async {
    final rows = await _rows('warehouses');
    return [
      for (final w in rows)
        if (Json.str(w['status']) != 'archived' &&
            (!scopeOnly || w['in_scope'] == null || Json.flag(w['in_scope'])))
          StockWarehouse.fromJson({
            ...w,
            'outlet_id': w['brand_outlet_id'],
            'outlet': outletNames[Json.integer(w['brand_outlet_id'])],
          }),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Balances per variant over [warehouseIds].
  Future<Map<int, List<WarehouseBalance>>> _balances(
    Set<int> warehouseIds,
  ) async {
    final out = <int, List<WarehouseBalance>>{};
    for (final b in await _rows('stock_balances')) {
      final wid = Json.integer(b['warehouse_id']);
      final vid = Json.integer(b['variant_id']);
      if (wid == null || vid == null || !warehouseIds.contains(wid)) continue;
      (out[vid] ??= []).add((
        warehouseId: wid,
        onHand: Json.integer(b['on_hand']) ?? 0,
        reserved: Json.integer(b['reserved']) ?? 0,
      ));
    }
    return out;
  }

  static Map<String, dynamic> _variant(
    Map<String, dynamic> v,
    List<WarehouseBalance> balances,
  ) {
    final onHand = balances.fold<int>(0, (s, b) => s + b.onHand);
    final held = balances.fold<int>(0, (s, b) => s + b.reserved);
    final available = (onHand - held) < 0 ? 0 : onHand - held;
    final low = Json.integer(v['low_stock_at']) ?? 0;
    return {
      'id': v['id'],
      'name': v['name'],
      'sku': v['sku'],
      'price': v['sale_price'],
      'on_hand': onHand,
      'held': held,
      'available': available,
      'state': available <= 0 ? 'out' : (available <= low ? 'low' : 'in'),
      'by_warehouse': [
        for (final b in balances)
          {
            'warehouse_id': b.warehouseId,
            'on_hand': b.onHand,
            'reserved': b.reserved,
          },
      ],
    };
  }

  static bool _active(Map<String, dynamic> r) =>
      r['status'] == null || Json.str(r['status']) == 'active';

  /// `GET stock`, from the copy.
  Future<StockOverview> overview({
    String show = 'all',
    String query = '',
    int? outletId,
    int page = 1,
    int perPage = 20,
  }) async {
    final warehouses = await _warehouses();
    final wanted = {
      for (final w in warehouses)
        if (outletId == null || w.outletId == outletId) w.id,
    };
    final balances = await _balances(wanted);
    final variants = await _rows('stock_variants');
    final q = query.trim().toLowerCase();
    final byProduct = <int, List<Map<String, dynamic>>>{};
    var units = 0, held = 0, low = 0, out = 0, count = 0;
    for (final v in variants) {
      if (!_active(v)) continue;
      final pid = Json.integer(v['seller_product_id']);
      if (pid == null) continue;
      final built = _variant(v, balances[Json.integer(v['id'])] ?? const []);
      count++;
      units += built['on_hand'] as int;
      held += built['held'] as int;
      if (built['state'] == 'low') low++;
      if (built['state'] == 'out') out++;
      final keep =
          show == 'all' ||
          built['state'] == show ||
          (show == 'low' && built['state'] == 'out');
      if (keep) (byProduct[pid] ??= []).add({...built, '_sku': v['sku']});
    }
    final products = <Map<String, dynamic>>[];
    for (final p in await _rows('stock_products')) {
      if (!_active(p)) continue;
      final vs = byProduct[Json.integer(p['id'])];
      if (vs == null || vs.isEmpty) continue;
      final title = Json.str(p['title']) ?? '';
      if (q.isNotEmpty &&
          !title.toLowerCase().contains(q) &&
          !vs.any(
            (v) => (Json.str(v['_sku']) ?? '').toLowerCase().contains(q),
          )) {
        continue;
      }
      products.add({
        'id': p['id'],
        'title': title,
        'tracking': p['tracking'],
        'auto_prefix': p['auto_prefix'],
        'catalogue_product_id': p['product_id'],
        'variants': vs,
      });
    }
    products.sort(
      (a, b) => (a['title'] as String).compareTo(b['title'] as String),
    );
    final last = products.isEmpty ? 1 : ((products.length - 1) ~/ perPage) + 1;
    return StockOverview.fromJson({
      'items': products.skip((page - 1) * perPage).take(perPage).toList(),
      'pagination': {
        'current_page': page,
        'last_page': last,
        'total': products.length,
      },
      'totals': {
        'units': units,
        'held': held,
        'low': low,
        'out': out,
        'variants': count,
      },
      'warehouses': [
        for (final w in warehouses)
          {
            'id': w.id,
            'name': w.name,
            'type': w.type,
            'outlet_id': w.outletId,
            'outlet': w.outlet,
            'sells_online': w.sellsOnline,
            'is_default': w.isDefault,
          },
      ],
      'held': await _holds(wanted),
    }, fromCopy: true);
  }

  Future<List<Map<String, dynamic>>> _holds(Set<int> warehouseIds) async {
    final variants = {
      for (final v in await _rows('stock_variants')) Json.integer(v['id']): v,
    };
    final products = {
      for (final p in await _rows('stock_products')) Json.integer(p['id']): p,
    };
    final names = {
      for (final w in await _rows('warehouses'))
        Json.integer(w['id']): w['name'],
    };
    return [
      for (final h in await _rows('stock_holds'))
        if (_active(h) &&
            warehouseIds.contains(Json.integer(h['warehouse_id'])))
          {
            'id': h['id'],
            'for': h['for'],
            'order_id': h['order_id'],
            'qty': h['qty'],
            'variant': variants[Json.integer(h['variant_id'])]?['name'],
            'product':
                products[Json.integer(
                  variants[Json.integer(h['variant_id'])]?['seller_product_id'],
                )]?['title'],
            'warehouse': names[Json.integer(h['warehouse_id'])],
          },
    ];
  }

  /// Units in stock in this person's warehouses.
  Future<List<UnitOption>> unitsInStock() async {
    final warehouses = {for (final w in await _warehouses()) w.id: w};
    final variants = {
      for (final v in await _rows('stock_variants')) Json.integer(v['id']): v,
    };
    final products = {
      for (final p in await _rows('stock_products')) Json.integer(p['id']): p,
    };
    final out = <UnitOption>[];
    for (final u in await _rows('stock_units')) {
      if (Json.str(u['status']) != 'in_stock') continue;
      final w = warehouses[Json.integer(u['warehouse_id'])];
      if (w == null) continue;
      final v = variants[Json.integer(u['variant_id'])];
      out.add(
        UnitOption(
          id: Json.integer(u['id']),
          serial: Json.str(u['serial']) ?? '',
          variantId: Json.integer(u['variant_id']),
          variant: Json.str(v?['name']),
          product: Json.str(
            products[Json.integer(v?['seller_product_id'])]?['title'],
          ),
          warehouseId: w.id,
          warehouse: w.name,
        ),
      );
    }
    return out;
  }

  /// `GET stock/form-options`, from the copy.
  Future<StockFormOptions> formOptions() async {
    final products = {
      for (final p in await _rows('stock_products'))
        if (_active(p)) Json.integer(p['id']): p,
    };
    final variants = <VariantOption>[
      for (final v in await _rows('stock_variants'))
        if (_active(v) &&
            products[Json.integer(v['seller_product_id'])] != null)
          VariantOption.fromJson({
            'id': v['id'],
            'product_id': v['seller_product_id'],
            'product': products[Json.integer(v['seller_product_id'])]!['title'],
            'variant': v['name'],
            'sku': v['sku'],
            'tracking':
                products[Json.integer(v['seller_product_id'])]!['tracking'],
            'auto_prefix':
                products[Json.integer(v['seller_product_id'])]!['auto_prefix'],
          }),
    ]..sort((a, b) => a.title.compareTo(b.title));
    return StockFormOptions(
      variants: variants,
      warehouses: await _warehouses(),
      allWarehouses: await _warehouses(scopeOnly: false),
      inStockUnits: await unitsInStock(),
    );
  }

  /// `GET stock/products/{id}`, from the copy (no ledger, no website).
  Future<ProductStock?> product(int id) async {
    Map<String, dynamic>? p;
    for (final r in await _rows('stock_products')) {
      if (Json.integer(r['id']) == id) p = r;
    }
    if (p == null) return null;
    final warehouses = await _warehouses();
    final ids = {for (final w in warehouses) w.id};
    final balances = await _balances(ids);
    final variants = [
      for (final v in await _rows('stock_variants'))
        if (_active(v) && Json.integer(v['seller_product_id']) == id)
          _variant(v, balances[Json.integer(v['id'])] ?? const []),
    ];
    final variantIds = {for (final v in variants) Json.integer(v['id'])};
    final perWarehouse = <int, (int, int)>{};
    for (final v in variants) {
      for (final b in Json.list(v['by_warehouse'])) {
        final m = Json.map(b);
        final wid = Json.integer(m['warehouse_id']) ?? 0;
        final cur = perWarehouse[wid] ?? (0, 0);
        perWarehouse[wid] = (
          cur.$1 + (Json.integer(m['on_hand']) ?? 0),
          cur.$2 + (Json.integer(m['reserved']) ?? 0),
        );
      }
    }
    final names = {for (final w in warehouses) w.id: w.name};
    final variantNames = {
      for (final v in variants) Json.integer(v['id']): v['name'],
    };
    return ProductStock.fromJson({
      'product': {
        'id': p['id'],
        'title': p['title'],
        'tracking': p['tracking'],
        'auto_prefix': p['auto_prefix'],
        'catalogue_product_id': p['product_id'],
      },
      'access': {'state': 'active', 'can_change': true},
      'variants': variants,
      'warehouses': [
        for (final w in warehouses)
          {
            'id': w.id,
            'name': w.name,
            'outlet': w.outlet,
            'sells_online': w.sellsOnline,
            'on_hand': perWarehouse[w.id]?.$1 ?? 0,
            'held': perWarehouse[w.id]?.$2 ?? 0,
            'available':
                ((perWarehouse[w.id]?.$1 ?? 0) - (perWarehouse[w.id]?.$2 ?? 0))
                    .clamp(0, 1 << 30),
          },
      ],
      'units': [
        for (final u in await _rows('stock_units'))
          if (variantIds.contains(Json.integer(u['variant_id'])) &&
              ids.contains(Json.integer(u['warehouse_id'])))
            {
              'id': u['id'],
              'serial': u['serial'],
              'variant': variantNames[Json.integer(u['variant_id'])],
              'status': Json.str(u['status']) == 'sold'
                  ? 'delivered'
                  : u['status'],
              'warehouse': Json.str(u['status']) == 'in_stock'
                  ? names[Json.integer(u['warehouse_id'])]
                  : null,
            },
      ],
    });
  }
}
