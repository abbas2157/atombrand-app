import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_icons.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/brand_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../auth/auth_scaffold.dart';

/// F11: edit name / email / phone.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _lastLogin;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final s = ref.read(signedInProvider);
    if (s != null) _fill(s.user.name, s.user.email, s.user.phone, s.user.lastLoginAt);
    _load();
  }

  void _fill(String name, String? email, String? phone, String? lastLogin) {
    _name.text = name;
    _email.text = email ?? '';
    _phone.text = phone ?? '';
    _lastLogin = lastLogin;
  }

  Future<void> _load() async {
    try {
      final (user, brand) = await ref.read(brandRepositoryProvider).profile();
      if (!mounted) return;
      ref.read(sessionProvider.notifier)
        ..updateUser(user)
        ..updateBrand(brand);
      setState(() => _fill(user.name, user.email, user.phone, user.lastLoginAt));
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(brandRepositoryProvider)
          .updateProfile(name: _name.text.trim(), email: _email.text.trim(), phone: _phone.text.trim());
      ref.read(sessionProvider.notifier).updateUser(user);
      if (mounted) showToast(context, 'Profile saved.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(signedInProvider)?.brand;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            AppCard(
              child: Column(
                children: [
                  KeyValue('Brand', brand?.title),
                  KeyValue('Last sign-in', formatDateTime(_lastLogin)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Name', errorText: _error?.fieldError('name')),
              validator: (v) => requiredValidator(v, 'Name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Email', errorText: _error?.fieldError('email')),
              validator: emailValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile (WhatsApp)',
                helperText: 'Sign-in codes are sent here',
                errorText: _error?.fieldError('phone'),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? null : phoneValidator(v),
            ),
            const SizedBox(height: 24),
            BusyButton(label: 'Save', busy: _saving, onPressed: _save),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/change-password'),
              icon: const Icon(AppIcons.lockKey),
              label: const Text('Change password'),
            ),
          ],
        ),
      ),
    );
  }
}

/// F11: change password. Signs out every other device.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  ApiException? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(brandRepositoryProvider).changePassword(_current.text, _password.text, _confirm.text);
      if (!mounted) return;
      showToast(context, 'Password changed. Other devices were signed out.');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget eye() => IconButton(
          tooltip: _obscure ? 'Show passwords' : 'Hide passwords',
          icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff),
          onPressed: () => setState(() => _obscure = !_obscure),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Form(
        key: _form,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const InfoBanner('Changing your password signs you out on every other device.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _current,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Current password',
                  errorText: _error?.fieldError('current_password'),
                  suffixIcon: eye(),
                ),
                validator: (v) => requiredValidator(v, 'Current password'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'New password',
                  helperText: 'At least 8 characters',
                  errorText: _error?.fieldError('password'),
                ),
                validator: passwordValidator,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(labelText: 'Confirm new password'),
                validator: (v) => v != _password.text ? "Passwords don't match." : null,
              ),
              const SizedBox(height: 24),
              BusyButton(label: 'Change password', busy: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

/// F13: delete the account (App Store 5.1.1(v), Google Play account deletion
/// policy). The password confirms it's the owner; then the server deletes the
/// login and this device signs out.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  ApiException? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final brand = ref.read(signedInProvider)?.brand.title ?? 'your brand';
    final go = await confirm(
      context,
      title: 'Delete your account?',
      message: "You'll be signed out and can't sign in to $brand again. This can't be undone.",
      confirmLabel: 'Delete account',
      destructive: true,
    );
    if (!go || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await ref.read(authRepositoryProvider).deleteAccount(_password.text);
      // The router leaves this screen once signed out.
      await ref
          .read(sessionProvider.notifier)
          .accountDeleted(message.isNotEmpty ? message : 'Your account has been deleted.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _busy = false;
      });
      if (e.fieldErrors.isEmpty) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final body = t.bodyMedium?.copyWith(height: 1.5);
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Delete your Atombrand account', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              'This permanently deletes your brand login. You and anyone using it will be signed out on every '
              "device, and order and bulk-request alerts stop. It can't be undone.",
              style: body,
            ),
            const SizedBox(height: 12),
            Text(
              'Your products are taken off AtomShop.pk. Records of orders, payouts and invoices are kept only '
              'as long as the law requires, then deleted.',
              style: body?.copyWith(color: pal.muted),
            ),
            const SizedBox(height: 12),
            Text(
              'If you have orders still in progress or payments due, AtomShop will tell you and settle them first.',
              style: body?.copyWith(color: pal.muted),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _delete(),
              decoration: InputDecoration(
                labelText: 'Enter your password to confirm',
                errorText: _error?.fieldError('password'),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => requiredValidator(v, 'Password'),
            ),
            const SizedBox(height: 24),
            BusyButton(label: 'Delete my account', busy: _busy, danger: true, onPressed: _delete),
          ],
        ),
      ),
    );
  }
}
