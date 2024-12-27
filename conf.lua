-- conf.lua
function love.conf(t)
    t.window.title = "Basketball Simulation Game"
    t.window.width = 800
    t.window.height = 600
    t.version = "11.4"
    
    -- Module configurations
    t.modules.audio = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.system = true
    t.modules.window = true
    
    -- Unused modules
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.touch = false
    t.modules.video = false
end