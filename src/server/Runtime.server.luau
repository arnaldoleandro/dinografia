local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Dinografia")
local Config, Trace = require(shared.Config), require(shared.Trace)
local Cage, Blue = require(script.Parent.Cage), require(script.Parent.Blue)

for _, name in ipairs({ "DinografiaPlayers", "DinografiaBlue" }) do
	if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
end
PhysicsService:CollisionGroupSetCollidable("DinografiaBlue", "DinografiaPlayers", false)
PhysicsService:CollisionGroupSetCollidable("DinografiaBlue", "DinografiaBlue", false)
PhysicsService:CollisionGroupSetCollidable("DinografiaBlue", "Default", true)

local playerConnections, characterConnections = {}, {}
local sessions, requests = {}, {}
local function setupCharacter(player, character)
	if characterConnections[player] then characterConnections[player]:Disconnect() end
	sessions[player] = nil
	local function assign(item)
		if item:IsA("BasePart") then item.CollisionGroup = "DinografiaPlayers" end
	end
	characterConnections[player] = character.DescendantAdded:Connect(assign)
	for _, item in ipairs(character:GetDescendants()) do assign(item) end
end
local function setupPlayer(player)
	playerConnections[player] = player.CharacterAdded:Connect(function(character) setupCharacter(player, character) end)
	if player.Character then setupCharacter(player, player.Character) end
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	if playerConnections[player] then playerConnections[player]:Disconnect(); playerConnections[player] = nil end
	if characterConnections[player] then characterConnections[player]:Disconnect(); characterConnections[player] = nil end
	sessions[player], requests[player] = nil, nil
end)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end

require(script.Parent.Environment)()
local cage = Cage.new()
local unlocked, owner, blue = false, nil, nil
local function spawnBlue()
	blue = Blue.new(ServerStorage:WaitForChild("BlueTemplate"), cage, function()
		blue = nil
		task.delay(Config.RespawnSeconds, spawnBlue)
	end)
	if unlocked then blue:Unlock(owner) end
end
spawnBlue()

local remote = Instance.new("RemoteEvent")
remote.Name = "Activity"
remote.Parent = shared
local function allow(player, action)
	local now = os.clock()
	local last = requests[player] or {}
	if now - (last[action] or -math.huge) < 0.5 then return false end
	last[action] = now
	requests[player] = last
	return true
end
remote.OnServerEvent:Connect(function(player, action, token, samples)
	if type(action) ~= "string" then return end
	if action ~= "begin" and action ~= "complete" and action ~= "cancel" then return end
	if not allow(player, action) then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		sessions[player] = nil
		remote:FireClient(player, "error", "Espere seu personagem aparecer e tente novamente.")
		return
	end
	if action == "begin" then
		local root=character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position-cage.Panel.Position).Magnitude>Config.ActivityDistance then
			remote:FireClient(player,"error","Chegue mais perto da porta da Blue.")
			return
		end
		local session = { token = HttpService:GenerateGUID(false), character = character }
		sessions[player] = session
		remote:FireClient(player, "ready", session.token)
		return
	end
	local session = sessions[player]
	if not session or type(token) ~= "string" or token ~= session.token or session.character ~= character then return end
	if action == "cancel" then sessions[player] = nil; return end
	local valid = Trace.Validate(samples, Config.TraceTolerance, Config.MaxTraceSamples)
	if not valid then
		remote:FireClient(player, "error", "Vamos tentar de novo, seguindo a faixa do V.", token)
		return
	end
	-- Consume before granting. Retries/replayed packets cannot reward twice.
	sessions[player] = nil
	owner = player
	remote:FireClient(player, "complete", token)
	cage:Open(function()
		unlocked = true
		if blue then blue:Unlock(owner) end
	end)
end)

print("[Dinografia] Pronto: V guiado, jaula alinhada e Blue com ciclo único de respawn.")
