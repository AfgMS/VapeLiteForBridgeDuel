--[[
    fap lite for ro-sex (idk why tf did i made this)
    bridge duel edition!
]]
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end
local vapelite

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextAction = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local suc, web = pcall(function() return WebSocket.connect('ws://127.0.0.1:6892/') end)
if not suc or suc and type(web) == 'boolean' then
    repeat
        suc, web = pcall(function() return WebSocket.connect('ws://127.0.0.1:6892/') end)
        if not suc or suc and type(web) == 'boolean' then
            print('websocket error:', web)
        else
            break
        end
        task.wait(1)
    until suc and type(web) ~= 'boolean'
end
--[[
    Setup
    Honestly it may come to 1 point to rewrite the garbage winforms ui at some point, dealing with the old naming structure isn't easy.
]]
run(function()
    vapelite = {
        Connections = {},
        Loaded = false,
        Modules = {}
    }

    local function getTableSize(tab)
        local ind = 0
        for _ in tab do ind += 1 end
        return ind
    end

    function vapelite:UpdateTextGUI() end

    function vapelite:CreateModule(modulesettings)
        local moduleapi = {Enabled = false, Options = {}, Connections = {}, Name = modulesettings.Name, Tooltip = modulesettings.Tooltip}

        function moduleapi:CreateToggle(optionsettings)
            local optionapi = {Type = 'Toggle', Enabled = false, Index = getTableSize(moduleapi.Options)}
            optionsettings.Function = optionsettings.Function or function() end

            function optionapi:Toggle()
                optionapi.Enabled = not optionapi.Enabled
                optionsettings.Function(optionapi.Enabled)
            end
            if optionsettings.Default then
                optionapi:Toggle()
            end

            moduleapi.Options[optionsettings.Name] = optionapi

            return optionapi
        end

        function moduleapi:CreateSlider(optionsettings)
            local optionapi = {Type = 'Slider', Value = optionsettings.Default or optionsettings.Min, Min = optionsettings.Min, Max = optionsettings.Max, Index = getTableSize(moduleapi.Options)}
            optionsettings.Function = optionsettings.Function or function() end

            function optionapi:SetValue(value)
                if tonumber(value) == math.huge or value ~= value then return end
                optionapi.Value = value
                optionsettings.Function(value)
            end

            moduleapi.Options[optionsettings.Name] = optionapi

            return optionapi
        end

        function moduleapi:Clean(obj) table.insert(moduleapi.Connections, obj) end

        function moduleapi:Toggle()
            moduleapi.Enabled = not moduleapi.Enabled
            if not moduleapi.Enabled then
                for _, v in moduleapi.Connections do
                    if typeof(v) == 'Instance' then
                        v:ClearAllChildren()
                        v:Destroy()
                    else
                        v:Disconnect()
                    end
                end
                table.clear(moduleapi.Connections)
            end
            task.spawn(modulesettings.Function, moduleapi.Enabled)
            vapelite:UpdateTextGUI()
        end

        vapelite.Modules[modulesettings.Name] = moduleapi

        return moduleapi
    end

    function vapelite:Save()
        if not vapelite.Loaded then return end
        vapelite:Send({
            msg = 'writesettings',
            id = (game.PlaceId == 6872265039 and 'bedwarslobbynew' or 'bedwarsmainnew'),
            content = httpService:JSONEncode(vapelite.Modules)
        })
    end

    function vapelite:Load()
        vapelite.read = Instance.new('BindableEvent')
        vapelite:Send({
            msg = 'readsettings',
            id = (game.PlaceId == 6872265039 and 'bedwarslobbynew' or 'bedwarsmainnew')
        })

        local got, data = pcall(function() return httpService:JSONDecode(vapelite.read.Event:Wait()) end)
        if type(data) == 'table' then
            for i, v in data do
                local object = vapelite.Modules[i]
                if object then
                    for i2, v2 in v.Options do
                        local optionobject = object.Options[i2]
                        if optionobject then
                            if v2.Type == 'Toggle' then
                                if v2.Enabled ~= optionobject.Enabled then optionobject:Toggle() end
                            else
                                optionobject:SetValue(v2.Value)
                            end
                        end
                    end

                    if v.Enabled then object:Toggle() end
                end
            end
        end

        local replicatedmodules = {}
        for i, v in vapelite.Modules do
            local newmodule = {name = i, desc = v.Tooltip, options = {}, toggled = v.Enabled}
            for i2, v2 in v.Options do
                if v2.Type == 'Slider' then
                    table.insert(newmodule.options, {name = i2, type = 'Slider', state = v2.Value, min = v2.Min, max = v2.Max, index = v2.Index})
                else
                    table.insert(newmodule.options, {name = i2, type = 'Toggle', toggled = v2.Enabled, index = v2.Index})
                end
            end
            table.sort(newmodule.options, function(a, b) return a.index < b.index end)
            table.insert(replicatedmodules, newmodule)
        end
        table.sort(replicatedmodules, function(a, b) return a.name < b.name end)

        vapelite.Loaded = true
        vapelite:Send({
            msg = 'connectrequest',
            modules = replicatedmodules
        })
    end

    function vapelite:Send(data)
        if suc and web then web:Send(httpService:JSONEncode(data)) end
    end

    function vapelite.Receive(data)
        data = httpService:JSONDecode(data)
        local write = false
        if data.msg == 'togglemodule' then
            local module = vapelite.Modules[data.module]
            if module and data.state ~= module.Enabled then module:Toggle() end
        elseif data.msg == 'togglebuttontoggle' or data.msg == 'togglebuttonslider' then
            local option = vapelite.Modules[data.module] and vapelite.Modules[data.module].Options[data.setting]
            if option then
                if option.Type == 'Toggle' then
                    option:Toggle(data.state)
                else
                    option:SetValue(data.state)
                end
            end
        elseif data.msg == 'readsettings' then
            if vapelite.read then
                vapelite.read:Fire(data.result)
                vapelite.read:Destroy()
            end
        end

        if data.msg ~= 'readsettings' then vapelite:Save() end
    end

    function vapelite.Uninject(tp)
        if web then pcall(function() web:Disconnect() end) end
        vapelite:Save()
        vapelite.Loaded = nil
        for _, v in vapelite.Modules do if v.Enabled then v:Toggle() end end
        for _, v in vapelite.Connections do pcall(function() v:Disconnect() end) end

        shared.vapelite = nil
        if tp then return end
        task.spawn(function()
            repeat task.wait() until game:IsLoaded()
            repeat task.wait(5) until isfile('vapelite.injectable.txt')
            delfile('vapelite.injectable.txt')
            loadstring(readfile('vapelite.lua'))()
        end)
    end

    shared.vapelite = vapelite.Uninject
end)

--[[
    Game stuff
]]

run(function()

    --[[
        Combat
    ]]

    --[[
        Blatant
    ]]

    --[[
        Render
    ]]

    run(function()
        local ESP = {Enabled = false}
        local ESPMethod = {Value = 1}
        local ESPBoundingBox = {Enabled = true}
        local ESPHealthBar = {Enabled = false}
        local ESPName = {Enabled = true}
        local ESPDisplay = {Enabled = true}
        local ESPBackground = {Enabled = false}
        local ESPFilled = {Enabled = false}
        local ESPTeammates = {Enabled = true}
        local ESPModes = {'2D', '3D', 'Skeleton'}
        local ESPFolder = {}
        local methodused

        local function floorESPPosition(pos)
            return pos // 1
        end

        local function ESPWorldToViewport(pos)
            local newpos = gameCamera:WorldToViewportPoint(gameCamera.CFrame:pointToWorldSpace(gameCamera.CFrame:pointToObjectSpace(pos)))
            return Vector2.new(newpos.X, newpos.Y)
        end

        local ESPAdded = {
            Drawing2D = function(ent)
                if ESPTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
                local EntityESP = {}
                EntityESP.Main = Drawing.new('Square')
                EntityESP.Main.Transparency = ESPBoundingBox.Enabled and 1 or 0
                EntityESP.Main.ZIndex = 2
                EntityESP.Main.Filled = false
                EntityESP.Main.Thickness = 1
                EntityESP.Main.Color = ent.Player.TeamColor.Color
                EntityESP.Border = Drawing.new('Square')
                EntityESP.Border.Transparency = ESPBoundingBox.Enabled and 0.35 or 0
                EntityESP.Border.ZIndex = 1
                EntityESP.Border.Thickness = 1
                EntityESP.Border.Filled = false
                EntityESP.Border.Color = Color3.new()
                EntityESP.Border2 = Drawing.new('Square')
                EntityESP.Border2.Transparency = ESPBoundingBox.Enabled and 0.35 or 0
                EntityESP.Border2.ZIndex = 1
                EntityESP.Border2.Thickness = 1
                EntityESP.Border2.Filled = ESPFilled.Enabled
                EntityESP.Border2.Color = Color3.new()
                if ESPHealthBar.Enabled then
                    EntityESP.HealthLine = Drawing.new('Line')
                    EntityESP.HealthLine.Thickness = 1
                    EntityESP.HealthLine.ZIndex = 2
                    EntityESP.HealthLine.Color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
                    EntityESP.HealthBorder = Drawing.new('Line')
                    EntityESP.HealthBorder.Thickness = 3
                    EntityESP.HealthBorder.Transparency = 0.35
                    EntityESP.HealthBorder.ZIndex = 1
                    EntityESP.HealthBorder.Color = Color3.new()
                end
                if ESPName.Enabled then
                    if ESPBackground.Enabled then
                        EntityESP.TextBKG = Drawing.new('Square')
                        EntityESP.TextBKG.Transparency = 0.35
                        EntityESP.TextBKG.ZIndex = 0
                        EntityESP.TextBKG.Thickness = 1
                        EntityESP.TextBKG.Filled = true
                        EntityESP.TextBKG.Color = Color3.new()
                    end
                    EntityESP.Drop = Drawing.new('Text')
                    EntityESP.Drop.Color = Color3.new()
                    EntityESP.Drop.Text = ent.Player and (ESPDisplay.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
                    EntityESP.Drop.ZIndex = 1
                    EntityESP.Drop.Center = true
                    EntityESP.Drop.Size = 20
                    EntityESP.Text = Drawing.new('Text')
                    EntityESP.Text.Text = EntityESP.Drop.Text
                    EntityESP.Text.ZIndex = 2
                    EntityESP.Text.Color = EntityESP.Main.Color
                    EntityESP.Text.Center = true
                    EntityESP.Text.Size = 20
                end
                ESPFolder[ent] = EntityESP
            end,
            Drawing3D = function(ent)
                if ESPTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
                local EntityESP = {}
                EntityESP.Line1 = Drawing.new('Line')
                EntityESP.Line2 = Drawing.new('Line')
                EntityESP.Line3 = Drawing.new('Line')
                EntityESP.Line4 = Drawing.new('Line')
                EntityESP.Line5 = Drawing.new('Line')
                EntityESP.Line6 = Drawing.new('Line')
                EntityESP.Line7 = Drawing.new('Line')
                EntityESP.Line8 = Drawing.new('Line')
                EntityESP.Line9 = Drawing.new('Line')
                EntityESP.Line10 = Drawing.new('Line')
                EntityESP.Line11 = Drawing.new('Line')
                EntityESP.Line12 = Drawing.new('Line')
                local color = ent.Player.TeamColor.Color
                for _, v in EntityESP do v.Thickness = 1 v.Color = color end
                ESPFolder[ent] = EntityESP
            end,
            DrawingSkeleton = function(ent)
                if ESPTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
                local EntityESP = {}
                EntityESP.Head = Drawing.new('Line')
                EntityESP.HeadFacing = Drawing.new('Line')
                EntityESP.Torso = Drawing.new('Line')
                EntityESP.UpperTorso = Drawing.new('Line')
                EntityESP.LowerTorso = Drawing.new('Line')
                EntityESP.LeftArm = Drawing.new('Line')
                EntityESP.RightArm = Drawing.new('Line')
                EntityESP.LeftLeg = Drawing.new('Line')
                EntityESP.RightLeg = Drawing.new('Line')
                local color = ent.Player.TeamColor.Color
                for _, v in EntityESP do v.Thickness = 2 v.Color = color end
                ESPFolder[ent] = EntityESP
            end
        }

        local ESPRemoved = {
            Drawing2D = function(ent)
                local EntityESP = ESPFolder[ent]
                if EntityESP then
                    ESPFolder[ent] = nil
                    for _, v in EntityESP do
                        pcall(function()
                            v.Visible = false
                            v:Remove()
                        end)
                    end
                end
            end
        }
        ESPRemoved.Drawing3D = ESPRemoved.Drawing2D
        ESPRemoved.DrawingSkeleton = ESPRemoved.Drawing2D

        local ESPUpdated = {
            Drawing2D = function(ent)
                local EntityESP = ESPFolder[ent]
                if EntityESP then
                    if EntityESP.HealthLine then
                        EntityESP.HealthLine.Color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
                    end
                    if EntityESP.Text then
                        EntityESP.Text.Text = ent.Player and (ESPDisplay.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
                        EntityESP.Drop.Text = EntityESP.Text.Text
                    end
                end
            end
        }

        local ESPLoop = {
            Drawing2D = function()
                for ent, EntityESP in ESPFolder do
                    local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
                    for _, obj in EntityESP do obj.Visible = rootVis end
                    if not rootVis then continue end
                    local topPos, topVis = gameCamera:WorldToViewportPoint((CFrame.new(ent.RootPart.Position, ent.RootPart.Position + gameCamera.CFrame.LookVector) * CFrame.new(2, ent.HipHeight, 0)).p)
                    local bottomPos, bottomVis = gameCamera:WorldToViewportPoint((CFrame.new(ent.RootPart.Position, ent.RootPart.Position + gameCamera.CFrame.LookVector) * CFrame.new(-2, -ent.HipHeight - 1, 0)).p)
                    local sizex, sizey = topPos.X - bottomPos.X, topPos.Y - bottomPos.Y
                    local posx, posy = (rootPos.X - sizex / 2),  ((rootPos.Y - sizey / 2))
                    EntityESP.Main.Position = floorESPPosition(Vector2.new(posx, posy))
                    EntityESP.Main.Size = floorESPPosition(Vector2.new(sizex, sizey))
                    EntityESP.Border.Position = floorESPPosition(Vector2.new(posx - 1, posy + 1))
                    EntityESP.Border.Size = floorESPPosition(Vector2.new(sizex + 2, sizey - 2))
                    EntityESP.Border2.Position = floorESPPosition(Vector2.new(posx + 1, posy - 1))
                    EntityESP.Border2.Size = floorESPPosition(Vector2.new(sizex - 2, sizey + 2))
                    if EntityESP.HealthLine then
                        local healthposy = sizey * math.clamp(ent.Health / ent.MaxHealth, 0, 1)
                        EntityESP.HealthLine.Visible = ent.Health > 0
                        EntityESP.HealthLine.From = floorESPPosition(Vector2.new(posx - 6, posy + (sizey - (sizey - healthposy))))
                        EntityESP.HealthLine.To = floorESPPosition(Vector2.new(posx - 6, posy))
                        EntityESP.HealthBorder.From = floorESPPosition(Vector2.new(posx - 6, posy + 1))
                        EntityESP.HealthBorder.To = floorESPPosition(Vector2.new(posx - 6, (posy + sizey) - 1))
                    end
                    if EntityESP.Text then
                        EntityESP.Text.Position = floorESPPosition(Vector2.new(posx + (sizex / 2), posy + (sizey - 28)))
                        EntityESP.Drop.Position = EntityESP.Text.Position + Vector2.new(1, 1)
                        if EntityESP.TextBKG then
                            EntityESP.TextBKG.Size = EntityESP.Text.TextBounds + Vector2.new(8, 4)
                            EntityESP.TextBKG.Position = EntityESP.Text.Position - Vector2.new(4 + (EntityESP.Text.TextBounds.X / 2), 0)
                        end
                    end
                end
            end,
            Drawing3D = function()
                for ent, EntityESP in ESPFolder do
                    local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
                    for _, obj in EntityESP do obj.Visible = rootVis end
                    if not rootVis then continue end
                    local point1 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, ent.HipHeight, 1.5))
                    local point2 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, -ent.HipHeight, 1.5))
                    local point3 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, ent.HipHeight, 1.5))
                    local point4 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, -ent.HipHeight, 1.5))
                    local point5 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, ent.HipHeight, -1.5))
                    local point6 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, -ent.HipHeight, -1.5))
                    local point7 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, ent.HipHeight, -1.5))
                    local point8 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, -ent.HipHeight, -1.5))
                    EntityESP.Line1.From = point1
                    EntityESP.Line1.To = point2
                    EntityESP.Line2.From = point3
                    EntityESP.Line2.To = point4
                    EntityESP.Line3.From = point5
                    EntityESP.Line3.To = point6
                    EntityESP.Line4.From = point7
                    EntityESP.Line4.To = point8
                    EntityESP.Line5.From = point1
                    EntityESP.Line5.To = point3
                    EntityESP.Line6.From = point1
                    EntityESP.Line6.To = point5
                    EntityESP.Line7.From = point5
                    EntityESP.Line7.To = point7
                    EntityESP.Line8.From = point7
                    EntityESP.Line8.To = point3
                    EntityESP.Line9.From = point2
                    EntityESP.Line9.To = point4
                    EntityESP.Line10.From = point2
                    EntityESP.Line10.To = point6
                    EntityESP.Line11.From = point6
                    EntityESP.Line11.To = point8
                    EntityESP.Line12.From = point8
                    EntityESP.Line12.To = point4
                end
            end,
            DrawingSkeleton = function()
                for ent, EntityESP in ESPFolder do
                    local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
                    for _, obj in EntityESP do obj.Visible = rootVis end
                    if not rootVis then continue end
                    local rigcheck = ent.Humanoid.RigType == Enum.HumanoidRigType.R6
                    pcall(function() -- kill me
                        local offset = rigcheck and CFrame.new(0, -0.8, 0) or CFrame.new()
                        local head = ESPWorldToViewport((ent.Head.CFrame).p)
                        local headfront = ESPWorldToViewport((ent.Head.CFrame * CFrame.new(0, 0, -0.5)).p)
                        local toplefttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(-1.5, 0.8, 0)).p)
                        local toprighttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(1.5, 0.8, 0)).p)
                        local toptorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0, 0.8, 0)).p)
                        local bottomtorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0, -0.8, 0)).p)
                        local bottomlefttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(-0.5, -0.8, 0)).p)
                        local bottomrighttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0.5, -0.8, 0)).p)
                        local leftarm = ESPWorldToViewport((ent.Character[(rigcheck and 'Left Arm' or 'LeftHand')].CFrame * offset).p)
                        local rightarm = ESPWorldToViewport((ent.Character[(rigcheck and 'Right Arm' or 'RightHand')].CFrame * offset).p)
                        local leftleg = ESPWorldToViewport((ent.Character[(rigcheck and 'Left Leg' or 'LeftFoot')].CFrame * offset).p)
                        local rightleg = ESPWorldToViewport((ent.Character[(rigcheck and 'Right Leg' or 'RightFoot')].CFrame * offset).p)
                        EntityESP.Head.From = toptorso
                        EntityESP.Head.To = head
                        EntityESP.HeadFacing.From = head
                        EntityESP.HeadFacing.To = headfront
                        EntityESP.UpperTorso.From = toplefttorso
                        EntityESP.UpperTorso.To = toprighttorso
                        EntityESP.Torso.From = toptorso
                        EntityESP.Torso.To = bottomtorso
                        EntityESP.LowerTorso.From = bottomlefttorso
                        EntityESP.LowerTorso.To = bottomrighttorso
                        EntityESP.LeftArm.From = toplefttorso
                        EntityESP.LeftArm.To = leftarm
                        EntityESP.RightArm.From = toprighttorso
                        EntityESP.RightArm.To = rightarm
                        EntityESP.LeftLeg.From = bottomlefttorso
                        EntityESP.LeftLeg.To = leftleg
                        EntityESP.RightLeg.From = bottomrighttorso
                        EntityESP.RightLeg.To = rightleg
                    end)
                end
            end
        }

        ESP = vapelite:CreateModule({
            Name = 'ESP',
            Function = function(callback)
                if callback then
                    methodused = 'Drawing'..ESPModes[ESPMethod.Value]
                    if ESPRemoved[methodused] then
                        table.insert(ESP.Connections, entitylib.Events.EntityRemoved:Connect(ESPRemoved[methodused]))
                    end
                    if ESPAdded[methodused] then
                        for _, v in entitylib.List do
                            if ESPFolder[v] then ESPRemoved[methodused](v) end
                            ESPAdded[methodused](v)
                        end
                        table.insert(ESP.Connections, entitylib.Events.EntityAdded:Connect(function(ent)
                            if ESPFolder[ent] then ESPRemoved[methodused](ent) end
                            ESPAdded[methodused](ent)
                        end))
                    end
                    if ESPUpdated[methodused] then
                        table.insert(ESP.Connections, entitylib.Events.EntityUpdated:Connect(ESPUpdated[methodused]))
                        for _, v in entitylib.List do ESPUpdated[methodused](v) end
                    end
                    if ESPLoop[methodused] then
                        table.insert(ESP.Connections, runService.RenderStepped:Connect(ESPLoop[methodused]))
                    end
                else
                    if ESPRemoved[methodused] then
                        for i in ESPFolder do ESPRemoved[methodused](i) end
                    end
                end
            end,
            Tooltip = 'Renders an ESP on players.'
        })
        ESPMethod = ESP:CreateSlider({
            Name = 'Mode',
            Min = 1,
            Max = #ESPModes,
            Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
        })
        ESPBoundingBox = ESP:CreateToggle({
            Name = 'Bounding Box',
            Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end,
            Default = true
        })
        ESPHealthBar = ESP:CreateToggle({
            Name = 'Health Bar',
            Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
        })
        ESPName = ESP:CreateToggle({
            Name = 'Name',
            Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
        })
        ESPDisplay = ESP:CreateToggle({
            Name = 'Use Displayname',
            Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end,
            Default = true
        })
        ESPBackground = ESP:CreateToggle({
            Name = 'Show Background',
            Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
        })
        ESPFilled = ESP:CreateToggle({
            Name = 'Filled',
            Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end
        })
        ESPTeammates = ESP:CreateToggle({
            Name = 'Priority Only',
            Function = function() if ESP.Enabled then ESP:Toggle() ESP:Toggle() end end,
            Default = true
        })
    end)

    run(function()
        local NameTags = {Enabled = false}
        local NameTagsBackground = {Value = 5}
        local NameTagsDisplayName = {Enabled = false}
        local NameTagsHealth = {Enabled = false}
        local NameTagsDistance = {Enabled = false}
        local NameTagsScale = {Value = 10}
        local NameTagsFont = {Value = 1}
        local NameTagsTeammates = {Enabled = true}
        local NameTagsStrings = {}
        local NameTagsSizes = {}
        local NameTagsDrawingFolder = {}
        local fontitems = {'Arial'}

        local NameTagAdded = function(ent)
            if NameTagsTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
            local EntityNameTag = {}
            EntityNameTag.BG = Drawing.new('Square')
            EntityNameTag.BG.Filled = true
            EntityNameTag.BG.Transparency = 1 - (NameTagsBackground.Value / 10)
            EntityNameTag.BG.Color = Color3.new()
            EntityNameTag.BG.ZIndex = 1
            EntityNameTag.Text = Drawing.new('Text')
            EntityNameTag.Text.Size = 15 * (NameTagsScale.Value / 10)
            EntityNameTag.Text.Font = 1
            EntityNameTag.Text.ZIndex = 2
            NameTagsStrings[ent] = ent.Player and (NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
            if NameTagsHealth.Enabled then
                local color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
                NameTagsStrings[ent] = NameTagsStrings[ent]..' '..math.round(ent.Health)
            end
            if NameTagsDistance.Enabled then
                NameTagsStrings[ent] = '[%s] '..NameTagsStrings[ent]
            end
            EntityNameTag.Text.Text = NameTagsStrings[ent]
            EntityNameTag.Text.Color = ent.Player.TeamColor.Color
            EntityNameTag.BG.Size = Vector2.new(EntityNameTag.Text.TextBounds.X + 8, EntityNameTag.Text.TextBounds.Y + 7)
            NameTagsDrawingFolder[ent] = EntityNameTag
        end


        local NameTagRemoved = function(ent)
            local v = NameTagsDrawingFolder[ent]
            if v then
                NameTagsDrawingFolder[ent] = nil
                NameTagsStrings[ent] = nil
                NameTagsSizes[ent] = nil
                for _, v2 in v do
                    pcall(function() v2.Visible = false v2:Remove() end)
                end
            end
        end


        local NameTagUpdated = function(ent)
            local EntityNameTag = NameTagsDrawingFolder[ent]
            if EntityNameTag then
                NameTagsSizes[ent] = nil
                NameTagsStrings[ent] = ent.Player and (NameTagsDisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
                if NameTagsHealth.Enabled then
                    NameTagsStrings[ent] = NameTagsStrings[ent]..' '..math.round(ent.Health)
                end
                if NameTagsDistance.Enabled then
                    NameTagsStrings[ent] = '[%s] '..NameTagsStrings[ent]
                    EntityNameTag.Text.Text = entitylib.isAlive and string.format(NameTagsStrings[ent], math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude)) or NameTagsStrings[ent]
                else
                    EntityNameTag.Text.Text = NameTagsStrings[ent]
                end
                EntityNameTag.BG.Size = Vector2.new(EntityNameTag.Text.TextBounds.X + 8, EntityNameTag.Text.TextBounds.Y + 7)
                EntityNameTag.Text.Color = ent.Player.TeamColor.Color
            end
        end


        local NameTagLoop = function()
            for ent, EntityNameTag in NameTagsDrawingFolder do
                local headPos, headVis = gameCamera:WorldToScreenPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
                EntityNameTag.Text.Visible = headVis
                EntityNameTag.BG.Visible = headVis
                if not headVis then
                    continue
                end
                if NameTagsDistance.Enabled and entitylib.isAlive then
                    local mag = math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude)
                    if NameTagsSizes[ent] ~= mag then
                        EntityNameTag.Text.Text = string.format(NameTagsStrings[ent], mag)
                        EntityNameTag.BG.Size = Vector2.new(EntityNameTag.Text.TextBounds.X + 8, EntityNameTag.Text.TextBounds.Y + 7)
                        NameTagsSizes[ent] = mag
                    end
                end
                EntityNameTag.BG.Position = Vector2.new(headPos.X - (EntityNameTag.BG.Size.X / 2), headPos.Y + (EntityNameTag.BG.Size.Y / 2))
                EntityNameTag.Text.Position = EntityNameTag.BG.Position + Vector2.new(4, 2.5)
            end
        end


        NameTags = vapelite:CreateModule({
            Name = 'NameTags',
            Function = function(callback)
                if callback then
                    table.insert(NameTags.Connections, entitylib.Events.EntityRemoved:Connect(NameTagRemoved))
                    for _, v in entitylib.List do
                        if NameTagsDrawingFolder[v] then NameTagRemoved(v) end
                        NameTagAdded(v)
                        NameTagUpdated(v)
                    end
                    table.insert(NameTags.Connections, entitylib.Events.EntityAdded:Connect(function(ent)
                        if NameTagsDrawingFolder[ent] then NameTagRemoved(ent) end
                        NameTagAdded(ent)
                    end))
                    table.insert(NameTags.Connections, entitylib.Events.EntityUpdated:Connect(NameTagUpdated))
                    table.insert(NameTags.Connections, runService.RenderStepped:Connect(NameTagLoop))
                else
                    for i in NameTagsDrawingFolder do NameTagRemoved(i) end
                end
            end,
            Tooltip = 'Renders nametags on entities through walls.'
        })
        NameTagsFont = NameTags:CreateSlider({
            Name = 'Font',
            Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
            Min = 1,
            Max = 3
        })
        NameTagsScale = NameTags:CreateSlider({
            Name = 'Scale',
            Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
            Default = 10,
            Min = 1,
            Max = 15
        })
        NameTagsBackground = NameTags:CreateSlider({
            Name = 'Transparency',
            Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
            Default = 5,
            Min = 0,
            Max = 10
        })
        NameTagsHealth = NameTags:CreateToggle({
            Name = 'Health',
            Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end
        })
        NameTagsDistance = NameTags:CreateToggle({
            Name = 'Distance',
            Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end
        })
        NameTagsDisplayName = NameTags:CreateToggle({
            Name = 'Use Displayname',
            Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
            Default = true
        })
        NameTagsTeammates = NameTags:CreateToggle({
            Name = 'Priority Only',
            Function = function() if NameTags.Enabled then NameTags:Toggle() NameTags:Toggle() end end,
            Default = true
        })
    end)
    
    run(function()
        local Tracers = {Enabled = false}
        local TracersTransparency = {Value = 0}
        local TracersStartPosition = {Value = 1}
        local TracersEndPosition = {Value = 1}
        local TracersTeammates = {Enabled = true}
        local TracersDistanceColor = {Enabled = false}
        local TracersBehind = {Enabled = true}
        local TracersFolder = {}

        local TracersAdded = function(ent)
            if TracersTeammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
            local EntityTracer = Drawing.new('Line')
            EntityTracer.Thickness = 1
            EntityTracer.Transparency = 1 - (TracersTransparency.Value / 10)
            EntityTracer.Color = ent.Player.TeamColor.Color
            TracersFolder[ent] = EntityTracer
        end

        local TracersRemoved = function(ent)
            local v = TracersFolder[ent]
            if v then
                TracersFolder[ent] = nil
                pcall(function() v.Visible = false v:Remove() end)
            end
        end

        local TracersLoop = function()
            for ent, EntityTracer in TracersFolder do
                local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude
                local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent[TracersEndPosition.Value == 2 and 'RootPart' or 'Head'].Position)
                if not rootVis and TracersBehind.Enabled then
                    local tempPos = gameCamera.CFrame:pointToObjectSpace(ent[TracersEndPosition.Value == 2 and 'RootPart' or 'Head'].Position)
                    tempPos = CFrame.Angles(0, 0, (math.atan2(tempPos.Y, tempPos.X) + math.pi)):vectorToWorldSpace((CFrame.Angles(0, math.rad(89.9), 0):vectorToWorldSpace(Vector3.new(0, 0, -1))));
                    rootPos = gameCamera:WorldToViewportPoint(gameCamera.CFrame:pointToWorldSpace(tempPos))
                    rootVis = true
                end
                local screensize = gameCamera.ViewportSize
                local startVector = TracersStartPosition.Value == 3 and inputService:GetMouseLocation() or Vector2.new(screensize.X / 2, (TracersStartPosition.Value == 1 and screensize.Y / 2 or screensize.Y))
                local endVector = Vector2.new(rootPos.X, rootPos.Y)
                EntityTracer.Visible = rootVis
                EntityTracer.From = startVector
                EntityTracer.To = endVector
                if TracersDistanceColor.Enabled and distance then
                    EntityTracer.Color = Color3.fromHSV(math.min((distance / 128) / 2.8, 0.4), 0.89, 0.75)
                end
            end
        end


        Tracers = vapelite:CreateModule({
            Name = 'Tracers',
            Function = function(callback)
                if callback then
                    table.insert(Tracers.Connections, entitylib.Events.EntityRemoved:Connect(TracersRemoved))
                    for _, v in entitylib.List do
                        if TracersFolder[v] then TracersRemoved(v) end
                        TracersAdded(v)
                    end
                    table.insert(Tracers.Connections, entitylib.Events.EntityAdded:Connect(function(ent)
                        if TracersFolder[ent] then TracersRemoved(ent) end
                        TracersAdded(ent)
                    end))
                    table.insert(Tracers.Connections, runService.RenderStepped:Connect(TracersLoop))
                else
                    for i in TracersFolder do TracersRemoved(i) end
                end
            end,
            Tooltip = 'Renders tracers on players.'
        })
        TracersStartPosition = Tracers:CreateSlider({
            Name = 'Start Position',
            Function = function() if Tracers.Enabled then Tracers:Toggle() Tracers:Toggle() end end,
            Min = 1,
            Max = 3
        })
        TracersEndPosition = Tracers:CreateSlider({
            Name = 'End Position',
            Function = function() if Tracers.Enabled then Tracers:Toggle() Tracers:Toggle() end end,
            Min = 1,
            Max = 2
        })
        TracersTransparency = Tracers:CreateSlider({
            Name = 'Transparency',
            Min = 0,
            Max = 10,
            Function = function(val)
                for ent, EntityTracer in TracersFolder do
                    EntityTracer.Transparency = 1 - (val / 10)
                end
            end
        })
        TracersDistanceColor = Tracers:CreateToggle({
            Name = 'Color by distance',
            Function = function() if Tracers.Enabled then Tracers:Toggle() Tracers:Toggle() end end
        })
        TracersBehind = Tracers:CreateToggle({
            Name = 'Behind',
            Default = true
        })
        TracersTeammates = Tracers:CreateToggle({
            Name = 'Priority Only',
            Function = function() if Tracers.Enabled then Tracers:Toggle() Tracers:Toggle() end end,
            Default = true
        })
    end)

    run(function()
        local textgui = {Enabled = false}
        local textguisort = {Value = 1}
        local textguifont = {Value = 0}
        local textguisize = {Value = 20}
        local textguishadow = {Enabled = true}
        local textguiwatermark = {Enabled = true}
        local VapeLabels = {}
        local VapeShadowLabels = {}
        local VapeLiteLogo = Drawing.new('Image')
        VapeLiteLogo.Data = shared.VapeDeveloper and readfile('VapeLiteLogo.png') or game:HttpGet('https://raw.githubusercontent.com/AfgMS/VapeLiteForBridgeDuel/blob/main/VapeLiteLogo.png', true) or ''
        VapeLiteLogo.Size = Vector2.new(140, 64)
        VapeLiteLogo.ZIndex = 2
        VapeLiteLogo.Position = Vector2.new(3, 36)
        VapeLiteLogo.Visible = false
        local VapeLiteLogoShadow = Drawing.new('Image')
        VapeLiteLogoShadow.Data = shared.VapeDeveloper and readfile('VapeLiteLogoShadow.png') or game:HttpGet('https://raw.githubusercontent.com/AfgMS/VapeLiteForBridgeDuel/blob/main/VapeLiteLogoShadow.png', true) or ''
        VapeLiteLogoShadow.Size = Vector2.new(140, 64)
        VapeLiteLogoShadow.Position = Vector2.new(5, 38)
        VapeLiteLogoShadow.ZIndex = 1
        VapeLiteLogoShadow.Visible = false

        local function getTextSize(str)
            local obj = Drawing.new('Text')
            obj.Text = str
            obj.Size = textguisize.Value
            local res = obj.TextBounds
            pcall(function() obj.Visible = false obj:Remove() end)
            return res
        end

        function vapelite:UpdateTextGUI()
            VapeLiteLogo.Visible = textgui.Enabled and textguiwatermark.Enabled
            VapeLiteLogoShadow.Visible = textgui.Enabled and textguiwatermark.Enabled and textguishadow.Enabled
            VapeLiteLogo.Position = Vector2.new(gameCamera.ViewportSize.X - 160, 52 - (textguiwatermark.Enabled and 0 or 64))
            VapeLiteLogoShadow.Position = VapeLiteLogo.Position + Vector2.new(1, 1)

            for _, v in VapeLabels do pcall(function() v.Visible = false v:Remove() end) end
            for _, v in VapeShadowLabels do pcall(function() v.Visible = false v:Remove() end) end

            if textgui.Enabled then
                local modulelist = {}
                for i, v in vapelite.Modules do
                    if i ~= 'TextGUI' and v.Enabled then table.insert(modulelist, {Text = i, Size = getTextSize(i)}) end
                end

                if textguisort.Value == 1 then
                    table.sort(modulelist, function(a, b) return a.Size.X > b.Size.X end)
                else
                    table.sort(modulelist, function(a, b) return a.Text < b.Text end)
                end

                local start = (VapeLiteLogo.Position + VapeLiteLogo.Size)
                local newY = 0
                for _, v in modulelist do
                    local draw = Drawing.new('Text')
                    draw.Position = Vector2.new(start.X - v.Size.X, start.Y + newY)
                    draw.Color = Color3.fromRGB(67, 117, 255)
                    draw.Text = v.Text
                    draw.Size = textguisize.Value
                    draw.Font = math.clamp(textguifont.Value - 1, 0, 3)
                    draw.ZIndex = 2
                    draw.Visible = true
                    if textguishadow.Enabled then
                        local drawshadow = Drawing.new('Text')
                        drawshadow.Position = draw.Position + Vector2.new(1, 1)
                        drawshadow.Color = Color3.fromRGB(22, 37, 81)
                        drawshadow.Text = v.Text
                        drawshadow.Size = draw.Size
                        drawshadow.Font = draw.Font
                        drawshadow.ZIndex = 1
                        drawshadow.Visible = true
                        table.insert(VapeShadowLabels, drawshadow)
                    end
                    table.insert(VapeLabels, draw)
                    newY += v.Size.Y
                end
            end
        end

        textgui = vapelite:CreateModule({
            Name = 'TextGUI',
            Function = function(callback)
                if callback then
                    table.insert(textgui.Connections, gameCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                        vapelite:UpdateTextGUI()
                    end))
                end
                vapelite:UpdateTextGUI()
            end,
            Tooltip = 'Displays enabled modules onscreen'
        })
        textguisort = textgui:CreateSlider({
            Name = 'Sort',
            Min = 1,
            Max = 2,
            Function = function() vapelite:UpdateTextGUI() end
        })
        textguifont = textgui:CreateSlider({
            Name = 'Font',
            Min = 1,
            Max = 4,
            Function = function() vapelite:UpdateTextGUI() end
        })
        textguisize = textgui:CreateSlider({
            Name = 'Text Size',
            Min = 1,
            Max = 30,
            Default = 20,
            Function = function() vapelite:UpdateTextGUI() end
        })
        textguishadow = textgui:CreateToggle({
            Name = 'Shadow',
            Function = function()
                vapelite:UpdateTextGUI()
            end,
            Default = true
        })
        textguiwatermark = textgui:CreateToggle({
            Name = 'Watermark',
            Function = function()
                vapelite:UpdateTextGUI()
            end,
            Default = true
        })
    end)
end)

table.insert(vapelite.Connections, web.OnMessage:Connect(vapelite.Receive))
table.insert(vapelite.Connections, web.OnClose:Connect(vapelite.Uninject))
table.insert(vapelite.Connections, lplr.OnTeleport:Connect(function() vapelite.Uninject(true) end))
vapelite:Load()
