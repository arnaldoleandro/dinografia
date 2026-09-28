local Players=game:GetService("Players")
local Catalog=require(game:GetService("ReplicatedStorage"):WaitForChild("Dinografia").DinosaurCatalog)
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="DinosaurCollection";gui.ResetOnSpawn=false;gui.DisplayOrder=25;gui.IgnoreGuiInset=true
local button=Instance.new("TextButton");button.Size=UDim2.fromOffset(146,40);button.Position=UDim2.new(1,-162,0,164)
button.Text="Minha coleção";button.TextSize=16;button.Font=Enum.Font.GothamMedium;button.Parent=gui
local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
panel.Size=UDim2.fromScale(.85,.72);panel.Visible=false;panel.Parent=gui
local constraint=Instance.new("UISizeConstraint");constraint.MaxSize=Vector2.new(640,620);constraint.Parent=panel
local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-55,0,48);title.BackgroundTransparency=1
 title.Text="Coleção de animais pré-históricos";title.TextScaled=true;title.Font=Enum.Font.GothamBold;title.Parent=panel
local close=Instance.new("TextButton");close.Size=UDim2.fromOffset(44,44);close.Position=UDim2.new(1,-48,0,2)
close.Text="×";close.TextSize=28;close.Parent=panel
local scroll=Instance.new("ScrollingFrame");scroll.Position=UDim2.fromOffset(10,52);scroll.Size=UDim2.new(1,-20,1,-62)
scroll.BackgroundTransparency=1;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.ScrollBarThickness=8;scroll.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,4);layout.Parent=scroll
local labels={}
for _,entry in ipairs(Catalog.Entries) do
 local label=Instance.new("TextLabel");label.Size=UDim2.new(1,-12,0,36);label.BackgroundTransparency=1
 label.TextXAlignment=Enum.TextXAlignment.Left;label.TextSize=18;label.Font=Enum.Font.GothamMedium
 label.Parent=scroll;table.insert(labels,label)
end
for _,item in ipairs({button,panel,close}) do
 item.BackgroundColor3=Color3.fromRGB(31,78,69);item.BorderSizePixel=0
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=item
end
title.TextColor3=Color3.fromRGB(255,234,185);button.TextColor3=title.TextColor3;close.TextColor3=title.TextColor3
--- Shows all collected species independently of the six visible companions.
local function update()
 local count=player:GetAttribute("CollectedCount") or 0
 for index,entry in ipairs(Catalog.Entries) do
  labels[index].Text=(if index<=count then "✓  " else "○  ")..entry.letter.." — "..entry.name
  labels[index].TextColor3=if index<=count then Color3.fromRGB(150,244,187) else Color3.fromRGB(216,219,210)
 end
end
button.Activated:Connect(function() panel.Visible=not panel.Visible end)
close.Activated:Connect(function() panel.Visible=false end)
player:GetAttributeChangedSignal("CollectedCount"):Connect(update)
player.CharacterRemoving:Connect(function() panel.Visible=false end)
update();gui.Parent=player:WaitForChild("PlayerGui")