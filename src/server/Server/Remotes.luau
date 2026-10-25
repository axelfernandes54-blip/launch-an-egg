-- Remotes (ModuleScript dans ServerScriptService > Server)
-- Crée tous les RemoteEvents (le client et le serveur se parlent avec eux, dans ReplicatedStorage > Remotes).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local LaunchEgg = makeRemote("LaunchEgg")       -- client -> serveur : "je lance avec cette puissance"
local BuyUpgrade = makeRemote("BuyUpgrade")     -- client -> serveur : "j'achète Force +"
local EggLaunched = makeRemote("EggLaunched")   -- serveur -> client : "voici ton œuf en vol"
local EggLanded = makeRemote("EggLanded")       -- serveur -> client : "ton œuf a atterri, voici ton pet"
local StateChanged = makeRemote("StateChanged") -- serveur -> client : pièces, pets, bonus...
local DumbbellCollected = makeRemote("DumbbellCollected") -- serveur -> clients : "une haltère vient d'être ramassée"
local EquipPet = makeRemote("EquipPet")         -- client -> serveur : "équipe / déséquipe ce pet"
local EquipBest = makeRemote("EquipBest")       -- client -> serveur : "équipe mes meilleurs pets"
local RerollTrait = makeRemote("RerollTrait")   -- client -> serveur : "change le trait de ce pet" (payé en pièces)
local TraitRerolled = makeRemote("TraitRerolled") -- serveur -> client : "voici le nouveau trait"
local OpenTraits = makeRemote("OpenTraits")     -- serveur -> client : "ouvre la fenêtre du Trait Master"
local SetUIScale = makeRemote("SetUIScale")     -- client -> serveur : "garde ma taille d'interface"
local World2Unlocked = makeRemote("World2Unlocked") -- serveur -> client : "ton œuf a touché le portail : monde 2 débloqué !"
local ShowMessage = makeRemote("ShowMessage")   -- serveur -> client : un petit message à afficher
local UsePotion = makeRemote("UsePotion")       -- client -> serveur : "je bois cette potion"
local OpenCodes = makeRemote("OpenCodes")       -- serveur -> client : "ouvre la fenêtre des codes"
local RedeemCode = Instance.new("RemoteFunction") -- client -> serveur : "j'essaie ce code" (le serveur répond)
RedeemCode.Name = "RedeemCode"
RedeemCode.Parent = remotes
return {
	LaunchEgg = LaunchEgg, BuyUpgrade = BuyUpgrade, EggLaunched = EggLaunched, EggLanded = EggLanded,
	StateChanged = StateChanged, DumbbellCollected = DumbbellCollected, EquipPet = EquipPet, EquipBest = EquipBest,
	RerollTrait = RerollTrait, TraitRerolled = TraitRerolled, OpenTraits = OpenTraits, SetUIScale = SetUIScale,
	World2Unlocked = World2Unlocked, ShowMessage = ShowMessage, UsePotion = UsePotion, OpenCodes = OpenCodes,
	RedeemCode = RedeemCode,
}
