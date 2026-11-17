import 'package:go_router/go_router.dart';

/// A numeric path parameter; 0 (which no record has) when it isn't one, so
/// the screen shows "Not found".
int intParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? 0;

/// A numeric query parameter, or null.
int? intQuery(GoRouterState state, String name) =>
    int.tryParse(state.uri.queryParameters[name] ?? '');

/// A text path parameter; empty when missing.
String textParam(GoRouterState state, String name) =>
    state.pathParameters[name] ?? '';
