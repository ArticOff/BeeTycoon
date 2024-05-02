local function serialize(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. serialize(v) .. ','
        end
        return s .. '} '
    elseif type(o) == 'string' then
        return ("%q"):format( o )
    else
        return tostring(o)
    end
end

local function condfail( cond, ... )
    if not cond then  return nil, (...) end
    return ...
end

local function deserialize( str, vars )
    -- create dummy environment
    local env = vars and setmetatable( {}, {__index=vars} ) or {}
    -- create function that returns deserialized value(s)
    local f, _err = load( "return "..str, "=deserialize", "t", env )
    if not f then  return nil, _err  end -- syntax error?
    -- set up safe runner
    local co = coroutine.create( f )
    local hook = function( )  debug.sethook( co, error, "c", 1000000 )  end
    debug.sethook( co, hook, "c" )
    -- now run the deserialization
    return condfail( coroutine.resume( co ) )
end

local codec = {}

codec.serialize = serialize
codec.deserialize = deserialize

return codec