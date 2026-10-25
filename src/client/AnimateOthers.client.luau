-- AnimateOthers (LocalScript dans StarterPlayer > StarterPlayerScripts)
-- Les animations faites par script ne se voient que sur l'écran où elles sont calculées :
-- chaque joueur anime donc aussi les personnages des AUTRES joueurs (voir ReplicatedStorage > CharacterAnimator).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterAnimator = require(ReplicatedStorage:WaitForChild("CharacterAnimator"))

local function watch(other)
	if other == Players.LocalPlayer then
		return
	end
	other.CharacterAdded:Connect(function(character)
		CharacterAnimator.Start(character, false)
	end)
	if other.Character then
		task.spawn(CharacterAnimator.Start, other.Character, false)
	end
end

Players.PlayerAdded:Connect(watch)
for _, other in Players:GetPlayers() do
	watch(other)
end
