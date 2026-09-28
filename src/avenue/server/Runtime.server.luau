local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local shared=ReplicatedStorage:WaitForChild("Dinografia")
local Catalog=require(shared.DinosaurCatalog)
local Trace=require(shared.LetterTrace)
local Journey=require(shared.JourneyProgress)
local Layout=require(shared.AvenueLayout)
local Config=require(shared.Config)
local Cycle=require(shared.DoorCycle)
local Models=require(script.Parent.DinosaurModels)
local templates=Instance.new("Folder");templates.Name="DinosaurTemplates"
for _,entry in ipairs(Catalog.Entries) do
 local model=Models.Create(entry);model.Name=entry.letter;model.Parent=templates
end
templates.Parent=ReplicatedStorage
local cages=require(script.Parent.World).Build()
local remote=Instance.new("RemoteEvent");remote.Name="Activity";remote.Parent=shared
local journeys,sessions,requests,connections={},{},{},{}
--- Publishes only the collection state earned by validated activities.
local function publish(player)
 local journey=journeys[player]
 player:SetAttribute("CollectedCount",journey.count)
 player:SetAttribute("NextLetter",journey:GetNextLetter() or "")
end
--- Starts a personal session without persisting prototype progress between servers.
local function join(player)
 journeys[player]=Journey.new();publish(player);player:SetAttribute("JourneyFinished",false)
 connections[player]=player.CharacterAdded:Connect(function() sessions[player]=nil end)
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(player)
 if connections[player] then connections[player]:Disconnect() end
 connections[player],journeys[player],sessions[player],requests[player]=nil,nil,nil,nil
end)
for _,player in ipairs(Players:GetPlayers()) do join(player) end
--- Requires a living avatar near the selected writing panel.
local function near(player,cage)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 return humanoid and humanoid.Health>0 and root and (root.Position-cage.Panel.Position).Magnitude<=Config.ActivityDistance
end
--- Validates each stroke and consumes its token before opening a shared door.
local function activity(player,action,value,samples)
 if action~="begin" and action~="complete" and action~="cancel" then return end
 local journey=journeys[player];if not journey then return end
 local now=os.clock();local recent=requests[player] or {};requests[player]=recent
 if now-(recent[action] or -math.huge)<.35 then return end;recent[action]=now
 if action=="begin" then
  if type(value)~="string" or not cages[value] then return end
  local cage=cages[value];local index=cage.Model:GetAttribute("StationIndex")
  if not journey:CanAttempt(index) then remote:FireClient(player,"error","Siga a avenida: a próxima letra é "..(journey:GetNextLetter() or "Z")..".");return end
  if not near(player,cage) then remote:FireClient(player,"error","Chegue mais perto da letra.");return end
  if not Cycle.CanWrite(cage.Model:GetAttribute("DoorState")) then remote:FireClient(player,"error","Espere a porta fechar para repetir.");return end
  local session={token=HttpService:GenerateGUID(false),letter=value,character=player.Character,time=now}
  sessions[player]=session;remote:FireClient(player,"ready",session.token,value);return
 end
 local session=sessions[player]
 if not session or type(value)~="string" or value~=session.token then return end
 if action=="cancel" then sessions[player]=nil;return end
 local cage=cages[session.letter]
 if session.character~=player.Character or now-session.time>300 or not near(player,cage) then
  sessions[player]=nil;remote:FireClient(player,"error","Aproxime-se da letra para tentar novamente.",value);return
 end
 if not Cycle.CanWrite(cage.Model:GetAttribute("DoorState")) then
  sessions[player]=nil;remote:FireClient(player,"error","A porta está em movimento. Espere ela fechar.",value);return
 end
 if not Trace.Validate(samples,session.letter,Config.AlphabetTraceTolerance,4096) then
  remote:FireClient(player,"error","Pinte um pouco mais nas partes que faltam.",value);return
 end
 sessions[player]=nil
 remote:FireClient(player,"complete",value)
 cage:Open(function()
  if journeys[player]~=journey then return end
  journey:Collect(cage.Model:GetAttribute("StationIndex"));publish(player)
 end)
end
remote.OnServerEvent:Connect(activity)
task.spawn(function()
 while true do
  task.wait(.5)
  for player,journey in pairs(journeys) do
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if journey:IsComplete() and root and math.abs(root.Position.X)<17 and math.abs(root.Position.Z-Layout.ExitZ)<12 and math.abs(root.Position.Y)<12 and not player:GetAttribute("JourneyFinished") then
    player:SetAttribute("JourneyFinished",true);remote:FireClient(player,"journeyComplete")
   end
  end
 end
end)
print("[Dinografia] Avenida A–Z pronta: 26 letras, coleção pessoal e portas reutilizáveis.")
