# SmartWallet AI — livraison UI

Date : 11 novembre 2026. APK release installé sur le Samsung SM_S938B avec `adb install -r`, sans effacer les données. Aucune transaction n’a été créée ou modifiée. Solde relu après installation : 18 181,300 TND. Dépenses du mois : 703,900 TND.

## Ce qui a changé

- Accueil : en-tête compact (avatar, salutation, mois, réglages), carte de solde resserrée, revenus et dépenses inchangés dans leur calcul, actions rapides, carte Plan, carte SmartWallet AI.
- Le graphique des dépenses affiche les jours 1, 10, 20 et le dernier jour du mois. S’il n’y a aucune dépense du mois, un état vide remplace la courbe.
- Une section « À suivre » n’apparaît que pour un budget à 80 % ou plus, ou pour un objectif encore ouvert.
- Plan est en deux groupes : Gérer mes finances (budgets, objectifs, investissements) et Intelligence financière (assistant, analyses et prévisions, simulation).
- « Atelier financier » n’est plus une entrée du menu Plan. Les 30 analyses restent sur `/plan/studio`, ouvertes depuis « Analyses et prévisions ».
- Les routes, les RPC, l’OCR local et l’assistant sans LLM sont inchangés.

## Vérifié sur le Samsung (mode sombre)

- Accueil : solde, revenus, dépenses, actions rapides, carte Plan et carte SmartWallet AI visibles au-dessus de la barre.
- Ouverture de Plan depuis la carte. Les six destinations compactes sont visibles. L’atelier n’y figure pas.
- Après défilement : graphique avec les jours 1, 10, 20 et 30, et la section « À suivre » (objectif réel « esprit », 0 %).
- La barre ne recouvre ni la carte Plan ni la carte assistant.

## Vérifié par tests automatisés

- `flutter analyze` : aucun problème.
- `flutter test` : 107 tests réussis, dont navigation Accueil → Plan, Accueil → assistant, les six modules Plan, absence de l’entrée atelier, mode sombre, anglais, arabe RTL, écran court, et les tests OCR déjà en place.
- Les tests Python des modèles n’ont pas été relancés : aucun fichier du service ML n’a changé.

## Non retesté sur le téléphone dans cette passe

- Mode clair.
- Ouverture réelle de chacune des 30 analyses, de la biométrie, et des modèles expérimentaux.
- Prénom affiché dans l’en-tête : le compte n’a pas de prénom dans les métadonnées, donc l’en-tête reste « Bonjour » avec l’initiale du courriel.
- Suppression de compte : le SQL reste dans `supabase/pending/` et n’a pas été déployé.

## Limites

- Les autres écrans (portefeuilles, transactions, réglages, scanner) gardent le design system déjà en place. Ils n’ont pas été redessinés.
- La variation du solde n’est affichée que lorsqu’un mois précédent a des dépenses dans la même devise. Elle n’est pas inventée.
- Les modèles restent expérimentaux et non validés sur des données réelles.
