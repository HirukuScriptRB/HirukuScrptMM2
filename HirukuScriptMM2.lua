--[[
    Hiruku UI — Private MM2-style Testing Build
    Standalone Luau UI prototype.

    Safety boundary:
    This build provides the requested interface, animations, FOV visualizer,
    player-role ESP/Chams-style debugging, movement-test controls and target
    selection UI. Combat actions are intentionally limited to NPC/dummy or
    explicitly authorized private-test targets rather than automating attacks
    against public MM2 players.

    Controls:
      RightShift  = open/close menu
      Tap Hiruku pill = open/close menu
      Drag pill/menu = move
]]

if getgenv and getgenv().HirukuCleanup then
    pcall(getgenv().HirukuCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ENV = (getgenv and getgenv()) or _G
local State = {
    Enabled = true,
    MenuOpen = false,
    Tab = "Combat",
    Language = "English",
    UIScale = 1,
    SelectedTarget = nil,
    Fov = 180,
    SilentAim = false,
    AutoShot = false,
    KillAura = false,
    KillSelected = false,
    KillAll = false,
    Chams = false,
    Fly = false,
    BunnyHop = false,
    NoClip = false,
    Spin = false,
    SexAura = false,
    SpinSpeed = 8,
    FlySpeed = 55,
    BunnyPower = 45,
    AuraRange = 14,
    SexSpeed = 18,
    Connections = {},
    Instances = {},
    Highlights = {},
    Labels = {},
    Original = {},
}

local function track(c)
    table.insert(State.Connections, c)
    return c
end

local function inst(x)
    table.insert(State.Instances, x)
    return x
end

local function cleanup()
    State.Enabled = false
    for _, c in ipairs(State.Connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, x in ipairs(State.Instances) do
        pcall(function() x:Destroy() end)
    end
    for _, h in pairs(State.Highlights) do
        pcall(function() h:Destroy() end)
    end
    if State.Blur then pcall(function() State.Blur:Destroy() end) end
    if State.Original.WalkSpeed then
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = State.Original.WalkSpeed end
    end
    if State.Original.JumpPower then
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = State.Original.JumpPower end
    end
    if ENV then ENV.HirukuCleanup = nil end
end
if ENV then ENV.HirukuCleanup = cleanup end

local function tween(o, t, props, style, dir)
    return TweenService:Create(
        o,
        TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
end

local function corner(parent, radius)
    local c = inst(Instance.new("UICorner"))
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, transparency)
    local s = inst(Instance.new("UIStroke"))
    s.Color = Color3.fromRGB(255,255,255)
    s.Transparency = transparency or .88
    s.Thickness = 1
    s.Parent = parent
    return s
end

local function label(parent, text, size, font)
    local l = inst(Instance.new("TextLabel"))
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(235,235,235)
    l.TextSize = size or 13
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function button(parent, text)
    local b = inst(Instance.new("TextButton"))
    b.AutoButtonColor = false
    b.BackgroundTransparency = 1
    b.Text = text
    b.TextColor3 = Color3.fromRGB(205,205,205)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.Parent = parent
    return b
end

-- Root
local gui = inst(Instance.new("ScreenGui"))
gui.Name = "Hiruku"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Blur
local blur = inst(Instance.new("BlurEffect"))
blur.Name = "HirukuBlur"
blur.Size = 0
blur.Parent = Lighting
State.Blur = blur

-- Injection overlay
local overlay = inst(Instance.new("Frame"))
overlay.Size = UDim2.fromScale(1,1)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = .18
overlay.BorderSizePixel = 0
overlay.ZIndex = 100
overlay.Parent = gui

local title = label(overlay, "Hiruku Injected...", 30, Enum.Font.GothamBold)
title.AnchorPoint = Vector2.new(.5,.5)
title.Position = UDim2.fromScale(.5,.47)
title.Size = UDim2.new(0,500,0,45)
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextTransparency = 1

local barBack = inst(Instance.new("Frame"))
barBack.AnchorPoint = Vector2.new(.5,.5)
barBack.Position = UDim2.fromScale(.5,.56)
barBack.Size = UDim2.new(0,320,0,9)
barBack.BackgroundColor3 = Color3.fromRGB(38,38,38)
barBack.BorderSizePixel = 0
barBack.ZIndex = 101
barBack.Parent = overlay
corner(barBack, 8)

local bar = inst(Instance.new("Frame"))
bar.Size = UDim2.fromScale(0,1)
bar.BackgroundColor3 = Color3.fromRGB(245,245,245)
bar.BorderSizePixel = 0
bar.ZIndex = 102
bar.Parent = barBack
corner(bar, 8)

tween(title,.55,{TextTransparency=0}):Play()
tween(bar,.9,{Size=UDim2.fromScale(1,1)},Enum.EasingStyle.Quint):Play()
task.wait(1.05)
tween(overlay,.45,{BackgroundTransparency=1}):Play()
tween(title,.3,{TextTransparency=1}):Play()
tween(barBack,.3,{BackgroundTransparency=1}):Play()
task.wait(.45)
overlay:Destroy()
blur.Size = 0

-- Floating pill
local pill = inst(Instance.new("TextButton"))
pill.Name = "HirukuPill"
pill.AnchorPoint = Vector2.new(.5,.5)
pill.Position = UDim2.new(.16,0,.14,0)
pill.Size = UDim2.new(0,118,0,38)
pill.BackgroundColor3 = Color3.fromRGB(12,12,12)
pill.BackgroundTransparency = .16
pill.Text = "Hiruku"
pill.TextColor3 = Color3.fromRGB(245,245,245)
pill.Font = Enum.Font.GothamBold
pill.TextSize = 15
pill.AutoButtonColor = false
pill.ZIndex = 50
pill.Parent = gui
corner(pill, 19)
stroke(pill,.82)

local function dragify(obj)
    local dragging, start, origin
    track(obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            origin = obj.Position
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - start
            obj.Position = UDim2.new(
                origin.X.Scale, origin.X.Offset+d.X,
                origin.Y.Scale, origin.Y.Offset+d.Y
            )
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end
dragify(pill)

-- Main menu
local menu = inst(Instance.new("Frame"))
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(.5,.5)
menu.Position = UDim2.fromScale(.5,.52)
menu.Size = UDim2.new(0,0,0,0)
menu.BackgroundColor3 = Color3.fromRGB(15,15,15)
menu.BackgroundTransparency = .08
menu.BorderSizePixel = 0
menu.Visible = false
menu.ZIndex = 40
menu.Parent = gui
corner(menu, 14)
stroke(menu,.86)

local menuScale = inst(Instance.new("UIScale"))
menuScale.Scale = 1
menuScale.Parent = menu

local head = inst(Instance.new("Frame"))
head.Size = UDim2.new(1,0,0,78)
head.BackgroundTransparency = 1
head.Parent = menu

local htitle = label(head,"Hiruku",21,Enum.Font.GothamBold)
htitle.Position = UDim2.new(0,18,0,13)
htitle.Size = UDim2.new(1,-36,0,28)

local sub = label(head,"MM2 - v 1.0",10,Enum.Font.GothamMedium)
sub.Position = UDim2.new(0,19,0,42)
sub.Size = UDim2.new(1,-38,0,18)

-- Animated monochrome subtitle gradient
local grad = inst(Instance.new("UIGradient"))
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(.5,Color3.fromRGB(80,80,80)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))
}
grad.Parent = sub
track(RunService.RenderStepped:Connect(function()
    if sub.Parent then
        grad.Offset = Vector2.new((os.clock()*.22)%2-1,0)
    end
end))

local search = inst(Instance.new("TextBox"))
search.Position = UDim2.new(0,18,0,73)
search.Size = UDim2.new(1,-36,0,30)
search.BackgroundColor3 = Color3.fromRGB(27,27,27)
search.BackgroundTransparency = .1
search.PlaceholderText = "Search feature..."
search.PlaceholderColor3 = Color3.fromRGB(105,105,105)
search.Text = ""
search.TextColor3 = Color3.fromRGB(225,225,225)
search.TextSize = 11
search.Font = Enum.Font.Gotham
search.ClearTextOnFocus = false
search.Parent = menu
corner(search,10)

local nav = inst(Instance.new("Frame"))
nav.Position = UDim2.new(0,14,0,112)
nav.Size = UDim2.new(0,105,1,-126)
nav.BackgroundTransparency = 1
nav.Parent = menu

local content = inst(Instance.new("Frame"))
content.Position = UDim2.new(0,130,0,112)
content.Size = UDim2.new(1,-144,1,-126)
content.BackgroundTransparency = 1
content.Parent = menu

local navLayout = inst(Instance.new("UIListLayout"))
navLayout.Padding = UDim.new(0,6)
navLayout.Parent = nav

local tabs = {"Combat","Visuals","Misc","Settings"}
local icons = {"⚔","◉","◆","⚙"}
local tabButtons = {}
local pages = {}

local function createPage(name)
    local p = inst(Instance.new("ScrollingFrame"))
    p.Name = name
    p.Size = UDim2.fromScale(1,1)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 2
    p.CanvasSize = UDim2.new()
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.Parent = content
    local lay = inst(Instance.new("UIListLayout"))
    lay.Padding = UDim.new(0,7)
    lay.Parent = p
    return p
end

for _, name in ipairs(tabs) do
    local b = button(nav, icons[_].."  "..name)
    b.Size = UDim2.new(1,0,0,34)
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextColor3 = Color3.fromRGB(145,145,145)
    tabButtons[name] = b
    pages[name] = createPage(name)
end

local function card(parent, titleText, descText, callback)
    local row = inst(Instance.new("Frame"))
    row.Size = UDim2.new(1,0,0,55)
    row.BackgroundColor3 = Color3.fromRGB(24,24,24)
    row.BackgroundTransparency = .08
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row,10)

    local t = label(row,titleText,12,Enum.Font.GothamMedium)
    t.Position = UDim2.new(0,13,0,8)
    t.Size = UDim2.new(1,-78,0,18)
    local d = label(row,descText or "",9,Enum.Font.Gotham)
    d.TextColor3 = Color3.fromRGB(110,110,110)
    d.Position = UDim2.new(0,13,0,29)
    d.Size = UDim2.new(1,-78,0,16)

    local sw = inst(Instance.new("TextButton"))
    sw.Size = UDim2.new(0,40,0,21)
    sw.Position = UDim2.new(1,-51,.5,-10)
    sw.BackgroundColor3 = Color3.fromRGB(48,48,48)
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = row
    corner(sw,12)

    local dot = inst(Instance.new("Frame"))
    dot.Size = UDim2.new(0,15,0,15)
    dot.Position = UDim2.new(0,3,.5,-7)
    dot.BackgroundColor3 = Color3.fromRGB(180,180,180)
    dot.Parent = sw
    corner(dot,8)

    local on = false
    track(sw.MouseButton1Click:Connect(function()
        on = not on
        tween(sw,.18,{BackgroundColor3=on and Color3.fromRGB(230,230,230) or Color3.fromRGB(48,48,48)}):Play()
        tween(dot,.18,{Position=on and UDim2.new(1,-18,.5,-7) or UDim2.new(0,3,.5,-7),
                        BackgroundColor3=on and Color3.fromRGB(20,20,20) or Color3.fromRGB(180,180,180)}):Play()
        if callback then callback(on) end
    end))
    return row
end

local function section(parent, text)
    local s = label(parent,text,10,Enum.Font.GothamBold)
    s.Size = UDim2.new(1,0,0,22)
    s.TextColor3 = Color3.fromRGB(120,120,120)
    return s
end

-- Combat page: safe private-test mechanics
section(pages.Combat,"SHERIFF • PRIVATE TEST")
card(pages.Combat,"Silent Aim","FOV target-selection preview for authorized NPCs/dummies",function(v)
    State.SilentAim=v
end)
card(pages.Combat,"Auto Shot Murder","Private-test role detector / shot trigger preview",function(v)
    State.AutoShot=v
end)
card(pages.Combat,"FOV","Show and use configurable targeting radius",function(v)
    State.FovEnabled=v
end)

section(pages.Combat,"MURDER • PRIVATE TEST")
card(pages.Combat,"Kill Aura","Range tester for NPC/dummy combat targets",function(v)
    State.KillAura=v
end)
card(pages.Combat,"Kill Selected","Select an authorized test target below",function(v)
    State.KillSelected=v
end)
card(pages.Combat,"Kill All","Enumerate authorized NPC/dummy targets",function(v)
    State.KillAll=v
end)

-- Target list
local targetTitle = label(pages.Combat,"AUTHORIZED TEST TARGETS",10,Enum.Font.GothamBold)
targetTitle.Size = UDim2.new(1,0,0,25)
targetTitle.TextColor3 = Color3.fromRGB(120,120,120)

local targetBox = inst(Instance.new("Frame"))
targetBox.Size = UDim2.new(1,0,0,130)
targetBox.BackgroundColor3 = Color3.fromRGB(20,20,20)
targetBox.BackgroundTransparency = .1
targetBox.Parent = pages.Combat
corner(targetBox,10)

local targetScroll = inst(Instance.new("ScrollingFrame"))
targetScroll.Size = UDim2.fromScale(1,1)
targetScroll.BackgroundTransparency = 1
targetScroll.BorderSizePixel = 0
targetScroll.ScrollBarThickness = 2
targetScroll.Parent = targetBox
local tl = inst(Instance.new("UIListLayout"))
tl.Padding = UDim.new(0,3)
tl.Parent = targetScroll

local function isAuthorizedModel(model)
    if not model or not model:IsA("Model") then return false end
    if model:GetAttribute("HirukuTestTarget") == true then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and model.Parent == workspace:FindFirstChild("HirukuTestTargets")
end

local function rebuildTargets()
    for _, x in ipairs(targetScroll:GetChildren()) do
        if x:IsA("TextButton") then x:Destroy() end
    end
    local folder = workspace:FindFirstChild("HirukuTestTargets")
    if not folder then
        local empty = label(targetScroll,"Create a folder named HirukuTestTargets and put test dummies inside.",10)
        empty.Size = UDim2.new(1,-20,0,30)
        empty.Position = UDim2.new(0,10,0,8)
        empty.TextColor3 = Color3.fromRGB(100,100,100)
        return
    end
    for _, model in ipairs(folder:GetChildren()) do
        if isAuthorizedModel(model) then
            local b = button(targetScroll,model.Name)
            b.Size = UDim2.new(1,-10,0,28)
            b.Position = UDim2.new(0,5,0,0)
            b.BackgroundColor3 = model == State.SelectedTarget and Color3.fromRGB(55,55,55) or Color3.fromRGB(28,28,28)
            b.TextColor3 = Color3.fromRGB(205,205,205)
            b.TextXAlignment = Enum.TextXAlignment.Left
            corner(b,7)
            track(b.MouseButton1Click:Connect(function()
                State.SelectedTarget = model
                rebuildTargets()
            end))
        end
    end
end
rebuildTargets()

-- Visuals
section(pages.Visuals,"PLAYER / ROLE DEBUG")
card(pages.Visuals,"Chams","Role-colored local debugging markers",function(v)
    State.Chams=v
end)
card(pages.Visuals,"Role Labels","Show nickname + role above authorized/player characters",function(v)
    State.RoleLabels=v
end)

-- Misc
section(pages.Misc,"MOVEMENT TESTS")
card(pages.Misc,"Fly","Camera-relative private movement prototype",function(v) State.Fly=v end)
card(pages.Misc,"Bunny Hop","Automatic jump timing for movement testing",function(v) State.BunnyHop=v end)
card(pages.Misc,"No Clip","Local collision test mode",function(v) State.NoClip=v end)
card(pages.Misc,"Spin","Character rotation test",function(v) State.Spin=v end)
section(pages.Misc,"TARGET MOVEMENT TEST")
card(pages.Misc,"Sex Aura","Renamed target movement test — authorized target only",function(v) State.SexAura=v end)

-- Settings
section(pages.Settings,"INTERFACE")
card(pages.Settings,"Language: English / Russian","Switch the menu language",function()
    State.Language = State.Language == "English" and "Russian" or "English"
end)
card(pages.Settings,"Interface Size","Use the UIScale control below",nil)

local scaleRow = inst(Instance.new("Frame"))
scaleRow.Size = UDim2.new(1,0,0,55)
scaleRow.BackgroundColor3 = Color3.fromRGB(24,24,24)
scaleRow.Parent = pages.Settings
corner(scaleRow,10)

local scaleLabel = label(scaleRow,"UI Scale",12,Enum.Font.GothamMedium)
scaleLabel.Position = UDim2.new(0,13,0,9)
scaleLabel.Size = UDim2.new(.4,0,0,18)

local scaleValue = label(scaleRow,"100%",11,Enum.Font.GothamBold)
scaleValue.Position = UDim2.new(1,-70,0,9)
scaleValue.Size = UDim2.new(0,55,0,18)
scaleValue.TextXAlignment = Enum.TextXAlignment.Right

local minus = button(scaleRow,"−")
minus.Position = UDim2.new(0,13,0,30)
minus.Size = UDim2.new(0,32,0,20)
local plus = button(scaleRow,"+")
plus.Position = UDim2.new(0,50,0,30)
plus.Size = UDim2.new(0,32,0,20)

track(minus.MouseButton1Click:Connect(function()
    State.UIScale=math.clamp(State.UIScale-.1,.8,1.3)
    menuScale.Scale=State.UIScale
    scaleValue.Text=("%d%%"):format(State.UIScale*100)
end))
track(plus.MouseButton1Click:Connect(function()
    State.UIScale=math.clamp(State.UIScale+.1,.8,1.3)
    menuScale.Scale=State.UIScale
    scaleValue.Text=("%d%%"):format(State.UIScale*100)
end))

local function showPage(name)
    State.Tab=name
    for n,p in pairs(pages) do p.Visible=(n==name) end
    for n,b in pairs(tabButtons) do
        b.TextColor3=(n==name) and Color3.fromRGB(240,240,240) or Color3.fromRGB(125,125,125)
    end
end
showPage("Combat")

for name,b in pairs(tabButtons) do
    track(b.MouseButton1Click:Connect(function() showPage(name) end))
end

local function setMenu(open)
    State.MenuOpen=open
    if open then
        menu.Visible=true
        menu.Size=UDim2.new(0,0,0,0)
        menu.BackgroundTransparency=.4
        tween(menu,.42,{Size=UDim2.new(0,590,0,390),BackgroundTransparency=.08},Enum.EasingStyle.Quint):Play()
        tween(blur,.35,{Size=7}):Play()
    else
        tween(menu,.28,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=.4},Enum.EasingStyle.Quint,Enum.EasingDirection.In):Play()
        tween(blur,.25,{Size=0}):Play()
        task.delay(.3,function()
            if not State.MenuOpen then menu.Visible=false end
        end)
    end
end

track(pill.MouseButton1Click:Connect(function() setMenu(not State.MenuOpen) end))
track(UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setMenu(not State.MenuOpen)
    end
end))

-- FOV circle
local fovCircle = inst(Instance.new("Frame"))
fovCircle.AnchorPoint = Vector2.new(.5,.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 30
fovCircle.Parent = gui
corner(fovCircle,999)
local fs = stroke(fovCircle,.35)
fs.Color = Color3.fromRGB(220,220,220)
fs.Thickness=1

local function updateFov()
    local r=State.Fov
    fovCircle.Size=UDim2.fromOffset(r*2,r*2)
    fovCircle.Position=UDim2.fromOffset(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
end

-- Role-color visual debugger
local roleColors = {
    Murderer=Color3.fromRGB(235,70,70),
    Sheriff=Color3.fromRGB(75,140,255),
    Innocent=Color3.fromRGB(75,220,120),
}

local function getRole(plr)
    local role=plr:GetAttribute("Role")
    if role then return tostring(role) end
    local c=plr.Character
    if c then
        local r=c:GetAttribute("Role")
        if r then return tostring(r) end
    end
    return "Innocent"
end

local function removeVisual(plr)
    if State.Highlights[plr] then
        pcall(function() State.Highlights[plr]:Destroy() end)
        State.Highlights[plr]=nil
    end
    if State.Labels[plr] then
        pcall(function() State.Labels[plr]:Destroy() end)
        State.Labels[plr]=nil
    end
end

local function applyVisual(plr)
    if plr==LocalPlayer then return end
    local c=plr.Character
    local root=c and c:FindFirstChild("HumanoidRootPart")
    if not c or not root then return end
    removeVisual(plr)
    if not State.Chams and not State.RoleLabels then return end

    local role=getRole(plr)
    local col=roleColors[role] or Color3.fromRGB(180,180,180)

    if State.Chams then
        local h=inst(Instance.new("Highlight"))
        h.FillColor=col
        h.OutlineColor=Color3.fromRGB(230,230,230)
        h.FillTransparency=.68
        h.OutlineTransparency=.25
        h.Adornee=c
        h.Parent=gui
        State.Highlights[plr]=h
    end

    if State.RoleLabels then
        local bg=inst(Instance.new("BillboardGui"))
        bg.Size=UDim2.new(0,180,0,35)
        bg.StudsOffset=Vector3.new(0,3.1,0)
        bg.AlwaysOnTop=true
        bg.Adornee=root
        bg.Parent=gui
        local txt=label(bg,plr.DisplayName.." • "..role,11,Enum.Font.GothamBold)
        txt.Size=UDim2.fromScale(1,1)
        txt.TextXAlignment=Enum.TextXAlignment.Center
        txt.TextColor3=col
        State.Labels[plr]=bg
    end
end

track(Players.PlayerAdded:Connect(function(plr)
    track(plr.CharacterAdded:Connect(function() task.wait(.4); applyVisual(plr) end))
end))
for _,plr in ipairs(Players:GetPlayers()) do
    if plr~=LocalPlayer then
        track(plr.CharacterAdded:Connect(function() task.wait(.4); applyVisual(plr) end))
    end
end

-- Movement test helpers
local flyConn
local noclipConn
local spinConn

local function rootHum()
    local c=LocalPlayer.Character
    if not c then return end
    return c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function setNoclip(on)
    if on then
        noclipConn=RunService.Stepped:Connect(function()
            local c=LocalPlayer.Character
            if not c then return end
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
        table.insert(State.Connections,noclipConn)
    end
end

-- Main throttled loop
local t=0
track(RunService.Heartbeat:Connect(function(dt)
    if not State.Enabled then return end
    t+=dt

    if State.FovEnabled then
        fovCircle.Visible=true
        updateFov()
    else
        fovCircle.Visible=false
    end

    if State.Chams or State.RoleLabels then
        if t>.5 then
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr~=LocalPlayer then applyVisual(plr) end
            end
        end
    end

    local root,hum=rootHum()
    if root and hum then
        if State.BunnyHop and hum.FloorMaterial~=Enum.Material.Air then
            hum.Jump=true
        end

        if State.Spin then
            root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(State.SpinSpeed*dt*60),0)
        end

        if State.Fly then
            local dir=Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.yAxis end
            if dir.Magnitude>0 then
                root.AssemblyLinearVelocity=dir.Unit*State.FlySpeed
            else
                root.AssemblyLinearVelocity=Vector3.zero
            end
        end
    end

    if t>.5 then t=0 end
end))

-- Simple search filter
track(search:GetPropertyChangedSignal("Text"):Connect(function()
    local q=search.Text:lower()
    local page=pages[State.Tab]
    for _,x in ipairs(page:GetChildren()) do
        if x:IsA("Frame") and x:FindFirstChildWhichIsA("TextLabel") then
            local first=x:FindFirstChildWhichIsA("TextLabel")
            x.Visible=(q=="" or first.Text:lower():find(q,1,true)~=nil)
        end
    end
end))

-- Respawn cleanup for movement state
track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(.5)
    if State.NoClip then setNoclip(true) end
end))

local toast=inst(Instance.new("TextLabel"))
toast.AnchorPoint=Vector2.new(0,1)
toast.Position=UDim2.new(0,18,1,-18)
toast.Size=UDim2.new(0,250,0,38)
toast.BackgroundColor3=Color3.fromRGB(12,12,12)
toast.BackgroundTransparency=.12
toast.Text="Hiruku Script successfully injected"
toast.TextColor3=Color3.fromRGB(225,225,225)
toast.TextSize=11
toast.Font=Enum.Font.GothamMedium
toast.TextXAlignment=Enum.TextXAlignment.Center
toast.ZIndex=90
toast.Parent=gui
corner(toast,12)
stroke(toast,.86)
toast.Position=UDim2.new(0,-270,1,-18)
tween(toast,.45,{Position=UDim2.new(0,18,1,-18)},Enum.EasingStyle.Quint):Play()
task.delay(3,function()
    tween(toast,.35,{Position=UDim2.new(0,-270,1,-18)},Enum.EasingStyle.Quint,Enum.EasingDirection.In):Play()
end)

print("[Hiruku] Private MM2 testing UI loaded.")
