import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'auth_scaffold.dart';
import 'partner_content.dart';
import 'partner_widgets.dart';
import 'verify_code_screen.dart';

/// F4: partner application. Fill the form, verify the phone, submit (§6.4).
class ApplyScreen extends ConsumerStatefulWidget {
  const ApplyScreen({super.key});

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  static const _businessTypes = ['Manufacturer', 'Official distributor', 'Authorised importer', 'Other'];

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _category = TextEditingController();
  final _website = TextEditingController();
  final _productsCount = TextEditingController();
  final _message = TextEditingController();
  String? _businessType;
  int? _percentage;
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _company, _category, _website, _productsCount, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _values() => {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'company': _company.text.trim(),
        'business_type': _businessType,
        if (_category.text.trim().isNotEmpty) 'category': _category.text.trim(),
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
        if (_productsCount.text.trim().isNotEmpty) 'products_count': int.tryParse(_productsCount.text.trim()),
        'percentage': _percentage,
        if (_message.text.trim().isNotEmpty) 'message': _message.text.trim(),
      };

  Future<void> _continue() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final values = _values();
      final challenge = await ref
          .read(authRepositoryProvider)
          .sendApplyCode(phone: values['phone'] as String, email: values['email'] as String, name: values['name'] as String);
      if (!mounted) return;
      final result = await context.push<Object?>('/verify', extra: VerifyArgs.apply(values, challenge));
      // The verify screen pops back with the error when a form field was refused.
      if (result is ApiException && mounted) setState(() => _error = result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String label, String field, {String? hint, String? helper}) =>
      InputDecoration(labelText: label, hintText: hint, helperText: helper, errorText: _error?.fieldError(field));

  @override
  Widget build(BuildContext context) {
    final percentages = ref.watch(configProvider).value?.applyPercentages ?? const [];
    const gap = SizedBox(height: 14);
    return AuthScaffold(
      title: 'Become a partner',
      icon: Icons.handshake_outlined,
      subtitle:
          'Sell your catalogue to instalment-ready buyers across Pakistan. It takes about two minutes, and we reply within ${PartnerContent.replyTime}.',
      children: [
        const _Eligibility(),
        const SizedBox(height: 32),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null && _error!.fieldErrors.isNotEmpty) ...[
                InfoBanner('Please fix the highlighted fields.', color: AppColors.dangerFg),
                gap,
              ],
              const AuthSectionTitle('About you'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: _dec('Your name', 'name'),
                validator: (v) => requiredValidator(v, 'Name'),
              ),
              gap,
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: _dec('Mobile (WhatsApp)', 'phone', hint: '0300 1234567', helper: "We'll send a code to this number"),
                validator: phoneValidator,
              ),
              gap,
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: _dec('Email', 'email', helper: 'Your login is sent here once approved'),
                validator: emailValidator,
              ),
              const SizedBox(height: 28),
              const AuthSectionTitle('Your business'),
              TextFormField(
                controller: _company,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Company / brand name', 'company'),
                validator: (v) => requiredValidator(v, 'Company'),
              ),
              gap,
              DropdownButtonFormField<String>(
                initialValue: _businessType,
                isExpanded: true,
                decoration: _dec('Business type', 'business_type'),
                items: [for (final b in _businessTypes) DropdownMenuItem(value: b, child: Text(b))],
                onChanged: (v) => setState(() => _businessType = v),
                validator: (v) => v == null ? 'Choose a business type.' : null,
              ),
              gap,
              TextFormField(
                controller: _category,
                decoration: _dec('Main category (optional)', 'category', hint: 'e.g. Mobiles, Smart TVs'),
              ),
              gap,
              TextFormField(
                controller: _website,
                keyboardType: TextInputType.url,
                decoration: _dec('Website (optional)', 'website'),
              ),
              gap,
              TextFormField(
                controller: _productsCount,
                keyboardType: TextInputType.number,
                decoration: _dec('Number of products (optional)', 'products_count', helper: 'At least 3 to get listed'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  return (n == null || n < 1) ? 'Enter a whole number, 1 or more.' : null;
                },
              ),
              const SizedBox(height: 28),
              const AuthSectionTitle('Partnership'),
              DropdownButtonFormField<int>(
                initialValue: _percentage,
                isExpanded: true,
                decoration: _dec('AtomShop share per sale', 'percentage', helper: "The % of each sale you're offering AtomShop"),
                items: [for (final p in percentages) DropdownMenuItem(value: p, child: Text('$p%'))],
                onChanged: (v) => setState(() => _percentage = v),
                validator: (v) => v == null ? 'Choose a percentage.' : null,
              ),
              gap,
              TextFormField(
                controller: _message,
                minLines: 3,
                maxLines: 6,
                decoration: _dec('Anything else? (optional)', 'message'),
              ),
              const SizedBox(height: 28),
              BusyButton(label: 'Verify phone & continue', busy: _busy, onPressed: _continue),
              const SizedBox(height: 12),
              Text(
                "Next, we'll send a 6-digit code to your WhatsApp to confirm your number.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Who can apply and what AtomShop looks for, before the form.
class _Eligibility extends StatelessWidget {
  const _Eligibility();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthSectionTitle('Who can apply'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in PartnerContent.whoCanApply)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(w, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.ink)),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const AuthSectionTitle('What we look for'),
          for (final c in PartnerContent.criteria) CheckLine(c),
        ],
      ),
    );
  }
}

class ApplySubmittedScreen extends StatelessWidget {
  const ApplySubmittedScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AuthTheme(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  const Center(child: BrandLogo.mark(height: 26)),
                  const SizedBox(height: 40),
                  const Center(
                    child: AuthIconBadge(
                      Icons.check_rounded,
                      color: AppColors.successFg,
                      background: AppColors.successBg,
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message?.isNotEmpty == true ? message! : 'Application received',
                    textAlign: TextAlign.center,
                    style: authTitleStyle(t),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Thanks for applying. We'll be in touch within ${PartnerContent.replyTime}.",
                    textAlign: TextAlign.center,
                    style: authSubtitleStyle(t),
                  ),
                  const SizedBox(height: 32),
                  const AuthSectionTitle('What happens next'),
                  const PartnerSteps(
                    current: 1,
                    steps: [
                      (title: 'Application sent', body: 'Your details and phone number are verified.'),
                      (title: 'Review', body: 'Our team checks your brand and agrees pricing and margins with you.'),
                      (
                        title: 'Your login arrives',
                        body: "Once approved, we email a temporary password. Sign in here and list your products.",
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  FilledButton(onPressed: () => context.go('/welcome'), child: const Text('Back to start')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
