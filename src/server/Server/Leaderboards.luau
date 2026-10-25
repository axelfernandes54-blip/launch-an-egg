-- Leaderboards (ModuleScript dans ServerScriptService > Server)
-- Le mur TOP THROWS (les 3 meilleurs lancers) et les tableaux TOP DISTANCE / TOP STRENGTH / TOP PETS.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))
local Data = require(script.Parent.PlayerData)
local playerData, sendState, petKey = Data.playerData, Data.sendState, Data.petKey
local getBonuses, getMultiplier, getForce, getCoinsPerSecond = Data.getBonuses, Data.getMultiplier, Data.getForce, Data.getCoinsPerSecond
local countOwned, countEquipped, equipBest = Data.countOwned, Data.countEquipped, Data.equipBest
local MapInfo = require(script.Parent.MapInfo)
local EGG_RADIUS, EGG_SCALE, LAUNCH_POINT, PLATFORM_TOP = MapInfo.EGG_RADIUS, MapInfo.EGG_SCALE, MapInfo.LAUNCH_POINT, MapInfo.PLATFORM_TOP
local PORTAL_X, PORTAL_CENTER, WORLD2_SPOT, LOBBY_BACK = MapInfo.PORTAL_X, MapInfo.PORTAL_CENTER, MapInfo.WORLD2_SPOT, MapInfo.LOBBY_BACK
local map = MapInfo.Map

-- On retrouve les places du podium et les lignes des tableaux dans la carte
local podiumSlots = {} -- [rang] = { Image, Unknown, Name, Score }
local podiumGui = map:WaitForChild("Podium"):FindFirstChildOfClass("SurfaceGui")
for rank = 1, 3 do
	local holder = podiumGui:FindFirstChild("Place" .. rank)
	if holder then
		local photo = holder:FindFirstChild("Photo")
		podiumSlots[rank] = { Image = photo, Unknown = photo:FindFirstChild("Inconnu"), Name = holder:FindFirstChild("Nom"), Score = holder:FindFirstChild("Score") }
	end
end
local leaderboards = {} -- { Rows = { TextLabel... }, Unit, Title }
for _, boardPart in CollectionService:GetTagged("Leaderboard") do
	local rows = {}
	for i = 1, 8 do
		table.insert(rows, boardPart:FindFirstChild("Ligne" .. i, true))
	end
	table.insert(leaderboards, { Rows = rows, Unit = boardPart:GetAttribute("Unit") or "", Title = boardPart:GetAttribute("Title") })
end

-- Met à jour le podium du lobby avec les 3 meilleurs records du serveur
local function updateLeaderboards()
	local values = {
		["TOP DISTANCE"] = function(data) return data.Best end,
		["TOP STRENGTH"] = function(data) return math.floor(getForce(data)) end,
		["TOP PETS"] = function(data) return #data.Pets end,
	}
	for _, board in leaderboards do
		local ranking = {}
		for player, data in playerData do
			table.insert(ranking, { Name = player.DisplayName, Value = values[board.Title](data) })
		end
		table.sort(ranking, function(a, b)
			return a.Value > b.Value
		end)
		for rank, row in board.Rows do
			local entry = ranking[rank]
			row.Text = entry and string.format("%d. %s  -  %s%s", rank, entry.Name, tostring(entry.Value), board.Unit) or ""
		end
	end
end

local function updatePodium()
	local ranking = {}
	for player, data in playerData do
		if data.Best > 0 then
			table.insert(ranking, { Player = player, Best = data.Best })
		end
	end
	table.sort(ranking, function(a, b)
		return a.Best > b.Best
	end)
	for rank, slot in podiumSlots do
		local entry = ranking[rank]
		slot.Unknown.Visible = entry == nil
		if entry then
			slot.Image.Image = "rbxthumb://type=AvatarHeadShot&id=" .. entry.Player.UserId .. "&w=150&h=150"
			slot.Name.Text = entry.Player.DisplayName
			slot.Score.Text = entry.Best .. " studs"
		else
			slot.Image.Image = ""
			slot.Name.Text = "—"
			slot.Score.Text = ""
		end
	end
end

return {
	Update = function()
		updatePodium()
		updateLeaderboards()
	end,
}
