--!strict
-- Forest Design §8: Lighting Future + golden hour + Atmosphere + Sky + post-processing.
-- Diset di server agar tereplikasi ke semua client.

local Lighting = game:GetService("Lighting")

-- Catatan: Lighting.Technology = Future diset via default.project.json (script
-- runtime tidak punya capability untuk menulisnya).
Lighting.ClockTime = 16.5 -- golden hour (cahaya hangat menembus pohon)
Lighting.GeographicLatitude = 20
Lighting.Brightness = 2.2
Lighting.ExposureCompensation = 0.15
Lighting.EnvironmentDiffuseScale = 0.5
Lighting.EnvironmentSpecularScale = 0.5
Lighting.Ambient = Color3.fromRGB(70, 70, 80)
Lighting.OutdoorAmbient = Color3.fromRGB(120, 110, 100)
Lighting.ColorShift_Top = Color3.fromRGB(255, 225, 180)

local function ensure(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

-- Skybox default Roblox (tekstur bawaan) — cukup untuk prototype
ensure("Sky", "ForestSky")

local atmosphere = ensure("Atmosphere", "ForestAtmosphere") :: Atmosphere
atmosphere.Density = 0.3
atmosphere.Offset = 0.1
atmosphere.Haze = 1.5
atmosphere.Glare = 0.2
atmosphere.Color = Color3.fromRGB(199, 199, 199)
atmosphere.Decay = Color3.fromRGB(106, 112, 125)

local bloom = ensure("BloomEffect", "ForestBloom") :: BloomEffect
bloom.Intensity = 0.5
bloom.Size = 24
bloom.Threshold = 1.1

local cc = ensure("ColorCorrectionEffect", "ForestColorCorrection") :: ColorCorrectionEffect
cc.Brightness = 0.02
cc.Contrast = 0.12
cc.Saturation = 0.15
cc.TintColor = Color3.fromRGB(255, 246, 235)

local sunRays = ensure("SunRaysEffect", "ForestSunRays") :: SunRaysEffect
sunRays.Intensity = 0.12
sunRays.Spread = 0.5

local dof = ensure("DepthOfFieldEffect", "ForestDOF") :: DepthOfFieldEffect
dof.FarIntensity = 0.05
dof.FocusDistance = 60
dof.InFocusRadius = 80
dof.NearIntensity = 0

print("[LightingSetup] Lighting Future + golden hour + post-processing aktif.")
