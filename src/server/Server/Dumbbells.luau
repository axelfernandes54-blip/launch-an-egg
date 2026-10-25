-- Dumbbells (ModuleScript dans ServerScriptService > Server)
-- Les haltères à ramasser dans le lobby (elles donnent de la Force 💪, ou un Reroll 💎 pour la magique).

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
local Data = require(script.Parent.PlayerData)
local playerData, sendState, petKey = Data.playerData, Data.sendState, Data.petKey
local getBonuses, getMultiplier, getForce, getCoinsPerSecond = Data.getBonuses, Data.getMultiplier, Data.getForce, Data.getCoinsPerSecond
local countOwned, countEquipped, equipBest = Data.countOwned, Data.countEquipped, Data.equipBest
local MapInfo = require(script.Parent.MapInfo)
local EGG_RADIUS, EGG_SCALE, LAUNCH_POINT, PLATFORM_TOP = MapInfo.EGG_RADIUS, MapInfo.EGG_SCALE, MapInfo.LAUNCH_POINT, MapInfo.PLATFORM_TOP
local PORTAL_X, PORTAL_CENTER, WORLD2_SPOT, LOBBY_BACK = MapInfo.PORTAL_X, MapInfo.PORTAL_CENTER, MapInfo.WORLD2_SPOT, MapInfo.LOBBY_BACK
local map = MapInfo.Map

-- Les endroits sans haltères en plus de ceux de la liste plus bas (tableaux, podium...)
local BLOCKED_SPOTS_EXTRA = {
	{ Position = Vector3.new(-122, 0, 28), Radius = 34 }, -- les tableaux de classement
	{ Position = Vector3.new(-57, 0, -58), Radius = 20 }, -- le mur TOP THROWS
}

-- 6) Les haltères à ramasser dans le lobby ---------------------------------

local dumbbellFolder = Instance.new("Folder")
dumbbellFolder.Name = "Halteres"
dumbbellFolder.Parent = workspace

local dumbbellRandom = Random.new()
-- Les endroits où il ne faut pas poser d'haltère (stands, œuf géant, œufs exposés...)
local BLOCKED_SPOTS = {
	{ Position = Vector3.new(-182, 0, 0), Radius = 22 }, -- le fond du lobby : libre pour la future zone VIP
	{ Position = Vector3.new(-155, 0, -66), Radius = 7 },
	{ Position = Vector3.new(-98, 0, 16), Radius = 11 },
	{ Position = Vector3.new(-128, 0, -4), Radius = 12 },
	{ Position = Vector3.new(-160, 0, 64), Radius = 14 },
	{ Position = Config.TraitMasterPosition, Radius = 9 },
}
for _, spot in BLOCKED_SPOTS_EXTRA do
	table.insert(BLOCKED_SPOTS, spot)
end

local function randomDumbbellSpot()
	for _ = 1, 30 do
		local spot = Vector3.new(dumbbellRandom:NextNumber(LOBBY_BACK + 15, -45), 0, dumbbellRandom:NextNumber(-66, 66))
		local free = true
		for _, blocked in BLOCKED_SPOTS do
			if (spot - blocked.Position).Magnitude < blocked.Radius then
				free = false
				break
			end
		end
		if free then
			return spot
		end
	end
	return Vector3.new(-60, 0, dumbbellRandom:NextNumber(-30, 30))
end

local function pickDumbbellType()
	local total = 0
	for _, kind in Config.Dumbbells do
		total += kind.Chance
	end
	local roll = dumbbellRandom:NextNumber(0, total)
	for _, kind in Config.Dumbbells do
		if roll < kind.Chance then
			return kind
		end
		roll -= kind.Chance
	end
	return Config.Dumbbells[1]
end

-- Fabrique une haltère avec des pièces : une barre en métal et deux gros disques de chaque côté
-- Les modèles Blender des haltères (ServerStorage > DumbbellModels, un par sorte d'haltère)
local dumbbellModels = ServerStorage:FindFirstChild("DumbbellModels")

local function buildDumbbell(kind)
	local s = kind.Size
	local template = dumbbellModels and dumbbellModels:FindFirstChild(kind.Name)
	local model = template and template:Clone() or Instance.new("Model")
	model.Name = "Haltere_" .. kind.Name
	if template then
		-- le modèle Blender, à la bonne taille et centré sur (0, 0, 0)
		model:ScaleTo(model:GetScale() * s)
		model:PivotTo(CFrame.new())
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
			end
		end
		-- une petite lueur de la couleur de l'haltère (plus forte pour les haltères qui brillent)
		local light = Instance.new("PointLight")
		light.Color = kind.Color
		light.Range = 5 + 3 * s
		light.Brightness = kind.Glow and 2.5 or 0.8
		light.Parent = model:FindFirstChild("Barre") or model:FindFirstChildWhichIsA("BasePart")
	else
		-- (s'il n'y a pas de modèle Blender : l'ancienne haltère faite avec des pièces)
		local function piece(name, size, offsetX, color, material)
			local part = Instance.new("Part")
			part.Name = name
			part.Shape = Enum.PartType.Cylinder
			part.Size = size
			part.CFrame = CFrame.new(offsetX, 0, 0)
			part.Color = color
			part.Material = material
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Parent = model
			return part
		end
		local plateMaterial = kind.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
		local bar = piece("Barre", Vector3.new(3.2 * s, 0.35 * s, 0.35 * s), 0, Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
		for _, side in { -1, 1 } do
			piece("Disque", Vector3.new(0.45 * s, 1.7 * s, 1.7 * s), side * 1.05 * s, kind.Color, plateMaterial)
			piece("Disque", Vector3.new(0.35 * s, 1.25 * s, 1.25 * s), side * 1.45 * s, kind.Color:Lerp(Color3.new(1, 1, 1), 0.25), plateMaterial)
		end
		if kind.Glow then
			local light = Instance.new("PointLight")
			light.Color = kind.Color
			light.Range = 10
			light.Brightness = 2
			light.Parent = bar
		end
	end
	-- La zone invisible qu'on touche pour ramasser l'haltère
	local hitbox = Instance.new("Part")
	hitbox.Name = "Zone"
	hitbox.Size = Vector3.new(3.6 * s + 1, 2 * s + 3, 2 * s + 3)
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanQuery = false
	hitbox.Parent = model
	model.PrimaryPart = hitbox
	model:SetAttribute("Value", kind.Value)
	model:SetAttribute("Color", kind.Color)
	model:SetAttribute("Size", s)
	model:SetAttribute("Reroll", kind.Reroll or 0)
	return model
end

local spawnDumbbell

local function collectDumbbell(model, player)
	if model:GetAttribute("Collected") then
		return
	end
	local data = playerData[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (data and root) then
		return
	end
	-- On vérifie que le joueur est vraiment à côté (anti-triche)
	if (root.Position - model:GetPivot().Position).Magnitude > 12 + model:GetAttribute("Size") * 3 then
		return
	end
	model:SetAttribute("Collected", true)
	local base = model:GetAttribute("Value")
	local petBonus = getBonuses(data).Dumbbell -- trait "Lifting" des pets équipés
	local value = math.max(base, math.floor(base * petBonus + 0.5))
	if data.HasX2 then
		value *= 2 -- le pass "x2 Force" double ce que donne l'haltère
	end
	if data.BoostTime > 0 then
		value *= Config.PotionMultiplier -- une potion est active : encore x2
	end
	local rerolls = model:GetAttribute("Reroll") or 0
	if rerolls > 0 then
		value = 0 -- l'haltère magique donne un Reroll 📜 au lieu de la Force
		data.Rerolls += rerolls
	end
	data.Strength += value
	sendState(player)
	-- Tous les joueurs voient l'animation ; celui qui ramasse voit aussi "💪 +X"
	DumbbellCollected:FireAllClients(player, model, value, { Base = base, Pets = petBonus, X2 = data.HasX2, Rerolls = rerolls })
	task.delay(0.6, function()
		model:Destroy()
	end)
	-- Une nouvelle haltère apparaît ailleurs un peu plus tard
	task.delay(dumbbellRandom:NextNumber(5, 12), spawnDumbbell)
end

function spawnDumbbell()
	local kind = pickDumbbellType()
	local model = buildDumbbell(kind)
	local spot = randomDumbbellSpot()
	-- l'haltère flotte un peu au-dessus du sol (le client la fait tourner et monter/descendre)
	local home = CFrame.new(spot + Vector3.new(0, 1.2 * kind.Size + 0.5, 0)) * CFrame.Angles(0, dumbbellRandom:NextNumber(0, math.pi * 2), 0)
	model:PivotTo(home)
	model:SetAttribute("Home", home)
	model.PrimaryPart.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			collectDumbbell(model, player)
		end
	end)
	model.Parent = dumbbellFolder
end

for _ = 1, Config.DumbbellCount do
	spawnDumbbell()
end

return {}
