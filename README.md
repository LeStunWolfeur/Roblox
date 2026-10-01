# Sky Rush Obby

Obby Roblox complet, 60 stages répartis sur 6 mondes, avec progression (coins, niveaux, rebirths, trails, récompense quotidienne) et monétisation (Game Passes, skips, packs de coins, dons).

Toute la map est générée par le code au lancement du serveur. Tu n'as rien à construire à la main dans Studio.

## Ce qu'il y a dans le jeu

**Parcours**
- 60 stages, 6 mondes de 10 (Meadow, Desert, Frost, Magma, Neon City, Void), chacun avec ses couleurs et son ambiance
- 8 types d'obstacles qui se débloquent au fil du parcours : sauts, sol piégé, plateformes qui disparaissent, barres qui tournent, poutres en zigzag, trampolines, blocs qui balayent, tour à grimper
- La difficulté monte stage après stage (plateformes plus petites, écarts plus grands, obstacles plus rapides). Tous les sauts restent faisables, je l'ai vérifié par simulation (écart max ~7 studs pour un saut d'environ 8,5)
- Checkpoints sauvegardés, impossible de sauter un stage en trichant (on ne valide que le checkpoint suivant)

**Progression**
- Coins et XP gagnés à chaque nouveau checkpoint, plus le stage est loin plus ça rapporte
- Niveaux avec barre d'XP, affichés au-dessus de la tête et dans le chat
- Rebirth une fois l'obby fini : retour au stage 0 avec +50% de coins et d'XP par rebirth, pour toujours
- 8 trails achetables en coins, débloqués par niveau et par nombre de rebirths
- Récompense quotidienne sur 7 jours avec série (la série repart à zéro après 48h sans réclamer)
- Classements mondiaux dans le lobby : Top Levels et Top Donors

**Monétisation**
- 6 Game Passes : VIP, 2x Coins, Double Jump, Speed Boost, Low Gravity, Rainbow Trail
- Developer Products : Skip Stage, Skip 5 Stages, 2 packs de coins, 3 dons
- Proposition de skip automatique quand un joueur meurt 4 fois sur le même stage
- Achats traités de façon sûre : un achat n'est validé auprès de Roblox qu'une fois livré et sauvegardé, donc personne ne perd ce qu'il a payé et personne ne le reçoit deux fois

## Structure

```
default.project.json        projet Rojo
build/SkyRushObby.rbxl      le jeu prêt à ouvrir dans Studio
src/shared/Config.luau      TOUS les réglages (IDs, prix en coins, récompenses, mondes)
src/shared/Remotes.luau     communication serveur / client
src/server/Main.server.luau démarrage
src/server/World/           génération de la map (lobby, stages, checkpoints)
src/server/Services/        sauvegarde, progression, achats, bonus, classements
src/client/                 interface et gameplay côté joueur (double saut, trampolines, chat)
```

## Publier le jeu, étape par étape

### 1. Ouvrir le jeu
Ouvre `build/SkyRushObby.rbxl` dans Roblox Studio (double clic ou File > Open).

Si tu veux modifier le code et voir les changements en direct, installe Rojo (plugin Studio + outil) puis lance `rojo serve` dans ce dossier. Sinon le .rbxl suffit.

### 2. Publier une première fois
File > Publish to Roblox. Donne un nom, une description, choisis le genre Obby.

### 3. Activer la sauvegarde
Home > Game Settings > Security > active **Enable Studio Access to API Services**. Sans ça, la sauvegarde ne marche pas pendant tes tests dans Studio (en jeu publié elle marche quand même).

### 4. Créer les articles payants
Sur create.roblox.com > Creations > ton jeu > Monetization :
- **Passes** : crée les 6 passes (VIP, 2x Coins, Double Jump, Speed Boost, Low Gravity, Rainbow Trail), mets une image et un prix, et passe-les en vente
- **Developer Products** : crée Skip Stage, Skip 5 Stages, 2 packs de coins (2 500 et 15 000), Donate 10, Donate 100, Donate 1000

Copie chaque ID et colle-le dans `src/shared/Config.luau` à la place du `0` correspondant. Si tu passes par le .rbxl sans Rojo, le fichier est dans ReplicatedStorage > Shared > Config.

Tant qu'un ID est à 0, l'article est simplement caché. Tu peux donc publier sans tout avoir.

Prix que je te propose pour démarrer (c'est mon avis, pas une donnée officielle, à ajuster selon tes ventes) :

| Article | Prix suggéré |
|---|---|
| VIP | 199 R$ |
| 2x Coins | 149 R$ |
| Double Jump | 99 R$ |
| Speed Boost | 79 R$ |
| Low Gravity | 79 R$ |
| Rainbow Trail | 49 R$ |
| Skip Stage | 15 R$ |
| Skip 5 Stages | 59 R$ |
| 2 500 coins | 49 R$ |
| 15 000 coins | 199 R$ |
| Dons | 10 / 100 / 1000 R$ |

Les prix des dons doivent correspondre au montant affiché, sinon le classement des dons sera faux (le jeu ajoute le montant écrit dans Config, pas le prix réel).

### 5. Badges (optionnel)
Tu peux créer des badges (Welcome, fin du monde 1, fin de l'obby, premier rebirth, niveau 10) et mettre leurs IDs dans `Config.Badges`.

### 6. Tester
Lance Play dans Studio. Pour tester les passes sans les acheter, mets `Config.StudioGrantAllPasses = true` (ça ne marche que dans Studio, jamais en jeu publié). Remets-le à `false` avant de publier.

### 7. Republier et ouvrir au public
File > Publish to Roblox, puis sur create.roblox.com passe le jeu en Public. Remplis aussi le questionnaire de maturité et conformité dans les réglages du jeu, un jeu sans classification risque de ne pas être visible par tout le monde.

### 8. Icône et miniatures
Fais des captures dans Studio (le lobby avec le titre, un monde Neon City ou Void de nuit rend bien) et mets-les en icône et en thumbnails. C'est ce qui donne envie de cliquer, ne le néglige pas.

## Ce que tu dois savoir avant de compter sur l'argent

- Le jeu est prêt techniquement, mais il ne fera pas de revenus tout seul. Sur Roblox, le plus dur c'est d'avoir des joueurs. Il y a énormément d'obbys, il faudra faire connaître le tien (TikTok / YouTube Shorts de passages difficiles, pubs Roblox, groupes)
- Pour transformer tes Robux en vrai argent il y a le programme DevEx. D'après la doc officielle de Roblox, il faut au minimum 30 000 Robux gagnés, avoir 13 ans ou plus, un email vérifié et un formulaire fiscal (W-8 pour toi qui n'es pas aux États-Unis). Le taux standard est de 0,0038 $ par Robux, soit 114 $ pour 30 000. Vérifie la page officielle au moment de retirer, ces règles changent
- Roblox prend une commission sur chaque vente de pass ou de produit, tu ne touches pas 100% du prix affiché

## Modifier le jeu

Presque tout se règle dans `Config.luau` :
- `StagesPerWorld` et `Worlds` pour la longueur et les thèmes
- `CoinsForStage`, `XPForStage`, `XPToNext` pour l'équilibrage
- `RebirthBonus` pour la puissance des rebirths
- `Trails` pour ajouter des trails
- `DailyRewards` pour la récompense quotidienne

Les obstacles sont dans `src/server/World/StageTypes.luau`. Chaque type est une fonction, tu peux en ajouter un et le déclarer dans `StageTypes.Unlock`.

Après chaque modification, si tu travailles avec les fichiers, regénère le .rbxl avec `rojo build -o build/SkyRushObby.rbxl`.
