-- Windows (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- Les fenêtres : Shop (Robux), Upgrades (diamants), Worlds (pièces), Inventory (onglets PETS / POTIONS...), Codes,
-- Trait Master, Index (album des pets), Leaderboard et Settings.

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

-- SHOP : le pass x2 Force et l'amélioration Power Up ----------------------------

local x2Price = nil -- prix du pass (récupéré auprès de Roblox)
task.spawn(function()
	if Config.X2ForcePassId ~= 0 then
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(Config.X2ForcePassId, Enum.InfoType.GamePass)
		end)
		if ok and info then
			x2Price = info.PriceInRobux
		end
	end
end)

local function buyX2()
	if UI.state and UI.state.HasX2 then
		toast("You already have x2 Strength!")
		return
	end
	if Config.X2ForcePassId == 0 then
		comingSoon()
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, Config.X2ForcePassId)
end

-- Une carte d'offre : une grosse icône, un titre, une phrase et un bouton
local function offerCard(parent, position, style, emoji, title, description)
	local card = make("Frame", { Position = position, Size = UDim2.new(0.5, -10, 1, 0), BackgroundColor3 = Theme.PanelLight }, parent)
	round(card, 20)
	border(card, 3)
	local glow = make("Frame", { Size = UDim2.new(1, 0, 0.6, 0), BackgroundColor3 = ButtonStyles[style][2] }, card)
	round(glow, 20)
	make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.25, 1) }, glow)
	icon(card, emoji, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.new(0, 92, 0, 92) })
	label(card, { Position = UDim2.new(0, 12, 0, 108), Size = UDim2.new(1, -24, 0, 36), Text = title, Font = TITLE_FONT }, 3)
	label(card, {
		Position = UDim2.new(0, 16, 0, 148),
		Size = UDim2.new(1, -32, 0, 44),
		Text = description,
		TextColor3 = Theme.SubText,
		TextWrapped = true,
	}, 1.5)
	local info = label(card, { Position = UDim2.new(0, 12, 0, 196), Size = UDim2.new(1, -24, 0, 26), Text = "", TextColor3 = Theme.Gold }, 2)
	local button = fancyButton(card, style, "BUY", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(1, -28, 0, 62),
	})
	return info, button
end

-- SHOP : seulement ce qui s'achète avec des Robux (les passes)
do
	local shop = makeWindow("Shop", "ROBUX SHOP", "🛒", 660, 420)
	local x2Info, x2Buy = offerCard(shop.Content, UDim2.new(), "Gold", "💪", "x2 STRENGTH", "Every dumbbell gives DOUBLE Strength. Forever!")
	local soonInfo, soonBuy = offerCard(shop.Content, UDim2.new(0.5, 10, 0, 0), "Purple", "🎁", "MORE PASSES", "New passes are on the way!")
	soonInfo.Text = "Stay tuned!"
	soonBuy.Label.Text = "SOON"
	soonBuy.SetStyle("Grey")
	soonBuy.Button.Activated:Connect(comingSoon)
	x2Buy.Button.Activated:Connect(buyX2)

	shop.Refresh = function()
		if UI.state and UI.state.HasX2 then
			x2Info.Text = "✔ Active"
			x2Buy.Label.Text = "OWNED"
			x2Buy.SetStyle("Grey")
		else
			x2Info.Text = "Best value!"
			x2Buy.Label.Text = x2Price and ("R$ " .. x2Price) or "BUY"
			x2Buy.SetStyle("Gold")
		end
	end
end

-- UPGRADES : les améliorations qu'on achète avec les diamants 💎 (gagnés avec les haltères)
-- Une ligne par upgrade (voir Config.Upgrades) : "Pet Luck: +5% [+2.5%/Level]", une barre 3/40, le prix et le bouton.
do
	local ROW_HEIGHT = 78
	local upgrades = makeWindow("Upgrades", "UPGRADES", "⚡", 760, 120 + #Config.Upgrades * (ROW_HEIGHT + 10))
	local rows = {}

	-- "+5%" ou "+1.5 studs"
	local function bonusText(upgrade, level)
		local value = upgrade.PerLevel * level
		if upgrade.Unit == "%" then
			value *= 100
		end
		return "+" .. (string.format("%.1f", value):gsub("%.0$", "")) .. upgrade.Unit
	end

	for index, upgrade in Config.Upgrades do
		local row = make("Frame", {
			Position = UDim2.new(0, 0, 0, (index - 1) * (ROW_HEIGHT + 10)),
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundColor3 = Theme.PanelLight,
		}, upgrades.Content)
		round(row, 14)
		border(row, 3)
		local title = label(row, {
			Position = UDim2.new(0, 12, 0, 6),
			Size = UDim2.new(1, -230, 0, 30),
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = TITLE_FONT,
		}, 2)
		-- la barre de niveau (0/40)
		local barBack = make("Frame", {
			Position = UDim2.new(0, 12, 0, 42),
			Size = UDim2.new(1, -230, 0, 26),
			BackgroundColor3 = Theme.PanelDark,
		}, row)
		round(barBack, 8)
		border(barBack, 2)
		local barFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ButtonStyles.Teal[2] }, barBack)
		round(barFill, 8)
		local barText = label(barBack, { Size = UDim2.fromScale(1, 1), Text = "0/" .. upgrade.MaxLevel, ZIndex = 2 }, 2)
		-- le prix et le bouton
		local price = label(row, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 4),
			Size = UDim2.new(0, 196, 0, 28),
			Text = "",
			TextColor3 = Theme.Gold,
		}, 2)
		local buy = fancyButton(row, "Gold", "Upgrade", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -12, 1, -6),
			Size = UDim2.new(0, 196, 0, 40),
		})
		buy.Button.Activated:Connect(function()
			if not UI.state then
				return
			end
			local level = UI.state.Upgrades and UI.state.Upgrades[upgrade.Id] or 0
			if level >= upgrade.MaxLevel then
				toast("Max level!")
			elseif (UI.state.Diamonds or 0) < Config.UpgradeCost(upgrade.Id, level) then
				toast("Not enough 💎! Collect dumbbells to get more.")
			else
				BuyUpgrade:FireServer(upgrade.Id)
			end
		end)
		rows[upgrade.Id] = { Title = title, Fill = barFill, BarText = barText, Price = price, Buy = buy }
	end

	label(upgrades.Content, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 24),
		Text = "💎 Collect dumbbells in the lobby to earn diamonds!",
		TextColor3 = Theme.SubText,
	}, 1.5)

	upgrades.Refresh = function()
		local diamonds = UI.state and UI.state.Diamonds or 0
		for _, upgrade in Config.Upgrades do
			local row = rows[upgrade.Id]
			local level = UI.state and UI.state.Upgrades and UI.state.Upgrades[upgrade.Id] or 0
			row.Title.Text = string.format("%s %s: %s [%s/Level]", upgrade.Icon, upgrade.Name, bonusText(upgrade, level), bonusText(upgrade, 1))
			row.Fill.Size = UDim2.fromScale(level / upgrade.MaxLevel, 1)
			row.BarText.Text = level .. "/" .. upgrade.MaxLevel
			if level >= upgrade.MaxLevel then
				row.Price.Text = "MAX"
				row.Buy.Label.Text = "MAX"
				row.Buy.SetStyle("Grey")
			else
				local cost = Config.UpgradeCost(upgrade.Id, level)
				row.Price.Text = "💎 " .. formatNumber(cost)
				row.Buy.Label.Text = "Upgrade"
				row.Buy.SetStyle(diamonds >= cost and "Gold" or "Grey")
			end
		end
	end
end

-- WORLDS (le portail du lobby) : acheter un world avec des pièces 💰, puis y aller
-- (les dimensions, elles, sont libres : l'œuf y arrive tout seul quand on a assez de Force)
do
	local CARD_HEIGHT = 96
	local worldsWindow = makeWindow("Worlds", "WORLDS", "🌍", 620, 130 + #Config.Worlds * (CARD_HEIGHT + 12))
	local ChooseWorld = remotes:WaitForChild("ChooseWorld")
	local cards = {}
	for index, world in Config.Worlds do
		local card = make("Frame", {
			Position = UDim2.new(0, 0, 0, (index - 1) * (CARD_HEIGHT + 12)),
			Size = UDim2.new(1, 0, 0, CARD_HEIGHT),
			BackgroundColor3 = Theme.PanelLight,
		}, worldsWindow.Content)
		round(card, 16)
		border(card, 3)
		label(card, {
			Position = UDim2.new(0, 16, 0, 10),
			Size = UDim2.new(1, -230, 0, 38),
			Text = "🌍 " .. world.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = TITLE_FONT,
		}, 2.5)
		label(card, {
			Position = UDim2.new(0, 16, 0, 54),
			Size = UDim2.new(1, -230, 0, 28),
			Text = world.Theme,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 1.5)
		local button = fancyButton(card, "Green", "", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.new(0, 196, 0, 62),
		})
		button.Button.Activated:Connect(function()
			if not UI.state then
				return
			end
			local unlocked = UI.state.UnlockedWorlds and UI.state.UnlockedWorlds[world.Id]
			if not unlocked and UI.state.Coins < world.Cost then
				toast("Not enough coins! Launch eggs and equip pets to earn more 💰")
			else
				ChooseWorld:FireServer(world.Id)
				closeWindow()
			end
		end)
		cards[world.Id] = button
	end
	label(worldsWindow.Content, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 24),
		Text = "💰 Earn coins with your pets and by launching eggs!",
		TextColor3 = Theme.SubText,
	}, 1.5)

	worldsWindow.Refresh = function()
		for _, world in Config.Worlds do
			local button = cards[world.Id]
			local unlocked = UI.state and UI.state.UnlockedWorlds and UI.state.UnlockedWorlds[world.Id]
			if unlocked then
				button.Label.Text = "GO!"
				button.SetStyle("Green")
			else
				button.Label.Text = "💰 " .. formatNumber(world.Cost)
				button.SetStyle(UI.state and UI.state.Coins >= world.Cost and "Gold" or "Grey")
			end
		end
	end
end

-- POTIONS (un onglet de l'inventaire) : les potions qu'on a, et le bouton pour en boire une 🧪 ---
-- (x2 Force des haltères ; boire une potion pendant qu'une autre marche ajoute son temps)

-- 299 secondes -> "4:59" ; 3725 -> "1:02:05"
local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, seconds % 3600 // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Construit la page dans "content" et renvoie sa fonction de mise à jour
local function buildPotionsPage(content)
	label(content, { Position = UDim2.new(0, 0, 0, 14), Size = UDim2.new(1, 0, 0, 30), Text = "Drink a potion: x2 Strength from dumbbells!", TextColor3 = Theme.Gold }, 2)
	local cards = {}
	for index, potion in Config.Potions do
		local card = make("Frame", {
			Position = UDim2.new((index - 1) / 3, (index - 1) * 5, 0, 54),
			Size = UDim2.new(1 / 3, -10, 0, 300),
			BackgroundColor3 = Theme.PanelLight,
		}, content)
		round(card, 20)
		border(card, 3)
		local glow = make("Frame", { Size = UDim2.new(1, 0, 0.6, 0), BackgroundColor3 = potion.Color }, card)
		round(glow, 20)
		make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.3, 1) }, glow)
		make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 170, 0, 170), BackgroundTransparency = 1, Image = potion.Image }, card)
		label(card, { Position = UDim2.new(0, 10, 0, 168), Size = UDim2.new(1, -20, 0, 36), Text = potion.Name, Font = TITLE_FONT }, 3)
		local owned = label(card, { Position = UDim2.new(0, 10, 0, 206), Size = UDim2.new(1, -20, 0, 22), Text = "Owned: x0", TextColor3 = Theme.SubText }, 1.5)
		local use = fancyButton(card, "Green", "USE", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, -24, 0, 54) })
		use.Button.Activated:Connect(function()
			if UI.state and UI.state.Potions and (UI.state.Potions[potion.Id] or 0) > 0 then
				UsePotion:FireServer(potion.Id)
				toast("🧪 +" .. potion.Minutes .. " min of x2 Strength!")
			else
				toast("Get potions with CODES in the lobby!")
			end
		end)
		cards[potion.Id] = { Owned = owned, Use = use }
	end
	local statusBar = make("Frame", { Position = UDim2.new(0, 0, 0, 372), Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Theme.PanelDark }, content)
	round(statusBar, 23)
	local statusStroke = border(statusBar, 3, Color3.fromRGB(70, 90, 150))
	local statusText = label(statusBar, { Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -32, 1, -16), Text = "" }, 2)

	return function()
		for id, card in cards do
			local count = UI.state and UI.state.Potions and UI.state.Potions[id] or 0
			card.Owned.Text = "Owned: x" .. count
			card.Use.SetStyle(count > 0 and "Green" or "Grey")
		end
		local left = UI.state and UI.state.BoostTime or 0
		if left > 0 then
			statusText.Text = "⚡ x2 STRENGTH ACTIVE • " .. formatTime(left) .. " left"
			statusText.TextColor3 = Theme.Gold
			statusStroke.Color = Theme.Gold
		else
			statusText.Text = "No potion active • Get potions with CODES in the lobby!"
			statusText.TextColor3 = Theme.SubText
			statusStroke.Color = Color3.fromRGB(70, 90, 150)
		end
	end
end

-- CODES : on tape un code (au coffre CODES du lobby) pour gagner des récompenses -------
do
	local codes = makeWindow("Codes", "CODES", "🎟️", 560, 340)
	local content = codes.Content
	label(content, { Position = UDim2.new(0, 0, 0, 14), Size = UDim2.new(1, 0, 0, 30), Text = "Enter a code for free rewards!", TextColor3 = Theme.Gold }, 2)
	local boxFrame = make("Frame", { Position = UDim2.new(0, 20, 0, 58), Size = UDim2.new(1, -40, 0, 64), BackgroundColor3 = Theme.PanelDark }, content)
	round(boxFrame, 18)
	border(boxFrame, 3, Theme.Gold)
	local box = make("TextBox", {
		Position = UDim2.new(0, 16, 0, 10),
		Size = UDim2.new(1, -32, 1, -20),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Type a code...",
		PlaceholderColor3 = Theme.SubText,
		TextColor3 = OUTLINE,
		TextScaled = true,
		Font = TITLE_FONT,
		ClearTextOnFocus = false,
	}, boxFrame)
	local redeem = fancyButton(content, "Green", "REDEEM", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 138), Size = UDim2.new(0, 220, 0, 62) })
	local result = label(content, { Position = UDim2.new(0, 0, 0, 212), Size = UDim2.new(1, 0, 0, 30), Text = "" }, 2)
	label(content, { Position = UDim2.new(0, 0, 0, 248), Size = UDim2.new(1, 0, 0, 22), Text = "Each code works once per player.", TextColor3 = Theme.SubText }, 1.5)

	local busy = false
	local function tryCode()
		local text = box.Text
		if busy or string.gsub(text, "%s", "") == "" then
			return
		end
		busy = true
		local ok, success, message = pcall(RedeemCode.InvokeServer, RedeemCode, text)
		busy = false
		if ok and success then
			result.Text = "✔ " .. message
			result.TextColor3 = ButtonStyles.Green[1]
			box.Text = ""
			toast("🎉 " .. message)
		else
			result.Text = "✖ " .. (ok and message or "Try again!")
			result.TextColor3 = ButtonStyles.Red[1]
		end
	end
	redeem.Button.Activated:Connect(tryCode)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			tryCode()
		end
	end)
	codes.OnOpen = function()
		result.Text = ""
	end
end

-- Les pets de l'inventaire ------------------------------------------------------
-- Un pet est repéré par sa clé "Nom|Trait|Niveau" (ou juste "Nom" s'il n'a pas encore de trait).

local function petInfo(key)
	local petName, trait, tier = Config.ParseKey(key)
	local pet = Config.GetPet(petName)
	return petName, pet and Config.GetRarity(pet.Rarity), trait, tier
end

-- La pastille du trait : l'icône + la lettre du niveau (D, C, B, A, S) dans sa couleur
local function traitBadge(parent, trait, tier, props)
	local tierInfo = Config.TraitTiers[tier]
	local frame = make("Frame", { Size = UDim2.new(0, 50, 0, 28), BackgroundColor3 = Theme.PanelDark }, parent)
	for key, value in props or {} do
		frame[key] = value
	end
	round(frame, 14)
	border(frame, 2, tierInfo.Color)
	icon(frame, Config.Abilities[trait].Icon, { Position = UDim2.new(0, 3, 0, 3), Size = UDim2.new(0, 22, 0, 22) })
	label(frame, { Position = UDim2.new(0, 26, 0, 3), Size = UDim2.new(0, 20, 1, -6), Text = tierInfo.Name, TextColor3 = tierInfo.Color, Font = TITLE_FONT }, 1.5)
	return frame
end

-- Les clés des pets qu'on possède, triées : les équipés d'abord, puis les meilleurs
local function ownedKeys(filter)
	local list = {}
	for key, count in (UI.state and UI.state.PetCounts) or {} do
		local _, rarity = petInfo(key)
		if count > 0 and rarity and (filter == "All" or filter == rarity.Id) then
			table.insert(list, key)
		end
	end
	table.sort(list, function(a, b)
		local ea, eb = equippedCount(a) > 0, equippedCount(b) > 0
		if ea ~= eb then
			return ea
		end
		local sa, sb = Config.PetScore(a), Config.PetScore(b)
		if sa ~= sb then
			return sa > sb
		end
		return a < b
	end)
	return list
end

-- Une carte de pet (inventaire et Trait Master). Renvoie son cadre "sélectionné".
local function petCard(parent, key, order, selectedKey, onClick)
	local petName, rarity, trait, tier = petInfo(key)
	local count = UI.state.PetCounts[key] or 0
	local equipped = equippedCount(key)
	local card = make("TextButton", { BackgroundColor3 = Theme.PanelLight, Text = "", AutoButtonColor = false, LayoutOrder = order }, parent)
	round(card, 16)
	rarityStroke(border(card, 3), rarity)
	local halo = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rarity.Color, BorderSizePixel = 0 }, card)
	round(halo, 16)
	make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.9, 0.3) }, halo)
	petViewport(card, petName, { Position = UDim2.new(0, 6, 0, 8), Size = UDim2.new(1, -12, 1, -44) })
	label(card, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -12, 0, 26),
		Text = petName,
	}, 2)
	if count > 1 then
		badge(card, "x" .. count, Theme.PanelDark, { Position = UDim2.new(0, 6, 0, 6) })
	end
	if equipped > 0 then
		badge(card, equipped > 1 and ("✔" .. equipped) or "✔", ButtonStyles.Green[2], {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 6),
		})
	end
	if trait then
		traitBadge(card, trait, tier, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -34) })
	end
	local highlight = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = key == selectedKey }, card)
	round(highlight, 16)
	make("UIStroke", { Thickness = 5, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, highlight)
	pressable(card)
	card.Activated:Connect(function()
		onClick(key)
	end)
	return highlight
end

-- La grille des pets (avec la fiche à droite), utilisée par l'inventaire et le Trait Master
local function petGrid(content, topOffset, bottomOffset)
	local grid = make("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, topOffset),
		Size = UDim2.new(1, -312, 1, -topOffset - bottomOffset),
		BackgroundColor3 = Theme.PanelDark,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Theme.Gold,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, content)
	round(grid, 16)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, grid)
	make("UIGridLayout", { CellSize = UDim2.new(0, 118, 0, 144), CellPadding = UDim2.new(0, 10, 0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	local emptyText = label(content, {
		Position = UDim2.new(0, 30, 0, topOffset + 110),
		Size = UDim2.new(1, -372, 0, 70),
		Text = "No pets here yet!\nLaunch an egg to hatch one 🥚",
		TextColor3 = Theme.SubText,
		Visible = false,
		ZIndex = 3,
	}, 2)
	local details = make("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, topOffset),
		Size = UDim2.new(0, 300, 1, -topOffset - bottomOffset),
		BackgroundColor3 = Theme.PanelDark,
	}, content)
	round(details, 18)
	local view = { Grid = grid, Details = details, Selected = nil, Cards = {} }
	view.DetailsStroke = border(details, 3, Theme.Gold)

	-- reconstruit les cartes ; onSelect est appelé quand on clique un pet
	function view.Rebuild(filter, onSelect)
		clearChildren(grid)
		table.clear(view.Cards)
		local list = ownedKeys(filter)
		for order, key in list do
			view.Cards[key] = petCard(grid, key, order, view.Selected, function(clicked)
				view.Selected = clicked
				for other, highlight in view.Cards do
					highlight.Visible = other == clicked
				end
				onSelect()
			end)
		end
		emptyText.Visible = #list == 0
		if not (view.Selected and view.Cards[view.Selected]) and list[1] then
			view.Selected = list[1]
			view.Cards[list[1]].Visible = true
		end
	end
	return view
end

-- La partie "trait" d'une fiche de pet (une boîte avec l'icône, le nom et l'effet)
local function traitBox(parent, y)
	local box = make("Frame", { Position = UDim2.new(0, 12, 0, y), Size = UDim2.new(1, -24, 0, 62), BackgroundColor3 = Theme.PanelLight }, parent)
	round(box, 14)
	local stroke = border(box, 2, Theme.Gold)
	local boxIcon = icon(box, "", { Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(0, 46, 0, 46) })
	local title = label(box, {
		Position = UDim2.new(0, 60, 0, 7),
		Size = UDim2.new(1, -68, 0, 24),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = TITLE_FONT,
	}, 2)
	local text = label(box, { Position = UDim2.new(0, 60, 0, 33), Size = UDim2.new(1, -68, 0, 22), Text = "", TextXAlignment = Enum.TextXAlignment.Left }, 1.5)
	local api = { Frame = box, Scale = make("UIScale", {}, box) }
	function api.Show(trait, tier)
		if trait then
			local tierInfo = Config.TraitTiers[tier]
			boxIcon.Text = Config.Abilities[trait].Icon
			title.Text = Config.Abilities[trait].Name .. "  " .. tierInfo.Name
			title.TextColor3 = tierInfo.Color
			stroke.Color = tierInfo.Color
			text.Text = Config.TraitText(trait, tier)
		else
			boxIcon.Text = "✨"
			title.Text = "No trait yet"
			title.TextColor3 = Theme.SubText
			stroke.Color = Color3.fromRGB(70, 90, 150)
			text.Text = ""
		end
	end
	return api
end

-- INVENTORY : tous ses pets en 3D, leurs traits, équiper / déséquiper -------------

local openInventoryCategory -- ouvre l'inventaire sur un onglet (écrite plus bas)

-- Le contenu de chaque onglet de l'inventaire (sauf PETS, construit juste en dessous).
-- Pour une nouvelle catégorie : l'ajouter dans Config.InventoryCategories, puis ici une fonction
-- qui construit la page et renvoie sa fonction de mise à jour.
local inventoryPageBuilders = {
	Potions = buildPotionsPage,
}

do
	local inventory = makeWindow("Inventory", "INVENTORY", "🎒", 920, 656)

	-- En haut : les catégories (PETS, POTIONS...). Chacune a sa page en dessous.
	local categoryBar = make("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1 }, inventory.Content)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, categoryBar)
	local pages, categoryButtons, pageRefreshers = {}, {}, {}
	local function showCategory(id)
		for pageId, page in pages do
			page.Visible = pageId == id
		end
		for buttonId, button in categoryButtons do
			button.SetStyle(buttonId == id and "Gold" or "Blue")
		end
		inventory.Refresh(false)
	end
	for order, info in Config.InventoryCategories do
		pages[info.Id] = make("Frame", { Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 1, -58), BackgroundTransparency = 1, Visible = order == 1 }, inventory.Content)
		local button = fancyButton(categoryBar, order == 1 and "Gold" or "Blue", info.Icon .. " " .. info.Name, { Size = UDim2.new(0, 200, 1, 0), LayoutOrder = order })
		button.Button.Activated:Connect(function()
			showCategory(info.Id)
		end)
		categoryButtons[info.Id] = button
		if inventoryPageBuilders[info.Id] then
			pageRefreshers[info.Id] = inventoryPageBuilders[info.Id](pages[info.Id])
		end
	end
	function openInventoryCategory(id)
		if UI.openWindowName ~= "Inventory" then
			openWindow("Inventory")
		end
		showCategory(id)
	end

	-- La page PETS
	local content = pages.Pets
	local filter = "All" -- la rareté affichée ("All" = toutes)
	local lastSignature = nil
	local view = petGrid(content, 54, 56)
	local details = view.Details
	local rebuildGrid -- (écrite plus bas)

	-- En haut : les onglets de rareté, le compteur d'équipés et "Equip Best"
	local tabs = make("Frame", { Size = UDim2.new(0, 520, 0, 40), BackgroundTransparency = 1 }, content)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabs)
	local tabButtons = {}
	local function makeTab(id, text, color, order)
		local tab = make("TextButton", { Size = UDim2.new(0, 82, 1, 0), BackgroundColor3 = color, Text = "", AutoButtonColor = false, LayoutOrder = order }, tabs)
		round(tab, 12)
		local stroke = border(tab, 3)
		label(tab, { Size = UDim2.new(1, -10, 0.62, 0), Position = UDim2.new(0, 5, 0.19, 0), Text = text, Font = TITLE_FONT }, 2)
		pressable(tab)
		tab.Activated:Connect(function()
			filter = id
			rebuildGrid()
		end)
		tabButtons[id] = { Button = tab, Stroke = stroke }
	end
	makeTab("All", "ALL", Theme.PanelLight, 0)
	for index, rarity in Config.Rarities do
		makeTab(rarity.Id, string.upper(rarity.Name), rarity.Color, index)
	end

	local equippedPill = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -170, 0, 0), Size = UDim2.new(0, 160, 0, 40), BackgroundColor3 = Theme.PanelDark }, content)
	round(equippedPill, 20)
	border(equippedPill, 3, Theme.Gold)
	local equippedText = label(equippedPill, { Size = UDim2.new(1, -16, 0.7, 0), Position = UDim2.new(0, 8, 0.15, 0), Text = "🐾 0/3 Equipped" }, 2)
	local bestButton = fancyButton(content, "Green", "EQUIP BEST", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, -2), Size = UDim2.new(0, 160, 0, 46) })
	bestButton.Button.Activated:Connect(function()
		EquipBest:FireServer()
		toast("Best pets equipped!")
	end)

	-- À droite : la fiche du pet sélectionné
	local rarityPill = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0, 160, 0, 30), BackgroundColor3 = Theme.PanelLight }, details)
	round(rarityPill, 15)
	border(rarityPill, 2)
	local rarityText = label(rarityPill, { Size = UDim2.new(1, -12, 0.72, 0), Position = UDim2.new(0, 6, 0.14, 0), Text = "", Font = TITLE_FONT }, 2)
	local viewHolder = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 44), Size = UDim2.new(0, 200, 0, 150), BackgroundTransparency = 1 }, details)
	local nameText = label(details, { Position = UDim2.new(0, 10, 0, 196), Size = UDim2.new(1, -20, 0, 30), Text = "", Font = TITLE_FONT }, 2.5)
	local ownedText = label(details, { Position = UDim2.new(0, 10, 0, 228), Size = UDim2.new(1, -20, 0, 20), Text = "", TextColor3 = Theme.SubText }, 1.5)
	local statsText = label(details, { Position = UDim2.new(0, 10, 0, 252), Size = UDim2.new(1, -20, 0, 24), Text = "", RichText = true }, 1.5)
	local trait = traitBox(details, 282)
	local equipButton = fancyButton(details, "Green", "EQUIP", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(0.5, -18, 0, 56) })
	local unequipButton = fancyButton(details, "Red", "REMOVE", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12), Size = UDim2.new(0.5, -18, 0, 56) })
	local noSelection = label(details, { Position = UDim2.new(0, 20, 0.35, 0), Size = UDim2.new(1, -40, 0, 60), Text = "Tap a pet to see\nits powers!", TextColor3 = Theme.SubText }, 1.5)
	local shownPet = nil

	-- En bas : le total des bonus de l'équipe
	local bonusBar = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, content)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, bonusBar)
	label(bonusBar, { Size = UDim2.new(0, 150, 0, 30), Text = "TEAM BONUS:", Font = TITLE_FONT, TextColor3 = Theme.Gold, LayoutOrder = 0 }, 2)
	local bonusTexts = {}
	for order, abilityId in Config.AbilityOrder do
		local _, text = bonusChip(bonusBar, abilityId, 1, { LayoutOrder = order })
		bonusTexts[abilityId] = text
	end

	local function updateDetails()
		local key = view.Selected
		local owned = key and UI.state and UI.state.PetCounts and UI.state.PetCounts[key] or 0
		local petName, rarity, traitId, tier = nil, nil, nil, nil
		if owned > 0 then
			petName, rarity, traitId, tier = petInfo(key)
		end
		for _, child in { rarityPill, viewHolder, nameText, ownedText, statsText, trait.Frame, equipButton.Button, unequipButton.Button } do
			child.Visible = rarity ~= nil
		end
		noSelection.Visible = rarity == nil
		if not rarity then
			view.DetailsStroke.Color = Theme.Gold
			return
		end
		view.DetailsStroke.Color = rarity.Color
		rarityPill.BackgroundColor3 = rarity.Color
		rarityText.Text = string.upper(rarity.Name)
		if shownPet ~= petName then
			shownPet = petName
			clearChildren(viewHolder)
			petViewport(viewHolder, petName, { Size = UDim2.fromScale(1, 1) }, { Mode = "spin", Zoom = 0.95 })
		end
		local equipped = equippedCount(key)
		nameText.Text = petName
		ownedText.Text = string.format("Owned: x%d   •   Equipped: %d", owned, equipped)
		statsText.Text = string.format("💪 <font color=\"#%s\">%s Strength</font>   💰 %s Coins", hexColor(Theme.Gold), formatMultiplier(1 + rarity.PowerBonus), formatMultiplier(1 + rarity.CoinBonus))
		trait.Show(traitId, tier)
		local slotsFull = #(UI.state.Equipped or {}) >= (UI.state.MaxEquipped or 3)
		equipButton.SetStyle((equipped < owned and not slotsFull) and "Green" or "Grey")
		unequipButton.SetStyle(equipped > 0 and "Red" or "Grey")
	end

	equipButton.Button.Activated:Connect(function()
		local key = view.Selected
		if not key or not UI.state then
			return
		end
		if #(UI.state.Equipped or {}) >= (UI.state.MaxEquipped or 3) then
			toast("All slots are full! Remove a pet first.")
		elseif equippedCount(key) >= (UI.state.PetCounts[key] or 0) then
			toast("This pet is already equipped!")
		else
			EquipPet:FireServer(key, true)
		end
	end)
	unequipButton.Button.Activated:Connect(function()
		if view.Selected and equippedCount(view.Selected) > 0 then
			EquipPet:FireServer(view.Selected, false)
		end
	end)

	function rebuildGrid()
		lastSignature = petsSignature()
		for id, tab in tabButtons do
			tab.Stroke.Color = id == filter and Color3.new(1, 1, 1) or OUTLINE
			tab.Stroke.Thickness = id == filter and 4 or 3
			tab.Button.BackgroundTransparency = id == filter and 0 or 0.35
		end
		view.Rebuild(filter, updateDetails)
	end

	inventory.OnOpen = function()
		if UI.inventoryDot then
			UI.inventoryDot.Visible = false
		end
	end

	inventory.Refresh = function(force)
		for _, refresh in pageRefreshers do
			refresh()
		end
		if force or petsSignature() ~= lastSignature then
			rebuildGrid()
		end
		equippedText.Text = string.format("🐾 %d/%d Equipped", #(UI.state and UI.state.Equipped or {}), UI.state and UI.state.MaxEquipped or 3)
		local bonuses = UI.state and UI.state.Bonuses or {}
		for abilityId, text in bonusTexts do
			local value = bonuses[abilityId] or 1
			text.Text = formatMultiplier(value)
			text.TextColor3 = value > 1.001 and Theme.Gold or Theme.SubText
		end
		updateDetails()
	end
end

-- TRAIT MASTER : donner ou changer le trait d'un pet, avec des diamants 💎 ----------
-- (les diamants se gagnent seulement avec les haltères)

do
	local traits = makeWindow("Traits", "TRAIT MASTER", "🔮", 920, 580)
	local content = traits.Content
	local lastSignature = nil
	local view = petGrid(content, 54, 0)
	local details = view.Details

	local rerollPill = make("Frame", { Size = UDim2.new(0, 190, 0, 42), BackgroundColor3 = Theme.PanelDark }, content)
	round(rerollPill, 21)
	border(rerollPill, 3, ButtonStyles.Teal[2])
	local rerollText = label(rerollPill, { Size = UDim2.new(1, -20, 0.7, 0), Position = UDim2.new(0, 10, 0.15, 0), Text = "💎 0" }, 2)
	local hint = label(content, {
		Position = UDim2.new(0, 205, 0, 4),
		Size = UDim2.new(1, -205, 0, 34),
		Text = "",
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 1.5)
	hint.TextWrapped = true

	local viewHolder = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0, 200, 0, 140), BackgroundTransparency = 1 }, details)
	local nameText = label(details, { Position = UDim2.new(0, 10, 0, 152), Size = UDim2.new(1, -20, 0, 30), Text = "", Font = TITLE_FONT }, 2.5)
	local trait = traitBox(details, 188)
	-- les chances de chaque niveau de trait
	local chances = {}
	for _, tier in Config.TraitTiers do
		table.insert(chances, string.format("<font color=\"#%s\">%s %d%%</font>", hexColor(tier.Color), tier.Name, tier.Chance))
	end
	label(details, {
		Position = UDim2.new(0, 10, 0, 258),
		Size = UDim2.new(1, -20, 0, 22),
		Text = "Chances: " .. table.concat(chances, "  "),
		RichText = true,
	}, 1.5)
	local rollButton = fancyButton(details, "Teal", "ADD TRAIT", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -24, 0, 64) })
	local busy = false

	local function cost(key)
		local _, rarity = petInfo(key)
		return rarity and Config.RerollCost[rarity.Id] or 1
	end

	local function updateDetails()
		local key = view.Selected
		local owned = key and UI.state and UI.state.PetCounts and UI.state.PetCounts[key] or 0
		details.Visible = owned > 0
		rerollText.Text = "💎 " .. formatNumber(UI.state and UI.state.Diamonds or 0)
		if owned == 0 then
			return
		end
		local petName, rarity, traitId, tier = petInfo(key)
		view.DetailsStroke.Color = rarity.Color
		if viewHolder:GetAttribute("Pet") ~= petName then
			viewHolder:SetAttribute("Pet", petName)
			clearChildren(viewHolder)
			petViewport(viewHolder, petName, { Size = UDim2.fromScale(1, 1) }, { Mode = "spin", Zoom = 0.95 })
		end
		nameText.Text = petName
		trait.Show(traitId, tier)
		rollButton.Label.Text = (traitId and "REROLL" or "ADD TRAIT") .. "  💎 " .. cost(key)
		rollButton.SetStyle((UI.state.Diamonds or 0) >= cost(key) and "Teal" or "Grey")
	end

	rollButton.Button.Activated:Connect(function()
		local key = view.Selected
		if busy or not key or not UI.state then
			return
		end
		if (UI.state.Diamonds or 0) < cost(key) then
			toast("Not enough 💎! Collect dumbbells to get more.")
			return
		end
		busy = true
		RerollTrait:FireServer(key)
		task.delay(1, function()
			busy = false
		end)
	end)

	-- Le nouveau trait arrive : la boîte du trait "pop" et un message s'affiche
	TraitRerolled.OnClientEvent:Connect(function(_, newKey)
		busy = false
		view.Selected = newKey
		lastSignature = nil
		traits.Refresh(true)
		local _, _, traitId, tier = petInfo(newKey)
		trait.Scale.Scale = 0.3
		TweenService:Create(trait.Scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		if traitId then
			toast("✨ New trait: " .. Config.Abilities[traitId].Icon .. " " .. Config.Abilities[traitId].Name .. " " .. Config.TraitTiers[tier].Name .. "!")
		end
	end)

	traits.Refresh = function(force)
		if force or petsSignature() ~= lastSignature then
			lastSignature = petsSignature()
			view.Rebuild("All", updateDetails)
		end
		updateDetails()
	end
end

-- INDEX : une ligne par rareté (comme un album). Les pets pas encore trouvés sont des ombres "??".
-- Quand toute la ligne est trouvée : bouton "Claim" -> +5 % de Force pour toujours (Config.IndexReward).

do
	local index = makeWindow("Index", "PET INDEX", "📖", 960, 620)
	local content = index.Content
	local ClaimIndex = remotes:WaitForChild("ClaimIndex")
	local lastSignature = nil
	local ROW_HEIGHT, TILE = 150, 104
	local rewardText = "+" .. math.round(Config.IndexReward.StrengthPerRow * 100) .. "%"

	local list = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Theme.Gold,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, content)
	make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	make("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 4) }, list)

	-- en bas : le bonus total et le nombre de pets trouvés
	local footer = make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.PanelDark,
	}, content)
	round(footer, 16)
	border(footer, 3, Theme.Gold)
	local boostText = label(footer, { Position = UDim2.new(0, 18, 0.15, 0), Size = UDim2.new(0.5, -18, 0.7, 0), Text = "", TextXAlignment = Enum.TextXAlignment.Left, Font = TITLE_FONT }, 2)
	local countText = label(footer, { Position = UDim2.new(0.5, 0, 0.15, 0), Size = UDim2.new(0.5, -18, 0.7, 0), Text = "", TextXAlignment = Enum.TextXAlignment.Right, Font = TITLE_FONT }, 2)

	-- la chance (en %) d'avoir ce pet en lançant à son record
	local function petChance(rarity)
		local best = UI.state and UI.state.Best or 0
		local dimension = Config.DimensionForDistance(best).Id
		local chances = Config.GetChances(Config.ToTrackDistance(best, dimension), 1)
		return (chances[rarity.Id] or 0) / #rarity.Pets
	end

	local function percentText(value)
		if value >= 10 then
			return math.round(value) .. "%"
		elseif value >= 1 then
			return string.format("%.1f%%", value)
		end
		return string.format("%.2f%%", value)
	end

	-- une case de pet : le pet en 3D (ou son ombre), la chance en haut, combien on en a en bas
	local function petTile(parent, petName, rarity, owned, count, position)
		local tile = make("Frame", { Position = position, Size = UDim2.new(0, TILE, 0, TILE), BackgroundColor3 = owned and rarity.Color:Lerp(Color3.new(1, 1, 1), 0.35) or Theme.Panel }, parent)
		round(tile, 14)
		local stroke = border(tile, 3)
		if owned then
			rarityStroke(stroke, rarity)
		end
		petViewport(tile, petName, { Position = UDim2.new(0, 6, 0, 14), Size = UDim2.new(1, -12, 1, -30) }, { Locked = not owned, Mode = owned and "sway" or "still" })
		label(tile, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.new(1, -8, 0, 22), Text = owned and percentText(petChance(rarity)) or "??", Font = TITLE_FONT, ZIndex = 3 }, 2)
		label(tile, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, -8, 0, 22), Text = owned and ("x" .. count) or "", TextColor3 = Theme.Gold, Font = TITLE_FONT, ZIndex = 3 }, 2)
		return tile
	end

	index.Refresh = function(force)
		local signature = petsSignature()
		for rarityId in (UI.state and UI.state.IndexClaimed) or {} do
			signature ..= "|" .. rarityId
		end
		if not force and signature == lastSignature then
			return
		end
		lastSignature = signature
		clearChildren(list)
		local found, total, claimed = 0, 0, 0
		for order, rarity in Config.Rarities do
			local row = make("Frame", { Size = UDim2.new(1, 0, 0, ROW_HEIGHT), BackgroundTransparency = 1, LayoutOrder = order }, list)
			-- à gauche : la ligne des pets de cette rareté
			local panel = make("Frame", { Size = UDim2.new(1, -250, 1, 0), BackgroundColor3 = rarity.Color:Lerp(Theme.PanelDark, 0.55) }, row)
			round(panel, 16)
			border(panel, 3)
			label(panel, { Position = UDim2.new(0, 14, 0, 6), Size = UDim2.new(0.6, 0, 0, 26), Text = "WORLD 1 - " .. string.upper(rarity.Name) .. " PETS", TextXAlignment = Enum.TextXAlignment.Left, Font = TITLE_FONT }, 2)
			label(panel, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 6), Size = UDim2.new(0.38, 0, 0, 26), Text = "UNLOCK ALL PETS", TextXAlignment = Enum.TextXAlignment.Right, Font = TITLE_FONT }, 2)
			local allFound = true
			for i, petName in rarity.Pets do
				total += 1
				local count = UI.state and UI.state.NameCounts and UI.state.NameCounts[petName] or 0
				if count > 0 then
					found += 1
				else
					allFound = false
				end
				petTile(panel, petName, rarity, count > 0, count, UDim2.new(0, 14 + (i - 1) * (TILE + 12), 0, 38))
			end
			local isClaimed = UI.state and UI.state.IndexClaimed and UI.state.IndexClaimed[rarity.Id]
			if isClaimed then
				claimed += 1
			elseif allFound then
				local claim = fancyButton(panel, "Green", "Claim", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.58, 0),
					Size = UDim2.new(0, 220, 0, 56),
					ZIndex = 5,
				})
				claim.Button.Activated:Connect(function()
					ClaimIndex:FireServer(rarity.Id)
				end)
			end
			-- à droite : la récompense (le pet le plus rare de la ligne + le bonus)
			local reward = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 238, 1, 0), BackgroundColor3 = Theme.PanelDark }, row)
			round(reward, 16)
			border(reward, 3, isClaimed and Theme.Gold or nil)
			label(reward, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(1, -12, 0, 26), Text = isClaimed and "✔ CLAIMED" or "REWARD", TextColor3 = isClaimed and Theme.Gold or Theme.Text, Font = TITLE_FONT }, 2)
			local rarest = rarity.Pets[#rarity.Pets]
			local rarestCount = UI.state and UI.state.NameCounts and UI.state.NameCounts[rarest] or 0
			petTile(reward, rarest, rarity, rarestCount > 0, rarestCount, UDim2.new(0, 12, 0, 38))
			local badge = make("Frame", { Position = UDim2.new(0, 128, 0, 46), Size = UDim2.new(0, 96, 0, 88), BackgroundColor3 = Theme.Panel }, reward)
			round(badge, 44)
			border(badge, 3, Theme.Gold)
			icon(badge, "💪", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.new(0, 34, 0, 34) })
			label(badge, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -10, 0, 34), Text = rewardText, Font = TITLE_FONT }, 2.5)
		end
		boostText.Text = string.format("💪 Total Index Boost: +%d%%", math.round(claimed * Config.IndexReward.StrengthPerRow * 100))
		countText.Text = string.format("Collected: %d/%d", found, total)
	end
end

-- LEADERBOARD : les meilleurs lancers du serveur -----------------------------------

do
	local board = makeWindow("Leaderboard", "TOP THROWS", "🏆", 560, 520)
	local list = make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Theme.Gold,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, board.Content)
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, list)
	local MEDALS = { Color3.fromRGB(255, 205, 60), Color3.fromRGB(205, 215, 235), Color3.fromRGB(225, 140, 80) }
	local lastSignature = nil

	board.Refresh = function(force)
		local ranking = {}
		for _, other in Players:GetPlayers() do
			local stats = other:FindFirstChild("leaderstats")
			local best = stats and stats:FindFirstChild("Best (m)")
			table.insert(ranking, { Player = other, Best = best and best.Value or 0 })
		end
		table.sort(ranking, function(a, b)
			return a.Best > b.Best
		end)
		local parts = {}
		for _, entry in ranking do
			table.insert(parts, entry.Player.UserId .. ":" .. entry.Best)
		end
		local signature = table.concat(parts, ",")
		if not force and signature == lastSignature then
			return
		end
		lastSignature = signature
		clearChildren(list)
		for rank, entry in ranking do
			local isMe = entry.Player == player
			local row = make("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = isMe and Theme.PanelLight or Theme.PanelDark, LayoutOrder = rank }, list)
			round(row, 16)
			border(row, 3, isMe and Theme.Gold or OUTLINE)
			local medal = make("Frame", { Position = UDim2.new(0, 10, 0.5, -22), Size = UDim2.new(0, 44, 0, 44), BackgroundColor3 = MEDALS[rank] or Theme.Panel }, row)
			round(medal, 22)
			border(medal, 3)
			label(medal, { Size = UDim2.new(1, -8, 0.7, 0), Position = UDim2.new(0, 4, 0.15, 0), Text = "#" .. rank, Font = TITLE_FONT }, 2)
			local head = make("ImageLabel", {
				Position = UDim2.new(0, 64, 0.5, -24),
				Size = UDim2.new(0, 48, 0, 48),
				BackgroundColor3 = Theme.Panel,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. entry.Player.UserId .. "&w=150&h=150",
			}, row)
			round(head, 24)
			border(head, 2, Theme.Gold)
			label(row, {
				Position = UDim2.new(0, 124, 0, 14),
				Size = UDim2.new(1, -270, 0, 34),
				Text = entry.Player.DisplayName,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, 2)
			local pill = make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 130, 0, 40), BackgroundColor3 = ButtonStyles.Gold[3] }, row)
			round(pill, 20)
			border(pill, 2)
			local pillFace = make("Frame", { Size = UDim2.new(1, 0, 1, -4), BackgroundColor3 = Color3.new(1, 1, 1) }, pill)
			round(pillFace, 20)
			gradient(pillFace, ButtonStyles.Gold[1], ButtonStyles.Gold[2])
			label(pillFace, { Size = UDim2.new(1, -16, 0.7, 0), Position = UDim2.new(0, 8, 0.15, 0), Text = formatNumber(entry.Best) .. " studs", Font = TITLE_FONT }, 2)
		end
	end
end

-- SETTINGS : la taille de l'interface ---------------------------------------------

local setUISize -- (utilisée aussi quand le serveur envoie la taille sauvegardée)
do
	local settings = makeWindow("Settings", "SETTINGS", "⚙️", 520, 320)
	local content = settings.Content
	label(content, { Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 34), Text = "UI SIZE", Font = TITLE_FONT, TextColor3 = Theme.Gold }, 2.5)
	local minus = fancyButton(content, "Red", "-", { Position = UDim2.new(0, 20, 0, 70), Size = UDim2.new(0, 70, 0, 64) })
	local plus = fancyButton(content, "Green", "+", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 70), Size = UDim2.new(0, 70, 0, 64) })
	local barBack = make("Frame", { Position = UDim2.new(0, 104, 0, 82), Size = UDim2.new(1, -208, 0, 40), BackgroundColor3 = Theme.PanelDark }, content)
	round(barBack, 20)
	border(barBack, 3)
	local barFill = make("Frame", { Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, barBack)
	round(barFill, 20)
	gradient(barFill, ButtonStyles.Gold[1], ButtonStyles.Gold[2])
	local valueText = label(barBack, { Size = UDim2.new(1, -16, 0.7, 0), Position = UDim2.new(0, 8, 0.15, 0), Text = "100%", Font = TITLE_FONT }, 2.5)
	local reset = fancyButton(content, "Blue", "RESET", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 160), Size = UDim2.new(0, 180, 0, 54) })

	local saveVersion = 0
	function setUISize(value, save)
		UI.uiSize = math.clamp(math.round(value * 10) / 10, 0.7, 1.3)
		updateScale()
		valueText.Text = math.round(UI.uiSize * 100) .. "%"
		barFill.Size = UDim2.fromScale((UI.uiSize - 0.7) / 0.6 * 0.9 + 0.1, 1)
		if save then
			-- on attend un peu avant de sauvegarder (si on clique plusieurs fois de suite)
			saveVersion += 1
			local version = saveVersion
			task.delay(1, function()
				if version == saveVersion then
					SetUIScale:FireServer(UI.uiSize)
				end
			end)
		end
	end
	minus.Button.Activated:Connect(function()
		setUISize(UI.uiSize - 0.1, true)
	end)
	plus.Button.Activated:Connect(function()
		setUISize(UI.uiSize + 0.1, true)
	end)
	reset.Button.Activated:Connect(function()
		setUISize(1, true)
	end)
	setUISize(1, false)
end

UI.Windows = { buyX2 = buyX2, formatTime = formatTime, openInventoryCategory = openInventoryCategory, setUISize = setUISize }

return {}
