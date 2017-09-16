local basePath = "mods/ScrapyardPlus/"

-- helpers
function NicerNumbers(n) -- http://lua-users.org/wiki/FormattingNumbers // credit http://richard.warburton.it
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1.'):reverse()) .. right
end

-- constants
local typeAlliance = 'ALLIANCE'
local typeSolo = 'SOLO'

-- server
local licenses
local illegalActions
local newsBroadcastCounter

-- client
local tabbedWindow
local planDisplayer
local sellButton
local sellWarningLabel
local uiMoneyValue
local visible
local uiGroups = {}
local vanillaLicenseDuration

-- solo license
local currentSoloLicenseDurationLabel
local maxSoloLicenseDurationLabel
local soloLicenseDuration = 0
-- alliance license
local currentAllianceLicenseDurationLabel
local maxAllianceLicenseDurationLabel
local allianceLicenseDuration = 0

function Scrapyard.injectParent(locals)
    -- server
    licenses = locals.licenses
    illegalActions = locals.illegalActions
    newsBroadcastCounter = locals.newsBroadcastCounter
    -- client
    tabbedWindow = locals.tabbedWindow
    planDisplayer = locals.planDisplayer
    sellButton = locals.sellButton
    sellWarningLabel = locals.sellWarningLabel
    uiMoneyValue = locals.uiMoneyValue
    visible = locals.visible
    vanillaLicenseDuration = locals.licenseDuration

end

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

    licenseTab:createLine(vec2(15, 215), vec2(size.x - 15, 215))

    licenseTab:createLabel(vec2(15, 220), "Total", fontSize)
    local totalPricelabel = licenseTab:createLabel(vec2(size.x - 260, 220), "", fontSize)

    -- Buy Now!
    local buyButton = licenseTab:createButton(Rect(size.x - 210, 275, size.x - 10, 325), "Buy License" % _t, "onBuyLicenseButtonPressed")

    -- License Status
    licenseTab:createLine(vec2(15, size.y - 55), vec2(size.x - 15, size.y - 55))

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
        buyButton = buyButton
    })
end

function Scrapyard.initSoloTab(durationSlider, licenseDurationlabel, basePricelabel, reputationDiscountlabel, bulkDiscountlabel, totalPricelabel, size)
    -- Init values & properties
    durationSlider.value = 5
    durationSlider.showValue = false

    licenseDurationlabel.caption = "${time}" % _t % { time = createReadableTimeString(durationSlider.value * 60) }
    licenseDurationlabel.width = size.x - 140
    licenseDurationlabel.centered = true

    local base, reputation, bulk, total = Scrapyard.getLicensePrice(Player(), durationSlider.value)

    basePricelabel.setTopRightAligned(basePricelabel)
    basePricelabel.width = 250
    basePricelabel.caption = "$${money}" % _t % { money = NicerNumbers(base) }

    reputationDiscountlabel.setTopRightAligned(reputationDiscountlabel)
    reputationDiscountlabel.width = 250
    reputationDiscountlabel.caption = "$${money}" % _t % { money = NicerNumbers(reputation) }

    bulkDiscountlabel.setTopRightAligned(bulkDiscountlabel)
    bulkDiscountlabel.width = 250
    bulkDiscountlabel.caption = "$${money}" % _t % { money = NicerNumbers(bulk) }

    totalPricelabel.setTopRightAligned(totalPricelabel)
    totalPricelabel.width = 250
    totalPricelabel.caption = "$${money}" % _t % { money = NicerNumbers(total) }

    currentSoloLicenseDurationLabel.setTopRightAligned(currentSoloLicenseDurationLabel)
    currentSoloLicenseDurationLabel.width = 350

    maxSoloLicenseDurationLabel.caption = createReadableTimeString(Scrapyard.getMaxLicenseDuration(Player()))
    maxSoloLicenseDurationLabel.setTopRightAligned(maxSoloLicenseDurationLabel)
    maxSoloLicenseDurationLabel.width = 350
end

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

    allianceTab:createLine(vec2(15, 215), vec2(size.x - 15, 215))

    allianceTab:createLabel(vec2(15, 220), "Total", fontSize)
    local totalPricelabel = allianceTab:createLabel(vec2(size.x - 260, 220), "", fontSize)

    -- Buy Now!
    local buyButton = allianceTab:createButton(Rect(size.x - 210, 275, size.x - 10, 325), "Buy License" % _t, "onBuyLicenseButtonPressed")

    -- License Status
    allianceTab:createLine(vec2(15, size.y - 55), vec2(size.x - 15, size.y - 55))

    allianceTab:createLabel(vec2(15, size.y - 50), "Current License expires in:", fontSize)
    currentAllianceLicenseDurationLabel = allianceTab:createLabel(vec2(size.x - 360, size.y - 50), "", fontSize)

    allianceTab:createLabel(vec2(15, size.y - 25), "Maximum allowed duration:", fontSize)
    maxAllianceLicenseDurationLabel = allianceTab:createLabel(vec2(size.x - 360, size.y - 25), "", fontSize)

    Scrapyard.initAllianceTab(durationSlider, licenseDurationlabel, basePricelabel, reputationDiscountlabel, bulkDiscountlabel, totalPricelabel, size)

    -- Save UIGroup
    table.insert(uiGroups, {
        type = typeAlliance,
        durationSlider = durationSlider,
        licenseDurationlabel = licenseDurationlabel,
        basePricelabel = basePricelabel,
        reputationDiscountlabel = reputationDiscountlabel,
        bulkDiscountlabel = bulkDiscountlabel,
        totalPricelabel = totalPricelabel,
        buyButton = buyButton
    })
end

function Scrapyard.initAllianceTab(durationSlider, licenseDurationlabel, basePricelabel, reputationDiscountlabel, bulkDiscountlabel, totalPricelabel, size)
    durationSlider.value = 5
    durationSlider.showValue = false

    licenseDurationlabel.caption = "${time}" % _t % { time = createReadableTimeString(durationSlider.value * 60) }
    licenseDurationlabel.width = size.x - 140
    licenseDurationlabel.centered = true

    local base, reputation, bulk, total = Scrapyard.getLicensePrice(Player(), durationSlider.value)

    basePricelabel.setTopRightAligned(basePricelabel)
    basePricelabel.width = 250
    basePricelabel.caption = "$${money}" % _t % { money = NicerNumbers(base) }

    reputationDiscountlabel.setTopRightAligned(reputationDiscountlabel)
    reputationDiscountlabel.width = 250
    reputationDiscountlabel.caption = "$${money}" % _t % { money = NicerNumbers(reputation) }

    bulkDiscountlabel.setTopRightAligned(bulkDiscountlabel)
    bulkDiscountlabel.width = 250
    bulkDiscountlabel.caption = "$${money}" % _t % { money = NicerNumbers(bulk) }

    totalPricelabel.setTopRightAligned(totalPricelabel)
    totalPricelabel.width = 250
    totalPricelabel.caption = "$${money}" % _t % { money = NicerNumbers(total) }

    currentAllianceLicenseDurationLabel.setTopRightAligned(currentAllianceLicenseDurationLabel)
    currentAllianceLicenseDurationLabel.width = 350

    maxAllianceLicenseDurationLabel.caption = createReadableTimeString(Scrapyard.getMaxLicenseDuration(Player()))
    maxAllianceLicenseDurationLabel.setTopRightAligned(maxAllianceLicenseDurationLabel)
    maxAllianceLicenseDurationLabel.width = 350
end


-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
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
    local sellTab = tabbedWindow:createTab("Sell Ship" % _t, "", "Sell your ship to the scrapyard" % _t)
    size = sellTab.size

    planDisplayer = sellTab:createPlanDisplayer(Rect(0, 0, size.x - 20, size.y - 60))
    planDisplayer.showStats = 0

    sellButton = sellTab:createButton(Rect(0, size.y - 40, 150, size.y), "Sell Ship" % _t, "onSellButtonPressed")
    sellWarningLabel = sellTab:createLabel(vec2(200, size.y - 30), "Warning! You will not get refunds for crews or turrets!" % _t, 15)
    sellWarningLabel.color = ColorRGB(1, 1, 0)

    Scrapyard.createSoloTab()
    Scrapyard.createAllianceTab()

end

-- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
function Scrapyard.renderUI()
    if tabbedWindow:getActiveTab().name == "Sell Ship"%_t then
        renderPrices(planDisplayer.lower + 20, "Ship Value:"%_t, uiMoneyValue, nil)
    end
end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function Scrapyard.onShowWindow()
    local ship = Player().craft

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

    Scrapyard.getLicenseDuration()

    visible = true
end

function Scrapyard.onBuyLicenseButtonPressed(button)
    for _, group in pairs(uiGroups) do
        -- find which button got pressed
        if group.buyButton.index == button.index then
            local player = Player()
            local alliance = player.allianceIndex

            if alliance then
                player:sendChatMessage("Member of an alliance");
            else
                player:sendChatMessage("Solo player");
            end

            invokeServerFunction("buyLicense", 60 * group.durationSlider.value, group.type)
        end
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
            group.basePricelabel.caption = "$${money}" % _t % { money = NicerNumbers(base) }
            group.reputationDiscountlabel.caption = "$${money}" % _t % { money = NicerNumbers(reputation) }
            group.bulkDiscountlabel.caption = "$${money}" % _t % { money = NicerNumbers(bulk) }
            group.totalPricelabel.caption = "$${money}" % _t % { money = NicerNumbers(total) }

            group.licenseDurationlabel.caption = "${time}" % _t % { time = createReadableTimeString(group.durationSlider.value * 60) }
        end
    end
end

function Scrapyard.updateClient(timeStep)
    soloLicenseDuration = soloLicenseDuration - timeStep
    allianceLicenseDuration = allianceLicenseDuration - timeStep
    if visible then
        if soloLicenseDuration > 0 then
            currentSoloLicenseDurationLabel.caption = "${time}" % _t % { time = createReadableTimeString(soloLicenseDuration) }
        else
            currentSoloLicenseDurationLabel.caption = "No license found." % _t
        end
        if allianceLicenseDuration > 0 then
            currentAllianceLicenseDurationLabel.caption = "${time}" % _t % { time = createReadableTimeString(allianceLicenseDuration) }
        else
            currentAllianceLicenseDurationLabel.caption = "No license found." % _t
        end
    end
end

function Scrapyard.setLicenseDuration(soloDuration, allianceDuration)
    soloLicenseDuration = soloDuration or nil
    allianceLicenseDuration = allianceDuration or nil
end

function Scrapyard.getLicensePrice(orderingFaction, minutes, type)
    local basePrice = round(minutes * 150 * (1.0 + GetFee(Faction(), orderingFaction)) * Balancing_GetSectorRichnessFactor(Sector():getCoordinates()))
    if type == typeAlliance then
        basePrice = round(10 * minutes * 150 * (1.0 + GetFee(Faction(), orderingFaction)) * Balancing_GetSectorRichnessFactor(Sector():getCoordinates()))
    end

    local currentReputation = orderingFaction:getRelations(Faction().index)
    local reputationDiscountFactor = math.floor(currentReputation / 10000 + 1) * 0.01
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

-- this function gets called once each frame, on server only
function Scrapyard.updateServer(timeStep)

    local station = Entity();

    newsBroadcastCounter = newsBroadcastCounter + timeStep
    if newsBroadcastCounter > 60 then
        Sector():broadcastChatMessage(station.title, 0, "Get a salvaging license now and try your luck with the wreckages!" % _t)
        newsBroadcastCounter = 0
    end

    -- counter for update, this is only executed once per second to save performance.
    for playerIndex, actions in pairs(illegalActions) do

        actions = actions - 1

        if actions <= 0 then
            illegalActions[playerIndex] = nil
        else
            illegalActions[playerIndex] = actions
        end
    end

    for playerIndex, time in pairs(licenses) do

        time = time - timeStep

        -- warn player if his time is running out
        if time + 1 > 10 and time <= 10 then
            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license will run out in 10 seconds." % _t);
            Player(playerIndex):sendChatMessage(station.title, 2, "Your salvaging license will run out in 10 seconds." % _t);
        end

        if time + 1 > 30 and time <= 30 then
            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license will run out in 30 seconds. Renew it and save yourself some trouble!" % _t);
        end

        if time + 1 > 120 and time <= 120 then
            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license will run out in 2 Minutes. Renew it NOW and save yourself some trouble!" % _t);
        end

        if time + 1 > 300 and time <= 300 then
            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license will run out in 5 Minutes. Renew it NOW and save yourself some trouble!" % _t);
        end

        if time + 1 > 600 and time <= 600 then
            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license will run out in 10 minutes. Renew it immediately and save yourself some trouble!" % _t);
        end

        if time < 0 then
            licenses[playerIndex] = nil

            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license expired. You may no longer salvage in this area." % _t);
        else
            licenses[playerIndex] = time
        end
    end
end

function Scrapyard.getMaxLicenseDuration(player)
    local currentReputation = player:getRelations(Faction().index)
    local reputationBonusFactor = math.floor(currentReputation / 10000)
    -- every 'level' gets us 30 minutes more max on top of our 3hrs base duration up to a total of 8hrs
    return (180 + (reputationBonusFactor * 30)) * 60
end

function Scrapyard.buyLicense(duration, type)
    print(type)
    local buyer, _, player, alliance = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end
    local station = Entity()

    local maxDuration = Scrapyard.getMaxLicenseDuration(player)
    local currentDuration = licenses[buyer.index] or 0

    -- check if we would go beyond maximum for current reputation level
    if ((currentDuration + duration) > maxDuration) then
        player:sendChatMessage(station.title, 0, "Transaction would exceed maximum duration. Adjusting your order." % _t);
        duration = round(maxDuration - currentDuration)
        -- minimum transaction = 5 minutes
        if (duration < 300) then duration = 300 end
    end

    local base, reputation, bulk, total = Scrapyard.getLicensePrice(buyer, duration / 60) -- minutes!

    local canPay, msg, args = buyer:canPay(total)
    if not canPay then
        player:sendChatMessage(station.title, 1, msg, unpack(args));
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
    local minutes = round(duration / 60)
    player:sendChatMessage(station.title, 0, "You bought a %s minutes salvaging license extension." % _t, minutes);
    player:sendChatMessage(station.title, 0, "%s cannot be held reliable for any damage to ships or deaths caused by salvaging." % _t, Faction().name);
    Scrapyard.sendLicenseDuration()
end

function Scrapyard.sendLicenseDuration()

    local _, _, player, alliance = getInteractingFaction(callingPlayer)

    local soloDuration
    if player then
        soloDuration = licenses[player.index]
    end

    local allianceDuration
    if alliance then
        allianceDuration = licenses[alliance.index]
    end

    if duration ~= nil then
        invokeClientFunction(player, "setLicenseDuration", soloDuration, allianceDuration)
    end
end

function Scrapyard.onHullHit(objectIndex, block, shootingCraftIndex, damage, position)
    local object = Entity(objectIndex)

    if object.isWreckage then
        local shooter = Entity(shootingCraftIndex)
        if shooter then
            local faction = Faction(shooter.factionIndex)

            if faction.isAlliance then
                if  not faction.isAIFaction and
                        licenses[faction.index] == nil and -- check alliance license
                        licenses[Player(faction.index).index] == nil -- check personal license
                then
                    Scrapyard.unallowedDamaging(shooter, faction, damage)
                end
            end
        end
    end
end