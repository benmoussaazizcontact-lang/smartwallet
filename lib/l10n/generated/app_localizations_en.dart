// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wallet & Transactions';

  @override
  String get navHome => 'Home';

  @override
  String get navWallets => 'Wallets';

  @override
  String get navActivity => 'Activity';

  @override
  String get navScan => 'Scan';

  @override
  String get navSettings => 'Settings';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get monthExcludesTransfers =>
      'This month, excluding transfers and refunds';

  @override
  String get transfer => 'Transfer';

  @override
  String get payment => 'Payment';

  @override
  String get refund => 'Refund';

  @override
  String get savings => 'Savings';

  @override
  String get addWallet => 'Add Wallet';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get addIncome => 'Add Income';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get retry => 'Retry';

  @override
  String get clear => 'Clear';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get expensesChart => 'Expenses chart';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get myWallets => 'My Wallets';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get noTransactionsYet => 'No transactions yet.';

  @override
  String get noWalletsYet => 'No wallets yet';

  @override
  String get noWalletsHint =>
      'Create a wallet to start recording real activity.';

  @override
  String get currenciesSeparated =>
      'Currencies are shown separately. Totals are never mixed without an explicit FX rate.';

  @override
  String get chartIn => 'In';

  @override
  String get chartOut => 'Out';

  @override
  String get other => 'Other';

  @override
  String get expense => 'Expense';

  @override
  String get walletsTitle => 'Wallets';

  @override
  String get totalsByCurrency => 'Totals by currency';

  @override
  String get firstWalletTitle => 'Create your first wallet';

  @override
  String get firstWalletHint => 'Cash, bank, card, savings or crypto.';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get searchHint => 'Search description or merchant';

  @override
  String get filterType => 'Type';

  @override
  String get filterWallet => 'Wallet';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterDate => 'Date';

  @override
  String get minAmount => 'Min';

  @override
  String get maxAmount => 'Max';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get noTransactionsHint => 'Add an expense or income to see it here.';

  @override
  String get add => 'Add';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get currency => 'Currency';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get categories => 'Categories';

  @override
  String get recurringTransactions => 'Recurring transactions';

  @override
  String get language => 'Language';

  @override
  String get langEnglish => 'English';

  @override
  String get langFrench => 'Français';

  @override
  String get langArabic => 'العربية';

  @override
  String get typeCash => 'Cash';

  @override
  String get typeBank => 'Bank Account';

  @override
  String get typeCard => 'Credit Card';

  @override
  String get typeCrypto => 'Crypto';

  @override
  String get typeSavings => 'Savings';

  @override
  String get typeWallet => 'Wallet';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeIncome => 'Income';

  @override
  String get typePayment => 'Payment';

  @override
  String get typeRefund => 'Refund';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String get typeTransferOut => 'Transfer out';

  @override
  String get name => 'Name';

  @override
  String get required => 'Required';

  @override
  String get walletType => 'Type';

  @override
  String get initialBalance => 'Initial balance';

  @override
  String get creditLimit => 'Credit limit';

  @override
  String get assetSymbol => 'Asset symbol';

  @override
  String get color => 'Color';

  @override
  String get editWallet => 'Edit wallet';

  @override
  String get addWalletTitle => 'Add wallet';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get created => 'Created';

  @override
  String get debt => 'Debt';

  @override
  String get limit => 'Limit';

  @override
  String get available => 'Available';

  @override
  String get archiveWallet => 'Archive wallet';

  @override
  String get archiveWalletTitle => 'Archive wallet?';

  @override
  String get archiveWalletBody =>
      'It will disappear from the list. Balances stay in PostgreSQL.';

  @override
  String get walletTransactions => 'Wallet transactions';

  @override
  String get noWalletTransactions => 'No transactions on this wallet.';

  @override
  String get amount => 'Amount';

  @override
  String get merchant => 'Merchant';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get none => 'None';

  @override
  String get tags => 'Tags';

  @override
  String get newTag => 'New tag';

  @override
  String get dateAndTime => 'Date and time';

  @override
  String get attachLocation => 'Attach current location';

  @override
  String get locationOptional => 'Optional. Never required to save.';

  @override
  String get locationDenied => 'Location permission denied or unavailable.';

  @override
  String get selectWallet => 'Select a wallet';

  @override
  String get selectCategoryLowConfidence =>
      'Select a category — confidence is too low to auto-apply.';

  @override
  String get transactionSaved => 'Transaction saved.';

  @override
  String addType(String type) {
    return 'Add $type';
  }

  @override
  String get tryAdvancedAi => 'Try advanced AI classification';

  @override
  String suggestedCategory(String label) {
    return 'Suggested category: $label';
  }

  @override
  String confidence(int percent) {
    return 'Confidence: $percent %';
  }

  @override
  String get lowConfidenceHint =>
      'Confidence is below 70%. Select the category yourself before saving.';

  @override
  String get transferTitle => 'Transfer money';

  @override
  String get fromWallet => 'From';

  @override
  String get toWallet => 'To';

  @override
  String availableBalance(String amount, String currency) {
    return 'Available $amount · $currency';
  }

  @override
  String get confirmTransfer => 'Confirm transfer';

  @override
  String confirmTransferBody(String amount) {
    return 'Transfer $amount between the selected wallets?';
  }

  @override
  String get transferCompleted => 'Transfer completed.';

  @override
  String get sameWallet => 'Choose two different wallets.';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get scanIntro =>
      'Photograph or import a receipt, preview it, then extract the text. Nothing is saved until you confirm.';

  @override
  String get noImageYet => 'No image yet';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get scanOcr => 'Scan text with OCR';

  @override
  String get ocrProgress => 'Reading the receipt…';

  @override
  String get ocrWebHint =>
      'Google ML Kit OCR runs on Android and iOS. Use a real device for scanning.';

  @override
  String get permissionDeniedMedia =>
      'Camera or gallery permission was denied. You can still type a transaction manually.';

  @override
  String get confirmReceipt => 'Confirm receipt';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get date => 'Date';

  @override
  String get ocrText => 'OCR text';

  @override
  String get confirmAndSave => 'Confirm and save';

  @override
  String get receiptNumber => 'Receipt number';

  @override
  String get receiptSaved => 'Receipt and expense saved after confirmation.';

  @override
  String get customCategory => 'Custom category';

  @override
  String get parent => 'Parent';

  @override
  String get topLevel => 'Top level';

  @override
  String get global => 'Global';

  @override
  String get custom => 'Custom';

  @override
  String get recurringTitle => 'Recurring';

  @override
  String get newRecurrence => 'New recurrence';

  @override
  String get editRecurrence => 'Edit recurrence';

  @override
  String get frequency => 'Frequency';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String nextRun(String date) {
    return 'Next run: $date';
  }

  @override
  String get executions => 'Executions';

  @override
  String get noExecutions =>
      'No executions yet. The hourly job writes here once due.';

  @override
  String get transaction => 'Transaction';

  @override
  String get noDescription => 'No description';

  @override
  String walletLabel(String name) {
    return 'Wallet: $name';
  }

  @override
  String categoryLabel(String name) {
    return 'Category: $name';
  }

  @override
  String statusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String get voidAction => 'Void';

  @override
  String get voidHint => 'A reversing ledger movement will be created.';

  @override
  String get amountRequired => 'Amount required';

  @override
  String get amountInvalid => 'Invalid amount format';

  @override
  String get amountPositive => 'Amount must be positive';

  @override
  String get amountTooHigh => 'Amount is too high';

  @override
  String maxDecimals(int scale) {
    return 'Maximum $scale decimal places';
  }

  @override
  String get catFood => 'Food';

  @override
  String get catRestaurants => 'Restaurants';

  @override
  String get catGroceries => 'Groceries';

  @override
  String get catCoffee => 'Coffee';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catClothes => 'Clothes';

  @override
  String get catElectronics => 'Electronics';

  @override
  String get catSupermarket => 'Supermarket';

  @override
  String get catTransport => 'Transport';

  @override
  String get catTaxi => 'Taxi';

  @override
  String get catFuel => 'Fuel';

  @override
  String get catPublicTransport => 'Public Transport';

  @override
  String get catHousing => 'Housing';

  @override
  String get catRent => 'Rent';

  @override
  String get catElectricity => 'Electricity';

  @override
  String get catWater => 'Water';

  @override
  String get catInternet => 'Internet';

  @override
  String get catHealth => 'Health';

  @override
  String get catPharmacy => 'Pharmacy';

  @override
  String get catDoctor => 'Doctor';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catCinema => 'Cinema';

  @override
  String get catGames => 'Games';

  @override
  String get catGaming => 'Gaming';

  @override
  String get catSubscriptions => 'Subscriptions';

  @override
  String get catIncome => 'Income';

  @override
  String get catSalary => 'Salary';

  @override
  String get catFreelance => 'Freelance';

  @override
  String get catGift => 'Gift';

  @override
  String get catSavings => 'Savings';

  @override
  String get catInvestments => 'Investments';

  @override
  String get insufficientFunds => 'Insufficient funds.';

  @override
  String get creditLimitExceeded => 'Credit limit exceeded.';

  @override
  String get currencyMismatch =>
      'Wallets must use the same currency. No automatic conversion.';

  @override
  String get invalidAmount => 'Invalid amount.';

  @override
  String get walletNotFound => 'Wallet not found or not allowed.';

  @override
  String get networkUnavailable => 'Network unavailable. Try again.';

  @override
  String initial(String amount) {
    return 'Initial $amount';
  }

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingSubtitle => 'Your money, beautifully organized.';

  @override
  String get hideBalance => 'Hide balances';

  @override
  String get showBalance => 'Show balances';

  @override
  String get appearance => 'Appearance';

  @override
  String get financialPreferences => 'Financial preferences';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Wallet & Transactions 1.0.0 — a private finance workspace for your account.';

  @override
  String get transferSuccess => 'Transfer confirmed';

  @override
  String get scanFrameHint => 'Align the receipt inside the frame';

  @override
  String get classificationRules => 'Rule-based suggestion';

  @override
  String get classificationRemote => 'Remote AI suggestion';

  @override
  String get classificationMemory => 'From your previous correction';

  @override
  String get acceptSuggestion => 'Use suggestion';

  @override
  String get monthTrendFlat => 'Spending is in line with last month';

  @override
  String monthTrendUp(String percent) {
    return 'Spending is $percent% above last month';
  }

  @override
  String monthTrendDown(String percent) {
    return 'Spending is $percent% below last month';
  }

  @override
  String get ocrUnreadableImage =>
      'This image could not be read. Choose another photo or retake the receipt.';

  @override
  String get ocrNoText =>
      'No text was found on this image. Try a sharper photo.';

  @override
  String get ocrEngineFailed =>
      'Text recognition failed. You can retry or pick another image.';

  @override
  String get ocrRetryHint =>
      'Retry the scan or select another image. Nothing was saved.';

  @override
  String get ocrArabicLocalUnsupported =>
      'Arabic receipts are not recognized by the on-device scanner. Use a French or English receipt, or enter the amount yourself.';

  @override
  String get amountNeedsReview =>
      'No reliable total was found. Enter the amount due before saving. Subtotal, tax, discount, and change are not used automatically.';

  @override
  String get receiptUploadRetry =>
      'The expense was saved. Receipt upload did not finish. Retrying will not create another transaction.';

  @override
  String get receiptSaveFailed =>
      'The expense was not saved. Check your connection and try again.';

  @override
  String get receiptPendingBody =>
      'A receipt confirmation is still unfinished for this account.';

  @override
  String get receiptAttachAgain => 'Attach the receipt';

  @override
  String get receiptDismissReminder => 'Dismiss reminder';

  @override
  String get notSignedIn => 'Sign in to continue.';

  @override
  String get confidenceNotMeasured =>
      'The model did not provide a confidence score. Confirm the category yourself.';

  @override
  String get welcomeHeadline => 'Manage your\nfinances,\nwith ease.';

  @override
  String get welcomeSubtitle =>
      'Wallet & Transactions — your private finance workspace.';

  @override
  String get welcomeSecure => 'Secured with Supabase Auth';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create an account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get newHere => 'New here?';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'At least 8 characters';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get createMyAccount => 'Create my account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get passwordFair => 'Fair';

  @override
  String get passwordGood => 'Good';

  @override
  String get passwordExcellent => 'Excellent';

  @override
  String passwordStrength(String label) {
    return 'Strength: $label';
  }

  @override
  String get checkEmail => 'Check your email';

  @override
  String checkEmailBody(String email) {
    return 'A confirmation link was sent to $email. Open it to activate your account.';
  }

  @override
  String get goToSignIn => 'Go to sign in';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email to receive a reset link';

  @override
  String get sendResetLink => 'Send the link';

  @override
  String get resetEmailSent => 'Email sent';

  @override
  String resetEmailBody(String email) {
    return 'Check $email and open the link to reset your password.';
  }

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody => 'You will return to the sign-in screen.';

  @override
  String get signOut => 'Sign out';

  @override
  String get preferenceNotSaved => 'Preference was not saved.';

  @override
  String get administration => 'Administration';

  @override
  String get userManagement => 'User management';

  @override
  String get userManagementHint => 'Accounts, sign-ups and activity';

  @override
  String get help => 'Help';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get contactSupportHint => 'A question or an account deletion request';

  @override
  String get myProfile => 'My profile';

  @override
  String get myProfileHint => 'Edit your personal information';

  @override
  String get security => 'Security';

  @override
  String get securityHint => 'MFA, biometrics and sign-in history';

  @override
  String get loginHistory => 'Sign-in history';

  @override
  String get loginHistoryHint => 'Review recent activity';

  @override
  String get createAnotherAccount => 'Create another account';

  @override
  String get createAnotherAccountHint => 'Register a new user';

  @override
  String get signOutHint => 'End the current session';

  @override
  String get guest => 'Guest';

  @override
  String get emailVerified => 'Email verified';

  @override
  String get emailUnverified => 'Not verified';

  @override
  String get startupError => 'Startup error';

  @override
  String get walletLoadFailed => 'This wallet could not be loaded.';

  @override
  String get walletSaveFailed =>
      'The wallet was not saved. Check your connection and try again.';

  @override
  String get twoFactor => 'Two-factor authentication';

  @override
  String get biometrics => 'Biometrics';

  @override
  String get biometricSubtitle =>
      'Protect access with your fingerprint or face';

  @override
  String get devices => 'Devices';

  @override
  String get support => 'Support';

  @override
  String get supportIntro =>
      'Send a request. It is linked to your account so the team can reply.';

  @override
  String get requestType => 'Request type';

  @override
  String get requestQuestion => 'Question or help';

  @override
  String get requestDeletion => 'Account deletion request';

  @override
  String get sendRequest => 'Send request';

  @override
  String get supportLoadFailed => 'Your requests could not be loaded.';

  @override
  String get noSupportRequests => 'No requests sent yet.';

  @override
  String get supportSendFailed => 'The request was not sent.';

  @override
  String get disableTwoFactorTitle => 'Disable 2FA?';

  @override
  String get disable => 'Disable';

  @override
  String get addAnotherFactor => 'Add another factor';

  @override
  String get cancelTwoFactorSetup => 'Cancel and delete this setup';

  @override
  String get done => 'Done';

  @override
  String get signOutThisDevice => 'Sign out of this device';

  @override
  String get signOutOtherSessions => 'Sign out other sessions';

  @override
  String get signOutThisDeviceTitle => 'Sign out of this device?';

  @override
  String get signOutOtherSessionsTitle => 'Sign out other sessions?';

  @override
  String get revoke => 'Revoke';

  @override
  String get signOutWalletTitle => 'Sign out of Wallet?';

  @override
  String get signOutWalletBody =>
      'The Supabase session will close and the local biometric lock will be removed on this device. You will need to sign in again.';

  @override
  String get localLockFailed => 'The local lock could not be checked.';

  @override
  String get signInToSeeHistory => 'Sign in to see the history.';

  @override
  String get adminOverview => 'Overview';

  @override
  String get adminAccounts => 'Accounts';

  @override
  String get adminSupport => 'Support';

  @override
  String get adminAudit => 'Audit log';

  @override
  String get refresh => 'Refresh';

  @override
  String get currentSession => 'Current session';

  @override
  String get subject => 'Subject';

  @override
  String get yourMessage => 'Your message';

  @override
  String get myRequests => 'My requests';

  @override
  String get planTitle => 'Plan';

  @override
  String get planSubtitle => 'Budgets, goals, investments, and the assistant';

  @override
  String get planBudget => 'Budget & expenses';

  @override
  String get planGoals => 'Goals';

  @override
  String get planInvest => 'Investments';

  @override
  String get planAssistant => 'SmartWallet AI';

  @override
  String get planManage => 'Manage my money';

  @override
  String get planIntelligence => 'Financial intelligence';

  @override
  String get planRowBody => 'Budgets, goals, and investments';

  @override
  String get aiAsk => 'Ask a question about your money';

  @override
  String get planBudgetBody => 'Limits and this month\'s spending';

  @override
  String get planGoalsBody => 'Progress toward what you are saving for';

  @override
  String get planInvestBody => 'Portfolios, with educational simulations';

  @override
  String get planInsightsBody => 'Forecasts, alerts, and the 30 analyses';

  @override
  String get planWhatIfBody => 'Try a savings scenario';

  @override
  String get planAssistantBody => 'Answers calculated from your records';

  @override
  String get chartEmptyMonth => 'No spending recorded this month yet.';

  @override
  String get homeAttention => 'Needs attention';

  @override
  String get openDetailedAnalyses => 'Open the 30 analyses';

  @override
  String get budgetDashboard => 'Budget dashboard';

  @override
  String get newBudget => 'New budget';

  @override
  String get budgetName => 'Budget name';

  @override
  String get budgetLimit => 'Spending limit';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get overallBudget => 'Overall budgets';

  @override
  String get categoryBudget => 'Category budgets';

  @override
  String get spentLabel => 'Spent';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get forecastLabel => 'Forecast';

  @override
  String get forecastInsufficient => 'Not enough history to forecast.';

  @override
  String get whatIf => 'What-if';

  @override
  String get monthlyReduction => 'Monthly reduction';

  @override
  String get monthsLabel => 'Months';

  @override
  String get potentialSavings => 'Potential savings';

  @override
  String get deleteBudget => 'Delete budget';

  @override
  String alertReached(int percent) {
    return 'Alert at $percent%';
  }

  @override
  String get goalsTitle => 'Goals';

  @override
  String get newGoal => 'New goal';

  @override
  String get goalTarget => 'Target amount';

  @override
  String get savedLabel => 'Saved';

  @override
  String get contribute => 'Add contribution';

  @override
  String get virtualHint =>
      'This tracks the goal only. It does not move money from a wallet.';

  @override
  String get requiredMonthly => 'Required each month';

  @override
  String get completeGoal => 'Mark complete';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get portfolioTitle => 'Portfolios';

  @override
  String get newPortfolio => 'New portfolio';

  @override
  String get newAsset => 'New asset';

  @override
  String get symbol => 'Symbol';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitPrice => 'Unit price';

  @override
  String get currentPrice => 'Current price';

  @override
  String get manualPrice => 'Manual price';

  @override
  String get unrealized => 'Unrealized gain/loss';

  @override
  String get realized => 'Realized gain/loss';

  @override
  String get allocation => 'Allocation';

  @override
  String get notAdvice =>
      'Figures are estimates from your entries. They are not a recommendation to buy or sell.';

  @override
  String get concentration => 'One holding is more than 40% of this currency.';

  @override
  String get assistantTitle => 'SmartWallet AI';

  @override
  String get assistantHint =>
      'Answers use your recorded transactions. Missing history is stated, not guessed.';

  @override
  String get ask => 'Ask';

  @override
  String get confirmDraft => 'Review transaction';

  @override
  String get draftTitle => 'Confirm before saving';

  @override
  String get chooseWallet => 'Wallet';

  @override
  String get aiLocalOnly =>
      'The remote assistant is not configured. This answer was calculated on your device.';

  @override
  String get recurringSection => 'Upcoming recurring expenses';

  @override
  String get noPlanData => 'Nothing here yet.';

  @override
  String get allCategories => 'All categories';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String get priceMissing => 'Price not set';

  @override
  String get archive => 'Archive';

  @override
  String get aiSuggestMonth => 'How much did I spend this month?';

  @override
  String get aiSuggestCategory => 'What is my biggest expense category?';

  @override
  String get aiSuggestWeek => 'Why are my expenses increasing?';

  @override
  String get aiSuggestDraft => 'I paid 45 dinars at a restaurant yesterday.';

  @override
  String get aiSuggestSave => 'How can I save 300 TND?';

  @override
  String get aiSuggestBalance => 'How much is left in my account?';

  @override
  String get aiSimulation => 'Simulation, not a saved transaction.';

  @override
  String get assetStocks => 'Stocks';

  @override
  String get assetEtf => 'ETF';

  @override
  String get assetCrypto => 'Crypto';

  @override
  String get assetOther => 'Other';

  @override
  String get authCallbackWaiting => 'Opening your SmartWallet session…';

  @override
  String get setNewPassword => 'Choose a new password';

  @override
  String get planInsights => 'Insights and forecasts';

  @override
  String get insightsTitle => 'Financial insights';

  @override
  String get mlBaselineNote =>
      'Figures use your recorded transactions and a statistical baseline. No production model has been trained on this account.';

  @override
  String get next7Days => 'Next 7 days';

  @override
  String get next30Days => 'Next 30 days';

  @override
  String get endOfMonth => 'End of month';

  @override
  String get overspendTitle => 'Overspending risk';

  @override
  String get daysLeft => 'Days left';

  @override
  String get dailyLimit => 'Suggested daily limit';

  @override
  String get subscriptionsTitle => 'Subscriptions';

  @override
  String get priceUp => 'Price increase';

  @override
  String get inactiveSub => 'Inactive';

  @override
  String get duplicateSub => 'Possible duplicate';

  @override
  String get anomaliesTitle => 'Anomaly alerts';

  @override
  String get anomalyDoesNotBlock =>
      'An alert explains a pattern. It never blocks a payment by itself.';

  @override
  String get allocationTitle => 'Suggested allocation';

  @override
  String get surplusLabel => 'Monthly surplus';

  @override
  String get behaviorTitle => 'Spending behavior';

  @override
  String get weekendShare => 'Weekend share';

  @override
  String get monthChange => 'Change versus last month';

  @override
  String get reportsTitle => 'This month';

  @override
  String get netLabel => 'Net';

  @override
  String get goalsPlanTitle => 'Goal feasibility';

  @override
  String get riskTitle => 'Portfolio risk';

  @override
  String get balanceChecks => 'Balance checks';

  @override
  String get consistent => 'Consistent';

  @override
  String get inconsistent => 'Inconsistent';

  @override
  String get unusualMovement => 'Large movement versus your usual payments';

  @override
  String get splitExpense => 'Split expense';

  @override
  String get splitHint =>
      'The two parts must add up to the total. Each part is saved with its own idempotent request.';

  @override
  String get splitPart => 'Part';

  @override
  String get splitReady => 'The parts match the total.';

  @override
  String get splitRemainder => 'Remainder';

  @override
  String get plannerTitle => 'Savings plan';

  @override
  String get recommendedSave => 'Recommended monthly saving';

  @override
  String get voiceUnavailable => 'Speech is not available on this device.';

  @override
  String get arabicOcrLimited =>
      'Arabic text was detected. On-device ML Kit reads Latin script, so check the extracted fields.';

  @override
  String get taxLabel => 'Tax';

  @override
  String get receiptItems => 'Items';

  @override
  String get studioTitle => 'Financial studio';

  @override
  String get studioBaseline =>
      'The thirty cards below are calculated on this device from your records. The lines above are the deployed service response. Experimental models are not real-world validated, and simulations are not guarantees.';

  @override
  String get documentKindLabel => 'Document';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This permanently deletes this account and its records. Type the confirmation word to continue.';

  @override
  String get deleteAccountConfirmWord => 'DELETE';

  @override
  String get deleteAccountUnavailable =>
      'Account deletion is not enabled on the server. No data was deleted.';
}
