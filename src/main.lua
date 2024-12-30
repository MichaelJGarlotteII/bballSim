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
    currentScreen = "menu",  -- menu, team_select, game
    teams = {},
    playerTeam = nil,
    schedule = {},
    currentWeek = 1,
    totalWeeks = 15
}

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
        -- Create team instance with conference data
        local team = Team:new(teamData.name, teamData.overall, teamData.conference)
        table.insert(gameState.teams, team)
    end
end

-- Helper function to group teams by conference
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

-- Generate season schedule (unchanged)
local function generateSchedule()
    gameState.schedule = {}
    print("Generating schedule...") -- Debug print
    
    -- Create a simple round-robin schedule
    for week = 1, gameState.totalWeeks do
        local weekGames = {}
        local available = {}
        
        -- Create list of available teams
        for i = 1, #gameState.teams do
            table.insert(available, i)
        end
        
        -- Match teams randomly
        while #available > 1 do
            local team1Index = table.remove(available, love.math.random(#available))
            local team2Index = table.remove(available, love.math.random(#available))
            
            table.insert(weekGames, {team1Index, team2Index})
        end
        
        -- Handle odd number of teams if necessary
        if #available == 1 then
            local byeTeam = table.remove(available, 1)
            print("Team " .. byeTeam .. " has a bye week")
        end
        
        gameState.schedule[week] = weekGames
        print(string.format("Week %d schedule generated with %d games", 
            week, #weekGames))
    end
end

-- Simulate a game between two teams (unchanged)
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

-- LÖVE callback functions
function love.load()
    love.window.setMode(800, 600)
    math.randomseed(os.time())
    
    print("Initializing game...")
    initTeams()
    print("Teams initialized:", #gameState.teams)
    
    generateSchedule()
    print("Schedule generated for " .. gameState.totalWeeks .. " weeks")
end

-- Helper function to check if mouse is over text (unchanged)
local function isMouseOver(x, y, width, height)
    local mouseX, mouseY = love.mouse.getPosition()
    return mouseX >= x and mouseX <= x + width and
           mouseY >= y and mouseY <= y + height
end

function love.mousepressed(x, y, button, istouch, presses)
    if gameState.currentScreen == "team_select" and button == 1 then
        -- Get teams grouped by conference
        local conferences = getTeamsByConference()
        local currentY = 70
        
        -- Check Eastern Conference teams
        for _, team in ipairs(conferences[CONFERENCES.EAST]) do
            if isMouseOver(350, currentY, 200, 20) then
                gameState.playerTeam = team
                gameState.currentScreen = "game"
                break
            end
            currentY = currentY + 20
        end
        
        -- Add spacing between conferences
        currentY = currentY + 20
        
        -- Check Western Conference teams
        for _, team in ipairs(conferences[CONFERENCES.WEST]) do
            if isMouseOver(350, currentY, 200, 20) then
                gameState.playerTeam = team
                gameState.currentScreen = "game"
                break
            end
            currentY = currentY + 20
        end
    end
end

function love.draw()
    if gameState.currentScreen == "menu" then
        love.graphics.print("Basketball Manager", 350, 250)
        love.graphics.print("Press ENTER to start", 350, 300)
    
    elseif gameState.currentScreen == "team_select" then
        love.graphics.print("Select your team:", 350, 30)
        
        -- Group teams by conference for display
        local conferences = getTeamsByConference()
        local yOffset = 70
        
        -- Draw Eastern Conference teams
        love.graphics.setColor(0.8, 0.8, 1) -- Light blue for conference header
        love.graphics.print("Eastern Conference", 350, yOffset - 20)
        love.graphics.setColor(1, 1, 1)
        
        for _, team in ipairs(conferences[CONFERENCES.EAST]) do
            if isMouseOver(350, yOffset, 200, 20) then
                love.graphics.setColor(0, 1, 0)
            end
            love.graphics.print(string.format("%s (Overall: %d)", team.name, team.overall), 350, yOffset)
            love.graphics.setColor(1, 1, 1)
            yOffset = yOffset + 20
        end
        
        -- Add spacing between conferences
        yOffset = yOffset + 20
        
        -- Draw Western Conference teams
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Western Conference", 350, yOffset - 20)
        love.graphics.setColor(1, 1, 1)
        
        for _, team in ipairs(conferences[CONFERENCES.WEST]) do
            if isMouseOver(350, yOffset, 200, 20) then
                love.graphics.setColor(0, 1, 0)
            end
            love.graphics.print(string.format("%s (Overall: %d)", team.name, team.overall), 350, yOffset)
            love.graphics.setColor(1, 1, 1)
            yOffset = yOffset + 20
        end
    
    elseif gameState.currentScreen == "game" then
        -- Display current week
        love.graphics.print("Week " .. gameState.currentWeek .. "/" .. gameState.totalWeeks, 50, 30)
        
        if gameState.playerTeam then
            love.graphics.print(string.format("Your team: %s (%s Conference)", 
                gameState.playerTeam.name, gameState.playerTeam.conference), 50, 50)
            
            if type(gameState.playerTeam.displayRoster) == "function" then
                love.graphics.print(gameState.playerTeam:displayRoster(), 400, 150)
            else
                love.graphics.print("Error: displayRoster not available", 400, 150)
            end
        end
        
        -- Display standings by conference
        local conferences = getTeamsByConference()
        local xOffset = 50
        
        -- Eastern Conference standings
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Eastern Conference Standings:", xOffset, 90)
        love.graphics.setColor(1, 1, 1)
        
        local yOffset = 110
        local eastTeams = conferences[CONFERENCES.EAST]
        table.sort(eastTeams, function(a, b)
            if a.wins == b.wins then
                return a.losses < b.losses
            end
            return a.wins > b.wins
        end)
        
        for _, team in ipairs(eastTeams) do
            love.graphics.print(string.format("%s: %d-%d (Overall: %d)",
                team.name, team.wins, team.losses, team.overall), xOffset, yOffset)
            yOffset = yOffset + 20
        end
        
        -- Western Conference standings
        xOffset = 400  -- Move to right side of screen
        yOffset = 110
        
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Western Conference Standings:", xOffset, 90)
        love.graphics.setColor(1, 1, 1)
        
        local westTeams = conferences[CONFERENCES.WEST]
        table.sort(westTeams, function(a, b)
            if a.wins == b.wins then
                return a.losses < b.losses
            end
            return a.wins > b.wins
        end)
        
        for _, team in ipairs(westTeams) do
            love.graphics.print(string.format("%s: %d-%d (Overall: %d)",
                team.name, team.wins, team.losses, team.overall), xOffset, yOffset)
            yOffset = yOffset + 20
        end
        
        if gameState.currentWeek < gameState.totalWeeks then
            love.graphics.print("Press SPACE to simulate next week", 50, 550)
        else
            love.graphics.print("Season Complete!", 50, 550)
        end
    end
end

function love.keypressed(key)
    if gameState.currentScreen == "menu" and key == "return" then
        gameState.currentScreen = "team_select"
    
    elseif gameState.currentScreen == "game" and key == "space" then
        if gameState.currentWeek <= gameState.totalWeeks then
            local weekGames = gameState.schedule[gameState.currentWeek]
            if not weekGames then
                print(string.format("Error: No games found for week %d", 
                    gameState.currentWeek))
                print("Schedule status:", gameState.schedule)
                return
            end
            
            print(string.format("Simulating %d games for week %d", 
                #weekGames, gameState.currentWeek))
                
            for _, game in ipairs(weekGames) do
                if game and game[1] and game[2] then
                    local team1 = gameState.teams[game[1]]
                    local team2 = gameState.teams[game[2]]
                    if team1 and team2 then
                        simulateGame(team1, team2)
                    else
                        print("Error: Invalid team reference", game[1], game[2])
                    end
                else
                    print("Error: Invalid game format", game)
                end
            end
            gameState.currentWeek = gameState.currentWeek + 1
        end
    end
end