-- player.lua
local Player = {
    name = "",
    position = "",  -- PG, SG, SF, PF, C
    ratings = {
        shooting = 50,
        defense = 50,
        playmaking = 50,
        rebounding = 50,
        athleticism = 50
    },
    age = 20,
    potential = 50
}

function Player:new(name, position)
    local player = setmetatable({}, { __index = Player })
    player.name = name
    player.position = position
    -- Generate random ratings based on position
    player.ratings = self:generateRatings(position)
    player.age = math.random(19, 35)
    player.potential = math.random(40, 99)
    return player
end

function Player:generateRatings(position)
    local ratings = {
        shooting = 50,
        defense = 50,
        playmaking = 50,
        rebounding = 50,
        athleticism = 50
    }
    
    -- Position-specific rating generation
    if position == "PG" then
        -- Point Guards excel at playmaking and are good shooters
        ratings.playmaking = math.random(60, 95)
        ratings.shooting = math.random(55, 90)
        ratings.defense = math.random(40, 85)
        ratings.rebounding = math.random(30, 70)
        ratings.athleticism = math.random(50, 90)
    elseif position == "SG" then
        -- Shooting Guards are best at shooting
        ratings.shooting = math.random(65, 95)
        ratings.playmaking = math.random(50, 85)
        ratings.defense = math.random(45, 85)
        ratings.rebounding = math.random(35, 75)
        ratings.athleticism = math.random(55, 90)
    elseif position == "SF" then
        -- Small Forwards are well-rounded
        ratings.shooting = math.random(50, 90)
        ratings.playmaking = math.random(45, 85)
        ratings.defense = math.random(50, 90)
        ratings.rebounding = math.random(45, 85)
        ratings.athleticism = math.random(60, 95)
    elseif position == "PF" then
        -- Power Forwards focus on rebounding and defense
        ratings.shooting = math.random(40, 85)
        ratings.playmaking = math.random(35, 75)
        ratings.defense = math.random(60, 95)
        ratings.rebounding = math.random(65, 95)
        ratings.athleticism = math.random(55, 90)
    elseif position == "C" then
        -- Centers dominate rebounding and interior defense
        ratings.shooting = math.random(35, 75)
        ratings.playmaking = math.random(30, 70)
        ratings.defense = math.random(65, 95)
        ratings.rebounding = math.random(70, 99)
        ratings.athleticism = math.random(50, 90)
    end
    
    return ratings
end

function Player:calculateOverall()
    -- Calculate overall rating based on position-specific weights
    local weights = self:getPositionWeights(self.position)
    local total = 0
    local totalWeight = 0
    
    for stat, weight in pairs(weights) do
        total = total + (self.ratings[stat] * weight)
        totalWeight = totalWeight + weight
    end
    
    return math.floor(total / totalWeight)
end

function Player:getPositionWeights(position)
    local weights = {
        PG = {
            shooting = 0.8,
            defense = 0.6,
            playmaking = 1.0,
            rebounding = 0.3,
            athleticism = 0.7
        },
        SG = {
            shooting = 1.0,
            defense = 0.7,
            playmaking = 0.7,
            rebounding = 0.4,
            athleticism = 0.8
        },
        SF = {
            shooting = 0.8,
            defense = 0.8,
            playmaking = 0.6,
            rebounding = 0.7,
            athleticism = 0.9
        },
        PF = {
            shooting = 0.6,
            defense = 0.9,
            playmaking = 0.4,
            rebounding = 1.0,
            athleticism = 0.8
        },
        C = {
            shooting = 0.4,
            defense = 1.0,
            playmaking = 0.3,
            rebounding = 1.0,
            athleticism = 0.7
        }
    }
    
    return weights[position]
end

-- This makes the Player class available to other files that require it
return Player