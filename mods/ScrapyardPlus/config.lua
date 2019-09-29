local config = {}

-- general
config.enableDebug = false -- [Default: false] Enable/Disable detailed log output
config.alliancePriceFactor = 4.5 -- [Default: 4.5] How much alliances have to pay more for a salvaging license
config.pricePerMinute = 175 -- [Default: 175] Price per one minute of salvaging

-- timers / announcements
config.advertisementTimer = 120 -- [Default: 120] Time (in seconds) when the scrapyard will spam the system with "get a license now"
config.expirationTimeNotice = 600 -- [Default: 600] Time (in seconds) at which the first reminder will be send to players/alliances about their license running out
config.expirationTimeWarning = 300 -- [Default: 300] Time (in seconds) at which the second reminder will be send to players/alliances about their license running out
config.expirationTimeCritical = 120 -- [Default: 120] Time (in seconds) at which the third reminder will be send to players/alliances about their license running out
config.expirationTimeFinal = 30 -- [Default: 30] Time (in seconds) at which the FINAL reminder will be send to players/alliances about their license running out

-- lifetime
config.allowLifetime = true -- [Default: true] Enable/Disable the ability to get lifetime salvaging licenses
config.lifetimeRepRequired = 100000 -- [Default: 100000] Minimum required reputation before you start to gather experience towards lifetime
config.lifetimeExpTicks = 1000 -- [Default: 1000] Actions (in ticks) after the player/alliance will get experience
config.lifetimeExpRequired = 100000 -- [Default: 100000] Amount of experience to unlock lifetime-license
config.lifetimeExpFactor = 0.75 -- [Default: 0.75] Factor to de-/increase the base experience calculation
config.lifetimeAllianceFactor = 0.5 -- [Default: 0.5] Factor to de-/increase the amount an alliance will get compared to a player
config.lifetimeExpBaseline = 7 -- [Default: 7] Base value of experience that's always granted

-- high traffic system
config.highTrafficChance = 0.3 -- [Default: 0.3] Chance that a discovered system is regenerative
config.enableRegen = false -- [Default: true] Enable/Disable the regeneration of wrecks inside a system
config.regenSpawntime = 15 -- [Default: 15] Time (in minutes) how often new event will start to spawn wrecks

-- events
config.enableDisasters = false -- [Default: true] Enable/Disable events from the (G)lobal (O)rganization of (D)isasters
config.disasterChance = 0.03 -- [Default: 0.03] Chance that something bad will happen
config.disasterSpawnTime = 20 -- [Default: 30] Time (in minutes) how often it's checked if bad things will happen

return config
