import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_controller.dart';

const prefsHideBalancesKey = 'hide_balances';

class HideBalancesController extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(prefsHideBalancesKey) ??
        false;
  }

  Future<void> toggle() async {
    state = !state;
    await ref.read(sharedPreferencesProvider).setBool(prefsHideBalancesKey, state);
  }
}

final hideBalancesProvider =
    NotifierProvider<HideBalancesController, bool>(HideBalancesController.new);
