// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Wallet & Transactions';

  @override
  String get navHome => 'Accueil';

  @override
  String get navWallets => 'Portefeuilles';

  @override
  String get navActivity => 'Transactions';

  @override
  String get navScan => 'Scanner un reçu';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get totalBalance => 'Solde total';

  @override
  String get income => 'Revenus';

  @override
  String get expenses => 'Dépenses';

  @override
  String get monthExcludesTransfers =>
      'Ce mois-ci, hors transferts et remboursements';

  @override
  String get transfer => 'Transfert';

  @override
  String get payment => 'Paiement';

  @override
  String get refund => 'Remboursement';

  @override
  String get savings => 'Épargne';

  @override
  String get addWallet => 'Ajouter un portefeuille';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String get addIncome => 'Ajouter un revenu';

  @override
  String get confirm => 'Confirmer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get search => 'Rechercher';

  @override
  String get filter => 'Filtrer';

  @override
  String get retry => 'Réessayer';

  @override
  String get clear => 'Effacer';

  @override
  String get create => 'Créer';

  @override
  String get edit => 'Modifier';

  @override
  String get loading => 'Chargement';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get expensesChart => 'Graphique des dépenses';

  @override
  String get spendingByCategory => 'Dépenses par catégorie';

  @override
  String get myWallets => 'Mes portefeuilles';

  @override
  String get recentTransactions => 'Dernières transactions';

  @override
  String get noTransactionsYet => 'Aucune transaction pour le moment.';

  @override
  String get noWalletsYet => 'Aucun portefeuille';

  @override
  String get noWalletsHint =>
      'Créez un portefeuille pour enregistrer une activité réelle.';

  @override
  String get currenciesSeparated =>
      'Les devises sont affichées séparément. Les totaux ne sont jamais mélangés sans un taux de change explicite.';

  @override
  String get chartIn => 'Entrées';

  @override
  String get chartOut => 'Sorties';

  @override
  String get other => 'Autre';

  @override
  String get expense => 'Dépense';

  @override
  String get walletsTitle => 'Portefeuilles';

  @override
  String get totalsByCurrency => 'Totaux par devise';

  @override
  String get firstWalletTitle => 'Créez votre premier portefeuille';

  @override
  String get firstWalletHint => 'Espèces, banque, carte, épargne ou crypto.';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get searchHint => 'Rechercher une description ou un commerçant';

  @override
  String get filterType => 'Type';

  @override
  String get filterWallet => 'Portefeuille';

  @override
  String get filterCategory => 'Catégorie';

  @override
  String get filterDate => 'Date';

  @override
  String get minAmount => 'Min';

  @override
  String get maxAmount => 'Max';

  @override
  String get noTransactions => 'Aucune transaction';

  @override
  String get noTransactionsHint =>
      'Ajoutez une dépense ou un revenu pour la voir ici.';

  @override
  String get add => 'Ajouter';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get currency => 'Devise';

  @override
  String get theme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get categories => 'Catégories';

  @override
  String get recurringTransactions => 'Transactions récurrentes';

  @override
  String get language => 'Langue';

  @override
  String get langEnglish => 'English';

  @override
  String get langFrench => 'Français';

  @override
  String get langArabic => 'العربية';

  @override
  String get typeCash => 'Espèces';

  @override
  String get typeBank => 'Compte bancaire';

  @override
  String get typeCard => 'Carte de crédit';

  @override
  String get typeCrypto => 'Crypto';

  @override
  String get typeSavings => 'Épargne';

  @override
  String get typeWallet => 'Portefeuille';

  @override
  String get typeExpense => 'Dépense';

  @override
  String get typeIncome => 'Revenu';

  @override
  String get typePayment => 'Paiement';

  @override
  String get typeRefund => 'Remboursement';

  @override
  String get typeTransfer => 'Transfert';

  @override
  String get typeTransferOut => 'Transfert sortant';

  @override
  String get name => 'Nom';

  @override
  String get required => 'Obligatoire';

  @override
  String get walletType => 'Type';

  @override
  String get initialBalance => 'Solde initial';

  @override
  String get creditLimit => 'Plafond de crédit';

  @override
  String get assetSymbol => 'Symbole de l’actif';

  @override
  String get color => 'Couleur';

  @override
  String get editWallet => 'Modifier le portefeuille';

  @override
  String get addWalletTitle => 'Ajouter un portefeuille';

  @override
  String get currentBalance => 'Solde actuel';

  @override
  String get created => 'Créé';

  @override
  String get debt => 'Dette';

  @override
  String get limit => 'Plafond';

  @override
  String get available => 'Disponible';

  @override
  String get archiveWallet => 'Archiver le portefeuille';

  @override
  String get archiveWalletTitle => 'Archiver le portefeuille ?';

  @override
  String get archiveWalletBody =>
      'Il disparaîtra de la liste. Les soldes restent dans PostgreSQL.';

  @override
  String get walletTransactions => 'Transactions du portefeuille';

  @override
  String get noWalletTransactions => 'Aucune transaction sur ce portefeuille.';

  @override
  String get amount => 'Montant';

  @override
  String get merchant => 'Commerçant';

  @override
  String get description => 'Description';

  @override
  String get category => 'Catégorie';

  @override
  String get none => 'Aucune';

  @override
  String get tags => 'Tags';

  @override
  String get newTag => 'Nouveau tag';

  @override
  String get dateAndTime => 'Date et heure';

  @override
  String get attachLocation => 'Associer la position actuelle';

  @override
  String get locationOptional =>
      'Facultatif. Jamais obligatoire pour enregistrer.';

  @override
  String get locationDenied =>
      'Autorisation de localisation refusée ou indisponible.';

  @override
  String get selectWallet => 'Sélectionnez un portefeuille';

  @override
  String get selectCategoryLowConfidence =>
      'Sélectionnez une catégorie — la confiance est trop faible pour l’appliquer automatiquement.';

  @override
  String get transactionSaved => 'Transaction enregistrée.';

  @override
  String addType(String type) {
    return 'Ajouter $type';
  }

  @override
  String get tryAdvancedAi => 'Essayer la classification IA avancée';

  @override
  String suggestedCategory(String label) {
    return 'Catégorie suggérée : $label';
  }

  @override
  String confidence(int percent) {
    return 'Confiance : $percent %';
  }

  @override
  String get lowConfidenceHint =>
      'La confiance est inférieure à 70 %. Choisissez vous-même la catégorie avant d’enregistrer.';

  @override
  String get transferTitle => 'Transférer de l’argent';

  @override
  String get fromWallet => 'Depuis';

  @override
  String get toWallet => 'Vers';

  @override
  String availableBalance(String amount, String currency) {
    return 'Disponible $amount · $currency';
  }

  @override
  String get confirmTransfer => 'Confirmer le transfert';

  @override
  String confirmTransferBody(String amount) {
    return 'Transférer $amount entre les portefeuilles sélectionnés ?';
  }

  @override
  String get transferCompleted => 'Transfert effectué.';

  @override
  String get sameWallet => 'Choisissez deux portefeuilles différents.';

  @override
  String get scanReceipt => 'Scanner un reçu';

  @override
  String get scanIntro =>
      'Photographiez ou importez un reçu, prévisualisez-le, puis extraire le texte. Rien n’est enregistré tant que vous n’avez pas confirmé.';

  @override
  String get noImageYet => 'Aucune image';

  @override
  String get camera => 'Caméra';

  @override
  String get gallery => 'Galerie';

  @override
  String get scanOcr => 'Scanner le texte (OCR)';

  @override
  String get ocrProgress => 'Lecture du reçu…';

  @override
  String get ocrWebHint =>
      'L’OCR Google ML Kit fonctionne sur Android et iOS. Utilisez un véritable appareil pour scanner.';

  @override
  String get permissionDeniedMedia =>
      'L’autorisation caméra ou galerie a été refusée. Vous pouvez toujours saisir une transaction manuellement.';

  @override
  String get confirmReceipt => 'Confirmer le reçu';

  @override
  String get paymentMethod => 'Moyen de paiement';

  @override
  String get date => 'Date';

  @override
  String get ocrText => 'Texte OCR';

  @override
  String get confirmAndSave => 'Confirmer et enregistrer';

  @override
  String get receiptNumber => 'Numéro de reçu';

  @override
  String get receiptSaved => 'Reçu et dépense enregistrés après confirmation.';

  @override
  String get customCategory => 'Catégorie personnalisée';

  @override
  String get parent => 'Parent';

  @override
  String get topLevel => 'Niveau supérieur';

  @override
  String get global => 'Globale';

  @override
  String get custom => 'Personnalisée';

  @override
  String get recurringTitle => 'Récurrences';

  @override
  String get newRecurrence => 'Nouvelle récurrence';

  @override
  String get editRecurrence => 'Modifier la récurrence';

  @override
  String get frequency => 'Fréquence';

  @override
  String get daily => 'Quotidienne';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get monthly => 'Mensuelle';

  @override
  String get yearly => 'Annuelle';

  @override
  String nextRun(String date) {
    return 'Prochaine exécution : $date';
  }

  @override
  String get executions => 'Exécutions';

  @override
  String get noExecutions =>
      'Aucune exécution pour le moment. Le job horaire l’écrira le moment venu.';

  @override
  String get transaction => 'Transaction';

  @override
  String get noDescription => 'Aucune description';

  @override
  String walletLabel(String name) {
    return 'Portefeuille : $name';
  }

  @override
  String categoryLabel(String name) {
    return 'Catégorie : $name';
  }

  @override
  String statusLabel(String status) {
    return 'Statut : $status';
  }

  @override
  String get voidAction => 'Annuler l’écriture';

  @override
  String get voidHint => 'Un mouvement comptable inverse sera créé.';

  @override
  String get amountRequired => 'Montant requis';

  @override
  String get amountInvalid => 'Format de montant invalide';

  @override
  String get amountPositive => 'Le montant doit être positif';

  @override
  String get amountTooHigh => 'Montant trop élevé';

  @override
  String maxDecimals(int scale) {
    return 'Maximum $scale décimales';
  }

  @override
  String get catFood => 'Alimentation';

  @override
  String get catRestaurants => 'Restaurants';

  @override
  String get catGroceries => 'Courses';

  @override
  String get catCoffee => 'Café';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catClothes => 'Vêtements';

  @override
  String get catElectronics => 'Électronique';

  @override
  String get catSupermarket => 'Supermarché';

  @override
  String get catTransport => 'Transport';

  @override
  String get catTaxi => 'Taxi';

  @override
  String get catFuel => 'Carburant';

  @override
  String get catPublicTransport => 'Transport public';

  @override
  String get catHousing => 'Logement';

  @override
  String get catRent => 'Loyer';

  @override
  String get catElectricity => 'Électricité';

  @override
  String get catWater => 'Eau';

  @override
  String get catInternet => 'Internet';

  @override
  String get catHealth => 'Santé';

  @override
  String get catPharmacy => 'Pharmacie';

  @override
  String get catDoctor => 'Médecin';

  @override
  String get catEntertainment => 'Divertissement';

  @override
  String get catCinema => 'Cinéma';

  @override
  String get catGames => 'Jeux';

  @override
  String get catGaming => 'Gaming';

  @override
  String get catSubscriptions => 'Abonnements';

  @override
  String get catIncome => 'Revenus';

  @override
  String get catSalary => 'Salaire';

  @override
  String get catFreelance => 'Freelance';

  @override
  String get catGift => 'Cadeau';

  @override
  String get catSavings => 'Épargne';

  @override
  String get catInvestments => 'Investissements';

  @override
  String get insufficientFunds => 'Solde insuffisant.';

  @override
  String get creditLimitExceeded => 'Plafond de crédit dépassé.';

  @override
  String get currencyMismatch =>
      'Les portefeuilles doivent avoir la même devise. Aucune conversion automatique.';

  @override
  String get invalidAmount => 'Montant invalide.';

  @override
  String get walletNotFound => 'Portefeuille introuvable ou non autorisé.';

  @override
  String get networkUnavailable => 'Réseau indisponible. Réessayez.';

  @override
  String initial(String amount) {
    return 'Initial $amount';
  }

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get greetingSubtitle => 'Votre argent, organisé avec élégance.';

  @override
  String get hideBalance => 'Masquer les soldes';

  @override
  String get showBalance => 'Afficher les soldes';

  @override
  String get appearance => 'Apparence';

  @override
  String get financialPreferences => 'Préférences financières';

  @override
  String get about => 'À propos';

  @override
  String get aboutBody =>
      'Wallet & Transactions 1.0.0 — espace financier privé de votre compte.';

  @override
  String get transferSuccess => 'Transfert confirmé';

  @override
  String get scanFrameHint => 'Alignez le reçu dans le cadre';

  @override
  String get classificationRules => 'Suggestion par règles';

  @override
  String get classificationRemote => 'Suggestion IA distante';

  @override
  String get classificationMemory => 'Issue de votre correction précédente';

  @override
  String get acceptSuggestion => 'Utiliser la suggestion';

  @override
  String get monthTrendFlat =>
      'Les dépenses sont stables par rapport au mois dernier';

  @override
  String monthTrendUp(String percent) {
    return 'Les dépenses sont $percent % au-dessus du mois dernier';
  }

  @override
  String monthTrendDown(String percent) {
    return 'Les dépenses sont $percent % en dessous du mois dernier';
  }

  @override
  String get ocrUnreadableImage =>
      'Cette image n’a pas pu être lue. Choisissez une autre photo ou reprenez le reçu.';

  @override
  String get ocrNoText =>
      'Aucun texte n’a été trouvé. Essayez une photo plus nette.';

  @override
  String get ocrEngineFailed =>
      'La reconnaissance de texte a échoué. Réessayez ou choisissez une autre image.';

  @override
  String get ocrRetryHint =>
      'Relancez le scan ou sélectionnez une autre image. Rien n’a été enregistré.';

  @override
  String get ocrArabicLocalUnsupported =>
      'Les reçus en arabe ne sont pas reconnus par le scanner de l’appareil. Utilisez un reçu français ou anglais, ou saisissez le montant.';

  @override
  String get amountNeedsReview =>
      'Aucun total fiable n’a été trouvé. Saisissez le montant à payer avant d’enregistrer. Le sous-total, la TVA, la remise et la monnaie ne sont pas utilisés automatiquement.';

  @override
  String get receiptUploadRetry =>
      'La dépense est enregistrée. L’envoi du reçu n’est pas terminé. Une nouvelle tentative ne créera pas une autre transaction.';

  @override
  String get receiptSaveFailed =>
      'La dépense n’a pas été enregistrée. Vérifiez la connexion et réessayez.';

  @override
  String get receiptPendingBody =>
      'Une confirmation de reçu est encore inachevée pour ce compte.';

  @override
  String get receiptAttachAgain => 'Joindre le reçu';

  @override
  String get receiptDismissReminder => 'Ignorer le rappel';

  @override
  String get notSignedIn => 'Connectez-vous pour continuer.';

  @override
  String get confidenceNotMeasured =>
      'Le modèle n’a pas fourni de score de confiance. Confirmez la catégorie vous-même.';

  @override
  String get welcomeHeadline => 'Gérez vos\nfinances,\nsereinement.';

  @override
  String get welcomeSubtitle =>
      'Wallet & Transactions — votre espace financier privé.';

  @override
  String get welcomeSecure => 'Sécurisé avec Supabase Auth';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'Créer un compte';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get signInSubtitle => 'Connectez-vous à votre compte';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get newHere => 'Nouveau ?';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordTooShort => 'Au moins 8 caractères';

  @override
  String get emailRequired => 'E-mail requis';

  @override
  String get emailInvalid => 'E-mail invalide';

  @override
  String get createMyAccount => 'Créer mon compte';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ?';

  @override
  String get passwordWeak => 'Faible';

  @override
  String get passwordFair => 'Moyen';

  @override
  String get passwordGood => 'Bon';

  @override
  String get passwordExcellent => 'Excellent';

  @override
  String passwordStrength(String label) {
    return 'Force : $label';
  }

  @override
  String get checkEmail => 'Vérifiez votre e-mail';

  @override
  String checkEmailBody(String email) {
    return 'Un lien de confirmation a été envoyé à $email. Ouvrez-le pour activer votre compte.';
  }

  @override
  String get goToSignIn => 'Aller à la connexion';

  @override
  String get forgotPasswordSubtitle =>
      'Entrez votre e-mail pour recevoir un lien de réinitialisation';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get resetEmailSent => 'E-mail envoyé';

  @override
  String resetEmailBody(String email) {
    return 'Consultez $email et ouvrez le lien pour réinitialiser votre mot de passe.';
  }

  @override
  String get backToSignIn => 'Retour à la connexion';

  @override
  String get signOutTitle => 'Se déconnecter ?';

  @override
  String get signOutBody => 'Vous serez redirigé vers l’écran de connexion.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get preferenceNotSaved => 'La préférence n’a pas été enregistrée.';

  @override
  String get administration => 'Administration';

  @override
  String get userManagement => 'Gestion des utilisateurs';

  @override
  String get userManagementHint => 'Comptes, inscriptions et activité';

  @override
  String get help => 'Aide';

  @override
  String get contactSupport => 'Contacter l’assistance';

  @override
  String get contactSupportHint =>
      'Question ou demande de suppression du compte';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get myProfileHint => 'Modifier vos informations personnelles';

  @override
  String get security => 'Sécurité';

  @override
  String get securityHint => 'MFA, biométrie et historique de connexion';

  @override
  String get loginHistory => 'Historique de connexion';

  @override
  String get loginHistoryHint => 'Consulter les activités récentes';

  @override
  String get createAnotherAccount => 'Créer un nouveau compte';

  @override
  String get createAnotherAccountHint => 'Inscription d’un nouvel utilisateur';

  @override
  String get signOutHint => 'Fermer la session en cours';

  @override
  String get guest => 'Invité';

  @override
  String get emailVerified => 'E-mail vérifié';

  @override
  String get emailUnverified => 'Non vérifié';

  @override
  String get startupError => 'Erreur de démarrage';

  @override
  String get walletLoadFailed => 'Impossible de charger ce portefeuille.';

  @override
  String get walletSaveFailed =>
      'Le portefeuille n’a pas été enregistré. Vérifiez la connexion et réessayez.';

  @override
  String get twoFactor => 'Authentification à deux facteurs';

  @override
  String get biometrics => 'Biométrie';

  @override
  String get biometricSubtitle =>
      'Protégez l’accès avec votre empreinte ou votre visage';

  @override
  String get devices => 'Appareils';

  @override
  String get support => 'Assistance';

  @override
  String get supportIntro =>
      'Envoyez une demande. Elle est liée à votre compte pour que l’équipe puisse répondre.';

  @override
  String get requestType => 'Type de demande';

  @override
  String get requestQuestion => 'Question ou assistance';

  @override
  String get requestDeletion => 'Demande de suppression du compte';

  @override
  String get sendRequest => 'Envoyer la demande';

  @override
  String get supportLoadFailed => 'Impossible de charger vos demandes.';

  @override
  String get noSupportRequests => 'Aucune demande envoyée.';

  @override
  String get supportSendFailed => 'La demande n’a pas été envoyée.';

  @override
  String get disableTwoFactorTitle => 'Désactiver le 2FA ?';

  @override
  String get disable => 'Désactiver';

  @override
  String get addAnotherFactor => 'Ajouter un autre facteur';

  @override
  String get cancelTwoFactorSetup => 'Annuler et supprimer cette configuration';

  @override
  String get done => 'Terminé';

  @override
  String get signOutThisDevice => 'Se déconnecter de cet appareil';

  @override
  String get signOutOtherSessions => 'Déconnecter les autres sessions';

  @override
  String get signOutThisDeviceTitle => 'Se déconnecter de cet appareil ?';

  @override
  String get signOutOtherSessionsTitle => 'Déconnecter les autres sessions ?';

  @override
  String get revoke => 'Révoquer';

  @override
  String get signOutWalletTitle => 'Se déconnecter de Wallet ?';

  @override
  String get signOutWalletBody =>
      'La session Supabase sera fermée et le verrou biométrique local supprimé sur cet appareil. Vous devrez vous reconnecter.';

  @override
  String get localLockFailed => 'Impossible de vérifier le verrouillage local.';

  @override
  String get signInToSeeHistory => 'Connectez-vous pour voir l’historique.';

  @override
  String get adminOverview => 'Vue d’ensemble';

  @override
  String get adminAccounts => 'Comptes';

  @override
  String get adminSupport => 'Assistance';

  @override
  String get adminAudit => 'Journal';

  @override
  String get refresh => 'Actualiser';

  @override
  String get currentSession => 'Session courante';

  @override
  String get subject => 'Sujet';

  @override
  String get yourMessage => 'Votre message';

  @override
  String get myRequests => 'Mes demandes';

  @override
  String get planTitle => 'Plan';

  @override
  String get planSubtitle => 'Budgets, objectifs, investissements et assistant';

  @override
  String get planBudget => 'Budget et dépenses';

  @override
  String get planGoals => 'Objectifs';

  @override
  String get planInvest => 'Investissements';

  @override
  String get planAssistant => 'SmartWallet AI';

  @override
  String get planManage => 'Gérer mes finances';

  @override
  String get planIntelligence => 'Intelligence financière';

  @override
  String get planRowBody => 'Budgets, objectifs et investissements';

  @override
  String get aiAsk => 'Pose une question sur tes finances';

  @override
  String get planBudgetBody => 'Plafonds et dépenses du mois';

  @override
  String get planGoalsBody => 'Avancement de ce que vous préparez';

  @override
  String get planInvestBody => 'Portefeuilles et simulations éducatives';

  @override
  String get planInsightsBody => 'Prévisions, alertes et les 30 analyses';

  @override
  String get planWhatIfBody => 'Essayer un scénario d\'épargne';

  @override
  String get planAssistantBody =>
      'Réponses calculées depuis vos enregistrements';

  @override
  String get chartEmptyMonth =>
      'Pas encore de dépenses enregistrées ce mois-ci.';

  @override
  String get homeAttention => 'À suivre';

  @override
  String get openDetailedAnalyses => 'Ouvrir les 30 analyses';

  @override
  String get budgetDashboard => 'Tableau de budget';

  @override
  String get newBudget => 'Nouveau budget';

  @override
  String get budgetName => 'Nom du budget';

  @override
  String get budgetLimit => 'Plafond';

  @override
  String get periodMonthly => 'Mensuel';

  @override
  String get periodWeekly => 'Hebdomadaire';

  @override
  String get overallBudget => 'Budgets globaux';

  @override
  String get categoryBudget => 'Budgets par catégorie';

  @override
  String get spentLabel => 'Dépensé';

  @override
  String get remainingLabel => 'Reste';

  @override
  String get previousPeriod => 'Période précédente';

  @override
  String get forecastLabel => 'Prévision';

  @override
  String get forecastInsufficient =>
      'Historique insuffisant pour une prévision.';

  @override
  String get whatIf => 'Simulation';

  @override
  String get monthlyReduction => 'Réduction mensuelle';

  @override
  String get monthsLabel => 'Mois';

  @override
  String get potentialSavings => 'Épargne potentielle';

  @override
  String get deleteBudget => 'Supprimer le budget';

  @override
  String alertReached(int percent) {
    return 'Alerte à $percent %';
  }

  @override
  String get goalsTitle => 'Objectifs';

  @override
  String get newGoal => 'Nouvel objectif';

  @override
  String get goalTarget => 'Montant cible';

  @override
  String get savedLabel => 'Épargné';

  @override
  String get contribute => 'Ajouter un versement';

  @override
  String get virtualHint =>
      'Ceci suit l’objectif uniquement. Aucun portefeuille n’est débité.';

  @override
  String get requiredMonthly => 'Versement mensuel requis';

  @override
  String get completeGoal => 'Marquer comme atteint';

  @override
  String get priorityLabel => 'Priorité';

  @override
  String get portfolioTitle => 'Portefeuilles d’investissement';

  @override
  String get newPortfolio => 'Nouveau portefeuille';

  @override
  String get newAsset => 'Nouvel actif';

  @override
  String get symbol => 'Symbole';

  @override
  String get quantity => 'Quantité';

  @override
  String get unitPrice => 'Prix unitaire';

  @override
  String get currentPrice => 'Prix actuel';

  @override
  String get manualPrice => 'Prix manuel';

  @override
  String get unrealized => 'Gain/perte latent';

  @override
  String get realized => 'Gain/perte réalisé';

  @override
  String get allocation => 'Répartition';

  @override
  String get notAdvice =>
      'Ces chiffres viennent de vos saisies. Ils ne sont pas un conseil d’achat ou de vente.';

  @override
  String get concentration => 'Une ligne dépasse 40 % de cette devise.';

  @override
  String get assistantTitle => 'SmartWallet AI';

  @override
  String get assistantHint =>
      'Les réponses utilisent vos transactions enregistrées. Un historique manquant est indiqué, pas inventé.';

  @override
  String get ask => 'Demander';

  @override
  String get confirmDraft => 'Vérifier la transaction';

  @override
  String get draftTitle => 'Confirmer avant d’enregistrer';

  @override
  String get chooseWallet => 'Portefeuille';

  @override
  String get aiLocalOnly =>
      'L’assistant distant n’est pas configuré. Cette réponse a été calculée sur l’appareil.';

  @override
  String get recurringSection => 'Dépenses récurrentes à venir';

  @override
  String get noPlanData => 'Rien pour le moment.';

  @override
  String get allCategories => 'Toutes les catégories';

  @override
  String get buy => 'Achat';

  @override
  String get sell => 'Vente';

  @override
  String get priceMissing => 'Prix non renseigné';

  @override
  String get archive => 'Archiver';

  @override
  String get aiSuggestMonth => 'Combien ai-je dépensé ce mois-ci ?';

  @override
  String get aiSuggestCategory => 'Quelle est ma plus grosse catégorie ?';

  @override
  String get aiSuggestWeek => 'Pourquoi mes dépenses augmentent ?';

  @override
  String get aiSuggestDraft => 'J\'ai payé 45 dinars au restaurant hier.';

  @override
  String get aiSuggestSave => 'Comment économiser 300 TND ?';

  @override
  String get aiSuggestBalance => 'Combien reste dans mon compte ?';

  @override
  String get aiSimulation => 'Simulation, pas une opération enregistrée.';

  @override
  String get assetStocks => 'Actions';

  @override
  String get assetEtf => 'ETF';

  @override
  String get assetCrypto => 'Crypto';

  @override
  String get assetOther => 'Autre';

  @override
  String get authCallbackWaiting => 'Ouverture de votre session SmartWallet…';

  @override
  String get setNewPassword => 'Choisir un nouveau mot de passe';

  @override
  String get planInsights => 'Analyses et prévisions';

  @override
  String get insightsTitle => 'Analyses financières';

  @override
  String get mlBaselineNote =>
      'Les chiffres viennent de vos transactions et d’une base statistique. Aucun modèle de production n’a été entraîné sur ce compte.';

  @override
  String get next7Days => '7 prochains jours';

  @override
  String get next30Days => '30 prochains jours';

  @override
  String get endOfMonth => 'Fin du mois';

  @override
  String get overspendTitle => 'Risque de dépassement';

  @override
  String get daysLeft => 'Jours restants';

  @override
  String get dailyLimit => 'Plafond quotidien suggéré';

  @override
  String get subscriptionsTitle => 'Abonnements';

  @override
  String get priceUp => 'Hausse de prix';

  @override
  String get inactiveSub => 'Inactif';

  @override
  String get duplicateSub => 'Doublon possible';

  @override
  String get anomaliesTitle => 'Alertes';

  @override
  String get anomalyDoesNotBlock =>
      'Une alerte explique un écart. Elle ne bloque jamais un paiement à elle seule.';

  @override
  String get allocationTitle => 'Répartition suggérée';

  @override
  String get surplusLabel => 'Excédent mensuel';

  @override
  String get behaviorTitle => 'Comportement de dépense';

  @override
  String get weekendShare => 'Part du week-end';

  @override
  String get monthChange => 'Écart avec le mois précédent';

  @override
  String get reportsTitle => 'Ce mois-ci';

  @override
  String get netLabel => 'Solde';

  @override
  String get goalsPlanTitle => 'Faisabilité des objectifs';

  @override
  String get riskTitle => 'Risque du portefeuille';

  @override
  String get balanceChecks => 'Contrôles de solde';

  @override
  String get consistent => 'Cohérent';

  @override
  String get inconsistent => 'Incohérent';

  @override
  String get unusualMovement =>
      'Mouvement élevé par rapport à vos paiements habituels';

  @override
  String get splitExpense => 'Ventiler une dépense';

  @override
  String get splitHint =>
      'Les deux parts doivent égaler le total. Chaque part est enregistrée avec une requête idempotente.';

  @override
  String get splitPart => 'Part';

  @override
  String get splitReady => 'Les parts correspondent au total.';

  @override
  String get splitRemainder => 'Écart';

  @override
  String get plannerTitle => 'Plan d’épargne';

  @override
  String get recommendedSave => 'Épargne mensuelle recommandée';

  @override
  String get voiceUnavailable =>
      'La voix n’est pas disponible sur cet appareil.';

  @override
  String get arabicOcrLimited =>
      'Du texte arabe a été détecté. ML Kit sur l’appareil lit l’écriture latine : vérifiez les champs.';

  @override
  String get taxLabel => 'Taxe';

  @override
  String get receiptItems => 'Articles';

  @override
  String get studioTitle => 'Atelier financier';

  @override
  String get studioBaseline =>
      'Les trente cartes ci-dessous sont calculées sur cet appareil à partir de vos enregistrements. Les lignes au-dessus sont la réponse du service déployé. Les modèles expérimentaux ne sont pas validés en conditions réelles, et les simulations ne sont pas des garanties.';

  @override
  String get documentKindLabel => 'Document';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountBody =>
      'Cette action supprime définitivement ce compte et ses enregistrements. Saisissez le mot de confirmation pour continuer.';

  @override
  String get deleteAccountConfirmWord => 'SUPPRIMER';

  @override
  String get deleteAccountUnavailable =>
      'La suppression du compte n’est pas activée sur le serveur. Aucune donnée n’a été effacée.';
}
