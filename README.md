# Steal a Card

Jeu Roblox du genre "Steal a" (dans la lignée de Steal an Egg), sur le thème des cartes à collectionner.

Tu pars de ta galerie, tu remontes une longue rue droite pleine de boutiques de cartes, tu voles une carte sur un présentoir et tu cours jusqu'à la zone sûre avant que le gardien de la boutique ne t'attrape. Les cartes volées passent au labo de gradation, reçoivent une note de 1 à 10, puis vont dans ta galerie où elles rapportent du cash. Ce cash sert à acheter de meilleurs tapis de course, pour aller plus vite et viser des boutiques plus lointaines.

Fichier prêt à ouvrir : `build/StealACard.rbxl`. Toute la map est générée par le code au lancement, rien à construire à la main.

## Pourquoi ce concept

- Le genre "Steal a" est ce qui marche le plus sur Roblox depuis 2025. Steal a Brainrot a battu le record de joueurs simultanés, et Steal an Egg (sorti le 25 juillet 2026) a atteint des milliards de visites en moins de deux mois.
- Les jeux de collection de cartes sont en pleine montée en ce moment (Anime Card Collection, Youtuber Card Collection, et CookieRun Card Collection qui sort le 10 octobre 2026).
- Je n'ai pas trouvé de jeu qui combine les deux. Attention, ça ne veut pas dire qu'il n'en existe aucun : je n'ai pas pu fouiller la recherche Roblox directement. Vérifie avant de publier en tapant "steal a card" dans Roblox.
- La note de condition (de 1 à 10, comme une carte gradée) vient directement du vrai marché des cartes. C'est ce qui remplace l'éclosion des œufs de Steal an Egg, et c'est le moment "gacha" du jeu.

## Les lieux

**La rue des bases (zone sûre)** : 8 bases de joueurs, 4 de chaque côté de la rue, juste avant les boutiques. Dans chaque base :
- **Le tapis de course** (devant à droite) : E pour monter, et ton personnage court tout seul. Tu peux rester AFK dessus, la Speed continue de monter. **9 niveaux**, chacun avec son propre modèle 3D (voir `docs/treadmill-tiers.png`) : Common (gris métal), Uncommon (néons verts), Rare (néons bleus), Epic (violet), Legendary (or), Mythic (rouge avec pointes), Divine (blanc et cyan, cristaux qui tournent autour), Ancient (bande galaxie, planètes en orbite) et Supreme (or et blanc, ailes, auréole, nuages). Les flèches de la bande défilent plus vite à chaque niveau. X pour descendre.
- **Le bouton d'amélioration**, à côté du tapis : un gros bouton rond sur un socle, avec le prix affiché au-dessus ("UPGRADE > RARE, $2.50K"). Tu cliques dessus pour passer au niveau suivant. L'étiquette est verte si tu as l'argent, grise sinon, dorée au niveau max. F marche aussi, et +1 niveau existe en Robux.
- **16 présentoirs** pour exposer tes cartes gradées. Ils produisent du cash, à ramasser sur la dalle verte. Les premiers sont ouverts, les suivants s'achètent.
- **La machine de gradation** au fond (E pour l'ouvrir). Les cartes volées y arrivent toutes seules. La gradation continue même déconnecté, et un panneau "X CARDS READY!" s'affiche au-dessus quand c'est prêt.

**Au bout de la rue des bases, deux stands** (avec comptoir, étagères, auvent rayé, grande enseigne et un vendeur) :
- **UPGRADES** : ouvre la fenêtre des améliorations (tapis, vitrines, labo).
- **SELL CARDS** : vendre ses cartes une par une ou toutes d'un coup, avec un filtre (toutes, en attente au labo, exposées dans la base). "SELL ALL" demande une confirmation. Une carte se revend 25 secondes de son revenu (moitié prix si elle n'est pas encore gradée) : c'est volontairement peu, une carte rapporte bien plus en restant exposée.

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

Il n'y a pas de portail bloquant : avant chaque zone, un grand panneau donne la **vitesse conseillée**, et une bannière la rappelle quand tu entres. Chaque boutique a 6 présentoirs. Sur chacun se tient la **créature de la carte** (chaque carte a la sienne), avec la carte qui flotte au-dessus et une étiquette nom, rareté et revenu. Le présentoir change selon la rareté :
- Common : gris.
- Rare : couleur bleue et lumière.
- Epic : en plus, un rayon lumineux.
- Legendary et Mythic : en plus, des étincelles.
- Secret : noir et blanc.

## Les règles du vol

- Maintiens E sur une carte pour la prendre. Tu la portes au-dessus de ta tête et tu cours 15 % moins vite.
- Le gardien (un vendeur en uniforme, animé) te poursuit jusqu'au portail de sa zone, et il accélère pendant la poursuite (jusqu'à +25 %). Il court aussi plus vite quand tu portes une carte rare : +4 % pour une Epic, +8 % Legendary, +12 % Mythic, +16 % Secret.
- S'il t'attrape, tu es projeté et **la carte disparaît** : elle retourne dans la boutique. Avant, elle tombait au sol et on pouvait se faire attraper exprès pour la reprendre, c'est corrigé.
- Les autres joueurs peuvent te mettre une claque pour te faire lâcher la carte (elle tombe au sol 25 s, n'importe qui peut la ramasser). Pas de claques dans la zone sûre.
- Dès que tu repasses la ligne SAFE ZONE, la carte part à la machine de gradation de ta base.

**Équilibrage, vérifié par simulation sur les 10 zones** :
- En dessous de la vitesse conseillée, le gardien t'attrape.
- À la vitesse conseillée, tu ressors avec les cartes de devant.
- Il faut environ 6 fois la vitesse conseillée pour celles du fond, près du gardien. C'est la même difficulté dans les 10 zones. Dans Steal an Egg aussi, la vitesse du portail permet seulement d'entrer, et il faut de la marge pour ressortir avec l'œuf.

## Progression

**L'argent et la vitesse.** La boucle : voler des cartes → les exposer pour gagner du cash → améliorer le tapis → plus de Speed → voler des cartes plus rares. Les chiffres sont dans `Config.luau` :

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

Chaque niveau donne environ 6 fois plus de Speed. Chaque prix correspond à quelques minutes du revenu qu'on a à ce stade. Il faut environ 1 h 20 de course pour tout débloquer sans rebirth, sans compter le temps de vol. Les rebirths (+25 % de Speed chacun) et le pass 2x Training raccourcissent tout ça.

**Rester AFK.** Sur le tapis, on peut laisser tourner : la Speed monte et les cartes exposées rapportent. Le panneau du tapis affiche le temps restant avant la vitesse conseillée de la prochaine boutique. Roblox déconnecte tout joueur inactif au bout de 20 minutes, et un jeu ne peut pas l'empêcher. Le jeu fait donc revenir le joueur dans le même serveur à 17 minutes d'inactivité, puis le remet sur son tapis. C'est une méthode courante (le système AutoRejoin fait pareil). Elle ne marche que dans le jeu publié, pas dans Studio.

**Sentir la vitesse.** Quand tu cours vite, le champ de vision s'élargit, des traits de vitesse défilent sur les bords de l'écran et une traînée colorée te suit. Sa couleur change selon la boutique que tu peux viser. Dès que tu atteins la vitesse conseillée d'une nouvelle boutique, un gros message l'annonce ("SPEED 6K REACHED!").

**Les cartes.** Nouveau design façon carte à collectionner :
- un cadre métallisé à la couleur de la rareté, ou de la finition (or, arc-en-ciel, matière noire…) ;
- le nom et le revenu en haut ;
- le portrait de la créature sur un halo ;
- un ruban de rareté avec des étoiles et un encart finition et note ;
- le numéro (#012/046) et le set ;
- une étiquette "GRADE 10" façon carte gradée.

Aperçu dans `docs/cards.png`.


- **46 cartes**, 7 raretés (Common à Secret). Chaque carte a sa créature en 3D, générée à partir de la carte : forme du corps, yeux, bouche, accessoires selon la rareté (feuille, chapeau, cornes, ailes, couronne et cape, auréole, aura pour les Secret), matière selon la finition (or, glace, hanté, arc-en-ciel…).
- **Finitions** tirées quand la carte apparaît : Holo x1.5, Gold x2.5, Rainbow x5, Dark Matter x10, et deux finitions de saison, Haunted et Frozen (x4).
- **Note de condition** 1 à 10 tirée au labo : de x0.5 (Poor) à x2.5 (GEM MINT 10).
- **Index** : toutes les créatures, en silhouette noire tant que tu ne les as pas trouvées. Pour chacune : son revenu, la première boutique où elle peut apparaître, la boutique où elle est la plus fréquente et sa chance par présentoir (par exemple "Shop 6+, best 9, 1 in 2K"). Les cartes rares n'apparaissent que dans les dernières boutiques. Filtres par rareté. Chaque carte différente découverte donne +1 % de cash, pour toujours.
- **Rebirth** : remet à zéro le cash, la Speed, les tapis et les cartes. En échange, tu gagnes pour toujours +50 % de cash, +25 % de Speed gagnée et un emplacement de gradation en plus.
- **Récompenses quotidiennes** sur un cycle de 7 jours, une récompense différente par jour : sac de cash, boost de Speed, pack Rare, tas de cash, pack Epic, méga Speed, et le jour 7 une Legend Box (carte Legendary + cash). Les montants suivent ton revenu et ton tapis. Si tu rates plus de 48 h, la série repart au jour 1. Tout se règle dans `Config.DailyRewards`.
- **Events serveur** toutes les 8 à 12 minutes : Holo Storm, Golden Hour, Restock Rush, Lucky Moon, Sleepy Guards, plus Blood Moon pendant Halloween et Blizzard pendant l'hiver.
- **Sets saisonniers datés** qui s'activent tout seuls : Spooky Set (1er octobre au 5 novembre, donc actif dès la sortie), Frost Set (10 décembre au 8 janvier), Bloom Set (printemps), Heatwave Set (été). Les cartes d'un set ne sortent que pendant sa fenêtre, après elles deviennent introuvables. L'ambiance lumineuse change aussi avec la saison.
- Classements mondiaux dans le hub : Top Cash/s et Top Speed.
- **Friend Boost** : +10 % de cash par ami présent dans le serveur (max +50 %), affiché en bas à gauche, avec une carte dans le shop et un bouton pour inviter.
- **Codes** : zone de saisie tout en bas du shop. Les codes se gèrent dans `Config.Codes` (cash, Speed ou carte, avec date d'expiration possible). Codes fournis : RELEASE, SPOOKY (jusqu'au 5 novembre), THANKYOU.
- **Prévision** en bas à droite, au-dessus des multiplicateurs : le prochain event et dans combien de temps.

## Monétisation

**Game Passes** : VIP (x1.5 cash et tag), 2x Cash (affiché "X2 Money" à droite de l'écran), 2x Training, 2x Grading, +2 Grading Slots, Auto Collect, x2 Luck (meilleure note sur deux tirages, affiché "X2 Luck" à droite).

**Developer Products** :
- **Starter Pack** : une carte Legendary ou mieux garantie, 15 min de cash et 15 min de Speed. Achetable une seule fois, mis en avant à droite de l'écran tant que tu ne l'as pas.
- **Skip Rebirth** : +1 rebirth sans rien perdre, proposé dans la fenêtre Rebirth à côté du bouton gratuit.
- **Mystery Pack** (Epic 70 %, Legendary 25 %, Mythic 4,6 %, Secret 0,4 %, chances affichées dans le shop).
- **Cash** (en premier dans le shop) : Cash Bag (10 min de revenu), Cash Vault (1 h), Cash Mountain (6 h), avec le montant que tu vas recevoir affiché sur chaque pack.
- Freeze Guards (tous les gardiens gelés 30 s pour tout le serveur), Treadmill +1 Level, Speed Boost et Mega Speed (10 min et 1 h de ton tapis), Grade All Now, Server Luck x2 pour tout le serveur pendant 15 min, Cash Bag et Cash Vault.
- Sous la barre de vitesse, trois boutons rapides comme dans les références : +10 min Speed, +1 hour Speed, +1 Treadmill.

Tous les achats sont traités de façon sûre : un achat n'est validé auprès de Roblox qu'une fois livré et sauvegardé, et un même reçu n'est jamais livré deux fois (testé).

Repère sur les prix : Steal an Egg vend son X2 Money 399 R$ et son X2 Growth 467 R$ (sources plus bas). Pour démarrer, je te conseille plutôt des prix un peu plus bas, le temps d'avoir des joueurs :

| Article | Prix suggéré (mon avis) |
|---|---|
| VIP | 299 R$ |
| 2x Cash | 349 R$ |
| 2x Training | 249 R$ |
| Treadmill +1 Level | 25 R$ |
| Freeze Guards | 79 R$ |
| 2x Grading | 199 R$ |
| +2 Grading Slots | 149 R$ |
| Auto Collect | 99 R$ |
| x2 Luck | 199 R$ |
| Starter Pack | 49 R$ |
| Skip Rebirth | 149 R$ |
| Speed Boost / Mega | 29 / 129 R$ |
| Grade All Now | 49 R$ |
| Server Luck x2 | 99 R$ |
| Mystery Pack | 79 R$ |
| Cash Bag / Vault / Mountain | 29 / 129 / 399 R$ |

## L'interface

Refaite sur le modèle de tes captures (la même disposition que la plupart des simulateurs) :
- **En haut** : trois gros onglets, Shop (rouge), My Base (bleu, plus grand, te ramène à ta base) et Upgrades (vert).
- **À gauche** : le bandeau Daily Rewards avec sa pastille "!" et la grille 2x2 Shop, Pass, Rebirth, Index.
- **À droite** : Starter Pack (cadeau et prix), X2 Money et X2 Luck avec leur prix en Robux. Ils disparaissent une fois achetés.
- **En bas à gauche** : le nombre de rebirths, ta Speed, ton cash en gros avec un "+" qui ouvre le shop, ton revenu et le Friend Boost.
- **En bas au centre** : la barre de vitesse (ta Speed et celle conseillée pour la prochaine boutique), le multiplicateur de Speed au-dessus, et les trois boutons de boost en dessous.
- **En bas à droite** : les multiplicateurs (cash, Speed, chance) et la prévision du prochain event.
- Plus de bandeau "Spooky Set" au milieu de l'écran. Une pastille n'apparaît sous les onglets que pendant un event.

Toutes les icônes sont de vrais petits objets 3D (panier, ticket, flèches de rebirth, livre, cadeau, caisse, billets, trèfle, éclair…) affichés dans l'interface, sans image à uploader. La police est Fredoka One partout, en blanc avec un gros contour. Les tuiles ont des dégradés saturés en diagonale, des reflets en biais et un contour épais.

Les fenêtres :
- **Shop** : le Mystery Card Pack avec ses chances par rareté, le Limited Starter Pack avec son contenu, 8 boosts, le Friend Boost, et la zone de codes tout en bas.
- **Game Passes** : une tuile par pass avec son icône, sa description et son prix (OWNED une fois acheté).
- **Daily Rewards** : jours 1 à 6 en grille et le jour 7 en grand avec "OP". Chaque jour affiche CLAIMED, CLAIM, LOCKED ou le temps restant.
- **Rebirth** : "Rebirth 4, X3 Money" vers "Rebirth 5, X3.5 Money", la condition avec sa barre de progression, puis Rebirth OU Skip [keep your stats] en Robux.
- **Upgrades** : le tapis (niveau, look actuel et suivant, amélioration en cash ou en Robux), les vitrines, les emplacements du labo.
- **Index**, **Grading Lab** et le panneau du tapis reprennent le même style.

## Le style

Tout est construit en briques à picots :
- **Les bases** : refaites (voir `docs/base-outside.png`). Un socle sombre avec un liseré lumineux, des murs vitrés façon galerie avec poteaux et rambarde lumineuse, un mur du fond plus haut avec une grande enseigne, des tours d'angle et une entrée avec deux pylônes, un auvent éclairé et un tapis rouge. Les enseignes sont dans le style de l'interface et affichent le nom du joueur, le revenu de la base en direct et le nombre de cartes. La disposition des cartes n'a pas changé.
- **Les boutiques** : façade avec pilastres, corniche, enseigne lumineuse, vitrines avec des affiches de cartes et auvent rayé. À l'intérieur, un sol en damier, des étagères de boosters, des affiches et des plafonniers.
- **Le décor de chaque boutique** suit son thème : bornes d'arcade, fontaine, bibliothèques, colonnes, coffre-fort, nuages, planètes…
- **La lumière** : en Halloween, une lumière de fin d'après-midi orangée (plus de nuit sombre).

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

- **Les illustrations des cartes.** Chaque carte a maintenant sa créature 3D, mais la face de la carte reste un design généré (dégradé, motif et monogramme). Une vraie illustration par carte ferait encore mieux : ajoute-la dans `src/shared/Cards.luau` (champ `Image = "rbxassetid://..."`). N'utilise pas de personnages sous droits (Pokémon, etc.).
- **Des sons** : vol, alerte du gardien, révélation de la note, collecte. Je n'en ai pas mis parce que je ne peux pas vérifier les IDs d'assets.
- **La promo** : TikTok et Shorts de poursuites et de révélations "GEM MINT 10", pubs Roblox. Sans joueurs, il n'y a pas de revenus.

## Ce qui a été testé, et ce qui ne l'a pas été

J'ai écrit une simulation du moteur Roblox (joueurs, temps, sauvegarde, achats) et j'ai fait tourner le vrai code du jeu dedans.

Ce qui a été vérifié :
- Arrivée d'un joueur, vol, poursuite, évasion, livraison au labo, gradation, exposition, revenu et collecte.
- Tapis de course (monter, course automatique, gain selon le niveau, descendre avec X), capture par un gardien (la carte disparaît), Freeze Guards, carte lâchée après une claque et ramassée par un autre joueur, codes.
- Récompenses quotidiennes : jour 1, double réclamation refusée, carte du jour 3 envoyée au labo, retour au jour 1 après le jour 7, série cassée après 48 h.
- Achats Robux (sans double livraison), vente, vitrines, rebirth, droits admin, sauvegarde puis reconnexion, et 5 minutes de jeu à 3 joueurs.
- Côté interface : chaque bouton cliqué, chaque panneau ouvert, sans erreur. J'ai aussi écrit un moteur de rendu pour voir l'interface et les icônes 3D comme elles s'afficheront, et j'ai comparé chaque fenêtre avec tes captures (aperçus dans `docs/`).
- La difficulté des gardiens a été mesurée sur les 10 zones et 3 présentoirs différents.

Ce que je n'ai **pas** pu vérifier, parce que je n'ai pas accès à Roblox lui-même :
- Le rendu exact dans Roblox (mes aperçus sont une reproduction : les polices, les ombres et les ViewportFrames peuvent légèrement différer).
- La physique réelle : les tapis de course qui ramènent en arrière, les projections.
- Le ressenti en jeu.

Fais une vraie session de test dans Studio (avec 2 joueurs via Test > Clients and Servers) avant de publier.

## Structure du code

```
src/shared/Config.luau        réglages : zones, vitesse, prix, events, passes, produits
src/shared/Cards.luau         les 46 cartes, raretés, finitions, notes, saisons
src/shared/CardArt.luau       dessin des cartes (3D et interface)
src/shared/Entity.luau        la créature 3D de chaque carte
src/shared/Odds.luau          chances d'apparition par boutique (Index)
src/shared/Nameplate.luau     étiquette nom / rareté / revenu au-dessus des créatures
src/server/World/MapBuilder   génération de la map
src/server/Services/          sauvegarde, zones et gardiens, labo, galerie, tapis, events, achats...
src/client/Main.client.luau   HUD et fenêtres
src/client/UI/Kit.luau        tuiles, boutons, prix Robux, barres (le style de l'interface)
src/client/UI/Icons3D.luau    les icônes 3D de l'interface
src/client/SpeedFX.client     sensation de vitesse, bande du tapis, objets en orbite
src/client/                   tapis, prompts et effets côté joueur
src/server/World/TreadmillModels  les 9 tapis en 3D
src/server/World/Stands       les stands UPGRADES et SELL CARDS
src/server/World/Signs        enseignes au style de l'interface
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
