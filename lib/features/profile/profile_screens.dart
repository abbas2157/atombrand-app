import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_icons.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
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
