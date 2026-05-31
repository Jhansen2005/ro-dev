--!strict
-- F-05: State objektif aktif per pemain (server-authoritative). Compass client
-- mengejar objektif aktif. Saat objektif tercapai, pindah ke berikutnya.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local objectivesFolder = Workspace:WaitForChild("Objectives")

type Objective = { order: number, position: Vector3, isHarbor: boolean, zone: BasePart }

local objectives: { Objective } = {}
for _, zone in objectivesFolder:GetChildren() do
	if zone:IsA("BasePart") then
		local order = zone:GetAttribute("ObjectiveOrder")
		if typeof(order) == "number" then
			table.insert(objectives, {
				order = order,
				position = zone.Position,
				isHarbor = zone:GetAttribute("IsHarbor") == true,
				zone = zone,
			})
		end
	end
end
table.sort(objectives, function(a, b)
	return a.order < b.order
end)

local function objectiveByOrder(order: number): Objective?
	for _, objective in objectives do
		if objective.order == order then
			return objective
		end
	end
	return nil
end

local function sendUpdate(player: Player)
	local idx = player:GetAttribute("ObjectiveIndex")
	if typeof(idx) ~= "number" then
		return
	end
	local objective = objectiveByOrder(idx)
	if objective then
		-- Attribute = sumber utama compass (tahan StreamingEnabled, anti-race).
		player:SetAttribute("ObjectivePos", objective.position)
		-- Remote tetap dikirim sesuai spesifikasi RemoteEvents.
		Remotes.UpdateObjective:FireClient(player, objective.position, objective.isHarbor)
	end
end

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

local function onObjectiveTouched(objective: Objective, hit: BasePart)
	local player = playerFromHit(hit)
	if not player or not isAlive(player) then
		return
	end

	local idx = player:GetAttribute("ObjectiveIndex")
	if typeof(idx) ~= "number" or idx ~= objective.order then
		return -- bukan objektif aktif pemain ini
	end

	local key = player.UserId .. ":" .. objective.order
	local now = os.clock()
	if lastTouch[key] and now - lastTouch[key] < Config.TOUCH_DEBOUNCE then
		return
	end
	lastTouch[key] = now

	-- Maju ke objektif berikutnya bila ada. Objektif terakhir (harbor) ditangani HarborTrigger.
	local nextObjective = objectiveByOrder(objective.order + 1)
	if nextObjective then
		player:SetAttribute("ObjectiveIndex", objective.order + 1)
		sendUpdate(player)
	end
end

for _, objective in objectives do
	objective.zone.Touched:Connect(function(hit)
		onObjectiveTouched(objective, hit)
	end)
end

local function onPlayerAdded(player: Player)
	if typeof(player:GetAttribute("ObjectiveIndex")) ~= "number" then
		player:SetAttribute("ObjectiveIndex", 1)
	end
	-- set posisi objektif aktif segera (agar compass punya target sejak awal)
	local startObjective = objectiveByOrder(player:GetAttribute("ObjectiveIndex") :: number)
	if startObjective then
		player:SetAttribute("ObjectivePos", startObjective.position)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		sendUpdate(player)
	end)
	if player.Character then
		task.spawn(function()
			task.wait(0.2)
			sendUpdate(player)
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
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
