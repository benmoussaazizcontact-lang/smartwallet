# Données de démonstration — insertions réelles

Date : 7 novembre 2026. Projet `jjfqpfxhgositfaglrzr`. Compte `azizbenmoussa125@gmail.com`, UUID `c19ec2bd-0480-428a-9f10-13a4640d9293`.

RLS est resté activé sur `wallets` et sur les tables Budget, Objectifs et Investissement.

## 1. Sauvegarde vérifiée

Deux fichiers, ignorés par Git dans `.backups/` :

| Fichier | Taille | Contenu vérifié |
| --- | --- | --- |
| `.backups/schema_20261107.sql` | 50 198 octets | schéma public, dont `wallets`, `transactions`, `transfers`, `wallet_movements`, `categories`, `profiles` |
| `.backups/data_20261107.sql` | 45 464 octets | `COPY` de ces tables, plus l'UUID du compte et les portefeuilles `n` et `tt` |
| `.backups/pre_snapshot.json` | 1 531 octets | comptes avant modification : 4 utilisateurs, 6 portefeuilles, 9 transactions, 2 virements, 14 mouvements, 32 catégories |

La sauvegarde couvre le schéma public et ses données. Le dump CLI exclut le schéma `auth`. `pg_dump` signale une clé étrangère circulaire sur `categories` : une restauration data-only de cette table demande `--disable-triggers` ou le schéma complet.

## 2. Migrations

`supabase db push` n'a pas été lancé. Plusieurs fichiers locaux absents de l'historique distant contiennent `DROP POLICY`, `DROP VIEW` ou `DROP FUNCTION`. Le schéma financier est déjà en place sous d'autres versions distantes. Ces fichiers n'ont pas été rejoués.

Seule `20261106120000_smartwallet_modules.sql` a été appliquée. Elle crée les tables et les politiques RLS, sans `DROP`, `DELETE` ni `TRUNCATE`. La version est enregistrée comme appliquée. Contrôle après application : RLS actif, 2 à 4 politiques par table.

## 3. Insertions

Script `supabase/seeds/demo_azizbenmoussa125.sql`, exécuté deux fois. Le second passage n'a ajouté aucune ligne.

### Portefeuilles

Les soldes viennent de `wallet_balances` (solde initial + mouvements).

| Nom | Type | Solde affiché |
| --- | --- | --- |
| BIAT | BANK_ACCOUNT | 5 000 TND |
| Espèces | CASH | 800 TND |
| Épargne | SAVINGS | 3 000 TND |
| Carte bancaire | CREDIT_CARD | solde −131,700 ; dette 131,700 ; limite 2 000 ; disponible 1 868,300 |
| Crypto | CRYPTO | 500 TND, symbole BTC |

`n` et `tt` sont inchangés : mêmes soldes initiaux (8 800 et 258), même limite de la carte `n` (2 465), mêmes horodatages `updated_at`.

### Transactions et historique

31 transactions pour ce compte : 28 EXPENSE et 3 INCOME. 4 virements. L'historique `activity_feed` contient 39 lignes (31 transactions + les deux sens de chaque virement).

Catégories utilisées : Carrefour et Restaurant en Food, Monoprix en Shopping, Shell en Transport, STEG et Ooredoo en Housing, Netflix en Entertainment, Pharmacie en Health, salaire en Income.

Dépenses de novembre réellement additionnées :

| Catégorie | Dépensé |
| --- | --- |
| Food | 274 |
| Transport | 95 |
| Shopping | 135 |
| Housing | 107 |
| Entertainment | 29,900 |
| Health | 18 |

Total des dépenses de novembre : 658,900 TND.

### Budgets

| Nom | Plafond mensuel |
| --- | --- |
| Food | 400 |
| Transport | 200 |
| Shopping | 300 |
| Bills | 250, rattaché à la catégorie Housing |
| Monthly total | 1 500, sans catégorie |

### Objectifs

Contributions virtuelles, sans mouvement de portefeuille.

| Objectif | Type | Cible | Épargné |
| --- | --- | --- | --- |
| Acheter un ordinateur | laptop | 3 500 | 2 100 |
| Voyage | travel | 5 000 | 1 250 |
| Voiture | car | 40 000 | 4 000 |

### Investissements

Portefeuille `Démo — prix fictifs`. Trois achats, trois prix manuels (`manual_price = true`).

| Symbole | Achat | Prix manuel |
| --- | --- | --- |
| DEMO-TPR, FICTIF Tunisie Profil | 30 × 8,500 | 9,200 |
| DEMO-ETF, FICTIF World ETF | 2 × 150 | 162 |
| DEMO-BTC, FICTIF Bitcoin | 0,0015 × 180 000 | 190 000 |

Valeur manuelle : 885 TND. Ces prix ne sont pas des cours de marché.

## 4. Données préexistantes

| Mesure | Avant | Après |
| --- | --- | --- |
| Utilisateurs | 4 | 4 |
| Catégories | 32 | 32 |
| Portefeuilles des autres comptes | 4 | 4 |
| Transactions des autres comptes | 9 | 9 |
| Virements des autres comptes | 2 | 2 |
| Portefeuilles au total | 6 | 11 |
| Transactions au total | 9 | 40 |
| Virements au total | 2 | 6 |
| Mouvements au total | 14 | 53 |

Les 39 mouvements ajoutés correspondent aux 31 transactions et aux 8 écritures des 4 virements. Aucun portefeuille d'un autre compte n'a été mis à jour après 00:50 UTC. Les tables Budget, Objectifs et Investissement ne contiennent aucune ligne hors de ce compte.

## 5. Application

Le téléphone Samsung est connecté, mais l'écran était verrouillé. L'interface n'a donc pas été ouverte. Les lignes sont dans les tables lues par l'application (`wallet_balances`, `activity_feed`, `budgets`, `financial_goals`, `goal_contributions`, `investment_portfolios`, `investment_assets`, `investment_transactions`). Le cache de schéma de l'API a été rechargé. Une actualisation dans la session déjà connectée de ce compte doit afficher les données.
