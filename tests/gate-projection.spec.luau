local Projection=require("../src/shared/GateProjection")
local Trace=require("../src/shared/Trace")
local size={x=10,y=10,z=.18}
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a).." ~= "..tostring(b)) end
local count=0
local function test(name,fn) fn();count+=1;print("PASS",name) end
test("front center",function()
	local p=Projection.Front({x=0,y=0,z=-20},{x=0,y=0,z=1},size)
	near(p.x,.5);near(p.y,.5)
end)
test("front left top is positive local X and Y",function()
	local p=Projection.Front({x=3,y=3.4,z=-20},{x=0,y=0,z=1},size)
	near(p.x,.2);near(p.y,.16)
end)
test("perspective ray reaches same letter point",function()
	local p=Projection.Front({x=6,y=7,z=-20},{x=-3,y=-3.6,z=19.91},size)
	near(p.x,.2);near(p.y,.16)
end)
test("back and parallel rays rejected",function()
	assert(not Projection.Front({x=0,y=0,z=20},{x=0,y=0,z=-1},size))
	assert(not Projection.Front({x=0,y=0,z=-20},{x=1,y=0,z=0},size))
	assert(not Projection.Front({x=0,y=0,z=-20},{x=0,y=0,z=-1},size))
end)
test("out of panel does not clamp into valid strokes",function()
	local p=Projection.Front({x=8,y=0,z=-20},{x=0,y=0,z=1},size)
	assert(not Projection.Inside(p));assert(not Projection.Inside(nil))
end)
test("V projected from oblique view passes shared server validator",function()
	local samples={}
	local origin={x=7,y=4,z=-25}
	for segment=1,2 do
		local a,b=Trace.Points[segment],Trace.Points[segment+1]
		for i=if segment==1 then 0 else 1,45 do
			local u,v=a.x+(b.x-a.x)*i/45,a.y+(b.y-a.y)*i/45
			local hit={x=(.5-u)*10,y=(.5-v)*10,z=-.09}
			local p=Projection.Front(origin,{x=hit.x-origin.x,y=hit.y-origin.y,z=hit.z-origin.z},size)
			p.start=#samples==0;table.insert(samples,p)
		end
	end
	assert(Trace.Validate(samples))
end)
print(count.." projection tests passed")
