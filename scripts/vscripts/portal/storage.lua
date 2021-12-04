
--[[
    v1.1.0

    Helps with saving/loading values for persistency between game sessions.
    Values are saved into the entity running this script. If the entity
    is killed the values cannot be retrieved during that game session.

    This script is loaded on a per script basis into the script's scope.
    Using the following line:

    DoIncludeScript("util/storage", thisEntity:GetPrivateScriptScope())

    -

    Functions are accessed through the Storage table.

    Examples of saving/loading the following local values that might be defined
    at the top of the file:

    local origin = origin or thisEntity:GetOrigin()
    local hp     = hp     or thisEntity:GetHealth()
    local name   = name   or thisEntity:GetName()

    Saving:

    Storage:SaveVector("origin", origin)
    Storage:SaveNumber("hp", hp)
    Storage:SaveString("name", name)

    Loading:

    function Activate(activateType)
        -- 2 indicates a loaded game, this is typically where you load values
        -- but loading can be done at any point during the game
        if activateType == 2 then
            origin = Storage:LoadVector("origin")
            hp     = Storage:LoadNumber("hp")
            name   = Storage:LoadString("name")
        end
    end
]]

Storage = Storage or {}

---Save a single number to this entity.
---@param name string Name to save as.
---@param value number Number to save.
function Storage:SaveNumber(name, value)
    thisEntity:SetContextNum(name, value, 0)
end

---Save a single string to this entity.
---@param name string Name to save as.
---@param value string String to save.
function Storage:SaveString(name, value)
    thisEntity:SetContext(name, value, 0)
end

---Save a Vector to this entity.
---@param name string Name to save as.
---@param vector Vector Vector to save.
function Storage:SaveVector(name, vector)
    Storage:SaveNumber(name .. ".x", vector.x)
    Storage:SaveNumber(name .. ".y", vector.y)
    Storage:SaveNumber(name .. ".z", vector.z)
end

---Save a QAngle to this entity.
---@param name string Name to save as.
---@param qangle QAngle QAngle to save.
function Storage:SaveQAngle(name, qangle)
    Storage:SaveNumber(name .. ".x", qangle.x)
    Storage:SaveNumber(name .. ".y", qangle.y)
    Storage:SaveNumber(name .. ".z", qangle.z)
end

---Save an ordered array of numbers or strings.
---@param name string
---@param array any[]
function Storage:SaveArray(name, array)
    -- Save number of items first
    Storage:SaveNumber(name, #array)
    for index, value in ipairs(array) do
        local t = type(value)
        if t == "number" then
            Storage:SaveNumber(name..index, value)
        elseif t == "string" then
            Storage:SaveString(name..index, value)
        end
    end
end

---Save a boolean.
---@param name string
---@param bool boolean
function Storage:SaveBoolean(name, bool)
    Storage:SaveNumber(name, bool and 1 or 0)
end

--== Loading

---Loads a number or string by name, whichever was stored.
---@param name string
---@return number|string
function Storage:LoadNumberOrString(name)
    return thisEntity:GetContext(name)
end

---Load a number from this entity.
---@param name string Name the number was saved as.
---@param default? string # Optional default value
---@return number
function Storage:LoadNumber(name, default)
    local value = thisEntity:GetContext(name)
    if not value or type(value) ~= "number" then
        print("Number " .. name .. " could not be loaded!", "("..type(value)..", "..tostring(value)..")")
        return default
    end
    return value
end

---Load a string from this entity.
---@param name string # Name the string was saved as.
---@param default? string # Optional default value
---@return string
function Storage:LoadString(name, default)
    local value = thisEntity:GetContext(name)
    if not value or type(value) ~= "string" then
        print("String " .. name .. " could not be loaded!")
        return default
    end
    return value
end

---Load a Vector from this entity.
---@param name string Name the Vector was saved as.
---@return Vector
function Storage:LoadVector(name)
    local x = Storage:LoadNumber(name .. ".x")
    if not x then
        return print("Vector " .. name .. " could not be loaded!")
    end
    local y = Storage:LoadNumber(name .. ".y")
    local z = Storage:LoadNumber(name .. ".z")
    return Vector(x, y, z)
end

---Load a QAngle from this entity.
---@param name string Name the QAngle was saved as.
---@return QAngle
function Storage:LoadQAngle(name)
    local x = Storage:LoadNumber(name .. ".x")
    if not x then
        return print("QAngle " .. name .. " could not be loaded!")
    end
    local y = Storage:LoadNumber(name .. ".y")
    local z = Storage:LoadNumber(name .. ".z")
    return QAngle(x, y, z)
end

---Load an array from this entity.
---@param name string
---@return any[]
function Storage:LoadArray(name)
    local arr = {}
    local len = Storage:LoadNumber(name)
    for i = 1, len do
        arr[#arr+1] = Storage:LoadNumberOrString(name..i)
    end
    return arr
end

function Storage:LoadBoolean(name)
    return Storage:LoadNumber(name) == 1
end

