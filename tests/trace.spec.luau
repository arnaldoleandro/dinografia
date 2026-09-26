local Trace = require("../src/shared/Trace")
local passed = 0
local function test(name, fn)
	local ok, result = pcall(fn)
	assert(ok, name .. ": " .. tostring(result))
	passed += 1
	print("PASS", name)
end
local function path()
	local samples = {}
	for segment = 1, 2 do
		local a, b = Trace.Points[segment], Trace.Points[segment+1]
		for step = if segment == 1 then 0 else 1, 45 do
			table.insert(samples, { x = a.x+(b.x-a.x)*step/45, y = a.y+(b.y-a.y)*step/45, start = #samples == 0 })
		end
	end
	return samples
end
test("complete guided V", function() assert(Trace.Validate(path())) end)
test("two endpoint taps do not complete", function()
	assert(not Trace.Validate({{x=.2,y=.16,start=true},{x=.8,y=.16,start=true},{x=.8,y=.16}}))
end)
test("three isolated vertex taps do not complete", function()
	assert(not Trace.Validate({{x=.2,y=.16,start=true},{x=.5,y=.82,start=true},{x=.8,y=.16,start=true}}))
end)
test("straight shortcut across top fails", function()
	local samples = {}
	for i=0,60 do table.insert(samples,{x=.2+i*.01,y=.16,start=i==0}) end
	assert(not Trace.Validate(samples))
end)
test("reverse direction fails", function()
	local forward, backward = path(), {}
	for i=#forward,1,-1 do table.insert(backward,{x=forward[i].x,y=forward[i].y,start=i==#forward}) end
	assert(not Trace.Validate(backward))
end)
test("lift and resume preserve progress", function()
	local samples = path()
	samples[24].start = true
	assert(Trace.Validate(samples))
end)
test("off-guide excursion followed by resume", function()
	local samples = path()
	table.insert(samples,25,{x=1.1,y=0})
	samples[26].start = true
	assert(Trace.Validate(samples))
end)
test("off-guide excursion cannot skip second leg", function()
	local samples=path()
	for i=#samples,47,-1 do table.remove(samples,i) end
	table.insert(samples,{x=1,y=.2})
	table.insert(samples,{x=.8,y=.16,start=true})
	assert(not Trace.Validate(samples))
end)
test("tolerant small deviations", function()
	local samples=path()
	for _,sample in ipairs(samples) do sample.x += .02 end
	assert(Trace.Validate(samples))
end)
test("malformed and nonfinite payloads fail", function()
	assert(not Trace.Validate("bad"))
	for _,value in ipairs({math.huge, -math.huge, 0/0}) do
		local samples=path(); samples[4].x=value
		assert(not Trace.Validate(samples))
	end
	local samples=path(); samples[4].start="bad"
	assert(not Trace.Validate(samples))
end)
test("payload limit and foreign keys", function()
	assert(not Trace.Validate(path(),.075,10))
	local samples=path(); samples.other=true
	assert(not Trace.Validate(samples))
end)
test("isolated taps with large gaps do not complete", function()
	-- Close sequential taps are a supported accessibility choice: lifting is
	-- allowed, but the full ordered route must still be covered.
	local samples={{x=.2,y=.16,start=true},{x=.21,y=.17,start=true},{x=.8,y=.16,start=true}}
	assert(not Trace.Validate(samples))
end)
print(string.format("%d trace tests passed", passed))
