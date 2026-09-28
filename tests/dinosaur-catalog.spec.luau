local Catalog = require("../src/shared/DinosaurCatalog")
local passed = 0

-- Executes one catalog invariant and reports a readable failure.
local function test(name, fn)
	local ok, result = pcall(fn)
	assert(ok, name .. ": " .. tostring(result))
	passed += 1
	print("PASS", name)
end

test("catalog has exactly one ordered species for every A-Z letter", function()
	assert(#Catalog.Entries == 26)
	for i, entry in Catalog.Entries do
		assert(entry.letter == string.char(64+i))
		assert(Catalog.ByLetter[entry.letter] == entry)
	end
end)

test("first requested animal is preserved for every letter", function()
	local expected = { "Alossauro", "Braquiossauro", "Carnotauro", "Dimetrodon", "Estegossauro", "Fukuiraptor", "Giganotossauro", "Hadrossauro", "Iguanodon", "Jobaria", "Kentrossauro", "Lambeossauro", "Megalossauro", "Nodossauro", "Oviraptor", "Pteranodon", "Qianzhousaurus", "Rex (Tyrannosaurus rex)", "Suchomimus", "Triceratops", "Utahraptor", "Velociraptor", "Wuerhosaurus", "Xenoceratops", "Yutyrannus", "Zuniceratops" }
	for i, name in expected do assert(Catalog.Entries[i].name == name) end
end)

test("all catalog models have supported silhouettes and safe RGB colors", function()
	local supported = { theropod=true, sauropod=true, synapsid=true, stegosaur=true, hadrosaur=true, armored=true, raptor=true, pterosaur=true, ceratopsian=true }
	for _, entry in Catalog.Entries do
		assert(supported[entry.family])
		assert(entry.modelKind == "original-procedural")
		assert(#entry.color == 3)
		for _, channel in entry.color do assert(channel >= 0 and channel <= 255 and channel%1 == 0) end
		assert(type(entry.features) == "table")
	end
end)

test("non-dinosaur animals carry an explicit educational classification", function()
	assert(Catalog.ByLetter.D.classification == "Sinapsídeo; não é dinossauro")
	assert(Catalog.ByLetter.P.classification == "Pterossauro; não é dinossauro")
	for _, entry in Catalog.Entries do
		if entry.letter ~= "D" and entry.letter ~= "P" then assert(entry.classification == "Dinossauro") end
	end
end)

test("catalog cannot be mutated by a consumer", function()
	assert(not pcall(function() Catalog.ByLetter.A.name = "Changed" end))
	assert(not pcall(function() Catalog.ByLetter.V.features.claws = false end))
	assert(not pcall(function() Catalog.Entries[1] = nil end))
	assert(not pcall(function() Catalog.ByLetter.A.color[1] = 0 end))
end)

print(string.format("%d dinosaur catalog tests passed", passed))
