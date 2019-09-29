describe("ScrapyardPlus", function()
    setup(function()
        package.loaded["galaxy"] = setmetatable({}, {})
        package.loaded["utility"] = setmetatable({}, {})
        package.loaded["faction"] = setmetatable({}, {})
        package.loaded["randomext"] = setmetatable({}, {})
        package.loaded["stringutility"] = setmetatable({}, {})
        package.loaded["dialogutility"] = setmetatable({}, {})


        local function hook_func(_, key)
            print('Accessing "lib" attribute '..tostring(key))
            -- other stuff you might want to do in the hook
            return lib[key]
        end

        package.loaded["lib"] = setmetatable({}, {__index = hook_func})


        -- time to get our Scrapyard object
        require("../data/scripts/entity/merchants/scrapyard")
    end)

    describe("should support vanilla", function()
        it("by providing interactionPossible()", function()
            assert.is_function(Scrapyard.interactionPossible)
        end)

        it("by providing renderUI()", function()
            assert.is_function(Scrapyard.renderUI)
        end)

        it("by providing onCloseWindow()", function()
            assert.is_function(Scrapyard.onCloseWindow)
        end)

        it("by providing getUpdateInterval()", function()
            assert.is_function(Scrapyard.getUpdateInterval)
        end)

        it("by providing getLicenseDuration()", function()
            assert.is_function(Scrapyard.getLicenseDuration)
        end)

        it("by providing sellCraft()", function()
            assert.is_function(Scrapyard.sellCraft)
        end)

        it("by providing getShipValue()", function()
            assert.is_function(Scrapyard.getShipValue)
        end)

        it("by providing transactionComplete()", function()
            assert.is_function(Scrapyard.transactionComplete)
        end)

        it("by providing unallowedDamaging()", function()
            assert.is_function(Scrapyard.unallowedDamaging)
        end)
    end)
end)