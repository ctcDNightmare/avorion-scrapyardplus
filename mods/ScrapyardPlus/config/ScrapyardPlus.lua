local ScrapyardPlus = {}

-- info
ScrapyardPlus.name = "ScrapyardPlus"
ScrapyardPlus.author = "DNightmare"
ScrapyardPlus.homepage = "https://github.com/ctcDNightmare"
ScrapyardPlus.tags = {"scrapyard", "overhaul", "server", "client", "events", "lifetime-license" }
ScrapyardPlus.version = {
    major=1, minor=4, patch = 0,
    string = function()
        return  ScrapyardPlus.version.major .. '.' ..
                ScrapyardPlus.version.minor .. '.' ..
                ScrapyardPlus.version.patch
    end
}

-- general
ScrapyardPlus.enableDebug = false -- [Default: false] Enable/Disable detailed log output
ScrapyardPlus.alliancePriceFactor = 4.5 -- [Default: 4.5] How much alliances have to pay more for a salvaging license
ScrapyardPlus.pricePerMinute = 175 -- [Default: 175] Price per one minute of salvaging

-- timers / announcements
ScrapyardPlus.advertisementTimer = 120 -- [Default: 120] Time (in seconds) when the scrapyard will spam the system with "get a license now"
ScrapyardPlus.expirationTimeNotice = 600 -- [Default: 600] Time (in seconds) at which the first reminder will be send to players/alliances about their license running out
ScrapyardPlus.expirationTimeWarning = 300 -- [Default: 300] Time (in seconds) at which the second reminder will be send to players/alliances about their license running out
ScrapyardPlus.expirationTimeCritical = 120 -- [Default: 120] Time (in seconds) at which the third reminder will be send to players/alliances about their license running out
ScrapyardPlus.expirationTimeFinal = 30 -- [Default: 30] Time (in seconds) at which the FINAL reminder will be send to players/alliances about their license running out

-- lifetime
ScrapyardPlus.allowLifetime = true -- [Default: true] Enable/Disable the ability to get lifetime salvaging licenses
ScrapyardPlus.lifetimeRepRequired = 100000 -- [Default: 100000] Minimum required reputation before you start to gather experience towards lifetime
ScrapyardPlus.lifetimeExpTicks = 1000 -- [Default: 1000] Actions (in ticks) after the player/alliance will get experience
ScrapyardPlus.lifetimeExpRequired = 100000 -- [Default: 100000] Amount of experience to unlock lifetime-license
ScrapyardPlus.lifetimeExpFactor = 0.75 -- [Default: 0.75] Factor to de-/increase the base experience calculation
ScrapyardPlus.lifetimeAllianceFactor = 0.5 -- [Default: 0.5] Factor to de-/increase the amount an alliance will get compared to a player
ScrapyardPlus.lifetimeExpBaseline = 7 -- [Default: 7] Base value of experience that's always granted

-- high traffic system
ScrapyardPlus.highTrafficChance = 0.3 -- [Default: 0.3] Chance that a discovered system is regenerative
ScrapyardPlus.enableRegen = false -- [Default: true] Enable/Disable the regeneration of wrecks inside a system
ScrapyardPlus.regenSpawntime = 15 -- [Default: 15] Time (in minutes) how often new event will start to spawn wrecks

-- events
ScrapyardPlus.enableDisasters = false -- [Default: true] Enable/Disable events from the (G)lobal (O)rganization of (D)isasters
ScrapyardPlus.disasterChance = 0.03 -- [Default: 0.03] Chance that something bad will happen
ScrapyardPlus.disasterSpawnTime = 20 -- [Default: 30] Time (in minutes) how often it's checked if bad things will happen

return ScrapyardPlus
