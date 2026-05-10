--[[
    PONY - 通用 FPS 優化腳本 (FPS Booster)
    功能：極致降低畫質、移除光影、材質與粒子，大幅提升幀數
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

-- 1. 優化 Lighting (光影與後處理)
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 1

for _, effect in pairs(Lighting:GetChildren()) do
    if effect:IsA("PostEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
        effect:Destroy()
    end
end

-- 2. 優化 Terrain (地形與水面)
if Terrain then
    pcall(function()
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
        Terrain.Decoration = false -- 關閉草地 (使用 pcall 避免報錯)
        Terrain.Lighting = false
        Terrain.MaterialColors = {}
    end)
end

-- 3. 遞迴優化所有物件 (材質、特效、貼圖)
local function optimizeObject(obj)
    -- 更改所有實體的材質為平滑塑膠，並關閉投影
    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
        obj.CastShadow = false
    end
    
    -- 移除特效與粒子
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        obj.Enabled = false
    end
    
    -- 移除貼圖
    if obj:IsA("Decal") or obj:IsA("Texture") then
        obj.Transparency = 1
    end
    
    -- 移除網格細節 (可選，這裡僅針對非角色模型)
    if obj:IsA("MeshPart") then
        obj.RenderFidelity = Enum.RenderFidelity.Performance
    end
end

-- 掃描 Workspace 中所有現有物件
for _, obj in pairs(Workspace:GetDescendants()) do
    optimizeObject(obj)
end

-- 監聽未來新生成的物件並即時優化
Workspace.DescendantAdded:Connect(function(obj)
    -- 使用 task.defer 避免卡頓
    task.defer(function()
        optimizeObject(obj)
    end)
end)

-- 優化設定 (針對有權限的 Executor)
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

-- 完成通知
pcall(function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "PONY FPS Booster",
        Text = "FPS 最大化",
        Duration = 5,
    })
end)
