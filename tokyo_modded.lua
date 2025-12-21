local startupArgs = ({...})[1] or {}

if getgenv().library ~= nil then
    getgenv().library:Unload()
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- // Cached Services
local Players = game:GetService('Players')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Stats = game:GetService('Stats')
local ContextActionService = game:GetService('ContextActionService')

local LocalPlayer = Players.LocalPlayer

-- // Cached Functions & Constructors
local floor, ceil, huge, pi, clamp, rad, random = math.floor, math.ceil, math.huge, math.pi, math.clamp, math.rad, math.random
local c3new, fromrgb, fromhsv = Color3.new, Color3.fromRGB, Color3.fromHSV
local next, newInstance, newUDim2, newVector2, typeof = next, Instance.new, UDim2.new, Vector2.new, typeof
local tableinsert, tableclear, tablefind, tableconcat = table.insert, table.clear, table.find, table.concat
local stringfind, stringsplit = string.find, string.split

local isexecutorclosure = isexecutorclosure or is_synapse_function or is_sirhurt_closure or iskrnlclosure
local executor = (syn and 'syn' or getexecutorname and getexecutorname() or 'unknown')

local library = {
    windows = {},
    indicators = {},
    flags = {},
    options = {},
    connections = {},
    drawings = {},
    instances = {},
    utility = {},
    notifications = {},
    tweens = {},
    theme = {},
    zindexOrder = {
        ['indicator'] = 950,
        ['window'] = 1000,
        ['dropdown'] = 1200,
        ['colorpicker'] = 1100,
        ['watermark'] = 1300,
        ['notification'] = 1400,
        ['cursor'] = 1500,
    },
    stats = {
        ['fps'] = 0,
        ['ping'] = 0,
    },
    images = {
        ['gradientp90'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/gradient90.png',
        ['gradientp45'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/gradient45.png',
        ['colorhue'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/lgbtqshit.png',
        ['colortrans'] = 'https://raw.githubusercontent.com/portallol/luna/main/modules/trans.png',
    },
    numberStrings = {['Zero'] = 0, ['One'] = 1, ['Two'] = 2, ['Three'] = 3, ['Four'] = 4, ['Five'] = 5, ['Six'] = 6, ['Seven'] = 7, ['Eight'] = 8, ['Nine'] = 9},
    signal = loadstring(game:HttpGet('https://raw.githubusercontent.com/drillygzzly/Other/main/1414'))(),
    open = false,
    opening = false,
    hasInit = false,
    cheatname = startupArgs.cheatname or 'Clanware',
    gamename = startupArgs.gamename or 'Universal',
    fileext = startupArgs.fileext or '.txt',
}

library.themes = {
    {
        name = 'Default',
        theme = {
            ['Accent']                    = fromrgb(124,97,196),
            ['Background']                = fromrgb(17,17,17),
            ['Border']                    = fromrgb(0,0,0),
            ['Border 1']                  = fromrgb(47,47,47),
            ['Border 2']                  = fromrgb(17,17,17),
            ['Border 3']                  = fromrgb(10,10,10),
            ['Primary Text']              = fromrgb(235,235,235),
            ['Group Background']          = fromrgb(17,17,17),
            ['Selected Tab Background']   = fromrgb(17,17,17),
            ['Unselected Tab Background'] = fromrgb(17,17,17),
            ['Selected Tab Text']         = fromrgb(245,245,245),
            ['Unselected Tab Text']       = fromrgb(145,145,145),
            ['Section Background']        = fromrgb(17,17,17),
            ['Option Text 1']             = fromrgb(245,245,245),
            ['Option Text 2']             = fromrgb(195,195,195),
            ['Option Text 3']             = fromrgb(145,145,145),
            ['Option Border 1']           = fromrgb(47,47,47),
            ['Option Border 2']           = fromrgb(0,0,0),
            ['Option Background']         = fromrgb(35,35,35),
            ["Risky Text"]                = fromrgb(175, 21, 21),
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41),
        }
    },
    {
        name = 'Midnight',
        theme = {
            ['Accent']                    = fromrgb(103,89,179),
            ['Background']                = fromrgb(22,22,31),
            ['Border']                    = fromrgb(0,0,0),
            ['Border 1']                  = fromrgb(50,50,50),
            ['Border 2']                  = fromrgb(24,25,37),
            ['Border 3']                  = fromrgb(10,10,10),
            ['Primary Text']              = fromrgb(235,235,235),
            ['Group Background']          = fromrgb(22,22,31),
            ['Selected Tab Background']   = fromrgb(22,22,31),
            ['Unselected Tab Background'] = fromrgb(22,22,31),
            ['Selected Tab Text']         = fromrgb(245,245,245),
            ['Unselected Tab Text']       = fromrgb(145,145,145),
            ['Section Background']        = fromrgb(22,22,31),
            ['Option Text 1']             = fromrgb(245,245,245),
            ['Option Text 2']             = fromrgb(195,195,195),
            ['Option Text 3']             = fromrgb(145,145,145),
            ['Option Border 1']           = fromrgb(50,50,50),
            ['Option Border 2']           = fromrgb(0,0,0),
            ['Option Background']         = fromrgb(40,40,55),
            ["Risky Text"]                = fromrgb(175, 21, 21),
            ["Risky Text Enabled"]        = fromrgb(255, 41, 41),
        }
    },
}

library.theme = library.themes[1].theme

local utility = library.utility

-- // Input Signals
local mousemove, button1down, button1up, button2down, button2up, scrollforward, scrollback, keypressed, keyreleased, inputbegin, inputend

-- // Utility Functions

function utility:GetMousePos()
    return UserInputService:GetMouseLocation()
end

local textMeasure = Drawing.new('Text')
textMeasure.Font = 2
textMeasure.Size = 13

function utility:GetStringSize(str, font, size)
    textMeasure.Font = font or 2
    textMeasure.Size = size or 13
    textMeasure.Text = str
    return textMeasure.TextBounds
end

function utility:GetStringFit(str, maxX, font, size, endStr)
    local fullSize = self:GetStringSize(str, font, size)
    if fullSize.X < maxX then
        return str
    end
    local split = stringsplit(str, '')
    local splitLen = #split
    for i = 1, splitLen do
        if self:GetStringSize(tableconcat(split, '', 1, i), font, size).X > maxX then
            return tableconcat(split, '', 1, i - 1) .. (endStr or '')
        end
    end
    return str
end

function utility:Tween(Object, Property, Value, Time, ...)
    local tween = TweenService:Create(Object, TweenInfo.new(Time or 0.1, ...), {[Property] = Value})
    local tweenCache = library.tweens[Object]
    if tweenCache and tweenCache[Property] then
        tweenCache[Property]:Cancel()
    end
    library.tweens[Object] = tweenCache or {}
    library.tweens[Object][Property] = tween
    tween:Play()
end

function utility:Connection(signal, callback)
    local connection = signal:Connect(callback)
    tableinsert(library.connections, connection)
    return connection
end

function utility:BindAction(action, callback, ...)
    ContextActionService:BindAction(action, callback, ...)
end

function utility:UnbindAction(action)
    ContextActionService:UnbindAction(action)
end

-- // Optimized Draw Function
local function applyThemeColor(wrapper, object, themeKey, offset, class)
    local col = library.theme[themeKey]
    if not col then return end
    
    offset = offset or 0
    local r = clamp(col.R * 255 + offset, 0, 255)
    local g = clamp(col.G * 255 + offset, 0, 255)
    local b = clamp(col.B * 255 + offset, 0, 255)
    local newColor = fromrgb(r, g, b)
    
    object.BackgroundColor3 = newColor
    if class == 'Text' then
        object.TextColor3 = newColor
    end
end

function utility:Draw(class, props)
    local object
    
    if class == 'Square' then
        object = newInstance('Frame')
        object.BorderSizePixel = 0
    elseif class == 'Text' then
        object = newInstance('TextLabel')
        object.BackgroundTransparency = 1
        object.RichText = true
        object.TextXAlignment = Enum.TextXAlignment.Left
    elseif class == 'Image' then
        object = newInstance('ImageLabel')
        object.BackgroundTransparency = 1
        object.BorderSizePixel = 0
    elseif class == 'ScrollFrame' then
        object = newInstance('ScrollingFrame')
        object.BorderSizePixel = 0
        object.ScrollBarThickness = 3
        object.ScrollBarImageColor3 = library.theme['Accent']
        object.CanvasSize = newUDim2(0, 0, 0, 0)
        object.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end

    local wrapper = {
        Object = object,
        Class = class,
        ThemeColor = nil,
        ThemeColorOffset = 0,
        _hover = false,
    }

    wrapper.MouseEnter = object.MouseEnter
    wrapper.MouseLeave = object.MouseLeave
    
    -- Mouse button signals
    local mb1DownSignal = library.signal.new()
    local mb1UpSignal = library.signal.new()
    
    object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            mb1DownSignal:Fire()
        end
    end)
    
    object.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            mb1UpSignal:Fire()
        end
    end)
    
    wrapper.MouseButton1Down = mb1DownSignal
    wrapper.MouseButton1Up = mb1UpSignal

    local mt = {}
    
    mt.__index = function(self, key)
        if key == 'Transparency' then
            return 1 - object.BackgroundTransparency
        elseif key == 'Visible' then
            return object.Visible
        elseif key == 'Parent' then
            return object.Parent
        elseif key == 'Position' then
            return object.Position
        elseif key == 'Size' then
            if class == 'Text' then
                return object.TextSize
            end
            return object.Size
        elseif key == 'ZIndex' then
            return object.ZIndex
        elseif key == 'Color' then
            return object.BackgroundColor3
        elseif key == 'Text' then
            return object.Text or ''
        elseif key == 'TextBounds' then
            return object.TextBounds or newVector2(0, 0)
        elseif key == 'Data' then
            return object.Image
        elseif key == 'Hover' then
            return wrapper._hover
        end
        return rawget(self, key)
    end

    mt.__newindex = function(self, key, value)
        if key == 'Transparency' then
            object.BackgroundTransparency = 1 - value
        elseif key == 'Visible' then
            object.Visible = value
        elseif key == 'Parent' then
            if value == nil then
                object.Parent = nil
            elseif typeof(value) == 'table' then
                object.Parent = value.Object
            else
                object.Parent = value
            end
        elseif key == 'Position' then
            object.Position = value
        elseif key == 'Size' then
            if class == 'Text' and typeof(value) == 'number' then
                object.TextSize = value
            else
                object.Size = value
            end
        elseif key == 'ZIndex' then
            object.ZIndex = value
        elseif key == 'Color' then
            object.BackgroundColor3 = value
        elseif key == 'ThemeColor' then
            rawset(self, 'ThemeColor', value)
            if value and library.theme[value] then
                applyThemeColor(self, object, value, rawget(self, 'ThemeColorOffset') or 0, class)
            end
        elseif key == 'ThemeColorOffset' then
            rawset(self, 'ThemeColorOffset', value)
            local tc = rawget(self, 'ThemeColor')
            if tc and library.theme[tc] then
                applyThemeColor(self, object, tc, value, class)
            end
        elseif key == 'Text' then
            object.Text = value
        elseif key == 'Font' then
            object.Font = Enum.Font.Code
            object.TextSize = value == 2 and 13 or 14
        elseif key == 'Outline' then
            object.TextStrokeTransparency = value and 0.5 or 1
        elseif key == 'Center' then
            object.TextXAlignment = value and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        elseif key == 'Data' then
            if value and stringfind(value, 'http') then
                task.spawn(function()
                    local success, result = pcall(game.HttpGet, game, value)
                    if success and result then
                        object.Image = result
                    end
                end)
            else
                object.Image = value
            end
        else
            rawset(self, key, value)
        end
    end

    setmetatable(wrapper, mt)

    object.MouseEnter:Connect(function()
        wrapper._hover = true
    end)
    object.MouseLeave:Connect(function()
        wrapper._hover = false
    end)

    if props then
        for k, v in next, props do
            wrapper[k] = v
        end
    end

    tableinsert(library.drawings, wrapper)
    return wrapper
end

function utility:GetDescendants(object)
    local descendants = {}
    local function recurse(obj)
        local children = obj:GetChildren()
        for i = 1, #children do
            local child = children[i]
            tableinsert(descendants, child)
            recurse(child)
        end
    end
    recurse(object)
    return descendants
end

-- // ScreenGui Setup
local screenGui = newInstance('ScreenGui')
screenGui.Name = 'TokyoLib'
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.ResetOnSpawn = false

if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
end

screenGui.Parent = (gethui and gethui()) or game:GetService('CoreGui')

library.screenGui = screenGui

-- // Input Setup
mousemove = library.signal.new()
button1down = library.signal.new()
button1up = library.signal.new()
button2down = library.signal.new()
button2up = library.signal.new()
scrollforward = library.signal.new()
scrollback = library.signal.new()
keypressed = library.signal.new()
keyreleased = library.signal.new()
inputbegin = library.signal.new()
inputend = library.signal.new()

local MouseButton1 = Enum.UserInputType.MouseButton1
local MouseButton2 = Enum.UserInputType.MouseButton2
local MouseMovement = Enum.UserInputType.MouseMovement
local MouseWheel = Enum.UserInputType.MouseWheel
local Keyboard = Enum.UserInputType.Keyboard

utility:Connection(UserInputService.InputBegan, function(input, gpe)
    local inputType = input.UserInputType
    if inputType == MouseButton1 then
        button1down:Fire(utility:GetMousePos())
    elseif inputType == MouseButton2 then
        button2down:Fire(utility:GetMousePos())
    elseif inputType == Keyboard then
        keypressed:Fire(input.KeyCode)
    end
    inputbegin:Fire(input, gpe)
end)

utility:Connection(UserInputService.InputEnded, function(input, gpe)
    local inputType = input.UserInputType
    if inputType == MouseButton1 then
        button1up:Fire(utility:GetMousePos())
    elseif inputType == MouseButton2 then
        button2up:Fire(utility:GetMousePos())
    elseif inputType == Keyboard then
        keyreleased:Fire(input.KeyCode)
    end
    inputend:Fire(input, gpe)
end)

utility:Connection(UserInputService.InputChanged, function(input, gpe)
    local inputType = input.UserInputType
    if inputType == MouseMovement then
        mousemove:Fire(utility:GetMousePos())
    elseif inputType == MouseWheel then
        if input.Position.Z > 0 then
            scrollforward:Fire()
        else
            scrollback:Fire()
        end
    end
end)

-- // Notification System
function library:SendNotification(text, duration)
    duration = duration or 3
    print('[Tokyo] ' .. tostring(text))
end

-- // Settings Tab
function library:CreateSettingsTab(window)
    local tab = window:AddTab("Settings")
    local themeSection = tab:AddSection("Theme", 1)
    local configSection = tab:AddSection("Config", 2)

    local themeNames = {}
    local themes = library.themes
    for i = 1, #themes do
        tableinsert(themeNames, themes[i].name)
    end

    themeSection:AddList({
        text = "Theme",
        values = themeNames,
        selected = "Default",
        callback = function(val)
            for i = 1, #themes do
                local t = themes[i]
                if t.name == val then
                    library.theme = t.theme
                    local drawings = library.drawings
                    for j = 1, #drawings do
                        local drawing = drawings[j]
                        if drawing.ThemeColor then
                            drawing.ThemeColor = drawing.ThemeColor
                        end
                    end
                    break
                end
            end
        end
    })

    return tab
end

-- // Window
function library.NewWindow(data)
    local window = {
        title = data.title or 'Window',
        size = data.size or newUDim2(0, 500, 0, 400),
        tabs = {},
        open = true,
        objects = {},
        dropdown = {
            selected = nil,
            objects = {
                values = {},
            },
        },
        colorpicker = {
            selected = nil,
            color = fromrgb(255, 255, 255),
            trans = 0,
            objects = {},
        },
    }

    tableinsert(library.windows, window)

    -- Create Objects
    do
        local objs = window.objects
        local z = library.zindexOrder.window

        objs.background = utility:Draw('Square', {
            Size = window.size,
            Position = newUDim2(0.5, -window.size.X.Offset / 2, 0.5, -window.size.Y.Offset / 2),
            ThemeColor = 'Background',
            ZIndex = z,
            Parent = screenGui,
        })

        objs.border1 = utility:Draw('Square', {
            Size = newUDim2(1, 2, 1, 2),
            Position = newUDim2(0, -1, 0, -1),
            ThemeColor = 'Border',
            ZIndex = z - 1,
            Parent = objs.background,
        })

        objs.border2 = utility:Draw('Square', {
            Size = newUDim2(1, 2, 1, 2),
            Position = newUDim2(0, -1, 0, -1),
            ThemeColor = 'Border 1',
            ZIndex = z - 2,
            Parent = objs.border1,
        })

        objs.border3 = utility:Draw('Square', {
            Size = newUDim2(1, 2, 1, 2),
            Position = newUDim2(0, -1, 0, -1),
            ThemeColor = 'Border',
            ZIndex = z - 3,
            Parent = objs.border2,
        })

        objs.topbar = utility:Draw('Square', {
            Size = newUDim2(1, 0, 0, 20),
            ThemeColor = 'Background',
            ZIndex = z + 1,
            Parent = objs.background,
        })

        objs.title = utility:Draw('Text', {
            Position = newUDim2(0, 5, 0, 3),
            ThemeColor = 'Primary Text',
            Text = window.title,
            Size = 13,
            Font = 2,
            ZIndex = z + 2,
            Parent = objs.topbar,
        })

        objs.tabHolder = utility:Draw('Square', {
            Size = newUDim2(1, -10, 0, 20),
            Position = newUDim2(0, 5, 0, 22),
            Transparency = 0,
            ZIndex = z + 3,
            Parent = objs.background,
        })

        objs.tabHolderLayout = newInstance('UIListLayout')
        objs.tabHolderLayout.FillDirection = Enum.FillDirection.Horizontal
        objs.tabHolderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        objs.tabHolderLayout.Padding = UDim.new(0, 2)
        objs.tabHolderLayout.Parent = objs.tabHolder.Object

        objs.contentHolder = utility:Draw('Square', {
            Size = newUDim2(1, -10, 1, -50),
            Position = newUDim2(0, 5, 0, 45),
            ThemeColor = 'Group Background',
            ZIndex = z + 4,
            Parent = objs.background,
        })

        objs.columnholder1 = utility:Draw('ScrollFrame', {
            Size = newUDim2(0.5, -3, 1, -5),
            Position = newUDim2(0, 0, 0, 5),
            Transparency = 0,
            ZIndex = z + 5,
            Parent = objs.contentHolder,
        })
        objs.columnholder1.Object.ScrollBarThickness = 2
        objs.columnholder1.Object.ScrollBarImageColor3 = library.theme['Accent']

        local layout1 = newInstance('UIListLayout')
        layout1.FillDirection = Enum.FillDirection.Vertical
        layout1.Padding = UDim.new(0, 5)
        layout1.Parent = objs.columnholder1.Object

        objs.columnholder2 = utility:Draw('ScrollFrame', {
            Size = newUDim2(0.5, -3, 1, -5),
            Position = newUDim2(0.5, 3, 0, 5),
            Transparency = 0,
            ZIndex = z + 5,
            Parent = objs.contentHolder,
        })
        objs.columnholder2.Object.ScrollBarThickness = 2
        objs.columnholder2.Object.ScrollBarImageColor3 = library.theme['Accent']

        local layout2 = newInstance('UIListLayout')
        layout2.FillDirection = Enum.FillDirection.Vertical
        layout2.Padding = UDim.new(0, 5)
        layout2.Parent = objs.columnholder2.Object

        -- Dropdown container
        objs.dropdownHolder = utility:Draw('Square', {
            Size = newUDim2(0, 150, 0, 200),
            Position = newUDim2(0, 0, 0, 0),
            ThemeColor = 'Background',
            ZIndex = library.zindexOrder.dropdown,
            Visible = false,
            Parent = screenGui,
        })
    end

    -- Dropdown refresh
    window.dropdown.objects.background = window.objects.dropdownHolder

    function window.dropdown:Refresh()
        local list = self.selected
        if not list then return end
        
        local holder = window.objects.dropdownHolder
        local holderObj = holder.Object

        -- Clear existing
        local children = holderObj:GetChildren()
        for i = 1, #children do
            local child = children[i]
            if child:IsA('Frame') or child:IsA('TextButton') then
                child:Destroy()
            end
        end

        local y = 2
        local listSelected = list.selected
        local isMulti = list.multi
        local values = list.values
        local dropdownZ = library.zindexOrder.dropdown + 1
        
        for idx = 1, #values do
            local value = values[idx]
            local isSelected = (typeof(listSelected) == 'table' and tablefind(listSelected, value)) or listSelected == value
            
            local btn = newInstance('TextButton')
            btn.Size = UDim2.new(1, -4, 0, 18)
            btn.Position = UDim2.new(0, 2, 0, y)
            btn.BackgroundColor3 = isSelected and fromrgb(60, 60, 60) or fromrgb(35, 35, 35)
            btn.BorderSizePixel = 0
            btn.Text = tostring(value)
            btn.TextColor3 = fromrgb(200, 200, 200)
            btn.TextSize = 13
            btn.Font = Enum.Font.Code
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.ZIndex = dropdownZ
            btn.Parent = holderObj

            btn.MouseButton1Click:Connect(function()
                local newSelected
                
                if isMulti then
                    newSelected = {}
                    for i, v in next, listSelected do
                        if v ~= "none" then
                            newSelected[i] = v
                        end
                    end
                    local foundIdx = tablefind(newSelected, value)
                    if foundIdx then
                        table.remove(newSelected, foundIdx)
                    else
                        tableinsert(newSelected, value)
                    end
                else
                    newSelected = value
                end

                list:Select(newSelected)

                if not isMulti then
                    list.open = false
                    list.objects.openText.Text = '+'
                    window.dropdown.selected = nil
                    holder.Visible = false
                else
                    self:Refresh()
                end
            end)

            y = y + 20
        end

        local holderObjSize = list.objects.holder.Object.AbsoluteSize
        holder.Size = newUDim2(0, holderObjSize.X - 4, 0, y + 2)
        local pos = list.objects.holder.Object.AbsolutePosition
        holder.Position = newUDim2(0, pos.X + 2, 0, pos.Y + holderObjSize.Y)
        holder.Visible = true
    end

    function window:AddTab(text, order)
        local tab = {
            text = text,
            order = order or #self.tabs + 1,
            objects = {},
            sections = {},
        }

        tableinsert(self.tabs, tab)

        -- Create Objects
        do
            local objs = tab.objects
            local z = library.zindexOrder.window + 5

            objs.background = utility:Draw('Square', {
                Size = newUDim2(0, 80, 1, 0),
                ThemeColor = 'Unselected Tab Background',
                ZIndex = z,
                Parent = window.objects.tabHolder,
            })

            objs.text = utility:Draw('Text', {
                Position = newUDim2(0.5, 0, 0.5, -6),
                ThemeColor = 'Unselected Tab Text',
                Text = text,
                Size = 13,
                Font = 2,
                ZIndex = z + 1,
                Center = true,
                Parent = objs.background,
            })

            utility:Connection(objs.background.Object.MouseButton1Click, function()
                tab:Select()
            end)
        end

        function tab:Select()
            local tabs = window.tabs
            for i = 1, #tabs do
                local t = tabs[i]
                t.objects.background.ThemeColor = 'Unselected Tab Background'
                t.objects.text.ThemeColor = 'Unselected Tab Text'
                local sections = t.sections
                for j = 1, #sections do
                    sections[j].objects.background.Visible = false
                end
            end

            self.objects.background.ThemeColor = 'Selected Tab Background'
            self.objects.text.ThemeColor = 'Selected Tab Text'

            local sections = self.sections
            for i = 1, #sections do
                sections[i].objects.background.Visible = true
            end

            task.defer(function()
                for i = 1, #sections do
                    sections[i]:UpdateOptions()
                end
            end)
        end

        function tab:AddSection(text, side, order)
            local section = {
                text = tostring(text),
                side = side == nil and 1 or clamp(side, 1, 2),
                order = order or #self.sections + 1,
                enabled = true,
                objects = {},
                options = {},
            }

            tableinsert(self.sections, section)

            -- Create Objects
            do
                local objs = section.objects
                local z = library.zindexOrder.window + 15

                objs.background = utility:Draw('Square', {
                    Size = newUDim2(1, 0, 0, 30),
                    ThemeColor = 'Section Background',
                    ZIndex = z,
                    Parent = window.objects['columnholder' .. section.side],
                })

                objs.innerBorder = utility:Draw('Square', {
                    Size = newUDim2(1, 2, 1, 2),
                    Position = newUDim2(0, -1, 0, -1),
                    ThemeColor = 'Border 3',
                    ZIndex = z - 1,
                    Parent = objs.background,
                })

                objs.outerBorder = utility:Draw('Square', {
                    Size = newUDim2(1, 2, 1, 2),
                    Position = newUDim2(0, -1, 0, -1),
                    ThemeColor = 'Border 1',
                    ZIndex = z - 2,
                    Parent = objs.innerBorder,
                })

                objs.topBorder = utility:Draw('Square', {
                    Size = newUDim2(1, 0, 0, 1),
                    ThemeColor = 'Accent',
                    ZIndex = z + 1,
                    Parent = objs.background,
                })

                objs.textlabel = utility:Draw('Text', {
                    Position = newUDim2(0, 5, 0, -7),
                    ThemeColor = 'Primary Text',
                    Text = text,
                    Size = 13,
                    Font = 2,
                    ZIndex = z + 2,
                    Parent = objs.background,
                })

                objs.optionholder = utility:Draw('Square', {
                    Size = newUDim2(1, -10, 1, -15),
                    Position = newUDim2(0, 5, 0, 13),
                    Transparency = 0,
                    ZIndex = z + 3,
                    Parent = objs.background,
                })

                local optionLayout = newInstance('UIListLayout')
                optionLayout.FillDirection = Enum.FillDirection.Vertical
                optionLayout.Padding = UDim.new(0, 2)
                optionLayout.Parent = objs.optionholder.Object
            end

            function section:UpdateOptions()
                local totalHeight = 15
                local options = self.options
                for i = 1, #options do
                    local option = options[i]
                    if option.enabled ~= false and option.objects.holder then
                        totalHeight = totalHeight + option.objects.holder.Object.AbsoluteSize.Y + 2
                    end
                end
                self.objects.background.Size = newUDim2(1, 0, 0, math.max(30, totalHeight))
            end

            function section:AddSeparator(data)
                local separator = {
                    class = 'separator',
                    text = data and data.text or '',
                    order = #self.options + 1,
                    enabled = true,
                    objects = {},
                }

                tableinsert(self.options, separator)

                do
                    local objs = separator.objects
                    local z = library.zindexOrder.window + 25

                    objs.holder = utility:Draw('Square', {
                        Size = newUDim2(1, 0, 0, 18),
                        Transparency = 0,
                        ZIndex = z,
                        Parent = section.objects.optionholder,
                    })

                    objs.line = utility:Draw('Square', {
                        Size = newUDim2(1, -4, 0, 1),
                        Position = newUDim2(0, 2, 0.5, 0),
                        ThemeColor = 'Border 1',
                        ZIndex = z + 1,
                        Parent = objs.holder,
                    })

                    if separator.text ~= '' then
                        objs.text = utility:Draw('Text', {
                            Position = newUDim2(0.5, 0, 0, 1),
                            ThemeColor = 'Option Text 3',
                            Text = separator.text,
                            Size = 13,
                            Font = 2,
                            ZIndex = z + 2,
                            Center = true,
                            Parent = objs.holder,
                        })
                    end
                end

                self:UpdateOptions()
                return separator
            end

            function section:AddToggle(data)
                local toggle = {
                    class = 'toggle',
                    flag = data.flag,
                    text = data.text or '',
                    state = data.state or false,
                    callback = data.callback or function() end,
                    enabled = true,
                    risky = data.risky or false,
                    objects = {},
                    options = {},
                }

                tableinsert(self.options, toggle)

                if toggle.flag then
                    library.flags[toggle.flag] = toggle.state
                    library.options[toggle.flag] = toggle
                end

                do
                    local objs = toggle.objects
                    local z = library.zindexOrder.window + 25

                    objs.holder = utility:Draw('Square', {
                        Size = newUDim2(1, 0, 0, 17),
                        Transparency = 0,
                        ZIndex = z,
                        Parent = section.objects.optionholder,
                    })

                    objs.checkbox = utility:Draw('Square', {
                        Size = newUDim2(0, 8, 0, 8),
                        Position = newUDim2(0, 2, 0, 4),
                        ThemeColor = 'Option Background',
                        ZIndex = z + 1,
                        Parent = objs.holder,
                    })

                    objs.checkboxBorder = utility:Draw('Square', {
                        Size = newUDim2(1, 2, 1, 2),
                        Position = newUDim2(0, -1, 0, -1),
                        ThemeColor = 'Option Border 1',
                        ZIndex = z,
                        Parent = objs.checkbox,
                    })

                    objs.text = utility:Draw('Text', {
                        Position = newUDim2(0, 18, 0, 1),
                        ThemeColor = 'Option Text 3',
                        Text = toggle.text,
                        Size = 13,
                        Font = 2,
                        ZIndex = z + 1,
                        Parent = objs.holder,
                    })

                    utility:Connection(objs.holder.Object.MouseButton1Click, function()
                        toggle:SetState(not toggle.state)
                    end)

                    utility:Connection(objs.holder.MouseEnter, function()
                        objs.checkboxBorder.ThemeColor = 'Accent'
                    end)

                    utility:Connection(objs.holder.MouseLeave, function()
                        objs.checkboxBorder.ThemeColor = toggle.state and 'Accent' or 'Option Border 1'
                    end)
                end

                function toggle:SetState(bool, nocallback)
                    if typeof(bool) == 'boolean' then
                        self.state = bool
                        if self.flag then
                            library.flags[self.flag] = bool
                        end

                        self.objects.checkbox.ThemeColor = bool and 'Accent' or 'Option Background'
                        self.objects.checkboxBorder.ThemeColor = bool and 'Accent' or 'Option Border 1'
                        self.objects.text.ThemeColor = bool and 'Option Text 1' or 'Option Text 3'

                        if not nocallback then
                            self.callback(bool)
                        end
                    end
                end

                function toggle:AddBind(data)
                    return toggle
                end

                function toggle:AddColor(data)
                    return toggle
                end

                toggle:SetState(toggle.state, true)
                section:UpdateOptions()
                return toggle
            end

            function section:AddSlider(data)
                local slider = {
                    class = 'slider',
                    flag = data.flag,
                    text = data.text or '',
                    value = data.default or data.value or 0,
                    min = data.min or 0,
                    max = data.max or 100,
                    increment = data.increment or 1,
                    suffix = data.suffix or '',
                    callback = data.callback or function() end,
                    enabled = true,
                    dragging = false,
                    objects = {},
                }

                tableinsert(self.options, slider)

                if slider.flag then
                    library.flags[slider.flag] = slider.value
                    library.options[slider.flag] = slider
                end

                do
                    local objs = slider.objects
                    local z = library.zindexOrder.window + 25

                    objs.holder = utility:Draw('Square', {
                        Size = newUDim2(1, 0, 0, 32),
                        Transparency = 0,
                        ZIndex = z,
                        Parent = section.objects.optionholder,
                    })

                    objs.text = utility:Draw('Text', {
                        Position = newUDim2(0, 2, 0, 1),
                        ThemeColor = 'Option Text 3',
                        Text = slider.text,
                        Size = 13,
                        Font = 2,
                        ZIndex = z + 1,
                        Parent = objs.holder,
                    })

                    objs.background = utility:Draw('Square', {
                        Size = newUDim2(1, -4, 0, 11),
                        Position = newUDim2(0, 2, 0, 17),
                        ThemeColor = 'Option Background',
                        ZIndex = z + 1,
                        Parent = objs.holder,
                    })

                    objs.fill = utility:Draw('Square', {
                        Size = newUDim2(0, 0, 1, 0),
                        ThemeColor = 'Accent',
                        ZIndex = z + 2,
                        Parent = objs.background,
                    })

                    objs.border = utility:Draw('Square', {
                        Size = newUDim2(1, 2, 1, 2),
                        Position = newUDim2(0, -1, 0, -1),
                        ThemeColor = 'Option Border 1',
                        ZIndex = z,
                        Parent = objs.background,
                    })

                    objs.valueText = utility:Draw('Text', {
                        Position = newUDim2(0.5, 0, 0, -1),
                        ThemeColor = 'Option Text 2',
                        Text = tostring(slider.value) .. slider.suffix,
                        Size = 13,
                        Font = 2,
                        ZIndex = z + 3,
                        Center = true,
                        Parent = objs.background,
                    })

                    local function updateSlider(input)
                        local bgObj = objs.background.Object
                        local pos = input.Position.X
                        local bgPos = bgObj.AbsolutePosition.X
                        local bgSize = bgObj.AbsoluteSize.X
                        local percent = clamp((pos - bgPos) / bgSize, 0, 1)
                        local value = slider.min + (slider.max - slider.min) * percent
                        value = floor(value / slider.increment + 0.5) * slider.increment
                        slider:SetValue(value)
                    end

                    utility:Connection(objs.background.Object.InputBegan, function(input)
                        if input.UserInputType == MouseButton1 then
                            slider.dragging = true
                            updateSlider(input)
                        end
                    end)

                    utility:Connection(UserInputService.InputChanged, function(input)
                        if slider.dragging and input.UserInputType == MouseMovement then
                            updateSlider(input)
                        end
                    end)

                    utility:Connection(UserInputService.InputEnded, function(input)
                        if input.UserInputType == MouseButton1 then
                            slider.dragging = false
                        end
                    end)
                end

                function slider:SetValue(value, nocallback)
                    value = clamp(value, self.min, self.max)
                    value = floor(value / self.increment + 0.5) * self.increment
                    self.value = value

                    if self.flag then
                        library.flags[self.flag] = value
                    end

                    local percent = (value - self.min) / (self.max - self.min)
                    self.objects.fill.Size = newUDim2(percent, 0, 1, 0)
                    self.objects.valueText.Text = tostring(value) .. self.suffix

                    if not nocallback then
                        self.callback(value)
                    end
                end

                slider:SetValue(slider.value, true)
                section:UpdateOptions()
                return slider
            end

            function section:AddList(data)
                local list = {
                    class = 'list',
                    flag = data.flag,
                    text = data.text or '',
                    values = data.values or {},
                    selected = data.selected or (data.values and data.values[1]) or '',
                    multi = data.multi or false,
                    callback = data.callback or function() end,
                    enabled = true,
                    open = false,
                    objects = {},
                }

                tableinsert(self.options, list)

                if list.flag then
                    library.flags[list.flag] = list.selected
                    library.options[list.flag] = list
                end

                do
                    local objs = list.objects
                    local z = library.zindexOrder.window + 25

                    objs.holder = utility:Draw('Square', {
                        Size = newUDim2(1, 0, 0, 38),
                        Transparency = 0,
                        ZIndex = z,
                        Parent = section.objects.optionholder,
                    })

                    objs.text = utility:Draw('Text', {
                        Position = newUDim2(0, 2, 0, 1),
                        ThemeColor = 'Option Text 3',
                        Text = list.text,
                        Size = 13,
                        Font = 2,
                        ZIndex = z + 1,
                        Parent = objs.holder,
                    })

                    objs.background = utility:Draw('Square', {
                        Size = newUDim2(1, -4, 0, 18),
                        Position = newUDim2(0, 2, 0, 17),
                        ThemeColor = 'Option Background',
                        ZIndex = z + 1,
                        Parent = objs.holder,
                    })

                    objs.border = utility:Draw('Square', {
                        Size = newUDim2(1, 2, 1, 2),
                        Position = newUDim2(0, -1, 0, -1),
                        ThemeColor = 'Option Border 1',
                        ZIndex = z,
                        Parent = objs.background,
                    })

                    objs.selectedText = utility:Draw('Text', {
                        Position = newUDim2(0, 4, 0, 1),
                        ThemeColor = 'Option Text 2',
                        Text = tostring(list.selected),
                        Size = 13,
                        Font = 2,
                        ZIndex = z + 2,
                        Parent = objs.background,
                    })

                    objs.openText = utility:Draw('Text', {
                        Position = newUDim2(1, -12, 0, 1),
                        ThemeColor = 'Option Text 3',
                        Text = '+',
                        Size = 13,
                        Font = 2,
                        ZIndex = z + 2,
                        Parent = objs.background,
                    })

                    utility:Connection(objs.background.Object.MouseButton1Click, function()
                        if list.open then
                            list.open = false
                            objs.openText.Text = '+'
                            if window.dropdown.selected == list then
                                window.dropdown.selected = nil
                                window.objects.dropdownHolder.Visible = false
                            end
                        else
                            if window.dropdown.selected ~= nil then
                                window.dropdown.selected.open = false
                                window.dropdown.selected.objects.openText.Text = '+'
                            end
                            list.open = true
                            objs.openText.Text = '-'
                            window.dropdown.selected = list
                            window.dropdown:Refresh()
                        end
                    end)

                    utility:Connection(objs.holder.MouseEnter, function()
                        objs.border.ThemeColor = 'Accent'
                    end)

                    utility:Connection(objs.holder.MouseLeave, function()
                        objs.border.ThemeColor = 'Option Border 1'
                    end)
                end

                function list:Select(option, nocallback)
                    option = typeof(option) == 'table' and (self.multi and option or (option[1] or '')) or option
                    self.selected = option

                    local text = typeof(option) == 'table' and (#option == 0 and 'none' or tableconcat(option, ', ')) or tostring(option)
                    self.objects.selectedText.Text = text

                    if self.flag then
                        library.flags[self.flag] = self.selected
                    end

                    if not nocallback then
                        self.callback(self.selected)
                    end
                end

                function list:SetValue(value)
                    self:Select(value)
                end

                function list:SetValues(newValues)
                    self.values = newValues
                    if window.dropdown.selected == self then
                        window.dropdown:Refresh()
                    end
                end

                function list:AddValue(value)
                    tableinsert(self.values, tostring(value))
                    if window.dropdown.selected == self then
                        window.dropdown:Refresh()
                    end
                end

                function list:RemoveValue(value)
                    local idx = tablefind(self.values, value)
                    if idx then
                        table.remove(self.values, idx)
                        if window.dropdown.selected == self then
                            window.dropdown:Refresh()
                        end
                    end
                end

                function list:ClearValues()
                    tableclear(self.values)
                    if window.dropdown.selected == self then
                        window.dropdown:Refresh()
                    end
                end

                list:Select(list.selected, true)
                section:UpdateOptions()
                return list
            end

            section:UpdateOptions()
            return section
        end

        function tab:UpdateSections()
            local sections = self.sections
            for i = 1, #sections do
                sections[i]:UpdateOptions()
            end
        end

        -- Auto-select first tab
        if #window.tabs == 1 then
            task.defer(function()
                tab:Select()
            end)
        end

        return tab
    end

    return window
end

function library:init()
    library.hasInit = true
    library.open = true

    -- Close dropdown when clicking elsewhere
    utility:Connection(UserInputService.InputBegan, function(input)
        if input.UserInputType == MouseButton1 then
            local windows = library.windows
            for i = 1, #windows do
                local win = windows[i]
                local dropdownSelected = win.dropdown.selected
                if dropdownSelected then
                    local holder = win.objects.dropdownHolder
                    local pos = utility:GetMousePos()
                    local holderObj = holder.Object
                    local absPos = holderObj.AbsolutePosition
                    local absSize = holderObj.AbsoluteSize

                    if pos.X < absPos.X or pos.X > absPos.X + absSize.X or
                       pos.Y < absPos.Y or pos.Y > absPos.Y + absSize.Y then
                        local listHolder = dropdownSelected.objects.holder
                        local lObj = listHolder.Object
                        local lPos = lObj.AbsolutePosition
                        local lSize = lObj.AbsoluteSize

                        if pos.X < lPos.X or pos.X > lPos.X + lSize.X or
                           pos.Y < lPos.Y or pos.Y > lPos.Y + lSize.Y then
                            dropdownSelected.open = false
                            dropdownSelected.objects.openText.Text = '+'
                            win.dropdown.selected = nil
                            holder.Visible = false
                        end
                    end
                end
            end
        end
    end)

    -- Force initial layout update
    task.defer(function()
        task.wait(0.1)
        local windows = library.windows
        for i = 1, #windows do
            local win = windows[i]
            local tabs = win.tabs
            if #tabs > 0 then
                tabs[1]:Select()
            end
        end
    end)
end

function library:Unload()
    local connections = library.connections
    for i = 1, #connections do
        connections[i]:Disconnect()
    end

    if screenGui then
        screenGui:Destroy()
    end
    
    if textMeasure then
        textMeasure:Remove()
    end

    getgenv().library = nil
end

getgenv().library = library
return library
