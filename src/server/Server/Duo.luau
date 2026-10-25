-- Duo (ModuleScript dans ServerScriptService > Server)
-- Le coup de pied à deux : invitations, duos formés, et fin du duo quand on s'éloigne.
-- Le tir lui-même (Forces additionnées, un pet pour chacun) est dans Launch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("PetConfig"))
local Remotes = require(script.Parent.Remotes)
local DuoInvite, DuoRespond, DuoLeave, DuoInvited, DuoUpdate = Remotes.DuoInvite, Remotes.DuoRespond, Remotes.DuoLeave, Remotes.DuoInvited, Remotes.DuoUpdate
local ShowMessage = Remotes.ShowMessage
local Data = require(script.Parent.PlayerData)
local playerData = Data.playerData

local Duo = {}
local partners = {}   -- [joueur] = son partenaire
local invites = {}    -- [joueur invité] = { From = qui invite, Time = quand }
local lastInvite = {} -- [joueur] = quand il a invité pour la dernière fois

-- La position du joueur s'il est sur la plateforme de tir (la même zone que pour tirer), sinon nil
local function launchPosition(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local p = root.Position
	if p.X < -43 or p.X > 3 or math.abs(p.Z) > 43 then
		return nil
	end
	return p
end

local function distanceBetween(a, b)
	local pa, pb = launchPosition(a), launchPosition(b)
	if not (pa and pb) then
		return math.huge
	end
	return (pa - pb).Magnitude
end

-- Envoie au joueur l'état de son duo (partner = son partenaire, ou nil)
local function send(player, partnerReady)
	if player.Parent then
		local partner = partners[player]
		DuoUpdate:FireClient(player, partner and { Partner = partner, PartnerReady = partnerReady == true } or nil)
	end
end

function Duo.PartnerOf(player)
	return partners[player]
end

-- Prévient le joueur que son partenaire a déjà relâché (il doit relâcher vite !)
function Duo.SendPartnerReady(player)
	send(player, true)
end

function Duo.Refresh(player)
	send(player, false)
end

function Duo.Break(player, message)
	local other = partners[player]
	if not other then
		return
	end
	partners[player] = nil
	partners[other] = nil
	send(player)
	send(other)
	if message and other.Parent then
		ShowMessage:FireClient(other, message)
	end
end

DuoInvite.OnServerEvent:Connect(function(player, target)
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target == player or not target.Parent then
		return
	end
	local data, targetData = playerData[player], playerData[target]
	if not (data and targetData) or data.Busy or targetData.Busy then
		return
	end
	if partners[player] or partners[target] then
		return
	end
	local now = os.clock()
	if lastInvite[player] and now - lastInvite[player] < Config.DuoKick.InviteCooldown then
		return -- pas de spam d'invitations
	end
	if distanceBetween(player, target) > Config.DuoKick.InviteDistance then
		return
	end
	lastInvite[player] = now
	invites[target] = { From = player, Time = now }
	DuoInvited:FireClient(target, player)
	ShowMessage:FireClient(player, "🤝 Invite sent to " .. target.DisplayName .. "!")
end)

DuoRespond.OnServerEvent:Connect(function(player, inviter, accept)
	local invite = invites[player]
	if not invite or invite.From ~= inviter then
		return
	end
	invites[player] = nil
	if not inviter.Parent or os.clock() - invite.Time > Config.DuoKick.InviteTimeout then
		return
	end
	if accept ~= true then
		ShowMessage:FireClient(inviter, player.DisplayName .. " said no 😢")
		return
	end
	if partners[player] or partners[inviter] or distanceBetween(player, inviter) > Config.DuoKick.BreakDistance then
		ShowMessage:FireClient(player, "Too far away!")
		return
	end
	partners[player] = inviter
	partners[inviter] = player
	send(player)
	send(inviter)
end)

DuoLeave.OnServerEvent:Connect(function(player)
	Duo.Break(player, player.DisplayName .. " left the duo")
end)

Players.PlayerRemoving:Connect(function(player)
	Duo.Break(player, player.DisplayName .. " left the duo")
	invites[player] = nil
	lastInvite[player] = nil
	for target, invite in invites do
		if invite.From == player then
			invites[target] = nil
		end
	end
end)

-- Le duo s'arrête si l'un des deux quitte la plateforme ou s'éloigne trop (sauf pendant un tir)
task.spawn(function()
	while true do
		task.wait(0.5)
		for player, partner in partners do
			local data, partnerData = playerData[player], playerData[partner]
			local busy = (data and data.Busy) or (partnerData and partnerData.Busy)
			if not busy and distanceBetween(player, partner) > Config.DuoKick.BreakDistance then
				Duo.Break(player, "Duo ended: too far away")
			end
		end
	end
end)

return Duo
