--!strict
-- F-01 + Forest Design: membangun biome Hutan berbasis TERRAIN (bukan part datar).
-- Terrain mengikuti centerline Config.PATH dengan elevasi 5 segmen (S1-S5), sungai,
-- laut, jembatan, batu pijakan, landmark, dan foliage acak. Semua part statis Anchored.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Terrain = Workspace.Terrain
local PATH = Config.PATH
local rng = Random.new(20260531)

-- ===== Bersihkan dunia lama =====
Terrain:Clear()
for _, child in Workspace:GetChildren() do
	if child.Name == "Baseplate" or child:IsA("SpawnLocation") then
		child:Destroy()
	end
end
for _, name in { "Map", "Checkpoints", "Objectives", "Hazards" } do
	local existing = Workspace:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

-- Catatan: FallenPartsDestroyHeight & Lighting.Technology TIDAK boleh ditulis
-- script runtime (capability error) — keduanya diset via default.project.json.

-- ===== Folder =====
local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local mapFolder = makeFolder("Map", Workspace)
local forestFolder = makeFolder("Forest", mapFolder)
local propsFolder = makeFolder("Props", mapFolder)
local foliageFolder = makeFolder("Foliage", mapFolder)
local checkpointsFolder = makeFolder("Checkpoints", Workspace)
local objectivesFolder = makeFolder("Objectives", Workspace)
local hazardsFolder = makeFolder("Hazards", Workspace)

-- ===== SpawnLocation di start (dibuat lebih awal agar pijakan spawn pasti ada) =====
do
	local startPos = PATH[1]
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ForestSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(startPos + Vector3.new(0, 2, 0))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(90, 160, 90)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = forestFolder
end

-- ===== Warna material terrain (realistis-ish) =====
Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(86, 112, 58))
Terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(70, 96, 52))
Terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(104, 102, 99))
Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(206, 190, 142))
Terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(94, 74, 52))
Terrain.WaterColor = Color3.fromRGB(24, 86, 110)
Terrain.WaterTransparency = 0.4
Terrain.WaterReflectance = 0.12
Terrain.WaterWaveSize = 0.12
Terrain.WaterWaveSpeed = 6

-- ===== Helper Part =====
local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

-- CFrame tegak dengan yaw mengikuti arah horizontal `dir`.
local function uprightCFrame(center: Vector3, dir: Vector3): CFrame
	local yawDir = Vector3.new(dir.X, 0, dir.Z)
	if yawDir.Magnitude < 0.01 then
		yawDir = Vector3.new(0, 0, 1)
	end
	return CFrame.lookAt(center, center + yawDir.Unit)
end

-- ===== Isi pita terrain di sepanjang jalur =====
local floorY = Config.TERRAIN_FLOOR_Y

local function fillRibbonSegment(surfacePos: Vector3, dir: Vector3, length: number, width: number, material: Enum.Material)
	local surfaceY = surfacePos.Y
	local height = surfaceY - floorY
	if height <= 0 then
		return
	end
	local center = Vector3.new(surfacePos.X, (surfaceY + floorY) / 2, surfacePos.Z)
	Terrain:FillBlock(uprightCFrame(center, dir), Vector3.new(width, height, length), material)
end

for leg = 1, #PATH - 1 do
	local a = PATH[leg]
	local b = PATH[leg + 1]
	local legVec = b - a
	local legLen = legVec.Magnitude
	local steps = math.max(1, math.floor(legLen / Config.SAMPLE_SPACING))
	local stepLen = legLen / steps
	local material = Config.LEG_MATERIAL[leg]

	for s = 0, steps do
		local t = s / steps
		local pos = a:Lerp(b, t)
		-- pita utama
		fillRibbonSegment(pos, legVec, stepLen * 1.9, Config.RIBBON_WIDTH, material)
		-- jalur setapak material kontras (Mud) di tengah, kecuali pantai
		if material ~= Enum.Material.Sand then
			local stripY = pos.Y + 1
			local stripCenter = Vector3.new(pos.X, stripY - 4, pos.Z)
			Terrain:FillBlock(
				uprightCFrame(stripCenter, legVec),
				Vector3.new(Config.PATH_STRIP_WIDTH, 8, stepLen * 1.9),
				Enum.Material.Mud
			)
		end
	end
end

-- Plateau lebih lebar di puncak (vista) S2
do
	local summit = PATH[4]
	Terrain:FillBlock(
		CFrame.new(summit.X, (summit.Y + floorY) / 2, summit.Z),
		Vector3.new(220, summit.Y - floorY, 220),
		Enum.Material.Rock
	)
end

-- ===== Sungai melintang (S3) + laut (pelabuhan) =====
local riverPos = PATH[Config.RIVER_PATH_INDEX]
local riverDir = (PATH[Config.RIVER_PATH_INDEX] - PATH[Config.RIVER_PATH_INDEX - 1])
local riverYaw = Vector3.new(riverDir.X, 0, riverDir.Z)
if riverYaw.Magnitude < 0.01 then
	riverYaw = Vector3.new(0, 0, 1)
end
local riverPerp = Vector3.new(riverYaw.Z, 0, -riverYaw.X).Unit -- arah melintang jalur
do
	-- air mengisi parit melintang jalur: lebar (sepanjang jalur)=46, span melintang=260
	local center = Vector3.new(riverPos.X, riverPos.Y - 2, riverPos.Z)
	local cf = CFrame.lookAt(center, center + riverPerp)
	Terrain:FillBlock(cf, Vector3.new(46, 22, 260), Enum.Material.Water)
end

-- Laut di pelabuhan (z besar), permukaan ~y0
do
	local harbor = PATH[#PATH]
	Terrain:FillBlock(
		CFrame.new(harbor.X, -7, harbor.Z + 150),
		Vector3.new(640, 18, 360),
		Enum.Material.Water
	)
end

-- ===== Props: jembatan kayu + batu pijakan =====
-- Jembatan kayu menyeberangi sungai
do
	local center = Vector3.new(riverPos.X, riverPos.Y + 1, riverPos.Z)
	local plank = makePart("LogBridge", Vector3.new(12, 2, 70), uprightCFrame(center, riverYaw), Color3.fromRGB(96, 68, 44), propsFolder)
	plank.Material = Enum.Material.WoodPlanks
	-- pegangan/penanda agar terlihat
	for side = -1, 1, 2 do
		local rail = makePart("Rail", Vector3.new(1, 4, 70), uprightCFrame(center + Vector3.new(0, 3, 0), riverYaw) + (riverPerp * (side * 6)), Color3.fromRGB(80, 56, 36), propsFolder)
		rail.Material = Enum.Material.Wood
	end
end

-- Batu pijakan di pendakian S2 (sekadar pijakan flavor, CanCollide)
do
	local base = PATH[3]
	local dir = (PATH[3] - PATH[2])
	for i = 1, 4 do
		local p = base + Vector3.new(rng:NextNumber(-26, 26), -2, rng:NextNumber(-20, 20))
		local rock = makePart("SteppingStone", Vector3.new(rng:NextNumber(8, 14), 6, rng:NextNumber(8, 14)), uprightCFrame(p, dir), Color3.fromRGB(96, 94, 92), propsFolder)
		rock.Material = Enum.Material.Slate
	end
end

-- ===== Landmark =====
-- Pohon raksasa di puncak S2
do
	local summit = PATH[4]
	local trunk = makePart("GiantTrunk", Vector3.new(14, 130, 14), CFrame.new(summit + Vector3.new(0, 65, 0)), Color3.fromRGB(82, 58, 40), forestFolder)
	trunk.Material = Enum.Material.Wood
	local canopy = makePart("GiantCanopy", Vector3.new(80, 80, 80), CFrame.new(summit + Vector3.new(0, 150, 0)), Color3.fromRGB(54, 92, 50), forestFolder)
	canopy.Shape = Enum.PartType.Ball
	canopy.Material = Enum.Material.Grass
	canopy.CanCollide = false
end

-- Mercusuar di pelabuhan
do
	local harbor = PATH[#PATH]
	-- Cylinder: sumbu silinder = Size.X (tinggi=110, diameter=16). Putar agar tegak.
	local tower = makePart("Lighthouse", Vector3.new(110, 16, 16), CFrame.new(harbor + Vector3.new(28, 55, -10)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(225, 225, 230), forestFolder)
	tower.Shape = Enum.PartType.Cylinder
	local lamp = makePart("LighthouseLamp", Vector3.new(12, 12, 12), CFrame.new(harbor + Vector3.new(28, 116, -10)), Color3.fromRGB(255, 240, 180), forestFolder)
	lamp.Shape = Enum.PartType.Ball
	lamp.Material = Enum.Material.Neon
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 60
	light.Color = Color3.fromRGB(255, 230, 170)
	light.Parent = lamp
end

-- Dermaga pelabuhan
do
	local harbor = PATH[#PATH]
	local dock = makePart("HarborDock", Vector3.new(46, 2, 60), CFrame.new(harbor + Vector3.new(0, 1, 28)), Color3.fromRGB(110, 80, 55), propsFolder)
	dock.Material = Enum.Material.WoodPlanks
end

-- ===== Foliage acak (skala & rotasi bervariasi) =====
local TRUNK_COLOR = Color3.fromRGB(84, 60, 42)
local LEAF_COLORS = {
	Color3.fromRGB(58, 92, 48),
	Color3.fromRGB(70, 104, 54),
	Color3.fromRGB(48, 82, 44),
}

local function makeTree(pos: Vector3)
	local model = Instance.new("Model")
	model.Name = "Tree"
	local scale = rng:NextNumber(0.7, 1.7)
	local h = 18 * scale
	local trunk = makePart(
		"Trunk",
		Vector3.new(2.4 * scale, h, 2.4 * scale),
		CFrame.new(pos + Vector3.new(0, h / 2 - 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
		TRUNK_COLOR,
		model
	)
	trunk.Material = Enum.Material.Wood
	local leafD = 13 * scale
	local leaf = makePart(
		"Leaf",
		Vector3.new(leafD, leafD * 1.1, leafD),
		CFrame.new(pos + Vector3.new(rng:NextNumber(-2, 2), h + leafD * 0.25, rng:NextNumber(-2, 2))),
		LEAF_COLORS[rng:NextInteger(1, #LEAF_COLORS)],
		model
	)
	leaf.Shape = Enum.PartType.Ball
	leaf.Material = Enum.Material.Grass
	leaf.CanCollide = false
	model.Parent = foliageFolder
end

local function makeBush(pos: Vector3)
	local d = rng:NextNumber(4, 8)
	local bush = makePart("Bush", Vector3.new(d, d * 0.7, d), CFrame.new(pos + Vector3.new(0, d * 0.3, 0)), LEAF_COLORS[rng:NextInteger(1, #LEAF_COLORS)], foliageFolder)
	bush.Shape = Enum.PartType.Ball
	bush.Material = Enum.Material.Grass
	bush.CanCollide = false
end

-- Sebar foliage di sisi jalur (hindari air & pantai)
for leg = 1, #PATH - 1 do
	local a = PATH[leg]
	local b = PATH[leg + 1]
	local material = Config.LEG_MATERIAL[leg]
	if material == Enum.Material.Sand then
		continue -- pantai: tanpa pohon
	end
	local legVec = b - a
	local yaw = Vector3.new(legVec.X, 0, legVec.Z)
	if yaw.Magnitude < 0.01 then
		yaw = Vector3.new(0, 0, 1)
	end
	local perp = Vector3.new(yaw.Z, 0, -yaw.X).Unit
	local count = math.floor(legVec.Magnitude / 26)
	for i = 1, count do
		local t = (i - 0.5) / count
		local base = a:Lerp(b, t)
		for side = -1, 1, 2 do
			local offset = rng:NextNumber(26, 64)
			local pos = base + perp * (side * offset) + Vector3.new(0, 0, 0)
			if rng:NextNumber() < 0.8 then
				makeTree(pos)
			else
				makeBush(pos)
			end
		end
	end
end

-- ===== Zona trigger (pilar marker + objektif + checkpoint) =====
local OBJ_COLOR = Color3.fromRGB(255, 215, 0)
local HARBOR_COLOR = Color3.fromRGB(120, 200, 255)
local CP_COLOR = Color3.fromRGB(90, 200, 120)

local function makeTriggerZone(name: string, pos: Vector3, color: Color3, parent: Instance): Part
	local zone = makePart(name, Vector3.new(Config.TRIGGER_RADIUS * 2, 14, Config.TRIGGER_RADIUS * 2), CFrame.new(pos + Vector3.new(0, 6, 0)), color, parent)
	zone.CanCollide = false
	zone.Transparency = 0.7
	zone.Material = Enum.Material.ForceField
	return zone
end

for _, obj in Config.OBJECTIVES do
	local pos = PATH[obj.pathIndex]
	local color = obj.isHarbor and HARBOR_COLOR or OBJ_COLOR
	-- pilar beacon
	local pillar = makePart("Beacon_" .. obj.order, Vector3.new(4, 60, 4), CFrame.new(pos + Vector3.new(0, 30, 0)), color, forestFolder)
	pillar.Material = Enum.Material.Neon
	pillar.CanCollide = false
	-- zona objektif
	local zone = makeTriggerZone("Objective_" .. obj.order, pos, color, objectivesFolder)
	zone:SetAttribute("ObjectiveOrder", obj.order)
	zone:SetAttribute("IsHarbor", obj.isHarbor)
end

for _, cp in Config.CHECKPOINTS do
	local pos = PATH[cp.pathIndex]
	local zone = makeTriggerZone("Checkpoint_" .. cp.order, pos, CP_COLOR, checkpointsFolder)
	zone:SetAttribute("CheckpointOrder", cp.order)
end

-- ===== Hazard: kill zone di sungai (jatuh -> respawn checkpoint) =====
do
	local center = Vector3.new(riverPos.X, riverPos.Y - 3, riverPos.Z)
	local kill = makePart("RiverKill", Vector3.new(40, 10, 250), CFrame.lookAt(center, center + riverPerp), Color3.new(1, 0, 0), hazardsFolder)
	kill.CanCollide = false
	kill.Transparency = 1
	kill:SetAttribute("Hazard", true)
end

print("[MapBuilder] Hutan terrain (5 segmen, ~2.100 stud) selesai dibangun.")
