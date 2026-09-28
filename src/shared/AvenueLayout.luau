local Layout = { Count = 26, ExitZ = 30 + 13 * 64 }

-- Returns a station pose, or nil for an invalid station index.
function Layout.Get(index)
	if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > Layout.Count then
		return nil
	end
	local left = index % 2 == 1
	return {
		index = index,
		x = if left then -34 else 34,
		z = 30 + math.floor((index - 1) / 2) * 64,
		yaw = if left then -math.pi / 2 else math.pi / 2,
	}
end

return Layout
