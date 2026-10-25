-- Launch (ModuleScript dans ServerScriptService > Server)
-- Le lancer d'œuf (seul ou à deux) : coup de pied, vol, apparence de l'œuf selon la zone, atterrissage, pet gagné.
-- La dimension (et la distance affichée) dépend de la Force du tir (voir Config.Dimensions) ; la piste est la même partout.
-- Chaque lancer rapporte aussi des pièces (Config.LaunchCoinsPerStud).

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
local Duo = require(script.Parent.Duo)
local playerData, sendState, petKey = Data.playerData, Data.sendState, Data.petKey
local getBonuses, getMultiplier, getForce, getCoinsPerSecond = Data.getBonuses, Data.getMultiplier, Data.getForce, Data.getCoinsPerSecond
local countOwned, countEquipped, equipBest = Data.countOwned, Data.countEquipped, Data.equipBest
local MapInfo = require(script.Parent.MapInfo)
local EGG_RADIUS, EGG_SCALE, LAUNCH_POINT, PLATFORM_TOP = MapInfo.EGG_RADIUS, MapInfo.EGG_SCALE, MapInfo.LAUNCH_POINT, MapInfo.PLATFORM_TOP
local PORTAL_X, PORTAL_CENTER, WORLD2_SPOT, LOBBY_BACK = MapInfo.PORTAL_X, MapInfo.PORTAL_CENTER, MapInfo.WORLD2_SPOT, MapInfo.LOBBY_BACK
local map = MapInfo.Map
local portalCore = MapInfo.PortalCore
local eggModels = ReplicatedStorage:FindFirstChild("OeufsZones") -- les œufs faits dans Blender

-- 4) Le lancer d'œuf ----------------------------------------------------------

-- L'apparence de l'œuf pendant le vol, selon la zone qu'il survole.
-- Material : la matière de l'œuf. Glow : la force de sa lumière. Sparkles : nombre d'étincelles par seconde.
local EGG_LOOKS = {
	Commune    = { Material = Enum.Material.SmoothPlastic, Glow = 0, Sparkles = 0 },
	Rare       = { Material = Enum.Material.Glass,         Glow = 1, Sparkles = 8 },
	Epique     = { Material = Enum.Material.Foil,          Glow = 2, Sparkles = 15 },
	Legendaire = { Material = Enum.Material.Neon,          Glow = 3, Sparkles = 25 },
	Mythique   = { Material = Enum.Material.Neon,          Glow = 5, Sparkles = 40 },
}

-- Ajoute à l'œuf une lumière et des étincelles (éteintes au départ)
local function addEggEffects(egg)
	local light = Instance.new("PointLight")
	light.Name = "Lueur"
	light.Range = 14
	light.Brightness = 0
	light.Parent = egg

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Etincelles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Lifetime = NumberRange.new(0.4, 0.8)
	sparkles.Speed = NumberRange.new(2, 6)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Size = NumberSequence.new(0.6, 0)
	sparkles.LightEmission = 1
	sparkles.Rate = 0
	sparkles.Parent = egg
end

-- Met le modèle Blender de l'œuf de cette rareté autour de la boule qui vole
-- (la boule devient invisible, c'est elle qui gère le vol).
local function attachEggModel(egg, rarityId)
	local model = eggModels and eggModels:FindFirstChild("Oeuf_" .. rarityId)
	if not model then
		return false
	end
	local old = egg:FindFirstChild("Visuel")
	if old then
		old:Destroy()
	end
	local visual = model:Clone()
	visual.Name = "Visuel"
	visual:ScaleTo(visual:GetScale() * EGG_SCALE)
	visual:PivotTo(egg.CFrame)
	for _, part in visual:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Eggs" -- le décor de l'œuf passe aussi à travers les barrières
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = egg
			weld.Part1 = part
			weld.Parent = part
		end
	end
	visual.Parent = egg
	egg.Transparency = 1
	return true
end

-- Change l'œuf aux couleurs de la zone, avec un petit "pop" d'étincelles
local function setEggLook(egg, rarityId)
	local rarity = Config.GetRarity(rarityId)
	local look = EGG_LOOKS[rarityId] or EGG_LOOKS.Commune
	if not attachEggModel(egg, rarityId) then
		-- pas de modèle Blender : on colore simplement la boule
		egg.Color = rarity.Color
		egg.Material = look.Material
	end

	local light = egg:FindFirstChild("Lueur")
	local sparkles = egg:FindFirstChild("Etincelles")
	if light then
		light.Color = rarity.Color
		light.Brightness = look.Glow
	end
	if sparkles then
		sparkles.Color = ColorSequence.new(rarity.Color, Color3.new(1, 1, 1))
		sparkles.Rate = look.Sparkles
		sparkles:Emit(30) -- le "pop" quand on change de zone
	end
end

local function waitForLanding(egg)
	local start = os.clock()
	local currentZone = nil
	while egg.Parent do
		task.wait()
		local elapsed = os.clock() - start

		-- Quelle zone l'œuf survole-t-il en ce moment ?
		local zone = Config.GetZoneForDistance(math.max(0, egg.Position.X - LAUNCH_POINT.X))
		if zone ~= currentZone then
			if currentZone then
				setEggLook(egg, zone.Rarity)
			end
			currentZone = zone
		end

		local position = egg.Position
		if position.X >= PORTAL_X then
			return "portal" -- l'œuf est entré dans le portail du monde 2 !
		end
		local falling = egg.AssemblyLinearVelocity.Y <= 1
		if elapsed > 0.3 and position.Y < EGG_RADIUS + 0.5 and falling then
			return -- posé sur le sol
		end
		if position.Y < -30 or elapsed > 20 then
			return -- tombé hors de la carte ou vol trop long : on s'arrête là
		end
	end
end

-- L'animation du coup de pied est préparée dès que le personnage apparaît
-- (sinon, au tout premier tir, elle n'est pas encore chargée et l'œuf part en retard)
local kickTracks = setmetatable({}, { __mode = "k" })
local function getKickTrack(animator)
	if not kickTracks[animator] then
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. Config.Animations.Kick
		local track = animator:LoadAnimation(animation)
		track.Priority = Enum.AnimationPriority.Action
		kickTracks[animator] = track
	end
	return kickTracks[animator]
end
local function preloadKick(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local animator = humanoid and humanoid:WaitForChild("Animator", 10)
	if animator and Config.Animations.Kick ~= "" then
		getKickTrack(animator)
	end
end
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(preloadKick)
end)
for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(preloadKick)
	if player.Character then
		task.spawn(preloadKick, player.Character)
	end
end

-- Animation du coup de pied : le joueur reste où il est, se tourne vers les zones, recule la jambe, puis tire.
-- onImpact est appelé au moment où le pied touche l'œuf.
local function playKick(player, onImpact)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and humanoid.Health > 0) then
		onImpact()
		return
	end

	-- La hanche droite (R15 ou R6) : c'est elle qu'on fait tourner pour lever la jambe.
	-- Selon l'avatar, c'est un Motor6D (on tourne son C0) ou une AnimationConstraint
	-- (on tourne son point d'attache sur le bassin).
	local joint
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		local leg = character:FindFirstChild("RightUpperLeg")
		joint = leg and leg:FindFirstChild("RightHip")
	else
		local torso = character:FindFirstChild("Torso")
		joint = torso and torso:FindFirstChild("Right Hip")
	end
	local hip, property
	if joint and joint:IsA("Motor6D") then
		hip, property = joint, "C0"
	elseif joint and joint:IsA("AnimationConstraint") and joint.Attachment0 then
		hip, property = joint.Attachment0, "CFrame"
	end
	local function legAngle(degrees)
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			return CFrame.Angles(math.rad(degrees), 0, 0)
		end
		return CFrame.Angles(0, 0, math.rad(degrees))
	end
	-- Fait tourner la hanche doucement de "from" vers "to" (comme un Tween)
	local function moveHip(from, to, duration, style, direction)
		local start = os.clock()
		repeat
			local alpha = math.min((os.clock() - start) / duration, 1)
			hip[property] = from:Lerp(to, TweenService:GetValue(alpha, style, direction))
			task.wait()
		until alpha >= 1
	end

	-- Le joueur reste à sa place : il se tourne juste vers les zones et ne bouge plus pendant le tir
	root.Anchored = true
	root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.xAxis)

	-- La vraie animation publiée (voir Config.Animations) : l'œuf part au marqueur "Impact"
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if Config.Animations.Kick ~= "" and animator then
		local track = getKickTrack(animator)
		local hit = false
		local markerConnection = track:GetMarkerReachedSignal("Impact"):Connect(function()
			hit = true
			onImpact()
		end)
		track:Play(0.05)
		-- sécurité : si le marqueur n'arrive pas (animation pas encore chargée...), l'œuf part quand même vers 0,3 s
		local start = os.clock()
		repeat
			task.wait()
		until hit or os.clock() - start > (track.Length > 0 and 0.6 or 0.32)
		markerConnection:Disconnect()
		onImpact()
		task.wait(math.max(0, (track.Length > 0 and track.Length or 0.6) - (os.clock() - start)))
		track:Stop(0.15)
	elseif hip then
		local rest = hip[property]
		local back = rest * legAngle(-50)
		local front = rest * legAngle(110)
		-- 1) la jambe recule (on prend de l'élan)
		moveHip(rest, back, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		-- 2) la jambe part très vite vers l'avant
		moveHip(back, front, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		onImpact()
		-- 3) la jambe reste levée un instant, puis revient tranquillement
		task.wait(0.25)
		moveHip(front, rest, 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	else
		task.wait(0.4)
		onImpact()
	end
	task.wait(0.3)
	root.Anchored = false
end

-- L'impact à l'atterrissage : onde de choc, poussière et petit rebond de l'œuf
local function playImpact(egg, color)
	local ground = Vector3.new(egg.Position.X, 0.15, egg.Position.Z)

	local wave = Instance.new("Part")
	wave.Name = "OndeDeChoc"
	wave.Shape = Enum.PartType.Cylinder
	wave.Anchored = true
	wave.CanCollide = false
	wave.CanQuery = false
	wave.Material = Enum.Material.Neon
	wave.Color = color
	wave.Size = Vector3.new(0.3, 4, 4)
	wave.CFrame = CFrame.new(ground) * CFrame.Angles(0, 0, math.rad(90))
	wave.Parent = workspace
	TweenService:Create(wave, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.3, 45, 45),
		Transparency = 1,
	}):Play()
	task.delay(0.8, wave.Destroy, wave)

	local dustHolder = Instance.new("Part")
	dustHolder.Anchored = true
	dustHolder.CanCollide = false
	dustHolder.CanQuery = false
	dustHolder.Transparency = 1
	dustHolder.Size = Vector3.new(1, 1, 1)
	dustHolder.Position = ground
	dustHolder.Parent = workspace
	local dust = Instance.new("ParticleEmitter")
	dust.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5))
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(0.6, 1.2)
	dust.Speed = NumberRange.new(15, 30)
	dust.SpreadAngle = Vector2.new(80, 80)
	dust.Drag = 4
	dust.Acceleration = Vector3.new(0, 4, 0)
	dust.Rate = 0
	dust.Parent = dustHolder
	dust:Emit(40)
	task.delay(1.5, dustHolder.Destroy, dustHolder)

	-- l'œuf se remet debout puis fait un petit rebond
	local rest = CFrame.new(egg.Position.X, EGG_RADIUS, egg.Position.Z)
	egg.CFrame = rest
	local up = TweenService:Create(egg, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = rest + Vector3.new(0, 2.5, 0) })
	up:Play()
	up.Completed:Connect(function()
		TweenService:Create(egg, TweenInfo.new(0.45, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { CFrame = rest }):Play()
	end)
end

-- Un tir, seul ou à deux. kickers = { { Player = joueur, Power = jauge de 0 à 1 }, ... }
-- À deux : les Forces s'additionnent, l'œuf part entre les deux joueurs, et chacun gagne son propre pet.
local function runLaunch(kickers)
	-- On ne fait jamais confiance au client : on vérifie chaque tireur.
	local valid = {}
	for _, kicker in kickers do
		local data = playerData[kicker.Player]
		local root = kicker.Player.Character and kicker.Player.Character:FindFirstChild("HumanoidRootPart")
		-- On ne peut tirer que depuis la plateforme de tir (x de -40 à 0, z de -40 à 40)
		local p = root and root.Position
		if data and not data.Busy and p and p.X >= -43 and p.X <= 3 and math.abs(p.Z) <= 43 then
			kicker.Data = data
			kicker.Position = p
			table.insert(valid, kicker)
		end
	end
	if #valid == 0 then
		return
	end
	for _, kicker in valid do
		kicker.Data.Busy = true -- un seul œuf à la fois
	end
	local isDuo = #valid > 1

	local launch = Config.Launch
	-- La Force du tir = la Force du compteur x la jauge (au moins 30 %), + celle du partenaire en duo
	local kickForce, launchBonus, center = 0, 0, Vector3.zero
	for i, kicker in valid do
		local force = math.floor(getForce(kicker.Data) * (launch.MinPower + (1 - launch.MinPower) * kicker.Power))
		kickForce += i == 1 and force or math.floor(force * Config.DuoKick.PartnerShare)
		launchBonus += getBonuses(kicker.Data).Launch
		center += kicker.Position
	end
	launchBonus /= #valid
	center /= #valid
	-- la distance voulue (voir Config.Progression, + le trait "Distance" des pets), en distance affichée,
	-- puis l'endroit où l'œuf doit tomber sur la piste de la dimension du joueur (studs réels),
	-- puis la vitesse qu'il faut donner à l'œuf pour l'atteindre
	local wantedDistance = Config.DistanceForForce(kickForce) * launchBonus
	-- la dimension se choisit toute seule : au-delà de 10K, l'œuf vole dans la Dimension 2, etc.
	local dimension = Config.DimensionForDistance(wantedDistance).Id
	local targetDistance = math.max(6, Config.ToTrackDistance(wantedDistance, dimension))
	targetDistance += math.max(0, -(center.X + 3.5)) -- l'œuf part de la plateforme, avant la ligne de départ (x = 0)
	local speed = math.sqrt(targetDistance * workspace.Gravity / math.sin(2 * math.rad(launch.Angle)))

	local egg = Instance.new("Part")
	egg.Name = "Oeuf_" .. valid[1].Player.Name
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(EGG_RADIUS * 2, EGG_RADIUS * 2, EGG_RADIUS * 2)
	egg.Color = Color3.fromRGB(255, 245, 220)
	egg.Material = Enum.Material.SmoothPlastic
	egg.CustomPhysicalProperties = PhysicalProperties.new(1, 2, 0) -- lourd, ne rebondit pas
	egg.CollisionGroup = "Eggs" -- il passe à travers les barrières magiques
	egg.Anchored = true -- il attend par terre, juste devant le joueur (entre les deux joueurs en duo)
	egg.CFrame = CFrame.new(center.X + 3.5, PLATFORM_TOP + EGG_RADIUS, center.Z)
	addEggEffects(egg)
	attachEggModel(egg, "Commune") -- l'œuf part avec le look Prairie
	if isDuo then
		egg.Etincelles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 60)) -- en duo, des étincelles dorées
		egg.Etincelles.Rate = 20
	end
	egg.Parent = workspace

	-- Les joueurs tirent dans l'œuf ; au premier impact, l'œuf s'envole en tournant sur lui-même
	local launched = false
	local function kickEgg()
		if launched then
			return
		end
		launched = true
		egg.Anchored = false
		egg:SetNetworkOwner(nil) -- c'est le serveur qui calcule le vol
		local angle = math.rad(launch.Angle)
		egg.AssemblyLinearVelocity = Vector3.new(math.cos(angle), math.sin(angle), 0) * speed
		egg.AssemblyAngularVelocity = Vector3.new(0, 0, -10) -- la rotation en l'air (il roule vers l'avant)
		egg.Etincelles:Emit(isDuo and 60 or 25) -- le "tchac" du coup de pied

		for i, kicker in valid do
			-- Le monde se charge autour de l'œuf (et plus autour du joueur) pendant le vol
			kicker.Player.ReplicationFocus = egg
			local partner = isDuo and valid[3 - i].Player or nil
			EggLaunched:FireClient(kicker.Player, egg, kickForce, partner and partner.DisplayName or nil, dimension)
		end
	end
	for _, kicker in valid do
		task.spawn(function()
			-- Si l'animation rate (avatar spécial...), l'œuf part quand même et le joueur est libéré
			local ok, problem = pcall(playKick, kicker.Player, kickEgg)
			if not ok then
				warn("Coup de pied : " .. tostring(problem))
				local root = kicker.Player.Character and kicker.Player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					root.Anchored = false
				end
			end
			kickEgg()
		end)
	end
	local start = os.clock()
	repeat
		task.wait()
	until launched or os.clock() - start > 1
	kickEgg()

	local reachedPortal = waitForLanding(egg) == "portal"
	egg.Anchored = true
	if reachedPortal then
		-- l'œuf est aspiré dans le tourbillon : il va au centre du portail et disparaît dans des étincelles
		TweenService:Create(egg, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(PORTAL_CENTER) }):Play()
		if portalCore and portalCore:FindFirstChild("Etincelles") then
			portalCore.Etincelles:Emit(150)
		end
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6586979979"
		sound.PlaybackSpeed = 0.45
		sound.Volume = 1
		sound.RollOffMaxDistance = 600
		sound.Parent = portalCore
		sound:Play()
		task.delay(3, sound.Destroy, sound)
	end
	for _, kicker in valid do
		if kicker.Player.Parent then
			task.delay(2, function()
				kicker.Player.ReplicationFocus = nil
			end)
		end
	end

	-- où l'œuf est tombé sur la piste (studs réels), et la distance affichée dans la dimension
	local trackDistance = math.max(0, egg.Position.X - LAUNCH_POINT.X)
	if reachedPortal then
		trackDistance = Config.TrackLength -- le bout de la piste : la distance maximum de la dimension
	end
	local distance = Config.ToDisplayDistance(trackDistance, dimension)
	local zone = Config.GetZoneForDistance(trackDistance)

	-- Chaque tireur tire son propre pet : aucune rareté garantie,
	-- plus l'œuf va loin sur la piste, meilleures sont les chances (+ le Luck des pets et de l'upgrade Pet Luck)
	for i, kicker in valid do
		local player = kicker.Player
		local data = playerData[player]
		if data then -- (le joueur est peut-être parti pendant le vol)
			local chances = Config.GetChances(trackDistance, getBonuses(data).Luck)
			local rarityId = Config.RollRarity(chances)
			local petName = Config.RandomPet(rarityId)
			if i == 1 and not reachedPortal then
				setEggLook(egg, rarityId) -- l'œuf montre la rareté du pet obtenu
				playImpact(egg, Config.GetRarity(rarityId).Color)
			end

			local newPet = { Name = petName, Rarity = rarityId } -- pas de trait : le Trait Master du lobby en donne
			table.insert(data.Pets, newPet)
			if #data.Equipped < Config.Launch.MaxEquipped then
				table.insert(data.Equipped, petKey(newPet)) -- il reste une place : le nouveau pet est équipé tout seul
			end
			data.Best = math.max(data.Best, distance)
			-- les pièces du lancer : plus l'œuf va loin, plus on en gagne (x le bonus de pièces des pets et de l'upgrade)
			local coins = math.floor(distance * Config.LaunchCoinsPerStud * getBonuses(data).Coins)
			data.Coins += coins
			data.Busy = false
			if isDuo then
				data.DuoKicks += 1
			end
			-- (toucher le portail du bout de la piste ne débloque plus rien : les dimensions s'achètent avec des pièces)

			EggLanded:FireClient(player, {
				Distance = distance,
				Zone = zone.Rarity,
				Rarity = rarityId,
				PetName = petName,
				KickForce = kickForce,
				GotReroll = false, -- (les lancers ne donnent plus de Rerolls : les diamants viennent des haltères)
				Coins = coins,
				Dimension = dimension,
				Chance = chances[rarityId], -- la chance (en %) qu'on avait d'avoir cette rareté
				Duo = isDuo,
			})
			sendState(player)
		end
	end
	if reachedPortal then
		task.delay(0.6, egg.Destroy, egg)
	else
		task.delay(3, egg.Destroy, egg)
	end
	for _, kicker in valid do
		Duo.Refresh(kicker.Player) -- le partenaire n'est plus "prêt" : on recommence
	end
end

-- En duo, le premier qui relâche attend son partenaire (au plus Config.DuoKick.ReleaseWindow secondes)
local waitingDuo = {} -- [joueur] = { Power = sa jauge }

LaunchEgg.OnServerEvent:Connect(function(player, power)
	local data = playerData[player]
	if not data or data.Busy then
		return -- un seul œuf à la fois
	end
	-- On ne fait jamais confiance au client : on vérifie la valeur reçue.
	if typeof(power) ~= "number" or power ~= power then
		return
	end
	power = math.clamp(power, 0, 1)

	local partner = Duo.PartnerOf(player)
	if not partner then
		runLaunch({ { Player = player, Power = power } })
		return
	end
	local partnerWaiting = waitingDuo[partner]
	if partnerWaiting then
		-- les deux ont relâché : on tire ensemble !
		waitingDuo[partner] = nil
		runLaunch({ { Player = partner, Power = partnerWaiting.Power }, { Player = player, Power = power } })
		return
	end
	if waitingDuo[player] then
		return
	end
	local entry = { Power = power }
	waitingDuo[player] = entry
	Duo.SendPartnerReady(partner)
	task.delay(Config.DuoKick.ReleaseWindow, function()
		if waitingDuo[player] ~= entry then
			return -- le partenaire a relâché à temps : le tir est déjà parti
		end
		waitingDuo[player] = nil
		-- le partenaire n'a pas relâché : on tire quand même, lui avec la jauge au minimum
		local stillPartner = Duo.PartnerOf(player)
		if stillPartner then
			runLaunch({ { Player = player, Power = power }, { Player = stillPartner, Power = 0 } })
		else
			runLaunch({ { Player = player, Power = power } })
		end
	end)
end)

return {}
