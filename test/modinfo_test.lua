describe("meta", function()
    setup(function()
        -- time to get our meta object
        require("../src/modinfo")
    end)

    describe("should contain relevant information:", function()

        it("steam ID", function()
            assert.is_string(meta.id)
            assert.same("1875903108", meta.id)
        end)

        it("name", function()
            assert.is_string(meta.name)
            assert.same("ScrapyardPlus", meta.name)
        end)

        it("contact", function()
            assert.is_string(meta.contact)
            assert.same("https://www.avorion.net/forum/index.php/topic,3850.0.html", meta.contact)
        end)

        it("version information", function()
            assert.is_string(meta.version)
            assert.same("2.0.1", meta.version)
        end)
    end)
end)