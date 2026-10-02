import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Failed loads show an error with "Try again" instead of retrying
      // silently (Riverpod 3 retries by default).
      retry: (_, _) => null,
      child: const BrandApp(),
    ),
  );
}
