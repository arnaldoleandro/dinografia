local Alphabet=require('../src/shared/Alphabet')
local Trace=require('../src/shared/LetterTrace')
local passed=0
-- Report one independent behavior check.
local function test(name,fn)
 local ok,message=pcall(fn); assert(ok,name..': '..tostring(message)); passed+=1; print('PASS',name)
end
-- Generate real continuous strokes with explicit pen lifts.
local function samples(letter)
 local result={}
 for _,stroke in ipairs(Alphabet.Get(letter).strokes) do
  table.insert(result,{x=stroke[1].x,y=stroke[1].y,start=true})
  for i=1,#stroke-1 do
   local a,b=stroke[i],stroke[i+1]
   local count=math.ceil(math.sqrt((b.x-a.x)^2+(b.y-a.y)^2)/.006)
   for step=1,count do table.insert(result,{x=a.x+(b.x-a.x)*step/count,y=a.y+(b.y-a.y)*step/count}) end
  end
 end
 return result
end
for _,entry in ipairs(Alphabet.Letters) do
 test('complete uppercase '..entry.letter,function() assert(Trace.Validate(samples(entry.letter),entry.letter)) end)
end
test('alphabet has 26 unique bounded recognizable guides',function()
 assert(#Alphabet.Letters==26)
 for i,entry in ipairs(Alphabet.Letters) do
  assert(entry.letter==string.char(64+i))
  for _,stroke in ipairs(entry.strokes) do
   assert(#stroke>=2)
   for _,p in ipairs(stroke) do assert(p.x>.05 and p.x<.95 and p.y>.05 and p.y<.95) end
  end
 end
end)
test('dots alone never paint any letter',function()
 for _,entry in ipairs(Alphabet.Letters) do
  local data=samples(entry.letter)
  for _,p in ipairs(data) do p.start=true end
  assert(not Trace.Validate(data,entry.letter))
 end
end)
test('reversed strokes remain valid handwriting',function()
 for _,entry in ipairs(Alphabet.Letters) do
  local original=samples(entry.letter); local reversed={}
  for i=#original,1,-1 do table.insert(reversed,{x=original[i].x,y=original[i].y,start=i==#original}) end
  assert(Trace.Validate(reversed,entry.letter),entry.letter)
 end
end)
test('skip an A leg or a crossbar fails',function()
 local path=samples('A'); local firstOnly={}
 for i,p in ipairs(path) do if i>1 and p.start then break end; table.insert(firstOnly,p) end
 assert(not Trace.Validate(firstOnly,'A'))
 local shortcut={{x=.2,y=.82,start=true},{x=.5,y=.18},{x=.8,y=.82},{x=.34,y=.53,start=true},{x=.66,y=.53}}
 assert(not Trace.Validate(shortcut,'A'))
end)
test('lift resumes earned position without painting a gap',function()
 local trace=Trace.new('V'); local path=samples('V')
 for i=1,30 do trace:Feed(path[i]) end
 local earned=trace:GetProgress(); local point=trace:GetResumePoint(); trace:Lift()
 assert(trace:Feed({x=.8,y=.18,start=true})); assert(trace:GetProgress()==earned)
 assert(trace:Feed({x=point.x,y=point.y,start=true})); assert(trace:GetProgress()==earned)
 for i=31,#path do trace:Feed(path[i]) end
 assert(trace.complete)
end)
test('X intersection cannot skip either ordered stroke',function()
 local data={{x=.23,y=.18,start=true}}
 for i=1,50 do table.insert(data,{x=.23+.27*i/50,y=.18+.32*i/50}) end
 for i=1,50 do table.insert(data,{x=.5-.27*i/50,y=.5+.32*i/50}) end
 assert(not Trace.Validate(data,'X'))
end)
test('paint is continuous and monotonic',function()
 local trace=Trace.new('I'); local previous=0
 for _,sample in ipairs(samples('I')) do
  trace:Feed(sample); local progress=trace:GetProgress()
  assert(progress>=previous and progress-previous<.15); previous=progress
 end
 assert(previous==1)
end)
test('malformed and sparse payloads are rejected',function()
 assert(not Trace.Validate({{x=0/0,y=.2},{x=.5,y=.5},{x=.5,y=.8}},'V'))
 assert(not Trace.Validate({[1]={x=.2,y=.18},[3]={x=.8,y=.18}},'V'))
 assert(not Trace.Validate(samples('V'),'unsupported'))
 assert(not Trace.Validate(samples('V'),'V',nil,4))
end)
test('small touch imprecision still completes every glyph',function()
 for _,entry in ipairs(Alphabet.Letters) do
  local data=samples(entry.letter)
  for _,p in ipairs(data) do p.x+=.035; p.y+=.025 end
  assert(Trace.Validate(data,entry.letter),entry.letter)
 end
end)
test('stroke order is free and lifting never paints a connecting gap',function()
 for _,entry in ipairs(Alphabet.Letters) do
  local data=samples(entry.letter);local strokes={};local stroke
  for _,point in ipairs(data) do
   if point.start then stroke={};table.insert(strokes,1,stroke) end
   table.insert(stroke,point)
  end
  local reordered={}
  for _,points in ipairs(strokes) do for _,point in ipairs(points) do table.insert(reordered,point) end end
  assert(Trace.Validate(reordered,entry.letter),entry.letter)
 end
 local trace=Trace.new('X')
 trace:Feed({x=.23,y=.18,start=true});trace:Feed({x=.77,y=.82,start=true})
 assert(trace:GetProgress()==0)
end)
test('B rounded corners and sparse pointer events do not stall',function()
 local data=samples('B');local sparse={}
 for index,point in ipairs(data) do if point.start or index%6==0 then table.insert(sparse,point) end end
 for _,point in ipairs(sparse) do point.x+=.025;point.y+=.02 end
 assert(Trace.Validate(sparse,'B'))
end)
test('returning from outside the guide preserves and resumes coverage anywhere',function()
 local data=samples('B');local trace=Trace.new('B')
 for index=1,40 do trace:Feed(data[index]) end
 local before=trace:GetProgress()
 trace:Feed({x=.95,y=.95});trace:Lift()
 assert(trace:GetProgress()>=before)
 for index=41,#data do
  local point=data[index];if index==41 then point.start=true end;trace:Feed(point)
 end
 assert(trace.complete)
end)
test('one scribble and repeated stationary movements do not complete a letter',function()
 local trace=Trace.new('B');trace:Feed({x=.25,y=.5,start=true})
 for index=1,500 do trace:Feed({x=.25,y=.5+(index%2)*.005}) end
 assert(not trace.complete and trace:GetProgress()<.3)
 local line={}
 for index=0,100 do table.insert(line,{x=.1+index*.008,y=.5,start=index==0}) end
 assert(not Trace.Validate(line,'B'))
end)
test('all strokes require coverage even when the missing stroke is short',function()
 for _,letter in ipairs({'A','F','H','Q','R','T','X'}) do
  local data=samples(letter);local starts={}
  for index,point in ipairs(data) do if point.start then table.insert(starts,index) end end
  local partial={}
  for index=1,starts[#starts]-1 do table.insert(partial,data[index]) end
  assert(not Trace.Validate(partial,letter),letter)
 end
end)
test('late malformed samples cannot hide behind completed coverage',function()
 local data=samples('B');table.insert(data,{x=0/0,y=.2})
 assert(not Trace.Validate(data,'B'))
end)
print(passed..' alphabet tests passed')
