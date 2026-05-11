--[[
    PONY - FPS Booster (引擎級效能解鎖)
    直接從 Roblox 引擎內部提升幀數，而非單純移除材質
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local CoreGui
pcall(function() CoreGui = game:GetService("CoreGui") end)

-- ═══════════════════════════════════════════════════
-- 1. FPS 解鎖 (移除 60fps 上限)
-- ═══════════════════════════════════════════════════
-- 透過 setfpscap 直接解除 Roblox 的幀率鎖定
pcall(function()
    if setfpscap then
        setfpscap(0) -- 0 = 無上限，讓顯示卡全力輸出
    end
end)

-- ═══════════════════════════════════════════════════
-- 2. 物理引擎節流 (Physics Throttle)
-- ═══════════════════════════════════════════════════
-- 降低物理模擬的更新頻率，大幅減少 CPU 負擔
pcall(function()
    settings().Physics.ThrottleAdjustTime = math.huge
    settings().Physics.AllowSleep = true
    settings().Physics.ForceCSGv2 = false
    settings().Physics.DisableCSGv2 = true
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
end)

-- ═══════════════════════════════════════════════════
-- 3. 渲染引擎降負 (Render Throttle)
-- ═══════════════════════════════════════════════════
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04 -- 最低細節
    settings().Rendering.EagerBulkExecution = true
end)

-- ═══════════════════════════════════════════════════
-- 4. 網路優化 (Network Optimization)
-- ═══════════════════════════════════════════════════
-- 降低網路接收的頻率與數據量
pcall(function()
    settings().Network.IncomingReplicationLag = 0
    settings().Network.NetworkOwnerRate = 60
end)

-- ═══════════════════════════════════════════════════
-- 5. 記憶體與垃圾回收 (GC Optimization)
-- ═══════════════════════════════════════════════════
-- 手動控制 Lua 垃圾回收器，避免它在戰鬥時突然觸發導致卡頓
pcall(function()
    -- 將 GC 步進放大，讓它每次觸發時一次性清理更多，但觸發頻率降低
    collectgarbage("setpause", 200)
    collectgarbage("setstepmul", 400)
end)

-- ═══════════════════════════════════════════════════
-- 6. 實例串流距離 (Instance Streaming)
-- ═══════════════════════════════════════════════════
-- 縮短客戶端載入遊戲物件的半徑，減少同時渲染的物件數量
pcall(function()
    if Workspace.StreamingEnabled then
        Workspace.StreamingMinRadius = 64
        Workspace.StreamingTargetRadius = 128
    end
end)

-- ═══════════════════════════════════════════════════
-- 7. 光影與後處理引擎級關閉
-- ═══════════════════════════════════════════════════
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- 8. 強制關閉所有物件的陰影投射
-- ═══════════════════════════════════════════════════
local function killShadow(obj)
    if obj:IsA("BasePart") then
        obj.CastShadow = false
    end
end

for _, obj in pairs(Workspace:GetDescendants()) do
    pcall(killShadow, obj)
end

Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        pcall(killShadow, obj)
    end)
end)

-- ═══════════════════════════════════════════════════
-- 9. 右上角 FPS 顯示器
-- ═══════════════════════════════════════════════════
local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "PonyFPSCounter"
fpsGui.ResetOnSpawn = false
pcall(function() fpsGui.Parent = CoreGui end)
if fpsGui.Parent == nil then
    fpsGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 100, 0, 30)
fpsLabel.Position = UDim2.new(1, -110, 0, 10)
fpsLabel.BackgroundTransparency = 0.5
fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fpsLabel.TextColor3 = Color3.fromRGB(147, 51, 234)
fpsLabel.Font = Enum.Font.Code
fpsLabel.TextSize = 18
fpsLabel.TextStrokeTransparency = 0
fpsLabel.Text = "FPS: --"
fpsLabel.Parent = fpsGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 4)
uiCorner.Parent = fpsLabel

local frames = 0
local lastUpdate = tick()

RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - lastUpdate >= 1 then
        fpsLabel.Text = "FPS: " .. tostring(math.floor(frames / (now - lastUpdate)))
        frames = 0
        lastUpdate = now
    end
end)

-- ═══════════════════════════════════════════════════
-- 完成通知
-- ═══════════════════════════════════════════════════
pcall(function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "PONY FPS Booster",
        Text = "引擎級效能解鎖完成",
        Duration = 5,
    })
end)
