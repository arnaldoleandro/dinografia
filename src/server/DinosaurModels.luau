local Models = {}
local V = Vector3.new

-- Builds an original anchored toy silhouette facing -Z with its feet at the origin plane.
function Models.Create(entry)
	local model = Instance.new("Model")
	model.Name = entry.letter .. "_" .. entry.name
	model:SetAttribute("Letter", entry.letter)
	model:SetAttribute("Species", entry.name)
	model:SetAttribute("ModelKind", entry.modelKind)
	model:SetAttribute("Classification", entry.classification)
	local base = Color3.fromRGB(table.unpack(entry.color))
	local accent = base:Lerp(Color3.fromRGB(238, 214, 162), 0.65)
	local dark = base:Lerp(Color3.fromRGB(37, 57, 65), 0.55)
	local f = entry.features

	-- Adds a rounded nonphysical part using coordinates relative to the model pivot.
	local function part(name, size, position, color, shape, rotation)
		local p = Instance.new("Part")
		p.Name, p.Size = name, size
		p.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
		p.Color = color or base
		p.Material = Enum.Material.SmoothPlastic
		p.Shape = shape or Enum.PartType.Ball
		p.Anchored, p.CanCollide, p.CanTouch = true, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	-- Joins two endpoints with an ellipsoid to keep limbs and tails continuous.
	local function link(name, a, b, width, color)
		return part(name, V(width, width, (b-a).Magnitude + width * 0.4), (a+b)/2, color, nil, CFrame.lookAt(a,b).Rotation)
	end

	-- Creates a tapered wedge whose narrow end forms a horn or decorative plate.
	local function wedge(name, size, position, color, rotation)
		local p = Instance.new("WedgePart")
		p.Name, p.Size, p.Color = name, size, color or accent
		p.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanTouch = true, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local root = part("Root", V(0.1,0.1,0.1), V(0,0,0))
	root.Transparency, root.CanQuery = 1, false
	model.PrimaryPart = root
	local family = entry.family
	local quadruped = family == "sauropod" or family == "ceratopsian" or family == "stegosaur" or family == "armored" or family == "synapsid"
	local bodyY = if quadruped then 2.4 else 3.4
	local bodyWidth = if quadruped then 3.8 else 2.8
	part("Body", V(bodyWidth, 2.8, 5.8), V(0,bodyY,0))
	part("Belly", V(bodyWidth*0.8, 1.8, 4.6), V(0,bodyY-0.45,-0.15), accent)
	local legX = bodyWidth * 0.33
	for _, side in {-1,1} do
		local x = side*legX
		link("HindLeg", V(x,bodyY,1.4), V(x,0.6,1.7), 1.05)
		part("HindFoot", V(1.2,0.6,1.8), V(x,0.3,1.25), dark)
		if quadruped then
			link("ForeLeg", V(x,bodyY,-1.5), V(x,0.6,-1.9), 0.9)
			part("ForeFoot", V(1.1,0.6,1.4), V(x,0.3,-2), dark)
		else
			local armLength = if f.shortArms then 0.65 else 1.45
			link("Arm", V(side*1.15,bodyY+0.3,-1.6), V(side*1.45,bodyY-armLength,-2.2), 0.45)
			if f.claws or f.thumbSpikes then
				wedge("HandClaw", V(0.3,0.4,0.8), V(side*1.45,bodyY-armLength,-2.55), accent)
			end
		end
	end
	link("TailBase", V(0,bodyY,2), V(0,bodyY+0.1,4.5), 1.55)
	link("TailTip", V(0,bodyY+0.1,4.3), V(0,bodyY+0.35,7), 0.65)
	local headY, headZ = bodyY+1.4, -3
	local headScale = f.headScale or 1
	if family == "sauropod" then
		headY, headZ = bodyY+(f.neck or 5), -3.3
		link("TallNeck", V(0,bodyY+0.4,-1.8), V(0,headY,-3), 1.6)
		headScale = 0.75
	elseif quadruped then
		headY = bodyY+0.05
	elseif family == "pterosaur" then
		headY = bodyY+1.9
	else
		link("Neck", V(0,bodyY,-1.4), V(0,headY,-2.7), 1.6)
	end
	part("Head", V(2*headScale,1.8*headScale,2.6*headScale), V(0,headY,headZ))
	if f.longSnout or f.duckBill or f.beak then
		local length = if f.longSnout or f.beak then 2.5 else 1.6
		part("Muzzle", V(if f.duckBill then 2.1 else 1.1,0.75,length), V(0,headY-0.2,headZ-1.5), if f.beak then accent else base)
	end
	for _, side in {-1,1} do
		part("Eye", V(0.22,0.42,0.42), V(side*(headScale-0.03),headY+0.25,headZ-0.5), Color3.fromRGB(28,38,44))
		part("EyeGlint", V(0.08,0.1,0.1), V(side*(headScale+0.08),headY+0.33,headZ-0.57), Color3.fromRGB(245,242,221))
		if f.brows then part("Brow", V(0.4,0.5,0.8), V(side*0.85,headY+0.85,headZ-0.4), accent) end
		if f.horns then wedge("BrowHorn", V(0.45,1.7,0.7), V(side*0.7,headY+1.5,headZ-0.5), accent) end
		if f.shoulderSpikes then wedge("ShoulderSpike", V(1.7,0.7,0.7), V(side*2,bodyY+0.4,-1.2), accent, CFrame.Angles(0,0,side*math.rad(40))) end
	end
	if f.horns == 3 then wedge("NoseHorn", V(0.5,0.9,0.65), V(0,headY+0.8,headZ-1.2), accent) end
	if f.frill then
		local size = if f.smallFrill then 2.8 else 3.7
		part("Frill", V(size,size,0.6), V(0,headY+0.5,headZ+0.95), dark)
		if f.frillSpikes then
			for _, side in {-1,1} do wedge("FrillHorn", V(0.5,1.3,0.6), V(side*1.2,headY+2.2,headZ+0.95), accent) end
		end
	end
	if f.crest then wedge("Crest", V(0.6,1.5,1.4), V(0,headY+1.4,headZ+0.1), accent) end
	if f.sail then part("Sail", V(0.45,5.5,5), V(0,bodyY+2.2,0), accent) end
	if f.plates then
		for i=1,f.plates do
			local z = -1.8+(i-1)*0.85
			local height = if f.lowPlates then 1.1 else 1.9
			wedge("BackPlate", V(0.5,height,1.3), V(if i%2==0 then -0.3 else 0.3,bodyY+1.3+height/2,z), accent)
		end
	end
	if f.tailSpikes then
		for _, side in {-1,1} do
			link("TailSpike", V(0,bodyY+0.2,5.5), V(side*1.2,bodyY+1.3,6), 0.28, accent)
		end
	end
	if f.armor then
		for x=-1,1 do
			for z=-1,2 do part("Armor", V(1.1,0.7,1.1), V(x,bodyY+1.2,z), accent) end
		end
	end
	if f.backRidge or f.feathers then
		for i=1,4 do part("BackDetail", V(if f.feathers then 2.5 else 0.55,0.75,0.7), V(0,bodyY+1.25,-1.5+i*0.9), dark) end
	end
	if f.stripe then
		for _, side in {-1,1} do part("BlueStripe", V(0.16,0.55,4), V(side*1.36,bodyY+0.25,0), dark) end
	end
	if f.wings then
		for _, side in {-1,1} do
			wedge("Wing", V(3.7,0.22,4.2), V(side*2.6,bodyY+0.5,0), accent, CFrame.Angles(0,if side==1 then 0 else math.pi,0))
			link("WingLeadingEdge", V(side*0.6,bodyY+0.55,-1.5), V(side*4.45,bodyY+0.55,-1.5), 0.3, dark)
		end
		wedge("HeadCrest", V(0.45,1.3,2), V(0,headY+0.7,headZ+1.3), accent)
	end
	model:SetAttribute("GroundOffset", 0)
	return model
end

return Models
