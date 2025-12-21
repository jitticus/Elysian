--[[
    NexusUI Library v1.0
    Combines: VaderHaxx aesthetics + Octohook functionality + Anti-detection
    
    Features:
    - Protected ScreenGui (gethui())
    - Multi-layered VaderHaxx border system
    - ESP Preview system from Octohook
    - Full UI element suite
    - Config system
    - Notification system
    - Watermark with FPS
    - Keybind list
]]

-- Anti-Detection: Environment cleanup
local function cleanEnv()
    for k, v in pairs(_G) do
        if type(v) == "table" and rawget(v, "NexusUI") then _G[k] = nil end
    end
    for k, v in pairs(getgenv()) do
        if type(v) == "table" and rawget(v, "NexusUI") then getgenv()[k] = nil end
    end
end
cleanEnv()

-- Services
local Services = setmetatable({}, {
    __index = function(self, svc)
        local s = game:GetService(svc)
        rawset(self, svc, s)
        return s
    end
})

local UserInputService = Services.UserInputService
local Players = Services.Players
local Workspace = Services.Workspace
local HttpService = Services.HttpService
local GuiService = Services.GuiService
local Lighting = Services.Lighting
local RunService = Services.RunService
local Stats = Services.Stats
local CoreGui = Services.CoreGui
local TweenService = Services.TweenService

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local GuiOffset = GuiService:GetGuiInset().Y

-- Constructors
local vec2, vec3 = Vector2.new, Vector3.new
local dim2, dim, dim_offset = UDim2.new, UDim.new, UDim2.fromOffset
local color, rgb, hex, hsv = Color3.new, Color3.fromRGB, Color3.fromHex, Color3.fromHSV
local rgbseq, rgbkey = ColorSequence.new, ColorSequenceKeypoint.new
local numseq, numkey = NumberSequence.new, NumberSequenceKeypoint.new
local rect = Rect.new

-- Protected parent
local function getProtectedParent()
    return (typeof(gethui) == "function" and gethui()) or CoreGui
end

-- Library Init
getgenv().NexusUI = {
    Directory = "nexusui",
    Folders = {"/fonts", "/configs"},
    Flags = {},
    ConfigFlags = {},
    Connections = {},
    Notifications = {Notifs = {}},
    OpenElement = {},
    EasingStyle = Enum.EasingStyle.Quint,
    TweeningSpeed = 0.25,
    DraggingSpeed = 0.05,
    Tweening = false,
}

local Library = getgenv().NexusUI
Library.__index = Library

-- Themes (VaderHaxx + Octohook hybrid)
local themes = {
    preset = {
        a = rgb(10, 10, 15),      -- outer outline
        b = rgb(46, 46, 51),      -- inline
        c = rgb(36, 36, 41),      -- inner
        d = rgb(20, 20, 25),      -- background
        e = rgb(30, 30, 35),      -- misc_1
        f = rgb(23, 23, 28),      -- misc_2
        g = rgb(15, 15, 20),      -- dark bg
        outline = rgb(10, 10, 15),
        inline = rgb(46, 46, 51),
        accent = rgb(19, 128, 225),
        background = rgb(20, 20, 25),
        misc_1 = rgb(30, 30, 35),
        misc_2 = rgb(23, 23, 28),
        text_color = rgb(245, 245, 245),
        unselected = rgb(145, 145, 145),
        tooltip = rgb(73, 73, 73),
        font = "ProggyClean",
        textsize = 12,
    },
    utility = {},
    gradients = {elements = {}},
}

for theme, _ in pairs(themes.preset) do
    if theme ~= "font" and theme ~= "textsize" then
        themes.utility[theme] = {
            BackgroundColor3 = {},
            TextColor3 = {},
            ImageColor3 = {},
            ScrollBarImageColor3 = {},
            Color = {},
        }
    end
end

-- Keys
local Keys = {
    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.LeftAlt] = "LA",
    [Enum.KeyCode.RightAlt] = "RA", [Enum.KeyCode.CapsLock] = "CAPS",
    [Enum.KeyCode.One] = "1", [Enum.KeyCode.Two] = "2", [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4", [Enum.KeyCode.Five] = "5", [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7", [Enum.KeyCode.Eight] = "8", [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.Zero] = "0", [Enum.KeyCode.Escape] = "ESC", [Enum.KeyCode.Space] = "SPC",
    [Enum.UserInputType.MouseButton1] = "MB1", [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

-- Fonts
local FontNames = {
    ["ProggyClean"] = "ProggyClean.ttf",
    ["Tahoma"] = "fs-tahoma-8px.ttf",
    ["Verdana"] = "Verdana-Font.ttf",
}
local FontIndexes = {"ProggyClean", "Tahoma", "Verdana"}
local Fonts = {}

-- Init folders
for _, path in ipairs(Library.Folders) do
    if not isfolder(Library.Directory .. path) then
        pcall(makefolder, Library.Directory .. path)
    end
end

-- Font registration
local function RegisterFont(Name, Weight, Asset)
    local fontFile = Library.Directory .. "/fonts/" .. Asset
    if not isfile(fontFile) then
        local ok, data = pcall(function()
            return game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/" .. Asset)
        end)
        if ok and data then writefile(fontFile, data) end
    end
    if not isfile(fontFile) then return nil end
    
    local fontPath = Library.Directory .. "/fonts/" .. Name .. ".font"
    if isfile(fontPath) then delfile(fontPath) end
    
    local Data = {
        name = Name,
        faces = {{
            name = "Normal", weight = Weight, style = "Normal",
            assetId = getcustomasset(fontFile),
        }},
    }
    writefile(fontPath, HttpService:JSONEncode(Data))
    return getcustomasset(fontPath)
end

for name, suffix in pairs(FontNames) do
    local reg = RegisterFont(name, 400, suffix)
    Fonts[name] = reg and Font.new(reg, Enum.FontWeight.Regular, Enum.FontStyle.Normal) or Font.fromEnum(Enum.Font.Code)
end

local Flags = Library.Flags
local ConfigFlags = Library.ConfigFlags
local Notifications = Library.Notifications

--[[ UTILITY FUNCTIONS ]]--

function Library:GetTransparency(obj)
    if obj:IsA("Frame") then return {"BackgroundTransparency"}
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then return {"TextTransparency", "BackgroundTransparency"}
    elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then return {"BackgroundTransparency", "ImageTransparency"}
    elseif obj:IsA("ScrollingFrame") then return {"BackgroundTransparency", "ScrollBarImageTransparency"}
    elseif obj:IsA("TextBox") then return {"TextTransparency", "BackgroundTransparency"}
    elseif obj:IsA("UIStroke") then return {"Transparency"}
    end
    return nil
end

function Library:Tween(Object, Properties, Info)
    local tween = TweenService:Create(Object, Info or TweenInfo.new(Library.TweeningSpeed, Library.EasingStyle, Enum.EasingDirection.InOut), Properties)
    tween:Play()
    return tween
end

function Library:Fade(obj, prop, vis, speed)
    if not (obj and prop) then return end
    local OldTransparency = obj[prop]
    obj[prop] = vis and 1 or OldTransparency
    local Tween = Library:Tween(obj, {[prop] = vis and OldTransparency or 1}, TweenInfo.new(speed or Library.TweeningSpeed, Library.EasingStyle, Enum.EasingDirection.InOut))
    Library:Connection(Tween.Completed, function()
        if not vis then task.wait() obj[prop] = OldTransparency end
    end)
    return Tween
end

function Library:Hovering(Object)
    if type(Object) == "table" then
        for _, obj in ipairs(Object) do if Library:Hovering(obj) then return true end end
        return false
    else
        if not Object or not Object.AbsolutePosition then return false end
        return Object.AbsolutePosition.Y <= Mouse.Y and Mouse.Y <= Object.AbsolutePosition.Y + Object.AbsoluteSize.Y
            and Object.AbsolutePosition.X <= Mouse.X and Mouse.X <= Object.AbsolutePosition.X + Object.AbsoluteSize.X
    end
end

function Library:Draggify(Parent)
    local Dragging, InitialSize, InitialPosition = false, Parent.Position, nil
    Parent.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging, InitialPosition, InitialSize = true, Input.Position, Parent.Position
        end
    end)
    Parent.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end
    end)
    Library:Connection(UserInputService.InputChanged, function(Input)
        if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
            local NewPos = dim2(0,
                math.clamp(InitialSize.X.Offset + (Input.Position.X - InitialPosition.X), 0, Camera.ViewportSize.X - Parent.Size.X.Offset), 0,
                math.clamp(InitialSize.Y.Offset + (Input.Position.Y - InitialPosition.Y), 0, Camera.ViewportSize.Y - Parent.Size.Y.Offset))
            Library:Tween(Parent, {Position = NewPos}, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear))
        end
    end)
end

function Library:Resizify(Parent)
    local Resizing = Library:Create("TextButton", {Position = dim2(1, -10, 1, -10), Size = dim2(0, 10, 0, 10), BackgroundTransparency = 1, Text = "", Parent = Parent})
    local IsResizing, Size, InputLost, ParentSize = false, nil, nil, Parent.Size
    Resizing.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then IsResizing, InputLost, Size = true, input.Position, Parent.Size end end)
    Resizing.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then IsResizing = false end end)
    Library:Connection(UserInputService.InputChanged, function(input)
        if IsResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            Library:Tween(Parent, {Size = dim2(Size.X.Scale, math.clamp(Size.X.Offset + (input.Position.X - InputLost.X), ParentSize.X.Offset, Camera.ViewportSize.X), Size.Y.Scale, math.clamp(Size.Y.Offset + (input.Position.Y - InputLost.Y), ParentSize.Y.Offset, Camera.ViewportSize.Y))}, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear))
        end
    end)
end

function Library:ConvertHex(c) return string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)) end
function Library:ConvertFromHex(c) c = c:gsub("#","") return Color3.new(tonumber(c:sub(1,2),16)/255, tonumber(c:sub(3,4),16)/255, tonumber(c:sub(5,6),16)/255) end
function Library:Round(num, float) local M = 1/(float or 1) return math.floor(num*M+0.5)/M end
function Library:Lerp(s, f, t) return s*(1-(t or 0.125)) + f*(t or 0.125) end

function Library:Connection(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Library.Connections, conn)
    return conn
end

function Library:CloseElement()
    if not Library.OpenElement then return end
    for i = 1, #Library.OpenElement do
        local Data = Library.OpenElement[i]
        if not Data.Ignore then Data.SetVisible(false) Data.Open = false end
    end
    Library.OpenElement = {}
end

function Library:Themify(instance, theme, property)
    if themes.utility[theme] and themes.utility[theme][property] then
        table.insert(themes.utility[theme][property], instance)
    end
end

function Library:SaveGradient(instance, theme)
    if themes.gradients[theme] then table.insert(themes.gradients[theme], instance) end
end

function Library:RefreshTheme(theme, newColor)
    if not themes.utility[theme] then return end
    for property, instances in pairs(themes.utility[theme]) do
        for _, object in ipairs(instances) do if object and object[property] then object[property] = newColor end end
    end
    themes.preset[theme] = newColor
end

function Library:Create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in pairs(options) do ins[prop] = value end
    if ins.ClassName == "TextButton" then ins.AutoButtonColor = false ins.Text = ins.Text or "" end
    return ins
end

--[[ CONFIG SYSTEM ]]--
local ConfigHolder
function Library:UpdateConfigList()
    if not ConfigHolder then return end
    local List = {}
    for _, file in ipairs(listfiles(Library.Directory .. "/configs")) do
        List[#List+1] = file:gsub(Library.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Library.Directory .. "\\configs\\", "")
    end
    ConfigHolder.RefreshOptions(List)
end

function Library:GetConfig()
    local Config = {}
    for Idx, Value in pairs(Flags) do
        if type(Value) == "table" and Value.Key then
            Config[Idx] = {Active = Value.Active, Mode = Value.Mode, Key = tostring(Value.Key)}
        elseif type(Value) == "table" and Value.Transparency and Value.Color then
            Config[Idx] = {Transparency = Value.Transparency, Color = Value.Color:ToHex()}
        else Config[Idx] = Value end
    end
    return HttpService:JSONEncode(Config)
end

function Library:LoadConfig(JSON)
    local Config = HttpService:JSONDecode(JSON)
    for Idx, Value in pairs(Config) do
        if Idx == "ignore" then continue end
        local Function = ConfigFlags[Idx]
        if Function then
            if type(Value) == "table" and Value.Transparency and Value.Color then
                Function(hex(Value.Color), Value.Transparency)
            else Function(Value) end
        end
    end
end

--[[ STATUS LIST (Keybind List) ]]--
function Library:StatusList(properties)
    local Cfg = {Name = properties.Name or "List", Items = {}}
    local Items = Cfg.Items
    
    Items.List = Library:Create("Frame", {Parent = Library.Elements, Size = dim2(0, 120, 0, 20), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = themes.preset.outline})
    Library:Themify(Items.List, "outline", "BackgroundColor3")
    Library:Draggify(Items.List)
    
    Items.Inline = Library:Create("Frame", {Parent = Items.List, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.inline})
    Items.Background = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.misc_1})
    Items.Title = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Background, TextColor3 = themes.preset.text_color, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Position = dim2(0.5,0,0,5), AnchorPoint = vec2(0.5,0), BorderSizePixel = 0, BackgroundTransparency = 1, RichText = true, ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Title, LineJoinMode = Enum.LineJoinMode.Miter})
    Library:Create("UIPadding", {Parent = Items.Title, PaddingBottom = dim(0,5), PaddingLeft = dim(0,5), PaddingRight = dim(0,3)})
    Items.Accent = Library:Create("Frame", {Parent = Items.Background, AnchorPoint = vec2(1,0), Position = dim2(1,0,0,0), Size = dim2(1,0,0,1), BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent})
    Library:Themify(Items.Accent, "accent", "BackgroundColor3")
    
    Items.Holder = Library:Create("Frame", {Parent = Library.Elements, Position = dim2(0,50,0,100), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1})
    Library:Create("UIListLayout", {Parent = Items.Holder, Padding = dim(0,-1), SortOrder = Enum.SortOrder.LayoutOrder})
    
    Items.List:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        Items.Holder.Position = Items.List.Position + dim_offset(0, 23)
        Items.List.Size = dim2(0, math.max(0, Items.Holder.AbsoluteSize.X, 120), 0, 20)
    end)
    Items.Holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Items.List.Size = dim2(0, math.max(0, Items.Holder.AbsoluteSize.X, 120), 0, 20)
    end)
    task.delay(0.01, function() Items.List.Position = dim2(0, 50, 0, 700) end)
    
    return setmetatable(Cfg, Library)
end

function Library:ListElement(properties)
    local Cfg = {Name = properties.Name or "Text", Items = {}}
    local Items = Cfg.Items
    
    Items.Outline = Library:Create("Frame", {Parent = self.Items.Holder, Size = dim2(1,0,0,20), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = themes.preset.outline})
    Items.Inline = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.inline})
    Items.Background = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.misc_1})
    Items.Title = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Background, TextColor3 = themes.preset.text_color, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Position = dim2(0,0,0,3), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, RichText = true, ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Title, LineJoinMode = Enum.LineJoinMode.Miter})
    Library:Create("UIPadding", {Parent = Items.Title, PaddingBottom = dim(0,5), PaddingLeft = dim(0,5)})
    
    function Cfg.SetVisible(bool) Items.Outline.Visible = bool end
    function Cfg.SetText(str) Items.Title.Text = str end
    
    return setmetatable(Cfg, Library)
end

--[[ IMAGE HOLDER (Octohook Style) ]]--
function Library:ImageHolder(properties)
    local Cfg = {Name = properties.Name or "Viewer", Items = {}}
    local Items = Cfg.Items
    
    Items.Glow = Library:Create("ImageLabel", {ImageColor3 = themes.preset.accent, ScaleType = Enum.ScaleType.Slice, ImageTransparency = 0.65, Parent = Library.Elements, Image = "rbxassetid://18245826428", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, SliceCenter = rect(vec2(21, 21), vec2(79, 79))})
    Library:Themify(Items.Glow, "accent", "ImageColor3")
    Library:Draggify(Items.Glow)
    
    Items.OutlineMenu = Library:Create("Frame", {Parent = Items.Glow, Size = dim2(0, 0, 0, 101), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.outline})
    Items.AccentMenu = Library:Create("Frame", {Parent = Items.OutlineMenu, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.accent})
    Library:Themify(Items.AccentMenu, "accent", "BackgroundColor3")
    Items.InlineMenu = Library:Create("Frame", {Parent = Items.AccentMenu, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.background})
    
    Items.Title = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.InlineMenu, TextColor3 = themes.preset.text_color, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Position = dim2(0,0,0,3), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, RichText = true, ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Title, LineJoinMode = Enum.LineJoinMode.Miter})
    Library:Create("UIPadding", {Parent = Items.Title, PaddingBottom = dim(0,5), PaddingLeft = dim(0,5), PaddingRight = dim(0,3)})
    
    Items.InnerSection = Library:Create("Frame", {Parent = Items.InlineMenu, Position = dim2(0,4,0,18), Size = dim2(1,-8,1,-22), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.outline})
    Items.InnerInline = Library:Create("Frame", {Parent = Items.InnerSection, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.inline})
    Items.InnerBackground = Library:Create("Frame", {Parent = Items.InnerInline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.misc_1})
    
    Library:Create("UIListLayout", {Parent = Items.InnerBackground, Padding = dim(0,4), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal})
    Library:Create("UIPadding", {Parent = Items.InnerBackground, PaddingTop = dim(0,4), PaddingBottom = dim(0,4), PaddingRight = dim(0,-4), PaddingLeft = dim(0,4)})
    Library:Create("UIPadding", {Parent = Items.Glow, PaddingTop = dim(0,20), PaddingBottom = dim(0,20), PaddingRight = dim(0,20), PaddingLeft = dim(0,20)})
    
    function Cfg.SetVisible(bool) Items.Glow.Visible = bool end
    
    return setmetatable(Cfg, Library)
end

function Library:AddImage(properties)
    local Cfg = {Image = properties.Image or "rbxassetid://86659429043601", Items = {}}
    local Items = Cfg.Items
    
    Items.Outline = Library:Create("Frame", {Parent = self.Items.InnerBackground, Size = dim2(0, 63, 0, 63), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Inline = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.Background = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.misc_1})
    Items.Image = Library:Create("ImageLabel", {Parent = Items.Background, BackgroundTransparency = 1, Image = Cfg.Image, Size = dim2(1,0,1,0), BorderSizePixel = 0})
    
    function Cfg.Remove() Items.Outline:Destroy() end
    
    return setmetatable(Cfg, Library)
end

--[[ WINDOW ]]--
function Library:Window(properties)
    local Cfg = {Name = properties.Name or "NexusUI", Size = properties.Size or dim2(0, 550, 0, 450), Items = {}, Tweening = false, Tick = tick(), Fps = 0}
    
    Library.Items = Library:Create("ScreenGui", {Parent = getProtectedParent(), Name = "\0", Enabled = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 100})
    Library.Other = Library:Create("ScreenGui", {Parent = getProtectedParent(), Name = "\0", Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true})
    Library.Elements = Library:Create("ScreenGui", {Parent = getProtectedParent(), Name = "\0", Enabled = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 100})
    Library.Blur = Library:Create("BlurEffect", {Parent = Lighting, Enabled = true, Size = 0})
    Library.KeybindList = Library:StatusList({Name = "Keybinds"})
    
    local Items = Cfg.Items
    Items.Holder = Library:Create("Frame", {Parent = Library.Items, BackgroundTransparency = 1, Visible = true, Size = Cfg.Size, Position = dim2(0.5, -Cfg.Size.X.Offset/2, 0.5, -Cfg.Size.Y.Offset/2), BorderSizePixel = 0})
    
    -- VaderHaxx multi-layer borders
    Items.OuterOutline = Library:Create("Frame", {Parent = Items.Holder, Size = dim2(1,0,1,0), BorderSizePixel = 0, BackgroundColor3 = themes.preset.a})
    Library:Themify(Items.OuterOutline, "outline", "BackgroundColor3")
    Items.Inline1 = Library:Create("Frame", {Parent = Items.OuterOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.b})
    Library:Create("UIStroke", {Parent = Items.Inline1, Color = themes.preset.b, Transparency = 0.75})
    Items.Inline2 = Library:Create("Frame", {Parent = Items.Inline1, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.c})
    Items.Inline3 = Library:Create("Frame", {Parent = Items.Inline2, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.c})
    Items.Inline4 = Library:Create("Frame", {Parent = Items.Inline3, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.b})
    Items.Background = Library:Create("Frame", {Parent = Items.Inline4, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.d, BackgroundTransparency = 0.35})
    Library:Themify(Items.Background, "background", "BackgroundColor3")
    
    -- Title bar
    Items.TitleBar = Library:Create("Frame", {Parent = Items.Background, Size = dim2(1,0,0,25), BorderSizePixel = 0, BackgroundTransparency = 1})
    Items.Title = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.TitleBar, TextColor3 = themes.preset.text_color, Text = Cfg.Name, Position = dim2(0,8,0,0), Size = dim2(1,-16,1,0), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14})
    Library:Create("UIStroke", {Parent = Items.Title, LineJoinMode = Enum.LineJoinMode.Miter})
    Items.AccentLine = Library:Create("Frame", {Parent = Items.Background, Position = dim2(0,0,0,25), Size = dim2(1,0,0,1), BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent})
    Library:Themify(Items.AccentLine, "accent", "BackgroundColor3")
    
    -- Tab holder
    Items.TabHolder = Library:Create("Frame", {Parent = Items.Background, Position = dim2(0,8,0,30), Size = dim2(1,-16,0,22), BorderSizePixel = 0, BackgroundTransparency = 1})
    Library:Create("UIListLayout", {Parent = Items.TabHolder, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0,4), SortOrder = Enum.SortOrder.LayoutOrder})
    
    -- Content area
    Items.ContentArea = Library:Create("Frame", {Parent = Items.Background, Position = dim2(0,8,0,56), Size = dim2(1,-16,1,-64), BorderSizePixel = 0, BackgroundColor3 = themes.preset.a})
    Items.ContentInline = Library:Create("Frame", {Parent = Items.ContentArea, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.g})
    Items.ContentBackground = Library:Create("Frame", {Parent = Items.ContentInline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.d, ClipsDescendants = true})
    Library:Themify(Items.ContentBackground, "background", "BackgroundColor3")
    
    -- Window buttons
    Items.WindowButtonHolder = Library:Create("Frame", {Parent = Items.TitleBar, AnchorPoint = vec2(1,0.5), Position = dim2(1,-5,0.5,0), Size = dim2(0,0,0,16), BorderSizePixel = 0, BackgroundTransparency = 1})
    Library:Create("UIListLayout", {Parent = Items.WindowButtonHolder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = dim(0,7), SortOrder = Enum.SortOrder.LayoutOrder})
    
    -- Watermark
    Items.Watermark = Library:Create("Frame", {Parent = Library.Elements, Visible = false, Position = dim2(0,20,0,33), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = themes.preset.outline})
    Library:Draggify(Items.Watermark)
    Items.WatermarkAccent = Library:Create("Frame", {Parent = Items.Watermark, Position = dim2(0,2,0,2), Size = dim2(1,-3,0,1), ZIndex = 3, BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent})
    Items.WatermarkGradient = Library:Create("UIGradient", {Parent = Items.WatermarkAccent, Transparency = numseq{numkey(0,0), numkey(0.5,1), numkey(1,0)}})
    Items.WatermarkInline = Library:Create("Frame", {Parent = Items.Watermark, Position = dim2(0,1,0,1), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = themes.preset.inline})
    Items.WatermarkBackground = Library:Create("Frame", {Parent = Items.WatermarkInline, Position = dim2(0,1,0,1), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = themes.preset.misc_1})
    Items.WatermarkText = Library:Create("TextLabel", {RichText = true, Parent = Items.WatermarkBackground, TextColor3 = themes.preset.accent, Text = Cfg.Name..' <font color="rgb(235,235,235)">| 0fps | 0ms</font>', AutomaticSize = Enum.AutomaticSize.XY, BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, FontFace = Fonts[themes.preset.font], ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.WatermarkText, LineJoinMode = Enum.LineJoinMode.Miter})
    Library:Create("UIPadding", {Parent = Items.WatermarkText, PaddingTop = dim(0,5), PaddingBottom = dim(0,6), PaddingRight = dim(0,4), PaddingLeft = dim(0,6)})
    Library:Create("UIPadding", {Parent = Items.WatermarkInline, PaddingBottom = dim(0,1), PaddingRight = dim(0,1)})
    Library:Create("UIPadding", {Parent = Items.Watermark, PaddingBottom = dim(0,1), PaddingRight = dim(0,1)})
    
    Library:Draggify(Items.Holder)
    Library:Resizify(Items.Holder)
    
    function Cfg.ChangeMenuTitle(str) Items.Title.Text = str end
    function Cfg.ChangeWatermarkTitle(str) Items.WatermarkText.Text = str end
    function Cfg.SetWatermarkVisible(bool) Items.Watermark.Visible = bool end
    
    function Cfg.SetVisible(bool)
        if Library.Tweening then return end
        Library:Tween(Library.Blur, {Size = bool and (Flags["BlurSize"] or 15) or 0})
        Cfg.Tween(bool)
    end
    
    function Cfg.Tween(bool)
        if Library.Tweening then return end
        Library.Tweening = true
        if bool then Library.Items.Enabled = true end
        local Children = Library.Items:GetDescendants()
        table.insert(Children, Items.Holder)
        local Tween
        for _, obj in ipairs(Children) do
            local Index = Library:GetTransparency(obj)
            if not Index then continue end
            if type(Index) == "table" then for _, prop in ipairs(Index) do Tween = Library:Fade(obj, prop, bool) end
            else Tween = Library:Fade(obj, Index, bool) end
        end
        if Tween then Library:Connection(Tween.Completed, function() Library.Tweening = false Library.Items.Enabled = bool end)
        else Library.Tweening = false Library.Items.Enabled = bool end
    end
    
    Cfg.SetVisible(true)
    
    Library:Connection(RunService.RenderStepped, function()
        if not Items.Watermark.Visible then return end
        local CurrentTick = tick()
        Cfg.Fps = Cfg.Fps + 1
        Items.WatermarkGradient.Offset = vec2(math.sin(CurrentTick), 0)
        if CurrentTick - Cfg.Tick >= 1 then
            Cfg.Tick = CurrentTick
            local Ping = math.floor(Stats.PerformanceStats.Ping:GetValue())
            Cfg.ChangeWatermarkTitle(string.format('%s <font color="%s">| %s | %sfps | %sms</font>', Cfg.Name, Library:ConvertHex(themes.preset.text_color), os.date("%X"), Cfg.Fps, Ping))
            Cfg.Fps = 0
        end
    end)
    
    return setmetatable(Cfg, Library)
end

--[[ TAB ]]--
function Library:Tab(properties)
    local Cfg = {Name = properties.Name or properties.name or "Tab", Items = {}, Tweening = false}
    local Items = Cfg.Items
    
    Items.TabButton = Library:Create("TextButton", {Parent = self.Items.TabHolder, Size = dim2(0,0,1,0), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.TabInline = Library:Create("Frame", {Parent = Items.TabButton, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.e})
    Items.TabTitle = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.TabInline, TextColor3 = themes.preset.unselected, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, AnchorPoint = vec2(0.5,0.5), Position = dim2(0.5,0,0.5,0), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.TabTitle, LineJoinMode = Enum.LineJoinMode.Miter})
    Library:Create("UIPadding", {Parent = Items.TabTitle, PaddingRight = dim(0,8), PaddingLeft = dim(0,8)})
    Items.AccentLine = Library:Create("Frame", {Parent = Items.TabInline, AnchorPoint = vec2(0,1), Position = dim2(0,0,1,0), Size = dim2(1,0,0,2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent, BackgroundTransparency = 1})
    Library:Themify(Items.AccentLine, "accent", "BackgroundColor3")
    
    Items.Page = Library:Create("Frame", {Parent = Library.Other, Visible = false, BackgroundTransparency = 1, Position = dim2(0,6,0,6), Size = dim2(1,-12,1,-12), ZIndex = 2, BorderSizePixel = 0})
    Library:Create("UIListLayout", {Parent = Items.Page, FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = dim(0,6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalFlex = Enum.UIFlexAlignment.Fill})
    
    function Cfg.OpenTab()
        local Tab = self.TabInfo
        if Tab == Cfg then return end
        if Tab then Tab.Items.TabTitle.TextColor3 = themes.preset.unselected Tab.Items.AccentLine.BackgroundTransparency = 1 Tab.Tween(false) end
        Cfg.Tween(true)
        Items.TabTitle.TextColor3 = themes.preset.text_color
        Items.AccentLine.BackgroundTransparency = 0
        self.TabInfo = Cfg
    end
    
    function Cfg.Tween(bool)
        if Cfg.Tweening then return end
        Cfg.Tweening = true
        if bool then Items.Page.Visible = true Items.Page.Parent = self.Items.ContentBackground end
        local Children = Items.Page:GetDescendants()
        table.insert(Children, Items.Page)
        local Tween
        for _, obj in ipairs(Children) do
            local Index = Library:GetTransparency(obj)
            if not Index then continue end
            if type(Index) == "table" then for _, prop in ipairs(Index) do Tween = Library:Fade(obj, prop, bool, Library.TweeningSpeed) end
            else Tween = Library:Fade(obj, Index, bool, Library.TweeningSpeed) end
        end
        if Tween then Library:Connection(Tween.Completed, function() Cfg.Tweening = false Items.Page.Visible = bool Items.Page.Parent = bool and self.Items.ContentBackground or Library.Other end)
        else Cfg.Tweening = false Items.Page.Visible = bool Items.Page.Parent = bool and self.Items.ContentBackground or Library.Other end
    end
    
    Items.TabButton.MouseButton1Down:Connect(function() if not Cfg.Tweening and not (self.TabInfo and self.TabInfo.Tweening) then Cfg.OpenTab() end end)
    if not self.TabInfo then Cfg.OpenTab() end
    
    return setmetatable(Cfg, Library)
end

--[[ COLUMN & SECTION ]]--
function Library:Column(properties)
    local Cfg = {Items = {}}
    Cfg.Items.Column = Library:Create("Frame", {Parent = self.Items.Page, BackgroundTransparency = 1, Size = dim2(0,100,0,100), BorderSizePixel = 0})
    Library:Create("UIListLayout", {Parent = Cfg.Items.Column, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = dim(0,8)})
    return setmetatable(Cfg, Library)
end

function Library:Section(properties)
    local Cfg = {Name = properties.Name or properties.name or "Section", Items = {}}
    local Items = Cfg.Items
    
    Items.Outline = Library:Create("Frame", {Parent = self.Items.Column, Size = dim2(0,100,0,0), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = themes.preset.inline})
    Library:Themify(Items.Outline, "inline", "BackgroundColor3")
    Library:Create("UIPadding", {Parent = Items.Outline, PaddingBottom = dim(0,2)})
    Items.TitleHolder = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,10,0,0), Size = dim2(0,0,0,10), BorderSizePixel = 0, ZIndex = 2, AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = themes.preset.background})
    Library:Create("UIPadding", {Parent = Items.TitleHolder, PaddingRight = dim(0,2), PaddingLeft = dim(0,3)})
    Items.Title = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.TitleHolder, TextColor3 = themes.preset.text_color, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, AnchorPoint = vec2(0,1), Position = dim2(0,0,0,9), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 2, TextSize = 12})
    Items.Inline = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = themes.preset.outline})
    Library:Create("UIPadding", {Parent = Items.Inline, PaddingBottom = dim(0,2)})
    Items.Background = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = themes.preset.background})
    Items.Accent = Library:Create("Frame", {Parent = Items.Background, Size = dim2(1,0,0,1), BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent})
    Library:Themify(Items.Accent, "accent", "BackgroundColor3")
    Items.Elements = Library:Create("Frame", {Parent = Items.Background, BackgroundTransparency = 1, Position = dim2(0,12,0,15), Size = dim2(1,-24,0,0), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y})
    Library:Create("UIPadding", {Parent = Items.Elements, PaddingBottom = dim(0,5)})
    Library:Create("UIListLayout", {Parent = Items.Elements, Padding = dim(0,7), SortOrder = Enum.SortOrder.LayoutOrder})
    
    return setmetatable(Cfg, Library)
end

--[[ UI ELEMENTS ]]--

-- Label
function Library:Label(properties)
    local Cfg = {Name = properties.Name or "Label", Items = {}}
    local Items = Cfg.Items
    Items.Label = Library:Create("Frame", {Parent = self.Items.Elements, BackgroundTransparency = 1, Size = dim2(1,0,0,12), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y})
    Items.Components = Library:Create("Frame", {Parent = Items.Label, Position = dim2(1,0,0,0), Size = dim2(0,0,0,12), BorderSizePixel = 0, BackgroundTransparency = 1})
    Library:Create("UIListLayout", {Parent = Items.Components, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = dim(0,5), SortOrder = Enum.SortOrder.LayoutOrder})
    Items.Text = Library:Create("TextLabel", {Parent = Items.Label, RichText = true, TextColor3 = themes.preset.unselected, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Size = dim2(1,0,0,0), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, FontFace = Fonts[themes.preset.font], ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Text, LineJoinMode = Enum.LineJoinMode.Miter})
    function Cfg.Set(text) Items.Text.Text = text end
    return setmetatable(Cfg, Library)
end

-- Toggle
function Library:Toggle(properties)
    local Cfg = {Name = properties.Name or "Toggle", Flag = properties.Flag or properties.Name or "Toggle", Enabled = properties.Default or false, Callback = properties.Callback or function() end, Items = {}}
    local Items = Cfg.Items
    
    Items.Toggle = Library:Create("TextButton", {Parent = self.Items.Elements, BackgroundTransparency = 1, Size = dim2(1,0,0,12), BorderSizePixel = 0})
    Items.Components = Library:Create("Frame", {Parent = Items.Toggle, Position = dim2(1,0,0,0), Size = dim2(0,0,1,0), BorderSizePixel = 0, BackgroundTransparency = 1})
    Library:Create("UIListLayout", {Parent = Items.Components, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = dim(0,5), SortOrder = Enum.SortOrder.LayoutOrder})
    Items.Outline = Library:Create("Frame", {Parent = Items.Toggle, Size = dim2(0,12,0,12), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Title = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Outline, TextColor3 = themes.preset.unselected, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Position = dim2(0,17,0,-1), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, TextSize = 12, RichText = true})
    Library:Create("UIStroke", {Parent = Items.Title, LineJoinMode = Enum.LineJoinMode.Miter})
    Items.Inline = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, ZIndex = 2, BackgroundColor3 = themes.preset.inline})
    Items.AccentBorder = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, ZIndex = 1, BackgroundColor3 = themes.preset.accent, BackgroundTransparency = 1})
    Library:Themify(Items.AccentBorder, "accent", "BackgroundColor3")
    Items.InnerOutline = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Background = Library:Create("Frame", {Parent = Items.InnerOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.misc_1})
    Items.AccentFill = Library:Create("Frame", {Parent = Items.InnerOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, ZIndex = 1, BackgroundColor3 = themes.preset.accent, BackgroundTransparency = 1})
    Library:Themify(Items.AccentFill, "accent", "BackgroundColor3")
    
    function Cfg.Set(bool)
        Cfg.Enabled = bool
        Library:Tween(Items.AccentBorder, {BackgroundTransparency = bool and 0 or 1})
        Library:Tween(Items.Inline, {BackgroundTransparency = bool and 1 or 0})
        Library:Tween(Items.AccentFill, {BackgroundTransparency = bool and 0 or 1})
        Library:Tween(Items.Title, {TextColor3 = bool and themes.preset.text_color or themes.preset.unselected})
        Flags[Cfg.Flag] = bool
        Cfg.Callback(bool)
    end
    
    Items.Toggle.MouseButton1Click:Connect(function() Cfg.Set(not Cfg.Enabled) end)
    Cfg.Set(Cfg.Enabled)
    ConfigFlags[Cfg.Flag] = Cfg.Set
    
    return setmetatable(Cfg, Library)
end

-- Slider
function Library:Slider(properties)
    local Cfg = {Name = properties.Name, Suffix = properties.Suffix or "", Flag = properties.Flag or properties.Name or "Slider", Callback = properties.Callback or function() end, Min = properties.Min or 0, Max = properties.Max or 100, Intervals = properties.Decimal or properties.Intervals or 1, Value = properties.Default or 10, Dragging = false, Items = {}}
    local Items = Cfg.Items
    
    Items.Slider = Library:Create("Frame", {Parent = self.Items.Elements, BackgroundTransparency = 1, Size = dim2(1,0,0,Cfg.Name and 27 or 10), BorderSizePixel = 0})
    if Cfg.Name then
        Items.Text = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Slider, TextColor3 = themes.preset.unselected, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Position = dim2(0,1,0,0), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, TextSize = 12})
        Library:Create("UIStroke", {Parent = Items.Text, LineJoinMode = Enum.LineJoinMode.Miter})
    end
    Items.Outline = Library:Create("TextButton", {Parent = Items.Slider, Position = dim2(0,4,0,Cfg.Name and 17 or 0), Size = dim2(1,-8,0,10), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Inline = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.InnerOutline = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Background = Library:Create("Frame", {Parent = Items.InnerOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.misc_1, ClipsDescendants = true})
    Library:Create("UIGradient", {Parent = Items.Background, Rotation = 90, Color = rgbseq{rgbkey(0, themes.preset.e), rgbkey(1, themes.preset.f)}})
    Items.Fill = Library:Create("Frame", {Parent = Items.Background, Size = dim2(0.5,0,1,0), BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent})
    Library:Themify(Items.Fill, "accent", "BackgroundColor3")
    Library:Create("UIGradient", {Parent = Items.Fill, Rotation = 90, Color = rgbseq{rgbkey(0, rgb(255,255,255)), rgbkey(1, rgb(42,42,42))}})
    Items.Value = Library:Create("TextBox", {FontFace = Fonts[themes.preset.font], Parent = Items.Fill, TextColor3 = themes.preset.text_color, Text = "0", AutomaticSize = Enum.AutomaticSize.XY, AnchorPoint = vec2(0.5,0.5), Position = dim2(1,0,0.5,1), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Value, LineJoinMode = Enum.LineJoinMode.Miter})
    Items.Minus = Library:Create("TextButton", {FontFace = Fonts[themes.preset.font], Parent = Items.Outline, AnchorPoint = vec2(1,0.5), Position = dim2(0,-5,0.5,0), TextColor3 = themes.preset.unselected, Text = "-", AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, ZIndex = 100, TextSize = 12})
    Items.Plus = Library:Create("TextButton", {FontFace = Fonts[themes.preset.font], Parent = Items.Outline, AnchorPoint = vec2(0,0.5), Position = dim2(1,5,0.5,0), TextColor3 = themes.preset.unselected, Text = "+", AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, ZIndex = 100, TextSize = 12})
    
    function Cfg.Set(value)
        Cfg.Value = math.clamp(Library:Round(value, Cfg.Intervals), Cfg.Min, Cfg.Max)
        Items.Value.Text = tostring(Cfg.Value) .. Cfg.Suffix
        Library:Tween(Items.Fill, {Size = dim2((Cfg.Value - Cfg.Min) / (Cfg.Max - Cfg.Min), 0, 1, 0)}, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear))
        Flags[Cfg.Flag] = Cfg.Value
        Cfg.Callback(Cfg.Value)
    end
    
    Items.Outline.MouseButton1Down:Connect(function() Cfg.Dragging = true end)
    Items.Minus.MouseButton1Click:Connect(function() Cfg.Set(Cfg.Value - Cfg.Intervals) end)
    Items.Plus.MouseButton1Click:Connect(function() Cfg.Set(Cfg.Value + Cfg.Intervals) end)
    Items.Value.FocusLost:Connect(function() local num = tonumber(Items.Value.Text:gsub(Cfg.Suffix, "")) if num then Cfg.Set(num) else Items.Value.Text = tostring(Cfg.Value) .. Cfg.Suffix end end)
    Library:Connection(UserInputService.InputChanged, function(input) if Cfg.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local Size = (input.Position.X - Items.Outline.AbsolutePosition.X) / Items.Outline.AbsoluteSize.X Cfg.Set(((Cfg.Max - Cfg.Min) * Size) + Cfg.Min) end end)
    Library:Connection(UserInputService.InputEnded, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Cfg.Dragging = false end end)
    
    Cfg.Set(Cfg.Value)
    ConfigFlags[Cfg.Flag] = Cfg.Set
    
    return setmetatable(Cfg, Library)
end

-- Button
function Library:Button(properties)
    local Cfg = {Name = properties.Name or "Button", Callback = properties.Callback or function() end, Items = {}}
    local Items = Cfg.Items
    
    Items.Button = Library:Create("TextButton", {Parent = self.Items.Elements, BackgroundTransparency = 1, Size = dim2(1,0,0,18), BorderSizePixel = 0})
    Items.Outline = Library:Create("Frame", {Parent = Items.Button, Size = dim2(1,0,0,18), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Inline = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.InnerOutline = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Background = Library:Create("Frame", {Parent = Items.InnerOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, ClipsDescendants = true})
    Library:Create("UIGradient", {Parent = Items.Background, Rotation = 90, Color = rgbseq{rgbkey(0, themes.preset.e), rgbkey(1, themes.preset.f)}})
    Items.Text = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Background, TextColor3 = themes.preset.unselected, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Size = dim2(1,0,1,0), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Text, LineJoinMode = Enum.LineJoinMode.Miter})
    
    Items.Button.MouseButton1Click:Connect(function() Cfg.Callback() end)
    
    return setmetatable(Cfg, Library)
end

-- Textbox
function Library:Textbox(properties)
    local Cfg = {Name = properties.Name, PlaceHolder = properties.PlaceHolder or "Type here...", ClearTextOnFocus = properties.ClearTextOnFocus or false, Default = properties.Default or "", Flag = properties.Flag or properties.Name or "Textbox", Callback = properties.Callback or function() end, Items = {}, Focused = false}
    Flags[Cfg.Flag] = Cfg.Default
    local Items = Cfg.Items
    
    Items.Textbox = Library:Create("TextButton", {Parent = self.Items.Elements, BackgroundTransparency = 1, Size = dim2(1,0,0,Cfg.Name and 35 or 18), BorderSizePixel = 0})
    if Cfg.Name then
        Items.Text = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Textbox, TextColor3 = themes.preset.unselected, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Position = dim2(0,1,0,0), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, TextSize = 12})
        Library:Create("UIStroke", {Parent = Items.Text, LineJoinMode = Enum.LineJoinMode.Miter})
    end
    Items.Outline = Library:Create("Frame", {Parent = Items.Textbox, Position = dim2(0,0,0,Cfg.Name and 17 or 0), Size = dim2(1,0,0,18), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Inline = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.InnerOutline = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Background = Library:Create("Frame", {Parent = Items.InnerOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, ClipsDescendants = true})
    Library:Create("UIGradient", {Parent = Items.Background, Rotation = 90, Color = rgbseq{rgbkey(0, themes.preset.e), rgbkey(1, themes.preset.f)}})
    Items.Input = Library:Create("TextBox", {Parent = Items.Background, FontFace = Fonts[themes.preset.font], TextColor3 = themes.preset.unselected, PlaceholderText = Cfg.PlaceHolder, Text = Cfg.Default, Size = dim2(1,0,1,0), Position = dim2(0,2,0,0), BorderSizePixel = 0, BackgroundTransparency = 1, ClearTextOnFocus = Cfg.ClearTextOnFocus, ZIndex = 44, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
    
    function Cfg.Set(text) Flags[Cfg.Flag] = text Items.Input.Text = text Cfg.Callback(text) end
    Items.Input:GetPropertyChangedSignal("Text"):Connect(function() if Cfg.Focused then Cfg.Set(Items.Input.Text) end end)
    Items.Input.Focused:Connect(function() Cfg.Focused = true end)
    Items.Input.FocusLost:Connect(function() Cfg.Focused = false end)
    if Cfg.Default ~= "" then Cfg.Set(Cfg.Default) end
    ConfigFlags[Cfg.Flag] = Cfg.Set
    
    return setmetatable(Cfg, Library)
end

-- Dropdown
function Library:Dropdown(properties)
    local Cfg = {Name = properties.Name, Flag = properties.Flag or properties.Name or "Dropdown", Options = properties.Options or {""}, Callback = properties.Callback or function() end, Multi = properties.Multi or false, Default = properties.Default, Open = false, OptionInstances = {}, MultiItems = {}, Items = {}, Tweening = false}
    Flags[Cfg.Flag] = Cfg.Default
    local Items = Cfg.Items
    
    Items.Dropdown = Library:Create("TextButton", {Parent = self.Items.Elements, BackgroundTransparency = 1, Size = dim2(1,0,0,Cfg.Name and 35 or 17), BorderSizePixel = 0})
    if Cfg.Name then
        Items.Text = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Dropdown, TextColor3 = themes.preset.unselected, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Position = dim2(0,1,0,0), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, TextSize = 12})
        Library:Create("UIStroke", {Parent = Items.Text, LineJoinMode = Enum.LineJoinMode.Miter})
    end
    Items.Outline = Library:Create("TextButton", {Parent = Items.Dropdown, Position = dim2(0,0,0,Cfg.Name and 18 or 0), Size = dim2(1,0,0,17), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Inline = Library:Create("Frame", {Parent = Items.Outline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.InnerOutline = Library:Create("Frame", {Parent = Items.Inline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.Background = Library:Create("Frame", {Parent = Items.InnerOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, ClipsDescendants = true})
    Library:Create("UIGradient", {Parent = Items.Background, Rotation = 90, Color = rgbseq{rgbkey(0, themes.preset.e), rgbkey(1, themes.preset.f)}})
    Items.Value = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Background, TextColor3 = themes.preset.unselected, Text = "...", AutomaticSize = Enum.AutomaticSize.XY, Position = dim2(0,2,0,-1), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 2, TextSize = 12})
    Items.Plus = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Background, TextColor3 = themes.preset.unselected, Text = "+", AutomaticSize = Enum.AutomaticSize.XY, AnchorPoint = vec2(1,0), Position = dim2(1,-2,0,-1), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 444, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Plus, LineJoinMode = Enum.LineJoinMode.Miter})
    
    Items.DropdownElements = Library:Create("Frame", {Parent = Library.Other, Visible = false, Size = dim2(0,213,0,18), Position = dim2(0,300,0,300), BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = themes.preset.outline})
    Items.DropInline = Library:Create("Frame", {Parent = Items.DropdownElements, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.DropInnerOutline = Library:Create("Frame", {Parent = Items.DropInline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.DropBackground = Library:Create("Frame", {Parent = Items.DropInnerOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, ClipsDescendants = true})
    Library:Create("UIGradient", {Parent = Items.DropBackground, Rotation = 90, Color = rgbseq{rgbkey(0, themes.preset.e), rgbkey(1, themes.preset.f)}})
    Library:Create("UIListLayout", {Parent = Items.DropBackground, SortOrder = Enum.SortOrder.LayoutOrder})
    Library:Create("UIPadding", {Parent = Items.DropBackground, PaddingBottom = dim(0,3)})
    
    function Cfg.RenderOption(text)
        local Button = Library:Create("TextButton", {FontFace = Fonts[themes.preset.font], TextColor3 = themes.preset.unselected, Text = text, Size = dim2(1,0,0,0), Parent = Items.DropBackground, AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, BackgroundTransparency = 1, Position = dim2(0,2,0,0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, TextSize = 12})
        Library:Create("UIPadding", {Parent = Button, PaddingTop = dim(0,3), PaddingBottom = dim(0,3), PaddingRight = dim(0,3), PaddingLeft = dim(0,3)})
        table.insert(Cfg.OptionInstances, Button)
        return Button
    end
    
    function Cfg.SetVisible(bool)
        if Cfg.Tweening then return end
        if Library.OpenElement ~= Cfg then Library:CloseElement() end
        Items.DropdownElements.Position = dim2(0, Items.Outline.AbsolutePosition.X, 0, Items.Outline.AbsolutePosition.Y + 80)
        Items.DropdownElements.Size = dim_offset(Items.Outline.AbsoluteSize.X + 1, 0)
        if not Cfg.Multi then Items.Plus.Text = bool and "-" or "+" end
        Cfg.Tween(bool)
        Library.OpenElement = {Cfg}
    end
    
    function Cfg.Set(value)
        local Selected = {}
        local IsTable = type(value) == "table"
        for _, option in ipairs(Cfg.OptionInstances) do
            if option.Text == value or (IsTable and table.find(value, option.Text)) then
                table.insert(Selected, option.Text)
                Cfg.MultiItems = Selected
                option.TextColor3 = themes.preset.text_color
            else option.TextColor3 = themes.preset.unselected end
        end
        Items.Value.Text = IsTable and table.concat(Selected, ", ") or (Selected[1] or "")
        Flags[Cfg.Flag] = IsTable and Selected or Selected[1]
        Cfg.Callback(Flags[Cfg.Flag])
    end
    
    function Cfg.RefreshOptions(options)
        for _, option in ipairs(Cfg.OptionInstances) do option:Destroy() end
        Cfg.OptionInstances = {}
        for _, option in ipairs(options) do
            local Button = Cfg.RenderOption(option)
            Button.MouseButton1Down:Connect(function()
                if Cfg.Multi then
                    local Selected = table.find(Cfg.MultiItems, Button.Text)
                    if Selected then table.remove(Cfg.MultiItems, Selected) else table.insert(Cfg.MultiItems, Button.Text) end
                    Cfg.Set(Cfg.MultiItems)
                else Cfg.SetVisible(false) Cfg.Open = false Cfg.Set(Button.Text) end
            end)
        end
    end
    
    function Cfg.Tween(bool)
        if Cfg.Tweening then return end
        Cfg.Tweening = true
        if bool then Items.DropdownElements.Parent = Library.Items Items.DropdownElements.Visible = true end
        local Children = Items.DropdownElements:GetDescendants()
        table.insert(Children, Items.DropdownElements)
        local Tween
        for _, obj in ipairs(Children) do
            local Index = Library:GetTransparency(obj)
            if not Index then continue end
            if type(Index) == "table" then for _, prop in ipairs(Index) do Tween = Library:Fade(obj, prop, bool, Library.TweeningSpeed) end
            else Tween = Library:Fade(obj, Index, bool, Library.TweeningSpeed) end
        end
        if Tween then Library:Connection(Tween.Completed, function() Cfg.Tweening = false Items.DropdownElements.Parent = bool and Library.Items or Library.Other Items.DropdownElements.Visible = bool end)
        else Cfg.Tweening = false Items.DropdownElements.Parent = bool and Library.Items or Library.Other Items.DropdownElements.Visible = bool end
    end
    
    Items.Outline.MouseButton1Click:Connect(function() Cfg.Open = not Cfg.Open Cfg.SetVisible(Cfg.Open) end)
    Library:Connection(UserInputService.InputBegan, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:Hovering({Items.DropdownElements, Items.Dropdown}) then Cfg.SetVisible(false) Cfg.Open = false end end)
    
    Cfg.SetVisible(false)
    Cfg.RefreshOptions(Cfg.Options)
    if Cfg.Default then Cfg.Set(Cfg.Default) end
    ConfigFlags[Cfg.Flag] = Cfg.Set
    
    return setmetatable(Cfg, Library)
end

-- Keybind
function Library:Keybind(properties)
    local Cfg = {Name = properties.Name or "Keybind", Flag = properties.Flag or properties.Name or "Keybind", Callback = properties.Callback or function() end, Key = properties.Key, Mode = properties.Mode or "Toggle", Active = properties.Default or false, Show = properties.ShowInList ~= false, Open = false, Binding = nil, Items = {}, Tweening = false}
    Flags[Cfg.Flag] = {Mode = Cfg.Mode, Key = Cfg.Key, Active = Cfg.Active}
    local KeybindElement = Library.KeybindList:ListElement({})
    local Items = Cfg.Items
    
    Items.Keybind = Library:Create("TextButton", {Parent = self.Items.Components, FontFace = Fonts[themes.preset.font], TextColor3 = themes.preset.unselected, Text = "[NONE]", AutomaticSize = Enum.AutomaticSize.XY, Size = dim2(0,0,1,0), BorderSizePixel = 0, BackgroundTransparency = 1, RichText = true, ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Keybind, LineJoinMode = Enum.LineJoinMode.Miter})
    
    function Cfg.SetMode(mode)
        Cfg.Mode = mode
        if mode == "Always" then Cfg.Set(true) elseif mode == "Hold" then Cfg.Set(false) end
        Flags[Cfg.Flag].Mode = mode
    end
    
    function Cfg.Set(input)
        if type(input) == "boolean" then
            Cfg.Active = input
            if Cfg.Mode == "Always" then Cfg.Active = true end
        elseif tostring(input):find("Enum") then
            input = input.Name == "Escape" and "NONE" or input
            Cfg.Key = input or "NONE"
        elseif table.find({"Toggle", "Hold", "Always"}, input) then
            if input == "Always" then Cfg.Active = true end
            Cfg.Mode = input
            Cfg.SetMode(Cfg.Mode)
        elseif type(input) == "table" then
            if input.Key then
                input.Key = type(input.Key) == "string" and input.Key ~= "NONE" and Enum.KeyCode[input.Key] or input.Key
                input.Key = input.Key == Enum.KeyCode.Escape and "NONE" or input.Key
            end
            Cfg.Key = input.Key or "NONE"
            Cfg.Mode = input.Mode or "Toggle"
            if input.Active ~= nil then Cfg.Active = input.Active end
            Cfg.SetMode(Cfg.Mode)
        end
        
        Cfg.Callback(Cfg.Active)
        
        local text = (tostring(Cfg.Key) ~= "Enums" and (Keys[Cfg.Key] or tostring(Cfg.Key):gsub("Enum.", "")) or nil)
        local __text = text and tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", "") or ""
        
        Items.Keybind.Text = string.format("[%s]", __text)
        
        Flags[Cfg.Flag] = {Mode = Cfg.Mode, Key = Cfg.Key, Active = Cfg.Active}
        
        KeybindElement.SetText(string.format("%s [%s] - %s", Cfg.Name, __text, Cfg.Mode))
        KeybindElement.SetVisible(Cfg.Show and Cfg.Active)
    end
    
    Items.Keybind.MouseButton1Down:Connect(function()
        task.wait()
        Items.Keybind.Text = "..."
        
        Cfg.Binding = Library:Connection(UserInputService.InputBegan, function(keycode)
            Cfg.Set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)
            
            if Cfg.Binding then
                Cfg.Binding:Disconnect()
                Cfg.Binding = nil
            end
        end)
    end)
    
    Library:Connection(UserInputService.InputBegan, function(input, gameProcessed)
        if not gameProcessed then
            local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
            
            if selected_key == Cfg.Key or tostring(selected_key) == Cfg.Key then
                if Cfg.Mode == "Toggle" then
                    Cfg.Active = not Cfg.Active
                    Cfg.Set(Cfg.Active)
                elseif Cfg.Mode == "Hold" then
                    Cfg.Set(true)
                end
            end
        end
    end)
    
    Library:Connection(UserInputService.InputEnded, function(input, gameProcessed)
        if gameProcessed then return end
        
        local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
        
        if selected_key == Cfg.Key then
            if Cfg.Mode == "Hold" then
                Cfg.Set(false)
            end
        end
    end)
    
    Cfg.Set({Mode = Cfg.Mode, Active = Cfg.Active, Key = Cfg.Key})
    ConfigFlags[Cfg.Flag] = Cfg.Set
    
    return setmetatable(Cfg, Library)
end

-- Colorpicker
function Library:Colorpicker(properties)
    local Cfg = {Name = properties.Name or "Color", Flag = properties.Flag or properties.Name or "Colorpicker", Callback = properties.Callback or function() end, Color = properties.Color or color(1, 1, 1), Alpha = properties.Alpha or properties.Transparency or 1, Open = false, Items = {}, Tweening = false}
    
    local DraggingSat = false
    local DraggingHue = false
    local DraggingAlpha = false
    
    local h, s, v = Cfg.Color:ToHSV()
    local a = Cfg.Alpha
    
    Flags[Cfg.Flag] = {Color = Cfg.Color, Transparency = Cfg.Alpha}
    
    local Items = Cfg.Items
    
    -- Color preview button
    Items.ColorpickerObject = Library:Create("TextButton", {Parent = self.Items.Components, Size = dim2(0, 20, 0, 12), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.PreviewInline = Library:Create("Frame", {Parent = Items.ColorpickerObject, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.PreviewOutline = Library:Create("Frame", {Parent = Items.PreviewInline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.MainColor = Library:Create("Frame", {Parent = Items.PreviewOutline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = Cfg.Color})
    Items.TransparencyHandler = Library:Create("ImageLabel", {Parent = Items.MainColor, Image = "rbxassetid://18274452449", ZIndex = 3, BackgroundTransparency = 1, ImageTransparency = 1 - a, Size = dim2(1,0,1,0), BorderSizePixel = 0, ScaleType = Enum.ScaleType.Tile, TileSize = dim2(0,4,0,4)})
    
    -- Colorpicker window
    Items.Colorpicker = Library:Create("Frame", {Parent = Library.Other, ZIndex = 999, Size = dim2(0, 179, 0, 200), Visible = false, BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Library:Resizify(Items.Colorpicker)
    
    Items.PickerInline = Library:Create("Frame", {Parent = Items.Colorpicker, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.PickerBackground = Library:Create("Frame", {Parent = Items.PickerInline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.background})
    Items.PickerTitle = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.PickerBackground, TextColor3 = themes.preset.text_color, Text = Cfg.Name, AutomaticSize = Enum.AutomaticSize.XY, Size = dim2(0,0,0,16), Position = dim2(0,3,0,0), BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.PickerTitle, LineJoinMode = Enum.LineJoinMode.Miter})
    
    -- Saturation/Value picker
    Items.SatValHolder = Library:Create("TextButton", {Parent = Items.PickerBackground, Position = dim2(0,3,0,16), Size = dim2(1,-21,1,-50), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.SatValInline = Library:Create("Frame", {Parent = Items.SatValHolder, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.SatValBackground = Library:Create("Frame", {Parent = Items.SatValInline, Position = dim2(0,1,0,1), Size = dim2(1,-3,1,-2), BorderSizePixel = 0, BackgroundColor3 = hsv(h, 1, 1)})
    Items.SatValPicker = Library:Create("Frame", {Parent = Items.SatValBackground, Size = dim2(0,2,0,2), ZIndex = 3, BorderSizePixel = 0, BackgroundColor3 = rgb(255,255,255)})
    Library:Create("UIStroke", {Parent = Items.SatValPicker, LineJoinMode = Enum.LineJoinMode.Miter})
    Items.Saturation = Library:Create("Frame", {Parent = Items.SatValBackground, Size = dim2(1,1,1,0), ZIndex = 2, BorderSizePixel = 0, BackgroundColor3 = rgb(255,255,255)})
    Library:Create("UIGradient", {Parent = Items.Saturation, Rotation = 270, Transparency = numseq{numkey(0,0), numkey(1,1)}, Color = rgbseq{rgbkey(0, rgb(0,0,0)), rgbkey(1, rgb(0,0,0))}})
    Items.Value = Library:Create("Frame", {Parent = Items.SatValBackground, Rotation = 180, Size = dim2(1,0,1,0), BorderSizePixel = 0, BackgroundColor3 = rgb(255,255,255)})
    Library:Create("UIGradient", {Parent = Items.Value, Transparency = numseq{numkey(0,0), numkey(1,1)}})
    
    -- Hue slider
    Items.Hue = Library:Create("TextButton", {Parent = Items.PickerBackground, Position = dim2(0,3,1,-30), Size = dim2(1,-6,0,14), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.HueInline = Library:Create("Frame", {Parent = Items.Hue, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.HueBackground = Library:Create("Frame", {Parent = Items.HueInline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = rgb(255,255,255)})
    Library:Create("UIGradient", {Parent = Items.HueBackground, Color = rgbseq{rgbkey(0, rgb(255,0,0)), rgbkey(0.17, rgb(255,255,0)), rgbkey(0.33, rgb(0,255,0)), rgbkey(0.5, rgb(0,255,255)), rgbkey(0.67, rgb(0,0,255)), rgbkey(0.83, rgb(255,0,255)), rgbkey(1, rgb(255,0,0))}})
    Items.HuePicker = Library:Create("Frame", {Parent = Items.HueBackground, AnchorPoint = vec2(0.5,0), Position = dim2(h,0,0,1), Size = dim2(0,2,1,-2), BorderSizePixel = 0, BackgroundColor3 = rgb(255,255,255), BackgroundTransparency = 0.25})
    Library:Create("UIStroke", {Parent = Items.HuePicker, LineJoinMode = Enum.LineJoinMode.Miter})
    
    -- Alpha slider
    Items.AlphaSlider = Library:Create("TextButton", {Parent = Items.PickerBackground, AnchorPoint = vec2(1,0), Position = dim2(1,-3,0,16), Size = dim2(0,14,1,-50), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    Items.AlphaInline = Library:Create("Frame", {Parent = Items.AlphaSlider, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.outline})
    Items.AlphaBackground = Library:Create("Frame", {Parent = Items.AlphaInline, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = rgb(255,255,255)})
    Items.AlphaIndicator = Library:Create("ImageLabel", {Parent = Items.AlphaBackground, ScaleType = Enum.ScaleType.Tile, Image = "rbxassetid://18274452449", BackgroundTransparency = 1, Size = dim2(1,0,1,0), TileSize = dim2(0,8,0,8), BorderSizePixel = 0})
    Items.AlphaFading = Library:Create("Frame", {Parent = Items.AlphaBackground, Size = dim2(1,0,1,0), BorderSizePixel = 0, BackgroundColor3 = hsv(h, 1, 1)})
    Library:Create("UIGradient", {Parent = Items.AlphaFading, Rotation = 90, Transparency = numseq{numkey(0,1), numkey(1,0)}})
    Items.AlphaPicker = Library:Create("Frame", {Parent = Items.AlphaFading, AnchorPoint = vec2(0,0.5), Position = dim2(0,1,1-a,0), Size = dim2(1,-2,0,2), BorderSizePixel = 0, BackgroundColor3 = rgb(255,255,255), BackgroundTransparency = 0.25})
    Library:Create("UIStroke", {Parent = Items.AlphaPicker, LineJoinMode = Enum.LineJoinMode.Miter})
    
    function Cfg.SetVisible(bool)
        if Cfg.Tweening then return end
        Items.Colorpicker.Position = dim2(0, Items.ColorpickerObject.AbsolutePosition.X + 2, 0, Items.ColorpickerObject.AbsolutePosition.Y + 74)
        Cfg.Tween(bool)
        Cfg.Set(hsv(h, s, v), a)
    end
    
    function Cfg.Tween(bool)
        if Cfg.Tweening then return end
        Cfg.Tweening = true
        if bool then Items.Colorpicker.Visible = true Items.Colorpicker.Parent = Library.Items end
        local Children = Items.Colorpicker:GetDescendants()
        table.insert(Children, Items.Colorpicker)
        local Tween
        for _, obj in ipairs(Children) do
            local Index = Library:GetTransparency(obj)
            if not Index then continue end
            if type(Index) == "table" then for _, prop in ipairs(Index) do Tween = Library:Fade(obj, prop, bool, Library.TweeningSpeed) end
            else Tween = Library:Fade(obj, Index, bool, Library.TweeningSpeed) end
        end
        if Tween then Library:Connection(Tween.Completed, function() Cfg.Tweening = false Items.Colorpicker.Visible = bool end)
        else Cfg.Tweening = false Items.Colorpicker.Visible = bool end
    end
    
    function Cfg.UpdateColor()
        local MousePos = UserInputService:GetMouseLocation()
        local offset = vec2(MousePos.X, MousePos.Y - GuiOffset)
        
        if DraggingSat then
            s = 1 - math.clamp((offset.X - Items.SatValHolder.AbsolutePosition.X) / Items.SatValHolder.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp((offset.Y - Items.SatValHolder.AbsolutePosition.Y) / Items.SatValHolder.AbsoluteSize.Y, 0, 1)
        elseif DraggingHue then
            h = math.clamp((offset.X - Items.Hue.AbsolutePosition.X) / Items.Hue.AbsoluteSize.X, 0, 1)
        elseif DraggingAlpha then
            a = 1 - math.clamp((offset.Y - Items.AlphaSlider.AbsolutePosition.Y) / Items.AlphaSlider.AbsoluteSize.Y, 0, 1)
        end
        
        Cfg.Set()
    end
    
    function Cfg.Set(newColor, alpha)
        if type(newColor) == "boolean" then return end
        
        if newColor then h, s, v = newColor:ToHSV() end
        if alpha then a = alpha end
        
        Items.MainColor.BackgroundColor3 = hsv(h, s, v)
        Items.TransparencyHandler.ImageTransparency = a
        
        if Items.Colorpicker.Visible then
            Library:Tween(Items.SatValPicker, {Position = dim2(1 - s, 0, 1 - v, 0)}, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear))
            Library:Tween(Items.AlphaPicker, {Position = dim2(0, 1, 1 - a, 0)}, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear))
            Library:Tween(Items.HuePicker, {Position = dim2(h, 0, 0, 1)}, TweenInfo.new(Library.DraggingSpeed, Enum.EasingStyle.Linear))
            Items.SatValBackground.BackgroundColor3 = hsv(h, 1, 1)
            Items.AlphaFading.BackgroundColor3 = hsv(h, 1, 1)
        end
        
        local Color = hsv(h, s, v)
        Flags[Cfg.Flag] = {Color = Color, Transparency = a}
        Cfg.Callback(Color, a)
    end
    
    Items.ColorpickerObject.MouseButton1Click:Connect(function() Cfg.Open = not Cfg.Open Cfg.SetVisible(Cfg.Open) end)
    UserInputService.InputChanged:Connect(function(input) if (DraggingSat or DraggingHue or DraggingAlpha) and input.UserInputType == Enum.UserInputType.MouseMovement then Cfg.UpdateColor() end end)
    Library:Connection(UserInputService.InputBegan, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:Hovering({Items.Colorpicker}) and Items.Colorpicker.Visible then Cfg.SetVisible(false) Cfg.Open = false end end)
    Library:Connection(UserInputService.InputEnded, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSat = false DraggingHue = false DraggingAlpha = false end end)
    Items.AlphaSlider.MouseButton1Down:Connect(function() DraggingAlpha = true end)
    Items.Hue.MouseButton1Down:Connect(function() DraggingHue = true end)
    Items.SatValHolder.MouseButton1Down:Connect(function() DraggingSat = true end)
    
    Cfg.Set(Cfg.Color, Cfg.Alpha)
    Cfg.SetVisible(false)
    ConfigFlags[Cfg.Flag] = Cfg.Set
    
    return setmetatable(Cfg, Library)
end

--[[ NOTIFICATION SYSTEM ]]--
function Library:FadeNotification(path, is_fading)
    local fading = is_fading and 1 or 0
    for _, instance in ipairs(path:GetDescendants()) do
        if not instance:IsA("GuiObject") then
            if instance:IsA("UIStroke") then Library:Tween(instance, {Transparency = fading}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)) end
            continue
        end
        if instance:IsA("TextLabel") then Library:Tween(instance, {TextTransparency = fading}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut))
        elseif instance:IsA("Frame") then Library:Tween(instance, {BackgroundTransparency = is_fading and 1 or 0}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)) end
    end
end

function Library:ReorderNotifications()
    local Offset = 50
    for _, notif in pairs(Notifications.Notifs) do
        if notif then
            notif.Position = dim_offset(20, Offset)
            Offset = Offset + (notif.AbsoluteSize.Y + 5)
        end
    end
    return Offset
end

function Library:Notification(properties)
    local Cfg = {Name = properties.Name or "Notification", Lifetime = properties.Lifetime or nil, Items = {}}
    local Index = #Notifications.Notifs + 1
    local Items = Cfg.Items
    
    Items.Holder = Library:Create("Frame", {Parent = Library.Elements, BackgroundTransparency = 1, Position = dim2(0,18,0,70), AnchorPoint = vec2(1,0), AutomaticSize = Enum.AutomaticSize.XY, Size = dim2(0,0,0,21), BorderSizePixel = 0})
    Items.Notification = Library:Create("Frame", {Parent = Items.Holder, BackgroundTransparency = 1, Size = dim2(0,0,0,25), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = themes.preset.outline})
    Items.Accent = Library:Create("Frame", {Parent = Items.Notification, Position = dim2(0,2,0,2), Size = dim2(0,1,1,-4), BackgroundTransparency = 1, ZIndex = 3, BorderSizePixel = 0, BackgroundColor3 = themes.preset.accent})
    Library:Themify(Items.Accent, "accent", "BackgroundColor3")
    Items.Background = Library:Create("Frame", {Parent = Items.Notification, Position = dim2(0,2,0,2), Size = dim2(1,-4,1,-4), BackgroundTransparency = 1, ZIndex = 2, BorderSizePixel = 0, BackgroundColor3 = themes.preset.g})
    Items.Title = Library:Create("TextLabel", {FontFace = Fonts[themes.preset.font], Parent = Items.Notification, TextColor3 = themes.preset.text_color, Text = Cfg.Name, TextTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, AnchorPoint = vec2(0,0.5), Position = dim2(0,0,0.5,0), BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 3, TextSize = 12})
    Library:Create("UIStroke", {Parent = Items.Title, LineJoinMode = Enum.LineJoinMode.Miter})
    Library:Create("UIPadding", {Parent = Items.Title, PaddingRight = dim(0,7), PaddingLeft = dim(0,9)})
    Items.Inline = Library:Create("Frame", {Parent = Items.Notification, BackgroundTransparency = 1, Position = dim2(0,1,0,1), Size = dim2(1,-2,1,-2), BorderSizePixel = 0, BackgroundColor3 = themes.preset.inline})
    
    function Cfg.DestroyNotif()
        local Tween = Library:Tween(Items.Holder, {AnchorPoint = vec2(1, 0)}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut))
        Library:FadeNotification(Items.Holder, true)
        Tween.Completed:Connect(function() Items.Holder:Destroy() Notifications.Notifs[Index] = nil Library:ReorderNotifications() end)
    end
    
    local Offset = Library:ReorderNotifications()
    Notifications.Notifs[Index] = Items.Holder
    Library:FadeNotification(Items.Holder, false)
    Library:Tween(Items.Holder, {AnchorPoint = vec2(0, 0), BackgroundTransparency = 1}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut))
    Items.Holder.Position = dim_offset(20, Offset)
    
    if Cfg.Lifetime then task.spawn(function() task.wait(Cfg.Lifetime) Cfg.DestroyNotif() end) end
    
    return setmetatable(Cfg, Library)
end

--[[ UNLOAD FUNCTION ]]--
function Library:Unload()
    if not Library then return end
    if Library.Items then Library.Items:Destroy() end
    if Library.Other then Library.Other:Destroy() end
    if Library.Elements then Library.Elements:Destroy() end
    for _, connection in ipairs(Library.Connections) do if connection then connection:Disconnect() end end
    if Library.Blur then Library.Blur:Destroy() end
    getgenv().NexusUI = nil
end

--[[ RETURN ]]--
return Library
