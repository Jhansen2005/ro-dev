--!strict
-- Forest Design §6: rintangan "jatuh = respawn". Part di folder Hazards dengan
-- atribut Hazard=true akan membunuh Humanoid yang menyentuhnya. GameManager lalu
-- respawn ke checkpoint terakhir. (Jatuh dari pita jalur ditangani FallenPartsDestroyHeight.)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local hazardsFolder = Workspace:WaitForChild("Hazards")

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function onHazardTouched(hit: BasePart)
	local player = playerFromHit(hit)
	if not player then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

local function hookZone(zone: Instance)
	if zone:IsA("BasePart") and zone:GetAttribute("Hazard") == true then
		zone.Touched:Connect(onHazardTouched)
	end
end

for _, zone in hazardsFolder:GetChildren() do
	hookZone(zone)
end
hazardsFolder.ChildAdded:Connect(hookZone)
