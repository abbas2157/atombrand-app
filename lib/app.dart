import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

class BrandApp extends ConsumerWidget {
  const BrandApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AtomShop Brand Partner',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(AppPalette.light),
      darkTheme: buildTheme(AppPalette.dark),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      // Support system font scaling, capped at 130% (§4.6).
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
          child: child!,
        );
      },
    );
  }
}
