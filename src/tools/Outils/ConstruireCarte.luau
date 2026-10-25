-- ConstruireCarte (ModuleScript dans ServerStorage > Outils)
-- Construit UNE FOIS la carte du jeu (sans décors) dans Workspace > LaunchMap :
-- sol du lobby, mer, barrières magiques, plateforme de tir, piste et zones, stands (Codes, Chaudron,
-- portail World 2), Trait Master, TOP THROWS, tableaux de classement, portail du bout de la piste, zone World 2.
-- Les scripts du jeu retrouvent ces objets par leur nom ou leur tag (ils ne construisent plus rien).
-- Pour reconstruire la carte : supprimer Workspace > LaunchMap, puis demander à Claude de relancer ce module.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, "Barriers")
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, "Eggs")
PhysicsService:CollisionGroupSetCollidable("Barriers", "Eggs", false)
local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))

local ZONE_WIDTH = 160
local EGG_RADIUS = 2   -- l'œuf fait 4 studs de large (un joueur fait environ 5 studs de haut)
local EGG_SCALE = 1.6  -- taille du modèle Blender de l'œuf (1.6 = environ la taille du joueur)
local TEE_HEIGHT = 1   -- le petit socle sur lequel l'œuf attend le coup de pied
local LAUNCH_POINT = Vector3.new(0, TEE_HEIGHT + EGG_RADIUS, 0) -- d'où part l'œuf ; les distances se comptent depuis x = 0
local PLATFORM_TOP = 0.3 -- hauteur du dessus de la plateforme de tir (là où l'œuf est posé)
local BLOCKED_SPOTS_EXTRA = {}
local map = Instance.new("Folder")
map.Name = "LaunchMap"
map.Parent = workspace

-- On enlève le Baseplate du modèle de base : les zones servent de sol.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

local function makePart(name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = map
	return part
end

-- Une barrière magique : on ne peut pas la traverser, elle est presque invisible
-- et elle brille comme de l'eau quand on s'approche (le client gère la lueur, tag "Barrier")
local function makeBarrier(size, position)
	local wall = makePart("Barriere", size, position, Color3.fromRGB(110, 220, 255))
	wall.Material = Enum.Material.ForceField
	wall.Transparency = 0.3
	wall.CastShadow = false
	wall.CanQuery = false -- la caméra et les pets l'ignorent
	wall.CanTouch = false
	wall.CollisionGroup = "Barriers"
	CollectionService:AddTag(wall, "Barrier")
	return wall
end

-- 4 barrières autour d'un rectangle (center = le milieu au sol)
local function barrierBox(center, sizeX, sizeZ, height)
	height = height or 8
	makeBarrier(Vector3.new(sizeX, height, 0.6), center + Vector3.new(0, height / 2, -sizeZ / 2))
	makeBarrier(Vector3.new(sizeX, height, 0.6), center + Vector3.new(0, height / 2, sizeZ / 2))
	makeBarrier(Vector3.new(0.6, height, sizeZ), center + Vector3.new(-sizeX / 2, height / 2, 0))
	makeBarrier(Vector3.new(0.6, height, sizeZ), center + Vector3.new(sizeX / 2, height / 2, 0))
end

local function makeSign(text, position, color)
	local anchor = makePart("Panneau", Vector3.new(1, 1, 1), position, color)
	anchor.Transparency = 1
	anchor.CanCollide = false

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 60)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 2000
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = billboard
end
-- Le sol du lobby et de la zone de lancement (tout ce qui est avant x = 0)
local LOBBY_BACK = -200
makePart("SolLobby", Vector3.new(-LOBBY_BACK, 4, ZONE_WIDTH), Vector3.new(LOBBY_BACK / 2, -2, 0), Color3.fromRGB(240, 220, 160)).Material = Enum.Material.Sand

-- La mer tout autour (de l'eau de Terrain, avec des vagues)
workspace.Terrain:FillBlock(CFrame.new(800, -6, 0), Vector3.new(2600, 10, 900), Enum.Material.Water)

-- Le thème de chaque zone (il va avec l'œuf de la même rareté).
-- Ground : couleur et matière du sol. Props : les décors faits dans Blender (ServerStorage > DecorsZones).
-- Float : les décors flottent dans les airs (pour le Cosmos).
local decorRandom = Random.new(42) -- toujours le même tirage, donc la même carte à chaque partie
local decorModels = ServerStorage:FindFirstChild("DecorsZones")

-- Monde 1 "Pirate Seas" : chaque zone est un coin de la mer des pirates.
local THEMES = {
	-- Plage : palmiers, caisses et tonneaux, avec une barrière de corde
	Commune = {
		Ground = { Color = Color3.fromRGB(240, 220, 160), Material = Enum.Material.Sand },
		Props = { "Palm", "Palm", "Crates", "Barrels" },
	},
	-- Port : ancres, lampadaires et bittes d'amarrage, avec une rambarde de quai
	Rare = {
		Ground = { Color = Color3.fromRGB(150, 105, 65), Material = Enum.Material.WoodPlanks },
		Props = { "Anchor", "Lamp", "Lamp", "Bollard" },
	},
	-- Île au trésor : coffres, tas d'or et rochers-crânes, avec un muret de pierres et des torches
	Epique = {
		Ground = { Color = Color3.fromRGB(120, 175, 80), Material = Enum.Material.Grass },
		Props = { "Chest", "GoldPile", "GoldPile", "SkullRock" },
	},
	-- Bateau fantôme : mâts, lanternes vertes et canons, avec un bastingage cassé
	Legendaire = {
		Ground = { Color = Color3.fromRGB(70, 60, 75), Material = Enum.Material.WoodPlanks },
		Props = { "Mast", "Lantern", "Lantern", "Cannon" },
	},
	-- Mer du kraken : tentacules géantes, tourbillons et coraux, avec une chaîne à bouées
	Mythique = {
		Ground = { Color = Color3.fromRGB(20, 70, 95), Material = Enum.Material.Glass },
		Props = { "Tentacle", "Tentacle", "Whirlpool", "Coral" },
	},
}

-- Les bords : une barrière magique tout le long d'un côté (plus de barrières en bois)
local function placeBorder(zoneName, fromX, toX, z)
	makeBarrier(Vector3.new(toX - fromX, 100, 0.6), Vector3.new((fromX + toX) / 2, 50, z))
end
-- 2b) Le lobby et la zone de lancement --------------------------------------
-- Les décors du lobby viennent de Blender (ServerStorage > DecorsLobby).

local lobbyModels = ServerStorage:FindFirstChild("DecorsLobby")
local LOBBY_CENTER = Vector3.new(-120, 0, 0)

-- Pose un décor du lobby, tourné vers le centre du lobby (ou vers "lookAt")
local function placeLobbyProp(name, position, scale, lookAt)
	local model = lobbyModels and lobbyModels:FindFirstChild(name)
	if not model then
		return nil
	end
	local prop = model:Clone()
	if scale ~= 1 then
		prop:ScaleTo(prop:GetScale() * scale)
	end
	local direction = (lookAt or LOBBY_CENTER) - position
	prop:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.atan2(direction.X, direction.Z), 0))
	prop.Parent = map
	return prop
end

-- Un grand panneau de dessin animé qui flotte (texte orange avec un contour foncé)
local function makeBigSign(text, position, color, width, height)
	local anchor = makePart("Enseigne", Vector3.new(1, 1, 1), position, color)
	anchor.Transparency = 1
	anchor.CanCollide = false
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(width or 20, height or 5) -- en studs : le panneau grandit quand on s'approche
	billboard.LightInfluence = 0
	billboard.MaxDistance = 400
	billboard.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = billboard
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(50, 20, 10)
	stroke.Parent = label
	return billboard, label
end

-- Des crochets colorés au sol, qui montrent où se placer
local function floorPad(center, size, color)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local corner = center + Vector3.new(sx * size / 2, 0.25, sz * size / 2)
			makePart("Case", Vector3.new(3, 0.3, 0.8), corner - Vector3.new(sx * 1.1, 0, 0), color).Material = Enum.Material.Neon
			makePart("Case", Vector3.new(0.8, 0.3, 3), corner - Vector3.new(0, 0, sz * 1.1), color).Material = Enum.Material.Neon
		end
	end
end

local function neonDisc(diameter, height, position, color)
	local disc = makePart("Anneau", Vector3.new(height, diameter, diameter), position, color)
	disc.Shape = Enum.PartType.Cylinder
	disc.Orientation = Vector3.new(0, 0, 90)
	disc.Material = Enum.Material.Neon
	return disc
end
-- Rebords (barrières) tout autour du lobby
placeBorder("Commune", LOBBY_BACK, 0, -ZONE_WIDTH / 2 + 1)
placeBorder("Commune", LOBBY_BACK, 0, ZONE_WIDTH / 2 - 1)
makeBarrier(Vector3.new(0.6, 100, ZONE_WIDTH), Vector3.new(LOBBY_BACK, 50, 0))
-- devant la plateforme de tir : les joueurs restent dans le lobby (l'œuf, lui, passe)
makeBarrier(Vector3.new(0.6, 100, ZONE_WIDTH), Vector3.new(2, 50, 0))
-- Le podium des 3 meilleurs lancers : un mur rayé jaune et blanc près de la plateforme de tir,
-- tourné vers le chemin du lobby (le fond du lobby est laissé libre pour une future zone VIP)
local PODIUM_CENTER = Vector3.new(-57, 0, -58) -- le milieu du mur, au sol
local PODIUM_HEIGHT = 26
for i = 0, 6 do
	local stripe = makePart("MurPodium", Vector3.new(5, PODIUM_HEIGHT, 2), PODIUM_CENTER + Vector3.new(-15 + i * 5, PODIUM_HEIGHT / 2, 0), i % 2 == 0 and Color3.fromRGB(255, 215, 50) or Color3.new(1, 1, 1))
	stripe.CanCollide = true
end
table.insert(BLOCKED_SPOTS_EXTRA, { Position = PODIUM_CENTER, Radius = 20 }) -- pas d'haltères dans le mur
local board = makePart("Podium", Vector3.new(35, PODIUM_HEIGHT, 0.2), PODIUM_CENTER + Vector3.new(0, PODIUM_HEIGHT / 2, 1.2), Color3.new(1, 1, 1))
board.Transparency = 1
board.CanCollide = false
local boardGui = Instance.new("SurfaceGui")
boardGui.Face = Enum.NormalId.Back -- la face tournée vers le lobby (+Z)
boardGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
boardGui.PixelsPerStud = 20
boardGui.LightInfluence = 0
boardGui.Parent = board
local boardTitle = Instance.new("TextLabel")
boardTitle.Size = UDim2.fromScale(1, 0.11)
boardTitle.Position = UDim2.fromScale(0, 0.02)
boardTitle.BackgroundTransparency = 1
boardTitle.Text = "TOP THROWS"
boardTitle.TextColor3 = Color3.fromRGB(255, 150, 30)
boardTitle.TextScaled = true
boardTitle.Font = Enum.Font.FredokaOne
boardTitle.Parent = boardGui
local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 6
titleStroke.Color = Color3.fromRGB(50, 20, 10)
titleStroke.Parent = boardTitle

local podiumSlots = {} -- [rang] = { Image, Name, Score }
local SLOT_LAYOUT = {
	{ X = 0.5, Y = 0.13, Size = 0.3, Color = Color3.fromRGB(255, 200, 40) },   -- #1 au milieu, plus grand
	{ X = 0.2, Y = 0.19, Size = 0.24, Color = Color3.fromRGB(200, 210, 230) }, -- #2
	{ X = 0.8, Y = 0.19, Size = 0.24, Color = Color3.fromRGB(220, 140, 80) },  -- #3
}
for rank, layout in SLOT_LAYOUT do
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.fromScale(layout.X, layout.Y)
	holder.Size = UDim2.fromScale(layout.Size, 0.5)
	holder.BackgroundTransparency = 1
	holder.Parent = boardGui
	local circle = Instance.new("ImageLabel")
	circle.AnchorPoint = Vector2.new(0.5, 0)
	circle.Position = UDim2.fromScale(0.5, 0.1)
	circle.Size = UDim2.fromScale(0.7, 0.7)
	circle.SizeConstraint = Enum.SizeConstraint.RelativeXX
	circle.BackgroundColor3 = Color3.fromRGB(130, 190, 245) -- fond clair : les avatars foncés se voient bien
	circle.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = circle
	-- un "?" quand personne n'a encore cette place
	local unknown = Instance.new("TextLabel")
	unknown.AnchorPoint = Vector2.new(0.5, 0.5)
	unknown.Position = UDim2.fromScale(0.5, 0.5)
	unknown.Size = UDim2.fromScale(0.6, 0.6)
	unknown.BackgroundTransparency = 1
	unknown.Text = "?"
	unknown.TextColor3 = Color3.new(1, 1, 1)
	unknown.TextScaled = true
	unknown.Font = Enum.Font.FredokaOne
	unknown.Parent = circle
	local unknownStroke = Instance.new("UIStroke")
	unknownStroke.Thickness = 4
	unknownStroke.Color = Color3.fromRGB(50, 20, 10)
	unknownStroke.Parent = unknown
	local ring = Instance.new("UIStroke")
	ring.Thickness = 10
	ring.Color = layout.Color
	ring.Parent = circle
	local function label(text, y, height, color)
		local l = Instance.new("TextLabel")
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, height)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = color
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.Parent = holder
		local s = Instance.new("UIStroke")
		s.Thickness = 4
		s.Color = Color3.fromRGB(50, 20, 10)
		s.Parent = l
		return l
	end
	label("#" .. rank, 0, 0.14, layout.Color)
	podiumSlots[rank] = {
		Image = circle,
		Unknown = unknown,
		Name = label("—", 0.8, 0.1, Color3.new(1, 1, 1)),
		Score = label("", 0.9, 0.1, layout.Color),
	}
end
-- Les stands tout autour du lobby
local codesPrompt = nil -- le coffre CODES du lobby (on lui parle pour entrer un code)
local upgradePrompt = nil -- (l'ancien stand "Force +" a été enlevé : la Force se gagne avec les haltères)
do
	-- Les futurs stands (déco pour l'instant)
	-- (la roue de la chance décorative a été enlevée : elle faisait classer le jeu "16+")


	-- autour de la place d'apparition (x = -75), pour que les nouveaux joueurs les voient tout de suite
	local plaza = Vector3.new(-75, 0, 0)
	local codesChest = placeLobbyProp("Coffre", Vector3.new(-98, 0, 16), 1.4, plaza)
	makeBigSign("CODES\nFree rewards!", Vector3.new(-98, 12, 16), Color3.fromRGB(255, 150, 30), 14, 6)
	if codesChest then
		codesPrompt = Instance.new("ProximityPrompt")
		codesPrompt.ActionText = "Enter Code"
		codesPrompt.ObjectText = "Codes"
		codesPrompt.HoldDuration = 0
		codesPrompt.MaxActivationDistance = 16
		codesPrompt.RequiresLineOfSight = false
		codesPrompt.Parent = codesChest.PrimaryPart or codesChest:FindFirstChildWhichIsA("BasePart", true)
	end
	floorPad(Vector3.new(-88, 0, 16), 10, Color3.fromRGB(255, 80, 200))

	placeLobbyProp("Chaudron", Vector3.new(-128, 0, -4), 1.4, plaza)
	makeBigSign("MAGIC CAULDRON\nComing soon!", Vector3.new(-128, 14, -4), Color3.fromRGB(255, 80, 200), 22, 7)
	floorPad(Vector3.new(-117, 0, -4), 10, Color3.fromRGB(255, 80, 200))

	-- Le portail du Monde 2 (fermé avec un cadenas), rose comme celui de la barre
	local lobbyPortal = placeLobbyProp("Portail", Vector3.new(-160, 0, 66), 1.4)
	if lobbyPortal then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EntreeMonde2"
		prompt.ActionText = "Enter World 2"
		prompt.ObjectText = "Portal"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.Parent = lobbyPortal.PrimaryPart or lobbyPortal:FindFirstChildWhichIsA("BasePart")
		CollectionService:AddTag(prompt, "World2Prompt")
	end
	makeBigSign("WORLD 2\n🔒 Coming soon!", Vector3.new(-160, 26, 66), Color3.fromRGB(255, 90, 220), 18, 7)
end
-- Le Trait Master : un vieux magicien pirate en style cube, qui donne des traits aux pets
do
	local base = Config.TraitMasterPosition
	local FACING = 90 -- il regarde vers +X (la place où les joueurs apparaissent)
	local facing = CFrame.new(base) * CFrame.Angles(0, math.rad(FACING), 0)
	local SKIN = Color3.fromRGB(255, 220, 180)
	local ROBE = Color3.fromRGB(110, 60, 190)
	local WHITE = Color3.fromRGB(245, 245, 250)
	local GOLD = Color3.fromRGB(255, 200, 60)
	local npc = Instance.new("Model")
	npc.Name = "TraitMaster"
	npc.Parent = map
	-- un morceau du personnage (offset = position par rapport à ses pieds ; il regarde vers +Z, le centre du lobby)
	local function piece(name, size, offset, color, material)
		local part = makePart(name, size, base, color)
		part.CFrame = facing * CFrame.new(offset)
		part.Material = material or Enum.Material.SmoothPlastic
		part.Parent = npc
		return part
	end
	local podium = piece("Socle", Vector3.new(1.2, 8, 8), Vector3.new(0, 0.6, 0), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
	podium.Shape = Enum.PartType.Cylinder
	podium.Orientation = Vector3.new(0, 0, 90)
	local ring = piece("Anneau", Vector3.new(0.3, 8.4, 8.4), Vector3.new(0, 1.1, 0), Color3.fromRGB(80, 230, 220), Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.Orientation = Vector3.new(0, 0, 90)
	for _, side in { -1, 1 } do
		piece("Jambe", Vector3.new(0.9, 1.2, 0.9), Vector3.new(side * 0.7, 1.8, 0), Color3.fromRGB(40, 30, 60))
		piece("Bras", Vector3.new(0.9, 2, 0.9), Vector3.new(side * 1.95, 3.9, 0), ROBE)
		piece("Main", Vector3.new(0.8, 0.8, 0.8), Vector3.new(side * 1.95, 2.7, 0.1), SKIN)
		piece("Oeil", Vector3.new(0.6, 0.9, 0.1), Vector3.new(side * 0.8, 7.2, 2.02), Color3.fromRGB(25, 20, 30))
		piece("Reflet", Vector3.new(0.22, 0.22, 0.1), Vector3.new(side * 0.8 - 0.12, 7.45, 2.08), WHITE)
		piece("Joue", Vector3.new(0.6, 0.25, 0.1), Vector3.new(side * 1.35, 6.55, 2.02), Color3.fromRGB(255, 150, 170))
	end
	piece("Robe", Vector3.new(3, 2.6, 2.4), Vector3.new(0, 3.7, 0), ROBE)
	piece("Ceinture", Vector3.new(3.1, 0.4, 2.5), Vector3.new(0, 3, 0), GOLD, Enum.Material.Metal)
	piece("Tete", Vector3.new(4, 4, 4), Vector3.new(0, 6.9, 0), SKIN)
	piece("Barbe", Vector3.new(2.6, 1.6, 0.7), Vector3.new(0, 5.4, 2), WHITE)
	piece("Moustache", Vector3.new(1.8, 0.4, 0.3), Vector3.new(0, 6.2, 2.15), WHITE)
	piece("Bord", Vector3.new(5, 0.4, 5), Vector3.new(0, 9.1, 0), Color3.fromRGB(30, 30, 70))
	piece("Chapeau", Vector3.new(3, 1.8, 3), Vector3.new(0, 10.2, 0), Color3.fromRGB(30, 30, 70))
	piece("Ruban", Vector3.new(3.1, 0.4, 3.1), Vector3.new(0, 9.5, 0), GOLD, Enum.Material.Metal)
	piece("Etoile", Vector3.new(0.7, 0.7, 0.2), Vector3.new(0, 10.3, 1.55), GOLD, Enum.Material.Neon).Orientation = Vector3.new(0, FACING, 45)
	local staff = piece("Baton", Vector3.new(7, 0.35, 0.35), Vector3.new(2.7, 4.6, 0.4), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
	staff.Orientation = Vector3.new(0, 0, 90)
	local orb = piece("Orbe", Vector3.new(1.5, 1.5, 1.5), Vector3.new(2.7, 8.6, 0.4), Color3.fromRGB(80, 230, 220), Enum.Material.Neon)
	orb.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = orb.Color
	light.Range = 14
	light.Brightness = 2
	light.Parent = orb

	makeBigSign("TRAIT MASTER\nGive your pets powers!", base + Vector3.new(0, 15, 0), Color3.fromRGB(80, 230, 220), 18, 6)
	floorPad((facing * CFrame.new(0, 0, 9)).Position, 10, Color3.fromRGB(80, 230, 220))

	-- "E" pour parler au Trait Master
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Traits"
	prompt.ObjectText = "Trait Master"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = npc:FindFirstChild("Robe")
	CollectionService:AddTag(prompt, "TraitMasterPrompt")
end
-- Les panneaux de classement du lobby (Top Distance, Top Strength, Top Pets), mis à jour tout seuls
local leaderboards = {} -- { Rows = { TextLabel... }, Value = function(data) }
do
	local BOARDS = {
		{ Title = "TOP DISTANCE", X = -146, Color = Color3.fromRGB(90, 200, 255), Unit = " studs" },
		{ Title = "TOP STRENGTH", X = -122, Color = Color3.fromRGB(255, 200, 60), Unit = "" },
		{ Title = "TOP PETS", X = -98, Color = Color3.fromRGB(80, 230, 140), Unit = " pets" },
	}
	for _, info in BOARDS do
		local z = 28
		for _, side in { -1, 1 } do
			local post = makePart("PoteauTableau", Vector3.new(1, 6, 1), Vector3.new(info.X + side * 6, 3, z), Color3.fromRGB(110, 70, 40))
			post.Material = Enum.Material.Wood
		end
		local board = makePart("Tableau", Vector3.new(14, 15, 0.8), Vector3.new(info.X, 11, z), Color3.fromRGB(40, 30, 25))
		board.Material = Enum.Material.Wood
		local trim = makePart("CadreTableau", Vector3.new(14.6, 15.6, 0.6), Vector3.new(info.X, 11, z + 0.15), Color3.fromRGB(255, 200, 60))
		trim.Material = Enum.Material.Metal
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front -- tourné vers le centre du lobby
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 25
		gui.LightInfluence = 0
		gui.Parent = board
		local background = Instance.new("Frame")
		background.Size = UDim2.fromScale(1, 1)
		background.BackgroundColor3 = Color3.fromRGB(20, 30, 65)
		background.Parent = gui
		local function text(content, y, height, color)
			local label = Instance.new("TextLabel")
			label.Position = UDim2.fromScale(0.05, y)
			label.Size = UDim2.fromScale(0.9, height)
			label.BackgroundTransparency = 1
			label.Text = content
			label.TextColor3 = color
			label.TextScaled = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Font = Enum.Font.FredokaOne
			label.Parent = background
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 3
			stroke.Color = Color3.fromRGB(15, 15, 35)
			stroke.Parent = label
			return label
		end
		local title = text(info.Title, 0.03, 0.13, info.Color)
		title.TextXAlignment = Enum.TextXAlignment.Center
		title.Font = Enum.Font.LuckiestGuy
		local rows = {}
		local MEDALS = { Color3.fromRGB(255, 205, 60), Color3.fromRGB(215, 225, 240), Color3.fromRGB(230, 145, 80) }
		for rank = 1, 8 do
			table.insert(rows, text("", 0.18 + (rank - 1) * 0.1, 0.085, MEDALS[rank] or Color3.new(1, 1, 1)))
		end
		table.insert(leaderboards, { Rows = rows, Unit = info.Unit, Title = info.Title })
	end
	table.insert(BLOCKED_SPOTS_EXTRA, { Position = Vector3.new(-122, 0, 28), Radius = 34 })
	for _, spot in { Vector3.new(-142, 0, -30), Vector3.new(-120, 0, -32), Vector3.new(-160, 0, -46), Vector3.new(-62, 0, 14) } do
		table.insert(BLOCKED_SPOTS_EXTRA, { Position = spot, Radius = 7 })
	end
end
-- La zone de lancement : une plateforme en damier sable avec un bord vert lumineux
for tx = 0, 4 do
	for tz = 0, 9 do
		local color = (tx + tz) % 2 == 0 and Color3.fromRGB(240, 210, 150) or Color3.fromRGB(225, 190, 125)
		makePart("Plateforme", Vector3.new(8, 0.3, 8), Vector3.new(-36 + tx * 8, 0.15, -36 + tz * 8), color)
	end
end
local GREEN = Color3.fromRGB(70, 255, 90)
makePart("BordVert", Vector3.new(1.5, 0.5, 81.5), Vector3.new(-40.75, 0.25, 0), GREEN).Material = Enum.Material.Neon
makePart("BordVert", Vector3.new(1.5, 0.5, 81.5), Vector3.new(0.75, 0.25, 0), GREEN).Material = Enum.Material.Neon
makePart("BordVert", Vector3.new(40, 0.5, 1.5), Vector3.new(-20, 0.25, -40.75), GREEN).Material = Enum.Material.Neon
makePart("BordVert", Vector3.new(40, 0.5, 1.5), Vector3.new(-20, 0.25, 40.75), GREEN).Material = Enum.Material.Neon

-- "LANCE ICI !" qui flotte au-dessus, avec une flèche verte qui monte et descend
local throwSign, throwLabel = makeBigSign("THROW HERE!", Vector3.new(-20, 15, 0), GREEN, 30, 12)
throwLabel.Size = UDim2.fromScale(1, 0.55)
local arrow = throwLabel:Clone()
arrow.Text = "▼"
arrow.Position = UDim2.fromScale(0, 0.5)
arrow.Size = UDim2.fromScale(1, 0.5)
arrow.Parent = throwSign
-- Des bandes de couleur au sol tous les 50 m, avec la distance écrite dessus
for distance = 0, Config.Zones[#Config.Zones].Finish - 50, 50 do
	local zone = Config.GetZoneForDistance(distance)
	local color = THEMES[zone.Rarity].Ground.Color
	if (distance / 50) % 2 == 1 then
		local band = makePart("Bande", Vector3.new(50, 0.1, ZONE_WIDTH - 6), Vector3.new(distance + 25, 0.05, 0), color:Lerp(Color3.new(1, 1, 1), 0.3))
		band.Material = THEMES[zone.Rarity].Ground.Material
	end
	if distance > 0 then
		local mark = makePart("Distance", Vector3.new(30, 0.1, 10), Vector3.new(distance, 0.12, 0), Color3.new(1, 1, 1))
		mark.Transparency = 1
		mark.CanCollide = false
		mark.Orientation = Vector3.new(0, 180, 0) -- pour que le texte se lise en regardant vers les zones
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Top
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		gui.LightInfluence = 0
		gui.Parent = mark
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = tostring(distance)
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextScaled = true
		text.Font = Enum.Font.FredokaOne
		text.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 6
		stroke.Color = Color3.fromRGB(40, 40, 60)
		stroke.Parent = text
	end
end
-- Les zones, posées les unes après les autres vers +X (sol, ligne de couleur, barrières)
for index, zone in Config.Zones do
	local rarity = Config.GetRarity(zone.Rarity)
	local theme = THEMES[zone.Rarity]
	local length = zone.Finish - zone.Start
	local ground = makePart("Zone_" .. zone.Rarity, Vector3.new(length, 4, ZONE_WIDTH), Vector3.new(zone.Start + length / 2, -2, 0), theme.Ground.Color)
	ground.Material = theme.Ground.Material
	makePart("Ligne_" .. zone.Rarity, Vector3.new(3, 0.2, ZONE_WIDTH), Vector3.new(zone.Start + 1.5, 0.1, 0), rarity.Color).Material = Enum.Material.Neon
	placeBorder(zone.Rarity, zone.Start, zone.Finish, -ZONE_WIDTH / 2 + 1)
	placeBorder(zone.Rarity, zone.Start, zone.Finish, ZONE_WIDTH / 2 - 1)
	if index == #Config.Zones then
		makeBarrier(Vector3.new(0.6, 100, ZONE_WIDTH), Vector3.new(zone.Finish - 1, 50, 0))
	end
end

-- Une eau plus belle (vagues, couleur, reflets)
workspace.Terrain.WaterColor = Color3.fromRGB(40, 160, 215)
workspace.Terrain.WaterWaveSize = 0.35
workspace.Terrain.WaterWaveSpeed = 12
workspace.Terrain.WaterTransparency = 0.5
workspace.Terrain.WaterReflectance = 0.6

-- Le portail magique tout au bout de la piste ---------------------------------
-- Un grand anneau de pierre et de corail avec un tourbillon d'eau lumineux.
-- Si un œuf le traverse, le joueur débloque le monde 2 (sauvegardé pour toujours).
local PORTAL_X = Config.Zones[#Config.Zones].Finish - 15 -- juste avant la barrière du bout
local PORTAL_RADIUS = 40
local PORTAL_CENTER = Vector3.new(PORTAL_X, PORTAL_RADIUS + 4, 0)
local portalCore -- le tourbillon (pour les effets quand un œuf arrive)
do
	local portal = Instance.new("Model")
	portal.Name = "PortailMonde2"
	portal.Parent = map
	local function piece(name, size, cframe, color, material)
		local part = makePart(name, size, cframe.Position, color)
		part.CFrame = cframe
		part.Material = material or Enum.Material.Slate
		part.CanCollide = false
		part.CanQuery = false
		part.Parent = portal
		return part
	end
	local center = CFrame.new(PORTAL_CENTER)
	-- l'anneau de pierres (dans le plan YZ, tourné vers la zone de lancement)
	local STONES = 24
	for i = 0, STONES - 1 do
		local angle = i / STONES * math.pi * 2
		local spot = center * CFrame.Angles(angle, 0, 0) * CFrame.new(0, PORTAL_RADIUS, 0)
		piece("Pierre", Vector3.new(8, 7, 11.5), spot, i % 2 == 0 and Color3.fromRGB(120, 125, 140) or Color3.fromRGB(95, 100, 115))
		-- des coraux qui poussent sur l'anneau, et des pierres lumineuses
		if i % 3 == 0 then
			local coral = piece("Corail", Vector3.new(3, 6, 3), spot * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(15)), i % 2 == 0 and Color3.fromRGB(255, 120, 150) or Color3.fromRGB(255, 160, 80), Enum.Material.SmoothPlastic)
			piece("Corail", Vector3.new(2, 4, 2), coral.CFrame * CFrame.new(1.8, 1.5, 0) * CFrame.Angles(0, 0, math.rad(-35)), coral.Color, Enum.Material.SmoothPlastic)
		elseif i % 3 == 1 then
			piece("Rune", Vector3.new(8.4, 2, 2), spot * CFrame.new(0, -2.6, 0), Color3.fromRGB(90, 240, 230), Enum.Material.Neon)
		end
	end
	-- les deux gros rochers du pied
	for _, side in { -1, 1 } do
		piece("Rocher", Vector3.new(16, 12, 18), CFrame.new(PORTAL_X, 5, side * 30) * CFrame.Angles(0, 0, math.rad(side * 8)), Color3.fromRGB(85, 90, 105))
	end
	-- le tourbillon d'eau lumineux
	portalCore = piece("Tourbillon", Vector3.new(1.5, PORTAL_RADIUS * 2 - 6, PORTAL_RADIUS * 2 - 6), center, Color3.fromRGB(60, 200, 255), Enum.Material.Neon)
	portalCore.Shape = Enum.PartType.Cylinder -- un disque (son axe va vers la piste)
	portalCore.Transparency = 0.35
	local inner = piece("TourbillonCoeur", Vector3.new(2, PORTAL_RADIUS * 1.1, PORTAL_RADIUS * 1.1), center, Color3.fromRGB(200, 250, 255), Enum.Material.ForceField)
	inner.Shape = Enum.PartType.Cylinder
	-- les bras du tourbillon (le client les fait tourner)
	for arm = 0, 3 do
		for k = 1, 6 do
			local angle = arm * math.pi / 2 + k * 0.35
			local radius = k * PORTAL_RADIUS / 7
			piece("BrasTourbillon", Vector3.new(0.6, 3 + k * 0.8, 1.6), center * CFrame.Angles(angle, 0, 0) * CFrame.new(-0.6, radius, 0), Color3.fromRGB(150, 240, 255), Enum.Material.Neon).Transparency = 0.2
		end
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(80, 220, 255)
	light.Range = 60
	light.Brightness = 4
	light.Parent = portalCore
	local swirl = Instance.new("ParticleEmitter")
	swirl.Name = "Etincelles"
	swirl.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	swirl.Color = ColorSequence.new(Color3.fromRGB(120, 230, 255), Color3.new(1, 1, 1))
	swirl.LightEmission = 1
	swirl.Size = NumberSequence.new(2, 0)
	swirl.Lifetime = NumberRange.new(1.5, 2.5)
	swirl.Speed = NumberRange.new(4, 10)
	swirl.RotSpeed = NumberRange.new(-180, 180)
	swirl.SpreadAngle = Vector2.new(180, 180)
	swirl.Rate = 25
	swirl.Parent = portalCore
	makeBigSign("WORLD 2", PORTAL_CENTER + Vector3.new(0, PORTAL_RADIUS + 14, 0), Color3.fromRGB(90, 240, 230), 60, 16)
	CollectionService:AddTag(portal, "Portal")
end

-- La zone "World 2 - Coming soon" (loin du lobby), et le chemin du retour
local WORLD2_SPOT = Vector3.new(-120, 0, 300)
do
	local floor = makePart("SolMonde2", Vector3.new(70, 4, 70), WORLD2_SPOT - Vector3.new(0, 2, 0), Color3.fromRGB(150, 120, 230))
	floor.Material = Enum.Material.Cobblestone
	makeBigSign("WORLD 2\nComing soon!", WORLD2_SPOT + Vector3.new(0, 16, -20), Color3.fromRGB(255, 120, 230), 40, 12)
	for _, side in { -1, 1 } do
		makeBarrier(Vector3.new(70, 100, 0.6), WORLD2_SPOT + Vector3.new(0, 50, side * 35))
		makeBarrier(Vector3.new(0.6, 100, 70), WORLD2_SPOT + Vector3.new(side * 35, 50, 0))
	end
	-- le portail du retour
	local back = makePart("PortailRetour", Vector3.new(1, 14, 14), WORLD2_SPOT + Vector3.new(0, 7, 25), Color3.fromRGB(90, 240, 230))
	back.Shape = Enum.PartType.Cylinder
	back.Orientation = Vector3.new(0, 90, 0)
	back.Material = Enum.Material.Neon
	back.CanCollide = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Back to Lobby"
	prompt.ObjectText = "Portal"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = back
	CollectionService:AddTag(prompt, "ReturnPrompt")
end
-- On place le point d'apparition des joueurs sur le terrain de départ
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if not spawn then
	spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Parent = workspace
end
spawn.Position = Vector3.new(-75, 0.6, 0) -- sur la place ronde du lobby
spawn.Transparency = 1
spawn.CanCollide = false
for _, child in spawn:GetChildren() do
	if child:IsA("Decal") then
		child:Destroy()
	end
end
-- Des noms clairs pour que les scripts du jeu retrouvent tout
throwSign.Parent.Name = "PanneauTir"
for rank, slot in podiumSlots do
	slot.Image.Parent.Name = "Place" .. rank
	slot.Image.Name = "Photo"
	slot.Unknown.Name = "Inconnu"
	slot.Name.Name = "Nom"
	slot.Score.Name = "Score"
end
for _, info in leaderboards do
	local boardPart = info.Rows[1]:FindFirstAncestorWhichIsA("BasePart")
	boardPart:SetAttribute("Title", info.Title)
	boardPart:SetAttribute("Unit", info.Unit)
	CollectionService:AddTag(boardPart, "Leaderboard")
	for i, row in info.Rows do
		row.Name = "Ligne" .. i
	end
end
if codesPrompt then
	CollectionService:AddTag(codesPrompt, "CodesPrompt")
end
return map
