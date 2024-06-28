local net = require("@lune/net")
local fs = require("@lune/fs")

local function getCrop(name)
    local bundle = fs.readFile("data/crops/" .. name .. "/init.luau")
    local json = net.jsonDecode(fs.readFile("data/crops/" .. name .. "/farmer.json"))
    return {
        bundle = bundle,
        json = json
    }
end

return function(req, res)
    local name = req.query.name

    name = string.lower(name)

    if not name then
        res.setStatus(400)
        res.json({
            status = "error",
            message = "Missing package to fetch"
        })
        return
    end

    local result = getCrop(name)

    if result then
        res.json(result)
    else
        res.setStatus(404)
        res.json({
            status = "error",
            message = "failed to fetch crop"
        })
    end
end