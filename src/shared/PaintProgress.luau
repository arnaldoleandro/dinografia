-- Visual progress follows the pointer continuously, within the validated path.

local Paint = {}
function Paint.Point(progress, points)
	local scaled = math.clamp(progress, 0, 1)*2
	local leg = if scaled <= 1 then 1 else 2
	local a,b = points[leg],points[leg+1]
	local t = scaled-(leg-1)
	return {x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t}
end
function Paint.Target(trace, previous, points)
	if trace.complete then return 1 end
	if not trace.last then return previous end
	local earned = math.clamp((trace.nextIndex-2)/(#trace.checkpoints-1),0,1)
	local best, nearest = previous, math.huge
	for leg=1,2 do
		local low,high = math.max(previous,(leg-1)/2), math.min(earned,leg/2)
		if low<=high then
			local a,b=points[leg],points[leg+1]
			local dx,dy=b.x-a.x,b.y-a.y
			local t=((trace.last.x-a.x)*dx+(trace.last.y-a.y)*dy)/(dx*dx+dy*dy)
			t=math.clamp(t,low*2-(leg-1),high*2-(leg-1))
			local distance=(trace.last.x-a.x-dx*t)^2+(trace.last.y-a.y-dy*t)^2
			if distance<nearest then nearest=distance;best=((leg-1)+t)/2 end
		end
	end
	return math.max(previous,best)
end
function Paint.Smooth(current,target,dt)
	local result=current+(target-current)*(1-math.exp(-math.max(dt,0)/0.035))
	return if math.abs(result-target)<0.0001 then target else result
end
return Paint
