local Players=game:GetService("Players")
local SoundService=game:GetService("SoundService")
local ContentProvider=game:GetService("ContentProvider")
local RunService=game:GetService("RunService")
local Settings=require(script.Parent.Settings)
local Controller={}
Controller.__index=Controller

--- Creates private audio instances and preloads them without blocking gameplay.
function Controller.new(cage)
    local folder=Instance.new("Folder")
    folder.Name="DinografiaAudio"
    folder.Parent=SoundService
    local group=Instance.new("SoundGroup")
    group.Name="Master"
    group.Volume=Settings.Levels[2]
    group.Parent=folder
    local self=setmetatable({Folder=folder,group=group,sounds={},volumes={},cage=cage,
        level=2,writingUntil=0,motor=false,lastGateY=cage.Gate.Position.Y,motionUntil=0,destroyed=false,connections={}},Controller)
    for _,template in ipairs(script.Parent.Objects:GetChildren()) do
        if template:IsA("Sound") then
            local sound=template:Clone()
            self.volumes[sound.Name]=sound.Volume
            sound.SoundGroup=group
            if sound.Name=="Motor" then
                sound.PlaybackRegionsEnabled=true
                sound.PlaybackRegion=NumberRange.new(8,10)
                sound.LoopRegion=NumberRange.new(8,10)
            end
            if sound.Looped then sound.Volume=0 end
            sound.Parent=folder
            self.sounds[sound.Name]=sound
            sound:SetAttribute("LoadState","Loading")
            sound:SetAttribute("PeakLoudness",0)
            if RunService:IsStudio() and not sound.Looped then
                table.insert(self.connections,sound.Ended:Connect(function()
                    print("[Dinografia audio] Ended "..sound.Name.."; source peak="..tostring(sound:GetAttribute("PeakLoudness")))
                end))
            end
            task.spawn(function()
                local ok=pcall(function()
                    ContentProvider:PreloadAsync({sound})
                end)
                if self.destroyed then return end
                local loaded=sound.IsLoaded
                sound:SetAttribute("LoadState",if loaded then "Ready" else "Unavailable")
                if not ok or not loaded then
                    warn("[Dinografia audio] "..sound.Name.." nao carregou ("..sound.SoundId.."); confira a permissao do asset na experiencia.")
                elseif RunService:IsStudio() then
                    print("[Dinografia audio] "..sound.Name.." carregado; duracao "..string.format("%.2f",sound.TimeLength).." s.")
                end
            end)
        end
    end
    self:AttachCage(cage)
    return self
end

--- Reuses the player's audio settings when moving to another letter station.
function Controller:AttachCage(cage)
    if self.cageConnection then self.cageConnection:Disconnect() end
    for _,sound in pairs(self.sounds) do sound:Stop() end
    self.cage=cage
    self.lastGateY=cage.Gate.Position.Y
    self.motionUntil=0
    self.writingUntil=0
    local previous=cage:GetAttribute("DoorState")
    self.motor=previous=="Opening" or previous=="Closing"
    self.cageConnection=cage:GetAttributeChangedSignal("DoorState"):Connect(function()
        local state=cage:GetAttribute("DoorState")
        self.motor=state=="Opening" or state=="Closing"
        if state=="Signalling" then self:Play("Beacon")
        elseif state=="Open" and previous~="Open" then self:Play("Blue") end
        previous=state
    end)
end
--- Plays a single cue without allowing copies of it to stack.
function Controller:Play(name)
    local sound=self.sounds[name]
    if self.destroyed or not sound or self.level==1 then return end
    if not sound.IsLoaded then
        if not sound:GetAttribute("WarnedNotReady") then
            sound:SetAttribute("WarnedNotReady",true)
            warn("[Dinografia audio] "..name.." solicitado antes de carregar; consulte LoadState no objeto de som.")
        end
        return
    end
    sound:SetAttribute("LoadState","Ready")
    sound:SetAttribute("PeakLoudness",0)
    sound:SetAttribute("PlayCount",(sound:GetAttribute("PlayCount") or 0)+1)
    if RunService:IsStudio() then print("[Dinografia audio] Playing "..name) end
    sound:Stop()
    sound:Play()
end

--- Keeps painting audible only while validated progress is arriving.
function Controller:Writing(advancing)
    self.writingUntil=if advancing then os.clock()+0.18 else 0
end

--- Cycles between mute, quiet and normal volume for this player only.
function Controller:CycleVolume()
    self.level=self.level%#Settings.Levels+1
    self.group.Volume=Settings.Levels[self.level]
    if self.level==1 then
        for _,sound in pairs(self.sounds) do sound:Stop() end
    end
    return Settings.Labels[self.level]
end

--- Fades a loop in and out without restarting it for each input sample.
function Controller:Loop(name,active,dt,gain)
    local sound=self.sounds[name]
    if not sound then return end
    local target=if active and self.level~=1 then self.volumes[name]*gain else 0
    local fade=if name=="Motor" then 0.025 else 0.06
    sound.Volume+=(target-sound.Volume)*(1-math.exp(-dt/fade))
    if target>0 and sound.IsLoaded and not sound.IsPlaying then
        if name=="Motor" then sound.TimePosition=8 end
        sound:Play()
    elseif target==0 and sound.Volume<0.001 then sound:Stop();sound.Volume=0 end
end

--- Matches motor audio to visible gate motion with attenuation independent of camera cuts.
function Controller:Step(dt)
    if self.destroyed then return end
    local character=Players.LocalPlayer.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local gain=1
    if root then
        local distance=(root.Position-self.cage.FrontBeam.Position).Magnitude
        gain=math.clamp(1-(distance-35)/80,0,1)
    end
    local gateY=self.cage.Gate.Position.Y
    if math.abs(gateY-self.lastGateY)>0.00001 then self.motionUntil=os.clock()+0.08 end
    self.lastGateY=gateY
    self:Loop("Paint",os.clock()<self.writingUntil,dt,1)
    self:Loop("Motor",self.motor and os.clock()<self.motionUntil,dt,gain)
    for _,name in ipairs({"Beacon","Blue"}) do
        local sound=self.sounds[name]
        if sound then
            local cueGain=if name=="Blue" then math.clamp(gain*3,0,1) else math.min(1,gain*1.2)
            sound.Volume=self.volumes[name]*cueGain
        end
    end
    if RunService:IsStudio() then
        for _,sound in pairs(self.sounds) do
            if sound.IsPlaying then
                sound:SetAttribute("PeakLoudness",math.max(sound:GetAttribute("PeakLoudness") or 0,sound.PlaybackLoudness))
            end
        end
    end
end

--- Disposes all local sound objects and subscriptions.
function Controller:Destroy()
    if self.destroyed then return end
    self.destroyed=true
    if self.cageConnection then self.cageConnection:Disconnect() end
    for _,connection in ipairs(self.connections) do connection:Disconnect() end
    self.Folder:Destroy()
end
return Controller