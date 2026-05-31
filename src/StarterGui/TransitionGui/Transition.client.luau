--!strict
-- F-06: UI transisi "Phase 1 Selesai". Fade to black + teks saat menerima PhaseComplete.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Config = require(Shared:WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("TransitionGui")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "TransitionGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = playerGui

local fade = Instance.new("Frame")
fade.Name = "Fade"
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.Visible = false
fade.Parent = gui

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.45)
title.Size = UDim2.fromScale(0.8, 0.12)
title.Text = "Phase 1 Selesai"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = fade

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.57)
subtitle.Size = UDim2.fromScale(0.6, 0.06)
subtitle.Text = "Naik Kapal..."
subtitle.TextColor3 = Color3.fromRGB(180, 220, 255)
subtitle.TextTransparency = 1
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextScaled = true
subtitle.Parent = fade

local TWEEN_IN = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local playing = false
Remotes.PhaseComplete.OnClientEvent:Connect(function()
	if playing then
		return
	end
	playing = true

	fade.Visible = true
	fade.BackgroundTransparency = 1
	title.TextTransparency = 1
	subtitle.TextTransparency = 1

	TweenService:Create(fade, TWEEN_IN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(title, TWEEN_IN, { TextTransparency = 0 }):Play()
	TweenService:Create(subtitle, TWEEN_IN, { TextTransparency = 0 }):Play()

	task.wait(Config.TRANSITION_HOLD)

	TweenService:Create(title, TWEEN_OUT, { TextTransparency = 1 }):Play()
	TweenService:Create(subtitle, TWEEN_OUT, { TextTransparency = 1 }):Play()
	local outTween = TweenService:Create(fade, TWEEN_OUT, { BackgroundTransparency = 1 })
	outTween:Play()
	outTween.Completed:Wait()

	fade.Visible = false
	playing = false
end)
