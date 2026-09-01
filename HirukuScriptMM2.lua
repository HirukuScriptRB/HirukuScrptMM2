--[[
    HIRUKU MM2 — PRIVATE TEST / QA BUILD
    Standalone Luau script.

    Updated:
      • Menu-only visual blur treatment (no Lighting BlurEffect)
      • Fully draggable menu + floating pill on touch/mouse
      • Imported icon sheet instead of emoji navigation icons
      • Deep settings panels with sliders/toggles
      • FOV circle + NPC/dummy target selector
      • Role-aware visual debugger with tool/attribute detection
      • Watermark with FPS / player / ping
      • Rerun-safe cleanup
      • MM2 QA utilities: coin radar, test-coin route, crosshair, fullbright, anti-AFK

    IMPORTANT:
      Public-player combat automation and public coin farming are not included.
      Test Coin Farm only moves to objects explicitly marked HirukuTestCoin or placed
      under workspace.HirukuTestCoins for controlled private QA.
      The combat controls below are wired as private-test target tools so the
      interface can be QA-tested without automating attacks against players.
]]

if getgenv and getgenv().HirukuCleanup then
    pcall(getgenv().HirukuCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ENV = (getgenv and getgenv()) or _G

local S = {
    alive = true,
    menu = false,
    tab = "Combat",
    selected = nil,

    FOV = 180,
    FOVEnabled = false,
    AimEnabled = false,
    AimSmooth = 0.18,
    AimLOS = true,
    AimTargetPart = "Head",
    AimNPCOnly = false,
    AimPlayers = true,

    AutoShot = false,
    KillAura = false,
    KillSelected = false,
    KillAll = false,
    AuraRange = 14,

    Chams = false,
    RoleLabels = true,
    Watermark = false,
    WatermarkFPS = true,
    WatermarkPing = true,

    Fly = false,
    FlySpeed = 55,
    BunnyHop = false,
    BunnyPower = 45,
    BunnySpeed = 18,
    BunnyAutoStrafe = true,
    NoClip = false,
    FlyVertical = 0,
    Spin = false,
    SpinSpeed = 8,
    TargetMovement = false,
    TargetMovementSpeed = 18,

    Language = "English",
    UIScale = 1,

    connections = {},
    instances = {},
    highlights = {},
    labels = {},
    saved = {},
}

local function conn(c)
    table.insert(S.connections, c)
    return c
end

local function add(x)
    table.insert(S.instances, x)
    return x
end

local function cleanup()
    S.alive = false

    for _, c in ipairs(S.connections) do
        pcall(function() c:Disconnect() end)
    end

    for _, x in ipairs(S.instances) do
        pcall(function() x:Destroy() end)
    end

    for _, x in pairs(S.highlights) do
        pcall(function() x:Destroy() end)
    end

    for _, x in pairs(S.labels) do
        pcall(function() x:Destroy() end)
    end
    local c = LocalPlayer.Character
    if c then
        for _,part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide=true end) end
        end
    end
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then
        if S.saved.WalkSpeed then h.WalkSpeed = S.saved.WalkSpeed end
        if S.saved.JumpPower then h.JumpPower = S.saved.JumpPower end
    end

    if ENV then ENV.HirukuCleanup = nil end
end

if ENV then ENV.HirukuCleanup = cleanup end

local function tw(o, t, props, style, direction)
    local x = TweenService:Create(
        o,
        TweenInfo.new(
            t,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        props
    )
    x:Play()
    return x
end

local function uiCorner(p, r)
    local x = add(Instance.new("UICorner"))
    x.CornerRadius = UDim.new(0, r)
    x.Parent = p
    return x
end

local function uiStroke(p, alpha)
    local x = add(Instance.new("UIStroke"))
    x.Color = Color3.fromRGB(255,255,255)
    x.Thickness = 1
    x.Transparency = alpha or .86
    x.Parent = p
    return x
end

local function text(p, value, size, font)
    local x = add(Instance.new("TextLabel"))
    x.BackgroundTransparency = 1
    x.Text = value
    x.TextColor3 = Color3.fromRGB(232,232,232)
    x.TextSize = size or 13
    x.Font = font or Enum.Font.Gotham
    x.TextXAlignment = Enum.TextXAlignment.Left
    x.Parent = p
    return x
end

local function mkButton(p)
    local x = add(Instance.new("TextButton"))
    x.BackgroundTransparency = 1
    x.AutoButtonColor = false
    x.Text = ""
    x.Parent = p
    return x
end

local function newFrame(p, color, transparency)
    local x = add(Instance.new("Frame"))
    x.BackgroundColor3 = color or Color3.fromRGB(20,20,20)
    x.BackgroundTransparency = transparency or 0
    x.BorderSizePixel = 0
    x.Parent = p
    return x
end

-- Root
local gui = add(Instance.new("ScreenGui"))
gui.Name = "Hiruku"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 1000000

pcall(function()
    gui.Parent = game:GetService("CoreGui")
end)
if not gui.Parent then
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Injection screen
local inject = newFrame(gui, Color3.new(0,0,0), .14)
inject.Size = UDim2.fromScale(1,1)
inject.ZIndex = 200

local injTitle = text(inject, "Hiruku Injected...", 29, Enum.Font.GothamBold)
injTitle.AnchorPoint = Vector2.new(.5,.5)
injTitle.Position = UDim2.fromScale(.5,.47)
injTitle.Size = UDim2.new(0,500,0,45)
injTitle.TextXAlignment = Enum.TextXAlignment.Center
injTitle.TextTransparency = 1

local barBack = newFrame(inject, Color3.fromRGB(45,45,45), 0)
barBack.AnchorPoint = Vector2.new(.5,.5)
barBack.Position = UDim2.fromScale(.5,.56)
barBack.Size = UDim2.new(0,330,0,8)
barBack.ZIndex = 201
uiCorner(barBack, 8)

local bar = newFrame(barBack, Color3.fromRGB(245,245,245), 0)
bar.Size = UDim2.fromScale(0,1)
bar.ZIndex = 202
uiCorner(bar, 8)

tw(injTitle,.5,{TextTransparency=0})
tw(bar,.95,{Size=UDim2.fromScale(1,1)})
task.wait(1.08)
tw(inject,.4,{BackgroundTransparency=1})
tw(injTitle,.25,{TextTransparency=1})
tw(barBack,.25,{BackgroundTransparency=1})
task.wait(.42)
pcall(function() inject:Destroy() end)

-- Floating pill
local pill = add(Instance.new("TextButton"))
pill.Name = "HirukuPill"
pill.AnchorPoint = Vector2.new(.5,.5)
pill.Position = UDim2.new(.16,0,.14,0)
pill.Size = UDim2.new(0,122,0,39)
pill.BackgroundColor3 = Color3.fromRGB(11,11,11)
pill.BackgroundTransparency = .13
pill.Text = "Hiruku"
pill.TextColor3 = Color3.fromRGB(245,245,245)
pill.TextSize = 15
pill.Font = Enum.Font.GothamBold
pill.AutoButtonColor = false
pill.Active = true
pill.Modal = true
pill.ZIndex = 1200
pill.Parent = gui
uiCorner(pill,20)
uiStroke(pill,.78)

-- Menu
local menu = newFrame(gui, Color3.fromRGB(14,14,14), .07)
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(.5,.5)
menu.Position = UDim2.fromScale(.5,.52)
menu.Size = UDim2.new(0,610,0,410)
menu.Visible = false
menu.ZIndex = 1190
menu.Active = true
uiCorner(menu,16)
uiStroke(menu,.84)

-- Faux local blur layers: only inside the menu.
-- Roblox's normal BlurEffect affects the entire viewport, so it is not used.
local blurLayer = newFrame(menu, Color3.fromRGB(40,40,40), .82)
blurLayer.Size = UDim2.fromScale(1,1)
blurLayer.ZIndex = 0
uiCorner(blurLayer,16)

local topGlow = newFrame(menu, Color3.fromRGB(255,255,255), .965)
topGlow.Position = UDim2.new(0,1,0,1)
topGlow.Size = UDim2.new(1,-2,0,85)
topGlow.ZIndex = 1
uiCorner(topGlow,15)

local header = newFrame(menu, Color3.fromRGB(0,0,0), 1)
header.Size = UDim2.new(1,0,0,112)
header.ZIndex = 1202

local title = text(header,"Hiruku",21,Enum.Font.GothamBold)
title.Position = UDim2.new(0,20,0,13)
title.ZIndex=1003
title.Size = UDim2.new(1,-40,0,28)

local subtitle = text(header,"MM2 - v 1.0",10,Enum.Font.GothamMedium)
subtitle.Position = UDim2.new(0,21,0,42)
subtitle.ZIndex=1003
subtitle.Size = UDim2.new(1,-42,0,17)

local sg = add(Instance.new("UIGradient"))
sg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(.5,Color3.fromRGB(75,75,75)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))
}
sg.Parent = subtitle

conn(RunService.RenderStepped:Connect(function()
    if subtitle.Parent then
        sg.Offset = Vector2.new((os.clock()*.25)%2-1,0)
    end
end))

local search = add(Instance.new("TextBox"))
search.Position = UDim2.new(0,18,0,73)
search.Size = UDim2.new(1,-36,0,30)
search.BackgroundColor3 = Color3.fromRGB(25,25,25)
search.BackgroundTransparency = .1
search.Text = ""
search.PlaceholderText = "Search feature..."
search.PlaceholderColor3 = Color3.fromRGB(100,100,100)
search.TextColor3 = Color3.fromRGB(230,230,230)
search.TextSize = 11
search.Font = Enum.Font.Gotham
search.ClearTextOnFocus = false
search.Active = true
search.ZIndex = 1203
search.Parent = menu
uiCorner(search,10)

local nav = newFrame(menu, Color3.new(0,0,0), 1)
nav.Position = UDim2.new(0,14,0,121)
nav.Size = UDim2.new(0,145,1,-135)
nav.ZIndex = 1205

local content = newFrame(menu, Color3.new(0,0,0), 1)
content.Position = UDim2.new(0,170,0,121)
content.Size = UDim2.new(1,-184,1,-135)
content.ZIndex = 1204

local ICON_SHEET = "rbxassetid://3926305904"
local ICONS = {
    Combat={Vector2.new(804,4),Vector2.new(36,36)}, -- sword / military-style icon
    Visuals={Vector2.new(204,444),Vector2.new(36,36)}, -- eye / visibility-style icon
    Misc={Vector2.new(764,764),Vector2.new(36,36)}, -- more / three dots
    Settings={Vector2.new(4,4),Vector2.new(36,36)}, -- settings / gear
}
local tabs={"Combat","Visuals","Misc","Settings"}
local pages={}
local tabButtons={}

local function icon(parent,tab)
    local im=add(Instance.new("ImageLabel"))
    im.BackgroundTransparency=1
    im.Image=ICON_SHEET
    im.ImageColor3=Color3.fromRGB(145,145,145)
    im.ImageRectOffset=ICONS[tab][1]
    im.ImageRectSize=ICONS[tab][2]
    im.Size=UDim2.new(0,24,0,24)
    im.Position=UDim2.new(0,7,.5,-12)
    im.ZIndex=1013
    im.Parent=parent
    return im
end

local function page(name)
    local p=add(Instance.new("ScrollingFrame"))
    p.Name=name
    p.Size=UDim2.fromScale(1,1)
    p.BackgroundTransparency=1
    p.BorderSizePixel=0
    p.ScrollBarThickness=2
    p.AutomaticCanvasSize=Enum.AutomaticSize.Y
    p.CanvasSize=UDim2.new()
    p.Visible=false
    p.ZIndex=1011
    p.Active=true
    p.Parent=content
    local l=add(Instance.new("UIListLayout"))
    l.Padding=UDim.new(0,9)
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Parent=p
    local pad=add(Instance.new("UIPadding"))
    pad.PaddingTop=UDim.new(0,2)
    pad.PaddingBottom=UDim.new(0,10)
    pad.Parent=p
    pages[name]=p
    return p
end

local navLayout=add(Instance.new("UIListLayout"))
navLayout.Padding=UDim.new(0,9)
navLayout.SortOrder=Enum.SortOrder.LayoutOrder
navLayout.Parent=nav
for order,name in ipairs(tabs) do
    local b=mkButton(nav)
    b.LayoutOrder=order
    b.Size=UDim2.new(1,0,0,40)
    b.ZIndex=1012
    b.BackgroundColor3=Color3.fromRGB(25,25,25)
    b.BackgroundTransparency=1
    b.Parent=nav
    b.Active=true
    b.Modal=true
    uiCorner(b,9)
    icon(b,name)
    local tx=text(b,name,11,Enum.Font.GothamMedium)
    tx.Position=UDim2.new(0,40,0,0)
    tx.Size=UDim2.new(1,-45,1,0)
    tx.TextColor3=Color3.fromRGB(170,170,170)
    tx.ZIndex=1013
    tabButtons[name]={button=b,label=tx}
    page(name)
end

local function setTab(name)
    S.tab=name
    for n,v in pairs(tabButtons) do
        local active=n==name
        v.button.BackgroundTransparency=active and .70 or 1
        v.label.TextColor3=active and Color3.fromRGB(240,240,240) or Color3.fromRGB(145,145,145)
        pages[n].Visible=active
    end
end

-- Card factory
local function card(parent, name, desc, callback, settingsCallback)
    local row = newFrame(parent,Color3.fromRGB(23,23,23),.06)
    row.Size = UDim2.new(1,0,0,57)
    row.ZIndex=1012
    uiCorner(row,10)

    local n=text(row,name,12,Enum.Font.GothamMedium)
    n.Position=UDim2.new(0,13,0,8)
    n.Size=UDim2.new(1,-105,0,18)
    n.ZIndex=1013

    local d=text(row,desc or "",9,Enum.Font.Gotham)
    d.Position=UDim2.new(0,13,0,30)
    d.Size=UDim2.new(1,-105,0,16)
    d.TextColor3=Color3.fromRGB(105,105,105)
    d.ZIndex=1013

    if settingsCallback then
        local sb=mkButton(row)
        sb.Size=UDim2.new(0,24,0,24)
        sb.Position=UDim2.new(1,-79,.5,-12)
        sb.ZIndex=1014

        local si=add(Instance.new("ImageLabel"))
        si.BackgroundTransparency=1
        si.Image=ICON_SHEET
        si.ImageColor3=Color3.fromRGB(125,125,125)
        si.ImageRectOffset=Vector2.new(4,4)
        si.ImageRectSize=Vector2.new(36,36)
        si.Size=UDim2.fromScale(1,1)
        si.ZIndex=1015
        si.Parent=sb
        conn(sb.Activated:Connect(settingsCallback))
    end

    local sw=mkButton(row)
    sw.Size=UDim2.new(0,42,0,22)
    sw.Position=UDim2.new(1,-52,.5,-11)
    sw.BackgroundColor3=Color3.fromRGB(48,48,48)
    sw.ZIndex=1014
    sw.Parent=row
    uiCorner(sw,12)

    local dot=newFrame(sw,Color3.fromRGB(180,180,180),0)
    dot.Size=UDim2.new(0,16,0,16)
    dot.Position=UDim2.new(0,3,.5,-8)
    dot.ZIndex=1015
    uiCorner(dot,8)

    local on=false
    conn(sw.Activated:Connect(function()
        on=not on
        tw(sw,.17,{BackgroundColor3=on and Color3.fromRGB(225,225,225) or Color3.fromRGB(48,48,48)})
        tw(dot,.17,{
            Position=on and UDim2.new(1,-19,.5,-8) or UDim2.new(0,3,.5,-8),
            BackgroundColor3=on and Color3.fromRGB(15,15,15) or Color3.fromRGB(180,180,180)
        })
        if callback then callback(on) end
    end))

    return row
end

local function heading(parent, value)
    local x=text(parent,value,10,Enum.Font.GothamBold)
    x.Size=UDim2.new(1,0,0,22)
    x.TextColor3=Color3.fromRGB(115,115,115)
    x.ZIndex=1013
    return x
end

-- Deep setting drawer
local drawer = newFrame(gui,Color3.fromRGB(15,15,15),.03)
drawer.Size=UDim2.new(0,330,0,0)
drawer.AnchorPoint=Vector2.new(1,.5)
drawer.Position=UDim2.new(1,-16,.5,0)
drawer.Visible=false
drawer.ZIndex=1300
uiCorner(drawer,14)
uiStroke(drawer,.84)

local drawerTitle=text(drawer,"Silent Aim Settings",15,Enum.Font.GothamBold)
drawerTitle.Position=UDim2.new(0,16,0,14)
drawerTitle.Size=UDim2.new(1,-32,0,25)

local drawerHint=text(drawer,"Private-test target selector",9,Enum.Font.Gotham)
drawerHint.Position=UDim2.new(0,17,0,40)
drawerHint.Size=UDim2.new(1,-34,0,18)
drawerHint.TextColor3=Color3.fromRGB(105,105,105)

local drawerClose=mkButton(drawer)
drawerClose.Size=UDim2.new(0,28,0,28)
drawerClose.Position=UDim2.new(1,-38,0,10)
drawerClose.BackgroundColor3=Color3.fromRGB(30,30,30)
drawerClose.Text="×"
drawerClose.TextColor3=Color3.fromRGB(190,190,190)
drawerClose.TextSize=18
drawerClose.Font=Enum.Font.GothamBold
drawerClose.ZIndex=1120
drawerClose.Parent=drawer
uiCorner(drawerClose,14)


local drawerBody=newFrame(drawer,Color3.new(0,0,0),1)
drawerBody.Position=UDim2.new(0,15,0,70)
drawerBody.Size=UDim2.new(1,-30,1,-80)
drawerBody.ZIndex=121

local function settingSlider(parent,name,min,max,get,set)
    local box=newFrame(parent,Color3.fromRGB(24,24,24),.03)
    box.Size=UDim2.new(1,0,0,62)
    uiCorner(box,9)

    local n=text(box,name,10,Enum.Font.GothamMedium)
    n.Position=UDim2.new(0,11,0,8)
    n.Size=UDim2.new(.65,0,0,17)

    local value=text(box,tostring(get()),10,Enum.Font.GothamBold)
    value.Position=UDim2.new(1,-70,0,8)
    value.Size=UDim2.new(0,59,0,17)
    value.TextXAlignment=Enum.TextXAlignment.Right

    local trackBar=newFrame(box,Color3.fromRGB(48,48,48),0)
    trackBar.Position=UDim2.new(0,11,0,35)
    trackBar.Size=UDim2.new(1,-22,0,7)
    uiCorner(trackBar,4)

    local fill=newFrame(trackBar,Color3.fromRGB(220,220,220),0)
    uiCorner(fill,4)

    local knob=newFrame(trackBar,Color3.fromRGB(245,245,245),0)
    knob.Size=UDim2.new(0,13,0,13)
    knob.AnchorPoint=Vector2.new(.5,.5)
    knob.ZIndex=5
    uiCorner(knob,8)

    local function setFromX(px)
        local a=math.clamp((px-trackBar.AbsolutePosition.X)/trackBar.AbsoluteSize.X,0,1)
        local val=min+(max-min)*a
        set(val)
        local shown=math.floor(val*10+.5)/10
        value.Text=tostring(shown)
        fill.Size=UDim2.new(a,0,1,0)
        knob.Position=UDim2.new(a,0,.5,0)
    end

    conn(trackBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            setFromX(i.Position.X)
        end
    end))
    conn(UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then
            -- mouse dragging is handled by a short-lived flag below
        end
    end))

    local initial=(get()-min)/(max-min)
    fill.Size=UDim2.new(initial,0,1,0)
    knob.Position=UDim2.new(initial,0,.5,0)
    return box
end

local function settingToggle(parent,name,get,set)
    local box=newFrame(parent,Color3.fromRGB(24,24,24),.03)
    box.Size=UDim2.new(1,0,0,45)
    uiCorner(box,9)

    local n=text(box,name,10,Enum.Font.GothamMedium)
    n.Position=UDim2.new(0,11,0,0)
    n.Size=UDim2.new(1,-65,1,0)

    local b=mkButton(box)
    b.Size=UDim2.new(0,42,0,22)
    b.Position=UDim2.new(1,-53,.5,-11)
    b.BackgroundColor3=get() and Color3.fromRGB(225,225,225) or Color3.fromRGB(48,48,48)
    uiCorner(b,12)

    local dot=newFrame(b,get() and Color3.fromRGB(15,15,15) or Color3.fromRGB(180,180,180),0)
    dot.Size=UDim2.new(0,16,0,16)
    dot.Position=get() and UDim2.new(1,-19,.5,-8) or UDim2.new(0,3,.5,-8)
    uiCorner(dot,8)

    conn(b.Activated:Connect(function()
        local v=not get()
        set(v)
        tw(b,.17,{BackgroundColor3=v and Color3.fromRGB(225,225,225) or Color3.fromRGB(48,48,48)})
        tw(dot,.17,{Position=v and UDim2.new(1,-19,.5,-8) or UDim2.new(0,3,.5,-8),
                    BackgroundColor3=v and Color3.fromRGB(15,15,15) or Color3.fromRGB(180,180,180)})
    end))
    return box
end

local function openDrawer()
    drawer.Visible=true
    drawer.Size=UDim2.new(0,330,0,0)
    tw(drawer,.3,{Size=UDim2.new(0,330,0,310)})
end

local function closeDrawer()
    tw(drawer,.25,{Size=UDim2.new(0,330,0,0)})
    task.delay(.27,function()
        if drawer.Parent and drawer.Size.Y.Offset<5 then drawer.Visible=false end
    end)
end

conn(drawerClose.Activated:Connect(closeDrawer))

local openMovementDrawer
local openAimDrawer

-- Movement settings
local function clearDrawerBody()
    for _,x in ipairs(drawerBody:GetChildren()) do
        if x:IsA("GuiObject") then x:Destroy() end
    end
end
openMovementDrawer = function(mode)
    drawerTitle.Text=mode.." Settings"
    drawerHint.Text="Movement configuration"
    clearDrawerBody()
    if mode=="Fly" then
        settingSlider(drawerBody,"Fly speed",10,120,function() return S.FlySpeed end,function(v) S.FlySpeed=v end)
    elseif mode=="Bunny Hop" then
        settingSlider(drawerBody,"Hop speed",8,40,function() return S.BunnySpeed end,function(v) S.BunnySpeed=v end)
        settingToggle(drawerBody,"Auto strafe",function() return S.BunnyAutoStrafe end,function(v) S.BunnyAutoStrafe=v end)
    elseif mode=="Spin" then
        settingSlider(drawerBody,"Spin speed",1,30,function() return S.SpinSpeed end,function(v) S.SpinSpeed=v end)
    elseif mode=="Test Coin Farm" then
        settingSlider(drawerBody,"Test farm speed",20,160,function() return S.CoinFarmSpeed end,function(v) S.CoinFarmSpeed=v end)
    end
    openDrawer()
end

openAimDrawer = function()
    clearDrawerBody()
    drawerTitle.Text="Silent Aim Settings"
    drawerHint.Text="Private-test target selection"
    settingSlider(drawerBody,"FOV",60,420,function() return S.FOV end,function(v) S.FOV=v end)
    settingSlider(drawerBody,"Smoothness",.02,.8,function() return S.AimSmooth end,function(v) S.AimSmooth=v end)
    settingToggle(drawerBody,"Line of sight",function() return S.AimLOS end,function(v) S.AimLOS=v end)
    settingToggle(drawerBody,"Players",function() return S.AimPlayers end,function(v) S.AimPlayers=v end)
    settingToggle(drawerBody,"NPC / dummy",function() return S.AimNPCOnly end,function(v) S.AimNPCOnly=v end)
    openDrawer()
end

-- Combat
heading(pages.Combat,"SHERIFF • PRIVATE TEST")
card(pages.Combat,"Silent Aim","FOV aim-assist target selector for private-test players / dummies",function(v) S.AimEnabled=v end,openAimDrawer)
card(pages.Combat,"Auto Shot Murder","Role-state QA trigger preview",function(v) S.AutoShot=v end)
card(pages.Combat,"FOV","Targeting circle used by the aim tester",function(v) S.FOVEnabled=v end,openAimDrawer)

heading(pages.Combat,"MURDER • PRIVATE TEST")
card(pages.Combat,"Kill Aura","Authorized target range tester",function(v) S.KillAura=v end)
card(pages.Combat,"Kill Selected","Selected authorized target test",function(v) S.KillSelected=v end)
card(pages.Combat,"Kill All","Enumerate authorized test targets",function(v) S.KillAll=v end)

local targetHead=heading(pages.Combat,"AUTHORIZED TEST TARGETS")
local targetBox=newFrame(pages.Combat,Color3.fromRGB(20,20,20),.04)
targetBox.Size=UDim2.new(1,0,0,125)
uiCorner(targetBox,10)

local targetScroll=add(Instance.new("ScrollingFrame"))
targetScroll.Size=UDim2.fromScale(1,1)
targetScroll.BackgroundTransparency=1
targetScroll.BorderSizePixel=0
targetScroll.ScrollBarThickness=2
targetScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
targetScroll.CanvasSize=UDim2.new()
targetScroll.Parent=targetBox
local targetLayout=add(Instance.new("UIListLayout"))
targetLayout.Padding=UDim.new(0,3)
targetLayout.Parent=targetScroll

local function authorized(model)
    if not model or not model:IsA("Model") then return false end
    if model:GetAttribute("HirukuTestTarget")==true then return true end
    local folder=workspace:FindFirstChild("HirukuTestTargets")
    return folder and model.Parent==folder and model:FindFirstChildOfClass("Humanoid")~=nil
end

local function rebuildTargets()
    for _,x in ipairs(targetScroll:GetChildren()) do
        if x:IsA("TextButton") or (x:IsA("TextLabel") and x.Name=="Empty") then
            x:Destroy()
        end
    end

    local folder=workspace:FindFirstChild("HirukuTestTargets")
    if not folder then
        local e=text(targetScroll,"Create workspace.HirukuTestTargets for private test dummies.",9)
        e.Name="Empty"
        e.Size=UDim2.new(1,-16,0,30)
        e.Position=UDim2.new(0,8,0,8)
        e.TextColor3=Color3.fromRGB(95,95,95)
        return
    end

    for _,m in ipairs(folder:GetChildren()) do
        if authorized(m) then
            local b=mkButton(targetScroll)
            b.Size=UDim2.new(1,-8,0,27)
            b.BackgroundColor3=(S.selected==m) and Color3.fromRGB(55,55,55) or Color3.fromRGB(28,28,28)
            b.Text=m.Name
            b.TextColor3=Color3.fromRGB(205,205,205)
            b.TextSize=10
            b.Font=Enum.Font.GothamMedium
            b.TextXAlignment=Enum.TextXAlignment.Left
            b.Parent=targetScroll
            uiCorner(b,7)
            conn(b.Activated:Connect(function()
                S.selected=m
                rebuildTargets()
            end))
        end
    end
end
rebuildTargets()

-- Visuals
heading(pages.Visuals,"PLAYER VISUAL DEBUG")
card(pages.Visuals,"Chams","Role-aware local visual debugger",function(v) S.Chams=v end)
card(pages.Visuals,"Role Labels","Nickname + detected role above characters",function(v) S.RoleLabels=v end)
card(pages.Visuals,"Watermark","Top-center Hiruku / FPS / player / ping",function(v) S.Watermark=v end)

heading(pages.Visuals,"WATERMARK OPTIONS")
card(pages.Visuals,"FPS","Display current frame rate",function(v) S.WatermarkFPS=v end)
card(pages.Visuals,"Ping","Display network latency in milliseconds",function(v) S.WatermarkPing=v end)

-- Misc
heading(pages.Misc,"MOVEMENT TESTS")
card(pages.Misc,"Fly","Camera-relative flight",function(v)
    S.Fly=v
    if not v then
        S.FlyVertical=0
        local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity=Vector3.zero end
    end
end,function() openMovementDrawer("Fly") end)
card(pages.Misc,"Bunny Hop","CS-style auto-jump timing",function(v)
    S.BunnyHop=v
    if not v then
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and S.saved.WalkSpeed then hum.WalkSpeed=S.saved.WalkSpeed end
    end
end,function() openMovementDrawer("Bunny Hop") end)
card(pages.Misc,"No Clip","Disable character collisions",function(v)
    S.NoClip=v
    if not v and LocalPlayer.Character then
        for _,part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide=true end) end
        end
    end
end)
card(pages.Misc,"Spin","Continuous character rotation",function(v) S.Spin=v end,function() openMovementDrawer("Spin") end)

heading(pages.Misc,"TARGET MOVEMENT TEST")
card(pages.Misc,"Sex Aura","Target movement tester for authorized targets",function(v) S.TargetMovement=v end)

-- Additional MM2 QA / utility features
heading(pages.Visuals,"MM2 UTILITIES")
card(pages.Visuals,"Coin Radar","Highlight nearby test coins without collecting them",function(v) S.CoinRadar=v end)
card(pages.Visuals,"Crosshair","Minimal center crosshair for testing",function(v) S.Crosshair=v end)
card(pages.Visuals,"Fullbright","Local lighting test mode",function(v) S.Fullbright=v end)

heading(pages.Misc,"MM2 ROUND / QA")
card(pages.Misc,"Anti AFK","Keep the test client active",function(v) S.AntiAFK=v end)
card(pages.Misc,"Round Info","Show local round/player state",function(v) S.RoundInfo=v end)
card(pages.Misc,"Test Coin Farm","Moves only to coins explicitly marked HirukuTestCoin",function(v) S.TestCoinFarm=v end,function() openMovementDrawer("Test Coin Farm") end)

-- Settings
heading(pages.Settings,"INTERFACE")
card(pages.Settings,"Language","English / Russian",function()
    S.Language=S.Language=="English" and "Russian" or "English"
end)
card(pages.Settings,"Interface Size","Adjust overall menu scale",nil)

local sizeBox=newFrame(pages.Settings,Color3.fromRGB(24,24,24),.03)
sizeBox.Size=UDim2.new(1,0,0,62)
uiCorner(sizeBox,9)
local sizeName=text(sizeBox,"UI Scale",10,Enum.Font.GothamMedium)
sizeName.Position=UDim2.new(0,11,0,8)
sizeName.Size=UDim2.new(.7,0,0,18)
local sizeValue=text(sizeBox,"100%",10,Enum.Font.GothamBold)
sizeValue.Position=UDim2.new(1,-65,0,8)
sizeValue.Size=UDim2.new(0,54,0,18)
sizeValue.TextXAlignment=Enum.TextXAlignment.Right

local minus=mkButton(sizeBox)
minus.Position=UDim2.new(0,11,0,34)
minus.Size=UDim2.new(0,38,0,20)
minus.BackgroundColor3=Color3.fromRGB(40,40,40)
minus.Text="−"
minus.TextColor3=Color3.fromRGB(220,220,220)
minus.TextSize=15
minus.Font=Enum.Font.GothamBold
uiCorner(minus,7)

local plus=mkButton(sizeBox)
plus.Position=UDim2.new(0,55,0,34)
plus.Size=UDim2.new(0,38,0,20)
plus.BackgroundColor3=Color3.fromRGB(40,40,40)
plus.Text="+"
plus.TextColor3=Color3.fromRGB(220,220,220)
plus.TextSize=15
plus.Font=Enum.Font.GothamBold
uiCorner(plus,7)

local menuScale=add(Instance.new("UIScale"))
menuScale.Scale=1
menuScale.Parent=menu

local function updateScale()
    menuScale.Scale=S.UIScale
    sizeValue.Text=("%d%%"):format(math.floor(S.UIScale*100))
end

conn(minus.Activated:Connect(function()
    S.UIScale=math.clamp(S.UIScale-.1,.75,1.35)
    updateScale()
end))
conn(plus.Activated:Connect(function()
    S.UIScale=math.clamp(S.UIScale+.1,.75,1.35)
    updateScale()
end))

-- Navigation
for name,ref in pairs(tabButtons) do
    conn(ref.button.MouseButton1Click:Connect(function()
        setTab(name)
    end))
end
setTab("Combat")

-- Dedicated drag surface prevents touch-dragging from rotating the camera.
local dragSurface=add(Instance.new("TextButton"))
dragSurface.Name="HirukuDragSurface"
dragSurface.BackgroundTransparency=1
dragSurface.Text=""
dragSurface.AutoButtonColor=false
dragSurface.Active=true
dragSurface.Modal=false
dragSurface.Size=UDim2.new(1,0,0,58)
dragSurface.ZIndex=1001
dragSurface.Parent=menu

local function makeDraggable(obj,handle)
    local dragging=false
    local start,origin
    handle.Active=true
    conn(handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            start=input.Position
            origin=obj.Position
        end
    end))
    conn(handle.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))
    conn(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
        local d=input.Position-start
        obj.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
    end))
end
makeDraggable(pill,pill)
makeDraggable(menu,dragSurface)
makeDraggable(menu,header)

-- Menu open/close
local function setMenu(v)
    S.menu=v
    if v then
        menu.Visible=true
        menu.Size=UDim2.new(0,570,0,380)
        menu.BackgroundTransparency=.35
        tw(menu,.34,{Size=UDim2.new(0,610,0,410),BackgroundTransparency=.07})
    else
        tw(menu,.25,{Size=UDim2.new(0,570,0,380),BackgroundTransparency=.35},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        task.delay(.26,function()
            if not S.menu then menu.Visible=false end
        end)
        closeDrawer()
    end
end

conn(pill.Activated:Connect(function()
    setMenu(not S.menu)
end))

conn(UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.RightShift then
        setMenu(not S.menu)
    end
end))

-- Mobile flight buttons
local flyControls=newFrame(gui,Color3.new(0,0,0),1)
flyControls.Size=UDim2.new(0,132,0,60)
flyControls.AnchorPoint=Vector2.new(1,1)
flyControls.Position=UDim2.new(1,-22,1,-105)
flyControls.ZIndex=970
flyControls.Visible=false
local function flyBtn(txt,x)
    local b=mkButton(flyControls)
    b.Position=UDim2.new(0,x,0,0)
    b.Size=UDim2.new(0,58,0,58)
    b.BackgroundColor3=Color3.fromRGB(10,10,10)
    b.BackgroundTransparency=.2
    b.Text=txt
    b.TextColor3=Color3.fromRGB(235,235,235)
    b.TextSize=20
    b.Font=Enum.Font.GothamBold
    b.ZIndex=971
    b.Parent=flyControls
    uiCorner(b,29)
    return b
end
local flyUp=flyBtn("↑",0)
local flyDown=flyBtn("↓",72)
conn(flyUp.MouseButton1Down:Connect(function() S.FlyVertical=1 end))
conn(flyUp.MouseButton1Up:Connect(function() if S.FlyVertical==1 then S.FlyVertical=0 end end))
conn(flyDown.MouseButton1Down:Connect(function() S.FlyVertical=-1 end))
conn(flyDown.MouseButton1Up:Connect(function() if S.FlyVertical==-1 then S.FlyVertical=0 end end))

-- Minimal crosshair
local crosshair=add(Instance.new("Frame"))
crosshair.BackgroundTransparency=1
crosshair.AnchorPoint=Vector2.new(.5,.5)
crosshair.Position=UDim2.fromScale(.5,.5)
crosshair.Size=UDim2.fromOffset(22,22)
crosshair.ZIndex=1250
crosshair.Visible=false
crosshair.Parent=gui
local chH=newFrame(crosshair,Color3.fromRGB(235,235,235),0)
chH.Position=UDim2.new(0,0,.5,-1)
chH.Size=UDim2.new(1,0,0,2)
local chV=newFrame(crosshair,Color3.fromRGB(235,235,235),0)
chV.Position=UDim2.new(.5,-1,0,0)
chV.Size=UDim2.new(0,2,1,0)

-- FOV
local fov=newFrame(gui,Color3.new(0,0,0),1)
fov.AnchorPoint=Vector2.new(.5,.5)
fov.ZIndex=900
fov.Visible=false
uiCorner(fov,999)
local fovStroke=uiStroke(fov,.3)
fovStroke.Color=Color3.fromRGB(225,225,225)

local function updateFov()
    fov.Size=UDim2.fromOffset(math.floor(S.FOV*2),math.floor(S.FOV*2))
    fov.Position=UDim2.fromOffset(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
end

-- Camera aim-assist for authorized/private-test player sessions.
local function getAimPart(model)
    if not model or model==LocalPlayer.Character then return nil end
    local hum=model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return nil end
    local part=model:FindFirstChild(S.AimTargetPart) or model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if not part then return nil end
    local vp,on=Camera:WorldToViewportPoint(part.Position)
    if not on or vp.Z<=0 then return nil end
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local d=(Vector2.new(vp.X,vp.Y)-center).Magnitude
    if d>S.FOV then return nil end
    if S.AimLOS then
        local rp=RaycastParams.new()
        rp.FilterType=Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances={LocalPlayer.Character,model}
        if workspace:Raycast(Camera.CFrame.Position,part.Position-Camera.CFrame.Position,rp) then return nil end
    end
    return part,d
end
local function getAimTarget()
    local best,bestD=nil,math.huge
    if S.AimPlayers then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then
                local part,d=getAimPart(plr.Character)
                if part and d<bestD then best,bestD=part,d end
            end
        end
    end
    for _,m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m:GetAttribute("HirukuTestTarget")==true then
            local part,d=getAimPart(m)
            if part and d<bestD then best,bestD=part,d end
        end
    end
    return best
end

-- Role detection
local roleColors={
    Murderer=Color3.fromRGB(235,65,65),
    Murder=Color3.fromRGB(235,65,65),
    Sheriff=Color3.fromRGB(70,135,255),
    Innocent=Color3.fromRGB(70,220,120),
}

local function normalizeRole(v)
    if not v then return nil end
    v=tostring(v):lower()
    if v:find("murder") then return "Murderer" end
    if v:find("sheriff") then return "Sheriff" end
    if v:find("innocent") then return "Innocent" end
    return nil
end

local function getRole(plr)
    -- 1. Explicit developer/test attributes
    local r=normalizeRole(plr:GetAttribute("Role"))
    if r then return r end

    local c=plr.Character
    if c then
        r=normalizeRole(c:GetAttribute("Role"))
        if r then return r end

        -- 2. Common MM2 state values exposed on character/player
        for _,key in ipairs({"Role","PlayerRole","MM2Role","RoundRole"}) do
            r=normalizeRole(c:GetAttribute(key))
            if r then return r end
            r=normalizeRole(plr:GetAttribute(key))
            if r then return r end
        end

        -- 3. Tool-based fallback. This avoids defaulting everyone to Innocent.
        if c:FindFirstChild("Knife",true) then return "Murderer" end
        if c:FindFirstChild("Gun",true) or c:FindFirstChild("Revolver",true) then return "Sheriff" end
    end

    local backpack=plr:FindFirstChildOfClass("Backpack")
    if backpack then
        if backpack:FindFirstChild("Knife",true) then return "Murderer" end
        if backpack:FindFirstChild("Gun",true) or backpack:FindFirstChild("Revolver",true) then return "Sheriff" end
    end

    -- Common MM2-style replicated role values under PlayerData.
    local pd=game:GetService("ReplicatedStorage"):FindFirstChild("PlayerData")
    local entry=pd and pd:FindFirstChild(plr.Name)
    if entry then
        for _,key in ipairs({"Role","RoleValue","PlayerRole"}) do
            local obj=entry:FindFirstChild(key)
            local rr=obj and normalizeRole(obj.Value)
            if rr then return rr end
        end
    end
    return "Unknown"
end

local function clearVisual(plr)
    if S.highlights[plr] then
        pcall(function() S.highlights[plr]:Destroy() end)
        S.highlights[plr]=nil
    end
    if S.labels[plr] then
        pcall(function() S.labels[plr]:Destroy() end)
        S.labels[plr]=nil
    end
end

local function applyVisual(plr)
    if plr==LocalPlayer then return end
    local c=plr.Character
    local root=c and c:FindFirstChild("HumanoidRootPart")
    if not c or not root then return end

    clearVisual(plr)

    if not S.Chams and not S.RoleLabels then return end

    local role=getRole(plr)
    local col=roleColors[role] or Color3.fromRGB(165,165,165)

    if S.Chams then
        local h=add(Instance.new("Highlight"))
        h.Name="HirukuChams"
        h.Adornee=c
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.FillColor=col
        h.OutlineColor=col
        h.FillTransparency=.62
        h.OutlineTransparency=.12
        h.Parent=gui
        S.highlights[plr]=h
    end

    if S.RoleLabels then
        local bg=add(Instance.new("BillboardGui"))
        bg.Name="HirukuRole"
        bg.Adornee=root
        bg.AlwaysOnTop=true
        bg.Size=UDim2.new(0,210,0,34)
        bg.StudsOffset=Vector3.new(0,3.1,0)
        bg.Parent=gui

        local t=text(bg,plr.DisplayName.." • "..role,10,Enum.Font.GothamBold)
        t.Size=UDim2.fromScale(1,1)
        t.TextXAlignment=Enum.TextXAlignment.Center
        t.TextColor3=col
        S.labels[plr]=bg
    end
end

for _,plr in ipairs(Players:GetPlayers()) do
    if plr~=LocalPlayer then
        conn(plr.CharacterAdded:Connect(function()
            task.wait(.35)
            if S.alive then applyVisual(plr) end
        end))
    end
end

conn(Players.PlayerAdded:Connect(function(plr)
    conn(plr.CharacterAdded:Connect(function()
        task.wait(.35)
        if S.alive then applyVisual(plr) end
    end))
end))

-- Watermark
local watermark=newFrame(gui,Color3.fromRGB(10,10,10),.16)
watermark.AnchorPoint=Vector2.new(.5,0)
watermark.Position=UDim2.new(.5,0,0,16)
watermark.Size=UDim2.new(0,330,0,34)
watermark.Visible=false
watermark.ZIndex=950
uiCorner(watermark,18)
uiStroke(watermark,.84)

local wmText=text(watermark,"",10,Enum.Font.GothamMedium)
wmText.Size=UDim2.new(1,-22,1,0)
wmText.Position=UDim2.new(0,11,0,0)
wmText.TextXAlignment=Enum.TextXAlignment.Center
wmText.ZIndex=81

local function getPing()
    local ok,value=pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    if ok and value then
        return tostring(value):match("%d+") or "—"
    end
    return "—"
end

local Lighting=game:GetService("Lighting")
local savedLighting={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows}
local frames=0
local lastFps=os.clock()
local fps=60

conn(RunService.RenderStepped:Connect(function()
    frames+=1
    local now=os.clock()
    if now-lastFps>=.5 then
        fps=math.floor(frames/(now-lastFps)+.5)
        frames=0
        lastFps=now
    end

    crosshair.Visible=S.Crosshair
    if S.Fullbright then
        Lighting.Brightness=2
        Lighting.ClockTime=14
        Lighting.FogEnd=100000
        Lighting.GlobalShadows=false
    else
        Lighting.Brightness=savedLighting.Brightness
        Lighting.ClockTime=savedLighting.ClockTime
        Lighting.FogEnd=savedLighting.FogEnd
        Lighting.GlobalShadows=savedLighting.GlobalShadows
    end
    if S.Watermark then
        local parts={"Hiruku"}
        if S.WatermarkFPS then table.insert(parts,tostring(fps).." FPS") end
        table.insert(parts,LocalPlayer.DisplayName)
        if S.WatermarkPing then table.insert(parts,getPing().." ms") end
        wmText.Text=table.concat(parts,"   •   ")
        watermark.Visible=true
    else
        watermark.Visible=false
    end
end))

-- Movement tests
local function getRootHum()
    local c=LocalPlayer.Character
    if not c then return end
    return c:FindFirstChild("HumanoidRootPart"),c:FindFirstChildOfClass("Humanoid")
end

local noclipOn=false

local function setNoclip(v)
    noclipOn=v
end

-- Search
conn(search:GetPropertyChangedSignal("Text"):Connect(function()
    local q=search.Text:lower()
    for _,child in ipairs(pages[S.tab]:GetChildren()) do
        if child:IsA("Frame") then
            local first=child:FindFirstChildWhichIsA("TextLabel")
            if first then
                child.Visible=(q=="" or first.Text:lower():find(q,1,true)~=nil)
            end
        end
    end
end))

-- Safe private-test coin helpers. Only objects with HirukuTestCoin=true or
-- objects inside workspace.HirukuTestCoins are eligible. Public MM2 coins are ignored.
local coinHighlights={}
for _,x in pairs(S.instances) do
    if x.Name=="HirukuCoinRadar" then pcall(function() x:Destroy() end) end
end
local function isTestCoin(obj)
    if not obj then return false end
    if obj:GetAttribute("HirukuTestCoin") == true then return true end
    local folder=workspace:FindFirstChild("HirukuTestCoins")
    return folder and obj:IsDescendantOf(folder)
end
local function coinPosition(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
        return pp and pp.Position
    end
end
local function nearestTestCoin(root)
    local best,bestD=nil,math.huge
    local folder=workspace:FindFirstChild("HirukuTestCoins")
    if folder then
        for _,obj in ipairs(folder:GetDescendants()) do
            if (obj:IsA("BasePart") or obj:IsA("Model")) and isTestCoin(obj) then
                local pos=coinPosition(obj)
                if pos then
                    local d=(pos-root.Position).Magnitude
                    if d<bestD then best,bestD=obj,d end
                end
            end
        end
    end
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:GetAttribute("HirukuTestCoin") == true then
            local pos=coinPosition(obj)
            if pos then
                local d=(pos-root.Position).Magnitude
                if d<bestD then best,bestD=obj,d end
            end
        end
    end
    return best,bestD
end
local function updateCoinRadar(root)
    if not S.CoinRadar then
        for obj,h in pairs(coinHighlights) do pcall(function() h:Destroy() end); coinHighlights[obj]=nil end
        return
    end
    for obj,h in pairs(coinHighlights) do
        if not obj.Parent then pcall(function() h:Destroy() end); coinHighlights[obj]=nil end
    end
    local folder=workspace:FindFirstChild("HirukuTestCoins")
    if not folder then return end
    for _,obj in ipairs(folder:GetChildren()) do
        if isTestCoin(obj) and not coinHighlights[obj] then
            local h=add(Instance.new("Highlight"))
            h.Name="HirukuCoinRadar"
            h.Adornee=obj:IsA("Model") and obj or nil
            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            h.FillColor=Color3.fromRGB(245,245,245)
            h.OutlineColor=Color3.fromRGB(180,180,180)
            h.FillTransparency=.55
            h.Parent=gui
            coinHighlights[obj]=h
        end
    end
end

-- Main loop
local roleTick=0
local antiAFKTick=0

conn(RunService.Heartbeat:Connect(function(dt)
    if not S.alive then return end

    if S.FOVEnabled then
        fov.Visible=true
        updateFov()
    else
        fov.Visible=false
    end

    antiAFKTick+=dt
    if S.AntiAFK and antiAFKTick>=45 then
        antiAFKTick=0
        pcall(function()
            local vu=game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end

    roleTick+=dt
    if roleTick>=.30 then
        roleTick=0
        if S.Chams or S.RoleLabels then
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr~=LocalPlayer then
                    applyVisual(plr)
                end
            end
        end
        rebuildTargets()
    end

    local root,hum=getRootHum()
    if not root or not hum then return end

    if S.AimEnabled then
        local target=getAimTarget()
        if target then
            local desired=CFrame.lookAt(Camera.CFrame.Position,target.Position)
            Camera.CFrame=Camera.CFrame:Lerp(desired,math.clamp(1-S.AimSmooth,0,1))
        end
    end

    if S.saved.WalkSpeed==nil then S.saved.WalkSpeed=hum.WalkSpeed end
    if S.saved.JumpPower==nil then S.saved.JumpPower=hum.JumpPower end

    if S.BunnyHop then
        hum.WalkSpeed=S.BunnySpeed
        if hum.FloorMaterial~=Enum.Material.Air then
            hum.Jump=true
            if S.BunnyAutoStrafe and hum.MoveDirection.Magnitude>0 then
                local md=hum.MoveDirection
                root.AssemblyLinearVelocity=Vector3.new(md.X*S.BunnySpeed,root.AssemblyLinearVelocity.Y,md.Z*S.BunnySpeed)
            end
        end
    elseif S.saved.WalkSpeed and not S.Fly then
        hum.WalkSpeed=S.saved.WalkSpeed
    end

    if S.NoClip then
        for _,part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide=false end
        end
    end

    if S.Spin then
        root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(S.SpinSpeed*dt*60),0)
    end

    flyControls.Visible=S.Fly
    if S.Fly then
        local cf=Camera.CFrame
        local dir=hum.MoveDirection
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=-cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=-cf.RightVector end
        dir=Vector3.new(dir.X,0,dir.Z)
        local vertical=S.FlyVertical
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical=1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical=-1 end
        dir=dir+Vector3.new(0,vertical,0)
        if dir.Magnitude>0 then root.AssemblyLinearVelocity=dir.Unit*S.FlySpeed else root.AssemblyLinearVelocity=Vector3.zero end
    end

    -- Private target movement tester.
    if S.TargetMovement and authorized(S.selected) then
        local targetRoot=S.selected:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local offset=targetRoot.Position-root.Position
            if offset.Magnitude>8 then
                root.AssemblyLinearVelocity=offset.Unit*S.TargetMovementSpeed
            elseif offset.Magnitude<4 then
                root.AssemblyLinearVelocity=-offset.Unit*S.TargetMovementSpeed
            end
        end
    end

    if S.TestCoinFarm then
        local coin=nearestTestCoin(root)
        local pos=coin and coinPosition(coin)
        if pos then
            -- Direct movement is intentionally limited to the private HirukuTestCoins set.
            root.CFrame=CFrame.new(pos + Vector3.new(0,2.5,0), pos)
        end
    end

    updateCoinRadar(root)
end))

-- Notification
local toast=newFrame(gui,Color3.fromRGB(10,10,10),.12)
toast.AnchorPoint=Vector2.new(0,1)
toast.Position=UDim2.new(0,-275,1,-18)
toast.Size=UDim2.new(0,258,0,38)
toast.ZIndex=150
uiCorner(toast,12)
uiStroke(toast,.84)

local toastText=text(toast,"Hiruku Script successfully injected",10,Enum.Font.GothamMedium)
toastText.Size=UDim2.fromScale(1,1)
toastText.TextXAlignment=Enum.TextXAlignment.Center
toastText.ZIndex=151

tw(toast,.42,{Position=UDim2.new(0,18,1,-18)})
task.delay(3,function()
    if toast.Parent then
        tw(toast,.35,{Position=UDim2.new(0,-275,1,-18)},Enum.EasingStyle.Quint,Enum.EasingDirection.In)
    end
end)

print("[Hiruku] MM2 private-test build loaded.")
