local stats = {}

local list = {}

local STAT_WIDTH = love.graphics.getWidth()/2
local STAT_X = (love.graphics.getWidth() - STAT_WIDTH)/2
local STAT_HEIGHT = 300 --math.min(love.graphics.getHeight()/3, 300)
local STAT_Y = (love.graphics.getHeight() - STAT_HEIGHT)/2
local PAD = 20

local panel = require( "panel" )

function stats:clear()
	list = {}
	STAT_WIDTH = love.graphics.getWidth()/2
	STAT_X = (love.graphics.getWidth() - STAT_WIDTH)/2
	STAT_HEIGHT = 300 --math.min(love.graphics.getHeight()/3, 300)
	STAT_Y = (love.graphics.getHeight() - STAT_HEIGHT)/2

	self.panel = panel:new( STAT_X - PAD, STAT_Y - 2*PAD,
			STAT_WIDTH + 3*PAD, STAT_HEIGHT + 2*PAD )

	-- Stat to be displayed:
	self.current = nil
end

-- Called for every statistic sent from the server:
function stats:add( str )
	local name, unit, data = str:match( "(.-)|(.-)|(.*)" )
	print("New stat string:", str)
	print("\t", name, unit, data)
	if name and unit and data then
		local stat = {
			name = name,
			unit = unit,
			timer = 0,
			data = {},
		}

		local users = network:getUsers()
		local max = -math.huge

		for id, value in data:gmatch( "(%S-)%s(%S-)|" ) do
			print( "id, value:", id, value)
			id = tonumber(id)
			if id and users[id] then
				local entry = {}
				entry.val = tonumber(value)
				entry.id = id
				entry.displayStr = " " .. users[id].playerName .. ": " .. entry.val .. " " .. unit
				table.insert( stat.data, entry )

				max = math.max( entry.val, max )
			end
		end

		-- Calculate the height (relative to the maximum):
		for k, u in ipairs( stat.data ) do
			if max ~= 0 then
				u.relHeight = u.val/max
			end
		end

		table.insert( list, stat )
	end
end

function stats:draw()
	if self.current and list[self.current] then

		local fontHeight = love.graphics.getFont():getHeight()

		local users = network:getUsers()
		local stat = list[self.current]
	
		--[[love.graphics.setColor( 0, 0, 0, 200 )
		love.graphics.rectangle( "fill", STAT_X - PAD, STAT_Y - PAD*2,
				STAT_WIDTH + 2*PAD, STAT_HEIGHT + 4*PAD )]]
		self.panel:draw()

		-- Print stat title:
		love.graphics.setColor( 255, 255, 255, 255 )
		love.graphics.printf( stat.name, STAT_X, STAT_Y - PAD, STAT_WIDTH )

		local slotWidth = STAT_WIDTH/(#stat.data+1)
		local barWidth = math.min( 30, slotWidth + 10 )
		for k, u in ipairs( stat.data ) do
			if users[u.id] then
				local barHeight = stat.timer*u.relHeight*STAT_HEIGHT
				love.graphics.setColor( users[u.id].customData.red, 
						users[u.id].customData.green,
						users[u.id].customData.blue,
						128 )

				love.graphics.rectangle( "fill", STAT_X + k*slotWidth - barWidth/2,
					STAT_Y + STAT_HEIGHT - barHeight, barWidth, barHeight )
				love.graphics.setColor( 0, 0, 0, 255 )
				love.graphics.rectangle( "line", STAT_X + k*slotWidth - barWidth/2,
					STAT_Y + STAT_HEIGHT - barHeight, barWidth, barHeight )

				love.graphics.setColor( 255, 255, 255, 255 )
				--love.graphics.setColor( 0, 0, 0, 255 )
				love.graphics.printf( u.displayStr,
						STAT_X + k*slotWidth - fontHeight/2, STAT_Y + STAT_HEIGHT - 5,
						500, "left", -math.pi/2 )
			end
		end
	end
end

function stats:update( dt )
	if not self.current then
		self.current = 1
		if list[self.current] then
			list[self.current].timer = 0
		end
	else
		if list[self.current] then
			if list[self.current].timer < 1 then
				list[self.current].timer = math.min( list[self.current].timer + dt, 1 )
			end
		end
	end
end

return stats
