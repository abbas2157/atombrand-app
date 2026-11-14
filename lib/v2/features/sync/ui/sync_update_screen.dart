import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/update/update_policy.dart';
import '../../../core/update/updates_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/sync_providers.dart';
import 'sync_parts.dart';

/// Update needed to send (10.6): `sync/check` said this version can't
/// sync (`app.update_needed`, or a newer `sync_version`). Nothing is lost:
/// the outbox stays on the phone and goes out right after the update.
class SyncUpdateScreen extends ConsumerWidget {
  const SyncUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider);
    final ios = !kIsWeb && Platform.isIOS;
    final latest = status.check?.latestVersion;
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: AtomColors.primarySoft,
                          borderRadius: BorderRadius.all(
                            Radius.circular(AtomRadius.sheet),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.download,
                          size: 34,
                          color: AtomColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        header: true,
                        child: Text(
                          l.syncUpdateAppTitle,
                          textAlign: TextAlign.center,
                          style: AtomText.successTitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AtomNote(
                        kind: AtomNoteKind.info,
                        iconless: true,
                        message: l.syncUpdateBody(
                          InstalledApp.current?.version == null
                              ? ''
                              : ' (${InstalledApp.current?.version})',
                          status.waiting,
                        ),
                        bold: [l.syncUpdateBold(status.waiting)],
                      ),
                      const SizedBox(height: 14),
                      SyncCard(
                        children: [
                          _Line(
                            label: l.syncWaitingTitle,
                            value: [
                              l.syncChanges(status.waiting),
                              if (status.photos > 0)
                                l.syncPhotoCount(status.photos),
                            ].join(' · '),
                          ),
                          if (latest != null)
                            _Line(label: l.updateNewVersion, value: latest),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AtomButton(
                    label: ios ? l.updateButtonIos : l.syncUpdateOnPlay,
                    onPressed: () =>
                        ref.read(updatesProvider.notifier).openStore(),
                  ),
                  const SizedBox(height: 10),
                  AtomButton(
                    label: l.syncUpdateLater,
                    kind: AtomButtonKind.outline,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(V2Routes.home),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.syncUpdateSafe,
                    textAlign: TextAlign.center,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        Text(
          value,
          style: AtomText.secondary.copyWith(
            color: AtomColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
