# ScrapyardPlus 

[![Build Status](https://travis-ci.org/ctcDNightmare/avorion-scrapyardplus.svg?branch=master)](https://travis-ci.org/ctcDNightmare/avorion-scrapyardplus)
[ ![Codeship Status for ctcDNightmare/avorion-scrapyardplus](https://app.codeship.com/projects/21b1c080-b156-0136-608f-02af9aea0ff6/status?branch=master)](https://app.codeship.com/projects/310567)

Your salvaging ops are longer then 60 minutes?  
You want to get something in return for grinding all the precious reputation?  

With ScrapyardPlus you can:
* buy up to 8 hours total (depending on your reputation)
* increment your current license in variable intervals from 5 minutes all the way up to 3 hours per order
* get discounts for bulk orders and your current standing with the owner of the scrapyard
* earn a lifetime-license for yourself or your alliance and never have to bother with buying an extension again (lifetime status is granted faction-wide!)
* configure all important things to suit your (or your servers) needs (``data/config/scrapyardplus.lua``)

## Installation (without steam workshop)
1. download & extract the [mod](https://github.com/ctcDNightmare/avorion-scrapyardplus/releases) into %AppData%\Avorion\mods\ folder on Windows or ~/.avorion/mods/ on Unix-based systems

2. done

## Default Config
___
```Lua
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
config.enableRegen = true -- [Default: true] Enable/Disable the regeneration of wrecks inside a system
config.regenSpawntime = 15 -- [Default: 15] Time (in minutes) how often new event will start to spawn wrecks

-- events
config.enableDisasters = false -- [Default: true] Enable/Disable events from the (G)lobal (O)rganization of (D)isasters
config.disasterChance = 0.03 -- [Default: 0.03] Chance that something bad will happen
config.disasterSpawnTime = 20 -- [Default: 30] Time (in minutes) how often it's checked if bad things will happen
```

## Screenshots
*Solo player after getting his first license*  
![Solo player after getting his first license](https://i.imgur.com/Gu3EqTQ.jpg)  

*Alliance player with normal reputation*  
![Alliance player with normal relations](https://i.imgur.com/lUCRjTm.jpg)  

*Nearly reached lifetime status but lost reputation before finishing it*  
![Nearly there!](https://i.imgur.com/8amcRQZ.jpg)

*Finally reached lifetime status*  
![Lifetime](https://i.imgur.com/ZOsQhzt.jpg)

## Roadmap
- ~~extend your current license instead of overwriting it~~
- ~~longer maximum duration for your license~~
- ~~reputation based benefits (max duration and discount)~~
- ~~split the license system into private & alliance so you can buy a personal one even if you are in an alliance~~
- ~~flexible duration selection via slider~~
- ~~lifetime license~~
- ~~regenerating wrecks / events to support lifetime licenses~~
- polishing current implementation with more texts, events, interactions

## Feedback & Discussion
http://www.avorion.net/forum/index.php/topic,3850.0.html

## Mentions & shoutouts
- [Dirtyredz](https://github.com/dirtyredz) - He got me into modding for Avorion with his [MoveUI-Mod](http://www.avorion.net/forum/index.php/topic,3834.0.html) and now we are even working together on each others mods to further improve our knowledge
- [slxsh](https://github.com/slxsh) - For creating the two license icons 