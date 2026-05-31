--!strict
-- F-04: Compass HUD. Menunjuk ke objektif aktif relatif arah hadap kamera.
-- Target diterima via RemoteEvent UpdateObjective, dengan fallback membaca atribut
-- ObjectiveIndex (anti-race saat remote terlewat). Update tiap frame (RenderStepped).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hindari duplikasi GUI saat respawn (ScreenGui ResetOnSpawn=false bertahan).
local old = playerGui:FindFirstChild("CompassGui")
if old then
	old:Destroy()
end

-- ===== Build UI =====
local gui = Instance.new("ScreenGui")
gui.Name = "CompassGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Compass"
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0, 16)
frame.Size = UDim2.fromOffset(120, 120)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BackgroundTransparency = 0.35
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = frame

local strokeUi = Instance.new("UIStroke")
strokeUi.Thickness = 2
strokeUi.Color = Color3.fromRGB(230, 230, 230)
strokeUi.Transparency = 0.3
strokeUi.Parent = frame

local topMark = Instance.new("TextLabel")
topMark.BackgroundTransparency = 1
topMark.AnchorPoint = Vector2.new(0.5, 0)
topMark.Position = UDim2.new(0.5, 0, 0, 2)
topMark.Size = UDim2.fromOffset(24, 18)
topMark.Text = "depan"
topMark.TextColor3 = Color3.fromRGB(255, 120, 120)
topMark.Font = Enum.Font.GothamBold
topMark.TextSize = 11
topMark.Parent = frame

local needle = Instance.new("TextLabel")
needle.Name = "Needle"
needle.BackgroundTransparency = 1
needle.AnchorPoint = Vector2.new(0.5, 0.5)
needle.Position = UDim2.fromScale(0.5, 0.5)
needle.Size = UDim2.fromOffset(80, 80)
needle.Text = "▲" -- default menunjuk atas; Rotation = bearing relatif
needle.TextColor3 = Color3.fromRGB(255, 215, 0)
needle.Font = Enum.Font.GothamBold
needle.TextSize = 48
needle.Parent = frame

local distLabel = Instance.new("TextLabel")
distLabel.Name = "Distance"
distLabel.BackgroundTransparency = 1
distLabel.AnchorPoint = Vector2.new(0.5, 0)
distLabel.Position = UDim2.new(0.5, 0, 0, 140)
distLabel.Size = UDim2.fromOffset(160, 22)
distLabel.Text = "-- studs"
distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distLabel.Font = Enum.Font.GothamMedium
distLabel.TextSize = 16
distLabel.TextStrokeTransparency = 0.5
distLabel.Parent = gui

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.BackgroundTransparency = 1
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 168)
toast.Size = UDim2.fromOffset(320, 24)
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(120, 255, 160)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 18
toast.TextStrokeTransparency = 0.4
toast.Parent = gui

-- ===== Target objektif =====
-- Sumber utama: attribute ObjectivePos pada Player (tahan StreamingEnabled — part
-- objektif yang jauh mungkin tidak ter-stream ke client, tapi attribute selalu ada).
local targetPos: Vector3? = nil

local function resolveFromAttribute()
	local pos = player:GetAttribute("ObjectivePos")
	if typeof(pos) == "Vector3" then
		targetPos = pos
	end
end

-- Remote sebagai jalur tambahan (sesuai spesifikasi RemoteEvents).
Remotes.UpdateObjective.OnClientEvent:Connect(function(pos)
	if typeof(pos) == "Vector3" then
		targetPos = pos
	end
end)

player:GetAttributeChangedSignal("ObjectivePos"):Connect(resolveFromAttribute)
resolveFromAttribute()

-- ===== Toast checkpoint =====
local toastUntil = 0
Remotes.CheckpointReached.OnClientEvent:Connect(function(order)
	toast.Text = "✔ Checkpoint " .. tostring(order) .. " tersimpan"
	toastUntil = os.clock() + 2.5
end)

-- ===== Render loop =====
local function flatten(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

RunService.RenderStepped:Connect(function()
	if toast.Text ~= "" and os.clock() > toastUntil then
		toast.Text = ""
	end

	local camera = Workspace.CurrentCamera
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not targetPos or not hrp or not camera then
		distLabel.Text = "-- studs"
		return
	end

	local toTarget = flatten((targetPos :: Vector3) - (hrp :: BasePart).Position)
	local look = flatten(camera.CFrame.LookVector)
	if toTarget.Magnitude < 0.1 or look.Magnitude < 0.1 then
		return
	end

	local relative = math.atan2(toTarget.X, toTarget.Z) - math.atan2(look.X, look.Z)
	needle.Rotation = math.deg(relative)
	distLabel.Text = string.format("%d studs", math.floor(toTarget.Magnitude + 0.5))
end)
