local devText = [[
This script only works with "Minecraft 1.20.6".

If you're using it in another fake Minecraft game, please don't worry. I'll add support for it soon!
]]

local WindUI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
  Title = "Minecraft 1.20.6 | TEST",
  Icon = "star",
  Theme = "Dark",
})

local Tab = Window:Tab({ Title = "Hack", Icon = "home" })

if game.PlaceId ~= 96524407319918 then
    local Dialog = Window:Dialog({
        Icon = "bird",
        Title = "Not support",
        Content = devText,
        Buttons = {
            {
                Title = "Teleport To",
                Callback = function()
                    local TeleportService = game:GetService("TeleportService")

                    pcall(function()
                        TeleportService:Teleport(96524407319918, game.Players.LocalPlayer)
                    end)
                    Window:Close()
                    Dialog:Close()
                end,
            },
            {
                Title = "Ok",
                Callback = function()
                    Window:Close()
                    Dialog:Close()
                end,
            },
        },
    })
else
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    local ESP = false

    local SelectedOre = {
        Iron = true,
        Coal = true,
        Redstone = true,
        Diamond = true,
        Gold = true
    }

    local SelectedMode = {
        Highlight = true,
        Line = true,
        Name = true,
        Cluster = true,
        ClickToTeleport = true
    }

    local guis = {}

    local function UpdateMultiSelection(targetTable, dropdownData)
        for k in pairs(targetTable) do
            targetTable[k] = nil
        end
        for k, v in pairs(dropdownData) do
            if type(k) == "number" then
                targetTable[v] = true 
            else
                targetTable[k] = v   
            end
        end
    end

    Tab:Toggle({
        Title = "Esp Ore",
        Value = false,
        Callback = function(state)
            ESP = state
            if not state then
                for _,v in ipairs(clusters or {}) do
                    if v.Highlight then v.Highlight.Enabled = false end
                    if v.Line then v.Line.Visible = false end
                    if v.Text then v.Text.Visible = false end
                    for _, p in ipairs(v.Parts) do
                        if p and guis[p] then
                            guis[p].Enabled = false
                        end
                    end
                end
            end
        end,
    })

    Tab:Dropdown({
        Title = "Ore",
        Values = {"Iron","Coal","Redstone", "Diamond", "Gold"},
        Value = {"Iron","Coal","Redstone", "Diamond", "Gold"},
        Multi = true,
        Callback = function(t)
            UpdateMultiSelection(SelectedOre, t)
        end,
    })

    Tab:Dropdown({
        Title = "Mode",
        Values = {"Highlight","Line","Name","Cluster","ClickToTeleport"},
        Value = {"Highlight","Line","Name","Cluster","ClickToTeleport"},
        Multi = true,
        Callback = function(t)
            UpdateMultiSelection(SelectedMode, t)
        end,
    })

    local ORE_IDS = {
        Iron = "131779247788978",
        Coal = "101285368663656",
        Redstone = "107428584594403",
        Gold = "112951741279211",
        Diamond = "84697441577522"
    }

    local ORE_COLORS = {
        Iron = Color3.fromRGB(200,200,200),
        Coal = Color3.fromRGB(50,50,50),
        Redstone = Color3.fromRGB(255,0,0),
        Diamond = Color3.fromRGB(83, 233, 221),
        Gold = Color3.fromRGB(248, 211, 62)
    }

    local CLUSTER_RADIUS = 6

    local processed = {}
    clusters = {}

    local function GetAssetId(str)
        str = tostring(str or ""):lower()
        local id = str:match("id=(%d+)") or str:match("rbxassetid://(%d+)")
        
        if not id then
            for num in str:gmatch("%d+") do
                if #num >= 7 then 
                    id = num
                    break
                end
            end
        end
        return id
    end

    local function RemoveCluster(cluster)
        if cluster.Highlight then cluster.Highlight:Destroy() end
        if cluster.Line then cluster.Line:Remove() end
        if cluster.Text then cluster.Text:Remove() end
        for _, p in ipairs(cluster.Parts) do
            if p and guis[p] then
                guis[p]:Destroy()
                guis[p] = nil
            end
        end
    end

    local function CreateVisual(cluster)
        local color = ORE_COLORS[cluster.Name] or Color3.new(1,1,1)

        local h = Instance.new("Highlight")
        h.FillColor = color
        h.OutlineColor = Color3.new(1,1,1)
        h.FillTransparency = .5
        h.Enabled = false
        h.Adornee = cluster.Parts[1]
        h.Parent = cluster.Parts[1]
        cluster.Highlight = h

        local l = Drawing.new("Line")
        l.Color = color
        l.Thickness = 1.5
        l.Transparency = 1
        l.Visible = false
        cluster.Line = l

        local txt = Drawing.new("Text")
        txt.Text = cluster.Name
        txt.Size = 14
        txt.Center = true
        txt.Outline = true
        txt.Font = 2
        txt.Color = color
        txt.Visible = false
        cluster.Text = txt
    end

    local function GetCenter(parts)
        local pos = Vector3.zero
        local c = 0

        for _,p in ipairs(parts) do
            if p and p.Parent then
                pos += p.Position
                c += 1
            end
        end

        if c == 0 then return nil end
        return pos / c
    end

    local function FindCluster(id,pos)
        for _,v in ipairs(clusters) do
            if v.Id == id and v.Center and (v.Center-pos).Magnitude <= CLUSTER_RADIUS then
                return v
            end
        end
    end

    local function AddOre(part,name,id)
        if processed[part] then return end
        processed[part] = true

        local cluster
        if SelectedMode.Cluster then
            cluster = FindCluster(id,part.Position)
        end

        if cluster then
            table.insert(cluster.Parts,part)
            cluster.Center = GetCenter(cluster.Parts)
        else
            cluster = {
                Name = name,
                Id = id,
                Parts = {part},
                Center = part.Position
            }
            CreateVisual(cluster)
            table.insert(clusters,cluster)
        end

        part.Destroying:Connect(function()
            processed[part] = nil
            if guis[part] then
                guis[part]:Destroy()
                guis[part] = nil
            end
        end)
    end

    local function Process(decal)
        local part = decal.Parent
        if not part or not part:IsA("BasePart") then return end

        local id = GetAssetId(decal.Texture)
        if not id then return end

        for name,target in pairs(ORE_IDS) do
            if id == target then
                AddOre(part,name,id)
                break
            end
        end
    end

    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Decal") then
            Process(v)
        end
    end

    workspace.DescendantAdded:Connect(function(v)
        if v:IsA("Decal") then
            Process(v)
        end
    end)

    RunService.RenderStepped:Connect(function()
        local from = Vector2.new(Camera.ViewportSize.X/2, 0)

        for i=#clusters,1,-1 do
            local c = clusters[i]
            local valid = {}

            for _,p in ipairs(c.Parts) do
                if p and p.Parent then
                    table.insert(valid,p)
                end
            end

            c.Parts = valid

            if #valid == 0 then
                RemoveCluster(c)
                table.remove(clusters,i)
            else
                if SelectedMode.Cluster then
                    c.Center = GetCenter(valid)
                else
                    c.Center = valid[1] and valid[1].Position or Vector3.zero
                end

                local enabled = ESP and not not SelectedOre[c.Name]

                if c.Highlight then
                    c.Highlight.Enabled = not not (enabled and SelectedMode.Highlight)
                end

                local tpEnabled = not not (enabled and SelectedMode.ClickToTeleport)
                for _, p in ipairs(valid) do
                    local gui = guis[p]
                    if tpEnabled then
                        if not gui then
                            gui = Instance.new("BillboardGui")
                            gui.Name = "OreTeleportGui"
                            gui.AlwaysOnTop = true
                            gui.Active = true
                            gui.Size = UDim2.new(0, 25, 0, 25)
                            gui.Adornee = p
                            gui.Parent = PlayerGui
                            
                            local btn = Instance.new("TextButton")
                            btn.Size = UDim2.new(1, 0, 1, 0)
                            btn.Text = ""
                            btn.BackgroundTransparency = 0.99
                            btn.BackgroundColor3 = Color3.new(1, 1, 1)
                            btn.Active = true
                            btn.Parent = gui
                            
                            btn.MouseButton1Click:Connect(function()
                                if p and p.Parent then
                                    local pos = p.Position
                                    firesignal(
                                        game:GetService("ReplicatedStorage"):WaitForChild("ClientWarning").OnClientEvent,
                                        "pos",
                                        {
                                            position = Vector3.new(pos.X / 3, (pos.Y / 3) + 1, pos.Z / 3)
                                        }
                                    )
                                end
                            end)
                            guis[p] = gui
                        end
                        gui.Enabled = true
                    else
                        if gui then
                            gui.Enabled = false
                        end
                    end
                end

                local pos,vis = Camera:WorldToViewportPoint(c.Center)
                vis = vis and enabled

                if c.Line then
                    c.Line.Visible = not not (vis and SelectedMode.Line)
                    if c.Line.Visible then
                        c.Line.From = from
                        c.Line.To = Vector2.new(pos.X,pos.Y)
                    end
                end

                if c.Text then
                    c.Text.Visible = not not (vis and SelectedMode.Name)
                    if c.Text.Visible then
                        c.Text.Position = Vector2.new(pos.X,pos.Y-16)
                    end
                end
            end
        end
    end)

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")

    _G.Noclip = false
    _G.NoclipY = false
    local Speed = 2.5
    local SpeedEnabled = false

    local plr = Players.LocalPlayer
    local playerGui = plr:WaitForChild("PlayerGui")
    task.spawn(function()
        local mainGui = playerGui:WaitForChild("MainGui")
        local overlay = mainGui:WaitForChild("SuffocationOverlay", 9e9)

        local function disableOverlay()
            if _G.Noclip or _G.NoclipY then
                overlay.Visible = false
                overlay.ImageTransparency = 1
            end
        end

        overlay:GetPropertyChangedSignal("Visible"):Connect(disableOverlay)
        overlay:GetPropertyChangedSignal("ImageTransparency"):Connect(disableOverlay)
    end)

    local CollisionCheckModule = ReplicatedStorage:FindFirstChild("CollisionCheck", true)
    local WideCollisionCheckModule = ReplicatedStorage:FindFirstChild("WideCollisionCheck", true)

    if CollisionCheckModule then
        local CollisionCheck = require(CollisionCheckModule)
        local oldCollisionCheck
        
        oldCollisionCheck = hookfunction(CollisionCheck, function(p1, p2, p3, p4)
            if not p2 or not p2.Motion then 
                return oldCollisionCheck(p1, p2, p3, p4) 
            end
            
            local originalMotion = p2.Motion
            
            if SpeedEnabled and originalMotion then
                p2.Motion = Vector3.new(
                    originalMotion.X * Speed,
                    originalMotion.Y,
                    originalMotion.Z * Speed
                )
            end
            
            if _G.Noclip then
                local moveX = p2.Motion.X
                local moveY = p2.Motion.Y
                local moveZ = p2.Motion.Z
                
                if moveY > 0 or _G.NoclipY then
                    p2.Motion = Vector3.new(0, 0, 0)
                    local colVec, hitBlocks = oldCollisionCheck(p1, p2, p3, p4)
                    p2.Motion = Vector3.new(moveX, moveY, moveZ)
                    p2.NextPos = p2.NextPos + Vector3.new(moveX, moveY, moveZ)
                    
                    if SpeedEnabled and originalMotion then p2.Motion = originalMotion end
                    return colVec, hitBlocks
                else
                    p2.Motion = Vector3.new(0, moveY, 0)
                    local colVec, hitBlocks = oldCollisionCheck(p1, p2, p3, p4)
                    p2.Motion = Vector3.new(moveX, moveY, moveZ)
                    p2.NextPos = p2.NextPos + Vector3.new(moveX, 0, moveZ)
                    
                    if SpeedEnabled and originalMotion then p2.Motion = originalMotion end
                    return colVec, hitBlocks
                end
            end
            
            local r1, r2 = oldCollisionCheck(p1, p2, p3, p4)
            
            if SpeedEnabled and originalMotion then
                p2.Motion = originalMotion
            end
            
            return r1, r2
        end)
    end

    if WideCollisionCheckModule then
        local WideCollisionCheck = require(WideCollisionCheckModule)
        local oldWideCollisionCheck
        
        oldWideCollisionCheck = hookfunction(WideCollisionCheck, function(a, b, c, d)
            if not b or not b.Motion then 
                return oldWideCollisionCheck(a, b, c, d) 
            end
            
            local originalMotion = b.Motion
            if SpeedEnabled and originalMotion then
                b.Motion = Vector3.new(
                    originalMotion.X * Speed,
                    originalMotion.Y,
                    originalMotion.Z * Speed
                )
            end

            local r1, r2 = oldWideCollisionCheck(a, b, c, d)

            if SpeedEnabled and originalMotion then
                b.Motion = originalMotion
            end

            return r1, r2
        end)
    end

    Tab:Toggle({
        Title = "Noclip",
        Value = false,
        Callback = function(state)
            _G.Noclip = state
            if state then
                disableOverlay()
            end
        end,
    })

    Tab:Toggle({
        Title = "Noclip Y (Floor)",
        Value = false,
        Callback = function(state)
            _G.NoclipY = state
            if state then
                disableOverlay()
            end
        end,
    })

    Tab:Input({
        Title = "Speed",
        Value = tostring(Speed),
        InputIcon = "bird",
        Type = "Input",
        Placeholder = "Speed Multiplier",
        Callback = function(input)
            local n = tonumber(input)
            if n then
                Speed = n
            end
        end
    })

    Tab:Toggle({
        Title = "Enable Speed",
        Value = false,
        Desc = "Noclip will not work normally",
        Callback = function(state)
            SpeedEnabled = state
        end
    })

    local Input = Tab:Input({
        Title = "Teleport (Vector3)",
        Value = "",
        Desc = "For greater safety, turn on Anti Falldamage.",
        InputIcon = "bird",
        Type = "Input",
        Placeholder = "Ex: -23.5,50,-0.5",
        Callback = function(input)
            local x, y, z = input:match("^%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*$")
            x, y, z = tonumber(x), tonumber(y), tonumber(z)
            if not (x and y and z) then
                return
            end

            firesignal(
                game:GetService("ReplicatedStorage"):WaitForChild("ClientWarning").OnClientEvent,
                "pos",
                {
                    position = Vector3.new(x, y, z)
                }
            )
        end
    })

local AntiFall = false

Tab:CreateToggle({
	Title = "Anti Falldamage",
	Callback = function(val)
		AntiFall = val
	end,
})

local old
old = hookmetamethod(game, "__namecall", function(self, ...)
	local args = {...}
	local method = getnamecallmethod()

	if method == "InvokeServer"
	and self.Name == "SendState"
	and AntiFall then

		local packet = args[1]

		if typeof(packet) == "table" then
			if packet.onGround == 1 then
				packet.onGround = 2
			elseif packet.onGround == nil then
				packet.onGround = 2
			end
		end
	end

	return old(self, unpack(args))
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

local addedEvent = ReplicatedStorage:WaitForChild("Added")
local entityTable = nil
local floatLoop = nil
local sg = nil

local isMovingUp = false
local isMovingDown = false
local speed = 0.12
local lockedHeight = 0

local function getEntity()
    if entityTable then return entityTable end
    for _, connection in pairs(getconnections(addedEvent.OnClientEvent)) do
        local func = connection.Function
        if func then
            local upvalues = debug.getupvalues(func)
            for _, v in pairs(upvalues) do
                if type(v) == "table" and v.Motion and v.Pos then
                    entityTable = v
                    return entityTable
                end
            end
        end
    end
    return nil
end

Tab:Toggle({
    Title = "Float",
    Callback = function(state)
        if state then
            local entity = getEntity()
            if not entity then return end
            
            lockedHeight = entity.Pos.Y
            isMovingUp = false
            isMovingDown = false
            
            sg = Instance.new("ScreenGui")
            sg.Name = "FloatControlUI"
            sg.ResetOnSpawn = false
            sg.Parent = CoreGui

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 70, 0, 160)
            frame.Position = UDim2.new(1, -90, 0.5, -80)
            frame.BackgroundTransparency = 1
            frame.Parent = sg

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 15)
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Center
            layout.Parent = frame

            local function createButton(text, color)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 55, 0, 55)
                btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                btn.BackgroundTransparency = 0.2
                btn.Text = text
                btn.TextColor3 = color
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 22
                btn.AutoButtonColor = true
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 16)
                corner.Parent = btn
                
                local stroke = Instance.new("UIStroke")
                stroke.Color = color
                stroke.Thickness = 2
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = btn
                
                btn.Parent = frame
                return btn
            end

            local btnUp = createButton("▲", Color3.fromRGB(0, 255, 140))
            local btnDown = createButton("▼", Color3.fromRGB(255, 60, 100))

            btnUp.MouseButton1Down:Connect(function() isMovingUp = true end)
            btnUp.MouseButton1Up:Connect(function() isMovingUp = false end)
            btnUp.MouseLeave:Connect(function() isMovingUp = false end)

            btnDown.MouseButton1Down:Connect(function() isMovingDown = true end)
            btnDown.MouseButton1Up:Connect(function() isMovingDown = false end)
            btnDown.MouseLeave:Connect(function() isMovingDown = false end)

            floatLoop = RunService.RenderStepped:Connect(function()
                if entityTable and type(entityTable) == "table" and entityTable.Pos then
                    if isMovingUp then
                        lockedHeight = lockedHeight + speed
                    elseif isMovingDown then
                        lockedHeight = lockedHeight - speed
                    end
                    
                    if entityTable.Motion then
                        entityTable.Motion = Vector3.new(entityTable.Motion.X, 0, entityTable.Motion.Z)
                    end
                    
                    entityTable.Pos = Vector3.new(entityTable.Pos.X, lockedHeight, entityTable.Pos.Z)
                    entityTable.FallDistance = 0
                    entityTable.Fell = nil
                    entityTable.OnGround = true
                else
                    if floatLoop then floatLoop:Disconnect() end
                    if sg then sg:Destroy() end
                end
            end)
        else
            if floatLoop then
                floatLoop:Disconnect()
                floatLoop = nil
            end
            if sg then
                sg:Destroy()
                sg = nil
            end
            isMovingUp = false
            isMovingDown = false
        end
    end,
})

    local envi = Window:Tab({ Title = "Environment", Icon = "home" })
    local L = game:GetService("Lighting")
    local C = {}

    envi:Toggle({
        Title = "No fog",
        Value = false,
        Callback = function(state)
            if state then
                L.FogStart = 9e9
                L.FogEnd = 9e9

                C[1] = L:GetPropertyChangedSignal("FogStart"):Connect(function()
                    L.FogStart = 9e9
                end)

                C[2] = L:GetPropertyChangedSignal("FogEnd"):Connect(function()
                    L.FogEnd = 9e9
                end)

                C[3] = L.DescendantAdded:Connect(function(v)
                    if v:IsA("Atmosphere") then
                        v.Enabled = false
                    end
                end)

                for _,v in ipairs(L:GetDescendants()) do
                    if v:IsA("Atmosphere") then
                        v.Enabled = false
                    end
                end
            else
                for _,v in pairs(C) do
                    if v then
                        v:Disconnect()
                    end
                end
                table.clear(C)

                for _,v in ipairs(L:GetDescendants()) do
                    if v:IsA("Atmosphere") then
                        v.Enabled = true
                    end
                end
            end
        end
    })

    local O = {
        Brightness = L.Brightness,
        Ambient = L.Ambient,
        OutdoorAmbient = L.OutdoorAmbient,
        ClockTime = L.ClockTime,
        ExposureCompensation = L.ExposureCompensation
    }

    local function on()
        L.Brightness = 2
        L.Ambient = Color3.fromRGB(140, 140, 140)
        L.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        L.ClockTime = 14
        L.ExposureCompensation = 0.2

        C[1] = L:GetPropertyChangedSignal("Brightness"):Connect(function()
            L.Brightness = 2
        end)

        C[2] = L:GetPropertyChangedSignal("Ambient"):Connect(function()
            L.Ambient = Color3.fromRGB(140, 140, 140)
        end)

        C[3] = L:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
            L.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        end)

        C[4] = L:GetPropertyChangedSignal("ClockTime"):Connect(function()
            L.ClockTime = 14
        end)

        C[5] = L:GetPropertyChangedSignal("ExposureCompensation"):Connect(function()
            L.ExposureCompensation = 0.2
        end)
    end

    local function off()
        for _, v in pairs(C) do
            if v then
                v:Disconnect()
            end
        end
        table.clear(C)

        L.Brightness = O.Brightness
        L.Ambient = O.Ambient
        L.OutdoorAmbient = O.OutdoorAmbient
        L.ClockTime = O.ClockTime
        L.ExposureCompensation = O.ExposureCompensation
    end

    envi:Toggle({
        Title = "Night Vision",
        Value = false,
        Callback = function(state)
            if state then
                on()
            else
                off()
            end
        end
    })
end