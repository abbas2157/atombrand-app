import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageMethods {
  LocalStorageMethods._();
  static final instance = LocalStorageMethods._();

  // Flutter Secure Storage for both sensitive and non-sensitive data
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Write data to secure storage (both sensitive and non-sensitive)

  Future<void> writeData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      // 🔥 Encryption failed → clear storage
      await _secureStorage.deleteAll();
      return null;
    }
  }

  ////////////////////
  Future<void> writeUserApiToken(String value) async {
    await _secureStorage.write(key: 'api_token', value: value);
  }

  Future<String?> readUserApiToken() async {
    return await _secureStorage.read(key: 'api_token');
  }

  // Delete data from secure storage
  Future<void> deleteData(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Clear all data from secure storage
  Future<void> clearAllData() async {
    await _secureStorage.deleteAll();
  }
}
