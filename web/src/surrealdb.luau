local net = require("@lune/net")

local URL = "http://surrealdb:8000"
local surrealdb = {}

local function get(url, token)
    local headers = {
        ["Accept"] = "application/json",
        ["NS"] = "farmer",
        ["DB"] = "main"
    }

    if token then
        headers["Authorization"] = "Bearer " .. token
    end

    return net.request({
        method = "GET",
        url = URL .. url,
        headers = headers
    })
end

local function post(url, body, token)
    local headers = {
        ["Accept"] = "application/json",
        ["Content-Type"] = "application/json",
        ["NS"] = "farmer",
        ["DB"] = "main"
    }

    if token then
        headers["Authorization"] = "Bearer " .. token
    end

    return net.request({
        method = "POST",
        url = URL .. url,
        body = net.jsonEncode(body),
        headers = headers
    })
end

local function patch(url, body, token)
    local headers = {
        ["Accept"] = "application/json",
        ["Content-Type"] = "application/json",
        ["NS"] = "farmer",
        ["DB"] = "main"
    }

    if token then
        headers["Authorization"] = "Bearer " .. token
    end

    return net.request({
        method = "PATCH",
        url = URL .. url,
        body = net.jsonEncode(body),
        headers = headers
    })
end

local function del(url, token)
    local headers = {
        ["Accept"] = "application/json",
        ["NS"] = "farmer",
        ["DB"] = "main"
    }

    if token then
        headers["Authorization"] = "Bearer " .. token
    end

    return net.request({
        method = "DELETE",
        url = URL .. url,
        headers = headers
    })
end

surrealdb.getStatus = function()
    return get("/status")
end

surrealdb.getVersion = function()
    return get("/version").body
end

surrealdb.signUp = function(user, pass)
    local body = {
        name = user,
        pass = pass,
        ns = "farmer",
        sc = "users",
        db = "main"
    }
   
    return post("/signup", body)
end

surrealdb.signIn = function(user, pass)
    local body = {
        name = user,
        pass = pass,
        ns = "farmer",
        sc = "users",
        db = "main"
    }
   
    return post("/signin", body)
end

surrealdb.getRecords = function(tableName, token)
    return get("/key/" .. tableName, token)
end

surrealdb.getRecord = function(tableName, key, token)
    return get("/key/" .. tableName .. "/" .. key, token)
end

surrealdb.createRecord = function(tableName, data, token)
    return post("/key/" .. tableName, data, token)
end

surrealdb.updateRecord = function(tableName, key, data, token)
    return patch("/key/" .. tableName .. "/" .. key, data, token)
end

surrealdb.deleteRecord = function(tableName, key, token)
    return del("/key/" .. tableName .. "/" .. key, token)
end

surrealdb.rawSQL = function(sql, token)
    return net.request({
        method = "POST",
        url = URL .. "/sql",
        body = sql,
        headers = {
            ["Accept"] = "application/json",
            ["Content-Type"] = "application/json",
            ["NS"] = "farmer",
            ["DB"] = "main",    
            ["Authorization"] = "Bearer " .. token
        }
    })
end

surrealdb.getWithoutSignIn__CAUTION = function(tableName, id)
    local token = net.jsonDecode(net.request({
        method = "POST",
        url = URL .. "/signin",
        headers = {
            ["Accept"] = "application/json",
        },
        body = net.jsonEncode({
            user = "view",
            pass = "view",
            ns = "farmer",
            db = "main"
        })
    }).body).token

    if not id then
        return surrealdb.getRecords(tableName, token)
    else
        return surrealdb.getRecord(tableName, id, token)
    end
end

surrealdb.rawSQLAsViewer__CAUTION = function(sql)
    local token = net.jsonDecode(net.request({
        method = "POST",
        url = URL .. "/signin",
        headers = {
            ["Accept"] = "application/json",
        },
        body = net.jsonEncode({
            user = "view",
            pass = "view",
            ns = "farmer",
            db = "main"
        })
    }).body).token

    return surrealdb.rawSQL(sql, token)
end

return surrealdb
