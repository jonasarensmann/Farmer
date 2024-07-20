local process = require("@lune/process")
local fs = require("@lune/fs")
local net = require("@lune/net")
local io = require("@lune/stdio")
local bundle = require("bundler/bundle.luau")

local DEFAULT_MIRROR = "https://farmer.jonas-arensmann.com"

local function getConfigFolder()
    if process.os == "windows" then
        return process.env.APPDATA .. "/farmer"
    else
        return process.env.HOME .. "/.config/farmer"
    end
end

local function getConfigValue(key)
    local configFolder = getConfigFolder()
    local configPath = configFolder .. "/farmer.conf"

    if not fs.isFile(configPath) then
        return nil
    end

    local file = fs.readFile(configPath)
    local lines = file:split("\n")

    for _, line in ipairs(lines) do
        local parts = line:split("=")

        if parts[1] == key then
            return parts[2]
        end
    end

    return nil
end

local function init(folderName)
    if not folderName then
        return print("Please provide a folder name.")
    end

    if fs.isDir(folderName) then
        return print("Folder already exists.")
    end

    fs.writeDir(folderName)
    fs.writeDir(folderName .. "/src")

    local fileTemplate = {
        name = folderName,
        version = "0.1.0",
        description = "Lorem Ipsum",
        author = "",
        license = "",
        dependencies = {}
    }

    fs.writeFile(folderName .. "/farmer.json", net.jsonEncode(fileTemplate, true))

    fs.writeFile(folderName .. "/src/main.luau", 'print("Hello, World!")')

    return print("Project initialized. Run 'cd " .. folderName .. " && farmer install' to install dependencies.")
end

local function getPackageFile()
    local packageFile = fs.readFile("farmer.json")

    if not packageFile then
        return
    end

    return net.jsonDecode(packageFile)
end

local function getDependencyPackageFile(name)
    local packageFile = fs.readFile("crops/" .. name .. "/farmer.json")

    if not packageFile then
        return
    end

    return net.jsonDecode(packageFile)
end

local function writePackageFile(content)
    fs.writeFile("farmer.json", net.jsonEncode(content, true))
end

local function createDotLuaurcFile()
    if fs.isFile(".luaurc") then
        fs.removeFile(".luaurc")
    end

    local data = {
        languageMode = "strict",
        aliases = {}
    }

    local packageFile = getPackageFile()
    if packageFile and packageFile.dependencies then 
        for name, version in pairs(packageFile.dependencies) do
            data.aliases[name] = "./crops/" .. name

            local function createDependencyAliases(name)
                local packageFile = getDependencyPackageFile(name)

                if packageFile and packageFile.dependencies then
                    for name, version in pairs(packageFile.dependencies) do
                        data.aliases[name] = "./crops/" .. name

                        createDependencyAliases(name)
                    end
                end
            end

            createDependencyAliases(name)
        end
    end

    fs.writeFile(".luaurc", net.jsonEncode(data, true))
end

local function fetch(packageName)
    local mirror = getConfigValue("core.mirror")

    if not mirror then
        return print("Mirror error.")
    end

    local result = net.request({
        url = mirror .. "/fetch",
        method = "GET",
        query = {
            name = packageName
        }
    })

    if result.statusCode ~= 200 then
        return print("Error fetching package.", result.body)
    end

    local json = net.jsonDecode(result.body)

    if not json.bundle or not json.json then
        return print("Error fetching package.")
    end

    if not fs.isDir("crops") then
        fs.writeDir("crops")
    end

    if fs.isDir("crops/" .. packageName) then
        fs.removeDir("crops/" .. packageName)
    end

    fs.writeDir("crops/" .. packageName)

    fs.writeFile("crops/" .. packageName .. "/init.luau", json.bundle)
    fs.writeFile("crops/" .. packageName .. "/farmer.json", net.jsonEncode(json.json, true))

    print("Downloaded: " .. packageName .. " " .. json.json.version)

    if json.json.dependencies then
        for name, version in pairs(json.json.dependencies) do
            fetch(name)
        end
    end

    return
end

local function getNewestVersion(packageName)
    local mirror = getConfigValue("core.mirror")

    if not mirror then
        return error("Mirror error.")
    end
    
    local result = net.request({
        url = mirror .. "/details",
        method = "GET",
        query = {
            name = packageName
        }
    })

    if result.statusCode ~= 200 then
        return error(result.body)
    end

    local json = net.jsonDecode(result.body)

    if not json.version then
        return error("Error fetching package.")
    end

    return json.version
end

local function install()
    local packageFile = getPackageFile()

    if not packageFile.dependencies then
        return error("No dependencies found.")
    end

    for name, version in pairs(packageFile.dependencies) do
        fetch(name)
    end

    createDotLuaurcFile()

    return
end

local function add(packageName: string)
    local packageFile = getPackageFile()

    if not packageFile.dependencies then
        packageFile.dependencies = {}
    end

    if packageFile.dependencies[packageName] then
        return error("Dependency already exists.")
    end

    packageFile.dependencies[packageName] = getNewestVersion(packageName)

    writePackageFile(packageFile)

    fetch(packageName)

    createDotLuaurcFile()

    return
end

local function remove(packageName: string)
    local packageFile = getPackageFile()

    if not packageFile.dependencies then 
        error("No dependencies found.")
    end

    if not packageFile.dependencies[packageName] then
        error("Dependency not found.")
    end

    fs.removeDir("crops/" .. packageName)

    packageFile.dependencies[packageName] = nil

    writePackageFile(packageFile)

    createDotLuaurcFile()
end

local function list()
    local packageFile = getPackageFile()

    if not packageFile.dependencies then
        return error("No dependencies found.")
    end

    for name, version in pairs(packageFile.dependencies) do
        print(name .. " " .. version)
    end

    return
end

local function upload()
    local packageFile = getPackageFile()

    if not packageFile then
        return error("No farmer.json file found.")
    end

    local bundle = bundle("src")

    local mirror = getConfigValue("core.mirror")

    if not mirror then
        return error("Mirror error.")
    end

    local user = io.prompt("text", "Username: ")
    local pass = io.prompt("text", "Password: ")

    local result = net.request({
        url = mirror .. "/upload",
        method = "POST",
        body = net.jsonEncode({
            user = user,
            pass = pass,
            bundle = bundle,
            packageFile = packageFile
        })
    })

    if result.statusCode ~= 200 then
        return error(result.body)
    end

    return print("Package uploaded.", result.body)
end

local function bundleToFile(output)
    if not output then
        return error("Please provide a output file.")
    end

    local bundle = bundle("src")

    fs.writeFile(output, bundle)

    return print("Bundle created.")
end

local function main()
    local args = process.args

    if not args or not args[1] or #args[1] == 0 or args[1] == "help" then
        return print([[
Farmer: A Package Manager for Lune
Usage: farmer <command> [options]

Commands:
    init  <name>    Initialize a new Lune project
    add <crop>      Add a new dependency
    remove <crop>   Remove a dependency
    bundle <output> Bundle a project to a single file
    install         Install dependencies
    list            List dependencies
    upload          Upload a package
    help            Display this help message
        ]])
    end

    local configFolder = getConfigFolder()
    if not fs.isDir(configFolder) or not fs.isFile(configFolder .. "/farmer.conf") then
        fs.writeDir(configFolder)

        fs.writeFile(configFolder .. "/farmer.conf", "core.mirror=".. DEFAULT_MIRROR .. "\n")
    end

    if args[1] == "init" then
        return init(args[2])
    elseif args[1] == "install" then
        return install()
    elseif args[1] == "add" then
        return add(args[2])
    elseif args[1] == "remove" then
        return remove(args[2])
    elseif args[1] == "list" then
        return list()
    elseif args[1] == "upload" then 
        return upload()
    elseif args[1] == "bundle" then 
        return bundleToFile(args[2])
    end

    return print("Command not found. Run 'farmer help' for a list of commands.")
end

return main()