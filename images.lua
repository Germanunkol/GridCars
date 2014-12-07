local images = {}

function images:load()
	local imageNames = love.filesystem.getDirectoryItems( "images" )
	for k, name in pairs( imageNames ) do
		-- Only load png files:
		if name:match(".*%.png") then
			images[name] = love.graphics.newImage( "images/" .. name )
		end
	end
end

return images
