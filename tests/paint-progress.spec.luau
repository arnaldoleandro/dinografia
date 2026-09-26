local Trace=require("../src/shared/Trace")
local Paint=require("../src/shared/PaintProgress")
local count=0
local function test(name,fn) fn();count+=1;print("PASS",name) end
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a).." ~= "..tostring(b)) end
local function feed(trace,t,start)
 local p=Paint.Point(t,Trace.Points);p.start=start;assert(trace:Feed(p))
end
test("paint follows sub-checkpoint movement",function()
 local trace=Trace.new();feed(trace,0,true)
 local a=Paint.Target(trace,0,Trace.Points)
 feed(trace,.002);local b=Paint.Target(trace,a,Trace.Points)
 feed(trace,.004);local c=Paint.Target(trace,b,Trace.Points)
 near(a,0);near(b,.002);near(c,.004)
end)
test("paint never retreats and survives lift",function()
 local trace=Trace.new();feed(trace,0,true);feed(trace,.05)
 local t=Paint.Target(trace,0,Trace.Points)
 feed(trace,.04);near(Paint.Target(trace,t,Trace.Points),t)
 trace:Lift();near(Paint.Target(trace,t,Trace.Points),t)
end)
test("both legs form a continuous path through vertex",function()
 local trace=Trace.new();local progress=0
 for i=0,200 do
  feed(trace,i/200,i==0)
  progress=Paint.Target(trace,progress,Trace.Points)
  if not trace.complete then near(progress,i/200) end
 end
 near(progress,1)
 local vertex=Paint.Point(.5,Trace.Points)
 near(vertex.x,.5);near(vertex.y,.82)
end)
test("invalid shortcut cannot advance paint",function()
 local trace=Trace.new();feed(trace,0,true)
 assert(not trace:Feed({x=.8,y=.16}))
 near(Paint.Target(trace,0,Trace.Points),0)
end)
test("smoothing is frame rate independent and never overshoots",function()
 local a,b=0,0
 for _=1,30 do a=Paint.Smooth(a,.8,1/30);assert(a<=.8) end
 for _=1,120 do b=Paint.Smooth(b,.8,1/120);assert(b<=.8) end
 near(a,b);near(a,.8)
 near(Paint.Smooth(0,.8,0),0)
end)
print(count.." paint tests passed")