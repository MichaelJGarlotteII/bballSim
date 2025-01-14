-- player.lua
local Player = {
    name = "",
    position = "",
    age = 0,
    attributes = {},
    salary = 0
}

-- Constants for salary calculation
local SALARY_CAP = 140588000  -- $140.588M
local MAX_PLAYER_PERCENT = 0.35  -- Maximum individual salary as percentage of cap
local MIN_PLAYER_PERCENT = 0.01  -- Minimum individual salary as percentage of cap

-- Initialize player attributes
local function initAttributes()
    return {
        shooting = math.random(30, 99),
        defense = math.random(30, 99),
        playmaking = math.random(30, 99),
        athleticism = math.random(30, 99),
        potential = math.random(30, 99)
    }
end

-- Calculate salary based on overall rating
local function calculateSalary(overall)
    -- Convert overall rating (0-100) to a percentage of the salary range
    local ratingPercent = (overall - 65) / 35  -- Normalize ratings around 65-100 range
    ratingPercent = math.max(0, math.min(1, ratingPercent))  -- Clamp between 0 and 1
    
    -- Use exponential scaling to make higher ratings more valuable
    local scaleFactor = math.exp(ratingPercent * 2) / math.exp(2)
    
    -- Calculate salary as a percentage of cap between MIN_PLAYER_PERCENT and MAX_PLAYER_PERCENT
    local salaryPercent = MIN_PLAYER_PERCENT + (MAX_PLAYER_PERCENT - MIN_PLAYER_PERCENT) * scaleFactor
    
    -- Add some randomization (±10%)
    local randomFactor = 0.9 + math.random() * 0.2
    local finalSalaryPercent = salaryPercent * randomFactor
    
    -- Calculate actual salary
    return math.floor(SALARY_CAP * finalSalaryPercent)
end

function Player:new(name, position)
    local player = setmetatable({}, { __index = Player })
    player.name = name
    player.position = position
    player.age = math.random(19, 38)
    player.attributes = initAttributes()
    
    -- Calculate initial overall and salary
    local overall = player:calculateOverall()
    player.salary = calculateSalary(overall)
    
    return player
end

function Player:calculateOverall()
    local weights = {
        PG = {shooting = 0.3, defense = 0.2, playmaking = 0.3, athleticism = 0.2},
        SG = {shooting = 0.4, defense = 0.2, playmaking = 0.2, athleticism = 0.2},
        SF = {shooting = 0.3, defense = 0.3, playmaking = 0.2, athleticism = 0.2},
        PF = {shooting = 0.2, defense = 0.3, playmaking = 0.2, athleticism = 0.3},
        C = {shooting = 0.1, defense = 0.4, playmaking = 0.1, athleticism = 0.4}
    }
    
    local posWeights = weights[self.position]
    local overall = 0
    
    if posWeights then
        overall = 
            (self.attributes.shooting * posWeights.shooting) +
            (self.attributes.defense * posWeights.defense) +
            (self.attributes.playmaking * posWeights.playmaking) +
            (self.attributes.athleticism * posWeights.athleticism)
    end
    
    return math.floor(overall)
end

function Player:getSalaryString()
    return string.format("$%.1fM", self.salary / 1000000)
end

return Player