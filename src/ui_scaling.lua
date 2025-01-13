-- ui_scaling.lua
local UIScaling = {
    baseWidth = 800,  -- Base resolution width for scaling calculations
    baseHeight = 600, -- Base resolution height for scaling calculations
    scaleFactorX = 1,
    scaleFactorY = 1
}

-- Initialize scaling
function UIScaling.init(currentWidth, currentHeight)
    UIScaling.scaleFactorX = currentWidth / UIScaling.baseWidth
    UIScaling.scaleFactorY = currentHeight / UIScaling.baseHeight
end

-- Get scale factors
function UIScaling.getScaleX()
    return UIScaling.scaleFactorX
end

function UIScaling.getScaleY()
    return UIScaling.scaleFactorY
end

-- Scale a position on X axis
function UIScaling.scaleX(value)
    return math.floor(value * UIScaling.scaleFactorX)
end

-- Scale a position on Y axis
function UIScaling.scaleY(value)
    return math.floor(value * UIScaling.scaleFactorY)
end

-- Scale both X and Y positions
function UIScaling.scalePos(x, y)
    return UIScaling.scaleX(x), UIScaling.scaleY(y)
end

-- Scale a font size
function UIScaling.scaleFontSize(size)
    return math.floor(size * math.min(UIScaling.scaleFactorX, UIScaling.scaleFactorY))
end

-- Get scaled font
function UIScaling.getFont(size)
    local scaledSize = UIScaling.scaleFontSize(size)
    return love.graphics.newFont(scaledSize)
end

-- Scale a rectangle (returns x, y, width, height)
function UIScaling.scaleRect(x, y, width, height)
    return UIScaling.scaleX(x), UIScaling.scaleY(y), 
           UIScaling.scaleX(width), UIScaling.scaleY(height)
end

-- Calculate centered position for text
function UIScaling.getCenteredTextPos(text, font, x, width)
    local textWidth = font:getWidth(text)
    local scaledWidth = UIScaling.scaleX(width)
    local scaledX = UIScaling.scaleX(x)
    return scaledX + (scaledWidth - textWidth) / 2
end

-- Initialize with default values
UIScaling.init(800, 600)

return UIScaling