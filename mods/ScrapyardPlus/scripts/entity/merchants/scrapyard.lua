package.path = package.path .. ";data/scripts/lib/?.lua"
include ("galaxy")
include ("utility")
include ("faction")
include ("randomext")
include ("callable")
include ("weapontype")
include ("stringutility")
include ("goods")
include ("reconstructiontoken")
include ("weapontypeutility")
include ("relations")
local TurretIngredients = include("turretingredients")
local SellableInventoryItem = include("sellableinventoryitem")
local Dialog = include("dialogutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Scrapyard

Scrapyard.interactionThreshold = -30000

-- constants
local MODULE = 'ScrapyardPlus' -- our module name
local FS = '::' -- field separator

-- general
local libPath = "mods/ctccommon/scripts/lib"
local basePath = "mods/" .. MODULE
local modConfig = require(basePath .. '/config')
local requiredLibs = {'/serialize'} -- libs from 'ctccommon' which are required by this mod

-- constants
local typeAlliance = 'ALLIANCE'
local typeSolo = 'SOLO'

-- server
local licenses = {}
local illegalActions = {}
local legalActions = {}
local newsBroadcastCounter = 0
local highTrafficSystem = false
local highTrafficTimer = 0
local disasterTimer = 0

-- client
local tabbedWindow = 0
local planDisplayer = 0
local sellButton = 0
local sellWarningLabel = 0
local uiMoneyValue = 0
local visible = false
local uiGroups = {}

-- turret tab
local inventory = nil
local scrapButton = nil
local goodsLabels = {}


-- solo license
local currentSoloLicenseDurationLabel
local maxSoloLicenseDurationLabel
local soloLicenseDuration = 0
-- alliance license
local currentAllianceLicenseDurationLabel
local maxAllianceLicenseDurationLabel
local allianceLicenseDuration = 0

-- lifetime
local soloLifetimeStatusBar
local currentSoloExp = 0
local allianceLifetimeStatusBar
local currentAllianceExp = 0

-- untouched but ported vanilla functions (running into upvalue issues etm)
-- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
function Scrapyard.renderUI()

    if tabbedWindow:getActiveTab().name == "Sell Ship"%_t then
        renderPrices(planDisplayer.lower + 20, "Ship Value:"%_t, uiMoneyValue, nil)
    end
end
function Scrapyard.onDismantleTurretPressed()
    local selected = inventory.selected
    if selected then
        invokeServerFunction("dismantleInventoryTurret", selected.index)
    end
end
function Scrapyard.onTurretSelected()
    local selected = inventory.selected
    if not selected then return end
    if not selected.item then return end

    scrapButton.active = true

    local _, possible = Scrapyard.getTurretGoods(selected.item)

    for _, line in pairs(goodsLabels) do
        line.icon:hide()
    end

    local i = 1
    for _, good in pairs(possible) do
        local line = goodsLabels[i]; i = i + 1
        line.icon:show()

        line.icon.picture = good.icon
        line.icon.tooltip = good:displayName(10)
    end
end

function Scrapyard.onTurretDeselected()
    scrapButton.active = false

    for _, line in pairs(goodsLabels) do
        line.icon:hide()
    end
end

function Scrapyard.onTurretDismantled()
    local ship = Player().craft
    if not ship then return end

    inventory:fill(ship.factionIndex, InventoryItemType.Turret)
end
function Scrapyard.onSellButtonPressed()
    invokeServerFunction("sellCraft")
end

-- modded vanilla functions
function Scrapyard.onShowWindow()
    visible = true

    local ship = Player().craft
    if not ship then return end

    -- get the plan of the player's ship
    local plan = ship:getPlan()
    planDisplayer.plan = plan

    if ship.isDrone then
        sellButton.active = false
        sellWarningLabel:hide()
    else
        sellButton.active = true
        sellWarningLabel:show()
    end

    uiMoneyValue = Scrapyard.getShipValue(plan)

    Scrapyard.getCurrentExperience()
    Scrapyard.getLicenseDuration()

    -- turrets
    inventory:fill(ship.factionIndex, InventoryItemType.Turret)

end
function Scrapyard.restore(data)
    -- clear earlier data
    licenses = data.licenses
    illegalActions = data.illegalActions
    legalActions = data.legalActions
    highTrafficSystem = data.highTrafficSystem
end
function Scrapyard.secure()
    -- save licenses
    local data = {}
    data.licenses = licenses
    data.illegalActions = illegalActions
    data.legalActions = legalActions
    data.highTrafficSystem = highTrafficSystem
    return data
end
function Scrapyard.initialize()

    if onServer() then
        -- load required common libs
        for _,lib in pairs(requiredLibs) do
            if not pcall(require, libPath .. lib) then
                print('failed loading ' .. lib)
            end
        end

        Sector():registerCallback("onHullHit", "onHullHit")
        local station = Entity()
        if station.title == "" then
            station.title = "Scrapyard"%_t
        end

        local isHighTraffic = math.random()
        if highTrafficSystem == nil and isHighTraffic <= modConfig.highTrafficChance
        then
            highTrafficSystem = true
        else
            highTrafficSystem = false
        end

        -- check for lifetime reached
        local experience = Scrapyard.loadExperience(Faction().index)
        local lifetimeReached = (experience[Faction().index] >= modConfig.lifetimeExpRequired)

    end

    if onClient() then
        Scrapyard.getCurrentExperience()
        Scrapyard.getLicenseDuration()
        if EntityIcon().icon == "" then
            EntityIcon().icon = "data/textures/icons/pixel/scrapyard_fat.png"
            InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())
        end
        invokeServerFunction("checkLifetime", Player().index)
    end
end
function Scrapyard.initUI()

    local res = getResolution()
    local size = vec2(700, 650)

    local menu = ScriptUI()
    local mainWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(mainWindow, "Scrapyard" % _t)
    mainWindow.caption = "Scrapyard" % _t
    mainWindow.showCloseButton = 1
    mainWindow.moveable = 1

    -- create a tabbed window inside the main window
    tabbedWindow = mainWindow:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create a "Sell" tab inside the tabbed window
    local sellTab = tabbedWindow:createTab("Sell Ship" % _t, "data/textures/icons/sell-ship.png", "Sell your ship to the scrapyard" % _t)
    size = sellTab.size

    planDisplayer = sellTab:createPlanDisplayer(Rect(0, 0, size.x - 20, size.y - 60))
    planDisplayer.showStats = 0

    sellButton = sellTab:createButton(Rect(0, size.y - 40, 150, size.y), "Sell Ship" % _t, "onSellButtonPressed")
    sellWarningLabel = sellTab:createLabel(vec2(200, size.y - 30), "Warning! You will not get refunds for crews or turrets!" % _t, 15)
    sellWarningLabel.color = ColorRGB(1, 1, 0)

    -- create a tab for dismantling turrets
    local turretTab = tabbedWindow:createTab("Turret Dismantling /*UI Tab title*/"%_t, "data/textures/icons/recycle-turret.png", "Dismantle turrets into goods"%_t)

    local vsplit = UIHorizontalSplitter(Rect(turretTab.size), 10, 0, 0.17)
    inventory = turretTab:createInventorySelection(vsplit.bottom, 10)

    inventory.onSelectedFunction = "onTurretSelected"
    inventory.onDeselectedFunction = "onTurretDeselected"

    local lister = UIVerticalLister(vsplit.top, 10, 0)
    scrapButton = turretTab:createButton(Rect(), "Dismantle"%_t, "onDismantleTurretPressed")
    lister:placeElementTop(scrapButton)
    scrapButton.active = false
    scrapButton.width = 300

    turretTab:createFrame(lister.rect)

    lister:setMargin(10, 10, 10, 10)

    local hlister = UIHorizontalLister(lister.rect, 10, 10)

    for i = 1, 10 do
        local rect = hlister:nextRect(30)
        rect.height = rect.width

        local pic = turretTab:createPicture(rect, "data/textures/icons/rocket.png")
        pic:hide()
        pic.isIcon = true

        table.insert(goodsLabels, {icon = pic})

    end

    Scrapyard.createSoloTab()

    if Player().allianceIndex then
        Scrapyard.createAllianceTab()
    end
end
function Scrapyard.updatePrice(slider)
    for i, group in pairs(uiGroups) do
        if group.durationSlider.index == slider.index then
            local buyer = Player()
            if group.type == typeAlliance then
                buyer = Alliance()
            end

            local base, reputation, bulk, total = Scrapyard.getLicensePrice(buyer, slider.value, group.type)
            group.basePricelabel.caption = "$${money}" % _t % { money = createMonetaryString(base) }
            group.reputationDiscountlabel.caption = "$${money}" % _t % { money = createMonetaryString(reputation) }
            group.bulkDiscountlabel.caption = "$${money}" % _t % { money = createMonetaryString(bulk) }
            group.totalPricelabel.caption = "$${money}" % _t % { money = createMonetaryString(total) }

            group.licenseDurationlabel.caption = "${time}" % _t % { time = createReadableTimeString(group.durationSlider.value * 60) }
        end
    end
end
function Scrapyard.updateClient(timeStep)
    local soloLifetime = (currentSoloExp >= modConfig.lifetimeExpRequired)
    local allianceLifetime = (currentAllianceExp >= modConfig.lifetimeExpRequired)
    local hasAlliance = false
    if Player().allianceIndex then
        hasAlliance = true
    end

    if not soloLifetime then
        soloLicenseDuration = soloLicenseDuration - timeStep
    end
    if not allianceLifetime and hasAlliance then
        allianceLicenseDuration = allianceLicenseDuration - timeStep
    end
    if visible then
        if soloLifetime then
            currentSoloLicenseDurationLabel.caption = "Never (lifetime license)" % _t
        else
            if soloLicenseDuration > 0 then
                currentSoloLicenseDurationLabel.caption = "${time}" % _t % { time = createReadableTimeString(soloLicenseDuration) }
            else
                currentSoloLicenseDurationLabel.caption = "No license found." % _t
            end
        end

        if hasAlliance then
            if allianceLifetime then
                currentAllianceLicenseDurationLabel.caption = "Never (lifetime license)" % _t
            else
                if allianceLicenseDuration > 0 then
                    currentAllianceLicenseDurationLabel.caption = "${time}" % _t % { time = createReadableTimeString(allianceLicenseDuration) }
                else
                    currentAllianceLicenseDurationLabel.caption = "No license found." % _t
                end
            end
        end

        Scrapyard.getCurrentExperience()
        if soloLifetimeStatusBar then -- solo leveling towards lifetime
            local currentReputation = Player():getRelations(Entity().factionIndex)

            local description
            local color

            if currentReputation >= modConfig.lifetimeRepRequired or soloLifetime then
                description = createMonetaryString(currentSoloExp) .. '/' .. createMonetaryString(modConfig.lifetimeExpRequired)
                color = ColorRGB(0.25, 1, 0.25)
            else
                description = createMonetaryString(currentSoloExp) .. '/' .. createMonetaryString(modConfig.lifetimeExpRequired) .. ' [Reputation to low]'
                color = ColorRGB(0.25, 0.25, 0.25)
            end
            soloLifetimeStatusBar:setValue(currentSoloExp, description, color)
        end

        if allianceLifetimeStatusBar then -- alliance leveling towards lifetime
            local currentReputation = Alliance():getRelations(Entity().factionIndex)

            local description
            local color

            if currentReputation >= modConfig.lifetimeRepRequired or allianceLifetime then
                description = createMonetaryString(currentAllianceExp) .. '/' .. createMonetaryString(modConfig.lifetimeExpRequired)
                color = ColorRGB(0.25, 1, 0.25)
            else
                description = createMonetaryString(currentAllianceExp) .. '/' .. createMonetaryString(modConfig.lifetimeExpRequired) .. ' [Reputation to low]'
                color = ColorRGB(0.25, 0.25, 0.25)
            end
            allianceLifetimeStatusBar:setValue(currentAllianceExp, description, color)
        end
    end
end
function Scrapyard.setLicenseDuration(soloDuration, allianceDuration)
    soloLicenseDuration = soloDuration or 0
    allianceLicenseDuration = allianceDuration or 0
end
function Scrapyard.getLicensePrice(orderingFaction, minutes, type)
    local basePrice = round(minutes * modConfig.pricePerMinute * Balancing_GetSectorRichnessFactor(Sector():getCoordinates()))
    if type == typeAlliance then
        basePrice = round(modConfig.alliancePriceFactor * basePrice)
    end

    local currentReputation = orderingFaction:getRelations(Faction().index)
    local reputationDiscountFactor = math.floor(currentReputation / 10000 + 1) * 0.01
    if type == typeAlliance then
        reputationDiscountFactor = reputationDiscountFactor * 0.85 -- alliance reputation is easier to obtain so less discount
    end
    local reputationDiscount = round(basePrice * reputationDiscountFactor);

    local bulkDiscountFactor = 0
    if minutes > 10 then bulkDiscountFactor = 0.01 end
    if minutes > 45 then bulkDiscountFactor = 0.02 end
    if minutes > 90 then bulkDiscountFactor = 0.06 end
    if minutes > 120 then bulkDiscountFactor = 0.09 end
    local bulkDiscount = round(basePrice * bulkDiscountFactor)

    local totalPrice = round(basePrice - reputationDiscount - bulkDiscount)

    return basePrice, reputationDiscount, bulkDiscount, totalPrice
end
function Scrapyard.buyLicense(duration, type)
    local buyer = Player(callingPlayer)
    local player = Player(callingPlayer)
    local ship

    if type == typeAlliance and player.allianceIndex then
        buyer = Alliance(player.allianceIndex)
    end

    if not buyer then return end
    local station = Entity()

    local maxDuration = Scrapyard.getMaxLicenseDuration(player)
    local currentDuration = licenses[buyer.index] or 0

    -- check if we would go beyond maximum for current reputation level
    if ((currentDuration + duration) > maxDuration) then
        Scrapyard.notifyFaction(buyer.index, 0, string.format("Transaction would exceed maximum duration. Adjusting your order."), station.title)
        duration = round(maxDuration - currentDuration)
        -- minimum transaction = 5 minutes
        if (duration < 300) then duration = 300 end
    end

    local base, reputation, bulk, total = Scrapyard.getLicensePrice(buyer, duration / 60, type) -- minutes!

    local canPay, msg, args = buyer:canPay(total)
    if not canPay then
        Scrapyard.notifyFaction(buyer.index, 1, string.format(msg, unpack(args)), station.title)
        return;
    end

    buyer:pay(total)

    -- sanity check
    if not licenses[buyer.index] then licenses[buyer.index] = 0 end

    -- register player's license
    if (licenses[buyer.index] + duration > maxDuration) then
        -- cap at maximum duration
        licenses[buyer.index] = maxDuration
    else
        licenses[buyer.index] = licenses[buyer.index] + duration
    end

    -- send a message as response
    local x,y = Sector():getCoordinates()
    local minutes = round(duration / 60)

    Scrapyard.notifyFaction(buyer.index, 0, string.format("\\s(%i:%i) You bought a %i minutes salvaging license extension.", x, y, minutes), station.title)
    Scrapyard.notifyFaction(player.index, 0, string.format("%s cannot be held reliable for any damage to ships or deaths caused by salvaging.", Faction().name), station.title)

    Scrapyard.sendLicenseDuration()
end
function Scrapyard.sendLicenseDuration()

    local player = Player(callingPlayer)
    local alliance
    if player.allianceIndex then
        alliance = Alliance(player.allianceIndex)
    end

    local soloDuration = 0
    if player then
        soloDuration = licenses[player.index]
    end

    local allianceDuration = 0
    if alliance then
        allianceDuration = licenses[alliance.index]
    end

    invokeClientFunction(player, "setLicenseDuration", soloDuration, allianceDuration)
end
function Scrapyard.onHullHit(objectIndex, block, shootingCraftIndex, damage, position)
    local object = Entity(objectIndex)
    if object and object.isWreckage then
        local shooter = Entity(shootingCraftIndex)
        if shooter then
            local faction = Faction(shooter.factionIndex)
            if not faction.isAIFaction then
                local pilot

                if faction.isAlliance then
                    for _, playerIndex in pairs({shooter:getPilotIndices()}) do
                        local player = Player(playerIndex)
                        if player then
                            pilot = player
                            break -- we only need the main pilot of this ship
                        end
                    end
                elseif faction.isPlayer then
                    pilot = Player(faction.index)
                end

                if licenses[faction.index] == nil and -- check alliance license
                        licenses[pilot.index] == nil -- check private license
                then
                    Scrapyard.unallowedDamaging(shooter, faction, damage)
                else
                    -- grant experience
                    Scrapyard.allowedDamaging(faction)
                end
            end
        end
    end
end
function Scrapyard.updateServer(timeStep)

    local station = Entity();

    if highTrafficSystem == true then
        station.title = "High Traffic Scrapyard"%_t
    end

    -- local advertisement
    newsBroadcastCounter = newsBroadcastCounter + timeStep
    if newsBroadcastCounter > modConfig.advertisementTimer then
        Sector():broadcastChatMessage(station.title, 0, "Get a salvaging license now and try your luck with the wreckages!"%_t)
        newsBroadcastCounter = 0
    end

    -- we need more minerals
    if highTrafficSystem and modConfig.enableRegen then
        highTrafficTimer = highTrafficTimer + timeStep
        if highTrafficTimer >= modConfig.highTrafficSpawntime * 60 then
            -- spawn new ship
            if station then
                station:addScript(basePath .. '/scripts/events/ScrapyardPlus', 'high-traffic')
            end
            highTrafficTimer = 0
        end
    end

    -- let's wreak some havoc
    disasterTimer = disasterTimer + timeStep
    if disasterTimer >= modConfig.disasterSpawnTime * 60 and modConfig.enableDisasters then
        local areWeInTrouble = math.random()
        -- maybe?!
        if station and areWeInTrouble <= modConfig.disasterChance then
            station:addScript(basePath .. '/scripts/events/ScrapyardPlus', 'disaster')
        end
        disasterTimer = 0
    end

    if not illegalActions then illegalActions = {} end
    for factionIndex, actions in pairs(illegalActions) do

        actions = actions - 1

        if actions <= 0 then
            illegalActions[factionIndex] = nil
        else
            illegalActions[factionIndex] = actions
        end
    end

    if legalActions == nil then
        legalActions = {}
    end

    if not licenses then licenses = {} end
    for factionIndex, time in pairs(licenses) do
        local faction = Faction(factionIndex)
        if not faction then return end

        -- check for lifetime reached
        local experience = Scrapyard.loadExperience(factionIndex)
        local lifetimeReached = (experience[Faction().index] >= modConfig.lifetimeExpRequired)

        if lifetimeReached then
            if time < 3600 then -- lock time at 1 hr as 'lifetime'
                time = 3600
            end
        else
            time = time - timeStep
        end

        local here = false
        local licenseType

        if faction.isAlliance then
            faction = Alliance(factionIndex)
            licenseType = 'alliance'
        elseif faction.isPlayer then
            faction = Player(factionIndex)
            licenseType = 'personal'

            local px, py = faction:getSectorCoordinates()
            local sx, sy = Sector():getCoordinates()

            here = (px == sx and py == sy)
        end

        local doubleSend = false
        local msg

        -- warn player / alliance if time is running out
        if time + 1 > modConfig.expirationTimeFinal and time <= modConfig.expirationTimeFinal then
            if here then
                msg = "Your %s salvaging license will run out in %s."%_t
            else
                msg = "Your %s salvaging license in %s will run out in %s."%_t
            end
            doubleSend = true
        end

        if time + 1 > modConfig.expirationTimeCritical and time <= modConfig.expirationTimeCritical then
            if here then
                msg = "Your %s salvaging license will run out in %s. Renew it NOW and save yourself some trouble!"%_t
            else
                msg = "Your %s salvaging license in %s will run out in %s. Renew it NOW and save yourself some trouble!"%_t
            end
        end

        if time + 1 > modConfig.expirationTimeWarning and time <= modConfig.expirationTimeWarning then
            if here then
                msg = "Your %s salvaging license will run out in %s. Renew it immediately and save yourself some trouble!"%_t
            else
                msg = "Your %s salvaging license in %s will run out in %s. Renew it immediately and save yourself some trouble!"%_t
            end
        end

        if time + 1 > modConfig.expirationTimeNotice and time <= modConfig.expirationTimeNotice then
            if here then
                msg = "Your %s salvaging license will run out in %s. Don't forget to renew it in time!"%_t
            else
                msg = "Your %s salvaging license in %s will run out in %s. Don't forget to renew it in time!"%_t
            end
        end

        if time < 0 then
            licenses[factionIndex] = nil

            if here then
                msg = "Your %s salvaging license expired. You may no longer salvage in this area."%_t
            else
                msg = "Your %s salvaging license in %s expired. You may no longer salvage in this area."%_t
            end
        else
            licenses[factionIndex] = time
        end

        if msg then
            local coordinates
            local remaining
            local x, y = Sector():getCoordinates()
            coordinates = "${x}:${y}" % {x = x, y = y }
            remaining = round(time)

            if here then
                faction:sendChatMessage(station.title, 0, msg, licenseType, createReadableTimeString(remaining))
                if doubleSend then
                    faction:sendChatMessage(station.title, 2, msg, licenseType, createReadableTimeString(remaining))
                end
            else
                faction:sendChatMessage(station.title, 0, msg, licenseType, coordinates, createReadableTimeString(remaining))
                if doubleSend then
                    faction:sendChatMessage(station.title, 2, msg, licenseType, coordinates, createReadableTimeString(remaining))
                end
            end

        end
    end

end

-- ScrapyardPlus new functions
--- createSoloTab
-- Create all relevant UIElements for the solo-license tab
function Scrapyard.createSoloTab()
    -- create a second tab
    local licenseTab = tabbedWindow:createTab("Private /*UI Tab title*/" % _t, "", "Buy a personal salvaging license" % _t)
    local size = licenseTab.size -- not really required, all tabs have the same size

    local fontSize = 18
    local textField = licenseTab:createTextField(Rect(0, 0, size.x, 50), "You can buy a temporary salvaging license here. This license makes it legal to damage or mine wreckages in this sector." % _t)
    textField.padding = 7

    -- Duration
    licenseTab:createLabel(vec2(15, 65), "Duration" % _t, fontSize)
    local durationSlider = licenseTab:createSlider(Rect(125, 65, size.x - 15, 90), 5, 180, 35, "", "updatePrice");
    local licenseDurationlabel = licenseTab:createLabel(vec2(125, 65), "" % _t, fontSize)

    -- Price
    licenseTab:createLabel(vec2(15, 115), "Baseprice", fontSize)
    local basePricelabel = licenseTab:createLabel(vec2(size.x - 260, 115), "", fontSize)

    licenseTab:createLabel(vec2(15, 150), "Reputation Discount", fontSize)
    local reputationDiscountlabel = licenseTab:createLabel(vec2(size.x - 260, 150), "", fontSize)

    licenseTab:createLabel(vec2(15, 185), "Bulk Discount", fontSize)
    local bulkDiscountlabel = licenseTab:createLabel(vec2(size.x - 260, 185), "", fontSize)

    licenseTab:createLine(vec2(0, 215), vec2(size.x, 215))

    licenseTab:createLabel(vec2(15, 220), "Total", fontSize)
    local totalPricelabel = licenseTab:createLabel(vec2(size.x - 260, 220), "", fontSize)

    -- Buy Now!
    local buyButton = licenseTab:createButton(Rect(size.x - 210, 275, size.x - 10, 325), "Buy License" % _t, "onBuyLicenseButtonPressed")

    -- lifetime license (can be disabled in options)
    if modConfig.allowLifetime then
        licenseTab:createLabel(vec2(15, size.y - 110), "Progress towards lifetime license:", fontSize)
        soloLifetimeStatusBar = licenseTab:createStatisticsBar(Rect(15, size.y - 80, size.x - 15, size.y - 65), ColorRGB(1, 1, 1))
    end

    -- License Status
    licenseTab:createLine(vec2(0, size.y - 55), vec2(size.x, size.y - 55))
    licenseTab:createLabel(vec2(15, size.y - 50), "Current License expires in:", fontSize)
    currentSoloLicenseDurationLabel = licenseTab:createLabel(vec2(size.x - 360, size.y - 50), "", fontSize)
    licenseTab:createLabel(vec2(15, size.y - 25), "Maximum allowed duration:", fontSize)
    maxSoloLicenseDurationLabel = licenseTab:createLabel(vec2(size.x - 360, size.y - 25), "", fontSize)

    -- the magic of by-reference to the rescue :-)
    Scrapyard.initSoloTab(
        durationSlider,
        licenseDurationlabel,
        basePricelabel,
        reputationDiscountlabel,
        bulkDiscountlabel,
        totalPricelabel,
        soloLifetimeStatusBar,
        size
    )

    -- Save UIGroup
    table.insert(uiGroups, {
        type = typeSolo,
        durationSlider = durationSlider,
        licenseDurationlabel = licenseDurationlabel,
        basePricelabel = basePricelabel,
        reputationDiscountlabel = reputationDiscountlabel,
        bulkDiscountlabel = bulkDiscountlabel,
        totalPricelabel = totalPricelabel,
        lifetimeStatusBar = soloLifetimeStatusBar,
        buyButton = buyButton
    })
end

--- initSoloTab
-- Initialize the solo-license tab with default values
function Scrapyard.initSoloTab(durationSlider, licenseDurationlabel, basePricelabel, reputationDiscountlabel, bulkDiscountlabel, totalPricelabel, lifetimeStatusBar, size)
    -- Init values & properties
    durationSlider.value = 5
    durationSlider.showValue = false

    licenseDurationlabel.caption = "${time}" % _t % { time = createReadableTimeString(durationSlider.value * 60) }
    licenseDurationlabel.width = size.x - 140
    licenseDurationlabel.centered = true

    local base, reputation, bulk, total = Scrapyard.getLicensePrice(Player(), durationSlider.value)

    basePricelabel.setTopRightAligned(basePricelabel)
    basePricelabel.width = 250
    basePricelabel.caption = "$${money}" % _t % { money = createMonetaryString(base) }

    reputationDiscountlabel.setTopRightAligned(reputationDiscountlabel)
    reputationDiscountlabel.width = 250
    reputationDiscountlabel.caption = "$${money}" % _t % { money = createMonetaryString(reputation) }

    bulkDiscountlabel.setTopRightAligned(bulkDiscountlabel)
    bulkDiscountlabel.width = 250
    bulkDiscountlabel.caption = "$${money}" % _t % { money = createMonetaryString(bulk) }

    totalPricelabel.setTopRightAligned(totalPricelabel)
    totalPricelabel.width = 250
    totalPricelabel.caption = "$${money}" % _t % { money = createMonetaryString(total) }

    currentSoloLicenseDurationLabel.setTopRightAligned(currentSoloLicenseDurationLabel)
    currentSoloLicenseDurationLabel.width = 350

    maxSoloLicenseDurationLabel.caption = createReadableTimeString(Scrapyard.getMaxLicenseDuration(Player()))
    maxSoloLicenseDurationLabel.setTopRightAligned(maxSoloLicenseDurationLabel)
    maxSoloLicenseDurationLabel.width = 350

    if lifetimeStatusBar then
        lifetimeStatusBar:setRange(0, modConfig.lifetimeExpRequired)
    end
end

--- createAllianceTab
-- Create all relevant UIElements for the alliance-license tab
function Scrapyard.createAllianceTab()
    local allianceTab = tabbedWindow:createTab("Alliance /*UI Tab title*/" % _t, "", "Buy a salvaging license for your alliance" % _t)
    local size = allianceTab.size -- not really required, all tabs have the same size

    local fontSize = 18
    local textField = allianceTab:createTextField(Rect(0, 0, size.x, 50), "You can buy a temporary salvaging license for your whole alliance here. This license makes it legal to damage or mine wreckages in this sector." % _t)
    textField.padding = 7

    -- Duration
    allianceTab:createLabel(vec2(15, 65), "Duration" % _t, fontSize)
    local durationSlider = allianceTab:createSlider(Rect(125, 65, size.x - 15, 90), 5, 180, 35, "", "updatePrice");
    local licenseDurationlabel = allianceTab:createLabel(vec2(125, 65), "" % _t, fontSize)

    -- Price
    allianceTab:createLabel(vec2(15, 115), "Baseprice", fontSize)
    local basePricelabel = allianceTab:createLabel(vec2(size.x - 260, 115), "", fontSize)

    allianceTab:createLabel(vec2(15, 150), "Reputation Discount", fontSize)
    local reputationDiscountlabel = allianceTab:createLabel(vec2(size.x - 260, 150), "", fontSize)

    allianceTab:createLabel(vec2(15, 185), "Bulk Discount", fontSize)
    local bulkDiscountlabel = allianceTab:createLabel(vec2(size.x - 260, 185), "", fontSize)

    allianceTab:createLine(vec2(0, 215), vec2(size.x, 215))

    allianceTab:createLabel(vec2(15, 220), "Total", fontSize)
    local totalPricelabel = allianceTab:createLabel(vec2(size.x - 260, 220), "", fontSize)

    -- Buy Now!
    local buyButton = allianceTab:createButton(Rect(size.x - 210, 275, size.x - 10, 325), "Buy License" % _t, "onBuyLicenseButtonPressed")

    -- lifetime license (can be disabled in options)
    if modConfig.allowLifetime then
        allianceTab:createLabel(vec2(15, size.y - 110), "Progress towards lifetime license:", fontSize)
        allianceLifetimeStatusBar = allianceTab:createStatisticsBar(Rect(15, size.y - 80, size.x - 15, size.y - 65), ColorRGB(1, 1, 1))
    end

    -- License Status
    allianceTab:createLine(vec2(0, size.y - 55), vec2(size.x, size.y - 55))

    allianceTab:createLabel(vec2(15, size.y - 50), "Current License expires in:", fontSize)
    currentAllianceLicenseDurationLabel = allianceTab:createLabel(vec2(size.x - 360, size.y - 50), "", fontSize)

    allianceTab:createLabel(vec2(15, size.y - 25), "Maximum allowed duration:", fontSize)
    maxAllianceLicenseDurationLabel = allianceTab:createLabel(vec2(size.x - 360, size.y - 25), "", fontSize)

    Scrapyard.initAllianceTab(durationSlider, licenseDurationlabel, basePricelabel, reputationDiscountlabel, bulkDiscountlabel, totalPricelabel, allianceLifetimeStatusBar, size)

    -- Save UIGroup
    table.insert(uiGroups, {
        type = typeAlliance,
        durationSlider = durationSlider,
        licenseDurationlabel = licenseDurationlabel,
        basePricelabel = basePricelabel,
        reputationDiscountlabel = reputationDiscountlabel,
        bulkDiscountlabel = bulkDiscountlabel,
        totalPricelabel = totalPricelabel,
        lifetimeStatusBar = allianceLifetimeStatusBar,
        buyButton = buyButton
    })
end

--- initAllianceTab
-- Initialize the alliance-license tab with default values
function Scrapyard.initAllianceTab(durationSlider, licenseDurationlabel, basePricelabel, reputationDiscountlabel, bulkDiscountlabel, totalPricelabel, lifetimeStatusBar, size)
    durationSlider.value = 5
    durationSlider.showValue = false

    licenseDurationlabel.caption = "${time}" % _t % { time = createReadableTimeString(durationSlider.value * 60) }
    licenseDurationlabel.width = size.x - 140
    licenseDurationlabel.centered = true

    local base, reputation, bulk, total = Scrapyard.getLicensePrice(Player(), durationSlider.value, typeAlliance)

    basePricelabel.setTopRightAligned(basePricelabel)
    basePricelabel.width = 250
    basePricelabel.caption = "$${money}" % _t % { money = createMonetaryString(base) }

    reputationDiscountlabel.setTopRightAligned(reputationDiscountlabel)
    reputationDiscountlabel.width = 250
    reputationDiscountlabel.caption = "$${money}" % _t % { money = createMonetaryString(reputation) }

    bulkDiscountlabel.setTopRightAligned(bulkDiscountlabel)
    bulkDiscountlabel.width = 250
    bulkDiscountlabel.caption = "$${money}" % _t % { money = createMonetaryString(bulk) }

    totalPricelabel.setTopRightAligned(totalPricelabel)
    totalPricelabel.width = 250
    totalPricelabel.caption = "$${money}" % _t % { money = createMonetaryString(total) }

    currentAllianceLicenseDurationLabel.setTopRightAligned(currentAllianceLicenseDurationLabel)
    currentAllianceLicenseDurationLabel.width = 350

    maxAllianceLicenseDurationLabel.caption = createReadableTimeString(Scrapyard.getMaxLicenseDuration(Player()))
    maxAllianceLicenseDurationLabel.setTopRightAligned(maxAllianceLicenseDurationLabel)
    maxAllianceLicenseDurationLabel.width = 350

    if lifetimeStatusBar then
        lifetimeStatusBar:setRange(0, modConfig.lifetimeExpRequired)
    end
end

--- onBuyLicenseButtonPressed
-- Register a new license with the correct faction (player/alliance)
function Scrapyard.onBuyLicenseButtonPressed(button)
    for _, group in pairs(uiGroups) do
        -- find which button got pressed
        if group.buyButton.index == button.index then
            local player = Player()
            local alliance = player.allianceIndex
            invokeServerFunction("buyLicense", 60 * group.durationSlider.value, group.type)
        end
    end
end

--- checkLifetime
-- Load a player and see if he already earned a lifetime license for personal or alliance use
function Scrapyard.checkLifetime(playerIndex)
    local player = Player(playerIndex)
    local soloExperience = Scrapyard.loadExperience(player.index)
    if soloExperience[Faction().index] >= modConfig.lifetimeExpRequired then
        licenses[player.index] = 3600
    end

    local alliance = player.allianceIndex
    if alliance then
        local allianceExperience  = Scrapyard.loadExperience(alliance)
        if allianceExperience[Faction().index] >= modConfig.lifetimeExpRequired then
            licenses[alliance] = 3600
        end
    end
end
callable(Scrapyard, "checkLifetime")

--- getMaxLicenseDuration
-- Based on current reputation return the current maximum duration a player can accumulate
function Scrapyard.getMaxLicenseDuration(player)
    local currentReputation = player:getRelations(Faction().index)
    local reputationBonusFactor = math.floor(currentReputation / 10000)
    -- every 'level' gets us 30 minutes more max on top of our 3hrs base duration up to a total of 8hrs

    return (180 + (reputationBonusFactor * 30)) * 60
end

--- notifyFaction
-- Helper to notify all online players of given faction
function Scrapyard.notifyFaction(factionIndex, channel,  message, sender)
    
    local faction = Faction(factionIndex)
    if faction.isPlayer then
        Player(factionIndex):sendChatMessage(sender, channel, message);
    else
        local onlinePlayers = {Server():getOnlinePlayers() }
        for _,player in pairs(onlinePlayers) do
            if player.allianceIndex == factionIndex then
                player:sendChatMessage(sender, channel, message);
            end
        end
    end
end

--- calculateNewExperience
-- Based on the current experience return how much a player/alliance will earn
function Scrapyard.calculateNewExperience(currentExp)
    local experience = 0

    experience = math.floor((modConfig.lifetimeExpRequired - currentExp) / 200 * modConfig.lifetimeExpFactor) + modConfig.lifetimeExpBaseline

    return experience
end

--- getCurrentExperience
-- Trigger the server to send the current experience to the client
function Scrapyard.getCurrentExperience()
    invokeServerFunction('sendCurrentExperience')
end

--- sendCurrentExperience
-- Send the current experience to the client
function Scrapyard.sendCurrentExperience()
    local player = Player(callingPlayer)
    local alliance
    if player.allianceIndex then
        alliance = Alliance(player.allianceIndex)
    end

    local playerExperience = Scrapyard.loadExperience(player.index)

    local allianceExperience
    if alliance then
        allianceExperience = Scrapyard.loadExperience(alliance.index)
    else
        allianceExperience = {}
        allianceExperience[Faction().index] = 0
    end

    invokeClientFunction(Player(callingPlayer), "setCurrentExperience",  playerExperience[Faction().index], allianceExperience[Faction().index])
end
callable(Scrapyard, "sendCurrentExperience")

--- loadExperience
-- Deserialize load and sanity-check current experience from given faction
function Scrapyard.loadExperience(factionIndex)
    local faction = Faction(factionIndex)
    local serialized = faction:getValue(MODULE .. FS .. 'experience')
    if serialized ~= nil then
        experience = loadstring(serialized)()
        if type(experience) ~= 'table' then
            experience = {}
        end
    else
        experience = {}
    end

    if experience[Faction().index] == nil then
        experience[Faction().index] = 0
    end

    return experience
end

--- setCurrentExperience
-- Store the received experience from the server at the client
function Scrapyard.setCurrentExperience(soloExp, allianceExp)
    currentSoloExp = soloExp or 0
    currentAllianceExp = allianceExp or 0
end

--- allowedDamaging
-- Called when a player/alliance is salvaging with a valid license
function Scrapyard.allowedDamaging(faction)
    local actions = legalActions[faction.index]
    local scrapyardFaction = Faction()
    if actions == nil then
        actions = 0
    end

    actions = actions + 1
    if actions >= modConfig.lifetimeExpTicks then
        local reputation = faction:getRelations(scrapyardFaction.index)
        if reputation >= modConfig.lifetimeRepRequired then
            local experience = Scrapyard.loadExperience(faction.index)
            local current = experience[scrapyardFaction.index]
            local newExp
            if current < modConfig.lifetimeExpRequired then
                newExp = Scrapyard.calculateNewExperience(current)
                if faction.isAlliance then
                    newExp =  math.floor(newExp * modConfig.lifetimeAllianceFactor)
                end
                if current + newExp > modConfig.lifetimeExpRequired then
                    experience[scrapyardFaction.index] = modConfig.lifetimeExpRequired
                    if faction.isAlliance then
                        Alliance(faction.index):sendChatMessage(Entity().title, 0, 'Congratulations! You reached lifetime status with our faction!')
                        Alliance(faction.index):sendChatMessage(Entity().title, 2, 'Lifetime license activated!')
                    elseif faction.isPlayer then
                        Player(faction.index):sendChatMessage(Entity().title, 0, 'Congratulations! You reached lifetime status with our faction!')
                        Player(faction.index):sendChatMessage(Entity().title, 2, 'Lifetime license activated!')
                    end
                else
                    experience[scrapyardFaction.index] = current + newExp
                end

                -- only setValue if nessecary
                faction:setValue(MODULE .. FS .. 'experience', serialize(experience))
            else
                newExp = 0
            end

            currentExp = experience[scrapyardFaction.index]
        end

        actions = 0

    end
    legalActions[faction.index] = actions
end
