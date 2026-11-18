-- Remotes: every RemoteEvent the game uses, created once in ReplicatedStorage.
-- Server modules require this module and fire through it; the client finds
-- the same events with WaitForChild. One home for all client-server traffic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if folder == nil then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local function makeRemote(name)
	local existing = folder:FindFirstChild(name)
	if existing ~= nil then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

-- Client -> server requests.
Remotes.SlapPlayer = makeRemote("SlapPlayer")
Remotes.LockBase = makeRemote("LockBase")
Remotes.Rebirth = makeRemote("Rebirth")
Remotes.BuyUpgrade = makeRemote("BuyUpgrade")
Remotes.RequestState = makeRemote("RequestState")

-- Server -> client updates.
Remotes.StateUpdate = makeRemote("StateUpdate")
Remotes.Announce = makeRemote("Announce")
Remotes.Toast = makeRemote("Toast")
Remotes.Effect = makeRemote("Effect")

-- Sends a short toast message to one player.
function Remotes.toastPlayer(player, text)
	Remotes.Toast:FireClient(player, text)
end

-- Sends a banner announcement to every player.
function Remotes.announceAll(title, subtitle)
	Remotes.Announce:FireAllClients(title, subtitle or "")
end

-- Plays a named visual effect at a world position for every player.
function Remotes.playEffect(effectName, position)
	Remotes.Effect:FireAllClients(effectName, position)
end

return Remotes
