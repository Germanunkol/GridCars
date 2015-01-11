local stats = {}

local list = {}

local STAT_WIDTH = love.graphics.getWidth()/2
local STAT_X = (love.graphics.getWidth() - STAT_WIDTH)/2
local STAT_HEIGHT = 300 --math.min(love.graphics.getHeight()/3, 300)
local STAT_Y = (love.graphics.getHeight() - STAT_HEIGHT)/2
local PAD = 20

local STAT_SWITCH_TIME = 5

local panel = require( "panel" )

function stats:clear()
	list = {}
	STAT_WIDTH = love.graphics.getWidth()/2
	STAT_X = (love.graphics.getWidth() - STAT_WIDTH)/2
	STAT_HEIGHT = 300 --math.min(love.graphics.getHeight()/3, 300)
	STAT_Y = (love.graphics.getHeight() - STAT_HEIGHT)/2 - PAD*4

	self.panel = panel:new( STAT_X - PAD, STAT_Y - 2*PAD,
			STAT_WIDTH + 3*PAD, STAT_HEIGHT + 6*PAD )

	-- Stat to be displayed:
	self.current = nil
	
	self.nextStatTimer = STAT_SWITCH_TIME
end

-- Called for every statistic sent from the server:
function stats:add( str )
	local name, unit, data = str:match( "(.-)|(.-)|(.*)" )
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
				-- Display at least a few pixels, even if u.val is zero:
				u.relHeight = math.max( 0.02, u.relHeight )
			else
				u.relHeight = 0.02
			end
		end

		table.insert( list, stat )
	end
end

function stats:draw()
	if self.current and list[self.current] then

		love.graphics.setLineWidth( 2 )
		local fontHeight = love.graphics.getFont():getHeight()

		local users = network:getUsers()
		local stat = list[self.current]
	
		--[[love.graphics.setColor( 0, 0, 0, 200 )
		love.graphics.rectangle( "fill", STAT_X - PAD, STAT_Y - PAD*2,
				STAT_WIDTH + 2*PAD, STAT_HEIGHT + 4*PAD )]]
		self.panel:draw()

		local statNameWidth = STAT_WIDTH/(#list)
		for k, s in ipairs( list ) do
			-- Print stat titles:
			if s == stat then
				love.graphics.setColor( 255, 255, 255, 255 )
			else
				love.graphics.setColor( 255, 255, 255, 64 )
			end
			love.graphics.printf( s.name, STAT_X + statNameWidth*(k-1),
				STAT_Y - PAD, statNameWidth, "center" )
		end

		local slotWidth = STAT_WIDTH/(#stat.data+1)
		local barWidth = math.min( 30, slotWidth + 10 )
		for k, u in ipairs( stat.data ) do
			if users[u.id] then
				local barHeight = math.min(stat.timer,u.relHeight)*STAT_HEIGHT
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

				if map:getCar( u.id ) then
					map:getCar( u.id ):drawOnUI( STAT_X + k*slotWidth,
							STAT_Y + STAT_HEIGHT + 30, 0.3 )
				end
			end
		end
	end
end

function stats:update( dt )
	if not self.current or not list[self.current] then
		self.current = 1
		if list[self.current] then
			list[self.current].timer = 0
		end
		self.nextStatTimer = STAT_SWITCH_TIME
	else
		if list[self.current] then
			if list[self.current].timer < 1 then
				list[self.current].timer = math.min( list[self.current].timer + dt*0.5, 1 )
			end
			self.nextStatTimer = self.nextStatTimer - dt
			if self.nextStatTimer < 0 then
				self.current = self.current + 1
				self.nextStatTimer = STAT_SWITCH_TIME
				if list[self.current] then
					list[self.current].timer = 0
				end
			end
		end
	end
end

return stats
