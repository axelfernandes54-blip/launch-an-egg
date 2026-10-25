-- Boards (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- Les classements de tous les serveurs : la fenêtre (touche E au grand panneau du lobby)
-- avec les boutons pour choisir le classement, Weekly / Lifetime, et l'écran du panneau dans le lobby.

local UI = require(script.Parent.UI)
local Players, ReplicatedStorage, RunService, TweenService = UI.Players, UI.ReplicatedStorage, UI.RunService, UI.TweenService
local CollectionService = game:GetService("CollectionService")
local Config, player, Theme, ButtonStyles, TITLE_FONT, NUMBER_FONT = UI.Config, UI.player, UI.Theme, UI.ButtonStyles, UI.TITLE_FONT, UI.NUMBER_FONT
local make, round, border, label, icon, fancyButton, formatNumber, gradient = UI.make, UI.round, UI.border, UI.label, UI.icon, UI.fancyButton, UI.formatNumber, UI.gradient
local makeWindow, openWindow = UI.makeWindow, UI.openWindow

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local results = {} -- [Id] = { Lifetime = { {UserId, Name, Value} }, Weekly = {...} }
local RANK_COLORS = { Color3.fromRGB(255, 215, 60), Color3.fromRGB(215, 220, 235), Color3.fromRGB(205, 140, 80) }

local function headshot(userId)
	return "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
end

-- Mon score dans ce classement (pour la ligne du bas)
local function myScore(boardId, weekly)
	local state = UI.state
	if not state then
		return 0
	end
	local week = state.Weekly or {}
	if boardId == "Throw" then
		return weekly and (week.Best or 0) or (state.Best or 0)
	elseif boardId == "Strength" then
		return weekly and (week.Strength or 0) or (state.Force or 0)
	elseif boardId == "Launches" then
		return weekly and (week.Launches or 0) or (state.Launches or 0)
	elseif boardId == "Robux" then
		return weekly and (week.Robux or 0) or (state.RobuxSpent or 0)
	end
	return 0
end

local function timeLeftText()
	local seconds = Config.WeekSecondsLeft()
	local days, hours, minutes = seconds // 86400, seconds % 86400 // 3600, seconds % 3600 // 60
	if days > 0 then
		return string.format("Week ends in %dd %dh %dm", days, hours, minutes)
	end
	return string.format("Week ends in %dh %dm", hours, minutes)
end

-- LA FENÊTRE ------------------------------------------------------------------------
local selected = Config.Leaderboards[1].Id
local weeklyMode = true

local window = makeWindow("GlobalBoards", "LEADERBOARDS", "🏆", 960, 620)
local content = window.Content

-- le grand panneau de couleur (à gauche)
local panel = make("Frame", { Size = UDim2.new(1, -250, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1) }, content)
round(panel, 20)
border(panel, 4)
local panelGradient = gradient(panel, Color3.new(1, 1, 1), Color3.new(1, 1, 1))
local title = label(panel, { Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -32, 0, 46), Text = "", Font = TITLE_FONT }, 3)
local headerHash = label(panel, { Position = UDim2.new(0, 20, 0, 60), Size = UDim2.new(0, 30, 0, 30), Text = "#", Font = TITLE_FONT }, 2)
label(panel, { Position = UDim2.new(0, 70, 0, 60), Size = UDim2.new(0, 220, 0, 30), Text = "USERNAME", TextXAlignment = Enum.TextXAlignment.Left, Font = TITLE_FONT }, 2)
local headerValue = label(panel, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 60), Size = UDim2.new(0, 200, 0, 30), Text = "", TextXAlignment = Enum.TextXAlignment.Right, Font = TITLE_FONT }, 2)

local list = make("ScrollingFrame", {
	Position = UDim2.new(0, 10, 0, 96),
	Size = UDim2.new(1, -20, 1, -210),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
}, panel)
make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

-- une ligne : rang, tête, nom, score
local function row(parent, rank, userId, name, value, props)
	local frame = make("Frame", { Size = UDim2.new(1, -8, 0, 42), BackgroundTransparency = 1, LayoutOrder = rank or 99 }, parent)
	for key, val in props or {} do
		frame[key] = val
	end
	if rank then
		label(frame, { Position = UDim2.new(0, 4, 0.1, 0), Size = UDim2.new(0, 44, 0.8, 0), Text = rank .. ".", TextXAlignment = Enum.TextXAlignment.Left, Font = TITLE_FONT, TextColor3 = RANK_COLORS[rank] or Theme.Text }, 2)
	end
	local face = make("ImageLabel", { Position = UDim2.new(0, 54, 0, 1), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1, Image = headshot(userId) }, frame)
	round(face, 20)
	label(frame, { Position = UDim2.new(0, 104, 0.1, 0), Size = UDim2.new(0.6, -104, 0.8, 0), Text = name, TextXAlignment = Enum.TextXAlignment.Left, Font = TITLE_FONT, TextColor3 = RANK_COLORS[rank] or Theme.Text }, 2)
	label(frame, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0.1, 0), Size = UDim2.new(0.38, 0, 0.8, 0), Text = formatNumber(value), TextXAlignment = Enum.TextXAlignment.Right, Font = TITLE_FONT }, 2)
	return frame
end

-- en bas : ma ligne, puis le temps qui reste dans la semaine
local mine = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -54), Size = UDim2.new(1, -20, 0, 50), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.7 }, panel)
round(mine, 12)
border(mine, 2)
local footer = label(panel, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -30, 0, 40), Text = "", Font = TITLE_FONT, TextColor3 = Color3.fromRGB(120, 210, 255) }, 3)

-- à droite : choisir le classement, puis Weekly / Lifetime
local side = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 236, 1, 0), BackgroundTransparency = 1 }, content)
make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, side)
local boardButtons = {}
for index, board in Config.Leaderboards do
	local button = fancyButton(side, "Blue", board.Icon .. " " .. board.Title, { Size = UDim2.new(1, 0, 0, 58), LayoutOrder = index })
	button.Button.Activated:Connect(function()
		selected = board.Id
		window.Refresh(true)
	end)
	boardButtons[board.Id] = button
end
make("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundTransparency = 1, LayoutOrder = 10 }, side)
local weeklyButton = fancyButton(side, "Purple", "📅 Weekly Board", { Size = UDim2.new(1, 0, 0, 58), LayoutOrder = 11 })
local lifetimeButton = fancyButton(side, "Gold", "🏆 Lifetime Board", { Size = UDim2.new(1, 0, 0, 58), LayoutOrder = 12 })
weeklyButton.Button.Activated:Connect(function()
	weeklyMode = true
	window.Refresh(true)
end)
lifetimeButton.Button.Activated:Connect(function()
	weeklyMode = false
	window.Refresh(true)
end)

local function getBoard(id)
	for _, board in Config.Leaderboards do
		if board.Id == id then
			return board
		end
	end
	return Config.Leaderboards[1]
end

window.Refresh = function()
	local board = getBoard(selected)
	panelGradient.Color = ColorSequence.new(board.Color:Lerp(Color3.new(1, 1, 1), 0.15), board.Color:Lerp(Color3.new(0, 0, 0), 0.25))
	title.Text = (weeklyMode and "WEEKLY: " or "LIFETIME: ") .. board.Title
	headerValue.Text = board.Column
	for id, button in boardButtons do
		button.SetStyle(id == selected and "Green" or "Blue")
	end
	weeklyButton.SetStyle(weeklyMode and "Purple" or "Grey")
	lifetimeButton.SetStyle(weeklyMode and "Grey" or "Gold")

	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local entries = results[board.Id] and results[board.Id][weeklyMode and "Weekly" or "Lifetime"] or {}
	for rank, entry in entries do
		row(list, rank, entry.UserId, entry.Name, entry.Value)
	end
	if #entries == 0 then
		label(list, { Size = UDim2.new(1, 0, 0, 40), Text = "Loading...", TextColor3 = Theme.SubText }, 2)
	end
	for _, child in mine:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	row(mine, nil, player.UserId, player.DisplayName, myScore(board.Id, weeklyMode), { Position = UDim2.new(0, 0, 0, 4) })
	footer.Text = weeklyMode and timeLeftText() or "All-time best players"
end

-- L'ÉCRAN DU PANNEAU DANS LE LOBBY : il montre un classement après l'autre ----------------
local screens = {} -- { Gui, Title, Rows }
local function setupBoard(model)
	local screen = nil
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name:find("Screen") then
			screen = part
		end
	end
	if not screen then
		-- (avec le streaming, l'écran peut arriver un peu après le panneau : on réessaie quand il arrive)
		local connection
		connection = model.DescendantAdded:Connect(function(part)
			if part:IsA("BasePart") and part.Name:find("Screen") then
				connection:Disconnect()
				setupBoard(model)
			end
		end)
		return
	end
	if screens[screen] then
		return
	end
	local gui = make("SurfaceGui", {
		Name = "Classement",
		Face = Enum.NormalId[model:GetAttribute("ScreenFace") or "Front"],
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 40,
		LightInfluence = 0,
		Adornee = screen,
	}, player:WaitForChild("PlayerGui"))
	local back = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) }, gui)
	local backGradient = gradient(back, Color3.new(1, 1, 1), Color3.new(1, 1, 1))
	local boardTitle = label(back, { Position = UDim2.new(0.04, 0, 0.02, 0), Size = UDim2.new(0.92, 0, 0.09, 0), Text = "", Font = TITLE_FONT }, 4)
	local rows = {}
	for i = 1, Config.LeaderboardSize do
		rows[i] = label(back, {
			Position = UDim2.new(0.06, 0, 0.13 + (i - 1) * 0.075, 0),
			Size = UDim2.new(0.88, 0, 0.065, 0),
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = TITLE_FONT,
			TextColor3 = RANK_COLORS[i] or Theme.Text,
		}, 3)
	end
	local hint = label(back, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.98, 0), Size = UDim2.new(0.9, 0, 0.07, 0), Text = "Press E to see all leaderboards", TextColor3 = Color3.fromRGB(255, 240, 180), Font = TITLE_FONT }, 3)
	screens[screen] = { Gui = gui, Gradient = backGradient, Title = boardTitle, Rows = rows, Hint = hint }
end
for _, model in CollectionService:GetTagged("GlobalLeaderboard") do
	task.spawn(setupBoard, model)
end
CollectionService:GetInstanceAddedSignal("GlobalLeaderboard"):Connect(setupBoard)

local shownIndex = 1
local function updateScreens()
	local board = Config.Leaderboards[shownIndex]
	local entries = results[board.Id] and results[board.Id].Weekly or {}
	for screen, view in screens do
		if not screen.Parent then
			view.Gui:Destroy()
			screens[screen] = nil
			continue
		end
		view.Gradient.Color = ColorSequence.new(board.Color:Lerp(Color3.new(1, 1, 1), 0.15), board.Color:Lerp(Color3.new(0, 0, 0), 0.3))
		view.Title.Text = "WEEKLY: " .. board.Title
		for i, rowLabel in view.Rows do
			local entry = entries[i]
			rowLabel.Text = entry and string.format("%d. %s  -  %s", i, entry.Name, formatNumber(entry.Value)) or ""
		end
	end
end
task.spawn(function()
	while true do
		updateScreens()
		task.wait(8)
		shownIndex = shownIndex % #Config.Leaderboards + 1
	end
end)

remotes:WaitForChild("LeaderboardsData").OnClientEvent:Connect(function(newResults)
	results = newResults or {}
	updateScreens()
	if UI.openWindowName == "GlobalBoards" then
		window.Refresh(true)
	end
end)

remotes:WaitForChild("OpenLeaderboards").OnClientEvent:Connect(function()
	if UI.openWindowName ~= "GlobalBoards" then
		openWindow("GlobalBoards")
	end
end)

-- le temps qui reste dans la semaine se met à jour toutes les 30 s
task.spawn(function()
	while true do
		task.wait(30)
		if UI.openWindowName == "GlobalBoards" and weeklyMode then
			footer.Text = timeLeftText()
		end
	end
end)

return {}
