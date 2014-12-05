-- contains all the colors for the PunchUI. Change to your liking:
--

local active = {
	BORDER = { 255, 128, 0, 255, ID = "{|}" },

	PANEL_BG = { 0, 0, 0, 230, ID = "{|}" },
	PLAIN_TEXT = { 255, 255, 255, 255, ID = "{p}" },

	HEADER = { 100, 160, 255, 255, ID = "{h}" },
	FUNCTION = { 255, 128, 0, 255, ID = "{f}" },
	ERROR = { 255, 100, 80, 255, ID = "{e}" },
	INPUT_BG = { 255, 128, 0, 50, ID = "{t}" },

	WHITE = { 255, 255, 255, 255, ID = "{w}" },
	GREY = { 150, 150, 150, 255, ID = "{g}" },
	
	RENDERED_TEXT = { 255, 255, 255, 255, ID = "{|}" },
}

local inactive = {
	-- inactive:
	BORDER = { 128, 64, 0, 128, ID = "{|}" },

	PANEL_BG = { 0, 0, 0, 230, ID = "{|}" },
	PLAIN_TEXT = { 255, 255, 255, 128, ID = "{p}" },

	HEADER = { 100, 160, 255, 128, ID = "{h}" },
	FUNCTION = { 128, 64, 0, 128, ID = "{f}" },
	ERROR = { 255, 100, 80, 128, ID = "{e}" },
	INPUT_BG = { 255, 128, 0, 50, ID = "{t}" },

	WHITE = { 255, 255, 255, 128, ID = "{w}" },
	GREY = { 150, 150, 150, 128, ID = "{g}" },

	RENDERED_TEXT = { 128, 128, 128, 128, ID = "{|}" },
}

-- let all inactive colors default to the active colors:
for k, v in pairs(active) do
	if not inactive[k] then
		inactive[k] = v
	end
end

return {active, inactive}
