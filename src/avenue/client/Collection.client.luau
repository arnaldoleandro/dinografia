local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local templates = ReplicatedStorage:WaitForChild("DinosaurTemplates")
local stations = workspace:WaitForChild("AlphabetStations")
local visuals = Instance.new("Folder")
visuals.Name = "DinosaurVisuals"
visuals.Parent = workspace

local MAX_FOLLOWERS, MAX_PREVIEWS = 6, 6
local PREVIEW_DISTANCE, STEP, SPACING = 150, 0.05, 5
local previews, followers = {}, {}
local trail, trailFirst, trailLast = {}, 1, 0
local elapsed, pollElapsed, animationTime = 0, 0, 0
local lastCount = -1
local character = player.Character
local root, humanoid
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude

-- Reads the server-owned ordered collection prefix without accepting invalid attributes.
local function count()
	local value = player:GetAttribute("CollectedCount")
	return if type(value) == "number" then math.clamp(math.floor(value),0,26) else 0
end

-- Resolves a station's explicit ground pivot instead of deriving it from cage bounds.
local function stationFor(index)
	for _, station in stations:GetChildren() do
		if station:GetAttribute("StationIndex") == index then
			local origin = station:GetAttribute("StationCFrame")
			if typeof(origin) == "CFrame" then return station, origin end
		end
	end
	return nil, nil
end

-- Clones only visible cosmetics and prevents them from intercepting world input or physics.
local function clone(letter, scale)
	local template = templates:FindFirstChild(letter)
	if not template or not template:IsA("Model") then return nil end
	local model = template:Clone()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		end
	end
	if scale ~= 1 then model:ScaleTo(scale) end
	model.Parent = visuals
	return model
end

-- Finds the player's ground level while excluding all avatars and cosmetic dinosaurs.
local function groundPosition()
	local excluded = { visuals }
	for _, other in Players:GetPlayers() do
		if other.Character then table.insert(excluded, other.Character) end
	end
	floorParams.FilterDescendantsInstances = excluded
	local hit = workspace:Raycast(root.Position,Vector3.new(0,-12,0),floorParams)
	if hit then return hit.Position end
	return root.Position - Vector3.new(0,(humanoid and humanoid.HipHeight or 2)+root.Size.Y/2,0)
end

-- Saves a bounded breadcrumb trail so followers retrace turns instead of targeting through walls.
local function recordTrail(position)
	local previous = trail[trailLast]
	if previous and (previous-position).Magnitude < 1 then return end
	trailLast += 1
	trail[trailLast] = position
	while trailLast-trailFirst > 600 do trail[trailFirst] = nil; trailFirst += 1 end
end

-- Returns the breadcrumb behind the player at the requested following distance.
local function targetIndex(distance)
	local remaining = distance
	for index=trailLast,trailFirst+1,-1 do
		remaining -= (trail[index]-trail[index-1]).Magnitude
		if remaining <= 0 then return index-1 end
	end
	return trailFirst
end

-- Joins the recorded route at its closest point after crossing the cage's open doorway.
local function nearestIndex(position)
	local nearest, distance = trailFirst, math.huge
	for index=trailFirst,trailLast do
		local current = (trail[index]-position).Magnitude
		if current < distance then nearest, distance = index, current end
	end
	return nearest
end

-- Moves a cosmetic at a bounded speed while preserving an upright orientation.
local function move(follower, target, delta)
	local offset = target-follower.position
	local distance = offset.Magnitude
	local step = math.min(distance,18*delta)
	if distance > 0.02 then
		follower.position += offset.Unit*step
		local flat = Vector3.new(offset.X,0,offset.Z)
		if flat.Magnitude > 0.01 then follower.facing = flat.Unit end
	end
	local bob = if distance > 0.2 then math.sin(animationTime*8+follower.index)*0.06 else 0
	local position = follower.position+Vector3.new(0,0.04+bob,0)
	follower.model:PivotTo(CFrame.lookAt(position,position+follower.facing))
	return distance <= step+0.05
end

-- Keeps only nearby uncollected exhibits and the newest six collected companions instantiated.
local function refresh()
	if not root or not root.Parent then return end
	local collected = count()
	local candidates = {}
	for _, station in stations:GetChildren() do
		local index, origin = station:GetAttribute("StationIndex"), station:GetAttribute("StationCFrame")
		if type(index)=="number" and typeof(origin)=="CFrame" and index>collected then
			local distance = (origin.Position-root.Position).Magnitude
			if distance <= PREVIEW_DISTANCE then table.insert(candidates,{index=index,origin=origin,distance=distance}) end
		end
	end
	table.sort(candidates,function(a,b) return a.distance<b.distance end)
	local wanted = {}
	for i=1,math.min(MAX_PREVIEWS,#candidates) do
		local candidate = candidates[i]
		wanted[candidate.index] = true
		if not previews[candidate.index] then
			local model = clone(string.char(64+candidate.index),1)
			if model then model:PivotTo(candidate.origin*CFrame.new(0,0.5,0)); previews[candidate.index]=model end
		end
	end
	for index, model in previews do
		if not wanted[index] then model:Destroy(); previews[index]=nil end
	end
	local firstFollower = math.max(1,collected-MAX_FOLLOWERS+1)
	for index, follower in followers do
		if index<firstFollower or index>collected then follower.model:Destroy(); followers[index]=nil end
	end
	for index=firstFollower,collected do
		if not followers[index] then
			local model = clone(string.char(64+index),0.4)
			local _, origin = stationFor(index)
			if model then
				local newlyReleased = lastCount>=0 and index>lastCount and origin~=nil
				local position = if newlyReleased then (origin*CFrame.new(0,0.5,0)).Position else trail[trailFirst] or groundPosition()
				followers[index] = { model=model, index=index, position=position, facing=Vector3.new(0,0,-1), cursor=trailFirst, exit=if newlyReleased then (origin*CFrame.new(0,0.5,-24)).Position else nil }
				move(followers[index],position,STEP)
			end
		end
	end
	lastCount = collected
end

-- Clears positional history on respawn so companions never follow an obsolete avatar path.
local function reset(nextCharacter)
	character, root, humanoid = nextCharacter, nil, nil
	for _, follower in followers do follower.model:Destroy() end
	table.clear(followers)
	table.clear(trail)
	trailFirst, trailLast, lastCount = 1,0,-1
end

player.CharacterAdded:Connect(reset)
player.CharacterRemoving:Connect(function() reset(nil) end)
player:GetAttributeChangedSignal("CollectedCount"):Connect(function() pollElapsed=0.5 end)

-- Updates a bounded number of local companions at 20 Hz; gameplay remains server-owned.
local connection = RunService.Heartbeat:Connect(function(delta)
	elapsed += delta
	if elapsed<STEP then return end
	local frameDelta = math.min(elapsed,0.15)
	elapsed = 0
	animationTime += frameDelta
	if not character or not character.Parent then return end
	root = character:FindFirstChild("HumanoidRootPart")
	humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root then return end
	recordTrail(groundPosition())
	pollElapsed += frameDelta
	if pollElapsed>=0.5 then pollElapsed=0; refresh() end
	local collected = count()
	for index, follower in followers do
		if follower.exit then
			if move(follower,follower.exit,frameDelta) then
				follower.exit=nil
				follower.cursor=nearestIndex(follower.position)
			end
		else
			local target = targetIndex((collected-index+1)*SPACING)
			follower.cursor=math.clamp(follower.cursor,trailFirst,trailLast)
			local position = trail[follower.cursor]
			if position and move(follower,position,frameDelta) and follower.cursor<target then follower.cursor+=1 end
		end
	end
end)

script.Destroying:Connect(function()
	connection:Disconnect()
	visuals:Destroy()
end)
