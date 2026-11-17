import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../atompay/ui/atompay_list.dart';
import '../../sync/ui/offline_bar.dart';
import 'bulk_list_screen.dart';

/// The third tab's root: Bulk deals for a role that may see them; for one
/// that may not, AtomPay orders (5.2's tab bar); for neither, the reason.
class BulkTabRoot extends ConsumerWidget {
  const BulkTabRoot({super.key, this.tab});

  final String? tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final who = ref.watch(sessionProvider.notifier).current?.who;
    if (who == null || who.can(BrandPermission.bulkView)) {
      return BulkListScreen(tab: tab);
    }
    final l = AppLocalizations.of(context);
    final header = Container(
      color: AtomColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.menuAtompay,
            actions: [
              AtomIconButton(
                icon: LucideIcons.search,
                label: l.ordersSearch,
                onTap: () => context.push(V2Routes.search),
              ),
            ],
          ),
          const OfflineBar(),
        ],
      ),
    );
    if (who.can(BrandPermission.atompayView)) {
      return Scaffold(
        backgroundColor: AtomColors.surface,
        body: AtompayListBody(header: header),
      );
    }
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          header,
          Expanded(
            child: AtomMessageState(
              icon: LucideIcons.lock,
              title: l.notInRoleTitle,
              body: l.notInRoleBody,
            ),
          ),
        ],
      ),
    );
  }
}
