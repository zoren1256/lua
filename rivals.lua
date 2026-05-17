--[[
    PONY - Rivals 專屬版本
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

--------------------------------------------------------------------------------
-- PONY - Key System (Minimalist & Auto-Login)
--------------------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local isVerified = false
local globalExpireTime = nil
local savedKeyFile = "PONY_Key.txt"
local adLink = "https://zoren.org/generate" 
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

-- 驗證函數 (後台)
local function VerifyKey(key)
    local success, response = pcall(function()
        return game:HttpGet("https://zoren.org/verify?key=" .. key .. "&hwid=" .. hwid)
    end)
    if success then
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
        if decodeSuccess and data.success then
            return true, data.expires_at_unix, data.script
        end
    end
    return false, nil, nil
end

-- 自動登入邏輯
if readfile and isfile and isfile(savedKeyFile) then
    local savedKey = readfile(savedKeyFile)
    local valid, expireTime, scriptPayload = VerifyKey(savedKey)
    if valid then
        isVerified = true
        globalExpireTime = expireTime
        
        -- 執行伺服器下發的腳本載荷
        if loadstring then
            task.spawn(function()
                local func, err = loadstring(scriptPayload)
                if func then func() else warn("PONY: 腳本載入失敗: " .. tostring(err)) end
            end)
        else
            warn("您的執行器不支援 loadstring，無法啟動腳本！")
        end
    else
        -- Key 過期或無效，自動刪除本地檔案
        if delfile then
            pcall(function() delfile(savedKeyFile) end)
        end
    end
end

-- 如果自動登入失敗或沒存過，顯示極簡 UI
if not isVerified then
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "PONY_KeySystem_" .. tostring(math.random(1000, 9999))
    KeyGui.Parent = CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyGui.IgnoreGuiInset = true

    -- 極簡黑底
    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Background.BackgroundTransparency = 0.2
    Background.Parent = KeyGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 350, 0, 200)
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -100)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.BorderSizePixel = 1
    MainFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.Parent = KeyGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1
    Title.Text = "PONY 驗證系統"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = MainFrame

    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(0, 310, 0, 35)
    KeyInput.Position = UDim2.new(0.5, -155, 0, 50)
    KeyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    KeyInput.TextColor3 = Color3.fromRGB(200, 200, 200)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.TextSize = 14
    KeyInput.PlaceholderText = "輸入您的 Key"
    KeyInput.Text = ""
    KeyInput.Parent = MainFrame
    Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 4)

    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Size = UDim2.new(0, 310, 0, 35)
    VerifyBtn.Position = UDim2.new(0.5, -155, 0, 95)
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    VerifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    VerifyBtn.Font = Enum.Font.GothamBold
    VerifyBtn.TextSize = 14
    VerifyBtn.Text = "驗證解鎖"
    VerifyBtn.Parent = MainFrame
    Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 4)

    -- 底部網址與 Copy 按鈕區域
    local LinkFrame = Instance.new("Frame")
    LinkFrame.Size = UDim2.new(0, 310, 0, 30)
    LinkFrame.Position = UDim2.new(0.5, -155, 0, 150)
    LinkFrame.BackgroundTransparency = 1
    LinkFrame.Parent = MainFrame

    local LinkText = Instance.new("TextBox")
    LinkText.Size = UDim2.new(0, 230, 1, 0)
    LinkText.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    LinkText.TextColor3 = Color3.fromRGB(150, 150, 150)
    LinkText.Font = Enum.Font.Gotham
    LinkText.TextSize = 12
    LinkText.Text = adLink
    LinkText.TextEditable = false
    LinkText.ClearTextOnFocus = false
    LinkText.Parent = LinkFrame
    Instance.new("UICorner", LinkText).CornerRadius = UDim.new(0, 4)

    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(0, 70, 1, 0)
    CopyBtn.Position = UDim2.new(1, -70, 0, 0)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.Font = Enum.Font.Gotham
    CopyBtn.TextSize = 12
    CopyBtn.Text = "複製網址"
    CopyBtn.Parent = LinkFrame
    Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 4)

    -- 邏輯
    CopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(adLink)
            CopyBtn.Text = "已複製"
            task.wait(2)
            CopyBtn.Text = "複製網址"
        end
    end)

    VerifyBtn.MouseButton1Click:Connect(function()
        local key = KeyInput.Text
        if key == "" then return end
        
        VerifyBtn.Text = "驗證中..."
        local valid, expireTime, scriptPayload = VerifyKey(key)
        
        if valid then
            VerifyBtn.Text = "驗證成功"
            VerifyBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            if writefile then
                pcall(function() writefile(savedKeyFile, key) end)
            end
            globalExpireTime = expireTime
            
            -- 執行伺服器下發的腳本載荷
            if loadstring then
                task.spawn(function()
                    local func, err = loadstring(scriptPayload)
                    if func then func() else warn("腳本載入失敗: " .. tostring(err)) end
                end)
            else
                warn("您的執行器不支援 loadstring，無法啟動腳本！")
            end
            
            task.wait(1)
            isVerified = true
            KeyGui:Destroy()
        else
            VerifyBtn.Text = "無效或過期"
            VerifyBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            task.wait(1.5)
            VerifyBtn.Text = "驗證解鎖"
            VerifyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)

    repeat task.wait(0.1) until isVerified
end

-- 創建右上角計時器
if globalExpireTime then
    local TimerGui = Instance.new("ScreenGui")
    TimerGui.Name = "PONY_TimerUI"
    TimerGui.Parent = CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")
    TimerGui.ResetOnSpawn = false
    TimerGui.IgnoreGuiInset = true

    local TimerFrame = Instance.new("Frame")
    TimerFrame.Size = UDim2.new(0, 120, 0, 26)
    TimerFrame.Position = UDim2.new(1, -130, 0, 10)
    TimerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TimerFrame.BackgroundTransparency = 0.3
    TimerFrame.BorderSizePixel = 1
    TimerFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    TimerFrame.Parent = TimerGui
    Instance.new("UICorner", TimerFrame).CornerRadius = UDim.new(0, 4)

    local TimerText = Instance.new("TextLabel")
    TimerText.Size = UDim2.new(1, 0, 1, 0)
    TimerText.BackgroundTransparency = 1
    TimerText.Text = "載入中..."
    TimerText.TextColor3 = Color3.fromRGB(200, 200, 200)
    TimerText.Font = Enum.Font.Gotham
    TimerText.TextSize = 12
    TimerText.Parent = TimerFrame

    task.spawn(function()
        while task.wait(1) do
            local currentUnix = math.floor(os.time())
            local diff = globalExpireTime - currentUnix
            if diff <= 0 then
                TimerText.Text = "Key 已過期"
                TimerText.TextColor3 = Color3.fromRGB(255, 100, 100)
                break
            end
            
            local d = math.floor(diff / 86400)
            local h = math.floor((diff % 86400) / 3600)
            local m = math.floor((diff % 3600) / 60)
            
            local timeStr = ""
            if d > 0 then timeStr = timeStr .. d .. "d " end
            if h > 0 or d > 0 then timeStr = timeStr .. h .. "h " end
            timeStr = timeStr .. m .. "m"
            
            TimerText.Text = "PONY: " .. timeStr
        end
    end)
end
--------------------------------------------------------------------------------
