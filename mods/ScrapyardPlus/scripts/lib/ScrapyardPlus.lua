-- namespace ScrapyardPlus
local ScrapyardPlus = {}

function ScrapyardPlus.nicerNumbers(n)
    -- http://lua-users.org/wiki/FormattingNumbers // credit http://richard.warburton.it
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1.'):reverse()) .. right
end

return ScrapyardPlus
