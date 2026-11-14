import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Home while today's work first loads (14.2, online only): the navy
/// header's shapes, a card of grey rows, and "Getting today's work…" with
/// the logo stripe. Still, with no shimmer.
class HomeLoadingBody extends StatelessWidget {
  const HomeLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Semantics(
        label: l.dpDbLoadingToday,
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ExcludeSemantics(
                child: Container(
                  color: AtomColors.nav,
                  padding: EdgeInsets.fromLTRB(16, top, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            _dk(36, 36, 10),
                            const SizedBox(width: 10),
                            _dk(140, 16, 10),
                            const Spacer(),
                            _dk(42, 42, 21),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _dk(190, 20, 10),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AtomColors.nav2,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AtomRadius.sheet),
                          ),
                          border: Border.all(color: AtomColors.navLine),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dk(110, 12, 10),
                            const SizedBox(height: 10),
                            _dk(170, 30, 10),
                            const SizedBox(height: 10),
                            _dk(double.infinity, 8, 10),
                            const SizedBox(height: 10),
                            _dk(double.infinity, 44, 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverToBoxAdapter(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AtomColors.skeleton,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const AtomLoadingCard(),
                    ],
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 24),
                  child: AtomLoadingCaption(text: l.dpDbLoadingToday),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _dk(double w, double h, double r) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: AtomColors.nav3,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}
