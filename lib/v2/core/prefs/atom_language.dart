import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_methods.dart';

/// The languages Ask Atom answers in (Settings › Language, 18.14):
/// `auto` follows the question.
const atomLanguages = ['auto', 'en', 'roman-ur', 'ur'];

/// Ask Atom's answer language, kept on this phone. Shared by Settings and
/// the Ask Atom feature.
final atomLanguageProvider = NotifierProvider<AtomLanguage, String>(
  AtomLanguage.new,
);

class AtomLanguage extends Notifier<String> {
  static const _key = 'v2_atom_language';

  @override
  String build() {
    _load();
    return 'auto';
  }

  Future<void> _load() async {
    try {
      final v = await LocalStorageMethods.instance.readData(_key);
      if (v is String && atomLanguages.contains(v)) state = v;
    } catch (_) {}
  }

  Future<void> choose(String lang) async {
    state = lang;
    try {
      await LocalStorageMethods.instance.writeData(_key, lang);
    } catch (_) {}
  }
}
