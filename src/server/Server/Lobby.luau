-- Lobby (ModuleScript dans ServerScriptService > Server)
-- Le lobby : les portails du World 2 (entrée et retour) et le panneau THROW HERE qui bouge.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))
local Remotes = require(script.Parent.Remotes)
local LaunchEgg, BuyUpgrade, EggLaunched, EggLanded, StateChanged = Remotes.LaunchEgg, Remotes.BuyUpgrade, Remotes.EggLaunched, Remotes.EggLanded, Remotes.StateChanged
local DumbbellCollected, EquipPet, EquipBest, RerollTrait, TraitRerolled = Remotes.DumbbellCollected, Remotes.EquipPet, Remotes.EquipBest, Remotes.RerollTrait, Remotes.TraitRerolled
local OpenTraits, SetUIScale, World2Unlocked, ShowMessage = Remotes.OpenTraits, Remotes.SetUIScale, Remotes.World2Unlocked, Remotes.ShowMessage
local UsePotion, OpenCodes, RedeemCode = Remotes.UsePotion, Remotes.OpenCodes, Remotes.RedeemCode
local Data = require(script.Parent.PlayerData)
local playerData, sendState, petKey = Data.playerData, Data.sendState, Data.petKey
local getBonuses, getMultiplier, getForce, getCoinsPerSecond = Data.getBonuses, Data.getMultiplier, Data.getForce, Data.getCoinsPerSecond
local countOwned, countEquipped, equipBest = Data.countOwned, Data.countEquipped, Data.equipBest
local MapInfo = require(script.Parent.MapInfo)
local EGG_RADIUS, EGG_SCALE, LAUNCH_POINT, PLATFORM_TOP = MapInfo.EGG_RADIUS, MapInfo.EGG_SCALE, MapInfo.LAUNCH_POINT, MapInfo.PLATFORM_TOP
local PORTAL_X, PORTAL_CENTER, WORLD2_SPOT, LOBBY_BACK = MapInfo.PORTAL_X, MapInfo.PORTAL_CENTER, MapInfo.WORLD2_SPOT, MapInfo.LOBBY_BACK
local map = MapInfo.Map

-- Le panneau "THROW HERE!" monte et descend doucement
local throwSign = map:FindFirstChild("PanneauTir")
local throwBillboard = throwSign and throwSign:FindFirstChildOfClass("BillboardGui")
if throwBillboard then
	TweenService:Create(throwBillboard, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		StudsOffset = Vector3.new(0, 1.5, 0),
	}):Play()
end

-- Le portail "Back to Lobby" de la zone World 2
for _, prompt in CollectionService:GetTagged("ReturnPrompt") do
	prompt.Triggered:Connect(function(player)
		if player.Character then
			player.Character:PivotTo(MapInfo.LOBBY_SPAWN)
		end
	end)
end


-- Le portail du lobby : il ouvre la fenêtre des WORLDS (on achète un world avec des pièces 💰, puis on y va)
-- (les dimensions, elles, sont libres : on y arrive avec sa Force)
local OpenWorlds, ChooseWorld = Remotes.OpenWorlds, Remotes.ChooseWorld
for _, prompt in CollectionService:GetTagged("World2Prompt") do
	prompt.ActionText = "Worlds"
	prompt.Triggered:Connect(function(player)
		OpenWorlds:FireClient(player)
	end)
end

ChooseWorld.OnServerEvent:Connect(function(player, worldId)
	local data = playerData[player]
	local world = typeof(worldId) == "number" and Config.GetWorld(worldId)
	if not data or data.Busy or not world then
		return
	end
	if not data.UnlockedWorlds[world.Id] then
		-- il faut l'acheter avec des pièces (et avoir le world d'avant)
		local previous = Config.GetWorld(world.Id - 1)
		if previous and not data.UnlockedWorlds[previous.Id] then
			ShowMessage:FireClient(player, "🔒 Unlock " .. previous.Name .. " first!")
			return
		end
		if data.Coins < world.Cost then
			ShowMessage:FireClient(player, "Not enough coins!")
			return
		end
		data.Coins -= world.Cost
		data.UnlockedWorlds[world.Id] = true
		ShowMessage:FireClient(player, "🌍 " .. world.Name .. " UNLOCKED!")
		sendState(player)
	end
	if player.Character then
		if world.Id == 1 then
			player.Character:PivotTo(MapInfo.LOBBY_SPAWN)
		else
			-- le World 2 n'est pas encore construit : on va dans la zone "Coming soon"
			player.Character:PivotTo(CFrame.new(WORLD2_SPOT + Vector3.new(0, 4, 10)))
		end
	end
end)

return {}
