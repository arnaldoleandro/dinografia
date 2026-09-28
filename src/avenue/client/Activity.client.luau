-- The avenue reuses one focused writing display and one audio controller across all cages.
local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local UserInputService=game:GetService('UserInputService')
local ContextActionService=game:GetService('ContextActionService')
local TweenService=game:GetService('TweenService')
local RunService=game:GetService('RunService')
local GuiService=game:GetService('GuiService')
local player=Players.LocalPlayer
local shared=ReplicatedStorage:WaitForChild('Dinografia')
local Trace,Config=require(shared.LetterTrace),require(shared.Config)
local Projection,DoorCycle=require(shared.GateProjection),require(shared.DoorCycle)
local Catalog=require(shared.DinosaurCatalog)
local WritingMetrics=require(shared.WritingMetrics)
local HttpService=game:GetService('HttpService')
local metrics,attemptNumber=nil,0
local aggregates={}
local logMetrics=RunService:IsStudio()
--- Prints one anonymous attempt and completed-attempt averages in the local Studio Output.
local function finishMetrics(outcome)
 if not metrics then return end
 local result=metrics:Summary(outcome)
 result.attempt=attemptNumber;result.rule='coverage-v1';result.tolerance=Config.AlphabetTraceTolerance
 local camera=workspace.CurrentCamera
 if camera then result.viewport=tostring(camera.ViewportSize) end
 for key,value in pairs(result) do if type(value)=='number' then result[key]=math.floor(value*1000+.5)/1000 end end
 print('[Dinografia escrita] '..HttpService:JSONEncode(result))
 if outcome=='completed' then
  local key=result.letter..':'..result.input
  local stats=aggregates[key] or {count=0,seconds=0,contacts=0,reversals=0}
  aggregates[key]=stats;stats.count+=1;stats.seconds+=result.seconds;stats.contacts+=result.contacts;stats.reversals+=result.directionReversals
  print('[Dinografia escrita media] '..HttpService:JSONEncode({letter=result.letter,input=result.input,
   completedAttempts=stats.count,meanSeconds=stats.seconds/stats.count,
   meanContacts=stats.contacts/stats.count,meanReversals=stats.reversals/stats.count,rule=result.rule}))
 end
 metrics=nil
end
local Display=require(script.Parent.LetterDisplay)
local Audio=require(ReplicatedStorage:WaitForChild('DinografiaAudio').Controller)
local remote=shared:WaitForChild('Activity',30)
if not remote then warn('[Dinografia] Atividade indisponível; confira o Output do servidor.'); return end
local stations=workspace:WaitForChild('AlphabetStations')
local playerGui=player:WaitForChild('PlayerGui')
local cage=stations:WaitForChild('Cage_A')
local panel,beam=cage:WaitForChild('WritingPanel'),cage:WaitForChild('FrontBeam')
local letter=cage:GetAttribute('Letter') or 'A'
local display=Display.new(panel,playerGui,letter)
local audio=Audio.new(cage)
local trace=Trace.new(letter,Config.AlphabetTraceTolerance)
local samples={}
local connections,cageConnections={},{}
local focused,pending,finishing,completed,cameraReady=false,false,false,false,false
local activeToken,activeTouch,lastSent=nil,nil,nil
local mouseDown,strokeStart=false,true
local requestGeneration,paintAudioProgress=0,0
local savedCamera,savedCameraType,savedFov,savedFovMode,savedCFrame=nil,nil,nil,nil,nil
local cameraTween,controls=nil,nil
local controlsDisabled,destroyed=false,false
local lastViewport=Vector2.zero
local scanElapsed=0
local actionName='DinografiaAvenueWritingControls'
-- Register an event whose lifetime is owned by the activity interface.
local function connect(signal,callback)
 local connection=signal:Connect(callback); table.insert(connections,connection); return connection
end
-- Create a configured interface object.
local function create(className,properties,parent)
 local item=Instance.new(className)
 for key,value in pairs(properties) do item[key]=value end
 item.Parent=parent; return item
end
local gui=create('ScreenGui',{Name='DinografiaAvenueActivity',ResetOnSpawn=false,IgnoreGuiInset=true,
 ScreenInsets=Enum.ScreenInsets.None,DisplayOrder=20},playerGui)
local status=create('TextLabel',{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-22),
 Size=UDim2.new(.88,0,0,64),BackgroundColor3=Color3.fromRGB(20,43,46),BackgroundTransparency=.15,
 TextColor3=Color3.fromRGB(247,244,229),TextSize=18,Font=Enum.Font.GothamMedium,
 TextWrapped=true,Text='Siga até a jaula A para começar.',BorderSizePixel=0},gui)
create('UISizeConstraint',{MaxSize=Vector2.new(700,64)},status)
create('UICorner',{CornerRadius=UDim.new(0,18)},status)
local heading=create('TextLabel',{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,58),
 Size=UDim2.new(.62,0,0,36),BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,234,185),
 Font=Enum.Font.GothamBold,Text='',TextScaled=true,Visible=false},gui)
create('UITextSizeConstraint',{MaxTextSize=26,MinTextSize=13},heading)
local collection=create('TextLabel',{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,14),
 Size=UDim2.new(.58,0,0,34),BackgroundColor3=Color3.fromRGB(20,43,46),BackgroundTransparency=.2,
 TextColor3=Color3.fromRGB(247,244,229),Font=Enum.Font.GothamMedium,Text='0 / 26',TextScaled=true,BorderSizePixel=0},gui)
create('UICorner',{CornerRadius=UDim.new(0,12)},collection)
create('UITextSizeConstraint',{MaxTextSize=18,MinTextSize=11},collection)
-- Create a large accessible writing control.
local function button(text,x,anchor)
 local item=create('TextButton',{AnchorPoint=Vector2.new(anchor,0),Position=UDim2.new(x,if anchor==1 then -16 else 16,0,58),
  Size=UDim2.fromOffset(48,48),Text=text,TextSize=30,Font=Enum.Font.GothamBold,
  BackgroundColor3=Color3.fromRGB(31,78,69),TextColor3=Color3.fromRGB(255,234,185),
  BorderSizePixel=0,Visible=false,Modal=true},gui)
 create('UICorner',{CornerRadius=UDim.new(0,14)},item); return item
end
local closeButton,repeatButton=button('×',1,1),button('↻',0,0)
local soundButton=create('TextButton',{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-16,0,116),
 Size=UDim2.fromOffset(146,40),Text='Som: baixo',TextSize=16,Font=Enum.Font.GothamMedium,
 BackgroundColor3=Color3.fromRGB(31,78,69),TextColor3=Color3.fromRGB(255,234,185),BorderSizePixel=0},gui)
create('UICorner',{CornerRadius=UDim.new(0,12)},soundButton)
connect(soundButton.Activated,function() soundButton.Text=audio:CycleVolume() end)
local playerModule=player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule',10)
if playerModule then
 local ok,result=pcall(function() return require(playerModule):GetControls() end)
 if ok then controls=result end
end
-- Check whether the selected station has been reached in the player's alphabet journey.
local function available()
 return (cage:GetAttribute('StationIndex') or 1)<=(player:GetAttribute('CollectedCount') or 0)+1
end
-- Check the avatar's distance from the selected physical writing panel.
local function nearPanel()
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 return root and panel.Parent and (root.Position-panel.Position).Magnitude<=Config.ActivityDistance
end
-- Project screen coordinates onto the door without a GUI-inset mismatch.
local function pointerPoint(position,checkOcclusion)
 local camera=workspace.CurrentCamera
 if not camera or not panel.Parent then return nil end
 local ray=camera:ScreenPointToRay(position.X,position.Y)
 local origin=panel.CFrame:PointToObjectSpace(ray.Origin)
 local direction=panel.CFrame:VectorToObjectSpace(ray.Direction)
 local point,distance=Projection.Front({x=origin.X,y=origin.Y,z=origin.Z},
  {x=direction.X,y=direction.Y,z=direction.Z},{x=panel.Size.X,y=panel.Size.Y,z=panel.Size.Z})
 if not point then return nil end
 if checkOcclusion then
  local exclusions={}
  if player.Character then table.insert(exclusions,player.Character) end
  local visuals=workspace:FindFirstChild('DinosaurVisuals')
  if visuals then table.insert(exclusions,visuals) end
  local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances=exclusions
  local hit=workspace:Raycast(ray.Origin,ray.Direction*(distance+.05),params)
  if not hit or hit.Instance~=panel then return nil end
 end
 return point
end
-- Release physical contact and keep the earned trace position.
local function lift()
 if metrics then metrics:Lift() end
 audio:Writing(false); trace:Lift()
 activeTouch,mouseDown,lastSent,strokeStart=nil,false,nil,true
end
-- Apply local progress or the shared door's completed appearance.
local function updateDisplay()
 display:Update(trace,completed or (not focused and cage:GetAttribute('LetterComplete')==true))
end
-- Fit the selected panel or the full opening animation in the current viewport.
local function cameraPose(reveal)
 local camera=workspace.CurrentCamera
 local aspect=math.max(.3,camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y))
 local width,height,target,margin=panel.Size.X,panel.Size.Y,panel.Position,.72
 if reveal then width,height,margin=30,34,.85; target=beam.Position-Vector3.new(0,1,0) end
 local tangent=math.tan(math.rad(50)/2)
 local distance=math.min(30,math.max(height/(2*tangent*margin),width/(2*tangent*aspect*margin)))
 local fov=math.clamp(math.deg(2*math.atan(math.max(height,width/aspect)/(2*distance*margin))),50,100)
 return CFrame.lookAt(target+panel.CFrame.LookVector*distance,target),CFrame.new(target),fov
end
-- Move the camera without enabling painting during the transition.
local function frameDoor(reveal,duration)
 if cameraTween then cameraTween:Cancel(); cameraTween=nil end
 local camera=workspace.CurrentCamera
 if not camera then return end
 local frame,focus,fov=cameraPose(reveal)
 local tween=TweenService:Create(camera,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),
  {CFrame=frame,Focus=focus,FieldOfView=fov})
 cameraTween=tween; cameraReady=false
 tween.Completed:Once(function(playback)
  if cameraTween~=tween or playback~=Enum.PlaybackState.Completed then return end
  cameraTween=nil; cameraReady=not reveal and focused
  if cameraReady and not pending then status.Text='Pinte a letra do seu jeito. Pode começar onde quiser.' end
 end)
 tween:Play()
end
-- Freeze avatar input and preserve the camera before focusing on a door.
local function lockControls()
 if controls and not controlsDisabled then controls:Disable(); controlsDisabled=true end
 ContextActionService:BindActionAtPriority(actionName,function() return Enum.ContextActionResult.Sink end,
  false,10000,unpack(Enum.PlayerActions:GetEnumItems()))
 savedCamera=workspace.CurrentCamera
 if savedCamera then
  savedCameraType,savedFov,savedFovMode,savedCFrame=savedCamera.CameraType,savedCamera.FieldOfView,savedCamera.FieldOfViewMode,savedCamera.CFrame
  savedCamera.CameraType=Enum.CameraType.Scriptable; savedCamera.FieldOfViewMode=Enum.FieldOfViewMode.Vertical
 end
 local humanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if humanoid then humanoid:Move(Vector3.zero) end
end
-- Restore avatar and camera controls after completion, cancellation or respawn.
local function releaseControls()
 if cameraTween then cameraTween:Cancel(); cameraTween=nil end
 ContextActionService:UnbindAction(actionName)
 if controls and controlsDisabled then controls:Enable(); controlsDisabled=false end
 if savedCamera and savedCamera.Parent then
  savedCamera.FieldOfView,savedCamera.FieldOfViewMode=savedFov,savedFovMode
  if savedCamera.CameraType==Enum.CameraType.Scriptable then savedCamera.CFrame,savedCamera.CameraType=savedCFrame,savedCameraType end
 end
 savedCamera=nil
end
-- Cancel the selected writing session and restore free movement.
local function close()
 finishMetrics('cancelled')
 if activeToken then remote:FireServer('cancel',activeToken) end
 requestGeneration+=1
 activeToken,pending,finishing,focused,cameraReady=nil,false,false,false,false
 heading.Visible,closeButton.Visible,repeatButton.Visible=false,false,false
 lift(); releaseControls(); updateDisplay()
end
-- Request a fresh session for the selected eligible closed door.
local function begin()
 if pending or finishing or not nearPanel() or not available() then return end
 if not DoorCycle.CanWrite(cage:GetAttribute('DoorState')) then return end
 if not focused then lockControls() end
 requestGeneration+=1; local generation=requestGeneration
 if activeToken then remote:FireServer('cancel',activeToken) end
 finishMetrics('restarted')
 trace,samples,activeToken=Trace.new(letter,Config.AlphabetTraceTolerance),{},nil
 if logMetrics then attemptNumber+=1;metrics=WritingMetrics.new(letter,trace.cells) end
 paintAudioProgress=0
 completed,finishing,pending,focused=false,false,true,true
 heading.Text=letter..' de '..Catalog.ByLetter[letter].name
 heading.Visible,closeButton.Visible,repeatButton.Visible,status.Visible=true,true,true,true
 lift(); updateDisplay(); status.Text='Aproxime o olhar…'; frameDoor(false,.55)
 remote:FireServer('begin',letter)
 task.delay(8,function()
  if not destroyed and generation==requestGeneration and pending then
   pending=false; status.Text='Toque em ↻ para tentar conectar novamente.'
  end
 end)
end
--- Feeds approximate coverage while preserving free starts and independent contact paths.
local function sampleAt(position)
 if not focused or not cameraReady or not activeToken or pending or finishing or completed then return end
 local point=pointerPoint(position,false)
 if not Projection.Inside(point) then
  if metrics then metrics:Outside() end
  audio:Writing(false); trace:Lift(); lastSent,strokeStart=nil,true
  status.Text='Pode continuar em qualquer parte da letra. A pintura está guardada.'; return
 end
 local sample={x=point.x,y=point.y,start=strokeStart}
 if lastSent and not strokeStart and (Vector2.new(point.x,point.y)-lastSent).Magnitude<.002 then return end
 if #samples>=4096 then audio:Writing(false); status.Text='Toque em ↻ para começar a letra novamente.'; return end
 table.insert(samples,sample); lastSent,strokeStart=Vector2.new(point.x,point.y),false
 local accepted,state=trace:Feed(sample)
 local progress=trace:GetProgress()
 if metrics then metrics:Sample(point,accepted,progress) end
 if accepted and progress>paintAudioProgress then audio:Writing(true)
 elseif not accepted then audio:Writing(false) end
 paintAudioProgress=progress
 status.Text=if accepted then 'Isso! Pinte também as partes que faltam.' else 'Pode continuar em qualquer parte da letra. A pintura está guardada.'
 updateDisplay()
 if state=='complete' then
  finishing=true; audio:Writing(false); status.Text='Muito bem!'
  remote:FireServer('complete',activeToken,samples)
  local generation=requestGeneration
  task.delay(8,function()
   if not destroyed and generation==requestGeneration and finishing then
    finishing=false; status.Text='A resposta demorou. Toque em ↻ para tentar de novo.'
   end
  end)
 end
end
-- Test whether a pointer belongs to an activity HUD button.
local function overButton(position,buttonGui)
 local p,s=buttonGui.AbsolutePosition,buttonGui.AbsoluteSize
 return buttonGui.Visible and position.X>=p.X and position.X<=p.X+s.X and position.Y>=p.Y and position.Y<=p.Y+s.Y
end
-- Bind shared door state without retaining subscriptions to previously selected cages.
local function watchCage()
 for _,connection in ipairs(cageConnections) do connection:Disconnect() end
 table.clear(cageConnections)
 table.insert(cageConnections,cage:GetAttributeChangedSignal('LetterComplete'):Connect(updateDisplay))
 table.insert(cageConnections,cage:GetAttributeChangedSignal('DoorState'):Connect(function()
  local state=cage:GetAttribute('DoorState')
  if DoorCycle.CanWrite(state) then
   if focused then close() end
   completed=false; trace,samples=Trace.new(letter,Config.AlphabetTraceTolerance),{}
   paintAudioProgress=0; updateDisplay()
  elseif focused and not finishing and not completed then close() end
 end))
end
-- Select the nearest cage while keeping the current one during a writing session.
local function selectNearest()
 if focused then return end
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 if not root then return end
 local nearest,best=cage,(root.Position-panel.Position).Magnitude
 for _,candidate in ipairs(stations:GetChildren()) do
  local candidatePanel=candidate:FindFirstChild('WritingPanel')
  local candidateLetter=candidate:GetAttribute('Letter')
  if candidatePanel and candidate:FindFirstChild('FrontBeam') and Catalog.ByLetter[candidateLetter] then
   local distance=(root.Position-candidatePanel.Position).Magnitude
   if distance<best-2 then nearest,best=candidate,distance end
  end
 end
 if nearest==cage then return end
 lift(); display:Destroy()
 cage=nearest; panel,beam=cage.WritingPanel,cage.FrontBeam; letter=cage:GetAttribute('Letter')
 trace,samples=Trace.new(letter,Config.AlphabetTraceTolerance),{}
 completed,paintAudioProgress=false,0
 display=Display.new(panel,playerGui,letter); audio:AttachCage(cage)
 watchCage(); updateDisplay()
end
-- Refresh collection guidance from authoritative player attributes.
local function updateCollection()
 local count=player:GetAttribute('CollectedCount') or 0
 local nextLetter=player:GetAttribute('NextLetter') or 'A'
 collection.Text=if player:GetAttribute('JourneyFinished') then '26 / 26 • Passeio completo!'
  elseif count>=26 then '26 / 26 • Siga até a saída!'
  else tostring(count)..' / 26 • Próxima letra: '..nextLetter
end
connect(UserInputService.InputBegan,function(input,processed)
 if destroyed or processed or GuiService.MenuIsOpen then return end
 local isTouch=input.UserInputType==Enum.UserInputType.Touch
 local isMouse=input.UserInputType==Enum.UserInputType.MouseButton1
 if not isTouch and not isMouse then return end
 if overButton(input.Position,closeButton) or overButton(input.Position,repeatButton) or overButton(input.Position,soundButton) then return end
 if not focused then
  if processed or not nearPanel() then return end
  if Projection.Inside(pointerPoint(input.Position,true)) then begin() end
  return
 end
 if not cameraReady or activeTouch or mouseDown then return end
 if not Projection.Inside(pointerPoint(input.Position,false)) then return end
 if metrics and activeToken and not pending and not finishing and not completed then metrics:Contact(if isTouch then 'touch' else 'mouse') end
 if isTouch then activeTouch=input else mouseDown=true end
 strokeStart,lastSent=true,nil; sampleAt(input.Position)
end)
connect(UserInputService.InputChanged,function(input)
 if (activeTouch and input==activeTouch) or (mouseDown and input.UserInputType==Enum.UserInputType.MouseMovement) then sampleAt(input.Position) end
end)
connect(UserInputService.InputEnded,function(input)
 if (activeTouch and input==activeTouch) or (mouseDown and input.UserInputType==Enum.UserInputType.MouseButton1) then sampleAt(input.Position); lift() end
end)
connect(UserInputService.WindowFocusReleased,lift)
connect(player.CharacterRemoving,close)
connect(closeButton.Activated,close)
connect(repeatButton.Activated,begin)
connect(workspace:GetPropertyChangedSignal('CurrentCamera'),function() if focused then close() end end)
for _,attribute in ipairs({'CollectedCount','NextLetter','JourneyFinished'}) do connect(player:GetAttributeChangedSignal(attribute),updateCollection) end
connect(RunService.RenderStepped,function(dt)
 if destroyed then return end
 display:Step(dt); audio:Step(dt)
 scanElapsed+=dt
 if scanElapsed>=.2 then scanElapsed=0; selectNearest() end
 local camera=workspace.CurrentCamera
 if not camera then return end
 if camera.ViewportSize~=lastViewport then
  lastViewport=camera.ViewportSize
  if focused then lift(); frameDoor(completed,.25) end
 end
 if not focused then
  local _,visible=camera:WorldToViewportPoint(panel.Position)
  status.Visible=nearPanel() and visible
  local state=cage:GetAttribute('DoorState')
  if not available() then status.Text='Primeiro encontre a letra '..tostring(player:GetAttribute('NextLetter') or 'A')..'.'
  elseif DoorCycle.CanWrite(state) then status.Text='Toque no '..letter..' da porta • '..Catalog.ByLetter[letter].name
  elseif state=='Open' then status.Text='Porta aberta! Continue pela avenida ou espere para repetir.'
  elseif state=='Closing' then status.Text='A porta está fechando…'
  else status.Text='A porta está abrindo…' end
 end
end)
connect(remote.OnClientEvent,function(action,payload,responseToken)
 if action=='journeyComplete' then
  audio:Play('Complete'); updateCollection()
 elseif action=='ready' then
  if not focused or not pending or responseToken~=letter then remote:FireServer('cancel',payload); return end
  activeToken,pending=payload,false
  if cameraReady then status.Text='Pinte a letra do seu jeito. Pode começar onde quiser.' end
 elseif action=='complete' and payload==activeToken and focused and finishing then
  finishMetrics('completed')
  completed,finishing=true,false; audio:Play('Complete')
  status.Text='Você escreveu '..letter..'! Veja a porta abrir…'; repeatButton.Visible=false
  lift(); updateDisplay(); frameDoor(true,.6)
  local generation=requestGeneration
  task.delay(Config.SignalSeconds+Config.GateLiftSeconds+1.5,function()
   if not destroyed and generation==requestGeneration then close() end
  end)
 elseif action=='error' and focused and (responseToken==nil or responseToken==activeToken) then
  pending,finishing=false,false; audio:Writing(false)
  if not DoorCycle.CanWrite(cage:GetAttribute('DoorState')) then close() end
  status.Text=tostring(payload)
 end
end)
connect(gui.Destroying,function()
 finishMetrics('interface_closed')
 destroyed=true; requestGeneration+=1
 if activeToken then remote:FireServer('cancel',activeToken) end
 releaseControls()
 for _,connection in ipairs(connections) do connection:Disconnect() end
 for _,connection in ipairs(cageConnections) do connection:Disconnect() end
 display:Destroy(); audio:Destroy()
end)
watchCage(); updateDisplay(); updateCollection()
