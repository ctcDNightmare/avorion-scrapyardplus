describe("ModInfo", function()
    setup(function()
        -- time to get our modinfo object
        require("../src/modinfo")
    end)

    describe("should contain relevant information:", function()
        it("name", function()
                    assert.is_string(meta.name)
        end)

        it("contact", function()
            assert.is_string(meta.contact)
        end)

        it("version information", function()
            assert.is_string(meta.version)
        end)
    end)
end)