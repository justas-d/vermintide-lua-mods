local hookData = ...

local function ParseLine(message)
    local msgLen = message:len()
    
    local lexData = 
    {
        original = message,
        stream = {},
        pos = 1,
        
        nextChar = function(self)
            self.pos = self.pos + 1
            return self.stream[self.pos - 1]
        end,
        
        nextToken = function(self)
            local SEPERATOR = " "
            local ret = ""
            
            local c = self:nextChar()
            if c == nil then return nil end
                
            repeat
                ret = ret .. c
                c = self:nextChar()
            until c == SEPERATOR or c == nil
            return ret
        end
            
    }
    message:gsub(".", function(c) table.insert(lexData.stream,c) end)
    
    local BEGIN_TOKEN = "."
    
    local c = lexData:nextChar()
    if c ~= BEGIN_TOKEN then return false, "Begin token " .. BEGIN_TOKEN .. " not found at the start." end
    
    local tokenParsers = 
    {
        ["f"] = function(data)
            return { Expression = "dofile", File = data:nextToken() }
        end,
    
        ["e"] = function(data)
            return { Expression = "eval", Eval = data.original:sub(data.pos) }
        end,
        
        ["clear"] = function(data)
            return function() pcall(global_chat_gui.create_ui_elements, global_chat_gui) end
        end
    }
    
    local token = lexData:nextToken()
    local parser = tokenParsers[token]
    if not parser then return false, "Parser for " .. token .. " doesn't exist." end
        
    return pcall(parser, lexData)
end

--[[
local json = require("../base/imports/dkjson")

local status, result = ParseLine(".clear")
if not status then print("fail:", tostring(result))
else print(json.encode(result))
end
--]]


--[[ ---------------------------------------------------------------------------------------
        Name: HandleInput
        Desc: Tries to parse and execute the given string.
        Args: (string) the string to parse/exec.
        Returns: 
                On successful execute:
                    (bool) true
                    (object) return object
                On failed execute:
                    (bool) false
                    (string) error message
                On failed parse:
                    (bool) false
                    nil
--]] ---------------------------------------------------------------------------------------
local function HandleInput(message)
    local parseSuccess, statement = ParseLine(message)
    if not parseSuccess then 
        Log.Debug(tostring(statement))
        return false, nil 
    end
    
    if Api.IsTable(statement) then 
        local expr = statement.Expression
        if expr == "dofile" then
            if not statement.File then return true, "No file specified." end
            
            local success, ret = pcall(Api.Std.dofile, "mods/" .. hookData:GetModHandle():GetModFolder() .. "/chat/" .. statement.File .. ".lua")
            if not success then return false, ret end
            return true, ret
        end
        if expr == "eval" then
            if not statement.Eval then return true, "No expression to evaluate." end

            local success1, chunk = pcall(Api.Std.loadstring, statement.Eval)
            if not success1 then return false, chunk end
            local success2, value = pcall(chunk)
            if not success2 then return false, value end
            return true, value
        end
    elseif Api.IsFunction(statement) then
       local status, value = pcall(statement)
       if not status then return false, value end
       return true, value
    end
    
    return false, "Unknown statement"
end

--  hijack the send_chat_message  --

-- we're not using FunctionHooks since they're only used for hooking functions, not outright hijacking them.
local sendMessage = Managers.chat.send_chat_message
Managers.chat.send_chat_message = function(self, noclue, message, ...)
    Log.Debug("noclue:", tostring(noclue), "message:", tostring(message))
    
    local status, obj = HandleInput(message)
    
    local output
    if not status then
        if obj == nil then
            return sendMessage(self, noclue, message)
        end
        output= "Error: " .. tostring(obj)
    else
        output= tostring(obj)
    end
    
    Log.Write(tostring(output))
end
