-- Pets (ModuleScript dans ServerScriptService > Server)
-- L'inventaire des pets : équiper / déséquiper un pet, et "Equip Best".

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

-- 4b) L'inventaire : équiper / déséquiper les pets -----------------------------

EquipPet.OnServerEvent:Connect(function(player, petName, equip)
	local data = playerData[player]
	if not data or typeof(petName) ~= "string" then
		return
	end
	if equip == true then
		if #data.Equipped >= Config.Launch.MaxEquipped or countEquipped(data, petName) >= countOwned(data, petName) then
			return -- plus de place, ou on n'a pas d'autre exemplaire de ce pet
		end
		table.insert(data.Equipped, petName)
	else
		local index = table.find(data.Equipped, petName)
		if index then
			table.remove(data.Equipped, index)
		end
	end
	sendState(player)
end)

EquipBest.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if data then
		equipBest(data)
		sendState(player)
	end
end)

-- L'Index : quand tous les pets d'une rareté ont été trouvés, on réclame la récompense (une seule fois)
Remotes.ClaimIndex.OnServerEvent:Connect(function(player, rarityId)
	local data = playerData[player]
	if not data or typeof(rarityId) ~= "string" or data.IndexClaimed[rarityId] then
		return
	end
	local rarity = nil
	for _, candidate in Config.Rarities do
		if candidate.Id == rarityId then
			rarity = candidate
		end
	end
	if not rarity then
		return
	end
	for _, petName in rarity.Pets do
		local found = false
		for _, pet in data.Pets do
			if pet.Name == petName then
				found = true
				break
			end
		end
		if not found then
			return -- il manque encore un pet de cette ligne
		end
	end
	data.IndexClaimed[rarityId] = true
	ShowMessage:FireClient(player, string.format("📖 +%d%% Strength forever!", math.round(Config.IndexReward.StrengthPerRow * 100)))
	sendState(player)
end)

return {}
