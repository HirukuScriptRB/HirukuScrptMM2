local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local Config = {
    AimBot = {Enabled = false, Range = 100},
    Silent = {Enabled = false, Range = 100},
    Trigger = {Enabled = false, Range = 50, Delay = 50},
    WallShot = {Enabled = false},
    Chams = {Enabled = false, Transparency = 0.3, FillColor = Color3.fromRGB(255,255,255), OutlineColor = Color3.fromRGB(0,0,0)},
    ESP = {Enabled = false, Box = true, Name = true, Health = true, Distance = true},
    BunnyHop = {Enabled = false, MaxSpeed = 100},
    Speed = {Enabled = false, Speed = 50},
    Fly = {Enabled = false, Speed = 50, HeightOffset = 10},
    Spin = {Enabled = false, Speed = 360},
    Collisions = {Enabled = false},
    Watermark = {Enabled = true},
    FOV = {Radius = 70},
    FOVCircle = {Enabled = true},
    SpeedIndicator = {Enabled = true},
    AutoFarm = {Enabled = false, Speed = 35},
    WhoIs = {Enabled = false},
    SkyColor = {Enabled = false, Color = Color3.fromRGB(135,206,235)},
    SexAura = {Enabled = false},
    HighJump = {Enabled = false},
    AutoPickupGun = {Enabled = false},
    KillAll = {Enabled = false},
    KillSelected = {Enabled = false, Target = ""},
    TPRole = {Enabled = false, Role = "Sheriff"},
    AutoShot = {Enabled = false}
}

local MenuOpen = false
local ESPActive = false
local ChamsActive = false
local FlyActive = false
local SpeedActive = false
local SpinActive = false
local CollisionsActive = false
local AutoFarmActive = false
local WhoIsActive = false
local SexAuraActive = false
local HighJumpActive = false
local AutoPickupGunActive = false
local KillAllActive = false
local KillSelectedActive = false
local TPRoleActive = false
local AutoShotActive = false
local CurrentFPS = 0
local LastFrameTime = tick()
local FOVCircle = nil
local ESPCache = {}
local ChamsObjects = {}
local BhopSpeed = 16
local LastBhopTime = 0
local triggerDelay = 0
local SkyChanged = false
local AutoFarmTarget = nil
local AutoFarmCoins = {}
local AutoFarmLines = {}
local CollectedCoins = {}

local ConfigPath = "HirukuConfig.json"
local function SaveConfig()
    if writefile then
        writefile(ConfigPath, HttpService:JSONEncode(Config))
    end
end
local function LoadConfig()
    if readfile and isfile(ConfigPath) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigPath)) end)
        if success and type(data) == "table" then
            for key, val in pairs(data) do
                if type(Config[key]) == "table" and type(val) == "table" then
                    for k, v in pairs(val) do Config[key][k] = v end
                else
                    Config[key] = val
                end
            end
        end
    end
end
LoadConfig()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HirukuInternal"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 99999
ScreenGui.IgnoreGuiInset = true

local InjectScreen = Instance.new("Frame")
InjectScreen.Size = UDim2.new(1,0,1,0)
InjectScreen.BackgroundColor3 = Color3.fromRGB(0,0,0)
InjectScreen.BackgroundTransparency = 0.5
InjectScreen.ZIndex = 999
InjectScreen.Parent = ScreenGui

local InjectTitle = Instance.new("TextLabel")
InjectTitle.Size = UDim2.new(0,400,0,50)
InjectTitle.Position = UDim2.new(0.5,-200,0.4,-25)
InjectTitle.BackgroundTransparency = 1
InjectTitle.Text = "Hiruku Injected..."
InjectTitle.TextColor3 = Color3.fromRGB(255,255,255)
InjectTitle.Font = Enum.Font.Code
InjectTitle.TextSize = 30
InjectTitle.Parent = InjectScreen

local InjectBarBg = Instance.new("Frame")
InjectBarBg.Size = UDim2.new(0,300,0,10)
InjectBarBg.Position = UDim2.new(0.5,-150,0.5,20)
InjectBarBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
InjectBarBg.BorderSizePixel = 0
InjectBarBg.Parent = InjectScreen

local InjectBarFill = Instance.new("Frame")
InjectBarFill.Size = UDim2.new(0,0,1,0)
InjectBarFill.BackgroundColor3 = Color3.fromRGB(255,255,255)
InjectBarFill.BorderSizePixel = 0
InjectBarFill.Parent = InjectBarBg

local InjectTween = TweenService:Create(InjectBarFill, TweenInfo.new(2), {Size = UDim2.new(1,0,1,0)})
InjectTween:Play()
InjectTween.Completed:Connect(function()
    InjectScreen:Destroy()
    local Notify = Instance.new("Frame")
    Notify.Size = UDim2.new(0,300,0,60)
    Notify.Position = UDim2.new(-0.5,0,0.85,0)
    Notify.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Notify.BorderSizePixel = 0
    Notify.Parent = ScreenGui
    local NotifyCorner = Instance.new("UICorner")
    NotifyCorner.CornerRadius = UDim.new(0,12)
    NotifyCorner.Parent = Notify
    local NotifyText = Instance.new("TextLabel")
    NotifyText.Size = UDim2.new(1,0,1,0)
    NotifyText.BackgroundTransparency = 1
    NotifyText.Text = "Hiruku Script Loaded Successfully"
    NotifyText.TextColor3 = Color3.fromRGB(255,255,255)
    NotifyText.Font = Enum.Font.Code
    NotifyText.TextSize = 14
    NotifyText.Parent = Notify
    TweenService:Create(Notify, TweenInfo.new(0.5), {Position = UDim2.new(0.02,0,0.85,0)}):Play()
    task.wait(3)
    TweenService:Create(Notify, TweenInfo.new(0.5), {Position = UDim2.new(-0.5,0,0.85,0)}):Play()
    task.delay(0.5, function() Notify:Destroy() end)
end)

local MenuButton = Instance.new("TextButton")
MenuButton.Size = UDim2.new(0,150,0,35)
MenuButton.Position = UDim2.new(0.5,-75,0.08,0)
MenuButton.BackgroundColor3 = Color3.fromRGB(0,0,0)
MenuButton.BackgroundTransparency = 0.4
MenuButton.Text = "Hiruku"
MenuButton.TextColor3 = Color3.fromRGB(255,255,255)
MenuButton.Font = Enum.Font.Code
MenuButton.TextSize = 18
MenuButton.BorderSizePixel = 1
MenuButton.BorderColor3 = Color3.fromRGB(255,255,255)
MenuButton.AutoButtonColor = false
MenuButton.ZIndex = 500
MenuButton.Parent = ScreenGui
local MenuButtonCorner = Instance.new("UICorner")
MenuButtonCorner.CornerRadius = UDim.new(0,15)
MenuButtonCorner.Parent = MenuButton

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0,700,0,450)
MainFrame.Position = UDim2.new(0.5,-350,0.5,-225)
MainFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.ZIndex = 400
MainFrame.Parent = ScreenGui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0,12)
mainCorner.Parent = MainFrame

local function ShowMenu()
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0,0,0,0)
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0,700,0,450)}):Play()
    TweenService:Create(MainFrame, TweenInfo.new(0.4), {Position = UDim2.new(0.5,-350,0.5,-225)}):Play()
    for _, child in ipairs(MainFrame:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
            child.AnchorPoint = Vector2.new(0.5,0.5)
        end
    end
    TweenService:Create(MainFrame, TweenInfo.new(0.4), {Position = UDim2.new(0.5,-350,0.5,-225)}):Play()
end

local function HideMenu()
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0,0,0,0)}):Play()
    TweenService:Create(MainFrame, TweenInfo.new(0.4), {Position = UDim2.new(0.5,-350,0.5,-225)}):Play()
    task.delay(0.4, function() MainFrame.Visible = false end)
end

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,50)
TitleBar.BackgroundColor3 = Color3.fromRGB(15,15,15)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0,12)
titleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -60, 0, 25)
TitleText.Position = UDim2.new(0, 15, 0, 2)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Hiruku"
TitleText.TextColor3 = Color3.fromRGB(255,255,255)
TitleText.Font = Enum.Font.Code
TitleText.TextSize = 20
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -60, 0, 15)
Subtitle.Position = UDim2.new(0, 15, 0, 28)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "MM2 - v 1.0"
Subtitle.TextColor3 = Color3.fromRGB(200,200,200)
Subtitle.Font = Enum.Font.Code
Subtitle.TextSize = 10
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TitleBar

local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(0,200,0,30)
SearchBar.Position = UDim2.new(1, -220, 0, 10)
SearchBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
SearchBar.Text = ""
SearchBar.PlaceholderText = "Search..."
SearchBar.TextColor3 = Color3.fromRGB(255,255,255)
SearchBar.Font = Enum.Font.Code
SearchBar.TextSize = 12
SearchBar.Parent = TitleBar
local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0,8)
SearchCorner.Parent = SearchBar

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1,0,0,40)
Tabs.Position = UDim2.new(0,0,0,50)
Tabs.BackgroundColor3 = Color3.fromRGB(5,5,5)
Tabs.BorderSizePixel = 0
Tabs.Parent = MainFrame

local TabsLayout = Instance.new("UIListLayout")
TabsLayout.FillDirection = Enum.FillDirection.Horizontal
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabsLayout.Padding = UDim.new(0,10)
TabsLayout.Parent = Tabs

local Sections = {"Combat", "Visuals", "Movement", "Misc"}
local TabButtons = {}
local AllTabs = {}

for i, name in ipairs(Sections) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,120,0,30)
    btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = Tabs
    TabButtons[name] = btn
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0,5)
    tabCorner.Parent = btn
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,0,1,-90)
    content.Position = UDim2.new(0,0,0,90)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = MainFrame
    AllTabs[name] = content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0,6)
    contentLayout.Parent = content
end

local function CreateSettingPanel(parent, title)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, -20, 0, 30)
    panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
    panel.BorderSizePixel = 0
    panel.Parent = parent
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0,8)
    panelCorner.Parent = panel
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1,0,0,25)
    header.BackgroundColor3 = Color3.fromRGB(30,30,30)
    header.Text = title
    header.TextColor3 = Color3.fromRGB(255,255,255)
    header.Font = Enum.Font.Code
    header.TextSize = 13
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = panel
    return panel
end

local function CreateToggle(parent, label, path)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -20, 0, 30)
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0.6,0,1,0)
    text.Position = UDim2.new(0,0,0,0)
    text.Text = label
    text.TextColor3 = Color3.fromRGB(220,220,220)
    text.Font = Enum.Font.Code
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = holder
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0,30,0,16)
    toggle.Position = UDim2.new(0.8,0,0.2,0)
    toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
    toggle.Parent = holder
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1,0)
    toggleCorner.Parent = toggle
    local check = Instance.new("Frame")
    check.Size = UDim2.new(0,12,0,12)
    check.Position = UDim2.new(0,2,0,2)
    check.BackgroundColor3 = Color3.fromRGB(80,80,80)
    check.Parent = toggle
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(1,0)
    checkCorner.Parent = check
    local function UpdateToggle()
        local current = Config
        for _, v in ipairs(path) do current = current[v] end
        if current then
            check.BackgroundColor3 = Color3.fromRGB(255,255,255)
            TweenService:Create(check, TweenInfo.new(0.15), {Position = UDim2.new(0,16,0,2)}):Play()
        else
            check.BackgroundColor3 = Color3.fromRGB(80,80,80)
            TweenService:Create(check, TweenInfo.new(0.15), {Position = UDim2.new(0,2,0,2)}):Play()
        end
    end
    UpdateToggle()
    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local current = Config
            for i = 1, #path - 1 do current = current[path[i]] end
            current[path[#path]] = not current[path[#path]]
            UpdateToggle()
            SaveConfig()
            if path[1] == "ESP" and path[2] == "Enabled" then if Config.ESP.Enabled then EnableESP() else DisableESP() end end
            if path[1] == "Chams" and path[2] == "Enabled" then if Config.Chams.Enabled then EnableChams() else DisableChams() end end
            if path[1] == "Fly" and path[2] == "Enabled" then if Config.Fly.Enabled then EnableFly() else DisableFly() end end
            if path[1] == "Speed" and path[2] == "Enabled" then if Config.Speed.Enabled then EnableSpeed() else DisableSpeed() end end
            if path[1] == "Spin" and path[2] == "Enabled" then if Config.Spin.Enabled then EnableSpin() else DisableSpin() end end
            if path[1] == "Collisions" and path[2] == "Enabled" then if Config.Collisions.Enabled then EnableCollisions() else DisableCollisions() end end
            if path[1] == "AutoFarm" and path[2] == "Enabled" then if Config.AutoFarm.Enabled then EnableAutoFarm() else DisableAutoFarm() end end
            if path[1] == "WhoIs" and path[2] == "Enabled" then if Config.WhoIs.Enabled then EnableWhoIs() else DisableWhoIs() end end
            if path[1] == "SkyColor" and path[2] == "Enabled" then if Config.SkyColor.Enabled then ApplySkyColor() else ResetSkyColor() end end
            if path[1] == "SexAura" and path[2] == "Enabled" then if Config.SexAura.Enabled then EnableSexAura() else DisableSexAura() end end
            if path[1] == "HighJump" and path[2] == "Enabled" then if Config.HighJump.Enabled then EnableHighJump() else DisableHighJump() end end
            if path[1] == "AutoPickupGun" and path[2] == "Enabled" then if Config.AutoPickupGun.Enabled then EnableAutoPickupGun() else DisableAutoPickupGun() end end
            if path[1] == "KillAll" and path[2] == "Enabled" then if Config.KillAll.Enabled then EnableKillAll() else DisableKillAll() end end
            if path[1] == "KillSelected" and path[2] == "Enabled" then if Config.KillSelected.Enabled then EnableKillSelected() else DisableKillSelected() end end
            if path[1] == "TPRole" and path[2] == "Enabled" then if Config.TPRole.Enabled then EnableTPRole() else DisableTPRole() end end
            if path[1] == "AutoShot" and path[2] == "Enabled" then if Config.AutoShot.Enabled then EnableAutoShot() else DisableAutoShot() end end
        end
    end)
end

local function CreateSlider(parent, label, path, min, max, decimal)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -20, 0, 45)
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0.5,0,0,20)
    text.Position = UDim2.new(0,0,0,0)
    text.Text = label
    text.TextColor3 = Color3.fromRGB(220,220,220)
    text.Font = Enum.Font.Code
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = holder
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.2,0,0,20)
    val.Position = UDim2.new(0.5,0,0,0)
    val.BackgroundTransparency = 1
    val.Text = "0"
    val.TextColor3 = Color3.fromRGB(255,255,255)
    val.Font = Enum.Font.Code
    val.TextSize = 12
    val.Parent = holder
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.9,0,0.2,0)
    slider.Position = UDim2.new(0,0,0.5,0)
    slider.BackgroundColor3 = Color3.fromRGB(40,40,40)
    slider.BorderSizePixel = 0
    slider.Parent = holder
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1,0)
    sliderCorner.Parent = slider
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(255,255,255)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1,0)
    fillCorner.Parent = fill
    local function UpdateSlider()
        local current = Config
        for _, v in ipairs(path) do current = current[v] end
        local percent = (current - min) / (max - min)
        fill.Size = UDim2.new(math.clamp(percent,0,1),0,1,0)
        if decimal then val.Text = string.format("%.2f",current) else val.Text = tostring(math.round(current)) end
    end
    UpdateSlider()
    local dragging = false
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local pos = input.Position.X - slider.AbsolutePosition.X
            local percent = math.clamp(pos / slider.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * percent
            if decimal then value = math.round(value / 0.01) * 0.01 else value = math.round(value) end
            local current = Config
            for i = 1, #path - 1 do current = current[path[i]] end
            current[path[#path]] = value
            UpdateSlider()
            SaveConfig()
        end
    end)
    slider.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position.X - slider.AbsolutePosition.X
            local percent = math.clamp(pos / slider.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * percent
            if decimal then value = math.round(value / 0.01) * 0.01 else value = math.round(value) end
            local current = Config
            for i = 1, #path - 1 do current = current[path[i]] end
            current[path[#path]] = value
            UpdateSlider()
            SaveConfig()
        end
    end)
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function CreateColorButton(parent, label, path, colorList)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -20, 0, 40)
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0.8,0,0,20)
    text.Position = UDim2.new(0,0,0,0)
    text.Text = label
    text.TextColor3 = Color3.fromRGB(220,220,220)
    text.Font = Enum.Font.Code
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = holder
    local btnHolder = Instance.new("Frame")
    btnHolder.Size = UDim2.new(1,0,0,20)
    btnHolder.Position = UDim2.new(0,0,0,20)
    btnHolder.BackgroundTransparency = 1
    btnHolder.Parent = holder
    local colorBtns = {}
    for idx, color in ipairs(colorList) do
        local btn = Instance.new("Frame")
        btn.Size = UDim2.new(0,18,0,18)
        btn.Position = UDim2.new(0,(idx-1)*20,0,0)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(60,60,60)
        btn.Parent = btnHolder
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0,3)
        btnCorner.Parent = btn
        table.insert(colorBtns, btn)
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local current = Config
                for i = 1, #path - 1 do current = current[path[i]] end
                current[path[#path]] = color
                for _, b in ipairs(colorBtns) do
                    if b.BackgroundColor3 == color then
                        b.BorderColor3 = Color3.fromRGB(255,255,255)
                        b.BorderSizePixel = 2
                    else
                        b.BorderColor3 = Color3.fromRGB(60,60,60)
                        b.BorderSizePixel = 1
                    end
                end
                SaveConfig()
                if path[1] == "Chams" and (path[2] == "FillColor" or path[2] == "OutlineColor") then UpdateChamsColors() end
                if path[1] == "SkyColor" and path[2] == "Color" then ApplySkyColor() end
            end
        end)
    end
    local current = Config
    for _, v in ipairs(path) do current = current[v] end
    for _, b in ipairs(colorBtns) do
        if b.BackgroundColor3 == current then
            b.BorderColor3 = Color3.fromRGB(255,255,255)
            b.BorderSizePixel = 2
        end
    end
end

local CombatTab = AllTabs["Combat"]
local aimPanel = CreateSettingPanel(CombatTab, "AimBot")
CreateToggle(aimPanel, "Enable", {"AimBot","Enabled"})
CreateSlider(aimPanel, "Range", {"AimBot","Range"}, 1, 100, false)

local silentPanel = CreateSettingPanel(CombatTab, "Silent Aim")
CreateToggle(silentPanel, "Enable", {"Silent","Enabled"})
CreateSlider(silentPanel, "Range", {"Silent","Range"}, 1, 100, false)

local triggerPanel = CreateSettingPanel(CombatTab, "Trigger")
CreateToggle(triggerPanel, "Enable", {"Trigger","Enabled"})
CreateSlider(triggerPanel, "Range", {"Trigger","Range"}, 1, 50, false)
CreateSlider(triggerPanel, "Delay", {"Trigger","Delay"}, 10, 500, false)

local VisualsTab = AllTabs["Visuals"]
local fovPanel = CreateSettingPanel(VisualsTab, "FOV Circle")
CreateToggle(fovPanel, "Show", {"FOVCircle","Enabled"})
CreateSlider(fovPanel, "Radius", {"FOV","Radius"}, 1, 180, false)

local espPanel = CreateSettingPanel(VisualsTab, "ESP")
CreateToggle(espPanel, "Enable", {"ESP","Enabled"})
CreateToggle(espPanel, "Box", {"ESP","Box"})
CreateToggle(espPanel, "Name", {"ESP","Name"})
CreateToggle(espPanel, "Health", {"ESP","Health"})
CreateToggle(espPanel, "Distance", {"ESP","Distance"})

local chamsPanel = CreateSettingPanel(VisualsTab, "Chams")
CreateToggle(chamsPanel, "Enable", {"Chams","Enabled"})
CreateSlider(chamsPanel, "Transparency", {"Chams","Transparency"}, 0, 1, true)
CreateColorButton(chamsPanel, "Fill", {"Chams","FillColor"}, {Color3.fromRGB(255,255,255), Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255)})
CreateColorButton(chamsPanel, "Outline", {"Chams","OutlineColor"}, {Color3.fromRGB(0,0,0), Color3.fromRGB(255,255,255), Color3.fromRGB(255,0,0), Color3.fromRGB(0,0,255)})

local MovementTab = AllTabs["Movement"]
local speedPanel = CreateSettingPanel(MovementTab, "Speed")
CreateToggle(speedPanel, "Enable", {"Speed","Enabled"})
CreateSlider(speedPanel, "Speed", {"Speed","Speed"}, 10, 200, false)

local flyPanel = CreateSettingPanel(MovementTab, "Fly")
CreateToggle(flyPanel, "Enable", {"Fly","Enabled"})
CreateSlider(flyPanel, "Speed", {"Fly","Speed"}, 10, 200, false)
CreateSlider(flyPanel, "Height", {"Fly","HeightOffset"}, 1, 50, false)

local bhopPanel = CreateSettingPanel(MovementTab, "Bunny Hop")
CreateToggle(bhopPanel, "Enable", {"BunnyHop","Enabled"})
CreateSlider(bhopPanel, "Max Speed", {"BunnyHop","MaxSpeed"}, 16, 200, false)

local MiscTab = AllTabs["Misc"]
local wallShotPanel = CreateSettingPanel(MiscTab, "Wall Shot")
CreateToggle(wallShotPanel, "Enable", {"WallShot","Enabled"})

local spinPanel = CreateSettingPanel(MiscTab, "Spin")
CreateToggle(spinPanel, "Enable", {"Spin","Enabled"})
CreateSlider(spinPanel, "Speed", {"Spin","Speed"}, 60, 720, false)

local collisionsPanel = CreateSettingPanel(MiscTab, "Collisions")
CreateToggle(collisionsPanel, "Enable", {"Collisions","Enabled"})

local watermarkPanel = CreateSettingPanel(MiscTab, "Watermark")
CreateToggle(watermarkPanel, "Enable", {"Watermark","Enabled"})

local speedIndPanel = CreateSettingPanel(MiscTab, "Speed Indicator")
CreateToggle(speedIndPanel, "Enable", {"SpeedIndicator","Enabled"})

local autoFarmPanel = CreateSettingPanel(MiscTab, "Auto Farm")
CreateToggle(autoFarmPanel, "Enable", {"AutoFarm","Enabled"})
CreateSlider(autoFarmPanel, "Speed", {"AutoFarm","Speed"}, 20, 60, false)

local whoIsPanel = CreateSettingPanel(MiscTab, "Who Is")
CreateToggle(whoIsPanel, "Enable", {"WhoIs","Enabled"})

local skyPanel = CreateSettingPanel(MiscTab, "Sky Color")
CreateToggle(skyPanel, "Enable", {"SkyColor","Enabled"})
CreateColorButton(skyPanel, "Color", {"SkyColor","Color"}, {Color3.fromRGB(135,206,235), Color3.fromRGB(0,0,0), Color3.fromRGB(255,255,255), Color3.fromRGB(255,0,0)})

local sexAuraPanel = CreateSettingPanel(MiscTab, "Sex Aura")
CreateToggle(sexAuraPanel, "Enable", {"SexAura","Enabled"})

local highJumpPanel = CreateSettingPanel(MiscTab, "High Jump")
CreateToggle(highJumpPanel, "Enable", {"HighJump","Enabled"})

local autoPickupPanel = CreateSettingPanel(MiscTab, "Auto Pickup Gun")
CreateToggle(autoPickupPanel, "Enable", {"AutoPickupGun","Enabled"})

local killAllPanel = CreateSettingPanel(MiscTab, "Kill All")
CreateToggle(killAllPanel, "Enable", {"KillAll","Enabled"})

local killSelectedPanel = CreateSettingPanel(MiscTab, "Kill Selected")
CreateToggle(killSelectedPanel, "Enable", {"KillSelected","Enabled"})

local tpRolePanel = CreateSettingPanel(MiscTab, "TP Role")
CreateToggle(tpRolePanel, "Enable", {"TPRole","Enabled"})

local autoShotPanel = CreateSettingPanel(MiscTab, "Auto Shot")
CreateToggle(autoShotPanel, "Enable", {"AutoShot","Enabled"})

local function SwitchTab(name)
    for _, tab in pairs(AllTabs) do
        tab.Visible = false
    end
    AllTabs[name].Visible = true
    for _, btn in pairs(TabButtons) do
        btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
        btn.TextColor3 = Color3.fromRGB(150,150,150)
    end
    TabButtons[name].BackgroundColor3 = Color3.fromRGB(35,35,35)
    TabButtons[name].TextColor3 = Color3.fromRGB(255,255,255)
    task.wait(0.1)
    local content = AllTabs[name]
    local maxY = 0
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") then
            local endY = child.Position.Y.Offset + child.Size.Y.Offset
            if endY > maxY then maxY = endY end
        end
    end
    ContentArea.CanvasSize = UDim2.new(0,0,0,maxY+20)
end

for name, btn in pairs(TabButtons) do
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end
SwitchTab("Combat")

function CreateFOVCircle()
    if FOVCircle then FOVCircle:Remove() end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 3
    FOVCircle.Radius = Config.FOV.Radius
    FOVCircle.Color = Color3.fromRGB(255,255,255)
    FOVCircle.Transparency = 0.5
    FOVCircle.Filled = false
    FOVCircle.Visible = Config.FOVCircle.Enabled
end
if Config.FOVCircle.Enabled then CreateFOVCircle() end

local function FindHead(char)
    return char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end
local function FindTorso(char)
    return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("LowerTorso") or char:FindFirstChild("HumanoidRootPart")
end

local function GetClosestTargetInFOV()
    local closest, bestDist = nil, Config.FOV.Radius
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = FindHead(player.Character)
            if head then
                if not Config.WallShot.Enabled then
                    local ray = Ray.new(myPos.Position, (head.Position - myPos.Position).Unit * (myPos.Position - head.Position).Magnitude)
                    local hit, hitPart = workspace:FindPartOnRay(ray, LocalPlayer.Character)
                    if hit and not hitPart:IsDescendantOf(player.Character) then continue end
                end
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (pos - center).Magnitude
                    if dist < bestDist then bestDist, closest = dist, player end
                end
            end
        end
    end
    return closest
end

local function GetClosestTargetByDistance()
    local closest, minDist = nil, math.huge
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myPos.Position - hrp.Position).Magnitude
                if dist < minDist then minDist, closest = dist, player end
            end
        end
    end
    return closest
end

local function AttemptAttack()
    local target = GetClosestTargetInFOV()
    if target and target.Character then
        local head = FindHead(target.Character)
        if head then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
                for _, remote in ipairs(ReplicatedStorage:GetChildren()) do
                    if remote:IsA("RemoteEvent") then pcall(function() remote:FireServer(head.Position) end) end
                end
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if Config.Silent.Enabled and not MenuOpen then AttemptAttack() end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if Config.FOVCircle.Enabled and FOVCircle then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = center
        FOVCircle.Radius = Config.FOV.Radius
        FOVCircle.Visible = true
    elseif FOVCircle then FOVCircle.Visible = false end

    if Config.AimBot.Enabled and not MenuOpen then
        local target = GetClosestTargetInFOV()
        if target and target.Character then
            local aimPart = FindHead(target.Character)
            if aimPart then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPart.Position), 0.25) end
        end
    end

    if Config.Trigger.Enabled and not MenuOpen then
        triggerDelay = triggerDelay + 1
        if triggerDelay >= Config.Trigger.Delay then
            local target = GetClosestTargetInFOV()
            if target then AttemptAttack() end
            triggerDelay = 0
        end
    end

    if SpinActive and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Config.Spin.Speed * 3), 0) end
    end

    if Config.SexAura.Enabled then
        local target = GetClosestTargetByDistance()
        if target and target.Character then
            local hrp, tHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and tHrp then
                local dist = (hrp.Position - tHrp.Position).Magnitude
                local dir = (tHrp.Position - hrp.Position).Unit
                if dist > 5 then hrp.CFrame = CFrame.new(hrp.Position + dir * 1) else hrp.CFrame = CFrame.new(hrp.Position - dir * 1) end
                hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            end
        end
    end

    if FlyActive and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hrp and humanoid then
            humanoid.PlatformStand = true
            humanoid.WalkSpeed = 0
            local moveDir = humanoid.MoveDirection
            local vel = moveDir * Config.Fly.Speed
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 50, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0, 50, 0) end
            vel = vel + Vector3.new(0, Config.Fly.HeightOffset, 0)
            hrp.CFrame = hrp.CFrame + vel * dt
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end

    if SpeedActive and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then humanoid.WalkSpeed = Config.Speed.Speed end
    end
end)

local function RemoveESPForPlayer(player)
    local data = ESPCache[player]
    if data then
        for _, obj in ipairs(data) do
            pcall(function() obj:Remove() end)
        end
        ESPCache[player] = nil
    end
end

local function CreateESPForPlayer(player)
    if not ESPActive then return end
    if not player.Character then return end
    local data = {}
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 2
    box.Color = Color3.fromRGB(255,255,255)
    box.Filled = false
    table.insert(data, box)
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Size = 13
    nameText.Font = 2
    nameText.Color = Color3.fromRGB(255,255,255)
    nameText.Outline = true
    nameText.Center = true
    table.insert(data, nameText)
    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Size = 13
    healthText.Font = 2
    healthText.Color = Color3.fromRGB(255,255,255)
    healthText.Outline = true
    healthText.Center = true
    table.insert(data, healthText)
    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Size = 13
    distText.Font = 2
    distText.Color = Color3.fromRGB(255,255,255)
    distText.Outline = true
    distText.Center = true
    table.insert(data, distText)
    ESPCache[player] = data
    local function onCharacterRemoved() RemoveESPForPlayer(player) end
    local char = player.Character
    char.AncestryChanged:Connect(function(_, parent)
        if not parent then onCharacterRemoved() end
    end)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Died:Connect(onCharacterRemoved) end
end

function EnableESP()
    ESPActive = true
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then CreateESPForPlayer(player) end
    end
end

function DisableESP()
    ESPActive = false
    for _, data in pairs(ESPCache) do
        for _, obj in ipairs(data) do
            pcall(function() obj:Remove() end)
        end
    end
    ESPCache = {}
end

Players.PlayerRemoving:Connect(function(player) RemoveESPForPlayer(player) end)

RunService.RenderStepped:Connect(function()
    if ESPActive then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local data = ESPCache[player]
                if not data then CreateESPForPlayer(player) data = ESPCache[player] end
                if data then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart") or FindTorso(player.Character)
                    local head = FindHead(player.Character)
                    if hrp and head then
                        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local footPos, footOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen and headOnScreen and footOnScreen then
                            local box, nameText, healthText, distText = data[1], data[2], data[3], data[4]
                            if Config.ESP.Box then
                                local scale = 1000 / hrpPos.Z
                                local width = 1.1 * scale
                                local height = (headPos.Y - footPos.Y) * 1.1
                                box.Size = Vector2.new(width, height)
                                box.Position = Vector2.new(hrpPos.X - width / 2, (headPos.Y + footPos.Y) / 2 - height / 2)
                                box.Visible = true
                            else box.Visible = false end
                            if Config.ESP.Name then
                                nameText.Position = Vector2.new(headPos.X, headPos.Y - 15)
                                nameText.Text = player.Name
                                nameText.Visible = true
                            else nameText.Visible = false end
                            if Config.ESP.Health then
                                healthText.Position = Vector2.new(headPos.X, headPos.Y - 30)
                                healthText.Text = tostring(math.floor(player.Character.Humanoid.Health))
                                healthText.Visible = true
                            else healthText.Visible = false end
                            if Config.ESP.Distance then
                                local dist = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                                distText.Position = Vector2.new(headPos.X, headPos.Y - 45)
                                distText.Text = tostring(math.floor(dist)) .. "m"
                                distText.Visible = true
                            else distText.Visible = false end
                        else
                            for _, obj in ipairs(data) do obj.Visible = false end
                        end
                    end
                end
            end
        end
    end
end)

function UpdateChamsColors()
    if not ChamsActive then return end
    for _, obj in pairs(ChamsObjects) do
        if obj:IsA("Highlight") then
            obj.FillColor = Config.Chams.FillColor
            obj.OutlineColor = Config.Chams.OutlineColor
        end
    end
end

function UpdateChamsTransparency()
    if not ChamsActive then return end
    for _, obj in pairs(ChamsObjects) do
        if obj:IsA("Highlight") then obj.FillTransparency = Config.Chams.Transparency end
    end
end

function EnableChams()
    ChamsActive = true
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, desc in ipairs(player.Character:GetDescendants()) do
                if desc:IsA("BasePart") then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = desc
                    highlight.FillColor = Config.Chams.FillColor
                    highlight.OutlineColor = Config.Chams.OutlineColor
                    highlight.FillTransparency = Config.Chams.Transparency
                    highlight.OutlineTransparency = 0.5
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = desc
                    table.insert(ChamsObjects, highlight)
                end
            end
        end
    end
end

function DisableChams()
    ChamsActive = false
    for _, obj in pairs(ChamsObjects) do pcall(function() obj:Destroy() end) end
    ChamsObjects = {}
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.5)
        if ChamsActive then
            for _, desc in ipairs(player.Character:GetDescendants()) do
                if desc:IsA("BasePart") then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = desc
                    highlight.FillColor = Config.Chams.FillColor
                    highlight.OutlineColor = Config.Chams.OutlineColor
                    highlight.FillTransparency = Config.Chams.Transparency
                    highlight.OutlineTransparency = 0.5
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = desc
                    table.insert(ChamsObjects, highlight)
                end
            end
        end
    end)
end)

function EnableFly() FlyActive = true end
function DisableFly()
    FlyActive = false
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if humanoid then humanoid.PlatformStand = false humanoid.WalkSpeed = 16 end
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end
    end
end
function EnableSpeed() SpeedActive = true end
function DisableSpeed()
    SpeedActive = false
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = 16 end
end
function EnableSpin() SpinActive = true end
function DisableSpin() SpinActive = false end
function EnableCollisions()
    CollisionsActive = true
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local playerY = hrp.Position.Y
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    if v.Position.Y >= playerY - 1 then v.CanCollide = false end
                end
            end
        end
    end
end
function DisableCollisions()
    CollisionsActive = false
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = true end
    end
end

function IsCoin(obj)
    if obj:IsA("BasePart") and (obj.Name:lower():find("coin") or obj.Name:lower():find("money") or obj.Name:lower():find("pickup")) then return true end
    return false
end
function FindClosestCoin()
    local closest = nil
    local minDist = math.huge
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not myPos then return nil end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if IsCoin(obj) and not CollectedCoins[obj] then
            local dist = (myPos - obj.Position).Magnitude
            if dist < minDist then minDist, closest = dist, obj end
        end
    end
    return closest
end
function EnableAutoFarm()
    AutoFarmActive = true
    CollectedCoins = {}
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.PlatformStand = true humanoid.WalkSpeed = 0 humanoid.JumpPower = 0 end
    for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if IsCoin(obj) then
            if not AutoFarmCoins[obj] then
                local line = Drawing.new("Line")
                line.Thickness = 1
                line.Color = Color3.fromRGB(255,255,0)
                line.Transparency = 0.5
                line.Visible = true
                AutoFarmCoins[obj] = line
                table.insert(AutoFarmLines, line)
            end
        end
    end
    AutoFarmTarget = FindClosestCoin()
end
function DisableAutoFarm()
    AutoFarmActive = false
    AutoFarmTarget = nil
    CollectedCoins = {}
    for _, line in pairs(AutoFarmCoins) do line:Remove() end
    AutoFarmCoins = {}
    AutoFarmLines = {}
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.PlatformStand = false humanoid.WalkSpeed = 16 humanoid.JumpPower = 50 end
    for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
end

RunService.RenderStepped:Connect(function(dt)
    if AutoFarmActive and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hrp and humanoid then
            humanoid.PlatformStand = true
            humanoid.WalkSpeed = 0
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            for obj, line in pairs(AutoFarmCoins) do
                if obj and obj.Parent then
                    local pos, onScreen = Camera:WorldToViewportPoint(obj.Position)
                    if onScreen then
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        line.To = Vector2.new(pos.X, pos.Y)
                        line.Visible = true
                    else line.Visible = false end
                else
                    line:Remove()
                    AutoFarmCoins[obj] = nil
                end
            end
            if not AutoFarmTarget or not AutoFarmTarget.Parent then AutoFarmTarget = FindClosestCoin() end
            if AutoFarmTarget then
                local targetPos = AutoFarmTarget.Position
                local distance = (hrp.Position - targetPos).Magnitude
                local step = Config.AutoFarm.Speed * dt
                if distance <= step or distance < 5.5 then
                    CollectedCoins[AutoFarmTarget] = true
                    if AutoFarmCoins[AutoFarmTarget] then AutoFarmCoins[AutoFarmTarget]:Remove() end
                    AutoFarmCoins[AutoFarmTarget] = nil
                    AutoFarmTarget = nil
                    AutoFarmTarget = FindClosestCoin()
                else
                    local direction = (targetPos - hrp.Position).Unit
                    local newPos = hrp.Position + direction * step
                    hrp.CFrame = CFrame.new(newPos)
                end
                hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Config.BunnyHop.Enabled then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local humanoid = char.Humanoid
                local state = humanoid:GetState()
                if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
                    humanoid.Jump = true
                    if tick() - LastBhopTime > 0.1 then
                        BhopSpeed = math.min(BhopSpeed + 5, Config.BunnyHop.MaxSpeed)
                        humanoid.WalkSpeed = BhopSpeed
                        LastBhopTime = tick()
                    end
                end
            end
        else BhopSpeed = 16 end
    end
end)

function EnableSexAura() SexAuraActive = true end
function DisableSexAura() SexAuraActive = false end
function EnableHighJump()
    HighJumpActive = true
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.JumpPower = 200 end
end
function DisableHighJump()
    HighJumpActive = false
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.JumpPower = 50 end
end
function EnableAutoPickupGun()
    AutoPickupGunActive = true
    task.spawn(function()
        while AutoPickupGunActive do
            task.wait(0.1)
            for _, tool in ipairs(workspace:GetDescendants()) do
                if tool:IsA("Tool") and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol")) and tool.Parent and not tool.Parent:IsA("Character") then
                    pcall(function() tool.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame end)
                end
            end
        end
    end)
end
function DisableAutoPickupGun() AutoPickupGunActive = false end

function EnableKillAll()
    KillAllActive = true
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool.Name:lower():find("knife") then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    pcall(function() tool:Activate() end)
                    for _, remote in ipairs(ReplicatedStorage:GetChildren()) do
                        if remote:IsA("RemoteEvent") then
                            pcall(function() remote:FireServer(head.Position) end)
                        end
                    end
                end
            end
        end
    end
end
function DisableKillAll() KillAllActive = false end

function EnableKillSelected()
    KillSelectedActive = true
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool and tool.Name:lower():find("knife") and Config.KillSelected.Target ~= "" then
        local target = Players:FindFirstChild(Config.KillSelected.Target)
        if target and target.Character and target.Character:FindFirstChild("Humanoid") then
            local head = target.Character:FindFirstChild("Head")
            if head then
                pcall(function() tool:Activate() end)
                for _, remote in ipairs(ReplicatedStorage:GetChildren()) do
                    if remote:IsA("RemoteEvent") then
                        pcall(function() remote:FireServer(head.Position) end)
                    end
                end
            end
        end
    end
end
function DisableKillSelected() KillSelectedActive = false end

function EnableTPRole()
    TPRoleActive = true
    local targetRole = Config.TPRole.Role
    local targetPlayer = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool then
                if targetRole == "Sheriff" and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol")) then targetPlayer = player break end
                if targetRole == "Murderer" and tool.Name:lower():find("knife") then targetPlayer = player break end
            end
        end
    end
    if targetPlayer and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0,2,0)
    end
end
function DisableTPRole() TPRoleActive = false end

function EnableAutoShot()
    AutoShotActive = true
    task.spawn(function()
        while AutoShotActive do
            task.wait(0.1)
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol")) then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local targetTool = player.Character:FindFirstChildOfClass("Tool")
                        if targetTool and targetTool.Name:lower():find("knife") then
                            local head = player.Character:FindFirstChild("Head")
                            if head then
                                pcall(function() tool:Activate() end)
                                for _, remote in ipairs(ReplicatedStorage:GetChildren()) do
                                    if remote:IsA("RemoteEvent") then pcall(function() remote:FireServer(head.Position) end) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end
function DisableAutoShot() AutoShotActive = false end

local RoleDisplay = Instance.new("TextLabel")
RoleDisplay.Size = UDim2.new(0,300,0,30)
RoleDisplay.Position = UDim2.new(0.5,-150,0,60)
RoleDisplay.BackgroundColor3 = Color3.fromRGB(0,0,0)
RoleDisplay.BackgroundTransparency = 0.5
RoleDisplay.TextColor3 = Color3.fromRGB(255,255,255)
RoleDisplay.TextScaled = true
RoleDisplay.Font = Enum.Font.Code
RoleDisplay.ZIndex = 300
RoleDisplay.Visible = false
RoleDisplay.Parent = ScreenGui

local function GetPlayerRole(player)
    local role = nil
    if player:GetAttribute("Role") then role = player:GetAttribute("Role") end
    if role then return role end
    local ls = player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Role") then return ls.Role.Value end
    local char = player.Character
    if char then
        local folder = char:FindFirstChild("RoleFolder")
        if folder then
            local val = folder:FindFirstChild("Role")
            if val then return val.Value end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local name = tool.Name:lower()
            if name:find("knife") or name:find("murder") or name:find("killer") then return "Murderer" end
            if name:find("gun") or name:find("sheriff") or name:find("pistol") or name:find("revolver") then return "Sheriff" end
        end
    end
    return nil
end
function EnableWhoIs() WhoIsActive = true RoleDisplay.Visible = true end
function DisableWhoIs() WhoIsActive = false RoleDisplay.Visible = false end

function ApplySkyColor()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then sky:Destroy() end
    sky = Instance.new("Sky")
    sky.SkyColor = Config.SkyColor.Color
    sky.CloudColor = Config.SkyColor.Color
    sky.StarColor = Config.SkyColor.Color
    sky.Parent = Lighting
    Lighting.Ambient = Config.SkyColor.Color
    Lighting.OutdoorAmbient = Config.SkyColor.Color
    SkyChanged = true
end
function ResetSkyColor()
    local current = Lighting:FindFirstChildOfClass("Sky")
    if current then current:Destroy() end
    SkyChanged = false
    Lighting.Ambient = Color3.fromRGB(128,128,128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
end

local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(0,250,0,20)
Watermark.Position = UDim2.new(0.5,-125,0,5)
Watermark.BackgroundColor3 = Color3.fromRGB(0,0,0)
Watermark.BackgroundTransparency = 0.3
Watermark.TextColor3 = Color3.fromRGB(255,255,255)
Watermark.TextScaled = true
Watermark.Font = Enum.Font.Code
Watermark.ZIndex = 300
Watermark.Parent = ScreenGui
local watermarkCorner = Instance.new("UICorner")
watermarkCorner.CornerRadius = UDim.new(1,0)
watermarkCorner.Parent = Watermark

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0,100,0,20)
SpeedLabel.Position = UDim2.new(0.5,-50,1,-30)
SpeedLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
SpeedLabel.BackgroundTransparency = 0.3
SpeedLabel.TextColor3 = Color3.fromRGB(255,255,255)
SpeedLabel.TextScaled = true
SpeedLabel.Font = Enum.Font.Code
SpeedLabel.ZIndex = 300
SpeedLabel.Parent = ScreenGui
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(1,0)
speedCorner.Parent = SpeedLabel

RunService.Heartbeat:Connect(function()
    local currentTick = tick()
    if currentTick - LastFrameTime > 0 then
        CurrentFPS = math.floor(1 / (currentTick - LastFrameTime))
        LastFrameTime = currentTick
    end
    if Config.Watermark.Enabled then
        Watermark.Visible = true
        Watermark.Text = "Hiruku | FPS: " .. CurrentFPS .. " | Players: " .. #Players:GetPlayers() .. " | @" .. LocalPlayer.Name
    else Watermark.Visible = false end
    if Config.SpeedIndicator.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        SpeedLabel.Visible = true
        local speed = LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude
        SpeedLabel.Text = "Speed: " .. math.floor(speed)
    else SpeedLabel.Visible = false end
    if WhoIsActive then
        local sheriff, murderer = nil, nil
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local role = GetPlayerRole(player)
                if role == "Sheriff" then sheriff = player.Name end
                if role == "Murderer" then murderer = player.Name end
            end
        end
        RoleDisplay.Text = "Sheriff: " .. (sheriff or "none") .. "\nMurderer: " .. (murderer or "none")
    end
end)

local isDraggingMenu = false
local dragStartPos = Vector2.new()
local dragStartFramePos = UDim2.new()
local function StartDragging(input)
    isDraggingMenu = true
    dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
    dragStartFramePos = MainFrame.Position
end
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then StartDragging(input) end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingMenu = false end
end)
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local objects = UserInputService:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
        local isClickable = false
        for _, obj in ipairs(objects) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then isClickable = true break end
        end
        if not isClickable then StartDragging(input) end
    end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingMenu = false end
end)
UserInputService.TouchMoved:Connect(function(input)
    if isDraggingMenu then
        MainFrame.Position = UDim2.new(0, dragStartFramePos.X.Offset + (input.Position.X - dragStartPos.X), 0, dragStartFramePos.Y.Offset + (input.Position.Y - dragStartPos.Y))
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDraggingMenu and input.UserInputType == Enum.UserInputType.MouseMovement then
        MainFrame.Position = UDim2.new(0, dragStartFramePos.X.Offset + (input.Position.X - dragStartPos.X), 0, dragStartFramePos.Y.Offset + (input.Position.Y - dragStartPos.Y))
    end
end)

local isDraggingMenuButton = false
local dragStartMenuButton = Vector2.new()
local dragOffsetMenuButton = Vector2.new()
local isClickMenuButton = false

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local absPos = MenuButton.AbsolutePosition
        local size = MenuButton.AbsoluteSize
        if pos.X >= absPos.X and pos.X <= absPos.X + size.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + size.Y then
            isDraggingMenuButton = true
            isClickMenuButton = true
            dragStartMenuButton = pos
            dragOffsetMenuButton = Vector2.new(pos.X - MenuButton.AbsolutePosition.X, pos.Y - MenuButton.AbsolutePosition.Y)
        end
    end
end)
UserInputService.TouchMoved:Connect(function(input)
    if isDraggingMenuButton then
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        if (pos - dragStartMenuButton).Magnitude > 10 then
            isClickMenuButton = false
            MenuButton.Position = UDim2.new(0, pos.X - dragOffsetMenuButton.X, 0, pos.Y - dragOffsetMenuButton.Y)
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDraggingMenuButton and input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        if (pos - dragStartMenuButton).Magnitude > 10 then
            isClickMenuButton = false
            MenuButton.Position = UDim2.new(0, pos.X - dragOffsetMenuButton.X, 0, pos.Y - dragOffsetMenuButton.Y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isDraggingMenuButton then
            if isClickMenuButton then
                MenuOpen = not MenuOpen
                if MenuOpen then ShowMenu() else HideMenu() end
            end
            isDraggingMenuButton = false
        end
    end
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,26,0,26)
CloseBtn.Position = UDim2.new(1,-31,0,4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150,40,40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.Code
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0,5)
closeCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function() MenuOpen = false HideMenu() end)
CloseBtn.TouchTap:Connect(function() MenuOpen = false HideMenu() end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(0.5)
            if ESPActive then CreateESPForPlayer(player) end
            if ChamsActive then DisableChams() EnableChams() end
        end)
    end
end
LocalPlayer.CharacterAdded:Connect(function()
    if CollisionsActive then wait(0.5) EnableCollisions() end
    if SpinActive then wait(0.5) EnableSpin() end
    if AutoFarmActive then wait(0.5) EnableAutoFarm() end
    if SkyChanged then ApplySkyColor() end
    if HighJumpActive then EnableHighJump() end
end)
if Config.FOVCircle.Enabled then CreateFOVCircle() end
print("Hiruku MM2 Script Loaded!")