local surrealdb = require("../surrealdb")
local net = require("@lune/net")

return function(req, res)
    local body = net.jsonDecode(req.body)
    local user = body.user
    local pass = body.pass

    user = string.lower(user)

    if not user or not pass then
        res.setStatus(400)
        res.json({
            status = "error",
            message = "Username and password are required"
        })
        return
    end

    local result = surrealdb.signIn(user, pass)

    if result.statusCode == 200 then
        res.json(net.jsonDecode(result.body))
    else
        res.setStatus(result.statusCode)
        res.json({
            status = "error",
            message = "failed to sign in"
        })
    end
end