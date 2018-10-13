describe("ModInfo", function()
    setup(function()
        -- time to get our modinfo object
        mod = require("../mods/ScrapyardPlus/mod")
    end)

    describe("should contain relevant information:", function()
        it("modname", function()
            assert.is_string(mod.name)
        end)

        it("author", function()
            assert.is_string(mod.author)
        end)

        it("homepage", function()
            assert.is_string(mod.homepage)
        end)

        it("tags", function()
            assert.is_table(mod.tags)
        end)

        it("version information", function()
            assert.is_table(mod.version)
            assert.is_number(mod.version.major)
            assert.is_number(mod.version.minor)
            assert.is_number(mod.version.patch)
            assert.is_function(mod.version.string)
            assert.is_string(mod.version.string())
            assert.is_equal(mod.version.string(), mod.version.major .. '.' .. mod.version.minor .. '.' .. mod.version.patch)
        end)
    end)
end)