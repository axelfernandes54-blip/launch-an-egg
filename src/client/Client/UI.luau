-- UI (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- Le cœur de l'interface : services, Remotes, style (couleurs, polices), petites fonctions pour créer
-- l'interface (boutons, textes...), mise à l'échelle de l'écran, petits messages (toast), pets en 3D,
-- et le système de fenêtres (ouvrir / fermer). Les autres modules l'utilisent tous.

local UI = {}
UI.state = nil -- les infos du joueur envoyées par le serveur (mises à jour dans Events)
UI.openWindowName = nil -- la fenêtre ouverte en ce moment
UI.uiSize = 1 -- la taille choisie dans Settings (0.7 à 1.3)
UI.inventoryDot = nil -- le point rouge "nouveau !" sur la tuile Inventory (créé dans Hud)
UI.trackedEgg = nil -- l'œuf en vol (nil quand il n'y en a pas)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local SocialService = game:GetService("SocialService")

local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local LaunchEgg = remotes:WaitForChild("LaunchEgg")
local BuyUpgrade = remotes:WaitForChild("BuyUpgrade")
local EggLaunched = remotes:WaitForChild("EggLaunched")
local EggLanded = remotes:WaitForChild("EggLanded")
local StateChanged = remotes:WaitForChild("StateChanged")
local DumbbellCollected = remotes:WaitForChild("DumbbellCollected")
local EquipPet = remotes:WaitForChild("EquipPet")
local EquipBest = remotes:WaitForChild("EquipBest")
local RerollTrait = remotes:WaitForChild("RerollTrait")
local TraitRerolled = remotes:WaitForChild("TraitRerolled")
local OpenTraits = remotes:WaitForChild("OpenTraits")
local SetUIScale = remotes:WaitForChild("SetUIScale")
local World2UnlockedRemote = remotes:WaitForChild("World2Unlocked")
local ShowMessage = remotes:WaitForChild("ShowMessage")
local UsePotion = remotes:WaitForChild("UsePotion")
local OpenCodes = remotes:WaitForChild("OpenCodes")
local RedeemCode = remotes:WaitForChild("RedeemCode")
local CRYSTAL_IMAGE = "rbxassetid://135650434228824" -- l'icône du cristal (la monnaie 💎 diamants)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Le style de l'interface (toutes les couleurs et polices sont ici) -------------

local TITLE_FONT = Enum.Font.FredokaOne -- police ronde et grasse pour les titres et boutons
local NUMBER_FONT = Enum.Font.FredokaOne -- police ronde pour les nombres et les textes
local OUTLINE = Color3.fromRGB(14, 18, 40) -- le contour foncé de tout

-- Style "blanc et contour foncé" (comme la capture de Katia du 25/10)
local Theme = {
	Panel = Color3.fromRGB(255, 255, 255),     -- blanc des fenêtres
	PanelDark = Color3.fromRGB(226, 232, 244), -- gris-bleu clair (cadres, pastilles)
	PanelLight = Color3.fromRGB(243, 246, 252), -- presque blanc (cartes)
	Pattern = Color3.fromRGB(224, 230, 243),   -- les petits motifs du fond des fenêtres
	Gold = Color3.fromRGB(255, 205, 80),       -- or
	Text = Color3.new(1, 1, 1),
	SubText = Color3.fromRGB(120, 128, 152),   -- texte gris (sans contour)
	Accent = Color3.fromRGB(40, 170, 255),     -- bleu des petits compteurs (ex. 2/4)
}

-- Les couleurs des boutons : { haut du dégradé, bas du dégradé, relief en dessous }
local ButtonStyles = {
	Gold = { Color3.fromRGB(255, 228, 110), Color3.fromRGB(245, 160, 35), Color3.fromRGB(170, 95, 20) },
	Green = { Color3.fromRGB(140, 250, 120), Color3.fromRGB(45, 190, 70), Color3.fromRGB(25, 120, 45) },
	Blue = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(45, 120, 245), Color3.fromRGB(25, 70, 170) },
	Red = { Color3.fromRGB(255, 125, 120), Color3.fromRGB(225, 50, 60), Color3.fromRGB(150, 25, 35) },
	Purple = { Color3.fromRGB(215, 140, 255), Color3.fromRGB(150, 70, 240), Color3.fromRGB(90, 35, 160) },
	Teal = { Color3.fromRGB(120, 245, 225), Color3.fromRGB(30, 185, 185), Color3.fromRGB(15, 115, 120) },
	Grey = { Color3.fromRGB(190, 195, 210), Color3.fromRGB(125, 130, 150), Color3.fromRGB(75, 80, 100) },
}

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 150)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 120)),
})

-- Petites fonctions pour créer l'interface ------------------------------------

local function make(className, props, parent)
	local object = Instance.new(className)
	for key, value in props do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function round(parent, radius)
	make("UICorner", { CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 10) }, parent)
end

-- Ajoute un contour foncé autour d'un texte
local function outlined(label, thickness, color)
	make("UIStroke", { Thickness = thickness or 3, Color = color or OUTLINE }, label)
	return label
end

-- Ajoute un contour épais autour d'un cadre ou d'un bouton
local function border(frame, thickness, color)
	return make("UIStroke", {
		Thickness = thickness or 4,
		Color = color or OUTLINE,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, frame)
end

local function gradient(frame, top, bottom, rotation)
	return make("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = rotation or 90 }, frame)
end

-- Un texte blanc avec un contour (props = les réglages en plus)
local function label(parent, props, strokeThickness)
	local text = make("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = Theme.Text,
		TextScaled = true,
		Font = NUMBER_FONT,
	}, parent)
	for key, value in props do
		text[key] = value
	end
	-- le texte gris n'a pas de contour (plus propre sur fond blanc)
	local stroke = make("UIStroke", { Thickness = strokeThickness or 2, Color = OUTLINE }, text)
	local function updateStroke()
		stroke.Enabled = text.TextColor3 ~= Theme.SubText
	end
	updateStroke()
	text:GetPropertyChangedSignal("TextColor3"):Connect(updateStroke)
	return text
end

-- Un emoji (sans contour)
local function icon(parent, emoji, props)
	local text = make("TextLabel", { BackgroundTransparency = 1, Text = emoji, TextScaled = true }, parent)
	for key, value in props or {} do
		text[key] = value
	end
	return text
end

-- Un reflet blanc en haut d'un bouton ou d'une barre (effet "brillant")
local function shine(parent, radius)
	local gloss = make("Frame", {
		Position = UDim2.new(0, 6, 0, 3),
		Size = UDim2.new(1, -12, 0.4, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
	}, parent)
	round(gloss, radius or 8)
	return gloss
end

-- Les boutons grossissent un peu au survol et s'écrasent quand on appuie
local touchOnly = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local function pressable(button)
	local scale = make("UIScale", {}, button)
	local function to(value, duration)
		TweenService:Create(scale, TweenInfo.new(duration or 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.07)
	end)
	button.MouseLeave:Connect(function()
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.9, 0.08)
	end)
	button.MouseButton1Up:Connect(function()
		to(touchOnly and 1 or 1.07)
	end)
	return scale
end

-- Un bouton en relief : une face en dégradé posée sur un socle plus foncé
local function fancyButton(parent, style, text, props)
	local colors = ButtonStyles[style]
	local button = make("TextButton", { BackgroundColor3 = colors[3], Text = "", AutoButtonColor = false }, parent)
	for key, value in props or {} do
		button[key] = value
	end
	round(button, 14)
	border(button, 3)
	local face = make("Frame", { Size = UDim2.new(1, 0, 1, -5), BackgroundColor3 = Color3.new(1, 1, 1) }, button)
	round(face, 14)
	local faceGradient = gradient(face, colors[1], colors[2])
	shine(face, 10)
	local caption = label(face, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.new(1, -16, 0.66, 0),
		Text = text,
		Font = TITLE_FONT,
	}, 2.5)
	make("UITextSizeConstraint", { MaxTextSize = 34 }, caption)
	pressable(button)
	local api = { Button = button, Label = caption }
	function api.SetStyle(newStyle)
		local c = ButtonStyles[newStyle]
		button.BackgroundColor3 = c[3]
		faceGradient.Color = ColorSequence.new(c[1], c[2])
	end
	return api
end

-- Écrit les grands nombres en court : 1 500 -> 1.5K, 2 000 000 -> 2M...
local function formatNumber(n)
	for _, unit in { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } } do
		if n >= unit[1] then
			return (string.format("%.1f", n / unit[1]):gsub("%.0$", "")) .. unit[2]
		end
	end
	return tostring(math.floor(n))
end

local function hexColor(color)
	return color:ToHex()
end

-- Un multiplicateur joli : 1.35 -> "x1.35", 2 -> "x2"
local function formatMultiplier(value)
	return "x" .. (string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", ""))
end

-- L'écran, mis à l'échelle selon sa taille (même interface sur ordinateur et téléphone) --------
-- On dessine tout pour un écran de 1280 x 760 : "gui" est agrandi ou rétréci pour remplir l'écran.

local screenGui = make("ScreenGui", {
	Name = "LaunchGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = false, -- on reste sous la barre du haut de Roblox
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))
local gui = make("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, screenGui)
local rootScale = make("UIScale", {}, gui)
local function updateScale()
	local size = screenGui.AbsoluteSize
	if size.X < 1 or size.Y < 1 then
		return
	end
	local scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.5, 1.25) * UI.uiSize
	rootScale.Scale = scale
	gui.Size = UDim2.fromScale(1 / scale, 1 / scale)
end
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
updateScale()

-- Petit message qui apparaît puis s'efface (ex. "Coming soon!") ------------------

local toastFrame = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 130),
	Size = UDim2.new(0, 0, 0, 48),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = Theme.PanelDark,
	Visible = false,
	ZIndex = 40,
}, gui)
round(toastFrame, 24)
border(toastFrame, 3, Theme.Gold)
make("UIPadding", { PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24) }, toastFrame)
local toastLabel = label(toastFrame, {
	Size = UDim2.new(0, 0, 1, 0),
	AutomaticSize = Enum.AutomaticSize.X,
	TextScaled = false,
	TextSize = 26,
	Font = TITLE_FONT,
}, 2.5)
local toastScale = make("UIScale", {}, toastFrame)
local toastVersion = 0
local function toast(text)
	toastVersion += 1
	local version = toastVersion
	toastLabel.Text = text
	toastFrame.Visible = true
	toastScale.Scale = 0.5
	TweenService:Create(toastScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(1.8, function()
		if version == toastVersion then
			toastFrame.Visible = false
		end
	end)
end
local function comingSoon()
	toast("Coming soon!")
end

-- Les données envoyées par le serveur (mises à jour dans StateChanged)

-- Les pets en 3D dans l'interface (ViewportFrame) ---------------------------------
-- La caméra tourne doucement autour du pet ("sway" = de gauche à droite, "spin" = tour complet).

local petModels = ReplicatedStorage:WaitForChild("PetModels")
local spinning = {} -- [viewport] = réglages de sa caméra
local rainbowGradients = {} -- les contours "arc-en-ciel" des pets Mythic (ils tournent)

local function aimViewport(info, angle)
	local direction = CFrame.Angles(0, angle, 0):VectorToWorldSpace(Vector3.new(0, 0.32, -1).Unit)
	info.Camera.CFrame = CFrame.lookAt(info.Center + direction * info.Distance, info.Center)
end

local function petViewport(parent, petName, props, options)
	options = options or {}
	local viewport = make("ViewportFrame", {
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 190),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-0.5, -1, -0.8),
	}, parent)
	for key, value in props do
		viewport[key] = value
	end
	local source = petModels:FindFirstChild(petName)
	if not source then
		return viewport
	end
	local model = source:Clone()
	if options.Locked then
		-- une ombre noire : le pet est encore secret
		viewport.Ambient = Color3.new(0, 0, 0)
		viewport.LightColor = Color3.new(0, 0, 0)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Color = Color3.new(0, 0, 0)
				part.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	model:PivotTo(CFrame.new())
	model.Parent = viewport
	local box, size = model:GetBoundingBox()
	local viewCamera = make("Camera", { FieldOfView = 30 }, viewport)
	viewport.CurrentCamera = viewCamera
	local radius = math.max(size.X, size.Y, size.Z) * 0.6
	local info = {
		Camera = viewCamera,
		Center = box.Position,
		Distance = radius / math.tan(math.rad(15)) * (options.Zoom or 1),
		Mode = options.Mode or "sway",
		Seed = math.random() * 6,
	}
	aimViewport(info, 0)
	spinning[viewport] = info
	return viewport
end

-- Le contour d'une carte prend la couleur de la rareté (arc-en-ciel animé pour Mythic)
local function rarityStroke(stroke, rarity)
	stroke.Color = rarity.Color
	if rarity.Id == "Mythique" then
		stroke.Color = Color3.new(1, 1, 1)
		rainbowGradients[make("UIGradient", { Color = RAINBOW }, stroke)] = true
	end
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for viewport, info in spinning do
		if not viewport.Parent then
			spinning[viewport] = nil
		elseif info.Mode == "spin" then
			aimViewport(info, t * 1.2)
		elseif info.Mode == "sway" then
			aimViewport(info, math.sin(t * 1.4 + info.Seed) * 0.5)
		end
	end
	for rainbow in rainbowGradients do
		if not rainbow.Parent then
			rainbowGradients[rainbow] = nil
		else
			rainbow.Rotation = (t * 120) % 360
		end
	end
end)

-- Les fenêtres (Shop, Inventory, Collection, Leaderboard) -----------------------
-- Un fond sombre derrière, la fenêtre arrive avec un rebond, et on ferme avec X (ou en cliquant à côté).

local windows = {}
local closeWindow -- (écrite plus bas)

local dim = make("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 20,
}, gui)
dim.Activated:Connect(function()
	closeWindow()
end)

local function makeWindow(name, title, emoji, width, height)
	local frame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 14),
		Size = UDim2.new(0, width, 0, height),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Active = true, -- les clics sur la fenêtre ne passent pas à travers
		Visible = false,
		ZIndex = 21,
	}, gui)
	round(frame, 22)
	border(frame, 5)
	local scale = make("UIScale", {}, frame)

	-- le fond à petits motifs (œufs et étoiles très pâles)
	local pattern = make("Frame", { Position = UDim2.new(0, 12, 0, 12), Size = UDim2.new(1, -24, 1, -24), BackgroundTransparency = 1, ClipsDescendants = true }, frame)
	for row = 0, math.ceil(height / 46) do
		make("TextLabel", {
			Position = UDim2.new(0, row % 2 == 0 and -10 or -36, 0, row * 46),
			Size = UDim2.new(0, width + 60, 0, 30),
			BackgroundTransparency = 1,
			Text = string.rep("★      ●      ", math.ceil(width / 80) + 1),
			TextColor3 = Theme.Pattern,
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = TITLE_FONT,
		}, pattern)
	end

	-- le contenu de la fenêtre
	local content = make("Frame", {
		Position = UDim2.new(0, 22, 0, 46),
		Size = UDim2.new(1, -44, 1, -64),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, frame)

	-- le titre dans le coin en haut à gauche : une grosse icône et le nom (ex. "Pets!")
	local niceTitle = string.gsub(string.lower(title), "(%a)([%w']*)", function(first, rest)
		return string.upper(first) .. rest
	end)
	local titleBox = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -18, 0, 2),
		Size = UDim2.new(0, 0, 0, 64),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, frame)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4) }, titleBox)
	local titleIcon = make("Frame", { Size = UDim2.new(0, 64, 0, 64), BackgroundColor3 = Color3.new(1, 1, 1), Rotation = -8, LayoutOrder = 1 }, titleBox)
	round(titleIcon, 16)
	border(titleIcon, 4)
	icon(titleIcon, emoji, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78) })
	local titleText = label(titleBox, {
		Size = UDim2.new(0, 0, 0, 52),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 46,
		Text = niceTitle,
		Font = TITLE_FONT,
		LayoutOrder = 2,
	}, 4)
	make("UIPadding", { PaddingRight = UDim.new(0, 6) }, titleText)

	-- la croix rouge pour fermer, collée au coin en haut à droite
	local close = fancyButton(frame, "Red", "X", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.new(0, 62, 0, 62),
		ZIndex = 6,
	})
	close.Button.Activated:Connect(function()
		closeWindow()
	end)

	local window = { Name = name, Frame = frame, Content = content, Scale = scale, Refresh = function() end, OnOpen = nil }
	windows[name] = window
	return window
end

local function openWindow(name)
	if UI.openWindowName == name then
		closeWindow()
		return
	end
	if UI.openWindowName then
		windows[UI.openWindowName].Frame.Visible = false
	end
	UI.openWindowName = name
	local window = windows[name]
	if window.OnOpen then
		window.OnOpen()
	end
	window.Refresh(true)
	dim.Visible = true
	TweenService:Create(dim, TweenInfo.new(0.2), { BackgroundTransparency = 0.45 }):Play()
	window.Frame.Visible = true
	-- si l'écran est trop petit (téléphone + grande interface), la fenêtre rétrécit pour rester visible
	local screen = screenGui.AbsoluteSize / rootScale.Scale
	local frameSize = window.Frame.Size
	local fit = math.min(1, (screen.Y - 30) / frameSize.Y.Offset, (screen.X - 30) / frameSize.X.Offset)
	window.Scale.Scale = 0.55 * fit
	TweenService:Create(window.Scale, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit }):Play()
end

function closeWindow()
	local window = UI.openWindowName and windows[UI.openWindowName]
	UI.openWindowName = nil
	if not window then
		return
	end
	TweenService:Create(dim, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
	local shrink = TweenService:Create(window.Scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.55 })
	shrink:Play()
	shrink.Completed:Connect(function()
		if UI.openWindowName ~= window.Name then
			window.Frame.Visible = false
		end
		if not UI.openWindowName then
			dim.Visible = false
		end
	end)
end

-- Pour les tests dans Studio : mettre l'attribut "OpenWindow" de LaunchGui ouvre cette fenêtre
screenGui:GetAttributeChangedSignal("OpenWindow"):Connect(function()
	local name = screenGui:GetAttribute("OpenWindow")
	if windows[name] then
		openWindow(name)
	elseif name == "" and UI.openWindowName then
		closeWindow()
	end
end)

-- Vide un cadre (sauf ses réglages de mise en page)
local function clearChildren(parent)
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Une petite étiquette arrondie (ex. "x3", "✔")
local function badge(parent, text, color, props)
	local frame = make("Frame", { BackgroundColor3 = color, Size = UDim2.new(0, 34, 0, 24) }, parent)
	for key, value in props or {} do
		frame[key] = value
	end
	round(frame, 12)
	border(frame, 2)
	label(frame, { Size = UDim2.new(1, -6, 1, -4), Position = UDim2.new(0, 3, 0, 2), Text = text }, 1.5)
	return frame
end

-- Une pastille de bonus (ex. "💪 x1.35")
local function bonusChip(parent, abilityId, value, props)
	local ability = Config.Abilities[abilityId]
	local chip = make("Frame", { BackgroundColor3 = Theme.PanelDark, Size = UDim2.new(0, 132, 0, 34) }, parent)
	for key, val in props or {} do
		chip[key] = val
	end
	round(chip, 17)
	border(chip, 2, value > 1.001 and Theme.Gold or Color3.fromRGB(70, 90, 150))
	icon(chip, ability.Icon, { Position = UDim2.new(0, 6, 0, 3), Size = UDim2.new(0, 28, 0, 28) })
	local text = label(chip, {
		Position = UDim2.new(0, 38, 0, 5),
		Size = UDim2.new(1, -46, 1, -10),
		Text = formatMultiplier(value),
		TextColor3 = value > 1.001 and Theme.Gold or Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 1.5)
	return chip, text
end

-- Combien d'exemplaires d'un pet sont équipés
local function equippedCount(petName)
	local count = 0
	for _, name in (UI.state and UI.state.Equipped) or {} do
		if name == petName then
			count += 1
		end
	end
	return count
end

-- Une "signature" des pets : si elle n'a pas changé, inutile de reconstruire les cartes 3D
local function petsSignature()
	if not UI.state then
		return ""
	end
	local parts = {}
	for key, count in UI.state.PetCounts or {} do
		table.insert(parts, key .. "=" .. count)
	end
	table.sort(parts)
	return table.concat(parts, ",") .. "|" .. table.concat(UI.state.Equipped or {}, ",") .. "|" .. tostring(UI.state.Diamonds)
end

-- Tout ce qui est au-dessus est partagé avec les autres modules
UI.Players = Players
UI.ReplicatedStorage = ReplicatedStorage
UI.RunService = RunService
UI.TweenService = TweenService
UI.UserInputService = UserInputService
UI.MarketplaceService = MarketplaceService
UI.SocialService = SocialService
UI.Config = Config
UI.remotes = remotes
UI.LaunchEgg = LaunchEgg
UI.BuyUpgrade = BuyUpgrade
UI.EggLaunched = EggLaunched
UI.EggLanded = EggLanded
UI.StateChanged = StateChanged
UI.DumbbellCollected = DumbbellCollected
UI.EquipPet = EquipPet
UI.EquipBest = EquipBest
UI.RerollTrait = RerollTrait
UI.TraitRerolled = TraitRerolled
UI.OpenTraits = OpenTraits
UI.SetUIScale = SetUIScale
UI.World2UnlockedRemote = World2UnlockedRemote
UI.ShowMessage = ShowMessage
UI.UsePotion = UsePotion
UI.OpenCodes = OpenCodes
UI.RedeemCode = RedeemCode
UI.CRYSTAL_IMAGE = CRYSTAL_IMAGE
UI.player = player
UI.camera = camera
UI.TITLE_FONT = TITLE_FONT
UI.NUMBER_FONT = NUMBER_FONT
UI.OUTLINE = OUTLINE
UI.Theme = Theme
UI.ButtonStyles = ButtonStyles
UI.RAINBOW = RAINBOW
UI.make = make
UI.round = round
UI.outlined = outlined
UI.border = border
UI.gradient = gradient
UI.label = label
UI.icon = icon
UI.shine = shine
UI.touchOnly = touchOnly
UI.pressable = pressable
UI.fancyButton = fancyButton
UI.formatNumber = formatNumber
UI.hexColor = hexColor
UI.formatMultiplier = formatMultiplier
UI.screenGui = screenGui
UI.gui = gui
UI.rootScale = rootScale
UI.updateScale = updateScale
UI.toastFrame = toastFrame
UI.toastLabel = toastLabel
UI.toastScale = toastScale
UI.toastVersion = toastVersion
UI.toast = toast
UI.comingSoon = comingSoon
UI.petModels = petModels
UI.spinning = spinning
UI.rainbowGradients = rainbowGradients
UI.aimViewport = aimViewport
UI.petViewport = petViewport
UI.rarityStroke = rarityStroke
UI.windows = windows
UI.closeWindow = closeWindow
UI.dim = dim
UI.makeWindow = makeWindow
UI.openWindow = openWindow
UI.clearChildren = clearChildren
UI.badge = badge
UI.bonusChip = bonusChip
UI.equippedCount = equippedCount
UI.petsSignature = petsSignature
UI.currentForce = Config.BaseForce -- la Force totale (envoyée par le serveur)

return UI
