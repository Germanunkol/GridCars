local chat = {
	lines = {},
	active = false,
	enterText,
}

function chat:init()
	self.lines = { "", "", "", "", "", "", "", "", "" }
end

function chat:draw()
	local x, y = 20, love.graphics.getHeight() - 20*(#self.lines+1)
	for k = 1, #self.lines do
		love.graphics.print( self.lines[k], x, y )
		y = y - 20
	end
	if self.active then
		love.graphics.setColor( 128, 128, 128, 255 )
		love.graphics.print( "Enter text: " .. self.enterText, x - 5, y )
		y = y - 20
	end
end

function chat:newLine( text )
	for k = 1, #self.lines-1 do
		self.lines[k] = self.lines[k+1]
	end
	self.lines[#self.lines] = text
end

function love.keypressed( key )
	if key == "return" then
		if self.active then
			network:send( CMD.CHAT, text )
			text = ""
			self.active = false
		else
			self.active = true
		end
	end
end

function love.textinput( letter )
	if self.active then
		text = text .. letter
	end
end

return chat
