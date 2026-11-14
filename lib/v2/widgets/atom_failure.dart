import '../../l10n/app_localizations.dart';
import '../core/api/api_result.dart';

/// What to tell the person about a failed call: "no signal" for offline
/// and timeouts, else the server's own words, else "Something went wrong".
String sayFailure(AppLocalizations l, ApiFailure f) => switch (f.kind) {
  ApiFailureKind.offline || ApiFailureKind.timeout => l.payOffline,
  _ => f.message ?? l.commonSomethingWrong,
};
