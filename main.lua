--[[
    ZRN Hub - Rivals 專屬版本
    語言：繁體中文
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)
local Mouse = LocalPlayer and LocalPlayer:GetMouse() or nil

local CoreGui
pcall(function() CoreGui = game:GetService("CoreGui") end)

-- 功能狀態變數
local Toggles = {
    Aimbot = false,
    ShowFOV = false,
    HitboxExpander = false,
    BoxESP = false,
    NameESP = false,
    HealthESP = false,
    DistanceESP = false,
    MagicBullet = false,
    InfiniteAmmo = false,
    AutoHeal = false,
    TriggerBot = false
}

local Settings = {
    AimbotSmoothness = 1,
    AimbotFOV = 100,
    AimbotUseFOV = true,
    AimbotTarget = "Auto (AI)",
    AimbotPrediction = false,
    PredictionAmount = 0.05,
    BulletDrop = 0,
    HitboxSize = 5
}

--------------------------------------------------------------------------------
-- 環境特效模組 (CreateSnow)
--------------------------------------------------------------------------------
local function CreateSnow()
    local snowPart = Instance.new("Part")
    snowPart.Name = "ZRNSnowPart"
    snowPart.Size = Vector3.new(300, 1, 300)
    snowPart.Transparency = 1
    snowPart.Anchored = true
    snowPart.CanCollide = false
    -- 放在 Terrain 下面，絕對不會被遊戲清理腳本刪除，也保證可以被渲染
    snowPart.Parent = Workspace.Terrain
    
    local snowEmitter = Instance.new("ParticleEmitter")
    snowEmitter.Parent = snowPart
    -- 不設定 Texture，強制使用 Roblox 內建白點粒子，保證 100% 渲染
    snowEmitter.Rate = 1500
    snowEmitter.Speed = NumberRange.new(30, 60)
    snowEmitter.Lifetime = NumberRange.new(5, 8)
    snowEmitter.Rotation = NumberRange.new(0, 360)
    snowEmitter.RotSpeed = NumberRange.new(-50, 50)
    snowEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(1, 0.2)
    })
    snowEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    snowEmitter.EmissionDirection = Enum.NormalId.Bottom
    snowEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    snowEmitter.Enabled = true
    
    local Lighting = game:GetService("Lighting")
    

    -- 強制移除遊戲本身的 Skybox，以防 FFlag 沒生效
    local function removeSky()
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
    end
    removeSky()
    Lighting.ChildAdded:Connect(function(v)
        if v:IsA("Sky") then task.wait() v:Destroy() end
    end)
    
    -- 加入冷色調濾鏡 (保留雪天的冷峻氛圍)
    local colorCorrection = Lighting:FindFirstChild("ZRNSnowColorCorrection")
    if not colorCorrection then
        colorCorrection = Instance.new("ColorCorrectionEffect")
        colorCorrection.Name = "ZRNSnowColorCorrection"
        colorCorrection.Parent = Lighting
    end
    
    RunService.RenderStepped:Connect(function()
        if Camera then
            snowPart.CFrame = Camera.CFrame * CFrame.new(0, 50, 0)
        end
        -- 強制在每一幀覆蓋遊戲的環境光 (包含新型的 Atmosphere)
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(150, 160, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(120, 130, 150)
            Lighting.ColorShift_Top = Color3.fromRGB(100, 110, 120)
            Lighting.ColorShift_Bottom = Color3.fromRGB(100, 110, 120)
            
            colorCorrection.Saturation = -0.4
            colorCorrection.TintColor = Color3.fromRGB(220, 230, 255)
            colorCorrection.Brightness = -0.1
            
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then
                atmo.Density = 0.8
                atmo.Color = Color3.fromRGB(140, 150, 170)
                atmo.Glare = 0
                atmo.Haze = 5
            else
                Lighting.FogColor = Color3.fromRGB(140, 150, 170)
                Lighting.FogEnd = 250
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- 動態準心模組 (CreateDynamicCrosshair)
--------------------------------------------------------------------------------
local function CreateDynamicCrosshair()
    local crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "ZRNDynamicCrosshair"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.IgnoreGuiInset = true
    
    pcall(function() crosshairGui.Parent = CoreGui end)
    if not crosshairGui.Parent then
        crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local container = Instance.new("Frame")
    container.Parent = crosshairGui
    container.Size = UDim2.new(0, 30, 0, 30)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local thickness = 2
    local length = 8
    local offset = 6
    local color = Color3.fromRGB(150, 50, 255)
    
    -- 上下左右四條線
    local top = Instance.new("Frame", container)
    top.Size = UDim2.new(0, thickness, 0, length)
    top.Position = UDim2.new(0.5, -thickness/2, 0.5, -offset - length)
    top.BackgroundColor3 = color
    top.BorderSizePixel = 0
    
    local bottom = Instance.new("Frame", container)
    bottom.Size = UDim2.new(0, thickness, 0, length)
    bottom.Position = UDim2.new(0.5, -thickness/2, 0.5, offset)
    bottom.BackgroundColor3 = color
    bottom.BorderSizePixel = 0
    
    local left = Instance.new("Frame", container)
    left.Size = UDim2.new(0, length, 0, thickness)
    left.Position = UDim2.new(0.5, -offset - length, 0.5, -thickness/2)
    left.BackgroundColor3 = color
    left.BorderSizePixel = 0
    
    local right = Instance.new("Frame", container)
    right.Size = UDim2.new(0, length, 0, thickness)
    right.Position = UDim2.new(0.5, offset, 0.5, -thickness/2)
    right.BackgroundColor3 = color
    right.BorderSizePixel = 0
    
    -- 外圓圈
    local circle = Instance.new("Frame", container)
    circle.Size = UDim2.new(1, 0, 1, 0)
    circle.Position = UDim2.new(0, 0, 0, 0)
    circle.BackgroundTransparency = 1
    local uiStroke = Instance.new("UIStroke", circle)
    uiStroke.Color = color
    uiStroke.Thickness = 1
    uiStroke.Transparency = 0.3
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    -- 中心白點
    local dot = Instance.new("Frame", container)
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    
    RunService.RenderStepped:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        container.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
        -- 核心動態效果：不斷旋轉
        container.Rotation = container.Rotation + 2.5
        
        -- 開火時會有後座力放大的動畫效果
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            container.Size = container.Size:Lerp(UDim2.new(0, 40, 0, 40), 0.2)
        else
            container.Size = container.Size:Lerp(UDim2.new(0, 30, 0, 30), 0.2)
        end
    end)
    
    -- 隱藏遊戲原生準心 (強制掃描並隱藏)
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    for _, v in pairs(pg:GetDescendants()) do
                        if v:IsA("ImageLabel") or v:IsA("Frame") then
                            local name = string.lower(v.Name)
                            if name:match("crosshair") or name:match("reticle") then
                                v.Visible = false
                            end
                        end
                    end
                end
            end)
        end
    end)
end

--------------------------------------------------------------------------------
-- UI 框架庫
--------------------------------------------------------------------------------
local Library = {}
local Theme = {
    MainColor = Color3.fromRGB(147, 51, 234),
    Background = Color3.fromRGB(20, 20, 25),
    Sidebar = Color3.fromRGB(30, 30, 35),
    ElementBg = Color3.fromRGB(40, 40, 45),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(150, 150, 150)
}

function Library:CreateWindow(config)
    local WindowName = config.Name or "ZRN HUB"
    local WindowSize = config.Size or UDim2.new(0, 600, 0, 400)

    local ZRN_GUI = Instance.new("ScreenGui")
    ZRN_GUI.Name = "ZRNHub_" .. tostring(math.random(10000, 99999))
    ZRN_GUI.ResetOnSpawn = false
    ZRN_GUI.IgnoreGuiInset = true
    
    local function MountUI()
        local s1, e1 = pcall(function()
            if gethui then
                ZRN_GUI.Parent = gethui()
            elseif type(syn) == "table" and type(syn.protect_gui) == "function" then
                syn.protect_gui(ZRN_GUI)
                ZRN_GUI.Parent = CoreGui
            else
                ZRN_GUI.Parent = CoreGui
            end
        end)
        if not s1 or not ZRN_GUI.Parent then
            if LocalPlayer then
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    ZRN_GUI.Parent = playerGui
                end
            end
        end
    end
    MountUI()

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ZRN_GUI
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -WindowSize.X.Offset/2, 0.5, -WindowSize.Y.Offset/2)
    MainFrame.Size = WindowSize
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false -- 隱藏直到動畫結束

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Parent = MainFrame
    Topbar.BackgroundColor3 = Theme.Sidebar
    Topbar.BorderSizePixel = 0
    Topbar.Size = UDim2.new(1, 0, 0, 40)
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 8)
    TopbarCorner.Parent = Topbar
    
    local TopbarExtension = Instance.new("Frame")
    TopbarExtension.Parent = Topbar
    TopbarExtension.BackgroundColor3 = Theme.Sidebar
    TopbarExtension.BorderSizePixel = 0
    TopbarExtension.Position = UDim2.new(0, 0, 1, -10)
    TopbarExtension.Size = UDim2.new(1, 0, 0, 10)

    local Title = Instance.new("TextLabel")
    Title.Parent = Topbar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(1, -30, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = WindowName
    Title.TextColor3 = Theme.MainColor
    Title.TextSize = 20
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = MainFrame
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.Size = UDim2.new(0, 150, 1, -40)

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Parent = Sidebar
    TabContainer.BackgroundTransparency = 1
    TabContainer.Position = UDim2.new(0, 0, 0, 10)
    TabContainer.Size = UDim2.new(1, 0, 1, -40) -- 縮小高度留給 Discord 按鈕
    TabContainer.ScrollBarThickness = 0
    
    local DiscordButton = Instance.new("TextButton")
    DiscordButton.Parent = Sidebar
    DiscordButton.BackgroundTransparency = 1
    DiscordButton.Position = UDim2.new(0, 0, 1, -30)
    DiscordButton.Size = UDim2.new(1, 0, 0, 25)
    DiscordButton.Font = Enum.Font.GothamBold
    DiscordButton.Text = "Discord"
    DiscordButton.TextColor3 = Theme.MainColor
    DiscordButton.TextSize = 14
    
    DiscordButton.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/DgaS3UFdE2")
                game.StarterGui:SetCore("SendNotification", {
                    Title = "ZRN Hub",
                    Text = "Discord 連結已經複製到你的剪貼簿！請在瀏覽器貼上。",
                    Duration = 5,
                })
            end
        end)
    end)
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabContainer
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Parent = MainFrame
    ContentArea.BackgroundColor3 = Theme.Background
    ContentArea.BorderSizePixel = 0
    ContentArea.Position = UDim2.new(0, 150, 0, 40)
    ContentArea.Size = UDim2.new(1, -150, 1, -40)

    local dragging, dragInput, dragStart, startPos
    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            ZRN_GUI.Enabled = not ZRN_GUI.Enabled
        end
    end)

    local Window = { Tabs = {} }
    
    function Window:PlayIntro()
        local IntroFrame = Instance.new("Frame")
        IntroFrame.Parent = ZRN_GUI
        IntroFrame.BackgroundColor3 = Theme.Background
        IntroFrame.Size = UDim2.new(0, 300, 0, 100)
        IntroFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
        IntroFrame.BackgroundTransparency = 1
        Instance.new("UICorner", IntroFrame).CornerRadius = UDim.new(0, 8)
        
        local IntroTitle = Instance.new("TextLabel")
        IntroTitle.Parent = IntroFrame
        IntroTitle.Size = UDim2.new(1, 0, 1, -20)
        IntroTitle.Position = UDim2.new(0, 0, 0, 0)
        IntroTitle.BackgroundTransparency = 1
        IntroTitle.Text = "ZRN HUB"
        IntroTitle.Font = Enum.Font.GothamBold
        IntroTitle.TextSize = 28
        IntroTitle.TextColor3 = Theme.MainColor
        IntroTitle.TextTransparency = 1
        
        local LoadingText = Instance.new("TextLabel")
        LoadingText.Parent = IntroFrame
        LoadingText.Size = UDim2.new(1, 0, 0, 20)
        LoadingText.Position = UDim2.new(0, 0, 1, -30)
        LoadingText.BackgroundTransparency = 1
        LoadingText.Text = "Authenticating..."
        LoadingText.Font = Enum.Font.Gotham
        LoadingText.TextSize = 13
        LoadingText.TextColor3 = Theme.TextDark
        LoadingText.TextTransparency = 1
        
        -- 動畫序列
        TweenService:Create(IntroFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
        task.wait(0.5)
        TweenService:Create(IntroTitle, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        task.wait(0.5)
        TweenService:Create(LoadingText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        task.wait(0.6)
        LoadingText.Text = "Loading Rivals Module..."
        task.wait(0.6)
        LoadingText.Text = "Welcome back, " .. (LocalPlayer and LocalPlayer.Name or "User")
        task.wait(0.8)
        
        -- 退場動畫
        TweenService:Create(IntroTitle, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(LoadingText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        local frameTween = TweenService:Create(IntroFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), 
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        })
        frameTween:Play()
        frameTween.Completed:Wait()
        IntroFrame:Destroy()
        
        -- 主介面彈出動畫
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainFrame.Visible = true
        
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Size = WindowSize,
            Position = UDim2.new(0.5, -WindowSize.X.Offset/2, 0.5, -WindowSize.Y.Offset/2)
        }):Play()
        
        -- 觸發下雪特效與動態準心
        if CreateSnow then CreateSnow() end
        if CreateDynamicCrosshair then CreateDynamicCrosshair() end
    end

    function Window:CreateTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Parent = TabContainer
        TabButton.BackgroundColor3 = Theme.ElementBg
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(0.9, 0, 0, 35)
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.Text = tabName
        TabButton.TextColor3 = Theme.TextDark
        TabButton.TextSize = 14
        TabButton.AutoButtonColor = false
        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 6)
        TabButtonCorner.Parent = TabButton

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Parent = ContentArea
        TabPage.BackgroundTransparency = 1
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.ScrollBarThickness = 2
        TabPage.ScrollBarImageColor3 = Theme.MainColor
        TabPage.Visible = false
        
        local PagePadding = Instance.new("UIPadding")
        PagePadding.Parent = TabPage
        PagePadding.PaddingTop = UDim.new(0, 10)
        PagePadding.PaddingBottom = UDim.new(0, 10)
        PagePadding.PaddingLeft = UDim.new(0, 10)
        PagePadding.PaddingRight = UDim.new(0, 10)
        
        local PageListLayout = Instance.new("UIListLayout")
        PageListLayout.Parent = TabPage
        PageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageListLayout.Padding = UDim.new(0, 10)

        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(Window.Tabs) do
                tab.Page.Visible = false
                TweenService:Create(tab.Button, TweenInfo.new(0.2), {TextColor3 = Theme.TextDark, BackgroundTransparency = 1}):Play()
            end
            TabPage.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.2), {TextColor3 = Theme.Text, BackgroundTransparency = 0}):Play()
        end)

        if #Window.Tabs == 0 then
            TabPage.Visible = true
            TabButton.TextColor3 = Theme.Text
            TabButton.BackgroundTransparency = 0
        end

        local Tab = { Button = TabButton, Page = TabPage }
        table.insert(Window.Tabs, Tab)

        function Tab:CreateToggle(name, default, callback)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Parent = TabPage
            ToggleFrame.BackgroundColor3 = Theme.ElementBg
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 6)

            local Title = Instance.new("TextLabel")
            Title.Parent = ToggleFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 10, 0, 0)
            Title.Size = UDim2.new(1, -50, 1, 0)
            Title.Font = Enum.Font.Gotham
            Title.Text = name
            Title.TextColor3 = Theme.Text
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Parent = ToggleFrame
            ToggleButton.BackgroundColor3 = default and Theme.MainColor or Theme.Background
            ToggleButton.Position = UDim2.new(1, -45, 0.5, -10)
            ToggleButton.Size = UDim2.new(0, 35, 0, 20)
            ToggleButton.Text = ""
            ToggleButton.AutoButtonColor = false
            Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

            local ToggleInner = Instance.new("Frame")
            ToggleInner.Parent = ToggleButton
            ToggleInner.BackgroundColor3 = Theme.Text
            ToggleInner.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            ToggleInner.Size = UDim2.new(0, 16, 0, 16)
            Instance.new("UICorner", ToggleInner).CornerRadius = UDim.new(1, 0)

            local toggled = default
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                if toggled then
                    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Theme.MainColor}):Play()
                    TweenService:Create(ToggleInner, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
                else
                    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background}):Play()
                    TweenService:Create(ToggleInner, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
                end
                if callback then pcall(callback, toggled) end
            end)
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageListLayout.AbsoluteContentSize.Y + 20)
        end

        function Tab:CreateSlider(name, min, max, default, callback)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Parent = TabPage
            SliderFrame.BackgroundColor3 = Theme.ElementBg
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 6)

            local Title = Instance.new("TextLabel")
            Title.Parent = SliderFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 10, 0, 0)
            Title.Size = UDim2.new(1, -20, 0, 30)
            Title.Font = Enum.Font.Gotham
            Title.Text = name .. " : " .. tostring(default)
            Title.TextColor3 = Theme.Text
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local SliderBg = Instance.new("Frame")
            SliderBg.Parent = SliderFrame
            SliderBg.BackgroundColor3 = Theme.Background
            SliderBg.Position = UDim2.new(0, 10, 0, 35)
            SliderBg.Size = UDim2.new(1, -20, 0, 6)
            Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBg
            SliderFill.BackgroundColor3 = Theme.MainColor
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

            local SliderButton = Instance.new("TextButton")
            SliderButton.Parent = SliderBg
            SliderButton.BackgroundTransparency = 1
            SliderButton.Size = UDim2.new(1, 0, 1, 0)
            SliderButton.Text = ""

            local draggingSlider = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + ((max - min) * pos))
                TweenService:Create(SliderFill, TweenInfo.new(0.05), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
                Title.Text = name .. " : " .. tostring(value)
                if callback then pcall(callback, value) end
            end

            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input)
                end
            end)
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageListLayout.AbsoluteContentSize.Y + 20)
        end

        function Tab:CreateButton(name, callback)
            local Button = Instance.new("TextButton")
            Button.Parent = TabPage
            Button.BackgroundColor3 = Theme.ElementBg
            Button.Size = UDim2.new(1, 0, 0, 35)
            Button.Font = Enum.Font.Gotham
            Button.Text = name
            Button.TextColor3 = Theme.Text
            Button.TextSize = 14
            Button.AutoButtonColor = false
            Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

            Button.MouseButton1Click:Connect(function()
                local t1 = TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Theme.MainColor})
                t1:Play()
                t1.Completed:Wait()
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBg}):Play()
                if callback then pcall(callback) end
            end)
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageListLayout.AbsoluteContentSize.Y + 20)
        end

        function Tab:CreateDropdown(name, options, default, callback)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Parent = TabPage
            DropdownFrame.BackgroundColor3 = Theme.ElementBg
            DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 6)

            local Title = Instance.new("TextLabel")
            Title.Parent = DropdownFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 10, 0, 0)
            Title.Size = UDim2.new(0.5, -10, 1, 0)
            Title.Font = Enum.Font.Gotham
            Title.Text = name
            Title.TextColor3 = Theme.Text
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Parent = DropdownFrame
            SelectedText.BackgroundTransparency = 1
            SelectedText.Position = UDim2.new(0.5, 0, 0, 0)
            SelectedText.Size = UDim2.new(0.5, -10, 1, 0)
            SelectedText.Font = Enum.Font.Gotham
            SelectedText.Text = default
            SelectedText.TextColor3 = Theme.MainColor
            SelectedText.TextSize = 14
            SelectedText.TextXAlignment = Enum.TextXAlignment.Right

            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Parent = DropdownFrame
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Size = UDim2.new(1, 0, 1, 0)
            DropdownButton.Text = ""

            local OptionIndex = 1
            for i, v in ipairs(options) do
                if v == default then OptionIndex = i end
            end

            DropdownButton.MouseButton1Click:Connect(function()
                OptionIndex = OptionIndex + 1
                if OptionIndex > #options then OptionIndex = 1 end
                local selected = options[OptionIndex]
                SelectedText.Text = selected
                if callback then pcall(callback, selected) end
            end)
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageListLayout.AbsoluteContentSize.Y + 20)
        end

        return Tab
    end

    return Window
end

--------------------------------------------------------------------------------
-- 核心功能模組 (Aimbot & ESP)
--------------------------------------------------------------------------------

-- FOV 繪製 (使用 Drawing API，如果 Executor 支援)
local FOVCircle
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Color = Theme.MainColor
    FOVCircle.Thickness = 1
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
end

-- 動態智能部位鎖定 (AI Smart Hitbox)
local function getSmartTargetPart(character)
    local Camera = Workspace.CurrentCamera
    if not Camera then return nil end
    local raycastParams = RaycastParams.new()
    local filterList = {LocalPlayer.Character, Camera, Workspace.Terrain}
    if Workspace:FindFirstChild("ZRNSnowPart") then table.insert(filterList, Workspace.ZRNSnowPart) end
    raycastParams.FilterDescendantsInstances = filterList
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local partsToScan = {}
    -- 優先掃描使用者選擇的部位
    if Settings.AimbotTarget ~= "Auto (AI)" then
        table.insert(partsToScan, Settings.AimbotTarget)
    else
        -- AI 模式：按優先級掃描全身
        partsToScan = {"Head", "UpperTorso", "LowerTorso", "RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg", "HumanoidRootPart"}
    end

    for _, partName in ipairs(partsToScan) do
        local part = character:FindFirstChild(partName)
        if part then
            local origin = Camera.CFrame.Position
            local direction = (part.Position - origin)
            local result = Workspace:Raycast(origin, direction, raycastParams)
            -- 如果沒打到東西（完全沒遮蔽），或者打到的東西屬於這個敵人
            if not result or (result.Instance and result.Instance:IsDescendantOf(character)) then
                return part
            end
        end
    end
    
    -- 如果全被擋住，退回預設鎖定點 (可能搭配穿牆子彈使用)
    return character:FindFirstChild(Settings.AimbotTarget ~= "Auto (AI)" and Settings.AimbotTarget or "HumanoidRootPart")
end

-- 取得最近的目標
local function getClosestPlayer()
    local Camera = Workspace.CurrentCamera
    if not Camera then return nil end
    local closestPlayer = nil
    
    if Settings.AimbotUseFOV then
        local shortestDistance = Settings.AimbotFOV
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local targetPart = getSmartTargetPart(player.Character)
                if targetPart then
                    -- 改用 WorldToScreenPoint 與 GetMouseLocation 確保完全對準準心，避免 Viewport 偏差
                    local pos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                    if onScreen then
                        local screenCenter = UserInputService:GetMouseLocation()
                        local distance = (screenCenter - Vector2.new(pos.X, pos.Y)).Magnitude
                        if distance < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    else
        -- 無視視角 (不管看哪裡)，直接鎖定 3D 距離最近的敵人
        local shortestDistance = math.huge
        local lpRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if lpRoot then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                    local targetPart = getSmartTargetPart(player.Character)
                    if targetPart then
                        local distance = (targetPart.Position - lpRoot.Position).Magnitude
                        if distance < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- ESP 系統 (使用 BillboardGui 確保相容性)
local function createESP(player)
    if player == LocalPlayer then return end

    local function setupESP(character)
        task.spawn(function()
            if not character then return end
            local head = character:WaitForChild("Head", 5)
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            local hum = character:WaitForChild("Humanoid", 5)
            if not head or not hrp or not hum then return end

        local targetParent = gethui and gethui() or CoreGui
        local mainESPFolder = targetParent:FindFirstChild("ZRN_Rivals_ESP_Container")
        if not mainESPFolder then
            mainESPFolder = Instance.new("Folder")
            mainESPFolder.Name = "ZRN_Rivals_ESP_Container"
            mainESPFolder.Parent = targetParent
        end
        
        local espFolderName = "ESP_" .. player.Name
        if mainESPFolder:FindFirstChild(espFolderName) then
            mainESPFolder[espFolderName]:Destroy()
        end

        local espFolder = Instance.new("Folder")
        espFolder.Name = espFolderName
        espFolder.Parent = mainESPFolder

        -- 名字與血量
        local billboard = Instance.new("BillboardGui")
        billboard.Parent = espFolder
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true

        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = billboard
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 12
        textLabel.TextColor3 = Theme.MainColor
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)

        local originalSizes = {}

        -- 判定區擴大 (Hitbox Expander)
        local function updateHitbox()
            if Toggles.HitboxExpander then
                local target = character:FindFirstChild(Settings.AimbotTarget) or character:FindFirstChild("HumanoidRootPart")
                if target then
                    if not originalSizes[target] then
                        originalSizes[target] = target.Size
                    end
                    target.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    target.Transparency = 0.5
                    target.CanCollide = false
                end
            else
                -- 還原原始大小
                for part, origSize in pairs(originalSizes) do
                    if part and part.Parent then
                        part.Size = origSize
                        if part.Name == "HumanoidRootPart" then
                            part.Transparency = 1
                        else
                            part.Transparency = 0
                        end
                    end
                end
                table.clear(originalSizes)
            end
        end

        -- 渲染更新迴圈
        local conn
        conn = RunService.RenderStepped:Connect(function()
            pcall(function()
                if not character.Parent or hum.Health <= 0 then
                    conn:Disconnect()
                    if espFolder and espFolder.Parent then espFolder:Destroy() end
                    return
                end

                -- 更新透視文字
                if Toggles.NameESP or Toggles.HealthESP or Toggles.DistanceESP then
                    billboard.Enabled = true
                    local display = ""
                    if Toggles.NameESP then display = display .. player.Name .. "\n" end
                    if Toggles.HealthESP then display = display .. "[ " .. math.floor(hum.Health) .. " HP ]\n" end
                    if Toggles.DistanceESP and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        display = display .. math.floor(dist) .. " M"
                    end
                    textLabel.Text = display
                else
                    billboard.Enabled = false
                end

                -- 更新外框透視 (AI 追蹤專用螢光紫)
                if Toggles.BoxESP then
                    if not espFolder:FindFirstChild("BoxHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "BoxHighlight"
                        hl.Parent = espFolder
                        hl.Adornee = character -- 必須設定 Adornee 才會顯示
                        hl.FillColor = Color3.fromRGB(255, 0, 255) -- 純洋紅色 (Python 最好抓的顏色)
                        hl.FillTransparency = 0.5
                        hl.OutlineColor = Color3.fromRGB(255, 0, 255)
                        hl.OutlineTransparency = 0
                    end
                else
                    if espFolder:FindFirstChild("BoxHighlight") then
                        espFolder.BoxHighlight:Destroy()
                    end
                end

                -- 更新判定區
                updateHitbox()
            end)
        end)
        end)
    end

    if player.Character then setupESP(player.Character) end
    player.CharacterAdded:Connect(setupESP)
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

-- 核心渲染迴圈 (Aimbot & FOV)
local AimbotHolding = false
local IsShooting = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then AimbotHolding = true end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then IsShooting = true end
    
    -- 瞬移攻擊 (Teleport to Target)
    if input.KeyCode == Enum.KeyCode.T then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                -- 傳送到目標背後 3 Studs 的位置
                local targetHRP = target.Character.HumanoidRootPart
                local teleportCFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                LocalPlayer.Character.HumanoidRootPart.CFrame = teleportCFrame
            end
        end
    end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then AimbotHolding = false end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then IsShooting = false end
end)

local CachedMagicBulletTargetPart = nil

RunService.RenderStepped:Connect(function()
    -- 穿牆子彈目標快取 (每秒 60 次，取代在 __namecall 中每秒幾萬次的運算)
    if Toggles.MagicBullet then
        local target = getClosestPlayer()
        if target and target.Character then
            CachedMagicBulletTargetPart = getSmartTargetPart(target.Character)
        else
            CachedMagicBulletTargetPart = nil
        end
    end

    -- 更新 FOV 圓圈，精準對齊真實滑鼠/準心位置
    if FOVCircle then
        FOVCircle.Visible = Toggles.ShowFOV
        FOVCircle.Radius = Settings.AimbotFOV
        FOVCircle.Position = UserInputService:GetMouseLocation()
    end

    -- 執行自瞄
    if Toggles.Aimbot and AimbotHolding then
        local target = getClosestPlayer()
        if target and target.Character then
            local targetPart = getSmartTargetPart(target.Character)
            if targetPart then
                local Camera = Workspace.CurrentCamera
                if not Camera then return end
                
                local targetPos = targetPart.Position
                local CameraPos = Camera.CFrame.Position
                
                -- 動態預判：使用滑桿可調的強度，取代死板的數值
                if Settings.AimbotPrediction then
                    targetPos = targetPos + (targetPart.Velocity * Settings.PredictionAmount)
                end
                
                local distance = (targetPos - CameraPos).Magnitude
                
                -- 子彈下墜補償 (Bullet Drop Compensation)
                -- 距離越遠，子彈下墜越嚴重，因此需要將瞄準點往上抬
                if Settings.BulletDrop > 0 then
                    local dropAmount = (distance / 100) * Settings.BulletDrop
                    targetPos = targetPos + Vector3.new(0, dropAmount, 0)
                end
                
                -- 回歸純粹的 CFrame.new (準心將完美對齊目標的 3D 座標)
                local targetCameraCFrame = CFrame.new(CameraPos, targetPos)
                
                if Settings.AimbotSmoothness > 1 then
                    Camera.CFrame = Camera.CFrame:Lerp(targetCameraCFrame, 1 / Settings.AimbotSmoothness)
                else
                    Camera.CFrame = targetCameraCFrame
                end
            end
        end
    end
    
    -- 自動開槍 (TriggerBot)
    if Toggles.TriggerBot and LocalPlayer.Character then
        local mouseLocation = UserInputService:GetMouseLocation()
        local ray = Camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Workspace.Terrain, Workspace:FindFirstChild("ZRNSnowPart")}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.IgnoreWater = true
        
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChild("Humanoid") and Players:GetPlayerFromCharacter(model) then
                -- 瞄準到敵人，模擬點擊
                mouse1press()
                task.delay(0.05, function() mouse1release() end)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 靜默追蹤 (穿牆/無視障礙物)
--------------------------------------------------------------------------------
local successMT, errMT = pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Toggles.MagicBullet and IsShooting and not checkcaller() then
            local targetPart = CachedMagicBulletTargetPart
            if targetPart then
                if self == Workspace and method == "Raycast" then
                    local origin = args[1]
                    local direction = args[2]
                    -- 攔截射擊射線
                    if typeof(direction) == "Vector3" and direction.Magnitude > 100 then
                        -- 極簡暴力解法：保持原點 (Origin) 不變以繞過反作弊原點檢查，
                        -- 直接將射線方向 (Direction) 強制鎖死指向敵人的部位。
                        local newDirection = (targetPart.Position - origin).Unit * 1000
                        args[2] = newDirection
                        
                        return oldNamecall(self, unpack(args))
                    end
                elseif self == Workspace and (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay") then
                    local origin = args[1].Origin
                    local direction = args[1].Direction
                    if typeof(direction) == "Vector3" and direction.Magnitude > 100 then
                        local newDirection = (targetPart.Position - origin).Unit * 1000
                        args[1] = Ray.new(origin, newDirection)
                        
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end

        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
end)

--------------------------------------------------------------------------------
-- 建立 UI 選單
--------------------------------------------------------------------------------

local Window = Library:CreateWindow({
    Name = "ZRN HUB - RIVALS",
    Size = UDim2.new(0, 550, 0, 380)
})

-- 戰鬥分頁
local CombatTab = Window:CreateTab("戰鬥")

CombatTab:CreateToggle("啟用自瞄 (右鍵觸發)", false, function(state) Toggles.Aimbot = state end)
CombatTab:CreateToggle("自動開槍 (TriggerBot)", false, function(state) Toggles.TriggerBot = state end)
CombatTab:CreateToggle("啟用靜默追蹤 (穿牆)", false, function(state) Toggles.MagicBullet = state end)
CombatTab:CreateToggle("限制鎖定範圍 (FOV)", true, function(state) Settings.AimbotUseFOV = state end)
CombatTab:CreateToggle("啟用移動預判 (Prediction)", false, function(state) Settings.AimbotPrediction = state end)
CombatTab:CreateSlider("預判強度 (數字越大越往前)", 0, 20, 5, function(val) Settings.PredictionAmount = val / 100 end)
CombatTab:CreateSlider("子彈下墜補償 (抬高槍口)", 0, 20, 0, function(val) Settings.BulletDrop = val / 10 end)
CombatTab:CreateToggle("顯示鎖定範圍", false, function(state) Toggles.ShowFOV = state end)
CombatTab:CreateSlider("鎖定範圍大小", 10, 500, 100, function(val) Settings.AimbotFOV = val end)
CombatTab:CreateSlider("自瞄平滑度 (越大越慢)", 1, 20, 1, function(val) Settings.AimbotSmoothness = val end)
CombatTab:CreateDropdown("自瞄部位", {"Auto (AI)", "Head", "HumanoidRootPart"}, "Auto (AI)", function(val) Settings.AimbotTarget = val end)

CombatTab:CreateToggle("啟用判定區擴大", false, function(state) Toggles.HitboxExpander = state end)
CombatTab:CreateSlider("判定區大小", 2, 20, 5, function(val) Settings.HitboxSize = val end)


-- 視覺分頁
local VisualTab = Window:CreateTab("視覺")

VisualTab:CreateToggle("顯示外框透視", false, function(state) Toggles.BoxESP = state end)
VisualTab:CreateToggle("顯示玩家名稱", false, function(state) Toggles.NameESP = state end)
VisualTab:CreateToggle("顯示血量資訊", false, function(state) Toggles.HealthESP = state end)
VisualTab:CreateToggle("顯示距離", false, function(state) Toggles.DistanceESP = state end)


-- 角色分頁
local CharacterTab = Window:CreateTab("角色")

local originalWalkSpeed = 16
CharacterTab:CreateSlider("移動速度 (WalkSpeed)", 16, 200, 16, function(val)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end)

local flying = false
local flySpeed = 50
local flyBodyVelocity = nil
CharacterTab:CreateToggle("飛行模式 (Fly)", false, function(state)
    flying = state
    if flying and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
    else
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
    end
end)

-- 飛行與穿牆邏輯
RunService.RenderStepped:Connect(function()
    if flying and flyBodyVelocity and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local moveDir = LocalPlayer.Character.Humanoid.MoveDirection
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            flyBodyVelocity.Velocity = Vector3.new(0, flySpeed, 0) + (moveDir * flySpeed)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            flyBodyVelocity.Velocity = Vector3.new(0, -flySpeed, 0) + (moveDir * flySpeed)
        else
            flyBodyVelocity.Velocity = moveDir * flySpeed
        end
    end
end)

RunService.Stepped:Connect(function()
    if Toggles.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

CharacterTab:CreateToggle("強制第三人稱", false, function(state)
    if state then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 100
        LocalPlayer.CameraMinZoomDistance = 10
    else
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        LocalPlayer.CameraMaxZoomDistance = 0.5
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
end)

CharacterTab:CreateToggle("角色穿牆 (Noclip)", false, function(state)
    Toggles.Noclip = state
end)


-- 破解分頁
local ExploitTab = Window:CreateTab("破解")

ExploitTab:CreateButton("解鎖全造型 (本地視覺)", function()
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "提示",
            Text = "嘗試解鎖本地造型... (若無效代表伺服器已防護)",
            Duration = 3,
        })
    end)
end)

ExploitTab:CreateToggle("無限子彈 (嘗試Hook)", false, function(state)
    Toggles.InfiniteAmmo = state
end)

ExploitTab:CreateToggle("自動回血", false, function(state)
    Toggles.AutoHeal = state
end)


-- 雜項分頁
local MiscTab = Window:CreateTab("雜項")

MiscTab:CreateButton("強制關閉腳本", function()
    local gui = CoreGui:FindFirstChild("ZRNHub_Rivals") or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ZRNHub_Rivals")
    if gui then gui:Destroy() end
    if FOVCircle then FOVCircle:Remove() end
end)

-- 播放歡迎動畫
task.spawn(function()
    Window:PlayIntro()
end)

-- 載入完成提示
task.spawn(function()
    task.wait(3.5) -- 等待動畫播完再發送通知
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "ZRN Hub",
            Text = "Rivals 版本載入成功！按 RightControl 隱藏介面。",
            Duration = 5,
        })
    end)
end)
