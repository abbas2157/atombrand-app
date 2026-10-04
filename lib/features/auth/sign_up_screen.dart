import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/feedback.dart';
import 'auth_field.dart';
import 'auth_scaffold.dart';
import 'google_sign_in_button.dart';
import 'partner_content.dart';

/// Create account (DESIGN.md §3.2). UI only for now: brand accounts are set
/// up by AtomShop (BRAND_APP.md §2), so a valid form leads to the partner
/// application instead of creating an account.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;
  bool _submitted = false;
  late final _termsTap = TapGestureRecognizer()..onTap = () => openExternal(context, PartnerContent.termsUrl);

  @override
  void dispose() {
    _termsTap.dispose();
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _confirmMatches => _confirm.text.isNotEmpty && _confirm.text == _password.text;

  /// Shown as soon as the confirmation is as long as the password.
  bool get _confirmMismatch =>
      _confirm.text.isNotEmpty && _confirm.text.length >= _password.text.length && _confirm.text != _password.text;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final valid = _form.currentState!.validate();
    if (!valid || !_agreed) return;
    FocusScope.of(context).unfocus();
    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brand accounts are set up by AtomShop'),
        content: const Text(
          "Apply to become a partner. Once we approve your brand, we'll email you a login for this app.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            child: const Text('Apply now'),
          ),
        ],
      ),
    );
    if (apply == true && mounted) context.push('/apply');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'It only takes a minute',
      compactHeader: true,
      bottomDivider: true,
      bottom: Builder(builder: (context) {
        final p = AppPalette.of(context);
        final termsError = _submitted && !_agreed;
        // While typing, keep only the button pinned so the form has room.
        if (MediaQuery.viewInsetsOf(context).bottom > 0) {
          return AuthButton(label: 'Create Account', onPressed: _submit);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MergeSemantics(
              child: InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreed,
                        isError: termsError,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Privacy Policy',
                              recognizer: _termsTap,
                              style: TextStyle(color: p.primary, fontWeight: FontWeight.w600),
                            ),
                          ]),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.45, color: p.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (termsError)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AuthFieldMessage(
                  'Please accept the terms to continue.',
                  color: p.danger,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            const SizedBox(height: 6),
            AuthButton(label: 'Create Account', onPressed: _submit),
            AuthFooterLink(prompt: 'Already have an account?', action: 'Sign in', onPressed: () => context.pushReplacement('/sign-in')),
          ],
        );
      }),
      children: [
        Form(
          key: _form,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  label: 'Full name',
                  controller: _name,
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => requiredValidator(v, 'Name'),
                ),
                const SizedBox(height: 14),
                AuthField(
                  label: 'Email',
                  controller: _email,
                  icon: Icons.mail_outline_rounded,
                  hint: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: emailValidator,
                ),
                const SizedBox(height: 14),
                AuthField(
                  label: 'Phone',
                  labelSuffix: '(optional)',
                  controller: _phone,
                  icon: Icons.phone_iphone_rounded,
                  hint: '0300 1234567',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: (v) => phoneValidator(v, required: false),
                ),
                const SizedBox(height: 14),
                AuthField(
                  label: 'Password',
                  controller: _password,
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                  scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 72), // keeps the meter in view
                  validator: passwordValidator,
                  below: PasswordStrengthMeter(controller: _password),
                ),
                const SizedBox(height: 14),
                AuthField(
                  label: 'Confirm password',
                  controller: _confirm,
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  errorText: _confirmMismatch ? "Passwords don't match." : null,
                  successText: _confirmMatches ? 'Passwords match' : null,
                  validator: (v) => v.isEmpty
                      ? 'Confirm your password.'
                      : v != _password.text
                          ? "Passwords don't match."
                          : null,
                ),
                const SizedBox(height: 28),
                const OrDivider(text: 'or sign up with'),
                const SizedBox(height: 20),
                const SocialLoginRow(verb: 'Sign up'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
