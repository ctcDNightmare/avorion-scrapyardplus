local mod = {}

mod.name = "ScrapyardPlus"
mod.author = "DNightmare"
mod.homepage = "https://github.com/ctcDNightmare/avorion-scrapyardplus"
mod.tags = { "scrapyard", "overhaul", "server", "client", "events", "lifetime-license" }
mod.version = {
    major=1, minor=4, patch = 0,
    string = function()
        return  mod.version.major .. '.' ..
                mod.version.minor .. '.' ..
                mod.version.patch
    end
}

return mod
