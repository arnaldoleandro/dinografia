local Journey = {}
Journey.__index = Journey

-- Accepts only integer indices within the alphabet.
local function validIndex(index)
	return type(index) == "number" and index % 1 == 0 and index >= 1 and index <= 26
end

-- Creates independent, empty progress for a journey.
function Journey.new()
	return setmetatable({ count = 0 }, Journey)
end

-- Allows the next station and completed stations for replay.
function Journey:CanAttempt(index)
	return validIndex(index) and index <= self.count + 1
end

-- Collects exactly the next station without counting replays twice.
function Journey:Collect(index)
	if not validIndex(index) or index ~= self.count + 1 then
		return false
	end
	self.count += 1
	return true
end

-- Returns the next uppercase letter, or nil when the journey is complete.
function Journey:GetNextLetter()
	return if self:IsComplete() then nil else string.char(65 + self.count)
end

-- Reports whether all alphabet stations were collected.
function Journey:IsComplete()
	return self.count == 26
end

return Journey
