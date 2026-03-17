--=============================================================================--
--  ROSE UI FRAMEWORK (V3 - Windows Resizing, Animations, Premium Dropdowns)
--=============================================================================--
local RoseUI = {}
RoseUI.SafeMode = false
pcall(function()
    local execName = identifyexecutor and identifyexecutor() or ""
    if string.find(string.lower(execName), "xeno") or type(getcustomasset) == "nil" then
        RoseUI.SafeMode = true
    end
end)

local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- ========================================================
-- 🛡️ ANTI-AFK has been moved exclusively to the Settings Tab UI.
-- ========================================================

local RoseUI_Themes = {
    ["Dark Rose"] = {
        Header = Color3.fromRGB(190, 25, 45),
        Sidebar = Color3.fromRGB(15, 12, 12),
        Content = Color3.fromRGB(15, 12, 12),
        Card = Color3.fromRGB(25, 18, 20),
        Text = Color3.fromRGB(255, 235, 240)
    },
    ["Ocean Blue"] = {
        Header = Color3.fromRGB(30, 100, 210),
        Sidebar = Color3.fromRGB(12, 14, 20),
        Content = Color3.fromRGB(12, 14, 20),
        Card = Color3.fromRGB(18, 22, 30),
        Text = Color3.fromRGB(235, 245, 255)
    },
    ["Forest Green"] = {
        Header = Color3.fromRGB(40, 160, 60),
        Sidebar = Color3.fromRGB(12, 18, 14),
        Content = Color3.fromRGB(12, 18, 14),
        Card = Color3.fromRGB(18, 26, 20),
        Text = Color3.fromRGB(240, 255, 240)
    }
}

local currentThemeName = "Dark Rose"
pcall(function()
    if isfile and readfile and isfile("RoseHub/theme.txt") then
        local savedTheme = readfile("RoseHub/theme.txt")
        if RoseUI_Themes[savedTheme] then
            currentThemeName = savedTheme
        end
    end
end)

local activeTheme = RoseUI_Themes[currentThemeName]

-- Design Colors (Loaded dynamically)
local HEADER_COLOR = activeTheme.Header
local SIDEBAR_COLOR = activeTheme.Sidebar
local CONTENT_COLOR = activeTheme.Content
local CARD_COLOR = activeTheme.Card
local TEXT_COLOR = activeTheme.Text

local GLOBAL_ZINDEX = 1

function RoseUI:Init()
    if RoseUI.CurrentWindow then
        task.spawn(function()
            pcall(function()
                local autoloadPath = RoseUI.CurrentWindow.ConfigFolder .. "/autoload.txt"
                if isfile and readfile and isfile(autoloadPath) then
                    local autoloadFile = readfile(autoloadPath)
                    if autoloadFile and autoloadFile ~= "" then
                        task.delay(0.5, function()
                            RoseUI.CurrentWindow:LoadConfig(autoloadFile)
                            RoseUI:Notify({Title = "🌹 Autoload", Text = "Loaded config: " .. autoloadFile, Duration = 4})
                        end)
                    end
                end
            end)
        end)
    end
end

function RoseUI:Notify(options)
    local title = options.Title or "Notification"
    local text = options.Text or ""
    local dur = options.Duration or 5

    local success, notifGui = pcall(function() return coreGui:FindFirstChild("RoseUI_Notifs") end)
    local targetParent = success and coreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    notifGui = targetParent:FindFirstChild("RoseUI_Notifs")
    
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
    notifFrame.BackgroundTransparency = 0.25 -- Acrylic look
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = notifGui
    Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 6)
    
    -- ACRYLIC BLUR TRICK FOR NOTIFICATION
    local camera = workspace.CurrentCamera
    local blurPart = Instance.new("Part")
    blurPart.Name = "NotifAcrylicBlur"
    blurPart.Material = Enum.Material.Glass
    blurPart.Color = Color3.fromRGB(0, 0, 0)
    blurPart.Transparency = 0.999
    blurPart.Reflectance = 0
    blurPart.CastShadow = false
    blurPart.CanCollide = false
    blurPart.CanQuery = false
    blurPart.Anchored = true
    blurPart.Parent = camera
    
    if not game:GetService("Lighting"):FindFirstChild("AcrylicDoF") then
        local dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "AcrylicDoF"
        dof.FarIntensity = 0
        dof.NearIntensity = 0.8
        dof.FocusDistance = 10
        dof.InFocusRadius = 20
        dof.Parent = game:GetService("Lighting")
    end
    
    local blurConn = game:GetService("RunService").RenderStepped:Connect(function()
        if not notifFrame or not notifFrame.Parent then
            pcall(function() blurPart:Destroy() end)
            return
        end
        local insetX = 6
        local insetY = 10
        local size = notifFrame.AbsoluteSize - Vector2.new(insetX * 2, insetY * 2)
        local pos = notifFrame.AbsolutePosition + Vector2.new(insetX, insetY)
        
        -- Fix Roblox TopBar Offset calculation natively
        local topbarOffset = game:GetService("GuiService"):GetGuiInset().Y
        pos = Vector2.new(pos.X, pos.Y + topbarOffset - 4)
        
        local z = 0.2
        local fov = math.rad(camera.FieldOfView)
        local h = 2 * math.tan(fov / 2) * z
        local w = h * (camera.ViewportSize.X / camera.ViewportSize.Y)
        
        local sizeX = (size.X / camera.ViewportSize.X) * w
        local sizeY = (size.Y / camera.ViewportSize.Y) * h
        local posX = (pos.X / camera.ViewportSize.X) * w - w / 2 + sizeX / 2
        local posY = -(pos.Y / camera.ViewportSize.Y) * h + h / 2 - sizeY / 2
        
        blurPart.Size = Vector3.new(math.max(0.001, sizeX), math.max(0.001, sizeY), 0)
        blurPart.CFrame = camera.CFrame * CFrame.new(posX, posY, -z)
    end)
    table.insert(_G.RoseUI_Connections, blurConn)
    
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
        pcall(function() blurPart:Destroy() end)
        pcall(function() blurConn:Disconnect() end)
        notifFrame:Destroy()
    end)
end


function RoseUI:CreateWindow(options)
    local titleText = options.Name or "Rose Hub"
    local hubType = options.HubType or "Rose Hub"

    -- Global overlapping prevention to kill old background loops
    _G.RoseBase_ID = (_G.RoseBase_ID or 0) + 1
    local currentID = _G.RoseBase_ID

    -- Purge old global event connections to stop massive memory leaks
    if _G.RoseUI_Connections then
        for _, conn in pairs(_G.RoseUI_Connections) do
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        end
    end
    _G.RoseUI_Connections = {}

    local function getTargetGui()
        local success, ui = pcall(function() return coreGui:FindFirstChild("RoseUI_Window") end)
        if success then return coreGui end
        return game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local targetContainer = getTargetGui()

    local winName = options.WindowName or "RoseUI_Window"

    if targetContainer:FindFirstChild(winName) then
        targetContainer[winName]:Destroy()
    end
    
    if targetContainer:FindFirstChild("RoseUI_Notifs") then
        targetContainer.RoseUI_Notifs:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = winName
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = targetContainer

    local openBtnGui = Instance.new("ScreenGui")
    openBtnGui.Name = winName .. "_OpenBtn"
    openBtnGui.ResetOnSpawn = false
    openBtnGui.Enabled = false
    openBtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    openBtnGui.Parent = targetContainer

    local mobileOpenBtn = Instance.new("ImageButton")
    mobileOpenBtn.Size = UDim2.new(0, 45, 0, 45)
    mobileOpenBtn.Position = UDim2.new(1, -60, 0, 15) -- Upper right corner
    mobileOpenBtn.BackgroundColor3 = CARD_COLOR
    mobileOpenBtn.Image = "rbxassetid://135043831839832"
    mobileOpenBtn.ZIndex = 100
    mobileOpenBtn.Parent = openBtnGui
    Instance.new("UICorner", mobileOpenBtn).CornerRadius = UDim.new(1, 0)
    
    task.spawn(function()
        local getasset = select(2, pcall(function() return getcustomasset and getcustomasset or (getgenv and getgenv().getcustomasset) end))
        if getasset and type(getasset) == "function" then
            local path = "RoseHub/assets/rose_logo_v3_small.png"
            if isfile and isfile(path) then pcall(function() mobileOpenBtn.Image = getasset(path) end) end
        end
    end)

    local mbStroke = Instance.new("UIStroke")
    mbStroke.Color = HEADER_COLOR
    mbStroke.Thickness = 2
    mbStroke.Parent = mobileOpenBtn
    
    -- Main Container Dynamic Scaling
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    
    local defaultWidth = 650
    local defaultHeight = 520
    
    local padding = 40 -- Minimum space from edges on mobile
    
    local finalWidth = math.min(defaultWidth, viewportSize.X - padding)
    local finalHeight = math.min(defaultHeight, viewportSize.Y - padding)
    
    local UIMinWidth = 300
    local UIMinHeight = 350
    finalWidth = math.max(finalWidth, UIMinWidth)
    finalHeight = math.max(finalHeight, UIMinHeight)

    local dragFrame = Instance.new("Frame")
    dragFrame.Name = "DragBox"
    dragFrame.Size = UDim2.new(0, finalWidth, 0, finalHeight)
    local DEFAULT_SIZE = dragFrame.Size
    dragFrame.Position = UDim2.new(0.5, -finalWidth/2, 0.5, -finalHeight/2)
    dragFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 18)
    dragFrame.BackgroundTransparency = 0.15 -- Less transparent, darker background
    dragFrame.Active = true
    dragFrame.Parent = screenGui
    Instance.new("UICorner", dragFrame).CornerRadius = UDim.new(0, 8)
    
    -- ACRYLIC BLUR TRICK
    local camera = workspace.CurrentCamera
    local blurPart = Instance.new("Part")
    blurPart.Name = "AcrylicBlur"
    blurPart.Material = Enum.Material.Glass
    blurPart.Color = Color3.fromRGB(0, 0, 0)
    blurPart.Transparency = 0.995 -- Needs to be slightly opaque for glass blur to render!
    blurPart.Reflectance = 0
    blurPart.CastShadow = false
    blurPart.CanCollide = false
    blurPart.CanQuery = false
    blurPart.Anchored = true
    blurPart.Parent = camera
    
    local dof = Instance.new("DepthOfFieldEffect")
    dof.Name = "AcrylicDoF"
    dof.FarIntensity = 0
    dof.NearIntensity = 0.8
    dof.FocusDistance = 10
    dof.InFocusRadius = 20
    dof.Parent = game:GetService("Lighting")
    
    local blurConn = game:GetService("RunService").RenderStepped:Connect(function()
        if not dragFrame or not dragFrame.Parent then
            pcall(function() blurPart:Destroy() end)
            return
        end
        if not screenGui.Enabled then
            blurPart.Transparency = 1
            return
        else
            blurPart.Transparency = 0.995
        end
        -- Inset the blur slightly to avoid bleeding past the rounded corners
        local insetX = 6
        local insetY = 10
        local size = dragFrame.AbsoluteSize - Vector2.new(insetX * 2, insetY * 2)
        local pos = dragFrame.AbsolutePosition + Vector2.new(insetX, insetY)
        
        -- Fix Roblox TopBar Offset calculation natively (and add extra 4px padding so it hides under topbar)
        local topbarOffset = game:GetService("GuiService"):GetGuiInset().Y
        pos = Vector2.new(pos.X, pos.Y + topbarOffset - 4)
        
        local z = 0.2
        local fov = math.rad(camera.FieldOfView)
        local h = 2 * math.tan(fov / 2) * z
        local w = h * (camera.ViewportSize.X / camera.ViewportSize.Y)
        
        local sizeX = (size.X / camera.ViewportSize.X) * w
        local sizeY = (size.Y / camera.ViewportSize.Y) * h
        local posX = (pos.X / camera.ViewportSize.X) * w - w / 2 + sizeX / 2
        local posY = -(pos.Y / camera.ViewportSize.Y) * h + h / 2 - sizeY / 2
        
        blurPart.Size = Vector3.new(sizeX, sizeY, 0)
        blurPart.CFrame = camera.CFrame * CFrame.new(posX, posY, -z)
    end)
    table.insert(_G.RoseUI_Connections, blurConn)
    
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
    local dragCon = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            tweenService:Create(dragFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
    table.insert(_G.RoseUI_Connections, dragCon)

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(15, 10, 20) -- Darker outer line as requested
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
    
    local headerLogo = Instance.new("ImageLabel")
    headerLogo.Size = UDim2.new(0, 24, 0, 24)
    headerLogo.Position = UDim2.new(0, 10, 0.5, -12)
    headerLogo.BackgroundTransparency = 1
    headerLogo.Image = "rbxassetid://135043831839832" -- Fallback
    headerLogo.ScaleType = Enum.ScaleType.Fit
    headerLogo.ZIndex = 6
    headerLogo.Parent = headerFrame

    task.spawn(function()
        local getasset = select(2, pcall(function() return getcustomasset and getcustomasset or (getgenv and getgenv().getcustomasset) end))
        if getasset and type(getasset) == "function" then
            pcall(function()
                if isfolder and makefolder then
                    if not isfolder("RoseHub") then makefolder("RoseHub") end
                    if not isfolder("RoseHub/assets") then makefolder("RoseHub/assets") end
                end
                local path = "RoseHub/assets/rose_logo_v3_small.png"
                if isfile and not isfile(path) and writefile then
                    local success, data = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/rosehublua/rosehubimages/main/roselogo.png") end)
                    if success and data then writefile(path, data) end
                end
                if isfile and isfile(path) then headerLogo.Image = getasset(path) end
            end)
        end
    end)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -150, 1, 0)
    title.Position = UDim2.new(0, 42, 0, 0) -- Text is now closer to the smaller logo
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
    controlsFrame.Size = UDim2.new(0, 160, 1, 0)
    controlsFrame.Position = UDim2.new(1, -175, 0, 0)
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
    local homeBtn = createControlBtn("", 0)
    local maxBtn = createControlBtn("", 1)
    local minBtn = createControlBtn("-", 2)
    local closeBtn = createControlBtn("", 3)
    if options.HideDefaultTabs then
        homeBtn.Visible = false
    end
    
    local homeIcon = Instance.new("ImageLabel")
    homeIcon.Size = UDim2.new(0, 14, 0, 14)
    homeIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    homeIcon.BackgroundTransparency = 1
    homeIcon.ImageColor3 = Color3.fromRGB(255, 180, 190)
    homeIcon.ScaleType = Enum.ScaleType.Fit
    homeIcon.ZIndex = 6
    homeIcon.Parent = homeBtn

    homeBtn.MouseButton1Click:Connect(function()
        if _G.RoseHub_ShowHub then 
            _G.RoseHub_ShowHub() 
        else
            RoseUI:Notify({Title = "🏠 Home", Text = "You are already at the Master Hub!", Duration = 3})
        end
    end)
    
    local maxIcon = Instance.new("ImageLabel")
    maxIcon.Size = UDim2.new(0, 14, 0, 14)
    maxIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    maxIcon.BackgroundTransparency = 1
    maxIcon.ImageColor3 = Color3.fromRGB(255, 180, 190)
    maxIcon.ScaleType = Enum.ScaleType.Fit
    maxIcon.ZIndex = 6
    maxIcon.Parent = maxBtn
    
    -- Note: closeBtn was created above with order 0, maxBtn order 1, minBtn order 2
    
    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Size = UDim2.new(0, 14, 0, 14)
    closeIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
    closeIcon.BackgroundTransparency = 1
    closeIcon.ImageColor3 = Color3.fromRGB(255, 180, 190)
    closeIcon.ScaleType = Enum.ScaleType.Fit
    closeIcon.ZIndex = 6
    closeIcon.Parent = closeBtn
    
    task.spawn(function()
        local getasset = select(2, pcall(function() return getcustomasset and getcustomasset or (getgenv and getgenv().getcustomasset) end))
        if getasset and type(getasset) == "function" then
            pcall(function()
                if isfolder and makefolder then
                    if not isfolder("RoseHub") then makefolder("RoseHub") end
                    if not isfolder("RoseHub/assets") then makefolder("RoseHub/assets") end
                end
                
                -- Reverting to Standard Cursor per User Request            
                -- Load Tabout icon
                local taboutPath = "RoseHub/assets/tabout_white.png"
                if isfile and not isfile(taboutPath) and writefile then
                    local s, d = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/rosehublua/rosehubimages/main/white/tabout.png") end)
                    if s and d then writefile(taboutPath, d) end
                end
                if isfile and isfile(taboutPath) then maxIcon.Image = getasset(taboutPath) end
                
                -- Load Home icon
                local homePath = "RoseHub/assets/home_white.png"
                if isfile and not isfile(homePath) and writefile then
                    local s, d = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/rosehublua/rosehubimages/main/white/home.png") end)
                    if s and d then writefile(homePath, d) end
                end
                if isfile and isfile(homePath) then homeIcon.Image = getasset(homePath) end
                
                -- Load Cross icon
                local crossPath = "RoseHub/assets/cross_white.png"
                if isfile and not isfile(crossPath) and writefile then
                    local s, d = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/rosehublua/rosehubimages/main/white/cross.png") end)
                    if s and d then writefile(crossPath, d) end
                end
                if isfile and isfile(crossPath) then closeIcon.Image = getasset(crossPath) end
            end)
        end
    end)
    
    maxBtn.MouseEnter:Connect(function() tweenService:Create(maxIcon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
    maxBtn.MouseLeave:Connect(function() tweenService:Create(maxIcon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 180, 190)}):Play() end)
    
    closeBtn.MouseEnter:Connect(function() tweenService:Create(closeIcon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
    closeBtn.MouseLeave:Connect(function() tweenService:Create(closeIcon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 180, 190)}):Play() end)

    homeBtn.MouseEnter:Connect(function() tweenService:Create(homeIcon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
    homeBtn.MouseLeave:Connect(function() tweenService:Create(homeIcon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 180, 190)}):Play() end)

    local isMinimized = false
    local isMaximized = false
    local preMaxSize = DEFAULT_SIZE
    local preMaxPos = UDim2.new(0.5, -finalWidth/2, 0.5, -finalHeight/2)

    -- Header Separator Line
    local headerLine = Instance.new("Frame")
    headerLine.Name = "HeaderLine"
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0, 45)
    headerLine.BackgroundColor3 = HEADER_COLOR
    headerLine.BackgroundTransparency = 0.2
    headerLine.BorderSizePixel = 0
    headerLine.ZIndex = 2
    headerLine.Parent = dragFrame
    
    local hlGradient = Instance.new("UIGradient")
    -- Red Glow Animation Effect
    hlGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, HEADER_COLOR),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 50, 50)), -- Bright Red Center
        ColorSequenceKeypoint.new(1, HEADER_COLOR)
    })
    hlGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.4, 0.2),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.6, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
    hlGradient.Rotation = 0
    hlGradient.Offset = Vector2.new(-1, 0)
    hlGradient.Parent = headerLine
    
    -- Animate the red beam scanning from left to right
    task.spawn(function()
        while headerLine.Parent do
            hlGradient.Offset = Vector2.new(-1, 0)
            local tween = tweenService:Create(hlGradient, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Offset = Vector2.new(1, 0)})
            tween:Play()
            tween.Completed:Wait()
        end
    end)

    -- Container für Alles was nicht Header ist (zum Ein/Ausblenden bei Mini)
    local bodyContainer = Instance.new("Frame")
    bodyContainer.Name = "Body"
    bodyContainer.Size = UDim2.new(1, 0, 1, -45)
    bodyContainer.Position = UDim2.new(0, 0, 0, 45)
    bodyContainer.BackgroundTransparency = 1
    bodyContainer.ZIndex = 1
    bodyContainer.Parent = dragFrame
    bodyContainer.ClipsDescendants = true
    
    -- Hover Glow removed per user request
    -- Minimize / Toggle Logic
    local function ToggleUI()
        screenGui.Enabled = not screenGui.Enabled
        openBtnGui.Enabled = not screenGui.Enabled
        if not screenGui.Enabled then
            RoseUI:Notify({Title = "Rose Hub Minimized", Text = "Tap the logo at the top right or press Right Alt to reopen.", Duration = 4})
        end
    end
    
    minBtn.MouseButton1Click:Connect(ToggleUI)
    mobileOpenBtn.MouseButton1Click:Connect(ToggleUI)
    
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
    table.insert(_G.RoseUI_Connections, inputConnection)


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

    closeBtn.MouseButton1Click:Connect(function() 
        pcall(function() blurPart:Destroy() end)
        pcall(function() dof:Destroy() end)
        pcall(function() blurConn:Disconnect() end)
        UserInputService.MouseIcon = "" -- Reset Custom Cursor
        screenGui:Destroy() 
    end)

    -- ================= RESIZE LOGIC =================
    local function createResizeGrip(name, size, pos, dirX, dirY, iconName)
        local grip = Instance.new("TextButton")
        grip.Name = name
        grip.Size = size
        grip.Position = pos
        grip.BackgroundTransparency = 1
        grip.Text = ""
        grip.ZIndex = 50
        grip.Parent = dragFrame
        
        local isGrabbing = false
        local startSize, startMousePos, startFramePos

        grip.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isGrabbing = true
                isMaximized = false
                startSize = dragFrame.Size
                startFramePos = dragFrame.Position
                startMousePos = input.Position
            end
        end)
        
        local resEnd = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isGrabbing = false
                UserInputService.MouseIconEnabled = true
            end
        end)
        
        local resChg = UserInputService.InputChanged:Connect(function(input)
            if isGrabbing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - startMousePos
                
                local currentX = startSize.X.Offset
                local currentY = startSize.Y.Offset
                local currentPosX = startFramePos.X.Offset
                local currentPosY = startFramePos.Y.Offset
                
                local newX, newY = currentX, currentY
                local newPosX, newPosY = currentPosX, currentPosY
                
                if dirX == 1 then
                    newX = math.clamp(currentX + delta.X, 450, 1200)
                elseif dirX == -1 then
                    newX = math.clamp(currentX - delta.X, 450, 1200)
                    newPosX = currentPosX + (currentX - newX)
                end
                
                if dirY == 1 then
                    newY = math.clamp(currentY + delta.Y, 300, 1000)
                elseif dirY == -1 then
                    newY = math.clamp(currentY - delta.Y, 300, 1000)
                    newPosY = currentPosY + (currentY - newY)
                end
                
                dragFrame.Size = UDim2.new(0, newX, 0, newY)
                dragFrame.Position = UDim2.new(startFramePos.X.Scale, newPosX, startFramePos.Y.Scale, newPosY)
            end
        end)
        
        table.insert(_G.RoseUI_Connections, resEnd)
        table.insert(_G.RoseUI_Connections, resChg)

        grip.MouseEnter:Connect(function()
            if not isGrabbing then UserInputService.MouseIcon = iconName end
        end)
        grip.MouseLeave:Connect(function()
            if not isGrabbing then UserInputService.MouseIcon = "" end
        end)
    end

    -- Edges
    createResizeGrip("RightGrip", UDim2.new(0, 10, 1, -20), UDim2.new(1, -5, 0, 10), 1, 0, "rbxasset://SystemCursors/SizeWE")
    createResizeGrip("LeftGrip", UDim2.new(0, 10, 1, -20), UDim2.new(0, -5, 0, 10), -1, 0, "rbxasset://SystemCursors/SizeWE")
    createResizeGrip("BottomGrip", UDim2.new(1, -20, 0, 10), UDim2.new(0, 10, 1, -5), 0, 1, "rbxasset://SystemCursors/SizeNS")
    createResizeGrip("TopGrip", UDim2.new(1, -20, 0, 10), UDim2.new(0, 10, 0, -5), 0, -1, "rbxasset://SystemCursors/SizeNS")
    -- Corners
    createResizeGrip("TopLeftGrip", UDim2.new(0, 20, 0, 20), UDim2.new(0, -10, 0, -10), -1, -1, "rbxasset://SystemCursors/SizeNWSE")
    createResizeGrip("BottomRightGrip", UDim2.new(0, 20, 0, 20), UDim2.new(1, -10, 1, -10), 1, 1, "rbxasset://SystemCursors/SizeNWSE")
    createResizeGrip("TopRightGrip", UDim2.new(0, 20, 0, 20), UDim2.new(1, -10, 0, -10), 1, -1, "rbxasset://SystemCursors/SizeNESW")
    createResizeGrip("BottomLeftGrip", UDim2.new(0, 20, 0, 20), UDim2.new(0, -10, 1, -10), -1, 1, "rbxasset://SystemCursors/SizeNESW")


    -- ==========================================
    -- SIDEBAR (Links - Dunkles Rose)
    -- ==========================================
    local isSidebarExpanded = false
    local sidebarElements = { labels = {} }

    local sidebarFrame = Instance.new("Frame")
    sidebarFrame.Name = "Sidebar"
    sidebarFrame.Size = UDim2.new(0, 50, 1, 0)
    sidebarFrame.Position = UDim2.new(0, 0, 0, 0)
    sidebarFrame.BackgroundTransparency = 1
    sidebarFrame.BorderSizePixel = 0
    sidebarFrame.ZIndex = 2
    sidebarFrame.Parent = bodyContainer

    -- FPS Label and Separator removed by user request

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(1, -10, 1, -125) -- Mehr Platz fuer das Profil unten lassen und Pfeile
    tabContainer.Position = UDim2.new(0, 5, 0, 15) -- Home Icon bisschen höher ziehen
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 0 
    tabContainer.ZIndex = 3
    tabContainer.Parent = sidebarFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = tabContainer
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 12) -- Larger Gap between tabs and lines

    -- Scroll Indicators
    local scrollUpInd = Instance.new("TextLabel")
    scrollUpInd.Size = UDim2.new(0, 24, 0, 24)
    scrollUpInd.Position = UDim2.new(0.5, -12, 0, 5)
    scrollUpInd.BackgroundTransparency = 1
    scrollUpInd.Text = "▲"
    scrollUpInd.TextColor3 = Color3.fromRGB(255, 40, 40) -- Extra bright red
    scrollUpInd.TextTransparency = 1
    scrollUpInd.Font = Enum.Font.GothamBold
    scrollUpInd.TextSize = 24
    scrollUpInd.ZIndex = 4
    scrollUpInd.Parent = sidebarFrame

    local scrollDownInd = Instance.new("TextLabel")
    scrollDownInd.Size = UDim2.new(0, 24, 0, 24)
    scrollDownInd.Position = UDim2.new(0.5, -12, 1, -135) -- Pulled much higher above the avatar
    scrollDownInd.BackgroundTransparency = 1
    scrollDownInd.Text = "▼"
    scrollDownInd.TextColor3 = Color3.fromRGB(255, 40, 40) -- Extra bright red
    scrollDownInd.TextTransparency = 1
    scrollDownInd.Font = Enum.Font.GothamBold
    scrollDownInd.TextSize = 24
    scrollDownInd.ZIndex = 4
    scrollDownInd.Parent = sidebarFrame
    
    local function updateScrollIndicators()
        local cPos = tabContainer.CanvasPosition.Y
        local windowY = tabContainer.AbsoluteWindowSize.Y
        local contentY = tabContainer.CanvasSize.Y.Offset
        
        if contentY > windowY then
            if cPos > 5 then
                tweenService:Create(scrollUpInd, TweenInfo.new(0.2), {TextTransparency = 0.5}):Play()
            else
                tweenService:Create(scrollUpInd, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            end
            
            if cPos + windowY < contentY - 5 then
                tweenService:Create(scrollDownInd, TweenInfo.new(0.2), {TextTransparency = 0.5}):Play()
            else
                tweenService:Create(scrollDownInd, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            end
        else
            tweenService:Create(scrollUpInd, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            tweenService:Create(scrollDownInd, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        end
    end

    tabContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScrollIndicators)
    tabContainer:GetPropertyChangedSignal("CanvasSize"):Connect(updateScrollIndicators)
    tabContainer:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollIndicators)
    
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 20)
        updateScrollIndicators()
    end)

    -- ==========================================
    -- USER PROFILE AREA (Sidebar Unten Links)
    -- ==========================================
    local profileFrame = Instance.new("Frame")
    profileFrame.Size = UDim2.new(1, -16, 0, 44)
    profileFrame.Position = UDim2.new(0, 8, 1, -55)
    profileFrame.BackgroundColor3 = Color3.fromRGB(25, 18, 30)
    profileFrame.BackgroundTransparency = 0.4
    profileFrame.ZIndex = 3
    profileFrame.Parent = sidebarFrame
    Instance.new("UICorner", profileFrame).CornerRadius = UDim.new(1, 0) -- Perfect Pill Shape

    local profileStroke = Instance.new("UIStroke")
    profileStroke.Color = Color3.fromRGB(120, 90, 150)
    profileStroke.Transparency = 0.6
    profileStroke.Thickness = 1
    profileStroke.Parent = profileFrame

    local localPlayer = game:GetService("Players").LocalPlayer
    local pName = localPlayer and localPlayer.Name or "Guest"
    local pId = localPlayer and localPlayer.UserId or 1
    
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(0, 30, 0, 30)
    avatarImg.Position = UDim2.new(0, 7, 0.5, -15)
    avatarImg.BackgroundColor3 = Color3.fromRGB(15, 12, 18)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. pId .. "&w=150&h=150"
    avatarImg.ZIndex = 4
    avatarImg.Parent = profileFrame
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
    
    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = HEADER_COLOR
    avatarStroke.Transparency = 0.5
    avatarStroke.Thickness = 1
    avatarStroke.Parent = avatarImg
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -45, 0, 14)
    nameLbl.Position = UDim2.new(0, 44, 0, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = pName
    nameLbl.TextColor3 = TEXT_COLOR
    nameLbl.TextTransparency = 1
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 4
    nameLbl.Parent = profileFrame
    table.insert(sidebarElements.labels, nameLbl)

    local rankLbl = Instance.new("TextLabel")
    rankLbl.Size = UDim2.new(1, -45, 0, 14)
    rankLbl.Position = UDim2.new(0, 44, 0, 22)
    rankLbl.BackgroundTransparency = 1
    rankLbl.Text = "Free User"
    rankLbl.TextColor3 = HEADER_COLOR
    rankLbl.TextTransparency = 1
    rankLbl.Font = Enum.Font.Gotham
    rankLbl.TextSize = 9
    rankLbl.TextXAlignment = Enum.TextXAlignment.Left
    rankLbl.ZIndex = 4
    rankLbl.Parent = profileFrame
    table.insert(sidebarElements.labels, rankLbl)
    
    -- ==========================================
    -- CONTENT AREA (Rechts)
    -- ==========================================
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentArea"
    contentFrame.Size = UDim2.new(1, -50, 1, 0)
    contentFrame.Position = UDim2.new(0, 50, 0, 0)
    contentFrame.BackgroundColor3 = CONTENT_COLOR
    contentFrame.BackgroundTransparency = 0.15 -- Less transparency 
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

    local function setSidebarExpanded(state)
        if isSidebarExpanded == state then return end
        isSidebarExpanded = state
        
        local targetWidth = state and 160 or 50
        local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        
        tweenService:Create(sidebarFrame, tInfo, {Size = UDim2.new(0, targetWidth, 1, 0)}):Play()
        tweenService:Create(contentFrame, tInfo, {
            Size = UDim2.new(1, -targetWidth, 1, 0),
            Position = UDim2.new(0, targetWidth, 0, 0)
        }):Play()
        
        local textAlpha = state and 0 or 1
        local profileBackgroundAlpha = state and 0.4 or 1
        local profileStrokeAlpha = state and 0.6 or 1
        
        local pStroke = profileFrame:FindFirstChildOfClass("UIStroke")
        if pStroke then tweenService:Create(pStroke, tInfo, {Transparency = profileStrokeAlpha}):Play() end
        tweenService:Create(profileFrame, tInfo, {BackgroundTransparency = profileBackgroundAlpha}):Play()
        
        for _, lbl in ipairs(sidebarElements.labels) do
            if lbl and lbl.Parent then
                tweenService:Create(lbl, tInfo, {TextTransparency = textAlpha}):Play()
            end
        end
    end

    sidebarFrame.MouseEnter:Connect(function() setSidebarExpanded(true) end)
    sidebarFrame.MouseLeave:Connect(function() setSidebarExpanded(false) end)
    sidebarFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            setSidebarExpanded(true)
        end
    end)
    contentFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and isSidebarExpanded then
            setSidebarExpanded(false)
        end
    end)
    
    -- ==========================================
    -- API OBJECT & CONFIGS
    -- ==========================================
    local WindowObj = {
        CurrentTab = nil,
        Tabs = {},
        Elements = {},
        ConfigFolder = options.ConfigFolder or "RoseHub/configs",
        ConfigRefreshListener = function() end,
        ID = currentID,
        TitleLabel = title,
        HubTypeLabel = hubTypeText
    }
    
    RoseUI.CurrentWindow = WindowObj
    
    if makefolder and not isfolder("RoseHub") then makefolder("RoseHub") end
    if makefolder and not isfolder(WindowObj.ConfigFolder) then makefolder(WindowObj.ConfigFolder) end


    
    function WindowObj:SaveConfig(fileName)
        local data = {}
        for _, elem in ipairs(self.Elements) do
            if elem.Type == "ColorPicker" then
                data[elem.Name] = {elem.Value.R, elem.Value.G, elem.Value.B}
            elseif elem.Type == "Keybind" then
                data[elem.Name] = elem.Value.Name
            elseif elem.Type == "ToggleSlider" then
                data[elem.Name] = {Toggle = elem.ToggleValue, Slider = elem.SliderValue}
            elseif elem.Value ~= nil then
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
                            if type(rgb) == "table" and #rgb >= 3 then
                                pcall(function() elem:Set(Color3.new(rgb[1], rgb[2], rgb[3])) end)
                            end
                        elseif elem.Type == "Keybind" then
                            pcall(function() elem:Set(Enum.KeyCode[data[elem.Name]]) end)
                        elseif elem.Type == "ToggleSlider" then
                            local vals = data[elem.Name]
                            if type(vals) == "table" then
                                if vals.Toggle ~= nil then pcall(function() elem:SetToggle(vals.Toggle) end) end
                                if vals.Slider ~= nil then pcall(function() elem:SetSlider(vals.Slider) end) end
                            end
                        else
                            pcall(function() elem:Set(data[elem.Name]) end)
                        end
                    end
                end
                RoseUI:Notify({Title = "🌹 Config Loaded", Text = "Loaded settings from " .. fileName .. ".json.", Duration = 4})
            end
        end
    end
    
    function WindowObj:MakeTab(tabOptions)
        local rawName = tabOptions.Name or "Tab"
        local tabName = rawName
        local extractedEmoji = nil
        
        -- Smart Parsing: If there's an Emoji buried in the name, pull it out automatically!
        -- Matches most common emoji ranges (UTF8) loosely by finding non-ascii leading characters before text.
        local foundEmoji, cleanName = utf8.charpattern and string.match(rawName, "^([%z\1-\127\194-\244][\128-\191]*)%s*(.*)")
        -- Fallback lua match for emojis: anything outside standard ascii range
        if not foundEmoji then
            foundEmoji, cleanName = string.match(rawName, "^([^%w%pn]+)%s*(.*)")
        end
        
        if foundEmoji and foundEmoji ~= "" and cleanName and cleanName ~= "" then
            -- We successfully stripped an emoji! 
            extractedEmoji = foundEmoji
            tabName = cleanName
        end
        
        local tabIcon = tabOptions.Icon or "rbxassetid://10652380582" -- Default Icon
        local emojiIcon = tabOptions.EmojiIcon or extractedEmoji
        
        local noSeparator = tabOptions.NoSeparator or false
        local forceSeparator = tabOptions.ForceSeparator or false
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 35)
        tabBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 45)
        tabBtn.BackgroundTransparency = 0.4 -- Made highly visible so the boxes don't get lost
        tabBtn.Text = ""
        tabBtn.LayoutOrder = tabOptions.LayoutOrder or (#WindowObj.Tabs + 1)
        tabBtn.ZIndex = 4
        tabBtn.Parent = tabContainer
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = HEADER_COLOR
        btnStroke.Transparency = 0.6 -- Made highly visible
        btnStroke.Thickness = 1
        btnStroke.Parent = tabBtn
        
        local tabIconImg = Instance.new("ImageLabel")
        tabIconImg.Size = UDim2.new(0, 16, 0, 16)
        tabIconImg.Position = UDim2.new(0, 12, 0.5, -8) -- Centered perfectly in 40px width
        tabIconImg.BackgroundTransparency = 1
        tabIconImg.ImageColor3 = Color3.fromRGB(255, 255, 255) -- White Icons
        tabIconImg.ZIndex = 5
        tabIconImg.Parent = tabBtn

        local tabIconText = Instance.new("TextLabel")
        tabIconText.Size = UDim2.new(0, 16, 0, 16)
        tabIconText.Position = UDim2.new(0, 12, 0.5, -8)
        tabIconText.BackgroundTransparency = 1
        tabIconText.TextColor3 = Color3.fromRGB(255, 255, 255) -- White Icons
        tabIconText.Font = Enum.Font.GothamBold
        tabIconText.TextSize = 13
        tabIconText.ZIndex = 5
        tabIconText.Parent = tabBtn

        local tabLabel = Instance.new("TextLabel")
        tabLabel.BackgroundTransparency = 1
        tabLabel.Text = tabName
        tabLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- White/Light Gray for unselected tabs
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.Font = Enum.Font.GothamSemibold
        tabLabel.TextSize = 13
        tabLabel.TextTransparency = 1 -- Hidden by default
        tabLabel.ZIndex = 5
        tabLabel.Parent = tabBtn
        table.insert(sidebarElements.labels, tabLabel)

        if RoseUI.SafeMode and emojiIcon then
            tabIconImg.Visible = false
            tabIconText.Visible = true
            tabIconText.Text = emojiIcon
            tabLabel.Size = UDim2.new(1, -33, 1, 0)
            tabLabel.Position = UDim2.new(0, 33, 0, 0)
        elseif tabIcon == "" then
            tabIconImg.Visible = false
            tabIconText.Visible = false
            tabLabel.Size = UDim2.new(1, -20, 1, 0)
            tabLabel.Position = UDim2.new(0, 15, 0, 0)
        elseif string.match(tabIcon, "rbxassetid://") then
            tabIconImg.Image = tabIcon
            tabIconText.Visible = false
            tabLabel.Size = UDim2.new(1, -33, 1, 0)
            tabLabel.Position = UDim2.new(0, 33, 0, 0)
        elseif string.match(tabIcon, "%.png") or string.match(tabIcon, "http") then
            tabIconImg.Image = ""
            tabIconText.Visible = false
            tabLabel.Size = UDim2.new(1, -33, 1, 0)
            tabLabel.Position = UDim2.new(0, 33, 0, 0)
            
            task.spawn(function()
                local getasset = select(2, pcall(function() return getcustomasset and getcustomasset or (getgenv and getgenv().getcustomasset) end))
                if getasset and type(getasset) == "function" then
                    if not isfolder("RoseHub") then makefolder("RoseHub") end
                    if not isfolder("RoseHub/assets") then makefolder("RoseHub/assets") end
                    
                    local fileName = string.match(tabIcon, "([^/]+%.png)$") or "icon.png"
                    local path = "RoseHub/assets/white_" .. fileName
                    
                    if not isfile(path) then
                        local url = tabIcon
                        if not string.match(url, "http") then
                            url = "https://raw.githubusercontent.com/rosehublua/rosehubimages/main/white/" .. tabIcon
                        end
                        local s, d = pcall(function() return game:HttpGet(url) end)
                        if s and d then writefile(path, d) end
                    end
                    if isfile(path) then tabIconImg.Image = getasset(path) end
                end
            end)
        else
            tabIconImg.Visible = false
            tabIconText.Text = tabIcon
            tabLabel.Size = UDim2.new(1, -33, 1, 0)
            tabLabel.Position = UDim2.new(0, 33, 0, 0)
        end
        
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
        pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Fixes UIStroke cut off on the left
        
        -- TAB TITLE INSIDE THE PAGE
        local topTitle = Instance.new("TextLabel")
        topTitle.Name = "TabTitle"
        topTitle.Size = UDim2.new(1, 0, 0, 30)
        topTitle.BackgroundTransparency = 1
        topTitle.Text = tabName
        topTitle.TextColor3 = TEXT_COLOR
        topTitle.TextXAlignment = Enum.TextXAlignment.Left
        topTitle.Font = Enum.Font.GothamBold
        topTitle.TextSize = 20
        topTitle.Parent = page
        
        local titleLine = Instance.new("Frame")
        titleLine.Name = "TitleDiv"
        titleLine.Size = UDim2.new(1, -10, 0, 1)
        titleLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        titleLine.BackgroundTransparency = 0.9
        titleLine.BorderSizePixel = 0
        titleLine.Parent = page
        
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 10)
        end)
        
        -- Fancy Slide in/out Logic (Ultra Smooth)
        local isSwitching = false
        local function SelectTabFunction()
            if WindowObj.CurrentTab == page or isSwitching then return end
            isSwitching = true

            local oldPage = WindowObj.CurrentTab

            -- Premium Tab Button Animations (Exponential Smooth)
            local tabTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            for _, t in pairs(WindowObj.Tabs) do
                local tStroke = t.Btn:FindFirstChildOfClass("UIStroke")
                if t.Page == page then
                    tweenService:Create(t.Btn, tabTweenInfo, {BackgroundTransparency = 0.1}):Play()
                    if tStroke then tweenService:Create(tStroke, tabTweenInfo, {Transparency = 0.1}):Play() end
                    tweenService:Create(t.Lbl, tabTweenInfo, {TextColor3 = TEXT_COLOR}):Play()
                    tweenService:Create(t.Img, tabTweenInfo, {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    if t.TxtIcon then tweenService:Create(t.TxtIcon, tabTweenInfo, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play() end
                else
                    tweenService:Create(t.Btn, tabTweenInfo, {BackgroundTransparency = 0.4}):Play()
                    if tStroke then tweenService:Create(tStroke, tabTweenInfo, {Transparency = 0.6}):Play() end
                    tweenService:Create(t.Lbl, tabTweenInfo, {TextColor3 = Color3.fromRGB(140, 140, 140)}):Play()
                    tweenService:Create(t.Img, tabTweenInfo, {ImageColor3 = Color3.fromRGB(140, 140, 140)}):Play()
                    if t.TxtIcon then tweenService:Create(t.TxtIcon, tabTweenInfo, {TextColor3 = Color3.fromRGB(140, 140, 140)}):Play() end
                end
            end

            -- Slide old page out smoothly
            if oldPage then
                tweenService:Create(oldPage, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0, 10, 0, 40)}):Play()
            end
            
            task.wait(0.15) -- Tiny delay for a staggered overlap effect
            
            if oldPage then oldPage.Visible = false end

            -- Slide new page in with an ultra clean snap
            WindowObj.CurrentTab = page
            page.Visible = true
            page.Position = UDim2.new(0, 10, 0, 50) -- Start lower
            tweenService:Create(page, TweenInfo.new(0.65, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 10, 0, 10)}):Play()
            
            task.wait(0.2)
            isSwitching = false
        end
        tabBtn.MouseButton1Click:Connect(SelectTabFunction)
        
        -- Setze ersten Tab aktiv
        if #WindowObj.Tabs == 0 then
            page.Visible = true
            page.Position = UDim2.new(0, 10, 0, 10)
            tabBtn.BackgroundTransparency = 0.1
            local bStroke = tabBtn:FindFirstChildOfClass("UIStroke")
            if bStroke then bStroke.Transparency = 0.1 end
            tabLabel.TextColor3 = TEXT_COLOR
            tabIconImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
            tabIconText.TextColor3 = Color3.fromRGB(255, 255, 255)
            WindowObj.CurrentTab = page
        end
        
        table.insert(WindowObj.Tabs, {Btn = tabBtn, Page = page, Lbl = tabLabel, Img = tabIconImg, TxtIcon = tabIconText})
        
        local TabObj = {
            Btn = tabBtn,
            Select = SelectTabFunction
        }
        
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
            sectionLabel.Size = UDim2.new(1, -30, 0, 30)
            sectionLabel.Position = UDim2.new(0, 15, 0, 0)
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
            proxyMethod("AddToggleSlider")
            proxyMethod("AddDropdown")
            proxyMethod("AddSearchDropdown")
            proxyMethod("AddTargetList")
            proxyMethod("AddColorPicker")
            proxyMethod("AddLabel")
            proxyMethod("AddTextbox")
            proxyMethod("AddKeybind")
            proxyMethod("AddInventoryGrid")
            proxyMethod("AddPlotGrid")
            proxyMethod("AddDashboardRow")
            proxyMethod("AddDashboardFullCard")
            
            return SectionAPI
        end
        
        -- 0.5 DASHBOARD ROW
        function TabObj:AddDashboardRow(rowOptions)
            local rowFrame = Instance.new("Frame")
            rowFrame.Size = UDim2.new(1, -10, 0, 85)
            rowFrame.BackgroundTransparency = 1
            rowFrame.ZIndex = 11
            rowFrame.Parent = page
            
            local rowLayout = Instance.new("UIListLayout")
            rowLayout.Parent = rowFrame
            rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
            rowLayout.FillDirection = Enum.FillDirection.Horizontal
            rowLayout.Padding = UDim.new(0, 10)
            
            -- Left Banner
            if rowOptions.Banner then
                local bannerCard = Instance.new("Frame")
                bannerCard.Size = UDim2.new(0.5, -5, 1, 0)
                bannerCard.BackgroundColor3 = Color3.fromRGB(30, 15, 25)
                bannerCard.ClipsDescendants = true
                bannerCard.ZIndex = 11
                bannerCard.Parent = rowFrame
                Instance.new("UICorner", bannerCard).CornerRadius = UDim.new(0, 6)
                
                local bgImage = Instance.new("ImageLabel")
                bgImage.Size = UDim2.new(1, 0, 1, 0)
                bgImage.BackgroundTransparency = 1
                bgImage.Image = rowOptions.Banner.Image or "rbxassetid://10459521360"
                bgImage.ImageColor3 = Color3.fromRGB(180, 150, 255)
                bgImage.ImageTransparency = 0.4
                bgImage.ScaleType = Enum.ScaleType.Crop
                bgImage.ZIndex = 11
                bgImage.Parent = bannerCard
                
                local gradient = Instance.new("UIGradient")
                gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                    ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
                })
                gradient.Rotation = 45
                gradient.Parent = bannerCard
                
                local bTitle = Instance.new("TextLabel")
                bTitle.Size = UDim2.new(1, -20, 0, 20)
                bTitle.Position = UDim2.new(0, 15, 0, 25)
                bTitle.BackgroundTransparency = 1
                bTitle.Text = rowOptions.Banner.Title or "Title"
                bTitle.TextColor3 = Color3.new(1,1,1)
                bTitle.Font = Enum.Font.GothamBold
                bTitle.TextSize = 16
                bTitle.TextXAlignment = Enum.TextXAlignment.Left
                bTitle.ZIndex = 12
                bTitle.Parent = bannerCard
                
                local bDesc = Instance.new("TextLabel")
                bDesc.Size = UDim2.new(1, -20, 0, 30)
                bDesc.Position = UDim2.new(0, 15, 0, 45)
                bDesc.BackgroundTransparency = 1
                bDesc.Text = rowOptions.Banner.Desc or "Description"
                bDesc.TextColor3 = Color3.fromRGB(200, 180, 220)
                bDesc.Font = Enum.Font.Gotham
                bDesc.TextSize = 12
                bDesc.TextWrapped = true
                bDesc.TextYAlignment = Enum.TextYAlignment.Top
                bDesc.TextXAlignment = Enum.TextXAlignment.Left
                bDesc.ZIndex = 12
                bDesc.Parent = bannerCard
            end
            
            -- Right Ring Card
            if rowOptions.Ring then
                local ringCard = Instance.new("Frame")
                ringCard.Size = UDim2.new(0.5, -5, 1, 0)
                ringCard.BackgroundColor3 = CARD_COLOR
                ringCard.ZIndex = 11
                ringCard.Parent = rowFrame
                Instance.new("UICorner", ringCard).CornerRadius = UDim.new(0, 6)
                
                local ringContainer = Instance.new("Frame")
                ringContainer.Size = UDim2.new(0, 60, 0, 60)
                ringContainer.Position = UDim2.new(0, 10, 0.5, -30)
                ringContainer.BackgroundTransparency = 1
                ringContainer.ZIndex = 12
                ringContainer.Parent = ringCard
                
                local ringBg = Instance.new("Frame")
                ringBg.Size = UDim2.new(1, 0, 1, 0)
                ringBg.BackgroundColor3 = Color3.fromRGB(40, 30, 45)
                ringBg.ZIndex = 12
                ringBg.Parent = ringContainer
                Instance.new("UICorner", ringBg).CornerRadius = UDim.new(1, 0)
                
                local ringStroke = Instance.new("UIStroke")
                ringStroke.Color = rowOptions.Ring.Color or Color3.fromRGB(150, 100, 200)
                ringStroke.Thickness = 5
                ringStroke.Transparency = 0.5
                ringStroke.Parent = ringBg
                
                local ringNum = Instance.new("TextLabel")
                ringNum.Size = UDim2.new(1, 0, 0, 20)
                ringNum.Position = UDim2.new(0, 0, 0.5, -15)
                ringNum.BackgroundTransparency = 1
                ringNum.Text = tostring(rowOptions.Ring.Number or "0")
                ringNum.TextColor3 = rowOptions.Ring.Color or Color3.fromRGB(200, 180, 255)
                ringNum.Font = Enum.Font.GothamBold
                ringNum.TextSize = 18
                ringNum.ZIndex = 13
                ringNum.Parent = ringContainer
                
                local ringLbl = Instance.new("TextLabel")
                ringLbl.Size = UDim2.new(1, 0, 0, 10)
                ringLbl.Position = UDim2.new(0, 0, 0.5, 5)
                ringLbl.BackgroundTransparency = 1
                ringLbl.Text = tostring(rowOptions.Ring.Label or "UNITS")
                ringLbl.TextColor3 = Color3.fromRGB(140, 120, 160)
                ringLbl.Font = Enum.Font.GothamBold
                ringLbl.TextSize = 9
                ringLbl.ZIndex = 13
                ringLbl.Parent = ringContainer
                
                local rTitle = Instance.new("TextLabel")
                rTitle.Size = UDim2.new(1, -85, 0, 16)
                rTitle.Position = UDim2.new(0, 80, 0, 10)
                rTitle.BackgroundTransparency = 1
                rTitle.Text = rowOptions.Ring.Title or "Title"
                rTitle.TextColor3 = Color3.new(1,1,1)
                rTitle.Font = Enum.Font.GothamBold
                rTitle.TextSize = 15
                rTitle.TextXAlignment = Enum.TextXAlignment.Left
                rTitle.ZIndex = 12
                rTitle.Parent = ringCard
                
                local rDesc = Instance.new("TextLabel")
                rDesc.Size = UDim2.new(1, -85, 0, 14)
                rDesc.Position = UDim2.new(0, 80, 0, 28)
                rDesc.BackgroundTransparency = 1
                rDesc.Text = rowOptions.Ring.Desc or "Description"
                rDesc.TextColor3 = Color3.fromRGB(230, 230, 230)
                rDesc.Font = Enum.Font.GothamBold
                rDesc.TextSize = 12
                rDesc.TextXAlignment = Enum.TextXAlignment.Left
                rDesc.ZIndex = 12
                rDesc.Parent = ringCard

                local rSub = Instance.new("TextLabel")
                rSub.Size = UDim2.new(1, -85, 0, 30)
                rSub.Position = UDim2.new(0, 80, 0, 44)
                rSub.BackgroundTransparency = 1
                rSub.Text = rowOptions.Ring.Message or ""
                rSub.TextColor3 = rowOptions.Ring.MessageColor or Color3.fromRGB(160, 140, 150)
                rSub.Font = Enum.Font.Gotham
                rSub.TextSize = 10
                rSub.TextWrapped = true
                rSub.TextYAlignment = Enum.TextYAlignment.Top
                rSub.TextXAlignment = Enum.TextXAlignment.Left
                rSub.ZIndex = 12
                rSub.Parent = ringCard
            end
        end
        
        -- 0.6 DASHBOARD FULL CARD
        function TabObj:AddDashboardFullCard(cardOptions)
            local cardFrame = Instance.new("Frame")
            cardFrame.Size = UDim2.new(1, -10, 0, 80)
            cardFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
            cardFrame.ClipsDescendants = true
            cardFrame.ZIndex = 11
            cardFrame.Parent = page
            Instance.new("UICorner", cardFrame).CornerRadius = UDim.new(0, 6)
            
            local bgImage = Instance.new("ImageLabel")
            bgImage.Size = UDim2.new(1, 0, 1, 0)
            bgImage.BackgroundTransparency = 1
            bgImage.Image = cardOptions.Image or "rbxassetid://10459521360"
            bgImage.ImageColor3 = cardOptions.ImageColor or Color3.fromRGB(80, 150, 255)
            bgImage.ImageTransparency = 0.6
            bgImage.ScaleType = Enum.ScaleType.Crop
            bgImage.ZIndex = 11
            bgImage.Parent = cardFrame
            
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
            })
            gradient.Rotation = -45
            gradient.Parent = cardFrame

            local cTitle = Instance.new("TextLabel")
            cTitle.Size = UDim2.new(1, -30, 0, 20)
            cTitle.Position = UDim2.new(0, 15, 0, 15)
            cTitle.BackgroundTransparency = 1
            cTitle.Text = cardOptions.Title or "Server Info"
            cTitle.TextColor3 = Color3.new(1,1,1)
            cTitle.Font = Enum.Font.GothamBold
            cTitle.TextSize = 16
            cTitle.TextXAlignment = Enum.TextXAlignment.Left
            cTitle.ZIndex = 12
            cTitle.Parent = cardFrame
            
            local cDesc = Instance.new("TextLabel")
            cDesc.Size = UDim2.new(1, -30, 0, 35)
            cDesc.Position = UDim2.new(0, 15, 0, 35)
            cDesc.BackgroundTransparency = 1
            cDesc.Text = cardOptions.Desc or "Loading server data..."
            cDesc.TextColor3 = Color3.fromRGB(200, 220, 255)
            cDesc.Font = Enum.Font.Gotham
            cDesc.TextSize = 12
            cDesc.TextWrapped = true
            cDesc.TextXAlignment = Enum.TextXAlignment.Left
            cDesc.TextYAlignment = Enum.TextYAlignment.Top
            cDesc.ZIndex = 12
            cDesc.Parent = cardFrame
            
            return {
                Frame = cardFrame,
                Title = cTitle,
                Desc = cDesc
            }
        end
        
        -- 1. BUTTON
        function TabObj:AddButton(btnOptions)
            local bName = btnOptions.Name or "Button"
            local bDesc = btnOptions.Description or nil
            local cb = btnOptions.Callback or function() end
            local h = bDesc and 56 or 38
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, h)
            btn.BackgroundColor3 = CARD_COLOR
            btn.Text = ""
            btn.ZIndex = 11
            btn.Parent = page
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            local titleLbl = Instance.new("TextLabel")
            titleLbl.Size = UDim2.new(1, -40, 0, bDesc and 28 or h)
            titleLbl.Position = UDim2.new(0, 15, 0, bDesc and 4 or 0)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text = bName
            titleLbl.TextColor3 = TEXT_COLOR
            titleLbl.Font = Enum.Font.GothamBold
            titleLbl.TextSize = 13
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.ZIndex = 12
            titleLbl.Parent = btn

            if bDesc then
                local descLbl = Instance.new("TextLabel")
                descLbl.Size = UDim2.new(1, -40, 0, 20)
                descLbl.Position = UDim2.new(0, 15, 0, 28)
                descLbl.BackgroundTransparency = 1
                descLbl.Text = bDesc
                descLbl.TextColor3 = Color3.fromRGB(160, 140, 150)
                descLbl.Font = Enum.Font.Gotham
                descLbl.TextSize = 11
                descLbl.TextXAlignment = Enum.TextXAlignment.Left
                descLbl.TextWrapped = true
                descLbl.ZIndex = 12
                descLbl.Parent = btn
            end

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
            btn.MouseButton1Down:Connect(function() tweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0.98, -10, 0, h - 3)}):Play() end)
            btn.MouseButton1Up:Connect(function() tweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(1, -10, 0, h)}):Play() end)
            btn.MouseButton1Click:Connect(cb)
        end

        -- 2. TOGGLE
        function TabObj:AddToggle(toggleOptions)
            local tName = toggleOptions.Name or "Toggle"
            local tDesc = toggleOptions.Description or nil
            local cb = toggleOptions.Callback or toggleOptions.OnToggle or function() end
            local defaultParams = toggleOptions.Default or false
            local isNested = toggleOptions.Nested or false
            local isToggled = defaultParams
            local h = tDesc and 56 or 42
            
            local toggleFrame = Instance.new("Frame")
            
            if isNested then
                toggleFrame.Size = UDim2.new(1, -25, 0, h)
                toggleFrame.Position = UDim2.new(0, 15, 0, 0)
            else
                toggleFrame.Size = UDim2.new(1, -10, 0, h)
            end
            
            toggleFrame.BackgroundColor3 = CARD_COLOR
            toggleFrame.ClipsDescendants = true
            toggleFrame.ZIndex = 11
            toggleFrame.Parent = page
            Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 0, tDesc and 28 or h)
            label.Position = UDim2.new(0, 15, 0, tDesc and 4 or 0)
            label.BackgroundTransparency = 1
            label.Text = tName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 12
            label.Parent = toggleFrame

            if tDesc then
                local descLbl = Instance.new("TextLabel")
                descLbl.Size = UDim2.new(1, -60, 0, 20)
                descLbl.Position = UDim2.new(0, 15, 0, 28)
                descLbl.BackgroundTransparency = 1
                descLbl.Text = tDesc
                descLbl.TextColor3 = Color3.fromRGB(160, 140, 150)
                descLbl.Font = Enum.Font.Gotham
                descLbl.TextSize = 11
                descLbl.TextXAlignment = Enum.TextXAlignment.Left
                descLbl.TextWrapped = true
                descLbl.ZIndex = 12
                descLbl.Parent = toggleFrame
            end

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
            local currentTween
            
            function ToggleAPI:Hide()
                if currentTween then currentTween:Cancel() end
                currentTween = tweenService:Create(toggleFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(isNested and 1 or 1, isNested and -25 or -10, 0, 0)})
                currentTween:Play()
                task.spawn(function()
                    currentTween.Completed:Wait()
                    if toggleFrame.Size.Y.Offset == 0 then toggleFrame.Visible = false end
                end)
            end
            
            function ToggleAPI:Show()
                toggleFrame.Visible = true
                if currentTween then currentTween:Cancel() end
                currentTween = tweenService:Create(toggleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(isNested and 1 or 1, isNested and -25 or -10, 0, h)})
                currentTween:Play()
            end
            
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
            
            ToggleAPI.Instance = toggleFrame
            table.insert(WindowObj.Elements, ToggleAPI)
            return ToggleAPI
        end

        -- 3. SLIDER
        function TabObj:AddSlider(sliderOptions)
            local sName = sliderOptions.Name or "Slider"
            local sDesc = sliderOptions.Description or nil
            local min = sliderOptions.Min or 0
            local max = sliderOptions.Max or 100
            local default = sliderOptions.Default or 50
            local cb = sliderOptions.Callback or function() end
            local h = sDesc and 74 or 50
            
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, -10, 0, h)
            sliderFrame.BackgroundColor3 = CARD_COLOR
            sliderFrame.ZIndex = 11
            sliderFrame.Parent = page
            Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 6)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 0, sDesc and 30 or 25)
            label.Position = UDim2.new(0, 15, 0, sDesc and -2 or 0)
            label.BackgroundTransparency = 1
            label.Text = sName
            label.TextColor3 = TEXT_COLOR
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 12
            label.Parent = sliderFrame

            if sDesc then
                local descLbl = Instance.new("TextLabel")
                descLbl.Size = UDim2.new(1, -60, 0, 20)
                descLbl.Position = UDim2.new(0, 15, 0, 24)
                descLbl.BackgroundTransparency = 1
                descLbl.Text = sDesc
                descLbl.TextColor3 = Color3.fromRGB(160, 140, 150)
                descLbl.Font = Enum.Font.Gotham
                descLbl.TextSize = 11
                descLbl.TextXAlignment = Enum.TextXAlignment.Left
                descLbl.TextWrapped = true
                descLbl.ZIndex = 12
                descLbl.Parent = sliderFrame
            end

            local highlightBox = Instance.new("Frame")
            highlightBox.Size = UDim2.new(0, 45, 0, 20)
            highlightBox.Position = UDim2.new(1, -55, 0, sDesc and 12 or 5)
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
            slideBg.Position = UDim2.new(0, 15, 0, sDesc and 54 or 32)
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

        -- 3.5 TOGGLE-SLIDER (Hybrid Component)
        function TabObj:AddToggleSlider(tsOptions)
            local tsName = tsOptions.Name or "ToggleSlider"
            local min = tsOptions.Min or 0
            local max = tsOptions.Max or 100
            local defSlider = tsOptions.DefaultSlider or math.floor((min + max) / 2)
            local defToggle = tsOptions.DefaultToggle or false
            local suffix = tsOptions.Suffix or ""
            local cbToggle = tsOptions.CallbackToggle or tsOptions.OnToggle or function() end
            local cbSlider = tsOptions.CallbackSlider or tsOptions.OnSlider or function() end
            
            local tsFrame = Instance.new("Frame")
            tsFrame.Size = UDim2.new(1, -10, 0, 70)
            tsFrame.BackgroundColor3 = CARD_COLOR
            tsFrame.ZIndex = 11
            tsFrame.Parent = page
            Instance.new("UICorner", tsFrame).CornerRadius = UDim.new(0, 6)
            
            local titleLbl = Instance.new("TextLabel")
            titleLbl.Size = UDim2.new(1, -60, 0, 30)
            titleLbl.Position = UDim2.new(0, 15, 0, 5)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text = tsName
            titleLbl.TextColor3 = TEXT_COLOR
            titleLbl.TextSize = 13
            titleLbl.Font = Enum.Font.GothamSemibold
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.ZIndex = 12
            titleLbl.Parent = tsFrame

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 44, 0, 22)
            toggleBtn.Position = UDim2.new(1, -55, 0, 9)
            toggleBtn.BackgroundColor3 = defToggle and HEADER_COLOR or Color3.fromRGB(30, 15, 20)
            toggleBtn.Text = ""
            toggleBtn.ZIndex = 12
            toggleBtn.Parent = tsFrame
            Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

            local circle = Instance.new("Frame")
            circle.Size = UDim2.new(0, 18, 0, 18)
            circle.Position = UDim2.new(0, defToggle and 24 or 2, 0.5, -9)
            circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            circle.ZIndex = 13
            circle.Parent = toggleBtn
            Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

            local outline = Instance.new("UIStroke")
            outline.Color = HEADER_COLOR
            outline.Transparency = defToggle and 0 or 0.8
            outline.Thickness = 1
            outline.Parent = toggleBtn

            local isToggled = defToggle

            local highlightBox = Instance.new("Frame")
            highlightBox.Size = UDim2.new(0, 45, 0, 20)
            highlightBox.Position = UDim2.new(1, -55, 0, 40)
            highlightBox.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
            highlightBox.ZIndex = 12
            highlightBox.Parent = tsFrame
            Instance.new("UICorner", highlightBox).CornerRadius = UDim.new(0, 4)

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(1, 0, 1, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(defSlider) .. suffix
            valueLabel.TextColor3 = HEADER_COLOR
            valueLabel.TextSize = 12
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.ZIndex = 13
            valueLabel.Parent = highlightBox

            local slideBg = Instance.new("Frame")
            slideBg.Size = UDim2.new(1, -85, 0, 6)
            slideBg.Position = UDim2.new(0, 15, 0, 47)
            slideBg.BackgroundColor3 = Color3.fromRGB(30, 15, 20)
            slideBg.ZIndex = 12
            slideBg.Parent = tsFrame
            Instance.new("UICorner", slideBg).CornerRadius = UDim.new(1, 0)

            local slideInner = Instance.new("Frame")
            slideInner.Size = UDim2.new((defSlider - min) / (max - min), 0, 1, 0)
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
            slideBtn.Size = UDim2.new(1, 0, 1, 20)
            slideBtn.Position = UDim2.new(0, 0, 0, -10)
            slideBtn.BackgroundTransparency = 1
            slideBtn.Text = ""
            slideBtn.ZIndex = 15
            slideBtn.Parent = slideBg

            local tsAPI = {
                Name = tsName,
                Type = "ToggleSlider",
                ToggleValue = defToggle,
                SliderValue = defSlider
            }

            local function fireToggle()
                isToggled = not isToggled
                tsAPI.ToggleValue = isToggled
                local colorGoal = isToggled and HEADER_COLOR or Color3.fromRGB(30, 15, 20)
                local posGoal = isToggled and UDim2.new(0, 24, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                local outlineAlpha = isToggled and 0 or 0.8

                tweenService:Create(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = colorGoal}):Play()
                tweenService:Create(circle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = posGoal}):Play()
                tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = outlineAlpha}):Play()

                cbToggle(isToggled)
            end

            local btnOverlay = Instance.new("TextButton")
            btnOverlay.Size = UDim2.new(1, 0, 0, 35) 
            btnOverlay.BackgroundTransparency = 1
            btnOverlay.Text = ""
            btnOverlay.ZIndex = 14
            btnOverlay.Parent = tsFrame

            btnOverlay.MouseButton1Click:Connect(fireToggle)

            local isDragging = false
            local UserInputService = game:GetService("UserInputService")

            local function updateSlider(input)
                local relativeX = math.clamp(input.Position.X - slideBg.AbsolutePosition.X, 0, slideBg.AbsoluteSize.X)
                local percentage = relativeX / slideBg.AbsoluteSize.X
                local value = math.floor(min + (max - min) * percentage)
                
                local clamped = math.clamp(value, min, max)
                tsAPI.SliderValue = clamped
                valueLabel.Text = tostring(clamped) .. suffix
                tweenService:Create(slideInner, TweenInfo.new(0.08), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
                cbSlider(clamped)
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
            
            function tsAPI:SetToggle(state)
                if isToggled ~= state then fireToggle() end
            end
            
            function tsAPI:SetSlider(val)
                local clamped = math.clamp(val, min, max)
                tsAPI.SliderValue = clamped
                valueLabel.Text = tostring(clamped) .. suffix
                local percentage = (clamped - min) / (max - min)
                tweenService:Create(slideInner, TweenInfo.new(0.08), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
                cbSlider(clamped)
            end

            tsAPI.Instance = tsFrame
            table.insert(WindowObj.Elements, tsAPI)
            return tsAPI
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
            dropMenuBg.Parent = dropFrame:FindFirstAncestor("DragBox") or screenGui -- Fix: Render above the clipped window boundaries
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
            
            local inputConn
            local UserInputService = game:GetService("UserInputService")
            
            local function toggleDropdown()
                isOpen = not isOpen
                if isOpen then
                    dropMenuBg.Visible = true
                    
                    -- Calculate absolute position and size relative to screen
                    dropMenuBg.Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, 0)
                    local dropParent = dropMenuBg.Parent
                    local relativeX = dropBtn.AbsolutePosition.X - (dropParent:IsA("GuiObject") and dropParent.AbsolutePosition.X or 0)
                    local relativeY = dropBtn.AbsolutePosition.Y - (dropParent:IsA("GuiObject") and dropParent.AbsolutePosition.Y or 0)
                    dropMenuBg.Position = UDim2.new(0, relativeX, 0, relativeY + dropBtn.AbsoluteSize.Y + 4)
                    
                    tweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 180, TextColor3 = TEXT_COLOR}):Play()
                    tweenService:Create(outline, TweenInfo.new(0.3), {Transparency = 0}):Play()
                    tweenService:Create(dropMenuBg, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, math.clamp(listHeight, 10, 150))}):Play()
                    
                    if not inputConn then
                        inputConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                local lp = game:GetService("Players").LocalPlayer
                                if not lp then return end
                                local mouse = lp:GetMouse()
                                local mx, my = mouse.X, mouse.Y
                                
                                -- GuiInset Correction: ScreenGui mit IgnoreGuiInset berücksichtigt (default 36px Topbar in Roblox)
                                -- AbsolutePosition beinhaltet Topbar-Offset nicht immer konsistent mit Mouse y. GetMouse() y beinhaltet Topbar nicht.
                                -- The safest cross-method is using AbsolutePosition + GUI Inset check or just adding 36 manually if an inset applies.
                                -- Simple Bounds Check (Adding 36 margin of error for TopBar if necessary):
                                local function isInside(gui)
                                    if not gui.Visible then return false end
                                    local absPos = gui.AbsolutePosition
                                    local absSize = gui.AbsoluteSize
                                    
                                    -- Check both raw Mouse Y and Mouse Y + 36 (TopBar Height in standard Roblox)
                                    local insideRaw = mx >= absPos.X and mx <= absPos.X + absSize.X and
                                           my >= absPos.Y and my <= absPos.Y + absSize.Y
                                    local insideTopBar = mx >= absPos.X and mx <= absPos.X + absSize.X and
                                           (my + 36) >= absPos.Y and (my + 36) <= absPos.Y + absSize.Y
                                           
                                    return insideRaw or insideTopBar
                                end
                                
                                if not isInside(dropMenuBg) and not isInside(dropBtn) then
                                    toggleDropdown()
                                end
                            end
                        end)
                    end
                else
                    tweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0, TextColor3 = Color3.fromRGB(150, 120, 130)}):Play()
                    tweenService:Create(outline, TweenInfo.new(0.3), {Transparency = 0.8}):Play()
                    local clsTween = tweenService:Create(dropMenuBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, 0)})
                    clsTween:Play()
                    
                    if inputConn then
                        inputConn:Disconnect()
                        inputConn = nil
                    end
                    
                    task.spawn(function()
                        clsTween.Completed:Wait()
                        if not isOpen then dropMenuBg.Visible = false end -- Check falls user schnell double clickt
                    end)
                end
            end
            
            -- Close dropdown when scrolling or window moves
            local function closeIfOpen() if isOpen then toggleDropdown() end end
            local scrollFrame = dropFrame:FindFirstAncestorWhichIsA("ScrollingFrame")
            if scrollFrame then scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(closeIfOpen) end
            bodyContainer:GetPropertyChangedSignal("Position"):Connect(closeIfOpen)
            bodyContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(closeIfOpen)
            
            -- Close when Tab switches (Page becomes invisible)
            page:GetPropertyChangedSignal("Visible"):Connect(function()
                if not page.Visible and isOpen then
                    toggleDropdown()
                end
            end)

            dropBtn.MouseEnter:Connect(function() tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = isOpen and 0 or 0.5}):Play() end)
            dropBtn.MouseLeave:Connect(function() tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = isOpen and 0 or 0.8}):Play() end)

            local function refreshOptions(newOptions)
                for _, child in pairs(dropMenu:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                
                listHeight = #newOptions * 25
                dropMenu.CanvasSize = UDim2.new(0, 0, 0, listHeight)
                
                for _, optText in pairs(newOptions or {}) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, -6, 0, 25)
                    optBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
                    optBtn.BackgroundTransparency = 0
                    optBtn.Text = "  " .. tostring(optText)
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

        function TabObj:AddInventoryGrid(invOptions)
            local iName = invOptions.Name or "Inventory"
            local cb = invOptions.OnSell or function() end
            
            GLOBAL_ZINDEX = GLOBAL_ZINDEX + 10
            local currentZ = GLOBAL_ZINDEX

            local gridContainer = Instance.new("Frame")
            gridContainer.Size = UDim2.new(1, -10, 0, 30)
            gridContainer.BackgroundColor3 = CARD_COLOR
            gridContainer.ZIndex = currentZ
            gridContainer.Parent = page
            Instance.new("UICorner", gridContainer).CornerRadius = UDim.new(0, 6)
            
            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = gridContainer
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 4)
            listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            
            local padding = Instance.new("UIPadding")
            padding.Parent = gridContainer
            padding.PaddingTop = UDim.new(0, 5)
            padding.PaddingBottom = UDim.new(0, 5)
            
            local InvAPI = {
                Name = iName,
                Type = "InventoryGrid"
            }
            
            local frameCache = {}
            local currentListRef = {}
            
            function InvAPI:Refresh(newList)
                currentListRef = newList
                local count = 0
                for i, itemData in ipairs(newList) do
                    count = count + 1
                    local itemFrame = frameCache[i]
                    if not itemFrame then
                        itemFrame = Instance.new("Frame")
                        itemFrame.Size = UDim2.new(1, -10, 0, 30)
                        itemFrame.BackgroundColor3 = Color3.fromRGB(45, 25, 35)
                        itemFrame.ZIndex = currentZ + 1
                        itemFrame.Parent = gridContainer
                        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 4)
                        
                        local nameLbl = Instance.new("TextLabel")
                        nameLbl.Name = "NameLbl"
                        nameLbl.Size = UDim2.new(0.4, 0, 1, 0)
                        nameLbl.Position = UDim2.new(0, 10, 0, 0)
                        nameLbl.BackgroundTransparency = 1
                        nameLbl.TextColor3 = TEXT_COLOR
                        nameLbl.Font = Enum.Font.GothamSemibold
                        nameLbl.TextSize = 12
                        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                        nameLbl.ZIndex = currentZ + 2
                        nameLbl.Parent = itemFrame
                        
                        local starsLbl = Instance.new("TextLabel")
                        starsLbl.Name = "StarsLbl"
                        starsLbl.Size = UDim2.new(0, 45, 1, 0)
                        starsLbl.Position = UDim2.new(1, -105, 0, 0)
                        starsLbl.BackgroundTransparency = 1
                        starsLbl.TextColor3 = Color3.fromRGB(245, 205, 50)
                        starsLbl.Font = Enum.Font.GothamBold
                        starsLbl.TextSize = 11
                        starsLbl.TextXAlignment = Enum.TextXAlignment.Right
                        starsLbl.ZIndex = currentZ + 2
                        starsLbl.Parent = itemFrame
                        
                        local levelLbl = Instance.new("TextLabel")
                        levelLbl.Name = "LevelLbl"
                        levelLbl.Size = UDim2.new(0, 50, 1, 0)
                        levelLbl.Position = UDim2.new(1, -155, 0, 0)
                        levelLbl.BackgroundTransparency = 1
                        levelLbl.TextColor3 = Color3.fromRGB(150, 200, 255)
                        levelLbl.Font = Enum.Font.GothamBold
                        levelLbl.TextSize = 11
                        levelLbl.TextXAlignment = Enum.TextXAlignment.Right
                        levelLbl.ZIndex = currentZ + 2
                        levelLbl.Parent = itemFrame
                        
                        local valLbl = Instance.new("TextLabel")
                        valLbl.Name = "ValLbl"
                        valLbl.Size = UDim2.new(0.4, -10, 1, 0)
                        valLbl.Position = UDim2.new(0.4, 0, 0, 0)
                        valLbl.BackgroundTransparency = 1
                        valLbl.Font = Enum.Font.Gotham
                        valLbl.TextSize = 11
                        valLbl.TextXAlignment = Enum.TextXAlignment.Left
                        valLbl.ZIndex = currentZ + 2
                        valLbl.Parent = itemFrame
                        
                        local sellBtn = Instance.new("TextButton")
                        sellBtn.Name = "SellBtn"
                        sellBtn.Size = UDim2.new(0, 50, 0, 22)
                        sellBtn.Position = UDim2.new(1, -55, 0.5, -11)
                        sellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 70)
                        sellBtn.Text = "Sell"
                        sellBtn.TextColor3 = Color3.new(1,1,1)
                        sellBtn.Font = Enum.Font.GothamBold
                        sellBtn.TextSize = 11
                        sellBtn.ZIndex = currentZ + 3
                        sellBtn.Parent = itemFrame
                        Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 4)
                        
                        local btnStroke = Instance.new("UIStroke")
                        btnStroke.Color = Color3.fromRGB(255, 100, 100)
                        btnStroke.Transparency = 0.5
                        btnStroke.Parent = sellBtn
                        
                        sellBtn.MouseButton1Click:Connect(function()
                            if cb and currentListRef[itemFrame:GetAttribute("Index")] then
                                cb(currentListRef[itemFrame:GetAttribute("Index")])
                            end
                        end)
                        
                        frameCache[i] = itemFrame
                    end
                    
                    itemFrame:SetAttribute("Index", i)
                    itemFrame.Visible = true
                    
                    itemFrame.NameLbl.Text = itemData.Name or "Unknown"
                    local stNum = tostring(itemData.Stars or "1")
                    if stNum == "0" or stNum == "" then stNum = "1" end
                    itemFrame.StarsLbl.Text = stNum .. " ⭐"
                    
                    local lvNum = tostring(itemData.Level or "1")
                    if lvNum == "0" or lvNum == "" then lvNum = "1" end
                    itemFrame.LevelLbl.Text = "📈 LV: " .. lvNum
                    
                    itemFrame.ValLbl.Text = (itemData.Rank or "") .. " | $" .. tostring(itemData.Value or "0")
                    if itemData.Rank == "Divine" or itemData.Rank == "GOD" or itemData.Rank == "???" then
                        itemFrame.ValLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                    else
                        itemFrame.ValLbl.TextColor3 = Color3.fromRGB(150, 200, 150)
                    end
                end
                
                for i = count + 1, #frameCache do
                    frameCache[i].Visible = false
                end
                
                gridContainer.Size = UDim2.new(1, -10, 0, (count * 34) + 10)
            end
            
            return InvAPI
        end

        function TabObj:AddPlotGrid(plotOptions)
            local iName = plotOptions.Name or "Plot Grid"
            local onPickup = plotOptions.OnPickup or function() end
            local onUpgrade = plotOptions.OnUpgrade or function() end
            local onPrestige = plotOptions.OnPrestige or function() end
            local onTitleClick = plotOptions.OnTitleClick or function() end
            
            GLOBAL_ZINDEX = GLOBAL_ZINDEX + 10
            local currentZ = GLOBAL_ZINDEX

            local gridContainer = Instance.new("Frame")
            gridContainer.Size = UDim2.new(1, -10, 0, 30)
            gridContainer.BackgroundColor3 = CARD_COLOR
            gridContainer.ZIndex = currentZ
            gridContainer.Parent = page
            Instance.new("UICorner", gridContainer).CornerRadius = UDim.new(0, 6)
            
            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = gridContainer
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 4)
            listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            
            local padding = Instance.new("UIPadding")
            padding.Parent = gridContainer
            padding.PaddingTop = UDim.new(0, 5)
            padding.PaddingBottom = UDim.new(0, 5)
            
            local PlotAPI = {
                Name = iName,
                Type = "PlotGrid"
            }
            
            local frameCache = {}
            local currentListRef = {}
            
            function PlotAPI:Refresh(newList)
                currentListRef = newList
                local count = 0
                for i, itemData in ipairs(newList) do
                    count = count + 1
                    local itemFrame = frameCache[i]
                    if not itemFrame then
                        itemFrame = Instance.new("Frame")
                        itemFrame.Size = UDim2.new(1, -10, 0, 30)
                        itemFrame.BackgroundColor3 = Color3.fromRGB(45, 25, 35)
                        itemFrame.ZIndex = currentZ + 1
                        itemFrame.Parent = gridContainer
                        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 4)
                        
                        local nameLbl = Instance.new("TextButton")
                        nameLbl.Name = "NameLbl"
                        nameLbl.Size = UDim2.new(0.3, 0, 1, 0)
                        nameLbl.Position = UDim2.new(0, 10, 0, 0)
                        nameLbl.BackgroundTransparency = 1
                        nameLbl.TextColor3 = TEXT_COLOR
                        nameLbl.Font = Enum.Font.GothamSemibold
                        nameLbl.TextSize = 11
                        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                        nameLbl.ZIndex = currentZ + 2
                        nameLbl.Parent = itemFrame
                        
                        nameLbl.MouseButton1Click:Connect(function()
                            if onTitleClick and currentListRef[itemFrame:GetAttribute("Index")] then
                                onTitleClick(currentListRef[itemFrame:GetAttribute("Index")])
                            end
                        end)
                        
                        local starsLbl = Instance.new("TextLabel")
                        starsLbl.Name = "StarsLbl"
                        starsLbl.Size = UDim2.new(0, 40, 1, 0)
                        starsLbl.Position = UDim2.new(1, -210, 0, 0)
                        starsLbl.BackgroundTransparency = 1
                        starsLbl.TextColor3 = Color3.fromRGB(245, 205, 50)
                        starsLbl.Font = Enum.Font.GothamBold
                        starsLbl.TextSize = 10
                        starsLbl.TextXAlignment = Enum.TextXAlignment.Right
                        starsLbl.ZIndex = currentZ + 2
                        starsLbl.Parent = itemFrame
                        
                        local levelLbl = Instance.new("TextLabel")
                        levelLbl.Name = "LevelLbl"
                        levelLbl.Size = UDim2.new(0, 50, 1, 0)
                        levelLbl.Position = UDim2.new(1, -255, 0, 0)
                        levelLbl.BackgroundTransparency = 1
                        levelLbl.TextColor3 = Color3.fromRGB(150, 200, 255)
                        levelLbl.Font = Enum.Font.GothamBold
                        levelLbl.TextSize = 10
                        levelLbl.TextXAlignment = Enum.TextXAlignment.Right
                        levelLbl.ZIndex = currentZ + 2
                        levelLbl.Parent = itemFrame
                        
                        local valLbl = Instance.new("TextLabel")
                        valLbl.Name = "ValLbl"
                        valLbl.Size = UDim2.new(0.3, 0, 1, 0)
                        valLbl.Position = UDim2.new(0.3, 0, 0, 0)
                        valLbl.BackgroundTransparency = 1
                        valLbl.Font = Enum.Font.Gotham
                        valLbl.TextSize = 10
                        valLbl.TextXAlignment = Enum.TextXAlignment.Left
                        valLbl.ZIndex = currentZ + 2
                        valLbl.Parent = itemFrame
                        
                        local pickupBtn = Instance.new("TextButton")
                        pickupBtn.Name = "PickupBtn"
                        pickupBtn.Size = UDim2.new(0, 60, 0, 22)
                        pickupBtn.Position = UDim2.new(1, -65, 0.5, -11)
                        pickupBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
                        pickupBtn.Text = "✋ Pick Up"
                        pickupBtn.TextColor3 = Color3.new(1,1,1)
                        pickupBtn.Font = Enum.Font.GothamBold
                        pickupBtn.TextSize = 10
                        pickupBtn.ZIndex = currentZ + 3
                        pickupBtn.Parent = itemFrame
                        Instance.new("UICorner", pickupBtn).CornerRadius = UDim.new(0, 4)
                        local puStroke = Instance.new("UIStroke", pickupBtn) puStroke.Color = Color3.fromRGB(100, 150, 255) puStroke.Transparency = 0.5
                        pickupBtn.MouseButton1Click:Connect(function() 
                            if onPickup and currentListRef[itemFrame:GetAttribute("Index")] then
                                onPickup(currentListRef[itemFrame:GetAttribute("Index")])
                            end
                        end)
                        
                        local actionBtn = Instance.new("TextButton")
                        actionBtn.Name = "ActionBtn"
                        actionBtn.Size = UDim2.new(0, 75, 0, 22)
                        actionBtn.Position = UDim2.new(1, -145, 0.5, -11)
                        actionBtn.TextSize = 10
                        actionBtn.Font = Enum.Font.GothamBold
                        actionBtn.TextColor3 = Color3.new(1,1,1)
                        actionBtn.ZIndex = currentZ + 3
                        actionBtn.Parent = itemFrame
                        Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 4)
                        local acStroke = Instance.new("UIStroke", actionBtn) acStroke.Name = "UIStroke" acStroke.Transparency = 0.5
                        
                        actionBtn.MouseButton1Click:Connect(function() 
                            local ref = currentListRef[itemFrame:GetAttribute("Index")]
                            if not ref then return end
                            local lvNum = tostring(ref.Level or "1")
                            local refSt = tostring(ref.Stars or "1")
                            local isMaxStars = string.match(refSt, "4") ~= nil
                            
                            if tonumber(lvNum) and tonumber(lvNum) >= 50 and not isMaxStars then
                                if onPrestige then onPrestige(ref) end
                            else
                                if onUpgrade then onUpgrade(ref) end
                            end
                        end)
                        
                        local hatchLbl = Instance.new("TextLabel")
                        hatchLbl.Name = "HatchLbl"
                        hatchLbl.Size = UDim2.new(0, 140, 1, 0)
                        hatchLbl.Position = UDim2.new(1, -145, 0, 0)
                        hatchLbl.BackgroundTransparency = 1
                        hatchLbl.Font = Enum.Font.GothamBold
                        hatchLbl.TextSize = 11
                        hatchLbl.TextXAlignment = Enum.TextXAlignment.Center
                        hatchLbl.TextColor3 = Color3.fromRGB(250, 200, 100)
                        hatchLbl.ZIndex = currentZ + 3
                        hatchLbl.Visible = false
                        hatchLbl.Parent = itemFrame
                        
                        frameCache[i] = itemFrame
                    end
                    
                    itemFrame:SetAttribute("Index", i)
                    itemFrame.Visible = true
                    
                    itemFrame.NameLbl.Text = itemData.Name or "Unknown"
                    local stNum = tostring(itemData.Stars or "1")
                    if stNum == "0" or stNum == "" then stNum = "1" end
                    itemFrame.StarsLbl.Text = stNum .. " ⭐"
                    
                    local lvNum = tostring(itemData.Level or "1")
                    if lvNum == "0" or lvNum == "" then lvNum = "1" end
                    
                    if lvNum == "55" then
                        itemFrame.LevelLbl.Text = "📈 MAX LVL"
                        itemFrame.LevelLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                    else
                        itemFrame.LevelLbl.Text = "📈 LV: " .. lvNum
                        itemFrame.LevelLbl.TextColor3 = Color3.fromRGB(150, 200, 255)
                    end
                    
                    itemFrame.ValLbl.Text = (itemData.Rank or "") .. " | $" .. tostring(itemData.Value or "0")
                    if itemData.Rank == "Divine" or itemData.Rank == "GOD" or itemData.Rank == "???" then
                        itemFrame.ValLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                    else
                        itemFrame.ValLbl.TextColor3 = Color3.fromRGB(150, 200, 150)
                    end
                    
                    local isPrestigeEligible = false
                    if tonumber(lvNum) and tonumber(lvNum) >= 50 then isPrestigeEligible = true end
                    local isMaxStars = string.match(stNum, "4") ~= nil
                    
                    if isPrestigeEligible and not isMaxStars then
                        itemFrame.ActionBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
                        itemFrame.ActionBtn.Text = "⭐ Prestige"
                        itemFrame.ActionBtn.UIStroke.Color = Color3.fromRGB(255, 200, 100)
                    elseif isMaxStars then
                        itemFrame.ActionBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 100)
                        itemFrame.ActionBtn.Text = "⬆️ +1 Lvl"
                        itemFrame.ActionBtn.UIStroke.Color = Color3.fromRGB(100, 255, 150)
                    else
                        itemFrame.ActionBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 100)
                        itemFrame.ActionBtn.Text = "🔥 Lvl. 50"
                        itemFrame.ActionBtn.UIStroke.Color = Color3.fromRGB(100, 255, 150)
                    end
                    
                    if itemData.IsHatching then
                        itemFrame.HatchLbl.Text = itemData.StatusText or "🥚 Hatching"
                        itemFrame.HatchLbl.Visible = true
                        
                        itemFrame.PickupBtn.Visible = false
                        itemFrame.ActionBtn.Visible = false
                        
                        itemFrame.ValLbl.Text = "--"
                        itemFrame.LevelLbl.Text = ""
                        itemFrame.StarsLbl.Text = ""
                    else
                        itemFrame.HatchLbl.Visible = false
                        itemFrame.PickupBtn.Visible = true
                        itemFrame.ActionBtn.Visible = true
                    end
                end
                
                for i = count + 1, #frameCache do
                    frameCache[i].Visible = false
                end
                
                gridContainer.Size = UDim2.new(1, -10, 0, (count * 34) + 10)
            end
            
            return PlotAPI
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
            dropMenuBg.Parent = dropFrame:FindFirstAncestor("DragBox") or screenGui
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
            searchBox.Active = true
            searchBox.Interactable = true
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
            
            function DropdownAPI:Set(val)
                local newSel = type(val) == "table" and val or {val}
                selectedItems = newSel
                DropdownAPI.Value = selectedItems
                updateBtnText()
                refreshOptions(searchBox.Text)
                cb(newSel)
            end

            local function toggleDropdown()
                isOpen = not isOpen
                if isOpen then
                    dropMenuBg.Visible = true
                    local dropParent = dropMenuBg.Parent
                    local relativeX = dropBtn.AbsolutePosition.X - (dropParent:IsA("GuiObject") and dropParent.AbsolutePosition.X or 0)
                    local relativeY = dropBtn.AbsolutePosition.Y - (dropParent:IsA("GuiObject") and dropParent.AbsolutePosition.Y or 0)
                    dropMenuBg.Position = UDim2.new(0, relativeX, 0, relativeY + dropBtn.AbsoluteSize.Y + 4)
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
            
            local function closeIfOpen() if isOpen then toggleDropdown() end end
            local scrollFrame = dropFrame:FindFirstAncestorWhichIsA("ScrollingFrame")
            if scrollFrame then scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(closeIfOpen) end
            bodyContainer:GetPropertyChangedSignal("Position"):Connect(closeIfOpen)
            bodyContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(closeIfOpen)

            dropBtn.MouseEnter:Connect(function() tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = isOpen and 0 or 0.5}):Play() end)
            dropBtn.MouseLeave:Connect(function() tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = isOpen and 0 or 0.8}):Play() end)

            local optBtnCache = {}
            
            refreshOptions = function(filterText)
                local displayedCount = 0
                local currentListHeight = 0
                
                for _, optText in pairs(optionsList) do
                    local isVisible = filterText == "" or string.find(string.lower(optText), string.lower(filterText), 1, true)
                    
                    if isVisible then
                        displayedCount = displayedCount + 1
                        local isSel = table.find(selectedItems, optText) ~= nil
                        
                        local optBtn = optBtnCache[optText]
                        if not optBtn then
                            optBtn = Instance.new("TextButton")
                            optBtn.Size = UDim2.new(1, -6, 0, 25)
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
                                    local isAllTag = string.match(optText, "^%[%s*All")
                                    if isAllTag then
                                        selectedItems = {optText}
                                    else
                                        for i = #selectedItems, 1, -1 do
                                            if string.match(selectedItems[i], "^%[%s*All") then
                                                table.remove(selectedItems, i)
                                            end
                                        end
                                        table.insert(selectedItems, optText)
                                    end
                                end
                                
                                if #selectedItems == 0 then
                                    for _, opt in ipairs(optionsList) do
                                        if string.match(opt, "^%[%s*All") then
                                            table.insert(selectedItems, opt)
                                            break
                                        end
                                    end
                                end
    
                                DropdownAPI.Value = selectedItems
                                updateBtnText()
                                refreshOptions(searchBox.Text) 
                                cb(selectedItems)
                            end)
                            
                            optBtnCache[optText] = optBtn
                        end
                        
                        optBtn.BackgroundColor3 = isSel and HEADER_COLOR or Color3.fromRGB(40, 25, 30)
                        optBtn.BackgroundTransparency = isSel and 0.5 or 0
                        optBtn.Text = "  " .. optText
                        optBtn.TextColor3 = isSel and Color3.new(1,1,1) or TEXT_COLOR
                        optBtn.Visible = true
                        currentListHeight = currentListHeight + 25
                    else
                        if optBtnCache[optText] then
                            optBtnCache[optText].Visible = false
                        end
                    end
                end
                
                for cachedText, btn in pairs(optBtnCache) do
                    if not table.find(optionsList, cachedText) then
                        btn:Destroy()
                        optBtnCache[cachedText] = nil
                    end
                end
                
                dropMenu.CanvasSize = UDim2.new(0, 0, 0, currentListHeight)
                
                if isOpen then
                    local maxH = math.clamp(currentListHeight + 36, 60, 200)
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
            tBox.ClearTextOnFocus = false
            tBox.Active = true
            tBox.Interactable = true
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
                        KeybindAPI.Value = currentKey -- Fix: Ensure Config Manager gets the new key
                        bindBtn.Text = currentKey.Name
                        isWaiting = false
                        tweenService:Create(outline, TweenInfo.new(0.2), {Transparency = 0.8}):Play()
                        tweenService:Create(bindBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 10, 15)}):Play()
                        conn:Disconnect()
                    end
                end)
            end)

            local mainConn = UserInputService.InputBegan:Connect(function(input, processed)
                if not processed and input.KeyCode == currentKey and not isWaiting then
                    -- Verhindert Ghost-Feuer wenn GUI gelöscht ist
                    if not screenGui or not screenGui.Parent then return end 
                    cb()
                end
            end)
            table.insert(_G.RoseUI_Connections, mainConn)
            
            table.insert(WindowObj.Elements, KeybindAPI)
            return KeybindAPI
        end
        -- 11. GAME GALLERY
        function TabObj:AddGameGallery(gOptions)
            local itemsList = gOptions.Items or {}
            
            GLOBAL_ZINDEX = GLOBAL_ZINDEX + 10
            local currentZ = GLOBAL_ZINDEX
            
            -- Search Bar Container
            local searchFrame = Instance.new("Frame")
            searchFrame.Size = UDim2.new(1, -10, 0, 42)
            searchFrame.BackgroundColor3 = CARD_COLOR
            searchFrame.ZIndex = currentZ
            searchFrame.Parent = page
            Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 6)
            
            local searchIcon = Instance.new("TextLabel")
            searchIcon.Size = UDim2.new(0, 30, 0, 42)
            searchIcon.Position = UDim2.new(0, 10, 0, 0)
            searchIcon.BackgroundTransparency = 1
            searchIcon.Text = "🔍"
            searchIcon.TextColor3 = TEXT_COLOR
            searchIcon.TextSize = 14
            searchIcon.ZIndex = currentZ + 1
            searchIcon.Parent = searchFrame
            
            local searchBox = Instance.new("TextBox")
            searchBox.Size = UDim2.new(1, -50, 0, 42)
            searchBox.Position = UDim2.new(0, 40, 0, 0)
            searchBox.BackgroundTransparency = 1
            searchBox.Text = ""
            searchBox.ClearTextOnFocus = false
            searchBox.PlaceholderText = "Search by game name or category..."
            searchBox.PlaceholderColor3 = Color3.fromRGB(120, 100, 110)
            searchBox.TextColor3 = TEXT_COLOR
            searchBox.Font = Enum.Font.Gotham
            searchBox.TextSize = 13
            searchBox.TextXAlignment = Enum.TextXAlignment.Left
            searchBox.ZIndex = currentZ + 1
            searchBox.Parent = searchFrame
            
            -- Gallery Scroll Container (Changed to Frame to prevent Roblox Double-ScrollingFrame input-swallowing)
            local galleryBg = Instance.new("Frame")
            galleryBg.Size = UDim2.new(1, -10, 0, 0)
            galleryBg.BackgroundColor3 = Color3.fromRGB(20, 10, 15)
            galleryBg.BackgroundTransparency = 1 -- Make background transparent to just act as a wrapper
            galleryBg.ZIndex = currentZ
            galleryBg.Parent = page
            
            local gridLayout = Instance.new("UIGridLayout")
            gridLayout.CellSize = UDim2.new(0.5, -5, 0, 160)
            gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
            gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
            gridLayout.Parent = galleryBg
            
            local cards = {}
            
            for i, itemData in ipairs(itemsList) do
                local card = Instance.new("ImageButton")
                card.BackgroundColor3 = CARD_COLOR
                card.AutoButtonColor = false
                card.ZIndex = currentZ + 2
                card.Parent = galleryBg
                Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
                
                -- Image Thumbnail
                local thumb = Instance.new("ImageLabel")
                thumb.Size = UDim2.new(1, 0, 0.65, 0)
                thumb.BackgroundColor3 = Color3.fromRGB(15, 8, 12)
                thumb.ScaleType = Enum.ScaleType.Crop
                thumb.ZIndex = currentZ + 3
                thumb.Parent = card
                
                if itemData.Image then
                    thumb.Image = "rbxassetid://" .. tostring(itemData.Image)
                elseif itemData.PlaceId then
                    thumb.Image = "" -- Start empty
                    task.spawn(function()
                        pcall(function()
                            local info = game:GetService("MarketplaceService"):GetProductInfo(itemData.PlaceId)
                            if info and info.IconImageAssetId then
                                thumb.Image = "rbxassetid://" .. tostring(info.IconImageAssetId)
                            end
                        end)
                    end)
                else
                    thumb.Image = "rbxassetid://9330663183" -- Default fallback
                end
                
                Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 6)
                -- Bottom flat corner fix for the thumbnail
                local botFix = Instance.new("Frame")
                botFix.Size = UDim2.new(1, 0, 0, 6)
                botFix.Position = UDim2.new(0, 0, 1, -6)
                botFix.BackgroundColor3 = Color3.fromRGB(15, 8, 12)
                botFix.BorderSizePixel = 0
                botFix.ZIndex = currentZ + 3
                botFix.Parent = thumb
                
                -- Gradient overlay for text readability
                local overlay = Instance.new("Frame")
                overlay.Size = UDim2.new(1, 0, 1, 0)
                overlay.BackgroundColor3 = Color3.new(0,0,0)
                overlay.BackgroundTransparency = 0.5
                overlay.BorderSizePixel = 0
                overlay.ZIndex = currentZ + 4
                overlay.Parent = thumb
                
                local uigrad = Instance.new("UIGradient")
                uigrad.Rotation = 90
                uigrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
                uigrad.Parent = overlay
                
                -- Title
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -20, 0, 25)
                title.Position = UDim2.new(0, 10, 0.65, 5)
                title.BackgroundTransparency = 1
                title.Text = itemData.Name or "Unknown"
                title.TextColor3 = TEXT_COLOR
                title.Font = Enum.Font.GothamBold
                title.TextSize = 13
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.TextTruncate = Enum.TextTruncate.AtEnd
                title.ZIndex = currentZ + 5
                title.Parent = card
                
                -- Category Badge
                local catBadge = Instance.new("Frame")
                catBadge.Size = UDim2.new(0, 80, 0, 16)
                catBadge.Position = UDim2.new(0, 10, 0.65, 30)
                catBadge.BackgroundColor3 = HEADER_COLOR
                catBadge.BackgroundTransparency = 0.5
                catBadge.ZIndex = currentZ + 5
                catBadge.Parent = card
                Instance.new("UICorner", catBadge).CornerRadius = UDim.new(0, 4)
                
                local catLbl = Instance.new("TextLabel")
                catLbl.Size = UDim2.new(1, 0, 1, 0)
                catLbl.BackgroundTransparency = 1
                catLbl.Text = string.upper(itemData.Category or "MINIGAME")
                catLbl.TextColor3 = Color3.fromRGB(255, 230, 240)
                catLbl.Font = Enum.Font.GothamBold
                catLbl.TextSize = 10
                catLbl.ZIndex = currentZ + 6
                catLbl.Parent = catBadge
                
                -- Play Icon
                local playIcon = Instance.new("TextLabel")
                playIcon.Size = UDim2.new(0, 25, 0, 25)
                playIcon.Position = UDim2.new(1, -35, 0.65, 15)
                playIcon.BackgroundTransparency = 1
                playIcon.Text = "▶"
                playIcon.TextColor3 = HEADER_COLOR
                playIcon.Font = Enum.Font.GothamBold
                playIcon.TextSize = 18
                playIcon.ZIndex = currentZ + 5
                playIcon.Parent = card
                
                -- Selection Effects
                local stroke = Instance.new("UIStroke")
                stroke.Color = HEADER_COLOR
                stroke.Thickness = 2
                stroke.Transparency = 1
                stroke.Parent = card
                
                card.MouseEnter:Connect(function() 
                    tweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
                    tweenService:Create(playIcon, TweenInfo.new(0.2), {TextColor3 = TEXT_COLOR}):Play()
                    tweenService:Create(thumb, TweenInfo.new(0.3), {Size = UDim2.new(1.05, 0, 0.68, 0), Position = UDim2.new(-0.025, 0, -0.015, 0)}):Play()
                end)
                card.MouseLeave:Connect(function() 
                    tweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
                    tweenService:Create(playIcon, TweenInfo.new(0.2), {TextColor3 = HEADER_COLOR}):Play()
                    tweenService:Create(thumb, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0.65, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
                end)
                
                card.MouseButton1Click:Connect(function()
                    if itemData.Callback then
                        RoseUI:Notify({Title = "🚀 Launching", Text = "Loading " .. tostring(itemData.Name) .. "...", Duration = 2})
                        itemData.Callback()
                    end
                end)
                
                table.insert(cards, {Gui = card, Data = itemData})
            end
            
            gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                galleryBg.Size = UDim2.new(1, -10, 0, gridLayout.AbsoluteContentSize.Y)
            end)
            
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = string.lower(searchBox.Text)
                for _, card in ipairs(cards) do
                    if q == "" or string.find(string.lower(card.Data.Name or ""), q, 1, true) or string.find(string.lower(card.Data.Category or ""), q, 1, true) then
                        card.Gui.Visible = true
                    else
                        card.Gui.Visible = false
                    end
                end
            end)
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
            Name = "Set as Autoload",
            Callback = function()
                if selectedConfig == "" or selectedConfig == "No Configs Found" then
                    RoseUI:Notify({Title = "⚠️ Error", Text = "Please select a valid config first.", Duration = 3})
                    return 
                end
                pcall(function()
                    if writefile then
                        writefile(WindowObj.ConfigFolder .. "/autoload.txt", selectedConfig)
                        RoseUI:Notify({Title = "🌹 Config Autoload", Text = selectedConfig .. " set to auto-load.", Duration = 4})
                    end
                end)
            end
        })
        
        cfgSection:AddButton({
            Name = "Refresh List",
            Callback = function()
                refreshConfigList()
            end
        })
    end
    
    -- ========================================================
    -- DEFAULT TABS (Settings, Debug, Config)
    -- ========================================================
    if not options.HideDefaultTabs then
        local SettingsTab = WindowObj:MakeTab({
            Name = "Settings",
            Icon = "settings.png",
            PremiumOnly = false,
            ForceSeparator = true,
            LayoutOrder = 9997
        })
        WindowObj.SettingsTab = SettingsTab
        local settingsSec = SettingsTab:AddSection("Window Settings ⚙️")
    SettingsTab:AddKeybind({
        Name = "Toggle Hub UI",
        Default = Enum.KeyCode.RightAlt,
        Hold = false,
        Callback = function() end -- Just visual, bound globally already
    })
    
    SettingsTab:AddDropdown({
        Name = "UI Theme",
        Options = {"Dark Rose", "Ocean Blue", "Forest Green"},
        Default = currentThemeName,
        Callback = function(themeName)
            if WindowObj.SetTheme then WindowObj:SetTheme(themeName) end
        end
    })
    
    local vuService = game:GetService("VirtualUser")
    local InitialAntiAfkConn = nil

    SettingsTab:AddToggle({
        Name = "🛡️ Rose Anti-AFK (VirtualUser)",
        Description = "Bypasses the 20-minute idle kick natively (Evxn Method).",
        Default = true,
        Save = true,
        Flag = "RoseSettings_AntiAfk",
        Callback = function(state)
            if state then
                if not InitialAntiAfkConn then
                    InitialAntiAfkConn = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                        pcall(function()
                            vuService:CaptureController()
                            vuService:ClickButton2(Vector2.new())
                        end)
                    end)
                    RoseUI:Notify({Title = "Anti-AFK", Text = "Anti-Afk Auto Enabled", Duration = 3})
                end
            else
                if InitialAntiAfkConn then
                    InitialAntiAfkConn:Disconnect()
                    InitialAntiAfkConn = nil
                    RoseUI:Notify({Title = "Anti-AFK", Text = "Anti-Afk Disabled", Duration = 3})
                end
            end
        end
    })
    
    SettingsTab:AddToggle({
        Name = "🚀 Max FPS Mode (Strip Textures)",
        Default = false,
        Callback = function(state)
            if not state then 
                RoseUI:Notify({Title = "⚠️ Info", Text = "You must rejoin the game to restore textures.", Duration = 4})
                return 
            end
            
            pcall(function()
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
                for _, v in pairs(lighting:GetDescendants()) do
                    if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") then
                        v.Enabled = false
                    end
                end
                
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Texture") or v:IsA("Decal") then
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
                        v.Enabled = false
                    elseif v:IsA("BasePart") then
                        v.Material = Enum.Material.SmoothPlastic
                    end
                end
                
                -- Catch new parts firing in
                workspace.DescendantAdded:Connect(function(v)
                    pcall(function()
                        if v:IsA("Texture") or v:IsA("Decal") then
                            v.Transparency = 1
                        elseif v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
                            v.Enabled = false
                        elseif v:IsA("BasePart") then
                            v.Material = Enum.Material.SmoothPlastic
                        end
                    end)
                end)
                
                RoseUI:Notify({Title = "🚀 Max FPS Activated", Text = "Graphics heavily stripped.", Duration = 4})
            end)
        end
    })
    
    function WindowObj:SetTheme(themeName)
        local newTheme = RoseUI_Themes[themeName]
        if not newTheme then return end
        
        local oldHeader = HEADER_COLOR
        local oldSidebar = SIDEBAR_COLOR
        local oldContent = CONTENT_COLOR
        local oldCard = CARD_COLOR
        local oldText = TEXT_COLOR
        
        local targetColors = {
            [oldHeader:ToHex()] = newTheme.Header,
            [oldSidebar:ToHex()] = newTheme.Sidebar,
            [oldContent:ToHex()] = newTheme.Content,
            [oldCard:ToHex()] = newTheme.Card,
            [oldText:ToHex()] = newTheme.Text
        }
        
        -- Update local state for NEW elements
        HEADER_COLOR = newTheme.Header
        SIDEBAR_COLOR = newTheme.Sidebar
        CONTENT_COLOR = newTheme.Content
        CARD_COLOR = newTheme.Card
        TEXT_COLOR = newTheme.Text
        
        -- Flashy Live Tween Update
        local tInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        
        local function scanAndTween(parentObj)
            for _, obj in pairs(parentObj:GetDescendants()) do
                local tweens = {}
                if obj:IsA("GuiObject") or obj:IsA("UIStroke") then
                    pcall(function()
                        if obj.BackgroundColor3 and targetColors[obj.BackgroundColor3:ToHex()] then tweens.BackgroundColor3 = targetColors[obj.BackgroundColor3:ToHex()] end
                    end)
                    pcall(function()
                        if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and obj.TextColor3 and targetColors[obj.TextColor3:ToHex()] then
                            tweens.TextColor3 = targetColors[obj.TextColor3:ToHex()]
                        end
                    end)
                    pcall(function()
                        if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.ImageColor3 and targetColors[obj.ImageColor3:ToHex()] then
                            tweens.ImageColor3 = targetColors[obj.ImageColor3:ToHex()]
                        end
                    end)
                    pcall(function()
                        if obj:IsA("ScrollingFrame") and obj.ScrollBarImageColor3 and targetColors[obj.ScrollBarImageColor3:ToHex()] then
                            tweens.ScrollBarImageColor3 = targetColors[obj.ScrollBarImageColor3:ToHex()]
                        end
                    end)
                    pcall(function()
                        if obj:IsA("UIStroke") and obj.Color and targetColors[obj.Color:ToHex()] then
                            tweens.Color = targetColors[obj.Color:ToHex()]
                        end
                    end)
                end
                if next(tweens) then
                    tweenService:Create(obj, tInfo, tweens):Play()
                end
            end
        end
        
        scanAndTween(screenGui)
        scanAndTween(openBtnGui)
        
        -- Save
        pcall(function()
            if writefile then
                if not isfolder("RoseHub") then makefolder("RoseHub") end
                writefile("RoseHub/theme.txt", themeName)
            end
        end)
    end
    SettingsTab:AddButton({
        Name = "Unload UI",
        Callback = function()
            if screenGui then
                pcall(function() blurPart:Destroy() end)
                pcall(function() dof:Destroy() end)
                if blurConn then blurConn:Disconnect() end
                screenGui:Destroy()
            end
        end
    })

    local DebugTab = WindowObj:MakeTab({
        Name = "Debug",
        Icon = "settings-sliders.png",
        PremiumOnly = false,
        NoSeparator = true,
        LayoutOrder = 9998
    })
    WindowObj.DebugTab = DebugTab
    
    local toolsSec = DebugTab:AddSection("Tools")
    
    DebugTab:AddButton({
        Name = "Remote Spy",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
        end
    })
    
    DebugTab:AddButton({
        Name = "Dex",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/MITUMAxDev/Tools/refs/heads/main/Dex-Explorer.lua"))({"https://discord.gg/PsF7tsxKSS"})
        end
    })
    
    DebugTab:AddButton({
        Name = "Infinite Yield",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end
    })
    
    local utilsSec = DebugTab:AddSection("Utilities")
    
    DebugTab:AddButton({
        Name = "Server Hop",
        Callback = function()
            RoseUI:Notify({Title = "Hop", Text = "Finding a new server...", Duration = 3})
            local HttpService, TPService = game:GetService("HttpService"), game:GetService("TeleportService")
            local sfUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            local reqFunc = request or http_request or (http and http.request) or (fluxus and fluxus.request)
            if not reqFunc then
                RoseUI:Notify({Title = "Error", Text = "Your executor does not support Server Hopping.", Duration = 4})
                return
            end
            pcall(function()
                local req = reqFunc({Url = sfUrl, Method = "GET"})
                if req and req.Body then
                    local body = HttpService:JSONDecode(req.Body)
                    if body and body.data then
                        for i, v in next, body.data do
                            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                                TPService:TeleportToPlaceInstance(game.PlaceId, v.id, game.Players.LocalPlayer)
                                break
                            end
                        end
                    end
                end
            end)
        end
    })
    
    DebugTab:AddButton({
        Name = "Rejoin Server",
        Callback = function()
            RoseUI:Notify({Title = "Rejoin", Text = "Rejoining current server...", Duration = 3})
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
        end
    })

        local ConfigTab = WindowObj:MakeTab({
            Name = "Config",
            Icon = "disk.png",
            PremiumOnly = false,
            NoSeparator = true,
            LayoutOrder = 9999
        })
        WindowObj.ConfigTab = ConfigTab
        WindowObj:CreateConfigManager(ConfigTab)
    end

    -- ================= INTRO ANIMATION =================
    dragFrame.Size = UDim2.new(0, 0, 0, 0)
    dragFrame.ClipsDescendants = true

-- Load vectors dynamically from GitHub to keep this file clean!
        local HttpService = game:GetService("HttpService")
        local roseHubOutline = {}
        
        pcall(function()
            local rawJson = game:HttpGet("https://raw.githubusercontent.com/mschr703/Rose-UI-Lua/main/RoseHubSVG.json")
            if rawJson then
                local parsed = HttpService:JSONDecode(rawJson)
                for _, shape in ipairs(parsed) do
                    local stroke = {}
                    for _, pt in ipairs(shape) do
                        table.insert(stroke, Vector2.new(pt[1], pt[2]))
                    end
                    table.insert(roseHubOutline, stroke)
                end
            end
        end)
        
        -- Fallback if fetch fails or is empty, just a tiny dot
        if #roseHubOutline == 0 then
            roseHubOutline = { { Vector2.new(0, 0), Vector2.new(1, 1) } }
        end

-- ========================================================
-- LOGO ASSET LOADER (Maximum Compatibility Edition)
-- ========================================================
local getasset = select(2, pcall(function() return getcustomasset and getcustomasset or (getgenv and getgenv().getcustomasset) end))
local logoAssetUrl = "" -- Empty means we fallback to the Rose Emoji

pcall(function()
    if getasset and type(getasset) == "function" then
        -- Ultra safe checks to prevent Xeno or basic executors from crashing
        local hasIsFolder = type(isfolder) == "function"
        local hasMakeFolder = type(makefolder) == "function"
        local hasIsFile = type(isfile) == "function"
        local hasWriteFile = type(writefile) == "function"
        
        if hasIsFolder and hasMakeFolder then
            pcall(function()
                if not isfolder("RoseHub") then makefolder("RoseHub") end
                if not isfolder("RoseHub/assets") then makefolder("RoseHub/assets") end
            end)
        end
        
        local path = "RoseHub/assets/rose_logo_v3_small.png"
        local fileExists = false
        if hasIsFile then
            pcall(function() fileExists = isfile(path) end)
        end
        
        if not fileExists and hasWriteFile then
            local success, data = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/rosehublua/rosehubimages/main/roselogo.png") end)
            if success and data then 
                pcall(function() writefile(path, data) end)
            end
        end
        
        -- Final check before assigning Native Asset URL
        if hasIsFile then
            local stillExists = false
            pcall(function() stillExists = isfile(path) end)
            if stillExists then
                logoAssetUrl = getasset(path)
            end
        end
    end
end)

local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")
local debris = game:GetService("Debris")

local GUI_NAME = "RoseUI_Animation_Test"
local CANVAS_SIZE = Vector2.new(400, 120)
local CANVAS_PADDING = 12
local BG_COLOR = Color3.fromRGB(12, 8, 12)
local STROKE_COLOR = Color3.fromHex("#c00000")
local OUTLINE_COLOR = Color3.fromHex("#5a0000") -- Darker red for the stroke outline
local GLOW_COLOR = Color3.fromRGB(220, 0, 0) -- Pure bright red for aura
local GLOW_SPREAD = 45 -- How much wider than the text the glow aura reaches
local GLOW_OPACITY = 0.88 -- Very transparent particles stacked to form organic glow
local STROKE_THICKNESS = 16 -- Much thinner core text to fully open all intrinsic loops
local BRUSH_STEP = 1
local SEGMENT_WAIT_EVERY = 18 -- Slightly faster drawing
local SIMPLIFY_SKIP = 2 -- Lower skip -> smoother curves, less lumpiness
local START_DELAY = 0.35
local END_HOLD = 0.6

-- screenGui from RoseUI














if not _G.RoseUI_IntroPlayed then
    _G.RoseUI_IntroPlayed = true

    local introBg = Instance.new("Frame")
    introBg.Size = UDim2.new(1, 0, 1, 0)
introBg.BackgroundColor3 = Color3.fromRGB(12, 8, 12)
introBg.BackgroundTransparency = 1 -- Start fully transparent
introBg.ZIndex = 999
introBg.Parent = screenGui

-- Fade in darkness smoothly
game:GetService("TweenService"):Create(introBg, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0.45
}):Play()
introBg.BorderSizePixel = 0
-- introBg.ZIndex = 999 -- Already set above
-- introBg.Parent = screenGui -- Already set above

local canvas = Instance.new("Frame")
canvas.Size = UDim2.fromOffset(CANVAS_SIZE.X, CANVAS_SIZE.Y)
canvas.Position = UDim2.new(0.5, 0, 0.5, 75)
canvas.AnchorPoint = Vector2.new(0.5, 0.5)
canvas.BackgroundTransparency = 1
canvas.BorderSizePixel = 0
canvas.ZIndex = 1000
canvas.Parent = introBg

local drawFolder = Instance.new("Folder")
drawFolder.Name = "DrawnSegments"
drawFolder.Parent = canvas

local function clonePath(path)
    local out = table.create(#path)
    for i = 1, #path do
        out[i] = path[i]
    end
    return out
end

local function reversePath(path)
    local out = table.create(#path)
    for i = #path, 1, -1 do
        out[#out + 1] = path[i]
    end
    return out
end

local function rotatePath(path, startIndex)
    local out = table.create(#path)
    for i = startIndex, #path do
        out[#out + 1] = path[i]
    end
    for i = 1, startIndex - 1 do
        out[#out + 1] = path[i]
    end
    return out
end

local function isClosedPath(path)
    if #path < 3 then
        return false
    end
    return (path[1] - path[#path]).Magnitude <= 4
end

local function orientClosedPathLeftToRight(path)
    local leftIndex = 1
    local bestX = math.huge
    local bestY = math.huge
    for i, p in ipairs(path) do
        if p.X < bestX or (math.abs(p.X - bestX) < 0.01 and p.Y < bestY) then
            bestX = p.X
            bestY = p.Y
            leftIndex = i
        end
    end

    local rotated = rotatePath(path, leftIndex)
    local nextIndex = math.min(4, #rotated)
    local prevIndex = #rotated - math.min(3, #rotated - 1)
    local nextX = rotated[nextIndex].X
    local prevX = rotated[prevIndex].X

    if nextX < prevX then
        path = reversePath(path)
        leftIndex = 1
        bestX = math.huge
        bestY = math.huge
        for i, p in ipairs(path) do
            if p.X < bestX or (math.abs(p.X - bestX) < 0.01 and p.Y < bestY) then
                bestX = p.X
                bestY = p.Y
                leftIndex = i
            end
        end
        rotated = rotatePath(path, leftIndex)
    end

    return rotated
end

local function simplifyPath(path, skip)
    if skip <= 1 or #path <= 3 then
        return path
    end
    local out = { path[1] }
    for i = 2, #path - 1, skip do
        out[#out + 1] = path[i]
    end
    out[#out + 1] = path[#path]
    return out
end

local function getBounds(paths)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for _, path in ipairs(paths) do
        for _, p in ipairs(path) do
            if p.X < minX then minX = p.X end
            if p.Y < minY then minY = p.Y end
            if p.X > maxX then maxX = p.X end
            if p.Y > maxY then maxY = p.Y end
        end
    end
    return minX, minY, maxX, maxY
end

local function sortAndPreparePaths(paths)
    local meta = {}
    for _, sourcePath in ipairs(paths) do
        local path = clonePath(sourcePath)
        local minX, maxX = math.huge, -math.huge
        local minY = math.huge
        for _, p in ipairs(path) do
            if p.X < minX then minX = p.X end
            if p.X > maxX then maxX = p.X end
            if p.Y < minY then minY = p.Y end
        end

        if isClosedPath(path) then
            path = orientClosedPathLeftToRight(path)
        elseif path[1].X > path[#path].X then
            path = reversePath(path)
        end

        meta[#meta + 1] = {
            path = path,
            minX = minX,
            maxX = maxX,
            minY = minY
        }
    end

    table.sort(meta, function(a, b)
        if math.abs(a.minX - b.minX) < 10 then
            return a.minY < b.minY
        end
        return a.minX < b.minX
    end)

    local ordered = {}
    for _, item in ipairs(meta) do
        ordered[#ordered + 1] = item.path
    end
    return ordered
end

local orderedPaths = sortAndPreparePaths(roseHubOutline)
local minX, minY, maxX, maxY = getBounds(orderedPaths)
local width = maxX - minX
local height = maxY - minY
local fitScale = math.min(
    (CANVAS_SIZE.X - CANVAS_PADDING * 2) / width,
    (CANVAS_SIZE.Y - CANVAS_PADDING * 2) / height
)
local stretchX = 1.22 -- Stretch text horizontally heavily to keep cursive loops readable
local scaledWidth = width * fitScale * stretchX
local offsetX = (CANVAS_SIZE.X - scaledWidth) * 0.5
local offsetY = (CANVAS_SIZE.Y - height * fitScale) * 0.5

local function transformPoint(p)
    return Vector2.new(
        (p.X - minX) * fitScale * stretchX + offsetX,
        (p.Y - minY) * fitScale + offsetY
    )
end

local transformedPaths = {}
for pathIndex, path in ipairs(orderedPaths) do
    local isO = (pathIndex == 2)
    local o_cy = 0
    if isO then
        local pMinY, pMaxY = math.huge, -math.huge
        for _, p in ipairs(path) do
            if p.Y < pMinY then pMinY = p.Y end
            if p.Y > pMaxY then pMaxY = p.Y end
        end
        o_cy = (pMinY + pMaxY) * 0.5
    end

    local transformed = table.create(#path)
    for i, p in ipairs(path) do
        local finalP = p
        if isO then
            -- Scale small loop letters outward from their individual independent centers
            -- This keeps 'o', 's', and 'e' geometrically hollow without displacing them
            finalP = Vector2.new(o_cy + (p.X - o_cy) * 1.35, o_cy + (p.Y - o_cy) * 1.45)
        end
        transformed[i] = transformPoint(finalP)
    end
    transformed = simplifyPath(transformed, SIMPLIFY_SKIP)
    transformedPaths[#transformedPaths + 1] = transformed
end

local function makeCircle(position, diameter, color, zindex, parent, transparency)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(diameter, diameter)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.fromOffset(position.X, position.Y)
    dot.BackgroundColor3 = color
    dot.BackgroundTransparency = transparency or 0
    dot.BorderSizePixel = 0
    dot.ZIndex = zindex
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    dot.Parent = parent
    return dot
end

local function makeGlow(position, diameter, color, zindex, parent)
    local glow = Instance.new("ImageLabel")
    glow.Image = "rbxassetid://1316045217" -- Soft blurry circle particle
    glow.ImageColor3 = color
    glow.BackgroundTransparency = 1
    glow.ImageTransparency = 1 -- Start totally invisible
    glow.Size = UDim2.fromOffset(diameter, diameter)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.fromOffset(position.X, position.Y)
    glow.BorderSizePixel = 0
    glow.ZIndex = zindex
    glow.Parent = parent
    return glow
end

local function drawSegment(pA, pB, thickness, color, zindex, parent, transparency)
    local delta = pB - pA
    local dist = delta.Magnitude
    if dist < 0.05 then
        local dot = makeCircle(pA, thickness, color, zindex, parent, transparency)
        return nil, dot
    end

    local line = Instance.new("Frame")
    line.Size = UDim2.fromOffset(dist + thickness, thickness)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.fromOffset((pA.X + pB.X) * 0.5, (pA.Y + pB.Y) * 0.5)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.BackgroundColor3 = color
    line.BackgroundTransparency = transparency or 0
    line.BorderSizePixel = 0
    line.ZIndex = zindex - 1
    Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)
    line.Parent = parent
    
    -- Crucial: Place a circle at the end point to act as a perfect round hinge for the next segment
    local joint = makeCircle(pB, thickness, color, zindex, parent, transparency)
    
    return line, joint
end

local function fadeOutAll(logoObj)
    local tweens = {}
    local objectsToFade = introBg:GetDescendants()
    if logoObj then
        table.insert(objectsToFade, logoObj)
    end
    
    for _, obj in ipairs(objectsToFade) do
        local goal = {}
        if obj:IsA("Frame") and obj ~= introBg then
            goal.BackgroundTransparency = 1
        elseif obj:IsA("ImageLabel") then
            goal.ImageTransparency = 1
        elseif obj:IsA("TextLabel") then
            goal.TextTransparency = 1
        end
        if next(goal) then
            tweens[#tweens + 1] = tweenService:Create(obj, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), goal)
        end
    end

    local bgTween = tweenService:Create(introBg, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        BackgroundTransparency = 1
    })
    tweens[#tweens + 1] = bgTween

    for _, tween in ipairs(tweens) do
        tween:Play()
    end

    bgTween.Completed:Wait()
    if logoObj then
        logoObj:Destroy()
    end
end

task.spawn(function()
    task.wait(START_DELAY)

    -- 1. Pop the logo out beautifully BEFORE drawing the text
    local logo
    local showGoal = { Size = UDim2.fromOffset(110, 110) }
    
    if logoAssetUrl ~= "" then
        logo = Instance.new("ImageLabel")
        logo.Image = logoAssetUrl
        logo.ImageTransparency = 1
        showGoal.ImageTransparency = 0
    else
        logo = Instance.new("TextLabel")
        logo.Text = "🌹"
        logo.TextScaled = true
        logo.TextTransparency = 1
        showGoal.TextTransparency = 0
    end

    logo.Name = "RoseLogo"
    logo.BackgroundTransparency = 1
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    
    logo.Position = UDim2.new(0.5, 0, 0.5, -20)
    
    logo.Size = UDim2.fromOffset(0, 0)
    logo.ZIndex = 2000 -- Ensure logo is above everything
    logo.Parent = screenGui -- Parent directly to ScreenGui so it's guaranteed visible over everything

    local showTween = tweenService:Create(logo, TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), showGoal)
    showTween:Play()
    showTween.Completed:Wait()
    -- 2. Draw the cursive text (Base Text First)
    local segmentCounter = 0
    local baseThickness = math.max(2, math.floor(STROKE_THICKNESS * fitScale * 1.0))
    local shadowThickness = baseThickness + 10 -- Massive 5px border on both sides retains exact overall visual blob width while core stays thin
    local lastEnd = nil
    
    local outlineFrames = {}
    local function addOutline(obj1, obj2)
        if obj1 then outlineFrames[#outlineFrames + 1] = obj1 end
        if obj2 then outlineFrames[#outlineFrames + 1] = obj2 end
    end
    
    local function createConcentricGlow(x, y, diameter, color, zindex, parent, baseTransp, layers, outTable)
        for i = 1, layers do
            local fraction = i / layers
            -- Soft exponential fade to the edges
            local targetTransp = baseTransp + (1 - baseTransp) * math.pow(fraction, 1.5)
            targetTransp = math.min(0.99, targetTransp)
            
            local dot = Instance.new("Frame")
            dot.BackgroundColor3 = color
            dot.BackgroundTransparency = 1 -- fully hidden at start
            dot.BorderSizePixel = 0
            dot.Size = UDim2.fromOffset(diameter * fraction, diameter * fraction)
            dot.Position = UDim2.fromOffset(x, y)
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.ZIndex = zindex
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            dot.Parent = parent
            
            outTable[#outTable+1] = { obj = dot, target = targetTransp }
        end
    end

    -- PASS: Prepare Cinematic Ambient Backglow natively
    local ambientGlows = {}
    for _, path in ipairs(transformedPaths) do
        if #path > 0 then
            local pMinX, pMaxX = math.huge, -math.huge
            local pMinY, pMaxY = math.huge, -math.huge
            for _, p in ipairs(path) do
                if p.X < pMinX then pMinX = p.X end
                if p.X > pMaxX then pMaxX = p.X end
                if p.Y < pMinY then pMinY = p.Y end
                if p.Y > pMaxY then pMaxY = p.Y end
            end
            
            local w = pMaxX - pMinX
            local h = pMaxY - pMinY
            local cx = pMinX + w * 0.5
            local cy = pMinY + h * 0.5
            local maxDim = math.max(w, h, 80)
            
            -- Deep wide crimson aura (Outer Bloom) - Natively stacked!
            createConcentricGlow(cx, cy, maxDim * 2.8 + 100, Color3.fromHex("#a00000"), 998, drawFolder, 0.98, 14, ambientGlows)

            -- Brighter neon core (Inner Bloom) - Natively stacked!
            createConcentricGlow(cx, cy, maxDim * 1.8 + 40, Color3.fromHex("#ff0000"), 999, drawFolder, 0.94, 10, ambientGlows)
        end
    end
    
    -- Start the glow fade-in IMMEDIATELY, taking 2.5 seconds to slowly bloom behind the drawing text
    task.spawn(function()
        for _, glowData in ipairs(ambientGlows) do
            tweenService:Create(glowData.obj, TweenInfo.new(2.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { BackgroundTransparency = glowData.target }):Play()
        end
    end)
    
    -- PASS: Main Fill & Invisible Outline Generated Concurrently
    for _, path in ipairs(transformedPaths) do
        if #path > 0 then
            makeCircle(path[1], baseThickness, STROKE_COLOR, 1006, drawFolder)
            -- Hidden dark red outline
            addOutline(makeCircle(path[1], shadowThickness, OUTLINE_COLOR, 1004, drawFolder, 1))

            for i = 2, #path do
                local pA = path[i - 1]
                local pB = path[i]
                
                -- Draw main red
                drawSegment(pA, pB, baseThickness, STROKE_COLOR, 1006, drawFolder)
                
                -- Draw hidden shadow outline concurrently
                local line, joint = drawSegment(pA, pB, shadowThickness, OUTLINE_COLOR, 1004, drawFolder, 1)
                addOutline(line, joint)
                
                segmentCounter = segmentCounter + 1
                if segmentCounter % SEGMENT_WAIT_EVERY == 0 then
                    task.wait()
                end
            end

            lastEnd = path[#path]
        end
    end

    -- 3. Fade in the Outline simultaneously after completion
    for _, obj in ipairs(outlineFrames) do
        tweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    end
    task.wait(0.5)

    -- 4. Hold for a moment so the user can literally soak in the neon glow
    task.wait(1.5)

    -- 4. Shrink logo slightly before the full fade out to simulate "jumping out"
    local shrinkTween = tweenService:Create(logo, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(80, 80)
    })
    shrinkTween:Play()
    shrinkTween.Completed:Wait()

    -- 5. Fade everything out
    fadeOutAll(logo)
    introBg:Destroy()

        -- Open main window
        local openTw = tweenService:Create(dragFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = DEFAULT_SIZE})
        openTw:Play()
        openTw.Completed:Wait()
        dragFrame.ClipsDescendants = false
        
        local pName = game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name or "Guest"
        RoseUI:Notify({Title = "🌹 Welcome, " .. pName .. "!", Text = "Successfully loaded " .. titleText .. ". Enjoy!", Duration = 5})

    end)
else
    -- Skip the intro entirely, but still open the window and notify!
    dragFrame.Size = DEFAULT_SIZE
    dragFrame.ClipsDescendants = false
    
    local pName = game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name or "Guest"
    RoseUI:Notify({Title = "🌹 Welcome, " .. pName .. "!", Text = "Successfully loaded " .. titleText .. ". Enjoy!", Duration = 5})
end
    -- AUTOMATIC AUTOLOADER:
    -- Wait 2 seconds for the user's script to finish building all their Tabs and Elements, then inject the saved configs natively.
    task.spawn(function()
        task.wait(2)
        pcall(function()
            if RoseUI.Init then RoseUI:Init() end
        end)
    end)

    if not options.HideDefaultTabs then
        local success, err = pcall(function()
            local HomeTab = WindowObj:MakeTab({Name = "Home", Icon = "home.png", LayoutOrder = -1})
            
            local homeSpacer = Instance.new("Frame")
            homeSpacer.Size = UDim2.new(1, 0, 0, 4) -- Small gap
            homeSpacer.BackgroundTransparency = 1
            homeSpacer.LayoutOrder = 0 -- Ensures it stays directly under HomeTab
            homeSpacer.Parent = tabContainer
            
            local execName = "Unknown Executor"
            pcall(function()
                if type(identifyexecutor) == "function" then
                    execName = identifyexecutor()
                end
            end)
            local pName = "Guest"
            pcall(function()
                pName = game:GetService("Players").LocalPlayer.Name
            end)
            
            local dayOfWeek = os.date("%A")
            local userRole = "Free User" -- Placeholder, could be integrated with your own auth
            
            local keyTimeStr = "Lifetime"
            pcall(function()
                if type(LRM_SecondsLeft) == "number" then
                    if LRM_SecondsLeft > 0 and LRM_SecondsLeft < 315360000 then -- If less than 10 years, it's not a lifetime key
                        local hours = math.floor(LRM_SecondsLeft / 3600)
                        local minutes = math.floor((LRM_SecondsLeft % 3600) / 60)
                        keyTimeStr = tostring(hours) .. "h " .. tostring(minutes) .. "m"
                    end
                end
            end)
            
            local eNameLower = string.lower(execName)
            local score = 3
            if string.find(eNameLower, "volt") then score = 10 
            elseif string.find(eNameLower, "potassium") then score = 9
            elseif string.find(eNameLower, "delta") then score = 8
            elseif string.find(eNameLower, "codex") then score = 8
            elseif string.find(eNameLower, "arceus") then score = 8
            elseif string.find(eNameLower, "wave") then score = 6
            elseif string.find(eNameLower, "solara") then score = 5
            elseif string.find(eNameLower, "awp") then score = 5
            elseif string.find(eNameLower, "xeno") then score = 5
            elseif string.find(eNameLower, "nezur") then score = 4
            end

            local rColor, rMsg
            if score >= 8 then
                rColor = Color3.fromRGB(80, 220, 100)
                rMsg = "You will have no problems with this executor."
            elseif score >= 5 then
                rColor = Color3.fromRGB(255, 170, 50)
                rMsg = "You may experience minor problems using our scripts with this executor."
            else
                rColor = Color3.fromRGB(240, 60, 60)
                rMsg = "You may experience problems using our scripts with this executor."
            end
            
            HomeTab:AddDashboardRow({
                Banner = {
                    Title = "Welcome, " .. pName,
                    Desc = "Role: " .. userRole .. "\nKey Time: " .. keyTimeStr,
                    Image = "rbxassetid://10459521360" -- Cool fluid purple texture
                },
                Ring = {
                    Title = "Executor:",
                    Desc = execName,
                    Number = tostring(score),
                    Label = "SCORE",
                    Color = rColor,
                    Message = rMsg,
                    MessageColor = rColor
                }
            })
            
            -- Full Width Card for Server Info
            local playerCount = 0
            local maxPlayers = 0
            pcall(function()
                playerCount = #game:GetService("Players"):GetPlayers()
                maxPlayers = game:GetService("Players").MaxPlayers
            end)
            
            local serverCard = HomeTab:AddDashboardFullCard({
                Title = "Server Information",
                Desc = "Loading Game Info...\nPlace ID: " .. tostring(game.PlaceId) .. "\nPlayers: " .. tostring(playerCount) .. " / " .. tostring(maxPlayers) .. "\nJob ID: " .. tostring(game.JobId),
                Image = "rbxassetid://10111160350", -- Alternate sleek fluid/tech background
                ImageColor = Color3.fromRGB(80, 150, 255)
            })
            
            task.spawn(function()
                local gName = "Unknown Game"
                pcall(function()
                    gName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                end)
                if serverCard and serverCard.Desc then
                    serverCard.Desc.Text = "Game: " .. tostring(gName) .. "\nPlace ID: " .. tostring(game.PlaceId) .. "\nPlayers: " .. tostring(playerCount) .. " / " .. tostring(maxPlayers) .. "\nJob ID: " .. tostring(game.JobId)
                end
            end)
            
            -- Full Width Card for Discord
            HomeTab:AddDashboardFullCard({
                Title = "Join the Community",
                Desc = "Stay updated on the latest scripts, get support, and talk to other exploiters!\nLink: discord.gg/rosehub",
                Image = "rbxassetid://10459521360", 
                ImageColor = Color3.fromRGB(80, 100, 240) -- Bluish Discord-like tone
            })
            
            -- Force Home Tab to be the default open tab regardless of script execution order!
            task.spawn(function()
                task.wait(0.1) -- Tiny delay allows the script to finish building other tabs first
                if HomeTab and type(HomeTab.Select) == "function" then
                    HomeTab:Select()
                end
            end)
        end)
        if not success then
            warn("[RoseUI] HomeTab Creation Error: " .. tostring(err))
        end
    end

    return WindowObj
end

-- ========================================================
-- ROSE UI FRAMEWORK V3 - COMPLETE DOCUMENTATION
-- ========================================================
--[[
    Welcome to the Rose UI Framework V3!
    This is a modern, responsive, and animated UI library for Roblox exploit scripts.

    # 1. Bootstrapping the Window
    local Window = RoseUI:CreateWindow({
        Name = "Rose Hub | Your Title",
        HidePremium = false,
        SaveConfig = true,
        ConfigFolder = "RoseHubConfigs"
    })

    # 2. Creating Tabs & Sections
    local MainTab = Window:MakeTab({
        Name = "Main",
        Icon = "home.png", -- Can be an asset ID or raw link from github
        PremiumOnly = false
    })
    
    local Section = MainTab:AddSection("Player Features")

    # 3. Basic Elements
    MainTab:AddLabel("Informational text goes here.")

    MainTab:AddButton({
        Name = "Kill All",
        Description = "Instantly wipe the server", -- Optional sub-text
        Callback = function()
            print("Action hit!")
        end
    })

    MainTab:AddToggle({
        Name = "Auto-Aim",
        Description = "Locks onto nearest players automatically", -- Optional sub-text
        Default = false,
        Callback = function(Value)
            print("Toggle Set To:", Value)
        end
    })

    # 4. Interactive Adjustments
    MainTab:AddSlider({
        Name = "WalkSpeed",
        Description = "Adjusts movement speed", -- Optional sub-text
        Min = 16,
        Max = 200,
        Default = 16,
        Color = Color3.fromRGB(240, 80, 100), -- Accent color (Optional)
        Increment = 1,
        ValueName = "WS",
        Callback = function(Value)
            print("Speed:", Value)
        end
    })

    # 5. Dropdowns & Pickers
    MainTab:AddDropdown({
        Name = "Target Player",
        Default = "LocalPlayer",
        Options = {"LocalPlayer", "Player1", "Player2"},
        Callback = function(Value)
            print("Selected:", Value)
        end
    })

    MainTab:AddSearchDropdown({
        Name = "Select Item",
        Default = "Sword",
        Options = {"Sword", "Shield", "Potion", "Bow", "Apple", "Wood"},
        Callback = function(Value)
            print("Searched & Selected:", Value)
        end
    })

    MainTab:AddColorPicker({
        Name = "ESP Color",
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(Value)
            print("Color:", Value)
        end
    })

    # 6. Inputs & Binds
    MainTab:AddTextbox({
        Name = "Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(Text)
            print("Input:", Text)
        end
    })

    MainTab:AddKeybind({
        Name = "Toggle Menu",
        Default = Enum.KeyCode.RightShift,
        Hold = false,
        Callback = function()
            print("Key Pressed!")
        end
    })

    # 7. Advanced Hybrid Elements
    MainTab:AddToggleSlider({
        Name = "Hitbox Expander",
        Min = 0,
        Max = 50,
        DefaultSlider = 10,
        DefaultToggle = false,
        Suffix = "studs",
        OnToggle = function(Toggled)
            print("Hitbox Active:", Toggled)
        end,
        OnSlider = function(Value)
            print("Hitbox Size:", Value)
        end
    })

    # 8. Data Layouts
    -- AddInventoryGrid is designed for slot-based items
    MainTab:AddInventoryGrid({
        Items = {
            {Name = "Sword", Quantity = 1},
            {Name = "Wood", Quantity = 64}
        },
        OnItemClick = function(item)
            print("Clicked", item.Name)
        end
    })

    # 9. Initialization
    -- You do NOT need to call anything at the end. RoseUI automatically loads your saved configs!
]]

-- ========================================================
-- MASTER HUB GENERATOR EXTENSION (NATIVE GALLERY)
-- ========================================================
function RoseUI:CreateMasterHub(gamesTable)
    _G.RoseHub_ShowHub = function()
        pcall(function()
            local cl = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            local getGui = game:GetService("CoreGui"):FindFirstChild("RoseUI_Window") or cl:FindFirstChild("RoseUI_Window")
            if getGui then getGui.Enabled = false end
            local getHub = game:GetService("CoreGui"):FindFirstChild("RoseUI_HubWindow") or cl:FindFirstChild("RoseUI_HubWindow")
            if getHub then getHub.Enabled = true end
        end)
    end
    
        local function SafeLaunch(placeName, funcObj)
        local cl = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local getGui = game:GetService("CoreGui"):FindFirstChild("RoseUI_Window") or cl:FindFirstChild("RoseUI_Window")
        
        -- Hide the hub IMMEDIATELY, don't stall with an animation or outline ghosting
        pcall(function()
            local getHub = game:GetService("CoreGui"):FindFirstChild("RoseUI_HubWindow") or cl:FindFirstChild("RoseUI_HubWindow")
            if getHub then getHub.Enabled = false end
        end)
        
        if getGui then
            getGui.Enabled = true
        else
            _G.Rose_SecureTicket = "ROSEHUB_" .. tostring(math.random(10000000, 99999999))
            task.spawn(function()
                local s, e = pcall(funcObj)
                if not s then warn("[RoseHub] Load Error: " .. tostring(e)) end
            end)
        end
    end
    
    local HubWin = RoseUI:CreateWindow({
        Name = "Rose Hub | Game Selector",
        HubType = "RoseUI",
        WindowName = "RoseUI_HubWindow",
        HideDefaultTabs = true
    })
    
    local GalleryTab = HubWin:MakeTab({Name = "Game Gallery", Icon = "gamepad.png"})
    
    -- Map SafeLaunch closures to the gamesTable
    for _, g in ipairs(gamesTable) do
        local originalCb = g.Callback
        g.Callback = function() SafeLaunch(g.Name, originalCb) end
    end
    
    GalleryTab:AddGameGallery({
        Name = "Explore Games",
        Items = gamesTable
    })
end

return RoseUI
