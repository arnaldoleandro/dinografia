local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Dinografia.Config)

local Cage = {}
function Cage.new()
	local model = Instance.new("Model")
	model.Name = "BlueCage"
	local center = Vector3.new(0, 0, 40)
	local floorTop = 0.5
	local function part(name, size, offset, color, transparency)
		local p = Instance.new("Part")
		p.Name, p.Size = name, size
		p.Anchored = true
		p.Position = center + offset
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
	pedestal.Orientation = Vector3.new(0,0,90)
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
	model.Parent = workspace
	model:SetAttribute("Unlocked", false)
	model:SetAttribute("DoorState", "Locked")
	local opening, opened, beaconConnection = false, false, nil
	local callbacks={}
	local self = { Model = model, FloorTop = floorTop, Center = center, Panel = panel }
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
	function self:Open(onOpened)
		model:SetAttribute("LetterComplete",true)
		self:Signal()
		if opened then onOpened(); return end
		table.insert(callbacks,onOpened)
		if opening then return end
		opening=true
		model:SetAttribute("DoorState", "Signalling")
		task.spawn(function()
			task.wait(Config.SignalSeconds)
			if not model.Parent then return end
			model:SetAttribute("DoorState", "Opening")
			local tween=TweenService:Create(gate,TweenInfo.new(Config.GateLiftSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),
				{CFrame=closed+Vector3.new(0,15,0)})
			tween:Play()
			local result=tween.Completed:Wait()
			if result~=Enum.PlaybackState.Completed or not model.Parent then return end
			gate.CanCollide=false
			opened=true
			model:SetAttribute("Unlocked",true)
			model:SetAttribute("DoorState","Open")
			for _,callback in ipairs(callbacks) do callback() end
			table.clear(callbacks)
		end)
	end
	return self
end
return Cage
