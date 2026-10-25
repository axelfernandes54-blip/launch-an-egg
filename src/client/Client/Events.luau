-- Events (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- Les messages du serveur : ouvrir les fenêtres (Codes, Trait Master), le portail du World 2,
-- et la mise à jour de tout l'écran quand les infos du joueur changent (StateChanged).

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

local Hud = UI.Hud
local baseLabel, bestValue, coinRate, coinsValue, portal = Hud.baseLabel, Hud.bestValue, Hud.coinRate, Hud.coinsValue, Hud.portal
local rerollsValue, showX2, strengthScale, updateBoostTimer, updateBoosts = Hud.rerollsValue, Hud.showX2, Hud.strengthScale, Hud.updateBoostTimer, Hud.updateBoosts
local setUISize = UI.Windows.setUISize
local lastStrength = 0
local previousPotionTotal = nil

-- Le coffre CODES du lobby ouvre la fenêtre des codes
OpenCodes.OnClientEvent:Connect(function()
	if UI.openWindowName ~= "Codes" then
		openWindow("Codes")
	end
end)

-- Le portail du lobby ouvre la fenêtre des worlds
remotes:WaitForChild("OpenWorlds").OnClientEvent:Connect(function()
	if UI.openWindowName ~= "Worlds" then
		openWindow("Worlds")
	end
end)

-- Le Trait Master ouvre sa fenêtre quand on lui parle
OpenTraits.OnClientEvent:Connect(function()
	if UI.openWindowName ~= "Traits" then
		openWindow("Traits")
	end
end)

-- Le portail du World 2 ---------------------------------------------------------
-- Sur la barre du haut : un cadenas tant qu'il n'est pas acheté, et il brille ensuite.
-- Dans le lobby : le panneau du portail dit "WORLDS".
local showWorld2
do
	local portalLock = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.75, 0.75),
		BackgroundTransparency = 1,
		Text = "🔒",
		TextScaled = true,
		ZIndex = 3,
	}, portal)
	local portalStroke = portal:FindFirstChildOfClass("UIStroke")
	local portalScale = make("UIScale", {}, portal)
	local unlocked = false
	local signDone = false -- le panneau du lobby n'est changé qu'une fois

	function showWorld2(isUnlocked)
		unlocked = isUnlocked
		portalLock.Visible = not isUnlocked
		if portalStroke then
			portalStroke.Color = isUnlocked and Theme.Gold or Color3.fromRGB(255, 120, 230)
			portalStroke.Thickness = isUnlocked and 5 or 3
		end
		-- le panneau du portail du lobby
		local map = workspace:FindFirstChild("LaunchMap")
		-- (avec le streaming, le panneau n'est pas toujours chargé : on réessaie jusqu'à le trouver)
		if map and not signDone then
			for _, text in map:GetDescendants() do
				if text:IsA("TextLabel") and string.find(text.Text, "WORLD 2") and string.find(text.Text, "Coming soon") and not string.find(text.Text, "\n.*\n") then
					if text.Parent and text.Parent.Parent and (text.Parent.Parent.Position - Vector3.new(-160, 26, 66)).Magnitude < 20 then
						text.Text = "🌍 WORLDS" -- le portail ouvre maintenant la fenêtre des worlds
						signDone = true
					end
				end
			end
		end
	end

	-- le portail du bout de la piste : ses bras tournent, et sur la barre il pulse quand il est ouvert
	local arms = {}
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		portalScale.Scale = unlocked and (1 + math.sin(t * 4) * 0.08) or 1
		local map = workspace:FindFirstChild("LaunchMap")
		local model = map and map:FindFirstChild("PortailMonde2")
		local core = model and model:FindFirstChild("Tourbillon")
		if not core then
			return
		end
		for _, part in model:GetChildren() do
			if part.Name == "BrasTourbillon" and not arms[part] then
				arms[part] = core.CFrame:ToObjectSpace(part.CFrame) -- sa place de départ
			end
		end
		for part, offset in arms do
			if part.Parent then
				part.CFrame = core.CFrame * CFrame.Angles(-t * 1.2, 0, 0) * offset
			else
				arms[part] = nil
			end
		end
	end)
end

-- La grosse animation quand l'œuf entre dans le portail
local function playWorld2Unlock()
	local flash = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 50 }, gui)
	TweenService:Create(flash, TweenInfo.new(1.4), { BackgroundTransparency = 1 }):Play()
	task.delay(1.5, flash.Destroy, flash)
	local holder = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.new(0, 900, 0, 210), BackgroundTransparency = 1, ZIndex = 51 }, gui)
	local scale = make("UIScale", { Scale = 0.1 }, holder)
	local title = label(holder, { Size = UDim2.new(1, 0, 0.62, 0), Text = "WORLD 2 UNLOCKED!", Font = TITLE_FONT, ZIndex = 52 }, 6)
	local rainbow = make("UIGradient", { Color = RAINBOW }, title)
	label(holder, { Position = UDim2.new(0, 0, 0.66, 0), Size = UDim2.new(1, 0, 0.28, 0), Text = "The WORLD 2 portal in the lobby is now open!", TextColor3 = Theme.Gold, ZIndex = 52 }, 3)
	TweenService:Create(scale, TweenInfo.new(0.7, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local sound = make("Sound", { SoundId = "rbxassetid://6586979979", PlaybackSpeed = 0.6, Volume = 1 }, gui)
	sound:Play()
	task.delay(2, sound.Destroy, sound)
	local start = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		rainbow.Rotation = ((os.clock() - start) * 160) % 360
	end)
	task.delay(5, function()
		local shrink = TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
		shrink:Play()
		shrink.Completed:Wait()
		connection:Disconnect()
		holder:Destroy()
	end)
	showWorld2(true)
end
World2UnlockedRemote.OnClientEvent:Connect(playWorld2Unlock)
ShowMessage.OnClientEvent:Connect(function(text)
	toast(text)
end)

-- Mise à jour des infos envoyées par le serveur -------------------------------

StateChanged.OnClientEvent:Connect(function(newState)
	local previousPetCount = UI.state and UI.state.PetCount
	local firstState = UI.state == nil
	UI.state = newState
	if firstState and newState.UIScale then
		setUISize(newState.UIScale, false) -- la taille d'interface sauvegardée
	end
	coinsValue.Text = formatNumber(UI.state.Coins)
	bestValue.Text = formatNumber(UI.state.Best) .. " studs"
	rerollsValue.Text = formatNumber(UI.state.Diamonds or 0)
	-- le portail au bout de la barre brille quand le World 2 est acheté (la barre suit la dimension : voir Hud)
	showWorld2((UI.state.UnlockedWorlds or {})[2] == true)
	coinRate.Text = "+" .. formatNumber(UI.state.CoinsPerSecond or 0) .. "/s"

	-- Le compteur de Force grossit un instant quand il augmente
	UI.currentForce = UI.state.Force
	baseLabel.Text = "Base: " .. formatNumber(UI.state.BaseForce)
	showX2(UI.state.HasX2)
	if UI.state.Force > lastStrength then
		strengthScale.Scale = 1.25
		TweenService:Create(strengthScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	lastStrength = UI.state.Force
	updateBoosts()
	updateBoostTimer()

	-- Une nouvelle potion : petit point rouge sur la tuile Inventory
	local potionTotal = 0
	for _, count in UI.state.Potions or {} do
		potionTotal += count
	end
	if previousPotionTotal and potionTotal > previousPotionTotal and UI.openWindowName ~= "Inventory" then
		UI.inventoryDot.Visible = true
	end
	previousPotionTotal = potionTotal

	-- Un nouveau pet : petit point rouge sur la tuile Inventory
	if previousPetCount and UI.state.PetCount > previousPetCount and UI.openWindowName ~= "Inventory" then
		UI.inventoryDot.Visible = true
	end

	-- Si une fenêtre est ouverte, on la met à jour
	if UI.openWindowName then
		windows[UI.openWindowName].Refresh(false)
	end
end)


return {}
