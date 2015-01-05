local utility = {}

-- Check if point (x,y) is inside of rectangular object:
function utility.isInside( x, y, ox, oy, ow, oh )
	return x > ox and y > oy and x < ox + ow and y < oy + oh
end

return utility
