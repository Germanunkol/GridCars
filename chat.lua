local chat = {
	lines = {},
	active = false,
	enterText = "",
	time = 0,
}

local CHAT_WIDTH = 300
local chatSide = "left"

function chat:init()
	CHAT_WIDTH = math.min(love.graphics.getWidth()/2 - 40, 500)
end

function chat:reset()
	self.lines = { "", "", "", "", "", "", "", "Press enter to chat.", "Welcome!" }
end

function chat:show()
end

function chat:draw()
	local fontHeight = love.graphics.getFont():getHeight()
	local x
	local y = love.graphics.getHeight() - 20*(#self.lines+1) - 70

	if map.loaded and client and client:getID() then
		if map:hasCar( client:getID() ) then
			local c = map:getCar( client:getID() )
			if c.vY > 0 then
			if chatSide == "left" then
				if c.vX < 0 then
					chatSide = "right"
				end
			else
				if c.vX > 0 then
					chatSide = "left"
				end
			end
		end
		end
	end
	
	if chatSide == "left" then
		x = 20
	else
		x = love.graphics.getWidth() - 20 - CHAT_WIDTH
	end

	love.graphics.setColor( 0, 0, 0, 200 )
	love.graphics.rectangle( "fill", x, y,
			CHAT_WIDTH, 20*(#self.lines) + 10 )

	love.graphics.setColor( 255, 255, 255, 255 )
	x = x + 5
	y = y + 10
	for k = 1, #self.lines do
		love.graphics.print( self.lines[k], x, y )
		y = y + 20
	end

	local x, y = 20, love.graphics.getHeight() - 70
	if self.active then
		love.graphics.setColor( 0, 0, 0, 200 )
		love.graphics.rectangle( "fill",
			x, y, CHAT_WIDTH, fontHeight + 10 )

		love.graphics.setColor( 255, 255, 255, 255 )
		if math.sin(self.time*3) > 0 then
			love.graphics.print( "Say: " .. self.enterText .. "|", x + 5, y + 5 )
		else
			love.graphics.print( "Say: " .. self.enterText, x + 5, y + 5 )
		end
	end

end

function chat:update( dt )
	if STATE == "Lobby" or STATE == "Game" then
		if self.active then
			self.time = self.time + dt
		end
	end
end

function chat:newLine( text )
	for k = 1, #self.lines-1 do
		self.lines[k] = self.lines[k+1]
	end
	self.lines[#self.lines] = text
end

function chat:keypressed( key )
	if STATE == "Game" or STATE == "Lobby" then
		if key == "return" then
			if self.active then
				if client then
					if #self.enterText > 0 then
						client:send( CMD.CHAT, self.enterText )
					end
				end
				self.enterText = ""
				self.active = false
			else
				if client then
					self.active = true
				end
			end
		elseif key == "backspace" then
			if #self.enterText > 0 then
				self.enterText = self.enterText:sub( 1, #self.enterText - 1 )
			end
		elseif key == "escape" then
			self.enterText = ""
			self.active = false
		end
	end
end

function chat:textinput( letter )
	if STATE == "Game" or STATE == "Lobby" then
		if self.active then
			if letter ~= "|" then
				if love.graphics.getFont():getWidth( "Say: " .. self.enterText .. letter ) < CHAT_WIDTH - 50 then
					self.enterText = self.enterText .. letter
				end
			end
		end
	end
end

return chat
