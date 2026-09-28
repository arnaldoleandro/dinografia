local Catalog = { Entries = {}, ByLetter = {} }

-- Registers one immutable, engine-independent entry in alphabetical order.
local function add(letter, name, family, color, features, classification)
	local entry = table.freeze({ letter = letter, name = name, family = family, color = table.freeze(color), features = table.freeze(features), classification = classification or "Dinossauro", modelKind = "original-procedural" })
	table.insert(Catalog.Entries, entry)
	Catalog.ByLetter[letter] = entry
end

add("A", "Alossauro", "theropod", { 98, 150, 123 }, { brows = true, headScale = 1.05 })
add("B", "Braquiossauro", "sauropod", { 110, 154, 178 }, { neck = 6, shoulders = true })
add("C", "Carnotauro", "theropod", { 186, 111, 88 }, { horns = 2, shortArms = true })
add("D", "Dimetrodon", "synapsid", { 137, 151, 95 }, { sail = true }, "Sinapsídeo; não é dinossauro")
add("E", "Estegossauro", "stegosaur", { 116, 158, 128 }, { plates = 6, tailSpikes = true })
add("F", "Fukuiraptor", "theropod", { 111, 151, 170 }, { claws = true, headScale = 0.85 })
add("G", "Giganotossauro", "theropod", { 148, 132, 174 }, { backRidge = true, headScale = 1.25 })
add("H", "Hadrossauro", "hadrosaur", { 177, 159, 99 }, { duckBill = true })
add("I", "Iguanodon", "hadrosaur", { 101, 151, 137 }, { thumbSpikes = true })
add("J", "Jobaria", "sauropod", { 174, 151, 117 }, { neck = 4.7 })
add("K", "Kentrossauro", "stegosaur", { 140, 155, 94 }, { plates = 3, tailSpikes = true, shoulderSpikes = true })
add("L", "Lambeossauro", "hadrosaur", { 173, 125, 151 }, { duckBill = true, crest = true })
add("M", "Megalossauro", "theropod", { 158, 137, 109 }, { headScale = 1.1, claws = true })
add("N", "Nodossauro", "armored", { 125, 142, 114 }, { armor = true, shoulderSpikes = true })
add("O", "Oviraptor", "raptor", { 173, 145, 107 }, { crest = true, feathers = true, beak = true })
add("P", "Pteranodon", "pterosaur", { 116, 158, 175 }, { wings = true, beak = true }, "Pterossauro; não é dinossauro")
add("Q", "Qianzhousaurus", "theropod", { 168, 136, 145 }, { longSnout = true, headScale = 0.85 })
add("R", "Rex (Tyrannosaurus rex)", "theropod", { 129, 151, 98 }, { headScale = 1.4, shortArms = true })
add("S", "Suchomimus", "theropod", { 98, 146, 164 }, { longSnout = true, backRidge = true })
add("T", "Triceratops", "ceratopsian", { 179, 134, 92 }, { horns = 3, frill = true })
add("U", "Utahraptor", "raptor", { 157, 121, 161 }, { feathers = true, claws = true })
add("V", "Velociraptor", "raptor", { 101, 154, 183 }, { claws = true, stripe = true })
add("W", "Wuerhosaurus", "stegosaur", { 139, 167, 128 }, { plates = 5, lowPlates = true, tailSpikes = true })
add("X", "Xenoceratops", "ceratopsian", { 164, 132, 162 }, { horns = 2, frill = true, frillSpikes = true })
add("Y", "Yutyrannus", "theropod", { 174, 160, 128 }, { feathers = true, headScale = 1.15 })
add("Z", "Zuniceratops", "ceratopsian", { 114, 160, 146 }, { horns = 2, frill = true, smallFrill = true })

table.freeze(Catalog.Entries)
table.freeze(Catalog.ByLetter)
return table.freeze(Catalog)
