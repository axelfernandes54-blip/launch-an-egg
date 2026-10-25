-- PlayerData (ModuleScript dans ServerScriptService > Server)
-- Les données des joueurs : bonus, Force, pièces, envoi des infos au client (sendState),
-- la sauvegarde (DataStore PlayerProgress_v2), l'arrivée et le départ des joueurs, et le pass x2 Strength.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))
local Remotes = require(script.Parent.Remotes)
local LaunchEgg, BuyUpgrade, EggLaunched, EggLanded, StateChanged = Remotes.LaunchEgg, Remotes.BuyUpgrade, Remotes.EggLaunched, Remotes.EggLanded, Remotes.StateChanged
local DumbbellCollected, EquipPet, EquipBest, RerollTrait, TraitRerolled = Remotes.DumbbellCollected, Remotes.EquipPet, Remotes.EquipBest, Remotes.RerollTrait, Remotes.TraitRerolled
local OpenTraits, SetUIScale, World2Unlocked, ShowMessage = Remotes.OpenTraits, Remotes.SetUIScale, Remotes.World2Unlocked, Remotes.ShowMessage
local UsePotion, OpenCodes, RedeemCode = Remotes.UsePotion, Remotes.OpenCodes, Remotes.RedeemCode

-- 3) Les données des joueurs -------------------------------------------------

local playerData = {} -- [player] = { Coins, Diamonds, Pets, Upgrades, Best, Busy, leaderstats... }

-- Les pets équipés (au plus Config.Launch.MaxEquipped) donnent leurs bonus :
-- la Force de leur rareté + leur capacité spéciale (voir PetConfig > PetAbilities).
-- Les upgrades (achetées en diamants 💎) s'ajoutent aux bonus des pets.
local function getBonuses(data)
	local bonuses = Config.GetBonuses(data.Equipped)
	local levels = data.Upgrades or {}
	bonuses.Luck += Config.UpgradeBonus("Luck", levels.Luck)
	bonuses.Coins += Config.UpgradeBonus("Coins", levels.Coins)
	bonuses.Dumbbell += Config.UpgradeBonus("Lifting", levels.Lifting)
	-- l'Index : chaque ligne de pets complétée et réclamée donne de la Force en plus
	local claimed = 0
	for _ in data.IndexClaimed or {} do
		claimed += 1
	end
	bonuses.Strength += claimed * Config.IndexReward.StrengthPerRow
	return bonuses
end

local function getMultiplier(data)
	return (1 + Config.UpgradeBonus("Power", data.Upgrades.Power)) * getBonuses(data).Strength
end

-- La Force totale (💪) : Force de départ + haltères, multipliée par les améliorations et les pets.
-- C'est exactement elle qu'on affiche et qu'on utilise pour le coup de pied.
local function getForce(data)
	return (Config.BaseForce + data.Strength) * getMultiplier(data)
end

-- Le multiplicateur de pièces des lancers : les pets ÉQUIPÉS (leur rareté), le trait "Coins" et l'upgrade Coin Bonus.
-- (les pets ne donnent plus de pièces chaque seconde)
local function getCoinMultiplier(data)
	return getBonuses(data).Coins
end

-- Chaque pet a un trait : on le repère avec sa clé "Nom|Trait|Niveau" (voir PetConfig)
local function petKey(pet)
	return Config.MakeKey(pet.Name, pet.Trait, pet.Tier)
end

local function countOwned(data, key)
	local count = 0
	for _, pet in data.Pets do
		if petKey(pet) == key then
			count += 1
		end
	end
	return count
end

local function countEquipped(data, key)
	local count = 0
	for _, name in data.Equipped do
		if name == key then
			count += 1
		end
	end
	return count
end

-- Équipe les meilleurs pets (bouton "Equip Best", et les anciennes sauvegardes)
local function equipBest(data)
	local names = {}
	for _, pet in data.Pets do
		table.insert(names, petKey(pet))
	end
	table.sort(names, function(a, b)
		return Config.PetScore(a) > Config.PetScore(b)
	end)
	data.Equipped = {}
	for i = 1, math.min(Config.Launch.MaxEquipped, #names) do
		table.insert(data.Equipped, names[i])
	end
end

-- Garde seulement les pets équipés que le joueur possède vraiment (anti-triche, vieilles sauvegardes)
local function cleanEquipped(data, wanted)
	data.Equipped = {}
	if type(wanted) ~= "table" then
		return
	end
	for _, petName in wanted do
		if type(petName) == "string" then
			if #data.Equipped < Config.Launch.MaxEquipped and countEquipped(data, petName) < countOwned(data, petName) then
				table.insert(data.Equipped, petName)
			end
		end
	end
end

local function sendState(player)
	local data = playerData[player]
	if not data then
		return
	end

	local rarityCounts = {}
	local petCounts = {} -- ["Nom|Trait|Niveau"] = nombre (pour l'inventaire)
	local nameCounts = {} -- [nom du pet] = nombre (pour la collection)
	for _, pet in data.Pets do
		rarityCounts[pet.Rarity] = (rarityCounts[pet.Rarity] or 0) + 1
		petCounts[petKey(pet)] = (petCounts[petKey(pet)] or 0) + 1
		nameCounts[pet.Name] = (nameCounts[pet.Name] or 0) + 1
	end

	data.CoinsValue.Value = math.floor(data.Coins)
	data.BestValue.Value = data.Best

	-- Les pets équipés suivent le joueur : on les note sur le joueur (tous les clients les voient)
	player:SetAttribute("EquippedPets", table.concat(data.Equipped, ","))

	StateChanged:FireClient(player, {
		Coins = math.floor(data.Coins),
		CoinMultiplier = getCoinMultiplier(data), -- le multiplicateur de pièces des lancers
		Multiplier = getMultiplier(data),
		Strength = data.Strength,
		BaseForce = Config.BaseForce + data.Strength,
		Force = math.floor(getForce(data)),
		HasX2 = data.HasX2,
		Upgrades = data.Upgrades, -- [Id de l'upgrade] = niveau
		Best = data.Best,
		PetCount = #data.Pets,
		RarityCounts = rarityCounts,
		PetCounts = petCounts,
		NameCounts = nameCounts,
		IndexClaimed = data.IndexClaimed, -- [rareté] = true : les lignes de l'Index déjà réclamées
		Diamonds = data.Diamonds,
		UIScale = data.UIScale,
		Dimension = Config.DimensionForDistance(data.Best).Id, -- la dimension de son record (pour la barre du haut)
		UnlockedWorlds = data.UnlockedWorlds, -- [Id] = true
		Equipped = data.Equipped,
		MaxEquipped = Config.Launch.MaxEquipped,
		Bonuses = getBonuses(data),
		Potions = data.Potions, -- [Id de la potion] = nombre
		BoostTime = data.BoostTime, -- secondes de x2 Force qui restent (0 = pas de potion)
	})
end

-- La sauvegarde de la progression (DataStore) -------------------------------
-- On garde : la Force des haltères, les pièces, les diamants, les pets, le record, les upgrades et les dimensions.
-- Une sauvegarde par joueur, avec la clé "Player_<UserId>".

-- (24/10/2026 : tout le monde repart de zéro avec "PlayerProgress_v2" ;
--  les anciennes sauvegardes sont gardées dans "PlayerProgress_v1", on peut y revenir en remettant ce nom)
local progressStore = DataStoreService:GetDataStore("PlayerProgress_v2")
local SAVE_VERSION = 2 -- 2 = dimensions, diamants et upgrades (25/10/2026) ; à augmenter si on change encore la forme des données

-- Réessaie plusieurs fois si Roblox ne répond pas tout de suite
local function withRetries(action)
	local lastError
	for attempt = 1, 3 do
		local ok, result = pcall(action)
		if ok then
			return true, result
		end
		lastError = result
		if tostring(result):find("Studio access") then
			break -- dans Studio, l'accès aux sauvegardes est désactivé : inutile de réessayer
		end
		task.wait(attempt) -- on attend un peu plus à chaque essai
	end
	return false, lastError
end

-- Les pets sont rangés en "nom = nombre" pour prendre moins de place
local function packPets(pets)
	local counts = {}
	for _, pet in pets do
		local key = Config.MakeKey(pet.Name, pet.Trait, pet.Tier)
		counts[key] = (counts[key] or 0) + 1
	end
	return counts
end

local function rarityOfPet(petName)
	for _, rarity in Config.Rarities do
		if table.find(rarity.Pets, petName) then
			return rarity.Id
		end
	end
	return nil
end

local function unpackPets(counts)
	local pets = {}
	for key, count in counts or {} do
		local petName, trait, tier = Config.ParseKey(key)
		petName = Config.OldPetNames[petName] or petName -- les anciens pets deviennent des pets pirates
		local rarityId = rarityOfPet(petName)
		if rarityId then -- un pet qui n'existe plus dans le jeu est ignoré
			for _ = 1, count do
				local petTrait, petTier = trait, tier
				if not (petTrait and Config.Abilities[petTrait] and Config.TraitTiers[petTier]) then
					petTrait, petTier = nil, nil -- pas de trait (ancien pet, ou pet jamais passé chez le Trait Master)
				end
				table.insert(pets, { Name = petName, Rarity = rarityId, Trait = petTrait, Tier = petTier })
			end
		end
	end
	return pets
end

local function loadProgress(player, data)
	local ok, saved = withRetries(function()
		return progressStore:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		warn("Impossible de charger la sauvegarde de " .. player.Name .. " : " .. tostring(saved))
		return -- Loaded reste faux : on ne sauvegardera pas, pour ne pas effacer la vraie sauvegarde
	end
	if type(saved) == "table" then
		data.Coins = tonumber(saved.Coins) or 0
		data.Best = tonumber(saved.Best) or 0
		data.Strength = tonumber(saved.Strength) or 0
		data.UIScale = math.clamp(tonumber(saved.UIScale) or 1, 0.7, 1.3)
		if (tonumber(saved.Version) or 1) < 2 then
			-- ancienne sauvegarde (avant les dimensions et les diamants, 25/10/2026) :
			-- le record passe en distance de la Dimension 1, les Rerolls deviennent des diamants,
			-- le niveau de Power Up devient l'upgrade Kick Power, et le portail touché débloque le World 2
			data.Best = Config.ToDisplayDistance(data.Best, 1)
			data.Diamonds = math.floor((tonumber(saved.Rerolls) or 0) * Config.DiamondsPerOldReroll)
			data.Upgrades.Power = math.clamp(math.floor(tonumber(saved.UpgradeLevel) or 0), 0, Config.GetUpgrade("Power").MaxLevel)
			if saved.World2Unlocked == true then
				data.UnlockedWorlds[2] = true
			end
		else
			data.Diamonds = math.max(0, math.floor(tonumber(saved.Diamonds) or 0))
			if type(saved.Upgrades) == "table" then
				for _, upgrade in Config.Upgrades do
					data.Upgrades[upgrade.Id] = math.clamp(math.floor(tonumber(saved.Upgrades[upgrade.Id]) or 0), 0, upgrade.MaxLevel)
				end
			end
			-- (quelques sauvegardes du 25/10 ont "UnlockedDimensions" : c'était la même chose que les worlds)
			for _, list in { saved.UnlockedWorlds, saved.UnlockedDimensions } do
				if type(list) == "table" then
					for _, id in list do
						if tonumber(id) and Config.GetWorld(tonumber(id)) then
							data.UnlockedWorlds[tonumber(id)] = true
						end
					end
				end
			end
		end
		data.DuoKicks = math.max(0, math.floor(tonumber(saved.DuoKicks) or 0))
		if type(saved.IndexClaimed) == "table" then
			for _, rarityId in saved.IndexClaimed do
				if type(rarityId) == "string" then
					data.IndexClaimed[rarityId] = true
				end
			end
		end
		data.Pets = unpackPets(saved.Pets)
		-- les potions (les vieilles sauvegardes n'en ont pas : 0)
		local potions = type(saved.Potions) == "table" and saved.Potions or {}
		for _, potion in Config.Potions do
			data.Potions[potion.Id] = math.max(0, math.floor(tonumber(potions[potion.Id]) or 0))
		end
		data.BoostTime = math.max(0, math.floor(tonumber(saved.BoostTime) or 0))
		if type(saved.Codes) == "table" then
			for _, code in saved.Codes do
				if type(code) == "string" then
					data.Codes[code] = true
				end
			end
		end
		cleanEquipped(data, saved.Equipped)
		if #data.Equipped == 0 then
			equipBest(data) -- ancienne sauvegarde (avant les traits) : on équipe les meilleurs pets
		end
	end
	data.Loaded = true
end

local savesInProgress = 0 -- nombre de sauvegardes pas encore terminées

local function saveProgress(player, data)
	if not data.Loaded then
		return
	end
	savesInProgress += 1
	local usedCodes = {}
	for code in data.Codes do
		table.insert(usedCodes, code)
	end
	local indexClaimed = {}
	for rarityId in data.IndexClaimed do
		table.insert(indexClaimed, rarityId)
	end
	local unlocked = {}
	for id in data.UnlockedWorlds do
		table.insert(unlocked, id)
	end
	local snapshot = {
		Version = SAVE_VERSION,
		Coins = math.floor(data.Coins),
		Best = data.Best,
		Strength = data.Strength,
		Upgrades = data.Upgrades, -- [Id de l'upgrade] = niveau
		Pets = packPets(data.Pets),
		Equipped = data.Equipped, -- les pets équipés (liste de noms)
		Diamonds = data.Diamonds,
		UIScale = data.UIScale,
		UnlockedWorlds = unlocked, -- les worlds achetés (liste d'Id)
		DuoKicks = data.DuoKicks,
		IndexClaimed = indexClaimed, -- les lignes de l'Index réclamées (liste de raretés)
		Potions = data.Potions,
		BoostTime = math.floor(data.BoostTime),
		Codes = usedCodes, -- les codes déjà utilisés
	}
	local ok, problem = withRetries(function()
		return progressStore:UpdateAsync("Player_" .. player.UserId, function()
			return snapshot
		end)
	end)
	savesInProgress -= 1
	if not ok then
		warn("Impossible de sauvegarder " .. player.Name .. " : " .. tostring(problem))
	end
end

Players.PlayerAdded:Connect(function(player)
	-- Le tableau des scores en haut à droite
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Parent = leaderstats

	local bestValue = Instance.new("IntValue")
	bestValue.Name = "Best (m)"
	bestValue.Parent = leaderstats

	local data = {
		Coins = 0,
		Pets = {},
		Equipped = {}, -- les noms des pets équipés (au plus Config.Launch.MaxEquipped)
		Diamonds = 0, -- les diamants 💎 (gagnés avec les haltères) : upgrades et Trait Master
		Upgrades = { Power = 0, Magnet = 0, Luck = 0, Coins = 0, Lifting = 0 }, -- niveaux des upgrades
		UIScale = 1, -- la taille de l'interface choisie dans Settings (0.7 à 1.3)
		UnlockedWorlds = { [1] = true }, -- les worlds achetés avec des pièces au portail du lobby
		DuoKicks = 0, -- nombre de coups de pied à deux réussis
		IndexClaimed = {}, -- [rareté] = true : lignes de l'Index réclamées
		Best = 0,
		Strength = 0, -- points de Force gagnés avec les haltères (on les garde)
		Potions = { Potion5 = 0, Potion10 = 0, Potion20 = 0 }, -- les potions qu'on a (pas encore bues)
		BoostTime = 0, -- secondes de potion x2 qui restent
		Codes = {}, -- [code] = true : les codes déjà utilisés
		HasX2 = false, -- a le pass "x2 Force" ? (pas sauvegardé : on demande à Roblox à chaque fois)
		Busy = false,
		Loaded = false, -- vrai si la sauvegarde a bien été lue (sinon on ne sauvegarde pas, pour ne rien écraser)
		CoinsValue = coinsValue,
		BestValue = bestValue,
	}

	-- On charge la progression sauvegardée AVANT de laisser jouer
	loadProgress(player, data)

	-- Est-ce que le joueur a déjà acheté le pass "x2 Force" ?
	if Config.X2ForcePassId ~= 0 then
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, Config.X2ForcePassId)
		if ok and owns then
			data.HasX2 = true
		end
	end

	if not player.Parent then
		return -- le joueur est parti pendant le chargement
	end
	playerData[player] = data -- maintenant le joueur peut jouer

	-- Petit délai pour laisser le client se charger avant de lui envoyer ses infos
	task.delay(2, sendState, player)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = playerData[player]
	playerData[player] = nil
	if data then
		saveProgress(player, data)
	end
end)

-- Sauvegarde automatique toutes les 60 secondes (si le serveur plante, on perd au pire 1 minute)
task.spawn(function()
	while true do
		task.wait(60)
		for player, data in playerData do
			task.spawn(saveProgress, player, data)
		end
	end
end)

-- Quand le serveur s'arrête (fin de partie, mise à jour du jeu...), on sauvegarde tout le monde
game:BindToClose(function()
	for player, data in playerData do
		task.spawn(saveProgress, player, data)
	end
	-- on attend que TOUTES les sauvegardes soient finies (aussi celles des joueurs qui viennent de partir)
	task.wait(0.1)
	local start = os.clock()
	while savesInProgress > 0 and os.clock() - start < 25 do
		task.wait(0.1)
	end
end)

-- Quand un joueur achète le pass "x2 Force" pendant la partie
-- (on revérifie aussi si le joueur l'avait déjà, par exemple le créateur du jeu)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if passId ~= Config.X2ForcePassId or not playerData[player] then
		return
	end
	local owns = purchased
	if not owns then
		local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		owns = ok and result
	end
	if owns and playerData[player] then
		playerData[player].HasX2 = true
		sendState(player)
	end
end)

SetUIScale.OnServerEvent:Connect(function(player, value)
	local data = playerData[player]
	if data and typeof(value) == "number" and value == value then
		data.UIScale = math.clamp(math.round(value * 10) / 10, 0.7, 1.3)
	end
end)

return {
	playerData = playerData, sendState = sendState, petKey = petKey,
	getBonuses = getBonuses, getMultiplier = getMultiplier, getForce = getForce, getCoinMultiplier = getCoinMultiplier,
	countOwned = countOwned, countEquipped = countEquipped, equipBest = equipBest,
}
