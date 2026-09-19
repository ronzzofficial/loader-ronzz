--[[
    ZANJI UI LIBRARY
    Fresh standalone Roblox UI library.

    Main design goals:
    - Dark compact UI
    - Rounded "card" containers so related controls stay together
    - Searchable dropdown modal
    - Built-in All / None buttons for Multi dropdowns
    - No external Select All / Clear buttons required
    - No divider required just to show which controls belong together

    Example:
        local Library = loadstring(game:HttpGet("RAW_URL_HERE"))()

        local Window = Library:CreateWindow({
            Title = "ZANJI HUB",
            Subtitle = "Grow a Garden"
        })

        local Gears = Window:AddTab("Gears")
        local GearGroup = Gears:AddGroup("Gears")
        local GearCard = GearGroup:AddCard()

        GearCard:AddDropdown("GearItems", {
            Text = "Items to buy",
            Values = {"Trowel", "Watering Can", "Recall Wrench"},
            Multi = true,
            Searchable = true,
            BulkActions = true,
            Callback = function(values)
                print("Selected:", table.concat(values, ", "))
            end
        })

        GearCard:AddToggle("AutoBuyGears", {
            Text = "Auto Buy Gears",
            Default = false
        })
]]

local Library = {}

--// services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

--// helpers
local LocalPlayer = Players.LocalPlayer

local function safeParent()
    local ok, hui = pcall(function()
        if type(gethui) == "function" then
            return gethui()
        end
    end)

    if ok and hui then
        return hui
    end

    local ok2, cg = pcall(function()
        return CoreGui
    end)

    if ok2 and cg then
        return cg
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
    local obj = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    return obj
end

local function corner(parent, radius)
    local c = new("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    })
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    })
    s.Parent = parent
    return s
end

local function padding(parent, l, r, t, b)
    local p = new("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0)
    })
    p.Parent = parent
    return p
end

local function list(parent, gap, align)
    local l = new("UIListLayout", {
        Padding = UDim.new(0, gap or 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left
    })
    l.Parent = parent
    return l
end

local function tween(obj, time, props)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function connectHover(button, normal, hover)
    button.MouseEnter:Connect(function()
        tween(button, 0.12, {BackgroundColor3 = hover})
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.12, {BackgroundColor3 = normal})
    end)
end

local function disconnectAll(listeners)
    for _, c in ipairs(listeners) do
        pcall(function()
            c:Disconnect()
        end)
    end
    table.clear(listeners)
end

local function shallowCopy(t)
    local out = {}
    for k, v in pairs(t or {}) do
        out[k] = v
    end
    return out
end

local function arrayCopy(t)
    local out = {}
    for i, v in ipairs(t or {}) do
        out[i] = v
    end
    return out
end

local function findArrayValue(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
end

local function asDisplay(entry)
    if type(entry) == "table" then
        return tostring(entry.Name or entry.Text or entry.Value or entry[1] or "Item")
    end
    return tostring(entry)
end

local function asSearchText(entry)
    if type(entry) == "table" then
        return string.lower(tostring(
            entry.SearchText
            or ((entry.Name or entry.Text or entry.Value or entry[1] or "") .. " " .. (entry.Subtext or ""))
        ))
    end
    return string.lower(tostring(entry))
end

local function normalizeMultiSelection(values, selected)
    local result = {}
    if type(selected) ~= "table" then
        return result
    end

    -- supports {"A","B"} and {A=true,B=true}
    for k, v in pairs(selected) do
        if type(k) == "number" then
            result[v] = true
        elseif v then
            result[k] = true
        end
    end

    local cleaned = {}
    for _, entry in ipairs(values) do
        local name = asDisplay(entry)
        if result[name] or result[entry] then
            cleaned[name] = true
        end
    end
    return cleaned
end

local function selectedArray(values, selectedMap)
    local out = {}
    for _, entry in ipairs(values) do
        local name = asDisplay(entry)
        if selectedMap[name] then
            table.insert(out, name)
        end
    end
    return out
end

--// theme
Library.Theme = {
    Background = Color3.fromRGB(10, 10, 11),
    Window = Color3.fromRGB(14, 14, 15),
    Header = Color3.fromRGB(17, 17, 18),
    Sidebar = Color3.fromRGB(12, 12, 13),

    Group = Color3.fromRGB(16, 16, 17),
    Card = Color3.fromRGB(28, 28, 29),
    CardHover = Color3.fromRGB(32, 32, 34),
    Control = Color3.fromRGB(21, 21, 22),
    ControlHover = Color3.fromRGB(26, 26, 28),
    Row = Color3.fromRGB(25, 25, 26),
    RowHover = Color3.fromRGB(30, 30, 32),

    Border = Color3.fromRGB(50, 50, 52),
    BorderSoft = Color3.fromRGB(39, 39, 41),

    Text = Color3.fromRGB(239, 239, 242),
    TextMuted = Color3.fromRGB(148, 148, 158),
    TextDim = Color3.fromRGB(104, 104, 112),

    Accent = Color3.fromRGB(111, 69, 255),
    AccentHover = Color3.fromRGB(127, 89, 255),
    AccentSoft = Color3.fromRGB(72, 48, 150),

    Cyan = Color3.fromRGB(76, 211, 235),
    Pink = Color3.fromRGB(235, 120, 192),
    Success = Color3.fromRGB(97, 214, 143),
    Danger = Color3.fromRGB(231, 93, 93),
}

local Theme = Library.Theme

--// root
local gui = new("ScreenGui", {
    Name = "ZANJI_UI_" .. tostring(math.random(100000, 999999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100000
})
protect(gui)
gui.Parent = safeParent()

Library.Gui = gui
Library.Flags = {}
Library.Options = {}
Library.Connections = {}
Library.OpenDropdown = nil

function Library:SetTheme(theme)
    for k, v in pairs(theme or {}) do
        if Theme[k] ~= nil then
            Theme[k] = v
        end
    end
end

function Library:Destroy()
    if Library.OpenDropdown and Library.OpenDropdown.Close then
        pcall(Library.OpenDropdown.Close)
    end
    disconnectAll(Library.Connections)
    pcall(function()
        gui:Destroy()
    end)
end

function Library:Notify(text, duration)
    duration = duration or 2.5

    local holder = gui:FindFirstChild("NotificationHolder")
    if not holder then
        holder = new("Frame", {
            Name = "NotificationHolder",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.new(0, 310, 1, -36),
            ZIndex = 500
        })
        holder.Parent = gui

        local layout = new("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right
        })
        layout.Parent = holder
    end

    local card = new("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 501
    })
    corner(card, 9)
    stroke(card, Theme.BorderSoft, 1, 0)
    padding(card, 12, 12, 10, 10)
    card.Parent = holder

    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text),
        TextColor3 = Theme.Text,
        Font = Enum.Font.Code,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = 502
    })
    label.Parent = card

    task.delay(duration, function()
        if card and card.Parent then
            tween(card, 0.18, {BackgroundTransparency = 1})
            tween(label, 0.18, {TextTransparency = 1})
            task.wait(0.2)
            pcall(function() card:Destroy() end)
        end
    end)
end

--// draggable helper
local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPos
    local dragInput

    table.insert(Library.Connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            local ended
            ended = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if ended then ended:Disconnect() end
                end
            end)
        end
    end))

    table.insert(Library.Connections, handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

--// popup dropdown
local function createDropdownPopup(option)
    if Library.OpenDropdown and Library.OpenDropdown ~= option then
        pcall(Library.OpenDropdown.Close)
    end

    local overlay = new("TextButton", {
        Name = "DropdownOverlay",
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.42,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 200
    })
    overlay.Parent = gui

    local modal = new("Frame", {
        BackgroundColor3 = Theme.Window,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 560, 0, 445),
        ZIndex = 201
    })
    corner(modal, 12)
    stroke(modal, Theme.Border, 1, 0)
    modal.Parent = overlay

    local sizeConstraint = new("UISizeConstraint", {
        MinSize = Vector2.new(360, 300),
        MaxSize = Vector2.new(700, 620)
    })
    sizeConstraint.Parent = modal

    local header = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 12),
        Size = UDim2.new(1, -32, 0, 40),
        ZIndex = 202
    })
    header.Parent = modal

    local title = new("TextLabel", {
        BackgroundTransparency = 1,
        Text = option.PopupTitle or option.Text or "Select items",
        TextColor3 = Theme.Text,
        Font = Enum.Font.Code,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -120, 1, 0),
        ZIndex = 203
    })
    title.Parent = header

    local done = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Accent,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 110, 0, 36),
        Text = "Done",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Code,
        TextSize = 14,
        ZIndex = 203
    })
    corner(done, 8)
    connectHover(done, Theme.Accent, Theme.AccentHover)
    done.Parent = header

    local body = new("Frame", {
        BackgroundColor3 = Theme.Group,
        Position = UDim2.new(0, 16, 0, 60),
        Size = UDim2.new(1, -32, 1, -76),
        ZIndex = 202
    })
    corner(body, 10)
    stroke(body, Theme.BorderSoft, 1, 0)
    body.Parent = modal

    local toolbar = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 12),
        Size = UDim2.new(1, -28, 0, 42),
        ZIndex = 203
    })
    toolbar.Parent = body

    local showBulk = option.Multi and option.BulkActions ~= false
    local rightWidth = showBulk and 116 or 0

    local search = new("TextBox", {
        BackgroundColor3 = Theme.Background,
        ClearTextOnFocus = false,
        PlaceholderText = "Search items...",
        PlaceholderColor3 = Theme.TextDim,
        Text = "",
        TextColor3 = Theme.Text,
        Font = Enum.Font.Code,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -(rightWidth + (showBulk and 10 or 0)), 1, 0),
        ZIndex = 204
    })
    corner(search, 8)
    stroke(search, Theme.BorderSoft, 1, 0)
    padding(search, 12, 10, 0, 0)
    search.Parent = toolbar

    local allButton
    local noneButton

    if showBulk then
        local bulk = new("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, rightWidth, 1, 0),
            ZIndex = 204
        })
        bulk.Parent = toolbar

        local bulkLayout = new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        bulkLayout.Parent = bulk

        allButton = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Control,
            Size = UDim2.new(0, 55, 0, 28),
            Text = "All",
            TextColor3 = Theme.Text,
            Font = Enum.Font.Code,
            TextSize = 12,
            LayoutOrder = 1,
            ZIndex = 205
        })
        corner(allButton, 7)
        stroke(allButton, Theme.BorderSoft, 1, 0)
        connectHover(allButton, Theme.Control, Theme.ControlHover)
        allButton.Parent = bulk

        noneButton = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Control,
            Size = UDim2.new(0, 55, 0, 28),
            Text = "None",
            TextColor3 = Theme.Text,
            Font = Enum.Font.Code,
            TextSize = 12,
            LayoutOrder = 2,
            ZIndex = 205
        })
        corner(noneButton, 7)
        stroke(noneButton, Theme.BorderSoft, 1, 0)
        connectHover(noneButton, Theme.Control, Theme.ControlHover)
        noneButton.Parent = bulk
    end

    local listFrame = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 64),
        Size = UDim2.new(1, -28, 1, -78),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Border,
        ZIndex = 203
    })
    listFrame.Parent = body
    padding(listFrame, 0, 4, 0, 2)

    local rowsLayout = new("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    rowsLayout.Parent = listFrame

    local rowObjects = {}

    local function updateRowVisual(rowInfo)
        local selected = false
        if option.Multi then
            selected = option.Selected[rowInfo.Name] == true
        else
            selected = option.Selected == rowInfo.Name
        end

        if selected then
            tween(rowInfo.Button, 0.1, {BackgroundColor3 = Theme.AccentSoft})
            rowInfo.Check.Text = "✓"
            rowInfo.Check.TextColor3 = Theme.Text
            rowInfo.Check.BackgroundColor3 = Theme.Accent
        else
            tween(rowInfo.Button, 0.1, {BackgroundColor3 = Theme.Row})
            rowInfo.Check.Text = ""
            rowInfo.Check.BackgroundColor3 = Theme.Control
        end
    end

    local function refreshRows()
        for _, info in ipairs(rowObjects) do
            pcall(function() info.Button:Destroy() end)
        end
        table.clear(rowObjects)

        local query = string.lower(search.Text or "")

        for index, entry in ipairs(option.Values) do
            local name = asDisplay(entry)
            local hay = asSearchText(entry)

            if query == "" or string.find(hay, query, 1, true) then
                local row = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Row,
                    Size = UDim2.new(1, 0, 0, option.RowHeight or 40),
                    Text = "",
                    LayoutOrder = index,
                    ZIndex = 204
                })
                corner(row, 7)
                row.Parent = listFrame

                local check = new("TextLabel", {
                    BackgroundColor3 = Theme.Control,
                    Position = UDim2.new(0, 9, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16),
                    Text = "",
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Code,
                    TextSize = 12,
                    ZIndex = 205
                })
                corner(check, 5)
                stroke(check, Theme.BorderSoft, 1, 0)
                check.Parent = row

                local rowText = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 36, 0, 0),
                    Size = UDim2.new(1, -46, 1, 0),
                    Text = "",
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Code,
                    TextSize = 14,
                    RichText = option.RichText == true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 205
                })

                if type(option.Format) == "function" then
                    local ok, formatted = pcall(option.Format, entry, index)
                    rowText.Text = ok and tostring(formatted) or name
                elseif type(entry) == "table" and entry.Subtext then
                    rowText.Text = name .. "  " .. tostring(entry.Subtext)
                else
                    rowText.Text = name
                end
                rowText.Parent = row

                local info = {
                    Button = row,
                    Check = check,
                    Name = name,
                    Entry = entry
                }
                table.insert(rowObjects, info)
                updateRowVisual(info)

                connectHover(row,
                    (option.Multi and option.Selected[name]) or (not option.Multi and option.Selected == name)
                        and Theme.AccentSoft or Theme.Row,
                    Theme.RowHover
                )

                row.Activated:Connect(function()
                    if option.Multi then
                        option.Selected[name] = not option.Selected[name]
                        updateRowVisual(info)
                        option:_sync()
                    else
                        option.Selected = name
                        for _, other in ipairs(rowObjects) do
                            updateRowVisual(other)
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

    function option:Close()
        if self.Popup then
            pcall(function() self.Popup:Destroy() end)
            self.Popup = nil
        end
        if Library.OpenDropdown == self then
            Library.OpenDropdown = nil
        end
        self:_sync()
    end

    done.Activated:Connect(function()
        option:Close()
    end)

    overlay.Activated:Connect(function()
        option:Close()
    end)

    modal.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            -- swallow through modal descendants naturally
        end
    end)

    search:GetPropertyChangedSignal("Text"):Connect(refreshRows)

    if allButton then
        allButton.Activated:Connect(function()
            for _, entry in ipairs(option.Values) do
                option.Selected[asDisplay(entry)] = true
            end
            for _, info in ipairs(rowObjects) do
                updateRowVisual(info)
            end
            option:_sync()
        end)
    end

    if noneButton then
        noneButton.Activated:Connect(function()
            table.clear(option.Selected)
            for _, info in ipairs(rowObjects) do
                updateRowVisual(info)
            end
            option:_sync()
        end)
    end

    refreshRows()
    Library.OpenDropdown = option

    task.defer(function()
        if option.Searchable ~= false then
            search:CaptureFocus()
        end
    end)
end

--// window
function Library:CreateWindow(config)
    config = config or {}

    local Window = {
        Tabs = {},
        ActiveTab = nil
    }

    local main = new("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Window,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position or UDim2.fromScale(0.5, 0.5),
        Size = config.Size or UDim2.new(0, 720, 0, 520),
        ClipsDescendants = true
    })
    corner(main, 10)
    stroke(main, Theme.Border, 1, 0)
    main.Parent = gui
    Window.Frame = main

    local scale = new("UIScale", {Scale = config.Scale or 1})
    scale.Parent = main
    Window.Scale = scale

    local header = new("Frame", {
        BackgroundColor3 = Theme.Header,
        Size = UDim2.new(1, 0, 0, 44)
    })
    header.Parent = main

    local title = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -110, 1, 0),
        Text = config.Title or "ZANJI HUB",
        TextColor3 = Theme.Text,
        Font = Enum.Font.Code,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    title.Parent = header

    local subtitleText = config.Subtitle
    if subtitleText and subtitleText ~= "" then
        title.Size = UDim2.new(0.55, -14, 1, 0)

        local subtitle = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.55, 0, 0, 0),
            Size = UDim2.new(0.45, -100, 1, 0),
            Text = tostring(subtitleText),
            TextColor3 = Theme.TextMuted,
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        subtitle.Parent = header
    end

    local minimize = new("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -42, 0.5, 0),
        Size = UDim2.new(0, 34, 0, 34),
        Text = "—",
        TextColor3 = Theme.TextMuted,
        Font = Enum.Font.Code,
        TextSize = 18
    })
    minimize.Parent = header

    local close = new("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 34, 0, 34),
        Text = "×",
        TextColor3 = Theme.TextMuted,
        Font = Enum.Font.Code,
        TextSize = 20
    })
    close.Parent = header

    local sidebarWidth = config.SidebarWidth or 140

    local sidebar = new("Frame", {
        BackgroundColor3 = Theme.Sidebar,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, sidebarWidth, 1, -44)
    })
    sidebar.Parent = main
    padding(sidebar, 8, 8, 8, 8)

    local sidebarLayout = new("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    sidebarLayout.Parent = sidebar

    local content = new("Frame", {
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0, sidebarWidth, 0, 44),
        Size = UDim2.new(1, -sidebarWidth, 1, -44),
        ClipsDescendants = true
    })
    content.Parent = main

    makeDraggable(header, main)

    local minimized = false
    local oldSize = main.Size

    minimize.Activated:Connect(function()
        minimized = not minimized
        if minimized then
            oldSize = main.Size
            tween(main, 0.18, {Size = UDim2.new(oldSize.X.Scale, oldSize.X.Offset, 0, 44)})
        else
            tween(main, 0.18, {Size = oldSize})
        end
    end)

    close.Activated:Connect(function()
        Library:Destroy()
    end)

    function Window:SetVisible(value)
        main.Visible = value and true or false
    end

    function Window:SetScale(value)
        scale.Scale = tonumber(value) or 1
    end

    function Window:AddTab(name, icon)
        local Tab = {
            Name = tostring(name),
            Groups = {}
        }

        local tabButton = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Sidebar,
            Size = UDim2.new(1, 0, 0, 34),
            Text = "",
            LayoutOrder = #Window.Tabs + 1
        })
        corner(tabButton, 7)
        tabButton.Parent = sidebar

        local tabText = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Text = ((icon and tostring(icon) .. "  ") or "") .. tostring(name),
            TextColor3 = Theme.TextMuted,
            Font = Enum.Font.Code,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        tabText.Parent = tabButton

        local page = new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border
        })
        padding(page, 10, 10, 10, 10)
        page.Parent = content

        local pageLayout = new("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        pageLayout.Parent = page

        Tab.Button = tabButton
        Tab.Text = tabText
        Tab.Page = page

        function Tab:Show()
            for _, other in ipairs(Window.Tabs) do
                other.Page.Visible = false
                other.Button.BackgroundColor3 = Theme.Sidebar
                other.Text.TextColor3 = Theme.TextMuted
            end
            self.Page.Visible = true
            self.Button.BackgroundColor3 = Theme.Control
            self.Text.TextColor3 = Theme.Text
            Window.ActiveTab = self
        end

        tabButton.Activated:Connect(function()
            Tab:Show()
        end)

        function Tab:AddGroup(groupName, groupIcon)
            local Group = {}

            local group = new("Frame", {
                BackgroundColor3 = Theme.Group,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = #Tab.Groups + 1
            })
            corner(group, 8)
            stroke(group, Theme.BorderSoft, 1, 0)
            padding(group, 7, 7, 7, 7)
            group.Parent = page

            local groupLayout = new("UIListLayout", {
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            groupLayout.Parent = group

            if groupName and groupName ~= "" then
                local groupHeader = new("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 26),
                    LayoutOrder = 1
                })
                groupHeader.Parent = group

                local groupTitle = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = ((groupIcon and tostring(groupIcon) .. "  ") or "") .. tostring(groupName),
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.Code,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                groupTitle.Parent = groupHeader
            end

            Group.Frame = group
            Group._nextOrder = 10

            function Group:AddCard(cardConfig)
                cardConfig = cardConfig or {}
                local Card = {}
                Group._nextOrder += 1

                local card = new("Frame", {
                    BackgroundColor3 = Theme.Card,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = Group._nextOrder
                })
                corner(card, cardConfig.Radius or 9)
                stroke(card, Theme.BorderSoft, 1, 0)
                padding(card, 7, 7, 7, 7)
                card.Parent = group

                local cardLayout = new("UIListLayout", {
                    Padding = UDim.new(0, cardConfig.Gap or 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                cardLayout.Parent = card

                Card.Frame = card
                Card._nextOrder = 0

                if cardConfig.Title then
                    Card._nextOrder += 1
                    local cTitle = new("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = tostring(cardConfig.Title),
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = Card._nextOrder
                    })
                    padding(cTitle, 5, 5, 0, 0)
                    cTitle.Parent = card
                end

                local function addControlFrame(height)
                    Card._nextOrder += 1
                    local frame = new("Frame", {
                        BackgroundColor3 = Theme.Control,
                        Size = UDim2.new(1, 0, 0, height),
                        LayoutOrder = Card._nextOrder
                    })
                    corner(frame, 7)
                    frame.Parent = card
                    return frame
                end

                function Card:AddLabel(text, config)
                    config = config or {}
                    Card._nextOrder += 1

                    local label = new("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, config.Height or 26),
                        Text = tostring(text or ""),
                        TextColor3 = config.Color or Theme.TextMuted,
                        Font = Enum.Font.Code,
                        TextSize = config.TextSize or 13,
                        TextWrapped = config.Wrap == true,
                        RichText = config.RichText == true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = Card._nextOrder
                    })
                    padding(label, 6, 6, 0, 0)
                    label.Parent = card

                    local obj = {}
                    function obj:SetText(v) label.Text = tostring(v) end
                    function obj:SetColor(v) label.TextColor3 = v end
                    obj.Instance = label
                    return obj
                end

                function Card:AddDivider()
                    Card._nextOrder += 1
                    local line = new("Frame", {
                        BackgroundColor3 = Theme.BorderSoft,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, -10, 0, 1),
                        LayoutOrder = Card._nextOrder
                    })
                    line.Parent = card
                    return line
                end

                function Card:AddButton(config2)
                    if type(config2) == "string" then
                        config2 = {Text = config2}
                    end
                    config2 = config2 or {}

                    local frame = addControlFrame(config2.Height or 36)
                    local button = new("TextButton", {
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Text = config2.Text or "Button",
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 13
                    })
                    button.Parent = frame

                    connectHover(frame, Theme.Control, Theme.ControlHover)

                    button.Activated:Connect(function()
                        if type(config2.Callback) == "function" then
                            task.spawn(config2.Callback)
                        end
                    end)

                    return {
                        Instance = frame,
                        Button = button
                    }
                end

                function Card:AddToggle(flag, config2)
                    config2 = config2 or {}
                    local frame = addControlFrame(config2.Height or 38)

                    local label = new("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 0),
                        Size = UDim2.new(1, -58, 1, 0),
                        Text = config2.Text or tostring(flag),
                        TextColor3 = Theme.TextMuted,
                        Font = Enum.Font.Code,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    label.Parent = frame

                    local track = new("Frame", {
                        BackgroundColor3 = Theme.Background,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -10, 0.5, 0),
                        Size = UDim2.new(0, 32, 0, 18)
                    })
                    corner(track, 9)
                    track.Parent = frame

                    local knob = new("Frame", {
                        BackgroundColor3 = Theme.Text,
                        Position = UDim2.new(0, 3, 0.5, -6),
                        Size = UDim2.new(0, 12, 0, 12)
                    })
                    corner(knob, 6)
                    knob.Parent = track

                    local hit = new("TextButton", {
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Text = ""
                    })
                    hit.Parent = frame

                    local Toggle = {
                        Value = config2.Default == true,
                        Flag = flag
                    }

                    local function render()
                        if Toggle.Value then
                            tween(track, 0.12, {BackgroundColor3 = Theme.Accent})
                            tween(knob, 0.12, {Position = UDim2.new(1, -15, 0.5, -6)})
                            label.TextColor3 = Theme.Text
                        else
                            tween(track, 0.12, {BackgroundColor3 = Theme.Background})
                            tween(knob, 0.12, {Position = UDim2.new(0, 3, 0.5, -6)})
                            label.TextColor3 = Theme.TextMuted
                        end
                    end

                    function Toggle:SetValue(value, silent)
                        self.Value = value and true or false
                        Library.Flags[flag] = self.Value
                        render()
                        if not silent and type(config2.Callback) == "function" then
                            task.spawn(config2.Callback, self.Value)
                        end
                    end

                    function Toggle:GetValue()
                        return self.Value
                    end

                    hit.Activated:Connect(function()
                        Toggle:SetValue(not Toggle.Value)
                    end)

                    Library.Options[flag] = Toggle
                    Toggle:SetValue(Toggle.Value, true)
                    return Toggle
                end

                function Card:AddInput(flag, config2)
                    config2 = config2 or {}
                    local frame = addControlFrame(config2.Height or 58)

                    local label = new("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 5),
                        Size = UDim2.new(1, -20, 0, 18),
                        Text = config2.Text or tostring(flag),
                        TextColor3 = Theme.TextMuted,
                        Font = Enum.Font.Code,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    label.Parent = frame

                    local input = new("TextBox", {
                        BackgroundColor3 = Theme.Background,
                        Position = UDim2.new(0, 8, 0, 25),
                        Size = UDim2.new(1, -16, 0, 27),
                        Text = tostring(config2.Default or ""),
                        PlaceholderText = config2.Placeholder or "",
                        PlaceholderColor3 = Theme.TextDim,
                        TextColor3 = Theme.Text,
                        ClearTextOnFocus = false,
                        Font = Enum.Font.Code,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    corner(input, 6)
                    stroke(input, Theme.BorderSoft, 1, 0)
                    padding(input, 8, 8, 0, 0)
                    input.Parent = frame

                    local Input = {
                        Value = input.Text,
                        Flag = flag
                    }

                    function Input:SetValue(v, silent)
                        self.Value = tostring(v or "")
                        input.Text = self.Value
                        Library.Flags[flag] = self.Value
                        if not silent and type(config2.Callback) == "function" then
                            task.spawn(config2.Callback, self.Value)
                        end
                    end

                    function Input:GetValue()
                        return self.Value
                    end

                    input.FocusLost:Connect(function(enterPressed)
                        Input.Value = input.Text
                        Library.Flags[flag] = Input.Value
                        if type(config2.Callback) == "function" then
                            task.spawn(config2.Callback, Input.Value, enterPressed)
                        end
                    end)

                    Library.Options[flag] = Input
                    Input:SetValue(Input.Value, true)
                    return Input
                end

                function Card:AddSlider(flag, config2)
                    config2 = config2 or {}

                    local min = tonumber(config2.Min) or 0
                    local max = tonumber(config2.Max) or 100
                    local rounding = tonumber(config2.Rounding) or 0
                    if max <= min then max = min + 1 end

                    local frame = addControlFrame(config2.Height or 58)

                    local label = new("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 5),
                        Size = UDim2.new(0.7, -10, 0, 18),
                        Text = config2.Text or tostring(flag),
                        TextColor3 = Theme.TextMuted,
                        Font = Enum.Font.Code,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    label.Parent = frame

                    local valueLabel = new("TextLabel", {
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, -10, 0, 5),
                        Size = UDim2.new(0.3, 0, 0, 18),
                        Text = "",
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Right
                    })
                    valueLabel.Parent = frame

                    local bar = new("Frame", {
                        BackgroundColor3 = Theme.Background,
                        Position = UDim2.new(0, 10, 0, 35),
                        Size = UDim2.new(1, -20, 0, 8)
                    })
                    corner(bar, 4)
                    bar.Parent = frame

                    local fill = new("Frame", {
                        BackgroundColor3 = Theme.Accent,
                        Size = UDim2.new(0, 0, 1, 0)
                    })
                    corner(fill, 4)
                    fill.Parent = bar

                    local hit = new("TextButton", {
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, -4, 0, -8),
                        Size = UDim2.new(1, 8, 1, 16),
                        Text = ""
                    })
                    hit.Parent = bar

                    local Slider = {
                        Value = tonumber(config2.Default) or min,
                        Flag = flag
                    }

                    local function round(n)
                        if rounding <= 0 then
                            return math.floor(n + 0.5)
                        end
                        local p = 10 ^ rounding
                        return math.floor(n * p + 0.5) / p
                    end

                    function Slider:SetValue(v, silent)
                        v = math.clamp(tonumber(v) or min, min, max)
                        v = round(v)
                        self.Value = v
                        Library.Flags[flag] = v

                        local alpha = (v - min) / (max - min)
                        tween(fill, 0.08, {Size = UDim2.new(alpha, 0, 1, 0)})
                        valueLabel.Text = tostring(v) .. (config2.Suffix or "")

                        if not silent and type(config2.Callback) == "function" then
                            task.spawn(config2.Callback, v)
                        end
                    end

                    function Slider:GetValue()
                        return self.Value
                    end

                    local sliding = false

                    local function updateFromX(x)
                        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                        Slider:SetValue(min + (max - min) * alpha)
                    end

                    hit.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            sliding = true
                            updateFromX(input.Position.X)
                        end
                    end)

                    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
                        if sliding and (
                            input.UserInputType == Enum.UserInputType.MouseMovement
                            or input.UserInputType == Enum.UserInputType.Touch
                        ) then
                            updateFromX(input.Position.X)
                        end
                    end))

                    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            sliding = false
                        end
                    end))

                    Library.Options[flag] = Slider
                    Slider:SetValue(Slider.Value, true)
                    return Slider
                end

                function Card:AddDropdown(flag, config2)
                    config2 = config2 or {}

                    local frame = addControlFrame(config2.Height or 64)

                    local label = new("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 5),
                        Size = UDim2.new(1, -20, 0, 18),
                        Text = config2.Text or tostring(flag),
                        TextColor3 = Theme.Text,
                        Font = Enum.Font.Code,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    label.Parent = frame

                    local selectButton = new("TextButton", {
                        AutoButtonColor = false,
                        BackgroundColor3 = Theme.Background,
                        Position = UDim2.new(0, 8, 0, 27),
                        Size = UDim2.new(1, -16, 0, 30),
                        Text = "",
                        ZIndex = 2
                    })
                    corner(selectButton, 7)
                    stroke(selectButton, Theme.BorderSoft, 1, 0)
                    connectHover(selectButton, Theme.Background, Theme.ControlHover)
                    selectButton.Parent = frame

                    local valueText = new("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 0),
                        Size = UDim2.new(1, -38, 1, 0),
                        Text = "---",
                        TextColor3 = Theme.TextMuted,
                        Font = Enum.Font.Code,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 3
                    })
                    valueText.Parent = selectButton

                    local arrow = new("TextLabel", {
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.new(0, 20, 1, 0),
                        Text = "⌄",
                        TextColor3 = Theme.TextMuted,
                        Font = Enum.Font.Code,
                        TextSize = 16,
                        ZIndex = 3
                    })
                    arrow.Parent = selectButton

                    local Dropdown = {
                        Flag = flag,
                        Text = config2.Text or tostring(flag),
                        PopupTitle = config2.PopupTitle or config2.Text or tostring(flag),
                        Values = arrayCopy(config2.Values or {}),
                        Multi = config2.Multi == true,
                        Searchable = config2.Searchable ~= false,
                        BulkActions = config2.BulkActions ~= false,
                        CloseOnSelect = config2.CloseOnSelect,
                        Format = config2.Format,
                        RichText = config2.RichText == true,
                        RowHeight = config2.RowHeight,
                        Popup = nil
                    }

                    if Dropdown.Multi then
                        Dropdown.Selected = normalizeMultiSelection(Dropdown.Values, config2.Default or {})
                    else
                        Dropdown.Selected = config2.Default
                        if Dropdown.Selected ~= nil then
                            Dropdown.Selected = tostring(Dropdown.Selected)
                        end
                    end

                    function Dropdown:_sync(silent)
                        if self.Multi then
                            local arr = selectedArray(self.Values, self.Selected)
                            Library.Flags[flag] = arr

                            if #arr == 0 then
                                valueText.Text = "---"
                                valueText.TextColor3 = Theme.TextMuted
                            elseif #arr <= (config2.MaxPreview or 2) then
                                valueText.Text = table.concat(arr, ", ")
                                valueText.TextColor3 = Theme.Text
                            else
                                valueText.Text = tostring(#arr) .. " selected"
                                valueText.TextColor3 = Theme.Text
                            end

                            if not silent and type(config2.Callback) == "function" then
                                task.spawn(config2.Callback, arrayCopy(arr))
                            end
                        else
                            Library.Flags[flag] = self.Selected

                            if self.Selected == nil or self.Selected == "" then
                                valueText.Text = "---"
                                valueText.TextColor3 = Theme.TextMuted
                            else
                                valueText.Text = tostring(self.Selected)
                                valueText.TextColor3 = Theme.Text
                            end

                            if not silent and type(config2.Callback) == "function" then
                                task.spawn(config2.Callback, self.Selected)
                            end
                        end
                    end

                    function Dropdown:Open()
                        createDropdownPopup(self)
                    end

                    function Dropdown:Close()
                        if self.Popup then
                            pcall(function() self.Popup:Destroy() end)
                            self.Popup = nil
                        end
                        if Library.OpenDropdown == self then
                            Library.OpenDropdown = nil
                        end
                        self:_sync()
                    end

                    function Dropdown:GetValue()
                        if self.Multi then
                            return selectedArray(self.Values, self.Selected)
                        end
                        return self.Selected
                    end

                    function Dropdown:SetValue(value, silent)
                        if self.Multi then
                            self.Selected = normalizeMultiSelection(self.Values, value or {})
                        else
                            self.Selected = value ~= nil and tostring(value) or nil
                        end
                        self:_sync(silent)
                    end

                    function Dropdown:SetValues(values, keepSelection)
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

                    function Dropdown:SelectAll()
                        if not self.Multi then return end
                        for _, entry in ipairs(self.Values) do
                            self.Selected[asDisplay(entry)] = true
                        end
                        self:_sync()
                    end

                    function Dropdown:Clear()
                        if self.Multi then
                            table.clear(self.Selected)
                        else
                            self.Selected = nil
                        end
                        self:_sync()
                    end

                    selectButton.Activated:Connect(function()
                        Dropdown:Open()
                    end)

                    Library.Options[flag] = Dropdown
                    Dropdown:_sync(true)
                    return Dropdown
                end

                return Card
            end

            -- convenience: group itself can act like one card
            function Group:AddToggle(flag, config2)
                if not self._defaultCard then
                    self._defaultCard = self:AddCard()
                end
                return self._defaultCard:AddToggle(flag, config2)
            end

            function Group:AddDropdown(flag, config2)
                if not self._defaultCard then
                    self._defaultCard = self:AddCard()
                end
                return self._defaultCard:AddDropdown(flag, config2)
            end

            function Group:AddButton(config2)
                if not self._defaultCard then
                    self._defaultCard = self:AddCard()
                end
                return self._defaultCard:AddButton(config2)
            end

            function Group:AddInput(flag, config2)
                if not self._defaultCard then
                    self._defaultCard = self:AddCard()
                end
                return self._defaultCard:AddInput(flag, config2)
            end

            function Group:AddSlider(flag, config2)
                if not self._defaultCard then
                    self._defaultCard = self:AddCard()
                end
                return self._defaultCard:AddSlider(flag, config2)
            end

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

return Library
