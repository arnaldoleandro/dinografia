-- Continuous layered strokes render uppercase grooves and validated paint on the door.
local shared=game:GetService('ReplicatedStorage').Dinografia
local Alphabet=require(shared.Alphabet)
local Trace=require(shared.LetterTrace)
local Display={}
local SIZE=1024
-- Create and parent one configured interface object.
local function create(className,properties,parent)
 local instance=Instance.new(className)
 for key,value in pairs(properties) do instance[key]=value end
 instance.Parent=parent; return instance
end
-- Apply circular corners to a square endpoint.
local function round(item) create('UICorner',{CornerRadius=UDim.new(.5,0)},item) end
-- Build one solid capsule with opaque round joins.
local function capsule(parent,width,color,z,offset)
 local properties={AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=color,BorderSizePixel=0,ZIndex=z,Visible=false}
 local body=create('Frame',properties,parent)
 local first,last=create('Frame',properties,parent),create('Frame',properties,parent)
 first.Size,last.Size=UDim2.fromOffset(width,width),UDim2.fromOffset(width,width)
 round(first); round(last)
 -- Update the length and position of a continuous paint segment.
 return function(a,b,visible)
  body.Visible,first.Visible,last.Visible=visible,visible,visible
  if not visible then return end
  local start=Vector2.new(a.x*SIZE,a.y*SIZE+offset)
  local finish=Vector2.new(b.x*SIZE,b.y*SIZE+offset)
  local delta=finish-start
  body.Position=UDim2.fromOffset((start.X+finish.X)/2,(start.Y+finish.Y)/2)
  body.Size=UDim2.fromOffset(math.max(.01,delta.Magnitude),width)
  body.Rotation=math.deg(math.atan2(delta.Y,delta.X))
  first.Position=UDim2.fromOffset(start.X,start.Y); last.Position=UDim2.fromOffset(finish.X,finish.Y)
 end
end
-- Create a display for one immutable uppercase guide.
function Display.new(panel,playerGui,letter)
 local definition=assert(Alphabet.Get(letter),'Unsupported display letter')
 local surface=create('SurfaceGui',{Name='DoorLetter',Adornee=panel,Face=Enum.NormalId.Front,
  SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,CanvasSize=Vector2.new(SIZE,SIZE),
  AlwaysOnTop=false,LightInfluence=.15,MaxDistance=125,Active=false,ResetOnSpawn=false,
  ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
 local segments={}; local total=0
 for strokeIndex,stroke in ipairs(definition.strokes) do
  for i=1,#stroke-1 do
   local a,b=stroke[i],stroke[i+1]; local length=math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
   table.insert(segments,{a=a,b=b,start=total,length=length,strokeIndex=strokeIndex}); total+=length
  end
 end
 for z,layer in ipairs({{144,Color3.fromRGB(126,155,151),3},{132,Color3.fromRGB(10,23,26),-1},{120,Color3.fromRGB(22,48,50),1}}) do
  for _,segment in ipairs(segments) do capsule(surface,layer[1],layer[2],z,layer[3])(segment.a,segment.b,true) end
 end
 local geometry=Trace.new(letter)
 local cells=geometry.cells
 for _,cell in ipairs(cells) do
  cell.paint=capsule(surface,110,Color3.fromRGB(79,212,154),4,0)
  cell.shown=0;cell.target=0
 end
 local dot=create('Frame',{Name='WritingPoint',AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(28,28),
  BackgroundColor3=Color3.fromRGB(255,204,87),BorderSizePixel=0,ZIndex=5},surface)
 round(dot);create('UIStroke',{Color=Color3.fromRGB(255,238,191),Thickness=3,Transparency=.25},dot)
 local currentTrace,finished=nil,false
 local self={Gui=surface}
 --- Keeps the contact marker on the pointer and suggests a remaining area when lifted.
 local function marker()
  local point=if currentTrace then currentTrace.last or currentTrace:GetResumePoint() else cells[1].a
  dot.Position=UDim2.fromScale(point.x,point.y)
  dot.Visible=not finished and not (currentTrace and currentTrace.complete)
 end
 --- Updates independent paint targets so coverage never fills untouched earlier strokes.
 function self:Update(trace,done)
  local reset=trace~=currentTrace
  currentTrace=trace;finished=done==true or trace.complete
  for index,cell in ipairs(cells) do
   if reset then cell.shown=0;cell.paint(cell.a,cell.b,false) end
   cell.target=if finished or trace.covered[index] then 1 else 0
  end
  marker()
 end
 --- Eases local paint patches while moving the contact marker without a tracking delay.
 function self:Step(dt)
  for _,cell in ipairs(cells) do
   if cell.shown~=cell.target then
    cell.shown+=(cell.target-cell.shown)*(1-math.exp(-math.max(0,dt)/.035))
    if math.abs(cell.shown-cell.target)<.001 then cell.shown=cell.target end
    local half=cell.shown*.5
    local a={x=cell.midpoint.x+(cell.a.x-cell.b.x)*half,y=cell.midpoint.y+(cell.a.y-cell.b.y)*half}
    local b={x=cell.midpoint.x+(cell.b.x-cell.a.x)*half,y=cell.midpoint.y+(cell.b.y-cell.a.y)*half}
    cell.paint(a,b,cell.shown>0)
   end
  end
  marker()
 end
 --- Releases all display objects when another station is selected.
 function self:Destroy() surface:Destroy() end
 self:Update(geometry,false)
 return self
end
return Display