import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/session/session.dart';

/// The brand questions Ask Atom offers before anything is typed (12.10),
/// when `ask-atom/context` sends none of its own. Each is shown only to
/// someone whose role can see the answer, the way the server's own checks
/// would answer `no_permission` otherwise.
List<String> brandQuestions(
  AppLocalizations l,
  Who who, {
  required bool inventory,
}) => [
  if (who.can(BrandPermission.ordersView)) l.askAtomQOrders,
  if (who.can(BrandPermission.bulkView)) l.askAtomQQuotes,
  if (inventory && who.can(BrandPermission.stockView)) l.askAtomQLow,
  if (who.canAny([BrandPermission.homeTotals, BrandPermission.moneyReports]))
    l.askAtomQSales,
  if (who.can(BrandPermission.bulkView)) l.askAtomQRequests,
];

/// [brandQuestions] for the person signed in, from their access.
List<String> brandQuestionsFor(
  AppLocalizations l,
  Who? who,
  AccessState access,
) => who == null
    ? const []
    : brandQuestions(l, who, inventory: access.has(Addon.inventory));
