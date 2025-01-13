---@diagnostic disable: undefined-global

package.path = "./src/?.lua;" .. package.path
local Player = require 'player'
local Team = require 'team'
local UIScaling = require 'ui_scaling'

-- Define conferences at the top level for easy reference
local CONFERENCES = {
    EAST = "Eastern",
    WEST = "Western"
}

-- main.lua
local gameState = {
    currentScreen = "menu",  -- menu, team_select, game, settings
    previousScreen = "menu",
    teams = {},
    playerTeam = nil,
    schedule = {},
    currentWeek = 1,
    totalWeeks = 15,
    settings = {
        resolution = {
            width = 800,
            height = 600,
            options = {
                {width = 800, height = 600},
                {width = 1024, height = 768},
                {width = 1280, height = 720},
                {width = 1920, height = 1080}
            },
            current = 1
        },
        audio = {
            masterVolume = 1.0,
            musicVolume = 0.7
        },
        fullscreen = false
    }
}

local audioState = {
    music = nil,
    settings = {
        masterVolume = 1.0,
        musicVolume = 0.7
    }
}



-- Settings management functions
local function applySettings()
    love.window.setMode(
        gameState.settings.resolution.options[gameState.settings.resolution.current].width,
        gameState.settings.resolution.options[gameState.settings.resolution.current].height,
        {fullscreen = gameState.settings.fullscreen}
    )
    -- Update UI scaling
    UIScaling.init(love.graphics.getWidth(), love.graphics.getHeight())
end

-- Add function to update audio volumes
local function updateVolumes()
    if audioState.music then
        audioState.music:setVolume(gameState.settings.audio.masterVolume * gameState.settings.audio.musicVolume)
    end
end

local function saveSettings()
    local success, message = love.filesystem.write("settings.txt", string.format(
        "%d,%s,%.2f,%.2f",
        gameState.settings.resolution.current,
        tostring(gameState.settings.fullscreen),
        gameState.settings.audio.masterVolume,
        gameState.settings.audio.musicVolume
    ))
    return success
end

local function loadSettings()
    if love.filesystem.getInfo("settings.txt") then
        local content = love.filesystem.read("settings.txt")
        local res, full, master, music = content:match("(%d+),(%a+),([-0-9.]+),([-0-9.]+)")
        if res and full then
            gameState.settings.resolution.current = tonumber(res)
            gameState.settings.fullscreen = full == "true"
            gameState.settings.audio.masterVolume = tonumber(master) or 1.0
            gameState.settings.audio.musicVolume = tonumber(music) or 0.7
            applySettings()
            updateVolumes()
        end
    end
end

-- Add this function to initialize audio
local function initAudio()
    -- Load the music file
    audioState.music = love.audio.newSource("assets/music/mainmenu.mp3", "stream")
    audioState.music:setLooping(true)
    
    -- Set initial volumes
    audioState.music:seek(0, "seconds")
    audioState.music:setVolume(gameState.settings.audio.masterVolume * gameState.settings.audio.musicVolume)
    
    -- Start playing
    audioState.music:play()
end
-- Initialize teams with conference assignments
local function initTeams()
    local teams = {
        -- Eastern Conference teams
        {name = "Warriors", overall = 98, conference = CONFERENCES.EAST},
        {name = "Eagles", overall = 95, conference = CONFERENCES.EAST},
        {name = "Dragons", overall = 85, conference = CONFERENCES.EAST},
        {name = "Phoenix", overall = 82, conference = CONFERENCES.EAST},
        {name = "Lions", overall = 78, conference = CONFERENCES.EAST},
        {name = "Tigers", overall = 75, conference = CONFERENCES.EAST},
        {name = "Bears", overall = 72, conference = CONFERENCES.EAST},
        {name = "Hawks", overall = 70, conference = CONFERENCES.EAST},
        {name = "Wolves", overall = 68, conference = CONFERENCES.EAST},
        {name = "Panthers", overall = 65, conference = CONFERENCES.EAST},
        {name = "Jaguars", overall = 62, conference = CONFERENCES.EAST},
        {name = "Cobras", overall = 58, conference = CONFERENCES.EAST},
        {name = "Vipers", overall = 55, conference = CONFERENCES.EAST},
        {name = "Ravens", overall = 52, conference = CONFERENCES.EAST},
        {name = "TGMs", overall = 55, conference = CONFERENCES.EAST},
        {name = "LDBs", overall = 52, conference = CONFERENCES.EAST},
        -- Western Conference teams
        {name = "Sharks", overall = 98, conference = CONFERENCES.WEST},
        {name = "Aces", overall = 95, conference = CONFERENCES.WEST},
        {name = "Sonics", overall = 92, conference = CONFERENCES.WEST},
        {name = "Giants", overall = 88, conference = CONFERENCES.WEST},
        {name = "Canadiens", overall = 85, conference = CONFERENCES.WEST},
        {name = "Raptors", overall = 82, conference = CONFERENCES.WEST},
        {name = "Wizards", overall = 78, conference = CONFERENCES.WEST},
        {name = "Vultures", overall = 75, conference = CONFERENCES.WEST},
        {name = "Pythons", overall = 72, conference = CONFERENCES.WEST},
        {name = "Terriers", overall = 70, conference = CONFERENCES.WEST},
        {name = "Bucks", overall = 68, conference = CONFERENCES.WEST},
        {name = "Bulls", overall = 65, conference = CONFERENCES.WEST},
        {name = "Pistons", overall = 62, conference = CONFERENCES.WEST},
        {name = "Pacers", overall = 58, conference = CONFERENCES.WEST},
        {name = "Packers", overall = 55, conference = CONFERENCES.WEST},
        {name = "Vikings", overall = 52, conference = CONFERENCES.WEST}
    }
    
    for _, teamData in ipairs(teams) do
        local team = Team:new(teamData.name, teamData.overall, teamData.conference)
        table.insert(gameState.teams, team)
    end
end

local function getTeamsByConference()
    local conferences = {
        [CONFERENCES.EAST] = {},
        [CONFERENCES.WEST] = {}
    }
    
    for _, team in ipairs(gameState.teams) do
        table.insert(conferences[team.conference], team)
    end
    
    return conferences
end

local function generateSchedule()
    gameState.schedule = {}
    
    for week = 1, gameState.totalWeeks do
        local weekGames = {}
        local available = {}
        
        for i = 1, #gameState.teams do
            table.insert(available, i)
        end
        
        while #available > 1 do
            local team1Index = table.remove(available, love.math.random(#available))
            local team2Index = table.remove(available, love.math.random(#available))
            table.insert(weekGames, {team1Index, team2Index})
        end
        
        if #available == 1 then
            local byeTeam = table.remove(available, 1)
        end
        
        gameState.schedule[week] = weekGames
    end
end

local function simulateGame(team1, team2)
    local ratingDiff = team1.overall - team2.overall
    local baseWinProb = 1 / (1 + math.exp(-ratingDiff / 15))
    local winProbability = baseWinProb + (ratingDiff > 0 and 0.1 or 0)
    winProbability = math.min(0.95, math.max(0.05, winProbability))
    
    if love.math.random() < winProbability then
        team1.wins = team1.wins + 1
        team2.losses = team2.losses + 1
        return team1.name
    else
        team2.wins = team2.wins + 1
        team1.losses = team1.losses + 1
        return team2.name
    end
end

local function isMouseOver(x, y, width, height)
    local mouseX, mouseY = love.mouse.getPosition()
    return mouseX >= x and mouseX <= x + width and
           mouseY >= y and mouseY <= y + height
end

function love.load()
    -- Initialize UI scaling
    UIScaling.init(love.graphics.getWidth(), love.graphics.getHeight())
    print("Current directory:", love.filesystem.getWorkingDirectory())
    print("Source base directory:", love.filesystem.getSource())
    -- Try to list files in the assets directory
    local files = love.filesystem.getDirectoryItems("assets")
    print("Files in assets directory:")
    for _, file in ipairs(files) do
        print(file)
    end
    loadSettings()
    math.randomseed(os.time())
    initTeams()
    generateSchedule()
    initAudio()
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Get scale factors once at the start
    local scaleFactorX = UIScaling.getScaleX()
    local scaleFactorY = UIScaling.getScaleY()
    
    -- Convert mouse coordinates to our scaled coordinate system
    local scaledX = x / scaleFactorX
    local scaledY = y / scaleFactorY

    if gameState.currentScreen == "settings" and button == 1 then
        local centerX = love.graphics.getWidth() / 2
        local scaledCenterX = centerX / scaleFactorX
        local yStart = 200  -- Base position, unscaled
        
        -- Resolution options
        for i, res in ipairs(gameState.settings.resolution.options) do
            if isMouseOverScaled(50, yStart + (i-1)*30, 200, 25) then
                gameState.settings.resolution.current = i
                applySettings()
                saveSettings()
                -- Re-init UI scaling after resolution change
                UIScaling.init(love.graphics.getWidth(), love.graphics.getHeight())
                break
            end
        end
        
        -- Volume sliders
        local sliderY = yStart + 150  -- Base position, unscaled
        local sliderWidth = 200  -- Base width, unscaled
        
        -- Master volume slider
        if isMouseOverScaled(50, sliderY, sliderWidth, 25) then
            local relativeX = scaledX - 50  -- Calculate relative to slider start
            local volume = math.max(0, math.min(1, relativeX / sliderWidth))
            gameState.settings.audio.masterVolume = volume
            updateVolumes()
            saveSettings()
            gameState.selectedVolume = "master"
        end
        
        -- Music volume slider
        if isMouseOverScaled(50, sliderY + 50, sliderWidth, 25) then
            local relativeX = scaledX - 50  -- Calculate relative to slider start
            local volume = math.max(0, math.min(1, relativeX / sliderWidth))
            gameState.settings.audio.musicVolume = volume
            updateVolumes()
            saveSettings()
            gameState.selectedVolume = "music"
        end
        
        -- Fullscreen toggle
        if isMouseOverScaled(50, sliderY + 100, 100, 25) then
            gameState.settings.fullscreen = not gameState.settings.fullscreen
            applySettings()
            saveSettings()
        end
        
        -- Back button
        if isMouseOverScaled(scaledCenterX - 50, love.graphics.getHeight() - 60, 100, 25) then
            gameState.currentScreen = gameState.previousScreen
        end
    
    elseif gameState.currentScreen == "team_select" and button == 1 then
        local conferences = getTeamsByConference()
        local leftColumnX = 50
        local rightColumnX = 400
        local yOffset = 90
        local teamHeight = 25
        
        -- Check Eastern Conference teams
        for i, team in ipairs(conferences[CONFERENCES.EAST]) do
            if isMouseOverScaled(leftColumnX, yOffset + (i-1)*teamHeight, 200, 20) then
                gameState.playerTeam = team
                gameState.selectedTeamIndex = i
                gameState.selectedConference = CONFERENCES.EAST
                -- Don't transition immediately, let player confirm with Enter
                break
            end
        end
        
        -- Check Western Conference teams
        for i, team in ipairs(conferences[CONFERENCES.WEST]) do
            if isMouseOverScaled(rightColumnX, yOffset + (i-1)*teamHeight, 200, 20) then
                gameState.playerTeam = team
                gameState.selectedTeamIndex = i
                gameState.selectedConference = CONFERENCES.WEST
                -- Don't transition immediately, let player confirm with Enter
                break
            end
        end
    
    elseif gameState.currentScreen == "game" and button == 1 then
        -- Add any game screen specific click handlers
        local buttonWidth = 150
        local buttonHeight = 30
        
        -- Example: Add a pause button
        if isMouseOverScaled(50, 550, buttonWidth, buttonHeight) then
            -- Handle pause functionality
        end
        
        -- Example: Add a menu button
        if isMouseOverScaled(50, love.graphics.getHeight() - 40, buttonWidth, buttonHeight) then
            gameState.currentScreen = "menu"
            if audioState.music then
                audioState.music:play()
            end
        end
    
    elseif gameState.currentScreen == "roster" and button == 1 then
        -- Add roster screen specific click handlers
        local buttonWidth = 150
        local buttonHeight = 30
        
        -- Back to game button
        if isMouseOverScaled(50, love.graphics.getHeight() - 40, buttonWidth, buttonHeight) then
            gameState.currentScreen = "game"
        end
    end

    -- Handle volume slider dragging
    if button == 1 then
        gameState.isDraggingSlider = false
        if gameState.currentScreen == "settings" then
            local centerX = love.graphics.getWidth() / 2
            local scaleFactorX = UIScaling.getScaleX()
            local scaledCenterX = centerX / scaleFactorX
            local sliderY = 350
            local sliderWidth = 200
            
            -- Check both volume sliders
            if isMouseOverScaled(scaledCenterX - 100, sliderY, sliderWidth, 25) or
               isMouseOverScaled(scaledCenterX - 100, sliderY + 50, sliderWidth, 25) then
                gameState.isDraggingSlider = true
            end
        end
    end
end

function isMouseOverScaled(x, y, width, height)
    local mouseX, mouseY = love.mouse.getPosition()
    local scaleFactorX = UIScaling.getScaleX()
    local scaleFactorY = UIScaling.getScaleY()
    local scaledMouseX = mouseX / scaleFactorX
    local scaledMouseY = mouseY / scaleFactorY
    
    return scaledMouseX >= x and scaledMouseX <= x + width and
           scaledMouseY >= y and scaledMouseY <= y + height
end

-- Add mouse drag handling for sliders
function love.mousemoved(x, y, dx, dy)
    if gameState.isDraggingSlider and gameState.currentScreen == "settings" then
        local scaleFactorX = UIScaling.getScaleX()
        local scaledX = x / scaleFactorX
        local baseX = 50  -- Base X position for sliders
        local sliderWidth = 200  -- Base slider width before scaling
        
        -- Calculate volume based on mouse position
        local volume = math.max(0, math.min(1, (scaledX - baseX) / sliderWidth))
        
        -- Update the appropriate volume based on which slider was selected
        if gameState.selectedVolume == "master" then
            gameState.settings.audio.masterVolume = volume
        elseif gameState.selectedVolume == "music" then
            gameState.settings.audio.musicVolume = volume
        end
        
        updateVolumes()
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and gameState.isDraggingSlider then
        gameState.isDraggingSlider = false
        saveSettings()  -- Save settings when done dragging
    end
end

function love.keypressed(key)
    -- Global settings access
    if (key == "s" or key == "S") and gameState.currentScreen ~= "settings" then
        gameState.previousScreen = gameState.currentScreen
        gameState.currentScreen = "settings"
        return  -- Exit early to prevent other key handling
    end

    if gameState.currentScreen == "menu" then
        if key == "return" then
            gameState.currentScreen = "team_select"
        elseif key == "escape" then
            love.event.quit()
        end
    elseif gameState.currentScreen == "settings" then
        if key == "escape" then
            gameState.currentScreen = gameState.previousScreen
        end
    elseif gameState.currentScreen == "team_select" then
        -- Stop music only when entering game, not when going to settings
        if key == "return" then
            gameState.currentScreen = "game"
            if audioState.music then
                audioState.music:stop()
            end
        end
    elseif gameState.currentScreen == "game" and key == "space" then
        if gameState.currentWeek <= gameState.totalWeeks then
            local weekGames = gameState.schedule[gameState.currentWeek]
            if weekGames then
                for _, game in ipairs(weekGames) do
                    if game and game[1] and game[2] then
                        local team1 = gameState.teams[game[1]]
                        local team2 = gameState.teams[game[2]]
                        if team1 and team2 then
                            simulateGame(team1, team2)
                        end
                    end
                end
                gameState.currentWeek = gameState.currentWeek + 1
            end
        end
    end
end

function love.draw()
    -- Set up commonly used fonts
    local headerFont = UIScaling.getFont(20)
    local normalFont = UIScaling.getFont(16)
    local smallFont = UIScaling.getFont(14)

    if gameState.currentScreen == "menu" then
        love.graphics.setFont(headerFont)
        local menuItems = {
            {text = "Basketball Manager", yPos = 250},
            {text = "Press ENTER to start", yPos = 300},
            {text = "Press S for settings", yPos = 330},
            {text = "Press ESC to quit", yPos = 360}
        }
    
        -- Calculate center X position once
        local centerX = love.graphics.getWidth() / 2
    
        for _, item in ipairs(menuItems) do
            -- Calculate text width for centering
            local textWidth = headerFont:getWidth(item.text)
            -- Position text in center of screen
            local x = centerX - (textWidth / 2)
            -- Draw text with scaled Y position
            love.graphics.print(item.text, x, UIScaling.scaleY(item.yPos))
        end

    elseif gameState.currentScreen == "settings" then
        local centerX = love.graphics.getWidth() / 2
        local yStart = UIScaling.scaleY(200)
        
        -- Settings header
        love.graphics.setFont(headerFont)
        local headerText = "Settings"
        local textWidth = headerFont:getWidth(headerText)
        local headerX = centerX - (textWidth / 2)
        love.graphics.print(headerText, headerX, UIScaling.scaleY(150))
        
        -- Resolution options
        love.graphics.setFont(normalFont)
        love.graphics.print("Resolution:", UIScaling.scaleX(50), UIScaling.scaleY(170))
        
        for i, res in ipairs(gameState.settings.resolution.options) do
            local text = string.format("%dx%d", res.width, res.height)
            if i == gameState.settings.resolution.current then
                love.graphics.setColor(0, 1, 0)
            end
            love.graphics.print(text, UIScaling.scaleX(50), yStart + (i-1) * UIScaling.scaleY(30))
            love.graphics.setColor(1, 1, 1)
        end
        
        -- Volume controls
        local sliderY = yStart + UIScaling.scaleY(150)
        local sliderWidth = UIScaling.scaleX(200)
        
        -- Master volume
        love.graphics.print("Master Volume:", UIScaling.scaleX(50), sliderY - UIScaling.scaleY(20))
        love.graphics.rectangle("line", UIScaling.scaleX(50), sliderY, sliderWidth, UIScaling.scaleY(20))
        love.graphics.rectangle("fill", UIScaling.scaleX(50), sliderY, 
            sliderWidth * gameState.settings.audio.masterVolume, UIScaling.scaleY(20))
        
        -- Music volume
        love.graphics.print("Music Volume:", UIScaling.scaleX(50), sliderY + UIScaling.scaleY(30))
        love.graphics.rectangle("line", UIScaling.scaleX(50), sliderY + UIScaling.scaleY(50), sliderWidth, UIScaling.scaleY(20))
        love.graphics.rectangle("fill", UIScaling.scaleX(50), sliderY + UIScaling.scaleY(50), 
            sliderWidth * gameState.settings.audio.musicVolume, UIScaling.scaleY(20))
        
        -- Fullscreen toggle
        love.graphics.print("Fullscreen:", UIScaling.scaleX(50), sliderY + UIScaling.scaleY(80))
        love.graphics.setColor(gameState.settings.fullscreen and {0, 1, 0} or {1, 1, 1})
        love.graphics.print(tostring(gameState.settings.fullscreen), UIScaling.scaleX(150), sliderY + UIScaling.scaleY(80))
        love.graphics.setColor(1, 1, 1)
        
        -- Back button
        local backText = string.format("Press ESC to return to %s", gameState.previousScreen:gsub("^%l", string.upper))
        local backWidth = normalFont:getWidth(backText)
        local backX = centerX - (backWidth / 2)
        love.graphics.print(backText, backX, UIScaling.scaleY(love.graphics.getHeight() - 50))

    elseif gameState.currentScreen == "team_select" then
        love.graphics.setFont(headerFont)
        love.graphics.print("Select your team:", UIScaling.scaleX(50), UIScaling.scaleY(30))
        
        local conferences = getTeamsByConference()
        local leftColumnX = UIScaling.scaleX(50)
        local rightColumnX = UIScaling.scaleX(400)
        
        -- Conference headers
        love.graphics.setFont(normalFont)
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Eastern Conference", leftColumnX, UIScaling.scaleY(70))
        love.graphics.print("Western Conference", rightColumnX, UIScaling.scaleY(70))
        love.graphics.setColor(1, 1, 1)
        
        -- Eastern Conference teams
        local yOffset = UIScaling.scaleY(90)
        local lineHeight = UIScaling.scaleY(25)
        for _, team in ipairs(conferences[CONFERENCES.EAST]) do
            if isMouseOver(leftColumnX, yOffset, UIScaling.scaleX(200), UIScaling.scaleY(20)) then
                love.graphics.setColor(0, 1, 0)
            end
            love.graphics.print(string.format("%s (Overall: %d)", team.name, team.overall), 
                leftColumnX, yOffset)
            love.graphics.setColor(1, 1, 1)
            yOffset = yOffset + lineHeight
        end
        
        -- Western Conference teams
        yOffset = UIScaling.scaleY(90)
        for _, team in ipairs(conferences[CONFERENCES.WEST]) do
            if isMouseOver(rightColumnX, yOffset, UIScaling.scaleX(200), UIScaling.scaleY(20)) then
                love.graphics.setColor(0, 1, 0)
            end
            love.graphics.print(string.format("%s (Overall: %d)", team.name, team.overall), 
                rightColumnX, yOffset)
            love.graphics.setColor(1, 1, 1)
            yOffset = yOffset + lineHeight
        end
        
        -- Settings reminder
        love.graphics.setFont(smallFont)
        love.graphics.print("Press S for settings", UIScaling.scaleX(50), 
            UIScaling.scaleY(love.graphics.getHeight() - 30))

    elseif gameState.currentScreen == "game" then
        love.graphics.setFont(normalFont)
        -- Week display
        love.graphics.print("Week " .. gameState.currentWeek .. "/" .. gameState.totalWeeks, 
            UIScaling.scaleX(50), UIScaling.scaleY(30))
        
        -- Your team info
        if gameState.playerTeam then
            love.graphics.print(string.format("Your team: %s (%s Conference)", 
                gameState.playerTeam.name, gameState.playerTeam.conference), 
                UIScaling.scaleX(50), UIScaling.scaleY(50))
        end
        
        local leftColumnX = UIScaling.scaleX(50)
        local rightColumnX = UIScaling.scaleX(400)
        
        -- Conference standings headers
        love.graphics.setFont(headerFont)
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Eastern Conference Standings:", leftColumnX, UIScaling.scaleY(90))
        love.graphics.print("Western Conference Standings:", rightColumnX, UIScaling.scaleY(90))
        love.graphics.setColor(1, 1, 1)
        
        -- Display standings
        love.graphics.setFont(normalFont)
        local conferences = getTeamsByConference()
        local yOffset = UIScaling.scaleY(110)
        local lineHeight = UIScaling.scaleY(20)
        
        -- Sort teams by wins
        local function sortTeams(teams)
            table.sort(teams, function(a, b)
                if a.wins == b.wins then return a.losses < b.losses end
                return a.wins > b.wins
            end)
            return teams
        end
        
        -- Eastern Conference standings
        for _, team in ipairs(sortTeams(conferences[CONFERENCES.EAST])) do
            love.graphics.print(string.format("%s: %d-%d", team.name, team.wins, team.losses), 
                leftColumnX, yOffset)
            yOffset = yOffset + lineHeight
        end
        
        -- Western Conference standings
        yOffset = UIScaling.scaleY(110)
        for _, team in ipairs(sortTeams(conferences[CONFERENCES.WEST])) do
            love.graphics.print(string.format("%s: %d-%d", team.name, team.wins, team.losses),
                rightColumnX, yOffset)
            yOffset = yOffset + lineHeight
        end
        
        -- Game controls
        love.graphics.setFont(smallFont)
        if gameState.currentWeek < gameState.totalWeeks then
            love.graphics.print("Press SPACE to simulate next week", 
                UIScaling.scaleX(50), UIScaling.scaleY(550))
        else
            love.graphics.print("Season Complete!", 
                UIScaling.scaleX(50), UIScaling.scaleY(550))
        end
        
        -- Navigation instructions
        love.graphics.print("Press R to view roster", 
            UIScaling.scaleX(50), UIScaling.scaleY(love.graphics.getHeight() - 60))
        love.graphics.print("Press S for settings", 
            UIScaling.scaleX(50), UIScaling.scaleY(love.graphics.getHeight() - 30))

    elseif gameState.currentScreen == "roster" then
        love.graphics.setFont(headerFont)
        love.graphics.print("Team Roster", UIScaling.scaleX(50), UIScaling.scaleY(30))
        
        if gameState.playerTeam then
            love.graphics.setFont(normalFont)
            -- Team info
            love.graphics.print(string.format("%s (%s Conference)", 
                gameState.playerTeam.name, gameState.playerTeam.conference), 
                UIScaling.scaleX(50), UIScaling.scaleY(60))
            
            -- Salary info if available
            if type(gameState.playerTeam.calculateTotalSalary) == "function" then
                local totalSalary = gameState.playerTeam:calculateTotalSalary()
                if totalSalary then
                    love.graphics.print(string.format("Total Salary: $%.1fM", totalSalary / 1000000), 
                        UIScaling.scaleX(50), UIScaling.scaleY(80))
                end
            end
            
            -- Roster display
            if type(gameState.playerTeam.getRoster) == "function" then
                local roster = gameState.playerTeam:getRoster()
                local yOffset = UIScaling.scaleY(120)
                local columnSpacing = UIScaling.scaleX(150)
                
                -- Headers
                local headers = {"Name", "Position", "Rating", "Salary"}
                for i, header in ipairs(headers) do
                    love.graphics.print(header, UIScaling.scaleX(50 + (i-1) * 100), yOffset)
                end
                
                -- Player listings
                yOffset = yOffset + UIScaling.scaleY(25)
                for _, player in ipairs(roster) do
                    love.graphics.print(player.name or "", UIScaling.scaleX(50), yOffset)
                    love.graphics.print(player.position or "", UIScaling.scaleX(150), yOffset)
                    love.graphics.print(tostring(player.rating or ""), UIScaling.scaleX(250), yOffset)
                    if player.salary then
                        love.graphics.print(string.format("$%.1fM", player.salary / 1000000), 
                            UIScaling.scaleX(350), yOffset)
                    end
                    yOffset = yOffset + UIScaling.scaleY(20)
                end
            end
        end
        
        -- Navigation instructions
        love.graphics.setFont(smallFont)
        love.graphics.print("Press ESC to return to game", 
            UIScaling.scaleX(50), UIScaling.scaleY(love.graphics.getHeight() - 60))
        love.graphics.print("Press S for settings", 
            UIScaling.scaleX(50), UIScaling.scaleY(love.graphics.getHeight() - 30))
    end
end


function love.keypressed(key)
    -- Update the isMouseOver function to use scaled coordinates
    local function isMouseOverScaled(x, y, width, height)
        local mouseX, mouseY = love.mouse.getPosition()
        -- Convert mouse coordinates to our scaled coordinate system
        local scaleFactorX = UIScaling.getScaleX()
        local scaleFactorY = UIScaling.getScaleY()
        local scaledMouseX = mouseX / scaleFactorX
        local scaledMouseY = mouseY / scaleFactorY


        return scaledMouseX >= x and scaledMouseX <= x + width and
               scaledMouseY >= y and scaledMouseY <= y + height
    end

    -- Global settings access
    if (key == "s" or key == "S") and gameState.currentScreen ~= "settings" then
        gameState.previousScreen = gameState.currentScreen
        gameState.currentScreen = "settings"
        return
    end
    
    -- Handle screen-specific key presses
    if gameState.currentScreen == "menu" then
        if key == "return" then
            gameState.currentScreen = "team_select"
        elseif key == "escape" then
            love.event.quit()
        end

    elseif gameState.currentScreen == "settings" then
        if key == "escape" then
            gameState.currentScreen = gameState.previousScreen
            -- Apply and save settings when leaving
            applySettings()
            saveSettings()
        elseif key == "f" or key == "F" then
            -- Toggle fullscreen
            gameState.settings.fullscreen = not gameState.settings.fullscreen
            applySettings()
            saveSettings()
        elseif key == "left" or key == "right" then
            -- Adjust volume
            local mouseX, mouseY = love.mouse.getPosition()
            local centerX = love.graphics.getWidth() / 2
            local sliderY = UIScaling.scaleY(350)  -- Adjust based on your layout
            local sliderWidth = UIScaling.scaleX(200)
            
            -- Check if mouse is over master volume slider
            if isMouseOverScaled(centerX - 100, sliderY, 200, 25) then
                local delta = key == "left" and -0.1 or 0.1
                gameState.settings.audio.masterVolume = math.max(0, math.min(1, 
                    gameState.settings.audio.masterVolume + delta))
                updateVolumes()
                saveSettings()
            end
            
            -- Check if mouse is over music volume slider
            if isMouseOverScaled(centerX - 100, sliderY + 50, 200, 25) then
                local delta = key == "left" and -0.1 or 0.1
                gameState.settings.audio.musicVolume = math.max(0, math.min(1, 
                    gameState.settings.audio.musicVolume + delta))
                updateVolumes()
                saveSettings()
            end
        end

    elseif gameState.currentScreen == "team_select" then
        if key == "return" and gameState.playerTeam then
            gameState.currentScreen = "game"
            -- Stop menu music when entering game
            if audioState.music then
                audioState.music:stop()
            end
        elseif key == "escape" then
            gameState.currentScreen = "menu"
        elseif key == "up" or key == "down" then
            -- Handle team selection with keyboard
            local conferences = getTeamsByConference()
            local currentConference = gameState.selectedConference or CONFERENCES.EAST
            local teams = conferences[currentConference]
            
            if not gameState.selectedTeamIndex then
                gameState.selectedTeamIndex = 1
            else
                if key == "up" then
                    gameState.selectedTeamIndex = ((gameState.selectedTeamIndex - 2) % #teams) + 1
                else
                    gameState.selectedTeamIndex = (gameState.selectedTeamIndex % #teams) + 1
                end
            end
            
            gameState.playerTeam = teams[gameState.selectedTeamIndex]
        elseif key == "left" or key == "right" then
            -- Switch between conferences
            gameState.selectedConference = gameState.selectedConference == CONFERENCES.EAST 
                and CONFERENCES.WEST or CONFERENCES.EAST
            gameState.selectedTeamIndex = 1
            local conferences = getTeamsByConference()
            gameState.playerTeam = conferences[gameState.selectedConference][1]
        end

    elseif gameState.currentScreen == "roster" then
        if key == "escape" then
            gameState.currentScreen = "game"
        end

    elseif gameState.currentScreen == "game" then
        if key == "space" then
            if gameState.currentWeek <= gameState.totalWeeks then
                local weekGames = gameState.schedule[gameState.currentWeek]
                if weekGames then
                    -- Simulate all games for the current week
                    for _, game in ipairs(weekGames) do
                        if game and game[1] and game[2] then
                            local team1 = gameState.teams[game[1]]
                            local team2 = gameState.teams[game[2]]
                            if team1 and team2 then
                                simulateGame(team1, team2)
                            end
                        end
                    end
                    gameState.currentWeek = gameState.currentWeek + 1
                end
            end
        elseif key == "r" then
            gameState.currentScreen = "roster"
        elseif key == "escape" then
            -- Add confirmation dialog here if needed
            gameState.currentScreen = "menu"
            -- Restart menu music
            if audioState.music then
                audioState.music:play()
            end
        end
    end
end

-- Add a new function to handle continuous keyboard input
function love.update(dt)
    -- Handle held keys for volume adjustment
    if gameState.currentScreen == "settings" then
        if love.keyboard.isDown('left') or love.keyboard.isDown('right') then
            local delta = love.keyboard.isDown('left') and -0.5 or 0.5
            delta = delta * dt  -- Scale by delta time for smooth adjustment
            
            -- Update volume based on which slider is selected
            if gameState.selectedVolume == "master" then
                gameState.settings.audio.masterVolume = math.max(0, math.min(1, 
                    gameState.settings.audio.masterVolume + delta))
            elseif gameState.selectedVolume == "music" then
                gameState.settings.audio.musicVolume = math.max(0, math.min(1, 
                    gameState.settings.audio.musicVolume + delta))
            end
            
            updateVolumes()
            -- Don't save settings every frame, maybe add a timer
            if not gameState.volumeUpdateTimer then
                gameState.volumeUpdateTimer = 0
            end
            gameState.volumeUpdateTimer = gameState.volumeUpdateTimer + dt
            if gameState.volumeUpdateTimer >= 0.5 then  -- Save every half second
                saveSettings()
                gameState.volumeUpdateTimer = 0
            end
        end
    end
end