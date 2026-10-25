-- ClientMain (LocalScript dans StarterPlayer > StarterPlayerScripts)
-- Le point de départ de l'interface et des effets côté joueur : il charge chaque partie (dossier Client).
--   UI           : le style et les petites fonctions de l'interface, les fenêtres
--   Windows      : Shop, Upgrades, Worlds, Inventory (PETS / POTIONS), Codes, Trait Master, Index, Leaderboard, Settings
--   Hud          : tuiles, compteurs, barre des zones, Force, minuteur de potion
--   Launch       : jauge, tir, caméra qui suit l'œuf, carte "YOU GOT..."
--   Duo          : coup de pied à deux (bouton DUO, invitation, bandeau)
--   Boards       : les classements de tous les serveurs (fenêtre touche E + écran du panneau du lobby)
--   Events       : messages du serveur et mise à jour de l'écran
--   World        : lumière, mouettes, course, barrières, haltères
--   PetFollowers : les pets qui suivent les joueurs
-- (les animations du personnage sont dans ReplicatedStorage > CharacterAnimator)

local Client = script.Parent:WaitForChild("Client")
for _, name in { "UI", "Windows", "Hud", "Launch", "Duo", "Boards", "Events", "World", "PetFollowers" } do
	local ok, problem = pcall(require, Client:WaitForChild(name))
	if not ok then
		warn("Client > " .. name .. " : " .. tostring(problem))
	end
end
