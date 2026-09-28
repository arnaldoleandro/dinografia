local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Dinografia")
local Trace, Config = require(shared.Trace), require(shared.Config)
local Projection = require(shared.GateProjection)
local DoorCycle, Paint = require(shared.DoorCycle), require(shared.PaintProgress)
local remote = shared:WaitForChild("Activity",30)
if not remote then warn("[Dinografia] Confira o Output do servidor: atividade indisponível."); return end
local cage = workspace:WaitForChild("BlueCage")
local panel = cage:WaitForChild("WritingPanel")
local beam = cage:WaitForChild("FrontBeam")
local playerGui = player:WaitForChild("PlayerGui")
local display = require(script.Parent.GateDisplay).new(panel,playerGui)
local audio = require(ReplicatedStorage:WaitForChild("DinografiaAudio").Controller).new(cage)

--- Creates a UI instance from a property table.
local function create(className,props,parent)
	local item=Instance.new(className)
	for key,value in pairs(props) do item[key]=value end
	item.Parent=parent
	return item
end
local gui=create("ScreenGui",{Name="DinografiaActivity",ResetOnSpawn=false,IgnoreGuiInset=true,
	ScreenInsets=Enum.ScreenInsets.None,DisplayOrder=20},playerGui)
local status=create("TextLabel",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-22),
	Size=UDim2.new(0.85,0,0,54),BackgroundColor3=Color3.fromRGB(20,43,46),BackgroundTransparency=0.15,
	TextColor3=Color3.fromRGB(247,244,229),TextSize=18,Font=Enum.Font.GothamMedium,
	TextWrapped=true,Text="Toque no V da porta",BorderSizePixel=0},gui)
create("UISizeConstraint",{MaxSize=Vector2.new(650,54)},status)
create("UICorner",{CornerRadius=UDim.new(0,18)},status)
local heading=create("TextLabel",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,55),
	Size=UDim2.new(0.6,0,0,34),BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,234,185),
	Font=Enum.Font.GothamBold,Text="V de velociraptor",TextScaled=true,Visible=false},gui)
create("UITextSizeConstraint",{MaxTextSize=26,MinTextSize=14},heading)
--- Creates an accessible activity control.
local function button(text,x,anchor)
	local item=create("TextButton",{AnchorPoint=Vector2.new(anchor,0),Position=UDim2.new(x,if anchor==1 then -16 else 16,0,52),
		Size=UDim2.fromOffset(48,48),Text=text,TextSize=30,Font=Enum.Font.GothamBold,
		BackgroundColor3=Color3.fromRGB(31,78,69),TextColor3=Color3.fromRGB(255,234,185),
		BorderSizePixel=0,Visible=false,Modal=true},gui)
	create("UICorner",{CornerRadius=UDim.new(0,14)},item)
	return item
end
local closeButton,repeatButton=button("×",1,1),button("↻",0,0)
local soundButton=create("TextButton",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-16,0,112),
	Size=UDim2.fromOffset(146,40),Text="Som: baixo",TextSize=16,Font=Enum.Font.GothamMedium,
	BackgroundColor3=Color3.fromRGB(31,78,69),TextColor3=Color3.fromRGB(255,234,185),BorderSizePixel=0},gui)
create("UICorner",{CornerRadius=UDim.new(0,12)},soundButton)
soundButton.Activated:Connect(function() soundButton.Text=audio:CycleVolume() end)
local paintAudioProgress=0
local trace=Trace.new(Config.TraceTolerance)
local samples={}
local focused,pending,finishing,completed,cameraReady=false,false,false,false,false
local activeToken,activeTouch,lastSent=nil,nil,nil
local mouseDown,strokeStart=false,true
local requestGeneration=0
local savedCamera,savedCameraType,savedFov,savedFovMode,savedCFrame=nil,nil,nil,nil,nil
local cameraTween,controls=nil,nil
local controlsDisabled=false
local lastViewport=Vector2.zero
local actionName="DinografiaWritingControls"
local playerModule=player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule",10)
if playerModule then
	local ok,result=pcall(function() return require(playerModule):GetControls() end)
	if ok then controls=result end
end

--- Checks whether the avatar can reach the writing activity.
local function nearPanel()
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position-panel.Position).Magnitude<=Config.ActivityDistance
end
--- Projects mouse or touch coordinates onto the physical door.
local function pointerPoint(position,checkOcclusion)
	local camera=workspace.CurrentCamera
	if not camera or not panel.Parent then return nil end
	-- InputObject.Position uses core UI coordinates, including the GUI inset.
	-- ScreenPointToRay matches that origin for both mouse and touch; do not add a fixed offset.
	local ray=camera:ScreenPointToRay(position.X,position.Y)
	local origin=panel.CFrame:PointToObjectSpace(ray.Origin)
	local direction=panel.CFrame:VectorToObjectSpace(ray.Direction)
	local point,distance=Projection.Front({x=origin.X,y=origin.Y,z=origin.Z},
		{x=direction.X,y=direction.Y,z=direction.Z},{x=panel.Size.X,y=panel.Size.Y,z=panel.Size.Z})
	if not point then return nil end
	if checkOcclusion then
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances=if player.Character then {player.Character} else {}
		local hit=workspace:Raycast(ray.Origin,ray.Direction*(distance+0.05),params)
		if not hit or hit.Instance~=panel then return nil end
	end
	return point
end
--- Ends the current stroke and silences painting.
local function lift()
	audio:Writing(false)
	trace:Lift()
	activeTouch,mouseDown,lastSent,strokeStart=nil,false,nil,true
end
--- Refreshes the painted guide from local and shared completion state.
local function updateDisplay()
	display:Update(trace,completed or (not focused and cage:GetAttribute("LetterComplete")==true))
end
--- Fits the door or opening sequence to the current screen.
local function cameraPose(reveal)
	local camera=workspace.CurrentCamera
	local aspect=math.max(0.3,camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y))
	local width,height=panel.Size.X,panel.Size.Y
	local target=panel.Position
	local margin=0.72
	if reveal then
		width,height,margin=30,34,0.85
		target=beam.Position-Vector3.new(0,1,0)
	end
	local tangent=math.tan(math.rad(50)/2)
	local distance=math.max(height/(2*tangent*margin),width/(2*tangent*aspect*margin))
	return CFrame.lookAt(target+panel.CFrame.LookVector*distance,target),CFrame.new(target)
end
--- Moves the camera to the selected view.
local function frameDoor(reveal,duration)
	if cameraTween then cameraTween:Cancel(); cameraTween=nil end
	local camera=workspace.CurrentCamera
	if not camera then return end
	local frame,focus=cameraPose(reveal)
	local tween=TweenService:Create(camera,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),
		{CFrame=frame,Focus=focus,FieldOfView=50})
	cameraTween=tween
	cameraReady=false
	tween.Completed:Once(function(playback)
		if cameraTween~=tween or playback~=Enum.PlaybackState.Completed then return end
		cameraTween=nil
		cameraReady=not reveal and focused
		if cameraReady and not pending then status.Text="Comece no ponto amarelo e pinte o sulco." end
	end)
	tween:Play()
end
--- Temporarily freezes avatar and camera input while writing.
local function lockControls()
	if controls and not controlsDisabled then controls:Disable(); controlsDisabled=true end
	ContextActionService:BindActionAtPriority(actionName,function() return Enum.ContextActionResult.Sink end,
		false,10000,unpack(Enum.PlayerActions:GetEnumItems()))
	savedCamera=workspace.CurrentCamera
	if savedCamera then
		savedCameraType,savedFov,savedFovMode,savedCFrame=savedCamera.CameraType,savedCamera.FieldOfView,savedCamera.FieldOfViewMode,savedCamera.CFrame
		savedCamera.CameraType=Enum.CameraType.Scriptable
		savedCamera.FieldOfViewMode=Enum.FieldOfViewMode.Vertical
	end
	local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:Move(Vector3.zero) end
end
--- Restores the controls and camera saved before writing.
local function releaseControls()
	if cameraTween then cameraTween:Cancel(); cameraTween=nil end
	ContextActionService:UnbindAction(actionName)
	if controls and controlsDisabled then controls:Enable(); controlsDisabled=false end
	if savedCamera and savedCamera.Parent then
		savedCamera.FieldOfView,savedCamera.FieldOfViewMode=savedFov,savedFovMode
		if savedCamera.CameraType==Enum.CameraType.Scriptable then
			savedCamera.CFrame,savedCamera.CameraType=savedCFrame,savedCameraType
		end
	end
	savedCamera=nil
end
--- Cancels the local writing session and restores gameplay controls.
local function close()
	if activeToken then remote:FireServer("cancel",activeToken) end
	requestGeneration+=1
	activeToken,pending,finishing,focused,cameraReady=nil,false,false,false,false
	heading.Visible,closeButton.Visible,repeatButton.Visible=false,false,false
	lift()
	releaseControls()
	updateDisplay()
end
--- Starts a writing session only on a stationary closed door.
local function begin()
	if pending or finishing or not nearPanel() then return end
	local doorState=cage:GetAttribute("DoorState")
	if not DoorCycle.CanWrite(doorState) then return end
	if not focused then lockControls() end
	requestGeneration+=1
	local generation=requestGeneration
	if activeToken then remote:FireServer("cancel",activeToken) end
	trace,samples,activeToken=Trace.new(Config.TraceTolerance),{},nil
	paintAudioProgress=0
	completed,finishing,pending,focused=false,false,true,true
	heading.Visible,closeButton.Visible,repeatButton.Visible,status.Visible=true,true,true,true
	lift()
	updateDisplay()
	status.Text="Aproxime o olhar…"
	frameDoor(false,0.55)
	remote:FireServer("begin")
	task.delay(8,function()
		if generation==requestGeneration and pending then
			pending=false
			status.Text="Toque em ↻ para tentar conectar novamente."
		end
	end)
end
--- Validates a pointer sample and updates paint and audio feedback.
local function sampleAt(position)
	if not focused or not cameraReady or not activeToken or pending or finishing or completed then return end
	local point=pointerPoint(position,false)
	if not Projection.Inside(point) then
		audio:Writing(false)
		trace:Lift();lastSent,strokeStart=nil,true
		status.Text="Continue no ponto amarelo. A pintura está guardada."
		return
	end
	local sample={x=point.x,y=point.y,start=strokeStart}
	if lastSent and not strokeStart and (Vector2.new(point.x,point.y)-lastSent).Magnitude<0.002 then return end
	if #samples>=Config.MaxTraceSamples then status.Text="Toque em ↻ para começar outro V.";return end
	table.insert(samples,sample)
	lastSent,strokeStart=Vector2.new(point.x,point.y),false
	local accepted,state=trace:Feed(sample)
	local progress=Paint.Target(trace,paintAudioProgress,Trace.Points)
	if accepted and progress>paintAudioProgress then audio:Writing(true)
	elseif not accepted then audio:Writing(false) end
	paintAudioProgress=progress
	status.Text=if accepted then (if trace:GetProgress()<0.5 then "Desça até a ponta…" else "Agora suba…")
		else "Continue no ponto amarelo. A pintura está guardada."
	updateDisplay()
	if state=="complete" then
		finishing=true
		audio:Writing(false)
		status.Text="Muito bem!"
		remote:FireServer("complete",activeToken,samples)
		local generation=requestGeneration
		task.delay(8,function()
			if generation==requestGeneration and finishing then
				finishing=false
				status.Text="A resposta demorou. Toque em ↻ para tentar de novo."
			end
		end)
	end
end
--- Checks whether input belongs to a HUD control.
local function overButton(position,buttonGui)
	local p,s=buttonGui.AbsolutePosition,buttonGui.AbsoluteSize
	return buttonGui.Visible and position.X>=p.X and position.X<=p.X+s.X and position.Y>=p.Y and position.Y<=p.Y+s.Y
end
UserInputService.InputBegan:Connect(function(input,processed)
	if GuiService.MenuIsOpen then return end
	local isTouch=input.UserInputType==Enum.UserInputType.Touch
	local isMouse=input.UserInputType==Enum.UserInputType.MouseButton1
	if not isTouch and not isMouse then return end
	if overButton(input.Position,closeButton) or overButton(input.Position,repeatButton) or overButton(input.Position,soundButton) then return end
	if not focused then
		if processed or not nearPanel() then return end
		if Projection.Inside(pointerPoint(input.Position,true)) then begin() end
		return -- The first tap frames the real door; the next stroke paints it.
	end
	if not cameraReady or activeTouch or mouseDown then return end
	if not Projection.Inside(pointerPoint(input.Position,false)) then return end
	if isTouch then activeTouch=input else mouseDown=true end
	strokeStart,lastSent=true,nil
	sampleAt(input.Position)
end)
UserInputService.InputChanged:Connect(function(input)
	if (activeTouch and input==activeTouch) or (mouseDown and input.UserInputType==Enum.UserInputType.MouseMovement) then sampleAt(input.Position) end
end)
UserInputService.InputEnded:Connect(function(input)
	if (activeTouch and input==activeTouch) or (mouseDown and input.UserInputType==Enum.UserInputType.MouseButton1) then
		sampleAt(input.Position);lift()
	end
end)
UserInputService.WindowFocusReleased:Connect(lift)
player.CharacterRemoving:Connect(close)
closeButton.Activated:Connect(close)
repeatButton.Activated:Connect(begin)
cage:GetAttributeChangedSignal("LetterComplete"):Connect(updateDisplay)
--- Resets the guide for a closed door and cancels competing writing sessions.
local function doorChanged()
    local state=cage:GetAttribute("DoorState")
    if DoorCycle.CanWrite(state) then
        if focused then close() end
        completed=false
        trace,samples=Trace.new(Config.TraceTolerance),{}
        paintAudioProgress=0
        updateDisplay()
    elseif focused and not finishing and not completed then
        close()
    end
end
cage:GetAttributeChangedSignal("DoorState"):Connect(doorChanged)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() if focused then close() end end)
local renderConnection=RunService.RenderStepped:Connect(function(dt)
	display:Step(dt)
	audio:Step(dt)
	local camera=workspace.CurrentCamera
	if not camera then return end
	if camera.ViewportSize~=lastViewport then
		lastViewport=camera.ViewportSize
		if focused then lift();frameDoor(completed,0.25) end
	end
	if not focused then
		local _,visible=camera:WorldToViewportPoint(panel.Position)
		status.Visible=nearPanel() and visible
		local doorState=cage:GetAttribute("DoorState")
        status.Text=if DoorCycle.CanWrite(doorState) then "Toque no V da porta"
            elseif doorState=="Open" then "Blue está livre! Afaste-se da passagem para a porta fechar."
            elseif doorState=="Closing" then "A porta está fechando…"
            else "A porta está abrindo…"
	end
end)
gui.Destroying:Connect(function()
	releaseControls()
	renderConnection:Disconnect()
	display.Gui:Destroy()
	audio:Destroy()
end)
remote.OnClientEvent:Connect(function(action,payload,responseToken)
	if action=="ready" then
		if not focused or not pending then remote:FireServer("cancel",payload);return end
		activeToken,pending=payload,false
		if cameraReady then status.Text="Comece no ponto amarelo e pinte o sulco." end
	elseif action=="complete" and payload==activeToken and focused and finishing then
		completed,finishing=true,false
		audio:Play("Complete")
		status.Text="Você escreveu V! Veja a porta abrir…"
		repeatButton.Visible=false
		lift();updateDisplay();frameDoor(true,0.6)
		local generation=requestGeneration
		task.delay(Config.SignalSeconds+Config.GateLiftSeconds+1.5,function()
			if generation==requestGeneration then close() end
		end)
	elseif action=="error" and focused and (responseToken==nil or responseToken==activeToken) then
		pending,finishing=false,false
		audio:Writing(false)
		if not DoorCycle.CanWrite(cage:GetAttribute("DoorState")) then close() end
		status.Text=tostring(payload)
	end
end)
updateDisplay()
