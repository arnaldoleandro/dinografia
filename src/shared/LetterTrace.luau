-- Approximate coverage tracing shared by the client and authoritative server replay.
local Alphabet=require(if script then script.Parent.Alphabet else './Alphabet')
local Trace={};Trace.__index=Trace
--- Measures normalized distance between two points.
local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
--- Rejects nonfinite coordinates before geometry calculations.
local function finite(value) return type(value)=='number' and value==value and math.abs(value)<math.huge end
--- Measures distance from a point to a bounded pointer movement.
local function segmentDistance(p,a,b)
 local dx,dy=b.x-a.x,b.y-a.y
 local t=math.clamp(((p.x-a.x)*dx+(p.y-a.y)*dy)/(dx*dx+dy*dy),0,1)
 return distance(p,{x=a.x+dx*t,y=a.y+dy*t})
end
--- Creates small coverage intervals without imposing stroke order or direction.
function Trace.new(letter,tolerance)
 local definition=assert(Alphabet.Get(letter),'Unsupported letter')
 local self=setmetatable({cells={},covered={},strokeLengths={},strokeEarned={},total=0,earned=0,
  last=nil,complete=false,tolerance=tolerance or .065},Trace)
 for strokeIndex,stroke in ipairs(definition.strokes) do
  self.strokeLengths[strokeIndex]=0;self.strokeEarned[strokeIndex]=0
  for index=1,#stroke-1 do
   local a,b=stroke[index],stroke[index+1];local length=distance(a,b)
   local divisions=math.ceil(length/.02)
   for step=1,divisions do
    local start=(step-1)/divisions;local finish=step/divisions
    table.insert(self.cells,{a={x=a.x+(b.x-a.x)*start,y=a.y+(b.y-a.y)*start},
     b={x=a.x+(b.x-a.x)*finish,y=a.y+(b.y-a.y)*finish},
     midpoint={x=a.x+(b.x-a.x)*(start+finish)/2,y=a.y+(b.y-a.y)*(start+finish)/2},
     dx=(b.x-a.x)/length,dy=(b.y-a.y)/length,length=length/divisions,stroke=strokeIndex})
   end
   self.total+=length;self.strokeLengths[strokeIndex]+=length
  end
 end
 return self
end
--- Returns length-weighted coverage while allowing small unpainted gaps at completion.
function Trace:GetProgress() return if self.complete then 1 else self.earned/self.total end
--- Suggests an unpainted area without requiring the player to start there.
function Trace:GetResumePoint()
 for index,cell in ipairs(self.cells) do if not self.covered[index] then return cell.midpoint end end
 return self.cells[#self.cells].b
end
--- Breaks the pointer path without removing any earned coverage.
function Trace:Lift() self.last=nil end
--- Checks total coverage and each stroke so short crossbars cannot be omitted.
function Trace:CheckComplete()
 if self.earned/self.total<.92 then return false end
 for stroke,length in ipairs(self.strokeLengths) do
  if self.strokeEarned[stroke]/length<.85 then return false end
 end
 self.complete=true;return true
end
--- Paints near an actual movement and never bridges lifts or large pointer jumps.
function Trace:Feed(sample)
 if type(sample)~='table' or not finite(sample.x) or not finite(sample.y) or math.abs(sample.x)>2 or math.abs(sample.y)>2
  or (sample.start~=nil and type(sample.start)~='boolean') then return false,'invalid' end
 if self.complete then return true,'complete' end
 if sample.start then self:Lift() end
 local point={x=sample.x,y=sample.y};local previous=self.last;self.last=point
 if not previous then return true,'drawing' end
 local travel=distance(previous,point)
 if travel>.22 then return false,'resume' end
 if travel<.001 then return true,'drawing' end
 local touching=false
 for index,cell in ipairs(self.cells) do
  local alignment=math.abs(((point.x-previous.x)*cell.dx+(point.y-previous.y)*cell.dy)/travel)
  if alignment>=.35 and segmentDistance(cell.midpoint,previous,point)<=self.tolerance then
   touching=true
   if not self.covered[index] then
    self.covered[index]=true;self.earned+=cell.length;self.strokeEarned[cell.stroke]+=cell.length
   end
  end
 end
 if self:CheckComplete() then return true,'complete' end
 return touching,if touching then 'drawing' else 'resume'
end
--- Replays a bounded dense payload with the same coverage rules used by the client.
function Trace.Validate(samples,letter,tolerance,limit)
 if not Alphabet.Get(letter) or type(samples)~='table' or #samples<3 or #samples>(limit or 4096) then return false,'invalid' end
 local count=0
 for key in pairs(samples) do
  if type(key)~='number' or key%1~=0 or key<1 or key>#samples then return false,'invalid' end
  count+=1
 end
 if count~=#samples then return false,'invalid' end
 local trace=Trace.new(letter,tolerance)
 for _,sample in ipairs(samples) do local _,status=trace:Feed(sample);if status=='invalid' then return false,status end end
 return trace.complete,if trace.complete then 'complete' else 'incomplete'
end
return Trace
