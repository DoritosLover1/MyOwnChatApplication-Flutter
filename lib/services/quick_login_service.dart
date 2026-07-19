import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../db/account_database.dart';
import '../models/local_account.dart';

class QuickLoginService {
  static const _secureStorage = FlutterSecureStorage();

  static Future<void> saveAccount({
    required String email,
    required String nickname,
    required String password,
  }) async {
    await AccountDatabase.instance.upsertAccount(email, nickname);
    await _secureStorage.write(key: 'pwd_$email', value: password);
  }

  static Future<List<LocalAccount>> getAccounts() async {
    final rows = await AccountDatabase.instance.getAccounts();
    return rows
        .map((r) => LocalAccount(email: r['email'], nickname: r['nickname']))
        .toList();
  }

  static Future<String?> getPassword(String email) async {
    return _secureStorage.read(key: 'pwd_$email');
  }

  static Future<void> removeAccount(String email) async {
    await AccountDatabase.instance.deleteAccount(email);
    await _secureStorage.delete(key: 'pwd_$email');
  }
}
