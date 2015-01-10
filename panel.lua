local panel = {}
panel.__index = panel

function panel:new( x, y, width, height, cornersize )
	local o = {
		x = x,
		y = y,
		w = width,
		h = height }
	setmetatable( o, self )
	
	cornersize = cornersize or 3
	self.corners = {cornersize, cornersize, cornersize, cornersize}

	panel.calcBorder( o )
	return o
end

function panel:calcBorder()
	self.border = {}

	-- top left:
	if self.corners[1] > 0 then
		table.insert( self.border, 0 )
		table.insert( self.border, 0 + self.corners[1] )
		table.insert( self.border, 0 + self.corners[1] )
		table.insert( self.border, 0 )
	else
		table.insert( self.border, 0 )
		table.insert( self.border, 0 )
	end
	-- top right
	if self.corners[2] > 0 then
		table.insert( self.border, self.w - self.corners[2] )
		table.insert( self.border, 0 )
		table.insert( self.border, self.w )
		table.insert( self.border, 0 + self.corners[2] )
	else
		table.insert( self.border, self.w )
		table.insert( self.border, 0 )
	end
	-- bottom right
	if self.corners[3] > 0 then
		table.insert( self.border, self.w )
		table.insert( self.border, self.h - self.corners[3] )
		table.insert( self.border, self.w - self.corners[3] )
		table.insert( self.border, self.h )
	else
		table.insert( self.border, self.w )
		table.insert( self.border, self.h )
	end
	-- bottom left:
	if self.corners[4] > 0 then
		table.insert( self.border, self.corners[4] )
		table.insert( self.border, self.h )
		table.insert( self.border, 0 )
		table.insert( self.border, self.h - self.corners[4] )
	else
		table.insert( self.border, 0 )
		table.insert( self.border, self.h )
	end
end

function panel:draw( x, y )
	love.graphics.setColor( 0,0,0,200 )
	love.graphics.push()
	love.graphics.translate( x or self.x, y or self.y )
	love.graphics.polygon( "fill", self.border )
	love.graphics.pop()
end

return panel
