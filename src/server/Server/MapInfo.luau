-- MapInfo (ModuleScript dans ServerScriptService > Server)
-- Les mesures de la carte (utilisées par plusieurs scripts) et les objets importants de Workspace > LaunchMap.
-- La carte elle-même est déjà construite dans Studio (voir ServerStorage > Outils > ConstruireCarte).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))

-- Les barrières magiques bloquent les joueurs, mais l'œuf passe à travers
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, "Barriers")
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, "Eggs")
PhysicsService:CollisionGroupSetCollidable("Barriers", "Eggs", false)

local MapInfo = {}
MapInfo.ZONE_WIDTH = 160
MapInfo.EGG_RADIUS = 2   -- l'œuf fait 4 studs de large (un joueur fait environ 5 studs de haut)
MapInfo.EGG_SCALE = 1.6  -- taille du modèle Blender de l'œuf (1.6 = environ la taille du joueur)
MapInfo.LAUNCH_POINT = Vector3.new(0, 1 + MapInfo.EGG_RADIUS, 0) -- d'où part l'œuf ; les distances se comptent depuis x = 0
MapInfo.PLATFORM_TOP = 0.3 -- hauteur du dessus de la plateforme de tir (là où l'œuf est posé)
MapInfo.LOBBY_BACK = -200 -- le fond du lobby (x)
MapInfo.PORTAL_X = Config.Zones[#Config.Zones].Finish - 15 -- le portail du bout de la piste
MapInfo.PORTAL_CENTER = Vector3.new(MapInfo.PORTAL_X, 40 + 4, 0)
MapInfo.WORLD2_SPOT = Vector3.new(-120, 0, 300) -- la zone "World 2 - Coming soon"
MapInfo.LOBBY_SPAWN = CFrame.new(-75, 4, 0) -- là où on revient dans le lobby

MapInfo.Map = workspace:WaitForChild("LaunchMap")
local portal = MapInfo.Map:WaitForChild("PortailMonde2")
MapInfo.PortalCore = portal:WaitForChild("Tourbillon") -- le tourbillon (pour les effets quand un œuf arrive)

-- On enlève le Baseplate du modèle de base s'il revient : la carte sert de sol
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

return MapInfo
