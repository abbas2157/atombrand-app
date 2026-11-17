import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/billing_repository.dart' show accountWho;
import 'account_parts.dart';

/// The daily summary's switches (`settings/daily-summary`).
typedef DailySummary = ({
  bool on,
  bool confirm,
  bool quotes,
  bool handOver,
  bool stock,

  /// The message today's data would give (`preview`); null when there is
  /// nothing to report, so nothing would be sent.
  String? preview,
});

DailySummary _fromJson(Object? data) {
  final d = Json.map(Json.map(data)['daily_summary'] ?? data);
  final preview = Json.str(Json.map(data)['preview']);
  bool f(String k, bool fallback) => d[k] == null ? fallback : Json.flag(d[k]);
  return (
    on: f('on', true),
    confirm: f('confirm', true),
    quotes: f('quotes', true),
    handOver: f('hand_over', true),
    stock: f('stock', false),
    preview: preview,
  );
}

Map<String, dynamic> _toJson(DailySummary s) => {
  'on': s.on,
  'confirm': s.confirm,
  'quotes': s.quotes,
  'hand_over': s.handOver,
  'stock': s.stock,
};

/// `GET settings/daily-summary` (owner): the switches, kept on the brand,
/// and today's message.
final dailySummaryProvider = FutureProvider.autoDispose<DailySummary>((
  ref,
) async {
  accountWho(ref);
  final r = await ref
      .read(apiClientProvider)
      .get('settings/daily-summary', parse: _fromJson);
  return switch (r) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});

/// Daily summary (18.12): one message a morning, on WhatsApp and in the
/// app, with what needs doing today. Nothing to report, no message.
class DailySummaryScreen extends ConsumerStatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  ConsumerState<DailySummaryScreen> createState() => _DailySummaryState();
}

class _DailySummaryState extends ConsumerState<DailySummaryScreen> {
  DailySummary? _s;

  Future<void> _set(DailySummary next) async {
    final l = AppLocalizations.of(context);
    final before = _s;
    setState(() => _s = next);
    ref.invalidate(dailySummaryProvider);
    final r = await ref
        .read(apiClientProvider)
        .post('settings/daily-summary', body: _toJson(next), parse: _fromJson);
    if (!mounted) return;
    if (r case ApiOk(:final value)) setState(() => _s = value);
    if (r case ApiErr(:final failure)) {
      setState(() => _s = before);
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: sayFailure(l, failure),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(dailySummaryProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final session = ref.watch(sessionProvider.notifier).current;
    _s ??= data.value;
    final s = _s;
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomFlowBar(title: l.acctDailyTitle),
          Expanded(
            child: switch (data) {
              _ when s != null => ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                children: [
                  AtomRowGroup(
                    children: [
                      _Switch(
                        icon: AtomBrandIcons.whatsapp,
                        title: l.acctDailySend,
                        sub: l.acctDailySendSub,
                        value: s.on,
                        onChanged: online
                            ? (v) => _set((
                                on: v,
                                confirm: s.confirm,
                                quotes: s.quotes,
                                handOver: s.handOver,
                                stock: s.stock,
                                preview: s.preview,
                              ))
                            : null,
                      ),
                    ],
                  ),
                  if (s.on) ...[
                    AtomSectionLabel(l.acctDailyTellsAbout),
                    AtomRowGroup(
                      children: [
                        _Switch(
                          title: l.acctDailyConfirm,
                          sub: l.acctDailyConfirmSub,
                          value: s.confirm,
                          onChanged: online
                              ? (v) => _set((
                                  on: s.on,
                                  confirm: v,
                                  quotes: s.quotes,
                                  handOver: s.handOver,
                                  stock: s.stock,
                                  preview: s.preview,
                                ))
                              : null,
                        ),
                        _Switch(
                          title: l.acctDailyQuotes,
                          sub: l.acctDailyQuotesSub,
                          value: s.quotes,
                          onChanged: online
                              ? (v) => _set((
                                  on: s.on,
                                  confirm: s.confirm,
                                  quotes: v,
                                  handOver: s.handOver,
                                  stock: s.stock,
                                  preview: s.preview,
                                ))
                              : null,
                        ),
                        _Switch(
                          title: l.acctFeatAlerts2,
                          sub: l.acctDailyHandOverSub,
                          value: s.handOver,
                          onChanged: online
                              ? (v) => _set((
                                  on: s.on,
                                  confirm: s.confirm,
                                  quotes: s.quotes,
                                  handOver: v,
                                  stock: s.stock,
                                  preview: s.preview,
                                ))
                              : null,
                        ),
                        _Switch(
                          title: l.acctDailyLow,
                          sub: l.acctDailyLowSub,
                          value: s.stock,
                          onChanged: online
                              ? (v) => _set((
                                  on: s.on,
                                  confirm: s.confirm,
                                  quotes: s.quotes,
                                  handOver: s.handOver,
                                  stock: v,
                                  preview: s.preview,
                                ))
                              : null,
                        ),
                      ],
                    ),
                    AtomSectionLabel(l.acctDailyYouSee),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        // The board's box: 12/14 padding, no border.
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: AtomColors.greenSoft,
                          borderRadius: AtomRadius.brCard,
                        ),
                        child: Text(
                          // Today's real message; with nothing to report, an
                          // example of what one looks like.
                          s.preview ??
                              l.acctDailySample(
                                session?.firstName ?? l.acctDailyThere,
                                session?.brandName ?? l.acctDailyYourBrand,
                              ),
                          style: AtomText.body.copyWith(
                            color: AtomColors.bubbleGreenText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                      child: Text(
                        s.preview == null
                            ? l.settingsDailyPreviewNone
                            : l.acctDailyNothing,
                        style: AtomText.small.copyWith(color: AtomColors.faint),
                      ),
                    ),
                  ],
                ],
              ),
              AsyncError(:final error) => AccountError(
                error: error,
                onRetry: () => ref.invalidate(dailySummaryProvider),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(16),
                child: AtomLoadingRows(count: 5),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final IconData? icon;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                AtomIconTile(icon: icon!, tone: AtomTone.green, size: 36),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AtomText.listTitle),
                    Text(sub, style: AtomText.small),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AtomSwitch(value: value, onChanged: onChanged ?? (_) {}),
            ],
          ),
        ),
      ),
    );
  }
}
