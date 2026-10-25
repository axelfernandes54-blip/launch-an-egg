-- Shop (ModuleScript dans ServerScriptService > Server)
-- Les upgrades achetées avec les diamants 💎 (Kick Power, Magnet Range...). Le pass x2 Strength est dans PlayerData.

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


-- Les upgrades, achetées avec les diamants 💎 (voir Config.Upgrades) --------------
BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local data = playerData[player]
	local upgrade = typeof(upgradeId) == "string" and Config.GetUpgrade(upgradeId)
	if not (data and upgrade) then
		return
	end
	local level = data.Upgrades[upgrade.Id] or 0
	if level >= upgrade.MaxLevel then
		return -- déjà au maximum
	end
	local cost = Config.UpgradeCost(upgrade.Id, level)
	if data.Diamonds >= cost then
		data.Diamonds -= cost
		data.Upgrades[upgrade.Id] = level + 1
		sendState(player)
	end
end)

return {}
