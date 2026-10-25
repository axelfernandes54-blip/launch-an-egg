-- CharacterAnimator (ModuleScript dans ReplicatedStorage)
-- Les animations du personnage (avatar R6), style dessin animé qui rebondit :
--  * à l'arrêt : il respire, se balance un peu et regarde autour de lui ;
--  * en marchant : bras et jambes qui balancent, le corps rebondit à chaque pas et se dandine ;
--  * en courant (Shift) : penché en avant, grands mouvements, gros rebonds ;
--  * au saut : il prend de l'élan (accroupi, bras en arrière), puis bras en l'air ;
--  * en tombant : bras qui gigotent ; à l'atterrissage : il s'écrase un instant.
-- Tout est fait par script : rien à publier sur Roblox. Les réglages sont juste en dessous.
-- Ces mouvements ne se voient QUE sur l'écran où ils sont calculés : chaque joueur anime donc
-- son personnage (script "Animate") ET ceux des autres joueurs (script "AnimateOthers").
-- Si un ID est mis dans PetConfig > Config.Animations (Idle, Walk, Run, Jump, Fall, Climb),
-- cette animation publiée remplace le mouvement fait par script (et elle se voit chez tout le monde).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))
local MOVE_PRIORITY = { Idle = Enum.AnimationPriority.Idle } -- les autres : Movement

-- Ce mouvement a-t-il une animation publiée ?
local function customId(move)
	local id = Config.Animations and Config.Animations[move]
	if id and id ~= "" then
		return "rbxassetid://" .. string.gsub(tostring(id), "%D", "")
	end
	return nil
end

-- Les réglages (change ces chiffres pour modifier les animations)
local WALK = { Swing = 0.7, Bob = 0.16, Lean = 0.06, Sway = 0.06 }  -- en marchant
local RUN = { Swing = 1.25, Bob = 0.34, Lean = 0.22, Sway = 0.1 }   -- en courant
local STEP_SPEED = 0.5    -- vitesse des pas (plus grand = pas plus rapides)
local SMOOTHNESS = 14     -- douceur des changements de pose (plus grand = plus rapide)
local OTHERS_MAX_DISTANCE = 250 -- les autres joueurs plus loin que ça ne sont pas animés (économe)

local CharacterAnimator = {}

-- Un mouvement doux qui revient (pour l'élan et l'atterrissage)
local function pulse(age, duration)
	if age < 0 or age > duration then
		return 0
	end
	return math.sin(age / duration * math.pi)
end

-- Anime ce personnage. isLocal = vrai pour notre propre personnage
-- (pour les autres, on devine le saut et la chute avec leur vitesse).
function CharacterAnimator.Start(character, isLocal)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local torso = character:WaitForChild("Torso", 10)
	if not (humanoid and root and torso) then
		return -- (fait pour les avatars R6)
	end

	-- Les articulations. Sur un avatar R6, les deux bras (et les deux jambes) sont en miroir :
	-- le même angle sur les deux fait partir un bras devant et l'autre derrière.
	local limbs = {
		RightArm = torso:WaitForChild("Right Shoulder", 10),
		LeftArm = torso:WaitForChild("Left Shoulder", 10),
		RightLeg = torso:WaitForChild("Right Hip", 10),
		LeftLeg = torso:WaitForChild("Left Hip", 10),
	}
	local neck = torso:WaitForChild("Neck", 10)
	local rootJoint = root:WaitForChild("RootJoint", 10)
	if not (limbs.RightArm and limbs.LeftArm and limbs.RightLeg and limbs.LeftLeg and neck and rootJoint) then
		return
	end

	-- La pose actuelle et la pose voulue
	local pose = { RightArm = 0, LeftArm = 0, RightLeg = 0, LeftLeg = 0, Bob = 0, Lean = 0, Sway = 0, Turn = 0, Nod = 0 }
	local wanted = table.clone(pose)

	local phase = 0
	local state = Enum.HumanoidStateType.Running
	local jumpStart = -10   -- quand le saut a commencé
	local landTime = -10    -- quand on a touché le sol
	local seed = math.random() * 10 -- pour que tout le monde ne respire pas en même temps
	if isLocal then
		humanoid.StateChanged:Connect(function(old, new)
			state = new
			if new == Enum.HumanoidStateType.Jumping then
				jumpStart = os.clock()
			elseif new == Enum.HumanoidStateType.Landed or (old == Enum.HumanoidStateType.Freefall and new == Enum.HumanoidStateType.Running) then
				landTime = os.clock()
			end
		end)
	end

	-- Une animation publiée importante (coup de pied, élan...) est en train de jouer ?
	local function actionPlaying()
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			return false
		end
		for _, track in animator:GetPlayingAnimationTracks() do
			local priority = track.Priority
			if priority ~= Enum.AnimationPriority.Core and priority.Value >= Enum.AnimationPriority.Action.Value then
				return true
			end
		end
		return false
	end

	-- Pour les autres joueurs : on devine s'ils sautent ou tombent avec leur vitesse verticale
	local airborne = false
	local function guessState(velocity)
		if velocity.Y > 4 then
			if not airborne then
				jumpStart = os.clock() - 0.14 -- (pas d'élan : on ne le voit pas venir)
			end
			airborne = true
			return Enum.HumanoidStateType.Jumping
		elseif velocity.Y < -4 then
			airborne = true
			return Enum.HumanoidStateType.Freefall
		end
		if airborne then
			landTime = os.clock()
		end
		airborne = false
		return Enum.HumanoidStateType.Running
	end

	-- Les animations publiées des mouvements (seulement pour notre personnage : Roblox les montre aux autres)
	local tracks, currentMove = {}, nil
	if isLocal then
		local animator = humanoid:WaitForChild("Animator", 10)
		for _, move in { "Idle", "Walk", "Run", "Jump", "Fall", "Climb" } do
			local id = customId(move)
			if id and animator then
				local animation = Instance.new("Animation")
				animation.AnimationId = id
				local ok, track = pcall(animator.LoadAnimation, animator, animation)
				if ok then
					track.Priority = MOVE_PRIORITY[move] or Enum.AnimationPriority.Movement
					track.Looped = move ~= "Jump"
					tracks[move] = track
				else
					warn("Animation " .. move .. " impossible à charger : " .. tostring(track))
				end
			end
		end
	end
	local function playMove(move, speed)
		if move ~= currentMove then
			if currentMove and tracks[currentMove] then
				tracks[currentMove]:Stop(0.15)
			end
			currentMove = move
			if tracks[move] then
				tracks[move]:Play(0.15)
			end
		end
		-- la marche et la course vont plus ou moins vite selon la vitesse du joueur
		if tracks[move] and (move == "Walk" or move == "Run") then
			tracks[move]:AdjustSpeed(math.max(speed, 1) / (move == "Walk" and 16 or 26))
		end
	end

	local camera = workspace.CurrentCamera
	local connection
	connection = RunService.Stepped:Connect(function(_, dt)
		if not character.Parent or not root.Parent then
			connection:Disconnect()
			return
		end
		if not isLocal and (root.Position - camera.CFrame.Position).Magnitude > OTHERS_MAX_DISTANCE then
			return -- trop loin pour qu'on le voie bien
		end
		if actionPlaying() then
			return -- on laisse l'animation publiée bouger le personnage
		end
		local t = os.clock()
		local velocity = root.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		if not isLocal then
			state = guessState(velocity)
		end
		local sinceJump = t - jumpStart
		local sinceLand = t - landTime

		-- le mouvement actuel ; s'il a une animation publiée, c'est elle qui bouge le personnage
		local move = "Idle"
		if sinceJump < 0.14 or state == Enum.HumanoidStateType.Jumping or (state == Enum.HumanoidStateType.Freefall and velocity.Y > 2) then
			move = "Jump"
		elseif state == Enum.HumanoidStateType.Freefall then
			move = "Fall"
		elseif state == Enum.HumanoidStateType.Climbing then
			move = "Climb"
		elseif speed > 1 then
			move = speed > 21 and "Run" or "Walk"
		end
		if isLocal then
			playMove(move, speed)
		end
		if customId(move) then
			return
		end

		if sinceJump < 0.14 then
			-- l'élan du saut : accroupi, bras en arrière
			wanted.RightArm, wanted.LeftArm = -0.7, -0.7
			wanted.RightLeg, wanted.LeftLeg = 0.5, -0.5
			wanted.Bob, wanted.Lean, wanted.Sway, wanted.Nod = -0.35, 0.25, 0, 0.1
		elseif state == Enum.HumanoidStateType.Jumping or (state == Enum.HumanoidStateType.Freefall and velocity.Y > 2) then
			-- en l'air, ça monte : bras bien en l'air, une jambe pliée
			wanted.RightArm, wanted.LeftArm = 2.8, -2.8
			wanted.RightLeg, wanted.LeftLeg = -0.6, -0.15
			wanted.Bob, wanted.Lean, wanted.Sway, wanted.Nod = 0.1, -0.08, 0, -0.1
		elseif state == Enum.HumanoidStateType.Freefall then
			-- en train de tomber : bras ouverts qui gigotent, jambes qui pédalent un peu
			local wiggle = math.sin(t * 16) * 0.3
			wanted.RightArm, wanted.LeftArm = 1.9 + wiggle, -1.9 + wiggle
			wanted.RightLeg, wanted.LeftLeg = 0.3 + wiggle * 0.5, -0.3 + wiggle * 0.5
			wanted.Bob, wanted.Lean, wanted.Sway, wanted.Nod = 0, 0.05, math.sin(t * 8) * 0.05, 0
		elseif state == Enum.HumanoidStateType.Climbing then
			-- grimper : bras et jambes en alternance
			phase += dt * math.abs(velocity.Y) * 0.6
			local swing = math.sin(phase)
			wanted.RightArm, wanted.LeftArm = 2.3 + swing, -2.3 + swing
			wanted.RightLeg, wanted.LeftLeg = swing * 0.7, swing * 0.7
			wanted.Bob, wanted.Lean, wanted.Sway, wanted.Nod = 0, 0, 0, 0
		elseif speed > 1 then
			-- marche ou course : on mélange les deux selon la vitesse
			local run = math.clamp((speed - 16) / 10, 0, 1)
			local function mix(key)
				return WALK[key] + (RUN[key] - WALK[key]) * run
			end
			phase += dt * speed * STEP_SPEED
			local legs = math.sin(phase)
			local arms = math.sin(phase - 0.25) -- les bras suivent les jambes avec un petit retard (plus naturel)
			wanted.RightArm, wanted.LeftArm = arms * mix("Swing"), arms * mix("Swing")
			wanted.RightLeg, wanted.LeftLeg = -legs * mix("Swing"), -legs * mix("Swing")
			wanted.Bob = math.abs(math.cos(phase)) * mix("Bob")   -- un rebond à chaque pas
			wanted.Lean = mix("Lean")                              -- penché en avant (surtout en courant)
			wanted.Sway = legs * mix("Sway")                       -- il se dandine
			wanted.Nod = math.cos(phase * 2) * 0.05
		else
			-- à l'arrêt : il respire et se balance doucement
			local breathe = math.sin(t * 2 + seed)
			wanted.RightArm, wanted.LeftArm = 0.05 + breathe * 0.04, -0.05 + breathe * 0.04
			wanted.RightLeg, wanted.LeftLeg = 0, 0
			wanted.Bob = breathe * 0.04
			wanted.Lean = 0.02
			wanted.Sway = math.sin(t * 0.9 + seed) * 0.03
			wanted.Nod = breathe * 0.03
		end
		-- regarder autour de soi (seulement à l'arrêt)
		wanted.Turn = speed < 1 and math.sin(t * 0.45 + seed) * 0.2 or 0

		-- l'atterrissage : on s'écrase un instant
		local squash = pulse(sinceLand, 0.25)
		if squash > 0 then
			wanted.Bob -= squash * 0.4
			wanted.Lean += squash * 0.15
		end

		-- un bras tient un objet ? il reste tendu devant
		if character:FindFirstChildOfClass("Tool") then
			wanted.RightArm = 1.57
		end

		-- on glisse doucement vers la nouvelle pose
		local alpha = math.min(1, dt * SMOOTHNESS)
		for key, value in wanted do
			pose[key] += (value - pose[key]) * alpha
		end
		for name, joint in limbs do
			joint.Transform = CFrame.Angles(0, 0, pose[name])
		end
		-- le corps : rebond (vers le haut), penché en avant, dandinement de côté
		rootJoint.Transform = CFrame.new(0, 0, pose.Bob) * CFrame.Angles(pose.Lean, pose.Sway, 0)
		-- la tête : petit hochement et regard autour
		neck.Transform = CFrame.Angles(-pose.Nod, 0, pose.Turn)
	end)
end

return CharacterAnimator
