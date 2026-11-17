import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/auth_repository.dart';
import 'auth_parts.dart';

/// Team agent · choose password (2.3), step 1 of 2 on the way in (the PIN
/// is step 2). Every other call is refused until this is done, so the
/// router keeps the agent here; X signs out.
class AgentPasswordScreen extends ConsumerStatefulWidget {
  const AgentPasswordScreen({super.key});

  @override
  ConsumerState<AgentPasswordScreen> createState() =>
      _AgentPasswordScreenState();
}

/// The three rules under the fields (2.3). [temporaryHash] is the hash of
/// the password the agent signed in with, when this phone saw it.
({bool length, bool mix, bool notTemporary}) agentPasswordRules(
  String password, {
  String? temporaryHash,
}) => (
  length: password.length >= 8,
  mix:
      RegExp('[A-Za-z]').hasMatch(password) && RegExp(r'\d').hasMatch(password),
  notTemporary:
      password.isNotEmpty &&
      (temporaryHash == null ||
          LastSignInPassword.hashOf(password) != temporaryHash),
);

class _AgentPasswordScreenState extends ConsumerState<AgentPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _passwordError;
  String? _confirmError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final temporary = ref.read(lastSignInPasswordProvider);
    final rules = agentPasswordRules(_password.text, temporaryHash: temporary);
    setState(() {
      _formError = null;
      _passwordError = !rules.length
          ? l.agentPasswordTooShort
          : !rules.mix
          ? l.auth2RuleMix
          : !rules.notTemporary
          ? l.auth2RuleNotTemp
          : null;
      _confirmError = _passwordError == null && _confirm.text != _password.text
          ? l.agentPasswordMismatch
          : null;
    });
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(authRepositoryProvider)
        .setAgentPassword(_password.text);
    if (!mounted) return;
    switch (result) {
      case ApiOk():
        ref.read(lastSignInPasswordProvider.notifier).forget();
        // 2.4 saves this one behind the fingerprint, not the temporary one.
        ref.read(pendingSignInProvider.notifier).newPassword(_password.text);
        // The router moves on once the flag is off: step 2, the PIN, says
        // it worked (no toast over its keypad).
        final sessions = ref.read(sessionProvider.notifier);
        final who = sessions.current?.who;
        if (who != null) {
          await sessions.updateWho(who.copyWith(mustChangePassword: false));
        }
      case ApiErr(:final failure):
        setState(() {
          _saving = false;
          _passwordError = failure.fieldErrors['password'];
          if (_passwordError == null) {
            _formError = switch (failure.kind) {
              ApiFailureKind.offline ||
              ApiFailureKind.timeout => l.signInOffline,
              _ => failure.message ?? l.commonSomethingWrong,
            };
          }
        });
    }
  }

  Future<void> _signOut() async {
    ref.read(lastSignInPasswordProvider.notifier).forget();
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final rules = agentPasswordRules(
      _password.text,
      temporaryHash: ref.watch(lastSignInPasswordProvider),
    );
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AtomColors.paper,
        body: Column(
          children: [
            AtomFlowBar(
              leading: AtomFlowLeading.close,
              onLeading: _signOut,
              trailing: [AuthStepLabel(l.pinStepOf(1))],
            ),
            Expanded(
              child: AutofillGroup(
                child: AuthScrollBody(
                  children: [
                    if (session != null) _WhoCard(l: l),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(l.agentPasswordTitle, style: AuthText.h1),
                    ),
                    const SizedBox(height: 8),
                    Text(l.agentPasswordBody, style: AuthText.sub),
                    const SizedBox(height: 20),
                    AtomPasswordField(
                      label: l.agentPasswordNew,
                      controller: _password,
                      error: _passwordError,
                      showStrength: true,
                      newPassword: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    AtomPasswordField(
                      label: l.agentPasswordConfirm,
                      controller: _confirm,
                      error: _confirmError,
                      newPassword: true,
                      reveal: false,
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 16),
                    _Rule(ok: rules.length, label: l.auth2RuleLength),
                    const SizedBox(height: 8),
                    _Rule(ok: rules.mix, label: l.auth2RuleMix),
                    const SizedBox(height: 8),
                    _Rule(ok: rules.notTemporary, label: l.auth2RuleNotTemp),
                    const Spacer(),
                    const SizedBox(height: 20),
                    if (_formError != null) ...[
                      AtomNote(
                        kind: AtomNoteKind.problem,
                        message: _formError!,
                      ),
                      const SizedBox(height: AtomSpace.s3),
                    ],
                    AtomButton(
                      label: l.agentPasswordSave,
                      saving: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The agent's card: initials, name, shop, and the role.
class _WhoCard extends ConsumerWidget {
  const _WhoCard({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider.notifier).current!;
    final shop = [
      if (s.brandName != null) s.brandName!,
      if (s.outletName != null) s.outletName!,
    ].join(' · ');
    final role = s.who.roleName;
    return Container(
      padding: const EdgeInsets.all(AtomSpace.inset),
      decoration: BoxDecoration(
        color: AtomColors.head,
        borderRadius: AtomRadius.brCard,
        border: Border.all(color: AtomColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AtomColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              s.initials,
              style: AtomText.input.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: AtomText.listTitle),
                if (shop.isNotEmpty) Text(shop, style: AuthText.small),
              ],
            ),
          ),
          if (role != null && role.isNotEmpty) ...[
            const SizedBox(width: 8),
            // Scales down rather than squeeze the name at large text.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AtomPill(label: role, tone: AtomTone.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.rule`: a tick and the rule, green once it is met.
class _Rule extends StatelessWidget {
  const _Rule({required this.ok, required this.label});
  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colour = ok ? AtomColors.green : AtomColors.muted;
    return Semantics(
      checked: ok,
      label: label,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(
              ok ? LucideIcons.check : LucideIcons.circle,
              size: ok ? 16 : 12,
              color: colour,
            ),
            SizedBox(width: ok ? 8 : 10),
            Expanded(
              child: Text(
                label,
                style: AtomText.secondary.copyWith(color: colour),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
