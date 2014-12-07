local utility = {}

local function vectorDet(x1,y1, x2,y2)
	return x1*y2 - y1*x2
end
local function vectorCross( V, W )
	return V.x*W.y - V.y*W.x
end
--[[function areColinear(p, q, r, eps)
	return math.abs(vectorDet(q.x-p.x, q.y-p.y,  r.x-p.x,r.y-p.y)) <= (eps or 1e-32)
end]]

-- test wether a and b lie on the same side of the line c->d
local function onSameSide(a,b, c,d)
	local px, py = d.x-c.x, d.y-c.y
	local l = vectorDet(px,py,  a.x-c.x, a.y-c.y)
	local m = vectorDet(px,py,  b.x-c.x, b.y-c.y)
	return l*m >= 0
end

local function sign( v )
	return (v > 0 and 1) or (v < 0 and -1) or 0
end

-- Get which side of a line a point lies (-1, 0 or 1)
function whichSideOfLine( l1,l2, p )
	--return sign( (Bx-Ax)*(Y-Ay) - (By-Ay)*(X-Ax) )
	return sign( (l1.x-l2.x)*(p.y-l1.y) - (l2.y-l1.y)*(p.x-l1.x) )
end

function projectPointOntoLine( l1,l2, p )
	-- Direction vector of line:
	local u = { x = l2.x - l1.x, y = l2.y - l1.y }
	-- Perpendicular to that:
	local n = { x =-u.y, y = u.x }

	local v = { x = p.x - l1.x, y = p.y - l1.y }

	local dist = vectorDot( u, v )/vectorDot( u, u )
	print("dist:", dist)
	return { x=u.x*dist + l1.x, y = u.y*dist + l1.y }
end

function utility.pointInTriangle(p, a,b,c)
	return onSameSide(p,a, b,c) and onSameSide(p,b, a,c) and onSameSide(p,c, a,b)
end
function vectorDot( q, p )
	return q.x*p.x + q.y*p.y
end



function utility.printTable( t, depth )
	depth = depth or 1
	for k, v in pairs( t ) do
		if type(v) == "table" then
			print( string.rep( "\t", depth ) .. k .. " = {")
			utility.printTable( v, depth + 1 )
			print( string.rep( "\t", depth ) .. "}" )
		else
			print( string.rep( "\t", depth ) .. k .. " = ", v )
		end
	end
end

function utility.dist( p1, p2 )
	local dx = p1.x - p2.x
	local dy = p1.y - p2.y
	return math.sqrt( dx*dx, dy*dy )
end

function utility.interpolateCos ( rel)
	return -math.cos(math.pi*rel)*0.5 + 0.5
end

return utility