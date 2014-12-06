local game = {}

function game:init()
end

function game:show()
	STATE = "Game"
	ui:setActiveScreen( nil )
end

function game:update( dt )
	map:update( dt )
end

function game:draw()
	map:draw()
end

function game:keypressed( key )
end

function game:mousepressed( button, x, y )
end

return game
