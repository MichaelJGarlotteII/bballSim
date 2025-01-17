-- team.lua
local Player = require 'player'  -- Make sure this path matches your file structure

-- List of first names and last names for random generation
local firstNames = {
    "James", "Michael", "Chris", "Kevin", "Anthony", "Stephen", "Karl", "Joel",
    "Luka", "Nikola", "Jayson", "Devin", "DeMar", "Trae", "Damian", "Bradley",
    "Zach", "Donovan", "Ja", "LaMelo", "Russell", "Draymond", "Bum", "Kyle"
}

local lastNames = {
    "Johnson", "Smith", "Williams", "Brown", "Jones", "Davis", "Miller", "Wilson",
    "Anderson", "Taylor", "Thomas", "Moore", "Martin", "Lee", "Thompson", "White",
    "Harris", "Clark", "Lewis", "Robinson", "Walker", "Young", "Ayimbadyo", "King"
}

local Team = {
    name = "",
    wins = 0,
    losses = 0,
    roster = {},
    overall = 50,
    conference = "",  -- Added conference property
    -- Add salary cap and budget management
    salaryCap = 140588000,  -- $100M salary cap
    currentSalary = 0
}

-- Updated constructor to accept conference parameter
function Team:new(name, targetRating, conference)
    local team = setmetatable({}, { __index = Team })
    team.name = name
    team.wins = 0
    team.losses = 0
    team.roster = {}
    team.targetRating = targetRating  -- Store the desired team rating
    team.conference = conference or "Unknown"  -- Store the conference, with fallback
    
    -- Generate initial roster
    team:generateStartingLineup()
    team:calculateOverall()
    
    return team
end

function Team:generatePlayerName()
    -- Generate a random name from our lists
    local firstName = firstNames[math.random(#firstNames)]
    local lastName = lastNames[math.random(#lastNames)]
    return firstName .. " " .. lastName
end

function Team:generateStartingLineup()
    -- Define our starting positions
    local positions = {"PG", "SG", "SF", "PF", "C"}
    
    -- For each position, create a starter and a backup
    for _, pos in ipairs(positions) do
        -- Create starter with higher potential rating
        local starterName = self:generatePlayerName()
        local starter = Player:new(starterName, pos)
        
        -- Create backup with slightly lower rating potential
        local backupName = self:generatePlayerName()
        local backup = Player:new(backupName, pos)

        --Create 3rd string player with even lower rating potential
        local benchName = self:generatePlayerName()
        local bench = Player:new(benchName, pos)
        
        -- Add both to roster
        table.insert(self.roster, starter)
        table.insert(self.roster, backup)
        table.insert(self.roster, bench)
    end
    
    -- Sort roster by overall rating
    self:sortRoster()
end

function Team:sortRoster()
    table.sort(self.roster, function(a, b)
        return a:calculateOverall() > b:calculateOverall()
    end)
end

function Team:calculateOverall()
    -- Get the starting lineup
    local starters = self:getStartingLineup()
    local total = 0
    
    -- Calculate average of the top 5 players' ratings
    for _, player in ipairs(starters) do
        total = total + player:calculateOverall()
    end
    
    -- Update team's overall rating
    self.overall = math.floor(total / 5)
    
    -- Adjust rating to move closer to target rating if specified
    if self.targetRating then
        -- Weighted average between calculated rating and target rating
        self.overall = math.floor((self.overall + self.targetRating * 2) / 3)
    end
    
    return self.overall
end

function Team:getStartingLineup()
    local starters = {}
    local positions = {"PG", "SG", "SF", "PF", "C"}
    
    -- Get the best player at each position
    for _, pos in ipairs(positions) do
        local bestPlayer = self:getBestPlayerAtPosition(pos)
        if bestPlayer then
            table.insert(starters, bestPlayer)
        end
    end
    
    return starters
end

function Team:getBestPlayerAtPosition(position)
    local bestPlayer = nil
    local bestRating = -1
    
    for _, player in ipairs(self.roster) do
        if player.position == position then
            local rating = player:calculateOverall()
            if rating > bestRating then
                bestRating = rating
                bestPlayer = player
            end
        end
    end
    
    return bestPlayer
end

-- Calculate total team salary
function Team:calculateTotalSalary()
    local total = 0
    for _, player in ipairs(self.roster) do
        total = total + player.salary
    end
    return total
end

-- Adjust roster salaries to meet cap requirements
function Team:adjustSalaries()
    local total = self:calculateTotalSalary()
    local salaryFloor = SALARY_CAP * 0.9  -- 90% of cap
    
    if total < salaryFloor or total > SALARY_CAP then
        -- Calculate adjustment factor to get to the middle of the valid range
        local targetSalary = (salaryFloor + SALARY_CAP) / 2
        local adjustmentFactor = targetSalary / total
        
        -- Adjust all salaries proportionally
        for _, player in ipairs(self.roster) do
            player.salary = math.floor(player.salary * adjustmentFactor)
        end
    end
end

-- Updated displayRoster to include conference information
function Team:displayRoster()
    -- Display team information including conference
    local info = string.format("\n%s (%s Conference)\nOverall: %d\nRecord: %d-%d\n\nRoster:\n",
        self.name, self.conference, self.overall, self.wins, self.losses)
    
    -- Display each player's information
    for _, player in ipairs(self.roster) do
        local overall = player:calculateOverall()
        info = info .. string.format("%-20s %-3s OVR: %d AGE: %d\n",
            player.name, player.position, overall, player.age)
    end
    
    return info
end

function Team:getRoster()
    local formattedRoster = {}
    
    for _, player in ipairs(self.roster) do
        table.insert(formattedRoster, {
            name = player.name,
            position = player.position,
            rating = player:calculateOverall()
        })
    end
    
    -- Sort by rating (highest to lowest)
    table.sort(formattedRoster, function(a, b)
        return a.rating > b.rating
    end)
    
    return formattedRoster
end
-- Make the Team class available to other files
return Team