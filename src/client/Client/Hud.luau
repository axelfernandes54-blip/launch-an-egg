-- Hud (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- L'écran de jeu : tuiles à gauche, compteurs et boutons à droite, barre des zones en haut,
-- compteur de Force en bas, minuteur de potion et bonus des pets.

local UI = require(script.Parent.UI)
local Players, ReplicatedStorage, RunService, TweenService, UserInputService = UI.Players, UI.ReplicatedStorage, UI.RunService, UI.TweenService, UI.UserInputService
local MarketplaceService, SocialService, Config, remotes, LaunchEgg = UI.MarketplaceService, UI.SocialService, UI.Config, UI.remotes, UI.LaunchEgg
local BuyUpgrade, EggLaunched, EggLanded, StateChanged, DumbbellCollected = UI.BuyUpgrade, UI.EggLaunched, UI.EggLanded, UI.StateChanged, UI.DumbbellCollected
local EquipPet, EquipBest, RerollTrait, TraitRerolled, OpenTraits = UI.EquipPet, UI.EquipBest, UI.RerollTrait, UI.TraitRerolled, UI.OpenTraits
local SetUIScale, World2UnlockedRemote, ShowMessage, UsePotion, OpenCodes = UI.SetUIScale, UI.World2UnlockedRemote, UI.ShowMessage, UI.UsePotion, UI.OpenCodes
local RedeemCode, CRYSTAL_IMAGE, player, camera, TITLE_FONT = UI.RedeemCode, UI.CRYSTAL_IMAGE, UI.player, UI.camera, UI.TITLE_FONT
local NUMBER_FONT, OUTLINE, Theme, ButtonStyles, RAINBOW = UI.NUMBER_FONT, UI.OUTLINE, UI.Theme, UI.ButtonStyles, UI.RAINBOW
local make, round, outlined, border, gradient = UI.make, UI.round, UI.outlined, UI.border, UI.gradient
local label, icon, shine, touchOnly, pressable = UI.label, UI.icon, UI.shine, UI.touchOnly, UI.pressable
local fancyButton, formatNumber, hexColor, formatMultiplier, screenGui = UI.fancyButton, UI.formatNumber, UI.hexColor, UI.formatMultiplier, UI.screenGui
local gui, rootScale, updateScale, toastFrame, toastLabel = UI.gui, UI.rootScale, UI.updateScale, UI.toastFrame, UI.toastLabel
local toastScale, toastVersion, toast, comingSoon, petModels = UI.toastScale, UI.toastVersion, UI.toast, UI.comingSoon, UI.petModels
local spinning, rainbowGradients, aimViewport, petViewport, rarityStroke = UI.spinning, UI.rainbowGradients, UI.aimViewport, UI.petViewport, UI.rarityStroke
local windows, closeWindow, dim, makeWindow, openWindow = UI.windows, UI.closeWindow, UI.dim, UI.makeWindow, UI.openWindow
local clearChildren, badge, bonusChip, equippedCount, petsSignature = UI.clearChildren, UI.badge, UI.bonusChip, UI.equippedCount, UI.petsSignature

local buyX2, formatTime, openInventoryCategory = UI.Windows.buyX2, UI.Windows.formatTime, UI.Windows.openInventoryCategory

-- À gauche : les tuiles Quests, Claim!, Daily Login, Collection -------------------

-- Une tuile carrée : un rond de couleur avec un emoji, et son nom en dessous
local function makeTile(parent, emoji, text, color, props, onClick)
	local tile = make("TextButton", { BackgroundColor3 = Theme.PanelDark, Text = "", AutoButtonColor = false }, parent)
	for key, value in props do
		tile[key] = value
	end
	round(tile, 20)
	border(tile, 3)
	local face = make("Frame", { Size = UDim2.new(1, 0, 1, -5), BackgroundColor3 = Color3.new(1, 1, 1) }, tile)
	round(face, 20)
	gradient(face, Theme.PanelLight, Theme.Panel)
	make("UIStroke", { Thickness = 2, Color = Theme.Gold, Transparency = 0.25 }, face)
	local bubble = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 7),
		Size = UDim2.new(0.62, 0, 0.62, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Color3.new(1, 1, 1),
	}, face)
	round(bubble, UDim.new(0.5, 0))
	gradient(bubble, color:Lerp(Color3.new(1, 1, 1), 0.35), color)
	border(bubble, 2)
	if string.find(emoji, "rbxassetid") then
		make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.05, 1.05), BackgroundTransparency = 1, Image = emoji }, bubble)
	else
		icon(bubble, emoji, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.72, 0.72) })
	end
	label(tile, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 6),
		Size = UDim2.new(1, 16, 0, 26),
		Text = text,
		Font = TITLE_FONT,
	}, 3)
	-- le petit point rouge "nouveau !"
	local dot = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = ButtonStyles.Red[2],
		Visible = false,
		ZIndex = 3,
	}, tile)
	round(dot, 13)
	border(dot, 2)
	label(dot, { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), Text = "!", Font = TITLE_FONT }, 1.5)
	pressable(tile)
	tile.Activated:Connect(onClick)
	return tile, dot
end

local leftColumn = make("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 30),
	Size = UDim2.new(0, 88, 0, 4 * 88 + 3 * 22),
	BackgroundTransparency = 1,
}, gui)
local TILE_SIZE = UDim2.new(0, 88, 0, 88)
makeTile(leftColumn, "🏆", "Quests", ButtonStyles.Gold[2], { Size = TILE_SIZE }, comingSoon)
makeTile(leftColumn, "🎁", "Claim!", ButtonStyles.Green[2], { Size = TILE_SIZE, Position = UDim2.new(0, 0, 0, 110) }, comingSoon)
makeTile(leftColumn, "📅", "Daily Login", ButtonStyles.Blue[2], { Size = TILE_SIZE, Position = UDim2.new(0, 0, 0, 220) }, comingSoon)
makeTile(leftColumn, "📖", "Collection", ButtonStyles.Purple[2], { Size = TILE_SIZE, Position = UDim2.new(0, 0, 0, 330) }, function()
	openWindow("Collection")
end)

-- À droite : les compteurs, le Shop et les boutons --------------------------------

local rightColumn = make("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 14),
	Size = UDim2.new(0, 226, 0, 480),
	BackgroundTransparency = 1,
}, gui)

-- Un compteur : un rond avec l'icône, la valeur, et un bouton "+" vert
local function makeCounter(y, emoji, color, onPlus)
	local pill = make("Frame", { Position = UDim2.new(0, 18, 0, y), Size = UDim2.new(1, -18, 0, 46), BackgroundColor3 = Theme.PanelDark }, rightColumn)
	round(pill, 23)
	border(pill, 3)
	make("UIStroke", { Thickness = 2, Color = color, Transparency = 0.2 }, pill)
	local value = label(pill, {
		Position = UDim2.new(0, 34, 0, 7),
		Size = UDim2.new(1, -84, 1, -14),
		Text = "0",
	}, 2.5)
	local bubble = make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 4, 0.5, 0), Size = UDim2.new(0, 50, 0, 50), BackgroundColor3 = Color3.new(1, 1, 1) }, pill)
	round(bubble, 25)
	border(bubble, 3)
	gradient(bubble, color:Lerp(Color3.new(1, 1, 1), 0.4), color)
	if string.find(emoji, "rbxassetid") then
		make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), BackgroundTransparency = 1, Image = emoji }, bubble)
	else
		icon(bubble, emoji, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.7) })
	end
	local plus = fancyButton(rightColumn, "Green", "+", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0, y + 23),
		Size = UDim2.new(0, 42, 0, 42),
		ZIndex = 2,
	})
	plus.Button.Activated:Connect(onPlus)
	return value
end

-- En haut à droite : deux petits boutons, Friends et Settings
local function smallButton(emoji, position, onClick)
	local button = fancyButton(rightColumn, "Blue", "", { AnchorPoint = Vector2.new(1, 0), Position = position, Size = UDim2.new(0, 48, 0, 48) })
	icon(button.Button:FindFirstChildWhichIsA("Frame"), emoji, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.65, 0.65) })
	button.Button.Activated:Connect(onClick)
	return button
end
smallButton("⚙️", UDim2.new(1, 0, 0, 0), function()
	openWindow("Settings")
end)
smallButton("👥", UDim2.new(1, -58, 0, 0), function()
	-- invite des amis à rejoindre le jeu (fenêtre officielle de Roblox)
	local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	if ok and canInvite then
		SocialService:PromptGameInvite(player)
	else
		toast("Invites aren't available here")
	end
end)

local coinsValue = makeCounter(56, "💰", ButtonStyles.Gold[2], function()
	openWindow("Shop")
end)
local bestValue = makeCounter(168, "🏁", ButtonStyles.Blue[2], function()
	toast("Check the leaderboards in the lobby!")
end)

-- les diamants 💎 (upgrades et Trait Master) : on les gagne seulement avec les haltères
local rerollsValue = makeCounter(112, CRYSTAL_IMAGE, ButtonStyles.Purple[2], function()
	openWindow("Upgrades")
end)

-- le multiplicateur de pièces des lancers (pets équipés, trait Coins, upgrade), à gauche du compteur
local coinRate = label(rightColumn, {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(0, -6, 0, 79),
	Size = UDim2.new(0, 170, 0, 20),
	Text = "",
	TextColor3 = Theme.Gold,
	TextXAlignment = Enum.TextXAlignment.Right,
}, 2)

local shopButton = fancyButton(rightColumn, "Gold", "🛒 SHOP", { Position = UDim2.new(0, 0, 0, 226), Size = UDim2.new(0.5, -6, 0, 66) })
shopButton.Button.Activated:Connect(function()
	openWindow("Shop")
end)
local upgradesButton = fancyButton(rightColumn, "Blue", "⚡ UPGRADES", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 226), Size = UDim2.new(0.5, -6, 0, 66) })
upgradesButton.Button.Activated:Connect(function()
	openWindow("Upgrades")
end)

local GRID_TILE = UDim2.new(0, 104, 0, 92)
local _, dot = makeTile(rightColumn, "🎒", "Inventory", ButtonStyles.Teal[2], { Size = GRID_TILE, Position = UDim2.new(0, 0, 0, 308) }, function()
	openWindow("Inventory")
end)
UI.inventoryDot = dot
makeTile(rightColumn, "🔄", "Trade", ButtonStyles.Purple[2], { Size = GRID_TILE, Position = UDim2.new(0, 122, 0, 308) }, comingSoon)

local autoButton = fancyButton(rightColumn, "Red", "AUTO LAUNCH", { Position = UDim2.new(0, 0, 0, 420), Size = UDim2.new(1, 0, 0, 58) })
autoButton.Button.Activated:Connect(comingSoon)

-- La barre de progression des zones (en haut de l'écran) ---------------------
-- Chaque zone prend la même largeur sur la barre, même si elle est plus longue dans le jeu.

local zoneCount = #Config.Zones

-- Transforme une distance (en m) en position sur la barre (0 = début, 1 = fin)
local function distanceToBar(distance)
	for index, zone in Config.Zones do
		if distance < zone.Finish or index == zoneCount then
			local t = math.clamp((distance - zone.Start) / (zone.Finish - zone.Start), 0, 1)
			return (index - 1 + t) / zoneCount
		end
	end
	return 0
end

local progressArea = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 34),
	Size = UDim2.new(0.5, 0, 0, 34),
	BackgroundTransparency = 1,
}, gui)
make("UISizeConstraint", { MaxSize = Vector2.new(800, 34) }, progressArea)

-- Le fond de la barre (le CanvasGroup coupe les couleurs aux coins arrondis)
local bar = make("CanvasGroup", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Theme.PanelDark,
}, progressArea)
round(bar, 12)
make("UIStroke", { Thickness = 3, Color = OUTLINE }, progressArea)
round(progressArea, 12)

for index, zone in Config.Zones do
	local segment = make("Frame", {
		Position = UDim2.fromScale((index - 1) / zoneCount, 0),
		Size = UDim2.fromScale(1 / zoneCount, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, bar)
	-- un dégradé : plus clair au début de la zone, plus foncé à la fin
	make("UIGradient", {
		Color = ColorSequence.new(zone.Color:Lerp(Color3.new(1, 1, 1), 0.35), zone.Color:Lerp(Color3.new(0, 0, 0), 0.2)),
	}, segment)
	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = zone.Name,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0,
		TextSize = 18,
		Font = NUMBER_FONT,
	}, segment)
	-- petit trait blanc entre deux zones
	if index > 1 then
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale((index - 1) / zoneCount, 0),
			Size = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 2,
		}, bar)
	end
end

-- Les distances sous la barre, selon la dimension (Dimension 1 : START ... 10K ; Dimension 2 : 10K ... 100K)
local ticks = { 0 } -- (en studs réels sur la piste)
for _, zone in Config.Zones do
	table.insert(ticks, zone.Finish)
end
local tickLabels = {}
for _, distance in ticks do
	tickLabels[distance] = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(distanceToBar(distance), 0, 1, 4),
		Size = UDim2.new(0, 70, 0, 18),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0,
		TextSize = 16,
		Font = NUMBER_FONT,
	}, progressArea)
end

-- Le titre au-dessus du bout de la barre
local barTitle = make("TextLabel", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 0, -2),
	Size = UDim2.new(0, 160, 0, 24),
	BackgroundTransparency = 1,
	Text = Config.WorldName or "WORLD 1",
	TextColor3 = Theme.Gold,
	TextStrokeTransparency = 0,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextSize = 24,
	Font = TITLE_FONT,
}, progressArea)

-- Met la barre à la dimension du joueur (appelé quand les infos du serveur arrivent)
local shownDimension = nil
local function showDimension(dimensionId)
	if dimensionId == shownDimension then
		return
	end
	shownDimension = dimensionId
	local dimension = Config.GetDimension(dimensionId)
	barTitle.Text = dimension.Name
	for distance, tickLabel in tickLabels do
		local shown = Config.ToDisplayDistance(distance, dimensionId)
		tickLabel.Text = shown == 0 and "START" or formatNumber(shown)
	end
end
showDimension(1)
UI.showDimension = showDimension

-- Le portail qui tourne après la fin de la barre (la dimension suivante)
local portal = make("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, 12, 0.5, 0),
	Size = UDim2.new(0, 44, 0, 44),
	BackgroundColor3 = Color3.new(1, 1, 1),
}, progressArea)
round(portal, 22)
local portalSwirl = make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 40, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 200)),
	}),
}, portal)
local portalCore = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.45, 0.45),
	BackgroundColor3 = Color3.fromRGB(255, 200, 250),
}, portal)
round(portalCore, 10)
make("UIStroke", { Thickness = 3, Color = Color3.fromRGB(255, 120, 230) }, portal)

-- La tête du joueur (avatar) sur la barre, avec "You" au-dessus : elle avance avec l'œuf pendant le vol
local recordMarker = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.new(0, 42, 0, 42),
	BackgroundColor3 = Color3.fromRGB(40, 40, 50),
	ZIndex = 5,
}, progressArea)
round(recordMarker, 21)
make("UIStroke", { Thickness = 3, Color = Color3.fromRGB(255, 215, 60) }, recordMarker)
local headshot = make("ImageLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 5,
}, recordMarker)
round(headshot, 21)
local recordLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0, -2),
	Size = UDim2.new(0, 120, 0, 34),
	BackgroundTransparency = 1,
	Text = "You\n▼",
	TextColor3 = Color3.fromRGB(255, 215, 60),
	TextStrokeTransparency = 0,
	TextSize = 16,
	LineHeight = 0.9,
	Font = NUMBER_FONT,
	ZIndex = 5,
}, recordMarker)
task.spawn(function()
	local ok, image = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok then
		headshot.Image = image
	end
end)

-- Le petit œuf qui avance sur la barre pendant le vol
local eggMarker = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.new(0, 20, 0, 26),
	BackgroundColor3 = Color3.fromRGB(255, 245, 220),
	Visible = false,
	ZIndex = 6,
}, progressArea)
round(eggMarker, 10)
make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(25, 25, 35) }, eggMarker)
local eggDistanceLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0, -6),
	Size = UDim2.new(0, 80, 0, 20),
	BackgroundTransparency = 1,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 0,
	TextSize = 18,
	Font = NUMBER_FONT,
	ZIndex = 6,
}, eggMarker)


-- L'œuf géant du lobby tourne doucement sur lui-même (juste chez nous, ça ne charge pas le serveur)
task.spawn(function()
	local giant = workspace:WaitForChild("LaunchMap"):WaitForChild("OeufGeant", 30)
	if not giant then
		return
	end
	local base = giant:GetPivot()
	local angle = 0
	RunService.RenderStepped:Connect(function(dt)
		angle += dt * 0.6
		giant:PivotTo(base * CFrame.Angles(0, angle, 0) + Vector3.new(0, math.sin(angle * 2) * 0.8, 0))
	end)
end)

local markerProgress = 0 -- où est la tête sur la barre (0 = START, 1 = fin)
RunService.RenderStepped:Connect(function(dt)
	portalSwirl.Rotation = (portalSwirl.Rotation + 4) % 360
	eggMarker.Visible = false -- (l'ancien petit œuf : c'est maintenant notre tête qui suit l'œuf)
	if UI.trackedEgg and UI.trackedEgg.Parent then
		-- pendant le vol, la tête suit l'œuf et affiche la distance en direct
		local trackDistance = math.max(0, UI.trackedEgg.Position.X)
		markerProgress = distanceToBar(trackDistance)
		-- la barre passe à la dimension où vole l'œuf (au-delà de 10K : Dimension 2)
		local dimension = UI.flightDimension or 1
		showDimension(dimension)
		local shown = Config.ToDisplayDistance(trackDistance, dimension)
		recordLabel.Text = "You: " .. formatNumber(shown) .. " studs\n▼"
	else
		-- sinon, elle revient doucement au départ
		markerProgress += (0 - markerProgress) * math.min(1, dt * 4)
		recordLabel.Text = "You\n▼"
		showDimension(UI.state and UI.state.Dimension or 1) -- au repos : la dimension de notre record
	end
	recordMarker.Position = UDim2.fromScale(markerProgress, 0.5)
end)

-- Le compteur de Force (💪), en bas au centre -------------------------------------
-- Une barre dorée avec la Force totale, "Base" au-dessus et le bouton du pass X2 à droite.
-- Au-dessus : les bonus de l'équipe de pets (💪 x1.35, 💰 x1.15...). On clique dessus pour ouvrir l'inventaire.

local strengthWidget = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -92),
	Size = UDim2.new(0, 390, 0, 74),
	BackgroundTransparency = 1,
}, gui)
local strengthScale = make("UIScale", {}, strengthWidget)

local baseLabel = label(strengthWidget, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, -30, 0, 0),
	Size = UDim2.new(0, 220, 0, 22),
	Text = "Base: " .. Config.BaseForce,
}, 2)

-- la barre dorée en relief
local strengthPill = make("Frame", {
	Position = UDim2.new(0, 30, 0, 24),
	Size = UDim2.new(1, -122, 0, 48),
	BackgroundColor3 = ButtonStyles.Gold[3],
}, strengthWidget)
round(strengthPill, 16)
border(strengthPill, 3)
local strengthFace = make("Frame", { Size = UDim2.new(1, 0, 1, -5), BackgroundColor3 = Color3.new(1, 1, 1) }, strengthPill)
round(strengthFace, 16)
gradient(strengthFace, ButtonStyles.Gold[1], ButtonStyles.Gold[2])
shine(strengthFace, 10)
local strengthLabel = label(strengthFace, {
	Position = UDim2.new(0, 34, 0, 5),
	Size = UDim2.new(1, -44, 1, -10),
	Text = tostring(Config.BaseForce),
}, 3)

-- le gros bras, qui dépasse sur la gauche de la barre
icon(strengthWidget, "💪", { Position = UDim2.new(0, 0, 0, 14), Size = UDim2.new(0, 64, 0, 64), ZIndex = 3 })

-- le bouton du pass X2 (gris tant qu'on ne l'a pas, doré quand on l'a)
local x2Button = fancyButton(strengthWidget, "Grey", "X2", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 18),
	Size = UDim2.new(0, 80, 0, 56),
})
x2Button.Button.Activated:Connect(buyX2)
local function showX2(owned)
	x2Button.SetStyle(owned and "Gold" or "Grey")
end

-- La potion active : une petite potion avec le temps qui reste, à droite de la Force
local boostTimer = make("TextButton", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 214, 1, -96),
	Size = UDim2.new(0, 140, 0, 56),
	BackgroundColor3 = Theme.PanelDark,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
}, gui)
round(boostTimer, 18)
border(boostTimer, 3, Theme.Gold)
local boostImage = make("ImageLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 24, 0.5, -4),
	Size = UDim2.new(0, 72, 0, 72),
	BackgroundTransparency = 1,
	Image = Config.Potions[2].Image,
	ZIndex = 2,
}, boostTimer)
label(boostTimer, { Position = UDim2.new(0, 58, 0, 5), Size = UDim2.new(1, -66, 0, 20), Text = "x2 💪", Font = TITLE_FONT, TextColor3 = Theme.Gold }, 2)
local boostTimeText = label(boostTimer, { Position = UDim2.new(0, 58, 0, 26), Size = UDim2.new(1, -66, 0, 24), Text = "0:00" }, 2)
pressable(boostTimer)
boostTimer.Activated:Connect(function()
	openInventoryCategory("Potions")
end)
TweenService:Create(boostImage, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 12 }):Play()
local function updateBoostTimer()
	local left = UI.state and UI.state.BoostTime or 0
	boostTimer.Visible = left > 0
	boostTimeText.Text = formatTime(left)
end

-- les bonus de l'équipe de pets, au-dessus de la Force
local boostRow = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -172),
	Size = UDim2.new(0, 700, 0, 34),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, boostRow)

local lastBoostKey = nil
local function updateBoosts()
	local bonuses = UI.state and UI.state.Bonuses or {}
	local key = ""
	for _, abilityId in Config.AbilityOrder do
		key ..= string.format("%.3f,", bonuses[abilityId] or 1)
	end
	if key == lastBoostKey then
		return -- rien n'a changé : on ne reconstruit pas
	end
	lastBoostKey = key
	clearChildren(boostRow)
	for order, abilityId in Config.AbilityOrder do
		local value = bonuses[abilityId] or 1
		-- la Force est toujours affichée ; les autres seulement quand un pet les donne
		if abilityId == "Strength" or value > 1.001 then
			local chip = bonusChip(boostRow, abilityId, value, { LayoutOrder = order, Size = UDim2.new(0, 116, 0, 34) })
			local button = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, chip)
			button.Activated:Connect(function()
				openWindow("Inventory")
			end)
		end
	end
end
updateBoosts()



UI.Hud = {
	baseLabel = baseLabel, bestValue = bestValue, coinRate = coinRate, coinsValue = coinsValue, portal = portal,
	rerollsValue = rerollsValue, showX2 = showX2, strengthLabel = strengthLabel, strengthScale = strengthScale,
	updateBoostTimer = updateBoostTimer, updateBoosts = updateBoosts,
}

return {}
