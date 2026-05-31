--!strict
-- F-03: Sistem checkpoint. Touched server-side + debounce per pemain. Menyimpan
-- posisi respawn (attribute CheckpointPos) dan hanya boleh "maju" (AC3).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local checkpointsFolder = Workspace:WaitForChild("Checkpoints")

local lastTouch: { [string]: number } = {}

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function isAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function onCheckpointTouched(zone: BasePart, hit: BasePart)
	local player = playerFromHit(hit)
	if not player or not isAlive(player) then
		return
	end

	local order = zone:GetAttribute("CheckpointOrder")
	if typeof(order) ~= "number" then
		return
	end

	local key = player.UserId .. ":" .. zone.Name
	local now = os.clock()
	if lastTouch[key] and now - lastTouch[key] < Config.TOUCH_DEBOUNCE then
		return
	end
	lastTouch[key] = now

	-- Hanya maju: abaikan checkpoint dengan order <= yang sudah dicapai (AC3).
	local reached = player:GetAttribute("CheckpointOrder")
	if typeof(reached) == "number" and order <= reached then
		return
	end

	player:SetAttribute("CheckpointOrder", order)
	player:SetAttribute("CheckpointPos", zone.Position)

	-- Feedback visual (AC2)
	zone.Color = Color3.fromRGB(60, 255, 120)

	Remotes.CheckpointReached:FireClient(player, order)
end

for _, zone in checkpointsFolder:GetChildren() do
	if zone:IsA("BasePart") then
		zone.Touched:Connect(function(hit)
			onCheckpointTouched(zone, hit)
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	local prefix = player.UserId .. ":"
	local toRemove = {}
	for key in lastTouch do
		if string.sub(key, 1, #prefix) == prefix then
			table.insert(toRemove, key)
		end
	end
	for _, key in toRemove do
		lastTouch[key] = nil
	end
end)
