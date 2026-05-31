--!strict
-- F-06: Zona pelabuhan -> PhaseComplete. Pemain wajib sudah mencapai objektif
-- terakhir (lewat checkpoint dulu). Setelah transisi, progress di-reset & loop ke start.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local objectivesFolder = Workspace:WaitForChild("Objectives")

local harborZone: BasePart? = nil
local harborOrder = 0
for _, zone in objectivesFolder:GetChildren() do
	if zone:IsA("BasePart") and zone:GetAttribute("IsHarbor") == true then
		harborZone = zone
		local order = zone:GetAttribute("ObjectiveOrder")
		if typeof(order) == "number" then
			harborOrder = order
		end
		break
	end
end

local completing: { [number]: boolean } = {}

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function onHarborTouched(hit: BasePart)
	local player = playerFromHit(hit)
	if not player or completing[player.UserId] then
		return
	end

	-- Wajib sudah di objektif terakhir (sudah melewati ≥2 checkpoint -> DoD).
	local idx = player:GetAttribute("ObjectiveIndex")
	if typeof(idx) ~= "number" or idx < harborOrder then
		return
	end

	completing[player.UserId] = true
	Remotes.PhaseComplete:FireClient(player)

	-- Loop: reset progress lalu respawn ke start setelah layar transisi tampil (F-06 AC3).
	task.delay(Config.TRANSITION_HOLD, function()
		if not player.Parent then
			return
		end
		player:SetAttribute("CheckpointPos", nil)
		player:SetAttribute("CheckpointOrder", nil)
		player:SetAttribute("ObjectiveIndex", 1)
		player:LoadCharacter()
		completing[player.UserId] = nil
	end)
end

if harborZone then
	harborZone.Touched:Connect(onHarborTouched)
else
	warn("[HarborTrigger] Zona pelabuhan (atribut IsHarbor) tidak ditemukan.")
end

Players.PlayerRemoving:Connect(function(player)
	completing[player.UserId] = nil
end)
