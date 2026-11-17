import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_icons.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/feedback.dart';
import 'auth_field.dart';
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
  bool _submitted = false;
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
    setState(() => _submitted = true);
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

  @override
  Widget build(BuildContext context) {
    final percentages = ref.watch(configProvider).value?.applyPercentages ?? const [];
    const gap = SizedBox(height: 14);
    return AuthScaffold(
      title: 'Become a partner',
      icon: AppIcons.handshake,
      subtitle:
          'Sell your catalogue to instalment-ready buyers across Pakistan. It takes about two minutes, and we reply within ${PartnerContent.replyTime}.',
      children: [
        const _Eligibility(),
        const SizedBox(height: 32),
        Form(
          key: _form,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null && _error!.fieldErrors.isNotEmpty) ...[
                const AuthBanner('Please fix the highlighted fields.'),
                gap,
              ],
              const AuthSectionTitle('About you'),
              AuthField(
                label: 'Your name',
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                errorText: _error?.fieldError('name'),
                validator: (v) => requiredValidator(v, 'Name'),
              ),
              gap,
              AuthField(
                label: 'Mobile (WhatsApp)',
                controller: _phone,
                hint: '0300 1234567',
                helper: "We'll send a code to this number",
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                errorText: _error?.fieldError('phone'),
                validator: phoneValidator,
              ),
              gap,
              AuthField(
                label: 'Email',
                controller: _email,
                helper: 'Your login is sent here once approved',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: _error?.fieldError('email'),
                validator: emailValidator,
              ),
              const SizedBox(height: 28),
              const AuthSectionTitle('Your business'),
              AuthField(
                label: 'Company / brand name',
                controller: _company,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                errorText: _error?.fieldError('company'),
                validator: (v) => requiredValidator(v, 'Company'),
              ),
              gap,
              const AuthFieldLabel('Business type'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _businessType,
                isExpanded: true,
                decoration: InputDecoration(hintText: 'Choose one', errorText: _error?.fieldError('business_type')),
                items: [for (final b in _businessTypes) DropdownMenuItem(value: b, child: Text(b))],
                onChanged: (v) => setState(() => _businessType = v),
                validator: (v) => v == null ? 'Choose a business type.' : null,
              ),
              gap,
              AuthField(
                label: 'Main category',
                labelSuffix: '(optional)',
                controller: _category,
                hint: 'e.g. Mobiles, Smart TVs',
                textInputAction: TextInputAction.next,
                errorText: _error?.fieldError('category'),
              ),
              gap,
              AuthField(
                label: 'Website',
                labelSuffix: '(optional)',
                controller: _website,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                errorText: _error?.fieldError('website'),
              ),
              gap,
              AuthField(
                label: 'Number of products',
                labelSuffix: '(optional)',
                controller: _productsCount,
                helper: 'At least 3 to get listed',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                errorText: _error?.fieldError('products_count'),
                validator: (v) {
                  if (v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  return (n == null || n < 1) ? 'Enter a whole number, 1 or more.' : null;
                },
              ),
              const SizedBox(height: 28),
              const AuthSectionTitle('Partnership'),
              const AuthFieldLabel('AtomShop share per sale'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _percentage,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Choose a percentage',
                  helperText: "The % of each sale you're offering AtomShop",
                  errorText: _error?.fieldError('percentage'),
                ),
                items: [for (final p in percentages) DropdownMenuItem(value: p, child: Text('$p%'))],
                onChanged: (v) => setState(() => _percentage = v),
                validator: (v) => v == null ? 'Choose a percentage.' : null,
              ),
              gap,
              AuthField(
                label: 'Anything else?',
                labelSuffix: '(optional)',
                controller: _message,
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                errorText: _error?.fieldError('message'),
              ),
              const SizedBox(height: 28),
              AuthButton(label: 'Verify phone & continue', busyLabel: 'Sending code…', busy: _busy, onPressed: _continue),
              const SizedBox(height: 12),
              Builder(
                builder: (context) => Text(
                  "Next, we'll send a 6-digit code to your WhatsApp to confirm your number.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(18)),
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
                    color: p.field,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(w, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.text)),
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
    return AuthTheme(
      child: Builder(builder: (context) {
        final p = AppPalette.of(context);
        return Scaffold(
          backgroundColor: p.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    const Center(child: BrandLogo.inline(height: 28)),
                    const SizedBox(height: 40),
                    Center(child: AuthIconBadge(AppIcons.check, color: p.onSuccess, background: p.success, size: 72)),
                    const SizedBox(height: 24),
                    Text(
                      message?.isNotEmpty == true ? message! : 'Application received',
                      textAlign: TextAlign.center,
                      style: authTitleStyle(context),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Thanks for applying. We'll be in touch within ${PartnerContent.replyTime}.",
                      textAlign: TextAlign.center,
                      style: authSubtitleStyle(context),
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
                    AuthButton(label: 'Back to start', onPressed: () => context.go('/welcome')),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
