-- Launch (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- Le tir : jauge (maintenir le clic), animation d'élan, caméra qui suit l'œuf, effets arcade,
-- et la carte "YOU GOT..." quand l'œuf atterrit.

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

local strengthLabel, strengthScale = UI.Hud.strengthLabel, UI.Hud.strengthScale

-- La jauge de puissance (en bas au centre) : elle n'apparaît que dans la zone de tir ----

local GAUGE_WIDTH = 420
local gaugeHolder = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -40),
	Size = UDim2.new(0, GAUGE_WIDTH, 0, 30),
	BackgroundTransparency = 1,
	Visible = false,
}, gui)
local gaugeStroke = make("UIStroke", { Thickness = 4, Color = Color3.fromRGB(25, 20, 35) }, gaugeHolder)
round(gaugeHolder, 15)

-- Le fond (le CanvasGroup coupe le remplissage aux coins arrondis)
local gaugeBack = make("CanvasGroup", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(40, 35, 55),
}, gaugeHolder)
round(gaugeBack, 15)

-- Le remplissage : un dégradé rouge -> jaune -> vert, qu'on dévoile de gauche à droite
local gaugeFill = make("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, gaugeBack)
local gaugeColors = make("Frame", {
	Size = UDim2.new(0, GAUGE_WIDTH, 1, 0),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
}, gaugeFill)
make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 210, 50)),
		ColorSequenceKeypoint.new(0.85, Color3.fromRGB(90, 230, 90)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 255, 160)),
	}),
}, gaugeColors)
-- un reflet blanc en haut, pour l'effet "brillant"
make("Frame", {
	Size = UDim2.fromScale(1, 0.4),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.75,
	BorderSizePixel = 0,
	ZIndex = 3,
}, gaugeBack)
-- des petits traits tous les 10 %
for i = 1, 9 do
	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(i / 10, 1),
		Size = UDim2.new(0, 2, 0.35, 0),
		BackgroundColor3 = Color3.fromRGB(25, 20, 35),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, gaugeBack)
end
-- la zone "parfait" (les derniers 10 %) a un léger voile doré
make("Frame", {
	Position = UDim2.fromScale(0.9, 0),
	Size = UDim2.fromScale(0.1, 1),
	BackgroundColor3 = Color3.fromRGB(255, 215, 60),
	BackgroundTransparency = 0.7,
	BorderSizePixel = 0,
	ZIndex = 2,
}, gaugeBack)
local gaugeText = make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "HOLD CLICK TO CHARGE",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 20,
	Font = NUMBER_FONT,
	ZIndex = 5,
}, gaugeBack)
make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(40, 25, 15) }, gaugeText)

-- Le curseur blanc qui suit la jauge
local gaugePointer = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0, 0, 0, 2),
	Size = UDim2.new(0, 24, 0, 20),
	BackgroundTransparency = 1,
	Text = "▼",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 22,
	Font = NUMBER_FONT,
}, gaugeHolder)
make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(25, 20, 35) }, gaugePointer)

-- "PERFECT!" quand la jauge est presque pleine
local perfectLabel = outlined(make("TextLabel", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, 12, 0.5, 0),
	Size = UDim2.new(0, 130, 0, 30),
	BackgroundTransparency = 1,
	Text = "PERFECT!",
	TextColor3 = Color3.fromRGB(255, 215, 60),
	TextScaled = true,
	Font = TITLE_FONT,
	Visible = false,
}, gaugeHolder))

-- Charger le tir : on maintient le clic (ou le doigt, ou la gâchette R2), on relâche pour tirer --

local ready = true     -- vrai quand on peut lancer
local charging = false -- vrai pendant qu'on maintient le clic
local chargeInput = nil
local chargeTime = 0
local power = 0

-- Est-ce que le joueur est sur la plateforme de tir ? (la même zone que celle vérifiée par le serveur)
local function isInLaunchArea()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local p = root.Position
	return p.X >= -41 and p.X <= 1 and math.abs(p.Z) <= 41
end

-- L'animation "je prends de l'élan" pendant qu'on maintient le clic (voir Config.Animations)
local chargeTrack = nil
local function startChargeAnim()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if Config.Animations.Charge == "" or not animator then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. Config.Animations.Charge
	chargeTrack = animator:LoadAnimation(animation)
	chargeTrack.Priority = Enum.AnimationPriority.Action
	chargeTrack.Looped = true
	chargeTrack:Play(0.15)
end
local function stopChargeAnim()
	if chargeTrack then
		chargeTrack:Stop(0.1)
		chargeTrack = nil
	end
end

local function launch()
	if not ready or not isInLaunchArea() then
		return -- on ne peut tirer que sur la plateforme de tir
	end
	ready = false
	LaunchEgg:FireServer(power)
	-- sécurité : si le serveur refuse le tir (ou si le partenaire du duo ne vient pas), on peut retirer
	local myLaunch = os.clock()
	UI.lastLaunchRequest = myLaunch
	task.delay(Config.DuoKick.ReleaseWindow + 3, function()
		if UI.lastLaunchRequest == myLaunch and not UI.trackedEgg and not ready then
			ready = true
		end
	end)
end

local function isChargeInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonR2
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- gameProcessed = vrai si on a cliqué sur un bouton de l'interface : dans ce cas on ne tire pas
	if gameProcessed or charging or not isChargeInput(input) then
		return
	end
	if ready and isInLaunchArea() then
		charging = true
		chargeInput = input
		chargeTime = 0
		startChargeAnim()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not charging then
		return
	end
	local sameInput = input == chargeInput
		or (input.UserInputType == chargeInput.UserInputType and input.KeyCode == chargeInput.KeyCode and input.UserInputType ~= Enum.UserInputType.Touch)
	if sameInput then
		charging = false
		stopChargeAnim()
		launch()
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local inArea = isInLaunchArea()
	if charging and not inArea then
		charging = false -- on est sorti de la zone : on annule
		stopChargeAnim()
	end
	if charging then
		-- La jauge monte puis redescend tant qu'on maintient : il faut relâcher au bon moment !
		chargeTime += dt * Config.Launch.GaugeSpeed
		power = 1 - math.abs((chargeTime * 2) % 2 - 1)
	elseif ready then
		power = 0
	end

	gaugeHolder.Visible = inArea or not ready
	gaugeFill.Size = UDim2.fromScale(power, 1)
	gaugePointer.Position = UDim2.new(power, 0, 0, 2)
	-- Presque plein : le contour devient doré et "PERFECT!" s'affiche
	local perfect = charging and power > 0.9
	perfectLabel.Visible = perfect
	gaugeStroke.Color = perfect and Color3.fromRGB(255, 215, 60) or Color3.fromRGB(25, 20, 35)
	gaugeHolder.Size = UDim2.new(0, GAUGE_WIDTH, 0, perfect and 34 or 30)

	if not ready then
		return -- pendant le vol, le compteur garde la Force du tir (💥)
	end
	strengthLabel.Text = formatNumber(UI.currentForce)
	if charging then
		-- La jauge montre la Force exacte du coup de pied si on relâche maintenant
		-- (jauge pleine = toute la Force du compteur)
		local kickForce = math.floor(UI.currentForce * (Config.Launch.MinPower + (1 - Config.Launch.MinPower) * power))
		gaugeText.Text = "💪 " .. formatNumber(kickForce)
	else
		gaugeText.Text = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "HOLD TO CHARGE" or "HOLD CLICK TO CHARGE"
	end
end)

-- La caméra suit l'œuf pendant le vol -----------------------------------------

local CAMERA_OFFSET = Vector3.new(-30, 14, 22) -- derrière, au-dessus et un peu sur le côté de l'œuf
local CAMERA_SMOOTHNESS = 4                    -- plus c'est grand, plus la caméra colle à l'œuf
local SHAKE_STRENGTH = 1.2                     -- force du tremblement à l'atterrissage
local followConnection = nil
local shakeUntil = 0

local function stopFollowing()
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
end

-- Avec le "streaming" de Roblox, l'œuf peut arriver chez nous un peu après le message :
-- on l'attend jusqu'à 2 secondes (un œuf déjà posé est ancré, on l'ignore).
local function waitForFlyingEgg()
	local start = os.clock()
	while os.clock() - start < 2 do
		for _, child in workspace:GetChildren() do
			if child.Name == "Oeuf_" .. player.Name and child:IsA("BasePart") and not child.Anchored then
				return child
			end
		end
		task.wait()
	end
	return nil
end

-- Style arcade : un gros mot de bande dessinée ("POW!", "BOOM!"...) qui claque au milieu de l'écran
local ARCADE_WORDS = { "POW!", "BOOM!", "WHAM!", "KAPOW!" }
local function arcadeBurst(text, color)
	local word = label(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0, 420, 0, 130),
		Text = text,
		Font = TITLE_FONT,
		TextColor3 = color or Theme.Gold,
		Rotation = math.random(-12, 12),
		ZIndex = 30,
	}, 7)
	local scale = make("UIScale", { Scale = 0.2 }, word)
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(0.55, function()
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		task.delay(0.22, word.Destroy, word)
	end)
end

EggLaunched.OnClientEvent:Connect(function(egg, kickForce, duoPartnerName)
	-- En duo, le partenaire a pu déclencher le tir : on arrête de charger
	ready = false
	UI.lastLaunchRequest = nil
	if charging then
		charging = false
		stopChargeAnim()
	end
	-- On affiche la Force du tir, en gros, au moment du coup de pied
	if kickForce then
		-- arcade : un petit tremblement et un gros "POW!" au coup de pied ("DUO KICK!" à deux)
		shakeUntil = os.clock() + 0.25
		arcadeBurst(duoPartnerName and "DUO KICK!" or ARCADE_WORDS[math.random(1, #ARCADE_WORDS)])
	end
	if kickForce then
		strengthLabel.Text = "💥 " .. formatNumber(kickForce)
		gaugeText.Text = "💥 " .. formatNumber(kickForce)
		strengthScale.Scale = 1.6
		TweenService:Create(strengthScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	egg = egg or waitForFlyingEgg()
	if not egg then
		return
	end
	UI.trackedEgg = egg
	stopFollowing()
	camera.CameraType = Enum.CameraType.Scriptable
	local lastPosition = egg.Position
	local lookTarget = egg.Position

	followConnection = RunService.RenderStepped:Connect(function(dt)
		if not egg.Parent then
			return -- l'œuf a disparu : on garde la dernière vue
		end
		local position = egg.Position
		local velocity = (position - lastPosition) / math.max(dt, 1 / 240)
		lastPosition = position

		-- On glisse doucement vers la bonne place (au lieu de sauter d'un coup)
		local alpha = 1 - math.exp(-CAMERA_SMOOTHNESS * dt)
		lookTarget = lookTarget:Lerp(position + velocity * 0.15, alpha)
		local wantedPosition = position + CAMERA_OFFSET
		local cameraPosition = camera.CFrame.Position:Lerp(wantedPosition, alpha)
		camera.CFrame = CFrame.lookAt(cameraPosition, lookTarget)

		-- Tremblement quand l'œuf s'écrase au sol
		local shakeLeft = shakeUntil - os.clock()
		if shakeLeft > 0 then
			local strength = SHAKE_STRENGTH * shakeLeft / 0.4
			camera.CFrame *= CFrame.new((math.random() * 2 - 1) * strength, (math.random() * 2 - 1) * strength, 0)
		end

		-- Plus l'œuf va vite, plus le champ de vision s'élargit (effet de vitesse)
		local wantedFov = 70 + math.clamp(velocity.Magnitude / 10, 0, 15)
		camera.FieldOfView += (wantedFov - camera.FieldOfView) * alpha
	end)
end)

-- Après l'atterrissage, la caméra revient en douceur vers le joueur
local function returnCameraToPlayer()
	stopFollowing()
	UI.trackedEgg = nil
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local target = CFrame.lookAt(root.Position + Vector3.new(-14, 8, 0), root.Position + Vector3.new(10, 0, 0))
		local tween = TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			CFrame = target,
			FieldOfView = 70,
		})
		tween:Play()
		tween.Completed:Wait()
	end
	camera.FieldOfView = 70
	camera.CameraType = Enum.CameraType.Custom
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

-- La carte "YOU GOT..." quand l'œuf atterrit ------------------------------------
-- Le pet obtenu tourne en 3D, avec des rayons de la couleur de sa rareté derrière lui.

local showReveal
do
	local frame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0, 360, 0, 360),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 30,
	}, gui)
	local scale = make("UIScale", {}, frame)

	-- les rayons qui tournent
	local rays = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.new(0, 560, 0, 560), BackgroundTransparency = 1 }, frame)
	local rayParts = {}
	for i = 0, 5 do
		local ray = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 56, 1, 0),
			Rotation = i * 30,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, rays)
		make("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.55),
				NumberSequenceKeypoint.new(0.5, 0.15),
				NumberSequenceKeypoint.new(0.8, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, ray)
		table.insert(rayParts, ray)
	end

	-- la carte
	local card = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 270, 0, 290), BackgroundColor3 = Color3.new(1, 1, 1) }, frame)
	round(card, 24)
	border(card, 4)
	gradient(card, Theme.Panel, Theme.PanelDark)
	local cardTrim = make("Frame", { Position = UDim2.new(0, 6, 0, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1 }, card)
	round(cardTrim, 20)
	local trimStroke = make("UIStroke", { Thickness = 3, Color = Theme.Gold }, cardTrim)

	local ribbon = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 230, 0, 50), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 }, card)
	round(ribbon, 16)
	border(ribbon, 4)
	local ribbonGradient = gradient(ribbon, Color3.new(1, 1, 1), Color3.new(1, 1, 1))
	local ribbonText = label(ribbon, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -20, 0.7, 0), Text = "", Font = TITLE_FONT }, 3)

	local newBadge = make("Frame", {
		Position = UDim2.new(0, -14, 0, 30),
		Size = UDim2.new(0, 70, 0, 32),
		Rotation = -14,
		BackgroundColor3 = ButtonStyles.Red[2],
		ZIndex = 4,
	}, card)
	round(newBadge, 10)
	border(newBadge, 3)
	label(newBadge, { Size = UDim2.new(1, -10, 0.75, 0), Position = UDim2.new(0, 5, 0.12, 0), Text = "NEW!", Font = TITLE_FONT }, 2)

	local viewHolder = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 32), Size = UDim2.new(0, 190, 0, 150), BackgroundTransparency = 1 }, card)
	local nameText = label(card, { Position = UDim2.new(0, 12, 0, 184), Size = UDim2.new(1, -24, 0, 32), Text = "", Font = TITLE_FONT }, 3)
	local abilityText = label(card, { Position = UDim2.new(0, 12, 0, 218), Size = UDim2.new(1, -24, 0, 22), Text = "", TextColor3 = Theme.Gold }, 2)
	local statsText = label(card, { Position = UDim2.new(0, 12, 0, 246), Size = UDim2.new(1, -24, 0, 22), Text = "", TextColor3 = Theme.SubText }, 1.5)

	RunService.RenderStepped:Connect(function(dt)
		if frame.Visible then
			rays.Rotation = (rays.Rotation + dt * 25) % 360
		end
	end)

	local version = 0
	function showReveal(result, isNew)
		version += 1
		local myVersion = version
		local pet = Config.GetPet(result.PetName)
		local rarity = Config.GetRarity(result.Rarity)
		for _, ray in rayParts do
			ray.BackgroundColor3 = rarity.Color
		end
		trimStroke.Color = rarity.Color
		ribbonGradient.Color = ColorSequence.new(rarity.Color:Lerp(Color3.new(1, 1, 1), 0.35), rarity.Color)
		if rarity.Id == "Mythique" then
			ribbonGradient.Color = RAINBOW
		end
		ribbonText.Text = string.upper(rarity.Name) .. "!"
		newBadge.Visible = isNew
		clearChildren(viewHolder)
		-- le pet en 3D apparaît juste après le "pop" de la carte (sinon il ne s'affiche pas toujours)
		task.delay(0.45, function()
			if myVersion == version then
				clearChildren(viewHolder)
				petViewport(viewHolder, result.PetName, { Size = UDim2.fromScale(1, 1) }, { Mode = "sway", Zoom = 0.9 })
			end
		end)
		nameText.Text = result.PetName
		abilityText.Text = result.GotReroll and "💎 +1 Reroll!" or "✨ Get a trait at the Trait Master!"
		-- la distance (avec une virgule pour les milliers) et la chance qu'on avait pour cette rareté
		local distanceText = tostring(result.Distance):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		local chance = result.Chance or 0
		statsText.Text = string.format("📏 %s studs  •  %s chance %s%%", distanceText, rarity.Name, chance >= 10 and tostring(math.round(chance)) or string.format("%.1f", chance))

		frame.Visible = true
		scale.Scale = 0.2
		TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.delay(3.6, function()
			if myVersion ~= version then
				return
			end
			local shrink = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.1 })
			shrink:Play()
			shrink.Completed:Wait()
			if myVersion == version then
				frame.Visible = false
				clearChildren(viewHolder)
			end
		end)
	end
end

EggLanded.OnClientEvent:Connect(function(result)
	shakeUntil = os.clock() + 0.4
	-- "NEW!" si on n'avait encore jamais eu ce pet
	local isNew = not (UI.state and UI.state.NameCounts and UI.state.NameCounts[result.PetName])
	showReveal(result, isNew)

	task.delay(1.5, function()
		returnCameraToPlayer()
		ready = true
	end)
end)


return {}
