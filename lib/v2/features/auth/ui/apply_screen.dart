import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/ids.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/auth_repository.dart';
import 'auth_parts.dart';

/// The five shares 2.3 offers, with 10% picked to start.
const applyBoardShares = <num>[5, 8, 10, 12, 15];
const applyDefaultShare = 10;

/// The commission shares Apply offers: the board's five, kept to those the
/// server accepts (`GET config` → `apply.percentages`, which `POST apply`
/// validates against). If the server allows none of them, its own list
/// (at most five) is offered so the application can still be sent.
final applyPercentagesProvider = FutureProvider.autoDispose<List<num>>((
  ref,
) async {
  final result = await ref.read(authRepositoryProvider).config();
  final raw = Json.list(Json.map(result.valueOrNull?['apply'])['percentages']);
  final server = [
    for (final p in raw)
      if (p is num) p else ?num.tryParse('$p'),
  ];
  if (server.isEmpty) return applyBoardShares;
  final allowed = [
    for (final p in applyBoardShares)
      if (server.contains(p)) p,
  ];
  return allowed.length >= 2 ? allowed : server.take(5).toList();
});

enum _Stage { form, code, done }

/// 2.3 Apply to list your brand: about you, your business, the share per
/// sale (step 1); the WhatsApp code (step 2); Application received.
/// `POST apply/otp/send`, then `POST apply`.
class ApplyScreen extends ConsumerStatefulWidget {
  const ApplyScreen({super.key});

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _category = TextEditingController();
  final _website = TextEditingController();
  final _products = TextEditingController();
  final _message = TextEditingController();
  final _code = TextEditingController();

  _Stage _stage = _Stage.form;
  String _type = 'Manufacturer';
  num? _share;
  bool _busy = false;
  Map<String, String> _errors = const {};
  String? _formError;

  static const _types = [
    'Manufacturer',
    'Official distributor',
    'Authorised importer',
    'Other',
  ];

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _email,
      _company,
      _category,
      _website,
      _products,
      _message,
      _code,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _mobile => AtomIds.normaliseMobile(_phone.text);

  /// The share picked, or the board's 10% to start (the first one offered
  /// if the server doesn't allow 10%).
  num? _shareIn(List<num> shares) {
    if (shares.isEmpty) return null;
    if (_share != null && shares.contains(_share)) return _share;
    return shares.contains(applyDefaultShare)
        ? applyDefaultShare
        : shares.first;
  }

  num? get _chosenShare =>
      _shareIn(ref.read(applyPercentagesProvider).value ?? const []);

  /// Step 1 → 2: check the form, then send the code to the phone.
  Future<void> _sendCode() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final errors = <String, String>{
      if (_name.text.trim().isEmpty) 'name': l.applyRequired,
      if (_mobile == null) 'phone': l.signInMobileInvalid,
      if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.text.trim()))
        'email': l.signInEmailInvalid,
      if (_company.text.trim().isEmpty) 'company': l.applyRequired,
      if (_chosenShare == null) 'percentage': l.applyRequired,
    };
    setState(() {
      _errors = errors;
      _formError = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _busy = true);
    final result = await ref
        .read(authRepositoryProvider)
        .sendApplyCode(
          phone: _mobile!,
          email: _email.text.trim(),
          name: _name.text.trim(),
          channel: ResetChannel.whatsapp,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case ApiOk():
        setState(() => _stage = _Stage.code);
      case ApiErr(:final failure):
        setState(() {
          _errors = failure.fieldErrors;
          if (_errors.isEmpty) _formError = sayFailure(l, failure);
        });
    }
  }

  /// Step 2: the code, then the application.
  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_code.text.trim().length < 4) return;
    setState(() {
      _busy = true;
      _formError = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .apply(
          BrandApplication(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _mobile!,
            company: _company.text.trim(),
            businessType: _type,
            percentage: _chosenShare!,
            otp: _code.text.trim(),
            category: _category.text.trim().isEmpty
                ? null
                : _category.text.trim(),
            website: _website.text.trim().isEmpty ? null : _website.text.trim(),
            productsCount: int.tryParse(_products.text.trim()),
            message: _message.text.trim().isEmpty ? null : _message.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case ApiOk():
        setState(() => _stage = _Stage.done);
      case ApiErr(:final failure):
        setState(() {
          final otp = failure.fieldErrors['otp'];
          if (otp == null && failure.fieldErrors.isNotEmpty) {
            // A field from step 1: back to the form to fix it.
            _errors = failure.fieldErrors;
            _stage = _Stage.form;
          }
          _formError = otp ?? sayFailure(l, failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final step = switch (_stage) {
      _Stage.form => l.applyStep(1, 2),
      _Stage.code => l.applyStep(2, 2),
      _Stage.done => null,
    };
    return PopScope(
      canPop: _stage != _Stage.code,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _stage = _Stage.form);
      },
      child: Scaffold(
        backgroundColor: AtomColors.paper,
        body: Column(
          children: [
            AtomFlowBar(
              leading: _stage == _Stage.done
                  ? AtomFlowLeading.none
                  : AtomFlowLeading.back,
              trailing: [if (step != null) AuthStepLabel(step)],
            ),
            Expanded(
              child: switch (_stage) {
                _Stage.form => _form(l),
                _Stage.code => _codeStep(l),
                _Stage.done => _done(l),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label,
    TextEditingController c, {
    String? note,
    String? hint,
    String? placeholder,
    IconData? icon,
    TextInputType? keyboard,
    int? minLines,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: AtomTextField(
      label: label,
      controller: c,
      labelNote: note,
      labelNoteInline: note != null,
      hint: hint,
      placeholder: placeholder,
      prefix: icon == null ? null : Icon(icon),
      error: _errors[key],
      keyboardType: keyboard,
      minLines: minLines,
      textInputAction: minLines == null ? TextInputAction.next : null,
    ),
  );

  Widget _form(AppLocalizations l) {
    final shares = ref.watch(applyPercentagesProvider).value ?? const [];
    return AuthScrollBody(
      children: [
        Text(l.applyTitle, style: AuthText.h1),
        const SizedBox(height: 8),
        Text(l.applyBody, style: AuthText.sub),
        const SizedBox(height: 22),
        AtomSectionLabel(l.applyAboutYou, page: false),
        _field('name', l.applyName, _name, icon: LucideIcons.user),
        _field(
          'phone',
          l.applyMobile,
          _phone,
          icon: LucideIcons.smartphone,
          placeholder: '0300 1234567',
          keyboard: TextInputType.phone,
        ),
        _field(
          'email',
          l.signInEmail,
          _email,
          icon: LucideIcons.mail,
          hint: l.applyEmailHint,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        AtomSectionLabel(l.applyBusiness, page: false),
        _field('company', l.applyCompany, _company, icon: LucideIcons.landmark),
        Text(l.applyBusinessType, style: AtomText.fieldLabel),
        const SizedBox(height: 8),
        AtomChips<String>(
          chips: [
            for (final t in _types)
              AtomChip(t, switch (t) {
                'Manufacturer' => l.applyTypeManufacturer,
                'Official distributor' => l.applyTypeDistributor,
                'Authorised importer' => l.applyTypeImporter,
                _ => l.applyTypeOther,
              }),
          ],
          selected: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: 14),
        _field(
          'category',
          l.applyCategory,
          _category,
          note: l.applyOptional,
          placeholder: l.applyCategoryPlaceholder,
        ),
        _field(
          'website',
          l.applyWebsite,
          _website,
          note: l.applyOptional,
          placeholder: 'https://',
          keyboard: TextInputType.url,
        ),
        _field(
          'products_count',
          l.applyProducts,
          _products,
          note: l.applyOptional,
          hint: l.applyProductsHint,
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 8),
        AtomSectionLabel(l.applyPartnership, page: false),
        Text(l.applyShare, style: AtomText.fieldLabel),
        const SizedBox(height: 8),
        if (shares.isEmpty)
          const AtomLoadingRows(count: 1)
        else if (shares.length < 2)
          // One share only: nothing to choose, so just say it.
          Text('${shares.first}%', style: AtomText.listTitle)
        else
          AtomChips<num>(
            chips: [for (final p in shares) AtomChip(p, '$p%')],
            selected: _shareIn(shares),
            onChanged: (p) => setState(() => _share = p),
          ),
        if (_errors['percentage'] case final e?) AtomFieldError(e),
        const SizedBox(height: 14),
        _field(
          'message',
          l.applyMessage,
          _message,
          note: l.applyOptional,
          minLines: 3,
        ),
        AtomNote(
          kind: AtomNoteKind.info,
          title: l.applyWhoTitle,
          icon: LucideIcons.shieldCheck,
          message: l.applyWhoBody,
        ),
        const SizedBox(height: 18),
        if (_formError != null) ...[
          AtomNote(kind: AtomNoteKind.problem, message: _formError!),
          const SizedBox(height: 12),
        ],
        AtomButton(label: l.applyVerify, saving: _busy, onPressed: _sendCode),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l.applyAlreadyPartner,
              style: AtomText.body.copyWith(color: AtomColors.muted),
            ),
            AuthLink(
              label: l.welcomeSignIn,
              onTap: () => context.go(V2Routes.signIn),
            ),
          ],
        ),
      ],
    );
  }

  Widget _codeStep(AppLocalizations l) {
    return AuthScrollBody(
      children: [
        Text(l.applyCodeTitle, style: AuthText.h1),
        const SizedBox(height: 8),
        Text(l.applyCodeBody(_phone.text.trim()), style: AuthText.sub),
        const SizedBox(height: 22),
        AtomCodeInput(
          controller: _code,
          error: _formError != null,
          onCompleted: (_) => _submit(),
        ),
        const SizedBox(height: 14),
        if (_formError != null) ...[
          AtomNote(kind: AtomNoteKind.problem, message: _formError!),
          const SizedBox(height: 12),
        ],
        AuthLink(label: l.applyResend, onTap: _busy ? () {} : _sendCode),
        const Spacer(),
        AtomButton(label: l.applySend, saving: _busy, onPressed: _submit),
        const SizedBox(height: 10),
        AtomButton(
          label: l.applyChange,
          kind: AtomButtonKind.outline,
          onPressed: () => setState(() => _stage = _Stage.form),
        ),
      ],
    );
  }

  Widget _done(AppLocalizations l) {
    Widget step(IconData icon, String title, String body, AtomTone tone) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtomIconTile(icon: icon, tone: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AtomText.listTitle),
                    const SizedBox(height: 2),
                    Text(body, style: AtomText.secondary),
                  ],
                ),
              ),
            ],
          ),
        );
    return AuthScrollBody(
      children: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: AtomIconTile(icon: LucideIcons.check, tone: AtomTone.green),
        ),
        const SizedBox(height: 16),
        Text(l.applyDoneTitle, style: AuthText.h1),
        const SizedBox(height: 8),
        Text(
          l.applyDoneBody(_name.text.trim(), _company.text.trim()),
          style: AuthText.sub,
        ),
        const SizedBox(height: 22),
        AtomSectionLabel(l.applyNext, page: false),
        step(
          LucideIcons.send,
          l.applyNextSent,
          l.applyNextSentBody,
          AtomTone.green,
        ),
        step(
          LucideIcons.search,
          l.applyNextReview,
          l.applyNextReviewBody,
          AtomTone.blue,
        ),
        step(
          LucideIcons.keyRound,
          l.applyNextLogin,
          l.applyNextLoginBody(_email.text.trim()),
          AtomTone.blue,
        ),
        const Spacer(),
        AtomButton(
          label: l.applyBackToStart,
          onPressed: () => context.go(V2Routes.welcome),
        ),
      ],
    );
  }
}
