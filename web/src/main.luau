local aurora = require("../crops/aurora")
local fs = require("@lune/fs")
local net = require("@lune/net")
local surrealdb = require("surrealdb")

local upload = require("routes/upload")
local view = require("routes/view")
local view_single = require("routes/view_single")
local signup = require("routes/signup")
local signin = require("routes/signin")
local fetch = require("routes/fetch_crop")
local details = require("routes/details")

aurora.get("/", function(req, res)
    res.html("pages/index.html", {
        page = fs.readFile("pages/home.html"),
    })
end)
aurora.get("/view", view)
aurora.get("/view_single", view_single)
aurora.post("/upload", upload)
aurora.get("/fetch", fetch)
aurora.get("/details", details)
aurora.get("/signup", function(req, res)
    res.html("pages/index.html", {
        page = fs.readFile("pages/signup.html"),
    })
end)
aurora.post("/signup", signup)
aurora.get("/signin", function(req, res)
    res.html("pages/index.html", {
        page = fs.readFile("pages/signin.html"),
    })
end)
aurora.post("/signin", signin)
aurora.get("/status", function(req, res)
    local result = surrealdb.getStatus()

    if result.statusCode == 200 then
        res.json(net.jsonDecode(result.body))
    else
        res.setStatus(result.statusCode)
        res.json({
            status = "error",
            message = "failed to get status"
        })
    end
end)

aurora.get("/docs", function(req, res)
    res.html("pages/index.html", {
        page = fs.readFile("pages/docs/index.html"),
    })
end)

aurora.static("/static", "static")

aurora.createServer({
    port = 9498,
})
