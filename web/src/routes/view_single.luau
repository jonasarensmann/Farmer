local surrealdb = require("../surrealdb")
local net = require("@lune/net")

local aurora = require("../../crops/aurora")

return function(req, res)
    if req.query.id then
        local result = surrealdb.getWithoutSignIn__CAUTION("crops", req.query.id)

        local body = net.jsonDecode(result.body)

        if result.statusCode ~= 200 then
            res.setStatus(result.statusCode)
            res.json({
                status = "error",
                error = body
            })
            return
        end

        local item = body[1].result[1]

        if not item then
            res.redirect("/view")
            return
        end

        local getOwnerResult = surrealdb.getWithoutSignIn__CAUTION("users", item.user)
        local owner = net.jsonDecode(getOwnerResult.body)[1].result[1].name

        local data = {
            name = aurora.escapeHtml(item.name),
            version = aurora.escapeHtml(item.version),
            license = aurora.escapeHtml(item.license),
            description = aurora.escapeHtml(item.description),  
            owner = aurora.escapeHtml(owner),              
        }

        if item.dependencies and #item.dependencies > 0 then
            for _,v in ipairs(item.dependencies) do
                data.deps = data.deps .. aurora.renderHtml("pages/components/listItem.html", {
                    name = aurora.escapeHtml(v.name),
                    version = aurora.escapeHtml(v.version),
                })
            end
        end

        if not data.deps then
            data.tableHidden = "None"
            data.deps = "No dependencies"
        end

        res.html("pages/index.html", {
            page = aurora.renderHtml("pages/view_single.html", data)
        })
    else
        res.redirect("/view")
    end
end