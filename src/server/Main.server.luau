-- Main (Script dans ServerScriptService)
-- Le point de départ du serveur : il charge chaque partie du jeu (dossier ServerScriptService > Server),
-- puis, chaque seconde, fait couler le temps des potions et met à jour les classements.
-- La carte (sol, piste, stands...) est déjà construite dans Workspace > LaunchMap.
-- Tous les réglages du jeu sont dans ReplicatedStorage > PetConfig.

local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")

require(Server.Remotes)       -- les RemoteEvents
require(Server.MapInfo)       -- les mesures et objets de la carte
local Data = require(Server.PlayerData) -- les joueurs et leur sauvegarde
require(Server.Duo)           -- le coup de pied à deux (invitations, duos)
require(Server.Launch)        -- le lancer d'œuf (seul ou à deux)
require(Server.Pets)          -- équiper les pets
require(Server.Traits)        -- le Trait Master
require(Server.Shop)          -- les upgrades (diamants)
require(Server.PotionsCodes)  -- les potions et les codes
require(Server.Lobby)         -- les portails (worlds) et le panneau THROW HERE
require(Server.Dumbbells)     -- les haltères
local Leaderboards = require(Server.Leaderboards) -- le TOP THROWS et les tableaux
require(Server.GlobalBoards)  -- les classements de tous les serveurs (le grand panneau, touche E)

-- Chaque seconde : la potion s'écoule, les classements se mettent à jour
-- (les pièces se gagnent en lançant : les pets donnent un multiplicateur, voir Launch)
while true do
	task.wait(1)
	for player, data in Data.playerData do
		data.BoostTime = math.max(0, data.BoostTime - 1) -- le temps de la potion s'écoule
		Data.sendState(player)
	end
	Leaderboards.Update()
end
