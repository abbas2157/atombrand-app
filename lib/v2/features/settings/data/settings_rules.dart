import '../../../../l10n/app_localizations.dart';
import '../../../core/format/ids.dart';

/// Form rules for the Settings screens, without widgets so they can be
/// tested. They follow the server's own (`person_name`, `min:8`).

/// Why Save on Your profile (16.1) can't go, or null.
String? profileProblem(AppLocalizations l, String name, String phone) {
  final n = name.trim();
  if (n.isEmpty) return l.settingsTypeName;
  if (!RegExp(r"^[A-Za-z][A-Za-z .'-]*$").hasMatch(n)) {
    return l.profileNameHint;
  }
  if (phone.trim().isNotEmpty && AtomIds.normaliseMobile(phone) == null) {
    return l.settingsTypeMobile;
  }
  return null;
}

/// Why Change password can't go, or null. The owner types the current one
/// too; a team member doesn't (`me/password`).
String? passwordProblem(
  AppLocalizations l, {
  required bool needsCurrent,
  required String current,
  required String next,
  required String again,
}) {
  if (needsCurrent && current.isEmpty) return l.passwordTypeCurrent;
  if (next.length < 8) return l.auth2RuleLength;
  if (next.length > 100) return l.settingsMax100;
  if (next != again) return l.settingsPasswordsDiffer;
  if (needsCurrent && next == current) {
    return l.settingsPasswordReused;
  }
  return null;
}

/// Why Delete my account can't go, or null.
String? deleteProblem(
  AppLocalizations l, {
  required String password,
  required bool online,
}) {
  if (!online) return l.dpDdNeedsInternet;
  if (password.isEmpty) return l.acctCloseTypePassword;
  return null;
}
