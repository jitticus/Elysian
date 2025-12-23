--[[
    Protected UI Library
    Based on Priv9 - Modified with Zenith API anti-detection
    Changes: Tabs on top, narrower/taller, customizable config tab, anti-detection
]]

-- Anti-detection: Clone services
local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local GuiService = cloneref(game:GetService("GuiService"))
local Stats = cloneref(game:GetService("Stats"))

-- Anti-detection: Store GUI references to hide
local hidden_instances = {}

-- Anti-detection: Hook gethui to hide our GUI
local old_gethui = gethui
gethui = newcclosure(function()
    local result = old_gethui()
    for _, inst in hidden_instances do
        if inst and inst.Parent == result then
            inst.Parent = nil
            task.defer(function()
                if inst then inst.Parent = result end
            end)
        end
    end
    return result
end)

-- Anti-detection: Hook getinstances
local old_getinstances = getinstances
getinstances = newcclosure(function()
    local result = old_getinstances()
    local filtered = {}
    for _, inst in result do
        local dominated = false
        for _, hidden in hidden_instances do
            if inst == hidden or inst:IsDescendantOf(hidden) then
                dominated = true
                break
            end
        end
        if not dominated then
            table.insert(filtered, inst)
        end
    end
    return filtered
end)

-- Anti-detection: Hook getnilinstances
if getnilinstances then
    local old_getnilinstances = getnilinstances
    getnilinstances = newcclosure(function()
        local result = old_getnilinstances()
        local filtered = {}
        for _, inst in result do
            local dominated = false
            for _, hidden in hidden_instances do
                if inst == hidden or inst:IsDescendantOf(hidden) then
                    dominated = true
                    break
                end
            end
            if not dominated then
                table.insert(filtered, inst)
            end
        end
        return filtered
    end)
end

-- Shortcuts
local vec2 = Vector2.new
local dim2 = UDim2.new
local dim = UDim.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new
local numseq = NumberSequence.new
local numkey = NumberSequenceKeypoint.new
local dim_offset = UDim2.fromOffset

local camera = workspace.CurrentCamera
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()
local gui_offset = GuiService:GetGuiInset().Y

local clamp = math.clamp
local floor = math.floor
local insert = table.insert
local find = table.find
local remove = table.remove
local concat = table.concat

-- Library init
getgenv().library = {
    directory = "protected_ui",
    folders = {"/fonts", "/configs"},
    flags = {},
    config_flags = {},
    connections = {},
    notifications = {},
    colorpicker_open = false,
    gui = nil,
    sgui = nil,
}

local themes = {
    preset = {
        outline = rgb(10, 10, 10),
        inline = rgb(35, 35, 35),
        text = rgb(180, 180, 180),
        text_outline = rgb(0, 0, 0),
        background = rgb(20, 20, 20),
        ["1"] = hex("#245771"),
        ["2"] = hex("#215D63"),
        ["3"] = hex("#1E6453"),
    },
    utility = {
        inline = {BackgroundColor3 = {}},
        text = {TextColor3 = {}},
        text_outline = {Color = {}},
        ["1"] = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, ScrollBarImageColor3 = {}},
        ["2"] = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, ScrollBarImageColor3 = {}},
        ["3"] = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, ScrollBarImageColor3 = {}},
    }
}

local keys = {
    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.LeftAlt] = "LA",
    [Enum.KeyCode.RightAlt] = "RA", [Enum.KeyCode.CapsLock] = "CAPS",
    [Enum.KeyCode.One] = "1", [Enum.KeyCode.Two] = "2", [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4", [Enum.KeyCode.Five] = "5", [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7", [Enum.KeyCode.Eight] = "8", [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.Zero] = "0", [Enum.KeyCode.Minus] = "-", [Enum.KeyCode.Equals] = "=",
    [Enum.KeyCode.Tilde] = "~", [Enum.KeyCode.LeftBracket] = "[", [Enum.KeyCode.RightBracket] = "]",
    [Enum.KeyCode.Semicolon] = ",", [Enum.KeyCode.Quote] = "'", [Enum.KeyCode.BackSlash] = "\\",
    [Enum.KeyCode.Comma] = ",", [Enum.KeyCode.Period] = ".", [Enum.KeyCode.Slash] = "/",
    [Enum.KeyCode.Backquote] = "`", [Enum.KeyCode.Escape] = "ESC", [Enum.KeyCode.Space] = "SPC",
    [Enum.UserInputType.MouseButton1] = "MB1", [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

library.__index = library

for _, path in library.folders do
    if not isfolder(library.directory .. path) then
        makefolder(library.directory .. path)
    end
end

local flags = library.flags
local config_flags = library.config_flags

-- Font system
local fonts = {}
do
    local function Register_Font(Name, Weight, Style, Asset)
        if not isfile(Asset.Id) then
            writefile(Asset.Id, Asset.Font)
        end
        if isfile(Name .. ".font") then
            delfile(Name .. ".font")
        end
        local Data = {
            name = Name,
            faces = {{name = "Regular", weight = Weight, style = Style, assetId = getcustomasset(Asset.Id)}}
        }
        writefile(Name .. ".font", HttpService:JSONEncode(Data))
        return getcustomasset(Name .. ".font")
    end

    local ProggyTiny = Register_Font("Tahoma", 200, "Normal", {
        Id = "Tahoma.ttf",
        Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/tahoma_bold.ttf"),
    })
    local ProggyClean = Register_Font("ProggyClean", 200, "normal", {
        Id = "ProggyClean.ttf",
        Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf")
    })

    fonts = {
        ["TahomaBold"] = Font.new(ProggyTiny, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        ["ProggyClean"] = Font.new(ProggyClean, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    }
end

-- Utility functions
function library:tween(obj, properties)
    return TweenService:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), properties):Play()
end

function library:mouse_in_frame(uiobject)
    local y_cond = uiobject.AbsolutePosition.Y <= mouse.Y and mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
    local x_cond = uiobject.AbsolutePosition.X <= mouse.X and mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X
    return y_cond and x_cond
end

function library:draggify(frame)
    local dragging, start, start_size = false, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, start, start_size = true, input.Position, frame.Position
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    library:connection(UIS.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local vx, vy = camera.ViewportSize.X, camera.ViewportSize.Y
            frame.Position = dim2(0, clamp(start_size.X.Offset + (input.Position.X - start.X), 0, vx - frame.Size.X.Offset), 0, clamp(start_size.Y.Offset + (input.Position.Y - start.Y), 0, vy - frame.Size.Y.Offset))
        end
    end)
end

function library:resizify(frame)
    local Frame = Instance.new("TextButton")
    Frame.Position, Frame.Size, Frame.BorderSizePixel, Frame.BackgroundTransparency, Frame.Text, Frame.Parent = dim2(1, -10, 1, -10), dim2(0, 10, 0, 10), 0, 1, "", frame
    local resizing, start, start_size, og_size = false, nil, nil, frame.Size
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing, start, start_size = true, input.Position, frame.Size
        end
    end)
    Frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
    library:connection(UIS.InputChanged, function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local vx, vy = camera.ViewportSize.X, camera.ViewportSize.Y
            frame.Size = dim2(start_size.X.Scale, clamp(start_size.X.Offset + (input.Position.X - start.X), og_size.X.Offset, vx), start_size.Y.Scale, clamp(start_size.Y.Offset + (input.Position.Y - start.Y), og_size.Y.Offset, vy))
        end
    end)
end

function library:round(number, float)
    local multiplier = 1 / (float or 1)
    return floor(number * multiplier + 0.5) / multiplier
end

function library:apply_theme(instance, theme, property)
    insert(themes.utility[theme][property], instance)
end

function library:update_theme(theme, color)
    for _, property in themes.utility[theme] do
        for _, object in property do
            if object[_] == themes.preset[theme] then object[_] = color end
        end
    end
    themes.preset[theme] = color
end

function library:connection(signal, callback)
    local connection = signal:Connect(callback)
    insert(library.connections, connection)
    return connection
end

function library:apply_stroke(parent)
    local stroke = library:create("UIStroke", {Parent = parent, Color = themes.preset.text_outline, LineJoinMode = Enum.LineJoinMode.Miter})
    library:apply_theme(stroke, "text_outline", "Color")
end

function library:create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do ins[prop] = value end
    if instance == "TextLabel" or instance == "TextButton" or instance == "TextBox" then
        library:apply_theme(ins, "text", "TextColor3")
        library:apply_stroke(ins)
    end
    return ins
end

function library:convert(str)
    local values = {}
    for value in string.gmatch(str, "[^,]+") do insert(values, tonumber(value)) end
    if #values == 4 then return unpack(values) end
end

function library:convert_enum(enum)
    local parts = {}
    for part in string.gmatch(enum, "[%w_]+") do insert(parts, part) end
    local t = Enum
    for i = 2, #parts do t = t[parts[i]] end
    return t
end

local config_holder
function library:update_config_list()
    if not config_holder then return end
    local list = {}
    for _, file in listfiles(library.directory .. "/configs") do
        local name = file:gsub(library.directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(library.directory .. "\\configs\\", "")
        list[#list + 1] = name
    end
    config_holder.refresh_options(list)
end

function library:get_config()
    local Config = {}
    for _, v in flags do
        if type(v) == "table" and v.key then
            Config[_] = {active = v.active, mode = v.mode, key = tostring(v.key)}
        elseif type(v) == "table" and v["Transparency"] and v["Color"] then
            Config[_] = {Transparency = v["Transparency"], Color = v["Color"]:ToHex()}
        else
            Config[_] = v
        end
    end
    return HttpService:JSONEncode(Config)
end

function library:load_config(config_json)
    local config = HttpService:JSONDecode(config_json)
    for _, v in config do
        local fn = library.config_flags[_]
        if _ == "config_name_list" then continue end
        if fn then
            if type(v) == "table" and v["Transparency"] and v["Color"] then
                fn(hex(v["Color"]), v["Transparency"])
            elseif type(v) == "table" and v["active"] then
                fn(v)
            else
                fn(v)
            end
        end
    end
end

function library:unload_menu()
    if library.gui then library.gui:Destroy() end
    for _, conn in library.connections do conn:Disconnect() end
    if library.sgui then library.sgui:Destroy() end
    library = nil
end
-- Part 2: Window, Tabs, Elements

function library:window(properties)
    local cfg = {
        name = properties.name or properties.Name or "protected",
        size = properties.size or properties.Size or dim2(0, 450, 0, 500), -- CHANGED: narrower, taller
        selected_tab = nil
    }

    -- Anti-detection: Use gethui() with random name
    local gui_parent = gethui and gethui() or CoreGui
    
    library.gui = library:create("ScreenGui", {
        Parent = gui_parent,
        Name = HttpService:GenerateGUID(false), -- Random name
        Enabled = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    
    -- Anti-detection: Register for hiding
    insert(hidden_instances, library.gui)

    local window_outline = library:create("Frame", {
        Parent = library.gui,
        Position = dim2(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2),
        BorderColor3 = rgb(0, 0, 0),
        Size = cfg.size,
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    window_outline.Position = dim2(0, window_outline.AbsolutePosition.X, 0, window_outline.AbsolutePosition.Y)
    cfg.main_outline = window_outline

    library:resizify(window_outline)
    library:draggify(window_outline)

    local title_holder = library:create("Frame", {
        Parent = window_outline,
        BackgroundTransparency = 0.8,
        Position = dim2(0, 2, 0, 2),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -4, 0, 20),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0)
    })

    library:create("TextLabel", {
        FontFace = fonts["TahomaBold"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = title_holder,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    library.gradient = library:create("UIGradient", {
        Color = rgbseq{rgbkey(0, themes.preset["1"]), rgbkey(0.5, themes.preset["2"]), rgbkey(1, themes.preset["3"])},
        Parent = window_outline
    })

    -- CHANGED: Tab bar at TOP instead of bottom
    local tab_button_holder = library:create("Frame", {
        Parent = window_outline,
        BackgroundTransparency = 0.8,
        Position = dim2(0, 2, 0, 24), -- At top, below title
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -4, 0, 20),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0)
    })
    cfg.tab_button_holder = tab_button_holder

    library:create("UIListLayout", {
        VerticalAlignment = Enum.VerticalAlignment.Center,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        Parent = tab_button_holder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalFlex = Enum.UIFlexAlignment.Fill
    })

    function cfg.toggle_menu(bool)
        window_outline.Visible = bool
    end

    return setmetatable(cfg, library)
end

function library:tab(properties)
    local cfg = {
        name = properties.name or "tab",
        count = 0
    }

    local tab_button = library:create("TextButton", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(170, 170, 170),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = self.tab_button_holder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    -- CHANGED: Page position adjusted for top tabs
    local Page = library:create("Frame", {
        Parent = self.main_outline,
        BackgroundTransparency = 0.6,
        Position = dim2(0, 2, 0, 46), -- Below title + tabs
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -4, 1, -48), -- Adjusted size
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0),
        Visible = false,
    })
    cfg.page = Page

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        Parent = Page,
        Padding = dim(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalFlex = Enum.UIFlexAlignment.Fill
    })

    library:create("UIPadding", {
        PaddingTop = dim(0, 2),
        PaddingBottom = dim(0, 2),
        Parent = Page,
        PaddingRight = dim(0, 2),
        PaddingLeft = dim(0, 2)
    })

    function cfg.open_tab()
        if self.selected_tab then
            self.selected_tab[1].Visible = false
            self.selected_tab[2].TextColor3 = rgb(170, 170, 170)
        end
        Page.Visible = true
        tab_button.TextColor3 = rgb(255, 255, 255)
        self.selected_tab = {Page, tab_button}
    end

    tab_button.MouseButton1Down:Connect(function() cfg.open_tab() end)
    if not self.selected_tab then cfg.open_tab() end

    return setmetatable(cfg, library)
end

function library:column(properties)
    self.count += 1
    local cfg = {color = library.gradient.Color.Keypoints[self.count].Value, count = self.count}

    local scrolling_frame = library:create("ScrollingFrame", {
        ScrollBarImageColor3 = rgb(0, 0, 0),
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = self.page,
        LayoutOrder = -1,
        BackgroundTransparency = 1,
        ScrollBarImageTransparency = 1,
        BorderColor3 = rgb(0, 0, 0),
        BackgroundColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        CanvasSize = dim2(0, 0, 0, 0)
    })
    cfg.column = scrolling_frame

    library:create("UIListLayout", {Parent = scrolling_frame, Padding = dim(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})

    return setmetatable(cfg, library)
end

function library:section(properties)
    local cfg = {
        name = properties.name or properties.Name or "section",
        size = properties.size or 1,
        autofill = properties.auto_fill or false,
        count = self.count,
        color = self.color,
    }

    local accent = library:create("Frame", {
        Parent = self.column,
        ClipsDescendants = true,
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

    local dark = library:create("Frame", {
        Parent = accent,
        BackgroundTransparency = 0.6,
        Position = dim2(0, 2, 0, 16),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -4, 1, -18),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0)
    })

    local elements = library:create("Frame", {
        Parent = dark,
        Position = dim2(0, 4, 0, 5),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -8, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    cfg.elements = elements

    if not cfg.autofill then
        elements.AutomaticSize = Enum.AutomaticSize.Y
        accent.AutomaticSize = Enum.AutomaticSize.Y
        accent.Size = dim2(1, 0, 0, 0)
        library:create("UIPadding", {Parent = elements, PaddingBottom = dim(0, 7)})
    else
        accent.Size = dim2(1, 0, cfg.size, 0)
    end

    library:create("UIListLayout", {Parent = elements, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})

    library:create("TextLabel", {
        FontFace = fonts["TahomaBold"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = accent,
        Size = dim2(1, 0, 0, 0),
        Position = dim2(0, 4, 0, 2),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    return setmetatable(cfg, library)
end

-- Toggle
function library:toggle(options)
    local cfg = {
        enabled = options.enabled or nil,
        name = options.name or "Toggle",
        flag = options.flag or options.name or "Flag",
        default = options.default or false,
        folding = options.folding or false,
        callback = options.callback or function() end,
        color = self.color,
        count = self.count,
    }

    local toggle = library:create("TextButton", {
        Parent = self.elements,
        BackgroundTransparency = 1,
        Text = "",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = toggle,
        Size = dim2(1, 0, 1, 0),
        Position = dim2(0, 1, 0, -1),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    local accent = library:create("Frame", {
        AnchorPoint = vec2(1, 0),
        Parent = toggle,
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 12, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

    local fill = library:create("Frame", {
        Parent = accent,
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(fill, tostring(self.count), "BackgroundColor3")

    local elements
    if cfg.folding then
        elements = library:create("Frame", {
            Parent = self.elements,
            BackgroundTransparency = 1,
            Position = dim2(0, 4, 0, 21),
            Size = dim2(1, 0, 0, 0),
            BorderSizePixel = 0,
            Visible = false,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = rgb(255, 255, 255)
        })
        cfg.elements = elements
        library:create("UIListLayout", {
            Parent = elements,
            Padding = dim(0, 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    end

    function cfg.set(bool)
        fill.BackgroundColor3 = bool and themes.preset[tostring(self.count)] or themes.preset.inline
        flags[cfg.flag] = bool
        cfg.callback(bool)
        if cfg.folding and elements then elements.Visible = bool end
    end

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    toggle.MouseButton1Click:Connect(function()
        cfg.enabled = not cfg.enabled
        cfg.set(cfg.enabled)
    end)

    return setmetatable(cfg, library)
end

-- Slider
function library:slider(options)
    local cfg = {
        name = options.name or nil,
        suffix = options.suffix or "",
        flag = options.flag or options.name or "Flag",
        callback = options.callback or function() end,
        min = options.min or 0,
        max = options.max or 100,
        intervals = options.interval or 1,
        default = options.default or 10,
        value = options.default or 10,
        dragging = false,
    }

    local slider = library:create("Frame", {
        Parent = self.elements,
        BackgroundTransparency = 1,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 25),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    local label = library:create("TextLabel", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(255, 255, 255),
        RichText = true,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        Parent = slider,
        Size = dim2(1, 0, 0, 0),
        Position = dim2(0, 1, 0, -2),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    local outline = library:create("TextButton", {
        Parent = slider,
        Text = "",
        AutoButtonColor = false,
        Position = dim2(0, 0, 0, 13),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(outline, tostring(self.count), "BackgroundColor3")

    local inline = library:create("Frame", {
        Parent = outline,
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.inline
    })

    local accent = library:create("Frame", {
        Parent = inline,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0.5, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

    function cfg.set(value)
        local v = tonumber(value)
        if not v then return end
        cfg.value = clamp(library:round(v, cfg.intervals), cfg.min, cfg.max)
        accent.Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), 0, 1, 0)
        label.Text = cfg.name .. "<font color='#AAAAAA'>" .. ' - ' .. tostring(cfg.value) .. cfg.suffix .. "</font>"
        flags[cfg.flag] = cfg.value
        cfg.callback(cfg.value)
    end

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    outline.MouseButton1Down:Connect(function() cfg.dragging = true end)

    library:connection(UIS.InputChanged, function(input)
        if cfg.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local size_x = (input.Position.X - inline.AbsolutePosition.X) / inline.AbsoluteSize.X
            cfg.set(((cfg.max - cfg.min) * size_x) + cfg.min)
        end
    end)

    library:connection(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then cfg.dragging = false end
    end)

    return setmetatable(cfg, library)
end

-- Button
function library:button(options)
    local cfg = {
        name = options.name or "button",
        callback = options.callback or function() end,
    }

    local frame = library:create("TextButton", {
        AnchorPoint = vec2(1, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = self.elements,
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 16),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(frame, tostring(self.count), "BackgroundColor3")

    library:create("Frame", {
        Parent = frame,
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.inline
    })

    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = frame,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Position = dim2(0, 1, 0, 1),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    frame.MouseButton1Click:Connect(function() cfg.callback() end)

    return setmetatable(cfg, library)
end

-- Textbox
function library:textbox(options)
    local cfg = {
        name = options.name or "...",
        placeholder = options.placeholder or "type here...",
        default = options.default,
        flag = options.flag or options.name or "Flag",
        callback = options.callback or function() end,
    }

    local frame = library:create("TextButton", {
        AnchorPoint = vec2(1, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = self.elements,
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 16),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(frame, tostring(self.count), "BackgroundColor3")

    library:create("Frame", {
        Parent = frame,
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset.inline
    })

    local input = library:create("TextBox", {
        Parent = frame,
        FontFace = fonts["ProggyClean"],
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 12,
        Text = "",
        Size = dim2(1, -6, 1, 0),
        RichText = true,
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        CursorPosition = -1,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = dim2(0, 6, 0, 0),
        BorderSizePixel = 0,
        PlaceholderColor3 = rgb(170, 170, 170),
    })

    function cfg.set(text)
        flags[cfg.flag] = text
        input.Text = text
        cfg.callback(text)
    end

    config_flags[cfg.flag] = cfg.set
    if cfg.default then cfg.set(cfg.default) end

    input:GetPropertyChangedSignal("Text"):Connect(function() cfg.set(input.Text) end)

    return setmetatable(cfg, library)
end
-- Part 3: Dropdown, Colorpicker, Keybind, Config

-- Dropdown
function library:dropdown(options)
    local cfg = {
        name = options.name or nil,
        flag = options.flag or options.name or "Flag",
        items = options.items or {""},
        callback = options.callback or function() end,
        multi = options.multi or false,
        open = false,
        option_instances = {},
        multi_items = {},
    }
    cfg.default = options.default or (cfg.multi and {cfg.items[1]}) or cfg.items[1] or "None"
    flags[cfg.flag] = {}

    local dropdown = library:create("Frame", {
        Parent = self.elements,
        BackgroundTransparency = 1,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 16),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    local dropdown_holder = library:create("TextButton", {
        AnchorPoint = vec2(1, 0),
        AutoButtonColor = false,
        Text = "",
        Parent = dropdown,
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0.5, 0, 0, 16),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(dropdown_holder, tostring(self.count), "BackgroundColor3")

    local inline = library:create("Frame", {
        Parent = dropdown_holder,
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(35, 35, 35)
    })

    local text = library:create("TextLabel", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = inline,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Position = dim2(0, 0, 0, 1),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = dropdown,
        Size = dim2(1, 0, 1, 0),
        Position = dim2(0, 1, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    local accent = library:create("Frame", {
        Parent = library.gui,
        Size = dim2(0, 100, 0, 20),
        Position = dim2(0, 500, 0, 100),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

    local holder_inline = library:create("Frame", {
        Parent = accent,
        Size = dim2(1, -2, 1, -2),
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = themes.preset.inline
    })
    library:apply_theme(holder_inline, "inline", "BackgroundColor3")

    library:create("UIListLayout", {Parent = holder_inline, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
    library:create("UIPadding", {PaddingTop = dim(0, 5), PaddingBottom = dim(0, 2), Parent = holder_inline, PaddingRight = dim(0, 6), PaddingLeft = dim(0, 6)})
    library:create("UIPadding", {PaddingBottom = dim(0, 2), Parent = accent})

    function cfg.render_option(txt)
        return library:create("TextButton", {
            FontFace = fonts["ProggyClean"],
            TextColor3 = rgb(170, 170, 170),
            BorderColor3 = rgb(0, 0, 0),
            Text = txt,
            Parent = holder_inline,
            Position = dim2(0, 0, 0, 1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.XY,
            TextSize = 12,
            AutoButtonColor = false,
            BackgroundColor3 = rgb(255, 255, 255)
        })
    end

    function cfg.set_visible(bool) accent.Visible = bool end

    function cfg.set(value)
        local selected = {}
        local isTable = type(value) == "table"
        if value == nil then return end
        for _, option in cfg.option_instances do
            if option.Text == value or (isTable and find(value, option.Text)) then
                insert(selected, option.Text)
                cfg.multi_items = selected
                option.TextColor3 = rgb(255, 255, 255)
            else
                option.TextColor3 = rgb(170, 170, 170)
            end
        end
        text.Text = isTable and concat(selected, ", ") or selected[1]
        flags[cfg.flag] = isTable and selected or selected[1]
        cfg.callback(flags[cfg.flag])
    end

    function cfg.refresh_options(list)
        for _, option in cfg.option_instances do option:Destroy() end
        cfg.option_instances = {}
        for _, option in list do
            local button = cfg.render_option(option)
            insert(cfg.option_instances, button)
            button.MouseButton1Down:Connect(function()
                if cfg.multi then
                    local idx = find(cfg.multi_items, button.Text)
                    if idx then remove(cfg.multi_items, idx) else insert(cfg.multi_items, button.Text) end
                    cfg.set(cfg.multi_items)
                else
                    cfg.set_visible(false)
                    cfg.open = false
                    cfg.set(button.Text)
                end
            end)
        end
    end

    cfg.refresh_options(cfg.items)
    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    dropdown_holder.MouseButton1Click:Connect(function()
        cfg.open = not cfg.open
        accent.Size = dim2(0, dropdown_holder.AbsoluteSize.X, 0, accent.Size.Y.Offset)
        accent.Position = dim2(0, dropdown_holder.AbsolutePosition.X, 0, dropdown_holder.AbsolutePosition.Y + 77)
        cfg.set_visible(cfg.open)
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not (library:mouse_in_frame(accent) or library:mouse_in_frame(dropdown)) then
                cfg.open = false
                cfg.set_visible(false)
            end
        end
    end)

    return setmetatable(cfg, library)
end

-- Colorpicker (simplified)
function library:colorpicker(options)
    local cfg = {
        name = options.name or "Color",
        flag = options.flag or options.name or "Flag",
        color = options.color or Color3.new(1, 1, 1),
        alpha = options.alpha and 1 - options.alpha or 0,
        open = false,
        callback = options.callback or function() end,
    }

    local h, s, v = cfg.color:ToHSV()
    local a = cfg.alpha
    flags[cfg.flag] = {}

    local element = library:create("TextButton", {
        Parent = self.elements,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    local accent = library:create("Frame", {
        AnchorPoint = vec2(1, 0),
        Parent = element,
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 30, 0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

    local color_display = library:create("Frame", {
        Parent = accent,
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = cfg.color
    })

    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = element,
        Size = dim2(1, 0, 1, 0),
        Position = dim2(0, 1, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    function cfg.set(color, alpha)
        if color then h, s, v = color:ToHSV() end
        if alpha then a = alpha end
        local c = Color3.fromHSV(h, s, v)
        color_display.BackgroundColor3 = c
        flags[cfg.flag] = {Color = c, Transparency = a}
        cfg.callback(c, a)
    end

    cfg.set(cfg.color, cfg.alpha)
    config_flags[cfg.flag] = cfg.set

    -- Simple click to cycle colors (simplified picker)
    local hue_step = 0
    element.MouseButton1Click:Connect(function()
        hue_step = (hue_step + 0.1) % 1
        cfg.set(Color3.fromHSV(hue_step, 1, 1), a)
    end)

    return setmetatable(cfg, library)
end

-- Keybind
function library:keybind(options)
    local cfg = {
        flag = options.flag or options.name or "Flag",
        callback = options.callback or function() end,
        open = false,
        binding = nil,
        name = options.name or nil,
        key = options.key or nil,
        mode = options.mode or "toggle",
        active = options.default or false,
        hold_instances = {},
    }
    flags[cfg.flag] = {}

    local keybind = library:create("Frame", {
        Parent = self.elements,
        BackgroundTransparency = 1,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 16),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    local keybind_holder = library:create("TextButton", {
        AnchorPoint = vec2(1, 0),
        AutoButtonColor = false,
        Text = "",
        Parent = keybind,
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0.5, 0, 0, 16),
        BorderSizePixel = 0,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(keybind_holder, tostring(self.count), "BackgroundColor3")

    library:create("Frame", {
        Parent = keybind_holder,
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(35, 35, 35)
    })

    local text = library:create("TextLabel", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = "...",
        Parent = keybind_holder,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Position = dim2(0, 0, 0, -1),
        BorderSizePixel = 0,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"],
        TextColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.name,
        Parent = keybind,
        Size = dim2(1, 0, 1, 0),
        Position = dim2(0, 1, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = 12,
        BackgroundColor3 = rgb(255, 255, 255)
    })

    function cfg.set(input)
        if type(input) == "boolean" then
            cfg.active = cfg.mode == "Always" and true or input
            cfg.callback(cfg.active)
        elseif tostring(input):find("Enum") then
            cfg.key = input.Name == "Escape" and "..." or input
            cfg.callback(cfg.active or false)
        elseif type(input) == "table" then
            if type(input.key) == "string" and input.key ~= "..." then
                input.key = library:convert_enum(input.key)
            end
            cfg.key = input.key == Enum.KeyCode.Escape and "..." or input.key or "..."
            cfg.mode = input.mode or "Toggle"
            if input.active then cfg.active = input.active end
        end
        flags[cfg.flag] = {mode = cfg.mode, key = cfg.key, active = cfg.active}
        local _text = cfg.key and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or "..."
        text.Text = " " .. tostring(_text):gsub("KeyCode.", ""):gsub("UserInputType.", "") .. " "
    end

    config_flags[cfg.flag] = cfg.set
    cfg.set({mode = cfg.mode, active = cfg.active, key = cfg.key})

    keybind_holder.MouseButton1Down:Connect(function()
        text.Text = "..."
        cfg.binding = library:connection(UIS.InputBegan, function(keycode)
            cfg.set(keycode.KeyCode)
            cfg.binding:Disconnect()
            cfg.binding = nil
        end)
    end)

    library:connection(UIS.InputBegan, function(input, gp)
        if not gp and input.KeyCode == cfg.key then
            if cfg.mode == "Toggle" then
                cfg.active = not cfg.active
                cfg.set(cfg.active)
            elseif cfg.mode == "Hold" then
                cfg.set(true)
            end
        end
    end)

    library:connection(UIS.InputEnded, function(input, gp)
        if gp then return end
        local k = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
        if k == cfg.key and cfg.mode == "Hold" then cfg.set(false) end
    end)

    return setmetatable(cfg, library)
end

-- List
function library:list(options)
    local cfg = {
        callback = options.callback or function() end,
        name = options.name or nil,
        scale = options.size or 90,
        items = options.items or {"1", "2", "3"},
        option_instances = {},
        current_instance = nil,
        flag = options.flag or "flag",
    }

    local accent = library:create("Frame", {
        BorderColor3 = rgb(0, 0, 0),
        AnchorPoint = vec2(1, 0),
        Parent = self.elements,
        Position = dim2(1, 0, 0, 0),
        Size = dim2(1, 0, 0, cfg.scale),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = themes.preset[tostring(self.count)]
    })
    library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

    local inline = library:create("Frame", {
        Parent = accent,
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(35, 35, 35)
    })

    local scrollingframe = library:create("ScrollingFrame", {
        ScrollBarImageColor3 = rgb(0, 0, 0),
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = inline,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarImageTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = dim2(0, 0, 0, 0)
    })

    library:create("UIListLayout", {Parent = scrollingframe, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
    library:create("UIPadding", {PaddingTop = dim(0, 2), PaddingBottom = dim(0, 4), Parent = scrollingframe, PaddingRight = dim(0, 5), PaddingLeft = dim(0, 5)})

    function cfg.render_option(txt)
        return library:create("TextButton", {
            FontFace = fonts["ProggyClean"],
            TextColor3 = rgb(170, 170, 170),
            BorderColor3 = rgb(0, 0, 0),
            Text = txt,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Parent = scrollingframe,
            BorderSizePixel = 0,
            Size = dim2(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = rgb(255, 255, 255)
        })
    end

    function cfg.refresh_options(options)
        for _, v in cfg.option_instances do v:Destroy() end
        for _, option in options do
            local button = cfg.render_option(option)
            insert(cfg.option_instances, button)
            button.MouseButton1Click:Connect(function()
                if cfg.current_instance and cfg.current_instance ~= button then
                    cfg.current_instance.TextColor3 = rgb(170, 170, 170)
                end
                cfg.current_instance = button
                button.TextColor3 = rgb(255, 255, 255)
                flags[cfg.flag] = button.Text
                cfg.callback(button.Text)
            end)
        end
    end

    function cfg.set(value)
        for _, btn in cfg.option_instances do
            btn.TextColor3 = btn.Text == value and rgb(255, 255, 255) or rgb(170, 170, 170)
        end
        flags[cfg.flag] = value
        cfg.callback(value)
    end

    cfg.refresh_options(cfg.items)

    return setmetatable(cfg, library)
end

-- CHANGED: Customizable config tab name
function library:init_config(window, tab_name)
    tab_name = tab_name or "Configs" -- Default name, can be customized
    
    local textbox
    local main = window:tab({name = tab_name})
    local section = main:column({}):section({name = "Settings", size = 1, default = true})
    
    config_holder = section:dropdown({
        name = "Configs",
        items = {},
        callback = function(option)
            if textbox then textbox.set(option) end
        end,
        flag = "config_name_list"
    })
    library:update_config_list()
    
    textbox = section:textbox({name = "Config name:", flag = "config_name_text"})
    
    section:button({
        name = "Save",
        callback = function()
            writefile(library.directory .. "/configs/" .. flags["config_name_text"] .. ".cfg", library:get_config())
            library:update_config_list()
        end
    })
    
    section:button({
        name = "Load",
        callback = function()
            library:load_config(readfile(library.directory .. "/configs/" .. flags["config_name_text"] .. ".cfg"))
            library:update_config_list()
        end
    })
    
    section:button({
        name = "Delete",
        callback = function()
            delfile(library.directory .. "/configs/" .. flags["config_name_text"] .. ".cfg")
            library:update_config_list()
        end
    })

    local section2 = main:column({}):section({name = "Menu", size = 1, default = true})
    
    section2:keybind({
        name = "Menu bind",
        callback = function(bool) window.toggle_menu(bool) end,
        default = true
    })
    
    section2:colorpicker({
        name = "Accent 1",
        callback = function(color)
            library:update_theme("1", color)
            library.gradient.Color = rgbseq{rgbkey(0, themes.preset["1"]), rgbkey(0.5, themes.preset["2"]), rgbkey(1, themes.preset["3"])}
        end,
        color = themes.preset["1"]
    })
    
    section2:colorpicker({
        name = "Accent 2",
        callback = function(color)
            library:update_theme("2", color)
            library.gradient.Color = rgbseq{rgbkey(0, themes.preset["1"]), rgbkey(0.5, themes.preset["2"]), rgbkey(1, themes.preset["3"])}
        end,
        color = themes.preset["2"]
    })
    
    section2:colorpicker({
        name = "Accent 3",
        callback = function(color)
            library:update_theme("3", color)
            library.gradient.Color = rgbseq{rgbkey(0, themes.preset["1"]), rgbkey(0.5, themes.preset["2"]), rgbkey(1, themes.preset["3"])}
        end,
        color = themes.preset["3"]
    })

    main:column({})
end

-- Watermark + Notifications holder
library.sgui = library:create("ScreenGui", {
    Name = HttpService:GenerateGUID(false),
    Parent = gethui and gethui() or CoreGui
})
insert(hidden_instances, library.sgui)

return library
