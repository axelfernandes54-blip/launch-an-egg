-- Animate (LocalScript dans StarterPlayer > StarterCharacterScripts)
-- Anime NOTRE personnage. Toutes les animations et leurs réglages sont dans
-- ReplicatedStorage > CharacterAnimator (les autres joueurs sont animés par StarterPlayerScripts > AnimateOthers).
-- Pour mettre tes propres animations : PetConfig > Config.Animations (Idle, Walk, Run, Jump, Fall, Climb).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterAnimator = require(ReplicatedStorage:WaitForChild("CharacterAnimator"))

CharacterAnimator.Start(script.Parent, true)
