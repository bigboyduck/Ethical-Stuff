-- Wait for WindUI framework
repeat task.wait() until _G.WindUI and _G.Functions and _G.RanERX

local WindUI = _G.WindUI
local Window = _G.Window
local Connections = _G.Connections
local Functions = _G.Functions

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local appliedCars = {}

--------------------------------------------------------------------------------
-- SCRIPT CONFIGURATION & CONTROL STATE
--------------------------------------------------------------------------------
local Config = {
    Enabled = true,
    RainbowSpeed = 0.55,
    SyncWithOthers = true,
    
    -- Individual Emitter Toggles
    EnableRoundBalls = true,
    EnableDenseBalls = true,
    EnableFireworks = true,
    
    -- Particle Settings Multipliers
    ParticleRate = 55,
    ParticleSpeed = 1.0,
    ParticleLifetime = 1.0,
}

-- Persistent configuration
local ConfigFolder = "ERX"
local ConfigFile = ConfigFolder .. "/SparkleRainbow.json"
local HttpService = game:GetService("HttpService")

local function loadSavedConfig()
    if not (readfile and isfile) then return end

    pcall(function()
        if not isfile(ConfigFile) then return end
        local data = HttpService:JSONDecode(readfile(ConfigFile))
        if type(data) ~= "table" then return end

        if type(data.Enabled) == "boolean" then Config.Enabled = data.Enabled end
        if type(data.EnableRoundBalls) == "boolean" then Config.EnableRoundBalls = data.EnableRoundBalls end
        if type(data.EnableDenseBalls) == "boolean" then Config.EnableDenseBalls = data.EnableDenseBalls end
        if type(data.EnableFireworks) == "boolean" then Config.EnableFireworks = data.EnableFireworks end
        if tonumber(data.RainbowSpeed) then Config.RainbowSpeed = math.clamp(tonumber(data.RainbowSpeed), 0.1, 2) end
        if type(data.SyncWithOthers) == "boolean" then Config.SyncWithOthers = data.SyncWithOthers end
        if tonumber(data.ParticleRate) then Config.ParticleRate = math.clamp(tonumber(data.ParticleRate), 10, 150) end
        if tonumber(data.ParticleSpeed) then Config.ParticleSpeed = math.clamp(tonumber(data.ParticleSpeed), 0.1, 5) end
        if tonumber(data.ParticleLifetime) then Config.ParticleLifetime = math.clamp(tonumber(data.ParticleLifetime), 0.1, 3) end
    end)
end

local function saveConfig()
    if not writefile then return false, "writefile is not available" end

    local ok, err = pcall(function()
        if makefolder and isfolder and not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end

        writefile(ConfigFile, HttpService:JSONEncode({
            Enabled = Config.Enabled,
            EnableRoundBalls = Config.EnableRoundBalls,
            EnableDenseBalls = Config.EnableDenseBalls,
            EnableFireworks = Config.EnableFireworks,
            RainbowSpeed = Config.RainbowSpeed,
            SyncWithOthers = Config.SyncWithOthers,
            ParticleRate = Config.ParticleRate,
            ParticleSpeed = Config.ParticleSpeed,
            ParticleLifetime = Config.ParticleLifetime,
        }))
    end)

    return ok, err
end

loadSavedConfig()

--------------------------------------------------------------------------------
-- 1. SET ROLEPLAY INFO AUTOMATICALLY
--------------------------------------------------------------------------------
local function applyRoleplayInfo()
    local roleplayArgs = {
        {
            BackgroundStyle = "Cityline",
            HairColor = "Brown",
            EyeColor = "Green",
            HeightFeet = 5,
            Age = "Kid",
            Name = player.Name,
            Weight = 187,
            HeightInches = 2,
            License = "Active",
            Gender = "Other"
        }
    }

    task.spawn(function()
        local changeRPInfoRemote = ReplicatedStorage:WaitForChild("FE", 10):WaitForChild("ChangeRoleplayInfo", 10)
        if changeRPInfoRemote then
            changeRPInfoRemote:InvokeServer(unpack(roleplayArgs))
        end
    end)
end

applyRoleplayInfo()

--------------------------------------------------------------------------------
-- 2. OPTIMIZED EFFECTS SYSTEM WITH DYNAMIC EMITTER TOGGLES
--------------------------------------------------------------------------------
local activeRainbowParts = {}
local activeEmitters = {}
local GlobalHue = 0

RunService.Heartbeat:Connect(function(dt)
    if not Config.Enabled then return end

    if Config.SyncWithOthers and workspace.GetServerTimeNow then
        GlobalHue = (workspace:GetServerTimeNow() * Config.RainbowSpeed) % 1
    else
        GlobalHue = (GlobalHue + dt * Config.RainbowSpeed) % 1
    end

    local rainbowColor = Color3.fromHSV(GlobalHue, 1, 1)

    for part in pairs(activeRainbowParts) do
        if part and part.Parent and part:IsA("BasePart") then
            part.Color = rainbowColor
        else
            activeRainbowParts[part] = nil
        end
    end
end)

local function updateActiveEmitters()
    for emitterData in pairs(activeEmitters) do
        local emitter = emitterData.Emitter
        local emitterType = emitterData.Type
        local baseRate = emitterData.BaseRate
        local baseMinSpeed = emitterData.BaseMinSpeed
        local baseMaxSpeed = emitterData.BaseMaxSpeed
        local baseMinLife = emitterData.BaseMinLife
        local baseMaxLife = emitterData.BaseMaxLife

        if emitter and emitter.Parent and emitter:IsA("ParticleEmitter") then
            local isTypeEnabled = true
            if emitterType == "RoundBalls" then
                isTypeEnabled = Config.EnableRoundBalls
            elseif emitterType == "DenseBalls" then
                isTypeEnabled = Config.EnableDenseBalls
            elseif emitterType == "Fireworks" then
                isTypeEnabled = Config.EnableFireworks
            end

            emitter.Enabled = Config.Enabled and isTypeEnabled
            emitter.Rate = (baseRate / 55) * Config.ParticleRate
            emitter.Speed = NumberRange.new(
                math.max(0.05, baseMinSpeed * Config.ParticleSpeed),
                math.max(0.05, baseMaxSpeed * Config.ParticleSpeed)
            )
            emitter.Lifetime = NumberRange.new(
                math.max(0.1, baseMinLife * Config.ParticleLifetime),
                math.max(0.1, baseMaxLife * Config.ParticleLifetime)
            )
        else
            activeEmitters[emitterData] = nil
        end
    end
end

local function addRainbow(target)
    if not target then return end
    
    if target:IsA("BasePart") then
        activeRainbowParts[target] = true
    elseif target:IsA("Model") or target:IsA("Folder") then
        for _, desc in ipairs(target:GetDescendants()) do
            if desc:IsA("BasePart") then
                activeRainbowParts[desc] = true
            end
        end
    end
end

local function attachParticleToPart(targetPart)
    if not targetPart or not targetPart:IsA("BasePart") then return end
    if targetPart:GetAttribute("HasParticlesAttached") then return end
    targetPart:SetAttribute("HasParticlesAttached", true)

    -- 1. Round Soft Balls Emitter
    local balls = Instance.new("ParticleEmitter")
    balls.Name = "RoundBalls"
    balls.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 40, 40)),
        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 140, 0)),
        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 120)),
        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 160, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(200, 0, 255)),
    })
    balls.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.4),
        NumberSequenceKeypoint.new(0.4, 2.8),
        NumberSequenceKeypoint.new(1, 0)
    })
    balls.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.7, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    balls.SpreadAngle = Vector2.new(35, 35)
    balls.LightEmission = 1
    balls.LightInfluence = 0
    balls.Drag = 4.5
    balls.Acceleration = Vector3.new(0, 1.2, 0)
    balls.Parent = targetPart

    activeEmitters[{
        Emitter = balls,
        Type = "RoundBalls",
        BaseRate = 55,
        BaseMinSpeed = 0.5,
        BaseMaxSpeed = 2.0,
        BaseMinLife = 9,
        BaseMaxLife = 12
    }] = true

    -- 2. Dense Balls Emitter
    local dense = Instance.new("ParticleEmitter")
    dense.Name = "DenseBalls"
    dense.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 255, 255)),
    })
    dense.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.4, 1.8),
        NumberSequenceKeypoint.new(1, 0)
    })
    dense.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.75, 0.35),
        NumberSequenceKeypoint.new(1, 1)
    })
    dense.SpreadAngle = Vector2.new(45, 45)
    dense.LightEmission = 1
    dense.LightInfluence = 0
    dense.Drag = 5
    dense.Parent = targetPart

    activeEmitters[{
        Emitter = dense,
        Type = "DenseBalls",
        BaseRate = 70,
        BaseMinSpeed = 0.4,
        BaseMaxSpeed = 1.6,
        BaseMinLife = 8,
        BaseMaxLife = 11
    }] = true

    -- 3. Fireworks Bursts Emitter
    local fireworks = Instance.new("ParticleEmitter")
    fireworks.Name = "Fireworks"
    fireworks.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 100)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 150, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 200)),
    })
    fireworks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(0.3, 2.3),
        NumberSequenceKeypoint.new(1, 0)
    })
    fireworks.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.6, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
    fireworks.SpreadAngle = Vector2.new(180, 180)
    fireworks.LightEmission = 1
    fireworks.LightInfluence = 0
    fireworks.Drag = 2.5
    fireworks.Acceleration = Vector3.new(0, 4, 0)
    fireworks.Parent = targetPart

    activeEmitters[{
        Emitter = fireworks,
        Type = "Fireworks",
        BaseRate = 40,
        BaseMinSpeed = 6.0,
        BaseMaxSpeed = 13.0,
        BaseMinLife = 6,
        BaseMaxLife = 9
    }] = true

    updateActiveEmitters()
end

local function addParticles(target)
    if not target then return end
    
    if target:IsA("BasePart") then
        attachParticleToPart(target)
    elseif target:IsA("Model") or target:IsA("Folder") then
        for _, desc in ipairs(target:GetDescendants()) do
            if desc:IsA("BasePart") then
                attachParticleToPart(desc)
            end
        end
    end
end

local function applyToCar(car)
    if not car or not Config.Enabled then return end
    appliedCars[car] = true

    local body = car:FindFirstChild("Body")
    local wheels = car:FindFirstChild("Wheels")

    if body then
        local rightBumper = body:FindFirstChild("RightBumper")
        local leftBumper = body:FindFirstChild("LeftBumper")

        if rightBumper then
            addRainbow(rightBumper)
            addParticles(rightBumper)
        end

        if leftBumper then
            addRainbow(leftBumper)
            addParticles(leftBumper)
        end

        local children = body:GetChildren()
        if children[8] then addRainbow(children[8]) end

        for _, child in ipairs(body:GetDescendants()) do
            if child.Name == "COLOR" then
                addRainbow(child)
            end
        end
    end

    if wheels then
        addParticles(wheels:FindFirstChild("RL"))
        addParticles(wheels:FindFirstChild("RR"))
    end
end

local function refreshAllCars()
    if not Config.Enabled then
        updateActiveEmitters()
        return
    end

    for car in pairs(appliedCars) do
        if car and car.Parent then
            applyToCar(car)
        else
            appliedCars[car] = nil
        end
    end

    updateActiveEmitters()
end

--------------------------------------------------------------------------------
-- 3. DETECTION & SYNC SYSTEM
--------------------------------------------------------------------------------
local function isScriptUser(targetPlayer)
    if not targetPlayer then return false end
    if targetPlayer == player then return true end

    local function getValue(container, key)
        if not container then return nil end
        local child = container:FindFirstChild(key)
        if child then
            if child:IsA("ValueBase") then return tostring(child.Value):lower() end
            return tostring(child):lower()
        end
        local attr = container:GetAttribute(key)
        if attr then return tostring(attr):lower() end
        return nil
    end

    local rpInfo = targetPlayer:FindFirstChild("RoleplayInfo") or (targetPlayer.Character and targetPlayer.Character:FindFirstChild("RoleplayInfo"))
    if rpInfo then
        local age = getValue(rpInfo, "Age")
        local weight = getValue(rpInfo, "Weight")
        if age == "kid" and weight == "187" then
            return true
        end
    end
    return false
end

local function scanForCars()
    if not Config.Enabled then return end

    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return end

    for _, car in ipairs(vehiclesFolder:GetChildren()) do
        if not appliedCars[car] then
            for _, desc in ipairs(car:GetDescendants()) do
                if desc:IsA("VehicleSeat") or desc:IsA("Seat") then
                    local occupant = desc.Occupant

                    if occupant and occupant:IsA("Humanoid") and occupant.Parent then
                        local driver = Players:GetPlayerFromCharacter(occupant.Parent)

                        if driver and isScriptUser(driver) then
                            applyToCar(car)
                            break
                        end
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        scanForCars()
    end
end)

--------------------------------------------------------------------------------
-- 4. WINDUI TAB CREATION & ELEMENT BINDING
--------------------------------------------------------------------------------
if not Window then
    error("Window object not found! Make sure WindUI is properly initialized.")
end

local VehicleTab
if Window.Tab then
    VehicleTab = Window:Tab({ Title = "Sparkle Rainbow", Icon = "car" })
elseif Window.CreateTab then
    VehicleTab = Window:CreateTab({ Title = "Sparkle Rainbow", Icon = "car" })
else
    error("Window does not have Tab or CreateTab method!")
end

if not VehicleTab then
    error("Failed to create VehicleTab!")
end

VehicleTab:Section({ Title = "Car Effects Toggle" })

VehicleTab:Toggle({
    Title = "Enable Sparkle & Rainbow",
    Value = Config.Enabled,
    Flag = "SparkleEnabled",
    Callback = function(Val)
        Config.Enabled = Val == true

        if Config.Enabled then
            scanForCars()
            refreshAllCars()
        else
            activeRainbowParts = {}
            updateActiveEmitters()
        end
    end,
})

VehicleTab:Toggle({
    Title = "Sync Effects With Other Users",
    Desc = "Synchronizes rainbow phase using the Roblox server clock",
    Value = Config.SyncWithOthers,
    Flag = "SparkleSync",
    Callback = function(Val)
        Config.SyncWithOthers = Val == true
        if Config.SyncWithOthers and workspace.GetServerTimeNow then
            GlobalHue = (workspace:GetServerTimeNow() * Config.RainbowSpeed) % 1
        end
    end,
})

VehicleTab:Button({
    Title = "Save Config",
    Desc = "Saves settings for the next time you run the script",
    Callback = function()
        local ok, err = saveConfig()
        WindUI:Notify({
            Title = ok and "Config Saved" or "Config Error",
            Content = ok and "Your settings were saved." or tostring(err or "Could not save config."),
            Duration = 3,
        })
    end,
})

VehicleTab:Section({ Title = "Particle Selection" })

VehicleTab:Toggle({
    Title = "Round Balls Particles",
    Value = Config.EnableRoundBalls,
    Flag = "EnableRoundBalls",
    Callback = function(Val)
        Config.EnableRoundBalls = Val == true
        updateActiveEmitters()
    end,
})

VehicleTab:Toggle({
    Title = "Dense Balls Particles",
    Value = Config.EnableDenseBalls,
    Flag = "EnableDenseBalls",
    Callback = function(Val)
        Config.EnableDenseBalls = Val == true
        updateActiveEmitters()
    end,
})

VehicleTab:Toggle({
    Title = "Fireworks Particles",
    Value = Config.EnableFireworks,
    Flag = "EnableFireworks",
    Callback = function(Val)
        Config.EnableFireworks = Val == true
        updateActiveEmitters()
    end,
})

VehicleTab:Section({ Title = "Rainbow Controls" })

VehicleTab:Slider({
    Title = "Rainbow Cycle Speed",
    Value = {
        Min = 0.1,
        Max = 2.0,
        Default = Config.RainbowSpeed,
    },
    Step = 0.05,
    Flag = "RainbowSpeed",
    Callback = function(Val)
        local n = tonumber(Val)
        if not n then return end
        Config.RainbowSpeed = math.clamp(n, 0.1, 2.0)
        if Config.SyncWithOthers and workspace.GetServerTimeNow then
            GlobalHue = (workspace:GetServerTimeNow() * Config.RainbowSpeed) % 1
        end
    end,
})

VehicleTab:Section({ Title = "Particle Controls" })

VehicleTab:Slider({
    Title = "Particle Emission Rate",
    Value = {
        Min = 10,
        Max = 150,
        Default = Config.ParticleRate,
    },
    Step = 5,
    Flag = "ParticleRate",
    Callback = function(Val)
        local n = tonumber(Val)
        if not n then return end
        Config.ParticleRate = math.clamp(n, 10, 150)
        updateActiveEmitters()
    end,
})

VehicleTab:Slider({
    Title = "Particle Speed Multiplier",
    Value = {
        Min = 0.1,
        Max = 3.0,
        Default = Config.ParticleSpeed,
    },
    Step = 0.1,
    Flag = "ParticleSpeed",
    Callback = function(Val)
        local n = tonumber(Val)
        if not n then return end
        Config.ParticleSpeed = math.clamp(n, 0.1, 3.0)
        updateActiveEmitters()
    end,
})

VehicleTab:Slider({
    Title = "Particle Lifetime Multiplier",
    Value = {
        Min = 0.1,
        Max = 3.0,
        Default = Config.ParticleLifetime,
    },
    Step = 0.1,
    Flag = "ParticleLifetime",
    Callback = function(Val)
        local n = tonumber(Val)
        if not n then return end
        Config.ParticleLifetime = math.clamp(n, 0.1, 3.0)
        updateActiveEmitters()
    end,
})

WindUI:Notify({
    Title = "ERLCXploit",
    Content = "Loaded Sparkly Rainbow car",
    Duration = 5,
})
