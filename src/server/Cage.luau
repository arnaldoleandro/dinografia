local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Dinografia.Config)

local Players = game:GetService("Players")
local Cycle = require(game:GetService("ReplicatedStorage").Dinografia.DoorCycle)
local Cage = {}
--- Builds the cage and its reusable, obstruction-aware door.
function Cage.new(options)
	local model = Instance.new("Model")
	model.Name = if options then "Cage_"..options.Letter else "BlueCage"
	local origin = if options then options.CFrame else CFrame.new(0,0,40)
	local center = origin.Position
	local floorTop = 0.5
	--- Creates one fixed structural part.
	local function part(name, size, offset, color, transparency)
		local p = Instance.new("Part")
		p.Name, p.Size = name, size
		p.Anchored = true
		p.CFrame = origin * CFrame.new(offset)
		p.Color = color
		p.Material = if transparency then Enum.Material.Glass else Enum.Material.Metal
		p.Transparency = transparency or 0
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local metal = Color3.fromRGB(64, 91, 91)
	local glass = Color3.fromRGB(156, 213, 201)
	part("Floor", Vector3.new(26, 0.5, 32), Vector3.new(0, 0.25, 0), metal)
	part("Back", Vector3.new(26, 14, 0.6), Vector3.new(0, floorTop + 7, 16), glass, 0.65)
	part("Left", Vector3.new(0.6, 14, 32), Vector3.new(-13, floorTop + 7, 0), glass, 0.65)
	part("Right", Vector3.new(0.6, 14, 32), Vector3.new(13, floorTop + 7, 0), glass, 0.65)
	part("FrontLeft", Vector3.new(7, 14, 0.6), Vector3.new(-9.5, floorTop + 7, -16), glass, 0.65)
	part("FrontRight", Vector3.new(7, 14, 0.6), Vector3.new(9.5, floorTop + 7, -16), glass, 0.65)
	part("Roof", Vector3.new(26, 0.6, 32), Vector3.new(0, floorTop + 14.3, 0), glass, 0.8)
	local gate = part("Gate", Vector3.new(12, 14, 0.8), Vector3.new(0, floorTop + 7, -16), metal)
	local panel = part("WritingPanel", Vector3.new(10,10,0.18), Vector3.new(0,floorTop+7,-16.5),
		Color3.fromRGB(56,83,83))
	panel.CanCollide, panel.CanTouch, panel.Massless = false, false, true
	panel.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = gate, panel, panel
	-- Door and writing surface move as a single assembly. No painting left floating.
	part("FrontBeam", Vector3.new(27,1.2,1.4), Vector3.new(0,floorTop+14.8,-16),metal)
	-- Above the fixed right wall, clear of the rising door.
	local pedestal = part("BeaconBase", Vector3.new(0.5,2.3,2.3), Vector3.new(9,floorTop+15.6,-16),metal)
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.CFrame = pedestal.CFrame * CFrame.Angles(0,0,math.pi/2)
	local dome = part("BeaconLens", Vector3.new(1.8,1.5,1.8),Vector3.new(9,floorTop+16.4,-16),Color3.fromRGB(101,73,30))
	dome.Shape = Enum.PartType.Ball
	dome.CanCollide = false
	local rotor = part("BeaconRotor",Vector3.new(0.2,0.2,0.2),Vector3.new(9,floorTop+16.4,-16),metal)
	rotor.Transparency,rotor.CanCollide,rotor.CanQuery = 1,false,false
	local glow=Instance.new("PointLight")
	glow.Color,glow.Range,glow.Brightness,glow.Enabled = Color3.fromRGB(255,186,64),18,1.6,false
	glow.Parent=dome
	local beams={}
	for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
		local light=Instance.new("SpotLight")
		light.Face,light.Color,light.Angle,light.Range,light.Brightness = face,glow.Color,65,35,4
		light.Enabled=false
		light.Parent=rotor
		table.insert(beams,light)
	end
	local closed = gate.CFrame
	if options then
        model:SetAttribute("Letter",options.Letter)
        model:SetAttribute("DinosaurName",options.Name)
        model:SetAttribute("StationIndex",options.Index)
    end
    model.Parent = if options then options.Parent else workspace
	model:SetAttribute("Unlocked", false)
	model:SetAttribute("DoorState", "Locked")
	local beaconConnection = nil
	local callbacks={}
	local self = { Model = model, FloorTop = floorTop, Center = center, Panel = panel }
	--- Starts one short beacon effect without stacking its update loop.
	function self:Signal()
		if beaconConnection then return end
		local elapsed, accumulated=0,0
		glow.Enabled=true
		dome.Material,dome.Color=Enum.Material.Neon,Color3.fromRGB(255,183,54)
		for _,light in ipairs(beams) do light.Enabled=true end
		beaconConnection=RunService.Heartbeat:Connect(function(dt)
			elapsed+=dt; accumulated+=dt
			if not model.Parent or elapsed>=Config.BeaconSeconds then
				beaconConnection:Disconnect(); beaconConnection=nil
				glow.Enabled=false
				for _,light in ipairs(beams) do light.Enabled=false end
				if model.Parent then dome.Material=Enum.Material.Metal; dome.Color=Color3.fromRGB(101,73,30) end
				return
			end
			if accumulated>=1/30 then
				accumulated=0
				rotor.CFrame=CFrame.new(dome.Position)*CFrame.Angles(0,elapsed*math.pi*1.6,0)
			end
		end)
	end
    local cycle=Cycle.new(Config.SignalSeconds,Config.GateLiftSeconds,Config.GateOpenSeconds)
    local activeTween,cycleConnection=nil,nil
    local raised=closed+Vector3.new(0,15,0)
    local params=OverlapParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    params.MaxParts=1

    --- Detects players or Blue in the cage and the entire doorway safety margin.
    local function occupied()
        local actors={}
        for _,player in ipairs(Players:GetPlayers()) do
            if player.Character then table.insert(actors,player.Character) end
        end
        local dinosaur=workspace:FindFirstChild("Blue")
        if dinosaur then table.insert(actors,dinosaur) end
        if #actors==0 then return false end
        params.FilterDescendantsInstances=actors
        return #workspace:GetPartBoundsInBox(origin*CFrame.new(0,8,-1.5),
            Vector3.new(28,17,37),params)>0
    end

    --- Applies one state transition and completes callbacks only after opening fully.
    local function applyState(previous)
        if previous==cycle.state then return end
        if activeTween then activeTween:Cancel();activeTween=nil end
        if cycle.state=="Signalling" then
            model:SetAttribute("LetterComplete",true)
            self:Signal()
        elseif cycle.state=="Opening" or cycle.state=="Closing" then
            gate.CanCollide=false
            activeTween=TweenService:Create(gate,TweenInfo.new(Config.GateLiftSeconds,
                Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),
                {CFrame=if cycle.state=="Opening" then raised else closed})
            activeTween:Play()
        elseif cycle.state=="Open" then
            gate.CFrame=raised
            gate.CanCollide=false
            model:SetAttribute("Unlocked",true)
        elseif cycle.state=="Closed" then
            gate.CFrame=closed
            gate.CanCollide=true
            model:SetAttribute("LetterComplete",false)
        end
        model:SetAttribute("DoorState",cycle.state)
        if cycle.state=="Open" then
            local ready=callbacks;callbacks={}
            for _,callback in ipairs(ready) do callback() end
        end
    end

    --- Opens or reopens the door, preserving Blue's permanent session release.
    function self:Open(onOpened)
        local previous=cycle.state
        cycle:Open(os.clock())
        if previous=="Open" then onOpened();return end
        table.insert(callbacks,onOpened)
        applyState(previous)
    end

    --- Updates the timer and reverses closing if an actor enters the protected area.
    local function stepDoor()
        if not model.Parent then
            cycleConnection:Disconnect()
            if activeTween then activeTween:Cancel() end
            return
        end
        local previous=cycle.state
        local now=os.clock()
        local blocked=(previous=="Closing" or (previous=="Open" and now>=cycle.deadline)) and occupied()
        cycle:Step(now,blocked)
        applyState(previous)
    end
    cycleConnection=RunService.Heartbeat:Connect(stepDoor)
	return self
end
return Cage
