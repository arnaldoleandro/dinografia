-- Uppercase paths use normalized panel coordinates and explicit pen-lift boundaries.
local Alphabet = { Letters = {}, ByLetter = {} }
-- Convert compact coordinate pairs into immutable guide points.
local function points(values)
 local result = {}
 for i=1,#values,2 do table.insert(result,table.freeze({x=values[i],y=values[i+1]})) end
 return table.freeze(result)
end
-- Register a glyph in alphabetical order.
local function add(letter, ...)
 local strokes = {}
 for _, values in ipairs({...}) do table.insert(strokes,points(values)) end
 local entry=table.freeze({letter=letter,strokes=table.freeze(strokes)})
 table.insert(Alphabet.Letters,entry); Alphabet.ByLetter[letter]=entry
end
add('A',{.2,.82,.5,.18,.8,.82},{.34,.53,.66,.53})
add('B',{.25,.82,.25,.18},{.25,.18,.53,.18,.66,.22,.72,.30,.69,.40,.58,.48,.25,.48},{.25,.48,.58,.48,.72,.55,.76,.65,.72,.76,.59,.82,.25,.82})
add('C',{.77,.27,.66,.20,.5,.18,.35,.23,.25,.35,.22,.5,.25,.66,.35,.78,.5,.82,.66,.8,.77,.73})
add('D',{.25,.82,.25,.18},{.25,.18,.48,.18,.63,.23,.74,.35,.78,.5,.74,.65,.63,.77,.48,.82,.25,.82})
add('E',{.76,.18,.25,.18,.25,.82,.76,.82},{.25,.49,.67,.49})
add('F',{.25,.82,.25,.18,.76,.18},{.25,.49,.67,.49})
add('G',{.77,.28,.65,.20,.5,.18,.35,.23,.25,.35,.22,.5,.25,.66,.35,.78,.5,.82,.66,.8,.77,.73,.77,.52,.53,.52})
add('H',{.25,.18,.25,.82},{.75,.18,.75,.82},{.25,.5,.75,.5})
add('I',{.25,.18,.75,.18},{.5,.18,.5,.82},{.25,.82,.75,.82})
add('J',{.3,.18,.75,.18},{.65,.18,.65,.66,.61,.76,.52,.82,.4,.82,.3,.76,.25,.65})
add('K',{.25,.18,.25,.82},{.77,.18,.25,.53,.78,.82})
add('L',{.25,.18,.25,.82,.76,.82})
add('M',{.19,.82,.19,.18,.5,.58,.81,.18,.81,.82})
add('N',{.25,.82,.25,.18,.75,.82,.75,.18})
add('O',{.5,.18,.35,.22,.25,.34,.21,.5,.25,.66,.35,.78,.5,.82,.65,.78,.75,.66,.79,.5,.75,.34,.65,.22,.5,.18})
add('P',{.25,.82,.25,.18},{.25,.18,.55,.18,.69,.23,.75,.33,.72,.45,.6,.52,.25,.52})
add('Q',{.5,.18,.35,.22,.25,.34,.21,.5,.25,.66,.35,.78,.5,.82,.65,.78,.75,.66,.79,.5,.75,.34,.65,.22,.5,.18},{.57,.64,.82,.86})
add('R',{.25,.82,.25,.18},{.25,.18,.55,.18,.69,.23,.75,.33,.72,.45,.6,.52,.25,.52},{.52,.52,.78,.82})
add('S',{.76,.26,.65,.2,.48,.18,.34,.22,.25,.3,.25,.4,.35,.47,.63,.55,.73,.62,.75,.71,.66,.79,.5,.82,.35,.8,.24,.73})
add('T',{.2,.18,.8,.18},{.5,.18,.5,.82})
add('U',{.25,.18,.25,.64,.29,.75,.38,.81,.5,.83,.62,.81,.71,.75,.75,.64,.75,.18})
add('V',{.2,.18,.5,.82,.8,.18})
add('W',{.15,.18,.31,.82,.5,.4,.69,.82,.85,.18})
add('X',{.23,.18,.77,.82},{.77,.18,.23,.82})
add('Y',{.22,.18,.5,.5,.78,.18},{.5,.5,.5,.82})
add('Z',{.23,.18,.77,.18,.23,.82,.77,.82})
-- Resolve a supported uppercase letter without changing its definition.
function Alphabet.Get(letter) return Alphabet.ByLetter[letter] end
table.freeze(Alphabet.Letters); table.freeze(Alphabet.ByLetter)
return table.freeze(Alphabet)
