-- PetConfig (ModuleScript dans ReplicatedStorage)
-- Tous les réglages du jeu sont ici : change les chiffres pour équilibrer le jeu.

local Config = {}

-- Les 5 raretés, de la plus faible à la plus forte.
-- CoinsPerSecond : pièces gagnées chaque seconde par un pet de cette rareté.
-- PowerBonus : bonus de force de lancer (0.10 = +10 %) quand le pet est équipé.
-- Id : le nom interne (ne pas changer). Name et Pets : ce que voient les joueurs (en anglais).
-- Les pets du monde "Pirate Seas" : des animaux pirates inventés (modèles 3D dans ReplicatedStorage > PetModels).
Config.Rarities = {
	{ Id = "Commune",    Name = "Common",    Color = Color3.fromRGB(170, 170, 170), CoinsPerSecond = 1,  PowerBonus = 0.05, Pets = { "Deckhand Otter", "Crab Cook", "Parrot Lookout" } },
	{ Id = "Rare",       Name = "Rare",      Color = Color3.fromRGB(60, 140, 255),  CoinsPerSecond = 3,  PowerBonus = 0.12, Pets = { "Cutlass Cat", "Cannon Frog", "Map Owl" } },
	{ Id = "Epique",     Name = "Epic",      Color = Color3.fromRGB(170, 70, 255),  CoinsPerSecond = 8,  PowerBonus = 0.25, Pets = { "Storm Shark", "Sea Witch Octopus" } },
	{ Id = "Legendaire", Name = "Legendary", Color = Color3.fromRGB(255, 190, 30),  CoinsPerSecond = 20, PowerBonus = 0.50, Pets = { "Iron-Jaw Walrus", "Kraken Tamer Turtle" } },
	{ Id = "Mythique",   Name = "Mythic",    Color = Color3.fromRGB(255, 60, 90),   CoinsPerSecond = 50, PowerBonus = 1.00, Pets = { "Sky Whale King" } },
}

-- Les anciens pets (avant le thème pirate) deviennent un pet pirate de la même rareté,
-- pour que les sauvegardes des joueurs ne perdent rien.
Config.OldPetNames = {
	["Chick"] = "Deckhand Otter", ["Bunny"] = "Crab Cook", ["Mouse"] = "Parrot Lookout",
	["Fox"] = "Cutlass Cat", ["Penguin"] = "Cannon Frog", ["Panda"] = "Map Owl",
	["Ice Wolf"] = "Storm Shark", ["Wizard Owl"] = "Sea Witch Octopus",
	["Unicorn"] = "Iron-Jaw Walrus", ["Phoenix"] = "Kraken Tamer Turtle",
	["Cosmic Dragon"] = "Sky Whale King",
}

-- Les traits des pets ------------------------------------------------------------
-- Un pet n'a PAS de trait quand on l'obtient. Le "Trait Master" (le personnage du lobby)
-- lui en donne un au hasard (ex. "💪 Strength B"), et peut le changer (reroll), contre des "Rerolls" 📜
-- (une monnaie spéciale qu'on gagne en jouant, jamais avec des Robux).
-- Un pet ÉQUIPÉ (au plus Launch.MaxEquipped) donne : la Force de sa rareté (PowerBonus) + son trait.
-- Les bonus s'ADDITIONNENT : deux traits à +10 % donnent +20 % (x1.20).
-- Name et Text : ce que voient les joueurs (en anglais). %d = le pourcentage.
Config.Abilities = { -- les 5 sortes de traits
	Strength = { Name = "Strength", Icon = "💪", Text = "+%d%% Strength" },
	Coins    = { Name = "Coins",    Icon = "💰", Text = "+%d%% Coins per second" },
	Dumbbell = { Name = "Lifting",  Icon = "🏋️", Text = "+%d%% Strength from dumbbells" },
	Luck     = { Name = "Luck",     Icon = "🍀", Text = "+%d%% chance of rarer pets" },
	Launch   = { Name = "Distance", Icon = "🚀", Text = "+%d%% egg distance" },
}
Config.AbilityOrder = { "Strength", "Coins", "Dumbbell", "Luck", "Launch" } -- l'ordre d'affichage

-- Les niveaux de trait, du plus courant (D) au plus rare (S).
-- Chance : sur 100. Values : le bonus de chaque sorte de trait (0.10 = +10 %).
Config.TraitTiers = {
	{ Name = "D", Chance = 45, Color = Color3.fromRGB(175, 175, 185), Values = { Strength = 0.05, Coins = 0.10, Dumbbell = 0.10, Luck = 0.03, Launch = 0.05 } },
	{ Name = "C", Chance = 30, Color = Color3.fromRGB(90, 210, 90),   Values = { Strength = 0.10, Coins = 0.20, Dumbbell = 0.20, Luck = 0.06, Launch = 0.10 } },
	{ Name = "B", Chance = 16, Color = Color3.fromRGB(60, 150, 255),  Values = { Strength = 0.20, Coins = 0.40, Dumbbell = 0.40, Luck = 0.12, Launch = 0.20 } },
	{ Name = "A", Chance = 7,  Color = Color3.fromRGB(180, 80, 255),  Values = { Strength = 0.35, Coins = 0.70, Dumbbell = 0.70, Luck = 0.20, Launch = 0.35 } },
	{ Name = "S", Chance = 2,  Color = Color3.fromRGB(255, 195, 30),  Values = { Strength = 0.60, Coins = 1.20, Dumbbell = 1.20, Luck = 0.35, Launch = 0.60 } },
}

Config.TraitMasterPosition = Vector3.new(-98, 0, -22) -- où se trouve le Trait Master dans le lobby

-- Le prix (en Rerolls 📜) pour donner / changer le trait d'un pet, selon la rareté du pet
Config.RerollCost = { Commune = 1, Rare = 1, Epique = 2, Legendaire = 3, Mythique = 5 }

-- Chance (sur 100) de gagner 1 Reroll 📜 à chaque lancer, selon la zone où l'œuf tombe
Config.RerollDrops = { Commune = 5, Rare = 10, Epique = 20, Legendaire = 40, Mythique = 100 }

Config.WorldName = "PIRATE SEAS" -- le nom du monde 1 (affiché en haut de l'écran)

-- Les parties de la piste (de simples ambiances : elles ne garantissent AUCUNE rareté).
-- Start / Finish : en studs. Name : le nom affiché (anglais). Color : sa couleur sur la barre du haut.
Config.Zones = {
	{ Rarity = "Commune",    Name = "Beach",           Start = 0,    Finish = 100,  Color = Color3.fromRGB(240, 205, 120) },
	{ Rarity = "Rare",       Name = "Port",            Start = 100,  Finish = 300,  Color = Color3.fromRGB(185, 120, 65) },
	{ Rarity = "Epique",     Name = "Treasure Island", Start = 300,  Finish = 600,  Color = Color3.fromRGB(95, 185, 85) },
	{ Rarity = "Legendaire", Name = "Ghost Ship",      Start = 600,  Finish = 1000, Color = Color3.fromRGB(125, 95, 160) },
	{ Rarity = "Mythique",   Name = "Kraken Sea",      Start = 1000, Finish = 1800, Color = Color3.fromRGB(40, 130, 175) },
}

-- Les chances d'obtenir chaque rareté, selon la distance (en studs).
-- Entre deux lignes, les chances changent doucement. Chaque ligne fait 100 %.
-- Même tout près, on a une toute petite chance d'avoir un Mythic !
Config.DropChances = {
	{ Distance = 0,    Commune = 80, Rare = 15, Epique = 4,  Legendaire = 0.8, Mythique = 0.2 },
	{ Distance = 100,  Commune = 65, Rare = 25, Epique = 8,  Legendaire = 1.6, Mythique = 0.4 },
	{ Distance = 300,  Commune = 42, Rare = 35, Epique = 17, Legendaire = 4.5, Mythique = 1.5 },
	{ Distance = 600,  Commune = 22, Rare = 32, Epique = 30, Legendaire = 12,  Mythique = 4 },
	{ Distance = 1000, Commune = 9,  Rare = 22, Epique = 35, Legendaire = 23,  Mythique = 11 },
	{ Distance = 1800, Commune = 2,  Rare = 10, Epique = 28, Legendaire = 35,  Mythique = 25 },
}

-- Réglages du lancer.
Config.Launch = {
	MinPower = 0.3,      -- même avec une jauge vide, l'œuf part à 30 % de la vitesse
	Angle = 45,          -- angle de tir en degrés (45 = le plus loin)
	GaugeSpeed = 0.8,    -- vitesse de la jauge (allers-retours par seconde)
	MaxEquipped = 3,     -- nombre de pets qui donnent leur bonus de force (les 3 meilleurs)
}

-- Les animations du tir (faites dans l'Animation Editor sur le rig "KickRig", puis publiées sur Roblox).
-- Colle ici le numéro (ID) de chaque animation. Vide ("") = l'ancien coup de pied fait par script.
Config.Animations = {
	Kick = "136334914883243",    -- le coup de pied (marqueur "Impact" = le moment où l'œuf part)
	Charge = "132272107281336",  -- la jambe en arrière qui se balance pendant qu'on maintient le clic

	-- Les mouvements du personnage (R6). Vide ("") = l'animation faite par script (ReplicatedStorage > CharacterAnimator).
	-- Colle l'ID d'une animation publiée avec TON compte, et elle remplace ce mouvement (tout le monde la voit).
	Idle = "",   -- à l'arrêt
	Walk = "",   -- en marchant
	Run = "",    -- en courant (Shift / bouton RUN)
	Jump = "",   -- au saut
	Fall = "",   -- en tombant
	Climb = "",  -- en grimpant
}

-- Les haltères à ramasser dans le lobby : chacune donne des points de Force (💪).
-- Value : points gagnés. Chance : plus le nombre est grand, plus on en trouve souvent.
-- Size : taille de l'haltère. Color : couleur des disques. Glow : brille dans le noir.
Config.Dumbbells = {
	{ Name = "Petite",  Value = 1,  Chance = 50, Size = 1,   Color = Color3.fromRGB(90, 210, 90) },
	{ Name = "Moyenne", Value = 3,  Chance = 30, Size = 1.4, Color = Color3.fromRGB(60, 140, 255) },
	{ Name = "Grande",  Value = 10, Chance = 15, Size = 1.9, Color = Color3.fromRGB(170, 70, 255) },
	{ Name = "Géante",  Value = 25, Chance = 5,  Size = 2.6, Color = Color3.fromRGB(255, 190, 30), Glow = true },
	-- l'haltère magique (rare) : elle donne 1 Reroll 📜 au lieu de la Force
	{ Name = "Magique", Value = 0, Reroll = 1, Chance = 2, Size = 1.5, Color = Color3.fromRGB(80, 230, 220), Glow = true },
}
Config.DumbbellCount = 40       -- nombre d'haltères dans le lobby en même temps
-- Le pass "x2 Force" (double la Force des haltères). Mets ici le numéro (ID) de ton pass
-- créé sur le Creator Hub. Tant que c'est 0, le bouton X2 dit que le pass n'existe pas encore.
Config.X2ForcePassId = 2054057476 -- pass "x2 Strength"

-- Les potions 🧪 : elles DOUBLENT la Force donnée par les haltères pendant un moment.
-- Le joueur les garde (Inventory > onglet POTIONS) et en boit une quand il veut.
-- Boire une potion pendant qu'une autre marche AJOUTE son temps.
-- Pour l'instant, on les gagne seulement avec les CODES (voir Config.Codes plus bas).
-- Image : l'icône (dessins dans Documents\LaunchAnEgg\ICONS). Name : ce qu'on voit (anglais).
Config.Potions = {
	{ Id = "Potion5",  Name = "5 MIN",  Minutes = 5,  Image = "rbxassetid://95008284747166",  Color = Color3.fromRGB(90, 170, 255) },
	{ Id = "Potion10", Name = "10 MIN", Minutes = 10, Image = "rbxassetid://75360697836671", Color = Color3.fromRGB(170, 90, 255) },
	{ Id = "Potion20", Name = "20 MIN", Minutes = 20, Image = "rbxassetid://131263588019630",  Color = Color3.fromRGB(255, 200, 60) },
}
Config.PotionMultiplier = 2 -- x2 Force des haltères pendant la potion

-- Les CODES (le coffre "CODES" du lobby). Chaque joueur peut utiliser chaque code UNE seule fois.
-- Pour ajouter un code : copie une ligne, change le nom (en MAJUSCULES) et la récompense.
-- Récompenses possibles : Potion5 / Potion10 / Potion20 = nombre de potions, Rerolls = 💎, Coins = 💰
Config.Codes = {
	["AHOY"]   = { Potion5 = 1 },
	["PIRATE"] = { Potion10 = 1 },
	["KRAKEN"] = { Potion20 = 1 },
}

-- Les catégories (onglets) de l'inventaire, dans l'ordre. Name et Icon : ce qu'on voit (anglais).
-- Pour ajouter une catégorie : une nouvelle ligne ici (le contenu de l'onglet se fait dans GameClient,
-- dans la table "inventoryPageBuilders").
Config.InventoryCategories = {
	{ Id = "Pets",    Name = "PETS",    Icon = "🐾" },
	{ Id = "Potions", Name = "POTIONS", Icon = "🧪" },
}

function Config.GetPotion(id)
	for _, potion in Config.Potions do
		if potion.Id == id then
			return potion
		end
	end
	return nil
end

Config.BaseForce = 100          -- la Force de départ (💪) ; chaque point d'haltère ajoute +1 Force
                                -- le coup de pied utilise exactement cette Force (x la jauge)

-- Amélioration "Force +" achetée avec les pièces.
-- La progression : tous les réglages de vitesse du jeu sont ici ----------------
-- Distance d'un lancer = BaseDistance x (Force du coup de pied / BaseForce) puissance Exponent
--   BaseDistance : la distance d'un nouveau joueur, jauge pleine (en studs)
--   Exponent : plus il est petit, plus la progression ralentit quand on devient fort
--     (0.55 : quand la Force double, la distance est multipliée par environ 1,5)
-- Le trait 🚀 Distance des pets multiplie ensuite la distance.
Config.Progression = {
	BaseDistance = 110,
	Exponent = 0.55,
}

-- Amélioration "Power Up" achetée avec les pièces.
Config.Upgrade = {
	BonusPerLevel = 0.10, -- +10 % de force par niveau
	BaseCost = 50,        -- prix du niveau 1
	CostGrowth = 1.9,     -- chaque niveau coûte 1,9 fois plus cher
}

-- Les pièces : seuls les pets ÉQUIPÉS rapportent des pièces chaque seconde (CoinsPerSecond de leur rareté).

-- Fonctions utiles (utilisées par le serveur et le client) --------------------

function Config.GetRarity(id)
	for _, rarity in Config.Rarities do
		if rarity.Id == id then
			return rarity
		end
	end
	return Config.Rarities[1]
end

function Config.GetZoneForDistance(distance)
	for _, zone in Config.Zones do
		if distance < zone.Finish then
			return zone
		end
	end
	return Config.Zones[#Config.Zones] -- au-delà de la dernière zone : Mythique
end

local random = Random.new()

-- Les chances (en %) de chaque rareté pour une distance donnée.
-- luck : la Chance des pets équipés (1.25 = les raretés Rare et plus sont 25 % plus probables).
function Config.GetChances(distance, luck)
	local rows = Config.DropChances
	local before, after = rows[1], rows[#rows]
	for i = 1, #rows - 1 do
		if distance >= rows[i].Distance and distance < rows[i + 1].Distance then
			before, after = rows[i], rows[i + 1]
			break
		end
	end
	local t = 0
	if after.Distance > before.Distance then
		t = math.clamp((distance - before.Distance) / (after.Distance - before.Distance), 0, 1)
	end
	local weights, total = {}, 0
	for index, rarity in Config.Rarities do
		local weight = before[rarity.Id] + (after[rarity.Id] - before[rarity.Id]) * t
		if index > 1 then
			weight *= (luck or 1)
		end
		weights[rarity.Id] = weight
		total += weight
	end
	for id, weight in weights do
		weights[id] = weight / total * 100
	end
	return weights
end

-- Tire une rareté au hasard avec ces chances
function Config.RollRarity(chances)
	local roll = random:NextNumber(0, 100)
	for _, rarity in Config.Rarities do
		local chance = chances[rarity.Id] or 0
		if roll < chance then
			return rarity.Id
		end
		roll -= chance
	end
	return Config.Rarities[1].Id
end

function Config.RandomPet(rarityId)
	local pets = Config.GetRarity(rarityId).Pets
	return pets[random:NextInteger(1, #pets)]
end

-- Toutes les infos d'un pet : Name, Rarity (Id), RarityIndex (1 à 5)
local petIndex = nil
function Config.GetPet(petName)
	if not petIndex then
		petIndex = {}
		for index, rarity in Config.Rarities do
			for _, name in rarity.Pets do
				petIndex[name] = { Name = name, Rarity = rarity.Id, RarityIndex = index }
			end
		end
	end
	return petIndex[petName]
end

-- Un pet avec son trait s'écrit "Nom|Trait|Niveau", ex. "Map Owl|Luck|3" ; sans trait : juste "Map Owl"
function Config.MakeKey(petName, trait, tier)
	if not trait then
		return petName
	end
	return petName .. "|" .. trait .. "|" .. tier
end

function Config.ParseKey(key)
	local name, trait, tier = string.match(key, "^(.-)|(%a+)|(%d+)$")
	if name then
		return name, trait, tonumber(tier)
	end
	return key, nil, nil -- ancien format : juste le nom du pet
end

-- Tire un trait au hasard : la sorte (au hasard) et le niveau (selon les chances)
function Config.RollTrait()
	local trait = Config.AbilityOrder[random:NextInteger(1, #Config.AbilityOrder)]
	local total = 0
	for _, tier in Config.TraitTiers do
		total += tier.Chance
	end
	local roll = random:NextNumber(0, total)
	for index, tier in Config.TraitTiers do
		if roll < tier.Chance then
			return trait, index
		end
		roll -= tier.Chance
	end
	return trait, 1
end

function Config.TraitValue(trait, tier)
	local info = Config.TraitTiers[tier or 0]
	return info and info.Values[trait] or 0
end

-- La phrase d'un trait, ex. "+20% Strength"
function Config.TraitText(trait, tier)
	local ability = Config.Abilities[trait]
	if not ability then
		return ""
	end
	return string.format(ability.Text, math.round(Config.TraitValue(trait, tier) * 100))
end

-- Les bonus de tous les pets équipés (liste de "Nom|Trait|Niveau"), en multiplicateurs (1 = pas de bonus)
function Config.GetBonuses(equippedKeys)
	local bonuses = { Strength = 1, Coins = 1, Dumbbell = 1, Luck = 1, Launch = 1 }
	for _, key in equippedKeys or {} do
		local petName, trait, tier = Config.ParseKey(key)
		local pet = Config.GetPet(petName)
		if pet then
			bonuses.Strength += Config.GetRarity(pet.Rarity).PowerBonus
			if trait and bonuses[trait] then
				bonuses[trait] += Config.TraitValue(trait, tier)
			end
		end
	end
	return bonuses
end

-- Une note pour classer les pets (bouton "Equip Best") : la rareté d'abord, puis le niveau du trait
function Config.PetScore(key)
	local petName, trait, tier = Config.ParseKey(key)
	local pet = Config.GetPet(petName)
	if not pet then
		return 0
	end
	return pet.RarityIndex * 100 + (tier or 0) * 10 + (trait == "Strength" and 5 or 0)
end

-- La distance (en studs) d'un coup de pied avec cette Force (voir Config.Progression)
function Config.DistanceForForce(force)
	local settings = Config.Progression
	return settings.BaseDistance * (math.max(force, 1) / Config.BaseForce) ^ settings.Exponent
end

function Config.UpgradeCost(level)
	return math.floor(Config.Upgrade.BaseCost * Config.Upgrade.CostGrowth ^ level)
end

return Config
