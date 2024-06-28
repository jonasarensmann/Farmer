local surrealdb = require("../surrealdb")

local net = require("@lune/net")

return function(req, res)
    local cropName = req.query.name

    if not cropName then
        res.setStatus(400)
        res.json({
            status = "error",
            message = "Missing package to fetch"
        })
        return
    end

    local function escape(str: string)
        str = str:gsub('"', "&quot;")
        str = str:gsub("'", "&#39;")
        return str    
    end

    cropName = escape(cropName)

    local result = surrealdb.rawSQLAsViewer__CAUTION("SELECT * FROM crops WHERE name = '" .. cropName .. "'") 

    if result.statusCode ~= 200 then
        res.setStatus(result.statusCode)
        res.json({
            status = "error",
            error = result.body
        })
        return
    end

    local body = net.jsonDecode(result.body)

    if #body[1].result == 0 then
        res.setStatus(404)
        res.json({
            status = "error",
            message = "failed to fetch crop"
        })
        return
    end

    res.json(body[1].result[1])

end