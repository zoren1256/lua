--[[
    PONY - FPS Booster (馬鈴薯電腦終極版)
    注入即啟動，無開關，極致引擎級優化
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- 1. 解鎖 FPS
pcall(function() if setfpscap then setfpscap(999) end end)

-- 2. 核心引擎參數 (極速模式)
local settings = settings()
settings.Rendering.QualityLevel = Enum.QualityLevel.Level01
settings.Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
settings.Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
settings.Physics.AllowSleep = true

-- 3. 暴力移除資源 (直接銷毀以釋放顯存)
local function kill(obj)
    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
        obj.CastShadow = false
    elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("Sky") or obj:IsA("Clouds") or obj:IsA("Atmosphere") then
        obj:Destroy()
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
        obj:Destroy()
    elseif obj:IsA("PostEffect") then
        obj.Enabled = false
    end
end

task.spawn(function()
    for _, obj in pairs(game:GetDescendants()) do
        pcall(kill, obj)
    end
end)

game.DescendantAdded:Connect(function(obj)
    pcall(kill, obj)
end)

-- 4. 降低 Terrain 渲染
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
if Terrain then
    pcall(function()
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
        Terrain.Decoration = false
    end)
end

-- 5. 右上角 FPS 顯示器
local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "PonyFPSCounter"
fpsGui.ResetOnSpawn = false
pcall(function() fpsGui.Parent = game:GetService("CoreGui") end)
if fpsGui.Parent == nil then fpsGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 100, 0, 30)
fpsLabel.Position = UDim2.new(1, -110, 0, 10)
fpsLabel.BackgroundTransparency = 1
fpsLabel.TextColor3 = Color3.fromRGB(147, 51, 234)
fpsLabel.Font = Enum.Font.Code
fpsLabel.TextSize = 20
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Text = "FPS: --"
fpsLabel.Parent = fpsGui

local frames = 0
local lastUpdate = tick()
RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - lastUpdate >= 1 then
        fpsLabel.Text = "FPS: " .. math.floor(frames / (now - lastUpdate))
        frames = 0
        lastUpdate = now
    end
end)

game.StarterGui:SetCore("SendNotification", {
    Title = "PONY FPS Booster",
    Text = "已優化",
    Duration = 5,
})
