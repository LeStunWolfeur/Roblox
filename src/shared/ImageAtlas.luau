-- Fichier généré par tools/art/make_art.py : ne pas modifier à la main.
-- Position de chaque image dans sa planche (assets/*.png).
-- Les IDs des planches uploadées se mettent dans Config.Images.

local ImageAtlas = {}

ImageAtlas.CardSize = Vector2.new(256, 200)
ImageAtlas.IconSize = Vector2.new(256, 256)

-- [id] = { planche, x, y }
ImageAtlas.Cards = {
	toastini = { 1, 0, 0 },
	sockrates = { 1, 256, 0 },
	bloop = { 1, 512, 0 },
	pebblepete = { 1, 768, 0 },
	mrnoodle = { 1, 0, 200 },
	cardboardcarl = { 1, 256, 200 },
	wobbles = { 1, 512, 200 },
	spaghettron = { 1, 768, 200 },
	bananaut = { 1, 0, 400 },
	cactuso = { 1, 256, 400 },
	duckmaster = { 1, 512, 400 },
	jellybyte = { 1, 768, 400 },
	captaincrumb = { 1, 0, 600 },
	turbotortellini = { 1, 256, 600 },
	neonnana = { 1, 512, 600 },
	sirpickles = { 1, 768, 600 },
	glitchygus = { 1, 0, 800 },
	pizzasaurus = { 1, 256, 800 },
	roboraccoon = { 1, 512, 800 },
	thundertaco = { 1, 768, 800 },
	moonmoo = { 2, 0, 0 },
	kingcroissant = { 2, 256, 0 },
	dragonfruitdrake = { 2, 512, 0 },
	cybershiba = { 2, 768, 0 },
	maestromeatball = { 2, 0, 200 },
	galacticat = { 2, 256, 200 },
	overlordonion = { 2, 512, 200 },
	goldengoose = { 2, 768, 200 },
	omegatoaster = { 2, 0, 400 },
	cardzero = { 2, 256, 400 },
	pumpking = { 2, 512, 400 },
	countspudula = { 2, 768, 400 },
	ghostini = { 2, 0, 600 },
	witchywhiskers = { 2, 256, 600 },
	skeleboi = { 2, 512, 600 },
	hollowcard = { 2, 768, 600 },
	frostbitefred = { 2, 0, 800 },
	jinglejelly = { 2, 256, 800 },
	snowmancer = { 2, 512, 800 },
	polarpudding = { 2, 768, 800 },
	petalpup = { 3, 0, 0 },
	bunnybun = { 3, 256, 0 },
	bloomlord = { 3, 512, 0 },
	surfslug = { 3, 768, 0 },
	sunnysundae = { 3, 0, 200 },
	lavalamp = { 3, 256, 200 },
}

ImageAtlas.Icons = {
	rebirth = { 1, 0, 0 },
	book = { 1, 256, 0 },
	basket = { 1, 512, 0 },
	ticket = { 1, 768, 0 },
	gift = { 1, 0, 256 },
	cardpack = { 1, 256, 256 },
	crate = { 1, 512, 256 },
	cash = { 1, 768, 256 },
	cashpile = { 1, 0, 512 },
	clover = { 1, 256, 512 },
	bolt = { 1, 512, 512 },
	house = { 1, 768, 512 },
	arrowup = { 1, 0, 768 },
	snowflake = { 1, 256, 768 },
	flask = { 1, 512, 768 },
	calendar = { 1, 768, 768 },
	people = { 2, 0, 0 },
	crown = { 2, 256, 0 },
	clock = { 2, 512, 0 },
	magnet = { 2, 768, 0 },
	cards = { 2, 0, 256 },
	treadmill = { 2, 256, 256 },
	cases = { 2, 512, 256 },
	plus = { 2, 768, 256 },
	trophy = { 2, 0, 512 },
}

return ImageAtlas
