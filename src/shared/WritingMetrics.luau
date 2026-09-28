local Metrics={};Metrics.__index=Metrics
--- Creates an anonymous attempt with an injectable monotonic clock.
function Metrics.new(letter,cells,clock)
 return setmetatable({letter=letter,cells=cells,clock=clock or os.clock,contacts=0,devices={},path=0,
  advancingPath=0,repeatedPath=0,rejectedPath=0,weightedError=0,heldSeconds=0,reversals=0,
  noAdvanceSeconds=0,longestNoAdvance=0,runNoAdvance=0,exits=0,progress=0,checkpoints={},sampleCount=0,jumps=0,last=nil,direction=nil,anchor=nil},Metrics)
end
--- Starts a physical mouse press or finger contact independently of trace restarts.
function Metrics:Contact(device)
 if self.contactStart then return end
 local now=self.clock();self.started=self.started or now;self.contactStart=now
 self.contacts+=1;self.devices[device]=true;self.last=nil;self.anchor=nil;self.direction=nil;self.lastTime=nil;self.runNoAdvance=0;self.outside=false
end
--- Ends contact without adding distance across a lift or interruption.
function Metrics:Lift()
 if self.contactStart then self.heldSeconds+=(self.finished or self.clock())-self.contactStart;self.contactStart=nil end
 self.last=nil;self.anchor=nil;self.direction=nil;self.lastTime=nil;self.runNoAdvance=0
end
--- Records one panel departure per episode without inventing a connecting path.
function Metrics:Outside()
 if not self.contactStart then return end
 if not self.outside then self.exits+=1 end
 self.outside=true;self.last=nil;self.anchor=nil;self.direction=nil;self.lastTime=nil;self.runNoAdvance=0
end
--- Measures distance to the guide without treating it as handwriting accuracy.
local function guideDistance(point,cells)
 local best=math.huge
 for _,cell in ipairs(cells) do
  local dx,dy=cell.b.x-cell.a.x,cell.b.y-cell.a.y
  local t=math.clamp(((point.x-cell.a.x)*dx+(point.y-cell.a.y)*dy)/(dx*dx+dy*dy),0,1)
  local x,y=point.x-cell.a.x-dx*t,point.y-cell.a.y-dy*t
  best=math.min(best,math.sqrt(x*x+y*y))
 end
 return best
end
--- Records sampled movement, meaningful direction reversals and time at coverage milestones.
function Metrics:Sample(point,accepted,progress)
 if not self.contactStart or self.finished then return end
 local now=self.clock();local previous=self.last;self.outside=false;self.sampleCount+=1
 if previous then
  local dx,dy=point.x-previous.x,point.y-previous.y;local length=math.sqrt(dx*dx+dy*dy)
  if length>.22 then self.jumps+=1;self.anchor=nil;self.direction=nil;self.runNoAdvance=0 end
  if length>0 and length<=.22 then
   local dt=math.min(.25,math.max(0,now-(self.lastTime or now)))
   if progress<=self.progress then
    self.noAdvanceSeconds+=dt;self.runNoAdvance+=dt
    self.longestNoAdvance=math.max(self.longestNoAdvance,self.runNoAdvance)
   else self.runNoAdvance=0 end
   self.path+=length;self.weightedError+=guideDistance(point,self.cells)*length
   if progress>self.progress then self.advancingPath+=length
   elseif accepted then self.repeatedPath+=length else self.rejectedPath+=length end
  end
 end
 local anchor=self.anchor or point
 local dx,dy=point.x-anchor.x,point.y-anchor.y;local length=math.sqrt(dx*dx+dy*dy)
 if length>=.015 then
  local direction={x=dx/length,y=dy/length}
  if self.direction and direction.x*self.direction.x+direction.y*self.direction.y<-.5 then self.reversals+=1 end
  self.direction=direction;self.anchor=point
 elseif not self.anchor then self.anchor=point end
 self.last={x=point.x,y=point.y};self.lastTime=now;self.progress=progress
 for _,threshold in ipairs({.25,.5,.75,.9,1}) do
  local key=tostring(math.floor(threshold*100))
  if progress>=threshold and not self.checkpoints[key] then self.checkpoints[key]=now-self.started end
 end
 if progress>=1 then self.finished=now end
end
--- Returns a bounded scalar summary without coordinates or player identifiers.
function Metrics:Summary(outcome)
 local now=self.finished or self.clock()
 local duration=if self.started then now-self.started else 0
 local held=self.heldSeconds+(if self.contactStart then now-self.contactStart else 0)
 local devices={};for device in pairs(self.devices) do table.insert(devices,device) end;table.sort(devices)
 return {letter=self.letter,outcome=outcome,seconds=duration,contactSeconds=math.min(held,duration),
  samples=self.sampleCount,largePointerJumps=self.jumps,contacts=self.contacts,input=table.concat(devices,'+'),coverage=self.progress,
  pathPanelWidths=self.path,advancingPath=self.advancingPath,repeatedPath=self.repeatedPath,
  rejectedPath=self.rejectedPath,meanGuideDistance=if self.path>0 then self.weightedError/self.path else 0,
  movingWithoutAdvanceSeconds=self.noAdvanceSeconds,longestMovingWithoutAdvanceSeconds=self.longestNoAdvance,directionReversals=self.reversals,panelExits=self.exits,checkpoints=self.checkpoints}
end
return Metrics
