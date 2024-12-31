---@diagnostic disable: undefined-global

package.path = "./src/?.lua;" .. package.path
local Player = require 'player'
local Team = require 'team'

-- Define conferences at the top level for easy reference
local CONFERENCES = {
    EAST = "Eastern",
    WEST = "Western"
}

-- main.lua
local gameState = {
    currentScreen = "menu",  -- menu, team_select, game, settings
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
        fullscreen = false
    }
}

-- Settings management functions
local function applySettings()
    love.window.setMode(
        gameState.settings.resolution.options[gameState.settings.resolution.current].width,
        gameState.settings.resolution.options[gameState.settings.resolution.current].height,
        {fullscreen = gameState.settings.fullscreen}
    )
end

local function saveSettings()
    local success, message = love.filesystem.write("settings.txt", string.format(
        "%d,%s",
        gameState.settings.resolution.current,
        tostring(gameState.settings.fullscreen)
    ))
    return success
end

local function loadSettings()
    if love.filesystem.getInfo("settings.txt") then
        local content = love.filesystem.read("settings.txt")
        local res, full = content:match("(%d+),(%a+)")
        if res and full then
            gameState.settings.resolution.current = tonumber(res)
            gameState.settings.fullscreen = full == "true"
            applySettings()
        end
    end
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
    loadSettings()
    math.randomseed(os.time())
    initTeams()
    generateSchedule()
end

function love.mousepressed(x, y, button, istouch, presses)
    if gameState.currentScreen == "settings" and button == 1 then
        local centerX = love.graphics.getWidth() / 2
        local yStart = 200
        
        -- Resolution options
        for i, res in ipairs(gameState.settings.resolution.options) do
            if isMouseOver(centerX - 100, yStart + (i-1)*30, 200, 25) then
                gameState.settings.resolution.current = i
                applySettings()
                saveSettings()
            end
        end
        
        -- Fullscreen toggle
        if isMouseOver(centerX - 100, yStart + 150, 200, 25) then
            gameState.settings.fullscreen = not gameState.settings.fullscreen
            applySettings()
            saveSettings()
        end
        
        -- Back button
        if isMouseOver(centerX - 50, yStart + 200, 100, 25) then
            gameState.currentScreen = "menu"
        end
    
    elseif gameState.currentScreen == "team_select" and button == 1 then
        local conferences = getTeamsByConference()
        local leftColumnX = 50
        local rightColumnX = 400
        local yOffset = 90
        
        -- Check Eastern Conference teams
        for _, team in ipairs(conferences[CONFERENCES.EAST]) do
            if isMouseOver(leftColumnX, yOffset, 200, 20) then
                gameState.playerTeam = team
                gameState.currentScreen = "game"
                break
            end
            yOffset = yOffset + 25
        end
        
        -- Check Western Conference teams
        yOffset = 90
        for _, team in ipairs(conferences[CONFERENCES.WEST]) do
            if isMouseOver(rightColumnX, yOffset, 200, 20) then
                gameState.playerTeam = team
                gameState.currentScreen = "game"
                break
            end
            yOffset = yOffset + 25
        end
    end
end

function love.keypressed(key)
    if gameState.currentScreen == "menu" then
        if key == "return" then
            gameState.currentScreen = "team_select"
        elseif key == "s" then
            gameState.currentScreen = "settings"
        elseif key == "escape" then
            love.event.quit()
        end
    
    elseif gameState.currentScreen == "settings" and key == "escape" then
        gameState.currentScreen = "menu"
    
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
    if gameState.currentScreen == "menu" then
        local centerX = love.graphics.getWidth() / 2
        love.graphics.print("Basketball Manager", centerX - 50, 250)
        love.graphics.print("Press ENTER to start", centerX - 50, 300)
        love.graphics.print("Press S for settings", centerX - 50, 330)
        love.graphics.print("Press ESC to quit", centerX - 50, 360)
        
    elseif gameState.currentScreen == "settings" then
        local centerX = love.graphics.getWidth() / 2
        love.graphics.print("Settings", centerX - 30, 150)
        
        -- Resolution options
        local yStart = 200
        love.graphics.print("Resolution:", centerX - 100, yStart - 30)
        for i, res in ipairs(gameState.settings.resolution.options) do
            local text = string.format("%dx%d", res.width, res.height)
            if i == gameState.settings.resolution.current then
                love.graphics.setColor(0, 1, 0)
            end
            love.graphics.print(text, centerX - 100, yStart + (i-1)*30)
            love.graphics.setColor(1, 1, 1)
        end
        
        -- Fullscreen toggle
        love.graphics.print("Fullscreen:", centerX - 100, yStart + 120)
        love.graphics.setColor(gameState.settings.fullscreen and {0, 1, 0} or {1, 1, 1})
        love.graphics.print(tostring(gameState.settings.fullscreen), centerX - 100, yStart + 150)
        love.graphics.setColor(1, 1, 1)
        
        -- Back button
        love.graphics.print("Back to Menu (ESC)", centerX - 50, yStart + 200)
        
    elseif gameState.currentScreen == "team_select" then
        love.graphics.print("Select your team:", 50, 30)
        
        local conferences = getTeamsByConference()
        local leftColumnX = 50
        local rightColumnX = 400
        
        -- Eastern Conference (left column)
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Eastern Conference", leftColumnX, 70)
        love.graphics.setColor(1, 1, 1)
        
        local yOffset = 90
        for _, team in ipairs(conferences[CONFERENCES.EAST]) do
            if isMouseOver(leftColumnX, yOffset, 200, 20) then
                love.graphics.setColor(0, 1, 0)
            end
            love.graphics.print(string.format("%s (Overall: %d)", team.name, team.overall), leftColumnX, yOffset)
            love.graphics.setColor(1, 1, 1)
            yOffset = yOffset + 25
        end
        
        -- Western Conference (right column)
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Western Conference", rightColumnX, 70)
        love.graphics.setColor(1, 1, 1)
        
        yOffset = 90
        for _, team in ipairs(conferences[CONFERENCES.WEST]) do
            if isMouseOver(rightColumnX, yOffset, 200, 20) then
                love.graphics.setColor(0, 1, 0)
            end
            love.graphics.print(string.format("%s (Overall: %d)", team.name, team.overall), rightColumnX, yOffset)
            love.graphics.setColor(1, 1, 1)
            yOffset = yOffset + 25
        end
    
    elseif gameState.currentScreen == "game" then
        -- Week display
        love.graphics.print("Week " .. gameState.currentWeek .. "/" .. gameState.totalWeeks, 50, 30)
        
        -- Your team info
        if gameState.playerTeam then
            love.graphics.print(string.format("Your team: %s (%s Conference)", 
                gameState.playerTeam.name, gameState.playerTeam.conference), 50, 50)
        end
        
        -- Two-column layout for standings
        local leftColumnX = 50
        local rightColumnX = 400
        
        -- Eastern Conference (left column)
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Eastern Conference Standings:", leftColumnX, 90)
        love.graphics.setColor(1, 1, 1)
        
        local conferences = getTeamsByConference()
        local yOffset = 110
        
        local eastTeams = conferences[CONFERENCES.EAST]
        table.sort(eastTeams, function(a, b)
            if a.wins == b.wins then return a.losses < b.losses end
            return a.wins > b.wins
        end)
        
        for _, team in ipairs(eastTeams) do
            love.graphics.print(string.format("%s: %d-%d", team.name, team.wins, team.losses), 
                leftColumnX, yOffset)
            yOffset = yOffset + 20
        end
        
        -- Western Conference (right column)
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Western Conference Standings:", rightColumnX, 90)
        love.graphics.setColor(1, 1, 1)
        
        yOffset = 110
        local westTeams = conferences[CONFERENCES.WEST]
        table.sort(westTeams, function(a, b)
            if a.wins == b.wins then return a.losses < b.losses end
            return a.wins > b.wins
        end)
        
        for _, team in ipairs(westTeams) do
            love.graphics.print(string.format("%s: %d-%d", team.name, team.wins, team.losses),
                rightColumnX, yOffset)
            yOffset = yOffset + 20
        end
        
        -- Roster display in right column
        if gameState.playerTeam and type(gameState.playerTeam.displayRoster) == "function" then
            love.graphics.print("Team Roster:", rightColumnX + 250, 90)
            love.graphics.print(gameState.playerTeam:displayRoster(), rightColumnX + 250, 110)
        end
        
        -- Simulation prompt
        if gameState.currentWeek < gameState.totalWeeks then
            love.graphics.print("Press SPACE to simulate next week", 50, 550)
        else
            love.graphics.print("Season Complete!", 50, 550)
        end
    end
end


function love.keypressed(key)
    if gameState.currentScreen == "menu" then
        if key == "return" then
            gameState.currentScreen = "team_select"
        elseif key == "s" or key == "S" then  -- Add support for both upper and lowercase
            gameState.currentScreen = "settings"
            print("Entering settings screen") -- Debug print
        elseif key == "escape" then
            love.event.quit()
        end
    elseif gameState.currentScreen == "settings" then
        if key == "escape" then
            gameState.currentScreen = "menu"
            print("Returning to menu") -- Debug print
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