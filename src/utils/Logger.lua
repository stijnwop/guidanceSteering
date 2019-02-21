---
-- Logger
--
-- Logger utility.
--
-- Copyright (c) Wopster, 2018

Logger = {}

Logger.INFO = 0
Logger.WARNING = 1
Logger.ERROR = 2

Logger.levelsText = {
    [Logger.INFO] = "Info",
    [Logger.WARNING] = "Warning",
    [Logger.ERROR] = "Error",
}

local function print_r(t, name, indent)
    local tableList = {}
    local function table_r(t, name, indent, full)
        local id = not full and name or type(name) ~= "number" and tostring(name) or '[' .. name .. ']'
        local tag = indent .. id .. ' : '
        local out = {}

        if type(t) == "table" then
            if tableList[t] ~= nil then
                table.insert(out, tag .. '{} -- ' .. tableList[t] .. ' (self reference)')
            else
                tableList[t] = full and (full .. '.' .. id) or id

                if next(t) then -- If table not empty.. fill it further
                    table.insert(out, tag .. '{')

                    for key, value in pairs(t) do
                        table.insert(out, table_r(value, key, indent .. '|  ', tableList[t]))
                    end

                    table.insert(out, indent .. '}')
                else
                    table.insert(out, tag .. '{}')
                end
            end
        else
            local val = type(t) ~= "number" and type(t) ~= "boolean" and '"' .. tostring(t) .. '"' or tostring(t)
            table.insert(out, tag .. val)
        end

        return table.concat(out, '\n')
    end

    return table_r(t, name or 'Value', indent or '')
end

local function log(level, input, ...)
    local levelText = Logger.levelsText[level]
    local p = ("[GS %s]: " .. input):format(levelText)

    if (... ~= nil) then
        p = print(print_r(..., p))
    end

    print(p)
end

function Logger.info(input, ...)
    log(Logger.INFO, input, ...)
end

function Logger.warning(input, ...)
    log(Logger.WARNING, input, ...)
end

function Logger.error(input, ...)
    log(Logger.ERROR, input, ...)
end
