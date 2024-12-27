---@diagnostic disable: undefined-global

package.path = "./src/?.lua;" .. package.path
local Player = require 'player'
local Team = require 'team'

-- main.lua
local gameState = {
    currentScreen = "menu",  -- menu, team_select, game
    teams = {},
    playerTeam = nil,
    schedule = {},
    currentWeek = 1,
    totalWeeks = 15
}


-- Initialize teams
local function initTeams()
    local teams = {
        {name = "Warriors", overall = 98},  -- Championship contender
        {name = "Eagles", overall = 95},    -- Elite team
        {name = "Suns", overall = 92},      -- Strong contender
        {name = "Knights", overall = 88},    -- Playoff team
        {name = "Dragons", overall = 85},    -- Solid team
        {name = "Phoenix", overall = 82},    -- Above average
        {name = "Lions", overall = 78},      -- Average team
        {name = "Tigers", overall = 75},     -- Average team
        {name = "Bears", overall = 72},      -- Below average
        {name = "Hawks", overall = 70},      -- Struggling team
        {name = "Wolves", overall = 68},     -- Rebuilding
        {name = "Panthers", overall = 65},   -- Weak team
        {name = "Jaguars", overall = 62},    -- Very weak
        {name = "Cobras", overall = 58},     -- Bottom tier
        {name = "Vipers", overall = 55},     -- Bottom tier
        {name = "Ravens", overall = 52}      -- Worst team
    }
    
    for _, teamData in ipairs(teams) do
        -- Use the imported Team class constructor
        local team = Team:new(teamData.name, teamData.overall)
        table.insert(gameState.teams, team)
    end
end

-- Generate season schedule
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
        while #available > 1 do  -- Changed from > 0 to ensure pairs
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
            week, #weekGames)) -- Debug print
    end
end

-- Simulate a game between two teams
local function simulateGame(team1, team2)
    -- Calculate win probability based on team ratings
    local ratingDiff = team1.overall - team2.overall
    -- Convert rating difference to win probability
    -- Using a logistic function with steeper curve (changed from /25 to /15)
    -- and adding a base advantage for higher-rated teams
    local baseWinProb = 1 / (1 + math.exp(-ratingDiff / 15))
    -- Add slight boost to higher-rated teams to reduce variance
    local winProbability = baseWinProb + (ratingDiff > 0 and 0.1 or 0)
    -- Clamp probability between 0.05 and 0.95 to prevent guaranteed wins/losses
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
    math.randomseed(os.time())  -- Set random seed
    
    print("Initializing game...")
    initTeams()
    print("Teams initialized:", #gameState.teams)
    
    generateSchedule()
    print("Schedule generated for " .. gameState.totalWeeks .. " weeks")
end

-- Helper function to check if mouse is over text
local function isMouseOver(x, y, width, height)
    local mouseX, mouseY = love.mouse.getPosition()
    return mouseX >= x and mouseX <= x + width and
           mouseY >= y and mouseY <= y + height
end

function love.mousepressed(x, y, button, istouch, presses)
    if gameState.currentScreen == "team_select" and button == 1 then
        for i, team in ipairs(gameState.teams) do
            local teamY = 70 + i * 20
            if isMouseOver(350, teamY, 200, 20) then
                gameState.playerTeam = team
                -- Add these debug lines
                print("Selected team:", team.name)
                print("Team methods:", team.displayRoster)
                print("Team overall:", team.overall)
                gameState.currentScreen = "game"
                break
            end
        end
    end
end

function love.draw()
    if gameState.currentScreen == "menu" then
        love.graphics.print("Basketball Manager", 350, 250)
        love.graphics.print("Press ENTER to start", 350, 300)
    
    elseif gameState.currentScreen == "team_select" then
        love.graphics.print("Select your team:", 350, 50)
        for i, team in ipairs(gameState.teams) do
            local y = 70 + i * 20
            -- Highlight team name if mouse is over it
            if isMouseOver(350, y, 200, 20) then
                love.graphics.setColor(0, 1, 0)  -- Green highlight
            end
            -- Display team name and overall rating
            love.graphics.print(string.format("%s (Overall: %d)", team.name, team.overall), 350, y)
            love.graphics.setColor(1, 1, 1)  -- Reset color
        end
    
    elseif gameState.currentScreen == "game" then
        -- Display current week and standings
        love.graphics.print("Week " .. gameState.currentWeek .. "/" .. gameState.totalWeeks, 50, 50)
        
        -- Add error checking for playerTeam
        if gameState.playerTeam then
            love.graphics.print(string.format("Your team: %s", gameState.playerTeam.name), 50, 70)
            if type(gameState.playerTeam.displayRoster) == "function" then
                love.graphics.print(gameState.playerTeam:displayRoster(), 400, 150)
            else
                love.graphics.print("Error: displayRoster not available", 400, 150)
                print("PlayerTeam type:", type(gameState.playerTeam))
                print("PlayerTeam methods:", gameState.playerTeam)
            end
        else
            love.graphics.print("No team selected", 50, 70)
        end
        
        -- Display standings
        love.graphics.print("League Standings:", 50, 130)
        local y = 150
        -- Sort teams by wins for standings
        local sortedTeams = {}
        for _, team in ipairs(gameState.teams) do
            table.insert(sortedTeams, team)
        end
        table.sort(sortedTeams, function(a, b) 
            if a.wins == b.wins then
                return a.losses < b.losses
            end
            return a.wins > b.wins
        end)
        
        for _, team in ipairs(sortedTeams) do
            love.graphics.print(string.format("%s: %d-%d (Overall: %d)", 
                team.name, team.wins, team.losses, team.overall), 50, y)
            y = y + 20
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
            -- Add error checking
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