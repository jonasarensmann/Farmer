local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")

local runtime = [[
local modules = {}
local function __rmd(module)
  module = module:gsub("init.luau", "")
  module = module:gsub("init", "")
  if module:sub(-1) == "/" then
    module = module:sub(1, -2)
  end
  return module
end

local function __r(module)
  if module:find("^@") ~= nil then 
    module = module:gsub("@", "crops/")
  end
    if modules[module] then
        return modules[module]()
    end
    if modules[module .. ".luau"] then 
        return modules[module .. ".luau"]()
    end

  
  if module:find("^@") ~= nil then 
    module = module:gsub("@", "crops/")
  end

    if module:find("/") or module:find("/init") or module:find("/init.luau") then 
        return modules[__rmd(module)]()
    end
    return nil
end
local function __newModule(name, module)
    modules[name] = module
end
]]

local cwd = process.cwd

local function getAllDependencies()
  if not fs.isFile(cwd .. "farmer.json") then
    print("No farmer.json file found.")
    return false
  end

  if not fs.isDir(cwd .. "crops") then
    print("No crops directory found.")
    return false
  end

  local packageFile = fs.readFile(cwd .. "farmer.json")
  local packageData = net.jsonDecode(packageFile)
  local deps = packageData.dependencies 

  return deps
end

return function(dir)
    local fileTree = fs.readDir(dir)

    local bundle = ""

    bundle = bundle .. runtime

  local function bundle_deps() 
    local deps = getAllDependencies()

    if not deps then 
      print("Failed to get dependencies. Bundling without dependencies.")
      return
    end

    for dep,_ in pairs(deps) do
      local depFile = fs.readFile(cwd .. "crops/" .. dep .. "/init.luau")
      bundle = bundle .. `__newModule("crops/{dep}", function() {depFile} end) \n`
    end
  end

    bundle_deps()

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
    bundle = bundle:gsub("require%(('.-')%)", "__r(%1)")
    bundle = bundle:gsub("__r%(('@lune/.-')%)", "require(%1)")

    bundle = bundle .. "return __r(\"main.luau\")"

    return bundle
end
