# Notifications Firebase de solde faible

La notification est envoyée lorsqu'un mouvement fait passer le **solde total des portefeuilles actifs d'une même devise sous 100**. Les devises ne sont jamais additionnées entre elles. Une alerte est envoyée une seule fois pendant que le total reste sous le seuil ; un retour à 100 ou plus réarme l'alerte.

Les notifications sont des notifications push FCM, pas des SMS. Elles peuvent arriver application en arrière-plan ou arrêtée si le téléphone a déjà ouvert Wallet, si l'utilisateur a autorisé les notifications et si le téléphone a accès à Internet. Les arrêts forcés par l'utilisateur peuvent suspendre leur réception jusqu'à la prochaine ouverture. Au premier plan, l'application les affiche avec `flutter_local_notifications`.

## Configuration requise

### 1. Firebase

Dans Firebase Console, crée un projet (ou utilise un projet existant) et ajoute les applications mobiles avec les identifiants de ce dépôt :

- Android : `com.example.wallet_app`
- iOS : `com.example.walletApp`

Active Firebase Cloud Messaging et récupère les valeurs publiques de configuration Android/iOS. Ajoute-les dans le fichier local `.env` sous `FIREBASE_ANDROID_API_KEY`, `FIREBASE_IOS_API_KEY`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_ANDROID_APP_ID` et `FIREBASE_IOS_APP_ID`. Le fichier `.env` est ignoré par Git. Ne mets jamais de clé de compte de service dans ce fichier.

Pour iOS, active les capacités **Push Notifications** et **Background Modes > Remote notifications** dans Xcode, puis ajoute la clé APNs dans Firebase Console. Les notifications web ne sont pas activées dans cette implémentation.

### 2. Migration Supabase

Applique `supabase/migrations/20261024120000_low_balance_push_notifications.sql` une seule fois dans le SQL Editor du projet Supabase utilisé par Wallet. Elle crée `push_tokens` avec RLS par utilisateur et une table d'état interne, ainsi qu'une fonction RPC inaccessible aux rôles `anon` et `authenticated`.

### 3. Edge Function et secrets

Déploie `supabase/functions/wallet-low-balance-push` avec la vérification JWT désactivée (la fonction vérifie à la place l'en-tête secret des Webhooks). Configure côté Supabase Functions les secrets suivants :

- `WALLET_PUSH_WEBHOOK_SECRET` : secret aléatoire long créé pour ce webhook.
- `FCM_SERVICE_ACCOUNT_JSON` : contenu JSON du compte de service Firebase.

Le compte de service doit avoir le rôle **Firebase Cloud Messaging API Admin** sur le projet Firebase. Le secret reste côté serveur ; aucun secret Firebase ni `service_role` ne doit être intégré dans l'application. Supabase fournit déjà à ses Edge Functions `SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY`.

### 4. Database Webhooks

Dans **Database > Webhooks**, crée les webhooks suivants. Pour chacun, l'URL est `https://<project-ref>.supabase.co/functions/v1/wallet-low-balance-push` et l'en-tête personnalisé est `x-wallet-webhook-secret: <même-secret-que-WALLET_PUSH_WEBHOOK_SECRET>`.

1. `wallets` : événements `INSERT` et `UPDATE`.
2. `wallet_movements` : événements `INSERT`, `UPDATE` et `DELETE`.
3. `push_tokens` : événements `INSERT` et `UPDATE` (permet de notifier lors de l'inscription d'un appareil si le solde est déjà sous le seuil).

Les webhooks sont exécutés après les modifications de lignes et appellent l'Edge Function de façon asynchrone. La fonction relit les soldes dans `wallet_balances`, regroupe uniquement les portefeuilles actifs par devise, puis envoie à chaque appareil FCM enregistré de cet utilisateur.

## Vérification

1. Installe et ouvre l'application sur un téléphone Android ou iPhone, connecte-toi et accepte les notifications.
2. Vérifie dans Supabase que `push_tokens` contient une ligne de l'utilisateur courant. Une permission refusée ou une configuration Firebase absente empêche cet enregistrement.
3. Avec un portefeuille en TND dont le total est supérieur ou égal à 100, enregistre une dépense qui fait passer son total TND sous 100.
4. Vérifie les logs de l'Edge Function et le téléphone, application ouverte puis en arrière-plan.
5. Remonte le total à 100 ou plus, puis repasse sous 100 pour vérifier que l'alerte est réarmée.

Le texte de notification ne révèle pas le montant exact sur l'écran verrouillé. Le mécanisme ne produit aucun SMS et n'invente ni localisation ni activité.
