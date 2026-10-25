-- World (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- Le monde autour du joueur : lumière selon l'ambiance, mouettes, course (Shift / bouton RUN),
-- barrières magiques qui brillent, haltères qui flottent et leur animation quand on les ramasse.

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

-- La lumière change selon l'ambiance où se trouve la caméra (pendant le vol de l'œuf) --------
-- Beach : grand soleil ; Port : après-midi ; Treasure Island : lumière dorée ;
-- Ghost Ship : brume verte du soir ; Kraken Sea : crépuscule bleu foncé.
do
	local Lighting = game:GetService("Lighting")
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or make("Atmosphere", {}, Lighting)
	local colorCorrection = Lighting:FindFirstChild("AmbianceColor") or make("ColorCorrectionEffect", { Name = "AmbianceColor" }, Lighting)
	local AMBIANCES = {
		Commune = { Clock = 14, Density = 0.2, Haze = 0.2, Color = Color3.fromRGB(200, 225, 255), Tint = Color3.new(1, 1, 1), Saturation = 0.1 },
		Rare = { Clock = 15.5, Density = 0.3, Haze = 0.8, Color = Color3.fromRGB(215, 225, 245), Tint = Color3.new(1, 1, 1), Saturation = 0.05 },
		Epique = { Clock = 16.6, Density = 0.32, Haze = 1, Color = Color3.fromRGB(255, 225, 190), Tint = Color3.fromRGB(255, 245, 225), Saturation = 0.15 },
		Legendaire = { Clock = 17.6, Density = 0.5, Haze = 2.2, Color = Color3.fromRGB(150, 205, 170), Tint = Color3.fromRGB(210, 255, 220), Saturation = -0.15 },
		Mythique = { Clock = 17.9, Density = 0.45, Haze = 1.8, Color = Color3.fromRGB(120, 140, 210), Tint = Color3.fromRGB(205, 215, 255), Saturation = 0 },
	}
	local current = table.clone(AMBIANCES.Commune)
	-- Style arcade : des couleurs plus vives et plus de contraste partout
	local ARCADE_SATURATION = 0.18
	local ARCADE_CONTRAST = 0.08
	colorCorrection.Contrast = ARCADE_CONTRAST
	RunService.RenderStepped:Connect(function(dt)
		local zone = Config.GetZoneForDistance(math.max(0, camera.CFrame.Position.X))
		local wanted = AMBIANCES[zone.Rarity] or AMBIANCES.Commune
		local alpha = math.min(1, dt * 1.5) -- on glisse doucement d'une ambiance à l'autre
		current.Clock += (wanted.Clock - current.Clock) * alpha
		current.Density += (wanted.Density - current.Density) * alpha
		current.Haze += (wanted.Haze - current.Haze) * alpha
		current.Saturation += (wanted.Saturation - current.Saturation) * alpha
		current.Color = current.Color:Lerp(wanted.Color, alpha)
		current.Tint = current.Tint:Lerp(wanted.Tint, alpha)
		Lighting.ClockTime = current.Clock
		atmosphere.Density = current.Density
		atmosphere.Haze = current.Haze
		atmosphere.Color = current.Color
		atmosphere.Decay = current.Color:Lerp(Color3.new(0.4, 0.4, 0.5), 0.5)
		colorCorrection.TintColor = current.Tint
		colorCorrection.Saturation = current.Saturation + ARCADE_SATURATION
	end)
end

-- Des mouettes qui tournent au-dessus du lobby et de la plage (juste chez nous, très léger)
do
	local gulls = {}
	local folder = make("Folder", { Name = "Mouettes" }, workspace)
	local function gullPart(size, color)
		return make("Part", { Size = size, Color = color, Material = Enum.Material.SmoothPlastic, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }, folder)
	end
	for index = 1, 10 do
		local gull = {
			Body = gullPart(Vector3.new(0.6, 0.6, 1.6), Color3.new(1, 1, 1)),
			Left = gullPart(Vector3.new(1.8, 0.15, 0.7), Color3.fromRGB(205, 210, 220)),
			Right = gullPart(Vector3.new(1.8, 0.15, 0.7), Color3.fromRGB(205, 210, 220)),
			Center = Vector3.new(index <= 4 and -120 or (index - 4) * 55, 0, (index % 2 == 0) and -40 or 40),
			Radius = 18 + (index % 3) * 10,
			Height = 26 + (index % 4) * 5,
			Speed = 0.35 + (index % 3) * 0.08,
			Seed = index * 1.7,
		}
		table.insert(gulls, gull)
	end
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, gull in gulls do
			local angle = t * gull.Speed + gull.Seed
			local position = gull.Center + Vector3.new(math.cos(angle) * gull.Radius, gull.Height + math.sin(t + gull.Seed) * 1.5, math.sin(angle) * gull.Radius)
			local forward = Vector3.new(-math.sin(angle), 0, math.cos(angle))
			local body = CFrame.lookAt(position, position + forward)
			local flap = math.sin(t * 8 + gull.Seed) * 0.5
			gull.Body.CFrame = body
			gull.Left.CFrame = body * CFrame.new(-0.3, 0, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-0.9, 0, 0)
			gull.Right.CFrame = body * CFrame.new(0.3, 0, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(0.9, 0, 0)
		end
	end)
end

-- Courir : maintenir Shift (ou L3 à la manette) ; sur téléphone, un bouton RUN -------------
do
	local WALK_SPEED, RUN_SPEED = 16, 26 -- vitesse normale et vitesse de course
	local holding = false -- Shift (ou L3) est maintenu
	local runToggle = false -- le bouton RUN du téléphone est allumé
	local function isRunKey(input)
		return input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.ButtonL3
	end
	local function isRunning()
		return holding or runToggle
	end
	local function apply()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = isRunning() and RUN_SPEED or WALK_SPEED
		end
	end
	UserInputService.InputBegan:Connect(function(input)
		if isRunKey(input) then
			holding = true
			apply()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isRunKey(input) then
			holding = false
			apply()
		end
	end)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		apply()
	end)

	-- le bouton RUN, seulement sur les écrans tactiles (à gauche du bouton de saut)
	if UserInputService.TouchEnabled then
		local runButton = fancyButton(gui, "Teal", "RUN", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -330, 1, -30),
			Size = UDim2.new(0, 110, 0, 70),
		})
		runButton.Button.Activated:Connect(function()
			runToggle = not runToggle
			runButton.SetStyle(runToggle and "Gold" or "Teal")
			runButton.Label.Text = runToggle and "RUNNING" or "RUN"
			apply()
		end)
	end

	-- le champ de vision s'élargit un peu quand on court (effet de vitesse), sauf pendant le vol de l'œuf
	RunService.RenderStepped:Connect(function(dt)
		if camera.CameraType ~= Enum.CameraType.Custom then
			return
		end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local moving = humanoid and humanoid.MoveDirection.Magnitude > 0.1
		local wanted = (isRunning() and moving) and 78 or 70
		camera.FieldOfView += (wanted - camera.FieldOfView) * math.min(1, dt * 6)
	end)
end

-- Les barrières magiques : presque invisibles de loin, elles brillent comme de l'eau quand on s'approche
do
	local CollectionService = game:GetService("CollectionService")
	local NEAR, FAR = 6, 24 -- en studs : pleine lueur à 6, invisible à 24
	task.spawn(function()
		while true do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				for _, wall in CollectionService:GetTagged("Barrier") do
					-- la distance entre le joueur et le point le plus proche du mur
					local localPosition = wall.CFrame:PointToObjectSpace(root.Position)
					local half = wall.Size / 2
					local closest = Vector3.new(
						math.clamp(localPosition.X, -half.X, half.X),
						math.clamp(localPosition.Y, -half.Y, half.Y),
						math.clamp(localPosition.Z, -half.Z, half.Z)
					)
					local distance = (localPosition - closest).Magnitude
					wall.LocalTransparencyModifier = math.clamp((distance - NEAR) / (FAR - NEAR), 0, 1) * 0.9
				end
			end
			task.wait(0.1)
		end
	end)
end

-- Les haltères du lobby ------------------------------------------------------

-- Elles tournent sur elles-mêmes et montent/descendent doucement (juste chez nous)
local dumbbellFolder = workspace:WaitForChild("Halteres")
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, model in dumbbellFolder:GetChildren() do
		local home = model:GetAttribute("Home")
		if home and not model:GetAttribute("Collected") then
			local seed = home.Position.X + home.Position.Z
			model:PivotTo(home * CFrame.Angles(0, t * 1.5 + seed, 0) + Vector3.new(0, math.sin(t * 2 + seed) * 0.4, 0))
		end
	end
end)

-- Quand quelqu'un ramasse une haltère : elle grossit, tourne, monte et disparaît dans des étincelles
DumbbellCollected.OnClientEvent:Connect(function(collector, model, value, info)
	if not model or not model.Parent then
		return
	end
	local color = model:GetAttribute("Color") or Color3.new(1, 1, 1)
	local size = model:GetAttribute("Size") or 1

	local ghost = model:Clone()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1 -- on cache la vraie, on anime une copie
		end
	end
	ghost:SetAttribute("Home", nil)
	ghost.Parent = workspace
	local start = ghost:GetPivot()

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.8 * size, 0)
	sparkles.Speed = NumberRange.new(6, 14)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Lifetime = NumberRange.new(0.4, 0.8)
	sparkles.Rate = 0
	sparkles.Parent = ghost:FindFirstChild("Barre")

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://6586979979" -- un petit "pop" de dessin animé
	sound.PlaybackSpeed = 1.15 - math.min(size, 2.6) * 0.1 -- un peu plus grave pour les grosses haltères
	sound.Volume = collector == player and 0.6 or 0.2
	sound.Parent = ghost:FindFirstChild("Barre")
	sound:Play()

	task.spawn(function()
		local duration = 0.45
		local began = os.clock()
		repeat
			local alpha = math.min((os.clock() - began) / duration, 1)
			local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			ghost:ScaleTo(1 + 0.8 * eased)
			ghost:PivotTo(start * CFrame.Angles(0, alpha * math.pi * 2, 0) + Vector3.new(0, 3 * eased, 0))
			for _, part in ghost:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "Zone" then
					part.Transparency = math.max(0, (alpha - 0.6) / 0.4)
				end
			end
			RunService.RenderStepped:Wait()
		until alpha >= 1
		sparkles:Emit(math.floor(15 + 10 * size))
		task.delay(1, ghost.Destroy, ghost)
	end)

	-- "💪 +X" qui monte au-dessus de notre personnage et s'efface (plus gros pour les grosses haltères)
	if collector ~= player then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local popup = Instance.new("BillboardGui")
	popup.Size = UDim2.new(0, 200, 0, (50 + size * 10) * 0.68)
	popup.StudsOffset = Vector3.new(math.random(-15, 15) / 10, 3, 0)
	popup.AlwaysOnTop = true
	popup.Adornee = root
	popup.Parent = screenGui
	local text = make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = (info and (info.Rerolls or 0) > 0) and ("💎 +" .. info.Rerolls .. " Reroll!") or ("💪 +" .. value),
		TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.3),
		TextScaled = true,
		Font = NUMBER_FONT,
	}, popup)
	local stroke = make("UIStroke", { Thickness = 3, Color = Color3.fromRGB(40, 20, 10) }, text)
	local info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(popup, info, { StudsOffset = popup.StudsOffset + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(text, TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.4), { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.4), { Transparency = 1 }):Play()
	task.delay(1.1, popup.Destroy, popup)
end)


return {}
