--!strict
-- Dispatcher RemoteEvent terpusat (Req.md aturan #3 & tabel RemoteEvents di requirement).
-- Server membuat folder + event; client menunggu (WaitForChild). Diakses lewat satu modul.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local REMOTE_NAMES = {
	"UpdateObjective", -- Server -> Client: posisi objektif aktif (untuk compass)
	"CheckpointReached", -- Server -> Client: feedback UI saat checkpoint aktif
	"PhaseComplete", -- Server -> Client: trigger UI transisi pelabuhan
	"SetFog", -- Server -> Client: aktif/nonaktif fog
}

local folder: Folder
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in REMOTE_NAMES do
		if not folder:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local Remotes: { [string]: RemoteEvent } = {}
for _, name in REMOTE_NAMES do
	Remotes[name] = folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
