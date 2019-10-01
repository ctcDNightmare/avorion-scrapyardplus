if (not onServer()) then return end

-- namespace ScrapyardPlus
ScrapyardPlus = {}

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
    local greetings = {
        "Howdy partner, look what I've found just outside the system. How much you payin' for it?",
        "Bleep blep!",
        "Yo! Interested in some fresh goodies?"
    }

    Sector():broadcastChatMessage('Scrapper', 0, greetings[math.random(1, #greetings)])

    local toBeCreated = math.random(0, 100)

    if toBeCreated == 100 then -- dreadnought
        print('dreadnought wreck incoming')
    end

    if toBeCreated > 95 and toBeCreated <= 99 then -- battleship
        print('battleship wreck incoming')
    end

    if toBeCreated > 85 and toBeCreated <= 95 then -- destroyer
        print('destroyer wreck incoming')
    end

    if toBeCreated > 65 and toBeCreated <= 85 then -- cruiser
        print('cruiser wreck incoming')
    end

    if toBeCreated > 15 and toBeCreated <= 65 then -- frigate
        print('frigate wreck incoming')
    end

    if toBeCreated <= 15 then -- transport
        print('transport wreck incoming')
    end

    nextStep = 'scrapperStageTwo' -- always set the next event or nil
end

function events.scrapperStageTwo()
    local delay = 5
    if timer < delay then -- wait before continue
        return
    else
        timer = 0
    end

    local goodbye = {
        "kthxbye!",
        "Fly safe.",
        "o/ byebye"
    }
    Sector():broadcastChatMessage('Scrapper', 0, goodbye[math.random(1, #goodbye)])

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




