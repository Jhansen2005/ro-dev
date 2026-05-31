--!strict
-- F-07 / Forest Design S4: kabut OTOMATIS saat pemain berada di zona hutan berkabut
-- (Config.FOG_ZONE) — di sinilah compass jadi krusial.
-- F-08: Debug Studio — [F] paksa toggle fog, [T] teleport ke objektif aktif.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Config = require(Shared:WaitForChild("Config"))

local player = Players.LocalPlayer

local CLEAR_FOG_END = 100000

local fogOn = false
local manualOverride = false -- [F] menimpa auto-zona sampai pemain pindah status zona

local function applyFog(on: boolean)
	fogOn = on
	if on then
		Lighting.FogStart = Config.FOG_START
		Lighting.FogEnd = Config.FOG_END
		Lighting.FogColor = Color3.fromRGB(200, 205, 210)
	else
		Lighting.FogStart = 0
		Lighting.FogEnd = CLEAR_FOG_END
	end
end

-- Server bisa memerintah fog secara eksplisit.
Remotes.SetFog.OnClientEvent:Connect(function(on)
	manualOverride = false
	applyFog(on == true)
end)

-- Auto-fog berdasarkan posisi pemain di zona S4.
local lastInZone: boolean? = nil
RunService.Heartbeat:Connect(function()
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end
	local z = hrp.Position.Z
	local inZone = z >= Config.FOG_ZONE.zMin and z <= Config.FOG_ZONE.zMax
	if inZone ~= lastInZone then
		lastInZone = inZone
		manualOverride = false -- berpindah status zona membatalkan override manual
		applyFog(inZone)
	end
end)

-- Debug helper hanya aktif di Studio (F-08 AC1).
if RunService:IsStudio() then
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.F then
			manualOverride = true
			applyFog(not fogOn)
		elseif input.KeyCode == Enum.KeyCode.T then
			local pos = player:GetAttribute("ObjectivePos")
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if typeof(pos) == "Vector3" and hrp and hrp:IsA("BasePart") then
				hrp.CFrame = CFrame.new((pos :: Vector3) + Vector3.new(0, 5, 0))
			end
		end
	end)

	print("[Debug] Studio: [F] toggle fog, [T] teleport ke objektif aktif.")
end
