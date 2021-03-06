-- This is part of the "Affair" library.
-- This file handles sending a server's data to the main server list.
-- Luasockets must be installed for this to work. If you have Löve installed, this is already the case.

local http = require("socket.http")

local URL = arg[1] or ""
local PORT = arg[2] or ""
local ID = arg[3] or ""
local INFO = arg[4] or ""

--print( "[ADVERTISE] Contacting: " .. URL )

local body = ""
body = body .. "port=" .. PORT.. "&"
body = body .. "id=" .. ID .. "&"
body = body .. "info=" .. INFO .. "&"

local result, errCode, errorMsg, status = http.request( URL, body )

if result then
	local err = result:match( "%[Warning:%]%s?(.-)\n" )
	if err then
		print( "[ADVERTISE] " .. err )
		--else
		--	print( "[ADVERTISE] Advertisement sent:", PORT, ID, INFO )
	end
end

if errCode and errCode >= 400 then
	print( "[ADVERTISE] Could not advertise: " .. errCode, status, "Correct URL?", URL )
end

-- Close this process:
os.exit()
