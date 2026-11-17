import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/ui/sign_in_screen.dart' show atomshopSupportPhone;
import '../../help/data/help_repository.dart';
import '../../help/ui/help_screens.dart'
    show LegalBar, LegalHead, LegalSections, helpErrorText;

/// The terms' head and sections (18.5), or why they can't be shown.
class _TermsBody extends ConsumerWidget {
  const _TermsBody({required this.version});

  /// The version the account must accept (accept mode), for the pill while
  /// the text loads.
  final String? version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(termsDocProvider);
    final doc = data.value;
    final v = doc?.version ?? version;
    final pill = v == null || v.isEmpty
        ? null
        : doc?.updatedAt == null
        ? l.termsVersion(v)
        : l.dpDcTermsPill(v, AtomDates.day(doc!.updatedAt!));
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        LegalHead(title: l.termsTitle, pill: pill, lead: l.termsBody),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: data.isLoading && !data.hasValue
              ? const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: AtomLoadingRows(count: 3),
                )
              : data.hasError && !data.hasValue
              ? AtomErrorState(
                  message: helpErrorText(l, data.error),
                  onRetry: () => ref.invalidate(termsDocProvider),
                )
              : doc!.sections.isNotEmpty
              ? LegalSections(doc: doc)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    AtomNote(
                      kind: AtomNoteKind.warning,
                      message: l.termsNotPublished,
                    ),
                    const SizedBox(height: 12),
                    if (doc.url != null) ...[
                      AtomButton(
                        label: l.termsRead,
                        kind: AtomButtonKind.outline,
                        icon: LucideIcons.fileText,
                        onPressed: () => launchUrl(
                          Uri.parse(doc.url!),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    AtomButton(
                      label: l.termsAskAtomshop,
                      kind: AtomButtonKind.whatsapp,
                      icon: AtomBrandIcons.whatsapp,
                      onPressed: () => launchUrl(
                        Uri.parse(
                          'https://wa.me/${atomshopSupportPhone.substring(1)}',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The bottom bar (`.bottombar`).
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      border: Border(top: BorderSide(color: AtomColors.line)),
    ),
    padding: EdgeInsets.fromLTRB(
      16,
      12,
      16,
      26 + MediaQuery.paddingOf(context).bottom,
    ),
    child: child,
  );
}

/// Terms & conditions to read (18.5), from Help: the sections, and who
/// accepted which version when.
class TermsReadScreen extends ConsumerWidget {
  const TermsReadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final doc = ref.watch(termsDocProvider).value;
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LegalBar(),
          const Expanded(child: _TermsBody(version: null)),
          if (doc?.acceptedBy != null && doc?.acceptedAt != null)
            _BottomBar(
              child: Text(
                l.dpDcTermsAccepted(
                  doc!.acceptedBy!,
                  AtomDates.day(doc.acceptedAt!),
                  doc.acceptedVersion ?? doc.version ?? '',
                ),
                textAlign: TextAlign.center,
                style: AtomText.small.copyWith(color: AtomColors.faint),
              ),
            ),
        ],
      ),
    );
  }
}

/// Terms & conditions, accept mode (18.5): the owner accepts each new
/// version once before using the app; who, when and the version are kept
/// on the server. Back can't get past it; Sign out can.
class TermsAcceptScreen extends ConsumerStatefulWidget {
  const TermsAcceptScreen({super.key});

  @override
  ConsumerState<TermsAcceptScreen> createState() => _TermsAcceptScreenState();
}

class _TermsAcceptScreenState extends ConsumerState<TermsAcceptScreen> {
  bool _ticked = false;
  bool _saving = false;
  String? _error;

  Future<void> _accept(String version) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await ref
        .read(accessProvider.notifier)
        .acceptTerms(version);
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure == null) return; // The router moves on.

    if (failure.kind == ApiFailureKind.validation) {
      // A newer version came out meanwhile: read it again, untick.
      await ref.read(accessProvider.notifier).refresh();
      ref.invalidate(termsDocProvider);
      if (!mounted) return;
      setState(() {
        _ticked = false;
        _error = l.termsChanged;
      });
      return;
    }
    setState(() {
      _error = switch (failure.kind) {
        ApiFailureKind.offline || ApiFailureKind.timeout => l.signInOffline,
        _ => l.commonSomethingWrong,
      };
    });
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final terms = ref.watch(accessProvider).terms;
    final version = terms?.version ?? '';
    final business =
        ref.watch(sessionProvider.notifier).current?.brandName ?? l.appName;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AtomColors.paper,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AtomFlowBar(leading: AtomFlowLeading.none),
            Expanded(child: _TermsBody(version: version)),
            _BottomBar(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    AtomNote(kind: AtomNoteKind.problem, message: _error!),
                    const SizedBox(height: 10),
                  ],
                  AtomPressable(
                    onTap: () => setState(() => _ticked = !_ticked),
                    isButton: false,
                    toggled: _ticked,
                    scaleOnPress: false,
                    semanticLabel: l.termsAcceptBox(business),
                    builder: (_, _) => ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AtomCheckbox(on: _ticked),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.termsAcceptBox(business),
                              style: AtomText.body.copyWith(
                                color: AtomColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AtomButton(
                    label: _ticked ? l.termsAccept : l.termsTickFirst,
                    saving: _saving,
                    onPressed: _ticked && version.isNotEmpty
                        ? () => _accept(version)
                        : null,
                  ),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      l.menuSignOut,
                      style: AtomText.body.copyWith(
                        color: AtomColors.rose,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
