local ScrapyardPlus = {}

-- info
ScrapyardPlus.name = "ScrapyardPlus"
ScrapyardPlus.author = "DNightmare"
ScrapyardPlus.homepage = "https://github.com/ctcDNightmare"
ScrapyardPlus.tags = {"scrapyard", "overhaul", "server", "client", "events", "lifetime-license" }
ScrapyardPlus.version = {
    major=1, minor=3, patch = 0,
    string = function()
        return  ScrapyardPlus.version.major .. '.' ..
                ScrapyardPlus.version.minor .. '.' ..
                ScrapyardPlus.version.patch
    end
}

-- general
ScrapyardPlus.enableDebug = false
ScrapyardPlus.alliancePriceFactor = 4.5
ScrapyardPlus.pricePerMinute = 175

-- timers / announcements
ScrapyardPlus.advertisementTimer = 120
ScrapyardPlus.expirationTimeNotice = 600
ScrapyardPlus.expirationTimeWarning = 300
ScrapyardPlus.expirationTimeCritical = 120
ScrapyardPlus.expirationTimeFinal = 30

-- lifetime
ScrapyardPlus.allowLifetime = true
ScrapyardPlus.lifetimeRepRequired = 100000
ScrapyardPlus.lifetimeExpTicks = 5
ScrapyardPlus.lifetimeExpRequired = 100000
ScrapyardPlus.lifetimeExpFactor = 0.9
ScrapyardPlus.lifetimeExpBaseline = 10

-- high traffic system
ScrapyardPlus.highTrafficChance = 0.3
ScrapyardPlus.highTrafficSpawntime = 1

-- disasters
ScrapyardPlus.disasterChance = 0.5
ScrapyardPlus.disasterSpawnTime = 3

return ScrapyardPlus
