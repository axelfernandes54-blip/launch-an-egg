-- RangerKit (ModuleScript dans ServerStorage > Outils)
-- Range le kit de décors importé depuis Blender (fichiers Documents\LaunchAnEgg\DecorKit\DecorKit_<Catégorie>.fbx) :
-- chaque décor va dans ServerStorage > DecorKit > <Catégorie>, avec ses vraies couleurs et matières,
-- ancré, et des collisions logiques (on traverse les petits décors et les feuillages).
-- Claude le lance après l'import (Katia n'a rien à faire ici).

local ServerStorage = game:GetService("ServerStorage")

-- Les couleurs du kit (le nom de chaque morceau finit par sa couleur, ex. "Palm_Tall_Leaf")
local PALETTE = {
	Wood = { 158, 97, 51 }, WoodDark = { 92, 54, 28 }, WoodLight = { 209, 153, 92 }, Plank = { 184, 122, 69 },
	Straw = { 237, 199, 102 }, Leaf = { 64, 199, 77 }, LeafDark = { 31, 148, 64 }, LeafLight = { 128, 230, 89 },
	Grass = { 97, 217, 82 }, Trunk = { 148, 102, 61 }, Rock = { 153, 158, 173 }, RockDark = { 107, 112, 133 },
	Sand = { 245, 219, 153 }, Stone = { 189, 184, 173 }, StoneDark = { 133, 128, 122 }, Red = { 224, 56, 61 },
	Blue = { 56, 133, 235 }, Teal = { 38, 191, 191 }, Yellow = { 255, 209, 51 }, Gold = { 255, 194, 46 },
	Orange = { 255, 140, 38 }, Pink = { 255, 115, 179 }, Purple = { 158, 89, 235 }, White = { 245, 245, 245 },
	Black = { 26, 26, 33 }, Iron = { 71, 77, 92 }, Rope = { 217, 184, 122 }, Cloth = { 242, 235, 209 },
	Water = { 77, 191, 255 }, Fire = { 255, 115, 26 }, FireCore = { 255, 217, 64 }, Glass = { 179, 235, 255 },
	Coral = { 255, 115, 115 }, CoralOrange = { 255, 158, 64 }, Shell = { 255, 217, 191 }, Green = { 51, 179, 89 },
	Brown = { 122, 77, 41 }, Cream = { 255, 242, 204 },
}
local MATERIALS = {
	Wood = Enum.Material.Wood, WoodDark = Enum.Material.Wood, WoodLight = Enum.Material.Wood, Plank = Enum.Material.WoodPlanks,
	Trunk = Enum.Material.Wood, Rock = Enum.Material.Slate, RockDark = Enum.Material.Slate, Stone = Enum.Material.Cobblestone,
	StoneDark = Enum.Material.Cobblestone, Sand = Enum.Material.Sand, Iron = Enum.Material.Metal, Gold = Enum.Material.Foil,
	Fire = Enum.Material.Neon, FireCore = Enum.Material.Neon, Glass = Enum.Material.Glass, Water = Enum.Material.Glass,
	Straw = Enum.Material.Fabric, Rope = Enum.Material.Fabric, Cloth = Enum.Material.Fabric,
}
-- Les décors qu'on peut traverser (petits, feuillages, eau...) : pas de collision
local WALK_THROUGH = {
	Flower = true, Grass = true, Bush = true, Seaweed = true, Coral = true, Shell = true, Starfish = true, Mushroom = true,
	Gold = true, Bottle = true, Lantern = true, Torch = true, Flag = true, Rope = true, Cannonballs = true,
	Sand = true, Treasure = true, Beach = true, Bucket = true, Sack = true, Stool = true, Campfire = true, Buoy = true,
}

local function colorKey(partName)
	local best = nil
	for key in PALETTE do
		if string.sub(partName, -#key - 1) == "_" .. key and (not best or #key > #best) then
			best = key
		end
	end
	return best
end

local function prepare(model)
	local prefix = string.match(model.Name, "^([^_]+)")
	local solid = not WALK_THROUGH[prefix]
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local key = colorKey(part.Name)
			if key then
				part.Color = Color3.fromRGB(table.unpack(PALETTE[key]))
				part.Material = MATERIALS[key] or Enum.Material.SmoothPlastic
				if key == "Water" then
					part.Transparency = 0.25
				elseif key == "Glass" then
					part.Transparency = 0.3
				end
				part.Name = key
			end
			for _, child in part:GetChildren() do
				if child:IsA("SurfaceAppearance") then
					child:Destroy() -- on garde la couleur unie du style dessin animé
				end
			end
			part.Anchored = true
			part.CanCollide = solid and key ~= "Water" and key ~= "Fire" and key ~= "FireCore"
			part.CanTouch = false
			part.CastShadow = true
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
		end
	end
	-- le point de départ (pivot) du décor : au milieu, posé au sol
	local cframe, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cframe.Position.X, cframe.Position.Y - size.Y / 2, cframe.Position.Z)
	if not model.PrimaryPart then
		local biggest, volume = nil, -1
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part.Size.X * part.Size.Y * part.Size.Z > volume then
				biggest, volume = part, part.Size.X * part.Size.Y * part.Size.Z
			end
		end
		model.PrimaryPart = biggest
	end
end

-- imported : le modèle importé (ex. Workspace > DecorKit_Nature). Renvoie le nombre de décors rangés.
local function ranger(imported, category)
	local kit = ServerStorage:FindFirstChild("DecorKit") or Instance.new("Folder")
	kit.Name = "DecorKit"
	kit.Parent = ServerStorage
	local folder = kit:FindFirstChild(category) or Instance.new("Folder")
	folder.Name = category
	folder.Parent = kit
	local count = 0
	for _, child in imported:GetChildren() do
		if child:IsA("Model") or child:IsA("BasePart") then
			local model = child
			if child:IsA("BasePart") then -- un décor d'un seul morceau : on le met dans un Model
				model = Instance.new("Model")
				model.Name = string.gsub(child.Name, "_%a+$", "")
				child.Parent = model
			end
			prepare(model)
			local old = folder:FindFirstChild(model.Name)
			if old then
				old:Destroy() -- (on remplace l'ancienne version)
			end
			model.Parent = folder
			count += 1
		end
	end
	imported:Destroy()
	return count
end

return function()
	local report = {}
	for _, category in { "Nature", "Buildings", "Props", "Ships", "Effects" } do
		local imported = workspace:FindFirstChild("DecorKit_" .. category)
		if imported then
			table.insert(report, category .. ": " .. ranger(imported, category))
		end
	end
	return table.concat(report, ", ")
end
