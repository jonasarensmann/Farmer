local surrealdb = require("../surrealdb")
local net = require("@lune/net")

return function(req, res)
    local body = net.jsonDecode(req.body)
    local user = body.user
    local pass = body.pass

    user = string.lower(user)

    if #user < 3 or #user > 25 then 
        res.setStatus(400)
        res.json({
            status = "error",
            message = "Username must be between 3 and 25 characters"
        })
        return
    end

    if #pass < 8 or #pass > 25 then 
        res.setStatus(400)
        res.json({
            status = "error",
            message = "Password must be between 8 and 25 characters"
        })
        return
    end

    if not user or not pass then
        res.setStatus(400)
        res.json({
            status = "error",
            message = "Username and password are required"
        })
        return
    end

    local result = surrealdb.signUp(user, pass)

    if result.statusCode == 200 then
        res.json(net.jsonDecode(result.body))
    else
        res.setStatus(result.statusCode)
        res.json({
            status = "error",
            message = "failed to create user"
        })
    end
end