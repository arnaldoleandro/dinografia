-- Adaptado do construtor presente no cenário exportado; fonte original preservada no RBXL.
return function()
-- Jurassic Paddock Builder (ServerScriptService) - FIXED
local TweenService = game:GetService("TweenService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local random = Random.new(260925) -- Mesmo cenário em cada teste.
local function isActivityArea(x, z)
	-- Reserva spawn, caminho de saída e toda a jaula, inclusive a cauda de Blue.
	return math.abs(x) <= 24 and z >= -20 and z <= 64
end

-- =========================
-- CONFIGS
-- =========================
local AVATAR_HEIGHT = 6
local GATE_HEIGHT = AVATAR_HEIGHT * 8      -- ~48
local GATE_WIDTH_TOTAL = 40
local GATE_THICKNESS = 3

local WALL_LINE_Z = -180                   -- empurra mais pra frente (mais espaço)
local GATE_CENTER_X = 0

local BUTTON_HEAD_HEIGHT = 5

-- Mundo (quadrado)
local PADDOCK_HALF_SIZE = 250              -- “quadrado grande” (500x500)
local TERRAIN_HEIGHT = 24                  -- espessura vertical do terreno
local TERRAIN_TOP_Y = 0                    -- topo do terreno no nível do chão

-- Densidades
local GRASS_TUFT_COUNT = 180               -- menos mato
local TREE_COUNT = 35

-- Cerca
local FENCE_SEGMENT_LENGTH = 12
local FENCE_HEIGHT = 14
local FENCE_POST_THICK = 0.6
local FENCE_MESH_THICK = 0.15

-- Organização
local folder = workspace:FindFirstChild("JurassicPaddock")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "JurassicPaddock"
folder.Parent = workspace

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = folder
	return p
end

-- =========================
-- TERRENO (topo no Y=0)
-- =========================
local function buildTerrain()
	if not Terrain then
		Terrain = Instance.new("Terrain")
		Terrain.Parent = workspace
	end
	Terrain:Clear()

	-- Centro do bloco de terreno calculado para o topo bater em TERRAIN_TOP_Y
	-- topo = centerY + height/2  => centerY = topo - height/2
	local centerY = TERRAIN_TOP_Y - (TERRAIN_HEIGHT / 2)

	local size = Vector3.new(PADDOCK_HALF_SIZE * 2, TERRAIN_HEIGHT, PADDOCK_HALF_SIZE * 2)
	local center = Vector3.new(0, centerY, 0)

	Terrain:FillBlock(CFrame.new(center), size, Enum.Material.Grass)

	-- Talude/parede atrás do portão (bem de leve)
	Terrain:FillBlock(
		CFrame.new(0, centerY + 6, WALL_LINE_Z - 25),
		Vector3.new(PADDOCK_HALF_SIZE * 2, 12, 45),
		Enum.Material.Rock
	)
end

-- =========================
-- MATO BAIXO (em área limitada)
-- =========================
local function scatterGrassTufts()
	for i = 1, GRASS_TUFT_COUNT do
		local x = random:NextInteger(-PADDOCK_HALF_SIZE + 10, PADDOCK_HALF_SIZE - 10)
		local z = random:NextInteger(-PADDOCK_HALF_SIZE + 10, PADDOCK_HALF_SIZE - 10)
		if isActivityArea(x, z) then continue end

		-- evita a área do portão
		if math.abs(z - WALL_LINE_Z) < 30 and math.abs(x - GATE_CENTER_X) < 90 then
			continue
		end

		local tuft = makePart({
			Name = "GrassTuft",
			Material = Enum.Material.Grass,
			Color = Color3.fromRGB(60, 140, 60),
			Size = Vector3.new(random:NextInteger(1, 3), random:NextInteger(1, 2), random:NextInteger(1, 3)),
			Position = Vector3.new(x, 0.5, z), -- agora o topo do terreno está em y=0
			CanCollide = false
		})
		tuft.Orientation = Vector3.new(0, random:NextInteger(0, 360), 0)
	end
end

-- =========================
-- ÁRVORES (simples, em área limitada)
-- =========================
local function createTree(pos)
	local trunkH = random:NextInteger(14, 22)

	local trunk = makePart({
		Name = "TreeTrunk",
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(101, 67, 33),
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(trunkH, 2, 2),
		Orientation = Vector3.new(0, 0, 90),
		Position = pos + Vector3.new(0, trunkH/2, 0),
		CanCollide = true
	})
	-- O eixo longitudinal do Cylinder é X; a rotação acima o coloca em pé.

	local crownSize = random:NextInteger(10, 16)
	makePart({
		Name = "TreeLeaves",
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(45, 120, 55),
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(crownSize, crownSize, crownSize),
		Position = trunk.Position + Vector3.new(0, trunkH/2 + (crownSize/3), 0),
		CanCollide = false
	})
end

local function scatterTrees()
	for i = 1, TREE_COUNT do
		local x = random:NextInteger(-PADDOCK_HALF_SIZE + 20, PADDOCK_HALF_SIZE - 20)
		local z = random:NextInteger(-PADDOCK_HALF_SIZE + 20, PADDOCK_HALF_SIZE - 20)
		if isActivityArea(x, z) then continue end

		-- clareira do portão
		if math.abs(z - WALL_LINE_Z) < 80 and math.abs(x - GATE_CENTER_X) < 150 then
			continue
		end

		createTree(Vector3.new(x, 0, z))
	end
end

-- =========================
-- CERCA ALAMBRADO (segmento)
-- =========================
local function createFenceSegment(p0, p1)
	local dir = (p1 - p0)
	local length = dir.Magnitude
	if length < 0.1 then return end
	makePart({
		Name = "FencePost",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(90, 90, 90),
		Size = Vector3.new(FENCE_POST_THICK, FENCE_HEIGHT, FENCE_POST_THICK),
		Position = p0 + Vector3.new(0, FENCE_HEIGHT/2, 0),
		CanCollide = true
	})

	makePart({
		Name = "FencePost",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(90, 90, 90),
		Size = Vector3.new(FENCE_POST_THICK, FENCE_HEIGHT, FENCE_POST_THICK),
		Position = p1 + Vector3.new(0, FENCE_HEIGHT/2, 0),
		CanCollide = true
	})

	local mesh = makePart({
		Name = "FenceMesh",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(130, 130, 130),
		Size = Vector3.new(length, FENCE_HEIGHT - 2, FENCE_MESH_THICK),
		CFrame = CFrame.new((p0 + p1)/2 + Vector3.new(0, FENCE_HEIGHT/2, 0)) * CFrame.Angles(0, math.atan2(-dir.Z, dir.X), 0),
		CanCollide = true
	})
	mesh.Transparency = 0.25
end

-- =========================
-- CERCA PERIMETRAL QUADRADA com vão do portão
-- =========================
local function buildPerimeterFence()
	local hs = PADDOCK_HALF_SIZE
	local zSouth = WALL_LINE_Z           -- lado do portão (sul)
	local zNorth = hs
	local xWest  = -hs
	local xEast  = hs

	-- define o vão do portão na cerca sul
	local gapMinX = GATE_CENTER_X - (GATE_WIDTH_TOTAL/2) - 12
	local gapMaxX = GATE_CENTER_X + (GATE_WIDTH_TOTAL/2) + 12

	-- Norte (linha inteira)
	for x = xWest, xEast - FENCE_SEGMENT_LENGTH, FENCE_SEGMENT_LENGTH do
		createFenceSegment(Vector3.new(x, 0, zNorth), Vector3.new(x + FENCE_SEGMENT_LENGTH, 0, zNorth))
	end

	-- Oeste (linha inteira)
	for z = zSouth, zNorth - FENCE_SEGMENT_LENGTH, FENCE_SEGMENT_LENGTH do
		createFenceSegment(Vector3.new(xWest, 0, z), Vector3.new(xWest, 0, z + FENCE_SEGMENT_LENGTH))
	end

	-- Leste (linha inteira)
	for z = zSouth, zNorth - FENCE_SEGMENT_LENGTH, FENCE_SEGMENT_LENGTH do
		createFenceSegment(Vector3.new(xEast, 0, z), Vector3.new(xEast, 0, z + FENCE_SEGMENT_LENGTH))
	end

	-- Sul (com gap)
	-- parte esquerda do sul
	for x = xWest, math.floor(gapMinX - FENCE_SEGMENT_LENGTH), FENCE_SEGMENT_LENGTH do
		createFenceSegment(Vector3.new(x, 0, zSouth), Vector3.new(x + FENCE_SEGMENT_LENGTH, 0, zSouth))
	end
	-- parte direita do sul
	for x = math.ceil(gapMaxX), xEast - FENCE_SEGMENT_LENGTH, FENCE_SEGMENT_LENGTH do
		createFenceSegment(Vector3.new(x, 0, zSouth), Vector3.new(x + FENCE_SEGMENT_LENGTH, 0, zSouth))
	end
end

-- =========================
-- PORTÃO PADDOCK (2 folhas grossas)
-- =========================
local function buildGate()
	makePart({
		Name = "GatePillarL",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(70, 70, 70),
		Size = Vector3.new(6, GATE_HEIGHT + 10, 6),
		Position = Vector3.new(GATE_CENTER_X - (GATE_WIDTH_TOTAL/2) - 4, (GATE_HEIGHT + 10)/2, WALL_LINE_Z),
		CanCollide = true
	})

	makePart({
		Name = "GatePillarR",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(70, 70, 70),
		Size = Vector3.new(6, GATE_HEIGHT + 10, 6),
		Position = Vector3.new(GATE_CENTER_X + (GATE_WIDTH_TOTAL/2) + 4, (GATE_HEIGHT + 10)/2, WALL_LINE_Z),
		CanCollide = true
	})

	makePart({
		Name = "GateTopBeam",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(60, 60, 60),
		Size = Vector3.new(GATE_WIDTH_TOTAL + 20, 4, 6),
		Position = Vector3.new(GATE_CENTER_X, GATE_HEIGHT + 8, WALL_LINE_Z),
		CanCollide = true
	})

	local leafWidth = (GATE_WIDTH_TOTAL / 2)

	local leafL = makePart({
		Name = "GateLeafL",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(45, 45, 45),
		Size = Vector3.new(leafWidth, GATE_HEIGHT, GATE_THICKNESS),
		Position = Vector3.new(GATE_CENTER_X - (leafWidth/2), (GATE_HEIGHT/2), WALL_LINE_Z),
		CanCollide = true
	})

	local leafR = makePart({
		Name = "GateLeafR",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(45, 45, 45),
		Size = Vector3.new(leafWidth, GATE_HEIGHT, GATE_THICKNESS),
		Position = Vector3.new(GATE_CENTER_X + (leafWidth/2), (GATE_HEIGHT/2), WALL_LINE_Z),
		CanCollide = true
	})

	return leafL, leafR
end

-- =========================
-- BOTÃO: placa cinza + botão circular vermelho CENTRALIZADO e VISÍVEL
-- =========================
local function buildButton()
	local plate = makePart({
		Name = "ControlPlate",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(120, 120, 120),
		Size = Vector3.new(6, 6, 0.6),
		Position = Vector3.new(GATE_CENTER_X + (GATE_WIDTH_TOTAL/2) + 14, BUTTON_HEAD_HEIGHT, WALL_LINE_Z + 6),
		CanCollide = true
	})

	-- botão como “puck” saindo da placa
	local buttonDepth = 1.0
	local button = makePart({
		Name = "RedButton",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(220, 0, 0),
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(buttonDepth, 1.8, 1.8), -- X é o eixo longitudinal.
		CanCollide = false
	})

	-- coloca centralizado e para fora (frente) da placa
	-- Para apontar para a frente, rotaciona o eixo X do cilindro até Z.
	button.CFrame =
		plate.CFrame
		* CFrame.new(0, 0, (plate.Size.Z/2) + (buttonDepth/2) + 0.02)
		* CFrame.Angles(0, math.rad(90), 0)

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 20
	cd.Parent = button

	return cd
end

-- =========================
-- ABRIR/FECHAR (Tween)
-- =========================
local function wireGateButton(clickDetector, leafL, leafR)
	local isOpen = false
	local busy = false
	local closedL, closedR = leafL.Position, leafR.Position
	local move = (GATE_WIDTH_TOTAL/2) + 8

	local function openGate()
		local tinfo = TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(leafL, tinfo, {Position = closedL + Vector3.new(-move, 0, 0)}):Play()
		TweenService:Create(leafR, tinfo, {Position = closedR + Vector3.new(move, 0, 0)}):Play()
	end

	local function closeGate()
		local tinfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(leafL, tinfo, {Position = closedL}):Play()
		TweenService:Create(leafR, tinfo, {Position = closedR}):Play()
	end

	clickDetector.MouseClick:Connect(function(player)
		if busy then return end
		busy = true
		task.delay(1.5, function() busy = false end)
		if not isOpen then openGate() else closeGate() end
		isOpen = not isOpen
	end)
end

-- =========================
-- EXECUÇÃO
-- =========================
buildTerrain()
scatterGrassTufts()
scatterTrees()
buildPerimeterFence()

local leafL, leafR = buildGate()
local cd = buildButton()
wireGateButton(cd, leafL, leafR)
end
