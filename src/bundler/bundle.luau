local fs = require("@lune/fs")

local runtime = [[
local modules = {}
local function __r(module)
    if modules[module] then
        return modules[module]()
    end
    if modules[module .. ".luau"] then 
        return modules[module .. ".luau"]()
    end
    return nil
end
local function __newModule(name, module)
    modules[name] = module
end
]]

return function(dir)
    local fileTree = fs.readDir(dir)

    local bundle = ""

    bundle = bundle .. runtime

    local function loop(tree, uDir)
        for _, file in ipairs(tree) do
            if fs.isDir(dir .. "/" .. file) or (uDir and fs.isDir(dir .. "/" .. uDir .. "/" .. file)) then
                local newDir = if uDir then uDir .. "/" .. file else file

                loop(fs.readDir(dir .. "/" .. newDir), newDir)
            else
                local newFile = if uDir then uDir .. "/" .. file else file
                bundle = bundle .. `__newModule("{newFile}", function() {fs.readFile(dir .. "/" .. newFile)} end) \n`
            end
        end
    end

    loop(fileTree)

    -- best code ever
    bundle = bundle:gsub("require%((\".-\")%)", "__r(%1)")
    bundle = bundle:gsub("__r%((\"@lune/.-\")%)", "require(%1)")

    bundle = bundle .. "return __r(\"main.luau\")"

    return bundle
end