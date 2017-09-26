local ScrapyardPlus = {}

local eventTypes
local eventFinished = false
local nextStep
local timer = 0


function Scrapyard.getUpdateInterval()
    return 1
end

function Scrapyard.restore(data)
    -- clear earlier data
    eventFinished = data.eventFinished
    nextStep = data.nextStep
    timer = data.timer
end

function Scrapyard.secure()
    local data = {}
    data.eventFinished = eventFinished
    data.nextStep = nextStep
    data.timer = timer

    return data
end

function ScrapyardPlus.initialize(eventType)
    print('initialize', eventType)
    if onServer() then
        ScrapyardPlus.initEventtypes()

        if ScrapyardPlus[eventType] ~= nil
                and type(ScrapyardPlus[eventType]) == 'function'
        then
            nextStep = ScrapyardPlus[eventType]() -- support for multi-stage events
        else
            terminate() -- no suitable event found
        end
    end
end

function ScrapyardPlus.initEventTypes()
    print('initEventTypes')
    eventTypes = {}
    eventTypes['high-traffic'] = ScrapyardPlus.eventScrapperStageOne
    eventTypes['disaster'] = ScrapyardPlus.eventDisasterStageOne
end

function Scrapyard.updateServer()

    if nextStep ~= nil then
        -- multi stage conversations and actions
        if ScrapyardPlus[nextStep] ~= nil
                and type(ScrapyardPlus[nextStep]) == 'function'
        then
            nextStep = ScrapyardPlus[nextStep]
            eventFinished = (nextStep == nil)
        end
    end

    if eventFinished == true then
        terminate()
    end
end

-- events

-- scrapper aka sell a ship to the scrapyard
function ScrapyardPlus.eventScrapperStageOne()
    print('eventScrapperStageOne')
    -- todo: jump in with towed ship, talk, fly, talk/sell, jump out with towing ship only, convert towed ship to wreck

    local greetings = {
        "Howdy partner, look what I've found just outside the system. How much you payin' for it?",
        "Bleep blep!",
        "Yo! Interested in some fresh goodies?"
    }

    Sector():broadcastChatMessage('Scrapper', 0, greetings[math.random(1, #greetings)] %_t)

    local toBeCreated = math.random(0, 100)

    if toBeCreated == 100 then -- dreadnought
    end

    if toBeCreated > 95 and toBeCreated <= 99 then -- battleship
    end

    if toBeCreated > 85 and toBeCreated <= 95 then -- destroyer
    end

    if toBeCreated > 50 and toBeCreated <= 85 then -- cruiser
    end

    if toBeCreated > 15 and toBeCreated <= 50 then -- frigate
    end

    if toBeCreated <= 15 then -- transport
    end

    return 'spawnScrapperStageTwo' -- always return the next event or nil
end

function ScrapyardPlus.eventScrapperStageTwo()
    print('eventScrapperStageTwo')

    return nil -- always return the next event or nil
end

-- disaster aka bad stuff happens
function ScrapyardPlus.eventDisasterStageOne()
    print('eventDisasterStageOne')
    -- bust some of the wrecks? hyperdrive overload?
    -- need some more options in here :-)

    -- DO
    -- BAD
    -- STUFF :)

    return nil -- always return the next event or nil
end


