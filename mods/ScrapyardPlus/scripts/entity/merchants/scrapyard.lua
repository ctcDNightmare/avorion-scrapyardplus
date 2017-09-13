package.path = package.path .. ";data/scripts/lib/?.lua"
require("galaxy")
require("utility")
require("faction")
require("randomext")
require("stringutility")
local Dialog = require("dialogutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Scrapyard
Scrapyard = {}

-- helpers
function NicerNumbers(n) -- http://lua-users.org/wiki/FormattingNumbers // credit http://richard.warburton.it
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1.'):reverse()) .. right
end

-- server
local licenses = {}
local illegalActions = {}
local newsBroadcastCounter = 0

-- client
local tabbedWindow = 0
local planDisplayer = 0
local sellButton = 0
local sellWarningLabel = 0
local currentLicenseDurationLabel
local maxLicenseDurationLabel
local licenseDuration = 0
local uiMoneyValue = 0
local visible = false
local uiGroups = {}

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function Scrapyard.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, -10000)
end

function Scrapyard.restore(data)
    -- clear earlier data
    licenses = data.licenses
    illegalActions = data.illegalActions
end

function Scrapyard.secure()
    -- save licenses
    local data = {}
    data.licenses = licenses
    data.illegalActions = illegalActions

    return data
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function Scrapyard.initialize()

    if onServer() then
        Sector():registerCallback("onHullHit", "onHullHit")

        local station = Entity()
        if station.title == "" then
            station.title = "Scrapyard" % _t
        end
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/scrapyard_fat.png"
        InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())
    end
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

    -- create a second tab
    local licenseTab = tabbedWindow:createTab("Salvaging /*UI Tab title*/" % _t, "", "Buy a salvaging license" % _t)
    size = licenseTab.size -- not really required, all tabs have the same size

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
    currentLicenseDurationLabel = licenseTab:createLabel(vec2(size.x - 360, size.y - 50), "", fontSize)

    licenseTab:createLabel(vec2(15, size.y - 25), "Maximum allowed duration:", fontSize)
    maxLicenseDurationLabel = licenseTab:createLabel(vec2(size.x - 360, size.y - 25), "", fontSize)

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

    currentLicenseDurationLabel.setTopRightAligned(currentLicenseDurationLabel)
    currentLicenseDurationLabel.width = 350

    maxLicenseDurationLabel.caption = createReadableTimeString(Scrapyard.getMaxLicenseDuration(Player()))
    maxLicenseDurationLabel.setTopRightAligned(maxLicenseDurationLabel)
    maxLicenseDurationLabel.width = 350

    -- Save UIGroup
    table.insert(uiGroups, {
        durationSlider = durationSlider,
        licenseDurationlabel = licenseDurationlabel,
        basePricelabel = basePricelabel,
        reputationDiscountlabel = reputationDiscountlabel,
        bulkDiscountlabel = bulkDiscountlabel,
        totalPricelabel = totalPricelabel,
        buyButton = buyButton
    })
end

-- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
function Scrapyard.renderUI()
    if tabbedWindow:getActiveTab().name == "Sell Ship" % _t then
        renderPrices(planDisplayer.lower + 20, "Ship Value:" % _t, uiMoneyValue, nil)
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

-- this function gets called every time the window is closed on the client
function Scrapyard.onCloseWindow()
    local station = Entity()
    displayChatMessage("Please, do come again." % _t, station.title, 0)

    visible = false
end

function Scrapyard.onSellButtonPressed()
    invokeServerFunction("sellCraft")
end

function Scrapyard.onBuyLicenseButtonPressed(button)
    for _, group in pairs(uiGroups) do
        -- find which button got pressed
        if group.buyButton.index == button.index then
            invokeServerFunction("buyLicense", 60 * group.durationSlider.value)
        end
    end
end

function Scrapyard.updatePrice(slider)
    for i, group in pairs(uiGroups) do
        if group.durationSlider.index == slider.index then
            local base, reputation, bulk, total = Scrapyard.getLicensePrice(Player(), slider.value)

            group.basePricelabel.caption = "$${money}" % _t % { money = NicerNumbers(base) }
            group.reputationDiscountlabel.caption = "$${money}" % _t % { money = NicerNumbers(reputation) }
            group.bulkDiscountlabel.caption = "$${money}" % _t % { money = NicerNumbers(bulk) }
            group.totalPricelabel.caption = "$${money}" % _t % { money = NicerNumbers(total) }

            group.licenseDurationlabel.caption = "${time}" % _t % { time = createReadableTimeString(group.durationSlider.value * 60) }
        end
    end
end

-- this function gets called once each frame, on client only
function Scrapyard.getUpdateInterval()
    return 1
end

function Scrapyard.updateClient(timeStep)
    licenseDuration = licenseDuration - timeStep
    if visible then
        if licenseDuration > 0 then
            currentLicenseDurationLabel.caption = "${time}" % _t % { time = createReadableTimeString(licenseDuration) }
        else
            currentLicenseDurationLabel.caption = "No license found." % _t
        end
    end
end

function Scrapyard.transactionComplete()
    ScriptUI():stopInteraction()
end

function Scrapyard.getLicenseDuration()
    invokeServerFunction("sendLicenseDuration")
end

function Scrapyard.setLicenseDuration(duration)
    licenseDuration = duration
end

-- this function gets called once each frame, on client and server
--function update(timeStep)
--
--end

function Scrapyard.getLicensePrice(orderingFaction, minutes)

    local basePrice = round(minutes * 150 * (1.0 + GetFee(Faction(), orderingFaction)) * Balancing_GetSectorRichnessFactor(Sector():getCoordinates()))

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

        if time + 1 > 20 and time <= 20 then
            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license will run out in 20 seconds." % _t);
            Player(playerIndex):sendChatMessage(station.title, 2, "Your salvaging license will run out in 20 seconds." % _t);
        end

        if time + 1 > 30 and time <= 30 then
            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license will run out in 30 seconds. Renew it and save yourself some trouble!" % _t);
        end

        if time + 1 > 60 and time <= 60 then
            Player(playerIndex):sendChatMessage(station.title, 0, "Your salvaging license will run out in 60 seconds. Renew it NOW and save yourself some trouble!" % _t);
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

function Scrapyard.sellCraft()
    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.ModifyCrafts, AlliancePrivilege.SpendResources)
    if not buyer then return end

    -- don't allow selling drones, would be an infinite income source
    if ship.isDrone then return end

    -- Create Wreckage
    local position = ship.position
    local plan = ship:getPlan();

    -- remove the old craft
    Sector():deleteEntity(ship)

    -- create a wreckage in its place
    local wreckageIndex = Sector():createWreckage(plan, position)

    local moneyValue = Scrapyard.getShipValue(plan)
    buyer:receive(moneyValue)

    invokeClientFunction(player, "transactionComplete")
end

function Scrapyard.getShipValue(plan)
    local sum = plan:getMoneyValue()
    local resourceValue = { plan:getResourceValue() }

    for i, v in pairs(resourceValue) do
        sum = sum + Material(i - 1).costFactor * v * 10;
    end

    -- players only get money, and not even the full value.
    -- This is to avoid exploiting the scrapyard functionality by buying and then selling ships
    return sum * 0.75
end

function Scrapyard.getMaxLicenseDuration(player)
    local currentReputation = player:getRelations(Faction().index)
    local reputationBonusFactor = math.floor(currentReputation / 10000) + 1
    -- every 'level' gets us 30 minutes more max on top of our 3hrs base duration up to a total of 8hrs
    return (180 + (reputationBonusFactor * 30)) * 60
end

function Scrapyard.buyLicense(duration)
    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end
    local station = Entity()

    local maxDuration = Scrapyard.getMaxLicenseDuration(player)
    local currentDuration = licenses[buyer.index]

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
    local duration = licenses[callingPlayer]

    if duration ~= nil then
        invokeClientFunction(Player(callingPlayer), "setLicenseDuration", duration)
    end
end

function Scrapyard.onHullHit(objectIndex, block, shootingCraftIndex, damage, position)
    local object = Entity(objectIndex)

    if object.isWreckage then
        local shooter = Entity(shootingCraftIndex)
        if shooter then
            local faction = Faction(shooter.factionIndex)
            if not faction.isAIFaction and licenses[faction.index] == nil then
                Scrapyard.unallowedDamaging(shooter, faction, damage)
            end
        end
    end
end

function Scrapyard.unallowedDamaging(shooter, faction, damage)

    local pilots = {}

    if faction.isAlliance then
        for _, playerIndex in pairs({ shooter:getPilotIndices() }) do
            local player = Player(playerIndex)

            if player then
                table.insert(pilots, player)
            end
        end

    elseif faction.isPlayer then
        table.insert(pilots, Player(faction.index))
    end

    local station = Entity()

    local actions = illegalActions[faction.index]
    if actions == nil then
        actions = 0
    end

    newActions = actions + damage

    for _, player in pairs(pilots) do
        if actions < 10 and newActions >= 10 then
            player:sendChatMessage(station.title, 0, "Salvaging or damaging wreckages in this sector is illegal. Please buy a salvaging license." % _t);
            player:sendChatMessage(station.title, 2, "You need a salvaging license for this sector." % _t);
        end

        if actions < 200 and newActions >= 200 then
            player:sendChatMessage(station.title, 0, "Salvaging wreckages in this sector is forbidden. Please buy a salvaging license." % _t);
            player:sendChatMessage(station.title, 2, "You need a salvaging license for this sector." % _t);
        end

        if actions < 500 and newActions >= 500 then
            player:sendChatMessage(station.title, 0, "Wreckages in this sector are the property of %s. Please buy a salvaging license." % _t, Faction().name);
            player:sendChatMessage(station.title, 2, "You need a salvaging license for this sector." % _t);
        end

        if actions < 1000 and newActions >= 1000 then
            player:sendChatMessage(station.title, 0, "Illegal salvaging will be punished by destruction. Buy a salvaging license or there will be consequences." % _t);
            player:sendChatMessage(station.title, 2, "You need a salvaging license for this sector." % _t);
        end

        if actions < 1500 and newActions >= 1500 then
            player:sendChatMessage(station.title, 0, "This is your last warning. If you do not stop salvaging without a license, you will be destroyed." % _t);
            player:sendChatMessage(station.title, 2, "You need a salvaging license for this sector." % _t);
        end

        if actions < 2000 and newActions >= 2000 then
            player:sendChatMessage(station.title, 0, "You have been warned. You will be considered an enemy of %s if you do not stop your illegal activities." % _t, Faction().name);
            player:sendChatMessage(station.title, 2, "You need a salvaging license for this sector." % _t);
        end
    end

    if newActions > 5 then
        Galaxy():changeFactionRelations(Faction(), faction, -newActions / 100)
    end

    illegalActions[faction.index] = newActions
end


