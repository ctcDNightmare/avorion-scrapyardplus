if (not onServer()) then return end

-- namespace ScrapyardPlus
ScrapyardPlus = {}

local SectorGenerator = include ("SectorGenerator")
local PlanGenerator = include("plangenerator")
local eventTypes = {}
local eventFinished = false
local nextStep
local timer = 0
local events = {}

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

--- events
-- scrapper aka sell a ship to the scrapyard
-- todo: jump in with towed ship, talk, fly, talk/sell, jump out with towing ship only, convert towed ship to wreck
function events.scrapperStageOne()
    local station = Entity()
    local faction = Faction(station.factionIndex)
    local generator = SectorGenerator(Sector():getCoordinates())
    local volume = 0

    local toBeCreated = math.random(0, 100)
    if toBeCreated == 100 then -- battleship
        print('HIGH TRAFFIC SYSTEM // Spawning new Wreck: Battleship')
        volume = 50000
    end

    if toBeCreated > 95 and toBeCreated <= 99 then -- dreadnought
        print('HIGH TRAFFIC SYSTEM // Spawning new Wreck: Dreadnought')
        volume = 32000
    end

    if toBeCreated > 85 and toBeCreated <= 95 then -- destroyer
        print('HIGH TRAFFIC SYSTEM // Spawning new Wreck: Destroyer')
        volume = 20000
    end

    if toBeCreated > 65 and toBeCreated <= 85 then -- cruiser
        print('HIGH TRAFFIC SYSTEM // Spawning new Wreck: Cruiser')
        volume = 15000
    end

    if toBeCreated > 15 and toBeCreated <= 65 then -- frigate
        print('HIGH TRAFFIC SYSTEM // Spawning new Wreck: Frigate')
        volume = 7500
    end

    if toBeCreated <= 15 then -- corvette
        print('HIGH TRAFFIC SYSTEM // Spawning new Wreck: Corvette')
        volume = 2500
    end

    local material = PlanGenerator.selectMaterial(faction)
    local style = PlanGenerator.selectShipStyle(faction)
    local plan = PlanGenerator.makeShipPlan(faction, volume, style, material)
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




