-- PotionsCodes (ModuleScript dans ServerScriptService > Server)
-- Les potions (boire une potion = x2 Force des haltères) et les CODES (le coffre du lobby).

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

local codesPrompt = CollectionService:GetTagged("CodesPrompt")[1] -- le coffre CODES du lobby

-- 4c) Les potions et les codes ----------------------------------------------

-- Boire une potion : son temps s'ajoute à celui qui reste
UsePotion.OnServerEvent:Connect(function(player, potionId)
	local data = playerData[player]
	local potion = type(potionId) == "string" and Config.GetPotion(potionId)
	if data and potion and (data.Potions[potion.Id] or 0) > 0 then
		data.Potions[potion.Id] -= 1
		data.BoostTime += potion.Minutes * 60
		sendState(player)
	end
end)

if codesPrompt then
	codesPrompt.Triggered:Connect(function(player)
		OpenCodes:FireClient(player)
	end)
end

local lastCodeTry = {} -- [player] = moment du dernier essai (anti-spam)
RedeemCode.OnServerInvoke = function(player, text)
	local data = playerData[player]
	if not data or type(text) ~= "string" or #text > 40 then
		return false, "Try again!"
	end
	if lastCodeTry[player] and os.clock() - lastCodeTry[player] < 1 then
		return false, "Slow down, matey!"
	end
	lastCodeTry[player] = os.clock()
	local code = string.upper((string.gsub(text, "%s", "")))
	local reward = Config.Codes[code]
	if not reward then
		return false, "Invalid code!"
	end
	if data.Codes[code] then
		return false, "Already redeemed!"
	end
	data.Codes[code] = true
	local gifts = {}
	for _, potion in Config.Potions do
		local count = tonumber(reward[potion.Id]) or 0
		if count > 0 then
			data.Potions[potion.Id] = (data.Potions[potion.Id] or 0) + count
			table.insert(gifts, string.format("%dx %s Potion", count, potion.Name))
		end
	end
	if (tonumber(reward.Rerolls) or 0) > 0 then
		data.Rerolls += reward.Rerolls
		table.insert(gifts, "+" .. reward.Rerolls .. " 💎")
	end
	if (tonumber(reward.Coins) or 0) > 0 then
		data.Coins += reward.Coins
		table.insert(gifts, "+" .. reward.Coins .. " 💰")
	end
	sendState(player)
	return true, table.concat(gifts, " + ")
end
Players.PlayerRemoving:Connect(function(player)
	lastCodeTry[player] = nil
end)

return {}
