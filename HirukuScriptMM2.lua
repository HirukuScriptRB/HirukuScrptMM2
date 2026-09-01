--[[
    HIRUKU MM2 — Android-first private QA build V8

    UI fixes:
      * No icon sprites: navigation uses clean text only.
      * Bright text with explicit ZIndex ordering.
      * Navigation uses fixed rows; no UIListLayout on the nav.
      * Old-style ON/OFF sliders restored.
      * Menu/tablets use translucent glass layers behind content only.
      * No Lighting BlurEffect: Roblox cannot blur only a Frame.
      * Touch-first buttons and drag handling.
      * Search filters the current page without hiding headers.
      * Font selector in Settings.

    Private-test scope:
      * Player aim/visual diagnostics are available for controlled testing.
      * Auto Pickup Gun only follows a dropped test gun explicitly marked
        HirukuTestGun=true or placed in workspace.HirukuTestDrops.
      * Coin tools search objects named exactly "Coin".
]]

local ENV = (getgenv and getgenv()) or _G
if ENV.HirukuCleanup then pcall(ENV.HirukuCleanup) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local S = {
    alive=true, menu=false, tab="Combat", selected=nil,
    FOV=180, FOVEnabled=false, AimEnabled=false, AimSmooth=.18, AimLOS=true,
    AimPlayers=true, AimNPC=false, AutoShot=false,
    KillAura=false, KillSelected=false, KillAll=false,
    Chams=false, RoleLabels=true, Watermark=false, WatermarkFPS=true, WatermarkPing=true,
    Fly=false, FlySpeed=55, BunnyHop=false, BunnySpeed=18, BunnyAutoStrafe=true,
    NoClip=false, Spin=false, SpinSpeed=8,
    CoinRadar=false, CoinFarm=false, CoinFarmSpeed=70, AutoPickupGun=false,
    Crosshair=false, Fullbright=false, AntiAFK=false,
    Language="English", UIScale=1, FontName="Gotham", Font=Enum.Font.Gotham,
    connections={}, instances={}, highlights={}, labels={}, saved={}, coinHighlights={}
}

local function track(x) table.insert(S.instances,x); return x end
local function connect(c, fn)
    if fn then return connect(c:Connect(fn)) end
    table.insert(S.connections,c); return c
end
local function cleanup()
    S.alive=false
    for _,c in ipairs(S.connections) do pcall(function() c:Disconnect() end) end
    for _,x in ipairs(S.instances) do pcall(function() x:Destroy() end) end
    for _,x in pairs(S.highlights) do pcall(function() x:Destroy() end) end
    for _,x in pairs(S.labels) do pcall(function() x:Destroy() end) end
    for _,x in pairs(S.coinHighlights) do pcall(function() x:Destroy() end) end
    local c=LocalPlayer.Character
    if c then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end
        end
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then
            if S.saved.WalkSpeed then h.WalkSpeed=S.saved.WalkSpeed end
            if S.saved.JumpPower then h.JumpPower=S.saved.JumpPower end
            h.AutoRotate=true
        end
    end
    if ENV then ENV.HirukuCleanup=nil end
end
ENV.HirukuCleanup=cleanup

local function tween(obj,time,props,style,dir)
    local t=TweenService:Create(obj,TweenInfo.new(time,style or Enum.EasingStyle.Quint,dir or Enum.EasingDirection.Out),props)
    t:Play(); return t
end
local function corner(p,r)
    local c=track(Instance.new("UICorner")); c.CornerRadius=UDim.new(0,r); c.Parent=p; return c
end
local function stroke(p,a)
    local s=track(Instance.new("UIStroke")); s.Color=Color3.fromRGB(255,255,255); s.Thickness=1; s.Transparency=a or .82; s.Parent=p; return s
end
local function frame(parent,color,trans,z)
    local f=track(Instance.new("Frame")); f.BackgroundColor3=color or Color3.fromRGB(20,20,20); f.BackgroundTransparency=trans or 0; f.BorderSizePixel=0; f.ZIndex=z or 1; f.Parent=parent; return f
end
local function label(parent,str,size,z)
    local t=track(Instance.new("TextLabel")); t.BackgroundTransparency=1; t.Text=str; t.TextColor3=Color3.fromRGB(242,242,242); t.TextSize=size or 13; t.Font=S.Font; t.ZIndex=z or 10; t.Parent=parent; return t
end
local function button(parent,z)
    local b=track(Instance.new("TextButton")); b.BackgroundTransparency=1; b.AutoButtonColor=false; b.Text=""; b.Active=true; b.Selectable=true; b.Modal=true; b.ZIndex=z or 20; b.Parent=parent; return b
end

-- Root GUI: high display order, reset safe on Android.
local gui=track(Instance.new("ScreenGui")); gui.Name="Hiruku"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Global; gui.DisplayOrder=1000000
pcall(function() gui.Parent=game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent=LocalPlayer:WaitForChild("PlayerGui") end

-- Injection overlay.
local inject=frame(gui,Color3.new(0,0,0),.12,2000); inject.Size=UDim2.fromScale(1,1)
local injTitle=label(inject,"Hiruku Injected...",29,2003); injTitle.AnchorPoint=Vector2.new(.5,.5); injTitle.Position=UDim2.fromScale(.5,.46); injTitle.Size=UDim2.new(0,520,0,50); injTitle.TextXAlignment=Enum.TextXAlignment.Center
local barBack=frame(inject,Color3.fromRGB(34,34,34),.05,2001); barBack.AnchorPoint=Vector2.new(.5,0); barBack.Position=UDim2.new(.5,0,.53,0); barBack.Size=UDim2.new(0,280,0,9); corner(barBack,5)
local bar=frame(barBack,Color3.fromRGB(248,248,248),0,2002); bar.Size=UDim2.new(0,0,1,0); corner(bar,5)
tween(bar,.95,{Size=UDim2.fromScale(1,1)}); tween(injTitle,.45,{TextTransparency=0}); task.wait(1.05); tween(inject,.3,{BackgroundTransparency=1}); tween(injTitle,.22,{TextTransparency=1}); tween(barBack,.22,{BackgroundTransparency=1}); task.wait(.25); pcall(function() inject:Destroy() end)

-- Floating pill.
local pill=track(Instance.new("TextButton")); pill.Name="HirukuPill"; pill.AnchorPoint=Vector2.new(.5,.5); pill.Position=UDim2.fromScale(.16,.14); pill.Size=UDim2.fromOffset(122,40); pill.BackgroundColor3=Color3.fromRGB(8,8,8); pill.BackgroundTransparency=.13; pill.Text="Hiruku"; pill.TextColor3=Color3.fromRGB(248,248,248); pill.TextSize=15; pill.Font=S.Font; pill.AutoButtonColor=false; pill.Active=true; pill.Modal=true; pill.ZIndex=1800; pill.Parent=gui; corner(pill,20); stroke(pill,.75)

-- Main menu.
-- Transparent modal blocker stops Android touch gestures from reaching the 3D camera while the menu is open.
local touchBlock=track(Instance.new("TextButton")); touchBlock.Name="HirukuTouchBlock"; touchBlock.Size=UDim2.fromScale(1,1); touchBlock.BackgroundTransparency=1; touchBlock.Text=""; touchBlock.AutoButtonColor=false; touchBlock.Active=true; touchBlock.Modal=true; touchBlock.ZIndex=1650; touchBlock.Visible=false; touchBlock.Parent=gui
local menu=frame(gui,Color3.fromRGB(10,10,10),.10,1700); menu.Name="Menu"; menu.AnchorPoint=Vector2.new(.5,.5); menu.Position=UDim2.fromScale(.5,.52); menu.Size=UDim2.fromOffset(610,410); menu.Visible=false; menu.Active=true; corner(menu,17); stroke(menu,.72)
-- Glass layer is below all content; it never covers text.
local glass=frame(menu,Color3.fromRGB(16,16,16),.18,1701); glass.Size=UDim2.fromScale(1,1); corner(glass,17)
local header=frame(menu,Color3.new(0,0,0),1,1710); header.Size=UDim2.new(1,0,0,112)
local title=label(header,"Hiruku",21,1720); title.Position=UDim2.fromOffset(20,12); title.Size=UDim2.new(1,-40,0,28); title.Font=Enum.Font.GothamBold
title.TextColor3=Color3.fromRGB(250,250,250)
local subtitle=label(header,"MM2 - v 1.0",10,1720); subtitle.Position=UDim2.fromOffset(21,42); subtitle.Size=UDim2.new(1,-42,0,18); subtitle.TextColor3=Color3.fromRGB(215,215,215)
local grad=track(Instance.new("UIGradient")); grad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(75,75,75)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))}; grad.Parent=subtitle
connect(RunService.RenderStepped:Connect(function() if subtitle.Parent then grad.Offset=Vector2.new((os.clock()*.28)%2-1,0) end end))
local search=track(Instance.new("TextBox")); search.Position=UDim2.fromOffset(18,73); search.Size=UDim2.new(1,-36,0,31); search.BackgroundColor3=Color3.fromRGB(27,27,27); search.BackgroundTransparency=.04; search.TextColor3=Color3.fromRGB(245,245,245); search.PlaceholderText="Search feature..."; search.PlaceholderColor3=Color3.fromRGB(135,135,135); search.TextSize=11; search.Font=S.Font; search.ClearTextOnFocus=false; search.Active=true; search.ZIndex=1725; search.Parent=menu; corner(search,11)

-- A dedicated header drag button is the only drag handle. It sits above background, below search.
local drag=button(menu,1715); drag.Position=UDim2.fromOffset(0,0); drag.Size=UDim2.new(1,-150,0,68); drag.Parent=menu

local nav=frame(menu,Color3.new(0,0,0),1,1712); nav.Position=UDim2.fromOffset(14,121); nav.Size=UDim2.new(0,145,1,-135)
local content=frame(menu,Color3.new(0,0,0),1,1712); content.Position=UDim2.fromOffset(170,121); content.Size=UDim2.new(1,-184,1,-135)
local tabs={"Combat","Visuals","Misc","Settings"}; local pages={}; local tabRefs={}

local function makePage(name)
    local p=track(Instance.new("ScrollingFrame")); p.Name=name; p.Size=UDim2.fromScale(1,1); p.BackgroundTransparency=1; p.BorderSizePixel=0; p.ScrollBarThickness=3; p.AutomaticCanvasSize=Enum.AutomaticSize.Y; p.CanvasSize=UDim2.new(); p.ScrollingDirection=Enum.ScrollingDirection.Y; p.Active=true; p.ZIndex=1720; p.Visible=false; p.Parent=content
    local pad=track(Instance.new("UIPadding")); pad.PaddingTop=UDim.new(0,2); pad.PaddingBottom=UDim.new(0,14); pad.Parent=p
    local list=track(Instance.new("UIListLayout")); list.Padding=UDim.new(0,10); list.SortOrder=Enum.SortOrder.LayoutOrder; list.Parent=p
    pages[name]=p; return p
end
for i,name in ipairs(tabs) do
    local b=button(nav,1730); b.Position=UDim2.fromOffset(0,(i-1)*51); b.Size=UDim2.new(1,0,0,43); b.BackgroundColor3=Color3.fromRGB(38,38,38); b.BackgroundTransparency=1; b.Text=name; b.TextColor3=Color3.fromRGB(190,190,190); b.TextSize=12; b.Font=S.Font; corner(b,10); tabRefs[name]=b; makePage(name)
end
local function setTab(name)
    S.tab=name
    for n,b in pairs(tabRefs) do
        b.BackgroundTransparency=(n==name) and .48 or 1
        b.TextColor3=(n==name) and Color3.fromRGB(250,250,250) or Color3.fromRGB(185,185,185)
    end
    for n,p in pairs(pages) do p.Visible=(n==name) end
end

-- Old style toggle: full row is touch target, switch is visible.
local function toggle(parent,name,desc,callback,settingsCallback)
    local row=frame(parent,Color3.fromRGB(25,25,25),.02,1730); row.Size=UDim2.new(1,0,0,63); corner(row,11)
    local n=label(row,name,12,1734); n.Position=UDim2.fromOffset(13,8); n.Size=UDim2.new(1,-115,0,18)
    local d=label(row,desc or "",9,1734); d.Position=UDim2.fromOffset(13,32); d.Size=UDim2.new(1,-115,0,16); d.TextColor3=Color3.fromRGB(155,155,155)
    local sw=track(Instance.new("TextButton")); sw.Size=UDim2.fromOffset(45,24); sw.Position=UDim2.new(1,-57,.5,-12); sw.BackgroundColor3=Color3.fromRGB(52,52,52); sw.Text=""; sw.AutoButtonColor=false; sw.Active=true; sw.Modal=true; sw.ZIndex=1738; sw.Parent=row; corner(sw,13)
    local knob=frame(sw,Color3.fromRGB(205,205,205),0,1739); knob.Size=UDim2.fromOffset(18,18); knob.Position=UDim2.fromOffset(3,3); corner(knob,9)
    local on=false
    local function set(v)
        on=v; tween(sw,.16,{BackgroundColor3=v and Color3.fromRGB(235,235,235) or Color3.fromRGB(52,52,52)}); tween(knob,.16,{Position=v and UDim2.new(1,-21,0,3) or UDim2.fromOffset(3,3),BackgroundColor3=v and Color3.fromRGB(20,20,20) or Color3.fromRGB(205,205,205)}); if callback then callback(v) end
    end
    connect(sw.Activated:Connect(function() set(not on) end))
    local hit=button(row,1737); hit.Position=UDim2.fromOffset(0,0); hit.Size=UDim2.new(1,-66,1,0); hit.Parent=row; connect(hit.Activated:Connect(function() set(not on) end))
    if settingsCallback then
        local gear=button(row,1738); gear.Size=UDim2.fromOffset(24,24); gear.Position=UDim2.new(1,-90,.5,-12); gear.Parent=row; gear.Text="SET"; gear.TextColor3=Color3.fromRGB(165,165,165); gear.TextSize=9; gear.Font=Enum.Font.GothamBold
        connect(gear.Activated:Connect(settingsCallback))
    end
    row:SetAttribute("FeatureName",name)
    return row
end
local function section(parent,str)
    local x=label(parent,str,10,1733); x.Size=UDim2.new(1,0,0,20); x.TextColor3=Color3.fromRGB(155,155,155); return x
end

-- Drawer for deep settings.
local drawer=frame(gui,Color3.fromRGB(12,12,12),.08,1900); drawer.AnchorPoint=Vector2.new(1,.5); drawer.Position=UDim2.new(1,-16,.5,0); drawer.Size=UDim2.fromOffset(335,0); drawer.Visible=false; corner(drawer,15); stroke(drawer,.72)
local drawerTitle=label(drawer,"Settings",15,1910); drawerTitle.Position=UDim2.fromOffset(16,13); drawerTitle.Size=UDim2.new(1,-60,0,24); drawerTitle.Font=Enum.Font.GothamBold
local close=button(drawer,1920); close.Size=UDim2.fromOffset(30,30); close.Position=UDim2.new(1,-40,0,9); close.BackgroundColor3=Color3.fromRGB(32,32,32); close.Text="×"; close.TextColor3=Color3.fromRGB(240,240,240); close.TextSize=18; close.Font=Enum.Font.GothamBold; corner(close,15)
local drawerBody=track(Instance.new("ScrollingFrame")); drawerBody.Position=UDim2.fromOffset(14,55); drawerBody.Size=UDim2.new(1,-28,1,-68); drawerBody.BackgroundTransparency=1; drawerBody.BorderSizePixel=0; drawerBody.ScrollBarThickness=3; drawerBody.AutomaticCanvasSize=Enum.AutomaticSize.Y; drawerBody.CanvasSize=UDim2.new(); drawerBody.ZIndex=1910; drawerBody.Parent=drawer
local dbList=track(Instance.new("UIListLayout")); dbList.Padding=UDim.new(0,9); dbList.SortOrder=Enum.SortOrder.LayoutOrder; dbList.Parent=drawerBody
local function clearDrawer()
    for _,x in ipairs(drawerBody:GetChildren()) do if x:IsA("GuiObject") then x:Destroy() end end
end
local function slider(parent,name,min,max,get,set)
    local box=frame(parent,Color3.fromRGB(25,25,25),.02,1920); box.Size=UDim2.new(1,0,0,70); corner(box,10)
    local n=label(box,name,10,1924); n.Position=UDim2.fromOffset(11,7); n.Size=UDim2.new(.7,0,0,17)
    local val=label(box,tostring(get()),10,1924); val.Position=UDim2.new(1,-70,0,7); val.Size=UDim2.fromOffset(59,17); val.TextXAlignment=Enum.TextXAlignment.Right
    local trackBar=frame(box,Color3.fromRGB(54,54,54),0,1924); trackBar.Position=UDim2.fromOffset(11,38); trackBar.Size=UDim2.new(1,-22,0,8); corner(trackBar,4)
    local fill=frame(trackBar,Color3.fromRGB(235,235,235),0,1925); corner(fill,4)
    local knob=frame(trackBar,Color3.fromRGB(250,250,250),0,1926); knob.Size=UDim2.fromOffset(14,14); knob.AnchorPoint=Vector2.new(.5,.5); corner(knob,7)
    local dragging=false
    local function apply(px)
        local a=math.clamp((px-trackBar.AbsolutePosition.X)/math.max(trackBar.AbsoluteSize.X,1),0,1); local v=min+(max-min)*a; set(v); val.Text=(math.abs(v-math.floor(v))<.05) and tostring(math.floor(v+.5)) or string.format("%.2f",v); fill.Size=UDim2.new(a,0,1,0); knob.Position=UDim2.new(a,0,.5,0)
    end
    connect(trackBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; apply(i.Position.X) end end))
    connect(UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then apply(i.Position.X) end end))
    connect(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
    local a=math.clamp((get()-min)/(max-min),0,1); fill.Size=UDim2.new(a,0,1,0); knob.Position=UDim2.new(a,0,.5,0)
end
local function subToggle(parent,name,get,set)
    local b=frame(parent,Color3.fromRGB(25,25,25),.02,1920); b.Size=UDim2.new(1,0,0,48); corner(b,10)
    local n=label(b,name,10,1924); n.Position=UDim2.fromOffset(11,0); n.Size=UDim2.new(1,-70,1,0)
    local sw=track(Instance.new("TextButton")); sw.Size=UDim2.fromOffset(45,24); sw.Position=UDim2.new(1,-56,.5,-12); sw.BackgroundColor3=get() and Color3.fromRGB(235,235,235) or Color3.fromRGB(52,52,52); sw.Text=""; sw.AutoButtonColor=false; sw.Active=true; sw.Modal=true; sw.ZIndex=1925; sw.Parent=b; corner(sw,13)
    local k=frame(sw,get() and Color3.fromRGB(20,20,20) or Color3.fromRGB(205,205,205),0,1926); k.Size=UDim2.fromOffset(18,18); k.Position=get() and UDim2.new(1,-21,0,3) or UDim2.fromOffset(3,3); corner(k,9)
    connect(sw.Activated:Connect(function() local v=not get(); set(v); tween(sw,.15,{BackgroundColor3=v and Color3.fromRGB(235,235,235) or Color3.fromRGB(52,52,52)}); tween(k,.15,{Position=v and UDim2.new(1,-21,0,3) or UDim2.fromOffset(3,3),BackgroundColor3=v and Color3.fromRGB(20,20,20) or Color3.fromRGB(205,205,205)}) end))
end
local function openDrawer(titleText, builder)
    clearDrawer(); drawerTitle.Text=titleText; builder(); drawer.Visible=true; drawer.Size=UDim2.fromOffset(335,0); tween(drawer,.26,{Size=UDim2.fromOffset(335,320)})
end
connect(close.Activated, function() tween(drawer,.2,{Size=UDim2.fromOffset(335,0)}); task.delay(.22,function() if drawer.Parent then drawer.Visible=false end end) end)

-- Combat.
local combat=pages.Combat
section(combat,"SHERIFF")
toggle(combat,"Silent Aim","FOV target selection for controlled player testing",function(v) S.AimEnabled=v end,function()
    openDrawer("Silent Aim",function()
        slider(drawerBody,"FOV",50,420,function() return S.FOV end,function(v) S.FOV=v end)
        slider(drawerBody,"Smoothness",.02,.8,function() return S.AimSmooth end,function(v) S.AimSmooth=v end)
        subToggle(drawerBody,"Line of sight",function() return S.AimLOS end,function(v) S.AimLOS=v end)
        subToggle(drawerBody,"Players",function() return S.AimPlayers end,function(v) S.AimPlayers=v end)
        subToggle(drawerBody,"NPC / dummy",function() return S.AimNPC end,function(v) S.AimNPC=v end)
    end)
end)
toggle(combat,"Auto Shot Murder","Controlled role-state test trigger",function(v) S.AutoShot=v end)
toggle(combat,"FOV","Show aim FOV circle",function(v) S.FOVEnabled=v end,function() openDrawer("FOV",function() slider(drawerBody,"Radius",50,420,function() return S.FOV end,function(v) S.FOV=v end) end) end)
section(combat,"MURDER")
toggle(combat,"Kill Aura","Authorized range test",function(v) S.KillAura=v end)
toggle(combat,"Kill Selected","Authorized selected-target test",function(v) S.KillSelected=v end)
toggle(combat,"Kill All","Authorized target enumeration",function(v) S.KillAll=v end)

-- Visuals.
local visuals=pages.Visuals
section(visuals,"PLAYER VISUAL DEBUG")
toggle(visuals,"Chams","Role-aware player highlights",function(v) S.Chams=v end)
toggle(visuals,"Role Labels","Player name and detected role",function(v) S.RoleLabels=v end)
toggle(visuals,"Watermark","Top center: Hiruku / FPS / player / ping",function(v) S.Watermark=v end)
toggle(visuals,"Coin Radar","Highlight objects named Coin",function(v) S.CoinRadar=v end)
toggle(visuals,"Crosshair","Center crosshair",function(v) S.Crosshair=v end)
toggle(visuals,"Fullbright","Local lighting test",function(v) S.Fullbright=v end)

-- Misc.
local misc=pages.Misc
section(misc,"MOVEMENT")
toggle(misc,"Fly","Camera-relative flight",function(v) S.Fly=v end,function() openDrawer("Fly",function() slider(drawerBody,"Fly speed",10,120,function() return S.FlySpeed end,function(v) S.FlySpeed=v end) end) end)
toggle(misc,"Bunny Hop","CS-style auto jump / air movement",function(v) S.BunnyHop=v end,function() openDrawer("Bunny Hop",function() slider(drawerBody,"Hop speed",8,40,function() return S.BunnySpeed end,function(v) S.BunnySpeed=v end); subToggle(drawerBody,"Auto strafe",function() return S.BunnyAutoStrafe end,function(v) S.BunnyAutoStrafe=v end) end) end)
toggle(misc,"No Clip","Disable character collisions",function(v) S.NoClip=v end)
toggle(misc,"Spin","Continuous character rotation",function(v) S.Spin=v end,function() openDrawer("Spin",function() slider(drawerBody,"Spin speed",1,30,function() return S.SpinSpeed end,function(v) S.SpinSpeed=v end) end) end)
toggle(misc,"Coin Farm","Find nearest object named Coin",function(v) S.CoinFarm=v end,function() openDrawer("Coin Farm",function() slider(drawerBody,"Speed",20,160,function() return S.CoinFarmSpeed end,function(v) S.CoinFarmSpeed=v end) end) end)
toggle(misc,"Auto Pickup Gun","Private-test dropped gun pickup",function(v) S.AutoPickupGun=v end)
toggle(misc,"Anti AFK","Keep test client active",function(v) S.AntiAFK=v end)
section(misc,"AUTHORIZED TARGET MOVEMENT")
toggle(misc,"Target Movement","Controlled target movement test",function(v) S.TargetMovement=v end)

-- Settings.
local settings=pages.Settings
section(settings,"INTERFACE")
toggle(settings,"Language","English / Russian",function() S.Language=(S.Language=="English") and "Russian" or "English" end)
local scaleBox=frame(settings,Color3.fromRGB(25,25,25),.02,1730); scaleBox.Size=UDim2.new(1,0,0,92); corner(scaleBox,11)
local scaleName=label(scaleBox,"Interface Size",11,1734); scaleName.Position=UDim2.fromOffset(13,9); scaleName.Size=UDim2.new(1,-26,0,20)
local scaleValue=label(scaleBox,"100%",10,1734); scaleValue.Position=UDim2.fromOffset(13,35); scaleValue.Size=UDim2.new(1,-26,0,18); scaleValue.TextColor3=Color3.fromRGB(170,170,170)
local minus=button(scaleBox,1738); minus.Size=UDim2.fromOffset(50,30); minus.Position=UDim2.fromOffset(10,56); minus.BackgroundColor3=Color3.fromRGB(42,42,42); minus.Text="−"; minus.TextColor3=Color3.fromRGB(240,240,240); minus.TextSize=18; corner(minus,8)
local plus=button(scaleBox,1738); plus.Size=UDim2.fromOffset(50,30); plus.Position=UDim2.fromOffset(68,56); plus.BackgroundColor3=Color3.fromRGB(42,42,42); plus.Text="+"; plus.TextColor3=Color3.fromRGB(240,240,240); plus.TextSize=18; corner(plus,8)
local function applyScale()
    scaleValue.Text=tostring(math.floor(S.UIScale*100+0.5)).."%"
    menu.Size=UDim2.fromOffset(610*S.UIScale,410*S.UIScale)
end
connect(minus.Activated,function() S.UIScale=math.max(.75,S.UIScale-.05); applyScale() end)
connect(plus.Activated,function() S.UIScale=math.min(1.25,S.UIScale+.05); applyScale() end)
section(settings,"MENU FONT")
local fonts={"Gotham","GothamBold","SourceSans","SourceSansBold","Arial","Code","Cartoon","Fantasy","SciFi","Bangers"}
local fontScroll=track(Instance.new("ScrollingFrame")); fontScroll.Size=UDim2.new(1,0,0,145); fontScroll.BackgroundColor3=Color3.fromRGB(25,25,25); fontScroll.BackgroundTransparency=.02; fontScroll.BorderSizePixel=0; fontScroll.ScrollBarThickness=3; fontScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; fontScroll.CanvasSize=UDim2.new(); fontScroll.ZIndex=1730; fontScroll.Parent=settings; corner(fontScroll,11)
local fontList=track(Instance.new("UIListLayout")); fontList.Padding=UDim.new(0,6); fontList.SortOrder=Enum.SortOrder.LayoutOrder; fontList.Parent=fontScroll
local fp=track(Instance.new("UIPadding")); fp.PaddingTop=UDim.new(0,7); fp.PaddingLeft=UDim.new(0,7); fp.PaddingRight=UDim.new(0,7); fp.Parent=fontScroll
local function setFont(name)
    local ok,f=pcall(function() return Enum.Font[name] end); if not ok or not f then return end
    S.FontName=name; S.Font=f
    for _,obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            pcall(function() obj.Font=f end)
        end
    end
end
for _,name in ipairs(fonts) do
    local b=button(fontScroll,1740); b.Size=UDim2.new(1,0,0,30); b.BackgroundColor3=Color3.fromRGB(38,38,38); b.BackgroundTransparency=.12; b.Text=name; b.TextColor3=Color3.fromRGB(235,235,235); b.TextSize=10; b.Font=Enum.Font[name] or Enum.Font.Gotham; corner(b,7); connect(b.Activated,function() setFont(name) end) end

-- Target / aim helpers.
local function getRootHum(plr)
    local c=plr and plr.Character; if not c then return end
    return c:FindFirstChild("HumanoidRootPart"),c:FindFirstChildOfClass("Humanoid")
end
local function alive(plr)
    local r,h=getRootHum(plr); return r and h and h.Health>0 and h:GetState()~=Enum.HumanoidStateType.Dead
end
local function canSee(part)
    if not S.AimLOS then return true end
    local origin=Camera.CFrame.Position; local dir=part.Position-origin
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={LocalPlayer.Character}; local hit=workspace:Raycast(origin,dir,params)
    return not hit or hit.Instance:IsDescendantOf(part.Parent)
end
local function aimTarget()
    local center=Camera.ViewportSize/2; local best,bestD=nil,S.FOV
    if S.AimPlayers then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and alive(p) then
                local c=p.Character; local part=c and (c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")); if part then local pos,on=Camera:WorldToViewportPoint(part.Position); if on then local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude; if d<bestD and canSee(part) then best,bestD=part,d end end end
            end
        end
    end
    if S.AimNPC then
        for _,m in ipairs(workspace:GetDescendants()) do
            if m:IsA("Model") and not Players:GetPlayerFromCharacter(m) and m:FindFirstChildOfClass("Humanoid") then
                local h=m:FindFirstChildOfClass("Humanoid"); local part=m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart"); if h.Health>0 and part then local pos,on=Camera:WorldToViewportPoint(part.Position); if on then local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude; if d<bestD and canSee(part) then best,bestD=part,d end end end
            end
        end
    end
    return best
end

-- FOV circle.
local fov=frame(gui,Color3.new(0,0,0),1,1750); fov.AnchorPoint=Vector2.new(.5,.5); fov.Position=UDim2.fromScale(.5,.5); fov.Size=UDim2.fromOffset(S.FOV*2,S.FOV*2); fov.Visible=false; corner(fov,S.FOV)
local fovStroke=stroke(fov,.35); fovStroke.Thickness=1
connect(RunService.RenderStepped:Connect(function() fov.Size=UDim2.fromOffset(S.FOV*2,S.FOV*2); fov.Visible=S.FOVEnabled end))

-- Watermark.
local wm=frame(gui,Color3.fromRGB(10,10,10),.13,1760); wm.AnchorPoint=Vector2.new(.5,0); wm.Position=UDim2.new(.5,0,0,15); wm.Size=UDim2.fromOffset(350,36); wm.Visible=false; corner(wm,18); stroke(wm,.78)
local wmText=label(wm,"",10,1765); wmText.Size=UDim2.new(1,-20,1,0); wmText.Position=UDim2.fromOffset(10,0); wmText.TextXAlignment=Enum.TextXAlignment.Center

-- Crosshair.
local cross=frame(gui,Color3.new(0,0,0),1,1760); cross.AnchorPoint=Vector2.new(.5,.5); cross.Position=UDim2.fromScale(.5,.5); cross.Size=UDim2.fromOffset(22,22); cross.Visible=false
local ch1=frame(cross,Color3.fromRGB(240,240,240),0,1761); ch1.Position=UDim2.new(.5,-1,0,0); ch1.Size=UDim2.fromOffset(2,22); local ch2=frame(cross,Color3.fromRGB(240,240,240),0,1761); ch2.Position=UDim2.new(0,.0,.5,-1); ch2.Size=UDim2.new(1,0,0,2)

-- Role detection.
local roleColors={Murder=Color3.fromRGB(255,70,70),Sheriff=Color3.fromRGB(80,150,255),Innocent=Color3.fromRGB(90,230,120),Unknown=Color3.fromRGB(185,185,185)}
local function getRole(plr)
    local pd=plr:FindFirstChild("PlayerData")
    local role=pd and (pd:FindFirstChild("Role") or pd:FindFirstChild("RoleValue"))
    if role and role.Value then local r=tostring(role.Value); if r:lower():find("murder") then return "Murder" elseif r:lower():find("sheriff") then return "Sheriff" elseif r:lower():find("innocent") then return "Innocent" end end
    local attr=plr:GetAttribute("Role"); if attr then local r=tostring(attr); if r:lower():find("murder") then return "Murder" elseif r:lower():find("sheriff") then return "Sheriff" elseif r:lower():find("innocent") then return "Innocent" end end
    local c=plr.Character
    if c then
        if c:FindFirstChild("Knife") or c:FindFirstChild("MurderKnife") then return "Murder" end
        if c:FindFirstChild("Gun") or c:FindFirstChild("Revolver") then return "Sheriff" end
    end
    local bp=plr:FindFirstChildOfClass("Backpack")
    if bp then
        if bp:FindFirstChild("Knife") or bp:FindFirstChild("MurderKnife") then return "Murder" end
        if bp:FindFirstChild("Gun") or bp:FindFirstChild("Revolver") then return "Sheriff" end
    end
    return "Unknown"
end
local function clearPlayerVisual(plr)
    if S.highlights[plr] then pcall(function() S.highlights[plr]:Destroy() end); S.highlights[plr]=nil end
    if S.labels[plr] then pcall(function() S.labels[plr]:Destroy() end); S.labels[plr]=nil end
end
local function applyVisual(plr)
    if plr==LocalPlayer then return end
    clearPlayerVisual(plr)
    local c=plr.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); if not c or not root then return end
    local role=getRole(plr); local col=roleColors[role] or roleColors.Unknown
    if S.Chams then local h=track(Instance.new("Highlight")); h.Name="HirukuChams"; h.Adornee=c; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.FillColor=col; h.OutlineColor=col; h.FillTransparency=.55; h.OutlineTransparency=.08; h.Parent=gui; S.highlights[plr]=h end
    if S.RoleLabels then local bg=track(Instance.new("BillboardGui")); bg.Name="HirukuRole"; bg.Adornee=root; bg.AlwaysOnTop=true; bg.Size=UDim2.fromOffset(220,35); bg.StudsOffset=Vector3.new(0,3,0); bg.Parent=gui; local t=label(bg,plr.DisplayName.." • "..role,10,1765); t.Size=UDim2.fromScale(1,1); t.TextXAlignment=Enum.TextXAlignment.Center; t.TextColor3=col; S.labels[plr]=bg end
end
for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then connect(p.CharacterAdded:Connect(function() task.wait(.25); if S.alive then applyVisual(p) end end)) end end
connect(Players.PlayerAdded:Connect(function(p) connect(p.CharacterAdded:Connect(function() task.wait(.25); if S.alive then applyVisual(p) end end)) end))

-- Coin helpers: exact object name "Coin" anywhere in Workspace.
local function coinPos(o)
    if o:IsA("BasePart") then return o.Position end
    if o:IsA("Model") then local p=o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true); return p and p.Position end
end
local function coins()
    local out={}; for _,o in ipairs(workspace:GetDescendants()) do if o.Name=="Coin" and (o:IsA("BasePart") or o:IsA("Model")) then table.insert(out,o) end end; return out
end
local function nearestCoin(root)
    local best,dist=nil,math.huge; for _,o in ipairs(coins()) do local p=coinPos(o); if p then local d=(p-root.Position).Magnitude; if d<dist then best,dist=o,d end end end; return best,dist
end

-- Private-test gun detector. It never searches arbitrary Tool names across live players.
local function isTestGun(o)
    if not o then return false end
    if o:GetAttribute("HirukuTestGun")==true then return true end
    local drops=workspace:FindFirstChild("HirukuTestDrops")
    return drops and o:IsDescendantOf(drops) and (o.Name=="Gun" or o.Name=="Revolver" or o.Name=="DroppedGun")
end
local function gunPos(o)
    if o:IsA("BasePart") then return o.Position end
    if o:IsA("Model") then local p=o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true); return p and p.Position end
    if o:IsA("Tool") then local p=o:FindFirstChild("Handle"); return p and p.Position end
end
local function nearestTestGun(root)
    local best,dist=nil,math.huge
    for _,o in ipairs(workspace:GetDescendants()) do if isTestGun(o) then local p=gunPos(o); if p then local d=(p-root.Position).Magnitude; if d<dist then best,dist=o,d end end end end
    return best,dist
end

-- Movement loop / Android joystick support.
local anti=0; local visualTick=0; local oldSpeed=nil; local oldJump=nil
connect(RunService.Heartbeat:Connect(function(dt)
    if not S.alive then return end
    local c=LocalPlayer.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); local hum=c and c:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if oldSpeed==nil then oldSpeed=hum.WalkSpeed end; if oldJump==nil then oldJump=hum.JumpPower end

    if S.AimEnabled then local target=aimTarget(); if target then local desired=CFrame.lookAt(Camera.CFrame.Position,target.Position); Camera.CFrame=Camera.CFrame:Lerp(desired,math.clamp(1-S.AimSmooth,0,1)) end end

    if S.BunnyHop then
        hum.WalkSpeed=S.BunnySpeed
        if hum.FloorMaterial~=Enum.Material.Air then hum.Jump=true end
        if S.BunnyAutoStrafe and hum.MoveDirection.Magnitude>.05 then local d=hum.MoveDirection; root.AssemblyLinearVelocity=Vector3.new(d.X*S.BunnySpeed,root.AssemblyLinearVelocity.Y,d.Z*S.BunnySpeed) end
    elseif not S.Fly then hum.WalkSpeed=oldSpeed end

    if S.NoClip then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
    if S.Spin then root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(S.SpinSpeed*60*dt),0) end

    if S.Fly then
        local dir=hum.MoveDirection; local cf=Camera.CFrame; local flat=Vector3.new(dir.X,0,dir.Z)
        if flat.Magnitude<.05 then flat=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z) end
        local vertical=0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical=1 elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical=-1 end
        local v=flat.Magnitude>0 and flat.Unit*S.FlySpeed or Vector3.zero; root.AssemblyLinearVelocity=Vector3.new(v.X,vertical*S.FlySpeed,v.Z)
    end

    if S.CoinFarm then
        local coin=nearestCoin(root); local p=coin and coinPos(coin); if p then local d=p-root.Position; if d.Magnitude>2 then root.AssemblyLinearVelocity=d.Unit*S.CoinFarmSpeed end end
    end
    if S.AutoPickupGun then
        local gun=nearestTestGun(root); local p=gun and gunPos(gun); if p then local d=p-root.Position; if d.Magnitude>3 then root.AssemblyLinearVelocity=d.Unit*math.max(90,S.CoinFarmSpeed) end end
    end

    anti+=dt; if S.AntiAFK and anti>45 then anti=0; pcall(function() local vu=game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new()) end) end
    visualTick+=dt; if visualTick>.35 then visualTick=0; if S.Chams or S.RoleLabels then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then applyVisual(p) end end end end
end))

-- Watermark and lighting.
local frames=0; local last=os.clock(); local fps=60; local savedLight={Brightness=Lighting.Brightness,ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows}
local function ping()
    local ok,v=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end); return ok and (tostring(v):match("%d+") or "—") or "—"
end
connect(RunService.RenderStepped:Connect(function()
    frames+=1; local now=os.clock(); if now-last>=.5 then fps=math.floor(frames/(now-last)+.5); frames=0; last=now end
    cross.Visible=S.Crosshair
    if S.Watermark then local p={"Hiruku"}; if S.WatermarkFPS then table.insert(p,fps.." FPS") end; table.insert(p,LocalPlayer.DisplayName); if S.WatermarkPing then table.insert(p,ping().." ms") end; wmText.Text=table.concat(p,"   •   "); wm.Visible=true else wm.Visible=false end
    if S.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=100000; Lighting.GlobalShadows=false else Lighting.Brightness=savedLight.Brightness; Lighting.ClockTime=savedLight.ClockTime; Lighting.FogEnd=savedLight.FogEnd; Lighting.GlobalShadows=savedLight.GlobalShadows end
end))

-- Search: only feature rows are filtered; section labels remain visible.
connect(search:GetPropertyChangedSignal("Text"):Connect(function()
    local q=search.Text:lower(); for _,x in ipairs(pages[S.tab]:GetChildren()) do if x:IsA("Frame") and x:GetAttribute("FeatureName") then x.Visible=(q=="" or tostring(x:GetAttribute("FeatureName")):lower():find(q,1,true)~=nil) end end
end))

-- Dragging: header-only; prevents menu body controls from moving the menu.
local function draggable(obj,handle)
    local active=false; local start; local origin
    connect(handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then active=true; start=i.Position; origin=obj.Position end
    end))
    connect(handle.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then active=false end end))
    connect(UserInputService.InputChanged:Connect(function(i)
        if active and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-start; obj.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y) end
    end))
end
draggable(menu,drag); draggable(pill,pill)

-- Navigation and menu visibility.
for n,b in pairs(tabRefs) do connect(b.Activated,function() setTab(n) end) end
setTab("Combat")
connect(pill.Activated,function() S.menu=not S.menu; if S.menu then touchBlock.Visible=true; menu.Visible=true; menu.BackgroundTransparency=.10; tween(menu,.25,{BackgroundTransparency=.02}) else tween(menu,.2,{BackgroundTransparency=.35}); task.delay(.21,function() if not S.menu then menu.Visible=false; touchBlock.Visible=false end end) end end)
connect(UserInputService.InputBegan:Connect(function(i,gpe) if not gpe and i.KeyCode==Enum.KeyCode.RightShift then S.menu=not S.menu; menu.Visible=S.menu; touchBlock.Visible=S.menu end end))

-- Notification.
local toast=frame(gui,Color3.fromRGB(10,10,10),.10,1980); toast.AnchorPoint=Vector2.new(0,1); toast.Position=UDim2.new(0,-275,1,-18); toast.Size=UDim2.fromOffset(270,40); corner(toast,13); stroke(toast,.78)
local tt=label(toast,"Hiruku Script successfully injected",10,1985); tt.Size=UDim2.fromScale(1,1); tt.TextXAlignment=Enum.TextXAlignment.Center
tween(toast,.35,{Position=UDim2.new(0,18,1,-18)}); task.delay(3,function() if toast.Parent then tween(toast,.3,{Position=UDim2.new(0,-275,1,-18)}) end end)

print("[Hiruku] V8 Android UI loaded")
