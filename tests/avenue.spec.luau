local Layout = require("../src/shared/AvenueLayout")
local Journey = require("../src/shared/JourneyProgress")
local passed = 0

-- Runs a named assertion group and records successful checks.
local function test(name, callback)
	local ok, failure = pcall(callback)
	assert(ok, name .. ": " .. tostring(failure))
	passed += 1
	print("PASS", name)
end

test("station positions alternate across thirteen ordered rows", function()
	assert(Layout.Count == 26)
	for row = 0, 12 do
		local left, right = Layout.Get(row * 2 + 1), Layout.Get(row * 2 + 2)
		assert(left.index == row * 2 + 1 and right.index == row * 2 + 2)
		assert(left.x == -34 and right.x == 34)
		assert(left.z == 30 + row * 64 and right.z == left.z)
		assert(left.yaw == -math.pi / 2 and right.yaw == math.pi / 2)
	end
	assert(Layout.ExitZ == Layout.Get(26).z + 64)
end)

test("layout and progress reject malformed indices without changing state", function()
	local journey = Journey.new()
	local malformed = { false, true, "1", {}, 0, -1, 27, 1.5, math.huge, -math.huge, 0 / 0 }
	for _, index in ipairs(malformed) do
		assert(Layout.Get(index) == nil)
		assert(not journey:CanAttempt(index))
		assert(not journey:Collect(index))
	end
	assert(Layout.Get(nil) == nil)
	assert(not journey:CanAttempt(nil) and not journey:Collect(nil))
	assert(journey.count == 0)
end)

test("a journey admits only its next letter and already completed letters", function()
	local journey = Journey.new()
	assert(journey:GetNextLetter() == "A" and not journey:IsComplete())
	assert(journey:CanAttempt(1) and not journey:CanAttempt(2))
	assert(not journey:Collect(2) and journey.count == 0)
	assert(journey:Collect(1) and journey.count == 1)
	assert(journey:CanAttempt(1) and journey:CanAttempt(2))
	assert(not journey:CanAttempt(3) and journey:GetNextLetter() == "B")
	assert(not journey:Collect(1) and journey.count == 1)
end)

test("collecting all twenty-six stations completes exactly once", function()
	local journey = Journey.new()
	for index = 1, 26 do
		assert(journey:GetNextLetter() == string.char(64 + index))
		assert(journey:CanAttempt(index) and journey:Collect(index))
		assert(journey.count == index and not journey:Collect(index))
	end
	assert(journey:IsComplete() and journey:GetNextLetter() == nil)
	for index = 1, 26 do
		assert(journey:CanAttempt(index) and not journey:Collect(index))
	end
	assert(not journey:Collect(27) and journey.count == 26)
end)

test("journeys and returned station poses have independent state", function()
	local first, second = Journey.new(), Journey.new()
	assert(first:Collect(1))
	assert(second.count == 0 and second:GetNextLetter() == "A")
	local changed = Layout.Get(1)
	changed.x = 999
	assert(Layout.Get(1).x == -34)
end)

print(string.format("%d avenue tests passed", passed))
