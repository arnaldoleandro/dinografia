local Cage=require(script.Parent.Cage)
local shared=game:GetService("ReplicatedStorage").Dinografia
local Catalog=require(shared.DinosaurCatalog)
local Layout=require(shared.AvenueLayout)
local World={}
--- Creates an anchored avenue structure.
local function part(parent,name,size,cf,color)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color
 p.Anchored=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent
 return p
end
--- Places a readable sign on the front of a fixed structure.
local function sign(p,text)
 local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(1000,160);gui.Parent=p
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
 label.Text=text;label.TextColor3=Color3.fromRGB(255,235,185);label.TextScaled=true;label.Font=Enum.Font.GothamBold;label.Parent=gui
end
--- Builds the ordered avenue and returns its server-owned cage controllers.
function World.Build()
 local scenery=Instance.new("Folder");scenery.Name="Avenue";scenery.Parent=workspace
 local stations=Instance.new("Folder");stations.Name="AlphabetStations";stations.Parent=workspace
 part(scenery,"Ground",Vector3.new(160,2,1040),CFrame.new(0,-1,440),Color3.fromRGB(105,145,99))
 part(scenery,"Promenade",Vector3.new(34,.1,980),CFrame.new(0,.05,430),Color3.fromRGB(195,181,145))
 for _,x in ipairs({-79,79}) do part(scenery,"Boundary",Vector3.new(2,5,1040),CFrame.new(x,2.5,440),Color3.fromRGB(69,98,84)) end
 for _,z in ipairs({-79,959}) do part(scenery,"Boundary",Vector3.new(160,5,2),CFrame.new(0,2.5,z),Color3.fromRGB(69,98,84)) end
 local spawn=Instance.new("SpawnLocation");spawn.Name="AvenueSpawn";spawn.Size=Vector3.new(10,.3,10)
 spawn.CFrame=CFrame.new(0,.2,-25);spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=scenery
 local intro=part(scenery,"Welcome",Vector3.new(25,5,1),CFrame.new(0,8,-55)*CFrame.Angles(0,math.pi,0),Color3.fromRGB(46,75,70))
 sign(intro,"DINOGRAFIA • A → Z\nSiga as letras e reúna sua coleção")
 local result={}
 for index,entry in ipairs(Catalog.Entries) do
  local position=Layout.Get(index)
  local cf=CFrame.new(position.x,0,position.z)*CFrame.Angles(0,position.yaw,0)
  local cage=Cage.new({Letter=entry.letter,Name=entry.name,Index=index,CFrame=cf,Parent=stations})
  cage.Model:SetAttribute("StationCFrame",cf)
  local title=part(cage.Model,"Title",Vector3.new(24,3,1),cf*CFrame.new(0,32,-16),Color3.fromRGB(46,75,70))
  sign(title,entry.letter.." — "..entry.name)
  result[entry.letter]=cage
 end
 local exit=part(scenery,"Exit",Vector3.new(30,.2,20),CFrame.new(0,.15,Layout.ExitZ),Color3.fromRGB(87,175,137))
 exit.CanCollide=false;exit.CanTouch=false
 local exitSign=part(scenery,"ExitSign",Vector3.new(30,5,1),CFrame.new(0,12,Layout.ExitZ+15),Color3.fromRGB(46,75,70))
 sign(exitSign,"SAÍDA • 26 descobertas\nSua coleção chega com você!")
 return result
end
return World
