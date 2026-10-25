-- Shop (ModuleScript dans ServerScriptService > Server)
-- Les améliorations achetées avec les pièces (Power Up). Le pass x2 Strength est dans PlayerData.

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

local upgradePrompt = nil -- (l'ancien stand "Force +" du lobby n'existe plus)

-- 5) L'amélioration "Force +" -------------------------------------------------

local function buyUpgrade(player)
	local data = playerData[player]
	if not data then
		return
	end
	local cost = Config.UpgradeCost(data.UpgradeLevel)
	if data.Coins >= cost then
		data.Coins -= cost
		data.UpgradeLevel += 1
		sendState(player)
	end
end

-- On peut acheter avec le bouton de l'écran ou au stand "FORCE +" du lobby
BuyUpgrade.OnServerEvent:Connect(buyUpgrade)
if upgradePrompt then
	upgradePrompt.Triggered:Connect(buyUpgrade)
end

return {}
