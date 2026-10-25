-- Traits (ModuleScript dans ServerScriptService > Server)
-- Le Trait Master : donner / changer le trait d'un pet contre des Rerolls (💎).

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

-- Parler au Trait Master (touche E) ouvre sa fenêtre
for _, prompt in CollectionService:GetTagged("TraitMasterPrompt") do
	prompt.Triggered:Connect(function(player)
		OpenTraits:FireClient(player)
	end)
end

-- Donner / changer le trait d'un pet chez le Trait Master (payé en pièces du jeu, jamais en Robux)
RerollTrait.OnServerEvent:Connect(function(player, key)
	local data = playerData[player]
	if not data or typeof(key) ~= "string" then
		return
	end
	-- il faut être à côté du Trait Master (anti-triche)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - Config.TraitMasterPosition).Magnitude > 30 then
		return
	end
	local target = nil
	for _, pet in data.Pets do
		if petKey(pet) == key then
			target = pet
			break
		end
	end
	if not target then
		return
	end
	local cost = Config.RerollCost[target.Rarity] or 1
	if data.Rerolls < cost then
		return
	end
	data.Rerolls -= cost
	target.Trait, target.Tier = Config.RollTrait()
	local newKey = petKey(target)
	-- si ce pet était équipé, l'équipement suit son nouveau trait
	if countEquipped(data, key) > countOwned(data, key) then
		local index = table.find(data.Equipped, key)
		if index then
			data.Equipped[index] = newKey
		end
	end
	sendState(player)
	TraitRerolled:FireClient(player, key, newKey)
end)

-- Outil de test (seulement dans Studio) : chaque joueur reçoit 5 Rerolls 📜 en arrivant,
-- pour essayer le Trait Master. Dans le vrai jeu (publié), ça ne fait rien.
if game:GetService("RunService"):IsStudio() then
	task.spawn(function()
		while true do
			task.wait(3)
			for player, data in playerData do
				if not data.TestRerollsGiven then
					data.TestRerollsGiven = true
					data.Rerolls = math.max(data.Rerolls, 5)
					sendState(player)
				end
			end
		end
	end)
end

return {}
