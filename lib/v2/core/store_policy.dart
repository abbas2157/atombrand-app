/// What the app may sell, by the stores' rules.
///
/// Atomshop's plan, add-ons and bills are digital services used in the app.
/// Apple (App Review 3.1.1) and Google Play's payments policy want those
/// bought through the store's own billing, and neither lets an app point to
/// paying elsewhere. So the app does not sell them: sellers pay bills and
/// switch add-ons on from their seller dashboard. In the app the plan, the
/// add-ons and the bills are shown as they stand, an add-on can be switched
/// off, and nothing says where or how to pay.
///
/// Collecting a customer's instalment is the seller's own business, not a
/// purchase from Atomshop, and is untouched.
///
/// To sell in the app again, the stores' billing has to come first; flip
/// this only with it.
abstract final class StorePolicy {
  /// False: no Pay bill screen, no Pay buttons, no switching a paid add-on
  /// on, no price list.
  static const sellsInApp = false;
}
