-- Config file handling, can save and load config data
-- By Germanunkol

-- Uses the format:
-- name1 = value1
-- name2 = value2
-- ...
-- Avoid using spaces and "=" signs in the names.
-- name must be a string or number, value must be string or number. Example:
--[[
level = l11.dat
lastLevel = n46.dat
fullscreen = false

Usage:
config = require("config.lua")

config.setValue( "lie", "cake", "configFile.txt" )
print(config.getValue( "lie", "configFile.txt" ))	-- should print "cake".

]]--

local config = {}

local CONFIG_FILE = "config.txt"	-- default file name if none is given.

-- Saves a name, value pair in the file "filename".
-- If an entry with the same name exists, it's overwritten.
function config.setValue( name, value, filename )

	filename = filename or CONFIG_FILE	-- default to configfile
	
	if not name or not value == nil then
		print(name, value)
		error("Error: configFile.setValue got nil value or nil name.")
	end
	
	if not love.filesystem.isFile( filename ) then
		local file = love.filesystem.newFile( filename )
		file:open('w')	--create the file
		file:close()
	end
	
	if type(value) ~= "string" then
		value = tostring(value)
	end
	
	local file = love.filesystem.newFile( filename )
	local data
	if file then
		file:open('r')
		data = file:read()
		file:close()
	end
	
	if not data then
		data = ""
	end
	
	local newData = ""
	local found = false
	--print("full:")
	for line in data:gmatch("[^\r\n]+") do
		--print(line)
		s, e = string.find(line, name .. " = [^\r\n]*")
		if s then
			--data = string.gsub(data, name .. " = [^\r\n]+\r\n", name .. " = " .. value .. "\r\n")
			newData = newData .. name .. " = " .. tostring(value) .. "\r\n"
			found = true
		else
			newData = newData .. line .. "\r\n"
			--data = data .. name .. " = " .. value .. "\r\n"
		end
	end
	if not found then
		newData = newData .. name .. " = " .. tostring(value) .. "\r\n"
	end
	
	file = love.filesystem.newFile( filename )
	if file then
		file:open('w')
		file:write(newData)
		file:close()
		return true
	end
end

-- Load and return the value corresponding to the name from filename.
-- If file can't be found or name is 
function config.getValue( name, filename )
	
	filename = filename or CONFIG_FILE	-- default to configfile

	if not love.filesystem.isFile(filename) then
		--print("Could not find config file.", name, filename)
		return nil
	end
	local ok, file = pcall(love.filesystem.newFile, filename )
	local data
	if ok and file then
		file:open('r')
		data = file:read()
		file:close()
	end
	if data then
		for k, v in string.gmatch(data, "([^ \r\n]+) = ([^\r\n]*)") do
			if k == name then
				if v == "false" then return false end
				if v == "true" then return true end
				return v
			end
		end
	end
	print("Value for '" .. name .. "' not found in config file. Using default.")
	return nil
end

return config
