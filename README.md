# RoseUI V3 - Premium Roblox UI Library
An elegant, modern, and translucent UI Library for Roblox, designed to look sleek and minimalistic.

![Preview](https://i.imgur.com/placeholder.png)

## Features
- **Sleek Glass Aesthetic:** Smooth translucent backgrounds with rounded solid inner containers.
- **Premium Intro Animation:** Eye-catching ripple explosion and fading text reveal.
- **Player Profile Sidebar:** Automatically fetches the user's Roblox Avatar and Username.
- **Built-in Configuration Manager:** Save and load your UI states (Toggles, Sliders, Colors, Dropdowns) locally via JSON. Automatically updates the dropdown when saving.
- **Custom Toggle Keybinds:** Right-click any toggle to assign a custom keybind to it dynamically.
- **Full Parity:** Supports Buttons, Toggles, Sliders, Dropdowns, 2D Color Pickers, Keybinds, Textboxes, and Labels.

### Basic Usage

```lua
-- Fetch the library
local RoseUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/DeinGitHubName/RoseUI/main/RoseUI.lua"))()

-- Create the Window
local Window = RoseUI:CreateWindow({
    Name = "My Premium Hub 🌹",
    HubType = "Private Script",
    ConfigFolder = "MyAwesomeHub_Configs" -- Name of the folder in your executor's workspace
})

-- Create a Tab
local CombatTab = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://10652380582"})

-- Create a Section
local AimbotSection = CombatTab:AddSection("Aimbot Settings")

-- Add a Toggle
AimbotSection:AddToggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(state)
        print("Aimbot is now:", state)
    end
})

-- You can also just add elements directly to the Tab
CombatTab:AddSlider({
    Name = "Field of View",
    Min = 10,
    Max = 800,
    Default = 200,
    Callback = function(val)
        print("FOV:", val)
    end
})

-- Build the Configuration Manager
-- (Pass the Tab where you want the Save/Load Config UI to appear)
local SettingsTab = Window:MakeTab({Name = "Settings", Icon = "rbxassetid://10652379361"})
Window:CreateConfigManager(SettingsTab)
```

## Adding Elements

### Button
```lua
Tab:AddButton({
    Name = "Click Me!",
    Callback = function()
        print("Clicked!")
    end
})
```

### Toggle (Supports Right-Click Custom Keybinds)
```lua
Tab:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(state)
        print("Auto Farm:", state)
    end
})
```

### Slider
```lua
Tab:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 250,
    Default = 50,
    Callback = function(val)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
})
```

### Dropdown
```lua
Tab:AddDropdown({
    Name = "Select Weapon",
    Options = {"Sword", "Bow", "Magic"},
    Default = "Sword",
    Callback = function(val)
        print("Selected:", val)
    end
})
```

### Color Picker
```lua
Tab:AddColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(col)
        print("New Color:", col)
    end
})
```

### Textbox
```lua
Tab:AddTextbox({
    Name = "Target Player",
    Placeholder = "Enter Name...",
    Callback = function(val)
        print("Target:", val)
    end
})
```

### Keybind
```lua
Tab:AddKeybind({
    Name = "Hide GUI",
    Default = Enum.KeyCode.RightAlt,
    Callback = function()
        print("Key pressed!")
    end
})
```

## Setup Notes
- To toggle the UI on and off, simply press **Right Alt**. (Can be changed in the source if needed).
- Configurations are saved in your Executor's `workspace` folder under the directory name you provide in `ConfigFolder`.
