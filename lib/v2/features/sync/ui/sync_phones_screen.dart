import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_models.dart';
import '../data/sync_repository.dart';
import 'sync_parts.dart';

/// `GET devices`: this person's phones, and the team's for the owner.
final phonesProvider = FutureProvider.autoDispose<PhonesSignedIn>((ref) async {
  final r = await ref.watch(phonesRepositoryProvider).devices();
  return switch (r) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});

/// Phones signed in (10.7): the phones that keep an offline copy, when each
/// last synced and what it has not sent. Signing one out (10.8) deletes its
/// token, so its next call answers 401 and it deletes its copy. Team
/// members see only their own phones; the owner sees the team's too.
class SyncPhonesScreen extends ConsumerWidget {
  const SyncPhonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final phones = ref.watch(phonesProvider);
    return SyncScaffold(
      title: l.syncPhones,
      child: switch (phones) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(phonesProvider.future),
          child: _List(phones: value),
        ),
        AsyncError(:final error) => AtomErrorState(
          message: error is ApiFailure ? sayFailure(l, error) : null,
          onRetry: () => ref.invalidate(phonesProvider),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(16),
          child: AtomLoadingRows(count: 4),
        ),
      },
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.phones});

  final PhonesSignedIn phones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mine = phones.mine.where((d) => d.signedIn).toList();
    final team = [
      for (final t in phones.team)
        for (final d in t.devices)
          if (d.signedIn) (t.name, d),
    ];
    final others = mine.where((d) => !d.thisDevice).length + team.length;
    final online = ref.watch(onlineProvider).value ?? true;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        AtomSectionLabel(l.syncYours, page: false),
        SyncCard(
          children: [
            for (final d in mine) _PhoneRow(device: d),
            if (mine.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(l.syncPhonesEmpty),
              ),
          ],
        ),
        if (team.isNotEmpty) ...[
          const SizedBox(height: 14),
          AtomSectionLabel(l.syncYourTeam, page: false),
          SyncCard(
            children: [
              for (final (name, d) in team) _PhoneRow(device: d, owner: name),
            ],
          ),
        ],
        if (others > 0) ...[
          const SizedBox(height: 14),
          AtomButton(
            label: team.isNotEmpty ? l.syncAllOutTeam : l.syncAllOut,
            kind: AtomButtonKind.danger,
            onPressed: online
                ? () => _signOutAll(context, ref, team: team.isNotEmpty)
                : null,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l.syncPhonesNote,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
      ],
    );
  }

  Future<void> _signOutAll(
    BuildContext context,
    WidgetRef ref, {
    required bool team,
  }) async {
    final l = AppLocalizations.of(context);
    final yes = await showAtomConfirm(
      context,
      title: l.syncAllOutTitle,
      body: l.syncAllOutBody,
      confirmLabel: l.syncSignOut,
      destructive: true,
      sideBySide: true,
    );
    if (!yes || !context.mounted) return;
    final r = await ref.read(phonesRepositoryProvider).revokeAll(team: team);
    if (!context.mounted) return;
    switch (r) {
      case ApiOk(:final value):
        ref.invalidate(phonesProvider);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.syncAllOutOk(value),
        );
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(l, failure),
        );
    }
  }
}

/// One phone (`.dev`): its owner's initials or a phone icon, its name, when
/// it last synced, and Sign out (or "Now" for this phone).
class _PhoneRow extends ConsumerWidget {
  const _PhoneRow({required this.device, this.owner});

  final SyncDevice device;

  /// The team member's name; null for the person's own phones.
  final String? owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = device;
    final name = d.name ?? l.syncUnknownPhone;
    final title = d.thisDevice
        ? l.devicesThisPhone(name)
        : owner == null
        ? name
        : '$owner · $name';
    final late =
        d.unsent > 0 ||
        (d.lastSyncAt != null &&
            DateTime.now().difference(d.lastSyncAt!).inDays >= 3);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (owner != null)
            AtomInitials(name: owner!, size: 36)
          else
            AtomIconTile(
              icon: d.platform == 'ios'
                  ? LucideIcons.smartphone
                  : LucideIcons.tabletSmartphone,
              tone: d.thisDevice ? AtomTone.blue : AtomTone.grey,
              size: 36,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AtomText.listTitle),
                const SizedBox(height: 2),
                Text(
                  phoneLine(l, d),
                  style: AtomText.secondary.copyWith(
                    color: late ? AtomColors.amberInk : null,
                    fontWeight: late ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (d.thisDevice)
            AtomPill(label: l.syncNowTag, tone: AtomTone.green)
          else
            AtomButton.small(
              label: l.syncSignOut,
              onPressed: () =>
                  showSignOutPhone(context, device: d, owner: owner),
            ),
        ],
      ),
    );
  }
}

/// "Synced 9:42 · works offline until 30 Nov", "Last sync 6 days ago · 2
/// changes not sent".
String phoneLine(AppLocalizations l, SyncDevice d) {
  final last = d.lastSyncAt;
  final days = last == null
      ? null
      : -AtomDates.daysFrom(last, today: AtomDates.now());
  final synced = last == null
      ? l.syncNeverSynced
      : days == 0
      ? l.syncSynced(AtomDates.time(last))
      : days! >= 3
      ? l.syncLastSync(l.syncDaysAgo(days))
      : l.syncLastSync(AtomDates.short(last));
  return [
    synced,
    if (d.unsent > 0)
      l.syncNotSent(d.unsent)
    else if (d.offlineUntil != null)
      l.syncOfflineUntil(AtomDates.short(d.offlineUntil!))
    else if (!d.thisDevice)
      l.syncNothingWaiting,
  ].join(' · ');
}

/// Sign a phone out (10.8): what happens to its copy, a warning when it
/// holds changes it never sent, and a button that needs internet.
Future<void> showSignOutPhone(
  BuildContext context, {
  required SyncDevice device,
  String? owner,
}) => showAtomSheet<void>(
  context,
  builder: (_) => _SignOutSheet(device: device, owner: owner),
);

class _SignOutSheet extends ConsumerStatefulWidget {
  const _SignOutSheet({required this.device, this.owner});

  final SyncDevice device;
  final String? owner;

  @override
  ConsumerState<_SignOutSheet> createState() => _SignOutSheetState();
}

class _SignOutSheetState extends ConsumerState<_SignOutSheet> {
  bool _busy = false;

  Future<void> _go() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    final r = await ref.read(phonesRepositoryProvider).revoke(widget.device.id);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case ApiOk(:final value):
        ref.invalidate(phonesProvider);
        Navigator.of(context).pop();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: value ?? l.syncSignedOutOk,
        );
      case ApiErr(:final failure):
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
    final d = widget.device;
    final owner = widget.owner?.split(' ').first;
    final online = ref.watch(onlineProvider).value ?? true;
    final me = ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.session.name : ''),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtomInitials(name: widget.owner ?? me, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        owner == null
                            ? l.syncSignOutThisTitle
                            : l.syncSignOutOwnerTitle(owner),
                        style: AtomText.heading,
                      ),
                    ),
                    Text(
                      [
                        d.name ?? l.syncUnknownPhone,
                        phoneLine(l, d),
                      ].join(' · '),
                      style: AtomText.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (d.unsent > 0) ...[
            const SizedBox(height: 14),
            AtomNote(
              kind: AtomNoteKind.problem,
              message: owner == null
                  ? l.syncUnsentWarn(d.unsent)
                  : '${l.syncUnsentWarn(d.unsent)} ${l.syncUnsentAsk(owner)}',
              bold: [l.syncChanges(d.unsent)],
            ),
          ],
          const SizedBox(height: 14),
          SyncCard(
            children: [
              _Line(label: l.syncNextOnline, value: l.syncCopyDeleted),
              _Line(
                label: owner == null
                    ? l.syncLoginYours
                    : l.syncLoginOwner(owner),
                value: l.syncLoginStays,
              ),
            ],
          ),
          if (owner != null) ...[
            const SizedBox(height: 10),
            Text(l.syncStopCompletely, style: AtomText.small),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: AtomButton(
                  label: l.syncKeepIt,
                  kind: AtomButtonKind.outline,
                  compact: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 13,
                child: AtomButton(
                  label: online ? l.syncSignItOut : l.syncNeedsInternet,
                  kind: AtomButtonKind.danger,
                  compact: true,
                  saving: _busy,
                  onPressed: online ? _go : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AtomText.secondary)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AtomText.secondary.copyWith(
              color: AtomColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
