import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

/// Error handling per §5.3: 409 → dialog, 403 → dialog, 422 without field
/// errors / 429 / network → toast. 401 and account-level 403 are handled by
/// the session (it signs out), so nothing extra is shown for those.
Future<void> showApiError(BuildContext context, Object error) async {
  if (!context.mounted) return;
  if (error is! ApiException) {
    showToast(context, 'Something went wrong. Please try again.');
    return;
  }
  final signedOut = ProviderScope.containerOf(context, listen: false).read(sessionProvider) is SignedOut;
  if (error.statusCode == 401 || (error.statusCode == 403 && signedOut)) return;

  if (error.statusCode == 409 || error.statusCode == 403) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(error.statusCode == 403 ? 'Not allowed' : "Can't do that"),
        content: Text(error.message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    return;
  }
  showToast(context, error.message);
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.dangerFg) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<void> openExternal(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) return;
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showToast(context, 'Could not open $url');
}

Future<void> callPhone(BuildContext context, String? phone) async {
  if (phone == null || phone.isEmpty) return;
  final ok = await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
  if (!ok && context.mounted) showToast(context, 'Could not start a call to $phone');
}
