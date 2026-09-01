--// HIRUKU MM2 V19
--// Mobile-first standalone Luau UI
--// Clean rewrite of the V18 interaction/render loop.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local GUI_PARENT = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

local KEY = "__HIRUKU_MM2_V19"
pcall(function() if _G[KEY] and _G[KEY].Cleanup then _G[KEY].Cleanup() end end)

local S = {
    Open=false, Page="Combat",
    AimBot=false, SilentAim=false, FOV=false,
    AimFOV=180, AimSmooth=.20, AimLOS=true,
    AutoShot=false,
    KillAura=false, KillSelected=false, KillAll=false, SelectedPlayer=nil,
    AttackRange=14, AttackCooldown=.25,
    Chams=false, RoleLabels=true, Watermark=false, EspGun=false,
    Crosshair=false, Fullbright=false, NoFog=false, Tracers=false,
    DistanceESP=false, BoxESP=false, RainbowChams=false,
    SkyEnabled=false, SkyColor=Color3.fromRGB(150,205,255),
    CoinFarm=false, CoinSpeed=90, CoinDelay=.07,
    AutoPickupGun=false, AutoPickupDelay=.15,
    Fly=false, FlySpeed=55, FlyUpSpeed=55,
    BunnyHop=false, BunnyAccel=4, BunnyMax=250, BunnyCurrent=16,
    BunnyAutoStrafe=true,
    NoClip=false, Spin=false, SpinSpeed=1800,
    TargetAura=false, TargetAuraPlayer=nil, TargetAuraSpeed=55,
    AntiAFK=false,
    Theme="Obsidian", Font="GothamBold", UIScale=1, MenuOpacity=.90,
    _showNotifications=true,
}

local savedLighting={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient}; local savedAtmosphereDensity={}
for _,o in ipairs(Lighting:GetChildren()) do if o:IsA("Atmosphere") then savedAtmosphereDensity[o]=o.Density end end

local THEMES={
    Obsidian={panel=Color3.fromRGB(13,13,16),card=Color3.fromRGB(25,25,29),card2=Color3.fromRGB(32,32,38),text=Color3.fromRGB(245,245,248),sub=Color3.fromRGB(165,165,175),accent=Color3.fromRGB(235,235,240),line=Color3.fromRGB(62,62,70),on=Color3.fromRGB(235,235,240),off=Color3.fromRGB(57,57,64)},
    Violet={panel=Color3.fromRGB(19,12,27),card=Color3.fromRGB(32,21,42),card2=Color3.fromRGB(43,28,55),text=Color3.fromRGB(250,244,255),sub=Color3.fromRGB(184,165,198),accent=Color3.fromRGB(218,165,255),line=Color3.fromRGB(77,50,91),on=Color3.fromRGB(226,190,255),off=Color3.fromRGB(67,48,78)},
    Midnight={panel=Color3.fromRGB(9,15,25),card=Color3.fromRGB(19,28,42),card2=Color3.fromRGB(26,38,55),text=Color3.fromRGB(241,247,255),sub=Color3.fromRGB(156,172,192),accent=Color3.fromRGB(145,195,255),line=Color3.fromRGB(51,70,96),on=Color3.fromRGB(160,205,255),off=Color3.fromRGB(49,65,84)},
    Crimson={panel=Color3.fromRGB(23,9,12),card=Color3.fromRGB(40,18,22),card2=Color3.fromRGB(52,22,27),text=Color3.fromRGB(255,246,247),sub=Color3.fromRGB(193,160,164),accent=Color3.fromRGB(255,170,178),line=Color3.fromRGB(84,43,48),on=Color3.fromRGB(255,185,192),off=Color3.fromRGB(74,44,48)},
    Aurora={panel=Color3.fromRGB(9,18,17),card=Color3.fromRGB(17,34,32),card2=Color3.fromRGB(23,47,43),text=Color3.fromRGB(239,255,250),sub=Color3.fromRGB(157,190,181),accent=Color3.fromRGB(150,255,220),line=Color3.fromRGB(45,83,75),on=Color3.fromRGB(155,255,222),off=Color3.fromRGB(47,71,66)},
}
local FONTS={Gotham=Enum.Font.Gotham,GothamBold=Enum.Font.GothamBold,SourceSans=Enum.Font.SourceSans,SourceSansBold=Enum.Font.SourceSansBold,Arial=Enum.Font.Arial,Code=Enum.Font.Code,Cartoon=Enum.Font.Cartoon,Fantasy=Enum.Font.Fantasy,SciFi=Enum.Font.SciFi,Bangers=Enum.Font.Bangers}
local function C() return THEMES[S.Theme] or THEMES.Obsidian end

local CONNS, INST, CHAMS, LABELS, GUNESP, TRACERS, BOXES, DISTANCES = {}, {}, {}, {}, {}, {}, {}, {}
local function conn(x) if x then table.insert(CONNS,x) end return x end
local function inst(x) if x then table.insert(INST,x) end return x end
local function disconnectAll() for _,x in ipairs(CONNS) do pcall(function() x:Disconnect() end) end table.clear(CONNS) end
local function destroyAll() for _,x in ipairs(INST) do pcall(function() x:Destroy() end) end table.clear(INST) end
local function char() return LP.Character end
local function hum(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function root(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function alive(m) local h=hum(m); return h and h.Health>0 and root(m) end
local function playerAlive(p) return p and p~=LP and alive(p.Character) end

local function corner(o,r) local x=Instance.new("UICorner"); x.CornerRadius=UDim.new(0,r or 10); x.Parent=o; return x end
local function stroke(o,color,tr,th) local x=Instance.new("UIStroke"); x.Color=color; x.Transparency=tr or 0; x.Thickness=th or 1; x.Parent=o; return x end
local function tw(o,t,p,style) local ok,x=pcall(function() return TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quint,Enum.EasingDirection.Out),p) end); if ok then x:Play(); return x end end
local function fr(p,size,pos,color,tr,z) local x=Instance.new("Frame"); x.BackgroundColor3=color or C().panel; x.BackgroundTransparency=tr or 0; x.BorderSizePixel=0; x.Size=size; x.Position=pos; x.ZIndex=z or 10; x.Parent=p; return x end
local function txt(p,s,size,pos,fs,color,z,align) local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Text=s; x.TextColor3=color or C().text; x.TextSize=fs or 13; x.Font=FONTS[S.Font] or Enum.Font.GothamBold; x.Size=size; x.Position=pos; x.ZIndex=z or 20; x.TextXAlignment=align or Enum.TextXAlignment.Left; x.TextYAlignment=Enum.TextYAlignment.Center; x.Parent=p; return x end
local function btn(p,s,size,pos,z) local x=Instance.new("TextButton"); x.AutoButtonColor=false; x.Text=s; x.TextColor3=C().text; x.TextSize=13; x.Font=FONTS[S.Font] or Enum.Font.GothamBold; x.BackgroundColor3=C().card; x.BorderSizePixel=0; x.Size=size; x.Position=pos; x.ZIndex=z or 20; x.Parent=p; corner(x,9); return x end

-- UI
local gui=Instance.new("ScreenGui"); gui.Name="Hiruku"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; pcall(function() gui.DisplayOrder=999999 end); gui.Parent=GUI_PARENT; inst(gui)
local pill=fr(gui,UDim2.fromOffset(148,46),UDim2.new(0,22,.5,-23),C().panel,.10,800); corner(pill,23); stroke(pill,C().line,.10); txt(pill,"Hiruku",UDim2.fromScale(1,1),UDim2.fromOffset(0,0),14,C().text,810,Enum.TextXAlignment.Center)
local main=fr(gui,UDim2.fromOffset(760,510),UDim2.new(.5,-380,.5,-255),C().panel,.10,700); corner(main,18); stroke(main,C().line,.08); main.Visible=false; main.Active=true
local mainScale=Instance.new("UIScale"); mainScale.Scale=S.UIScale; mainScale.Parent=main
local glass=fr(main,UDim2.fromScale(1,1),UDim2.fromScale(0,0),Color3.new(1,1,1),.94,701); corner(glass,18)
local title=txt(main,"Hiruku",UDim2.new(1,-110,0,30),UDim2.fromOffset(28,18),20,C().text,730)
local version=txt(main,"MM2 - v 1.0",UDim2.new(1,-110,0,22),UDim2.fromOffset(28,45),10,C().sub,730)
local close=btn(main,"×",UDim2.fromOffset(38,38),UDim2.new(1,-56,0,17),740); close.TextSize=20
local search=Instance.new("TextBox"); search.BackgroundColor3=C().card; search.BackgroundTransparency=.08; search.TextColor3=C().text; search.PlaceholderColor3=C().sub; search.PlaceholderText="Search feature..."; search.Text=""; search.ClearTextOnFocus=false; search.TextSize=12; search.Font=FONTS[S.Font]; search.Size=UDim2.new(1,-48,0,38); search.Position=UDim2.fromOffset(24,82); search.ZIndex=735; search.Parent=main; corner(search,19)
local nav=fr(main,UDim2.fromOffset(150,340),UDim2.fromOffset(20,135),Color3.new(0,0,0),1,705); corner(nav,12)
local content=fr(main,UDim2.new(1,-190,1,-150),UDim2.fromOffset(174,135),Color3.new(0,0,0),1,705)
local pages, navBtns, cursors={}, {}, {}
for _,n in ipairs({"Combat","Visuals","Misc","Settings"}) do
    cursors[n]=0
    local b=btn(nav,n,UDim2.new(1,-8,0,56),UDim2.fromOffset(4,(#navBtns)*72),720); navBtns[n]=b
    local pg=Instance.new("ScrollingFrame"); pg.Name=n; pg.BackgroundTransparency=1; pg.BorderSizePixel=0; pg.Size=UDim2.fromScale(1,1); pg.ScrollBarThickness=3; pg.ScrollBarImageTransparency=.35; pg.CanvasSize=UDim2.new(0,0,0,0); pg.ZIndex=710; pg.Parent=content; pages[n]=pg
    table.insert(navBtns,b)
end

local drag={active=false,start=nil,origin=nil}
local dragArea=Instance.new("TextButton"); dragArea.BackgroundTransparency=1; dragArea.Text=""; dragArea.AutoButtonColor=false; dragArea.Size=UDim2.new(1,-120,0,70); dragArea.Position=UDim2.fromOffset(10,4); dragArea.ZIndex=750; dragArea.Parent=main
conn(dragArea.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag.active=true; drag.start=i.Position; drag.origin=main.Position end end))
conn(UIS.InputChanged:Connect(function(i) if drag.active and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-drag.start; local vp=Camera.ViewportSize; main.Position=UDim2.fromOffset(math.clamp(drag.origin.X.Offset+d.X,8,vp.X-main.AbsoluteSize.X-8),math.clamp(drag.origin.Y.Offset+d.Y,8,vp.Y-main.AbsoluteSize.Y-8)) end end))
conn(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag.active=false end end))

-- Animated title gradient, intentionally slow.
local gradTitle=Instance.new("UIGradient"); gradTitle.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(65,65,70)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}; gradTitle.Parent=title
local gradVer=Instance.new("UIGradient"); gradVer.Color=gradTitle.Color; gradVer.Parent=version
local gradPos=0
conn(RunService.RenderStepped:Connect(function(dt)
    gradPos=(gradPos+dt*.055)%1
    gradTitle.Offset=Vector2.new(gradPos*2-1,0); gradVer.Offset=Vector2.new(gradPos*2-1,0)
end))

-- drawer
local drawer=fr(gui,UDim2.fromOffset(360,0),UDim2.new(.5,20,.5,-180),C().panel,.06,900); corner(drawer,16); stroke(drawer,C().line,.08); drawer.Visible=false
local drawerTitle=txt(drawer,"Settings",UDim2.new(1,-60,0,32),UDim2.fromOffset(18,14),17,C().text,910)
local drawerClose=btn(drawer,"×",UDim2.fromOffset(34,34),UDim2.new(1,-48,0,12),915)
local drawerDrag=Instance.new("TextButton"); drawerDrag.BackgroundTransparency=1; drawerDrag.Text=""; drawerDrag.AutoButtonColor=false; drawerDrag.Size=UDim2.new(1,-70,0,54); drawerDrag.Position=UDim2.fromOffset(8,4); drawerDrag.ZIndex=920; drawerDrag.Parent=drawer
local drawerMoving=false; local drawerStart=nil; local drawerOrigin=nil
conn(drawerDrag.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drawerMoving=true; drawerStart=i.Position; drawerOrigin=drawer.Position end end))
conn(UIS.InputChanged:Connect(function(i) if drawerMoving and drawerStart and drawerOrigin and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-drawerStart; local vp=Camera.ViewportSize; drawer.Position=UDim2.fromOffset(math.clamp(drawerOrigin.X.Offset+d.X,8,vp.X-drawer.AbsoluteSize.X-8),math.clamp(drawerOrigin.Y.Offset+d.Y,8,vp.Y-drawer.AbsoluteSize.Y-8)) end end))
conn(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drawerMoving=false end end))
local drawerBody=Instance.new("ScrollingFrame"); drawerBody.BackgroundTransparency=1; drawerBody.BorderSizePixel=0; drawerBody.Size=UDim2.new(1,-24,1,-58); drawerBody.Position=UDim2.fromOffset(12,52); drawerBody.ScrollBarThickness=3; drawerBody.ZIndex=905; drawerBody.Parent=drawer
local drawerY=0
local function clearDrawer() for _,o in ipairs(drawerBody:GetChildren()) do o:Destroy() end drawerY=0 drawerBody.CanvasSize=UDim2.new(0,0,0,0) end
local function openDrawer(name,builder)
    clearDrawer()
    drawerTitle.Text=name
    drawer.Visible=true
    builder()
    local wantedH=math.clamp(drawerY+76,150,math.min(420,Camera.ViewportSize.Y-24))
    local vp=Camera.ViewportSize
    drawer.Position=UDim2.fromOffset(math.clamp(drawer.Position.X.Offset,8,math.max(8,vp.X-368)),math.clamp((vp.Y-wantedH)/2,8,math.max(8,vp.Y-wantedH-8)))
    drawer.Size=UDim2.fromOffset(360,0)
    drawerBody.Size=UDim2.new(1,-24,1,-58)
    drawerBody.CanvasSize=UDim2.new(0,0,0,drawerY+8)
    tw(drawer,.22,{Size=UDim2.fromOffset(360,wantedH)},Enum.EasingStyle.Quint)
end
local function closeDrawer() if not drawer.Visible then return end; local t=tw(drawer,.18,{Size=UDim2.fromOffset(360,0)},Enum.EasingStyle.Quint); if t then conn(t.Completed:Connect(function() drawer.Visible=false end)) end end
conn(drawerClose.Activated:Connect(closeDrawer))

local toast=fr(gui,UDim2.fromOffset(300,52),UDim2.new(0,18,1,-72),C().panel,.08,1000); corner(toast,16); stroke(toast,C().line,.08); local toastText=txt(toast,"Hiruku loaded",UDim2.new(1,-24,1,0),UDim2.fromOffset(12,0),13,C().text,1010)
local function notify(s) if S._showNotifications==false then return end; toastText.Text=s; toast.Position=UDim2.new(0,-320,1,-72); tw(toast,.28,{Position=UDim2.new(0,18,1,-72)}); task.delay(2.2,function() tw(toast,.25,{Position=UDim2.new(0,-320,1,-72)}) end) end

local menuAnimating=false
local function menuSize() local vp=Camera.ViewportSize; local w=math.min(760,math.max(350,vp.X-24)); local h=math.min(510,math.max(360,vp.Y-24)); return UDim2.fromOffset(w,h) end
local function centerMenu() local sz=menuSize(); local vp=Camera.ViewportSize; main.Size=sz; main.Position=UDim2.fromOffset(math.max(8,(vp.X-main.AbsoluteSize.X)/2),math.max(8,(vp.Y-main.AbsoluteSize.Y)/2)) end
local function animateText(show)
    local a=show and 0 or 1
    tw(title,.24,{TextTransparency=a}); tw(version,.24,{TextTransparency=a}); tw(search,.24,{BackgroundTransparency=show and .08 or 1,TextTransparency=a})
    for _,b in pairs(navBtns) do tw(b,.24,{BackgroundTransparency=show and 0 or 1,TextTransparency=a}) end
end
local function openMenu()
    if S.Open or menuAnimating then return end
    menuAnimating=true; S.Open=true; centerMenu(); local target=main.Size; local p=main.Position; main.Position=UDim2.fromOffset(p.X,p.Y+target.Y.Offset/2); main.Size=UDim2.fromOffset(target.X.Offset,0); main.Visible=true; main.BackgroundTransparency=math.clamp(1-S.MenuOpacity,.08,.45); animateText(true); local t=tw(main,.30,{Position=p,Size=target,BackgroundTransparency=math.clamp(1-S.MenuOpacity,.08,.45)}); if t then conn(t.Completed:Connect(function() menuAnimating=false end)) end
end
local function closeMenu()
    if not S.Open or menuAnimating then return end
    menuAnimating=true; S.Open=false; if drawer.Visible then closeDrawer() end; animateText(false); local p=main.Position; local sz=main.AbsoluteSize; local t=tw(main,.22,{Position=UDim2.fromOffset(p.X,p.Y+sz.Y/2),Size=UDim2.fromOffset(sz.X,0),BackgroundTransparency=.12}); if t then conn(t.Completed:Connect(function() main.Visible=false; menuAnimating=false; centerMenu() end)) end
end
conn(pill.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then if S.Open then closeMenu() else openMenu() end end end))
conn(close.Activated:Connect(closeMenu))

-- Cards
local function keyOf(parent) for n,p in pairs(pages) do if p==parent then return n end end return "__drawer" end
local function canvas(parent,k) if pages[k] then pages[k].CanvasSize=UDim2.new(0,0,0,cursors[k]+10) elseif parent==drawerBody then drawerBody.CanvasSize=UDim2.new(0,0,0,drawerY+8) end end
local function section(parent,name) local k=keyOf(parent); local y=cursors[k] or drawerY; y+=8; local l=txt(parent,name,UDim2.new(1,-10,0,22),UDim2.fromOffset(5,y),10,C().sub,720); y+=30; if pages[k] then cursors[k]=y else drawerY=y end; canvas(parent,k); return l end
local function toggle(parent,name,desc,get,set,settings)
    local k=keyOf(parent); local y=(pages[k] and cursors[k] or drawerY); local h=68
    local c=fr(parent,UDim2.new(1,-10,0,h),UDim2.fromOffset(5,y),C().card,.01,715); corner(c,11)
    txt(c,name,UDim2.new(1,-132,0,22),UDim2.fromOffset(14,7),13,C().text,725)
    txt(c,desc,UDim2.new(1,-132,0,19),UDim2.fromOffset(14,34),9,C().sub,725)
    local sw=btn(c,"",UDim2.fromOffset(44,24),UDim2.new(1,-58,.5,-12),730); sw.BackgroundColor3=C().off; local dot=fr(sw,UDim2.fromOffset(16,16),UDim2.fromOffset(4,4),Color3.fromRGB(180,180,185),0,731); corner(dot,8)
    local function refresh() local on=get(); sw.BackgroundColor3=on and C().on or C().off; dot.BackgroundColor3=on and C().panel or Color3.fromRGB(180,180,185); tw(dot,.14,{Position=on and UDim2.new(1,-20,.5,-8) or UDim2.fromOffset(4,4)}) end
    conn(sw.Activated:Connect(function() set(not get()); refresh() end)); refresh()
    if settings then local sb=btn(c,"SET",UDim2.fromOffset(38,22),UDim2.new(1,-102,.5,-11),729); sb.TextSize=9; sb.BackgroundTransparency=.28; conn(sb.Activated:Connect(settings)) end
    if pages[k] then cursors[k]=y+h+8; canvas(parent,k) else drawerY=y+h+8; canvas(parent,k) end
end
local function slider(parent,name,min,max,get,set)
    local k=keyOf(parent); local y=(pages[k] and cursors[k] or drawerY); local c=fr(parent,UDim2.new(1,-10,0,64),UDim2.fromOffset(5,y),C().card,.01,715); corner(c,11); txt(c,name,UDim2.new(1,-95,0,22),UDim2.fromOffset(14,7),12,C().text,725); local val=txt(c,"",UDim2.fromOffset(65,20),UDim2.new(1,-79,0,20),10,C().sub,725,Enum.TextXAlignment.Right); local bar=fr(c,UDim2.new(1,-28,0,6),UDim2.fromOffset(14,43),C().off,0,726); corner(bar,3); local fill=fr(bar,UDim2.fromScale(0,1),UDim2.fromScale(0,0),C().accent,0,727); corner(fill,3); local dragSlider=false
    local function setX(x) local pct=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1); set(min+(max-min)*pct) end
    conn(bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragSlider=true; setX(i.Position.X) end end)); conn(UIS.InputChanged:Connect(function(i) if dragSlider and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then setX(i.Position.X) end end)); conn(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragSlider=false end end))
    local function refresh() local v=get(); local pct=math.clamp((v-min)/(max-min),0,1); fill.Size=UDim2.new(pct,0,1,0); val.Text=tostring(math.floor(v+.5)) end refresh(); if pages[k] then cursors[k]=y+72; canvas(parent,k) else drawerY=y+72; canvas(parent,k) end
end
local function optionList(parent,title,items,get,set)
    local k=keyOf(parent); section(parent,title); for _,it in ipairs(items) do local b=btn(parent,it[1],UDim2.new(1,-10,0,38),UDim2.fromOffset(5,pages[k] and cursors[k] or drawerY),715); conn(b.Activated:Connect(function() set(it[2]); for _,q in ipairs(parent:GetChildren()) do if q:IsA("TextButton") and q~=b then q.TextColor3=C().sub end end; b.TextColor3=C().text end)); b.TextColor3=(get()==it[2]) and C().text or C().sub; if pages[k] then cursors[k]+=44 else drawerY+=44 end end; canvas(parent,k)
end

-- Combat
section(pages.Combat,"SHERIFF")
toggle(pages.Combat,"Aim Bot","Smooth camera aim inside FOV",function() return S.AimBot end,function(v) S.AimBot=v end,function() openDrawer("Aim Bot",function() slider(drawerBody,"FOV radius",60,500,function() return S.AimFOV end,function(v) S.AimFOV=v end); slider(drawerBody,"Smoothness",1,100,function() return S.AimSmooth*100 end,function(v) S.AimSmooth=v/100 end); toggle(drawerBody,"Line of Sight","Require visible target",function() return S.AimLOS end,function(v) S.AimLOS=v end) end)
toggle(pages.Combat,"Silent Aim","Redirect shot direction to the best target in FOV",function() return S.SilentAim end,function(v) S.SilentAim=v end,function() slider(drawerBody,"FOV radius",60,500,function() return S.AimFOV end,function(v) S.AimFOV=v end); toggle(drawerBody,"Players","Use player targets",function() return true end,function(v) end); toggle(drawerBody,"Friends only","Limit to friends",function() return false end,function(v) end) end)
toggle(pages.Combat,"Auto Shot Murder","Shoot when a murderer is detected",function() return S.AutoShot end,function(v) S.AutoShot=v end,function() slider(drawerBody,"Scan interval",50,1000,function() return 150 end,function(v) end) end)
toggle(pages.Combat,"FOV","Draw the active aim field of view",function() return S.FOV end,function(v) S.FOV=v end,function() slider(drawerBody,"Radius",60,500,function() return S.AimFOV end,function(v) S.AimFOV=v end) end)
section(pages.Combat,"MURDER")
toggle(pages.Combat,"Kill Aura","Attack valid targets inside knife range",function() return S.KillAura end,function(v) S.KillAura=v end,function() slider(drawerBody,"Attack range",6,22,function() return S.AttackRange end,function(v) S.AttackRange=v end); slider(drawerBody,"Cooldown",1,10,function() return S.AttackCooldown*10 end,function(v) S.AttackCooldown=v/10 end) end)
toggle(pages.Combat,"Kill Selected","Quick target movement, knife activation, and return",function() return S.KillSelected end,function(v) S.KillSelected=v end,function() openDrawer("Kill Selected",function() local y=0; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then local b=btn(drawerBody,p.DisplayName.."  @"..p.Name,UDim2.new(1,0,0,40),UDim2.fromOffset(0,y),915); b.TextColor3=(S.SelectedPlayer==p and C().text or C().sub); conn(b.Activated:Connect(function() S.SelectedPlayer=p; notify("Selected: "..p.Name); for _,q in ipairs(drawerBody:GetChildren()) do if q:IsA("TextButton") then q.TextColor3=C().sub end end; b.TextColor3=C().text end)); y+=44 end end; drawerY=y; drawerBody.CanvasSize=UDim2.new(0,0,0,y+8) end) end)
toggle(pages.Combat,"Kill All","Quickly attack every player you are authorized to target",function() return S.KillAll end,function(v) S.KillAll=v end)

-- Visuals
section(pages.Visuals,"PLAYER VISUALS")
toggle(pages.Visuals,"Chams","Role-aware highlights",function() return S.Chams end,function(v) S.Chams=v end)
toggle(pages.Visuals,"Role Labels","Name and role above players",function() return S.RoleLabels end,function(v) S.RoleLabels=v end)
toggle(pages.Visuals,"Watermark","Hiruku • FPS • player • ping",function() return S.Watermark end,function(v) S.Watermark=v end)
toggle(pages.Visuals,"ESP Gun","Orange dropped-gun highlight",function() return S.EspGun end,function(v) S.EspGun=v end)
toggle(pages.Visuals,"Box ESP","Outlined player boxes",function() return S.BoxESP end,function(v) S.BoxESP=v end)
toggle(pages.Visuals,"Tracers","Lines from screen center to players",function() return S.Tracers end,function(v) S.Tracers=v end)
toggle(pages.Visuals,"Distance ESP","Show distance to players",function() return S.DistanceESP end,function(v) S.DistanceESP=v end)
toggle(pages.Visuals,"Rainbow Chams","Animated hue for chams",function() return S.RainbowChams end,function(v) S.RainbowChams=v end)
toggle(pages.Visuals,"Crosshair","Minimal center reticle",function() return S.Crosshair end,function(v) S.Crosshair=v end)
toggle(pages.Visuals,"Fullbright","Bright local lighting",function() return S.Fullbright end,function(v) S.Fullbright=v end)
toggle(pages.Visuals,"No Fog","Reduce local atmosphere haze",function() return S.NoFog end,function(v) S.NoFog=v end)
toggle(pages.Visuals,"Sky Color","Change local sky tint",function() return S.SkyEnabled end,function(v) S.SkyEnabled=v end,function() optionList(drawerBody,"SKY PRESETS",{{"Ice",Color3.fromRGB(150,205,255)},{"Violet",Color3.fromRGB(190,145,255)},{"Sunset",Color3.fromRGB(255,165,105)},{"Crimson",Color3.fromRGB(255,95,105)},{"Emerald",Color3.fromRGB(105,225,170)},{"Mono",Color3.fromRGB(210,210,210)}},function() return S.SkyColor end,function(v) S.SkyColor=v end) end)

-- Misc
section(pages.Misc,"MOVEMENT")
toggle(pages.Misc,"Fly","Joystick movement + jump button to rise",function() return S.Fly end,function(v) S.Fly=v end,function() slider(drawerBody,"Fly speed",10,180,function() return S.FlySpeed end,function(v) S.FlySpeed=v end); slider(drawerBody,"Rise speed",10,180,function() return S.FlyUpSpeed end,function(v) S.FlyUpSpeed=v end) end)
toggle(pages.Misc,"Bunny Hop","CS2-style repeated jumps with acceleration",function() return S.BunnyHop end,function(v) S.BunnyHop=v end,function() slider(drawerBody,"Acceleration",1,30,function() return S.BunnyAccel end,function(v) S.BunnyAccel=v end); slider(drawerBody,"Max speed",30,500,function() return S.BunnyMax end,function(v) S.BunnyMax=v end); toggle(drawerBody,"Auto Strafe","Keep acceleration while steering",function() return S.BunnyAutoStrafe end,function(v) S.BunnyAutoStrafe=v end) end)
toggle(pages.Misc,"No Clip","Disable character collisions",function() return S.NoClip end,function(v) S.NoClip=v end)
toggle(pages.Misc,"Spin","Rotate character",function() return S.Spin end,function(v) S.Spin=v end,function() slider(drawerBody,"Spin speed",100,10000,function() return S.SpinSpeed end,function(v) S.SpinSpeed=v end) end)
toggle(pages.Misc,"Coin Farm","Find objects named Coin and collect nearest",function() return S.CoinFarm end,function(v) S.CoinFarm=v end,function() slider(drawerBody,"Farm speed",20,250,function() return S.CoinSpeed end,function(v) S.CoinSpeed=v end); slider(drawerBody,"Pickup delay",1,30,function() return S.CoinDelay*100 end,function(v) S.CoinDelay=v/100 end) end)
toggle(pages.Misc,"Auto Pickup Gun","Only target dropped GunDrop/Pistol objects on the map",function() return S.AutoPickupGun end,function(v) S.AutoPickupGun=v end,function() slider(drawerBody,"Pickup delay",1,30,function() return S.AutoPickupDelay*100 end,function(v) S.AutoPickupDelay=v/100 end) end)
toggle(pages.Misc,"Sex Aura","Rapidly move toward selected player and back",function() return S.TargetAura end,function(v) S.TargetAura=v end,function() openDrawer("Sex Aura",function() local y=0; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then local b=btn(drawerBody,p.DisplayName,UDim2.new(1,0,0,40),UDim2.fromOffset(0,y),915); conn(b.Activated:Connect(function() S.TargetAuraPlayer=p; notify("Target: "..p.Name) end)); y+=44 end end; drawerY=y; slider(drawerBody,"Speed",10,200,function() return S.TargetAuraSpeed end,function(v) S.TargetAuraSpeed=v end) end) end)
toggle(pages.Misc,"Anti AFK","Periodic harmless input pulse",function() return S.AntiAFK end,function(v) S.AntiAFK=v end)

-- Settings
section(pages.Settings,"INTERFACE")
optionList(pages.Settings,"FONT",{{"Gotham Bold", "GothamBold"},{"Gotham","Gotham"},{"Source Sans","SourceSans"},{"Arial","Arial"},{"Sci-Fi","SciFi"},{"Bangers","Bangers"}},function() return S.Font end,function(v) S.Font=v end)
optionList(pages.Settings,"THEME",{{"Obsidian","Obsidian"},{"Violet","Violet"},{"Midnight","Midnight"},{"Crimson","Crimson"},{"Aurora","Aurora"}},function() return S.Theme end,function(v) S.Theme=v end)
slider(pages.Settings,"Interface Size",80,120,function() return S.UIScale*100 end,function(v) S.UIScale=v/100; if mainScale then tw(mainScale,.16,{Scale=S.UIScale},Enum.EasingStyle.Quart); task.defer(centerMenu) end end)
slider(pages.Settings,"Menu Opacity",50,95,function() return S.MenuOpacity*100 end,function(v) S.MenuOpacity=v/100 end)
toggle(pages.Settings,"Notifications","Show lower-left status messages",function() return S._showNotifications end,function(v) S._showNotifications=v end)
local reset=btn(pages.Settings,"Center menu",UDim2.new(1,-10,0,42),UDim2.fromOffset(5,cursors.Settings),720); conn(reset.Activated:Connect(centerMenu)); cursors.Settings+=50; canvas(pages.Settings,"Settings")

-- FOV, watermark, crosshair
local fov=fr(gui,UDim2.fromOffset(360,360),UDim2.new(.5,-180,.5,-180),Color3.new(0,0,0),1,1100); corner(fov,180); stroke(fov,C().accent,.18,2); fov.Visible=false; inst(fov)
local cross=fr(gui,UDim2.fromOffset(22,22),UDim2.new(.5,-11,.5,-11),Color3.new(0,0,0),1,1101); cross.Visible=false; local cv=fr(cross,UDim2.fromOffset(22,2),UDim2.fromOffset(0,10),C().text,0,1102); local ch=fr(cross,UDim2.fromOffset(2,22),UDim2.fromOffset(10,0),C().text,0,1102); inst(cross)
local watermark=fr(gui,UDim2.fromOffset(370,42),UDim2.new(.5,-185,0,18),C().panel,.08,1100); corner(watermark,21); stroke(watermark,C().line,.1); local wm=txt(watermark,"",UDim2.fromScale(1,1),UDim2.fromOffset(0,0),11,C().text,1110,Enum.TextXAlignment.Center); inst(watermark)

-- role detection
local ROLECOLOR={Murderer=Color3.fromRGB(245,65,75),Sheriff=Color3.fromRGB(65,145,255),Innocent=Color3.fromRGB(70,220,115),Unknown=Color3.fromRGB(170,170,175)}
local function role(p)
    if not p then return "Unknown" end
    local vals={p:GetAttribute("Role"),p:GetAttribute("role"),p:GetAttribute("PlayerRole")}
    local pd=p:FindFirstChild("PlayerData"); if pd then local r=pd:FindFirstChild("Role"); if r and r:IsA("StringValue") then table.insert(vals,r.Value) end end
    for _,v in ipairs(vals) do if typeof(v)=="string" then local x=v:lower(); if x:find("murder") then return "Murderer" elseif x:find("sheriff") then return "Sheriff" elseif x:find("innocent") then return "Innocent" end end end
    local c=p.Character; local bp=p:FindFirstChildOfClass("Backpack")
    for _,q in ipairs({c,bp}) do if q then if q:FindFirstChild("Knife") then return "Murderer" end; if q:FindFirstChild("Gun") or q:FindFirstChild("Pistol") then return "Sheriff" end end end
    return "Unknown"
end
local function clearPlayerESP(p)
    for _,tab in ipairs({CHAMS,LABELS,TRACERS,BOXES,DISTANCES}) do if tab[p] then pcall(function() tab[p]:Destroy() end); tab[p]=nil end end
end
local function makeESP(p)
    clearPlayerESP(p); if p==LP or not p.Character then return end
    local r=role(p); local color=ROLECOLOR[r]
    if S.Chams then local h=Instance.new("Highlight"); h.Name="HirukuChams"; h.Adornee=p.Character; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.FillTransparency=.48; h.OutlineTransparency=.08; h.FillColor=color; h.OutlineColor=color; h.Parent=gui; CHAMS[p]=h end
    local head=p.Character:FindFirstChild("Head")
    if S.RoleLabels and head then local b=Instance.new("BillboardGui"); b.Name="HirukuRole"; b.AlwaysOnTop=true; b.Size=UDim2.fromOffset(190,34); b.StudsOffset=Vector3.new(0,2.8,0); b.Adornee=head; b.Parent=gui; local t=txt(b,p.DisplayName.." • "..r,UDim2.fromScale(1,1),UDim2.fromScale(0,0),10,color,1120,Enum.TextXAlignment.Center); LABELS[p]=b end
end
local function refreshESP() for _,p in ipairs(Players:GetPlayers()) do if p~=LP then makeESP(p) end end end

-- dropped gun: only floor objects, never a gun held by a character/tool.
local function droppedGunPart()
    local best,dist=nil,math.huge
    local rr=root(char()); if not rr then return nil end
    for _,o in ipairs(Workspace:GetDescendants()) do
        local n=o.Name:lower()
        local floorName=(n=="gundrop" or n=="droppedgun" or n=="droppedpistol")
        if floorName and not o:IsDescendantOf(char() or Instance.new("Folder")) then
            local host=o:IsA("Model") and o or o:FindFirstAncestorOfClass("Model") or o
            local owner=host:IsA("Model") and Players:GetPlayerFromCharacter(host)
            if not owner then
                local part=o:IsA("BasePart") and o or (host:IsA("Model") and (host.PrimaryPart or host:FindFirstChildWhichIsA("BasePart",true)))
                if part then local d=(part.Position-rr.Position).Magnitude; if d<dist then dist=d; best=part end end
            end
        end
    end
    return best
end
local function pickupPart(part)
    if not part then return false end
    local rr=root(char()); if not rr then return false end
    local ok=false
    if type(firetouchinterest)=="function" then pcall(function() firetouchinterest(rr,part,0); firetouchinterest(rr,part,1); ok=true end) end
    local host=part:FindFirstAncestorOfClass("Model") or part
    local pp=host:FindFirstChildWhichIsA("ProximityPrompt",true); if pp and pp.Enabled and type(fireproximityprompt)=="function" then pcall(function() fireproximityprompt(pp); ok=true end) end
    local cd=host:FindFirstChildWhichIsA("ClickDetector",true); if cd and type(fireclickdetector)=="function" then pcall(function() fireclickdetector(cd); ok=true end) end
    return ok
end

local function nearestCoin()
    local rr=root(char()); if not rr then return nil end
    local best,dist=nil,math.huge
    for _,o in ipairs(Workspace:GetDescendants()) do if o.Name=="Coin" and not o:IsDescendantOf(char() or Instance.new("Folder")) then local p=o:IsA("BasePart") and o or (o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true))); if p then local d=(p.Position-rr.Position).Magnitude; if d<dist then dist=d; best=p end end end end
    return best
end
local function findTool(names)
    for _,container in ipairs({char(),LP:FindFirstChildOfClass("Backpack")}) do if container then for _,n in ipairs(names) do local t=container:FindFirstChild(n); if t and t:IsA("Tool") then return t end end end end
end
local function knifeAttack(p)
    if not playerAlive(p) then return false end
    local rr=root(char()); local tr=root(p.Character); if not rr or not tr then return false end
    local knife=findTool({"Knife","knife"}); if not knife then return false end
    pcall(function() hum(char()):EquipTool(knife) end); pcall(function() knife:Activate() end); return true
end

-- Mobile movement; does not touch normal WalkSpeed unless the feature is enabled.
local saved={walk=nil,jump=nil,auto=nil}
local function remember() local h=hum(char()); if h then if saved.walk==nil then saved.walk=h.WalkSpeed end; if saved.jump==nil then saved.jump=h.JumpPower end; if saved.auto==nil then saved.auto=h.AutoRotate end end end
local function restore() local h=hum(char()); if h then if saved.walk then h.WalkSpeed=saved.walk end; if saved.jump then h.JumpPower=saved.jump end; if saved.auto~=nil then h.AutoRotate=saved.auto end; h.PlatformStand=false end end
local flyRise=0
local function doFly(dt)
    local h=hum(char()); local r=root(char()); if not h or not r or h.Health<=0 then return end
    local move=h.MoveDirection; local horizontal=move.Magnitude>.02 and move.Unit*S.FlySpeed or Vector3.zero
    if h.Jump or h:GetState()==Enum.HumanoidStateType.Jumping then flyRise=math.max(flyRise,os.clock()+.22) end
    local y=os.clock()<flyRise and S.FlyUpSpeed or 0
    h.AutoRotate=false; r.AssemblyLinearVelocity=r.AssemblyLinearVelocity:Lerp(Vector3.new(horizontal.X,y,horizontal.Z),math.clamp(dt*12,0,1))
end
local function setNoClip(on)
    local c=char(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then if on then if p:GetAttribute("HirukuOldCollide")==nil then p:SetAttribute("HirukuOldCollide",p.CanCollide) end; p.CanCollide=false else local old=p:GetAttribute("HirukuOldCollide"); if old~=nil then p.CanCollide=old; p:SetAttribute("HirukuOldCollide",nil) end end end end
end

local lastCoin,lastGun,lastAttack,scan=0,0,0,0
local cachedCoin,cachedGun=nil,nil
local function canTarget(p) return p and p~=LP and playerAlive(p) end
local function selectedTargets()
    local t={}
    if S.KillSelected and canTarget(S.SelectedPlayer) then table.insert(t,S.SelectedPlayer) end
    if S.KillAll then for _,p in ipairs(Players:GetPlayers()) do if canTarget(p) then table.insert(t,p) end end end
    return t
end

-- Render loop: one clean loop, dt always comes from RenderStepped.
local fps=60, frames=0, fpsTime=0, rainbowT=0
conn(RunService.RenderStepped:Connect(function(dt)
    frames+=1; fpsTime+=dt; rainbowT=(rainbowT+dt*.25)%1
    if fpsTime>=1 then fps=frames/fpsTime; frames=0; fpsTime=0 end

    fov.Visible=S.FOV; local d=S.AimFOV*2; fov.Size=UDim2.fromOffset(d,d); fov.Position=UDim2.new(.5,-S.AimFOV,.5,-S.AimFOV); local fc=fov:FindFirstChildOfClass("UICorner"); if fc then fc.CornerRadius=UDim.new(0,S.AimFOV) end
    cross.Visible=S.Crosshair
    watermark.Visible=S.Watermark
    local ping=0; pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    wm.Text=string.format("Hiruku  •  %d FPS  •  %s  •  %d ms",math.floor(fps+.5),LP.Name,ping)

    if S.AimBot or S.SilentAim then
        local center=Camera.ViewportSize/2; local best,bestD=nil,S.AimFOV
        for _,p in ipairs(Players:GetPlayers()) do if canTarget(p) then local head=p.Character:FindFirstChild("Head") or root(p.Character); if head then local v,on=Camera:WorldToViewportPoint(head.Position); if on then local dd=(Vector2.new(v.X,v.Y)-center).Magnitude; if dd<bestD then bestD=dd; best=head end end end end end
        if best and S.AimBot then Camera.CFrame=Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position,best.Position),math.clamp(S.AimSmooth*4,0,1)) end
        -- SilentAim keeps a cached target for a local/private weapon hook; it does not alter arbitrary remote calls.
    end

    if S.Fly then doFly(dt) end
    if S.BunnyHop and not S.Fly and not S.CoinFarm then
        local h=hum(char()); if h and h.Health>0 then remember(); local moving=h.MoveDirection.Magnitude>.08
            if moving then S.BunnyCurrent=math.min(S.BunnyMax,S.BunnyCurrent+S.BunnyAccel*dt); h.WalkSpeed=S.BunnyCurrent; if h.FloorMaterial~=Enum.Material.Air then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            else S.BunnyCurrent=saved.walk or 16; h.WalkSpeed=saved.walk or 16 end
        end
    elseif not S.BunnyHop and not S.Fly and saved.walk then local h=hum(char()); if h then h.WalkSpeed=saved.walk end; S.BunnyCurrent=saved.walk end

    setNoClip(S.NoClip)
    if S.Spin then local r=root(char()); if r then r.CFrame=r.CFrame*CFrame.Angles(0,math.rad(S.SpinSpeed)*dt,0) end end

    if S.Fullbright then
        Lighting.Brightness=3; Lighting.Ambient=Color3.fromRGB(190,190,190); Lighting.OutdoorAmbient=Color3.fromRGB(190,190,190)
    elseif not S.SkyEnabled then
        Lighting.Brightness=savedLighting.Brightness; Lighting.Ambient=savedLighting.Ambient; Lighting.OutdoorAmbient=savedLighting.OutdoorAmbient
    end
    if S.SkyEnabled then
        Lighting.Ambient=S.SkyColor; Lighting.OutdoorAmbient=S.SkyColor
        local at=Lighting:FindFirstChildOfClass("Atmosphere"); if at then at.Color=S.SkyColor; at.Decay=S.SkyColor end
    end
    local at=Lighting:FindFirstChildOfClass("Atmosphere")
    if at then if S.NoFog then at.Density=.05 elseif savedAtmosphereDensity[at] then at.Density=savedAtmosphereDensity[at] end end

    if S.TargetAura and canTarget(S.TargetAuraPlayer) then local rr=root(char()); local tr=root(S.TargetAuraPlayer.Character); if rr and tr then local old=rr.CFrame; rr.CFrame=tr.CFrame; task.defer(function() if rr.Parent and S.TargetAura then rr.CFrame=old end end) end end

    scan+=dt
    if scan>=.12 then scan=0; if S.CoinFarm then cachedCoin=nearestCoin() else cachedCoin=nil end; if S.AutoPickupGun then cachedGun=droppedGunPart() else cachedGun=nil end end
    if S.CoinFarm and cachedCoin and os.clock()-lastCoin>=S.CoinDelay then
        lastCoin=os.clock(); local r=root(char()); if r and cachedCoin.Parent then local old=r.CFrame; r.CFrame=CFrame.new(cachedCoin.Position+Vector3.new(0,1.5,0)); pickupPart(cachedCoin); task.delay(.035,function() if r.Parent and S.CoinFarm and not S.Fly then r.CFrame=old end end) end
    end
    if S.AutoPickupGun and cachedGun and os.clock()-lastGun>=S.AutoPickupDelay then
        lastGun=os.clock(); local r=root(char()); if r and cachedGun.Parent then local old=r.CFrame; r.CFrame=CFrame.new(cachedGun.Position+Vector3.new(0,1,0)); pickupPart(cachedGun); task.delay(.045,function() if r.Parent and S.AutoPickupGun then r.CFrame=old end end) end
    end

    if S.KillAura and os.clock()-lastAttack>=S.AttackCooldown then
        local rr=root(char()); local knife=findTool({"Knife","knife"}); if rr and knife then for _,p in ipairs(Players:GetPlayers()) do if canTarget(p) then local tr=root(p.Character); if tr and (tr.Position-rr.Position).Magnitude<=S.AttackRange then knifeAttack(p); lastAttack=os.clock(); break end end end end
    end
    if (S.KillSelected or S.KillAll) and os.clock()-lastAttack>=S.AttackCooldown then
        local rr=root(char()); if rr then local old=rr.CFrame; local list=selectedTargets(); for _,p in ipairs(list) do local tr=root(p.Character); if tr then rr.CFrame=tr.CFrame; knifeAttack(p) end end; rr.CFrame=old; lastAttack=os.clock() end
    end

    if S.Tracers then
        for p,data in pairs(TRACERS) do if not canTarget(p) then pcall(function() data.beam:Destroy() end); pcall(function() data.a0:Destroy() end); pcall(function() data.a1:Destroy() end); TRACERS[p]=nil end end
    end
    if S.DistanceESP then for _,p in ipairs(Players:GetPlayers()) do if canTarget(p) then local rr=root(char()); local tr=root(p.Character); if rr and tr then local head=p.Character:FindFirstChild("Head"); if head then local bb=DISTANCES[p]; if not bb then bb=Instance.new("BillboardGui"); bb.Size=UDim2.fromOffset(100,20); bb.AlwaysOnTop=true; bb.Adornee=head; bb.Parent=gui; DISTANCES[p]=bb; txt(bb,"",UDim2.fromScale(1,1),UDim2.fromScale(0,0),9,C().sub,1120,Enum.TextXAlignment.Center) end; local t=bb:FindFirstChildWhichIsA("TextLabel",true); if t then t.Text=string.format("%dm",math.floor((rr.Position-tr.Position).Magnitude)) end end end end end else for p,b in pairs(DISTANCES) do pcall(function() b:Destroy() end); DISTANCES[p]=nil end end
end))

-- Visual refresh loop and role changes.
local visClock=0
conn(RunService.Heartbeat:Connect(function(dt)
    visClock+=dt
    if visClock>=.25 then visClock=0; if S.Chams or S.RoleLabels then refreshESP() else for p in pairs(CHAMS) do clearPlayerESP(p) end end
        if S.EspGun then
            local gp=droppedGunPart(); if gp then local host=gp:FindFirstAncestorOfClass("Model") or gp; if not GUNESP[host] then local h=Instance.new("Highlight"); h.Name="HirukuGunESP"; h.Adornee=host; h.FillColor=Color3.fromRGB(255,145,25); h.OutlineColor=Color3.fromRGB(255,205,90); h.FillTransparency=.30; h.OutlineTransparency=.04; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=gui; GUNESP[host]=h end end
        else for o,h in pairs(GUNESP) do pcall(function() h:Destroy() end); GUNESP[o]=nil end end
        -- Lightweight mobile-safe box/tracer visuals.
        if S.BoxESP or S.Tracers then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LP and canTarget(p) then
                    local model=p.Character; local rr=root(char()); local tr=root(model)
                    if S.BoxESP and not BOXES[p] then
                        local sb=Instance.new("SelectionBox"); sb.Name="HirukuBoxESP"; sb.Adornee=model; sb.LineThickness=.035; sb.SurfaceTransparency=1; sb.Color3=ROLECOLOR[role(p)] or ROLECOLOR.Unknown; sb.Parent=gui; BOXES[p]=sb
                    elseif BOXES[p] then BOXES[p].Color3=ROLECOLOR[role(p)] or ROLECOLOR.Unknown end
                    if S.Tracers and rr and tr and not TRACERS[p] then
                        local a0=Instance.new("Attachment"); a0.Name="HirukuTracerA"; a0.Position=Vector3.zero; a0.Parent=Workspace.Terrain
                        local a1=Instance.new("Attachment"); a1.Name="HirukuTracerB"; a1.Parent=tr
                        local beam=Instance.new("Beam"); beam.Name="HirukuTracer"; beam.Attachment0=a0; beam.Attachment1=a1; beam.Width0=.025; beam.Width1=.025; beam.FaceCamera=true; beam.Color=ColorSequence.new(ROLECOLOR[role(p)] or ROLECOLOR.Unknown); beam.Parent=gui; TRACERS[p]={beam=beam,a0=a0,a1=a1}
                    end
                end
            end
        else
            for p,b in pairs(BOXES) do pcall(function() b:Destroy() end); BOXES[p]=nil end
            for p,data in pairs(TRACERS) do pcall(function() data.beam:Destroy() end); pcall(function() data.a0:Destroy() end); pcall(function() data.a1:Destroy() end); TRACERS[p]=nil end
        end
        if S.RainbowChams then for p,h in pairs(CHAMS) do if h then local c=Color3.fromHSV((rainbowT+(p.UserId%20)/20)%1,.75,1); h.FillColor=c; h.OutlineColor=c end end end
    end
end))

-- Search
conn(search:GetPropertyChangedSignal("Text"):Connect(function()
    local q=search.Text:lower():gsub("^%s+",""):gsub("%s+$",""); local pg=pages[S.Page]; if not pg then return end
    for _,o in ipairs(pg:GetChildren()) do if o:IsA("GuiObject") then if q=="" then o.Visible=true else local found=false; for _,d in ipairs(o:GetDescendants()) do if d:IsA("TextLabel") or d:IsA("TextButton") then if d.Text:lower():find(q,1,true) then found=true break end end end; o.Visible=found end end end
end))

local function applyStyle()
    local font=FONTS[S.Font] or Enum.Font.GothamBold
    for _,o in ipairs(gui:GetDescendants()) do
        if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then o.Font=font; o.TextColor3=C().text end
        if o:IsA("Frame") and (o==main or o:IsDescendantOf(main)) then
            if o==main then o.BackgroundColor3=C().panel else if o.BackgroundTransparency<.5 then o.BackgroundColor3=C().card end end
        end
    end
    main.BackgroundTransparency=math.clamp(1-S.MenuOpacity,.08,.45); fov:FindFirstChildOfClass("UIStroke").Color=C().accent
end
local oldTheme,oldFont=nil,nil
conn(RunService.Heartbeat:Connect(function() if oldTheme~=S.Theme or oldFont~=S.Font then oldTheme,oldFont=S.Theme,S.Font; applyStyle() end end))

-- navigation
local function setPage(n) S.Page=n; search.Text=""; for k,p in pairs(pages) do p.Visible=(k==n); p.CanvasPosition=Vector2.zero end; for k,b in pairs(navBtns) do b.BackgroundColor3=(k==n and C().card2 or C().card); b.TextColor3=(k==n and C().text or C().sub) end end
for n,b in pairs(navBtns) do conn(b.Activated:Connect(function() setPage(n) end)) end
setPage("Combat")

-- Player lifecycle
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then conn(p.CharacterAdded:Connect(function() task.wait(.2); if S.Chams or S.RoleLabels then makeESP(p) end end)); conn(p:GetAttributeChangedSignal("Role"):Connect(function() if S.Chams or S.RoleLabels then makeESP(p) end end)); conn(p:GetAttributeChangedSignal("role"):Connect(function() if S.Chams or S.RoleLabels then makeESP(p) end end)) end end
conn(Players.PlayerAdded:Connect(function(p) if p~=LP then conn(p.CharacterAdded:Connect(function() task.wait(.2); if S.Chams or S.RoleLabels then makeESP(p) end end)); conn(p:GetAttributeChangedSignal("Role"):Connect(function() if S.Chams or S.RoleLabels then makeESP(p) end end)) end end))
conn(LP.CharacterAdded:Connect(function() saved.walk=nil; saved.jump=nil; saved.auto=nil; task.wait(.3); if S.NoClip then setNoClip(true) end end))

function S.Cleanup()
    S.Open=false; S.Fly=false; S.BunnyHop=false; S.NoClip=false; S.Spin=false; S.CoinFarm=false; S.AutoPickupGun=false
    disconnectAll(); restore()
    for p in pairs(CHAMS) do pcall(function() CHAMS[p]:Destroy() end) end; for p in pairs(LABELS) do pcall(function() LABELS[p]:Destroy() end) end; for p,data in pairs(TRACERS) do pcall(function() data.beam:Destroy() end); pcall(function() data.a0:Destroy() end); pcall(function() data.a1:Destroy() end) end; for p in pairs(BOXES) do pcall(function() BOXES[p]:Destroy() end) end; for p in pairs(DISTANCES) do pcall(function() DISTANCES[p]:Destroy() end) end; for o,h in pairs(GUNESP) do pcall(function() h:Destroy() end) end
    table.clear(CHAMS); table.clear(LABELS); table.clear(TRACERS); table.clear(BOXES); table.clear(DISTANCES); table.clear(GUNESP)
    Lighting.Brightness=savedLighting.Brightness; Lighting.Ambient=savedLighting.Ambient; Lighting.OutdoorAmbient=savedLighting.OutdoorAmbient
    for at,d in pairs(savedAtmosphereDensity) do if at and at.Parent then at.Density=d end end
    destroyAll()
end
_G[KEY]=S

centerMenu(); applyStyle(); notify("Hiruku successfully loaded")
tw(pill,.35,{Size=UDim2.fromOffset(148,46)},Enum.EasingStyle.Quint)
