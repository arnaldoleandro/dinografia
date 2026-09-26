local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Config = require(game:GetService("ReplicatedStorage").Dinografia.Config)

local Blue = {}
Blue.__index = Blue

local function flatDistance(a, b)
	return Vector3.new(a.X-b.X, 0, a.Z-b.Z).Magnitude
end

local function characterRoot(player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return if humanoid and humanoid.Health > 0 then character:FindFirstChild("HumanoidRootPart") else nil
end

function Blue.new(template, cage, onDeath)
	local model = template:Clone()
	model.Name = "Blue"
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BaseScript") then item:Destroy() end
	end
	local body = assert(model:FindFirstChild("Body"), "Blue precisa de Body")
	local humanoid = assert(body:FindFirstChildOfClass("Humanoid"), "Blue precisa de Humanoid")
	local root = assert(body:FindFirstChild("HumanoidRootPart"), "Blue precisa de HumanoidRootPart")
	assert(body:FindFirstChild("BoundingBox"), "Blue precisa do collider BoundingBox")
	model.PrimaryPart = root
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then
			item.CollisionGroup = "DinografiaBlue"
			item.Anchored = false
			-- Keep the original rig's feet/root and torso collider; decorative limbs
			-- cannot catch the gate or push one another during animation.
			item.CanCollide = item == root or item.Name == "BoundingBox"
			item.Massless = not item.CanCollide
		end
	end
	root.Anchored = true
	humanoid.WalkSpeed = Config.WalkSpeed
	humanoid.AutoRotate = true
	humanoid.HipHeight = 0 -- This exported custom rig stands on its small root.
	local position = cage.Center + Vector3.new(0, cage.FloorTop + root.Size.Y/2 + 0.06, 0)
	local targetRoot = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	model:PivotTo(targetRoot * root.CFrame:Inverse() * model:GetPivot())
	model:SetAttribute("Unlocked", false)
	model:SetAttribute("State", "Locked")
	model.Parent = workspace
	local self = setmetatable({ Model = model, Root = root, Humanoid = humanoid,
		alive = true, unlocked = false, owner = nil, connections = {}, tracks = {},
		path = nil, blocked = false, waypointIndex = 1, moving = false,
		nextPlan = 0, targetPosition = nil, waypointStarted = 0 }, Blue)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	for name, id in pairs({ Idle = "1776597036", Walk = "1776392604", Jump = "507765000" }) do
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. id
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		animation:Destroy()
		if ok then
			track.Looped = name ~= "Jump"
			track.Priority = if name == "Idle" then Enum.AnimationPriority.Idle else Enum.AnimationPriority.Movement
			self.tracks[name] = track
		else
			warn("[Dinografia] Animação indisponível:", name, track)
		end
	end
	local function play(name, speed)
		if self.animation ~= name then
			for _, track in pairs(self.tracks) do track:Stop(0.2) end
			self.animation = name
			if self.tracks[name] then self.tracks[name]:Play(0.2) end
		end
		if name == "Walk" and self.tracks.Walk then
			self.tracks.Walk:AdjustSpeed(math.clamp((speed or Config.WalkSpeed)/10, 0.5, 1.6))
		end
	end
	play("Idle")
	table.insert(self.connections, humanoid.Running:Connect(function(speed)
		if self.alive then play(if speed > 0.4 and self.unlocked then "Walk" else "Idle", speed) end
	end))
	table.insert(self.connections, humanoid.Died:Connect(function()
		if not self.alive then return end
		self:Destroy()
		onDeath()
	end))
	-- A single worker owns all ComputeAsync calls: no overlapping Heartbeat jobs.
	task.spawn(function()
		while self.alive and model.Parent and humanoid.Health > 0 do
			self:Step()
			task.wait(0.1)
		end
	end)
	return self
end

function Blue:ClearPath()
	if self.blockConnection then self.blockConnection:Disconnect(); self.blockConnection = nil end
	if self.path then self.path:Destroy(); self.path = nil end
	self.waypoints = nil
	self.blocked = false
	self.targetPosition = nil
end

function Blue:Stop()
	self:ClearPath()
	self.moving = false
	self.Humanoid:Move(Vector3.zero)
	self.Humanoid:MoveTo(self.Root.Position)
	self.Model:SetAttribute("State", if self.unlocked then "Resting" else "Locked")
end

function Blue:Unlock(player)
	if not self.alive then return end
	if not self.unlocked then
		self.unlocked = true
		self.Model:SetAttribute("Unlocked", true)
		self.Root.Anchored = false
		self.Root.AssemblyLinearVelocity = Vector3.zero
		self.Root.AssemblyAngularVelocity = Vector3.zero
		local canSet = self.Root:CanSetNetworkOwnership()
		if canSet then self.Root:SetNetworkOwner(nil) end
	end
	if player and player.Parent == Players then
		self.owner = player
		self:ClearPath()
	end
end

function Blue:Plan(target)
	self:ClearPath()
	self.nextPlan = os.clock() + Config.RepathSeconds
	local path = PathfindingService:CreatePath({ AgentRadius = Config.AgentRadius,
		AgentHeight = Config.AgentHeight, AgentCanJump = true, WaypointSpacing = 4 })
	local ok = pcall(function() path:ComputeAsync(self.Root.Position, target) end)
	if not self.alive or not self.Model.Parent then path:Destroy(); return end
	if not ok or path.Status ~= Enum.PathStatus.Success then
		path:Destroy()
		self.Humanoid:MoveTo(self.Root.Position)
		self.Model:SetAttribute("State", "WaitingForPath")
		return
	end
	self.path, self.targetPosition = path, target
	self.waypoints = path:GetWaypoints()
	self.waypointIndex = 1
	while self.waypointIndex < #self.waypoints
		and flatDistance(self.Root.Position, self.waypoints[self.waypointIndex].Position) < 2 do
		self.waypointIndex += 1
	end
	self.waypointStarted = os.clock()
	self.blockConnection = path.Blocked:Connect(function(index)
		if index >= self.waypointIndex then self.blocked = true end
	end)
	self.commandedIndex = nil
end

function Blue:Step()
	if not self.unlocked then return end
	if self.Root.Position.Y < -80 then
		self.Humanoid.Health = 0 -- Recover via the one respawn lifecycle, never a path teleport.
		return
	end
	local targetRoot = characterRoot(self.owner)
	if not targetRoot then
		local nearest, bestDistance = nil, 150
		for _, player in ipairs(Players:GetPlayers()) do
			local candidate = characterRoot(player)
			if candidate then
				local distance = flatDistance(candidate.Position, self.Root.Position)
				if distance < bestDistance then nearest, bestDistance = player, distance end
			end
		end
		self.owner = nearest
		targetRoot = characterRoot(nearest)
		self:ClearPath()
	end
	if not targetRoot then self:Stop(); return end
	local distance = flatDistance(self.Root.Position, targetRoot.Position)
	if distance <= Config.FollowDistance or (not self.moving and distance < Config.FollowResumeDistance) then
		if self.moving or self.path then self:Stop() end
		return
	end
	self.moving = true
	local direction = Vector3.new(targetRoot.Position.X-self.Root.Position.X, 0, targetRoot.Position.Z-self.Root.Position.Z).Unit
	local destination = targetRoot.Position - direction * (Config.FollowDistance - 2)
	local moved = self.targetPosition and flatDistance(destination, self.targetPosition) > 5
	local expired = self.waypoints and os.clock() - self.waypointStarted > Config.WaypointTimeout
	if self.blocked or expired then
		self:ClearPath()
		self.Humanoid:MoveTo(self.Root.Position)
	end
	if (not self.path or moved) and os.clock() >= self.nextPlan then self:Plan(destination) end
	if not self.alive or not self.Model.Parent or not self.waypoints then return end
	-- ComputeAsync yields. Do not apply its result to a departed/dead target.
	if characterRoot(self.owner) ~= targetRoot then self:Stop(); return end
	local waypoint = self.waypoints[self.waypointIndex]
	if waypoint and flatDistance(self.Root.Position, waypoint.Position) < 2 then
		self.waypointIndex += 1
		self.waypointStarted = os.clock()
		waypoint = self.waypoints[self.waypointIndex]
	end
	if not waypoint then self:ClearPath(); return end
	if self.commandedIndex ~= self.waypointIndex then
		self.commandedIndex = self.waypointIndex
		self.Model:SetAttribute("State", "Following")
		if waypoint.Action == Enum.PathWaypointAction.Jump then self.Humanoid.Jump = true end
		self.Humanoid:MoveTo(waypoint.Position)
	end
end

function Blue:Destroy()
	if not self.alive then return end
	self.alive = false
	self:ClearPath()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	for _, track in pairs(self.tracks) do track:Stop(); track:Destroy() end
	self.Model:Destroy()
end

return Blue
