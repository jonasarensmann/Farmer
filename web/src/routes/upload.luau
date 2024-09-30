local surrealdb = require("../surrealdb")
local net = require("@lune/net")
local fs = require("@lune/fs")

local function storeFiles(bundle, json, folderName)
    if fs.isDir("data/crops/" .. folderName) then
        fs.removeDir("data/crops/" .. folderName)
    end

    fs.writeDir("data/crops/" .. folderName)

    fs.writeFile("data/crops/" .. folderName .. "/init.luau", bundle)
    fs.writeFile("data/crops/" .. folderName .. "/farmer.json", net.jsonEncode(json, true))

    return {
        status = "success",
        message = "file stored"
    }
end

return function(req, res)
    local body = net.jsonDecode(req.body)

    if not body.user or not body.pass then
        res.setStatus(400)
        res.json({
            status = "error",
            message = "Username and password are required"
        })
        return
    end

    body.user = string.lower(body.user)

    local signInResult = surrealdb.signIn(body.user, body.pass)

    if signInResult.statusCode ~= 200 then
        res.setStatus(signInResult.statusCode)
        res.json({
            status = "error",
            message = "failed to sign in"
        })
        return
    end

    if string.len(req.body) == 0 then
        res.setStatus(400)
        res.json({
            status = "error",
            message = "File body is empty"
        })
        return
    end

    if string.len(req.body) > 10000000 then
        res.setStatus(400)
        res.json({
            status = "error",
            message = "Too large"
        })
        return
    end

    if not body.packageFile or not body.bundle then
        res.setStatus(400)
        res.json({
            status = "error",
            message = "farmerFile and initFile are required"
        })
        return
    end

    local farmerFile = body.packageFile
    local bundle = body.bundle

    local signInBody = net.jsonDecode(signInResult.body)
    local token = signInBody.token

    local checkOwnerResult = surrealdb.rawSQL("SELECT * FROM crops WHERE name = '" .. string.lower(farmerFile.name) .. "'", token)
    local getUsernameResult = surrealdb.rawSQLAsViewer__CAUTION("SELECT id FROM users WHERE name = '" .. body.user .. "'")

    if checkOwnerResult.statusCode ~= 200 or getUsernameResult.statusCode ~= 200 then
        res.setStatus(checkOwnerResult.statusCode)
        res.json({
            status = "error",
            message = "failed to check owner of crop: " .. checkOwnerResult.body .. " or failed to get username: " .. getUsernameResult.body
        })
        return
    end

    local checkOwnerBody = net.jsonDecode(checkOwnerResult.body)[1]
    local getUsernameBody = net.jsonDecode(getUsernameResult.body)[1]

    if not checkOwnerBody.result or #checkOwnerBody.result == 0 then
        local createData = {
            name = string.lower(farmerFile.name),
            description = farmerFile.description,
            version = farmerFile.version,
        }

        if not farmerFile.license or farmerFile.license == '' then 
            createData.license = "Not Specified"
        else
            createData.license = farmerFile.license
        end

        if farmerFile.dependencies and #farmerFile.dependencies > 0 then
            createData.dependencies = farmerFile.dependencies
        end

        local createResult = surrealdb.createRecord("crops", createData, token)
    
        if createResult.statusCode == 200 then
            storeFiles(bundle, farmerFile, string.lower(farmerFile.name))
            res.setStatus(createResult.statusCode)
            res.json({
                status = "success",
                message = "crop created"
            })
            return
        else
            res.setStatus(createResult.statusCode)
            res.json({
                status = "error",
                message = "failed to create crop: " .. createResult.body
            })
            return
        end
    elseif checkOwnerBody.result[1].user ~= getUsernameBody.result[1].id then
        res.setStatus(401)
        res.json({
             status = "error",
            message = "Crop already exists but you are not the owner of it."
        })
        return
    elseif checkOwnerBody.result[1].user == getUsernameBody.result[1].id then
        local updateData = {
            name = string.lower(farmerFile.name),
            description = farmerFile.description,
            version = farmerFile.version,
        }

        if not farmerFile.license or farmerFile.license == '' then 
            updateData.license = "Not Specified"
        else
            updateData.license = farmerFile.license
        end

        if farmerFile.dependencies and #farmerFile.dependencies > 0 then
            updateData.dependencies = farmerFile.dependencies
        end

        local updateResult = surrealdb.updateRecord("crops", checkOwnerBody.result[1].id, updateData, token)
        if updateResult.statusCode ~= 200 then
            res.setStatus(updateResult.statusCode)
            res.json({
                status = "error",
                message = "failed to update crop: " .. updateResult.body
            })
            return
        end
        storeFiles(bundle, farmerFile, string.lower(farmerFile.name))
        res.json({
            status = "success",
            message = "crop updated"
        })
    end
end
