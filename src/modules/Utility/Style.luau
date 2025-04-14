--[[ Style
    Core UI styling constants and functions
    @module Style
]]
local Style = {}

-- Colors
Style.Colors = {
    Background = {
        Primary = Color3.fromRGB(30, 30, 40),
        Secondary = Color3.fromRGB(40, 40, 50),
        Tertiary = Color3.fromRGB(45, 45, 55),
        Elevated = Color3.fromRGB(50, 50, 60),
        Overlay = Color3.fromRGB(0, 0, 0),
        Modal = Color3.fromRGB(35, 35, 45),
        Card = Color3.fromRGB(45, 45, 55),
        Tooltip = Color3.fromRGB(25, 25, 35),
        Highlight = Color3.fromRGB(55, 55, 65)
    },
    Text = {
        Primary = Color3.fromRGB(255, 255, 255),
        Secondary = Color3.fromRGB(200, 200, 200),
        Disabled = Color3.fromRGB(150, 150, 150),
        Accent = Color3.fromRGB(65, 140, 240),
        Error = Color3.fromRGB(255, 100, 100),
        Success = Color3.fromRGB(100, 200, 100),
        Warning = Color3.fromRGB(255, 180, 100),
        Link = Color3.fromRGB(100, 160, 255),
        Inverse = Color3.fromRGB(30, 30, 40)
    },
    Accent = {
        Primary = Color3.fromRGB(65, 140, 240),
        Secondary = Color3.fromRGB(100, 160, 255),
        Success = Color3.fromRGB(60, 200, 60),
        Warning = Color3.fromRGB(240, 180, 60),
        Danger = Color3.fromRGB(200, 60, 60),
        Info = Color3.fromRGB(100, 200, 255),
        Light = Color3.fromRGB(120, 180, 255),
        Dark = Color3.fromRGB(45, 120, 220)
    },
    Button = {
        Default = Color3.fromRGB(45, 45, 55),
        Hover = Color3.fromRGB(55, 55, 65),
        Pressed = Color3.fromRGB(35, 35, 45),
        Disabled = Color3.fromRGB(40, 40, 50),
        Primary = Color3.fromRGB(65, 140, 240),
        PrimaryHover = Color3.fromRGB(85, 160, 255),
        Danger = Color3.fromRGB(200, 60, 60),
        DangerHover = Color3.fromRGB(220, 80, 80),
        Success = Color3.fromRGB(60, 180, 60),
        SuccessHover = Color3.fromRGB(80, 200, 80),
        Warning = Color3.fromRGB(240, 180, 60),
        WarningHover = Color3.fromRGB(255, 200, 80),
        Close = Color3.fromRGB(200, 60, 60)
    },
    Input = {
        Background = Color3.fromRGB(40, 40, 50),
        Border = Color3.fromRGB(60, 60, 70),
        Focus = Color3.fromRGB(65, 140, 240),
        Error = Color3.fromRGB(200, 60, 60),
        Success = Color3.fromRGB(60, 180, 60),
        Disabled = Color3.fromRGB(35, 35, 45)
    },
    Overlay = {
        Modal = Color3.fromRGB(0, 0, 0),
        ModalTransparency = 0.5,
        Toast = Color3.fromRGB(0, 0, 0),
        ToastTransparency = 0.2,
        Dropdown = Color3.fromRGB(0, 0, 0),
        DropdownTransparency = 0.3
    },
    Border = {
        Default = Color3.fromRGB(60, 60, 70),
        Focus = Color3.fromRGB(65, 140, 240),
        Error = Color3.fromRGB(200, 60, 60),
        Success = Color3.fromRGB(60, 180, 60),
        Divider = Color3.fromRGB(50, 50, 60)
    },
    Inventory = {
        Slot = Color3.fromRGB(35, 35, 45),
        SlotHover = Color3.fromRGB(50, 50, 60),
        SlotSelected = Color3.fromRGB(60, 60, 70)
    }
}

-- Typography
Style.Typography = {
    Display = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Weight = Enum.FontWeight.Bold,
        Size = 48,
        LineHeight = 1.2
    },
    Header = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Weight = Enum.FontWeight.Bold,
        Size = 42,
        LineHeight = 1.2
    },
    Title = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Weight = Enum.FontWeight.Bold,
        Size = 36,
        LineHeight = 1.2
    },
    Subtitle = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Weight = Enum.FontWeight.Bold,
        Size = 32,
        LineHeight = 1.3
    },
    Body = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Weight = Enum.FontWeight.Regular,
        Size = 28,
        LineHeight = 1.4
    },
    Button = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Weight = Enum.FontWeight.Bold,
        Size = 28,
        LineHeight = 1
    },
    Caption = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Size = 24,
        LineHeight = 1.4
    },
    Small = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Size = 22,
        LineHeight = 1.4
    },
    Tiny = {
        Font = "rbxasset://fonts/families/AccanthisADFStd.json",
        Size = 18,
        LineHeight = 1.4
    }
}

-- Layout
Style.Layout = {
    Padding = {
        Tiny = 4,
        Small = 6,
        Medium = 10,
        Large = 20,
        XLarge = 32
    },
    Corner = {
        None = 0,
        Small = 6,
        Medium = 8,
        Large = 12,
        XLarge = 16,
        Circle = 999
    },
    Border = {
        None = 0,
        Thin = 1,
        Medium = 2,
        Thick = 3
    },
    Shadow = {
        None = 0,
        Small = 2,
        Medium = 4,
        Large = 8,
        XLarge = 16
    },
    Spacing = {
        Tiny = 4,
        Small = 8,
        Medium = 16,
        Large = 24,
        XLarge = 32,
        XXLarge = 48
    },
    ZIndex = {
        Base = 1,
        Above = 2,
        Dropdown = 100,
        Modal = 1000,
        Toast = 2000,
        Tooltip = 3000
    }
}

-- Utility Functions
function Style.GetTextSize(text: string, size: number, font: Enum.Font, frameSize: Vector2): Vector2
    local textService = game:GetService("TextService")
    return textService:GetTextSize(text, size, font, frameSize)
end

function Style.GetContrastColor(backgroundColor: Color3): Color3
    local luminance = (0.299 * backgroundColor.R) + (0.587 * backgroundColor.G) + (0.114 * backgroundColor.B)
    return luminance > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
end

function Style.LerpColor(color1: Color3, color2: Color3, alpha: number): Color3
    return color1:Lerp(color2, alpha)
end

function Style.GetAlphaColor(color: Color3, alpha: number): Color3
    return Style.LerpColor(color, Color3.new(1, 1, 1), 1 - alpha)
end

function Style.GetDarkenedColor(color: Color3, amount: number): Color3
    return Color3.new(
        math.clamp(color.R - amount, 0, 1),
        math.clamp(color.G - amount, 0, 1),
        math.clamp(color.B - amount, 0, 1)
    )
end

function Style.GetLightenedColor(color: Color3, amount: number): Color3
    return Color3.new(
        math.clamp(color.R + amount, 0, 1),
        math.clamp(color.G + amount, 0, 1),
        math.clamp(color.B + amount, 0, 1)
    )
end

return Style