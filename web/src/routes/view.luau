local surrealdb = require("../surrealdb")
local net = require("@lune/net")

local aurora = require("../../crops/aurora")

return function(req, res)
    local list = ""

    local result = surrealdb.getWithoutSignIn__CAUTION("crops")

    local body = net.jsonDecode(result.body)

    if result.statusCode ~= 200 then
        res.setStatus(result.statusCode)
        res.json({
            status = "error",
            error = body
        })
        return
    end

    local items = body[1].result

    for _, item in ipairs(items) do 
        list = list .. aurora.renderHtml("pages/components/listItem.html", {
            name = aurora.escapeHtml(item.name),
            version = aurora.escapeHtml(item.version),
            id = aurora.escapeHtml(item.id),
        })
    end

    res.html("pages/index.html", {
        page = aurora.renderHtml("pages/view.html", {
            list = list,
        }),
    })
end