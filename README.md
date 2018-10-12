# ScrapyardPlus 
## v1.4.0 *"profanatory-narcotisation"*

[![Build Status](https://travis-ci.org/ctcDNightmare/avorion-scrapyardplus.svg?branch=master)](https://travis-ci.org/ctcDNightmare/avorion-scrapyardplus)
___
Your salvaging ops are longer then 60 minutes?  
You want to get something in return for grinding all the precious reputation?  

With ScrapyardPlus you can:
* buy up to 8 hours total (depending on your reputation)
* increment your current license in variable intervals from 5 minutes all the way up to 3 hours per order
* get discounts for bulk orders and your current standing with the owner of the scrapyard
* earn a lifetime-license for yourself or your alliance an never have to bother with buying an extension again (lifetime status is granted faction-wide!)
* configure all important things to suit your (or your servers) needs
``mods/ScrapyardPlus/config/ScrapyardPlus.lua``

**This mod requires the [ctccommon](https://github.com/ctcDNightmare/avorion-ctccommon) libs to run.  
It's included in every release but not the sources!** 

## Installation
1. download & extract the [mod](https://github.com/ctcDNightmare/avorion-scrapyardplus/releases) into your Avorion folder

2. insert the following code at the end of the original scrapyard file (``data/scripts/entity/merchants/scrapyard.lua``)
```Lua
-- mod:ctcdnightmare/avorion-scrapyardplus:start
if not pcall(require, "mods/ScrapyardPlus/scripts/entity/merchants/scrapyard") then print("Failed to load ScrapyardPlus") end
-- mod:ctcdnightmare/avorion-scrapyardplus:end
```  
**In case you are using the MoveUI-Mod from Dirtyredz as well, insert ScrapyardPlus before MoveUI!**
 
3. done

## Default Config
___
```Lua
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
```

## Screenshots
*Solo player with good reputation*
![Lone wolf with good relations](https://i.imgur.com/hp9nsGU.jpg)  

*Alliance player with normal reputation*  
![Alliance player with normal relations](https://i.imgur.com/KU8JH3A.jpg)  

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
- regenerating wrecks / events to support lifetime licenses
Hint: you can take a look at the regen/event system by enabling it in the config


## Feedback & Discussion
http://www.avorion.net/forum/index.php/topic,3850.0.html

## Mentions & shoutouts
- [Dirtyredz](https://github.com/dirtyredz) - He got me into modding for Avorion with his [MoveUI-Mod](http://www.avorion.net/forum/index.php/topic,3834.0.html) and now we are even working together on each others mods to further improve our knowledge