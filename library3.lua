--[[
    ZANJI UI LIBRARY V3 - SHELL MATCH
    Fresh standalone UI shell inspired by the current ZANJI layout.

    Core UI:
      - left icon sidebar
      - top page title + description
      - top search box
      - draggable move button
      - resizable bottom-right handle
      - centered footer
      - collapsible icon groupboxes
      - two-column pages
      - nested cards for controls
      - multi dropdown modal with Search + All + None
      - NO checkbox inside dropdown rows
      - selected dropdown rows use full-row highlight + accent outline

    Default theme matches the current ronzz-loader library:
      Background = 15,15,15
      Main       = 25,25,25
      Accent     = 125,85,255
      Outline    = 40,40,40
      Font       = Code

    The icon provider defaults to the Lucide source already used in:
      ronzzofficial/ronzz-loader/source.lua

    Basic usage:
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ronzzofficial/loader-ronzz/refs/heads/main/library3.lua"))()

        local Window = Library:CreateWindow({
            Title = "ZANJIHUB",
            Footer = "discord.gg/ywgY5taFYU",
            Size = UDim2.fromOffset(820, 560),
        })

        local Home = Window:AddTab({
            Name = "Home",
            Icon = "house",
            Description = "Live session overview, latest pickup and performance statistics."
        })

        local Session = Home:AddGroup({
            Title = "Session",
            Icon = "timer",
            Side = "Left",
            Collapsible = true,
        })

        Session:AddLabel("ZANJI SESSION · LIVE")
]]

local Library = {}

--// services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--// theme - aligned with the current ronzz-loader palette
Library.Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Main = Color3.fromRGB(25, 25, 25),
    MainHover = Color3.fromRGB(31, 31, 31),
    MainSelected = Color3.fromRGB(55, 55, 57),
    Outline = Color3.fromRGB(40, 40, 40),
    OutlineSoft = Color3.fromRGB(33, 33, 33),
    Accent = Color3.fromRGB(125, 85, 255),
    AccentHover = Color3.fromRGB(139, 104, 255),
    AccentDark = Color3.fromRGB(68, 46, 142),
    Font = Color3.new(1, 1, 1),
    Muted = Color3.fromRGB(145, 145, 155),
    Dim = Color3.fromRGB(96, 96, 108),
    Red = Color3.fromRGB(255, 50, 50),
    Destructive = Color3.fromRGB(220, 38, 38),
    Black = Color3.new(0, 0, 0),
}

Library.RarityColors = {
    Ethereal = Color3.fromRGB(93, 225, 245),
    Divine = Color3.fromRGB(244, 151, 211),
    Mythic = Color3.fromRGB(255, 102, 114),
    Legendary = Color3.fromRGB(255, 203, 62),
    Epic = Color3.fromRGB(173, 134, 255),
    Rare = Color3.fromRGB(88, 156, 255),
}

local Theme = Library.Theme

Library.Flags = {}
Library.Options = {}
Library.Connections = {}
Library.OpenDropdown = nil
Library.Gui = nil
Library.IconProvider = nil

Library.DefaultIconSource =
    "https://raw.githubusercontent.com/ronzzofficial/ronzz-loader/refs/heads/main/source.lua"

--// helpers
local function safeParent()
    local ok, result = pcall(function()
        if type(gethui) == "function" then
            return gethui()
        end
    end)
    if ok and result then
        return result
    end

    local ok2, result2 = pcall(function()
        return CoreGui
    end)
    if ok2 and result2 then
        return result2
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protect(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        end
    end)
end

local function new(className, props)
    local object = Instance.new(className)
    if props then
        for key, value in pairs(props) do
            object[key] = value
        end
    end
    return object
end

local function corner(parent, radius)
    local object = new("UICorner", {
        CornerRadius = UDim.new(0, radius or 4),
    })
    object.Parent = parent
    return object
end

local function stroke(parent, color, thickness, transparency)
    local object = new("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or Theme.Outline,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    })
    object.Parent = parent
    return object
end

local function padding(parent, left, right, top, bottom)
    local object = new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
    object.Parent = parent
    return object
end

local function list(parent, gap)
    local object = new("UIListLayout", {
        Padding = UDim.new(0, gap or 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    object.Parent = parent
    return object
end

local function tween(object, duration, properties)
    local t = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
    t:Play()
    return t
end

local function onHover(button, normal, hover)
    button.MouseEnter:Connect(function()
        tween(button, 0.1, {BackgroundColor3 = hover})
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.1, {BackgroundColor3 = normal})
    end)
end

local function arrayCopy(values)
    local out = {}
    for index, value in ipairs(values or {}) do
        out[index] = value
    end
    return out
end

local function displayName(entry)
    if type(entry) == "table" then
        return tostring(entry.Name or entry.Text or entry.Value or entry[1] or "Item")
    end
    return tostring(entry)
end

local function searchText(entry)
    if type(entry) == "table" then
        return string.lower(tostring(
            entry.SearchText
            or (
                tostring(entry.Name or entry.Text or entry.Value or entry[1] or "")
                .. " "
                .. tostring(entry.Subtext or "")
                .. " "
                .. tostring(entry.Rarity or "")
                .. " "
                .. tostring(entry.Luck or "")
            )
        ))
    end
    return string.lower(tostring(entry))
end

local function normalizeMulti(values, selected)
    local lookup = {}
    if type(selected) == "table" then
        for key, value in pairs(selected) do
            if type(key) == "number" then
                lookup[tostring(value)] = true
            elseif value then
                lookup[tostring(key)] = true
            end
        end
    end

    local out = {}
    for _, entry in ipairs(values or {}) do
        local name = displayName(entry)
        if lookup[name] then
            out[name] = true
        end
    end
    return out
end

local function selectedArray(values, selected)
    local out = {}
    for _, entry in ipairs(values or {}) do
        local name = displayName(entry)
        if selected[name] then
            table.insert(out, name)
        end
    end
    return out
end

local function rgbHex(color)
    return string.format(
        "#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

--// icons
function Library:LoadIconProvider(url)
    if self.IconProvider then
        return self.IconProvider
    end

    local source = url or self.DefaultIconSource
    local ok, provider = pcall(function()
        return loadstring(game:HttpGet(source))()
    end)

    if ok and type(provider) == "table" and type(provider.GetAsset) == "function" then
        self.IconProvider = provider
        return provider
    end

    return nil
end

local function createIcon(parent, iconName, size, color, zIndex)
    size = size or 16
    color = color or Theme.Muted
    zIndex = zIndex or 1

    if iconName == nil or iconName == "" then
        return nil
    end

    if type(iconName) == "number" then
        local image = new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. tostring(iconName),
            ImageColor3 = color,
            Size = UDim2.fromOffset(size, size),
            ZIndex = zIndex,
        })
        image.Parent = parent
        return image
    end

    local iconString = tostring(iconName)

    if iconString:match("^rbxassetid://") or iconString:match("^https?://") then
        local image = new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = iconString,
            ImageColor3 = color,
            Size = UDim2.fromOffset(size, size),
            ZIndex = zIndex,
        })
        image.Parent = parent
        return image
    end

    if not Library.IconProvider then
        Library:LoadIconProvider()
    end

    if Library.IconProvider then
        local ok, data = pcall(Library.IconProvider.GetAsset, iconString)
        if ok and type(data) == "table" and data.Url then
            local image = new("ImageLabel", {
                BackgroundTransparency = 1,
                Image = data.Url,
                ImageRectSize = data.ImageRectSize or Vector2.zero,
                ImageRectOffset = data.ImageRectOffset or Vector2.zero,
                ImageColor3 = color,
                Size = UDim2.fromOffset(size, size),
                ZIndex = zIndex,
            })
            image.Parent = parent
            return image
        end
    end

    -- No fallback icon.
    -- If the icon provider cannot resolve this icon, leave the slot empty.
    return nil
end

local function setIconColor(icon, color)
    if not icon then
        return
    end
    if icon:IsA("ImageLabel") or icon:IsA("ImageButton") then
        icon.ImageColor3 = color
    elseif icon:IsA("TextLabel") or icon:IsA("TextButton") then
        icon.TextColor3 = color
    end
end

--// root gui
local gui = new("ScreenGui", {
    Name = "ZANJI_UI_V2_" .. tostring(math.random(100000, 999999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100000,
})
protect(gui)
gui.Parent = safeParent()
Library.Gui = gui

function Library:Destroy()
    if self.OpenDropdown and self.OpenDropdown.Close then
        pcall(function()
            self.OpenDropdown:Close()
        end)
    end

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(self.Connections)

    pcall(function()
        gui:Destroy()
    end)
end

function Library:SetTheme(values)
    for key, value in pairs(values or {}) do
        if Theme[key] ~= nil then
            Theme[key] = value
        end
    end
end

function Library:Notify(text, duration)
    duration = duration or 2.5

    local holder = gui:FindFirstChild("ZANJI_Notifications")
    if not holder then
        holder = new("Frame", {
            Name = "ZANJI_Notifications",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -12, 1, -12),
            Size = UDim2.new(0, 310, 1, -24),
            ZIndex = 500,
        })
        holder.Parent = gui

        local layout = new("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
        })
        layout.Parent = holder
    end

    local card = new("Frame", {
        BackgroundColor3 = Theme.Main,
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 501,
    })
    corner(card, 4)
    stroke(card, Theme.Accent, 1, 0.35)
    padding(card, 10, 10, 9, 9)
    card.Parent = holder

    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = tostring(text),
        TextColor3 = Theme.Font,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 502,
    })
    label.Parent = card

    task.delay(duration, function()
        if card and card.Parent then
            tween(card, 0.15, {BackgroundTransparency = 1})
            tween(label, 0.15, {TextTransparency = 1})
            task.wait(0.16)
            pcall(function()
                card:Destroy()
            end)
        end
    end)
end

--// dropdown popup
local function openDropdown(option)
    if Library.OpenDropdown and Library.OpenDropdown ~= option then
        pcall(function()
            Library.OpenDropdown:Close()
        end)
    end

    local overlay = new("TextButton", {
        Name = "DropdownOverlay",
        AutoButtonColor = false,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.42,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 200,
    })
    overlay.Parent = gui

    local modal = new("Frame", {
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = option.PopupSize or UDim2.fromOffset(560, 440),
        ZIndex = 201,
    })
    corner(modal, 8)
    stroke(modal, Theme.Outline, 1, 0)
    modal.Parent = overlay

    local header = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -28, 0, 40),
        ZIndex = 202,
    })
    header.Parent = modal

    local titleIconHolder = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(24, 40),
        ZIndex = 203,
    })
    titleIconHolder.Parent = header

    local titleIcon = createIcon(
        titleIconHolder,
        option.PopupIcon or option.Icon or "target",
        18,
        Theme.Accent,
        204
    )
    if titleIcon then
        titleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        titleIcon.Position = UDim2.fromScale(0.5, 0.5)
    end

    local title = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -150, 1, 0),
        Text = option.PopupTitle or option.Text or "Select items",
        TextColor3 = Theme.Font,
        Font = Enum.Font.Code,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
    })
    title.Parent = header

    local done = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Accent,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(110, 34),
        Text = "Done",
        TextColor3 = Theme.Font,
        Font = Enum.Font.Code,
        TextSize = 13,
        ZIndex = 203,
    })
    corner(done, 7)
    onHover(done, Theme.Accent, Theme.AccentHover)
    done.Parent = header

    local body = new("Frame", {
        BackgroundColor3 = Theme.Main,
        Position = UDim2.fromOffset(14, 58),
        Size = UDim2.new(1, -28, 1, -72),
        ZIndex = 202,
    })
    corner(body, 8)
    stroke(body, Theme.Outline, 1, 0)
    body.Parent = modal

    local toolbar = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.new(1, -28, 0, 38),
        ZIndex = 203,
    })
    toolbar.Parent = body

    local showBulk = option.Multi and option.BulkActions ~= false
    local bulkWidth = showBulk and 104 or 0

    local searchHolder = new("Frame", {
        BackgroundColor3 = Theme.Background,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -(bulkWidth + (showBulk and 8 or 0)), 1, 0),
        ZIndex = 204,
    })
    corner(searchHolder, 7)
    stroke(searchHolder, Theme.Outline, 1, 0)
    searchHolder.Parent = toolbar

    local searchIconHolder = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(7, 0),
        Size = UDim2.fromOffset(24, 38),
        ZIndex = 205,
    })
    searchIconHolder.Parent = searchHolder

    local searchIcon = createIcon(searchIconHolder, "search", 15, Theme.Accent, 206)
    if searchIcon then
        searchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        searchIcon.Position = UDim2.fromScale(0.5, 0.5)
    end

    local search = new("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        PlaceholderText = "Search items...",
        PlaceholderColor3 = Theme.Dim,
        Text = "",
        TextColor3 = Theme.Font,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -40, 1, 0),
        ZIndex = 205,
    })
    search.Parent = searchHolder

    local allButton
    local noneButton

    if showBulk then
        local bulk = new("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(bulkWidth, 38),
            ZIndex = 204,
        })
        bulk.Parent = toolbar

        local bulkLayout = new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
        })
        bulkLayout.Parent = bulk

        allButton = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Background,
            Size = UDim2.fromOffset(49, 28),
            Text = "All",
            TextColor3 = Theme.Font,
            Font = Enum.Font.Code,
            TextSize = 12,
            LayoutOrder = 1,
            ZIndex = 205,
        })
        corner(allButton, 6)
        stroke(allButton, Theme.Outline, 1, 0)
        onHover(allButton, Theme.Background, Theme.MainHover)
        allButton.Parent = bulk

        noneButton = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Background,
            Size = UDim2.fromOffset(49, 28),
            Text = "None",
            TextColor3 = Theme.Font,
            Font = Enum.Font.Code,
            TextSize = 12,
            LayoutOrder = 2,
            ZIndex = 205,
        })
        corner(noneButton, 6)
        stroke(noneButton, Theme.Outline, 1, 0)
        onHover(noneButton, Theme.Background, Theme.MainHover)
        noneButton.Parent = bulk
    end

    local listFrame = new("ScrollingFrame", {
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 58),
        Size = UDim2.new(1, -28, 1, -72),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Outline,
        ZIndex = 203,
    })
    corner(listFrame, 7)
    listFrame.Parent = body
    padding(listFrame, 6, 6, 6, 6)

    local rowsLayout = list(listFrame, 3)
    rowsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local rows = {}

    local function isSelected(name)
        if option.Multi then
            return option.Selected[name] == true
        end
        return option.Selected == name
    end

    local function updateRow(info)
        local selected = isSelected(info.Name)
        if selected then
            tween(info.Button, 0.08, {BackgroundColor3 = Theme.MainSelected})
            info.Stroke.Color = Theme.Accent
            info.Stroke.Transparency = 0
        else
            tween(info.Button, 0.08, {BackgroundColor3 = Theme.Main})
            info.Stroke.Color = Theme.Outline
            info.Stroke.Transparency = 1
        end
    end

    local function rebuild()
        for _, info in ipairs(rows) do
            pcall(function()
                info.Button:Destroy()
            end)
        end
        table.clear(rows)

        local query = string.lower(search.Text or "")

        for index, entry in ipairs(option.Values) do
            local name = displayName(entry)
            if query == "" or string.find(searchText(entry), query, 1, true) then
                local row = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Main,
                    Size = UDim2.new(1, -2, 0, option.RowHeight or 42),
                    Text = "",
                    LayoutOrder = index,
                    ZIndex = 204,
                })
                corner(row, 6)
                local rowStroke = stroke(row, Theme.Outline, 1, 1)
                row.Parent = listFrame

                local text = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(13, 0),
                    Size = UDim2.new(1, -22, 1, 0),
                    Text = name,
                    TextColor3 = Theme.Font,
                    Font = Enum.Font.Code,
                    TextSize = 13,
                    RichText = option.RichText == true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 205,
                })
                text.Parent = row

                if type(option.Format) == "function" then
                    local ok, formatted = pcall(option.Format, entry, index)
                    if ok then
                        text.Text = tostring(formatted)
                    end
                elseif type(entry) == "table" and entry.Subtext then
                    text.Text = name .. "  " .. tostring(entry.Subtext)
                end

                local info = {
                    Button = row,
                    Stroke = rowStroke,
                    Text = text,
                    Name = name,
                    Entry = entry,
                }
                table.insert(rows, info)
                updateRow(info)

                row.MouseEnter:Connect(function()
                    if not isSelected(name) then
                        tween(row, 0.08, {BackgroundColor3 = Theme.MainHover})
                    end
                end)

                row.MouseLeave:Connect(function()
                    updateRow(info)
                end)

                row.Activated:Connect(function()
                    if option.Multi then
                        option.Selected[name] = not option.Selected[name]
                        updateRow(info)
                        option:_sync()
                    else
                        option.Selected = name
                        for _, other in ipairs(rows) do
                            updateRow(other)
                        end
                        option:_sync()
                        if option.CloseOnSelect ~= false then
                            option:Close()
                        end
                    end
                end)
            end
        end
    end

    option.Popup = overlay
    Library.OpenDropdown = option

    done.Activated:Connect(function()
        option:Close()
    end)

    overlay.Activated:Connect(function()
        option:Close()
    end)

    search:GetPropertyChangedSignal("Text"):Connect(rebuild)

    if allButton then
        allButton.Activated:Connect(function()
            for _, entry in ipairs(option.Values) do
                option.Selected[displayName(entry)] = true
            end
            for _, info in ipairs(rows) do
                updateRow(info)
            end
            option:_sync()
        end)
    end

    if noneButton then
        noneButton.Activated:Connect(function()
            table.clear(option.Selected)
            for _, info in ipairs(rows) do
                updateRow(info)
            end
            option:_sync()
        end)
    end

    rebuild()

    if option.Searchable ~= false then
        task.defer(function()
            pcall(function()
                search:CaptureFocus()
            end)
        end)
    end
end

--// control API factory
local function attachControls(api, holder, elementRegistry)
    api._holder = holder
    api._elements = elementRegistry or {}
    api._order = api._order or 0

    local function register(frame, text)
        api._order += 1
        frame.LayoutOrder = api._order
        table.insert(api._elements, {
            Frame = frame,
            Text = string.lower(tostring(text or "")),
        })
        return frame
    end

    local function controlFrame(height, text)
        local isFlat = api._flatControls == true
        local frame = new("Frame", {
            BackgroundColor3 = api._controlColor or Theme.Main,
            BackgroundTransparency = isFlat and 1 or 0,
            Size = UDim2.new(1, 0, 0, height),
        })
        if not isFlat then
            corner(frame, 5)
        end
        register(frame, text)
        frame.Parent = holder
        return frame
    end

    function api:AddLabel(text, config)
        config = config or {}
        local label = new("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, config.Height or 24),
            Text = tostring(text or ""),
            TextColor3 = config.Color or Theme.Muted,
            Font = Enum.Font.Code,
            TextSize = config.TextSize or 12,
            TextWrapped = config.Wrap == true,
            RichText = config.RichText == true,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        padding(label, 5, 5, 0, 0)
        register(label, text)
        label.Parent = holder

        local object = {Instance = label}
        function object:SetText(value)
            label.Text = tostring(value)
        end
        function object:SetColor(value)
            label.TextColor3 = value
        end
        return object
    end

    function api:AddStat(labelText, valueText, config)
        config = config or {}
        local frame = controlFrame(config.Height or 43, tostring(labelText) .. " " .. tostring(valueText))

        local label = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(7, 4),
            Size = UDim2.new(1, -14, 0, 15),
            Text = tostring(labelText or ""),
            TextColor3 = config.LabelColor or Theme.Muted,
            Font = Enum.Font.Code,
            TextSize = config.LabelSize or 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        label.Parent = frame

        local value = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(7, 19),
            Size = UDim2.new(1, -14, 0, 20),
            Text = tostring(valueText or ""),
            TextColor3 = config.ValueColor or Theme.Font,
            Font = Enum.Font.Code,
            TextSize = config.ValueSize or 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        value.Parent = frame

        local object = {Instance = frame}
        function object:SetValue(v)
            value.Text = tostring(v)
        end
        function object:SetLabel(v)
            label.Text = tostring(v)
        end
        return object
    end

    function api:AddDivider()
        local line = new("Frame", {
            BackgroundColor3 = Theme.OutlineSoft,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -10, 0, 1),
        })
        register(line, "")
        line.Parent = holder
        return line
    end

    function api:AddButton(config)
        if type(config) == "string" then
            config = {Text = config}
        end
        config = config or {}

        local frame = controlFrame(config.Height or 34, config.Text)
        if api._flatControls ~= true then
            onHover(frame, api._controlColor or Theme.Main, Theme.MainHover)
        end

        local iconHolder = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(7, 0),
            Size = UDim2.fromOffset(config.Icon and 22 or 0, frame.Size.Y.Offset),
        })
        iconHolder.Parent = frame

        local icon
        if config.Icon then
            icon = createIcon(iconHolder, config.Icon, 14, Theme.Accent, 2)
            if icon then
                icon.AnchorPoint = Vector2.new(0.5, 0.5)
                icon.Position = UDim2.fromScale(0.5, 0.5)
            end
        end

        local button = new("TextButton", {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(config.Icon and 28 or 0, 0),
            Size = UDim2.new(1, -(config.Icon and 28 or 0), 1, 0),
            Text = config.Text or "Button",
            TextColor3 = Theme.Font,
            Font = Enum.Font.Code,
            TextSize = 12,
        })
        button.Parent = frame

        button.Activated:Connect(function()
            if type(config.Callback) == "function" then
                task.spawn(config.Callback)
            end
        end)

        return {Instance = frame, Button = button, Icon = icon}
    end

    function api:AddToggle(flag, config)
        config = config or {}
        local frame = controlFrame(config.Height or 36, config.Text or flag)

        local label = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(9, 0),
            Size = UDim2.new(1, -55, 1, 0),
            Text = config.Text or tostring(flag),
            TextColor3 = Theme.Muted,
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        label.Parent = frame

        local track = new("Frame", {
            BackgroundColor3 = Theme.Background,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -9, 0.5, 0),
            Size = UDim2.fromOffset(31, 17),
        })
        corner(track, 8)
        stroke(track, Theme.Outline, 1, 0)
        track.Parent = frame

        local knob = new("Frame", {
            BackgroundColor3 = Theme.Font,
            Position = UDim2.new(0, 3, 0.5, -5),
            Size = UDim2.fromOffset(10, 10),
        })
        corner(knob, 5)
        knob.Parent = track

        local hit = new("TextButton", {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
        })
        hit.Parent = frame

        local object = {
            Flag = flag,
            Value = config.Default == true,
        }

        local function render()
            if object.Value then
                tween(track, 0.1, {BackgroundColor3 = Theme.Accent})
                tween(knob, 0.1, {Position = UDim2.new(1, -13, 0.5, -5)})
                label.TextColor3 = Theme.Font
            else
                tween(track, 0.1, {BackgroundColor3 = Theme.Background})
                tween(knob, 0.1, {Position = UDim2.new(0, 3, 0.5, -5)})
                label.TextColor3 = Theme.Muted
            end
        end

        function object:SetValue(value, silent)
            self.Value = value and true or false
            Library.Flags[flag] = self.Value
            render()
            if not silent and type(config.Callback) == "function" then
                task.spawn(config.Callback, self.Value)
            end
        end

        function object:GetValue()
            return self.Value
        end

        hit.Activated:Connect(function()
            object:SetValue(not object.Value)
        end)

        Library.Options[flag] = object
        object:SetValue(object.Value, true)
        return object
    end

    function api:AddInput(flag, config)
        config = config or {}
        local frame = controlFrame(config.Height or 56, (config.Text or flag) .. " " .. tostring(config.Default or ""))

        local label = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 3),
            Size = UDim2.new(1, -16, 0, 17),
            Text = config.Text or tostring(flag),
            TextColor3 = Theme.Muted,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        label.Parent = frame

        local box = new("TextBox", {
            BackgroundColor3 = Theme.Background,
            ClearTextOnFocus = false,
            Position = UDim2.fromOffset(7, 22),
            Size = UDim2.new(1, -14, 0, 27),
            Text = tostring(config.Default or ""),
            PlaceholderText = config.Placeholder or "",
            PlaceholderColor3 = Theme.Dim,
            TextColor3 = Theme.Font,
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        corner(box, 5)
        stroke(box, Theme.Outline, 1, 0)
        padding(box, 8, 8, 0, 0)
        box.Parent = frame

        local object = {
            Flag = flag,
            Value = box.Text,
        }

        function object:SetValue(value, silent)
            self.Value = tostring(value or "")
            box.Text = self.Value
            Library.Flags[flag] = self.Value
            if not silent and type(config.Callback) == "function" then
                task.spawn(config.Callback, self.Value)
            end
        end

        function object:GetValue()
            return self.Value
        end

        box.FocusLost:Connect(function(enterPressed)
            object.Value = box.Text
            Library.Flags[flag] = object.Value
            if type(config.Callback) == "function" then
                task.spawn(config.Callback, object.Value, enterPressed)
            end
        end)

        Library.Options[flag] = object
        object:SetValue(object.Value, true)
        return object
    end

    function api:AddSlider(flag, config)
        config = config or {}
        local min = tonumber(config.Min) or 0
        local max = tonumber(config.Max) or 100
        local rounding = tonumber(config.Rounding) or 0
        if max <= min then
            max = min + 1
        end

        local frame = controlFrame(config.Height or 54, config.Text or flag)

        local label = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 3),
            Size = UDim2.new(0.65, -8, 0, 18),
            Text = config.Text or tostring(flag),
            TextColor3 = Theme.Muted,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        label.Parent = frame

        local valueLabel = new("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 3),
            Size = UDim2.new(0.35, 0, 0, 18),
            Text = "",
            TextColor3 = Theme.Font,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        valueLabel.Parent = frame

        local bar = new("Frame", {
            BackgroundColor3 = Theme.Background,
            Position = UDim2.fromOffset(8, 34),
            Size = UDim2.new(1, -16, 0, 7),
        })
        corner(bar, 4)
        stroke(bar, Theme.Outline, 1, 0)
        bar.Parent = frame

        local fill = new("Frame", {
            BackgroundColor3 = Theme.Accent,
            Size = UDim2.new(0, 0, 1, 0),
        })
        corner(fill, 4)
        fill.Parent = bar

        local hit = new("TextButton", {
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-3, -7),
            Size = UDim2.new(1, 6, 1, 14),
            Text = "",
        })
        hit.Parent = bar

        local object = {
            Flag = flag,
            Value = tonumber(config.Default) or min,
        }

        local function round(value)
            if rounding <= 0 then
                return math.floor(value + 0.5)
            end
            local p = 10 ^ rounding
            return math.floor(value * p + 0.5) / p
        end

        function object:SetValue(value, silent)
            value = math.clamp(tonumber(value) or min, min, max)
            value = round(value)
            self.Value = value
            Library.Flags[flag] = value

            local alpha = (value - min) / (max - min)
            tween(fill, 0.06, {Size = UDim2.new(alpha, 0, 1, 0)})
            valueLabel.Text = tostring(value) .. tostring(config.Suffix or "")

            if not silent and type(config.Callback) == "function" then
                task.spawn(config.Callback, value)
            end
        end

        function object:GetValue()
            return self.Value
        end

        local dragging = false

        local function update(inputX)
            local alpha = math.clamp(
                (inputX - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1),
                0,
                1
            )
            object:SetValue(min + (max - min) * alpha)
        end

        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position.X)
            end
        end)

        table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                update(input.Position.X)
            end
        end))

        table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))

        Library.Options[flag] = object
        object:SetValue(object.Value, true)
        return object
    end

    function api:AddDropdown(flag, config)
        config = config or {}
        local frame = controlFrame(config.Height or 61, config.Text or flag)

        local label = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 3),
            Size = UDim2.new(1, -16, 0, 18),
            Text = config.Text or tostring(flag),
            TextColor3 = Theme.Font,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        label.Parent = frame

        local selectButton = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Background,
            Position = UDim2.fromOffset(7, 24),
            Size = UDim2.new(1, -14, 0, 29),
            Text = "",
        })
        corner(selectButton, 5)
        stroke(selectButton, Theme.Outline, 1, 0)
        onHover(selectButton, Theme.Background, Theme.MainHover)
        selectButton.Parent = frame

        local valueText = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(9, 0),
            Size = UDim2.new(1, -35, 1, 0),
            Text = "---",
            TextColor3 = Theme.Muted,
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        valueText.Parent = selectButton

        local arrowHolder = new("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -5, 0, 0),
            Size = UDim2.fromOffset(24, 29),
        })
        arrowHolder.Parent = selectButton

        local arrow = createIcon(arrowHolder, "chevron-down", 14, Theme.Muted, 2)
        if arrow then
            arrow.AnchorPoint = Vector2.new(0.5, 0.5)
            arrow.Position = UDim2.fromScale(0.5, 0.5)
        end

        local option = {
            Flag = flag,
            Text = config.Text or tostring(flag),
            Icon = config.Icon,
            PopupTitle = config.PopupTitle or config.Text or tostring(flag),
            PopupIcon = config.PopupIcon,
            PopupSize = config.PopupSize,
            Values = arrayCopy(config.Values or {}),
            Multi = config.Multi == true,
            Searchable = config.Searchable ~= false,
            BulkActions = config.BulkActions ~= false,
            RichText = config.RichText == true,
            Format = config.Format,
            RowHeight = config.RowHeight,
            CloseOnSelect = config.CloseOnSelect,
            Selected = nil,
            Popup = nil,
        }

        if option.Multi then
            option.Selected = normalizeMulti(option.Values, config.Default or {})
        else
            option.Selected = config.Default ~= nil and tostring(config.Default) or nil
        end

        function option:_sync(silent)
            if self.Multi then
                local values = selectedArray(self.Values, self.Selected)
                Library.Flags[flag] = values

                if #values == 0 then
                    valueText.Text = "---"
                    valueText.TextColor3 = Theme.Muted
                elseif #values <= (config.MaxPreview or 2) then
                    valueText.Text = table.concat(values, ", ")
                    valueText.TextColor3 = Theme.Font
                else
                    valueText.Text = tostring(#values) .. " selected"
                    valueText.TextColor3 = Theme.Font
                end

                if not silent and type(config.Callback) == "function" then
                    task.spawn(config.Callback, arrayCopy(values))
                end
            else
                Library.Flags[flag] = self.Selected
                valueText.Text = self.Selected or "---"
                valueText.TextColor3 = self.Selected and Theme.Font or Theme.Muted

                if not silent and type(config.Callback) == "function" then
                    task.spawn(config.Callback, self.Selected)
                end
            end
        end

        function option:Open()
            openDropdown(self)
        end

        function option:Close()
            if self.Popup then
                pcall(function()
                    self.Popup:Destroy()
                end)
                self.Popup = nil
            end
            if Library.OpenDropdown == self then
                Library.OpenDropdown = nil
            end
            self:_sync(true)
        end

        function option:GetValue()
            if self.Multi then
                return selectedArray(self.Values, self.Selected)
            end
            return self.Selected
        end

        function option:SetValue(value, silent)
            if self.Multi then
                self.Selected = normalizeMulti(self.Values, value or {})
            else
                self.Selected = value ~= nil and tostring(value) or nil
            end
            self:_sync(silent)
        end

        function option:SetValues(values, keepSelection)
            local old = self:GetValue()
            self.Values = arrayCopy(values or {})

            if keepSelection then
                self:SetValue(old, true)
            else
                if self.Multi then
                    self.Selected = {}
                else
                    self.Selected = nil
                end
                self:_sync(true)
            end

            if self.Popup then
                self:Close()
                self:Open()
            end
        end

        function option:SelectAll()
            if not self.Multi then
                return
            end
            for _, entry in ipairs(self.Values) do
                self.Selected[displayName(entry)] = true
            end
            self:_sync()
        end

        function option:Clear()
            if self.Multi then
                table.clear(self.Selected)
            else
                self.Selected = nil
            end
            self:_sync()
        end

        selectButton.Activated:Connect(function()
            option:Open()
        end)

        Library.Options[flag] = option
        option:_sync(true)
        return option
    end

    function api:AddCard(config)
        config = config or {}

        local card = new("Frame", {
            BackgroundColor3 = config.BackgroundColor or Theme.Main,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        corner(card, config.Radius or 5)
        stroke(card, config.OutlineColor or Theme.OutlineSoft, 1, 0)
        padding(card, 5, 5, 5, 5)
        register(card, config.Title or "")
        card.Parent = holder

        local layout = list(card, config.Gap or 3)

        local child = {
            Frame = card,
            Layout = layout,
            _order = 0,
            _flatControls = false,
            _controlColor = Theme.Background,
        }

        attachControls(child, card, api._elements)
        return child
    end

    return api
end

--// window
function Library:CreateWindow(config)
    config = config or {}

    local Window = {
        Tabs = {},
        ActiveTab = nil,
        SearchText = "",
    }

    local main = new("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position or UDim2.fromScale(0.5, 0.5),
        Size = config.Size or UDim2.fromOffset(720, 600),
        ClipsDescendants = true,
    })
    corner(main, config.CornerRadius or 4)
    stroke(main, Theme.Accent, 1, 0.25)
    main.Parent = gui
    Window.Frame = main

    local minSize = config.MinSize or Vector2.new(480, 360)
    local sizeConstraint = new("UISizeConstraint", {
        MinSize = minSize,
    })
    sizeConstraint.Parent = main

    local scale = new("UIScale", {
        Scale = config.Scale or 1,
    })
    scale.Parent = main
    Window.Scale = scale

    local headerHeight = 44
    local footerHeight = 20
    local sidebarWidth = config.SidebarWidth or 128

    -- header
    local header = new("Frame", {
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(1, 0, 0, headerHeight),
    })
    header.Parent = main

    local headerBottom = new("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
    })
    headerBottom.Parent = header

    local brand = new("Frame", {
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(0, sidebarWidth, 1, 0),
    })
    brand.Parent = header

    local brandRight = new("Frame", {
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
    })
    brandRight.Parent = brand

    if config.LogoAsset then
        local logo = new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = type(config.LogoAsset) == "number"
                and ("rbxassetid://" .. tostring(config.LogoAsset))
                or tostring(config.LogoAsset),
            Position = UDim2.fromOffset(12, 9),
            Size = config.LogoSize or UDim2.fromOffset(112, 28),
            ScaleType = Enum.ScaleType.Fit,
        })
        logo.Parent = brand
    else
        local z = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.fromOffset(22, headerHeight),
            Text = "Z",
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 19,
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        z.Parent = brand

        local gradient = new("UIGradient", {
            Rotation = 0,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(114, 72, 255)),
                ColorSequenceKeypoint.new(0.45, Color3.fromRGB(226, 74, 221)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 197, 67)),
            })
        })
        gradient.Parent = z

        local brandText = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(31, 0),
            Size = UDim2.new(1, -38, 1, 0),
            Text = "ZANJIHUB",
            TextColor3 = Color3.fromRGB(214, 205, 229),
            Font = Enum.Font.Code,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        brandText.Parent = brand
    end

    local pageTitle = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(sidebarWidth + 13, 5),
        Size = UDim2.new(1, -(sidebarWidth + 360), 0, 17),
        Text = config.DefaultPageTitle or "Home",
        TextColor3 = Theme.Font,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    pageTitle.Parent = header

    local pageDescription = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(sidebarWidth + 13, 21),
        Size = UDim2.new(1, -(sidebarWidth + 360), 0, 17),
        Text = config.DefaultPageDescription or "",
        TextColor3 = Theme.Dim,
        Font = Enum.Font.Code,
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    pageDescription.Parent = header

    local moveButton = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(34, 34),
        Text = "",
    })
    corner(moveButton, 4)
    stroke(moveButton, Theme.Accent, 1, 0)
    onHover(moveButton, Theme.Background, Theme.MainHover)
    moveButton.Parent = header

    local moveIconHolder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    })
    moveIconHolder.Parent = moveButton
    local moveIcon = createIcon(moveIconHolder, "move", 18, Theme.Accent, 2)
    if moveIcon then
        moveIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        moveIcon.Position = UDim2.fromScale(0.5, 0.5)
    end

    local searchHolder = new("Frame", {
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -48, 0.5, 0),
        Size = UDim2.fromOffset(config.SearchWidth or 280, 34),
    })
    corner(searchHolder, 4)
    stroke(searchHolder, Theme.Accent, 1, 0)
    searchHolder.Parent = header

    local searchIconHolder = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(7, 0),
        Size = UDim2.fromOffset(24, 34),
    })
    searchIconHolder.Parent = searchHolder

    local topSearchIcon = createIcon(searchIconHolder, "search", 15, Theme.Accent, 2)
    if topSearchIcon then
        topSearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        topSearchIcon.Position = UDim2.fromScale(0.5, 0.5)
    end

    local searchBox = new("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -40, 1, 0),
        PlaceholderText = "Search",
        PlaceholderColor3 = Theme.Dim,
        Text = "",
        TextColor3 = Theme.Font,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    searchBox.Parent = searchHolder
    Window.SearchBox = searchBox

    -- sidebar
    local sidebar = new("Frame", {
        BackgroundColor3 = Theme.Background,
        Position = UDim2.fromOffset(0, headerHeight),
        Size = UDim2.new(0, sidebarWidth, 1, -(headerHeight + footerHeight)),
    })
    sidebar.Parent = main
    padding(sidebar, 7, 7, 7, 7)

    local sideLayout = list(sidebar, 2)
    sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local sidebarLine = new("Frame", {
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 7, 0, -7),
        Size = UDim2.new(0, 1, 1, 14),
    })
    sidebarLine.Parent = sidebar

    -- content
    local content = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(8, 12, 18),
        Position = UDim2.fromOffset(sidebarWidth, headerHeight),
        Size = UDim2.new(1, -sidebarWidth, 1, -(headerHeight + footerHeight)),
        ClipsDescendants = true,
    })
    content.Parent = main
    Window.Content = content

    -- footer
    local footer = new("Frame", {
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0, 0, 1, -footerHeight),
        Size = UDim2.new(1, 0, 0, footerHeight),
    })
    footer.Parent = main

    local footerTop = new("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
    })
    footerTop.Parent = footer

    local footerText = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = config.Footer or "",
        TextColor3 = Theme.Dim,
        Font = Enum.Font.Code,
        TextSize = 10,
    })
    footerText.Parent = footer

    local resizeButton = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0.5, 0),
        Size = UDim2.fromOffset(29, 20),
        Text = "",
    })
    corner(resizeButton, 3)
    stroke(resizeButton, Theme.Accent, 1, 0)
    resizeButton.Parent = footer

    local resizeIconHolder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    })
    resizeIconHolder.Parent = resizeButton
    local resizeIcon = createIcon(resizeIconHolder, "maximize-2", 12, Theme.Accent, 2)
    if resizeIcon then
        resizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        resizeIcon.Position = UDim2.fromScale(0.5, 0.5)
    end

    -- dragging from the top-right move button
    do
        local dragging = false
        local dragInput
        local dragStart
        local startPosition

        moveButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPosition = main.Position
            end
        end)

        moveButton.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end))

        table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    -- resizing from footer handle
    if config.Resizable ~= false then
        local resizing = false
        local startMouse
        local startSize

        resizeButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                startMouse = input.Position
                startSize = main.AbsoluteSize
            end
        end)

        table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
            if resizing and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                local delta = input.Position - startMouse
                local width = math.max(minSize.X, startSize.X + delta.X)
                local height = math.max(minSize.Y, startSize.Y + delta.Y)
                main.Size = UDim2.fromOffset(width, height)
            end
        end))

        table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end))
    end

    function Window:SetScale(value)
        scale.Scale = tonumber(value) or 1
    end

    function Window:SetVisible(value)
        main.Visible = value and true or false
    end

    function Window:SetFooter(text)
        footerText.Text = tostring(text or "")
    end

    function Window:SetPageHeader(title, description)
        pageTitle.Text = tostring(title or "")
        pageDescription.Text = tostring(description or "")
    end

    function Window:ApplySearch(query)
        query = string.lower(tostring(query or ""))
        self.SearchText = query

        local tab = self.ActiveTab
        if not tab then
            return
        end

        for _, group in ipairs(tab.Groups) do
            local titleMatch = query == ""
                or string.find(string.lower(group.Title or ""), query, 1, true)

            local childMatch = false
            for _, element in ipairs(group.Elements) do
                local visible = query == ""
                    or titleMatch
                    or string.find(element.Text or "", query, 1, true) ~= nil

                element.Frame.Visible = visible
                if visible then
                    childMatch = true
                end
            end

            group.Frame.Visible = query == "" or titleMatch or childMatch
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Window:ApplySearch(searchBox.Text)
    end)

    function Window:AddTab(tabConfig, icon, description)
        if type(tabConfig) ~= "table" then
            tabConfig = {
                Name = tostring(tabConfig),
                Icon = icon,
                Description = description,
            }
        end

        local Tab = {
            Name = tabConfig.Name or "Tab",
            Icon = tabConfig.Icon,
            Description = tabConfig.Description or "",
            Groups = {},
        }

        local sideButton = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Background,
            Size = UDim2.new(1, 0, 0, 34),
            Text = "",
            LayoutOrder = #Window.Tabs + 1,
        })
        corner(sideButton, 4)
        sideButton.Parent = sidebar

        local iconHolder = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.fromOffset(24, 34),
        })
        iconHolder.Parent = sideButton

        local tabIcon = createIcon(iconHolder, Tab.Icon or "circle", 15, Theme.Dim, 2)
        if tabIcon then
            tabIcon.AnchorPoint = Vector2.new(0.5, 0.5)
            tabIcon.Position = UDim2.fromScale(0.5, 0.5)
        end

        local tabLabel = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(34, 0),
            Size = UDim2.new(1, -39, 1, 0),
            Text = Tab.Name,
            TextColor3 = Theme.Dim,
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        tabLabel.Parent = sideButton

        local page = new("Frame", {
            BackgroundTransparency = 1,
            Visible = false,
            Size = UDim2.fromScale(1, 1),
        })
        page.Parent = content

        local gap = 7
        local left = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(7, 7),
            Size = UDim2.new(0.5, -(10 + gap / 2), 1, -14),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Outline,
        })
        padding(left, 0, 3, 0, 3)
        left.Parent = page
        list(left, 7)

        local right = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, gap / 2, 0, 7),
            Size = UDim2.new(0.5, -(10 + gap / 2), 1, -14),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Outline,
        })
        padding(right, 0, 3, 0, 3)
        right.Parent = page
        list(right, 7)

        Tab.Page = page
        Tab.Button = sideButton
        Tab.Label = tabLabel
        Tab.IconObject = tabIcon
        Tab.Left = left
        Tab.Right = right

        function Tab:Show()
            for _, other in ipairs(Window.Tabs) do
                other.Page.Visible = false
                other.Button.BackgroundColor3 = Theme.Background
                other.Label.TextColor3 = Theme.Dim
                setIconColor(other.IconObject, Theme.Dim)
            end

            self.Page.Visible = true
            self.Button.BackgroundColor3 = Theme.Main
            self.Label.TextColor3 = Theme.Font
            setIconColor(self.IconObject, Theme.Accent)

            Window.ActiveTab = self
            Window:SetPageHeader(self.Name, self.Description)
            Window:ApplySearch(searchBox.Text)
        end

        sideButton.Activated:Connect(function()
            Tab:Show()
        end)

        function Tab:AddGroup(groupConfig, groupIcon, side)
            if type(groupConfig) ~= "table" then
                groupConfig = {
                    Title = tostring(groupConfig),
                    Icon = groupIcon,
                    Side = side,
                }
            end

            local Group = {
                Title = groupConfig.Title or "Group",
                Icon = groupConfig.Icon,
                Side = groupConfig.Side or "Left",
                Elements = {},
                Collapsed = false,
            }

            local parentColumn =
                string.lower(tostring(Group.Side)) == "right"
                and right
                or left

            local frame = new("Frame", {
                BackgroundColor3 = Color3.fromRGB(8, 12, 18),
                Size = UDim2.new(1, -2, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            corner(frame, 5)
            stroke(frame, Theme.Accent, 1, 0.45)
            frame.Parent = parentColumn
            Group.Frame = frame

            local headerFrame = new("Frame", {
                BackgroundColor3 = Theme.Background,
                Size = UDim2.new(1, 0, 0, 30),
            })
            corner(headerFrame, 5)
            headerFrame.Parent = frame

            local groupIconHolder = new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(5, 0),
                Size = UDim2.fromOffset(24, 30),
            })
            groupIconHolder.Parent = headerFrame

            local groupIconObject = createIcon(
                groupIconHolder,
                Group.Icon or "box",
                16,
                Theme.Accent,
                2
            )
            if groupIconObject then
                groupIconObject.AnchorPoint = Vector2.new(0.5, 0.5)
                groupIconObject.Position = UDim2.fromScale(0.5, 0.5)
            end

            local titleLabel = new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(31, 0),
                Size = UDim2.new(1, -68, 1, 0),
                Text = Group.Title,
                TextColor3 = Theme.Muted,
                Font = Enum.Font.Code,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            titleLabel.Parent = headerFrame

            local collapse = new("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -3, 0, 0),
                Size = UDim2.fromOffset(30, 30),
                Text = "",
            })
            collapse.Parent = headerFrame

            local chevronHolder = new("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
            })
            chevronHolder.Parent = collapse

            local chevron = createIcon(chevronHolder, "chevron-down", 14, Theme.Font, 2)
            if chevron then
                chevron.AnchorPoint = Vector2.new(0.5, 0.5)
                chevron.Position = UDim2.fromScale(0.5, 0.5)
            end

            local body = new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(5, 34),
                Size = UDim2.new(1, -10, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            padding(body, 0, 0, 0, 5)
            local bodyLayout = list(body, 3)
            body.Parent = frame
            Group.Body = body

            local controls = {
                Frame = frame,
                Body = body,
                Elements = Group.Elements,
                _order = 0,
                _flatControls = true,
            }
            attachControls(controls, body, Group.Elements)

            for key, value in pairs(controls) do
                if type(value) == "function" and Group[key] == nil then
                    Group[key] = value
                end
            end

            function Group:SetCollapsed(value)
                if groupConfig.Collapsible == false then
                    return
                end

                self.Collapsed = value and true or false
                body.Visible = not self.Collapsed

                if chevron then
                    if chevron:IsA("ImageLabel") then
                        chevron.Rotation = self.Collapsed and -90 or 0
                    elseif chevron:IsA("TextLabel") then
                        chevron.Text = self.Collapsed and "›" or "⌄"
                    end
                end
            end

            function Group:ToggleCollapsed()
                self:SetCollapsed(not self.Collapsed)
            end

            collapse.Activated:Connect(function()
                Group:ToggleCollapsed()
            end)

            table.insert(Tab.Groups, Group)
            return Group
        end

        table.insert(Window.Tabs, Tab)

        if #Window.Tabs == 1 then
            Tab:Show()
        end

        return Tab
    end

    return Window
end


--// compatibility aliases
-- These keep the new implementation fresh while making source migration easier.
Library.Create = Library.CreateWindow

return Library
