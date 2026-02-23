--=============================================================================--
--  ROSE UI FRAMEWORK (V3 - Windows Resizing, Animations, Premium Dropdowns)
--=============================================================================--
local RoseUI = {}
local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Design Colors (Solid, Matching aesthetic)
local HEADER_COLOR = Color3.fromRGB(220, 160, 255)
local SIDEBAR_COLOR = Color3.fromRGB(15, 12, 18)
local CONTENT_COLOR = Color3.fromRGB(15, 12, 18)
local CARD_COLOR = Color3.fromRGB(25, 20, 25)
local TEXT_COLOR = Color3.fromRGB(255, 240, 245)

local GLOBAL_ZINDEX = 1

function RoseUI:Notify(options)
    local title = options.Title or "Notification"
    local text = options.Text or ""
    local dur = options.Duration or 5

    local notifGui = coreGui:FindFirstChild("RoseUI_Notifs")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name = "RoseUI_Notifs"
        notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        notifGui.Parent = coreGui
    end

    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 250, 0, 70)
    notifFrame.Position = UDim2.new(1, 10, 1, -80)
    notifFrame.BackgroundColor3 = CARD_COLOR
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = notifGui
    Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 6)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = HEADER_COLOR
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = notifFrame

    for _, child in pairs(notifGui:GetChildren()) do
        if child:IsA("Frame") and child ~= notifFrame then
            tweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
                Position = UDim2.new(1, -260, 1, (child.Position.Y.Offset - 80))
            }):Play()
        end
    end

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 25)
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = TEXT_COLOR
    titleLbl.TextSize = 14
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = notifFrame

    local textLbl = Instance.new("TextLabel")
    textLbl.Size = UDim2.new(1, -20, 0, 35)
    textLbl.Position = UDim2.new(0, 10, 0, 30)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = text
    textLbl.TextColor3 = Color3.fromRGB(200, 180, 190)
    textLbl.TextSize = 12
    textLbl.Font = Enum.Font.Gotham
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.TextWrapped = true
    textLbl.Parent = notifFrame

    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = HEADER_COLOR
    line.BorderSizePixel = 0
    line.Parent = notifFrame

    tweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -80)}):Play()
    tweenService:Create(line, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(1, -2, 0, 2)}):Play()

    task.delay(dur, function()
        local out = tweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, notifFrame.Position.Y.Offset)})
        out:Play()
        out.Completed:Wait()
        notifFrame:Destroy()
    end)
end


function RoseUI:CreateWindow(options)
    local titleText = options.Name or "Rose Hub 🌹"
    local hubType = options.HubType or "Rose Hub"

    if coreGui:FindFirstChild("RoseUI_Window") then
        coreGui.RoseUI_Window:Destroy()
    end
    
    if coreGui:FindFirstChild("RoseUI_Notifs") then
        coreGui.RoseUI_Notifs:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RoseUI_Window"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = coreGui
    
    -- Main Container
    local dragFrame = Instance.new("Frame")
    dragFrame.Name = "DragBox"
    dragFrame.Size = UDim2.new(0, 650, 0, 450)
    local DEFAULT_SIZE = UDim2.new(0, 650, 0, 450)
    dragFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
    dragFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 18)
    dragFrame.BackgroundTransparency = 0.2 -- Glassy look
    dragFrame.Active = true
    dragFrame.Parent = screenGui
    Instance.new("UICorner", dragFrame).CornerRadius = UDim.new(0, 8)
    
    -- Custom Dragging Logic (damit Resize nicht verbuggt)
    local dragging, dragInput, dragStart, startPos
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- Nur im Header Bereich draggen lassen (Y < 45)
            local relativeY = input.Position.Y - dragFrame.AbsolutePosition.Y
            if relativeY <= 45 then
                dragging = true
                dragStart = input.Position
                startPos = dragFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            tweenService:Create(dragFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = HEADER_COLOR
    mainStroke.Transparency = 0.5
    mainStroke.Thickness = 2
    mainStroke.Parent = dragFrame
    
    -- ==========================================
    -- HEADER (Oben)
    -- ==========================================
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.Size = UDim2.new(1, 0, 0, 45)
    headerFrame.Position = UDim2.new(0, 0, 0, 0)
    headerFrame.BackgroundTransparency = 1
    headerFrame.BorderSizePixel = 0
    headerFrame.ZIndex = 5
    headerFrame.Parent = dragFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -150, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 13
    title.Font = Enum.Font.GothamMedium
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 6
    title.Parent = headerFrame
    
    -- ================= WINDOW CONTROLS =================
    local controlLayout = Instance.new("UIListLayout")
    controlLayout.FillDirection = Enum.FillDirection.Horizontal
    controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    controlLayout.Padding = UDim.new(0, 8)
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(0, 120, 1, 0)
    controlsFrame.Position = UDim2.new(1, -135, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.ZIndex = 6
    controlsFrame.Parent = headerFrame
    controlLayout.Parent = controlsFrame

    -- Helper für Controls
    local function createControlBtn(icon, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.BackgroundTransparency = 1
        btn.Text = icon
        btn.TextColor3 = Color3.fromRGB(255, 180, 190)
        btn.TextSize = 18
        btn.Font = Enum.Font.GothamBold
        btn.LayoutOrder = order
        btn.ZIndex = 6
        btn.Parent = controlsFrame
        
        btn.MouseEnter:Connect(function() tweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
        btn.MouseLeave:Connect(function() tweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 180, 190)}):Play() end)
        return btn
    end

    local minBtn = createControlBtn("-", 1)
    local maxBtn = createControlBtn("□", 2)
    local closeBtn = createControlBtn("X", 3)
    closeBtn.TextSize = 16

    local isMinimized = false
    local isMaximized = false
    local preMaxSize = DEFAULT_SIZE
    local preMaxPos = UDim2.new(0.5, -325, 0.5, -225)

    -- Container für Alles was nicht Header ist (zum Ein/Ausblenden bei Mini)
    local bodyContainer = Instance.new("Frame")
    bodyContainer.Name = "Body"
    bodyContainer.Size = UDim2.new(1, 0, 1, -45)
    bodyContainer.Position = UDim2.new(0, 0, 0, 45)
    bodyContainer.BackgroundTransparency = 1
    bodyContainer.ZIndex = 1
    bodyContainer.Parent = dragFrame
    bodyContainer.ClipsDescendants = true

    -- Minimize / Toggle Logic
    local function ToggleUI()
        screenGui.Enabled = not screenGui.Enabled
        if not screenGui.Enabled then
            RoseUI:Notify({Title = "🌹 Hub Minimized", Text = "Press Right Alt to reopen the Hub.", Duration = 4})
        end
    end
    
    minBtn.MouseButton1Click:Connect(ToggleUI)
    
    local inputConnection
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightAlt then
            -- Verhindert Bug bei Script Re-Execution, indem Ghost-Events sterben
            if not screenGui or not screenGui.Parent then
                if inputConnection then inputConnection:Disconnect() end
                return
            end
            ToggleUI()
        end
    end)


    maxBtn.MouseButton1Click:Connect(function()
        if isMinimized then return end -- Geht nicht auswährend mini
        isMaximized = not isMaximized
        if isMaximized then
            preMaxSize = dragFrame.Size
            preMaxPos = dragFrame.Position
            tweenService:Create(dragFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = DEFAULT_SIZE,
                Position = UDim2.new(0.5, -DEFAULT_SIZE.X.Offset/2, 0.5, -DEFAULT_SIZE.Y.Offset/2)
            }):Play()
        else
            tweenService:Create(dragFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = preMaxSize,
                Position = preMaxPos
            }):Play()
        end
    end)

    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    -- ================= RESIZE LOGIC =================
    local function createResizeGrip(name, size, pos, cursorX, cursorY, iconName)
        local grip = Instance.new("TextButton")
        grip.Name = name
        grip.Size = size
        grip.Position = pos
        grip.BackgroundTransparency = 1
        grip.Text = ""
        grip.ZIndex = 50
        grip.Parent = dragFrame
        
        local isGrabbing = false
        local startSize, startPos

        grip.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isGrabbing = true
                isMaximized = false
                startSize = dragFrame.Size
                startPos = input.Position
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isGrabbing = false
                UserInputService.MouseIconEnabled = true
                UserInputService.MouseIcon = ""
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if isGrabbing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - startPos
                local newX = startSize.X.Offset + (cursorX and delta.X or 0)
                local newY = startSize.Y.Offset + (cursorY and delta.Y or 0)
                dragFrame.Size = UDim2.new(0, math.clamp(newX, 450, 1200), 0, math.clamp(newY, 300, 1000))
            end
        end)

        grip.MouseEnter:Connect(function()
            if not isGrabbing then
                UserInputService.MouseIcon = iconName
            end
        end)
        grip.MouseLeave:Connect(function()
            if not isGrabbing then
                UserInputService.MouseIcon = ""
            end
        end)
    end

    createResizeGrip("RightGrip", UDim2.new(0, 10, 1, -20), UDim2.new(1, -5, 0, 10), true, false, "rbxasset://SystemCursors/SizeWE")
    createResizeGrip("BottomGrip", UDim2.new(1, -20, 0, 10), UDim2.new(0, 10, 1, -5), false, true, "rbxasset://SystemCursors/SizeNS")
    createResizeGrip("CornerGrip", UDim2.new(0, 20, 0, 20), UDim2.new(1, -10, 1, -10), true, true, "rbxasset://SystemCursors/SizeNWSE")


    -- ==========================================
    -- SIDEBAR (Links - Dunkles Rose)
    -- ==========================================
    local sidebarFrame = Instance.new("Frame")
    sidebarFrame.Name = "Sidebar"
    sidebarFrame.Size = UDim2.new(0, 160, 1, 0)
    sidebarFrame.Position = UDim2.new(0, 0, 0, 0)
    sidebarFrame.BackgroundTransparency = 1
    sidebarFrame.BorderSizePixel = 0
    sidebarFrame.ZIndex = 2
    sidebarFrame.Parent = bodyContainer

    local hubTypeText = Instance.new("TextLabel")
    hubTypeText.Size = UDim2.new(1, 0, 0, 30)
    hubTypeText.Position = UDim2.new(0, 0, 0, 10)
    hubTypeText.BackgroundTransparency = 1
    hubTypeText.Text = hubType
    hubTypeText.TextColor3 = Color3.fromRGB(200, 150, 170)
    hubTypeText.TextSize = 12
    hubTypeText.Font = Enum.Font.GothamSemibold
    hubTypeText.ZIndex = 3
    hubTypeText.Parent = sidebarFrame
    
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(0, 1, 1, -20)
    separator.Position = UDim2.new(1, -1, 0, 10)
    separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    separator.BackgroundTransparency = 0.9
    separator.BorderSizePixel = 0
    separator.ZIndex = 3
    separator.Parent = sidebarFrame

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(1, -10, 1, -115) -- Mehr Platz fuer das Profil unten lassen
    tabContainer.Position = UDim2.new(0, 5, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 0 
    tabContainer.ZIndex = 3
    tabContainer.Parent = sidebarFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = tabContainer
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)

    -- ==========================================
    -- USER PROFILE AREA (Sidebar Unten Links)
    -- ==========================================
    local profileFrame = Instance.new("Frame")
    profileFrame.Size = UDim2.new(1, -10, 0, 50)
    profileFrame.Position = UDim2.new(0, 5, 1, -55)
    profileFrame.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
    profileFrame.ZIndex = 3
    profileFrame.Parent = sidebarFrame
    Instance.new("UICorner", profileFrame).CornerRadius = UDim.new(0, 6)
    
    local pStroke = Instance.new("UIStroke")
    pStroke.Color = HEADER_COLOR
    pStroke.Transparency = 0.5
    pStroke.Thickness = 1
    pStroke.Parent = profileFrame

    local localPlayer = game:GetService("Players").LocalPlayer
    local pName = localPlayer and localPlayer.Name or "Guest"
    local pId = localPlayer and localPlayer.UserId or 1
    
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(0, 36, 0, 36)
    avatarImg.Position = UDim2.new(0, 7, 0.5, -18)
    avatarImg.BackgroundColor3 = Color3.fromRGB(20, 10, 15)
    avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. pId .. "&w=150&h=150"
    avatarImg.ZIndex = 4
    avatarImg.Parent = profileFrame
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -55, 0, 15)
    nameLbl.Position = UDim2.new(0, 50, 0, 10)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = pName
    nameLbl.TextColor3 = TEXT_COLOR
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 4
    nameLbl.Parent = profileFrame

    local rankLbl = Instance.new("TextLabel")
    rankLbl.Size = UDim2.new(1, -55, 0, 15)
    rankLbl.Position = UDim2.new(0, 50, 0, 25)
    rankLbl.BackgroundTransparency = 1
    rankLbl.Text = "Free User"
    rankLbl.TextColor3 = HEADER_COLOR
    rankLbl.Font = Enum.Font.Gotham
    rankLbl.TextSize = 10
    rankLbl.TextXAlignment = Enum.TextXAlignment.Left
    rankLbl.ZIndex = 4
    rankLbl.Parent = profileFrame
    
    -- ==========================================
    -- CONTENT AREA (Rechts)
    -- ==========================================
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentArea"
    contentFrame.Size = UDim2.new(1, -160, 1, 0)
    contentFrame.Position = UDim2.new(0, 160, 0, 0)
    contentFrame.BackgroundColor3 = CONTENT_COLOR
    contentFrame.BackgroundTransparency = 0.3
    contentFrame.BorderSizePixel = 0
    contentFrame.ZIndex = 1
    contentFrame.Parent = bodyContainer
    Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 8)
    
    local pageContainer = Instance.new("Frame")
    pageContainer.Size = UDim2.new(1, 0, 1, 0)
    pageContainer.Position = UDim2.new(0, 0, 0, 0)
    pageContainer.BackgroundTransparency = 1
    pageContainer.ZIndex = 10
    pageContainer.ClipsDescendants = true -- Wichtig für Slide In Animation
    pageContainer.Parent = contentFrame
    
    -- ==========================================
    -- API OBJECT & CONFIGS
    -- ==========================================
    local WindowObj = {
        CurrentTab = nil,
        Tabs = {},
        Elements = {},
        ConfigFolder = options.ConfigFolder or "RoseHubConfigs"
    }
    
    if makefolder and not isfolder(WindowObj.ConfigFolder) then
        makefolder(WindowObj.ConfigFolder)
    end
    
    function WindowObj:SaveConfig(fileName)
        local data = {}
        for _, elem in ipairs(self.Elements) do
            if elem.Type == "ColorPicker" then
                data[elem.Name] = {elem.Value.R, elem.Value.G, elem.Value.B}
            elseif elem.Type == "Keybind" then
                data[elem.Name] = elem.Value.Name
            else
                data[elem.Name] = elem.Value
            end
        end
        if writefile then
            local pcallSuccess, json = pcall(function() return HttpService:JSONEncode(data) end)
            if pcallSuccess then
                writefile(self.ConfigFolder .. "/" .. fileName .. ".json", json)
                RoseUI:Notify({Title = "🌹 Config Saved", Text = "Saved to " .. fileName .. ".json successfully.", Duration = 4})
                
                if self.ConfigRefreshListener then
                    self.ConfigRefreshListener()
                end
            end
        end
    end

    function WindowObj:LoadConfig(fileName)
        local path = self.ConfigFolder .. "/" .. fileName .. ".json"
        if readfile and isfile and isfile(path) then
            local pcallSuccess, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
            if pcallSuccess and type(data) == "table" then
                for _, elem in ipairs(self.Elements) do
                    if data[elem.Name] ~= nil then
                        if elem.Type == "ColorPicker" then
                            local rgb = data[elem.Name]
                            elem:Set(Color3.new(rgb[1], rgb[2], rgb[3]))
                        elseif elem.Type == "Keybind" then
                            elem:Set(Enum.KeyCode[data[elem.Name]])
                        else
                            elem:Set(data[elem.Name])
                        end
                    end
                end
                RoseUI:Notify({Title = "🌹 Config Loaded", Text = "Loaded settings from " .. fileName .. ".json.", Duration = 4})
            end
        end
    end
    
    function WindowObj:MakeTab(tabOptions)
        local tabName = tabOptions.Name or "Tab"
        local tabIcon = tabOptions.Icon or "rbxassetid://10652380582" -- Default Icon
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 35)
        tabBtn.BackgroundColor3 = HEADER_COLOR
        tabBtn.BackgroundTransparency = 1 
        tabBtn.Text = ""
        tabBtn.ZIndex = 4
        tabBtn.Parent = tabContainer
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)
        
        local tabIconImg = Instance.new("ImageLabel")
        tabIconImg.Size = UDim2.new(0, 18, 0, 18)
        tabIconImg.Position = UDim2.new(0, 8, 0.5, -9)
        tabIconImg.BackgroundTransparency = 1
        tabIconImg.Image = tabIcon
        tabIconImg.ImageColor3 = Color3.fromRGB(180, 150, 160)
        tabIconImg.ZIndex = 5
        tabIconImg.Parent = tabBtn

        local tabLabel = Instance.new("TextLabel")
        tabLabel.Size = UDim2.new(1, -35, 1, 0)
        tabLabel.Position = UDim2.new(0, 32, 0, 0)
        tabLabel.BackgroundTransparency = 1
        tabLabel.Text = tabName
        tabLabel.TextColor3 = Color3.fromRGB(180, 150, 160)
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.Font = Enum.Font.GothamSemibold
        tabLabel.TextSize = 13
        tabLabel.ZIndex = 5
        tabLabel.Parent = tabBtn
        
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, -20, 1, -20)
        page.Position = UDim2.new(0, 10, 0, 10)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = HEADER_COLOR
        page.Visible = false
        page.ZIndex = 10
        page.Parent = pageContainer
        
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Parent = page
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 10)
        end)
        
        -- Fancy Slide in/out Logic (No overlap)
        local isSwitching = false
        tabBtn.MouseButton1Click:Connect(function()
            if WindowObj.CurrentTab == page or isSwitching then return end
            isSwitching = true

            -- Hide all other tabs immediately to prevent overlap issues
            for _, t in pairs(WindowObj.Tabs) do
                if t.Page ~= page then
                    t.Page.Visible = false
                end
                tweenService:Create(t.Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                tweenService:Create(t.Lbl, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(180, 150, 160)}):Play()
                tweenService:Create(t.Img, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(180, 150, 160)}):Play()
            end

            -- Neue Page Slide in
            page.Visible = true
            page.Position = UDim2.new(0, 10, 0, 50) -- Startet leicht unten
            tweenService:Create(page, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 10, 0, 10)}):Play()
            
            tweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
            tweenService:Create(tabLabel, TweenInfo.new(0.2), {TextColor3 = TEXT_COLOR}):Play()
            tweenService:Create(tabIconImg, TweenInfo.new(0.2), {ImageColor3 = TEXT_COLOR}):Play()
            
            WindowObj.CurrentTab = page
            task.wait(0.2)
            isSwitching = false
        end)
        
        -- Setze ersten Tab aktiv
        if #WindowObj.Tabs == 0 then
            page.Visible = true
            tabBtn.BackgroundTransparency = 0.1
            tabLabel.TextColor3 = TEXT_COLOR
            tabIconImg.ImageColor3 = TEXT_COLOR
            WindowObj.CurrentTab = page
        end
        
        table.insert(WindowObj.Tabs, {Btn = tabBtn, Page = page, Lbl = tabLabel, Img = tabIconImg})
        
        local TabObj = {}
        
        -- 0. SECTION
        function TabObj:AddSection(sName)
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(1, -10, 0, 30)
            sectionFrame.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
            sectionFrame.BackgroundTransparency = 0.5
            sectionFrame.ZIndex = 11
            sectionFrame.Parent = page
            Instance.new("UICorner", sectionFrame).CornerRadius = UDim.new(0, 6)
            
            local sectionStroke = Instance.new("UIStroke")
            sectionStroke.Color = HEADER_COLOR
            sectionStroke.Transparency = 0.7
            sectionStroke.Thickness = 1
            sectionStroke.Parent = sectionFrame

            local sectionLabel = Instance.new("TextLabel")
            sectionLabel.Size = UDim2.new(1, -20, 0, 30)
            sectionLabel.Position = UDim2.new(0, 10, 0, 0)
            sectionLabel.BackgroundTransparency = 1
            sectionLabel.Text = sName
            sectionLabel.TextColor3 = HEADER_COLOR
            sectionLabel.TextSize = 13
            sectionLabel.Font = Enum.Font.GothamBold
            sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            sectionLabel.ZIndex = 12
            sectionLabel.Parent = sectionFrame
            
            local sectionContainer = Instance.new("Frame")
            sectionContainer.Size = UDim2.new(1, 0, 0, 0)
            sectionContainer.Position = UDim2.new(0, 0, 0, 35)
            sectionContainer.BackgroundTransparency = 1
            sectionContainer.Parent = sectionFrame
            
            local secLayout = Instance.new("UIListLayout")
            secLayout.Parent = sectionContainer
            secLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secLayout.Padding = UDim.new(0, 8)
            secLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            
            secLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sectionContainer.Size = UDim2.new(1, 0, 0, secLayout.AbsoluteContentSize.Y)
                sectionFrame.Size = UDim2.new(1, -10, 0, 45 + secLayout.AbsoluteContentSize.Y)
            end)
            
            local SectionAPI = {}
            local function proxyMethod(methodName)
                SectionAPI[methodName] = function(self, ...)
                    local oldPage = page
                    page = sectionContainer
                    local success, res = pcall(function(...) return TabObj[methodName](TabObj, ...) end, ...)
                    page = oldPage
                    if not success then
                        warn("[RoseUI] Error in " .. tostring(methodName) .. ": " .. tostring(res))
                        local errLabel = Instance.new("TextLabel")
                        errLabel.Size = UDim2.new(1, 0, 0, 40)
                        errLabel.BackgroundTransparency = 1
                        errLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
                        errLabel.TextWrapped = true
                        errLabel.TextScaled = true
                        errLabel.Text = "Crash in " .. tostring(methodName) .. ": " .. tostring(res)
                        errLabel.Parent = sectionContainer
                        return nil
                    end
                    return res
                end
            end
            
            proxyMethod("AddButton")
            proxyMethod("AddToggle")
            proxyMethod("AddSlider")
            proxyMethod("AddDropdown")
            proxyMethod("AddSearchDropdown")
            proxyMethod("AddTargetList")
            proxyMethod("AddColorPicker")
            proxyMethod("AddLabel")
            proxyMethod("AddTextbox")
            proxyMethod("AddKeybind")
            
            return SectionAPI
        end
        
        -- 1. BUTTON
        function TabObj:AddButton(btnOptions)
            local bName = btnOptions.Name or "Button"
            local cb = btnOptions.Callback or function() end
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 38)
            btn.BackgroundColor3 = CARD_COLOR
            btn.Text = "  " .. bName
            btn.TextColor3 = TEXT_COLOR
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.ZIndex = 11
            btn.Parent = page
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            -- Click Icon for aesthetic
            local clickIcon = Instance.new("TextLabel")
            clickIcon.Size = UDim2.new(0, 20, 0, 20)
            clickIcon.Position = UDim2.new(1, -30, 0.5, -10)
            clickIcon.BackgroundTransparency = 1
            clickIcon.Text = "▶"
            clickIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
            clickIcon.Font = Enum.Font.GothamBold
            clickIcon.TextSize = 12
            clickIcon.ZIndex = 12
            clickIcon.Parent = btn
            
            btn.MouseEnter:Connect(function() 
                tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 35, 50)}):Play()
                tweenService:Create(clickIcon, TweenInfo.new(0.2), {Position = UDim2.new(1, -25, 0.5, -10), TextColor3 = TEXT_COLOR}):Play()
            end)
            btn.MouseLeave:Connect(function() 
                tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = CARD_COLOR}):Play() 
                tweenService:Create(clickIcon, TweenInfo.new(0.2), {Position = UDim2.new(1, -30, 0.5, -10), TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
            end)
            btn.MouseButton1Down:Connect(function() tweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0.98, -10, 0, 35)}):Play() end)
            btn.MouseButton1Up:Connect(function() tweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(1, -10, 0, 38)}):Play() end)
            btn.MouseButton1Click:Connect(cb)
        end

        -- 2. TOGGLE
        function TabObj:AddToggle(toggleOptions)
            local tName = toggleOptions.Name or "Toggle"
            local cb = toggleOptions.Callback or function() end
            local defaultParams = toggleOptions.Default or false
            local isToggled = defaultParams
            
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, -10, 0, 42)
            toggleFrame.BackgroundColor3 = CARD_COLOR
            toggleFrame.ZIndex = 11
            toggleFrame.Parent = page
            Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = tName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 12
            label.Parent = toggleFrame

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 44, 0, 22)
            toggleBtn.Position = UDim2.new(1, -55, 0.5, -11)
            toggleBtn.BackgroundColor3 = defaultParams and HEADER_COLOR or Color3.fromRGB(30, 15, 20)
            toggleBtn.Text = ""
            toggleBtn.ZIndex = 12
            toggleBtn.Parent = toggleFrame
            Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

            local circle = Instance.new("Frame")
            circle.Size = UDim2.new(0, 18, 0, 18)
            circle.Position = UDim2.new(0, defaultParams and 24 or 2, 0.5, -9)
            circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            circle.ZIndex = 13
            circle.Parent = toggleBtn
            Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

            local outline = Instance.new("UIStroke")
            outline.Color = HEADER_COLOR
            outline.Transparency = defaultParams and 0 or 0.8
            outline.Thickness = 1
            outline.Parent = toggleBtn

            local currentBinds = {}
            local ToggleAPI = {
                Name = tName,
                Type = "Toggle",
                Value = defaultParams
            }
            
            function ToggleAPI:Set(state)
                if ToggleAPI.Value == state then return end
                ToggleAPI.Value = state
                isToggled = state
                local colorGoal = isToggled and HEADER_COLOR or Color3.fromRGB(30, 15, 20)
                local posGoal = isToggled and UDim2.new(0, 24, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                local outlineAlpha = isToggled and 0 or 0.8
                
                tweenService:Create(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = colorGoal}):Play()
                tweenService:Create(circle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = posGoal}):Play()
                tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = outlineAlpha}):Play()
                
                cb(isToggled)
            end
            
            local function fireToggle()
                ToggleAPI:Set(not isToggled)
            end
            
            local btnOverlay = Instance.new("TextButton")
            btnOverlay.Size = UDim2.new(1, 0, 1, 0)
            btnOverlay.BackgroundTransparency = 1
            btnOverlay.Text = ""
            btnOverlay.ZIndex = 14
            btnOverlay.Parent = toggleFrame
            
            btnOverlay.MouseButton1Click:Connect(fireToggle)
            
            btnOverlay.MouseButton2Click:Connect(function()
                local ctxBg = Instance.new("TextButton")
                ctxBg.Size = UDim2.new(1, 0, 1, 0)
                ctxBg.BackgroundTransparency = 1
                ctxBg.Text = ""
                ctxBg.ZIndex = 100
                ctxBg.Parent = screenGui
                
                local ctxMenu = Instance.new("Frame")
                local mouse = UserInputService:GetMouseLocation()
                ctxMenu.Position = UDim2.new(0, mouse.X + 10, 0, mouse.Y - 45)
                ctxMenu.BackgroundColor3 = CARD_COLOR
                ctxMenu.ZIndex = 101
                ctxMenu.ClipsDescendants = true
                ctxMenu.Parent = ctxBg
                Instance.new("UICorner", ctxMenu).CornerRadius = UDim.new(0, 6)
                
                local ctxStroke = Instance.new("UIStroke")
                ctxStroke.Color = HEADER_COLOR
                ctxStroke.Thickness = 1
                ctxStroke.Transparency = 0.5
                ctxStroke.Parent = ctxMenu
                
                local ctxList = Instance.new("UIListLayout")
                ctxList.SortOrder = Enum.SortOrder.LayoutOrder
                ctxList.Parent = ctxMenu
                
                local isWaitingForKey = false
                
                local function renderMenu()
                    for _, c in pairs(ctxMenu:GetChildren()) do
                        if c:IsA("GuiObject") then c:Destroy() end
                    end
                    
                    local titleLbl = Instance.new("TextLabel")
                    titleLbl.Size = UDim2.new(1, 0, 0, 30)
                    titleLbl.BackgroundTransparency = 1
                    titleLbl.Text = "  " .. tName .. " Binds"
                    titleLbl.TextColor3 = HEADER_COLOR
                    titleLbl.Font = Enum.Font.GothamBold
                    titleLbl.TextSize = 12
                    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                    titleLbl.ZIndex = 102
                    titleLbl.Parent = ctxMenu
                    
                    for i, bind in pairs(currentBinds) do
                        local bindBtn = Instance.new("TextButton")
                        bindBtn.Size = UDim2.new(1, 0, 0, 25)
                        bindBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
                        bindBtn.BackgroundTransparency = 0.5
                        bindBtn.Text = "  " .. bind.Name
                        bindBtn.TextColor3 = TEXT_COLOR
                        bindBtn.Font = Enum.Font.Gotham
                        bindBtn.TextSize = 12
                        bindBtn.TextXAlignment = Enum.TextXAlignment.Left
                        bindBtn.ZIndex = 102
                        bindBtn.Parent = ctxMenu
                        
                        local delBtn = Instance.new("TextButton")
                        delBtn.Size = UDim2.new(0, 25, 0, 25)
                        delBtn.Position = UDim2.new(1, -25, 0, 0)
                        delBtn.BackgroundTransparency = 1
                        delBtn.Text = "X"
                        delBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
                        delBtn.Font = Enum.Font.GothamBold
                        delBtn.ZIndex = 103
                        delBtn.Parent = bindBtn
                        
                        delBtn.MouseButton1Click:Connect(function()
                            table.remove(currentBinds, i)
                            renderMenu()
                        end)
                    end
                    
                    local addBtn = Instance.new("TextButton")
                    addBtn.Size = UDim2.new(1, 0, 0, 30)
                    addBtn.BackgroundColor3 = HEADER_COLOR
                    addBtn.BackgroundTransparency = 0.8
                    addBtn.Text = isWaitingForKey and "Press any key..." or "+ Add Keybind"
                    addBtn.TextColor3 = HEADER_COLOR
                    addBtn.Font = Enum.Font.GothamSemibold
                    addBtn.TextSize = 12
                    addBtn.ZIndex = 102
                    addBtn.Parent = ctxMenu
                    
                    addBtn.MouseButton1Click:Connect(function()
                        if isWaitingForKey then return end
                        isWaitingForKey = true
                        renderMenu()
                    end)
                    
                    ctxMenu.Size = UDim2.new(0, 160, 0, ctxList.AbsoluteContentSize.Y)
                end
                
                renderMenu()
                
                ctxBg.MouseButton1Click:Connect(function()
                    if not isWaitingForKey then ctxBg:Destroy() end
                end)
                ctxBg.MouseButton2Click:Connect(function()
                    if not isWaitingForKey then ctxBg:Destroy() end
                end)
                
                local bindConn
                bindConn = UserInputService.InputBegan:Connect(function(input2, proc2)
                    if isWaitingForKey and input2.UserInputType == Enum.UserInputType.Keyboard then
                        table.insert(currentBinds, input2.KeyCode)
                        isWaitingForKey = false
                        renderMenu()
                    end
                end)
                
                ctxBg.Destroying:Connect(function()
                    if bindConn then bindConn:Disconnect() end
                end)
            end)
            
            UserInputService.InputBegan:Connect(function(input, proc)
                if not proc and input.UserInputType == Enum.UserInputType.Keyboard then
                    for _, bind in ipairs(currentBinds) do
                        if input.KeyCode == bind then
                            if screenGui and screenGui.Parent then 
                                fireToggle()
                            end
                            break
                        end
                    end
                end
            end)
            
            table.insert(WindowObj.Elements, ToggleAPI)
            return ToggleAPI
        end

        -- 3. SLIDER
        function TabObj:AddSlider(sliderOptions)
            local sName = sliderOptions.Name or "Slider"
            local min = sliderOptions.Min or 0
            local max = sliderOptions.Max or 100
            local default = sliderOptions.Default or 50
            local cb = sliderOptions.Callback or function() end
            
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, -10, 0, 50)
            sliderFrame.BackgroundColor3 = CARD_COLOR
            sliderFrame.ZIndex = 11
            sliderFrame.Parent = page
            Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 0, 25)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = sName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 12
            label.Parent = sliderFrame

            local highlightBox = Instance.new("Frame")
            highlightBox.Size = UDim2.new(0, 45, 0, 20)
            highlightBox.Position = UDim2.new(1, -55, 0, 5)
            highlightBox.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
            highlightBox.ZIndex = 12
            highlightBox.Parent = sliderFrame
            Instance.new("UICorner", highlightBox).CornerRadius = UDim.new(0, 4)

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(1, 0, 1, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(default)
            valueLabel.TextColor3 = HEADER_COLOR
            valueLabel.TextSize = 12
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.ZIndex = 13
            valueLabel.Parent = highlightBox

            local slideBg = Instance.new("Frame")
            slideBg.Size = UDim2.new(1, -30, 0, 6)
            slideBg.Position = UDim2.new(0, 15, 0, 32)
            slideBg.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
            slideBg.ZIndex = 12
            slideBg.Parent = sliderFrame
            Instance.new("UICorner", slideBg).CornerRadius = UDim.new(1, 0)

            local slideInner = Instance.new("Frame")
            slideInner.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            slideInner.BackgroundColor3 = HEADER_COLOR
            slideInner.ZIndex = 13
            slideInner.Parent = slideBg
            Instance.new("UICorner", slideInner).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 14, 0, 14)
            knob.Position = UDim2.new(1, -7, 0.5, -7)
            knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            knob.ZIndex = 14
            knob.Parent = slideInner
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

            local slideBtn = Instance.new("TextButton")
            slideBtn.Size = UDim2.new(1, 0, 1, 10)
            slideBtn.Position = UDim2.new(0, 0, 0, -5)
            slideBtn.BackgroundTransparency = 1
            slideBtn.Text = ""
            slideBtn.ZIndex = 15
            slideBtn.Parent = slideBg

            local isDragging = false
            local UserInputService = game:GetService("UserInputService")

            local SliderAPI = {
                Name = sName,
                Type = "Slider",
                Value = default
            }

            function SliderAPI:Set(val)
                local clamped = math.clamp(val, min, max)
                SliderAPI.Value = clamped
                valueLabel.Text = tostring(clamped)
                local percentage = (clamped - min) / (max - min)
                tweenService:Create(slideInner, TweenInfo.new(0.08), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
                cb(clamped)
            end

            local function updateSlider(input)
                local relativeX = math.clamp(input.Position.X - slideBg.AbsolutePosition.X, 0, slideBg.AbsoluteSize.X)
                local percentage = relativeX / slideBg.AbsoluteSize.X
                local value = math.floor(min + (max - min) * percentage)
                SliderAPI:Set(value)
            end

            slideBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    tweenService:Create(knob, TweenInfo.new(0.2), {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -9, 0.5, -9)}):Play()
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                    tweenService:Create(knob, TweenInfo.new(0.2), {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7)}):Play()
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
            
            table.insert(WindowObj.Elements, SliderAPI)
            return SliderAPI
        end

        -- 4. FANCY DROPDOWN (Premium Animations)
        function TabObj:AddDropdown(dOptions)
            local dName = dOptions.Name or "Dropdown"
            local optionsList = dOptions.Options or {"Option 1", "Option 2"}
            local defaultParams = dOptions.Default or optionsList[1]
            local cb = dOptions.Callback or function() end
            
            GLOBAL_ZINDEX = GLOBAL_ZINDEX + 10 -- FIXED: Descending ZIndex ensures Dropdowns overlap elements below them
            local currentZ = GLOBAL_ZINDEX

            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(1, -10, 0, 42)
            dropFrame.BackgroundColor3 = CARD_COLOR
            dropFrame.ZIndex = currentZ
            dropFrame.Parent = page
            Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.4, 0, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = dName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = currentZ + 1
            label.Parent = dropFrame

            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(0.5, -15, 0, 30)
            dropBtn.Position = UDim2.new(0.5, 5, 0.5, -15)
            dropBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
            dropBtn.Text = "  " .. defaultParams
            dropBtn.TextColor3 = Color3.fromRGB(200, 180, 190)
            dropBtn.Font = Enum.Font.Gotham
            dropBtn.TextSize = 12
            dropBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropBtn.ZIndex = currentZ + 1
            dropBtn.Parent = dropFrame
            Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)
            
            local outline = Instance.new("UIStroke")
            outline.Color = HEADER_COLOR
            outline.Transparency = 0.8
            outline.Thickness = 1
            outline.Parent = dropBtn

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -25, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = Color3.fromRGB(150, 120, 130)
            arrow.TextSize = 10
            arrow.Font = Enum.Font.GothamBold
            arrow.ZIndex = currentZ + 2
            arrow.Parent = dropBtn

            -- Dropdown Container Animierbar!
            local dropMenuBg = Instance.new("Frame")
            dropMenuBg.Size = UDim2.new(0.5, -15, 0, 0) -- Startet bei 0 size Y
            dropMenuBg.Position = UDim2.new(0.5, 5, 1, 5)
            dropMenuBg.BackgroundColor3 = Color3.fromRGB(45, 25, 35)
            dropMenuBg.ZIndex = currentZ + 50
            dropMenuBg.ClipsDescendants = true -- Verhindert dass buttons rausgucken
            dropMenuBg.Visible = false
            dropMenuBg.Parent = pageContainer
            Instance.new("UICorner", dropMenuBg).CornerRadius = UDim.new(0, 4)
            
            local dropMenuStroke = Instance.new("UIStroke")
            dropMenuStroke.Color = HEADER_COLOR
            dropMenuStroke.Transparency = 0.5
            dropMenuStroke.Thickness = 1
            dropMenuStroke.Parent = dropMenuBg

            local dropMenu = Instance.new("ScrollingFrame")
            dropMenu.Size = UDim2.new(1, -4, 1, -4)
            dropMenu.Position = UDim2.new(0, 2, 0, 2)
            dropMenu.BackgroundTransparency = 1
            dropMenu.BorderSizePixel = 0
            dropMenu.ScrollBarThickness = 3
            dropMenu.ScrollBarImageColor3 = HEADER_COLOR
            dropMenu.ZIndex = currentZ + 51
            dropMenu.Parent = dropMenuBg
            
            local dropLayout = Instance.new("UIListLayout")
            dropLayout.Parent = dropMenu
            dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            
            local isOpen = false
            local listHeight = 0
            local currentSelection = defaultParams

            local DropdownAPI = {
                Name = dName,
                Type = "Dropdown",
                Value = defaultParams
            }

            function DropdownAPI:Set(val)
                DropdownAPI.Value = val
                dropBtn.Text = "  " .. tostring(val)
                cb(val)
            end
            
            local function toggleDropdown()
                isOpen = not isOpen
                if isOpen then
                    dropMenuBg.Visible = true
                    
                    -- Calculate absolute position and size
                    dropMenuBg.Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, 0)
                    dropMenuBg.Position = UDim2.new(0, dropBtn.AbsolutePosition.X - pageContainer.AbsolutePosition.X, 0, dropBtn.AbsolutePosition.Y - pageContainer.AbsolutePosition.Y + dropBtn.AbsoluteSize.Y + 2)
                    
                    tweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 180, TextColor3 = TEXT_COLOR}):Play()
                    tweenService:Create(outline, TweenInfo.new(0.3), {Transparency = 0}):Play()
                    tweenService:Create(dropMenuBg, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, math.clamp(listHeight, 10, 150))}):Play()
                else
                    tweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0, TextColor3 = Color3.fromRGB(150, 120, 130)}):Play()
                    tweenService:Create(outline, TweenInfo.new(0.3), {Transparency = 0.8}):Play()
                    local clsTween = tweenService:Create(dropMenuBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, 0)})
                    clsTween:Play()
                    clsTween.Completed:Wait()
                    if not isOpen then dropMenuBg.Visible = false end -- Check falls user schnell double clickt
                end
            end
            
            -- Close dropdown if scrolling
            local scrollFrame = dropFrame:FindFirstAncestorWhichIsA("ScrollingFrame")
            if scrollFrame then
                scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                    if isOpen then toggleDropdown() end
                end)
            end

            dropBtn.MouseEnter:Connect(function() tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = isOpen and 0 or 0.5}):Play() end)
            dropBtn.MouseLeave:Connect(function() tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = isOpen and 0 or 0.8}):Play() end)

            local function refreshOptions(newOptions)
                for _, child in pairs(dropMenu:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                
                listHeight = #newOptions * 25
                dropMenu.CanvasSize = UDim2.new(0, 0, 0, listHeight)
                
                for _, optText in pairs(newOptions) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, -6, 0, 25)
                    optBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
                    optBtn.BackgroundTransparency = 0
                    optBtn.Text = "  " .. optText
                    optBtn.TextColor3 = TEXT_COLOR
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 11
                    optBtn.TextXAlignment = Enum.TextXAlignment.Left
                    optBtn.ZIndex = currentZ + 52
                    optBtn.Parent = dropMenu
                    Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 2)
                    
                    optBtn.MouseEnter:Connect(function() tweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0, TextColor3 = HEADER_COLOR}):Play() end)
                    optBtn.MouseLeave:Connect(function() tweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundTransparency = 1, TextColor3 = TEXT_COLOR}):Play() end)

                    optBtn.MouseButton1Click:Connect(function()
                        DropdownAPI:Set(optText)
                        toggleDropdown()
                    end)
                end
                
                if isOpen then
                    tweenService:Create(dropMenuBg, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, math.clamp(listHeight, 10, 150))}):Play()
                end
            end
            
            refreshOptions(optionsList)
            dropBtn.MouseButton1Click:Connect(toggleDropdown)
            
            function DropdownAPI:Refresh(newList, newDefault)
                optionsList = newList
                refreshOptions(newList)
                if newDefault then
                    DropdownAPI:Set(newDefault)
                elseif not table.find(newList, DropdownAPI.Value) then
                    if newList[1] then
                        DropdownAPI:Set(newList[1])
                    end
                end
            end
            table.insert(WindowObj.Elements, DropdownAPI)
            return DropdownAPI
        end

        -- 4.5. SEARCH MULTI-DROPDOWN
        function TabObj:AddSearchDropdown(dOptions)
            local dName = dOptions.Name or "Search Dropdown"
            local optionsList = dOptions.Options or {}
            local defaultParams = dOptions.Default or {} -- Now expects a table of selected strings
            local cb = dOptions.Callback or function() end
            
            GLOBAL_ZINDEX = GLOBAL_ZINDEX + 10
            local currentZ = GLOBAL_ZINDEX

            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(1, -10, 0, 42)
            dropFrame.BackgroundColor3 = CARD_COLOR
            dropFrame.ZIndex = currentZ
            dropFrame.Parent = page
            Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.4, 0, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = dName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = currentZ + 1
            label.Parent = dropFrame

            -- Display Button shows selected items (e.g. "Egg 1, Egg 2")
            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(0.5, -15, 0, 30)
            dropBtn.Position = UDim2.new(0.5, 5, 0, 6)
            dropBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
            dropBtn.Text = "  Select..."
            dropBtn.TextWrapped = true
            dropBtn.TextYAlignment = Enum.TextYAlignment.Center
            dropBtn.TextColor3 = Color3.fromRGB(200, 180, 190)
            dropBtn.Font = Enum.Font.Gotham
            dropBtn.TextSize = 12
            dropBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropBtn.ZIndex = currentZ + 1
            dropBtn.Parent = dropFrame
            Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)
            
            local outline = Instance.new("UIStroke")
            outline.Color = HEADER_COLOR
            outline.Transparency = 0.8
            outline.Thickness = 1
            outline.Parent = dropBtn

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 0, 30)
            arrow.Position = UDim2.new(1, -25, 0.5, -15)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = Color3.fromRGB(150, 120, 130)
            arrow.TextSize = 10
            arrow.Font = Enum.Font.GothamBold
            arrow.ZIndex = currentZ + 2
            arrow.Parent = dropBtn

            local dropMenuBg = Instance.new("Frame")
            dropMenuBg.Size = UDim2.new(0.5, -15, 0, 0)
            dropMenuBg.Position = UDim2.new(0.5, 5, 1, 5)
            dropMenuBg.BackgroundColor3 = Color3.fromRGB(45, 25, 35)
            dropMenuBg.ZIndex = currentZ + 50
            dropMenuBg.ClipsDescendants = true
            dropMenuBg.Visible = false
            dropMenuBg.Parent = pageContainer
            Instance.new("UICorner", dropMenuBg).CornerRadius = UDim.new(0, 4)
            
            local dropMenuStroke = Instance.new("UIStroke")
            dropMenuStroke.Color = HEADER_COLOR
            dropMenuStroke.Transparency = 0.5
            dropMenuStroke.Thickness = 1
            dropMenuStroke.Parent = dropMenuBg

            -- Search Box inside Dropdown
            local searchBoxBg = Instance.new("Frame")
            searchBoxBg.Size = UDim2.new(1, -10, 0, 25)
            searchBoxBg.Position = UDim2.new(0, 5, 0, 5)
            searchBoxBg.BackgroundColor3 = Color3.fromRGB(25, 12, 18)
            searchBoxBg.ZIndex = currentZ + 51
            searchBoxBg.Parent = dropMenuBg
            Instance.new("UICorner", searchBoxBg).CornerRadius = UDim.new(0, 4)

            local searchBox = Instance.new("TextBox")
            searchBox.Size = UDim2.new(1, -10, 1, 0)
            searchBox.Position = UDim2.new(0, 5, 0, 0)
            searchBox.BackgroundTransparency = 1
            searchBox.PlaceholderText = "Search..."
            searchBox.Text = ""
            searchBox.TextColor3 = TEXT_COLOR
            searchBox.ClearTextOnFocus = false
            searchBox.PlaceholderColor3 = Color3.fromRGB(150, 120, 130)
            searchBox.Font = Enum.Font.Gotham
            searchBox.TextSize = 11
            searchBox.ZIndex = currentZ + 52
            searchBox.TextXAlignment = Enum.TextXAlignment.Left
            searchBox.Parent = searchBoxBg

            local dropMenu = Instance.new("ScrollingFrame")
            dropMenu.Size = UDim2.new(1, -4, 1, -34)
            dropMenu.Position = UDim2.new(0, 2, 0, 32)
            dropMenu.BackgroundTransparency = 1
            dropMenu.BorderSizePixel = 0
            dropMenu.ScrollBarThickness = 3
            dropMenu.ScrollBarImageColor3 = HEADER_COLOR
            dropMenu.ZIndex = currentZ + 51
            dropMenu.Parent = dropMenuBg
            
            local dropLayout = Instance.new("UIListLayout")
            dropLayout.Parent = dropMenu
            dropLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local isOpen = false
            local selectedItems = type(defaultParams) == "table" and defaultParams or {}
            if type(selectedItems) ~= "table" then selectedItems = {selectedItems} end

            local function updateBtnText()
                if #selectedItems == 0 then
                    dropBtn.Text = "  Select..."
                    tweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 42)}):Play()
                    tweenService:Create(dropBtn, TweenInfo.new(0.2), {Size = UDim2.new(0.5, -15, 0, 30)}):Play()
                else
                    dropBtn.Text = "  " .. table.concat(selectedItems, ", ")
                    local estLines = math.ceil(string.len(dropBtn.Text) / 20)
                    local newBtnH = math.max(30, estLines * 16)
                    local newFrameH = newBtnH + 12
                    
                    tweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, newFrameH)}):Play()
                    tweenService:Create(dropBtn, TweenInfo.new(0.2), {Size = UDim2.new(0.5, -15, 0, newBtnH)}):Play()
                end
            end
            updateBtnText()

            local DropdownAPI = {
                Name = dName,
                Type = "SearchDropdown",
                Value = selectedItems
            }
            
            local refreshOptions = function() end
            
            function DropdownAPI:Refresh(newOptions, newSelected)
                if newOptions then optionsList = newOptions end
                if newSelected then 
                    selectedItems = type(newSelected) == "table" and newSelected or {newSelected}
                    DropdownAPI.Value = selectedItems
                    updateBtnText()
                end
                refreshOptions(searchBox.Text)
            end

            local function toggleDropdown()
                isOpen = not isOpen
                if isOpen then
                    dropMenuBg.Visible = true
                    dropMenuBg.Position = UDim2.new(0, dropFrame.AbsolutePosition.X + dropBtn.Position.X.Offset, 0, dropFrame.AbsolutePosition.Y + dropFrame.AbsoluteSize.Y + 5)
                    arrow.Text = "▲"
                    tweenService:Create(outline, TweenInfo.new(0.3), {Transparency = 0.2}):Play()
                    
                    local maxH = math.clamp((#optionsList * 25) + 36, 60, 200)
                    tweenService:Create(dropMenuBg, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, maxH)}):Play()
                else
                    arrow.Text = "▼"
                    tweenService:Create(outline, TweenInfo.new(0.3), {Transparency = 0.8}):Play()
                    local clsTween = tweenService:Create(dropMenuBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, 0)})
                    clsTween:Play()
                    clsTween.Completed:Wait()
                    if not isOpen then dropMenuBg.Visible = false end 
                end
            end
            
            local scrollFrame = dropFrame:FindFirstAncestorWhichIsA("ScrollingFrame")
            if scrollFrame then
                scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                    if isOpen then toggleDropdown() end
                end)
            end

            dropBtn.MouseEnter:Connect(function() tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = isOpen and 0 or 0.5}):Play() end)
            dropBtn.MouseLeave:Connect(function() tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = isOpen and 0 or 0.8}):Play() end)

            refreshOptions = function(filterText)
                for _, child in pairs(dropMenu:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                
                local displayedCount = 0
                for _, optText in pairs(optionsList) do
                    if filterText == "" or string.find(string.lower(optText), string.lower(filterText), 1, true) then
                        displayedCount = displayedCount + 1
                        local isSel = table.find(selectedItems, optText) ~= nil

                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, -6, 0, 25)
                        optBtn.BackgroundColor3 = isSel and HEADER_COLOR or Color3.fromRGB(40, 25, 30)
                        optBtn.BackgroundTransparency = isSel and 0.5 or 0
                        optBtn.Text = "  " .. optText
                        optBtn.TextColor3 = isSel and Color3.new(1,1,1) or TEXT_COLOR
                        optBtn.Font = Enum.Font.Gotham
                        optBtn.TextSize = 11
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.ZIndex = currentZ + 52
                        optBtn.Parent = dropMenu
                        Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 2)
                        
                        optBtn.MouseEnter:Connect(function() 
                            if not table.find(selectedItems, optText) then
                                tweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.2, TextColor3 = HEADER_COLOR}):Play() 
                            end
                        end)
                        optBtn.MouseLeave:Connect(function() 
                            if not table.find(selectedItems, optText) then
                                tweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundTransparency = 0, TextColor3 = TEXT_COLOR}):Play() 
                            end
                        end)

                        optBtn.MouseButton1Click:Connect(function()
                            local idx = table.find(selectedItems, optText)
                            if idx then
                                table.remove(selectedItems, idx)
                            else
                                table.insert(selectedItems, optText)
                            end
                            DropdownAPI.Value = selectedItems
                            updateBtnText()
                            refreshOptions(searchBox.Text) -- Redraw to update colors
                            cb(selectedItems)
                        end)
                    end
                end
                
                local listHeight = displayedCount * 25
                dropMenu.CanvasSize = UDim2.new(0, 0, 0, listHeight)
                
                if isOpen then
                    local maxH = math.clamp(listHeight + 36, 60, 200)
                    tweenService:Create(dropMenuBg, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, maxH)}):Play()
                end
            end
            
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                refreshOptions(searchBox.Text)
            end)

            refreshOptions("")
            dropBtn.MouseButton1Click:Connect(toggleDropdown)
            
            function DropdownAPI:Refresh(newList, newDefault)
                optionsList = newList
                -- Clean up selected items that no longer exist
                local validSelections = {}
                for _, sel in pairs(selectedItems) do
                    if table.find(newList, sel) then table.insert(validSelections, sel) end
                end
                selectedItems = validSelections
                DropdownAPI.Value = selectedItems
                updateBtnText()
                refreshOptions(searchBox.Text)
            end
            table.insert(WindowObj.Elements, DropdownAPI)
            return DropdownAPI
        end

        -- 4.6. INTERACTIVE TARGET LIST (With Click-to-Remove & Clear All)
        function TabObj:AddTargetList(lOptions)
            local lName = lOptions.Name or "Target List"
            local optionsList = lOptions.Options or {}
            local cb = lOptions.Callback or function() end
            
            GLOBAL_ZINDEX = GLOBAL_ZINDEX + 10
            local currentZ = GLOBAL_ZINDEX

            local listFrame = Instance.new("Frame")
            listFrame.Size = UDim2.new(1, -10, 0, 120) -- Fixed vertical height for the list container
            listFrame.BackgroundColor3 = CARD_COLOR
            listFrame.ZIndex = currentZ
            listFrame.Parent = page
            Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, 0, 0, 30)
            label.Position = UDim2.new(0, 15, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = lName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = currentZ + 1
            label.Parent = listFrame

            local clearBtn = Instance.new("TextButton")
            clearBtn.Size = UDim2.new(0, 70, 0, 22)
            clearBtn.Position = UDim2.new(1, -85, 0, 9)
            clearBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 70)
            clearBtn.BackgroundTransparency = 0.8
            clearBtn.Text = "Clear All"
            clearBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            clearBtn.Font = Enum.Font.GothamBold
            clearBtn.TextSize = 11
            clearBtn.ZIndex = currentZ + 1
            clearBtn.Parent = listFrame
            Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)
            local outline = Instance.new("UIStroke")
            outline.Color = Color3.fromRGB(255, 100, 100)
            outline.Transparency = 0.5
            outline.Parent = clearBtn

            clearBtn.MouseEnter:Connect(function() tweenService:Create(clearBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play() end)
            clearBtn.MouseLeave:Connect(function() tweenService:Create(clearBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play() end)

            local scrollBg = Instance.new("Frame")
            scrollBg.Size = UDim2.new(1, -20, 1, -45)
            scrollBg.Position = UDim2.new(0, 10, 0, 35)
            scrollBg.BackgroundColor3 = Color3.fromRGB(25, 12, 18)
            scrollBg.ZIndex = currentZ + 1
            scrollBg.Parent = listFrame
            Instance.new("UICorner", scrollBg).CornerRadius = UDim.new(0, 4)

            local scrollMenu = Instance.new("ScrollingFrame")
            scrollMenu.Size = UDim2.new(1, -4, 1, -4)
            scrollMenu.Position = UDim2.new(0, 2, 0, 2)
            scrollMenu.BackgroundTransparency = 1
            scrollMenu.BorderSizePixel = 0
            scrollMenu.ScrollBarThickness = 3
            scrollMenu.ScrollBarImageColor3 = HEADER_COLOR
            scrollMenu.ZIndex = currentZ + 2
            scrollMenu.Parent = scrollBg
            
            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = scrollMenu
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 2)

            local ListAPI = {
                Name = lName,
                Type = "TargetList",
                Value = optionsList
            }

            local function refreshList()
                for _, child in pairs(scrollMenu:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                
                local count = 0
                for i, targetName in ipairs(ListAPI.Value) do
                    count = count + 1
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, -6, 0, 25)
                    optBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 35)
                    optBtn.Text = "  ✕  " .. targetName
                    optBtn.TextColor3 = TEXT_COLOR
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 12
                    optBtn.TextXAlignment = Enum.TextXAlignment.Left
                    optBtn.ZIndex = currentZ + 3
                    optBtn.Parent = scrollMenu
                    Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)
                    
                    optBtn.MouseEnter:Connect(function() tweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(65, 35, 45), TextColor3 = Color3.fromRGB(255, 100, 100)}):Play() end)
                    optBtn.MouseLeave:Connect(function() tweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 25, 35), TextColor3 = TEXT_COLOR}):Play() end)

                    optBtn.MouseButton1Click:Connect(function()
                        table.remove(ListAPI.Value, i)
                        refreshList()
                        cb(ListAPI.Value)
                    end)
                end
                
                scrollMenu.CanvasSize = UDim2.new(0, 0, 0, count * 27)
            end

            clearBtn.MouseButton1Click:Connect(function()
                ListAPI.Value = {}
                refreshList()
                cb(ListAPI.Value)
            end)

            function ListAPI:Refresh(newList)
                ListAPI.Value = newList
                refreshList()
            end

            refreshList()
            table.insert(WindowObj.Elements, ListAPI)
            return ListAPI
        end

        -- 5. COLOR PICKER (2D Wheel / Hex Style)
        function TabObj:AddColorPicker(cpOptions)
            local cpName = cpOptions.Name or "Color Picker"
            local defaultColor = cpOptions.Default or Color3.fromRGB(255, 255, 255)
            local cb = cpOptions.Callback or function() end
            
            GLOBAL_ZINDEX = GLOBAL_ZINDEX + 10
            local currentZ = GLOBAL_ZINDEX

            local cpFrame = Instance.new("Frame")
            cpFrame.Size = UDim2.new(1, -10, 0, 42)
            cpFrame.BackgroundColor3 = CARD_COLOR
            cpFrame.ZIndex = currentZ
            cpFrame.Parent = page
            Instance.new("UICorner", cpFrame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = cpName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = currentZ + 1
            label.Parent = cpFrame

            -- Color Preview Box
            local colorBtn = Instance.new("TextButton")
            colorBtn.Size = UDim2.new(0, 40, 0, 24)
            colorBtn.Position = UDim2.new(1, -55, 0.5, -12)
            colorBtn.BackgroundColor3 = defaultColor
            colorBtn.Text = ""
            colorBtn.ZIndex = currentZ + 1
            colorBtn.Parent = cpFrame
            Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 6)
            
            local outline = Instance.new("UIStroke")
            outline.Color = Color3.fromRGB(255, 255, 255)
            outline.Transparency = 0.5
            outline.Thickness = 1
            outline.Parent = colorBtn

            -- Hex Box Container
            local expandBg = Instance.new("Frame")
            expandBg.Size = UDim2.new(1, 0, 0, 0) 
            expandBg.Position = UDim2.new(0, 0, 1, 5)
            expandBg.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
            expandBg.ClipsDescendants = true
            expandBg.Visible = false
            expandBg.ZIndex = currentZ + 3
            expandBg.Parent = cpFrame
            Instance.new("UICorner", expandBg).CornerRadius = UDim.new(0, 6)

            local expandStroke = Instance.new("UIStroke")
            expandStroke.Color = HEADER_COLOR
            expandStroke.Transparency = 0.6
            expandStroke.Thickness = 1
            expandStroke.Parent = expandBg

            local h, s, v = defaultColor:ToHSV()
            local currentColor = defaultColor

            -- 2D Color Map (Hue = X, Saturation = Y)
            local colorMap = Instance.new("TextButton")
            colorMap.Size = UDim2.new(0, 100, 0, 100)
            colorMap.Position = UDim2.new(0, 15, 0, 15)
            colorMap.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            colorMap.Text = ""
            colorMap.AutoButtonColor = false
            colorMap.ZIndex = currentZ + 4
            colorMap.Parent = expandBg
            Instance.new("UICorner", colorMap).CornerRadius = UDim.new(0, 4)

            local mapHsvGradient = Instance.new("UIGradient")
            mapHsvGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
            })
            mapHsvGradient.Parent = colorMap
            
            local satOverlay = Instance.new("Frame")
            satOverlay.Size = UDim2.new(1, 0, 1, 0)
            satOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            satOverlay.ZIndex = currentZ + 5
            satOverlay.Parent = colorMap
            Instance.new("UICorner", satOverlay).CornerRadius = UDim.new(0, 4)
            local satGradient = Instance.new("UIGradient")
            satGradient.Rotation = 90
            satGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), -- Top: transparent (full saturation)
                NumberSequenceKeypoint.new(1, 0)  -- Bottom: solid white (0 saturation)
            })
            satGradient.Parent = satOverlay

            local valOverlay = Instance.new("Frame")
            valOverlay.Size = UDim2.new(1, 0, 1, 0)
            valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            valOverlay.BackgroundTransparency = v
            valOverlay.ZIndex = currentZ + 6
            valOverlay.Parent = colorMap
            Instance.new("UICorner", valOverlay).CornerRadius = UDim.new(0, 4)

            local pickerRing = Instance.new("Frame")
            pickerRing.Size = UDim2.new(0, 10, 0, 10)
            pickerRing.AnchorPoint = Vector2.new(0.5, 0.5)
            pickerRing.Position = UDim2.new(h, 0, 1 - s, 0)
            pickerRing.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            pickerRing.ZIndex = currentZ + 7
            pickerRing.Parent = colorMap
            Instance.new("UICorner", pickerRing).CornerRadius = UDim.new(1, 0)
            local ringStroke = Instance.new("UIStroke")
            ringStroke.Color = Color3.new(0,0,0)
            ringStroke.Thickness = 1
            ringStroke.Parent = pickerRing

            -- Value (Darkness) Slider
            local valBg = Instance.new("Frame")
            valBg.Size = UDim2.new(1, -145, 0, 20)
            valBg.Position = UDim2.new(0, 130, 0, 15)
            valBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            valBg.ZIndex = currentZ + 4
            valBg.Parent = expandBg
            Instance.new("UICorner", valBg).CornerRadius = UDim.new(0, 4)

            local valGradient = Instance.new("UIGradient")
            valGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(h, s, 1))
            })
            valGradient.Parent = valBg

            local valBtn = Instance.new("TextButton")
            valBtn.Size = UDim2.new(1, 0, 1, 0)
            valBtn.BackgroundTransparency = 1
            valBtn.Text = ""
            valBtn.ZIndex = currentZ + 5
            valBtn.Parent = valBg

            local valKnob = Instance.new("Frame")
            valKnob.Size = UDim2.new(0, 6, 1, 4)
            valKnob.Position = UDim2.new(v, -3, 0, -2)
            valKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            valKnob.ZIndex = currentZ + 6
            valKnob.Parent = valBg
            Instance.new("UICorner", valKnob).CornerRadius = UDim.new(0, 2)

            -- Hex Input Display
            local hexBox = Instance.new("TextBox")
            hexBox.Size = UDim2.new(1, -145, 0, 25)
            hexBox.Position = UDim2.new(0, 130, 0, 50)
            hexBox.BackgroundColor3 = Color3.fromRGB(20, 10, 15)
            hexBox.TextColor3 = TEXT_COLOR
            hexBox.TextSize = 12
            hexBox.Font = Enum.Font.Code
            hexBox.Text = "#" .. defaultColor:ToHex():upper()
            hexBox.ZIndex = currentZ + 4
            hexBox.Parent = expandBg
            Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0, 4)

            local ColorAPI = {
                Name = cName,
                Type = "ColorPicker",
                Value = defaultColor
            }

            local function updateVisuals()
                currentColor = Color3.fromHSV(h, s, v)
                ColorAPI.Value = currentColor
                colorBtn.BackgroundColor3 = currentColor
                valOverlay.BackgroundTransparency = v
                valGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV(h, s, 1))
                })
                hexBox.Text = "#" .. currentColor:ToHex():upper()
                cb(currentColor)
            end
            
            function ColorAPI:Set(nc)
                h, s, v = nc:ToHSV()
                pickerRing.Position = UDim2.new(h, 0, 1 - s, 0)
                valKnob.Position = UDim2.new(v, -3, 0, -2)
                updateVisuals()
            end

            -- Click / Drag Logic for Wheel
            local mapDragging = false
            local function updateMap(input)
                local relX = math.clamp(input.Position.X - colorMap.AbsolutePosition.X, 0, colorMap.AbsoluteSize.X)
                local relY = math.clamp(input.Position.Y - colorMap.AbsolutePosition.Y, 0, colorMap.AbsoluteSize.Y)
                
                h = relX / colorMap.AbsoluteSize.X
                s = 1 - (relY / colorMap.AbsoluteSize.Y) -- 1 at top, 0 at bottom
                
                pickerRing.Position = UDim2.new(h, 0, 1 - s, 0)
                updateVisuals()
            end

            colorMap.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    mapDragging = true
                    updateMap(input)
                end
            end)

            -- Value Slider Drag
            local valDragging = false
            local function updateValSlider(input)
                local relX = math.clamp(input.Position.X - valBg.AbsolutePosition.X, 0, valBg.AbsoluteSize.X)
                local pct = relX / valBg.AbsoluteSize.X
                valKnob.Position = UDim2.new(pct, -3, 0, -2)
                v = pct
                updateVisuals()
            end

            valBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    valDragging = true
                    updateValSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    mapDragging = false
                    valDragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if mapDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateMap(input)
                elseif valDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateValSlider(input)
                end
            end)

            -- Hex Code Update functionality
            hexBox.FocusLost:Connect(function()
                local txt = hexBox.Text:gsub("#", "")
                if #txt == 6 then
                    local pcallSuccess, newColor = pcall(function()
                        return Color3.fromHex(txt)
                    end)
                    if pcallSuccess then
                        h, s, v = newColor:ToHSV()
                        pickerRing.Position = UDim2.new(h, 0, 1 - s, 0)
                        valKnob.Position = UDim2.new(v, -3, 0, -2)
                        updateVisuals()
                    end
                else
                    hexBox.Text = "#" .. currentColor:ToHex():upper()
                end
            end)

            local isOpen = false
            colorBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    expandBg.Visible = true
                    tweenService:Create(expandBg, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 130)}):Play()
                    tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = 0}):Play()
                else
                    tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
                    local closeTween = tweenService:Create(expandBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})
                    closeTween:Play()
                    closeTween.Completed:Wait()
                    if not isOpen then expandBg.Visible = false end
                end
            end)

            -- Initial ring setup
            local initMax = 50 -- 100/2
            local initDist = s * initMax
            local initAngle = (h * math.pi * 2) - math.pi
            pickerRing.Position = UDim2.new(0.5, math.cos(initAngle)*initDist, 0.5, math.sin(initAngle)*initDist)
            updateVisuals()
        end

        -- ==========================================
        -- MISSING RAYFIELD COMPONENTS (Label, Textbox, Keybind)
        -- ==========================================

        -- 6. LABEL
        function TabObj:AddLabel(text)
            local lblFrame = Instance.new("Frame")
            lblFrame.Size = UDim2.new(1, -10, 0, 30)
            lblFrame.BackgroundColor3 = CARD_COLOR
            lblFrame.BackgroundTransparency = 0.5
            lblFrame.Parent = page
            Instance.new("UICorner", lblFrame).CornerRadius = UDim.new(0, 4)

            local txtLbl = Instance.new("TextLabel")
            txtLbl.Size = UDim2.new(1, -20, 1, 0)
            txtLbl.Position = UDim2.new(0, 10, 0, 0)
            txtLbl.BackgroundTransparency = 1
            txtLbl.Text = text
            txtLbl.TextColor3 = TEXT_COLOR
            txtLbl.TextSize = 13
            txtLbl.Font = Enum.Font.Gotham
            txtLbl.TextXAlignment = Enum.TextXAlignment.Left
            txtLbl.Parent = lblFrame
            
            local LblAPI = {}
            function LblAPI:Set(newText)
                txtLbl.Text = newText
            end
            return LblAPI
        end

        -- 7. TEXTBOX
        function TabObj:AddTextbox(tbOptions)
            local tbName = tbOptions.Name or "Textbox"
            local placeholder = tbOptions.Placeholder or "Enter Text..."
            local optionsList = tbOptions.Options -- Optional Array for Autocomplete
            local cb = tbOptions.Callback or function() end

            local tbFrame = Instance.new("Frame")
            tbFrame.Size = UDim2.new(1, -10, 0, 42)
            tbFrame.BackgroundColor3 = CARD_COLOR
            tbFrame.Parent = page
            Instance.new("UICorner", tbFrame).CornerRadius = UDim.new(0, 6)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, 0, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = tbName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = tbFrame

            local tBox = Instance.new("TextBox")
            tBox.Size = UDim2.new(0, 200, 0, 26)
            tBox.Position = UDim2.new(1, -215, 0.5, -13)
            tBox.BackgroundColor3 = Color3.fromRGB(20, 10, 15)
            tBox.Text = ""
            tBox.PlaceholderText = placeholder
            tBox.TextColor3 = TEXT_COLOR
            tBox.PlaceholderColor3 = Color3.fromRGB(150, 120, 130)
            tBox.TextSize = 12
            tBox.Font = Enum.Font.Gotham
            tBox.Parent = tbFrame
            Instance.new("UICorner", tBox).CornerRadius = UDim.new(0, 4)
            
            local outline = Instance.new("UIStroke")
            outline.Color = HEADER_COLOR
            outline.Transparency = 0.8
            outline.Parent = tBox

            tBox.Focused:Connect(function()
                tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
            end)
            
            local TextboxAPI = {
                Name = tbName,
                Type = "Textbox",
                Value = ""
            }
            function TextboxAPI:Set(val)
                TextboxAPI.Value = val
                tBox.Text = val
                cb(val)
            end
            
            local refreshSuggestions = function() end
            local isSelectingOption = false
            
            function TextboxAPI:Refresh(newOptions)
                if type(newOptions) == "table" then
                    optionsList = newOptions
                    if tBox:IsFocused() then
                        refreshSuggestions(tBox.Text)
                    end
                end
            end
            
            tBox:GetPropertyChangedSignal("Text"):Connect(function()
                TextboxAPI.Value = tBox.Text
                cb(tBox.Text, false)
            end)
            
            local suggestBg
            if type(optionsList) == "table" then
                GLOBAL_ZINDEX = GLOBAL_ZINDEX + 10
                local currentZ = GLOBAL_ZINDEX
                
                suggestBg = Instance.new("Frame")
                suggestBg.AnchorPoint = Vector2.new(1, 0)
                suggestBg.Size = UDim2.new(0, 200, 0, 0)
                suggestBg.Position = UDim2.new(1, -15, 0.5, 15)
                suggestBg.BackgroundColor3 = Color3.fromRGB(35, 18, 25)
                suggestBg.ZIndex = currentZ + 50
                suggestBg.ClipsDescendants = true
                suggestBg.Visible = false
                suggestBg.Parent = tbFrame
                Instance.new("UICorner", suggestBg).CornerRadius = UDim.new(0, 4)
                
                local suggestStroke = Instance.new("UIStroke")
                suggestStroke.Color = HEADER_COLOR
                suggestStroke.Transparency = 0.5
                suggestStroke.Thickness = 1
                suggestStroke.Parent = suggestBg
                
                local suggestMenu = Instance.new("ScrollingFrame")
                suggestMenu.Size = UDim2.new(1, -4, 1, -4)
                suggestMenu.Position = UDim2.new(0, 2, 0, 2)
                suggestMenu.BackgroundTransparency = 1
                suggestMenu.BorderSizePixel = 0
                suggestMenu.ScrollBarThickness = 2
                suggestMenu.ScrollBarImageColor3 = HEADER_COLOR
                suggestMenu.ZIndex = currentZ + 51
                suggestMenu.Parent = suggestBg
                
                local suggestLayout = Instance.new("UIListLayout")
                suggestLayout.Parent = suggestMenu
                suggestLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local TextService = game:GetService("TextService")
                refreshSuggestions = function(filter)
                    for _, child in pairs(suggestMenu:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    
                    local count = 0
                    local maxWidth = 200
                    local lowerFilter = string.lower(filter)
                    for _, opt in ipairs(optionsList) do
                        if filter == "" or string.find(string.lower(opt), lowerFilter, 1, true) then
                            count = count + 1
                            local btn = Instance.new("TextButton")
                            btn.Size = UDim2.new(1, -6, 0, 22)
                            btn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
                            btn.BackgroundTransparency = 0
                            btn.Text = "  " .. opt
                            btn.TextColor3 = TEXT_COLOR
                            btn.Font = Enum.Font.Gotham
                            btn.TextSize = 11
                            btn.TextXAlignment = Enum.TextXAlignment.Left
                            btn.ZIndex = currentZ + 52
                            btn.Parent = suggestMenu
                            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 2)
                            
                            local bounds = TextService:GetTextSize(btn.Text, 11, Enum.Font.Gotham, Vector2.new(2000, 22))
                            if bounds.X + 30 > maxWidth then maxWidth = bounds.X + 30 end
                            
                            btn.MouseEnter:Connect(function() 
                                tweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = HEADER_COLOR}):Play() 
                            end)
                            btn.MouseLeave:Connect(function() 
                                tweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = TEXT_COLOR}):Play() 
                            end)
                            
                            btn.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                    isSelectingOption = true
                                    cb(opt, true)
                                    preventNextRefresh = true
                                    tBox.Text = "" 
                                    tBox:CaptureFocus()
                                    task.delay(0.15, function() isSelectingOption = false end)
                                end
                            end)
                        end
                    end
                    
                    local h = math.clamp(count * 22 + 4, 0, 150)
                    suggestMenu.CanvasSize = UDim2.new(0, 0, 0, count * 22)
                    tweenService:Create(suggestBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, maxWidth, 0, h)}):Play()
                end

                local preventNextRefresh = false

                tBox.Focused:Connect(function()
                    suggestBg.Visible = true
                    refreshSuggestions(tBox.Text)
                end)
                
                tBox:GetPropertyChangedSignal("Text"):Connect(function()
                    if preventNextRefresh then
                        preventNextRefresh = false
                        return
                    end
                    if tBox:IsFocused() then
                        refreshSuggestions(tBox.Text)
                    end
                end)
            end

            tBox.FocusLost:Connect(function()
                tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = 0.8}):Play()
                if suggestBg then
                    task.delay(0.1, function() -- Minor delay to allow clicks to register
                        if isSelectingOption then return end
                        local cls = tweenService:Create(suggestBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, suggestBg.Size.X.Offset, 0, 0)})
                        cls:Play()
                        cls.Completed:Connect(function() suggestBg.Visible = false end)
                    end)
                end
            end)
            
            table.insert(WindowObj.Elements, TextboxAPI)
            return TextboxAPI
        end

        -- 8. KEYBIND
        function TabObj:AddKeybind(kbOptions)
            local kbName = kbOptions.Name or "Keybind"
            local defaultKey = kbOptions.Default or Enum.KeyCode.E
            local cb = kbOptions.Callback or function() end

            local currentKey = defaultKey

            local kbFrame = Instance.new("Frame")
            kbFrame.Size = UDim2.new(1, -10, 0, 42)
            kbFrame.BackgroundColor3 = CARD_COLOR
            kbFrame.Parent = page
            Instance.new("UICorner", kbFrame).CornerRadius = UDim.new(0, 6)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = kbName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = kbFrame

            local bindBtn = Instance.new("TextButton")
            bindBtn.Size = UDim2.new(0, 80, 0, 26)
            bindBtn.Position = UDim2.new(1, -95, 0.5, -13)
            bindBtn.BackgroundColor3 = Color3.fromRGB(20, 10, 15)
            bindBtn.Text = currentKey.Name
            bindBtn.TextColor3 = HEADER_COLOR
            bindBtn.TextSize = 12
            bindBtn.Font = Enum.Font.GothamBold
            bindBtn.Parent = kbFrame
            Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)

            local outline = Instance.new("UIStroke")
            outline.Color = HEADER_COLOR
            outline.Transparency = 0.8
            outline.Parent = bindBtn

            local isWaiting = false
            local conn
            
            local KeybindAPI = {
                Name = kbName,
                Type = "Keybind",
                Value = currentKey
            }
            function KeybindAPI:Set(keyEnum)
                currentKey = keyEnum
                KeybindAPI.Value = keyEnum
                bindBtn.Text = keyEnum.Name
                cb()
            end

            bindBtn.MouseButton1Click:Connect(function()
                if isWaiting then return end
                isWaiting = true
                bindBtn.Text = "..."
                tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = 0}):Play()
                tweenService:Create(bindBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 20, 30)}):Play()

                conn = UserInputService.InputBegan:Connect(function(input, processed)
                    if not processed and input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        bindBtn.Text = currentKey.Name
                        isWaiting = false
                        tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = 0.8}):Play()
                        tweenService:Create(bindBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 10, 15)}):Play()
                        conn:Disconnect()
                    end
                end)
            end)

            UserInputService.InputBegan:Connect(function(input, processed)
                if not processed and input.KeyCode == currentKey and not isWaiting then
                    -- Verhindert Ghost-Feuer wenn GUI gelöscht ist
                    if not screenGui or not screenGui.Parent then return end 
                    cb()
                end
            end)
            
            table.insert(WindowObj.Elements, KeybindAPI)
            return KeybindAPI
        end

        return TabObj
    end
    
    function WindowObj:CreateConfigManager(tab)
        local cfgSection = tab:AddSection("📁 Configuration Manager")
        
        local configName = ""
        cfgSection:AddTextbox({
            Name = "Config Name",
            Placeholder = "my_legit_config",
            Callback = function(val)
                configName = val
            end
        })

        cfgSection:AddButton({
            Name = "Save Config",
            Callback = function()
                if configName == "" then
                    RoseUI:Notify({Title = "⚠️ Error", Text = "Please enter a config name.", Duration = 3})
                    return
                end
                WindowObj:SaveConfig(configName)
            end
        })
        
        local cfgDropdown
        
        local function refreshConfigList()
            local list = {}
            if listfiles and isfolder and isfolder(WindowObj.ConfigFolder) then
                local pcallSuccess, files = pcall(function() return listfiles(WindowObj.ConfigFolder) end)
                if pcallSuccess and files then
                    for _, file in pairs(files) do
                        if file:match("%.json$") then
                            local name = string.match(file, "[\\/]([^\\/]+)%.json$")
                            if not name then
                                name = string.match(file, "([^\\/]+)%.json$")
                            end
                            if name then
                                table.insert(list, name)
                            end
                        end
                    end
                end
            end
            if #list == 0 then table.insert(list, "No Configs Found") end
            if cfgDropdown then
                cfgDropdown:Refresh(list, list[1])
            end
            return list
        end
        
        WindowObj.ConfigRefreshListener = refreshConfigList
        
        local selectedConfig = ""
        cfgDropdown = cfgSection:AddDropdown({
            Name = "Select Config",
            Options = refreshConfigList(),
            Callback = function(val)
                selectedConfig = val
            end
        })
        
        cfgSection:AddButton({
            Name = "Load Config",
            Callback = function()
                if selectedConfig == "" or selectedConfig == "No Configs Found" then return end
                WindowObj:LoadConfig(selectedConfig)
            end
        })
        
        cfgSection:AddButton({
            Name = "Refresh List",
            Callback = function()
                refreshConfigList()
            end
        })
    end
    
    -- ================= INTRO ANIMATION =================
    dragFrame.Size = UDim2.new(0, 0, 0, 0)
    dragFrame.ClipsDescendants = true
    
    local splashOrigin = Instance.new("Frame")
    splashOrigin.Size = UDim2.new(0, 0, 0, 0)
    splashOrigin.Position = UDim2.new(0.5, 0, 0.5, 0)
    splashOrigin.BackgroundColor3 = HEADER_COLOR
    splashOrigin.ZIndex = 100
    splashOrigin.Parent = screenGui
    Instance.new("UICorner", splashOrigin).CornerRadius = UDim.new(1, 0)
    
    local ripple = Instance.new("Frame")
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.BackgroundTransparency = 1
    ripple.ZIndex = 99
    ripple.Parent = screenGui
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
    
    local rippleStroke = Instance.new("UIStroke")
    rippleStroke.Color = HEADER_COLOR
    rippleStroke.Thickness = 6
    rippleStroke.Parent = ripple
    
    local splashText = Instance.new("TextLabel")
    splashText.Size = UDim2.new(0, 200, 0, 50)
    splashText.Position = UDim2.new(0.5, -100, 0.5, -25)
    splashText.BackgroundTransparency = 1
    splashText.Text = "R o s e  H u b"
    splashText.TextColor3 = Color3.fromRGB(255, 255, 255)
    splashText.TextTransparency = 1
    splashText.Font = Enum.Font.GothamBold
    splashText.TextSize = 28
    splashText.ZIndex = 110
    splashText.Parent = screenGui
    
    local splashTextShadow = Instance.new("TextLabel")
    splashTextShadow.Size = UDim2.new(1, 0, 1, 0)
    splashTextShadow.Position = UDim2.new(0, 0, 0, 2)
    splashTextShadow.BackgroundTransparency = 1
    splashTextShadow.Text = "R o s e  H u b"
    splashTextShadow.TextColor3 = HEADER_COLOR
    splashTextShadow.TextTransparency = 1
    splashTextShadow.Font = Enum.Font.GothamBold
    splashTextShadow.TextSize = 28
    splashTextShadow.ZIndex = 109
    splashTextShadow.Parent = splashText

    task.spawn(function()
        -- Splash in
        tweenService:Create(splashOrigin, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0.5, -15, 0.5, -15)
        }):Play()
        task.wait(0.3)
        -- Ripple explode
        tweenService:Create(ripple, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 250, 0, 250), Position = UDim2.new(0.5, -125, 0.5, -125)
        }):Play()
        tweenService:Create(rippleStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1, Thickness = 0
        }):Play()
        -- Splash shrink and Drop Text
        tweenService:Create(splashOrigin, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        tweenService:Create(splashText, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.new(0.5, -100, 0.5, -35)}):Play()
        tweenService:Create(splashTextShadow, TweenInfo.new(0.5), {TextTransparency = 0.5}):Play()
        
        task.wait(1.4)
        
        -- Text Fade out
        tweenService:Create(splashText, TweenInfo.new(0.3), {TextTransparency = 1, Position = UDim2.new(0.5, -100, 0.5, -50)}):Play()
        tweenService:Create(splashTextShadow, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        task.wait(0.3)
        
        splashOrigin:Destroy()
        ripple:Destroy()
        splashText:Destroy()
        
        -- Open main window
        local openTw = tweenService:Create(dragFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = DEFAULT_SIZE})
        openTw:Play()
        openTw.Completed:Wait()
        dragFrame.ClipsDescendants = false
        
        -- Welcome Notification nach dem das Fenster offen ist
        local pName = game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name or "Guest"
        RoseUI:Notify({Title = "🌹 Welcome, " .. pName .. "!", Text = "Successfully loaded " .. titleText .. ". Enjoy!", Duration = 5})
    end)

    return WindowObj
end

return RoseUI
