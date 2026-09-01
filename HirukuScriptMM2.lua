--// HIRUKU MM2 V14
--// Mobile movement, Coin farming, pickup routing and animated typography refresh.
--// Mobile-first Roblox UI
--// Features: animated menu, themes, fonts, role-aware visuals, aim assist,
--// movement utilities, coin collection, weapon pickup, target movement and
--// cleanup-safe rerun handling.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--==================================================
-- CONFIG / STATE
--==================================================

local GKEY = "__HIRUKU_MM2_V12"
pcall(function()
    if _G[GKEY] and _G[GKEY].Cleanup then
        _G[GKEY].Cleanup()
    end
end)

local S = {
    Open = false,
    Page = "Combat",

    SilentAim = false,
    SilentFOV = 180,
    SilentSmooth = 0.18,
    SilentLOS = true,
    SilentPlayers = true,
    SilentNPC = true,

    AutoShot = false,
    FOV = false,

    KillAura = false,
    KillSelected = false,
    KillAll = false,
    SelectedPlayer = nil,
    AttackRange = 14,
    AttackCooldown = 0.35,

    Chams = false,
    RoleLabels = true,
    Watermark = false,
    EspGun = false,
    Crosshair = false,
    Fullbright = false,

    Fly = false,
    FlySpeed = 55,
    FlyVertical = 0,

    BunnyHop = false,
    BunnySpeed = 22,
    BunnyAccel = 4,
    BunnyAirControl = 0.55,
    BunnyAutoStrafe = true,
    BunnyCurrentSpeed = 16,

    NoClip = false,
    Spin = false,
    SpinSpeed = 180,

    TargetAura = false,
    TargetAuraPlayer = nil,
    TargetAuraSpeed = 55,

    CoinFarm = false,
    CoinSpeed = 65,
    CoinRadius = 999999,

    AutoPickupGun = false,

    AntiAFK = false,

    Theme = "Obsidian",
    Font = "Gotham",
    UIScale = 1.0,
    MenuOpacity = .90,
    Language = "English",

    _saved = {},
}

local CONNS = {}
local INSTANCES = {}
local CHAMS = {}
local ROLE_LABELS = {}
local GUN_ESPS = {}
local DRAG = {active=false, input=nil, start=nil, origin=nil}
local GUI_SCALE_OBJECT = nil
local originalWalkSpeed = nil
local originalJumpPower = nil
local originalAutoRotate = nil
local flyVerticalUntil = 0
local lastGunPickup = 0
local lastCoinHop = 0
local gunEspClock = 0

local function conn(c)
    if c then table.insert(CONNS, c) end
    return c
end

local function addInst(x)
    if x then table.insert(INSTANCES, x) end
    return x
end

local function disconnectAll()
    for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
    table.clear(CONNS)
end

local function destroyAll()
    for _, x in ipairs(INSTANCES) do pcall(function() x:Destroy() end) end
    table.clear(INSTANCES)
end

local function char()
    return LocalPlayer.Character
end

local function humanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function root(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function alive(model)
    local h = humanoid(model)
    return h and h.Health > 0 and root(model) ~= nil
end

local function playerAlive(plr)
    return plr and plr ~= LocalPlayer and alive(plr.Character)
end

--==================================================
-- THEMES / FONTS
--==================================================

local THEMES = {
    Obsidian = {
        bg = Color3.fromRGB(10,10,12),
        panel = Color3.fromRGB(19,19,22),
        card = Color3.fromRGB(26,26,30),
        card2 = Color3.fromRGB(31,31,36),
        text = Color3.fromRGB(245,245,248),
        sub = Color3.fromRGB(165,165,173),
        accent = Color3.fromRGB(225,225,230),
        line = Color3.fromRGB(55,55,62),
        on = Color3.fromRGB(235,235,240),
        off = Color3.fromRGB(55,55,62),
        onDot = Color3.fromRGB(20,20,22),
        offDot = Color3.fromRGB(180,180,185),
    },
    Midnight = {
        bg = Color3.fromRGB(8,13,22),
        panel = Color3.fromRGB(14,21,33),
        card = Color3.fromRGB(20,29,43),
        card2 = Color3.fromRGB(25,35,51),
        text = Color3.fromRGB(240,246,255),
        sub = Color3.fromRGB(154,169,190),
        accent = Color3.fromRGB(150,195,255),
        line = Color3.fromRGB(48,65,88),
        on = Color3.fromRGB(165,205,255),
        off = Color3.fromRGB(50,64,82),
        onDot = Color3.fromRGB(12,20,32),
        offDot = Color3.fromRGB(170,185,205),
    },
    Violet = {
        bg = Color3.fromRGB(15,10,21),
        panel = Color3.fromRGB(25,16,34),
        card = Color3.fromRGB(34,22,45),
        card2 = Color3.fromRGB(42,27,55),
        text = Color3.fromRGB(249,243,255),
        sub = Color3.fromRGB(184,165,197),
        accent = Color3.fromRGB(218,170,255),
        line = Color3.fromRGB(70,49,82),
        on = Color3.fromRGB(226,190,255),
        off = Color3.fromRGB(67,48,77),
        onDot = Color3.fromRGB(25,15,34),
        offDot = Color3.fromRGB(195,175,205),
    },
    Crimson = {
        bg = Color3.fromRGB(19,8,9),
        panel = Color3.fromRGB(29,13,15),
        card = Color3.fromRGB(40,18,21),
        card2 = Color3.fromRGB(49,21,25),
        text = Color3.fromRGB(255,246,246),
        sub = Color3.fromRGB(193,161,164),
        accent = Color3.fromRGB(255,170,177),
        line = Color3.fromRGB(82,43,47),
        on = Color3.fromRGB(255,184,190),
        off = Color3.fromRGB(74,44,47),
        onDot = Color3.fromRGB(30,12,15),
        offDot = Color3.fromRGB(205,175,178),
    },
    Mono = {
        bg = Color3.fromRGB(22,22,22),
        panel = Color3.fromRGB(29,29,29),
        card = Color3.fromRGB(39,39,39),
        card2 = Color3.fromRGB(46,46,46),
        text = Color3.fromRGB(255,255,255),
        sub = Color3.fromRGB(165,165,165),
        accent = Color3.fromRGB(255,255,255),
        line = Color3.fromRGB(65,65,65),
        on = Color3.fromRGB(245,245,245),
        off = Color3.fromRGB(58,58,58),
        onDot = Color3.fromRGB(20,20,20),
        offDot = Color3.fromRGB(190,190,190),
    },
}

local FONT_MAP = {
    Gotham = Enum.Font.Gotham,
    GothamBold = Enum.Font.GothamBold,
    SourceSans = Enum.Font.SourceSans,
    SourceSansBold = Enum.Font.SourceSansBold,
    Arial = Enum.Font.Arial,
    Code = Enum.Font.Code,
    Cartoon = Enum.Font.Cartoon,
    Fantasy = Enum.Font.Fantasy,
    SciFi = Enum.Font.SciFi,
    Bangers = Enum.Font.Bangers,
}

local function T()
    return THEMES[S.Theme] or THEMES.Obsidian
end

--==================================================
-- GUI HELPERS
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "Hiruku"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.DisplayOrder = 999999 end)
gui.Parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
addInst(gui)

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
    return c
end

local function stroke(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

local function frame(parent, size, pos, color, trans, z)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = color or T().panel
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    f.Size = size
    f.Position = pos
    f.ZIndex = z or 10
    f.Parent = parent
    return f
end

local function label(parent, text, size, pos, fontSize, color, z, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or T().text
    l.TextSize = fontSize or 14
    l.Font = FONT_MAP[S.Font] or Enum.Font.Gotham
    l.Size = size
    l.Position = pos
    l.ZIndex = z or 20
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function button(parent, text, size, pos, z)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = text
    b.TextColor3 = T().text
    b.TextSize = 13
    b.Font = FONT_MAP[S.Font] or Enum.Font.Gotham
    b.TextTruncate = Enum.TextTruncate.AtEnd
    b.BackgroundColor3 = T().card
    b.BackgroundTransparency = 0
    b.BorderSizePixel = 0
    b.Size = size
    b.Position = pos
    b.ZIndex = z or 20
    b.Parent = parent
    corner(b, 9)
    return b
end

local function tween(obj, duration, props, style, direction)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(duration or .2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function scaleGui()
    if not gui then return end
    if not GUI_SCALE_OBJECT or not GUI_SCALE_OBJECT.Parent then
        GUI_SCALE_OBJECT = gui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
        GUI_SCALE_OBJECT.Name = "HirukuScale"
        GUI_SCALE_OBJECT.Parent = gui
    end
    GUI_SCALE_OBJECT.Scale = math.clamp(S.UIScale, 0.80, 1.20)
end

--==================================================
-- OPEN/CLOSE PILL
--==================================================

local pill = frame(gui, UDim2.fromOffset(148,46), UDim2.new(0,22,0.5,-23), T().panel, .08, 100)
corner(pill, 23)
stroke(pill, T().line, .15)
local pillText = label(pill, "Hiruku", UDim2.fromScale(1,1), UDim2.fromOffset(0,0), 15, T().text, 105, Enum.TextXAlignment.Center)

--==================================================
-- MAIN WINDOW
--==================================================

local main = frame(gui, UDim2.fromOffset(760,510), UDim2.new(.5,-380,.5,-255), T().panel, .18, 200)
corner(main, 18)
main.BackgroundTransparency=1-S.MenuOpacity
stroke(main, T().line, .1, 1)

local glass = frame(main, UDim2.fromScale(1,1), UDim2.fromScale(0,0), T().panel, .42, 201)
corner(glass,18)

-- Frosted-glass layers: blur stays visually contained inside the menu.
-- No Lighting BlurEffect is used, so the actual game view remains sharp.
local frostA = frame(main, UDim2.new(1,-6,1,-6), UDim2.fromOffset(3,3), Color3.fromRGB(255,255,255), .965, 202)
corner(frostA,16)
local frostB = frame(main, UDim2.new(1,-18,1,-18), UDim2.fromOffset(9,9), Color3.fromRGB(255,255,255), .985, 203)
corner(frostB,14)

local title = label(main, "Hiruku", UDim2.fromOffset(260,34), UDim2.fromOffset(24,18), 23, T().text, 220)
local version = label(main, "MM2 - v 1.0", UDim2.fromOffset(180,20), UDim2.fromOffset(25,50), 11, T().sub, 220)

local function addAnimatedTextGradient(obj)
    local g = Instance.new("UIGradient")
    g.Name = "HirukuTextGradient"
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.28, Color3.fromRGB(220,220,220)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(15,15,15)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(220,220,220)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,255,255)),
    })
    g.Offset = Vector2.new(-1,0)
    g.Parent = obj
    obj.TextStrokeColor3 = Color3.fromRGB(255,255,255)
    obj.TextStrokeTransparency = 0.72
    task.spawn(function()
        while obj.Parent do
            g.Offset = Vector2.new(-1,0)
            local tw = TweenService:Create(g,TweenInfo.new(2.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Offset=Vector2.new(1,0)})
            tw:Play()
            tw.Completed:Wait()
            task.wait(.12)
        end
    end)
    return g
end

addAnimatedTextGradient(title)
addAnimatedTextGradient(version)

local search = Instance.new("TextBox")
search.PlaceholderText = "Search feature..."
search.ClearTextOnFocus = false
search.Active = true
search.Text = ""
search.TextColor3 = T().text
search.PlaceholderColor3 = T().sub
search.TextSize = 13
search.Font = FONT_MAP[S.Font] or Enum.Font.Gotham
search.BackgroundColor3 = T().card
search.BackgroundTransparency = .08
search.BorderSizePixel = 0
search.Size = UDim2.new(1,-48,0,38)
search.Position = UDim2.fromOffset(24,82)
search.ZIndex = 225
search.Parent = main
corner(search,19)

local nav = frame(main, UDim2.fromOffset(150,340), UDim2.fromOffset(20,135), Color3.new(0,0,0), 1, 225)
corner(nav,12)
local content = frame(main, UDim2.new(1,-190,1,-150), UDim2.fromOffset(174,135), Color3.new(0,0,0), 1, 225)

local pages = {}
local navButtons = {}
local pageLayout = {}
local pageCursor = {}

local pageNames = {"Combat","Visuals","Misc","Settings"}

for i, name in ipairs(pageNames) do
    local y = (i-1)*72
    local nb = button(nav, name, UDim2.new(1,-8,0,56), UDim2.fromOffset(4,y), 230)
    navButtons[name] = nb

    local pg = Instance.new("ScrollingFrame")
    pg.Name = name .. "Page"
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0
    pg.Size = UDim2.fromScale(1,1)
    pg.Position = UDim2.fromOffset(0,0)
    pg.ScrollBarThickness = 3
    pg.ScrollBarImageTransparency = .35
    pg.CanvasSize = UDim2.new(0,0,0,0)
    pg.ScrollingDirection = Enum.ScrollingDirection.Y
    pg.ZIndex = 225
    pg.Parent = content
    pages[name] = pg
    pageLayout[name] = {}
    pageCursor[name] = 0
end

local function updateResponsiveLayout()
    local mw=main.AbsoluteSize.X
    local navW=math.clamp(mw*.22,132,160)
    nav.Size=UDim2.fromOffset(navW,math.max(250,main.AbsoluteSize.Y-155))
    content.Position=UDim2.fromOffset(navW+24,135)
    content.Size=UDim2.new(1,-navW-44,1,-150)
end

local close = button(main, "×", UDim2.fromOffset(38,38), UDim2.new(1,-58,0,18), 230)
close.TextSize = 22

--==================================================
-- MOBILE DRAGGING
--==================================================

local dragArea = Instance.new("TextButton")
dragArea.Name = "DragArea"
dragArea.Text = ""
dragArea.AutoButtonColor = false
dragArea.BackgroundTransparency = 1
dragArea.Size = UDim2.new(1,-105,0,72)
dragArea.Position = UDim2.fromOffset(8,5)
dragArea.ZIndex = 260
dragArea.Active = true
dragArea.Selectable = false
dragArea.Parent = main

local function beginDrag(input)
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    DRAG.active = true
    DRAG.input = input
    DRAG.start = input.Position
    DRAG.origin = main.Position
end

conn(dragArea.InputBegan:Connect(beginDrag))
conn(dragArea.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        DRAG.input = input
    end
end))
conn(UIS.InputChanged:Connect(function(input)
    if not DRAG.active or not DRAG.start or not DRAG.origin then return end
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local delta = input.Position - DRAG.start
    local vp = Camera.ViewportSize
    local x = math.clamp(DRAG.origin.X.Offset + delta.X, -main.AbsoluteSize.X + 80, vp.X - 80)
    local y = math.clamp(DRAG.origin.Y.Offset + delta.Y, 10, vp.Y - 60)
    main.Position = UDim2.fromOffset(x,y)
end))
conn(UIS.InputEnded:Connect(function(input)
    if input == DRAG.input or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        DRAG.active = false
        DRAG.input = nil
        DRAG.start = nil
        DRAG.origin = nil
    end
end))

--==================================================
-- NOTIFICATION
--==================================================

local toast = frame(gui, UDim2.fromOffset(300,52), UDim2.new(0,18,1,-72), T().panel, .08, 500)
corner(toast, 16)
stroke(toast, T().line, .1)
local toastText = label(toast, "Hiruku loaded", UDim2.new(1,-28,1,0), UDim2.fromOffset(14,0), 13, T().text, 505)

local function notify(text)
    if S._showNotifications==false then return end
    toastText.Text = text
    toast.Position = UDim2.new(0,-320,1,-72)
    tween(toast,.35,{Position=UDim2.new(0,18,1,-72)})
    task.delay(2.5,function()
        tween(toast,.3,{Position=UDim2.new(0,-320,1,-72)})
    end)
end

--==================================================
-- OPEN / CLOSE ANIMATION
--==================================================

main.Visible = false
local menuAnimating = false
local drawer

local function menuTargetSize()
    local vp = Camera.ViewportSize
    local scale = math.clamp(S.UIScale, .80, 1.20)
    local w = math.min(760, math.max(340, (vp.X - 20) / scale))
    local h = math.min(510, math.max(400, (vp.Y - 20) / scale))
    return UDim2.fromOffset(w, h)
end

local function animateMenuElements(show)
    local titleAlpha = show and 0 or 1
    local versionAlpha = show and 0 or 1
    tween(title,.22,{TextTransparency=titleAlpha},Enum.EasingStyle.Quart)
    tween(version,.22,{TextTransparency=versionAlpha},Enum.EasingStyle.Quart)
    tween(search,.22,{BackgroundTransparency=show and .08 or 1,TextTransparency=show and 0 or 1},Enum.EasingStyle.Quart)
    for _,b in pairs(navButtons) do
        tween(b,.22,{BackgroundTransparency=show and 0 or 1,TextTransparency=show and 0 or 1},Enum.EasingStyle.Quart)
    end
end

local function openMenu()
    if S.Open or menuAnimating then return end
    menuAnimating = true
    S.Open = true
    scaleGui()
    local target = menuTargetSize()
    local vp = Camera.ViewportSize
    local tw = target.X.Offset
    local th = target.Y.Offset
    local x = math.clamp((vp.X-tw)/2, 8, math.max(8,vp.X-tw-8))
    local y = math.clamp((vp.Y-th)/2, 8, math.max(8,vp.Y-th-8))
    main.Position = UDim2.fromOffset(x, y + th/2)
    main.Size = UDim2.fromOffset(tw, 0)
    main.Visible = true
    main.BackgroundTransparency = 1-S.MenuOpacity
    animateMenuElements(true)
    local t = tween(main,.34,{Position=UDim2.fromOffset(x,y),Size=target,BackgroundTransparency=1-S.MenuOpacity},Enum.EasingStyle.Quint)
    t.Completed:Connect(function()
        menuAnimating = false
    end)
end

local function closeMenu()
    if drawer and drawer.Visible then
        drawer.Visible = false
    end
    if not S.Open or menuAnimating then
        return
    end
    menuAnimating = true
    S.Open = false
    -- Close any open settings drawer at the same time.
    if drawer and drawer.Visible then
        drawer.Visible = false
    end
    animateMenuElements(false)
    local pos = main.Position
    local size = main.AbsoluteSize
    local scaledW = math.max(320, size.X / math.max(S.UIScale,.01))
    local scaledH = math.max(0, size.Y / math.max(S.UIScale,.01))
    local targetY = pos.Y.Offset + scaledH/2
    local t = tween(main,.28,{
        Position=UDim2.fromOffset(pos.X.Offset,targetY),
        Size=UDim2.fromOffset(scaledW,0),
        BackgroundTransparency=1-S.MenuOpacity
    },Enum.EasingStyle.Quint)
    t.Completed:Connect(function()
        if not S.Open then main.Visible=false end
        menuAnimating=false
    end)
end

conn(pill.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        if S.Open then closeMenu() else openMenu() end
    end
end))
conn(close.Activated:Connect(closeMenu))

--==================================================
-- CARD / TOGGLE / SLIDER
--==================================================

local function pageKey(parent)
    if parent == drawerBody then return "__drawer" end
    for name, pg in pairs(pages) do
        if pg == parent then return name end
    end
    return S.Page
end

local function updateCanvas(parent,key)
    if pages[key] then
        pages[key].CanvasSize = UDim2.new(0,0,0,(pageCursor[key] or 0)+12)
    elseif parent == drawerBody then
        drawerBody.CanvasSize = UDim2.new(0,0,0,(pageCursor[key] or 0)+12)
    end
end

local function section(parent, text, y)
    local key=pageKey(parent)
    pageCursor[key]=(pageCursor[key] or 0)+8
    local yy=pageCursor[key]
    local h = label(parent,text,UDim2.new(1,-10,0,22),UDim2.fromOffset(5,yy),11,T().sub,240)
    h.TextTransparency = .05
    pageCursor[key]=yy+30
    if pages[key] then pages[key].CanvasSize=UDim2.new(0,0,0,pageCursor[key]+12) end
    return h
end

local function toggleCard(parent, name, desc, get, set, settingsFn)
    local key=pageKey(parent)
    local y = pageCursor[key] or 0
    pageCursor[key]=y+76
    updateCanvas(parent,key)
    table.insert(pageLayout[key] or {}, true)

    local c = frame(parent, UDim2.new(1,-10,0,68), UDim2.fromOffset(5,y), T().card, .02, 235)
    corner(c,11)
    local n = label(c,name,UDim2.new(1,-112,0,22),UDim2.fromOffset(14,7),13,T().text,240)
    local d = label(c,desc,UDim2.new(1,-112,0,19),UDim2.fromOffset(14,34),10,T().sub,240)
    d.TextTruncate = Enum.TextTruncate.AtEnd

    local sw = button(c,"",UDim2.fromOffset(44,24),UDim2.new(1,-58,.5,-12),245)
    corner(sw,13)

    local dot = frame(sw,UDim2.fromOffset(16,16),UDim2.fromOffset(4,4),T().offDot,0,246)
    corner(dot,8)

    local function refresh()
        local on = get()
        sw.BackgroundColor3 = on and T().on or T().off
        dot.BackgroundColor3 = on and T().onDot or T().offDot
        tween(dot,.16,{Position=on and UDim2.new(1,-20,.5,-8) or UDim2.fromOffset(4,4)})
    end

    local function activate()
        local v = not get()
        set(v)
        refresh()
    end

    conn(sw.Activated:Connect(activate))
    conn(c.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            -- Card itself is touch-friendly, but do not steal drag input from the window.
        end
    end))

    if settingsFn then
        local setBtn = button(c,"SET",UDim2.fromOffset(36,20),UDim2.new(1,-99,.5,-10),244)
        setBtn.TextSize = 9
        setBtn.BackgroundTransparency = .35
        conn(setBtn.Activated:Connect(settingsFn))
    end

    refresh()
    return c
end

local function sliderCard(parent, name, min, max, get, set)
    local key=pageKey(parent)
    local y = pageCursor[key] or 0
    pageCursor[key]=y+76
    updateCanvas(parent,key)
    table.insert(pageLayout[key] or {}, true)

    local c = frame(parent, UDim2.new(1,-10,0,68), UDim2.fromOffset(5,y), T().card, .02,235)
    corner(c,11)
    local n = label(c,name,UDim2.new(.45,0,1,0),UDim2.fromOffset(14,0),13,T().text,240)
    local value = label(c,"",UDim2.fromOffset(70,20),UDim2.new(1,-84,.5,-10),11,T().sub,240,Enum.TextXAlignment.Right)

    local bar = frame(c,UDim2.fromOffset(170,6),UDim2.new(1,-195,.5,-3),T().off,0,240)
    corner(bar,3)
    local fill = frame(bar,UDim2.fromScale(0,1),UDim2.fromOffset(0,0),T().accent,0,241)
    corner(fill,3)
    local knob = frame(bar,UDim2.fromOffset(16,16),UDim2.new(0,-8,.5,-8),T().accent,0,242)
    corner(knob,8)

    local dragging = false
    local function updateX(x)
        local pct = math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local val = min + (max-min)*pct
        set(val)
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,-8,.5,-8)
        value.Text = tostring(math.floor(val+0.5))
    end

    conn(bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateX(i.Position.X)
        end
    end))
    conn(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            updateX(i.Position.X)
        end
    end))
    conn(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end))

    local function refresh()
        local v = get()
        local pct = math.clamp((v-min)/(max-min),0,1)
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,-8,.5,-8)
        value.Text = tostring(math.floor(v+0.5))
    end
    refresh()
    return c
end

--==================================================
-- DRAWERS
--==================================================

drawer = frame(gui, UDim2.fromOffset(320,360), UDim2.new(.5,390,.5,-180), T().panel, .03, 700)
corner(drawer,16)
stroke(drawer,T().line,.08)
drawer.Visible = false

local drawerTitle = label(drawer,"Settings",UDim2.new(1,-60,0,32),UDim2.fromOffset(18,15),17,T().text,710)
local drawerClose = button(drawer,"×",UDim2.fromOffset(32,32),UDim2.new(1,-47,0,12),710)
local drawerBody = Instance.new("ScrollingFrame")
drawerBody.BackgroundTransparency = 1
drawerBody.BorderSizePixel = 0
drawerBody.Size = UDim2.new(1,-24,1,-62)
drawerBody.Position = UDim2.fromOffset(12,54)
drawerBody.ScrollBarThickness = 3
drawerBody.ScrollBarImageTransparency = .4
drawerBody.CanvasSize = UDim2.new(0,0,0,0)
drawerBody.ScrollingDirection = Enum.ScrollingDirection.Y
drawerBody.ZIndex = 705
drawerBody.Parent = drawer

local drawerCursor = 0

local function clearDrawer()
    for _, x in ipairs(drawerBody:GetChildren()) do
        x:Destroy()
    end
    drawerCursor = 0
    drawerBody.CanvasPosition = Vector2.zero
    drawerBody.CanvasSize = UDim2.new(0,0,0,0)
end

local function openDrawer(titleText, builder)
    clearDrawer()
    drawerTitle.Text = titleText
    drawer.Visible = true
    drawer.Size = UDim2.fromOffset(320,0)
    tween(drawer,.25,{Size=UDim2.fromOffset(320,360)},Enum.EasingStyle.Quint)
    builder()
    local maxY = 0
    for _,o in ipairs(drawerBody:GetChildren()) do
        if o:IsA("GuiObject") then
            maxY = math.max(maxY, o.Position.Y.Offset + o.Size.Y.Offset + 10)
        end
    end
    drawerBody.CanvasSize = UDim2.new(0,0,0,maxY)
end

local function closeDrawer()
    if not drawer.Visible then return end
    local targetX = drawer.Position.X.Offset
    local targetY = drawer.Position.Y.Offset
    tween(drawer,.18,{Size=UDim2.fromOffset(320,0),BackgroundTransparency=.35},Enum.EasingStyle.Quint)
    task.delay(.19,function()
        if drawer then drawer.Visible=false end
    end)
end
conn(drawerClose.Activated:Connect(closeDrawer))

local function drawerToggle(text, get, set, y)
    local b = button(drawerBody,text,UDim2.new(1,0,0,42),UDim2.fromOffset(0,y),710)
    local function refresh()
        b.Text = text.."   ["..(get() and "ON" or "OFF").."]"
        b.TextColor3 = get() and T().text or T().sub
    end
    conn(b.Activated:Connect(function() set(not get()); refresh() end))
    drawerBody.CanvasSize = UDim2.new(0,0,0,math.max(drawerBody.CanvasSize.Y.Offset,y+50))
    refresh()
end

--==================================================
-- PAGES
--==================================================

local function resetPage(pageName)
    for _, x in ipairs(pages[pageName]:GetChildren()) do
        x:Destroy()
    end
    pageLayout[pageName] = {}
    pageCursor[pageName] = 0
    pages[pageName].CanvasPosition = Vector2.zero
    pages[pageName].CanvasSize = UDim2.new(0,0,0,0)
end

local function setPage(name)
    S.Page = name
    -- Never let an old search query make a new page look empty.
    search.Text = ""
    for p, pg in pairs(pages) do
        pg.Visible = (p == name)
        pg.Active = (p == name)
        pg.ZIndex = 225
    end
    for p, b in pairs(navButtons) do
        b.BackgroundColor3 = p == name and T().card2 or T().card
        b.TextColor3 = p == name and T().text or T().sub
        b.ZIndex = 230
    end
    if pages[name] then
        pages[name].CanvasPosition = Vector2.zero
        pages[name].CanvasSize = UDim2.new(0,0,0,(pageCursor[name] or 0)+16)
    end
end

for name,b in pairs(navButtons) do
    conn(b.Activated:Connect(function() setPage(name) end))
end

--==================================================
-- COMBAT
--==================================================

resetPage("Combat")
local combat = pages.Combat
section(combat,"SHERIFF",4)

toggleCard(combat,"Silent Aim","Camera aim assist inside FOV",function() return S.SilentAim end,function(v) S.SilentAim=v end,function()
    openDrawer("Silent Aim",function()
        local y=4
        local function dt(t,get,set)
            drawerToggle(t,get,set,y); y=y+48
        end
        -- sliders are custom in drawer for better mobile hit targets
        local function dslider(t,min,max,get,set)
            local c=frame(drawerBody,UDim2.new(1,0,0,52),UDim2.fromOffset(0,y),T().card,.02,710)
            corner(c,9)
            label(c,t,UDim2.new(.45,0,1,0),UDim2.fromOffset(10,0),11,T().text,715)
            local val=label(c,"",UDim2.fromOffset(65,20),UDim2.new(1,-75,.5,-10),10,T().sub,715,Enum.TextXAlignment.Right)
            local bar=frame(c,UDim2.fromOffset(145,5),UDim2.new(1,-160,.5,-2),T().off,0,715); corner(bar,3)
            local fill=frame(bar,UDim2.fromScale(0,1),UDim2.fromOffset(0,0),T().accent,0,716); corner(fill,3)
            local drag=false
            local function upd(x)
                local p=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
                set(min+(max-min)*p)
                fill.Size=UDim2.new(p,0,1,0)
                val.Text=string.format("%.2f",get())
            end
            conn(bar.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(i.Position.X) end
            end))
            conn(UIS.InputChanged:Connect(function(i)
                if drag and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then upd(i.Position.X) end
            end))
            conn(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end))
            y=y+58
        end
        dslider("FOV",40,500,function() return S.SilentFOV end,function(v) S.SilentFOV=v end)
        dslider("Smooth",.05,.75,function() return S.SilentSmooth end,function(v) S.SilentSmooth=v end)
        dt("Line of sight",function() return S.SilentLOS end,function(v) S.SilentLOS=v end)
        dt("Players",function() return S.SilentPlayers end,function(v) S.SilentPlayers=v end)
        dt("NPC",function() return S.SilentNPC end,function(v) S.SilentNPC=v end)
    end)
end)

toggleCard(combat,"Auto Shot Murder","Automatic shot trigger when a valid murderer is detected",function() return S.AutoShot end,function(v) S.AutoShot=v end)

toggleCard(combat,"FOV","Display Silent Aim field of view",function() return S.FOV end,function(v) S.FOV=v end,function()
    openDrawer("FOV",function()
        sliderCard(drawerBody,"FOV radius",50,500,function() return S.SilentFOV end,function(v) S.SilentFOV=v end)
    end)
end)

section(combat,"MURDER",220)

toggleCard(combat,"Kill Aura","Keep knife ready and attack targets in range",function() return S.KillAura end,function(v) S.KillAura=v end,function()
    openDrawer("Kill Aura",function()
        sliderCard(drawerBody,"Attack range",6,22,function() return S.AttackRange end,function(v) S.AttackRange=v end)
        sliderCard(drawerBody,"Cooldown",1,10,function() return S.AttackCooldown*10 end,function(v) S.AttackCooldown=v/10 end)
    end)
end)

toggleCard(combat,"Kill Selected","Attack the selected player when in knife range",function() return S.KillSelected end,function(v) S.KillSelected=v end,function()
    openDrawer("Kill Selected",function()
        local y=4
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then
                local b=button(drawerBody,plr.DisplayName.."  @"..plr.Name,UDim2.new(1,0,0,38),UDim2.fromOffset(0,y),710)
                b.TextColor3=(S.SelectedPlayer==plr and T().text or T().sub)
                conn(b.Activated:Connect(function()
                    S.SelectedPlayer=plr
                    notify("Selected: "..plr.Name)
                    for _,q in ipairs(drawerBody:GetChildren()) do
                        if q:IsA("TextButton") then q.TextColor3=T().sub end
                    end
                    b.TextColor3=T().text
                end))
                y=y+42
            end
        end
    end)
end)

toggleCard(combat,"Kill All","Attack every valid player in knife range",function() return S.KillAll end,function(v) S.KillAll=v end)

--==================================================
-- VISUALS
--==================================================

resetPage("Visuals")
local visuals=pages.Visuals
section(visuals,"PLAYER VISUALS",4)
toggleCard(visuals,"Chams","Role-aware player highlights",function() return S.Chams end,function(v) S.Chams=v end)
toggleCard(visuals,"Role Labels","Show player name and detected role",function() return S.RoleLabels end,function(v) S.RoleLabels=v end)
toggleCard(visuals,"Watermark","Hiruku • FPS • player • ping",function() return S.Watermark end,function(v) S.Watermark=v end)
toggleCard(visuals,"ESP Gun","Highlight dropped guns on the map in orange",function() return S.EspGun end,function(v) S.EspGun=v end)
toggleCard(visuals,"Crosshair","Minimal center reticle",function() return S.Crosshair end,function(v) S.Crosshair=v end)
toggleCard(visuals,"Fullbright","Maximum local lighting",function() return S.Fullbright end,function(v) S.Fullbright=v end)
section(visuals,"COINS",350)
toggleCard(visuals,"Coin Radar","Mark objects named Coin",function() return false end,function(v) end)

--==================================================
-- MISC
--==================================================

resetPage("Misc")
local misc=pages.Misc
section(misc,"MOVEMENT",4)

toggleCard(misc,"Fly","Joystick movement + jump to rise",function() return S.Fly end,function(v)
    S.Fly=v
    if v then
        local h=humanoid(char())
        if h then originalWalkSpeed=h.WalkSpeed end
    end
end,function()
    openDrawer("Fly",function()
        sliderCard(drawerBody,"Fly speed",15,120,function() return S.FlySpeed end,function(v) S.FlySpeed=v end)
    end)
end)

toggleCard(misc,"Bunny Hop","CS-style jump acceleration with joystick",function() return S.BunnyHop end,function(v)
    S.BunnyHop=v
    local h=humanoid(char())
    if v then
        if h then originalWalkSpeed=h.WalkSpeed end
        S.BunnyCurrentSpeed=h and h.WalkSpeed or 16
    elseif h then
        h.WalkSpeed=originalWalkSpeed or 16
    end
end,function()
    openDrawer("Bunny Hop",function()
        sliderCard(drawerBody,"Max speed",16,80,function() return S.BunnySpeed end,function(v) S.BunnySpeed=v end)
        sliderCard(drawerBody,"Acceleration",1,15,function() return S.BunnyAccel end,function(v) S.BunnyAccel=v end)
        sliderCard(drawerBody,"Air control",0,1,function() return S.BunnyAirControl end,function(v) S.BunnyAirControl=v end)
        drawerToggle("Auto strafe",function() return S.BunnyAutoStrafe end,function(v) S.BunnyAutoStrafe=v end,190)
    end)
end)

toggleCard(misc,"No Clip","Disable character collisions",function() return S.NoClip end,function(v) S.NoClip=v end)

toggleCard(misc,"Spin","Rotate the character continuously",function() return S.Spin end,function(v) S.Spin=v end,function()
    openDrawer("Spin",function()
        sliderCard(drawerBody,"Spin speed",20,720,function() return S.SpinSpeed end,function(v) S.SpinSpeed=v end)
    end)
end)

section(misc,"TARGET",285)
toggleCard(misc,"Sex Aura","Move rapidly toward the selected player",function() return S.TargetAura end,function(v) S.TargetAura=v end,function()
    openDrawer("Target Aura",function()
        sliderCard(drawerBody,"Speed",10,120,function() return S.TargetAuraSpeed end,function(v) S.TargetAuraSpeed=v end)
        local y=62
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then
                local b=button(drawerBody,plr.DisplayName.."  @"..plr.Name,UDim2.new(1,0,0,36),UDim2.fromOffset(0,y),710)
                conn(b.Activated:Connect(function()
                    S.TargetAuraPlayer=plr
                    notify("Target: "..plr.Name)
                end))
                y=y+40
            end
        end
    end)
end)

section(misc,"MM2",500)
toggleCard(misc,"Coin Farm","Find the nearest object named Coin",function() return S.CoinFarm end,function(v) S.CoinFarm=v end,function()
    openDrawer("Coin Farm",function()
        sliderCard(drawerBody,"Move speed",15,120,function() return S.CoinSpeed end,function(v) S.CoinSpeed=v end)
    end)
end)

toggleCard(misc,"Auto Pickup Gun","Instantly attempts supported dropped-gun pickup methods",function() return S.AutoPickupGun end,function(v) S.AutoPickupGun=v end,function()
    openDrawer("Auto Pickup Gun",function()
        drawerToggle("Enabled",function() return S.AutoPickupGun end,function(v) S.AutoPickupGun=v end,4)
        local info=label(drawerBody,"Recognizes GunDrop, Gun, Pistol and DroppedGun objects.",UDim2.new(1,-12,0,42),UDim2.fromOffset(6,58),10,T().sub,715)
        info.TextWrapped=true
        info.TextYAlignment=Enum.TextYAlignment.Top
    end)
end)
toggleCard(misc,"Anti AFK","Keep the client active",function() return S.AntiAFK end,function(v) S.AntiAFK=v end)

--==================================================
-- SETTINGS
--==================================================

resetPage("Settings")
local settings=pages.Settings
section(settings,"INTERFACE",4)

toggleCard(settings,"Language","English / Russian",function() return S.Language=="Russian" end,function(v) S.Language=v and "Russian" or "English" end)

toggleCard(settings,"Theme","Choose a visual theme",function() return false end,function(v) end,function()
    openDrawer("Themes",function()
        local y=4
        for name in pairs(THEMES) do
            local b=button(drawerBody,name,UDim2.new(1,0,0,42),UDim2.fromOffset(0,y),710)
            b.TextColor3=name==S.Theme and T().text or T().sub
            conn(b.Activated:Connect(function()
                S.Theme=name
                notify("Theme: "..name)
                -- refresh is handled by the theme pass below
            end))
            y=y+47
        end
    end)
end)

toggleCard(settings,"Font","Change menu typography",function() return false end,function(v) end,function()
    openDrawer("Fonts",function()
        local y=4
        for name in pairs(FONT_MAP) do
            local b=button(drawerBody,name,UDim2.new(1,0,0,36),UDim2.fromOffset(0,y),710)
            b.TextColor3=name==S.Font and T().text or T().sub
            conn(b.Activated:Connect(function()
                S.Font=name
                notify("Font: "..name)
            end))
            y=y+40
        end
    end)
end)

sliderCard(settings,"Interface size",80,120,function() return S.UIScale*100 end,function(v)
    S.UIScale=math.clamp(v/100,.80,1.20)
    scaleGui()
    task.defer(fitWindow)
end)
toggleCard(settings,"Show Notifications","Show status messages in the lower-left",function() return S._showNotifications~=false end,function(v) S._showNotifications=v end)
sliderCard(settings,"Menu Opacity",50,95,function() return S.MenuOpacity*100 end,function(v)
    S.MenuOpacity=math.clamp(v/100,.50,.95)
    main.BackgroundTransparency=1-S.MenuOpacity
end)
toggleCard(settings,"Reset Position","Center the menu on the screen",function() return false end,function(v)
    if v then
        local vp=Camera.ViewportSize
        local target=menuTargetSize()
        local scale=math.clamp(S.UIScale,.80,1.20)
        main.Position=UDim2.fromOffset((vp.X-target.X.Offset*scale)/2/scale,(vp.Y-target.Y.Offset*scale)/2/scale)
    end
end)


--==================================================
-- FOV / WATERMARK / CROSSHAIR
--==================================================

local fovCircle=Instance.new("Frame")
fovCircle.BackgroundTransparency=1
fovCircle.Size=UDim2.fromOffset(S.SilentFOV*2,S.SilentFOV*2)
fovCircle.Position=UDim2.new(.5,-S.SilentFOV,.5,-S.SilentFOV)
fovCircle.ZIndex=100
fovCircle.Visible=false
fovCircle.Parent=gui
corner(fovCircle,S.SilentFOV)
stroke(fovCircle,T().accent,.25,1)
addInst(fovCircle)

local cross=frame(gui,UDim2.fromOffset(20,20),UDim2.new(.5,-10,.5,-10),Color3.new(0,0,0),1,100)
cross.Visible=false
local cv=frame(cross,UDim2.fromOffset(20,2),UDim2.fromOffset(0,9),T().text,0,101)
local ch=frame(cross,UDim2.fromOffset(2,20),UDim2.fromOffset(9,0),T().text,0,101)
addInst(cross)

local watermark=frame(gui,UDim2.fromOffset(360,42),UDim2.new(.5,-180,0,20),T().panel,.08,500)
corner(watermark,21)
stroke(watermark,T().line,.12)
local wmText=label(watermark,"",UDim2.fromScale(1,1),UDim2.fromOffset(0,0),12,T().text,505,Enum.TextXAlignment.Center)
addInst(watermark)

--==================================================
-- ROLE DETECTION
--==================================================

local function roleOf(plr)
    if not plr then return "Unknown" end

    local candidates = {
        plr:GetAttribute("Role"),
        plr:GetAttribute("role"),
        plr:GetAttribute("PlayerRole"),
    }

    local pd = plr:FindFirstChild("PlayerData")
    if pd then
        local r = pd:FindFirstChild("Role")
        if r and r:IsA("StringValue") then table.insert(candidates,r.Value) end
        local rs = pd:FindFirstChild("RoleValue")
        if rs and rs:IsA("StringValue") then table.insert(candidates,rs.Value) end
    end

    for _,v in ipairs(candidates) do
        if typeof(v)=="string" then
            local s=v:lower()
            if s:find("murder") then return "Murderer" end
            if s:find("sheriff") then return "Sheriff" end
            if s:find("innocent") then return "Innocent" end
        end
    end

    local c=plr.Character
    if c then
        if c:FindFirstChild("Knife") then return "Murderer" end
        if c:FindFirstChild("Gun") or c:FindFirstChild("Pistol") then return "Sheriff" end
    end

    local bp=plr:FindFirstChildOfClass("Backpack")
    if bp then
        if bp:FindFirstChild("Knife") then return "Murderer" end
        if bp:FindFirstChild("Gun") or bp:FindFirstChild("Pistol") then return "Sheriff" end
    end

    return "Unknown"
end

local ROLE_COLOR={
    Murderer=Color3.fromRGB(245,70,75),
    Sheriff=Color3.fromRGB(70,145,255),
    Innocent=Color3.fromRGB(80,220,120),
    Unknown=Color3.fromRGB(170,170,175),
}

local function removeVisual(plr)
    if CHAMS[plr] then pcall(function() CHAMS[plr]:Destroy() end); CHAMS[plr]=nil end
    if ROLE_LABELS[plr] then pcall(function() ROLE_LABELS[plr]:Destroy() end); ROLE_LABELS[plr]=nil end
end

local function updateVisual(plr)
    if plr==LocalPlayer then return end
    removeVisual(plr)
    if not plr.Character then return end
    local r=roleOf(plr)
    if S.Chams then
        local h=Instance.new("Highlight")
        h.Name="HirukuChams"
        h.Adornee=plr.Character
        h.FillColor=ROLE_COLOR[r] or ROLE_COLOR.Unknown
        h.OutlineColor=h.FillColor
        h.FillTransparency=.55
        h.OutlineTransparency=.1
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent=gui
        CHAMS[plr]=h
    end
    if S.RoleLabels then
        local head=plr.Character:FindFirstChild("Head")
        if head then
            local bb=Instance.new("BillboardGui")
            bb.Name="HirukuRole"
            bb.Adornee=head
            bb.AlwaysOnTop=true
            bb.Size=UDim2.fromOffset(180,34)
            bb.StudsOffset=Vector3.new(0,2.8,0)
            bb.Parent=gui
            local t=label(bb,plr.DisplayName.." • "..r,UDim2.fromScale(1,1),UDim2.fromOffset(0,0),10,ROLE_COLOR[r] or ROLE_COLOR.Unknown,20,Enum.TextXAlignment.Center)
            ROLE_LABELS[plr]=bb
        end
    end
end

local function refreshVisuals()
    for _,p in ipairs(Players:GetPlayers()) do
        updateVisual(p)
    end
end
local function isPlayerCharacterModel(m)
    return m and Players:GetPlayerFromCharacter(m) ~= nil
end

local function removeGunEsp(obj)
    local h=GUN_ESPS[obj]
    if h then pcall(function() h:Destroy() end) end
    GUN_ESPS[obj]=nil
end

local function gunPartOf(obj)
    if not obj or not obj:IsDescendantOf(Workspace) then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
    end
    return nil
end

local function isDroppedGunObject(obj)
    if not obj then return false end
    local n=obj.Name:lower()
    if n=="gundrop" or n=="droppedgun" or n=="pistol" or n=="droppedpistol" then return true end
    if n=="gun" and not isPlayerCharacterModel(obj:FindFirstAncestorOfClass("Model")) then return true end
    return false
end

local function refreshGunEsp()
    for obj in pairs(GUN_ESPS) do
        if not obj.Parent or not isDroppedGunObject(obj) then removeGunEsp(obj) end
    end
    if not S.EspGun then
        for obj in pairs(GUN_ESPS) do removeGunEsp(obj) end
        return
    end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if isDroppedGunObject(obj) then
            local host = obj:IsA("Model") and obj or obj:FindFirstAncestorOfClass("Model") or obj
            if not GUN_ESPS[host] then
                local part=gunPartOf(host)
                if part then
                    local h=Instance.new("Highlight")
                    h.Name="HirukuGunESP"
                    h.Adornee=host
                    h.FillColor=Color3.fromRGB(255,150,35)
                    h.OutlineColor=Color3.fromRGB(255,205,100)
                    h.FillTransparency=.35
                    h.OutlineTransparency=.05
                    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent=gui
                    GUN_ESPS[host]=h
                end
            end
        end
    end
end


--==================================================
-- TARGETING / AIM ASSIST
--==================================================

local function lineOfSight(part, targetModel)
    if not S.SilentLOS then return true end
    local origin=Camera.CFrame.Position
    local direction=part.Position-origin
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={char()}
    local hit=Workspace:Raycast(origin,direction,params)
    return hit and hit.Instance and hit.Instance:IsDescendantOf(targetModel)
end

local function bestTarget()
    local center=Camera.ViewportSize/2
    local best=nil
    local bestDist=S.SilentFOV

    if S.SilentPlayers then
        for _,p in ipairs(Players:GetPlayers()) do
            if playerAlive(p) then
                local hrp=p.Character:FindFirstChild("Head") or root(p.Character)
                if hrp then
                    local pos,on=Camera:WorldToViewportPoint(hrp.Position)
                    if on then
                        local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
                        if d<bestDist and lineOfSight(hrp,p.Character) then
                            bestDist=d
                            best=hrp
                        end
                    end
                end
            end
        end
    end

    if S.SilentNPC then
        for _,m in ipairs(Workspace:GetChildren()) do
            if m:IsA("Model") and m~=char() and not Players:GetPlayerFromCharacter(m) and alive(m) then
                local h=m:FindFirstChild("Head") or root(m)
                if h then
                    local pos,on=Camera:WorldToViewportPoint(h.Position)
                    if on then
                        local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
                        if d<bestDist and lineOfSight(h,m) then
                            bestDist=d
                            best=h
                        end
                    end
                end
            end
        end
    end

    return best
end

--==================================================
-- WEAPON / ATTACK HELPERS
--==================================================

local function findTool(names)
    local c=char()
    local bp=LocalPlayer:FindFirstChildOfClass("Backpack")
    for _,container in ipairs({c,bp}) do
        if container then
            for _,n in ipairs(names) do
                local t=container:FindFirstChild(n)
                if t and t:IsA("Tool") then return t end
            end
        end
    end
end

local function equipAndActivate(tool)
    if not tool then return false end
    local h=humanoid(char())
    if not h then return false end
    pcall(function() h:EquipTool(tool) end)
    task.wait()
    pcall(function() tool:Activate() end)
    return true
end

local function knifeAttack(target)
    if not alive(target) then return false end
    local rr=root(char())
    local tr=root(target)
    if not rr or not tr then return false end
    if (rr.Position-tr.Position).Magnitude>S.AttackRange then return false end
    local knife=findTool({"Knife","knife"})
    if not knife then return false end
    return equipAndActivate(knife)
end

--==================================================
-- COIN / GUN SEARCH
--==================================================

local function findNamedNearest(name)
    local rr=root(char())
    if not rr then return nil end
    local best,dist=nil,math.huge
    for _,d in ipairs(Workspace:GetDescendants()) do
        if d.Name==name then
            local p
            if d:IsA("BasePart") then p=d
            elseif d:IsA("Model") then p=d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart",true) end
            if p then
                local dd=(p.Position-rr.Position).Magnitude
                if dd<dist then dist=dd;best=p end
            end
        end
    end
    return best
end

local function findDroppedGun()
    local rr=root(char())
    if not rr then return nil end
    local best,dist=nil,math.huge
    for _,d in ipairs(Workspace:GetDescendants()) do
        local n=d.Name:lower()
        if n=="gun" or n=="pistol" or n=="droppedgun" or n=="gundrop" or n=="droppedpistol" then
            local p
            if d:IsA("BasePart") then p=d
            elseif d:IsA("Model") then p=d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart",true) end
            if p then
                local dd=(p.Position-rr.Position).Magnitude
                if dd<dist then dist=dd;best=p end
            end
        end
    end
    return best
end

local function touchPickup(part)
    if not part then return false end
    local rr=root(char())
    if not rr then return false end
    local used=false
    if type(firetouchinterest)=="function" then
        pcall(function() firetouchinterest(rr,part,0); firetouchinterest(rr,part,1); used=true end)
    end
    local model=part:FindFirstAncestorOfClass("Model") or part
    local prompt=model and model:FindFirstChildWhichIsA("ProximityPrompt",true)
    if prompt and prompt.Enabled and type(fireproximityprompt)=="function" then
        pcall(function() fireproximityprompt(prompt); used=true end)
    end
    local click=model and model:FindFirstChildWhichIsA("ClickDetector",true)
    if click and type(fireclickdetector)=="function" then
        pcall(function() fireclickdetector(click); used=true end)
    end
    return used
end

--==================================================
-- MOVEMENT
--==================================================

local function rememberMovementDefaults()
    local h=humanoid(char())
    if not h then return end
    if originalWalkSpeed==nil then originalWalkSpeed=h.WalkSpeed end
    if originalJumpPower==nil then originalJumpPower=h.JumpPower end
    if originalAutoRotate==nil then originalAutoRotate=h.AutoRotate end
end

local function restoreMovementDefaults()
    local h=humanoid(char())
    if not h then return end
    if originalWalkSpeed then h.WalkSpeed=originalWalkSpeed end
    if originalJumpPower then h.JumpPower=originalJumpPower end
    if originalAutoRotate~=nil then h.AutoRotate=originalAutoRotate end
    h.PlatformStand=false
end

local function doFly(dt)
    local c=char()
    local r=root(c)
    local h=humanoid(c)
    if not r or not h or h.Health<=0 then return end
    rememberMovementDefaults()

    local move=h.MoveDirection
    local targetVel=Vector3.zero
    if move.Magnitude>.02 then
        targetVel=move.Unit*S.FlySpeed
    end

    -- Android jump button is the vertical control.
    local state=h:GetState()
    if h.Jump or state==Enum.HumanoidStateType.Jumping then
        flyVerticalUntil=math.max(flyVerticalUntil,os.clock()+.32)
    end
    local y=0
    if os.clock()<flyVerticalUntil then y=S.FlySpeed end

    h.AutoRotate=false
    h.PlatformStand=false
    local desired=Vector3.new(targetVel.X,y,targetVel.Z)
    r.AssemblyLinearVelocity=r.AssemblyLinearVelocity:Lerp(desired,math.clamp(dt*9,0,1))
end

local function stopFly()
    flyVerticalUntil=0
    local h=humanoid(char())
    local r=root(char())
    if h then
        h.PlatformStand=false
        h.AutoRotate=originalAutoRotate==nil and true or originalAutoRotate
    end
    -- Never modify velocity here; doing so breaks normal Roblox running/jumping.
end

--==================================================
-- ANTI AFK
--==================================================

local afkTick=0

--==================================================
-- HEARTBEAT
--==================================================

local fps=60
local frames=0
local fpsClock=0
local lastAttack=0
local targetScanClock=0
local cachedCoin=nil
local cachedGun=nil

conn(RunService.RenderStepped:Connect(function(dt)
    frames+=1
    fpsClock+=dt
    if fpsClock>=1 then fps=frames/fpsClock;frames=0;fpsClock=0 end

    -- FOV
    fovCircle.Visible=S.Open and S.FOV
    fovCircle.Size=UDim2.fromOffset(S.SilentFOV*2,S.SilentFOV*2)
    fovCircle.Position=UDim2.new(.5,-S.SilentFOV,.5,-S.SilentFOV)

    cross.Visible=S.Crosshair

    -- Watermark
    watermark.Visible=S.Watermark
    local ping="?"
    pcall(function()
        local item=Stats.Network.ServerStatsItem["Data Ping"]
        ping=math.floor(item:GetValue())
    end)
    wmText.Text=string.format("Hiruku  •  %d FPS  •  %s  •  %d ms",math.floor(fps+0.5),LocalPlayer.Name,ping)

    -- Aim assist
    if S.SilentAim and UIS.MouseEnabled == false then
        local target=bestTarget()
        if target then
            local desired=CFrame.lookAt(Camera.CFrame.Position,target.Position)
            Camera.CFrame=Camera.CFrame:Lerp(desired,S.SilentSmooth)
        end
    elseif S.SilentAim and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target=bestTarget()
        if target then
            local desired=CFrame.lookAt(Camera.CFrame.Position,target.Position)
            Camera.CFrame=Camera.CFrame:Lerp(desired,S.SilentSmooth)
        end
    end

    -- Fly
    if S.Fly then
        doFly(dt)
    else
        stopFly()
    end

    -- Bunny hop: gradual acceleration while moving, automatic jump on landing.
    if S.BunnyHop and not S.Fly and not S.CoinFarm then
        local h=humanoid(char())
        if h and h.Health>0 then
            rememberMovementDefaults()
            local moving=h.MoveDirection.Magnitude>.08
            if moving then
                S.BunnyCurrentSpeed=math.min(S.BunnySpeed,S.BunnyCurrentSpeed + S.BunnyAccel*dt)
                h.WalkSpeed=S.BunnyCurrentSpeed
                if h.FloorMaterial~=Enum.Material.Air then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            else
                S.BunnyCurrentSpeed=originalWalkSpeed or 16
                h.WalkSpeed=originalWalkSpeed or 16
            end
        end
    elseif not S.BunnyHop and not S.Fly then
        local h=humanoid(char())
        if h and originalWalkSpeed then h.WalkSpeed=originalWalkSpeed end
        S.BunnyCurrentSpeed=originalWalkSpeed or 16
    end

    -- No clip with restoration when disabled.
    if S.NoClip and char() then
        for _,p in ipairs(char():GetDescendants()) do
            if p:IsA("BasePart") then
                if p:GetAttribute("HirukuOriginalCollision")==nil then
                    p:SetAttribute("HirukuOriginalCollision",p.CanCollide)
                end
                p.CanCollide=false
            end
        end
    elseif char() then
        for _,p in ipairs(char():GetDescendants()) do
            if p:IsA("BasePart") then
                local old=p:GetAttribute("HirukuOriginalCollision")
                if old~=nil then
                    p.CanCollide=old
                    p:SetAttribute("HirukuOriginalCollision",nil)
                end
            end
        end
    end

    -- Spin
    if S.Spin then
        local r=root(char())
        if r then r.CFrame=r.CFrame*CFrame.Angles(0,math.rad(S.SpinSpeed)*dt,0) end
    end

    -- Target Aura
    if S.TargetAura and playerAlive(S.TargetAuraPlayer) then
        local rr=root(char())
        local tr=root(S.TargetAuraPlayer.Character)
        if rr and tr then
            local dir=(tr.Position-rr.Position)
            if dir.Magnitude>2 then
                rr.AssemblyLinearVelocity=dir.Unit*S.TargetAuraSpeed
            end
        end
    end

    targetScanClock += dt
    if targetScanClock >= 0.12 then
        targetScanClock = 0
        if S.CoinFarm then cachedCoin=findNamedNearest("Coin") else cachedCoin=nil end
        if S.AutoPickupGun then cachedGun=findDroppedGun() else cachedGun=nil end
    end

    -- Coin Farm: short, controlled hops to the nearest Coin so walls do not stall the route.
    if S.CoinFarm and not S.Fly then
        local coin=cachedCoin
        local rr=root(char())
        if coin and rr and os.clock()-lastCoinHop>.12 then
            lastCoinHop=os.clock()
            local oldCF=rr.CFrame
            local target=coin.Position+Vector3.new(0,1.8,0)
            rr.CFrame=CFrame.new(target)
            touchPickup(coin)
            task.delay(.04,function()
                if rr and rr.Parent and S.CoinFarm then
                    rr.CFrame=oldCF
                end
            end)
        end
    end

    -- Auto Pickup Gun: briefly place the character at the dropped gun, fire every
    -- available pickup mechanism, then immediately restore the previous position.
    if S.AutoPickupGun and cachedGun and os.clock()-lastGunPickup>.30 then
        lastGunPickup=os.clock()
        local rr=root(char())
        if rr then
            local oldCF=rr.CFrame
            rr.CFrame=CFrame.new(cachedGun.Position+Vector3.new(0,1.2,0))
            touchPickup(cachedGun)
            task.delay(.06,function()
                if rr and rr.Parent and S.AutoPickupGun then
                    rr.CFrame=oldCF
                end
            end)
        end
    end

    -- Kill Aura / Selected / All
    if os.clock()-lastAttack>=S.AttackCooldown then
        local targets={}
        if S.KillAura then
            for _,p in ipairs(Players:GetPlayers()) do
                if playerAlive(p) then table.insert(targets,p.Character) end
            end
        end
        if S.KillSelected and playerAlive(S.SelectedPlayer) then
            table.insert(targets,S.SelectedPlayer.Character)
        end
        if S.KillAll then
            for _,p in ipairs(Players:GetPlayers()) do
                if playerAlive(p) then table.insert(targets,p.Character) end
            end
        end
        for _,t in ipairs(targets) do
            if knifeAttack(t) then lastAttack=os.clock();break end
        end
    end

    -- Anti AFK: gentle input pulse only while enabled
    if S.AntiAFK then
        afkTick+=dt
        if afkTick>55 then
            afkTick=0
            pcall(function()
                VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
                VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
            end)
        end
    end
end))

--==================================================
-- PLAYER EVENTS
--==================================================

conn(Players.PlayerAdded:Connect(function(p)
    conn(p.CharacterAdded:Connect(function()
        task.wait(.5)
        updateVisual(p)
    end))
end))

for _,p in ipairs(Players:GetPlayers()) do
    if p~=LocalPlayer then
        conn(p.CharacterAdded:Connect(function()
            task.wait(.35)
            updateVisual(p)
        end))
    end
end

conn(LocalPlayer.CharacterAdded:Connect(function()
    originalWalkSpeed=nil
    originalJumpPower=nil
    originalAutoRotate=nil
    task.wait(.4)
    rememberMovementDefaults()
    if S.NoClip then
        for _,p in ipairs(char():GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end
end))

--==================================================
-- THEME / FONT REFRESH
--==================================================

local function applyStyle(rootGui)
    if not rootGui then return end
    for _,o in ipairs(rootGui:GetDescendants()) do
        if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
            o.Font=FONT_MAP[S.Font] or Enum.Font.Gotham
            if o==search then
                o.TextColor3=T().text
                o.PlaceholderColor3=T().sub
            else
                o.TextColor3=T().text
            end
        end
        if o:IsA("Frame") or o:IsA("TextButton") or o:IsA("TextBox") then
            -- Only recolor known Hiruku surfaces; avoid changing game UI.
            if o==main or o:IsDescendantOf(main) then
                if o==main or o==glass then
                    o.BackgroundColor3=T().panel
                    if o==main then o.BackgroundTransparency=1-S.MenuOpacity end
                elseif o:IsA("TextButton") or o:IsA("TextBox") then
                    if o==search then o.BackgroundColor3=T().card end
                end
            end
        end
    end
    pill.BackgroundColor3=T().panel
    toast.BackgroundColor3=T().panel
    watermark.BackgroundColor3=T().panel
    fovCircle:FindFirstChildOfClass("UIStroke").Color=T().accent
end

local lastTheme, lastFont = nil, nil
conn(RunService.Heartbeat:Connect(function()
    if lastTheme ~= S.Theme or lastFont ~= S.Font then
        lastTheme, lastFont = S.Theme, S.Font
        applyStyle(gui)
    end
    if S.Chams or S.RoleLabels then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local r=roleOf(p)
                if CHAMS[p] then
                    CHAMS[p].FillColor=ROLE_COLOR[r] or ROLE_COLOR.Unknown
                    CHAMS[p].OutlineColor=ROLE_COLOR[r] or ROLE_COLOR.Unknown
                end
                if ROLE_LABELS[p] then
                    local t=ROLE_LABELS[p]:FindFirstChildWhichIsA("TextLabel",true)
                    if t then t.Text=p.DisplayName.." • "..r; t.TextColor3=ROLE_COLOR[r] or ROLE_COLOR.Unknown end
                end
            end
        end
    end
    gunEspClock += dt
    if gunEspClock >= .5 then
        gunEspClock = 0
        if S.EspGun then
            refreshGunEsp()
        elseif next(GUN_ESPS) then
            for obj in pairs(GUN_ESPS) do removeGunEsp(obj) end
        end
    end
end))

--==================================================
-- SEARCH FILTER
--==================================================

conn(search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = search.Text:lower():gsub("^%s+",""):gsub("%s+$","")
    local pg = pages[S.Page]
    if not pg then return end
    for _,o in ipairs(pg:GetChildren()) do
        if o:IsA("GuiObject") then
            if q == "" then
                o.Visible = true
            else
                local found = false
                if o:IsA("TextButton") or o:IsA("TextLabel") then
                    found = o.Text:lower():find(q,1,true) ~= nil
                else
                    for _,d in ipairs(o:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                            if d.Text:lower():find(q,1,true) then found=true break end
                        end
                    end
                end
                o.Visible = found
            end
        end
    end
end))

--==================================================
-- CLEANUP
--==================================================

function S.Cleanup()
    S.Open=false
    S.Fly=false
    S.NoClip=false
    S.BunnyHop=false
    S.Spin=false
    S.CoinFarm=false
    S.AutoPickupGun=false
    disconnectAll()
    for p in pairs(CHAMS) do pcall(function() CHAMS[p]:Destroy() end) end
    for p in pairs(ROLE_LABELS) do pcall(function() ROLE_LABELS[p]:Destroy() end) end
    for o in pairs(GUN_ESPS) do pcall(function() GUN_ESPS[o]:Destroy() end) end
    table.clear(CHAMS)
    table.clear(ROLE_LABELS)
    table.clear(GUN_ESPS)
    stopFly()
    restoreMovementDefaults()
    originalWalkSpeed=nil
    originalJumpPower=nil
    originalAutoRotate=nil
    if char() then
        for _,p in ipairs(char():GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function()
                    local old=p:GetAttribute("HirukuOriginalCollision")
                    p.CanCollide=(old==nil and true or old)
                    p:SetAttribute("HirukuOriginalCollision",nil)
                end)
            end
        end
    end
    destroyAll()
end

_G[GKEY]=S

--==================================================
-- STARTUP
--==================================================

scaleGui()

local function fitWindow()
    local vp=Camera.ViewportSize
    local scale=math.clamp(S.UIScale,.80,1.20)
    local w=math.min(760,math.max(340,(vp.X-20)/scale))
    local h=math.min(510,math.max(400,(vp.Y-20)/scale))
    main.Size=UDim2.fromOffset(w,h)
    if not DRAG.active and not S.Open then
        main.Position=UDim2.fromOffset((vp.X-(w*scale))/2/scale,math.max(14,(vp.Y-(h*scale))/2/scale))
    end
end
fitWindow()
updateResponsiveLayout()
conn(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    fitWindow()
    updateResponsiveLayout()
end))
conn(main:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveLayout))
setPage("Combat")
search.Text = ""
refreshVisuals()
notify("Hiruku successfully loaded")

-- Small startup animation.
pill.Size=UDim2.fromOffset(0,46)
tween(pill,.35,{Size=UDim2.fromOffset(148,46)},Enum.EasingStyle.Quint)
