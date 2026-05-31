--!strict
-- Konstanta bersama (server & client). Lihat REQUIREMENTS-FOREST-DESIGN.md.
-- Dunia dibangun mengikuti CENTERLINE (Config.PATH): polyline 3D berelevasi yang
-- menjadi tulang punggung terrain, jalur, checkpoint, dan objektif.

local Config = {}

-- ===== Centerline perjalanan (titik kontrol, urut start -> pelabuhan) =====
-- (X, Y=elevasi permukaan, Z). Total ~2.100 stud, beda elevasi ~115 stud.
Config.PATH = {
	Vector3.new(0, 30, 0), -- 1  S1 Tepi Hutan (start)
	Vector3.new(40, 34, 220), -- 2  S1->S2 (kaki bukit)
	Vector3.new(20, 80, 420), -- 3  S2 mendaki
	Vector3.new(-30, 120, 600), -- 4  S2 PUNCAK (tertinggi, landmark + vista)
	Vector3.new(-60, 70, 820), -- 5  turun ke lembah
	Vector3.new(-40, 42, 1020), -- 6  S3 Lembah Sungai (river crossing)
	Vector3.new(0, 40, 1240), -- 7  S3->S4
	Vector3.new(30, 40, 1480), -- 8  S4 Hutan Rapat Berkabut (datar)
	Vector3.new(10, 38, 1700), -- 9  S4->S5 (puncak tebing)
	Vector3.new(-20, 16, 1880), -- 10 S5 turun tebing
	Vector3.new(0, 5, 2060), -- 11 S5 Pantai & Pelabuhan (sea level, terendah)
}

-- Material terrain per "leg" (antar titik kontrol). Panjang = #PATH - 1.
Config.LEG_MATERIAL = {
	Enum.Material.Grass, -- 1-2  S1
	Enum.Material.Rock, -- 2-3  pendakian
	Enum.Material.Rock, -- 3-4  puncak
	Enum.Material.Grass, -- 4-5  turun
	Enum.Material.Grass, -- 5-6  lembah
	Enum.Material.Grass, -- 6-7
	Enum.Material.LeafyGrass, -- 7-8  hutan berkabut
	Enum.Material.LeafyGrass, -- 8-9
	Enum.Material.Rock, -- 9-10 tebing
	Enum.Material.Sand, -- 10-11 pantai
}

-- Checkpoint (F-03): satu di tiap awal segmen. order = urutan maju.
Config.CHECKPOINTS = {
	{ pathIndex = 1, order = 1 }, -- start S1
	{ pathIndex = 2, order = 2 }, -- sebelum pendakian S2
	{ pathIndex = 4, order = 3 }, -- puncak S2 / awal S3
	{ pathIndex = 7, order = 4 }, -- sebelum kabut S4
	{ pathIndex = 9, order = 5 }, -- sebelum tebing S5
}

-- Objektif (F-05): target compass berturut. Objektif terakhir = pelabuhan.
Config.OBJECTIVES = {
	{ pathIndex = 2, order = 1, isHarbor = false },
	{ pathIndex = 4, order = 2, isHarbor = false }, -- puncak (vista)
	{ pathIndex = 7, order = 3, isHarbor = false },
	{ pathIndex = 9, order = 4, isHarbor = false },
	{ pathIndex = 11, order = 5, isHarbor = true }, -- pelabuhan
}

-- Sungai melintang menyeberangi jalur (S3).
Config.RIVER_PATH_INDEX = 6

-- Zona kabut S4 (rentang Z). Compass jadi krusial di sini.
Config.FOG_ZONE = { zMin = 1200, zMax = 1720 }
Config.FOG_START = 12
Config.FOG_END = 80

-- ===== Parameter generasi terrain =====
Config.RIBBON_WIDTH = 150 -- lebar pita terrain di sepanjang jalur
Config.SAMPLE_SPACING = 12 -- jarak antar sampel saat mengisi terrain
Config.TERRAIN_FLOOR_Y = -16 -- dasar terrain (di bawah sea level)
Config.PATH_STRIP_WIDTH = 18 -- lebar "jalur setapak" material kontras

-- ===== Gameplay =====
Config.TRIGGER_RADIUS = 14 -- radius zona checkpoint/objektif
Config.TOUCH_DEBOUNCE = 1.5
Config.TRANSITION_HOLD = 3.5 -- durasi layar transisi sebelum loop respawn
Config.FALLEN_DESTROY_HEIGHT = -40 -- jatuh dari jalur -> respawn

return Config
