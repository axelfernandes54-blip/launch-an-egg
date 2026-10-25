-- Écran d'entrée de Launch an Egg : titre, œuf animé, vagues, barre de chargement, astuces,
-- puis bouton PLAY -> la caméra vole au-dessus du port pirate jusqu'au joueur.
-- Tout dure 8 secondes maximum, et on peut passer avec SKIP.

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LOAD_MAX = 6 -- secondes maximum de chargement avant le bouton PLAY
local FLY_TIME = 2.6 -- durée du vol de la caméra

local NAVY = Color3.fromRGB(12, 24, 52)
local NAVY_LIGHT = Color3.fromRGB(28, 52, 98)
local GOLD = Color3.fromRGB(255, 200, 60)
local GOLD_DARK = Color3.fromRGB(150, 95, 20)

local TIPS = {
	"Hold to charge, then release in the gold zone for a PERFECT launch!",
	"Hold Shift (or tap RUN) to sprint!",
	"The farther your egg flies, the rarer the pet!",
	"Reach the Port zone for Rare pets!",
	"Your pets follow you everywhere. Collect them all!",
}

local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in props do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local function tween(obj, time, props, style)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

-- L'écran -----------------------------------------------------------------------------------------
local screen = make("ScreenGui", {
	Name = "LoadingScreen",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 1000,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)
ReplicatedFirst:RemoveDefaultLoadingScreen()

local bg = make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, screen)
local bgGradient = make("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(NAVY_LIGHT, NAVY),
}, bg)

-- Petites étoiles qui scintillent
local stars = {}
local rng = Random.new()
for i = 1, 26 do
	local star = make("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 240, 190),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(rng:NextNumber(0.02, 0.98), rng:NextNumber(0.02, 0.55)),
		Size = UDim2.fromOffset(3, 3),
	}, bg)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, star)
	stars[i] = { frame = star, phase = rng:NextNumber(0, math.pi * 2), speed = rng:NextNumber(1, 3) }
end

-- Les vagues en bas : trois rangées de bosses qui glissent
local waves = {}
local waveColors = { Color3.fromRGB(30, 70, 130), Color3.fromRGB(22, 90, 150), Color3.fromRGB(35, 120, 175) }
for row = 1, 3 do
	local strip = make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1 - (3 - row) * 0.035),
		Size = UDim2.fromScale(1.4, 0.1),
	}, bg)
	make("Frame", {
		BackgroundColor3 = waveColors[row],
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(1, 0.5),
	}, strip)
	for i = 0, 19 do
		local bump = make("Frame", {
			BackgroundColor3 = waveColors[row],
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(i / 19, 0),
			Size = UDim2.fromScale(0.1, 1),
		}, strip)
		make("UIAspectRatioConstraint", { AspectRatio = 1 }, bump)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, bump)
	end
	waves[row] = { frame = strip, speed = 0.03 + row * 0.015, offset = row * 0.1, baseY = 1 - (3 - row) * 0.035 }
end

-- Le contenu au centre (grandit/rétrécit avec l'écran : marche sur téléphone)
local content = make("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.46),
	Size = UDim2.fromScale(0.92, 0.86),
}, screen)
make("UISizeConstraint", { MaxSize = Vector2.new(820, 620) }, content)

local title = make("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.02),
	Size = UDim2.fromScale(1, 0.2),
	Font = Enum.Font.FredokaOne,
	Text = "LAUNCH AN EGG",
	TextColor3 = Color3.new(1, 1, 1),
	TextScaled = true,
}, content)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 235, 140), GOLD) }, title)
make("UIStroke", { Color = Color3.fromRGB(70, 40, 5), Thickness = 4 }, title)


-- L'œuf : un ovale crème avec des taches dorées, qui flotte et se balance
local eggHolder = make("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.3, 0.3),
}, content)
local egg = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(255, 248, 225),
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
}, eggHolder)
make("UIAspectRatioConstraint", { AspectRatio = 0.78 }, egg)
make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, egg)
make("UIGradient", {
	Rotation = 35,
	Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 210, 150)),
}, egg)
make("UIStroke", { Color = GOLD_DARK, Thickness = 4 }, egg)
for _, spot in { { 0.3, 0.3, 0.2 }, { 0.68, 0.45, 0.16 }, { 0.4, 0.7, 0.14 }, { 0.72, 0.75, 0.1 } } do
	local dot = make("Frame", {
		BackgroundColor3 = GOLD,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(spot[1], spot[2]),
		Size = UDim2.fromScale(spot[3], spot[3]),
	}, egg)
	make("UIAspectRatioConstraint", { AspectRatio = 1 }, dot)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
end
local shadow = make("Frame", {
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.7,
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.67),
	Size = UDim2.fromScale(0.16, 0.025),
}, content)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, shadow)
-- Ombre douce : plus foncée au centre, s'efface sur les bords
make("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, shadow)

-- La barre de chargement
local barBack = make("Frame", {
	BackgroundColor3 = Color3.fromRGB(8, 14, 32),
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.74),
	Size = UDim2.fromScale(0.7, 0.06),
}, content)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, barBack)
make("UIStroke", { Color = GOLD, Thickness = 3 }, barBack)
local barFill = make("Frame", {
	BackgroundColor3 = GOLD,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(0, 1),
}, barBack)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, barFill)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 235, 140), Color3.fromRGB(230, 150, 30)) }, barFill)
local barText = make("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.FredokaOne,
	Text = "LOADING... 0%",
	TextColor3 = Color3.new(1, 1, 1),
	TextScaled = true,
	ZIndex = 2,
}, barBack)
make("UIStroke", { Color = Color3.fromRGB(40, 25, 5), Thickness = 2 }, barText)
make("UIPadding", { PaddingTop = UDim.new(0.12, 0), PaddingBottom = UDim.new(0.12, 0) }, barText)

local tipLabel = make("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.83),
	Size = UDim2.fromScale(0.9, 0.06),
	Font = Enum.Font.GothamBold,
	Text = "TIP: " .. TIPS[1],
	TextColor3 = Color3.fromRGB(220, 235, 255),
	TextScaled = true,
}, content)

-- Le gros bouton PLAY (caché pendant le chargement)
local playButton = make("TextButton", {
	AutoButtonColor = true,
	BackgroundColor3 = GOLD,
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.79),
	Size = UDim2.fromScale(0.38, 0.13),
	Font = Enum.Font.FredokaOne,
	Text = "PLAY",
	TextColor3 = Color3.new(1, 1, 1),
	TextScaled = true,
	Visible = false,
	ZIndex = 3,
}, content)
make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, playButton)
make("UIStroke", { Color = Color3.fromRGB(90, 50, 5), Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, playButton)
playButton.TextStrokeColor3 = Color3.fromRGB(90, 50, 5)
playButton.TextStrokeTransparency = 0
make("UIPadding", { PaddingTop = UDim.new(0.14, 0), PaddingBottom = UDim.new(0.14, 0) }, playButton)
local playScale = make("UIScale", {}, playButton)

-- Bouton SKIP en haut à droite
local skipButton = make("TextButton", {
	BackgroundColor3 = Color3.fromRGB(8, 14, 32),
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 50),
	Size = UDim2.fromOffset(110, 40),
	Font = Enum.Font.FredokaOne,
	Text = "SKIP >>",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 22,
	ZIndex = 5,
}, screen)
make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, skipButton)
make("UIStroke", { Color = GOLD, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, skipButton)

-- On cache le HUD du jeu (LaunchGui) tant que l'écran d'entrée est là ---------------------------
local finished = false
local function hideHud(child)
	if not finished and child.Name == "LaunchGui" and child:IsA("ScreenGui") then
		child.Enabled = false
	end
end
for _, child in playerGui:GetChildren() do
	hideHud(child)
end
local hudConn = playerGui.ChildAdded:Connect(hideHud)

-- Animations (œuf, vagues, étoiles, bouton PLAY) ----------------------------------------------------
local clock = 0
local waveDrop = 0 -- quand on appuie sur PLAY, les vagues descendent hors de l'écran
local leaving = false
local animConn = RunService.RenderStepped:Connect(function(dt)
	clock += dt
	local bob = math.sin(clock * 2.2)
	egg.Position = UDim2.fromScale(0.5, 0.5 - bob * 0.06)
	egg.Rotation = math.sin(clock * 1.6) * 10
	shadow.Size = UDim2.fromScale(0.16 + bob * 0.025, 0.025)
	if leaving then
		waveDrop += dt * 0.6
	end
	for _, w in waves do
		local x = -((clock * w.speed + w.offset) % (1 / 19)) * 1.4
		w.frame.Position = UDim2.fromScale(x, w.baseY + waveDrop + math.sin(clock * 1.5 + w.offset * 10) * 0.006)
	end
	for _, s in stars do
		s.frame.BackgroundTransparency = 0.35 + 0.5 * (0.5 + 0.5 * math.sin(clock * s.speed + s.phase))
	end
	if playButton.Visible then
		playScale.Scale = 1 + math.sin(clock * 4) * 0.04
	end
end)

-- Astuces qui changent toutes les 2,5 s
task.spawn(function()
	local i = 1
	while not finished do
		task.wait(2.5)
		if finished or not tipLabel.Visible then
			break
		end
		i = i % #TIPS + 1
		tipLabel.TextTransparency = 1
		tipLabel.Text = "TIP: " .. TIPS[i]
		tween(tipLabel, 0.4, { TextTransparency = 0 })
	end
end)

-- Le chargement ---------------------------------------------------------------------------------
local loadStart = os.clock()
local realProgress = 0
local loadDone = false
task.spawn(function()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	-- On précharge les images et sons de l'interface + les animations du perso
	local assets = {}
	for _, id in { "rbxassetid://136334914883243", "rbxassetid://132272107281336" } do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		table.insert(assets, anim)
	end
	for _, item in playerGui:GetDescendants() do
		if item:IsA("ImageLabel") or item:IsA("ImageButton") then
			table.insert(assets, item)
		end
	end
	local soundFolder = game:GetService("SoundService")
	for _, item in soundFolder:GetDescendants() do
		if item:IsA("Sound") then
			table.insert(assets, item)
		end
	end
	local total, done = math.max(#assets, 1), 0
	pcall(function()
		ContentProvider:PreloadAsync(assets, function()
			done += 1
			realProgress = done / total
		end)
	end)
	realProgress = 1
	loadDone = true
end)

local skipped = false
skipButton.Activated:Connect(function()
	skipped = true
end)

-- La barre avance doucement (au moins 2 s pour qu'on voie l'écran), au plus LOAD_MAX secondes
local shown = 0
while not skipped do
	local elapsed = os.clock() - loadStart
	local target = math.min(realProgress, elapsed / 2)
	if elapsed >= LOAD_MAX then
		target = 1 -- trop long : on n'attend plus
	elseif loadDone then
		target = math.min(1, elapsed / 2)
	end
	shown += (target - shown) * 0.15
	if target >= 1 and shown > 0.985 then
		shown = 1
	end
	barFill.Size = UDim2.fromScale(shown, 1)
	barText.Text = "LOADING... " .. math.floor(shown * 100) .. "%"
	if shown >= 1 then
		break
	end
	task.wait()
end

-- Rendre la main au jeu : HUD visible, écran retiré -----------------------------------------------
local function finish()
	if finished then
		return
	end
	finished = true
	hudConn:Disconnect()
	local hud = playerGui:FindFirstChild("LaunchGui")
	if hud then
		hud.Enabled = true
	end
	local camera = workspace.CurrentCamera
	if camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
	end
	animConn:Disconnect()
	screen:Destroy()
end

local function getRoot()
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("HumanoidRootPart", 5)
end

-- Point de départ du vol : haut au-dessus du port, en regardant vers le lobby
local function portView(t)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local focus = root and root.Position or Vector3.new(-75, 3, 0)
	local angle = t * 0.08
	local pos = focus + Vector3.new(170 + math.cos(angle) * 20, 75, 70 + math.sin(angle) * 20)
	return CFrame.lookAt(pos, focus + Vector3.new(60, 0, 0))
end

if skipped then
	finish()
	return
end

-- Écran "PLAY" : le fond devient transparent et on voit le port qui tourne doucement derrière
barBack.Visible = false
tipLabel.Visible = false
tween(shadow, 0.4, { BackgroundTransparency = 1 }) -- l'ombre ferait une barre grise sur le port
playButton.Visible = true
playScale.Scale = 0.2
tween(playScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)

local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
local menuTime = 0
local menuConn = RunService.RenderStepped:Connect(function(dt)
	menuTime += dt
	workspace.CurrentCamera.CFrame = portView(menuTime)
end)
tween(bg, 0.8, { BackgroundTransparency = 0.55 })
for _, s in stars do
	s.frame.Visible = false
end

local clicked = false
playButton.Activated:Connect(function()
	clicked = true
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA) then
		clicked = true
	end
end)
repeat
	task.wait()
until clicked or skipped
menuConn:Disconnect()
if skipped then
	finish() -- SKIP : on va directement au jeu, sans le vol de caméra
	return
end
skipButton.Visible = false

-- PLAY ! L'écran disparaît, la caméra plonge en courbe jusque derrière le joueur
tween(bg, 0.5, { BackgroundTransparency = 1 })
for _, item in content:GetDescendants() do
	if item:IsA("TextLabel") or item:IsA("TextButton") then
		tween(item, 0.4, { TextTransparency = 1, TextStrokeTransparency = 1, BackgroundTransparency = 1 })
	elseif item:IsA("Frame") then
		tween(item, 0.4, { BackgroundTransparency = 1 })
	elseif item:IsA("UIStroke") then
		tween(item, 0.4, { Transparency = 1 })
	end
end
leaving = true

local root = getRoot()
if not root then
	finish()
	return
end
camera = workspace.CurrentCamera
local startCF = camera.CFrame
local flyStart = os.clock()
local tapped = false
local tapConn = UserInputService.InputBegan:Connect(function(input)
	if os.clock() - flyStart > 0.3 and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		tapped = true -- on peut passer le vol en touchant l'écran
	end
end)
while not tapped do
	local a = math.min((os.clock() - flyStart) / FLY_TIME, 1)
	local t = TweenService:GetValue(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 then
		look = Vector3.new(1, 0, 0)
	end
	look = look.Unit
	local head = root.Position + Vector3.new(0, 1.5, 0)
	local endPos = head - look * 12 + Vector3.new(0, 3, 0)
	-- Courbe : on passe par un point haut entre le départ et l'arrivée
	local p0, p2 = startCF.Position, endPos
	local p1 = (p0 + p2) / 2 + Vector3.new(0, 25, 0)
	local pos = (1 - t) ^ 2 * p0 + 2 * (1 - t) * t * p1 + t ^ 2 * p2
	local startFocus = startCF.Position + startCF.LookVector * 100
	local focus = startFocus:Lerp(head, math.min(1, t * 1.3))
	camera.CFrame = CFrame.lookAt(pos, focus)
	if a >= 1 then
		break
	end
	RunService.RenderStepped:Wait()
end
tapConn:Disconnect()
finish()
