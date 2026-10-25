-- GlobalBoards (ModuleScript dans ServerScriptService > Server)
-- Les classements de TOUS les serveurs (le grand panneau du lobby, touche E) : "Weekly" et "Lifetime".
-- Chaque classement est un OrderedDataStore : "LB_<Id>" (pour toujours) et "LB_<Id>_W<semaine>" (la semaine).
-- Toutes les minutes : on écrit les scores des joueurs du serveur, puis on lit les 10 meilleurs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))
local Remotes = require(script.Parent.Remotes)
local Data = require(script.Parent.PlayerData)
local playerData = Data.playerData

local GlobalBoards = {}

-- La valeur de chaque classement pour un joueur : { Lifetime, Weekly }
local VALUES = {
	Throw = function(data) return data.Best, Data.getWeekly(data).Best end,
	Strength = function(data) return math.floor(Data.getForce(data)), Data.getWeekly(data).Strength end,
	Launches = function(data) return data.Launches, Data.getWeekly(data).Launches end,
	Robux = function(data) return data.RobuxSpent, Data.getWeekly(data).Robux end,
}

local function storeName(boardId, weekly)
	return "LB_" .. boardId .. (weekly and ("_W" .. Config.CurrentWeek()) or "")
end

local stores = {}
local function getStore(name)
	if not stores[name] then
		stores[name] = DataStoreService:GetOrderedDataStore(name)
	end
	return stores[name]
end

-- Ce qu'on envoie aux joueurs : [Id] = { Lifetime = { {UserId, Name, Value}, ... }, Weekly = {...} }
local results = {}
local names = {} -- [UserId] = nom affiché (pour ne pas le redemander)
local lastWritten = {} -- [store .. UserId] = dernière valeur écrite

local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.DisplayName
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = ok and name or ("Player " .. userId)
	return names[userId]
end

local function writeScores()
	for player, data in playerData do
		if data.Loaded then
			for _, board in Config.Leaderboards do
				local lifetime, weekly = VALUES[board.Id](data)
				for _, entry in { { false, lifetime }, { true, weekly } } do
					local name = storeName(board.Id, entry[1])
					local value = math.floor(entry[2] or 0)
					local key = name .. "|" .. player.UserId
					if value > 0 and lastWritten[key] ~= value then
						local ok, problem = pcall(function()
							getStore(name):SetAsync(tostring(player.UserId), value)
						end)
						if ok then
							lastWritten[key] = value
						elseif not tostring(problem):find("Studio access") then
							warn("Classement " .. name .. " : " .. tostring(problem))
						end
					end
				end
			end
		end
	end
end

local function readScores()
	for _, board in Config.Leaderboards do
		results[board.Id] = results[board.Id] or {}
		for _, weekly in { false, true } do
			local ok, page = pcall(function()
				return getStore(storeName(board.Id, weekly)):GetSortedAsync(false, Config.LeaderboardSize):GetCurrentPage()
			end)
			if ok then
				local list = {}
				for _, row in page do
					local userId = tonumber(row.key)
					if userId then
						table.insert(list, { UserId = userId, Name = nameOf(userId), Value = row.value })
					end
				end
				results[board.Id][weekly and "Weekly" or "Lifetime"] = list
			end
		end
	end
	Remotes.LeaderboardsData:FireAllClients(results)
end

-- Les scores du joueur lui-même (la ligne en bas de la fenêtre)
function GlobalBoards.MyScores(data)
	local mine = {}
	for _, board in Config.Leaderboards do
		local lifetime, weekly = VALUES[board.Id](data)
		mine[board.Id] = { Lifetime = math.floor(lifetime or 0), Weekly = math.floor(weekly or 0) }
	end
	return mine
end

-- Le panneau du lobby : "E" ouvre la fenêtre des classements
local function addPrompt(model)
	if model:FindFirstChildWhichIsA("ProximityPrompt", true) then
		return
	end
	local screen = nil
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name:find("Screen") then
			screen = part
		end
	end
	local holder = screen or model:FindFirstChildWhichIsA("BasePart", true)
	if not holder then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Open UI"
	prompt.ActionText = "Leaderboards"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = holder
	prompt.Triggered:Connect(function(player)
		Remotes.OpenLeaderboards:FireClient(player)
	end)
end
for _, model in CollectionService:GetTagged("GlobalLeaderboard") do
	addPrompt(model)
end
CollectionService:GetInstanceAddedSignal("GlobalLeaderboard"):Connect(addPrompt)

-- Un joueur qui arrive reçoit tout de suite les classements déjà lus
Players.PlayerAdded:Connect(function(player)
	task.delay(5, function()
		if player.Parent then
			Remotes.LeaderboardsData:FireClient(player, results)
		end
	end)
end)

task.spawn(function()
	task.wait(8) -- on laisse les sauvegardes se charger
	while true do
		writeScores()
		readScores()
		task.wait(60)
	end
end)

return GlobalBoards
