-- PetFollowers (ModuleScript dans StarterPlayer > StarterPlayerScripts > Client)
-- Les pets 3D qui suivent les joueurs en sautillant (pour tous les joueurs).

local UI = require(script.Parent.UI)
local Players, ReplicatedStorage, RunService, TweenService, UserInputService = UI.Players, UI.ReplicatedStorage, UI.RunService, UI.TweenService, UI.UserInputService
local MarketplaceService, SocialService, Config, remotes, LaunchEgg = UI.MarketplaceService, UI.SocialService, UI.Config, UI.remotes, UI.LaunchEgg
local BuyUpgrade, EggLaunched, EggLanded, StateChanged, DumbbellCollected = UI.BuyUpgrade, UI.EggLaunched, UI.EggLanded, UI.StateChanged, UI.DumbbellCollected
local EquipPet, EquipBest, RerollTrait, TraitRerolled, OpenTraits = UI.EquipPet, UI.EquipBest, UI.RerollTrait, UI.TraitRerolled, UI.OpenTraits
local SetUIScale, World2UnlockedRemote, ShowMessage, UsePotion, OpenCodes = UI.SetUIScale, UI.World2UnlockedRemote, UI.ShowMessage, UI.UsePotion, UI.OpenCodes
local RedeemCode, CRYSTAL_IMAGE, player, camera, TITLE_FONT = UI.RedeemCode, UI.CRYSTAL_IMAGE, UI.player, UI.camera, UI.TITLE_FONT
local NUMBER_FONT, OUTLINE, Theme, ButtonStyles, RAINBOW = UI.NUMBER_FONT, UI.OUTLINE, UI.Theme, UI.ButtonStyles, UI.RAINBOW
local make, round, outlined, border, gradient = UI.make, UI.round, UI.outlined, UI.border, UI.gradient
local label, icon, shine, touchOnly, pressable = UI.label, UI.icon, UI.shine, UI.touchOnly, UI.pressable
local fancyButton, formatNumber, hexColor, formatMultiplier, screenGui = UI.fancyButton, UI.formatNumber, UI.hexColor, UI.formatMultiplier, UI.screenGui
local gui, rootScale, updateScale, toastFrame, toastLabel = UI.gui, UI.rootScale, UI.updateScale, UI.toastFrame, UI.toastLabel
local toastScale, toastVersion, toast, comingSoon, petModels = UI.toastScale, UI.toastVersion, UI.toast, UI.comingSoon, UI.petModels
local spinning, rainbowGradients, aimViewport, petViewport, rarityStroke = UI.spinning, UI.rainbowGradients, UI.aimViewport, UI.petViewport, UI.rarityStroke
local windows, closeWindow, dim, makeWindow, openWindow = UI.windows, UI.closeWindow, UI.dim, UI.makeWindow, UI.openWindow
local clearChildren, badge, bonusChip, equippedCount, petsSignature = UI.clearChildren, UI.badge, UI.bonusChip, UI.equippedCount, UI.petsSignature

-- Les pets 3D qui suivent les joueurs ------------------------------------------
-- Le serveur écrit sur chaque joueur ses meilleurs pets (attribut "EquippedPets").
-- Chaque client fabrique les modèles et les fait suivre le joueur en petit groupe (pour tous les joueurs).
-- Style "pets cubes" : ils marchent en sautillant (petits bonds, écrasés à l'atterrissage, penchés),
-- et quand le joueur s'arrête, ils respirent doucement sur place.

local petModels = ReplicatedStorage:WaitForChild("PetModels")
local PET_SIZE = 0.8        -- taille des pets qui suivent (1 = taille d'origine)
local FOLLOW_DIST = 5       -- distance derrière le joueur (en studs)
local SPREAD = math.rad(55) -- écart entre les pets du groupe (assez grand pour ne pas cacher la vue)
local HOP_LENGTH = 3.6      -- distance parcourue pendant un bond (plus grand = bonds plus lents)
local HOP_HEIGHT = 0.9      -- hauteur d'un bond
local FAR_DIST = 250        -- plus loin que ça de la caméra : pas d'animation (économise le jeu)
local SQUASH_DIST = 90      -- plus loin que ça : pas d'écrasement (on ne le verrait pas)
local followers = {} -- [joueur] = { Names = "...", Pets = { pet, ... } }

local function clearFollowers(owner)
	local entry = followers[owner]
	if entry then
		for _, pet in entry.Pets do
			pet.Model:Destroy()
		end
	end
	followers[owner] = nil
end

local function buildFollowers(owner)
	clearFollowers(owner)
	local names = owner:GetAttribute("EquippedPets") or ""
	local entry = { Names = names, Pets = {} }
	for key in string.gmatch(names, "[^,]+") do
		-- un pet avec un trait s'écrit "Nom|Trait|Niveau" : on garde juste son nom
		local petName = Config.ParseKey(key)
		local source = petModels:FindFirstChild(petName)
		if source then
			local model = source:Clone()
			model:ScaleTo(model:GetScale() * PET_SIZE)
			-- on retient la place et la taille de chaque morceau (pour écraser / étirer le pet)
			local pivot = model:GetPivot()
			local parts = {}
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
					part.CanTouch = false
					part.CanQuery = false
					table.insert(parts, { Part = part, Offset = pivot:ToObjectSpace(part.CFrame), Size = part.Size })
				end
			end
			model.Parent = workspace
			table.insert(entry.Pets, {
				Model = model,
				Parts = parts,
				Position = nil,
				Yaw = 0,
				Phase = math.random() * math.pi,
				Move = 0,       -- 0 = immobile, 1 = en marche
				Squash = 1,     -- écrasement actuel (1 = normal)
				Seed = math.random() * 6,
			})
		end
	end
	followers[owner] = entry
end

local function watchPlayer(owner)
	owner:GetAttributeChangedSignal("EquippedPets"):Connect(function()
		buildFollowers(owner)
	end)
	buildFollowers(owner)
end
for _, other in Players:GetPlayers() do
	watchPlayer(other)
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(clearFollowers)

local function lerpAngle(a, b, alpha)
	local diff = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + diff * alpha
end

local movedParts, movedCFrames = {}, {}
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude

RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 0.1)
	local t = os.clock()
	local cameraPos = workspace.CurrentCamera.CFrame.Position
	table.clear(movedParts)
	table.clear(movedCFrames)

	for owner, entry in followers do
		local character = owner.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root then
			-- la direction du joueur (seulement à plat)
			local look = root.CFrame.LookVector
			local rootYaw = math.atan2(-look.X, -look.Z)
			-- le sol sous le joueur (un rayon vers le bas) ; sinon on estime avec la taille des jambes
			groundParams.FilterDescendantsInstances = { character }
			local hit = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), groundParams)
			local legs = (humanoid and humanoid.RigType == Enum.HumanoidRigType.R15) and humanoid.HipHeight or 2
			local groundY = hit and hit.Position.Y or (root.Position.Y - root.Size.Y / 2 - legs)
			local basis = CFrame.new(root.Position) * CFrame.Angles(0, rootYaw, 0)
			local cameraDist = (root.Position - cameraPos).Magnitude
			local count = #entry.Pets

			for index, pet in entry.Pets do
				-- la place voulue : en arc de cercle derrière le joueur (un groupe un peu désordonné)
				local angle = (index - (count + 1) / 2) * SPREAD
				local radius = FOLLOW_DIST + (index % 2) * 1.5
				local slot = basis * Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius)
				local wanted = Vector3.new(slot.X, groundY, slot.Z)
				if not pet.Position or (pet.Position - wanted).Magnitude > 60 then
					pet.Position = wanted -- trop loin (téléportation) : on le pose directement
				end

				local old = pet.Position
				local new = old:Lerp(wanted, 1 - math.exp(-dt * 7))
				pet.Position = new
				local step = Vector3.new(new.X - old.X, 0, new.Z - old.Z)
				local walking = step.Magnitude / dt > 1.5
				pet.Move += ((walking and 1 or 0) - pet.Move) * math.min(1, dt * 8)

				-- il regarde là où il marche, puis dans la même direction que le joueur
				if walking then
					pet.Yaw = lerpAngle(pet.Yaw, math.atan2(-step.X, -step.Z), 1 - math.exp(-dt * 10))
				else
					pet.Yaw = lerpAngle(pet.Yaw, rootYaw, 1 - math.exp(-dt * 4))
				end

				if cameraDist < FAR_DIST then
					-- les bonds avancent avec la distance parcourue
					pet.Phase += step.Magnitude / HOP_LENGTH * math.pi
					local hop = math.abs(math.sin(pet.Phase))   -- 0 = au sol, 1 = en haut du bond
					local breathe = math.sin(t * 2.2 + pet.Seed) -- petite respiration à l'arrêt
					local move = pet.Move
					local height = hop * HOP_HEIGHT * move + (breathe + 1) * 0.08 * (1 - move)

					-- écrasé quand il touche le sol, un peu étiré en l'air
					local landing = 1 - math.min(1, hop / 0.3)
					local squash = 1 + move * (0.08 * hop - 0.2 * landing) + (1 - move) * 0.03 * breathe
					local roll = math.sin(pet.Phase) * math.rad(8) * move -- se dandine à gauche / à droite
					local lean = -math.rad(8) * move                      -- se penche en avant en marchant

					local base = CFrame.new(new.X, new.Y + height, new.Z)
						* CFrame.Angles(0, pet.Yaw, 0)
						* CFrame.Angles(lean, 0, roll)

					local useSquash = cameraDist < SQUASH_DIST
					if not useSquash then
						squash = 1
					end
					local resize = math.abs(squash - pet.Squash) > 0.004
					if resize then
						pet.Squash = squash
					end
					local wide = 1 / math.sqrt(pet.Squash) -- garde le même volume
					local scale = Vector3.new(wide, pet.Squash, wide)

					for _, info in pet.Parts do
						local offset = info.Offset
						local p = offset.Position
						table.insert(movedParts, info.Part)
						table.insert(movedCFrames, base * CFrame.new(p * scale) * offset.Rotation)
						if resize then
							info.Part.Size = info.Size * scale
						end
					end
				end
			end
		end
	end

	if #movedParts > 0 then
		workspace:BulkMoveTo(movedParts, movedCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)


return {}
