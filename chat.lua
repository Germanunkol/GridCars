local chat = {
	lines = {},
	active = false,
	enterText = "",
	time = 0,
}

local CHAT_WIDTH = 300

function chat:init()
	CHAT_WIDTH = math.min(love.graphics.getWidth()/2, 500)
end

function chat:show()
	self.lines = { "", "", "", "", "", "", "", "Press enter to chat.", "Welcome!" }
end

function chat:draw()
	local x, y = 20, love.graphics.getHeight() - 20*(#self.lines+5)
	love.graphics.setColor( 0, 0, 0, 200 )
	love.graphics.rectangle( "fill", x, y + 40,
			CHAT_WIDTH, 20*(#self.lines) + 10 )
	if self.active then
		love.graphics.setColor( 0, 0, 0, 200 )
		love.graphics.rectangle( "fill", x, y,
		CHAT_WIDTH, love.graphics.getFont():getHeight() + 10 )

		love.graphics.setColor( 255, 255, 255, 255 )
		if math.sin(self.time) > 0 then
			love.graphics.print( "Enter text: " .. self.enterText .. "|", x + 5, y + 5 )
		else
			love.graphics.print( "Enter text: " .. self.enterText, x + 5, y + 5 )
		end
		y = y + 40
	end

	local x, y = 25, love.graphics.getHeight() - 20*(#self.lines+2) - 10
	love.graphics.setColor( 255, 255, 255, 255 )
	for k = #self.lines, 1, -1 do
		love.graphics.print( self.lines[k], x, y )
		y = y + 20
	end
end

function chat:update( dt )
	if self.active then
		self.time = self.time + dt
	end
end

function chat:newLine( text )
	for k = 1, #self.lines-1 do
		self.lines[k] = self.lines[k+1]
	end
	self.lines[#self.lines] = text
end

function chat:keypressed( key )
	if key == "return" then
		if self.active then
			if client then
				client:send( CMD.CHAT, self.enterText )
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
	end
	print(key)
end

function chat:textinput( letter )
	if self.active then
		if letter ~= "|" then
			if love.graphics.getFont():getWidth( self.enterText ) < CHAT_WIDTH - 30 then
			self.enterText = self.enterText .. letter
			end
		end
	end
end

return chat
