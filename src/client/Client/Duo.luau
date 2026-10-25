-- Duo (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- Le coup de pied à deux côté joueur : le bouton DUO à côté de la jauge, l'invitation (YES / NO),
-- et le bandeau "DUO with ..." qui dit quand le partenaire a relâché.

local UI = require(script.Parent.UI)
local Players, ReplicatedStorage, RunService, TweenService = UI.Players, UI.ReplicatedStorage, UI.RunService, UI.TweenService
local Config, player, gui, Theme, TITLE_FONT = UI.Config, UI.player, UI.gui, UI.Theme, UI.TITLE_FONT
local make, round, border, label, fancyButton, toast = UI.make, UI.round, UI.border, UI.label, UI.fancyButton, UI.toast

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local DuoInvite = remotes:WaitForChild("DuoInvite")
local DuoRespond = remotes:WaitForChild("DuoRespond")
local DuoLeave = remotes:WaitForChild("DuoLeave")
local DuoInvited = remotes:WaitForChild("DuoInvited")
local DuoUpdate = remotes:WaitForChild("DuoUpdate")

local partner = nil      -- le partenaire du duo (nil = pas de duo)
local nearest = nil      -- le joueur le plus proche qu'on peut inviter
local partnerReady = false

-- Sur la plateforme de tir ? (la même zone que pour tirer)
local function launchPosition(who)
	local root = who.Character and who.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local p = root.Position
	if p.X < -41 or p.X > 1 or math.abs(p.Z) > 41 then
		return nil
	end
	return p
end

-- Le bouton à droite de la jauge : DUO (inviter) ou LEAVE (quitter le duo)
local duoButton = fancyButton(gui, "Purple", "🤝 DUO", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 226, 1, -34),
	Size = UDim2.new(0, 132, 0, 46),
	Visible = false,
})

-- Le bandeau au-dessus de la jauge quand on est en duo
local banner = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -82),
	Size = UDim2.new(0, 420, 0, 36),
	BackgroundColor3 = Theme.PanelDark,
	Visible = false,
}, gui)
round(banner, 18)
local bannerStroke = border(banner, 3, Theme.Gold)
local bannerText = label(banner, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, -24, 0.72, 0),
	Text = "",
	Font = TITLE_FONT,
}, 2)

-- La fenêtre d'invitation "X wants to kick together!"
local invitePanel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.6),
	Size = UDim2.new(0, 400, 0, 150),
	BackgroundColor3 = Theme.Panel,
	Visible = false,
	ZIndex = 20,
}, gui)
round(invitePanel, 20)
border(invitePanel, 4)
local inviteText = label(invitePanel, {
	Position = UDim2.new(0, 16, 0, 14),
	Size = UDim2.new(1, -32, 0, 60),
	Text = "",
	Font = TITLE_FONT,
	ZIndex = 21,
}, 2)
local yesButton = fancyButton(invitePanel, "Green", "YES", {
	Position = UDim2.new(0, 30, 1, -66),
	Size = UDim2.new(0.5, -45, 0, 50),
	ZIndex = 21,
})
local noButton = fancyButton(invitePanel, "Red", "NO", {
	Position = UDim2.new(0.5, 15, 1, -66),
	Size = UDim2.new(0.5, -45, 0, 50),
	ZIndex = 21,
})
local inviteScale = make("UIScale", {}, invitePanel)

local currentInviter = nil
local inviteVersion = 0
local function closeInvite()
	invitePanel.Visible = false
	currentInviter = nil
end

DuoInvited.OnClientEvent:Connect(function(inviter)
	if partner then
		return
	end
	inviteVersion += 1
	local myVersion = inviteVersion
	currentInviter = inviter
	inviteText.Text = "🤝 " .. inviter.DisplayName .. " wants to kick together!"
	invitePanel.Visible = true
	inviteScale.Scale = 0.4
	TweenService:Create(inviteScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(Config.DuoKick.InviteTimeout, function()
		if myVersion == inviteVersion then
			closeInvite()
		end
	end)
end)

yesButton.Button.Activated:Connect(function()
	if currentInviter then
		DuoRespond:FireServer(currentInviter, true)
	end
	closeInvite()
end)
noButton.Button.Activated:Connect(function()
	if currentInviter then
		DuoRespond:FireServer(currentInviter, false)
	end
	closeInvite()
end)

duoButton.Button.Activated:Connect(function()
	if partner then
		DuoLeave:FireServer()
	elseif nearest then
		DuoInvite:FireServer(nearest)
	end
end)

DuoUpdate.OnClientEvent:Connect(function(info)
	local wasInDuo = partner ~= nil
	partner = info and info.Partner or nil
	partnerReady = info and info.PartnerReady or false
	if partner and not wasInDuo then
		toast("🤝 DUO with " .. partner.DisplayName .. "! Charge together!")
	end
	if partner then
		closeInvite()
	end
end)

-- Chaque image : qui peut-on inviter, et quoi afficher
RunService.RenderStepped:Connect(function()
	local myPosition = launchPosition(player)
	nearest = nil
	if myPosition and not partner then
		local best = Config.DuoKick.InviteDistance
		for _, other in Players:GetPlayers() do
			if other ~= player then
				local otherPosition = launchPosition(other)
				local distance = otherPosition and (otherPosition - myPosition).Magnitude
				if distance and distance <= best then
					best = distance
					nearest = other
				end
			end
		end
	end

	local flying = UI.trackedEgg ~= nil
	duoButton.Button.Visible = myPosition ~= nil and not flying and (partner ~= nil or nearest ~= nil)
	if partner then
		duoButton.Label.Text = "✖ LEAVE"
		duoButton.SetStyle("Red")
	else
		duoButton.Label.Text = "🤝 DUO"
		duoButton.SetStyle("Purple")
	end

	banner.Visible = partner ~= nil and myPosition ~= nil
	if partner then
		if partnerReady and not flying then
			-- le partenaire a déjà relâché : il faut relâcher vite ! (le bandeau clignote en doré)
			bannerText.Text = "⚡ " .. partner.DisplayName .. " is ready! RELEASE NOW!"
			bannerText.TextColor3 = Theme.Gold
			bannerStroke.Color = (os.clock() * 4) % 2 < 1 and Theme.Gold or Color3.new(1, 1, 1)
		else
			bannerText.Text = "🤝 DUO with " .. partner.DisplayName
			bannerText.TextColor3 = Theme.Text
			bannerStroke.Color = Theme.Gold
		end
	end
end)

return {}
