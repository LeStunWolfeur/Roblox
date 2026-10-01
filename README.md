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

**Le hub (zone sûre)**
- **Ta galerie** : 16 vitrines (6 au départ, les suivantes s'achètent). Les cartes exposées produisent du cash, à ramasser sur la dalle verte. Tu peux vendre une carte en maintenant E devant sa vitrine.
- **Le Grading Lab** : les cartes volées y arrivent toutes seules. La gradation prend de 20 s (Common) à 25 min (Secret) et continue même quand tu es déconnecté. Une fois terminée, tu récupères la carte et sa note est révélée.
- **La Training Track** : 8 tapis de course, du Basic au Singularity. Appuie sur E devant un tapis pour monter dessus, puis **reste appuyé** sur Espace (ou W, clic, ou le bouton RUN sur mobile) pour courir et gagner de la Speed. X ou le bouton LEAVE pour descendre. Le pass Auto Train fait courir sans tenir la touche. Chaque tapis se débloque avec du cash.

**La rue (10 boutiques en ligne droite)**

| # | Boutique | Speed minimum | Gardien |
|---|---|---|---|
| 1 | Corner Shop | 0 | Grandpa Gus |
| 2 | Comic Corner | 600 | Comic Kev |
| 3 | Pixel Arcade | 6K | Arcade Ace |
| 4 | Mall Kiosk | 50K | Mall Cop Mike |
| 5 | Collector's Den | 400K | The Collector |
| 6 | Auction House | 3M | The Auctioneer |
| 7 | Bank Vault | 25M | Vault Guard |
| 8 | Grand Museum | 200M | The Curator |
| 9 | Sky Exchange | 1.6B | Sky Broker |
| 10 | Cosmic Archive | 12B | The Archivist |

Avant chaque zone, un grand panneau indique la vitesse minimum, puis un portail bloque ceux qui ne l'ont pas. Chaque boutique a 6 présentoirs qui se remplissent tout seuls, avec des raretés de plus en plus hautes à mesure qu'on avance.

## Les règles du vol

- Maintiens E sur une carte pour la prendre. Tu la portes au-dessus de ta tête et tu cours 15 % moins vite.
- Le gardien (un vendeur en uniforme, animé) te poursuit jusqu'au portail de sa zone, et il accélère pendant la poursuite (jusqu'à +25 %). S'il t'attrape, tu es projeté et la carte tombe au sol pendant 25 s : n'importe quel joueur peut la ramasser.
- Les autres joueurs peuvent te mettre une claque pour te faire lâcher la carte. Pas de claques dans la zone sûre.
- Dès que tu rentres dans le hub, la carte part au labo.

**Équilibrage, vérifié par simulation** : à la vitesse minimum d'une zone, le gardien t'attrape. Avec environ 2 à 3 fois la Speed demandée, tu ressors avec les cartes de devant. Il faut environ 6 à 10 fois pour celles du fond, près du gardien. C'est la même difficulté dans les 10 zones. Dans Steal an Egg aussi, la vitesse du portail permet seulement d'entrer, et il faut de la marge pour ressortir avec l'œuf.

## Progression

- **48 cartes**, 7 raretés (Common à Secret).
- **Finitions** tirées quand la carte apparaît : Holo x1.5, Gold x2.5, Rainbow x5, Dark Matter x10, et deux finitions de saison, Haunted et Frozen (x4).
- **Note de condition** 1 à 10 tirée au labo : de x0.5 (Poor) à x2.5 (GEM MINT 10).
- **Index** : chaque carte différente découverte donne +1 % de cash, pour toujours.
- **Rebirth** : remet à zéro le cash, la Speed, les tapis et les cartes. En échange, tu gagnes pour toujours +50 % de cash, +25 % de Speed gagnée et un emplacement de gradation en plus.
- **Récompense quotidienne** sur 7 jours, calculée en minutes de ton revenu.
- **Events serveur** toutes les 8 à 12 minutes : Holo Storm, Golden Hour, Restock Rush, Lucky Moon, Sleepy Guards, plus Blood Moon pendant Halloween et Blizzard pendant l'hiver.
- **Sets saisonniers datés** qui s'activent tout seuls : Spooky Set (1er octobre au 5 novembre, donc actif dès la sortie), Frost Set (10 décembre au 8 janvier), Bloom Set (printemps), Heatwave Set (été). Les cartes d'un set ne sortent que pendant sa fenêtre, après elles deviennent introuvables. L'ambiance lumineuse change aussi avec la saison.
- Classements mondiaux dans le hub : Top Cash/s et Top Speed.
- **Friend Boost** : +10 % de cash par ami présent dans le serveur (max +50 %), affiché en bas à gauche avec un bouton pour inviter.
- **Codes** : zone de saisie tout en bas du shop. Les codes se gèrent dans `Config.Codes` (cash, Speed ou carte, avec date d'expiration possible). Codes fournis : RELEASE, SPOOKY (jusqu'au 5 novembre), THANKYOU.
- **Prévision** en bas à droite : le prochain event et dans combien de temps.

## Monétisation

**Game Passes** : VIP (x1.5 cash et tag), 2x Cash, 2x Training, Auto Train, 2x Grading, +2 Grading Slots, Auto Collect, Lucky Grader (meilleure note sur deux tirages).

**Developer Products** : Freeze Guards (tous les gardiens gelés 30 s pour tout le serveur, mis en avant à droite de l'écran comme dans les jeux du genre), Speed Boost et Speed Mega Boost (10 min et 1 h de ton meilleur tapis), Grade All Now, Server Luck x2 pour tout le serveur pendant 15 min, Mystery Pack (Epic ou mieux), Cash Bag et Cash Vault.

Tous les achats sont traités de façon sûre : un achat n'est validé auprès de Roblox qu'une fois livré et sauvegardé, et un même reçu n'est jamais livré deux fois (testé).

Repère sur les prix : Steal an Egg vend son X2 Money 399 R$ et son X2 Growth 467 R$ (sources plus bas). Pour démarrer, je te conseille plutôt des prix un peu plus bas, le temps d'avoir des joueurs :

| Article | Prix suggéré (mon avis) |
|---|---|
| VIP | 299 R$ |
| 2x Cash | 349 R$ |
| 2x Training | 249 R$ |
| Auto Train | 199 R$ |
| Freeze Guards | 79 R$ |
| 2x Grading | 199 R$ |
| +2 Grading Slots | 149 R$ |
| Auto Collect | 99 R$ |
| Lucky Grader | 199 R$ |
| Speed Boost / Mega | 29 / 129 R$ |
| Grade All Now | 49 R$ |
| Server Luck x2 | 99 R$ |
| Mystery Pack | 79 R$ |
| Cash Bag / Vault | 29 / 129 R$ |

## L'interface

- À gauche, de gros boutons avec icônes : Shop, Index, Rebirth, Lab, Daily (et Admin pour toi).
- En bas à gauche : ta Speed (avec ton multiplicateur), ton cash, ton revenu par seconde, la prochaine boutique à débloquer avec une barre de progression, et le Friend Boost.
- À droite : Freeze Guards, et des téléporteurs Plot (ta galerie), Lab et Train. Impossible de se téléporter en portant une carte.
- En haut : l'endroit où tu es (zone sûre, numéro de boutique, nom du gardien) et les events en cours.
- En bas à droite : la prévision du prochain event.

## Le style

Tout est construit en briques à picots, comme dans tes captures de référence, avec une décoration propre à chaque endroit :
- **Le hub :** pelouse, fontaine, arbres, bancs et lampadaires.
- **Les galeries :** façon musée, avec tapis rouge, barrières dorées, appliques, tableaux et vitrines en verre.
- **Les boutiques :** chacune a un décor à son thème, par exemple des bornes d'arcade, une fontaine de centre commercial, des bibliothèques, des colonnes de musée, une porte de coffre-fort, des nuages ou des planètes. Elles ont toutes une enseigne lumineuse, des vitrines, un auvent rayé, des plafonniers et un comptoir.

## Panneau admin ("admin abuse")

Le créateur du jeu voit automatiquement un bouton ADMIN. Tu peux aussi ajouter d'autres UserIds dans `Config.Admins`. Le panneau permet de lancer n'importe quel event, de geler les gardiens, d'activer Server Luck, de remplir tous les présentoirs, et de se donner du cash, de la Speed ou des cartes pour tester. Les "admin abuse" du samedi, c'est ce qui fait revenir les joueurs de Steal a Brainrot. Tu peux faire pareil avec ce panneau.

## Publier, étape par étape

1. Ouvre `build/StealACard.rbxl` dans Roblox Studio.
2. **File > Publish to Roblox**, genre "Simulator" ou "Adventure".
3. **Game Settings > Security** : active "Enable Studio Access to API Services" pour tester la sauvegarde dans Studio.
4. Sur create.roblox.com > ton jeu > Monetization, crée les passes et les produits, puis colle leurs IDs dans `ReplicatedStorage > Shared > Config` (ou `src/shared/Config.luau` si tu utilises Rojo). Tant qu'un ID est à 0, l'article est simplement caché.
5. Optionnel : crée les badges et mets leurs IDs dans `Config.Badges`.
6. Teste avec Play. Pour essayer les passes sans les acheter, mets `Config.StudioGrantAllPasses = true`, et remets `false` avant de publier.
7. Remplis le questionnaire de maturité et conformité, passe le jeu en Public, ajoute une icône et des miniatures (fais des captures de la rue la nuit pendant Halloween et d'une galerie remplie).

## Ce qu'il faut faire en priorité pour que ça marche

- **Les illustrations des cartes.** Pour l'instant, chaque carte a un design généré (dégradé, motif et monogramme), propre mais sans personnage. Dans le genre, ce sont les personnages qui font partager le jeu (les brainrots, les œufs). Ajoute une image par carte dans `src/shared/Cards.luau` (champ `Image = "rbxassetid://..."`). Tu peux les dessiner, les commander, ou les générer toi-même. Respecte les règles Roblox, et n'utilise pas de personnages sous droits (Pokémon, etc.).
- **Des sons** : vol, alerte du gardien, révélation de la note, collecte. Je n'en ai pas mis parce que je ne peux pas vérifier les IDs d'assets.
- **La promo** : TikTok et Shorts de poursuites et de révélations "GEM MINT 10", pubs Roblox. Sans joueurs, il n'y a pas de revenus.

## Ce qui a été testé, et ce qui ne l'a pas été

J'ai écrit une simulation du moteur Roblox (joueurs, temps, sauvegarde, achats) et j'ai fait tourner le vrai code du jeu dedans.

Ce qui a été vérifié :
- Arrivée d'un joueur, vol, poursuite, évasion, livraison au labo, gradation, exposition, revenu et collecte.
- Tapis de course (monter, courir en tenant Espace, s'arrêter en relâchant, descendre avec X), portails de vitesse, capture par un gardien, Freeze Guards, carte au sol ramassée par un autre joueur, claque, codes.
- Achats Robux (sans double livraison), vente, vitrines, rebirth, droits admin, sauvegarde puis reconnexion, et 5 minutes de jeu à 3 joueurs.
- Côté interface : chaque bouton cliqué, chaque panneau ouvert, sans erreur.
- La difficulté des gardiens a été mesurée sur les 10 zones et 3 présentoirs différents.

Ce que je n'ai **pas** pu vérifier, parce que je n'ai pas accès à Roblox lui-même :
- Le rendu visuel.
- La physique réelle : les tapis de course qui ramènent en arrière, les projections.
- Le ressenti en jeu.

Fais une vraie session de test dans Studio (avec 2 joueurs via Test > Clients and Servers) avant de publier.

## Structure du code

```
src/shared/Config.luau        réglages : zones, vitesse, prix, events, passes, produits
src/shared/Cards.luau         les 48 cartes, raretés, finitions, notes, saisons
src/shared/CardArt.luau       dessin des cartes (3D et interface)
src/server/World/MapBuilder   génération de la map
src/server/Services/          sauvegarde, zones et gardiens, labo, galerie, tapis, events, achats...
src/client/                   interface et effets côté joueur
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
