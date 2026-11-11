import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Transactions'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get navWallets;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @monthExcludesTransfers.
  ///
  /// In en, this message translates to:
  /// **'This month, excluding transfers and refunds'**
  String get monthExcludesTransfers;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @addWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWallet;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @expensesChart.
  ///
  /// In en, this message translates to:
  /// **'Expenses chart'**
  String get expensesChart;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spendingByCategory;

  /// No description provided for @myWallets.
  ///
  /// In en, this message translates to:
  /// **'My Wallets'**
  String get myWallets;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactionsYet;

  /// No description provided for @noWalletsYet.
  ///
  /// In en, this message translates to:
  /// **'No wallets yet'**
  String get noWalletsYet;

  /// No description provided for @noWalletsHint.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet to start recording real activity.'**
  String get noWalletsHint;

  /// No description provided for @currenciesSeparated.
  ///
  /// In en, this message translates to:
  /// **'Currencies are shown separately. Totals are never mixed without an explicit FX rate.'**
  String get currenciesSeparated;

  /// No description provided for @chartIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get chartIn;

  /// No description provided for @chartOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get chartOut;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @walletsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get walletsTitle;

  /// No description provided for @totalsByCurrency.
  ///
  /// In en, this message translates to:
  /// **'Totals by currency'**
  String get totalsByCurrency;

  /// No description provided for @firstWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first wallet'**
  String get firstWalletTitle;

  /// No description provided for @firstWalletHint.
  ///
  /// In en, this message translates to:
  /// **'Cash, bank, card, savings or crypto.'**
  String get firstWalletHint;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search description or merchant'**
  String get searchHint;

  /// No description provided for @filterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterType;

  /// No description provided for @filterWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get filterWallet;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDate;

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxAmount;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// No description provided for @noTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Add an expense or income to see it here.'**
  String get noTransactionsHint;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @recurringTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get recurringTransactions;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @typeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get typeCash;

  /// No description provided for @typeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get typeBank;

  /// No description provided for @typeCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get typeCard;

  /// No description provided for @typeCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get typeCrypto;

  /// No description provided for @typeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get typeSavings;

  /// No description provided for @typeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get typeWallet;

  /// No description provided for @typeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get typeExpense;

  /// No description provided for @typeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get typeIncome;

  /// No description provided for @typePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get typePayment;

  /// No description provided for @typeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get typeRefund;

  /// No description provided for @typeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get typeTransfer;

  /// No description provided for @typeTransferOut.
  ///
  /// In en, this message translates to:
  /// **'Transfer out'**
  String get typeTransferOut;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @walletType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get walletType;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get initialBalance;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// No description provided for @assetSymbol.
  ///
  /// In en, this message translates to:
  /// **'Asset symbol'**
  String get assetSymbol;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @editWallet.
  ///
  /// In en, this message translates to:
  /// **'Edit wallet'**
  String get editWallet;

  /// No description provided for @addWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Add wallet'**
  String get addWalletTitle;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limit;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @archiveWallet.
  ///
  /// In en, this message translates to:
  /// **'Archive wallet'**
  String get archiveWallet;

  /// No description provided for @archiveWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive wallet?'**
  String get archiveWalletTitle;

  /// No description provided for @archiveWalletBody.
  ///
  /// In en, this message translates to:
  /// **'It will disappear from the list. Balances stay in PostgreSQL.'**
  String get archiveWalletBody;

  /// No description provided for @walletTransactions.
  ///
  /// In en, this message translates to:
  /// **'Wallet transactions'**
  String get walletTransactions;

  /// No description provided for @noWalletTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions on this wallet.'**
  String get noWalletTransactions;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get newTag;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @attachLocation.
  ///
  /// In en, this message translates to:
  /// **'Attach current location'**
  String get attachLocation;

  /// No description provided for @locationOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional. Never required to save.'**
  String get locationOptional;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied or unavailable.'**
  String get locationDenied;

  /// No description provided for @selectWallet.
  ///
  /// In en, this message translates to:
  /// **'Select a wallet'**
  String get selectWallet;

  /// No description provided for @selectCategoryLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Select a category — confidence is too low to auto-apply.'**
  String get selectCategoryLowConfidence;

  /// No description provided for @transactionSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved.'**
  String get transactionSaved;

  /// No description provided for @addType.
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String addType(String type);

  /// No description provided for @tryAdvancedAi.
  ///
  /// In en, this message translates to:
  /// **'Try advanced AI classification'**
  String get tryAdvancedAi;

  /// No description provided for @suggestedCategory.
  ///
  /// In en, this message translates to:
  /// **'Suggested category: {label}'**
  String suggestedCategory(String label);

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {percent} %'**
  String confidence(int percent);

  /// No description provided for @lowConfidenceHint.
  ///
  /// In en, this message translates to:
  /// **'Confidence is below 70%. Select the category yourself before saving.'**
  String get lowConfidenceHint;

  /// No description provided for @transferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer money'**
  String get transferTitle;

  /// No description provided for @fromWallet.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromWallet;

  /// No description provided for @toWallet.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toWallet;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available {amount} · {currency}'**
  String availableBalance(String amount, String currency);

  /// No description provided for @confirmTransfer.
  ///
  /// In en, this message translates to:
  /// **'Confirm transfer'**
  String get confirmTransfer;

  /// No description provided for @confirmTransferBody.
  ///
  /// In en, this message translates to:
  /// **'Transfer {amount} between the selected wallets?'**
  String confirmTransferBody(String amount);

  /// No description provided for @transferCompleted.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed.'**
  String get transferCompleted;

  /// No description provided for @sameWallet.
  ///
  /// In en, this message translates to:
  /// **'Choose two different wallets.'**
  String get sameWallet;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceipt;

  /// No description provided for @scanIntro.
  ///
  /// In en, this message translates to:
  /// **'Photograph or import a receipt, preview it, then extract the text. Nothing is saved until you confirm.'**
  String get scanIntro;

  /// No description provided for @noImageYet.
  ///
  /// In en, this message translates to:
  /// **'No image yet'**
  String get noImageYet;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @scanOcr.
  ///
  /// In en, this message translates to:
  /// **'Scan text with OCR'**
  String get scanOcr;

  /// No description provided for @ocrProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading the receipt…'**
  String get ocrProgress;

  /// No description provided for @ocrWebHint.
  ///
  /// In en, this message translates to:
  /// **'Google ML Kit OCR runs on Android and iOS. Use a real device for scanning.'**
  String get ocrWebHint;

  /// No description provided for @permissionDeniedMedia.
  ///
  /// In en, this message translates to:
  /// **'Camera or gallery permission was denied. You can still type a transaction manually.'**
  String get permissionDeniedMedia;

  /// No description provided for @confirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Confirm receipt'**
  String get confirmReceipt;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @ocrText.
  ///
  /// In en, this message translates to:
  /// **'OCR text'**
  String get ocrText;

  /// No description provided for @confirmAndSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm and save'**
  String get confirmAndSave;

  /// No description provided for @receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get receiptNumber;

  /// No description provided for @receiptSaved.
  ///
  /// In en, this message translates to:
  /// **'Receipt and expense saved after confirmation.'**
  String get receiptSaved;

  /// No description provided for @customCategory.
  ///
  /// In en, this message translates to:
  /// **'Custom category'**
  String get customCategory;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// No description provided for @topLevel.
  ///
  /// In en, this message translates to:
  /// **'Top level'**
  String get topLevel;

  /// No description provided for @global.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get global;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTitle;

  /// No description provided for @newRecurrence.
  ///
  /// In en, this message translates to:
  /// **'New recurrence'**
  String get newRecurrence;

  /// No description provided for @editRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Edit recurrence'**
  String get editRecurrence;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @nextRun.
  ///
  /// In en, this message translates to:
  /// **'Next run: {date}'**
  String nextRun(String date);

  /// No description provided for @executions.
  ///
  /// In en, this message translates to:
  /// **'Executions'**
  String get executions;

  /// No description provided for @noExecutions.
  ///
  /// In en, this message translates to:
  /// **'No executions yet. The hourly job writes here once due.'**
  String get noExecutions;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @walletLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet: {name}'**
  String walletLabel(String name);

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {name}'**
  String categoryLabel(String name);

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(String status);

  /// No description provided for @voidAction.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get voidAction;

  /// No description provided for @voidHint.
  ///
  /// In en, this message translates to:
  /// **'A reversing ledger movement will be created.'**
  String get voidHint;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount required'**
  String get amountRequired;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount format'**
  String get amountInvalid;

  /// No description provided for @amountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be positive'**
  String get amountPositive;

  /// No description provided for @amountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Amount is too high'**
  String get amountTooHigh;

  /// No description provided for @maxDecimals.
  ///
  /// In en, this message translates to:
  /// **'Maximum {scale} decimal places'**
  String maxDecimals(int scale);

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get catRestaurants;

  /// No description provided for @catGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get catGroceries;

  /// No description provided for @catCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get catCoffee;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get catClothes;

  /// No description provided for @catElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get catElectronics;

  /// No description provided for @catSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get catSupermarket;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get catTaxi;

  /// No description provided for @catFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get catFuel;

  /// No description provided for @catPublicTransport.
  ///
  /// In en, this message translates to:
  /// **'Public Transport'**
  String get catPublicTransport;

  /// No description provided for @catHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get catHousing;

  /// No description provided for @catRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catRent;

  /// No description provided for @catElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get catElectricity;

  /// No description provided for @catWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get catWater;

  /// No description provided for @catInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get catInternet;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get catPharmacy;

  /// No description provided for @catDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get catDoctor;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catCinema.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get catCinema;

  /// No description provided for @catGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get catGames;

  /// No description provided for @catGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get catGaming;

  /// No description provided for @catSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get catSubscriptions;

  /// No description provided for @catIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get catIncome;

  /// No description provided for @catSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get catSalary;

  /// No description provided for @catFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get catFreelance;

  /// No description provided for @catGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get catGift;

  /// No description provided for @catSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get catSavings;

  /// No description provided for @catInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get catInvestments;

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds.'**
  String get insufficientFunds;

  /// No description provided for @creditLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Credit limit exceeded.'**
  String get creditLimitExceeded;

  /// No description provided for @currencyMismatch.
  ///
  /// In en, this message translates to:
  /// **'Wallets must use the same currency. No automatic conversion.'**
  String get currencyMismatch;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount.'**
  String get invalidAmount;

  /// No description provided for @walletNotFound.
  ///
  /// In en, this message translates to:
  /// **'Wallet not found or not allowed.'**
  String get walletNotFound;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Try again.'**
  String get networkUnavailable;

  /// No description provided for @initial.
  ///
  /// In en, this message translates to:
  /// **'Initial {amount}'**
  String initial(String amount);

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your money, beautifully organized.'**
  String get greetingSubtitle;

  /// No description provided for @hideBalance.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get hideBalance;

  /// No description provided for @showBalance.
  ///
  /// In en, this message translates to:
  /// **'Show balances'**
  String get showBalance;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @financialPreferences.
  ///
  /// In en, this message translates to:
  /// **'Financial preferences'**
  String get financialPreferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Transactions 1.0.0 — a private finance workspace for your account.'**
  String get aboutBody;

  /// No description provided for @transferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transfer confirmed'**
  String get transferSuccess;

  /// No description provided for @scanFrameHint.
  ///
  /// In en, this message translates to:
  /// **'Align the receipt inside the frame'**
  String get scanFrameHint;

  /// No description provided for @classificationRules.
  ///
  /// In en, this message translates to:
  /// **'Rule-based suggestion'**
  String get classificationRules;

  /// No description provided for @classificationRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote AI suggestion'**
  String get classificationRemote;

  /// No description provided for @classificationMemory.
  ///
  /// In en, this message translates to:
  /// **'From your previous correction'**
  String get classificationMemory;

  /// No description provided for @acceptSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Use suggestion'**
  String get acceptSuggestion;

  /// No description provided for @monthTrendFlat.
  ///
  /// In en, this message translates to:
  /// **'Spending is in line with last month'**
  String get monthTrendFlat;

  /// No description provided for @monthTrendUp.
  ///
  /// In en, this message translates to:
  /// **'Spending is {percent}% above last month'**
  String monthTrendUp(String percent);

  /// No description provided for @monthTrendDown.
  ///
  /// In en, this message translates to:
  /// **'Spending is {percent}% below last month'**
  String monthTrendDown(String percent);

  /// No description provided for @ocrUnreadableImage.
  ///
  /// In en, this message translates to:
  /// **'This image could not be read. Choose another photo or retake the receipt.'**
  String get ocrUnreadableImage;

  /// No description provided for @ocrNoText.
  ///
  /// In en, this message translates to:
  /// **'No text was found on this image. Try a sharper photo.'**
  String get ocrNoText;

  /// No description provided for @ocrEngineFailed.
  ///
  /// In en, this message translates to:
  /// **'Text recognition failed. You can retry or pick another image.'**
  String get ocrEngineFailed;

  /// No description provided for @ocrRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Retry the scan or select another image. Nothing was saved.'**
  String get ocrRetryHint;

  /// No description provided for @ocrArabicLocalUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Arabic receipts are not recognized by the on-device scanner. Use a French or English receipt, or enter the amount yourself.'**
  String get ocrArabicLocalUnsupported;

  /// No description provided for @amountNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'No reliable total was found. Enter the amount due before saving. Subtotal, tax, discount, and change are not used automatically.'**
  String get amountNeedsReview;

  /// No description provided for @receiptUploadRetry.
  ///
  /// In en, this message translates to:
  /// **'The expense was saved. Receipt upload did not finish. Retrying will not create another transaction.'**
  String get receiptUploadRetry;

  /// No description provided for @receiptSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The expense was not saved. Check your connection and try again.'**
  String get receiptSaveFailed;

  /// No description provided for @receiptPendingBody.
  ///
  /// In en, this message translates to:
  /// **'A receipt confirmation is still unfinished for this account.'**
  String get receiptPendingBody;

  /// No description provided for @receiptAttachAgain.
  ///
  /// In en, this message translates to:
  /// **'Attach the receipt'**
  String get receiptAttachAgain;

  /// No description provided for @receiptDismissReminder.
  ///
  /// In en, this message translates to:
  /// **'Dismiss reminder'**
  String get receiptDismissReminder;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue.'**
  String get notSignedIn;

  /// No description provided for @confidenceNotMeasured.
  ///
  /// In en, this message translates to:
  /// **'The model did not provide a confidence score. Confirm the category yourself.'**
  String get confidenceNotMeasured;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Manage your\nfinances,\nwith ease.'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Transactions — your private finance workspace.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeSecure.
  ///
  /// In en, this message translates to:
  /// **'Secured with Supabase Auth'**
  String get welcomeSecure;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get signUp;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @createMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get createMyAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// No description provided for @passwordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordFair;

  /// No description provided for @passwordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordGood;

  /// No description provided for @passwordExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get passwordExcellent;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength: {label}'**
  String passwordStrength(String label);

  /// No description provided for @checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmail;

  /// No description provided for @checkEmailBody.
  ///
  /// In en, this message translates to:
  /// **'A confirmation link was sent to {email}. Open it to activate your account.'**
  String checkEmailBody(String email);

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to sign in'**
  String get goToSignIn;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send the link'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Email sent'**
  String get resetEmailSent;

  /// No description provided for @resetEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Check {email} and open the link to reset your password.'**
  String resetEmailBody(String email);

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will return to the sign-in screen.'**
  String get signOutBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @preferenceNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Preference was not saved.'**
  String get preferenceNotSaved;

  /// No description provided for @administration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get userManagement;

  /// No description provided for @userManagementHint.
  ///
  /// In en, this message translates to:
  /// **'Accounts, sign-ups and activity'**
  String get userManagementHint;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @contactSupportHint.
  ///
  /// In en, this message translates to:
  /// **'A question or an account deletion request'**
  String get contactSupportHint;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @myProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Edit your personal information'**
  String get myProfileHint;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securityHint.
  ///
  /// In en, this message translates to:
  /// **'MFA, biometrics and sign-in history'**
  String get securityHint;

  /// No description provided for @loginHistory.
  ///
  /// In en, this message translates to:
  /// **'Sign-in history'**
  String get loginHistory;

  /// No description provided for @loginHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Review recent activity'**
  String get loginHistoryHint;

  /// No description provided for @createAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Create another account'**
  String get createAnotherAccount;

  /// No description provided for @createAnotherAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Register a new user'**
  String get createAnotherAccountHint;

  /// No description provided for @signOutHint.
  ///
  /// In en, this message translates to:
  /// **'End the current session'**
  String get signOutHint;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @emailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get emailUnverified;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Startup error'**
  String get startupError;

  /// No description provided for @walletLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This wallet could not be loaded.'**
  String get walletLoadFailed;

  /// No description provided for @walletSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The wallet was not saved. Check your connection and try again.'**
  String get walletSaveFailed;

  /// No description provided for @twoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get twoFactor;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @biometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect access with your fingerprint or face'**
  String get biometricSubtitle;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportIntro.
  ///
  /// In en, this message translates to:
  /// **'Send a request. It is linked to your account so the team can reply.'**
  String get supportIntro;

  /// No description provided for @requestType.
  ///
  /// In en, this message translates to:
  /// **'Request type'**
  String get requestType;

  /// No description provided for @requestQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question or help'**
  String get requestQuestion;

  /// No description provided for @requestDeletion.
  ///
  /// In en, this message translates to:
  /// **'Account deletion request'**
  String get requestDeletion;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @supportLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your requests could not be loaded.'**
  String get supportLoadFailed;

  /// No description provided for @noSupportRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests sent yet.'**
  String get noSupportRequests;

  /// No description provided for @supportSendFailed.
  ///
  /// In en, this message translates to:
  /// **'The request was not sent.'**
  String get supportSendFailed;

  /// No description provided for @disableTwoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA?'**
  String get disableTwoFactorTitle;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @addAnotherFactor.
  ///
  /// In en, this message translates to:
  /// **'Add another factor'**
  String get addAnotherFactor;

  /// No description provided for @cancelTwoFactorSetup.
  ///
  /// In en, this message translates to:
  /// **'Cancel and delete this setup'**
  String get cancelTwoFactorSetup;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @signOutThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device'**
  String get signOutThisDevice;

  /// No description provided for @signOutOtherSessions.
  ///
  /// In en, this message translates to:
  /// **'Sign out other sessions'**
  String get signOutOtherSessions;

  /// No description provided for @signOutThisDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device?'**
  String get signOutThisDeviceTitle;

  /// No description provided for @signOutOtherSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out other sessions?'**
  String get signOutOtherSessionsTitle;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @signOutWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Wallet?'**
  String get signOutWalletTitle;

  /// No description provided for @signOutWalletBody.
  ///
  /// In en, this message translates to:
  /// **'The Supabase session will close and the local biometric lock will be removed on this device. You will need to sign in again.'**
  String get signOutWalletBody;

  /// No description provided for @localLockFailed.
  ///
  /// In en, this message translates to:
  /// **'The local lock could not be checked.'**
  String get localLockFailed;

  /// No description provided for @signInToSeeHistory.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see the history.'**
  String get signInToSeeHistory;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @adminAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get adminAccounts;

  /// No description provided for @adminSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get adminSupport;

  /// No description provided for @adminAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get adminAudit;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @currentSession.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get currentSession;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get yourMessage;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequests;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planTitle;

  /// No description provided for @planSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets, goals, investments, and the assistant'**
  String get planSubtitle;

  /// No description provided for @planBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget & expenses'**
  String get planBudget;

  /// No description provided for @planGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get planGoals;

  /// No description provided for @planInvest.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get planInvest;

  /// No description provided for @planAssistant.
  ///
  /// In en, this message translates to:
  /// **'SmartWallet AI'**
  String get planAssistant;

  /// No description provided for @planManage.
  ///
  /// In en, this message translates to:
  /// **'Manage my money'**
  String get planManage;

  /// No description provided for @planIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Financial intelligence'**
  String get planIntelligence;

  /// No description provided for @planRowBody.
  ///
  /// In en, this message translates to:
  /// **'Budgets, goals, and investments'**
  String get planRowBody;

  /// No description provided for @aiAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask a question about your money'**
  String get aiAsk;

  /// No description provided for @planBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'Limits and this month\'s spending'**
  String get planBudgetBody;

  /// No description provided for @planGoalsBody.
  ///
  /// In en, this message translates to:
  /// **'Progress toward what you are saving for'**
  String get planGoalsBody;

  /// No description provided for @planInvestBody.
  ///
  /// In en, this message translates to:
  /// **'Portfolios, with educational simulations'**
  String get planInvestBody;

  /// No description provided for @planInsightsBody.
  ///
  /// In en, this message translates to:
  /// **'Forecasts, alerts, and the 30 analyses'**
  String get planInsightsBody;

  /// No description provided for @planWhatIfBody.
  ///
  /// In en, this message translates to:
  /// **'Try a savings scenario'**
  String get planWhatIfBody;

  /// No description provided for @planAssistantBody.
  ///
  /// In en, this message translates to:
  /// **'Answers calculated from your records'**
  String get planAssistantBody;

  /// No description provided for @chartEmptyMonth.
  ///
  /// In en, this message translates to:
  /// **'No spending recorded this month yet.'**
  String get chartEmptyMonth;

  /// No description provided for @homeAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get homeAttention;

  /// No description provided for @openDetailedAnalyses.
  ///
  /// In en, this message translates to:
  /// **'Open the 30 analyses'**
  String get openDetailedAnalyses;

  /// No description provided for @budgetDashboard.
  ///
  /// In en, this message translates to:
  /// **'Budget dashboard'**
  String get budgetDashboard;

  /// No description provided for @newBudget.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get newBudget;

  /// No description provided for @budgetName.
  ///
  /// In en, this message translates to:
  /// **'Budget name'**
  String get budgetName;

  /// No description provided for @budgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Spending limit'**
  String get budgetLimit;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @periodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get periodWeekly;

  /// No description provided for @overallBudget.
  ///
  /// In en, this message translates to:
  /// **'Overall budgets'**
  String get overallBudget;

  /// No description provided for @categoryBudget.
  ///
  /// In en, this message translates to:
  /// **'Category budgets'**
  String get categoryBudget;

  /// No description provided for @spentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spentLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get previousPeriod;

  /// No description provided for @forecastLabel.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecastLabel;

  /// No description provided for @forecastInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough history to forecast.'**
  String get forecastInsufficient;

  /// No description provided for @whatIf.
  ///
  /// In en, this message translates to:
  /// **'What-if'**
  String get whatIf;

  /// No description provided for @monthlyReduction.
  ///
  /// In en, this message translates to:
  /// **'Monthly reduction'**
  String get monthlyReduction;

  /// No description provided for @monthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get monthsLabel;

  /// No description provided for @potentialSavings.
  ///
  /// In en, this message translates to:
  /// **'Potential savings'**
  String get potentialSavings;

  /// No description provided for @deleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get deleteBudget;

  /// No description provided for @alertReached.
  ///
  /// In en, this message translates to:
  /// **'Alert at {percent}%'**
  String alertReached(int percent);

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// No description provided for @newGoal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get newGoal;

  /// No description provided for @goalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get goalTarget;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @contribute.
  ///
  /// In en, this message translates to:
  /// **'Add contribution'**
  String get contribute;

  /// No description provided for @virtualHint.
  ///
  /// In en, this message translates to:
  /// **'This tracks the goal only. It does not move money from a wallet.'**
  String get virtualHint;

  /// No description provided for @requiredMonthly.
  ///
  /// In en, this message translates to:
  /// **'Required each month'**
  String get requiredMonthly;

  /// No description provided for @completeGoal.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get completeGoal;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolios'**
  String get portfolioTitle;

  /// No description provided for @newPortfolio.
  ///
  /// In en, this message translates to:
  /// **'New portfolio'**
  String get newPortfolio;

  /// No description provided for @newAsset.
  ///
  /// In en, this message translates to:
  /// **'New asset'**
  String get newAsset;

  /// No description provided for @symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbol;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get unitPrice;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price'**
  String get currentPrice;

  /// No description provided for @manualPrice.
  ///
  /// In en, this message translates to:
  /// **'Manual price'**
  String get manualPrice;

  /// No description provided for @unrealized.
  ///
  /// In en, this message translates to:
  /// **'Unrealized gain/loss'**
  String get unrealized;

  /// No description provided for @realized.
  ///
  /// In en, this message translates to:
  /// **'Realized gain/loss'**
  String get realized;

  /// No description provided for @allocation.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get allocation;

  /// No description provided for @notAdvice.
  ///
  /// In en, this message translates to:
  /// **'Figures are estimates from your entries. They are not a recommendation to buy or sell.'**
  String get notAdvice;

  /// No description provided for @concentration.
  ///
  /// In en, this message translates to:
  /// **'One holding is more than 40% of this currency.'**
  String get concentration;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'SmartWallet AI'**
  String get assistantTitle;

  /// No description provided for @assistantHint.
  ///
  /// In en, this message translates to:
  /// **'Answers use your recorded transactions. Missing history is stated, not guessed.'**
  String get assistantHint;

  /// No description provided for @ask.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get ask;

  /// No description provided for @confirmDraft.
  ///
  /// In en, this message translates to:
  /// **'Review transaction'**
  String get confirmDraft;

  /// No description provided for @draftTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm before saving'**
  String get draftTitle;

  /// No description provided for @chooseWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get chooseWallet;

  /// No description provided for @aiLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'The remote assistant is not configured. This answer was calculated on your device.'**
  String get aiLocalOnly;

  /// No description provided for @recurringSection.
  ///
  /// In en, this message translates to:
  /// **'Upcoming recurring expenses'**
  String get recurringSection;

  /// No description provided for @noPlanData.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get noPlanData;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @priceMissing.
  ///
  /// In en, this message translates to:
  /// **'Price not set'**
  String get priceMissing;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @aiSuggestMonth.
  ///
  /// In en, this message translates to:
  /// **'How much did I spend this month?'**
  String get aiSuggestMonth;

  /// No description provided for @aiSuggestCategory.
  ///
  /// In en, this message translates to:
  /// **'What is my biggest expense category?'**
  String get aiSuggestCategory;

  /// No description provided for @aiSuggestWeek.
  ///
  /// In en, this message translates to:
  /// **'Why are my expenses increasing?'**
  String get aiSuggestWeek;

  /// No description provided for @aiSuggestDraft.
  ///
  /// In en, this message translates to:
  /// **'I paid 45 dinars at a restaurant yesterday.'**
  String get aiSuggestDraft;

  /// No description provided for @aiSuggestSave.
  ///
  /// In en, this message translates to:
  /// **'How can I save 300 TND?'**
  String get aiSuggestSave;

  /// No description provided for @aiSuggestBalance.
  ///
  /// In en, this message translates to:
  /// **'How much is left in my account?'**
  String get aiSuggestBalance;

  /// No description provided for @aiSimulation.
  ///
  /// In en, this message translates to:
  /// **'Simulation, not a saved transaction.'**
  String get aiSimulation;

  /// No description provided for @assetStocks.
  ///
  /// In en, this message translates to:
  /// **'Stocks'**
  String get assetStocks;

  /// No description provided for @assetEtf.
  ///
  /// In en, this message translates to:
  /// **'ETF'**
  String get assetEtf;

  /// No description provided for @assetCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get assetCrypto;

  /// No description provided for @assetOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get assetOther;

  /// No description provided for @authCallbackWaiting.
  ///
  /// In en, this message translates to:
  /// **'Opening your SmartWallet session…'**
  String get authCallbackWaiting;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get setNewPassword;

  /// No description provided for @planInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights and forecasts'**
  String get planInsights;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial insights'**
  String get insightsTitle;

  /// No description provided for @mlBaselineNote.
  ///
  /// In en, this message translates to:
  /// **'Figures use your recorded transactions and a statistical baseline. No production model has been trained on this account.'**
  String get mlBaselineNote;

  /// No description provided for @next7Days.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get next7Days;

  /// No description provided for @next30Days.
  ///
  /// In en, this message translates to:
  /// **'Next 30 days'**
  String get next30Days;

  /// No description provided for @endOfMonth.
  ///
  /// In en, this message translates to:
  /// **'End of month'**
  String get endOfMonth;

  /// No description provided for @overspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Overspending risk'**
  String get overspendTitle;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get daysLeft;

  /// No description provided for @dailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Suggested daily limit'**
  String get dailyLimit;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptionsTitle;

  /// No description provided for @priceUp.
  ///
  /// In en, this message translates to:
  /// **'Price increase'**
  String get priceUp;

  /// No description provided for @inactiveSub.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveSub;

  /// No description provided for @duplicateSub.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get duplicateSub;

  /// No description provided for @anomaliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Anomaly alerts'**
  String get anomaliesTitle;

  /// No description provided for @anomalyDoesNotBlock.
  ///
  /// In en, this message translates to:
  /// **'An alert explains a pattern. It never blocks a payment by itself.'**
  String get anomalyDoesNotBlock;

  /// No description provided for @allocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested allocation'**
  String get allocationTitle;

  /// No description provided for @surplusLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly surplus'**
  String get surplusLabel;

  /// No description provided for @behaviorTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending behavior'**
  String get behaviorTitle;

  /// No description provided for @weekendShare.
  ///
  /// In en, this message translates to:
  /// **'Weekend share'**
  String get weekendShare;

  /// No description provided for @monthChange.
  ///
  /// In en, this message translates to:
  /// **'Change versus last month'**
  String get monthChange;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reportsTitle;

  /// No description provided for @netLabel.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netLabel;

  /// No description provided for @goalsPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal feasibility'**
  String get goalsPlanTitle;

  /// No description provided for @riskTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio risk'**
  String get riskTitle;

  /// No description provided for @balanceChecks.
  ///
  /// In en, this message translates to:
  /// **'Balance checks'**
  String get balanceChecks;

  /// No description provided for @consistent.
  ///
  /// In en, this message translates to:
  /// **'Consistent'**
  String get consistent;

  /// No description provided for @inconsistent.
  ///
  /// In en, this message translates to:
  /// **'Inconsistent'**
  String get inconsistent;

  /// No description provided for @unusualMovement.
  ///
  /// In en, this message translates to:
  /// **'Large movement versus your usual payments'**
  String get unusualMovement;

  /// No description provided for @splitExpense.
  ///
  /// In en, this message translates to:
  /// **'Split expense'**
  String get splitExpense;

  /// No description provided for @splitHint.
  ///
  /// In en, this message translates to:
  /// **'The two parts must add up to the total. Each part is saved with its own idempotent request.'**
  String get splitHint;

  /// No description provided for @splitPart.
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get splitPart;

  /// No description provided for @splitReady.
  ///
  /// In en, this message translates to:
  /// **'The parts match the total.'**
  String get splitReady;

  /// No description provided for @splitRemainder.
  ///
  /// In en, this message translates to:
  /// **'Remainder'**
  String get splitRemainder;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings plan'**
  String get plannerTitle;

  /// No description provided for @recommendedSave.
  ///
  /// In en, this message translates to:
  /// **'Recommended monthly saving'**
  String get recommendedSave;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech is not available on this device.'**
  String get voiceUnavailable;

  /// No description provided for @arabicOcrLimited.
  ///
  /// In en, this message translates to:
  /// **'Arabic text was detected. On-device ML Kit reads Latin script, so check the extracted fields.'**
  String get arabicOcrLimited;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @receiptItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get receiptItems;

  /// No description provided for @studioTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial studio'**
  String get studioTitle;

  /// No description provided for @studioBaseline.
  ///
  /// In en, this message translates to:
  /// **'The thirty cards below are calculated on this device from your records. The lines above are the deployed service response. Experimental models are not real-world validated, and simulations are not guarantees.'**
  String get studioBaseline;

  /// No description provided for @documentKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentKindLabel;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes this account and its records. Type the confirmation word to continue.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountConfirmWord;

  /// No description provided for @deleteAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account deletion is not enabled on the server. No data was deleted.'**
  String get deleteAccountUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
