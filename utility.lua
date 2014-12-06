local utility = {}

function utility.printTable( t, depth )
	depth = depth or 1
	for k, v in pairs( t ) do
		if type(v) == "table" then
			print( string.rep( "\t", depth ) .. k .. " = {")
			printTable( v, depth + 1 )
			print( string.rep( "\t", depth ) .. "}" )
		else
			print( string.rep( "\t", depth ) .. k .. " = ", v )
		end
	end
end

return utility
