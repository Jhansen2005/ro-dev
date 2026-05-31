--!strict
-- F-02: Spawn & respawn. Spawn pertama di SpawnLocation start; setelah menyentuh
-- checkpoint, respawn dipindah ke posisi checkpoint terakhir (server-authoritative).

local Players = game:GetService("Players")

local RESPAWN_OFFSET = Vector3.new(0, 5, 0)

local function onCharacterAdded(player: Player, character: Model)
	local cp = player:GetAttribute("CheckpointPos")
	if typeof(cp) ~= "Vector3" then
		return -- belum ada checkpoint: biarkan di SpawnLocation start (AC3)
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	task.wait() -- beri engine satu frame menempatkan di spawn sebelum kita override
	character:PivotTo(CFrame.new((cp :: Vector3) + RESPAWN_OFFSET))
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
