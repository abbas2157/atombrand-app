import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/orders_models.dart';
import '../data/orders_providers.dart';
import 'order_parts.dart';

/// Opens a form of an order (deliver, payment) only when the order is at
/// that step. The order is read again as the form opens, so a link, a
/// stale list or a second phone that moved it on can't show Deliver on a
/// Pending order; the decision is kept once made, so the form doesn't turn
/// into "not open" while it is being filled.
class OrderStepGate extends ConsumerStatefulWidget {
  const OrderStepGate({
    super.key,
    required this.uuid,
    required this.fits,
    required this.builder,
    this.notOpenTitle,
  });

  final String uuid;
  final bool Function(CashOrderDetail o) fits;
  final Widget Function(CashOrderDetail o) builder;

  /// "This step isn't open" when null.
  final String? notOpenTitle;

  @override
  ConsumerState<OrderStepGate> createState() => _OrderStepGateState();
}

class _OrderStepGateState extends ConsumerState<OrderStepGate> {
  bool? _fits;
  bool _reread = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.invalidate(orderDetailProvider(widget.uuid));
      setState(() => _reread = true);
    });
  }

  Widget _page(Widget child) => Scaffold(
    backgroundColor: AtomColors.paper,
    body: Column(
      children: [
        const AtomFlowBar(leading: AtomFlowLeading.close),
        Expanded(child: child),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final order = ref.watch(orderDetailProvider(widget.uuid));
    final o = order.value;
    final deciding = _fits == null && (!_reread || order.isLoading);
    if (o == null || deciding) {
      if (order.hasError && !order.isLoading) {
        final e = order.error;
        return _page(
          AtomErrorState(
            message: e is ApiFailure ? sayOrderFailure(e, l) : null,
            onRetry: () => ref.invalidate(orderDetailProvider(widget.uuid)),
          ),
        );
      }
      return _page(const Center(child: AtomSpinner(size: 28)));
    }
    if (!(_fits ??= widget.fits(o))) {
      return _page(
        AtomMessageState(
          icon: LucideIcons.listChecks,
          title: widget.notOpenTitle ?? l.ordersStepNotOpen,
          body: l.ordersGateIsNow(o.order.stageName(l).toLowerCase()),
          actionLabel: l.ordersOpenOrder,
          onAction: () => context.canPop()
              ? context.pop()
              : context.go(V2Routes.orderOf(widget.uuid)),
        ),
      );
    }
    return widget.builder(o);
  }
}
