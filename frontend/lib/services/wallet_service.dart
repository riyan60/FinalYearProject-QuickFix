import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/money_utils.dart';
import 'auth_service.dart';

class WalletService {
  static const String _walletPrefix = 'wallet_balance_';

  String _walletKey() {
    final session = AuthService.currentSession ?? const <String, dynamic>{};
    final accountId = (session['accountId'] ?? session['id'] ?? 'guest')
        .toString()
        .trim();
    return '$_walletPrefix$accountId';
  }

  Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_walletKey()) ?? 0;
  }

  Future<double> topUp(double amount) async {
    if (amount <= 0) {
      throw Exception('Top-up amount must be greater than zero.');
    }

    final prefs = await SharedPreferences.getInstance();
    final updated = MoneyUtils.normalize(
      (prefs.getDouble(_walletKey()) ?? 0) + amount,
    );
    await prefs.setDouble(_walletKey(), updated);
    await AuthService.updateSessionData({'wallet_balance': updated});
    return updated;
  }

  Future<double> deduct(double amount) async {
    if (amount <= 0) {
      throw Exception('Deduction amount must be greater than zero.');
    }

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getDouble(_walletKey()) ?? 0;
    if (current < amount) {
      throw Exception('Insufficient wallet balance.');
    }

    final updated = MoneyUtils.normalize(current - amount);
    await prefs.setDouble(_walletKey(), updated);
    await AuthService.updateSessionData({'wallet_balance': updated});
    return updated;
  }
}
