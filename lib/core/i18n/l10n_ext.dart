import 'package:flutter/widgets.dart';

import '../../features/wallets/models/wallet.dart';
import '../../l10n/generated/app_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

String? localizeValidator(AppLocalizations l10n, String? code) {
  return switch (code) {
    'emailRequired' => l10n.emailRequired,
    'emailInvalid' => l10n.emailInvalid,
    'passwordShort' => l10n.passwordTooShort,
    'passwordMismatch' => l10n.passwordMismatch,
    'nameShort' => l10n.required,
    null => null,
    _ => code,
  };
}

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizedWalletType(AppLocalizations l10n, String type) {
  return switch (type) {
    'CASH' => l10n.typeCash,
    'BANK_ACCOUNT' => l10n.typeBank,
    'CREDIT_CARD' => l10n.typeCard,
    'CRYPTO' => l10n.typeCrypto,
    'SAVINGS' => l10n.typeSavings,
    _ => l10n.typeWallet,
  };
}

String localizedTransactionType(AppLocalizations l10n, String type) {
  return switch (type) {
    'EXPENSE' => l10n.typeExpense,
    'INCOME' => l10n.typeIncome,
    'PAYMENT' => l10n.typePayment,
    'REFUND' => l10n.typeRefund,
    'TRANSFER' => l10n.typeTransfer,
    'TRANSFER_OUT' => l10n.typeTransferOut,
    _ => type,
  };
}

String localizedCategoryName(AppLocalizations l10n, String name) {
  return switch (name) {
    'Food' => l10n.catFood,
    'Restaurants' => l10n.catRestaurants,
    'Groceries' => l10n.catGroceries,
    'Coffee' => l10n.catCoffee,
    'Shopping' => l10n.catShopping,
    'Clothes' => l10n.catClothes,
    'Electronics' => l10n.catElectronics,
    'Supermarket' => l10n.catSupermarket,
    'Transport' => l10n.catTransport,
    'Taxi' => l10n.catTaxi,
    'Fuel' => l10n.catFuel,
    'Public Transport' => l10n.catPublicTransport,
    'Housing' => l10n.catHousing,
    'Rent' => l10n.catRent,
    'Electricity' => l10n.catElectricity,
    'Water' => l10n.catWater,
    'Internet' => l10n.catInternet,
    'Health' => l10n.catHealth,
    'Pharmacy' => l10n.catPharmacy,
    'Doctor' => l10n.catDoctor,
    'Entertainment' => l10n.catEntertainment,
    'Cinema' => l10n.catCinema,
    'Games' => l10n.catGames,
    'Gaming' => l10n.catGaming,
    'Subscriptions' => l10n.catSubscriptions,
    'Income' => l10n.catIncome,
    'Salary' => l10n.catSalary,
    'Freelance' => l10n.catFreelance,
    'Gift' => l10n.catGift,
    'Savings' => l10n.catSavings,
    'Investments' => l10n.catInvestments,
    _ => name,
  };
}

String walletTypeLabel(AppLocalizations l10n, WalletBalance wallet) {
  return localizedWalletType(l10n, wallet.walletType);
}
