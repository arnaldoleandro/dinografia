-- Opaque strokes and circular joins form one continuous silhouette per layer.
local shared = game:GetService("ReplicatedStorage").Dinografia
local Trace, Paint = require(shared.Trace), require(shared.PaintProgress)
local Display = {}
local SIZE = 1024
local function create(className, props, parent)
	local item = Instance.new(className)
	for key, value in pairs(props) do item[key] = value end
	item.Parent = parent
	return item
end
local function round(item)
	create("UICorner", {CornerRadius=UDim.new(0.5,0)}, item)
end
local function stroke(parent,width,color,z,offset)
	local props={AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=color,BorderSizePixel=0,ZIndex=z,Visible=false}
	local body=create("Frame",props,parent)
	local first,last=create("Frame",props,parent),create("Frame",props,parent)
	first.Size,last.Size=UDim2.fromOffset(width,width),UDim2.fromOffset(width,width)
	round(first);round(last)
	return function(a,b,visible)
		body.Visible,first.Visible,last.Visible=visible,visible,visible
		if not visible then return end
		local start=Vector2.new(a.x*SIZE,a.y*SIZE+offset)
		local finish=Vector2.new(b.x*SIZE,b.y*SIZE+offset)
		local delta=finish-start
		body.Position=UDim2.fromOffset((start.X+finish.X)/2,(start.Y+finish.Y)/2)
		body.Size=UDim2.fromOffset(math.max(0.01,delta.Magnitude),width)
		body.Rotation=math.deg(math.atan2(delta.Y,delta.X))
		first.Position=UDim2.fromOffset(start.X,start.Y)
		last.Position=UDim2.fromOffset(finish.X,finish.Y)
	end
end
function Display.new(panel,playerGui)
	local surface=create("SurfaceGui",{Name="DoorLetter",Adornee=panel,Face=Enum.NormalId.Front,
		SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,CanvasSize=Vector2.new(SIZE,SIZE),
		AlwaysOnTop=false,LightInfluence=0.15,MaxDistance=180,Active=false,ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
	-- Complete each solid layer before the next: no individual outlines at the V joint.
	for z,layer in ipairs({{178,Color3.fromRGB(126,155,151),5},
		{160,Color3.fromRGB(10,23,26),-2},{132,Color3.fromRGB(22,48,50),2}}) do
		for leg=1,2 do
			stroke(surface,layer[1],layer[2],z,layer[3])(Trace.Points[leg],Trace.Points[leg+1],true)
		end
	end
	local paint={stroke(surface,120,Color3.fromRGB(79,212,154),4,1),
		stroke(surface,120,Color3.fromRGB(79,212,154),4,1)}
	local dot=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(47,47),
		BackgroundColor3=Color3.fromRGB(255,204,87),BorderSizePixel=0,ZIndex=5},surface)
	round(dot)
	create("UIStroke",{Color=Color3.fromRGB(255,238,191),Thickness=5,Transparency=0.25},dot)
	local currentTrace,target,shown,finished=nil,0,0,false
	local self={Gui=surface}
	local function draw()
		paint[1](Trace.Points[1],Paint.Point(math.min(shown,0.5),Trace.Points),shown>0)
		paint[2](Trace.Points[2],Paint.Point(math.max(shown,0.5),Trace.Points),shown>0.5)
		local p=Paint.Point(shown,Trace.Points)
		dot.Position=UDim2.fromScale(p.x,p.y)
		dot.Visible=not finished and not (currentTrace and currentTrace.complete)
	end
	function self:Update(trace,done)
		if currentTrace~=trace then currentTrace,target,shown=trace,0,0 end
		finished=done
		target=if done then 1 else Paint.Target(trace,target,Trace.Points)
		draw()
	end
	function self:Step(dt)
		if shown==target then return end
		shown=Paint.Smooth(shown,target,dt)
		draw()
	end
	self:Update(Trace.new(),false)
	return self
end
return Display