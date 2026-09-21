local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local FindFirstChild = game.FindFirstChild
local FindChildOfClass = game.FindFirstChildOfClass
local InstanceNew = Instance.new

local LocalPlayer = Players.LocalPlayer

local function WaitForChildContinue(parent, name, timeout)
    if not parent then
        return nil
    end
    return parent:WaitForChild(name, timeout or 5)
end

local Killers = WaitForChildContinue(Workspace, "Killers", 5)
local RemoteEvents = WaitForChildContinue(ReplicatedStorage, "Remote Events", 5)
local reloadEvent = WaitForChildContinue(RemoteEvents, "Reload", 5)
local WeaponModule = WaitForChildContinue(ReplicatedStorage, "Weapon", 5)

local KILLER_COLOR = Color3.fromRGB(255, 100, 100)
local PLAYER_COLOR = Color3.fromRGB(255, 255, 255)
local pacotesClonados = {}
local trackedKillers = {}
local limitePenteArmaAtual = 30
local executandoRecarga = false

local Config = {
    InfAmmo = false,
    InfAmmo2 = false,
    NoRecoil = false,
    NoSpread = false,
    FireRate2x = false,
    NoBolt = false,

    KillerESP = false,
    PlayerESP = false,
    WeaponESP = false,
    ESPName = false,
    NoFog = false,

    NoKillBricks = false,

    NoBlockChat = false,
    MuteFireSound = false,

    SpeedBoost = false,
    BulletSpeed3x = false,
    BulletSpeedMultiplier = 3,
    Wallbang = false,

    KillerCameraAim = false,
    WallCheck = true,
    SpeedBoostAmount = 15,
    KillerAimPart = "Head",
    GunKillAura = false,
    NoclipDoors = false,
    KillerMoreDamage = false,
    KillAll = false,
    ProtectPlayer = false,
}


local WeaponPropertyBackup = {}
local AnimationModuleBackup = {}
local FireRateStatsBackup = setmetatable({}, {__mode = "k"})
local ChatStateBackup = nil

local function backupProperty(tbl, key)
    if not tbl or WeaponPropertyBackup[tbl] == nil then
        WeaponPropertyBackup[tbl] = {}
    end

    if WeaponPropertyBackup[tbl][key] == nil then
        WeaponPropertyBackup[tbl][key] = {
            Exists = tbl[key] ~= nil,
            Value = tbl[key]
        }
    end
end

local function setWeaponProperty(tbl, key, value)
    backupProperty(tbl, key)
    tbl[key] = value
end

local function restoreWeaponProperty(tbl, key)
    local backup = WeaponPropertyBackup[tbl]
    local data = backup and backup[key]

    if not data then
        return
    end

    if data.Exists then
        tbl[key] = data.Value
    else
        tbl[key] = nil
    end
end

local function applyWeaponToggles()
    if not WeaponModule or not WeaponModule:IsA("ModuleScript") then
        return
    end

    pcall(function()
        local t = require(WeaponModule)
        if typeof(t) ~= "table" then
            return
        end

        if Config.NoBolt then
            setWeaponProperty(t, "is_auto", true)
            setWeaponProperty(t, "bolt_fire", false)
            setWeaponProperty(t, "bolt_cancelled", true)
        else
            restoreWeaponProperty(t, "is_auto")
            restoreWeaponProperty(t, "bolt_fire")
            restoreWeaponProperty(t, "bolt_cancelled")
        end

        if Config.NoSpread then
            setWeaponProperty(t, "inaccuracy", 0)
        else
            restoreWeaponProperty(t, "inaccuracy")
        end

        local recoilKeys = {"recoil", "recoil_amount", "recoil_speed", "recoil_return"}
        for _, key in ipairs(recoilKeys) do
            if Config.NoRecoil then
                setWeaponProperty(t, key, 0)
            else
                restoreWeaponProperty(t, key)
            end
        end

        if Config.InfAmmo then
            setWeaponProperty(t, "ReloadTime", 0.001)
            setWeaponProperty(t, "reload_time", 0.001)
            setWeaponProperty(t, "reload_wait", newcclosure(function()
                return task.wait(0.001)
            end))
        else
            restoreWeaponProperty(t, "ReloadTime")
            restoreWeaponProperty(t, "reload_time")
            restoreWeaponProperty(t, "reload_wait")
        end
    end)
end

local function aplicarAnimacoesNoBolt()
    if not Config.NoBolt then
        return
    end

    if not WeaponModule then
        return
    end

    for _, desc in ipairs(WeaponModule:GetDescendants()) do
        if desc:IsA("ModuleScript") then
            local name = string.lower(desc.Name)
            if name == "reload" or name == "bolt" or (desc.Parent and desc.Parent.Name == "Animations") then
                pcall(function()
                    local t = require(desc)
                    if typeof(t) == "table" then
                        if not AnimationModuleBackup[t] then
                            local original = {}
                            for k, v in pairs(t) do
                                original[k] = v
                            end
                            AnimationModuleBackup[t] = original
                        end
                        for k in pairs(t) do
                            t[k] = nil
                        end
                    end
                end)
            end
        end
    end
end

local function restaurarAnimacoesNoBolt()
    for t, original in pairs(AnimationModuleBackup) do
        pcall(function()
            for k in pairs(t) do
                t[k] = nil
            end
            for k, v in pairs(original) do
                t[k] = v
            end
        end)
    end
    table.clear(AnimationModuleBackup)
end


local ALLOWED_WEAPON_MAPS = {
    [4678052190] = true,
    [1076129670] = true
}

local espArmasAutorizado = ALLOWED_WEAPON_MAPS[game.PlaceId] or false

local GREEN_WEAPONS = {
    ["RayGun"] = true,
    ["Crossbow"] = true,
    ["AWP"] = true
}

local WEAPON_CHECK_INTERVAL = 0.1
local nextWeaponCheck = 0
local criadosArmas = {}

if espArmasAutorizado then
    
else
    
end

local function matarSom(sound)
    if sound:IsA("Sound") and sound.Name == "AmmoReload" then
        pcall(function()
            sound.Volume = 0
            sound:Stop()

            sound.Changed:Connect(function()
                if sound.Volume > 0 then
                    sound.Volume = 0
                end

                if sound.Playing then
                    sound:Stop()
                end
            end)
        end)
    end
end

for _, desc in ipairs(SoundService:GetDescendants()) do
    matarSom(desc)
end

SoundService.DescendantAdded:Connect(matarSom)

local function forcarRecargaCobalt()
    if not Config.InfAmmo then
        return
    end

    if reloadEvent and firesignal and not executandoRecarga then
        executandoRecarga = true

        pcall(function()
            firesignal(reloadEvent.OnClientEvent)
        end)

        task.delay(0.1, function()
            executandoRecarga = false
        end)
    end
end





local function removerAnim(objeto)
    
    
    if Config.NoBolt then
        aplicarAnimacoesNoBolt()
    end
end

if WeaponModule then
    for _, desc in ipairs(WeaponModule:GetDescendants()) do
        removerAnim(desc)
    end

    WeaponModule.DescendantAdded:Connect(removerAnim)
end

local function injetarLeitor(objeto)
    if objeto:IsA("ModuleScript") then
        pcall(function()
            local t = require(objeto)

            if t and typeof(t) == "table" and t.get_stats then
                local old = t.get_stats

                t.get_stats = newcclosure(function(self, p3)
                    local orig = old(self, p3)

                    if orig and typeof(orig) == "table" then
                        if orig.ammo then
                            limitePenteArmaAtual = orig.ammo
                        end

                        if Config.FireRate2x then
                            
                            if not FireRateStatsBackup[orig] then
                                FireRateStatsBackup[orig] = {
                                    shoot_wait = orig.shoot_wait,
                                    fire_rate = orig.fire_rate
                                }
                            end

                            local backup = FireRateStatsBackup[orig]
                            if backup.shoot_wait ~= nil then
                                orig.shoot_wait = backup.shoot_wait / 2
                            end
                            if backup.fire_rate ~= nil then
                                orig.fire_rate = backup.fire_rate / 2
                            end
                        elseif FireRateStatsBackup[orig] then
                            local backup = FireRateStatsBackup[orig]
                            orig.shoot_wait = backup.shoot_wait
                            orig.fire_rate = backup.fire_rate
                            FireRateStatsBackup[orig] = nil
                        end
                    end

                    return orig
                end)
            end
        end)
    end
end

if WeaponModule then
    for _, filho in ipairs(WeaponModule:GetDescendants()) do
        injetarLeitor(filho)
    end

    WeaponModule.DescendantAdded:Connect(injetarLeitor)
end








local ammoGui = WaitForChildContinue(LocalPlayer:FindFirstChild("PlayerGui"), "Ammo", 5)
local ammoLeft = WaitForChildContinue(ammoGui, "AmmoLeft", 5)

if ammoLeft then
    ammoLeft.Changed:Connect(function()
    local currentAmmoGui = LocalPlayer:FindFirstChild("PlayerGui")
    local currentAmmo = currentAmmoGui and currentAmmoGui:FindFirstChild("Ammo")
    local ammoLeft = currentAmmo and currentAmmo:FindFirstChild("AmmoLeft")
    if not ammoLeft then
        return
    end
    local partes = string.split(ammoLeft.Text, "|")

    -- Inf Ammo 2: usa SOMENTE o segundo numero.
    -- Exemplos: 30|1, 15|1, 999|1 -> dispara o evento.
    -- O primeiro numero nao importa.
    if Config.InfAmmo2 then
        local segundoNumero = tonumber(string.match(partes[2] or "", "%d+"))

        if segundoNumero == 1 then
            forcarRecargaCobalt()
        end
    end

    -- Inf Ammo normal: usa o primeiro numero.
    if not Config.InfAmmo then
        return
    end

    if #partes >= 1 and partes[1] then
        local penteAtual = tonumber(string.match(partes[1], "%d+"))

        if penteAtual then
            if limitePenteArmaAtual > 1 then
                if penteAtual == 1 then
                    forcarRecargaCobalt()
                end
            elseif limitePenteArmaAtual == 1 then
                if penteAtual == 0 then
                    forcarRecargaCobalt()
                end
            end
        end
    end
    end)
end

local FogBackup = nil

local function applyNoFog()
    if Config.NoFog then
        if not FogBackup then
            FogBackup = {
                FogStart = Lighting.FogStart,
                FogEnd = Lighting.FogEnd,
                FogColor = Lighting.FogColor
            }
        end
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000
    else
        if FogBackup then
            Lighting.FogStart = FogBackup.FogStart
            Lighting.FogEnd = FogBackup.FogEnd
            Lighting.FogColor = FogBackup.FogColor
            FogBackup = nil
        end
    end
end

local function removeESPName(character)
    if not character then return end
    local label = character:FindFirstChild("ESPNameLabel")
    if label then
        label:Destroy()
    end
end

local function createESPName(character, text, color)
    if not character or not character.Parent or not text or text == "" then return end

    local root = character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChildWhichIsA("BasePart", true)

    if not root then return end

    local billboard = character:FindFirstChild("ESPNameLabel")
    if not billboard then
        billboard = InstanceNew("BillboardGui")
        billboard.Name = "ESPNameLabel"
        billboard.Size = UDim2.new(0, 80, 0, 20)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Adornee = root
        billboard.Parent = character

        local textLabel = InstanceNew("TextLabel")
        textLabel.Name = "Text"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextSize = 9
        textLabel.TextTransparency = 0.3
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextStrokeTransparency = 0.5
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Parent = billboard
    end

    billboard.Adornee = root
    local textLabel = billboard:FindFirstChild("Text")
    if textLabel and textLabel:IsA("TextLabel") then
        textLabel.Text = text
        textLabel.TextColor3 = color
    end
end

local function getKillerControllerDisplayName(killer)
    if not killer then return nil end

    local killerHumanoid = killer:FindFirstChildOfClass("Humanoid")
        or killer:FindFirstChild("Humanoid", true)

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("Camera") then
                    local subject = obj.CameraSubject
                    if subject == killer or subject == killerHumanoid or (subject and subject:IsDescendantOf(killer)) then
                        return player.DisplayName
                    end
                end
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Camera") then
            local subject = obj.CameraSubject
            if subject == killer or subject == killerHumanoid or (subject and subject:IsDescendantOf(killer)) then
                for _, player in ipairs(Players:GetPlayers()) do
                    if obj.Name == player.Name or obj.Name == player.DisplayName then
                        return player.DisplayName
                    end
                end
                local owner = obj:FindFirstChild("Player")
                    or obj:FindFirstChild("Owner")
                    or obj:FindFirstChild("Controller")

                if owner and owner:IsA("ObjectValue") and owner.Value and owner.Value:IsA("Player") then
                    return owner.Value.DisplayName
                end

                if owner and owner:IsA("StringValue") then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if owner.Value == player.Name or owner.Value == player.DisplayName then
                            return player.DisplayName
                        end
                    end
                end
            end
        end
    end

    return nil
end

local function getPlayerESPName(player)
    if not player or player == LocalPlayer then return nil end
    return player.DisplayName
end

local function isKillerControlledByLocalCamera(killer)
    local camera = Workspace.CurrentCamera
    if not camera or not killer then return false end

    local subject = camera.CameraSubject
    if not subject then return false end

    if subject == killer then
        return true
    end

    return subject:IsDescendantOf(killer)
end

local function removeHighlight(m)
    local h = m:FindFirstChild("EventHighlight")

    if h then
        h:Destroy()
    end
end

local function addHighlight(m)
    if not Config.KillerESP then
        return
    end

    if isKillerControlledByLocalCamera(m) then
        removeHighlight(m)
        removeESPName(m)
        return
    end

    if not m.Parent then
        return
    end

    local hum = m:FindFirstChildOfClass("Humanoid")
        or m:FindFirstChild("Humanoid", true)

    if not hum or hum.Health <= 0 then
        removeHighlight(m)
        return
    end

    local h = m:FindFirstChild("EventHighlight")

    if not h then
        h = Instance.new("Highlight")
        h.Name = "EventHighlight"
        h.Adornee = m
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = KILLER_COLOR
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = m
    end
end

local function setupKiller(k)
    if not k:IsA("Model") or trackedKillers[k] then
        return
    end

    local hum = k:FindFirstChildOfClass("Humanoid")
        or k:FindFirstChild("Humanoid", true)

    if not hum then
        task.delay(0.1, function()
            if k.Parent == Killers then
                setupKiller(k)
            end
        end)

        return
    end

    if hum.Health <= 0 then
        return
    end

    trackedKillers[k] = {
        last = k:GetPivot().Position,
        moved = false,
        dead = false,
        controllerName = nil,
        nextNameLookup = 0
    }

    hum.Died:Connect(function()
        removeHighlight(k)

        local d = trackedKillers[k]

        if d then
            d.dead = true
        end
    end)
end

for _, k in ipairs(Killers:GetChildren()) do
    setupKiller(k)
end

Killers.ChildAdded:Connect(function(k)
    task.defer(function()
        setupKiller(k)
    end)
end)

Killers.ChildRemoved:Connect(function(k)
    trackedKillers[k] = nil
    removeHighlight(k)
    removeESPName(k)
end)

local function aplicarEspJogador(p)
    if p == LocalPlayer then
        return
    end

    local function tratarChar(char)
        if not char then
            return
        end

        local hum = WaitForChildContinue(char, "Humanoid", 5)

        if not hum or hum.Health <= 0 then
            return
        end

        task.defer(function()
            if not Config.PlayerESP then
                return
            end

            local h = char:FindFirstChild("PlayerHighlight")

            if not h then
                h = InstanceNew("Highlight")
                h.Name = "PlayerHighlight"
                h.FillTransparency = 1
                h.OutlineTransparency = 0
                h.OutlineColor = PLAYER_COLOR
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = char
            end
        end)

        hum.Died:Connect(function()
            local h = char:FindFirstChild("PlayerHighlight")

            if h then
                h:Destroy()
            end
            removeESPName(char)
        end)
    end

    tratarChar(p.Character)
    p.CharacterAdded:Connect(function(char)
        tratarChar(char)
        task.defer(function()
            if Config.PlayerESP and Config.ESPName and p ~= LocalPlayer and char.Parent then
                createESPName(char, getPlayerESPName(p), PLAYER_COLOR)
            else
                removeESPName(char)
            end
        end)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    aplicarEspJogador(p)
end

Players.PlayerAdded:Connect(aplicarEspJogador)










local AREA51 = WaitForChildContinue(Workspace, "AREA51", 5)





local NoKillBricksBackup = {}
local SpinnerReplacementBackup = {}
local TeleporterCollisionBackup = {}

local function clonarOriginal(obj)
    if not obj then
        return nil
    end

    local antigoArchivable = obj.Archivable
    local clone

    pcall(function()
        obj.Archivable = true
        clone = obj:Clone()
        obj.Archivable = antigoArchivable
    end)

    pcall(function()
        obj.Archivable = antigoArchivable
    end)

    return clone
end

local function deletarPerigos(obj)
    if not Config.NoKillBricks then
        return
    end

    if not obj:IsA("BasePart") then
        return
    end

    if obj.Name == "Kill" or obj.Name == "KillTop" then
        if not NoKillBricksBackup[obj] then
            local clone = clonarOriginal(obj)

            NoKillBricksBackup[obj] = {
                Clone = clone,
                Parent = obj.Parent,
                ClassName = obj.ClassName,
                Name = obj.Name
            }
        end

        obj:Destroy()
    end
end

local function restaurarNoKillBricks()
    
    for original, data in pairs(NoKillBricksBackup) do
        if data.Clone and data.Parent and data.Parent.Parent then
            if not data.Clone.Parent then
                data.Clone.Parent = data.Parent
            end
        end
    end

    table.clear(NoKillBricksBackup)

    
    for _, data in pairs(SpinnerReplacementBackup) do
        if data.Replacement and data.Replacement.Parent then
            data.Replacement:Destroy()
        end

        if data.Clone and data.Parent and data.Parent.Parent then
            if not data.Clone.Parent then
                data.Clone.Parent = data.Parent
            end
        end
    end

    table.clear(SpinnerReplacementBackup)

    
    for part, oldCanCollide in pairs(TeleporterCollisionBackup) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = oldCanCollide
            end)
        end
    end

    table.clear(TeleporterCollisionBackup)
end













local function substituirSpinner(obj)

    if not Config.NoKillBricks then
        return false
    end

    if not obj then
        return false
    end

    if obj.Name ~= "Spinner" then
        return false
    end

    if not obj:IsA("Model") then
        return false
    end

    local parent = obj.Parent

    if not parent then
        return false
    end

    if not SpinnerReplacementBackup[obj] then
        SpinnerReplacementBackup[obj] = {
            Clone = clonarOriginal(obj),
            Parent = parent
        }
    end

    
    local extension = obj:FindFirstChild("Extension")

    local partesValidas = {}

    for _, descendant in ipairs(obj:GetDescendants()) do

        if descendant:IsA("BasePart") then

            local ignorar = false

            
            
            if extension then
                if descendant == extension
                    or descendant:IsDescendantOf(extension) then

                    ignorar = true
                end
            end

            if not ignorar then
                table.insert(partesValidas, descendant)
            end
        end
    end

    if #partesValidas == 0 then
        




        return false
    end

    
    
    

    local minX = math.huge
    local minY = math.huge
    local minZ = math.huge

    local maxX = -math.huge
    local maxY = -math.huge
    local maxZ = -math.huge

    for _, part in ipairs(partesValidas) do

        local cf = part.CFrame
        local size = part.Size

        local corners = {
            cf * Vector3.new(
                size.X / 2,
                size.Y / 2,
                size.Z / 2
            ),

            cf * Vector3.new(
                size.X / 2,
                size.Y / 2,
                -size.Z / 2
            ),

            cf * Vector3.new(
                size.X / 2,
                -size.Y / 2,
                size.Z / 2
            ),

            cf * Vector3.new(
                size.X / 2,
                -size.Y / 2,
                -size.Z / 2
            ),

            cf * Vector3.new(
                -size.X / 2,
                size.Y / 2,
                size.Z / 2
            ),

            cf * Vector3.new(
                -size.X / 2,
                size.Y / 2,
                -size.Z / 2
            ),

            cf * Vector3.new(
                -size.X / 2,
                -size.Y / 2,
                size.Z / 2
            ),

            cf * Vector3.new(
                -size.X / 2,
                -size.Y / 2,
                -size.Z / 2
            )
        }

        for _, corner in ipairs(corners) do

            minX = math.min(minX, corner.X)
            minY = math.min(minY, corner.Y)
            minZ = math.min(minZ, corner.Z)

            maxX = math.max(maxX, corner.X)
            maxY = math.max(maxY, corner.Y)
            maxZ = math.max(maxZ, corner.Z)

        end
    end

    local centro = Vector3.new(
        (minX + maxX) / 2,
        (minY + maxY) / 2,
        (minZ + maxZ) / 2
    )

    local tamanho = Vector3.new(
        maxX - minX,
        maxY - minY,
        maxZ - minZ
    )

    
    
    

    local novaPart = InstanceNew("Part")

    novaPart.Name = "Spinner_Replaced"

    
    novaPart.Size = tamanho

    novaPart.CFrame = CFrame.new(centro)

    
    novaPart.Anchored = true
    novaPart.CanCollide = true
    novaPart.CanTouch = true
    novaPart.CanQuery = true

    
    novaPart.Transparency = 1
    novaPart.CastShadow = false

    
    novaPart.Parent = parent

    
    local backup = SpinnerReplacementBackup[obj]
    if backup then
        backup.Replacement = novaPart
    end

    
    obj:Destroy()

    




    




    return true
end





local spinnersEncontrados = 0

for _, obj in ipairs(AREA51:GetDescendants()) do

    if obj.Name == "Spinner"
        and obj:IsA("Model") then

        if substituirSpinner(obj) then
            spinnersEncontrados += 1
        end

    elseif obj:IsA("BasePart") then

        deletarPerigos(obj)

    end
end










AREA51.DescendantAdded:Connect(function(obj)

    task.defer(function()

        if not obj.Parent then
            return
        end

        
        if obj.Name == "Spinner"
            and obj:IsA("Model") then

            substituirSpinner(obj)
            return
        end

        
        if obj:IsA("BasePart") then
            deletarPerigos(obj)
        end

    end)

end)





local teleporter =
    AREA51.TeleporterRoom.Teleporter.Teleporter

local function desativarColisao(obj)
    if not Config.NoKillBricks then
        return
    end

    if obj:IsA("BasePart") then
        if TeleporterCollisionBackup[obj] == nil then
            TeleporterCollisionBackup[obj] = obj.CanCollide
        end

        obj.CanCollide = false
    end
end

for _, obj in ipairs(teleporter:GetDescendants()) do
    desativarColisao(obj)
end

teleporter.DescendantAdded:Connect(desativarColisao)










pcall(function()
    ChatStateBackup = {
        ChatWindowEnabled = TextChatService.ChatWindowConfiguration.Enabled,
        ChatInputEnabled = TextChatService.ChatInputBarConfiguration.Enabled,
        TargetTextChannel = TextChatService.ChatInputBarConfiguration.TargetTextChannel,
        LegacyEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
    }
end)

local function restaurarChatOriginal()
    if not ChatStateBackup then
        return
    end

    pcall(function()
        TextChatService.ChatWindowConfiguration.Enabled =
            ChatStateBackup.ChatWindowEnabled
    end)

    pcall(function()
        TextChatService.ChatInputBarConfiguration.Enabled =
            ChatStateBackup.ChatInputEnabled
    end)

    pcall(function()
        TextChatService.ChatInputBarConfiguration.TargetTextChannel =
            ChatStateBackup.TargetTextChannel
    end)

    pcall(function()
        StarterGui:SetCoreGuiEnabled(
            Enum.CoreGuiType.Chat,
            ChatStateBackup.LegacyEnabled
        )
    end)
end

local function encontrarCanalGeral()
    local channels = TextChatService:FindFirstChild("TextChannels")

    if not channels then
        return nil
    end

    local general = channels:FindFirstChild("RBXGeneral")

    if general and general:IsA("TextChannel") then
        return general
    end

    for _, channel in ipairs(channels:GetChildren()) do
        if channel:IsA("TextChannel") then
            return channel
        end
    end

    return nil
end

local function reabilitarTextChat()
    if not Config.NoBlockChat then
        return
    end

    pcall(function()
        local windowConfig = TextChatService.ChatWindowConfiguration
        windowConfig.Enabled = true
    end)

    pcall(function()
        local inputConfig = TextChatService.ChatInputBarConfiguration
        inputConfig.Enabled = true

        if inputConfig.TargetTextChannel == nil then
            local channel = encontrarCanalGeral()

            if channel then
                inputConfig.TargetTextChannel = channel
            end
        end
    end)
end

local function reabilitarLegacyChat()
    if not Config.NoBlockChat then
        return
    end

    pcall(function()
        StarterGui:SetCoreGuiEnabled(
            Enum.CoreGuiType.Chat,
            true
        )
    end)
end

local function forcarChat()
    if not Config.NoBlockChat then
        return
    end

    reabilitarTextChat()
    reabilitarLegacyChat()
end


forcarChat()


pcall(function()
    TextChatService.ChatWindowConfiguration
        :GetPropertyChangedSignal("Enabled")
        :Connect(function()
            if Config.NoBlockChat then
                task.defer(forcarChat)
            end
        end)
end)


pcall(function()
    TextChatService.ChatInputBarConfiguration
        :GetPropertyChangedSignal("Enabled")
        :Connect(function()
            if Config.NoBlockChat then
                task.defer(forcarChat)
            end
        end)
end)


pcall(function()
    TextChatService.ChildAdded:Connect(function(child)
        if Config.NoBlockChat and child.Name == "TextChannels" then
            task.defer(forcarChat)
        end
    end)
end)


task.spawn(function()
    while task.wait(0.25) do
        if Config.NoBlockChat then
            forcarChat()
        end
    end
end)

-- ============================================================
-- NOBLOCKCHAT / KILLER CHAT GUI
-- Place-specific: 4678052190
-- The normal Roblox chat stays enabled while this option is on.
-- A small draggable sender GUI appears only while LocalPlayer is Killer.
-- ============================================================
local NO_BLOCK_CHAT_PLACE_ID = 4678052190
local noBlockChatPlaceAllowed = game.PlaceId == NO_BLOCK_CHAT_PLACE_ID
local noBlockChatGui = nil
local noBlockChatFrame = nil
local noBlockChatInput = nil
local noBlockChatSend = nil
local noBlockChatDragConnection = nil
local noBlockChatKillerState = false

local function noBlockChatIsKiller()
    local camera = Workspace.CurrentCamera
    if not camera then
        return false
    end

    local subject = camera.CameraSubject
    if not subject then
        return false
    end

    return subject:IsDescendantOf(Killers)
end

local function getNoBlockChatGuiParent()
    local parent = WaitForChildContinue(LocalPlayer, "PlayerGui", 5)

    pcall(function()
        if typeof(gethui) == "function" then
            local hui = gethui()
            if hui then
                parent = hui
            end
        end
    end)

    return parent
end

local function destroyNoBlockChatGui()
    if noBlockChatGui then
        pcall(function()
            noBlockChatGui:Destroy()
        end)
    end

    noBlockChatGui = nil
    noBlockChatFrame = nil
    noBlockChatInput = nil
    noBlockChatSend = nil

    if noBlockChatDragConnection then
        pcall(function()
            noBlockChatDragConnection:Disconnect()
        end)
        noBlockChatDragConnection = nil
    end
end

local function createNoBlockChatGui()
    destroyNoBlockChatGui()

    if not noBlockChatPlaceAllowed then
        return
    end

    local parent = getNoBlockChatGuiParent()

    pcall(function()
        local old = parent:FindFirstChild("SaktkNoBlockChatGui")
        if old then
            old:Destroy()
        end
    end)

    local gui = InstanceNew("ScreenGui")
    gui.Name = "SaktkNoBlockChatGui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Enabled = false
    gui.Parent = parent

    local frame = InstanceNew("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.fromOffset(250, 88)
    frame.Position = UDim2.new(0, 15, 0, 190)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = InstanceNew("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = frame

    local title = InstanceNew("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 24)
    title.Position = UDim2.fromOffset(9, 0)
    title.BackgroundTransparency = 1
    title.Text = "Killer Chat"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local input = InstanceNew("TextBox")
    input.Name = "Input"
    input.Size = UDim2.new(1, -76, 0, 36)
    input.Position = UDim2.fromOffset(8, 34)
    input.BackgroundTransparency = 0.1
    input.PlaceholderText = "Digite sua mensagem..."
    input.ClearTextOnFocus = false
    input.MultiLine = false
    input.Text = ""
    input.TextSize = 13
    input.Font = Enum.Font.SourceSans
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.Parent = frame

    local inputCorner = InstanceNew("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = input

    local send = InstanceNew("TextButton")
    send.Name = "Send"
    send.Size = UDim2.fromOffset(60, 36)
    send.Position = UDim2.new(1, -68, 0, 34)
    send.BackgroundTransparency = 0.05
    send.Text = "Enviar"
    send.TextSize = 13
    send.Font = Enum.Font.SourceSansBold
    send.TextColor3 = Color3.fromRGB(255, 255, 255)
    send.Parent = frame

    local sendCorner = InstanceNew("UICorner")
    sendCorner.CornerRadius = UDim.new(0, 6)
    sendCorner.Parent = send

    -- Drag by the title bar; works with mouse and touch.
    local dragging = false
    local dragStart = nil
    local startPosition = nil

    title.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inputObject.Position
            startPosition = frame.Position
        end
    end)

    title.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    noBlockChatDragConnection = UserInputService.InputChanged:Connect(function(inputObject)
        if not dragging or not dragStart or not startPosition then
            return
        end

        if inputObject.UserInputType ~= Enum.UserInputType.MouseMovement
            and inputObject.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = inputObject.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    send.MouseButton1Click:Connect(function()
        if not Config.NoBlockChat or not noBlockChatPlaceAllowed then
            return
        end

        if not noBlockChatIsKiller() then
            return
        end

        local text = input.Text or ""
        if text == "" then
            return
        end

        pcall(function()
            local channels = TextChatService:FindFirstChild("TextChannels")
            local generalChannel = channels and channels:FindFirstChild("RBXGeneral")

            if generalChannel and generalChannel:IsA("TextChannel") then
                generalChannel:SendAsync(text)
            end
        end)
    end)

    noBlockChatGui = gui
    noBlockChatFrame = frame
    noBlockChatInput = input
    noBlockChatSend = send
end

local function updateNoBlockChatGui()
    if not noBlockChatPlaceAllowed then
        if noBlockChatGui then
            noBlockChatGui.Enabled = false
        end
        noBlockChatKillerState = false
        return
    end

    if not Config.NoBlockChat then
        if noBlockChatGui then
            noBlockChatGui.Enabled = false
        end
        noBlockChatKillerState = false
        return
    end

    if not noBlockChatGui then
        createNoBlockChatGui()
    end

    local isKiller = noBlockChatIsKiller()

    if isKiller ~= noBlockChatKillerState then
        noBlockChatKillerState = isKiller

        if noBlockChatGui then
            noBlockChatGui.Enabled = isKiller
        end
    end
end

if noBlockChatPlaceAllowed then
    createNoBlockChatGui()

    task.spawn(function()
        while task.wait(0.1) do
            updateNoBlockChatGui()
        end
    end)
end


local pastaArmasESP = nil

if espArmasAutorizado then

    pastaArmasESP =
        workspace:FindFirstChild("ESP_Armas_Temp")

    if not pastaArmasESP then

        pastaArmasESP =
            InstanceNew("Folder")

        pastaArmasESP.Name =
            "ESP_Armas_Temp"

        pastaArmasESP.Parent =
            workspace

    end
end

RunService.Heartbeat:Connect(function()

    
    
    

    for k, d in pairs(trackedKillers) do

        if k.Parent ~= Killers then
            trackedKillers[k] = nil
            removeHighlight(k)
            continue
        end

        local hum =
            k:FindFirstChildOfClass("Humanoid")
            or k:FindFirstChild("Humanoid", true)

        if not hum
            or hum.Health <= 0
            or d.dead then

            removeHighlight(k)
            removeESPName(k)
            continue
        end

        local pos =
            k:GetPivot().Position

        if (pos - d.last).Magnitude >= 0.1 then
            d.moved = true
        end

        d.last = pos

        if Config.KillerESP and d.moved and not isKillerControlledByLocalCamera(k) then
            addHighlight(k)

            if Config.ESPName then
                -- The controller lookup scans many descendants, so never run it every frame.
                local label = k:FindFirstChild("ESPNameLabel")

                if not label then
                    local now = os.clock()
                    if now >= (d.nextNameLookup or 0) then
                        d.nextNameLookup = now + 0.75

                        local controllerName = getKillerControllerDisplayName(k)
                        if controllerName and controllerName ~= "" then
                            d.controllerName = controllerName
                        end
                    end

                    createESPName(k, d.controllerName or k.Name, KILLER_COLOR)
                end
            else
                removeESPName(k)
            end
        else
            removeHighlight(k)
            removeESPName(k)
        end

    end

    
    
    

    if espArmasAutorizado and not Config.WeaponESP then
        for nomeArma, tracker in pairs(criadosArmas) do
            if tracker and tracker.Parent then
                tracker:Destroy()
            end
            criadosArmas[nomeArma] = nil
        end
    end

    if espArmasAutorizado and Config.WeaponESP then

        if not pastaArmasESP or not pastaArmasESP.Parent then
            pastaArmasESP = workspace:FindFirstChild("ESP_Armas_Temp")

            if not pastaArmasESP then
                pastaArmasESP = InstanceNew("Folder")
                pastaArmasESP.Name = "ESP_Armas_Temp"
                pastaArmasESP.Parent = workspace
            end
        end

        local osClock =
            os.clock()

        if osClock >= nextWeaponCheck then

            nextWeaponCheck =
                osClock + WEAPON_CHECK_INTERVAL

            local weaponsFolder =
                FindFirstChild(
                    workspace,
                    "Weapons"
                )

            local modelosAlvoESP = {}
            local currentId =
                game.PlaceId

            if weaponsFolder then

                local children =
                    weaponsFolder:GetChildren()

                if currentId == 4678052190 then

                    for i = 1, #children do

                        local pastaPai =
                            children[i]

                        if pastaPai:IsA("Model")
                            or pastaPai:IsA("Folder") then

                            local nomeDaArma =
                                pastaPai.Name

                            local modeloRealInterno =
                                FindFirstChild(
                                    pastaPai,
                                    nomeDaArma
                                )

                            if modeloRealInterno
                                and (
                                    modeloRealInterno:IsA("Model")
                                    or modeloRealInterno:IsA("BasePart")
                                ) then

                                modelosAlvoESP[nomeDaArma] =
                                    modeloRealInterno

                            end
                        end
                    end

                elseif currentId == 1076129670 then

                    for i = 1, #children do

                        local weapon =
                            children[i]

                        if weapon:IsA("Model")
                            or weapon:IsA("BasePart") then

                            modelosAlvoESP[weapon.Name] =
                                weapon

                        end
                    end

                end
            end

            for nomeArma, tracker in pairs(criadosArmas) do

                if not modelosAlvoESP[nomeArma] then

                    if tracker
                        and tracker.Parent then

                        tracker:Destroy()

                    end

                    criadosArmas[nomeArma] =
                        nil

                end
            end

            for nomeArma, modeloFisico in pairs(modelosAlvoESP) do

                local visualTracker =
                    criadosArmas[nomeArma]

                if visualTracker
                    and not visualTracker.Parent then

                    criadosArmas[nomeArma] =
                        nil

                    visualTracker =
                        nil

                end

                if visualTracker then

                    if modeloFisico:IsA("Model")
                        and modeloFisico.PrimaryPart then

                        visualTracker.CFrame =
                            modeloFisico.PrimaryPart.CFrame

                    else

                        local alternativePart =
                            FindChildOfClass(
                                modeloFisico,
                                "BasePart"
                            )

                        if alternativePart then

                            visualTracker.CFrame =
                                alternativePart.CFrame

                        end
                    end

                else

                    local corEscolhida =
                        Color3.fromRGB(
                            255,
                            255,
                            0
                        )

                    if GREEN_WEAPONS[nomeArma] then

                        corEscolhida =
                            Color3.fromRGB(
                                0,
                                255,
                                100
                            )

                    end

                    local trackerPart =
                        InstanceNew("Part")

                    trackerPart.Name =
                        nomeArma .. "_ESP"

                    trackerPart.Size =
                        Vector3.new(
                            1.8,
                            1.8,
                            1.8
                        )

                    trackerPart.Transparency =
                        1

                    trackerPart.CanCollide =
                        false

                    trackerPart.Anchored =
                        true

                    if modeloFisico:IsA("Model")
                        and modeloFisico.PrimaryPart then

                        trackerPart.CFrame =
                            modeloFisico.PrimaryPart.CFrame

                    else

                        local alternativePart =
                            FindChildOfClass(
                                modeloFisico,
                                "BasePart"
                            )

                        if alternativePart then

                            trackerPart.CFrame =
                                alternativePart.CFrame

                        end
                    end

                    local selectionBox =
                        InstanceNew("SelectionBox")

                    selectionBox.Color3 =
                        corEscolhida

                    selectionBox.LineThickness =
                        0.06

                    selectionBox.Adornee =
                        trackerPart

                    selectionBox.Parent =
                        trackerPart

                    local billboard =
                        InstanceNew("BillboardGui")

                    billboard.Name =
                        "WeaponLabel"

                    billboard.Size =
                        UDim2.new(
                            0,
                            80,
                            0,
                            20
                        )

                    billboard.AlwaysOnTop =
                        true

                    billboard.StudsOffset =
                        Vector3.new(
                            0,
                            2,
                            0
                        )

                    billboard.Adornee =
                        trackerPart

                    billboard.Parent =
                        trackerPart

                    local textLabel =
                        InstanceNew("TextLabel")

                    textLabel.Size =
                        UDim2.new(
                            1,
                            0,
                            1,
                            0
                        )

                    textLabel.BackgroundTransparency =
                        1

                    textLabel.Text =
                        nomeArma

                    textLabel.TextColor3 =
                        corEscolhida

                    textLabel.TextSize =
                        9

                    textLabel.TextTransparency =
                        0.3

                    textLabel.Font =
                        Enum.Font.SourceSansBold

                    textLabel.TextStrokeTransparency =
                        0.5

                    textLabel.TextStrokeColor3 =
                        Color3.fromRGB(
                            0,
                            0,
                            0
                        )

                    textLabel.Parent =
                        billboard

                    trackerPart.Parent =
                        pastaArmasESP

                    criadosArmas[nomeArma] =
                        trackerPart

                end
            end
        end
    end
end)





local metatable =
    getrawmetatable(game)

local oldNamecall =
    metatable.__namecall

setreadonly(
    metatable,
    false
)

metatable.__namecall =
    newcclosure(function(
        self,
        ...
    )

        local method =
            getnamecallmethod()

        local args = {...}

        if method == "FireServer"
            and (
                tostring(self) == "ByteNetReliable"
                or tostring(self) == "ByteNetUnreliable"
            ) then

            local buf =
                args

            if typeof(buf) == "buffer"
                and buffer.len(buf) > 0
                and not pacotesClonados[buf] then

                if Config.InfAmmo and limitePenteArmaAtual == 1 then
                    forcarRecargaCobalt()
                end

                local clone =
                    buffer.create(
                        buffer.len(buf)
                    )

                buffer.copy(
                    clone,
                    0,
                    buf,
                    0,
                    buffer.len(buf)
                )

                pacotesClonados[buf] =
                    true

                task.spawn(function()

                    oldNamecall(
                        self,
                        clone,
                        args
                    )

                    task.wait(0.1)

                        pacotesClonados[buf] =
                        nil

                end)
            end
        end

        return oldNamecall(
            self,
            ...
        )

    end)

setreadonly(
    metatable,
    true
)

local function clearKillerESP()
    for killer in pairs(trackedKillers) do
        removeHighlight(killer)
        removeESPName(killer)
    end
end

local function clearPlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("PlayerHighlight")
            if highlight then
                highlight:Destroy()
            end
            removeESPName(player.Character)
        end
    end
end

local function refreshPlayerESP()
    if not Config.PlayerESP then
        clearPlayerESP()
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local highlight = player.Character:FindFirstChild("PlayerHighlight")

                if not highlight then
                    highlight = InstanceNew("Highlight")
                    highlight.Name = "PlayerHighlight"
                    highlight.FillTransparency = 1
                    highlight.OutlineTransparency = 0
                    highlight.OutlineColor = PLAYER_COLOR
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = player.Character
                end

                if Config.ESPName then
                    createESPName(player.Character, getPlayerESPName(player), PLAYER_COLOR)
                else
                    removeESPName(player.Character)
                end
            end
        end
    end
end






local speedConnection
local speedCharacterConnection

local function stopSpeedBoost()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
end

local function startSpeedBoost()
    stopSpeedBoost()

    local function setupCharacter(character)
        stopSpeedBoost()

        local humanoid = WaitForChildContinue(character, "Humanoid", 5)
        local rootPart = WaitForChildContinue(character, "HumanoidRootPart", 5)

        if not humanoid or not rootPart then
            return
        end

        speedConnection = RunService.Heartbeat:Connect(function()
            if not Config.SpeedBoost then
                return
            end

            if not character.Parent or humanoid.Health <= 0 or not rootPart.Parent then
                return
            end

            local direction = humanoid.MoveDirection

            if direction.Magnitude > 0 then
                
                
                local normalSpeed = humanoid.WalkSpeed
                local targetSpeed = normalSpeed + Config.SpeedBoostAmount

                local velocity = rootPart.AssemblyLinearVelocity
                local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)

                if horizontalDirection.Magnitude > 0 then
                    horizontalDirection = horizontalDirection.Unit
                    rootPart.AssemblyLinearVelocity = Vector3.new(
                        horizontalDirection.X * targetSpeed,
                        velocity.Y,
                        horizontalDirection.Z * targetSpeed
                    )
                end
            end
        end)
    end

    if LocalPlayer.Character then
        setupCharacter(LocalPlayer.Character)
    end

    if not speedCharacterConnection then
        speedCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
            if Config.SpeedBoost then
                setupCharacter(character)
            end
        end)
    end
end

local bulletSpeedConnection

local function applyBulletSpeed(bullet)
    if not Config.BulletSpeed3x then
        return
    end

    if not bullet or not bullet:IsA("BasePart") or bullet.Name ~= "Bullet" then
        return
    end

    task.defer(function()
        if not Config.BulletSpeed3x or not bullet.Parent then
            return
        end

        if bullet:GetAttribute("SaktkBulletSpeedApplied") then
            return
        end

        local velocity = bullet.AssemblyLinearVelocity
        if velocity.Magnitude <= 0 then
            return
        end

        bullet:SetAttribute("SaktkOriginalBulletVelocity", velocity)
        bullet:SetAttribute("SaktkBulletSpeedApplied", true)
        bullet.AssemblyLinearVelocity = velocity * Config.BulletSpeedMultiplier
    end)
end

local function restoreBulletSpeed()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Bullet" then
            local original = obj:GetAttribute("SaktkOriginalBulletVelocity")
            if typeof(original) == "Vector3" then
                pcall(function()
                    obj.AssemblyLinearVelocity = original
                    obj:SetAttribute("SaktkOriginalBulletVelocity", nil)
                    obj:SetAttribute("SaktkBulletSpeedApplied", nil)
                end)
            end
        end
    end
end

local wallbangConnection
local wallbangTrackedBullets = {}
local wallbangRaycastParams = RaycastParams.new()
wallbangRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
wallbangRaycastParams.IgnoreWater = true

local function isKillerPart(obj)
    return obj and obj:IsA("BasePart") and Killers and obj:IsDescendantOf(Killers)
end

local function isCharacterPart(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function isToolPart(obj)
    return obj:FindFirstAncestorOfClass("Tool") ~= nil
end

local function isWall(obj)
    if not obj or not obj:IsA("BasePart") then
        return false
    end

    -- Killers always have priority.
    if isKillerPart(obj) then
        return false
    end

    if not obj.CanCollide or obj.Transparency >= 0.99 then
        return false
    end

    if isCharacterPart(obj) or isToolPart(obj) then
        return false
    end

    local inArea51 = AREA51 and obj:IsDescendantOf(AREA51)
    local doors = Workspace:FindFirstChild("Doors")
    local inDoors = doors and obj:IsDescendantOf(doors)

    return inArea51 or inDoors
end

local function backupBulletCollision(bullet)
    if bullet:GetAttribute("SaktkWallbangBackup") then
        return
    end

    bullet:SetAttribute("SaktkWallbangBackup", true)
    bullet:SetAttribute("SaktkWallbangCanCollide", bullet.CanCollide)
    bullet:SetAttribute("SaktkWallbangCanTouch", bullet.CanTouch)
end

local function restoreBulletCollision(bullet)
    if not bullet or not bullet:GetAttribute("SaktkWallbangBackup") then
        return
    end

    local cc = bullet:GetAttribute("SaktkWallbangCanCollide")
    local ct = bullet:GetAttribute("SaktkWallbangCanTouch")

    pcall(function()
        if typeof(cc) == "boolean" then
            bullet.CanCollide = cc
        end

        if typeof(ct) == "boolean" then
            bullet.CanTouch = ct
        end

        bullet:SetAttribute("SaktkWallbangBackup", nil)
        bullet:SetAttribute("SaktkWallbangCanCollide", nil)
        bullet:SetAttribute("SaktkWallbangCanTouch", nil)
    end)
end

local function trackWallbangBullet(obj)
    if not obj:IsA("BasePart") or obj.Name ~= "Bullet" then
        return
    end

    wallbangTrackedBullets[obj] = true
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    trackWallbangBullet(obj)
end

Workspace.DescendantAdded:Connect(trackWallbangBullet)

Workspace.DescendantRemoving:Connect(function(obj)
    wallbangTrackedBullets[obj] = nil
end)

local function checkBullet(bullet)
    if not Config.Wallbang then
        return
    end

    if not bullet or not bullet.Parent
        or not bullet:IsA("BasePart")
        or bullet.Name ~= "Bullet" then
        wallbangTrackedBullets[bullet] = nil
        return
    end

    -- Killer collision always wins over wallbang.
    for _, obj in ipairs(Workspace:GetPartBoundsInRadius(bullet.Position, 4)) do
        if isKillerPart(obj) then
            restoreBulletCollision(bullet)
            return
        end
    end

    local velocity = bullet.AssemblyLinearVelocity
    local speed = velocity.Magnitude

    if speed > 0.01 then
        local distance = math.clamp(
            speed * 0.12 + bullet.Size.Magnitude,
            4,
            30
        )

        wallbangRaycastParams.FilterDescendantsInstances = {
            bullet
        }

        local result = Workspace:Raycast(
            bullet.Position,
            velocity.Unit * distance,
            wallbangRaycastParams
        )

        if result then
            local hit = result.Instance

            if isKillerPart(hit) then
                restoreBulletCollision(bullet)
                return
            end

            if isWall(hit) then
                backupBulletCollision(bullet)

                pcall(function()
                    bullet.CanCollide = false
                    bullet.CanTouch = false
                end)

                return
            end
        end
    end

    -- Short-range fallback for thin/fast walls.
    for _, obj in ipairs(Workspace:GetPartBoundsInRadius(bullet.Position, 2.5)) do
        if isKillerPart(obj) then
            restoreBulletCollision(bullet)
            return
        end

        if isWall(obj) then
            backupBulletCollision(bullet)

            pcall(function()
                bullet.CanCollide = false
                bullet.CanTouch = false
            end)

            return
        end
    end

    restoreBulletCollision(bullet)
end

wallbangConnection = RunService.Heartbeat:Connect(function()
    if not Config.Wallbang then
        return
    end

    for bullet in pairs(wallbangTrackedBullets) do
        if bullet and bullet.Parent then
            checkBullet(bullet)
        else
            wallbangTrackedBullets[bullet] = nil
        end
    end
end)

local gunKillAuraTrackedBullets = {}
local gunKillAuraChaseTargets = {}
local gunKillAuraConnection = nil
local gunKillAuraAutoDisabled = false
local gunKillAuraAutoChanging = false
local gunKillAuraToggle = nil

local GUN_KILL_AURA_BULLET_DISTANCE = 6.2
local GUN_KILL_AURA_MAX_DISTANCE = 10000

local function GunKillAuraGetCharacterRoot()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
end

local function GunKillAuraGetRandomKiller()
    local validKillers = {}

    for _, killer in ipairs(Killers:GetChildren()) do
        if killer.Name == "Jane" then
            continue
        end

        if not killer:IsA("Model") then
            continue
        end

        local humanoid =
            killer:FindFirstChildOfClass("Humanoid")
            or killer:FindFirstChild("Humanoid", true)

        if not humanoid or humanoid.Health <= 0 then
            continue
        end

        local targetPart =
            killer:FindFirstChild("Head", true)
            or killer:FindFirstChild("HumanoidRootPart", true)
            or killer:FindFirstChild("Torso", true)

        if not targetPart or not targetPart:IsA("BasePart") then
            continue
        end

        table.insert(validKillers, {
            Model = killer,
            Part = targetPart
        })
    end

    if #validKillers == 0 then
        return nil, nil
    end

    local chosen = validKillers[math.random(1, #validKillers)]

    return chosen.Model, chosen.Part
end

local function GunKillAuraIsMyBullet(bullet)
    if not Config.GunKillAura then
        return false
    end

    if not bullet or not bullet.Parent
        or not bullet:IsA("BasePart")
        or bullet.Name ~= "Bullet" then
        return false
    end

    local root = GunKillAuraGetCharacterRoot()
    if not root then
        return false
    end

    return (bullet.Position - root.Position).Magnitude
        <= GUN_KILL_AURA_BULLET_DISTANCE
end

local function GunKillAuraProcessBullet(bullet)
    if not Config.GunKillAura then
        return
    end

    if not bullet or not bullet.Parent then
        return
    end

    if gunKillAuraTrackedBullets[bullet] then
        return
    end

    if not GunKillAuraIsMyBullet(bullet) then
        return
    end

    gunKillAuraTrackedBullets[bullet] = true

    local killer, target = GunKillAuraGetRandomKiller()

    if not killer or not target then
        return
    end
    gunKillAuraChaseTargets[bullet] = {
        Killer = killer,
        Part = target,
        LastPosition = target.Position,
        Moving = false
    }

    pcall(function()
        bullet.CFrame = CFrame.new(target.Position)
    end)
end

gunKillAuraConnection = Workspace.DescendantAdded:Connect(function(obj)
    if not obj:IsA("BasePart") or obj.Name ~= "Bullet" then
        return
    end

    task.defer(function()
        GunKillAuraProcessBullet(obj)
    end)
end)

Workspace.DescendantRemoving:Connect(function(obj)
    gunKillAuraTrackedBullets[obj] = nil
    gunKillAuraChaseTargets[obj] = nil
end)

RunService.Heartbeat:Connect(function()
    local camera = Workspace.CurrentCamera
    local subject = camera and camera.CameraSubject
    local isLocalPlayerKiller = subject ~= nil
        and subject:IsDescendantOf(Killers)

    if isLocalPlayerKiller then
        if Config.GunKillAura then
            Config.GunKillAura = false
            gunKillAuraAutoDisabled = true
            table.clear(gunKillAuraTrackedBullets)
            table.clear(gunKillAuraChaseTargets)

            if gunKillAuraToggle then
                gunKillAuraAutoChanging = true
                pcall(function()
                    gunKillAuraToggle:Set(false)
                end)
                gunKillAuraAutoChanging = false
            end
        end

        return
    end

    if gunKillAuraAutoDisabled then
        Config.GunKillAura = true
        gunKillAuraAutoDisabled = false

        if gunKillAuraToggle then
            gunKillAuraAutoChanging = true
            pcall(function()
                gunKillAuraToggle:Set(true)
            end)
            gunKillAuraAutoChanging = false
        end
    end

    if not Config.GunKillAura then
        return
    end

    for bullet, data in pairs(gunKillAuraChaseTargets) do
        if not bullet or not bullet.Parent then
            gunKillAuraChaseTargets[bullet] = nil
            continue
        end

        local killer = data.Killer
        local target = data.Part

        if not killer
            or not killer.Parent
            or not target
            or not target.Parent then
            gunKillAuraChaseTargets[bullet] = nil
            continue
        end

        local humanoid =
            killer:FindFirstChildOfClass("Humanoid")
            or killer:FindFirstChild("Humanoid", true)

        if not humanoid or humanoid.Health <= 0 then
            gunKillAuraChaseTargets[bullet] = nil
            continue
        end

        local currentPosition = target.Position
        local movedDistance = (currentPosition - data.LastPosition).Magnitude

        data.Moving = movedDistance > 0.03
        data.LastPosition = currentPosition

        if data.Moving then
            pcall(function()
                bullet.CFrame = CFrame.new(currentPosition)
            end)
        end
    end
end)

local KillerCameraAimConnection = nil

local function KillerAimGetHead(model)
    if not model or not model:IsA("Model") then
        return nil
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
        or model:FindFirstChild("Humanoid", true)

    if not humanoid or humanoid.Health <= 0 then
        return nil
    end

    local partName = Config.KillerAimPart or "Head"
    local head = model:FindFirstChild(partName, true)

    if not head or not head:IsA("BasePart") then
        if partName == "Torso" then
            head = model:FindFirstChild("UpperTorso", true)
                or model:FindFirstChild("HumanoidRootPart", true)
                or model:FindFirstChild("Torso", true)
        else
            head = model:FindFirstChild("Head", true)
        end
    end

    if not head or not head:IsA("BasePart") then
        return nil
    end

    return head
end

local function KillerAimGetAimPosition(model, part)
    if Config.KillerAimPart ~= "Neck" then
        return part and part.Position or nil
    end

    local head = model and model:FindFirstChild("Head", true)
    local torso = model and (
        model:FindFirstChild("UpperTorso", true)
        or model:FindFirstChild("Torso", true)
        or model:FindFirstChild("HumanoidRootPart", true)
    )

    if head and head:IsA("BasePart") and torso and torso:IsA("BasePart") then
        return head.Position:Lerp(torso.Position, 0.5)
    end

    return part and part.Position or nil
end

local KillerAimOriginalCanQuery = {}
local KillerAimQuerySetup = false

local function KillerAimSetupQuery()
    if KillerAimQuerySetup then
        return
    end

    KillerAimQuerySetup = true

    local folders = {
        AREA51,
        Workspace:FindFirstChild("Doors")
    }

    for _, folder in ipairs(folders) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if KillerAimOriginalCanQuery[obj] == nil then
                        KillerAimOriginalCanQuery[obj] = obj.CanQuery
                    end

                    obj.CanQuery = true
                end
            end
        end
    end
end

local function KillerAimRestoreQuery()
    for obj, originalValue in pairs(KillerAimOriginalCanQuery) do
        if obj and obj.Parent then
            obj.CanQuery = originalValue
        end
    end

    table.clear(KillerAimOriginalCanQuery)
    KillerAimQuerySetup = false
end

local function KillerAimWallCheck(head)
    if not Config.WallCheck then
        return true
    end

    if not head or not head.Parent then
        return false
    end

    local character = LocalPlayer.Character
    if not character then
        return false
    end

    local rootPart =
        character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")

    if not rootPart then
        return false
    end

    local origin = rootPart.Position
    local direction = head.Position - origin

    if direction.Magnitude <= 0 then
        return true
    end

    KillerAimSetupQuery()

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        character,
        head.Parent
    }
    params.IgnoreWater = true

    local currentOrigin = origin
    local remainingDirection = direction
    local directionUnit = direction.Unit

    for _ = 1, 20 do
        local result = Workspace:Raycast(
            currentOrigin,
            remainingDirection,
            params
        )

        if not result then
            return true
        end

        local hit = result.Instance

        if AREA51 and hit:IsDescendantOf(AREA51) then
            return false
        end

        local doors = Workspace:FindFirstChild("Doors")

        if doors and hit:IsDescendantOf(doors) then
            return false
        end

        local distanceFromStart = (result.Position - origin).Magnitude

        if distanceFromStart >= direction.Magnitude - 0.1 then
            return true
        end

        local remainingDistance = direction.Magnitude - distanceFromStart

        currentOrigin = result.Position + directionUnit * 0.05
        remainingDirection = directionUnit * remainingDistance
    end

    return true
end

local function KillerAimGetTarget()
    local camera = Workspace.CurrentCamera

    if not camera then
        return nil
    end

    local viewport = camera.ViewportSize
    local center = Vector2.new(
        viewport.X / 2,
        viewport.Y / 2
    )

    local bestHead = nil
    local bestDistance = math.huge

    for _, model in ipairs(Killers:GetChildren()) do
        if model:IsA("Model") then
            local head = KillerAimGetHead(model)

            if head then
                local aimPosition = KillerAimGetAimPosition(model, head)
                local screenPosition, onScreen =
                    camera:WorldToViewportPoint(aimPosition)

                if onScreen and screenPosition.Z > 0 then
                    local character = LocalPlayer.Character
                    local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
                    local distanceFromPlayer = rootPart and (aimPosition - rootPart.Position).Magnitude or math.huge

                    if distanceFromPlayer > 100 then
                        continue
                    end

                    local screenDistance = (
                        Vector2.new(
                            screenPosition.X,
                            screenPosition.Y
                        ) - center
                    ).Magnitude

                    if screenDistance < bestDistance
                        and KillerAimWallCheck(head) then

                        bestDistance = screenDistance
                        bestHead = head
                    end
                end
            end
        end
    end

    return bestHead
end

local function StopKillerCameraAim()
    if KillerCameraAimConnection then
        KillerCameraAimConnection:Disconnect()
        KillerCameraAimConnection = nil
    end

    KillerAimRestoreQuery()
end

local function StartKillerCameraAim()
    StopKillerCameraAim()
    KillerAimSetupQuery()

    KillerCameraAimConnection = RunService.RenderStepped:Connect(function()
        if not Config.KillerCameraAim then
            return
        end

        local camera = Workspace.CurrentCamera

        if not camera then
            return
        end

        local head = KillerAimGetTarget()

        if not head then
            return
        end

        
        local model = head:FindFirstAncestorOfClass("Model")

        if not model or not model:IsDescendantOf(Killers) then
            return
        end

        local humanoid = model:FindFirstChildOfClass("Humanoid")
            or model:FindFirstChild("Humanoid", true)

        if not humanoid or humanoid.Health <= 0 then
            return
        end

        
        if not KillerAimWallCheck(head) then
            return
        end

        local cameraPosition = camera.CFrame.Position
        local aimPosition = KillerAimGetAimPosition(model, head)

        if not aimPosition then
            return
        end

        local character = LocalPlayer.Character
        local playerRoot = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
        local killerRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")

        camera.CFrame = CFrame.lookAt(
            cameraPosition,
            aimPosition
        )
    end)
end


local muteFireConnections = {}

local function muteFireSound(obj)
    if not obj or not obj:IsA("Sound") or obj.Name ~= "Fire" then
        return
    end
    pcall(function()
        obj.Volume = 0
        obj:Stop()
    end)
end

local function watchFireTool(tool)
    if not Config.MuteFireSound or not tool:IsA("Tool") then return end
    for _, obj in ipairs(tool:GetDescendants()) do
        muteFireSound(obj)
    end
    if muteFireConnections[tool] then
        muteFireConnections[tool]:Disconnect()
    end
    muteFireConnections[tool] = tool.DescendantAdded:Connect(function(obj)
        if Config.MuteFireSound then muteFireSound(obj) end
    end)
end

local function stopMuteFireSound()
    for tool, connection in pairs(muteFireConnections) do
        if connection then connection:Disconnect() end
        muteFireConnections[tool] = nil
    end
end

local function startMuteFireSound()
    stopMuteFireSound()
    local characters = Workspace:FindFirstChild("Characters to kill")
    if not characters then return end
    local character = characters:FindFirstChild(LocalPlayer.Name)
    if not character then return end

    for _, obj in ipairs(character:GetChildren()) do
        watchFireTool(obj)
    end

    muteFireConnections._character = character.ChildAdded:Connect(function(obj)
        if Config.MuteFireSound then
            task.defer(function() watchFireTool(obj) end)
        end
    end)
end

local NoclipDoorsBackup = {}
local NoclipDoorsDescendantConnection = nil

local function NoclipDoorsApplyPart(obj)
    if not obj or not obj:IsA("BasePart") or obj.Name ~= "Door" then
        return
    end

    if NoclipDoorsBackup[obj] == nil then
        NoclipDoorsBackup[obj] = obj.CanCollide
    end

    pcall(function()
        obj.CanCollide = false
    end)
end

local function NoclipDoorsApplyAll()
    local doors = Workspace:FindFirstChild("Doors")
    if not doors then
        return
    end

    for _, obj in ipairs(doors:GetDescendants()) do
        NoclipDoorsApplyPart(obj)
    end
end

local function NoclipDoorsRestore()
    for obj, originalCanCollide in pairs(NoclipDoorsBackup) do
        if obj and obj.Parent then
            pcall(function()
                obj.CanCollide = originalCanCollide
            end)
        end
    end

    table.clear(NoclipDoorsBackup)
end

local function StopNoclipDoors()
    if NoclipDoorsDescendantConnection then
        NoclipDoorsDescendantConnection:Disconnect()
        NoclipDoorsDescendantConnection = nil
    end

    NoclipDoorsRestore()
end

local function StartNoclipDoors()
    StopNoclipDoors()

    local doors = Workspace:FindFirstChild("Doors")
    if not doors then
        return
    end

    NoclipDoorsApplyAll()

    NoclipDoorsDescendantConnection = doors.DescendantAdded:Connect(function(obj)
        if Config.NoclipDoors then
            task.defer(function()
                NoclipDoorsApplyPart(obj)
            end)
        end
    end)
end


-- Killer: More damage
local KillerMoreDamageMultiplier = 2
local KillerMoreDamageBackup = {}

local function KillerMoreDamageIsMyKiller(model)
    if not model or not model:IsA("Model") or not model:IsDescendantOf(Killers) then return false end
    local camera = Workspace.CurrentCamera
    if not camera then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Humanoid", true)
    return humanoid ~= nil and camera.CameraSubject == humanoid
end

local function KillerMoreDamageRestore()
    for obj, original in pairs(KillerMoreDamageBackup) do
        if obj and obj.Parent then
            pcall(function() obj.Value = original end)
        end
    end
    table.clear(KillerMoreDamageBackup)
end

local function KillerMoreDamageApplyTo(model)
    if not Config.KillerMoreDamage or not KillerMoreDamageIsMyKiller(model) then return end
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            local name = string.lower(obj.Name)
            if name == "damage" or name == "damageamount" or name == "attackdamage" or name == "meleedamage" or name == "hitdamage" then
                if KillerMoreDamageBackup[obj] == nil then KillerMoreDamageBackup[obj] = obj.Value end
                pcall(function() obj.Value = KillerMoreDamageBackup[obj] * KillerMoreDamageMultiplier end)
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not Config.KillerMoreDamage then
        if next(KillerMoreDamageBackup) ~= nil then KillerMoreDamageRestore() end
        return
    end
    local found = false
    for _, killer in ipairs(Killers:GetChildren()) do
        if KillerMoreDamageIsMyKiller(killer) then
            found = true
            KillerMoreDamageApplyTo(killer)
            break
        end
    end
    if not found and next(KillerMoreDamageBackup) ~= nil then KillerMoreDamageRestore() end
end)

Killers.ChildAdded:Connect(function(killer)
    if Config.KillerMoreDamage then
        task.defer(function() KillerMoreDamageApplyTo(killer) end)
    end
end)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Saktkia51 Script",
    Icon = 0,
    LoadingTitle = "Made by Eftyno or \"Homer Vulnerabilities Lol\"",
    LoadingSubtitle = "I create another account btw",
    Theme = "Default",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Saktkia51 by me",
        FileName = "Place_" .. tostring(game.PlaceId)
    },

    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },

    KeySystem = false
})

-- Tabs criadas antecipadamente para evitar nil em CreateToggle/CreateButton/CreateSlider.
local CombatTab = Window:CreateTab("Combat", 4483362458)
local ESPTab = Window:CreateTab("Visual", 4483362458)
local MapTab = Window:CreateTab("Map", 4483362458)
local KillerTab = Window:CreateTab("Killer", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

CombatTab:CreateSection("Combat")
ESPTab:CreateSection("Visual")
MapTab:CreateSection("Map")
KillerTab:CreateSection("Killer")
MiscTab:CreateSection("Misc")
TeleportTab:CreateSection("Teleport")


-- ============================================================
-- KILL ALL / KILLER ORBIT
-- Quando o jogador for Killer, procura o player vivo mais
-- próximo em Workspace["Characters to kill"], ignorando:
--   * LocalPlayer
--   * jogadores mortos
--   * personagens dentro de Workspace.Killers
--
-- Ao encontrar um alvo:
--   * teleporta para 0.5 stud
--   * orbita muito rápido
--   * gira o próprio personagem muito rápido
-- Quando o alvo deixa de ser válido, procura o próximo.
-- ============================================================

local KillAllTarget = nil
local KillAllOrbitAngle = 0
local KillAllTeleported = false

local KILL_ALL_MAX_DISTANCE = 1000
local KILL_ALL_MAX_TARGET_Y = 500
local KILL_ALL_ORBIT_DISTANCE = 0.5
local KILL_ALL_ORBIT_SPEED = 150
local KILL_ALL_SPIN_SPEED = 2000

local function KillAllIsKiller()
    local camera = Workspace.CurrentCamera
    if not camera then
        return false
    end

    local subject = camera.CameraSubject
    if not subject then
        return false
    end

    return subject:IsDescendantOf(Killers)
end

local function KillAllIsAlive(character)
    if not character then
        return false
    end

    local humanoid =
        character:FindFirstChildOfClass("Humanoid")
        or character:FindFirstChild("Humanoid", true)

    return humanoid ~= nil and humanoid.Health > 0
end

local function KillAllIsKillerCharacter(character)
    return character ~= nil
        and character:IsDescendantOf(Killers)
end

local function KillAllGetClosestTarget()
    local myCharacter = LocalPlayer.Character
    if not myCharacter then
        return nil
    end

    local myRoot =
        myCharacter:FindFirstChild("HumanoidRootPart")
        or myCharacter:FindFirstChild("Torso")

    if not myRoot then
        return nil
    end

    local charactersFolder =
        Workspace:FindFirstChild("Characters to kill")

    if not charactersFolder then
        return nil
    end

    local closestPlayer = nil
    local closestDistance = KILL_ALL_MAX_DISTANCE

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character

            if character
                and character:IsDescendantOf(charactersFolder)
                and not KillAllIsKillerCharacter(character)
                and KillAllIsAlive(character) then

                local targetRoot =
                    character:FindFirstChild("HumanoidRootPart")
                    or character:FindFirstChild("Torso")

                if targetRoot and targetRoot.Position.Y <= KILL_ALL_MAX_TARGET_Y then
                    local distance =
                        (targetRoot.Position - myRoot.Position).Magnitude

                    if distance <= closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function KillAllReset()
    KillAllTarget = nil
    KillAllOrbitAngle = 0
    KillAllTeleported = false
end

local function KillAllStep(dt)
    if not Config.KillAll or not KillAllIsKiller() then
        KillAllReset()
        return
    end

    local myCharacter = LocalPlayer.Character
    if not myCharacter then
        return
    end

    local myRoot =
        myCharacter:FindFirstChild("HumanoidRootPart")
        or myCharacter:FindFirstChild("Torso")

    if not myRoot then
        return
    end

    local charactersFolder =
        Workspace:FindFirstChild("Characters to kill")

    if not charactersFolder then
        KillAllReset()
        return
    end

    if not KillAllTarget then
        KillAllTarget = KillAllGetClosestTarget()
        KillAllTeleported = false
        KillAllOrbitAngle = 0
    end

    if not KillAllTarget then
        return
    end

    local targetCharacter = KillAllTarget.Character

    if not targetCharacter
        or not targetCharacter:IsDescendantOf(charactersFolder)
        or KillAllIsKillerCharacter(targetCharacter)
        or not KillAllIsAlive(targetCharacter) then

        KillAllTarget = nil
        KillAllTeleported = false
        KillAllOrbitAngle = 0
        return
    end

    local targetRoot =
        targetCharacter:FindFirstChild("HumanoidRootPart")
        or targetCharacter:FindFirstChild("Torso")

    if not targetRoot then
        KillAllTarget = nil
        KillAllTeleported = false
        return
    end

    -- Nunca atacar/teleportar para jogadores acima de Y = 500.
    if targetRoot.Position.Y > KILL_ALL_MAX_TARGET_Y then
        KillAllTarget = nil
        KillAllTeleported = false
        KillAllOrbitAngle = 0
        return
    end

    if not KillAllTeleported then
        myRoot.CFrame =
            targetRoot.CFrame
            * CFrame.new(0, 0, -KILL_ALL_ORBIT_DISTANCE)

        KillAllTeleported = true
    end

    -- Órbita
    KillAllOrbitAngle += KILL_ALL_ORBIT_SPEED * dt

    local orbitOffset = Vector3.new(
        math.cos(KillAllOrbitAngle) * KILL_ALL_ORBIT_DISTANCE,
        0,
        math.sin(KillAllOrbitAngle) * KILL_ALL_ORBIT_DISTANCE
    )

    local orbitPosition =
        targetRoot.Position + orbitOffset

    -- Giro muito rápido do próprio personagem
    local spinAngle =
        math.rad(KILL_ALL_SPIN_SPEED) * dt

    myRoot.CFrame =
        CFrame.lookAt(
            orbitPosition,
            targetRoot.Position
        )
        * CFrame.Angles(0, spinAngle, 0)
end

local KillAllConnection = RunService.RenderStepped:Connect(function(dt)
    KillAllStep(dt)
end)


-- ============================================================
-- KILL PLAYER
-- Select Player mostra somente jogadores que atualmente possuem
-- um Character dentro de Workspace["Characters to kill"].
-- A lista e atualizada continuamente e tambem reage a mortes,
-- respawns e mudancas no Characters to kill.
-- O metodo de ataque e o mesmo do Kill All, mas somente no alvo
-- selecionado. O botao so funciona enquanto somos Killer.
-- No Place 4678052190, alvos acima de Y = 500 sao ignorados.
-- ============================================================

local SelectedKillPlayer = nil
local KillPlayerTarget = nil
local KillPlayerOrbitAngle = 0
local KillPlayerTeleported = false
local killPlayerDropdown = nil
local killPlayerListKey = ""
local updatingKillPlayerDropdown = false
local KILL_PLAYER_UPDATE_INTERVAL = 0.25

local function KillPlayerTargetAllowed(player)
    if not player or player == LocalPlayer then
        return false
    end

    local charactersFolder = Workspace:FindFirstChild("Characters to kill")
    if not charactersFolder then
        return false
    end

    local character = player.Character
    if not character or not character:IsDescendantOf(charactersFolder) then
        return false
    end

    if KillAllIsKillerCharacter(character) or not KillAllIsAlive(character) then
        return false
    end

    local root = character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")

    if not root then
        return false
    end

    if game.PlaceId == 4678052190 and root.Position.Y > KILL_ALL_MAX_TARGET_Y then
        return false
    end

    return true
end

local function GetKillPlayerOptions()
    local options = {}
    local seen = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if KillPlayerTargetAllowed(player) and not seen[player.Name] then
            seen[player.Name] = true
            options[#options + 1] = player.Name
        end
    end

    table.sort(options, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    return options
end

local function KillPlayerReset()
    KillPlayerTarget = nil
    KillPlayerOrbitAngle = 0
    KillPlayerTeleported = false
end

local function UpdateKillPlayerDropdown()
    if updatingKillPlayerDropdown or not killPlayerDropdown then
        return
    end

    updatingKillPlayerDropdown = true

    pcall(function()
        local options = GetKillPlayerOptions()
        local key = table.concat(options, "\31")

        if key ~= killPlayerListKey then
            killPlayerListKey = key

            local selectedStillValid = false
            if SelectedKillPlayer then
                for _, name in ipairs(options) do
                    if name == SelectedKillPlayer then
                        selectedStillValid = true
                        break
                    end
                end
            end

            if not selectedStillValid then
                SelectedKillPlayer = nil
                KillPlayerReset()
            end

            killPlayerDropdown:Refresh(options, false)
        end
    end)

    updatingKillPlayerDropdown = false
end

local function KillPlayerStep(dt)
    if not KillPlayerTarget then
        return
    end

    if not Config.KillAll and not KillAllIsKiller() then
        KillPlayerReset()
        return
    end

    -- Mesmo se Kill All estiver ligado, Kill Player continua usando
    -- somente o alvo escolhido; os dois sistemas nao compartilham alvo.
    if not KillAllIsKiller() then
        KillPlayerReset()
        return
    end

    local myCharacter = LocalPlayer.Character
    if not myCharacter then
        KillPlayerReset()
        return
    end

    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
        or myCharacter:FindFirstChild("Torso")

    if not myRoot then
        KillPlayerReset()
        return
    end

    local charactersFolder = Workspace:FindFirstChild("Characters to kill")
    if not charactersFolder then
        KillPlayerReset()
        return
    end

    if not KillPlayerTargetAllowed(KillPlayerTarget) then
        KillPlayerReset()
        UpdateKillPlayerDropdown()
        return
    end

    local targetCharacter = KillPlayerTarget.Character
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        or targetCharacter:FindFirstChild("Torso")

    if not targetRoot then
        KillPlayerReset()
        return
    end

    if not KillPlayerTeleported then
        myRoot.CFrame = targetRoot.CFrame
            * CFrame.new(0, 0, -KILL_ALL_ORBIT_DISTANCE)
        KillPlayerTeleported = true
    end

    KillPlayerOrbitAngle += KILL_ALL_ORBIT_SPEED * dt

    local orbitOffset = Vector3.new(
        math.cos(KillPlayerOrbitAngle) * KILL_ALL_ORBIT_DISTANCE,
        0,
        math.sin(KillPlayerOrbitAngle) * KILL_ALL_ORBIT_DISTANCE
    )

    local orbitPosition = targetRoot.Position + orbitOffset

    -- Acumula o giro para manter a rotacao realmente rapida.
    myRoot.CFrame = CFrame.lookAt(
        orbitPosition,
        targetRoot.Position
    ) * CFrame.Angles(0, KillPlayerOrbitAngle * (KILL_ALL_SPIN_SPEED / KILL_ALL_ORBIT_SPEED), 0)
end

local KillPlayerConnection = RunService.RenderStepped:Connect(function(dt)
    KillPlayerStep(dt)
end)

local function BindKillPlayerPlayer(player)
    if player == LocalPlayer then
        return
    end

    local function refresh()
        task.defer(UpdateKillPlayerDropdown)
    end

    player.CharacterAdded:Connect(function(character)
        refresh()

        local humanoid = character:FindFirstChildOfClass("Humanoid")
            or WaitForChildContinue(character, "Humanoid", 5)

        if humanoid then
            humanoid.Died:Connect(function()
                if KillPlayerTarget == player then
                    KillPlayerReset()
                end
                refresh()
            end)
        end
    end)

    player.CharacterRemoving:Connect(function()
        if KillPlayerTarget == player then
            KillPlayerReset()
        end
        refresh()
    end)

    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                if KillPlayerTarget == player then
                    KillPlayerReset()
                end
                refresh()
            end)
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    BindKillPlayerPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
    BindKillPlayerPlayer(player)
    task.defer(UpdateKillPlayerDropdown)
end)

Players.PlayerRemoving:Connect(function(player)
    if KillPlayerTarget == player then
        KillPlayerReset()
    end
    if SelectedKillPlayer == player.Name then
        SelectedKillPlayer = nil
    end
    task.defer(UpdateKillPlayerDropdown)
end)

task.spawn(function()
    while task.wait(KILL_PLAYER_UPDATE_INTERVAL) do
        pcall(UpdateKillPlayerDropdown)
    end
end)


local infAmmoToggle
local infAmmo2Toggle

infAmmoToggle = CombatTab:CreateToggle({
    Name = "Inf Ammo",
    CurrentValue = Config.InfAmmo,
    Flag = "InfAmmo",
    Callback = function(Value)
        Config.InfAmmo = Value

        if Value then
            Config.InfAmmo2 = false
            if infAmmo2Toggle then
                infAmmo2Toggle:Set(false)
            end
        end

        applyWeaponToggles()
    end
})

infAmmo2Toggle = CombatTab:CreateToggle({
    Name = "Inf Ammo 2",
    CurrentValue = Config.InfAmmo2,
    Flag = "InfAmmo2",
    Callback = function(Value)
        Config.InfAmmo2 = Value

        if Value then
            Config.InfAmmo = false
            if infAmmoToggle then
                infAmmoToggle:Set(false)
            end

            -- Inf Ammo 2 nao altera as propriedades da arma.
            -- Ele apenas observa o segundo numero de AmmoLeft.
            applyWeaponToggles()
        end
    end
})

CombatTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = Config.NoRecoil,
    Flag = "NoRecoil",
    Callback = function(Value)
        Config.NoRecoil = Value
        applyWeaponToggles()
    end
})

CombatTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = Config.NoSpread,
    Flag = "NoSpread",
    Callback = function(Value)
        Config.NoSpread = Value
        applyWeaponToggles()
    end
})

CombatTab:CreateToggle({
    Name = "2x Fire Rate [BETA]",
    CurrentValue = Config.FireRate2x,
    Flag = "FireRate2x",
    Callback = function(Value)
        Config.FireRate2x = Value

        if not Value then
            for stats, backup in pairs(FireRateStatsBackup) do
                pcall(function()
                    stats.shoot_wait = backup.shoot_wait
                    stats.fire_rate = backup.fire_rate
                end)
                FireRateStatsBackup[stats] = nil
            end
        end
    end
})

CombatTab:CreateToggle({
    Name = "No Bolt",
    CurrentValue = Config.NoBolt,
    Flag = "NoBolt",
    Callback = function(Value)
        Config.NoBolt = Value
        applyWeaponToggles()

        if Value then
            aplicarAnimacoesNoBolt()
        else
            restaurarAnimacoesNoBolt()
        end
    end
})

CombatTab:CreateToggle({
    Name = "Bullet Speed",
    CurrentValue = Config.BulletSpeed3x,
    Flag = "BulletSpeed3x",
    Callback = function(Value)
        Config.BulletSpeed3x = Value

        if Value then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                applyBulletSpeed(obj)
            end
        else
            restoreBulletSpeed()
        end
    end
})

CombatTab:CreateSlider({
    Name = "Bullet Speed Multiplier",
    Range = {1.2, 7.5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = Config.BulletSpeedMultiplier,
    Flag = "BulletSpeedMultiplier",
    Callback = function(Value)
        Config.BulletSpeedMultiplier = Value

        if Config.BulletSpeed3x then
            restoreBulletSpeed()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                applyBulletSpeed(obj)
            end
        end
    end
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Neck", "Torso"},
    CurrentOption = {Config.KillerAimPart},
    MultipleOptions = false,
    Flag = "KillerAimPart",
    Callback = function(Option)
        Config.KillerAimPart = Option[1] or Option
    end
})

CombatTab:CreateToggle({
    Name = "Killer Camera Aim",
    CurrentValue = Config.KillerCameraAim,
    Flag = "KillerCameraAim",
    Callback = function(Value)
        Config.KillerCameraAim = Value

        if Value then
            StartKillerCameraAim()
        else
            StopKillerCameraAim()
        end
    end
})

local killAllToggle = KillerTab:CreateToggle({
    Name = "Kill All",
    CurrentValue = Config.KillAll,
    Flag = "KillAll",
    Callback = function(Value)
        Config.KillAll = Value

        if not Value then
            KillAllReset()
        end
    end
})

killPlayerDropdown = KillerTab:CreateDropdown({
    Name = "Select Player",
    Options = {},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "SelectKillPlayer",
    Callback = function(Option)
        SelectedKillPlayer = Option[1] or Option
        KillPlayerReset()

        if SelectedKillPlayer then
            local player = Players:FindFirstChild(SelectedKillPlayer)
            if KillPlayerTargetAllowed(player) then
                KillPlayerTarget = player
            end
        end
    end
})

KillerTab:CreateButton({
    Name = "Kill Player",
    Callback = function()
        -- O botao so funciona enquanto o LocalPlayer for Killer.
        if not KillAllIsKiller() then
            return
        end

        if not SelectedKillPlayer then
            return
        end

        local player = Players:FindFirstChild(SelectedKillPlayer)
        if not KillPlayerTargetAllowed(player) then
            KillPlayerReset()
            UpdateKillPlayerDropdown()
            return
        end

        -- Se Kill All estiver ligado, desligamos para evitar que os dois
        -- sistemas tentem controlar o personagem ao mesmo tempo.
        Config.KillAll = false
        KillAllReset()
        if killAllToggle then
            killAllToggle:Set(false)
        end

        KillPlayerTarget = player
        KillPlayerOrbitAngle = 0
        KillPlayerTeleported = false
    end
})

UpdateKillPlayerDropdown()

CombatTab:CreateToggle({
    Name = "WallCheck",
    CurrentValue = Config.WallCheck,
    Flag = "WallCheck",
    Callback = function(Value)
        Config.WallCheck = Value
    end
})

gunKillAuraToggle = CombatTab:CreateToggle({
    Name = "Gun Kill Aura(Very op lol)",
    CurrentValue = Config.GunKillAura,
    Flag = "GunKillAura",
    Callback = function(Value)
        Config.GunKillAura = Value

        if not Value and not gunKillAuraAutoChanging then
            gunKillAuraAutoDisabled = false
            table.clear(gunKillAuraTrackedBullets)
            table.clear(gunKillAuraChaseTargets)
        end
    end
})




ESPTab:CreateToggle({
    Name = "Killer ESP",
    CurrentValue = Config.KillerESP,
    Flag = "KillerESP",
    Callback = function(Value)
        Config.KillerESP = Value

        if not Value then
            clearKillerESP()
        end
    end
})

ESPTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = Config.PlayerESP,
    Flag = "PlayerESP",
    Callback = function(Value)
        Config.PlayerESP = Value

        if Value then
            refreshPlayerESP()
        else
            clearPlayerESP()
        end
    end
})

ESPTab:CreateToggle({
    Name = "ESP Name",
    CurrentValue = Config.ESPName,
    Flag = "ESPName",
    Callback = function(Value)
        Config.ESPName = Value

        if not Value then
            clearPlayerESP()
            clearKillerESP()
            return
        end

        refreshPlayerESP()

        for killer, data in pairs(trackedKillers) do
            if Config.KillerESP and killer.Parent == Killers
                and not isKillerControlledByLocalCamera(killer) then

                local controllerName = data.controllerName

                if not controllerName or controllerName == "" then
                    controllerName = getKillerControllerDisplayName(killer)
                    data.controllerName = controllerName
                end

                createESPName(killer, controllerName or killer.Name, KILLER_COLOR)
            else
                removeESPName(killer)
            end
        end
    end
})

ESPTab:CreateToggle({
    Name = "No Fog",
    CurrentValue = Config.NoFog,
    Flag = "NoFog",
    Callback = function(Value)
        Config.NoFog = Value
        applyNoFog()
    end
})

if espArmasAutorizado then
    ESPTab:CreateToggle({
        Name = "Weapon ESP",
        CurrentValue = Config.WeaponESP,
        Flag = "WeaponESP",
        Callback = function(Value)
            Config.WeaponESP = Value

            if not Value then
                for nomeArma, tracker in pairs(criadosArmas) do
                    if tracker and tracker.Parent then
                        tracker:Destroy()
                    end
                    criadosArmas[nomeArma] = nil
                end
            else
                if not pastaArmasESP or not pastaArmasESP.Parent then
                    pastaArmasESP = workspace:FindFirstChild("ESP_Armas_Temp")

                    if not pastaArmasESP then
                        pastaArmasESP = InstanceNew("Folder")
                        pastaArmasESP.Name = "ESP_Armas_Temp"
                        pastaArmasESP.Parent = workspace
                    end
                end
            end
        end
    })
else
    
    Config.WeaponESP = false
end

-- ============================================================
-- WEAPON PICKER
-- Funciona em qualquer Place.
-- No Place 4678052190 existe uma estrutura especial:
-- Workspace.Weapons.Arma.Arma
-- Podem existir 2, 3, 4... modelos com o mesmo nome.
-- ============================================================

local selectedWeaponName = nil
local weaponDropdown = nil
local weaponPickerUpdating = false
local lastWeaponListKey = ""
local WEAPON_PICKER_INTERVAL = 0.35

local function getWeaponsContainer()
    local weapons = Workspace:FindFirstChild("Weapons")

    if weapons then
        return weapons
    end

    return Workspace:FindFirstChild("weapon")
end

local function hasBackpackWeapon(name)
    if not name or name == "" then
        return false
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        return false
    end

    return backpack:FindFirstChild(name) ~= nil
end

local function isWeaponObject(obj)
    return obj and (
        obj:IsA("Model")
        or obj:IsA("BasePart")
        or obj:IsA("Folder")
    )
end

local function getAvailableWeaponNames()
    local result = {}
    local seen = {}
    local container = getWeaponsContainer()

    if not container then
        return result
    end

    if game.PlaceId == 4678052190 then
        -- Estrutura:
        -- Workspace.Weapons.Arma.Arma
        -- Pode haver vários Arma dentro de Weapons.Arma.
        for _, weaponFolder in ipairs(container:GetChildren()) do
            if isWeaponObject(weaponFolder) then
                local weaponName = weaponFolder.Name
                local foundSameNameModel = false

                -- A arma só é válida se o PAI existir e tiver
                -- pelo menos um FILHO com exatamente o mesmo nome.
                -- Podem existir 2, 3, 4... cópias; continua aparecendo
                -- apenas uma vez no dropdown.
                for _, child in ipairs(weaponFolder:GetChildren()) do
                    if child.Name == weaponName
                        and (child:IsA("Model") or child:IsA("BasePart")) then
                        foundSameNameModel = true
                        break
                    end
                end
                -- Se o pai desaparecer, ele nem chega neste loop.
                -- Se o pai existir mas o filho de mesmo nome desaparecer,
                -- a arma também sai do dropdown.
                if foundSameNameModel
                    and not hasBackpackWeapon(weaponName)
                    and not seen[weaponName] then

                    seen[weaponName] = true
                    result[#result + 1] = weaponName
                end
            end
        end
    else
        -- Estrutura normal:
        -- Workspace.Weapons.Arma
        -- ou Workspace.weapon.Arma
        for _, weapon in ipairs(container:GetChildren()) do
            if isWeaponObject(weapon)
                and not hasBackpackWeapon(weapon.Name)
                and not seen[weapon.Name] then

                seen[weapon.Name] = true
                result[#result + 1] = weapon.Name
            end
        end
    end

    table.sort(result)
    return result
end

local function getWeaponPhysicalObject(name)
    if not name or name == "" then
        return nil
    end

    local container = getWeaponsContainer()

    if not container then
        return nil
    end

    if game.PlaceId == 4678052190 then
        -- Estrutura física real:
        -- Workspace.Weapons.<Arma>.Hitbox
        local weaponFolder = container:FindFirstChild(name)

        if not weaponFolder then
            return nil
        end

        return weaponFolder
    end

    -- Outros Places:
    -- Workspace.Weapons.Arma
    -- ou Workspace.weapon.Arma
    return container:FindFirstChild(name)
end

local function getWeaponHitbox(name)
    local physicalWeapon = getWeaponPhysicalObject(name)
    if not physicalWeapon then
        return nil
    end

    local hitbox = physicalWeapon:FindFirstChild("Hitbox", true)

    if hitbox then
        if hitbox:IsA("BasePart") then
            return hitbox
        end

        -- Caso Hitbox seja um Model/Folder contendo a peça física.
        local part = hitbox:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part
        end
    end

    -- Alguns mapas podem usar a própria arma como BasePart.
    if physicalWeapon:IsA("BasePart") then
        return physicalWeapon
    end

    return nil
end

local function getWeaponPrompt(name)
    local hitbox = getWeaponHitbox(name)
    if not hitbox then
        return nil, nil
    end

    -- Procura o prompt dentro do Hitbox inteiro.
    local prompt = hitbox:FindFirstChild("ProximityPrompt", true)

    if prompt and prompt:IsA("ProximityPrompt") then
        return hitbox, prompt
    end

    -- Caso o ProximityPrompt esteja no objeto-pai do Hitbox.
    local physicalWeapon = getWeaponPhysicalObject(name)
    if physicalWeapon then
        prompt = physicalWeapon:FindFirstChild("ProximityPrompt", true)

        if prompt and prompt:IsA("ProximityPrompt") then
            return hitbox, prompt
        end
    end

    return hitbox, nil
end

local function updateWeaponDropdown()
    if weaponPickerUpdating or not weaponDropdown then
        return
    end

    weaponPickerUpdating = true

    pcall(function()
        local options = getAvailableWeaponNames()
        local key = table.concat(options, "\31")

        if key ~= lastWeaponListKey then
            lastWeaponListKey = key

            if selectedWeaponName then
                local stillExists = false
                for _, name in ipairs(options) do
                    if name == selectedWeaponName then
                        stillExists = true
                        break
                    end
                end

                if not stillExists then
                    selectedWeaponName = nil
                end
            end

            weaponDropdown:Refresh(options, false)
        end
    end)

    weaponPickerUpdating = false
end

local function pickWeapon(name)
    if not name or name == "" then
        return
    end

    -- Se já está no Backpack, não tenta pegar novamente.
    if hasBackpackWeapon(name) then
        updateWeaponDropdown()
        return
    end

    local hitbox, prompt = getWeaponPrompt(name)

    if not hitbox or not prompt then
        updateWeaponDropdown()
        return
    end

    local character = LocalPlayer.Character
    if not character or not character.Parent then
        return
    end

    local originalPivot = character:GetPivot()
    local teleported = false

    local success = pcall(function()
        -- 4678052190 precisa ir até a peça física
        -- Workspace.Weapons.Arma.Arma.Hitbox.
        character:PivotTo(hitbox.CFrame)
        teleported = true

        -- Dá um pequeno tempo para o personagem realmente atualizar
        -- a posição antes de disparar o prompt.
        task.wait(0.05)

        fireproximityprompt(prompt)

        -- Espera o Backpack receber a arma.
        local timeout = os.clock() + 0.5
        repeat
            task.wait(0.03)
        until hasBackpackWeapon(name) or os.clock() >= timeout
    end)

    -- SEMPRE volta para a posição original.
    pcall(function()
        character:PivotTo(originalPivot)
    end)

    if not success or not teleported then
        return
    end

    updateWeaponDropdown()
end

local function pickAllWeapons()
    local options = getAvailableWeaponNames()
    local alreadyPicked = {}

    for _, name in ipairs(options) do
        if not alreadyPicked[name] then
            alreadyPicked[name] = true

            -- Revalida antes de cada arma porque o Backpack muda
            -- depois que o prompt é executado.
            if not hasBackpackWeapon(name) then
                pickWeapon(name)
                task.wait(0.08)
            end
        end
    end

    updateWeaponDropdown()
end

weaponDropdown = MapTab:CreateDropdown({
    Name = "Select Weapon",
    Options = {},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "SelectWeapon",
    Callback = function(Option)
        selectedWeaponName = Option[1] or Option
    end
})

MapTab:CreateButton({
    Name = "Pick Weapon",
    Callback = function()
        pickWeapon(selectedWeaponName)
    end
})

MapTab:CreateButton({
    Name = "Pick All Weapons",
    Callback = function()
        pickAllWeapons()
    end
})

-- Atualiza continuamente porque armas podem aparecer/desaparecer
-- durante a partida e também podem entrar/sair do Backpack.
task.spawn(function()
    while task.wait(WEAPON_PICKER_INTERVAL) do
        pcall(updateWeaponDropdown)
    end
end)

updateWeaponDropdown()


MapTab:CreateToggle({
    Name = "No Kill Bricks",
    CurrentValue = Config.NoKillBricks,
    Flag = "NoKillBricks",
    Callback = function(Value)
        Config.NoKillBricks = Value

        if Value then
            for _, obj in ipairs(AREA51:GetDescendants()) do
                if obj.Name == "Spinner" and obj:IsA("Model") then
                    substituirSpinner(obj)
                elseif obj:IsA("BasePart") then
                    deletarPerigos(obj)
                end
            end

            for _, obj in ipairs(teleporter:GetDescendants()) do
                desativarColisao(obj)
            end
        else
            restaurarNoKillBricks()
        end
    end
})

MiscTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = Config.SpeedBoost,
    Flag = "SpeedBoost",
    Callback = function(Value)
        Config.SpeedBoost = Value

        if Value then
            startSpeedBoost()
        else
            stopSpeedBoost()
        end
    end
})

MiscTab:CreateSlider({
    Name = "+Speed",
    Range = {1, 100},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = Config.SpeedBoostAmount,
    Flag = "SpeedBoostAmount",
    Callback = function(Value)
        Config.SpeedBoostAmount = Value
    end
})

MiscTab:CreateToggle({
    Name = "Wallbang",
    CurrentValue = Config.Wallbang,
    Flag = "Wallbang",
    Callback = function(Value)
        Config.Wallbang = Value
    end
})

if noBlockChatPlaceAllowed then
    MiscTab:CreateToggle({
        Name = "NoBlockChat [Killer Chat]",
        CurrentValue = Config.NoBlockChat,
        Flag = "NoBlockChat",
        Callback = function(Value)
            Config.NoBlockChat = Value

            if Value then
                reabilitarTextChat()
                reabilitarLegacyChat()
                updateNoBlockChatGui()
            else
                noBlockChatKillerState = false

                if noBlockChatGui then
                    noBlockChatGui.Enabled = false
                end

                restaurarChatOriginal()
            end
        end
    })
end

MiscTab:CreateToggle({
    Name = "Mute Fire Sound",
    CurrentValue = Config.MuteFireSound,
    Flag = "MuteFireSound",
    Callback = function(Value)
        Config.MuteFireSound = Value
        if Value then
            startMuteFireSound()
        else
            stopMuteFireSound()
        end
    end
})

MiscTab:CreateToggle({
    Name = "Noclip Doors",
    CurrentValue = Config.NoclipDoors,
    Flag = "NoclipDoors",
    Callback = function(Value)
        Config.NoclipDoors = Value

        if Value then
            StartNoclipDoors()
        else
            StopNoclipDoors()
        end
    end
})
















KillerTab:CreateToggle({
    Name = "Killer: More damage",
    CurrentValue = Config.KillerMoreDamage,
    Flag = "KillerMoreDamage",
    Callback = function(Value)
        Config.KillerMoreDamage = Value
        if not Value then KillerMoreDamageRestore() end
    end
})

Rayfield:LoadConfiguration()

-- ============================================================
-- TELEPORT
-- ============================================================

local SelectedTeleportKiller = nil
local SelectedTeleportPlayer = nil
local teleportKillerDropdown
local teleportPlayerDropdown
local teleportKillerListKey = ""
local teleportPlayerListKey = ""
local updatingTeleportKillerDropdown = false
local updatingTeleportPlayerDropdown = false

local function TeleportGetRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

local function TeleportGetAliveKillerOptions()
    local options, seen = {}, {}
    for _, killer in ipairs(Killers:GetChildren()) do
        if killer:IsA("Model") and not seen[killer.Name] then
            local hum = killer:FindFirstChildOfClass("Humanoid") or killer:FindFirstChild("Humanoid", true)
            if hum and hum.Health > 0 and TeleportGetRoot(killer) then
                seen[killer.Name] = true
                options[#options + 1] = killer.Name
            end
        end
    end
    table.sort(options, function(a,b) return string.lower(a) < string.lower(b) end)
    return options
end

local function TeleportGetPlayerOptions()
    local options, seen = {}, {}
    local folder = Workspace:FindFirstChild("Characters to kill")
    if not folder then return options end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:IsDescendantOf(folder) and KillAllIsAlive(char) and TeleportGetRoot(char) and not seen[player.Name] then
                seen[player.Name] = true
                options[#options + 1] = player.Name
            end
        end
    end
    table.sort(options, function(a,b) return string.lower(a) < string.lower(b) end)
    return options
end

local function TeleportRefreshKillerDropdown()
    if updatingTeleportKillerDropdown or not teleportKillerDropdown then return end
    updatingTeleportKillerDropdown = true
    pcall(function()
        local options = TeleportGetAliveKillerOptions()
        local key = table.concat(options, "\31")
        if key ~= teleportKillerListKey then
            teleportKillerListKey = key
            local valid = false
            if SelectedTeleportKiller then
                for _, name in ipairs(options) do if name == SelectedTeleportKiller then valid = true break end end
            end
            if not valid then SelectedTeleportKiller = nil end
            teleportKillerDropdown:Refresh(options, false)
        end
    end)
    updatingTeleportKillerDropdown = false
end

local function TeleportRefreshPlayerDropdown()
    if updatingTeleportPlayerDropdown or not teleportPlayerDropdown then return end
    updatingTeleportPlayerDropdown = true
    pcall(function()
        local options = TeleportGetPlayerOptions()
        local key = table.concat(options, "\31")
        if key ~= teleportPlayerListKey then
            teleportPlayerListKey = key
            local valid = false
            if SelectedTeleportPlayer then
                for _, name in ipairs(options) do if name == SelectedTeleportPlayer then valid = true break end end
            end
            if not valid then SelectedTeleportPlayer = nil end
            teleportPlayerDropdown:Refresh(options, false)
        end
    end)
    updatingTeleportPlayerDropdown = false
end

local function TeleportBehindTarget(target)
    local character = LocalPlayer.Character
    local root = TeleportGetRoot(target)
    if not character or not root then return end
    pcall(function()
        character:PivotTo(root.CFrame * CFrame.new(0, 0, 1))
    end)
end

-- ============================================================
-- PROTECT PLAYER / HUMAN SHIELD
-- Stays 1 stud in front of the selected player.
-- Faces the nearest Killer without spinning around.
-- Continues after local respawn until manually disabled.
-- ============================================================
local SelectedProtectPlayer = nil
local protectPlayerDropdown = nil
local protectPlayerListKey = ""
local updatingProtectPlayerDropdown = false
local protectPlayerCharacterConnection = nil
local protectPlayerHeartbeatConnection = nil
local protectPlayerRespawnToken = 0

local function ProtectPlayerGetAliveRoot(character)
    if not character then return nil end

    local hum = character:FindFirstChildOfClass("Humanoid")
        or character:FindFirstChild("Humanoid", true)

    if not hum or hum.Health <= 0 then
        return nil
    end

    return TeleportGetRoot(character)
end

local function ProtectPlayerGetOptions()
    -- Same player-selection system used by "Select Player to teleport".
    return TeleportGetPlayerOptions()
end

local function ProtectPlayerRefreshDropdown()
    if updatingProtectPlayerDropdown or not protectPlayerDropdown then
        return
    end

    updatingProtectPlayerDropdown = true

    pcall(function()
        local options = ProtectPlayerGetOptions()
        local key = table.concat(options, "\31")

        if key ~= protectPlayerListKey then
            protectPlayerListKey = key

            local valid = false

            if SelectedProtectPlayer then
                for _, name in ipairs(options) do
                    if name == SelectedProtectPlayer then
                        valid = true
                        break
                    end
                end
            end

            if not valid then
                SelectedProtectPlayer = nil
            end

            protectPlayerDropdown:Refresh(options, false)
        end
    end)

    updatingProtectPlayerDropdown = false
end

local function ProtectPlayerGetNearestKiller(position)
    local closestKiller = nil
    local closestDistance = math.huge

    if not position then
        return nil
    end

    for _, killer in ipairs(Killers:GetChildren()) do
        if killer:IsA("Model") then
            local root = ProtectPlayerGetAliveRoot(killer)

            if root then
                local distance = (root.Position - position).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closestKiller = killer
                end
            end
        end
    end

    return closestKiller
end

local function ProtectPlayerGetTarget()
    if not SelectedProtectPlayer then
        return nil
    end

    local player = Players:FindFirstChild(SelectedProtectPlayer)
    if not player then
        return nil
    end

    local folder = Workspace:FindFirstChild("Characters to kill")
    local character = player.Character

    if not folder
        or not character
        or not character:IsDescendantOf(folder) then
        return nil
    end

    local root = ProtectPlayerGetAliveRoot(character)

    if not root then
        return nil
    end

    return player, character, root
end

local function ProtectPlayerMoveToShieldPosition()
    if not Config.ProtectPlayer then
        return
    end

    local _, _, targetRoot = ProtectPlayerGetTarget()
    if not targetRoot then
        return
    end

    local character = LocalPlayer.Character
    local myRoot = TeleportGetRoot(character)

    if not character or not myRoot then
        return
    end

    local shieldPosition =
        targetRoot.Position
        + targetRoot.CFrame.LookVector

    local nearestKiller =
        ProtectPlayerGetNearestKiller(targetRoot.Position)

    pcall(function()
        if nearestKiller then
            local killerRoot = ProtectPlayerGetAliveRoot(nearestKiller)

            if killerRoot then
                myRoot.CFrame = CFrame.lookAt(
                    shieldPosition,
                    killerRoot.Position
                )
                return
            end
        end

        -- No Killer found: stay in front without artificial spinning.
        myRoot.CFrame =
            CFrame.lookAt(
                shieldPosition,
                shieldPosition + targetRoot.CFrame.LookVector
            )
    end)
end

local function ProtectPlayerStopConnections()
    if protectPlayerHeartbeatConnection then
        pcall(function()
            protectPlayerHeartbeatConnection:Disconnect()
        end)
        protectPlayerHeartbeatConnection = nil
    end

    if protectPlayerCharacterConnection then
        pcall(function()
            protectPlayerCharacterConnection:Disconnect()
        end)
        protectPlayerCharacterConnection = nil
    end
end

local function ProtectPlayerStart()
    ProtectPlayerStopConnections()

    protectPlayerRespawnToken += 1
    local token = protectPlayerRespawnToken

    protectPlayerHeartbeatConnection =
        RunService.Heartbeat:Connect(function()
            if not Config.ProtectPlayer or token ~= protectPlayerRespawnToken then
                return
            end

            ProtectPlayerMoveToShieldPosition()
        end)

    protectPlayerCharacterConnection =
        LocalPlayer.CharacterAdded:Connect(function(character)
            if not Config.ProtectPlayer or token ~= protectPlayerRespawnToken then
                return
            end

            task.spawn(function()
                local root = WaitForChildContinue(character, "HumanoidRootPart", 5)
                    or WaitForChildContinue(character, "Torso", 5)

                if not Config.ProtectPlayer or token ~= protectPlayerRespawnToken then
                    return
                end

                if root then
                    task.wait()
                    ProtectPlayerMoveToShieldPosition()
                end
            end)
        end)

    task.defer(ProtectPlayerMoveToShieldPosition)
end

local function ProtectPlayerStop()
    protectPlayerRespawnToken += 1
    ProtectPlayerStopConnections()
end

protectPlayerDropdown = MiscTab:CreateDropdown({
    Name = "Select Player to Protect",
    Options = {},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "SelectProtectPlayer",
    Callback = function(Option)
        SelectedProtectPlayer = Option[1] or Option

        if Config.ProtectPlayer then
            task.defer(ProtectPlayerMoveToShieldPosition)
        end
    end
})

MiscTab:CreateToggle({
    Name = "Protect Player",
    CurrentValue = Config.ProtectPlayer,
    Flag = "ProtectPlayer",
    Callback = function(Value)
        Config.ProtectPlayer = Value

        if Value then
            ProtectPlayerStart()
        else
            ProtectPlayerStop()
        end
    end
})

Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.defer(ProtectPlayerRefreshDropdown)
    end)

    player.CharacterRemoving:Connect(function()
        if SelectedProtectPlayer == player.Name then
            SelectedProtectPlayer = nil
        end

        task.defer(ProtectPlayerRefreshDropdown)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if SelectedProtectPlayer == player.Name then
        SelectedProtectPlayer = nil
    end

    task.defer(ProtectPlayerRefreshDropdown)
end)

task.spawn(function()
    while task.wait(0.25) do
        pcall(ProtectPlayerRefreshDropdown)
    end
end)

teleportKillerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Killer to teleport", Options = {}, CurrentOption = {},
    MultipleOptions = false, Flag = "SelectTeleportKiller",
    Callback = function(Option) SelectedTeleportKiller = Option[1] or Option end
})

teleportPlayerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player to teleport", Options = {}, CurrentOption = {},
    MultipleOptions = false, Flag = "SelectTeleportPlayer",
    Callback = function(Option) SelectedTeleportPlayer = Option[1] or Option end
})

TeleportTab:CreateButton({
    Name = "Tp to Player",
    Callback = function()
        if not SelectedTeleportPlayer then return end
        local player = Players:FindFirstChild(SelectedTeleportPlayer)
        local folder = Workspace:FindFirstChild("Characters to kill")
        if not player or not player.Character or not folder or not player.Character:IsDescendantOf(folder) or not KillAllIsAlive(player.Character) then
            SelectedTeleportPlayer = nil
            TeleportRefreshPlayerDropdown()
            return
        end
        TeleportBehindTarget(player.Character)
    end
})

TeleportTab:CreateButton({
    Name = "Tp to Killer",
    Callback = function()
        if not SelectedTeleportKiller then return end
        local killer = Killers:FindFirstChild(SelectedTeleportKiller)
        if not killer or not killer:IsA("Model") or not KillAllIsAlive(killer) or not TeleportGetRoot(killer) then
            SelectedTeleportKiller = nil
            TeleportRefreshKillerDropdown()
            return
        end
        TeleportBehindTarget(killer)
    end
})

Killers.ChildAdded:Connect(function() task.defer(TeleportRefreshKillerDropdown) end)
Killers.ChildRemoved:Connect(function(killer)
    if SelectedTeleportKiller == killer.Name then SelectedTeleportKiller = nil end
    task.defer(TeleportRefreshKillerDropdown)
end)

local function BindTeleportPlayer(player)
    if player == LocalPlayer then return end
    local function refresh() task.defer(TeleportRefreshPlayerDropdown) end
    player.CharacterAdded:Connect(function(character)
        refresh()
        local hum = character:FindFirstChildOfClass("Humanoid") or WaitForChildContinue(character, "Humanoid", 5)
        if hum then hum.Died:Connect(function()
            if SelectedTeleportPlayer == player.Name then SelectedTeleportPlayer = nil end
            refresh()
        end) end
    end)
    player.CharacterRemoving:Connect(function()
        if SelectedTeleportPlayer == player.Name then SelectedTeleportPlayer = nil end
        refresh()
    end)
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Died:Connect(function()
            if SelectedTeleportPlayer == player.Name then SelectedTeleportPlayer = nil end
            refresh()
        end) end
    end
end

for _, player in ipairs(Players:GetPlayers()) do BindTeleportPlayer(player) end
Players.PlayerAdded:Connect(function(player) BindTeleportPlayer(player); task.defer(TeleportRefreshPlayerDropdown) end)
Players.PlayerRemoving:Connect(function(player)
    if SelectedTeleportPlayer == player.Name then SelectedTeleportPlayer = nil end
    task.defer(TeleportRefreshPlayerDropdown)
end)

task.spawn(function()
    while task.wait(0.25) do
        pcall(TeleportRefreshKillerDropdown)
        pcall(TeleportRefreshPlayerDropdown)
    end
end)

TeleportRefreshKillerDropdown()
TeleportRefreshPlayerDropdown()

TeleportTab:CreateButton({
    Name = "TP Spawn",
    Callback = function()
        local character = LocalPlayer.Character
        if not character then return end
        pcall(function()
            character:PivotTo(CFrame.new(368, 512, 401))
        end)
    end
})

TeleportTab:CreateButton({
    Name = "TP Entrance",
    Callback = function()
        local character = LocalPlayer.Character
        if not character then return end
        pcall(function()
            character:PivotTo(CFrame.new(324, 314, 368))
        end)
    end
})

