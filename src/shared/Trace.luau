-- Pure Luau: shared by the UI, server validation and command-line tests.
local Trace = {}
Trace.__index = Trace
Trace.Points = table.freeze({ { x = 0.2, y = 0.16 }, { x = 0.5, y = 0.82 }, { x = 0.8, y = 0.16 } })

local function distance(a, b)
	return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end

local function segmentDistance(p, a, b)
	local dx, dy = b.x - a.x, b.y - a.y
	local t = math.clamp(((p.x - a.x)*dx + (p.y - a.y)*dy)/(dx*dx + dy*dy), 0, 1)
	return distance(p, { x = a.x + dx*t, y = a.y + dy*t })
end

function Trace.new(tolerance)
	local checkpoints = {}
	for segment = 1, 2 do
		local a, b = Trace.Points[segment], Trace.Points[segment + 1]
		for i = if segment == 1 then 0 else 1, 24 do
			table.insert(checkpoints, { x = a.x + (b.x-a.x)*i/24, y = a.y + (b.y-a.y)*i/24 })
		end
	end
	return setmetatable({ checkpoints = checkpoints, nextIndex = 1, last = nil,
		tolerance = tolerance or 0.075, complete = false }, Trace)
end

function Trace:GetProgress()
	return math.clamp((self.nextIndex - 1)/#self.checkpoints, 0, 1)
end

function Trace:GetResumePoint()
	return self.checkpoints[math.clamp(self.nextIndex - 1, 1, #self.checkpoints)]
end

function Trace:Lift()
	self.last = nil
end

function Trace:Feed(sample)
	if type(sample) ~= "table" or not finite(sample.x) or not finite(sample.y)
		or math.abs(sample.x) > 2 or math.abs(sample.y) > 2
		or (sample.start ~= nil and type(sample.start) ~= "boolean") then
		return false, "invalid"
	end
	if self.complete then return true, "complete" end
	if sample.start then self:Lift() end
	local point = { x = sample.x, y = sample.y }
	if not self.last then
		if distance(point, self:GetResumePoint()) > self.tolerance then
			return false, "resume"
		end
		self.last = point
	end
	local start = self.last
	local length = distance(start, point)
	-- Do not infer a stroke from a pointer teleport or two isolated taps.
	if length > 0.3 then
		self:Lift()
		return false, "resume"
	end
	local steps = math.max(1, math.ceil(length/0.01))
	for step = 1, steps do
		local p = { x = start.x + (point.x-start.x)*step/steps, y = start.y + (point.y-start.y)*step/steps }
		local onGuide = math.min(segmentDistance(p, Trace.Points[1], Trace.Points[2]),
			segmentDistance(p, Trace.Points[2], Trace.Points[3])) <= self.tolerance
		if not onGuide then
			self:Lift()
			return false, "resume"
		end
		while self.nextIndex <= #self.checkpoints
			and distance(p, self.checkpoints[self.nextIndex]) <= self.tolerance do
			self.nextIndex += 1
		end
	end
	self.last = point
	self.complete = self.nextIndex > #self.checkpoints
	return true, if self.complete then "complete" else "drawing"
end

function Trace.Validate(samples, tolerance, limit)
	if type(samples) ~= "table" or #samples < 3 or #samples > (limit or 2048) then
		return false, "invalid"
	end
	local count = 0
	for key in pairs(samples) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #samples then return false, "invalid" end
		count += 1
	end
	if count ~= #samples then return false, "invalid" end
	local trace = Trace.new(tolerance)
	for _, sample in ipairs(samples) do
		local _, status = trace:Feed(sample)
		if status == "invalid" then return false, status end
	end
	return trace.complete, if trace.complete then "complete" else "incomplete"
end

return Trace
