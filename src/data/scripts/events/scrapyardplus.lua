if (not onServer()) then return end
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
SectorGenerator = include ("SectorGenerator")
PlanGenerator = include ("plangenerator")

-- namespace ScrapyardPlus
ScrapyardPlus = {}

local eventTypes = {}
local eventFinished = false
local nextStep
local timer = 0
local events = {}

local shiptypes = {
    battleship = {
        name = "Battleship"%_t,
        volume = 50000
    },
    dreadnought = {
        name = "Dreadnought"%_t,
        volume = 32000
    },
    destroyer = {
        name = "Destroyer"%_t,
        volume = 20000
    },
    cruiser = {
        name = "Cruiser"%_t,
        volume = 15000
    },
    frigate = {
        name = "Frigate"%_t,
        volume = 7500
    },
    corvette = {
        name = "Corvette"%_t,
        volume = 2500
    }
}

function ScrapyardPlus.getUpdateInterval()
    return 1
end

function ScrapyardPlus.restore(data)
    -- clear earlier data
    eventFinished = data.eventFinished
    nextStep = data.nextStep
    timer = data.timer
end

function ScrapyardPlus.secure()
    local data = {}
    data.eventFinished = eventFinished
    data.nextStep = nextStep
    data.timer = timer

    return data
end

function ScrapyardPlus.initialize(eventType)
    if eventType == nil then terminate() end -- sanity check
    ScrapyardPlus.initEventTypes()
    if eventTypes[eventType] ~= nil and type(eventTypes[eventType]) == 'function'
    then
        eventTypes[eventType]() -- support for multi-stage events
    else
        terminate() -- no suitable event found
    end
end

function ScrapyardPlus.updateServer(timeStep)
    timer = timer + timeStep
    if nextStep ~= nil then
        -- multi stage conversations and actions
        if events[nextStep] ~= nil
                and type(events[nextStep]) == 'function'
        then
            events[nextStep]()
            eventFinished = (nextStep == nil)
        end
    end

    if eventFinished == true then
        terminate()
    end
end

function ScrapyardPlus.initEventTypes()
    eventTypes['high-traffic'] = events.scrapperStageOne
    eventTypes['disaster'] = events.disasterStageOne
end

function events.getNewWreck()
    local toBeCreated = math.random(0, 100)
    if toBeCreated == 100 then -- battleship
        return shiptypes.battleship
    end

    if toBeCreated > 95 and toBeCreated <= 99 then -- dreadnought
        return shiptypes.dreadnought
    end

    if toBeCreated > 85 and toBeCreated <= 95 then -- destroyer
        return shiptypes.destroyer
    end

    if toBeCreated > 65 and toBeCreated <= 85 then -- cruiser
        return shiptypes.cruiser
    end

    if toBeCreated > 15 and toBeCreated <= 65 then -- frigate
        return shiptypes.frigate
    end

    if toBeCreated <= 15 then -- corvette
        return shiptypes.corvette
    end
end

--- events
-- scrapper aka sell a ship to the scrapyard
-- todo: jump in with towed ship, talk, fly, talk/sell, jump out with towing ship only, convert towed ship to wreck
function events.scrapperStageOne()
    local station = Entity()
    local faction = Faction(station.factionIndex)
    local wreck = events.getNewWreck()

    Sector():broadcastChatMessage(station.title, 0, string.format("Oh look, a %s wreck just got dropped off at my Scrapyard!"%_t, wreck.name))

    local generator = SectorGenerator(Sector():getCoordinates())
    local material = PlanGenerator.selectMaterial(faction)
    local style = PlanGenerator.selectShipStyle(faction)
    local plan = PlanGenerator.makeShipPlan(faction, wreck.volume, style, material)

    generator:createUnstrippedWreckage(faction, plan)


    nextStep = nil -- always set the next event or nil
end

-- disaster aka bad stuff happens
function events.disasterStageOne()
    -- bust some of the wrecks? hyperdrive overload?
    -- need some more options in here :-)

    -- DO
    -- BAD
    -- STUFF :)
    Sector():broadcastChatMessage('G.O.D.', 0, 'Bad stuff is happening')

    nextStep = nil -- always set the next event or nil
end
