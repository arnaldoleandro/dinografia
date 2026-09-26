-- Ray in the panel's local space -> coordinates on its Front (-Z) face.
-- Front is viewed from -Z: screen-right is local -X, screen-down is -Y.
local Projection = {}
function Projection.Front(origin, direction, size)
	local z = -size.z/2
	if origin.z >= z or direction.z <= 0.000001 then return nil end
	local distance = (z-origin.z)/direction.z
	if distance < 0 then return nil end
	return {
		x = 0.5-(origin.x+direction.x*distance)/size.x,
		y = 0.5-(origin.y+direction.y*distance)/size.y,
	}, distance
end
function Projection.Inside(point)
	return point ~= nil and point.x >= 0 and point.x <= 1 and point.y >= 0 and point.y <= 1
end
return Projection
