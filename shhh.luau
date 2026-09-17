-- LocalScript → put in StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local appliedCars = {} -- remembers which cars already have the effect

--------------------------------------------------------------------------------
-- 1. SET ROLEPLAY INFO AUTOMATICALLY ON EXECUTION (USES PLAYER'S ACTUAL NAME)
--------------------------------------------------------------------------------
local roleplayArgs = {
    {
        BackgroundStyle = "Cityline",
        HairColor = "Grey",
        EyeColor = "Green",
        HeightFeet = 5,
        Age = "Kid",
        Name = player.Name, -- Dynamically fetches their actual Roblox Username
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
        print("✅ Roleplay info updated for " .. player.Name .. " (Grey Hair & Kid Age).")
    else
        warn("❌ Could not find ChangeRoleplayInfo RemoteFunction.")
    end
end)

--------------------------------------------------------------------------------
-- 2. EFFECT HELPER FUNCTIONS
--------------------------------------------------------------------------------
local function addRainbow(part)
    if not part or not part:IsA("BasePart") then return end
    if part:GetAttribute("HasRainbow") then return end
    part:SetAttribute("HasRainbow", true)

    local hue = 0
    RunService.Heartbeat:Connect(function(dt)
        if not part or not part.Parent then return end
        hue = (hue + dt * 0.55) % 1
        part.Color = Color3.fromHSV(hue, 1, 1)
    end)
end

local function addParticles(part)
    if not part or not part:IsA("BasePart") then return end
    if part:GetAttribute("HasParticles") then return end
    part:SetAttribute("HasParticles", true)

    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("ParticleEmitter") then
            child:Destroy()
        end
    end

    -- Round soft balls
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
    balls.Lifetime = NumberRange.new(9, 12)
    balls.Rate = 55
    balls.Speed = NumberRange.new(0.5, 2)
    balls.SpreadAngle = Vector2.new(35, 35)
    balls.LightEmission = 1
    balls.LightInfluence = 0
    balls.Drag = 4.5
    balls.Acceleration = Vector3.new(0, 1.2, 0)
    balls.Parent = part

    -- Dense balls
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
    dense.Lifetime = NumberRange.new(8, 11)
    dense.Rate = 70
    dense.Speed = NumberRange.new(0.4, 1.6)
    dense.SpreadAngle = Vector2.new(45, 45)
    dense.LightEmission = 1
    dense.LightInfluence = 0
    dense.Drag = 5
    dense.Parent = part

    -- Firework bursts
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
    fireworks.Lifetime = NumberRange.new(6, 9)
    fireworks.Rate = 40
    fireworks.Speed = NumberRange.new(6, 13)
    fireworks.SpreadAngle = Vector2.new(180, 180)
    fireworks.LightEmission = 1
    fireworks.LightInfluence = 0
    fireworks.Drag = 2.5
    fireworks.Acceleration = Vector3.new(0, 4, 0)
    fireworks.Parent = part
end

local function applyToCar(car)
    if not car or appliedCars[car] then return end
    appliedCars[car] = true

    local body = car:FindFirstChild("Body")
    local wheels = car:FindFirstChild("Wheels")

    if body then
        addRainbow(body:FindFirstChild("RightBumper"))
        addRainbow(body:FindFirstChild("LeftBumper"))

        local children = body:GetChildren()
        if children[8] then addRainbow(children[8]) end
        if children[26] then addRainbow(children[26]) end

        -- Scans all body descendants and turns parts named "COLOR" rainbow
        for _, child in ipairs(body:GetDescendants()) do
            if child.Name == "COLOR" and child:IsA("BasePart") then
                addRainbow(child)
            end
        end

        addParticles(body:FindFirstChild("LeftBumper"))
        addParticles(body:FindFirstChild("RightBumper"))
    end

    if wheels then
        addParticles(wheels:FindFirstChild("RL"))
        addParticles(wheels:FindFirstChild("RR"))
    end

    print("✅ Rainbow & Sparkle applied to car:", car.Name)
end

--------------------------------------------------------------------------------
-- 3. DETECTION SYSTEM FOR SCRIPT USERS
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
        local hair = getValue(rpInfo, "HairColor")
        local age = getValue(rpInfo, "Age")

        if hair and age then
            local isGrey = (hair == "grey" or hair == "gray")
            local isKid = (age == "kid")
            if isGrey and isKid then
                return true
            end
        end
    end

    return false
end

-- Detects seats and updates cars for anyone running the Grey/Kid script
RunService.Heartbeat:Connect(function()
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then return end

    for _, car in ipairs(vehiclesFolder:GetChildren()) do
        if not appliedCars[car] then
            for _, desc in ipairs(car:GetDescendants()) do
                if desc:IsA("VehicleSeat") or desc:IsA("Seat") then
                    local occupant = desc.Occupant
                    if occupant and occupant:IsA("Humanoid") and occupant.Parent then
                        local driverPlayer = Players:GetPlayerFromCharacter(occupant.Parent)
                        if driverPlayer and isScriptUser(driverPlayer) then
                            applyToCar(car)
                            break
                        end
                    end
                end
            end
        end
    end
end)

print("Script ready — automatically using player username, updating RP info, and scanning vehicles.")
