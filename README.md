# Steal a Card

Jeu Roblox du genre "Steal a" (dans la lignée de Steal an Egg), sur le thème des cartes à collectionner.

Tu pars de ta base, tu remontes une longue rue droite pleine de boutiques de cartes, tu prends une carte sur un présentoir et tu cours jusqu'à la zone sûre avant que le gardien ne t'attrape. La carte volée se pose toute seule sur un support libre de ta base et rapporte du cash. Tu peux la faire noter au stand GRADING LAB (note de 1 à 10, qui multiplie son revenu), ouvrir des packs au stand CARD PACKS, et améliorer ton tapis de course pour aller plus vite et viser des boutiques plus lointaines.

Fichier prêt à ouvrir : `build/StealACard.rbxl`. Toute la map est générée par le code au lancement, rien à construire à la main.

## Pourquoi ce concept

- Le genre "Steal a" est ce qui marche le plus sur Roblox depuis 2025. Steal a Brainrot a battu le record de joueurs simultanés, et Steal an Egg (sorti le 25 juillet 2026) a atteint des milliards de visites en moins de deux mois.
- Les jeux de collection de cartes sont en pleine montée en ce moment (Anime Card Collection, Youtuber Card Collection, et CookieRun Card Collection qui sort le 10 octobre 2026).
- Je n'ai pas trouvé de jeu qui combine les deux. Attention, ça ne veut pas dire qu'il n'en existe aucun : je n'ai pas pu fouiller la recherche Roblox directement. Vérifie avant de publier en tapant "steal a card" dans Roblox.
- La note de condition (de 1 à 10, comme une carte gradée) vient directement du vrai marché des cartes. C'est ce qui remplace l'éclosion des œufs de Steal an Egg, et c'est le moment "gacha" du jeu.

## Les lieux

**La rue des bases (zone sûre)** : 8 bases de joueurs, 4 de chaque côté. Sur l'enseigne de la base s'affiche le pseudo du joueur et son revenu en direct. Une base libre n'affiche rien, juste sa couleur.

Dans chaque base :
- **Le tapis de course** (devant à droite) : E pour monter, ton personnage court tout seul et tu peux rester AFK dessus. **9 niveaux**, et le modèle 3D change à chaque niveau (voir `docs/treadmill-tiers.png`) : Common, Uncommon, Rare, Epic, Legendary, Mythic, Divine, Ancient et Supreme. X pour descendre.
- **Le bouton d'amélioration**, à côté du tapis, avec le prix affiché au-dessus. Il faut cliquer dessus à chaque fois (il n'y a plus de touche pour améliorer). L'étiquette est verte si tu as l'argent, grise sinon, dorée au niveau max.
- **Les supports de cartes** : 8 par étage. Tu commences avec 3 supports ouverts, les suivants s'achètent un par un et coûtent de plus en plus cher (150 $, 480 $, 1,5K $, 4,9K $...). Le 2e étage s'ouvre au 1er rebirth, le 3e au 3e rebirth (24 supports au total, +2 avec le pass). Des plaques "UP TO FLOOR 2/3" font monter et descendre.
- Sur un support, la carte flotte en grand et tourne doucement. Quand tu t'approches, deux boutons apparaissent : **SELL** (avec une confirmation "SURE?") et **PICK UP** pour la prendre en main et la poser ailleurs ou l'emmener au labo. Il n'y a plus de vente par touche.
- Si tous les supports sont pleins, les nouvelles cartes vont dans la **réserve** (bouton STORAGE en bas à gauche, 30 places), d'où tu peux les reprendre ou les vendre.

**Au bout de la rue des bases, trois stands** (comptoir, enseigne, vendeur) :
- **UPGRADES** : la fenêtre des améliorations (tapis, supports, étages).
- **GRADING LAB** : tu viens avec une carte en main, tu paies et la note tombe tout de suite. Le prix vaut 60 secondes du revenu de la carte (minimum 25 $), donc une carte chère coûte cher à noter. Tu peux regrader si la note ne te plaît pas. Une carte volée ne va plus au labo toute seule : elle va directement sur un support.
- **CARD PACKS** : 5 packs, du moins cher au plus fort.

| Pack | Prix | Chances | Carte bonus |
|---|---|---|---|
| Basic | 500 $ | Common 70 %, Uncommon 25 %, Rare 5 % | 10 % |
| Silver | 15K $ | Uncommon 50 %, Rare 38 %, Epic 11 %, Legendary 1 % | 15 % |
| Gold | 400K $ | Rare 45 %, Epic 40 %, Legendary 13 %, Mythic 2 % | 20 % |
| Diamond | 12M $ | Epic 45 %, Legendary 42 %, Mythic 12 %, Secret 1 % | 25 % |
| Cosmic | 500M $ | Legendary 55 %, Mythic 38 %, Secret 7 % | 35 % |

Le stock change toutes les 5 minutes (le même dans tous les serveurs) et les gros packs ne sont pas toujours en rayon. Chaque pack ouvert sans Legendary ou mieux te donne +3 % de chance pour les suivants (jusqu'à +45 %, remis à zéro quand tu tombes sur une Legendary). Les packs Gold, Diamond et Cosmic donnent aussi +20 % de cash pendant 10 minutes. On peut remplir son stock tout de suite en Robux.

**La rue des boutiques** : la suite de la même rue, avec 10 boutiques à thème.

| # | Boutique | Speed conseillée | Gardien |
|---|---|---|---|
| 1 | Corner Shop | aucune | Grandpa Gus |
| 2 | Comic Corner | 600 | Comic Kev |
| 3 | Pixel Arcade | 6K | Arcade Ace |
| 4 | Mall Kiosk | 50K | Mall Cop Mike |
| 5 | Collector's Den | 400K | The Collector |
| 6 | Auction House | 3M | The Auctioneer |
| 7 | Bank Vault | 25M | Vault Guard |
| 8 | Grand Museum | 200M | The Curator |
| 9 | Sky Exchange | 1.6B | Sky Broker |
| 10 | Cosmic Archive | 12B | The Archivist |

Avant chaque zone, un grand panneau donne la **vitesse conseillée**. Sur les présentoirs, plus de créatures en 3D : ce sont **de grandes cartes en 3D** qui flottent et tournent, avec une aura selon la rareté (particules, lumière dès Rare) et un effet par mutation (Holo, Gold, Diamond, Rainbow, Dark Matter, Haunted, Frozen). Le socle prend la couleur de la rareté.

**Refresh de la map** : toutes les 10 minutes, un compte à rebours de 5 secondes s'affiche à l'écran et sur le grand écran au-dessus de la rue. À zéro, tous les joueurs qui sont dans les boutiques sont renvoyés dans leur base (ceux qui sont dans la zone sûre ne bougent pas) et tous les présentoirs changent.

## Les règles du vol

- Maintiens E sur une carte pour la prendre. Tu la tiens devant toi, dans les mains, et tu cours 15 % moins vite.
- Le gardien (un policier détaillé, casquette, uniforme, matraque, lunettes noires dans les boutiques 5 à 10) te poursuit jusqu'au portail de sa zone et accélère pendant la poursuite (jusqu'à +25 %). Il court aussi plus vite quand tu portes une carte rare.
- S'il t'attrape, la carte disparaît et une nouvelle carte réapparaît ailleurs dans la boutique.
- Les autres joueurs peuvent te mettre une claque pour te faire lâcher la carte (elle tombe au sol 25 s). Pas de claques dans la zone sûre.
- Dès que tu repasses la ligne SAFE ZONE, la carte se pose sur un support libre de ta base.

**Équilibrage, vérifié par simulation sur les 10 zones** : en dessous de la vitesse conseillée, le gardien t'attrape. À la vitesse conseillée, tu ressors avec les cartes de devant. Il faut environ 6 fois la vitesse conseillée pour celles du fond. C'est la même difficulté dans les 10 zones.

## Progression

**L'argent et la vitesse.** La boucle : voler des cartes, les poser pour gagner du cash, les faire noter, améliorer le tapis, voler des cartes plus rares. Les chiffres sont dans `Config.luau` :

| Niveau du tapis | Speed/s | Prix pour y passer | Boutique visée | Temps de course pour l'atteindre |
|---|---|---|---|---|
| 1 Common | 5 | gratuit | 2 Comic Corner (600) | 2 min |
| 2 Uncommon | 30 | $250 | 3 Pixel Arcade (6K) | 3 min |
| 3 Rare | 180 | $2.5K | 4 Mall Kiosk (50K) | 4 min |
| 4 Epic | 1.1K | $25K | 5 Collector's Den (400K) | 5 min |
| 5 Legendary | 6.5K | $200K | 6 Auction House (3M) | 7 min |
| 6 Mythic | 40K | $1.5M | 7 Bank Vault (25M) | 9 min |
| 7 Divine | 240K | $12M | 8 Grand Museum (200M) | 12 min |
| 8 Ancient | 1.4M | $100M | 9 Sky Exchange (1.6B) | 17 min |
| 9 Supreme | 8.5M | $1B | 10 Cosmic Archive (12B) | 20 min |

Il faut environ 1 h 20 de course pour tout débloquer sans rebirth, sans compter le temps de vol. La vitesse n'est donc pas trop facile : chaque boutique demande plusieurs minutes de tapis, et il faut des cartes exposées pour payer le niveau suivant.

**Rester AFK.** Sur le tapis, la Speed monte et les cartes posées rapportent. Roblox déconnecte tout joueur inactif au bout de 20 minutes et un jeu ne peut pas l'empêcher. Le jeu fait donc revenir le joueur dans le même serveur à 17 minutes d'inactivité, puis le remet sur son tapis (même méthode que le système AutoRejoin). Ça ne marche que dans le jeu publié, pas dans Studio.

**Sentir la vitesse.** Quand tu cours vite, le champ de vision s'élargit, des traits de vitesse défilent sur les bords et une traînée colorée te suit. Un message s'affiche quand tu atteins la vitesse d'une nouvelle boutique.

**Les cartes.**
- **46 cartes**, 7 raretés (Common à Secret), chacune avec son illustration dessinée (toast, chaussette philosophe, cookie capitaine, chat galaxie...). Aperçu dans `docs/card-art.png`.
- Design façon carte à collectionner : cadre à la couleur de la rareté ou de la mutation, nom et revenu en haut, illustration, ruban de rareté avec étoiles, encart mutation et note, numéro (#012/046) et set, étiquette "GRADE 10" façon carte gradée.
- **Mutations** tirées quand la carte apparaît : Holo x1.5, Gold x2.5, Diamond x3.5, Rainbow x5, Dark Matter x10, et deux de saison, Haunted et Frozen (x4).
- **Note** de 1 à 10 au GRADING LAB : de x0.5 (Poor) à x2.5 (GEM MINT 10).
- **Revente** : 25 secondes du revenu de la carte, et moitié moins si elle n'est pas notée. C'est volontairement bas : une carte rapporte bien plus en restant posée.

**Index** : toutes les cartes, cachées tant que tu ne les as pas trouvées, avec la boutique où elles apparaissent et leurs chances. Chaque carte découverte donne +1 % de cash pour toujours. En plus, des **paliers** avec récompense à réclamer : 5 cartes (sac de cash), 10 (Silver Pack), 15 (+5 % de cash pour toujours), 20 (Gold Pack), 25 (+10 %), 30 (Diamond Pack), 40 (+25 %), 46 (Cosmic Pack).

**Rebirth** : le premier coûte 300K $ (avant c'était 2M), puis x6 à chaque fois. Il remet à zéro le cash, la Speed, le tapis et les cartes posées, mais tu gardes les supports achetés. En échange : +50 % de cash et +25 % de Speed pour toujours, et un nouvel étage dans ta base au 1er et au 3e rebirth.

**Le reste** :
- **Récompenses quotidiennes** sur 7 jours (cash, Speed, packs, et une Legend Box le jour 7). Si tu rates plus de 48 h, la série repart au jour 1.
- **Events serveur** toutes les 8 à 12 minutes : Holo Storm, Golden Hour, Restock Rush, Lucky Moon, Sleepy Guards, plus Blood Moon pendant Halloween et Blizzard l'hiver. Ils s'affichent dans une petite bannière propre sous les onglets, avec une icône, la couleur de l'event et le temps restant.
- **Sets saisonniers datés** qui s'activent tout seuls : Spooky Set (1er octobre au 5 novembre), Frost Set, Bloom Set, Heatwave Set.
- Classements mondiaux (Top Cash/s et Top Speed), **Friend Boost** (+10 % de cash par ami présent, max +50 %), **codes** (RELEASE, SPOOKY, THANKYOU, réglables dans `Config.Codes`).
- **Ramassage du cash** : des pièces volent jusqu'à ton compteur, qui grossit un instant, avec un son et le gain affiché.

## Monétisation

**Game Passes** : VIP (x1.5 cash et tag), 2x Cash ("X2 Money" à droite de l'écran), 2x Training, Half-Price Grading (noter coûte moitié prix), +2 Display Cases (deux supports en plus, gratuits), Auto Collect, x2 Luck (meilleure note sur deux tirages et packs plus chanceux, "X2 Luck" à droite).

**Developer Products** :
- **Starter Pack** : une carte Legendary ou mieux, 15 min de cash et 15 min de Speed. Une seule fois par joueur.
- **Skip Rebirth** : +1 rebirth sans rien perdre.
- **Mystery Pack** (Epic 70 %, Legendary 25 %, Mythic 4,6 %, Secret 0,4 %, chances affichées).
- **Restock Packs** : remplit tout de suite ton stock au stand CARD PACKS.
- **Cash** : Cash Bag (10 min de revenu), Cash Vault (1 h), Cash Mountain (6 h), avec le montant reçu affiché.
- Freeze Guards (30 s pour tout le serveur), Treadmill +1 Level, Speed Boost et Mega Speed, Server Luck x2 pour tout le serveur pendant 15 min.
- Sous la barre de vitesse, trois boutons rapides : +10 min Speed, +1 hour Speed, +1 Treadmill.

Tous les achats sont traités de façon sûre : un achat n'est validé auprès de Roblox qu'une fois livré et sauvegardé, et un même reçu n'est jamais livré deux fois (testé).

Repère sur les prix : Steal an Egg vend son X2 Money 399 R$ et son X2 Growth 467 R$ (sources plus bas). Pour démarrer, je te conseille des prix un peu plus bas, le temps d'avoir des joueurs :

| Article | Prix suggéré (mon avis) |
|---|---|
| VIP | 299 R$ |
| 2x Cash | 349 R$ |
| 2x Training | 249 R$ |
| Half-Price Grading | 149 R$ |
| +2 Display Cases | 149 R$ |
| Auto Collect | 99 R$ |
| x2 Luck | 199 R$ |
| Treadmill +1 Level | 25 R$ |
| Freeze Guards | 79 R$ |
| Starter Pack | 49 R$ |
| Skip Rebirth | 149 R$ |
| Speed Boost / Mega | 29 / 129 R$ |
| Restock Packs | 39 R$ |
| Server Luck x2 | 99 R$ |
| Mystery Pack | 79 R$ |
| Cash Bag / Vault / Mountain | 29 / 129 / 399 R$ |

## L'interface

- **En haut** : Shop (rouge), My Base (bleu) et Upgrades (vert). En dessous, la bannière de l'event en cours.
- **À gauche** : Daily Rewards et la grille Shop, Pass, Rebirth, Index.
- **À droite** : Starter Pack, X2 Money et X2 Luck avec leur prix en Robux (ils disparaissent une fois achetés).
- **En bas à gauche** : rebirths, bouton STORAGE, Speed, cash avec un "+", revenu et Friend Boost.
- **En bas au centre** : la barre de vitesse et les trois boutons de boost.
- **En bas à droite** : les multiplicateurs, le prochain refresh des boutiques et le prochain event.

Fenêtres : Shop, Game Passes, Daily Rewards, Rebirth (avec les étages débloqués), Index (avec les paliers à réclamer), Upgrades, **Grading** (la carte en main, le prix, les chances de chaque note, GRADE puis REGRADE), **Packs** (les 5 packs, stock, chances, carte bonus, barre de chance accumulée, prochain réassort), **Storage** et l'ouverture animée des packs.

**Icônes et illustrations** : les icônes (rebirth, index, shop, pass, cadeau, cash...) et les 46 illustrations de cartes sont de vraies images dessinées, regroupées dans 5 planches dans `assets/`. Tant que tu ne les as pas uploadées, le jeu utilise les versions faites en code (icônes 3D et portraits simples), donc rien ne casse. Pour les mettre :
1. Dans Studio : **Window > Asset Manager > Images > Bulk Import**, sélectionne les 5 fichiers de `assets/` (cards_1, cards_2, cards_3, icons_1, icons_2).
2. Attends la validation de Roblox, puis clic droit sur chaque image > **Copy ID to Clipboard**.
3. Colle chaque ID dans `Config.Images`, sous la forme `"rbxassetid://123456789"`, dans le bon ordre (cards_1, cards_2, cards_3 puis icons_1, icons_2).

Les images sont générées par `tools/art/make_art.py` (Python, numpy, pillow, scipy). Si tu changes une carte ou une icône, relance-le : il refait les planches et `src/shared/ImageAtlas.luau`.

**Sons et musique** : clic, cash, vol, attrapé, amélioration, pack, révélation, event. Par défaut ce sont des sons livrés avec Roblox (`rbxasset://sounds/...`). Je n'ai pas pu les écouter : vérifie-les dans Studio et remplace-les par des sons du Creator Store si besoin (`Config.Sounds`). Pour la musique, ajoute des IDs dans `Config.Music`, elles passent en boucle.

## Le style

- **Les bases** : socle sombre avec liseré lumineux, murs vitrés, tours d'angle, auvent et tapis rouge. Les enseignes ont un fond en dégradé à la couleur de la base avec un gros texte blanc.
- **Les étages** : dalle, garde-corps vitrés, colonnes et panneau "FLOOR 2/3".
- **Les supports** : des podiums ronds avec un anneau lumineux à la couleur de la rareté, un cadenas quand ils sont verrouillés.
- **Les stands** : comptoir, auvent, enseigne et décor propre à chacun (scanner et loupe pour le GRADING LAB, présentoirs de packs pour CARD PACKS).
- **Les boutiques** : façade avec enseigne lumineuse, vitrines et auvent rayé, décor intérieur selon le thème.
- **Les panneaux** (arches de zone, enseignes, sortie) : même style que l'interface, plus de texte brut.

## Panneau admin ("admin abuse")

Le créateur du jeu voit automatiquement un bouton ADMIN. Tu peux aussi ajouter d'autres UserIds dans `Config.Admins`. Le panneau permet de lancer n'importe quel event, de geler les gardiens, d'activer Server Luck, de remplir tous les présentoirs, et de se donner du cash, de la Speed ou des cartes pour tester. Les "admin abuse" du samedi, c'est ce qui fait revenir les joueurs de Steal a Brainrot. Tu peux faire pareil avec ce panneau.

## Publier, étape par étape

1. Ouvre `build/StealACard.rbxl` dans Roblox Studio.
2. **File > Publish to Roblox**, genre "Simulator" ou "Adventure".
3. **Game Settings > Security** : active "Enable Studio Access to API Services" pour tester la sauvegarde dans Studio.
4. Sur create.roblox.com > ton jeu > Monetization, crée les passes et les produits, puis colle leurs IDs dans `ReplicatedStorage > Shared > Config` (ou `src/shared/Config.luau` si tu utilises Rojo). Tant qu'un ID est à 0, l'article reste affiché avec le prix "--" et un message "not on sale yet" s'affiche si on clique dessus. Les prix affichés sont lus directement chez Roblox.
5. Optionnel : crée les badges et mets leurs IDs dans `Config.Badges`.
6. Teste avec Play. Pour essayer les passes sans les acheter, mets `Config.StudioGrantAllPasses = true`, et remets `false` avant de publier.
7. Remplis le questionnaire de maturité et conformité, passe le jeu en Public, ajoute une icône et des miniatures (fais des captures de la rue la nuit pendant Halloween et d'une galerie remplie).

## Ce qu'il faut faire en priorité pour que ça marche

- **Uploader les 5 images** (voir plus haut) : c'est ce qui donne le rendu final aux cartes et aux icônes.
- **Vérifier les sons** dans Studio et ajouter une musique.
- **La promo** : TikTok et Shorts de poursuites, d'ouvertures de packs et de "GEM MINT 10". Sans joueurs, il n'y a pas de revenus.

## Ce qui a été testé, et ce qui ne l'a pas été

J'ai écrit une simulation du moteur Roblox (joueurs, temps, sauvegarde, achats) et j'ai fait tourner le vrai code du jeu dedans.

Ce qui a été vérifié :
- Arrivée d'un joueur, vol, poursuite, évasion, carte posée toute seule sur un support, revenu et collecte.
- Supports : achat, PICK UP, PLACE, vente avec confirmation, réserve (reprendre, vendre), étages après rebirth.
- GRADING LAB : prix, note, regrade. Packs : achat, stock, carte bonus, chance accumulée, réassort. Paliers de l'Index.
- Refresh de la map : les joueurs dans les boutiques rentrent, ceux de la zone sûre ne bougent pas, les présentoirs changent.
- Tapis (monter, course automatique, bouton d'amélioration), capture par un gardien (la carte disparaît et une autre réapparaît), Freeze Guards, claques, codes, récompenses quotidiennes.
- Achats Robux (sans double livraison), rebirth, droits admin, sauvegarde puis reconnexion (avec migration des anciennes sauvegardes), 5 minutes de jeu à 3 joueurs.
- Côté interface : chaque bouton cliqué, chaque panneau ouvert, sans erreur, avec et sans les images uploadées. Aperçus dans `docs/`.

Ce que je n'ai **pas** pu vérifier, parce que je n'ai pas accès à Roblox lui-même :
- Le rendu exact dans Roblox (mes aperçus sont une reproduction : les polices, les ombres et les ViewportFrames peuvent légèrement différer).
- La physique réelle : les tapis de course qui ramènent en arrière, les projections.
- Le ressenti en jeu.

Fais une vraie session de test dans Studio (avec 2 joueurs via Test > Clients and Servers) avant de publier.

## Structure du code

```
src/shared/Config.luau        réglages : zones, vitesse, prix, packs, grading, étages, events, sons, images
src/shared/Cards.luau         les 46 cartes, raretés, mutations, notes, saisons
src/shared/CardArt.luau       face des cartes (3D et interface)
src/shared/ImageAtlas.luau    position des images dans les planches (généré)
src/shared/Odds.luau          chances d'apparition par boutique (Index)
src/server/World/MapBuilder   génération de la map
src/server/World/CardDisplay  grandes cartes 3D, aura et effets de mutation
src/server/World/Showcase     podiums des cartes
src/server/World/GuardModel   gardiens et vendeurs
src/server/World/TreadmillModels  les 9 tapis en 3D
src/server/World/Stands       stands UPGRADES, GRADING LAB et CARD PACKS
src/server/World/Signs        enseignes au style de l'interface
src/server/Services/          sauvegarde, zones et gardiens, galerie, grading, packs, tapis, events, achats...
src/client/Main.client.luau   HUD et fenêtres
src/client/UI/Kit.luau        tuiles, boutons, prix Robux, barres
src/client/UI/Icons3D.luau    icônes (image si uploadée, sinon modèle 3D)
src/client/UI/Sounds.luau     sons et musique
src/client/SpeedFX.client     sensation de vitesse, bande du tapis, objets en orbite
tools/art/                    générateur des images (cartes et icônes)
assets/                       les 5 planches à uploader
```

## Gagner de l'argent réel (DevEx)

D'après la doc officielle de Roblox, il faut au minimum 30 000 Robux gagnés, avoir 13 ans ou plus, un email vérifié et un formulaire fiscal W-8 (tu n'es pas aux États-Unis). Le taux standard est de 0,0038 $ par Robux, soit 114 $ pour 30 000. Vérifie la page officielle au moment de retirer.

## Sources

- [Steal a Brainrot (Wikipedia)](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- [Steal an Egg, zones, vitesses et gardiens (Eldorado)](https://www.eldorado.gg/blog/steal-an-egg/steal-an-egg-biomes-and-speed-requirements/)
- [Steal an Egg, vitesse et tapis de course (stealaneggwiki.net)](https://stealaneggwiki.net/speed)
- [Steal an Egg, gamepasses (bo3.gg)](https://bo3.gg/games/articles/steal-an-egg-gamepasses-guide)
- [Meilleurs jeux Roblox de septembre 2026 (Sportskeeda)](https://www.sportskeeda.com/roblox-news/best-roblox-games-to-play-right-now)
- [CookieRun Card Collection arrive sur Roblox (Pro Game Guides)](https://progameguides.com/roblox/cookierun-card-collection-brings-cookierun-tcg-to-roblox-this-october/)
- [Roblox Developer Exchange](https://create.roblox.com/docs/production/monetization/developer-exchange)
- [Déconnexion après 20 min d'inactivité (DevForum)](https://devforum.roblox.com/t/bypass-roblox-afk-kick/1932814)
- [Revenir dans le même serveur juste avant la déconnexion (AutoRejoin)](https://builtbybit.com/resources/autorejoin-anti-afk-system.102375/)
