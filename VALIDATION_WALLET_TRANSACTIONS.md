# Validation Wallet & Transactions

Date : 12 octobre 2026  
Compte démo : `demo@wallet.app` / UUID `7d2f1a6e-9c4b-4e8a-b3d1-2f6a8c0e5b91`  
RLS : **jamais désactivé**. Aucune donnée existante supprimée. Les essais SQL de création/mouvements ont été exécutés dans une transaction **BEGIN … ROLLBACK**.

## Commandes techniques

| Commande | Résultat |
| --- | --- |
| `flutter pub get` | OK |
| `flutter analyze` | OK — aucun problème |
| `flutter test --reporter expanded` | OK — 36 tests |
| `flutter build apk --release` | OK — `build/app/outputs/flutter-apk/app-release.apk` (86.9 MB) |

Aucun téléphone Android n’était connecté à cette session. Tout ce qui exige caméra, galerie, ML Kit matériel, permission OS ou saisie dans l’UI est **NON TESTÉ** sur device.

---

## 1. Wallets

| Fonctionnalité | Résultat | Méthode | Problèmes | Corrections |
| --- | --- | --- | --- | --- |
| Types Cash / Bank Account / Credit Card / Crypto / Savings (contrainte SQL) | **OK** | PostgreSQL `wallets_wallet_type_check` | — | — |
| Création des 5 types + solde `wallet_balances` | **OK** | RPC `app_private.create_transaction` / INSERT wallets dans txn rollback : Cash 100→120→110, Savings 300→310 | — | — |
| Modification nom/couleur (hors type et devise) | **OK** | `UPDATE wallets SET name, color` dans la même txn | Le type et la devise sont volontairement non modifiables dans le formulaire | — |
| Historique d’un wallet | **OK** (SQL) / **NON TESTÉ** (UI) | Transactions liées dans la txn ; écran `WalletDetailsScreen` lu dans le code | Pas de parcours UI | — |
| Archivage bloque les écritures | **OK** | Wallet crypto archivé puis `create_transaction` → `Wallet introuvable` | — | — |
| Affichage liste / totaux par devise dans l’app | **NON TESTÉ** | Nécessite l’app sur téléphone. Le compte démo n’a **qu’un** wallet réel (`qa`, CASH, EUR, solde 12.000) | UI non exercée | — |
| Création via `AddWalletScreen` sur Android | **NON TESTÉ** | Téléphone réel | — | — |

## 2. Transactions

| Fonctionnalité | Résultat | Méthode | Problèmes | Corrections |
| --- | --- | --- | --- | --- |
| Dépense (EXPENSE) et solde | **OK** | SQL : Cash 120 → 110 après 10 TND | — | — |
| Revenu (INCOME) et solde | **OK** | SQL : Cash 100 → 120 après 20 TND | — | — |
| Paiement (PAYMENT) + remboursement (REFUND) | **OK** | SQL : −5 puis +5, solde inchangé à 110 | — | — |
| Transfert atomique + soldes | **OK** | SQL `transfer_money` : Cash 110→100, Savings 300→310 ; 2 `wallet_movements` | — | — |
| Idempotence `client_request_id` | **OK** | Deux `create_transaction` même UUID → même id | — | — |
| Géolocalisation persistée (lat/lng SQL) | **OK** | Dépense de test avec 36.8 / 10.1 dans la txn rollback | Permission GPS Android **NON TESTÉE** | `deniedForever` géré dans `LocationService` |
| Catégories PostgreSQL (32 globales) | **OK** | `SELECT count(*) FROM categories WHERE user_id IS NULL` | — | — |
| Tags / `transaction_tags` | **NON TESTÉ** | 0 tags sur le compte démo ; pas d’essai SQL de tags dans cette session | — | — |
| Recherche / filtres / pagination UI | **NON TESTÉ** | Code `TransactionsScreen` + vue `activity_feed` inspectés | 0 transactions réelles sur le démo | — |
| Récurrentes (CRUD UI) | **NON TESTÉ** | 0 lignes `recurring_transactions` | Job cron présent (voir §5) | — |
| Ajout dépense/revenu/paiement/remboursement via Flutter | **NON TESTÉ** | Téléphone + session démo | — | — |

## 3. Scan de reçus

| Fonctionnalité | Résultat | Méthode | Problèmes | Corrections |
| --- | --- | --- | --- | --- |
| Parser OCR (commerçant, date, montant, devise, CARD) | **OK** | Tests `ocr_classification_test` sur le reçu exemple | — | — |
| Reçu sans montant | **OK** | Test : total `null`, commerçant conservé | — | — |
| Image illisible / texte vide | **OK** | Test parser + code OCR qui refuse un texte vide | ML Kit sur device **NON TESTÉ** | — |
| Aucun enregistrement avant confirmation | **OK** (code) | `ScanReceiptScreen` n’appelle pas `create_transaction` ; seul `ConfirmReceiptScreen` le fait | Pas d’essai instrumenté UI | Garde anti double-clic ajoutée sur Confirm |
| Caméra / galerie / prévisualisation / ML Kit | **NON TESTÉ** | Matériel Android requis | — | Message si permission caméra/galerie refusée |
| Upload Storage privé + ligne `receipts` | **NON TESTÉ** | 0 reçus en base ; bucket `receipts` `public=false`, 5 Mo, policies SELECT/INSERT/UPDATE/DELETE dossier `{auth.uid()}` | — | — |

## 4. Classification automatique

| Fonctionnalité | Résultat | Méthode | Problèmes | Corrections |
| --- | --- | --- | --- | --- |
| Carrefour → Shopping / Groceries, 95 % | **OK** | Test unitaire local | — | — |
| Restaurant → Food / Restaurants | **OK** | Test unitaire | — | — |
| Shell → Transport / Fuel | **OK** | Test unitaire | — | — |
| Netflix → Entertainment / Subscriptions | **OK** | Test unitaire | — | — |
| Pharmacy → Health / Pharmacy | **OK** | Test unitaire | — | — |
| Catégorie non reconnue (pas d’invention) | **OK** | Tests `zzzz` / `UnknownShop` | — | — |
| Corrections utilisateur (99 %, même commerçant) | **OK** | Test `classification_corrections` simulé | Pas de ligne réelle en base (0 `ai_classifications`) | — |
| Edge Function `classify-transaction` déployée + JWT | **OK** | POST authentifié démo → HTTP 200 | — | — |
| Classification IA distante opérationnelle | **ÉCHEC** (attendu) | Corps : `available: false`, `OPENAI_API_KEY` absent | L’IA distante **n’est pas opérationnelle**. Les règles locales restent valides. | Ne pas afficher de catégorie inventée — comportement conforme |

## 5. PostgreSQL / Supabase

| Fonctionnalité | Résultat | Méthode | Problèmes | Corrections |
| --- | --- | --- | --- | --- |
| Tables / vues nécessaires | **OK** | `profiles`, `wallets`, `wallet_balances`, `wallet_movements`, `transactions`, `transfers`, `activity_feed`, `categories`, `tags`, `transaction_tags`, `receipts`, `ai_classifications`, `classification_corrections`, `recurring_transactions`, `recurring_executions` | — | — |
| RPC `create_transaction`, `transfer_money`, `void_transaction` | **OK** | `pg_proc` public + `app_private`, `SECURITY DEFINER` | `void_transaction` non exercé (0 tx à voider sans muter les données) | — |
| RLS sur toutes les tables métier | **OK** | `relrowsecurity = true` | — | — |
| `authenticated` ne peut pas INSERT `wallet_movements` | **OK** | Grants : SELECT seulement | — | — |
| Vues `security_invoker` | **OK** | `wallet_balances`, `activity_feed` | — | — |
| Contraintes montants / types / transfert ≠ même wallet | **OK** | `pg_constraint` | — | — |
| Doublons récurrence | **OK** (schéma) | `UNIQUE (recurring_id, executed_on)` | Pas d’exécution réelle | — |
| Cron horaire | **OK** | `process-due-recurring-hourly` `20 * * * *` | Jamais observé en live dans cette session | — |
| Compte démo Auth | **OK** | `auth.users` + login password grant + UUID Flutter identique | Un seul wallet EUR, zéro transaction réelle | — |
| Storage privé `receipts` | **OK** (config) | Bucket non public + 4 policies | Upload réel **NON TESTÉ** | — |

## 6. Cas d’erreur

| Cas | Résultat | Méthode | Problèmes | Corrections |
| --- | --- | --- | --- | --- |
| Montant négatif | **OK** | `Money.validate` + RPC `assert_amount` dans txn | — | — |
| Montant nul | **OK** | Idem | — | — |
| Solde insuffisant | **OK** | RPC dépense 9999 TND → `Solde insuffisant` | — | — |
| Wallet inexistant | **OK** | UUID aléatoire → exception Wallet | — | — |
| Transfert vers le même wallet | **OK** | SQL `Wallets invalides` + garde Flutter | UI ne le bloquait que via le repo | SnackBar + return avant RPC |
| Perte Internet | **OK** (mapping) | `AppException.from(SocketException)` | Pas de coupure réseau réelle | — |
| Double clic validation | **OK** (code) | `_submitted` add tx / transfer / confirm receipt | Pas de test widget d’un double tap | Garde ajoutée sur confirm reçu |
| Photo illisible | **OK** (parser) / **NON TESTÉ** (ML Kit) | Texte vide | — | — |
| Reçu sans montant | **OK** (parser) / **NON TESTÉ** (UI confirm) | total null | Confirm exige encore un montant valide pour sauver | — |
| Catégorie non reconnue | **OK** | Classifier `null` | — | — |
| Permission caméra refusée | **NON TESTÉ** | Device | — | Message dédié dans le catch `image_picker` |
| Permission localisation refusée | **NON TESTÉ** | Device | — | `denied` / `deniedForever` → pas d’enregistrement de position |

## 7. Corrections effectuées pendant cette validation

1. Transfert : refus explicite si wallets source et destination identiques, avant l’appel RPC.  
2. Confirmation de reçu : drapeau `_submitted` contre le double envoi.  
3. Scan : message clair si la permission caméra/galerie est refusée.  
4. Localisation : `deniedForever` ne tente plus de lire la position.  
5. Tests `validation_error_cases_test.dart` (montants, OCR vide, catégorie inconnue, réseau).

## 8. Automatisé vs téléphone Android

**Automatisé (cette session)**  
Analyse, 36 tests, APK release, SQL/RPC (rollback), contraintes, RLS, cron, login démo, Edge Function JWT.

**Téléphone Android réel indispensable**  
Caméra, galerie, prévisualisation, ML Kit, permissions, GPS, parcours complet wallets/transactions/tags/recherche/pull-to-refresh, upload Storage, scan confirmé bout-en-bout.

## 9. Incomplet — actions pour terminer

1. **Installer l’APK** `build/app/outputs/flutter-apk/app-release.apk` sur un téléphone Android et exécuter le parcours manuel : 5 wallets TND, dépense/revenu/paiement/remboursement/transfert, tags, filtres, récurrente, scan caméra + galerie, GPS optionnel.  
2. **Configurer l’IA distante** seulement si voulue : secret Supabase `OPENAI_API_KEY` sur la fonction `classify-transaction`. Tant que ce secret est absent, la classification avancée reste **non opérationnelle** (déjà affiché clairement). Les règles locales suffisent pour les exemples demandés.  
3. **Alimenter le compte démo** : aujourd’hui 1 wallet EUR `qa`, 0 transactions, 0 reçus. Sans ça, le dashboard et l’historique restent vides en conditions réelles.  
4. **Observer une exécution récurrente** après insertion d’une récurrence due (job à minute 20).  
5. **Tester `void_transaction`** depuis les détails d’une vraie dépense.  
6. Recettes Storage : valider un upload `{demoUuid}/{file}.jpg` après un scan confirmé.

Tant que le point 1 n’est pas fait, la partie OCR/caméra et les écrans Flutter ne peuvent pas être déclarés **OK**.
