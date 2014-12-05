ui = require(".")

function love.load()

	love.filesystem.setIdentity("PunchUI")
	love.graphics.setBackgroundColor(25,25,25,255)
	
	scr = ui:newScreen( "main" )

	scr:addPanel( "centerPanel",
			love.graphics.getWidth()/2-100,
			love.graphics.getHeight()/2-120,
			200, 220 )

	scr:addHeader( "centerPanel", "welcome", 0, 0, "Welcome" )
	scr:enableToolTips()
	scr:addText( "centerPanel", "welcometxt", 10, 20, nil, 7, "Welcome to the {f}PunchUI{w}!\n\nTo get started: Open the 'Example' menu by pressing {f}E{w}. Then press {f}1{w} to choose the first option.\n\n\nCheck out the github site for more info: {g}https://github.com/Germanunkol/PunchUI")

	ui:setActiveScreen( scr )

	scr:addPanel( "topMenu", 1, 1, love.graphics.getWidth()-1, 25, nil, 5, {0,0,0,0} )
	scr:addFunction( "topMenu", "menu", 0, 0, "Menu", "m", spawnMainMenu )
	scr:addFunction( "topMenu", "examples", 1*love.graphics.getWidth()/4, 0, "Examples", "e", spawnExampleMenu, "Show multiple small examples." )
	scr:addFunction( "topMenu", "license", 2*love.graphics.getWidth()/4, 0, "Show License", "l", spawnLicense, "Display the license." )
end

function spawnMainMenu()
	local list = {
		{ txt="Reset", event=love.load },
		{ txt="Quit", event=quit },
	}
	scr:newMenu( 5, 25, nil, list )
end

function spawnExampleMenu()
	local list = {
		{ txt="Input Box", event=spawnInputBox },
		{ txt="Login", event=spawnLoginBox },
		{ txt="Sub menu", event=spawnSubMenu },
	}
	scr:newMenu( love.graphics.getWidth()/4 + 5, 25, nil, list )
end

function spawnSubSubMenu( layer )
	if layer < 7 then
		return function()
			local list = {}
			for k = 1, layer do
				table.insert( list, { txt = "sub",
				event = spawnSubSubMenu( layer + 1) } )
			end
			table.insert( list, { txt = "menu",
			event = spawnSubSubMenu( layer + 1) } )
			table.insert( list, { txt = "(esc to close)",
			event = spawnSubSubMenu( layer + 1) } )
			scr:newMenu( 0, 0, nil, list )
		end
	else
	return function()
			local list = {}
			table.insert( list, { txt = "close all",
			event = nil } )
			table.insert( list, { txt = "(esc to close)",
			} )
			scr:newMenu( 0, 0, nil, list )
		end
	end
end

function spawnSubMenu()
	local list = {
		{ txt = "This is", event=spawnSubSubMenu(2) },
		{ txt = "just an", event=spawnSubSubMenu(2) },
		{ txt = "example sub menu.", event=spawnSubSubMenu(2) },
		{ txt = "It can do", event=spawnSubSubMenu(2) },
		{ txt = "{h}col{g}ors, {f}too.", event=spawnSubSubMenu(2) },
	}
	scr:newMenu( 0,0, nil, list )
end

function spawnInputBox()
	scr:addPanel( "centerPanel", love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2 - 200, 200, 400 )
	scr:addHeader( "centerPanel", "header", 0, 0, "Text Input Test" )
	scr:addText( "centerPanel", "expl1", 10, 20, math.huge, 100, "Below is an input box. By typing the letter infront of it, you'll gain access to the content. Type some text!") 

	scr:addInput( "centerPanel", "firstInput", 0, 100, nil, 50, "t" )
	scr:addText( "centerPanel", "explanation", 10, 200, math.huge, 100, "While typing, other functions are disabled. Finish typing by pressing enter (accept) or escape (reset content).") 
	scr:addFunction( "centerPanel", "close", 0, 340, "Close", "c", function() scr:removePanel( "centerPanel" ) end )
end

function spawnLoginBox()
	scr:addPanel( "centerPanel", love.graphics.getWidth()/2 - 150, love.graphics.getHeight()/2 - 75, 300, 150 )
	scr:addHeader( "centerPanel", "header", 0, 0, "Username:")
	scr:addInput( "centerPanel", "username", 10, 14, nil, 20, "u", checkUser )

	scr:addHeader( "centerPanel", "header2", 0, 26, "Password:")
	scr:addPassword( "centerPanel", "password", 10, 40, nil, 20, "p", checkPassword )
end

function spawnLicense()
	scr:addPanel( "centerPanel", love.graphics.getWidth()/2 - 300, love.graphics.getHeight()/2 - 200, 600, 400 )
	scr:addHeader( "centerPanel", "header", 0, 0, "License:" )

	license = love.filesystem.read("License.txt")
	scr:addText( "centerPanel", "license", 10, 20, math.huge, nil, license )
end

local user, password = "", ""

function checkUser( txt )
	user = txt
	if password and #password > 0 then
		checkPassword( password )
	end
end

function checkPassword( txt )
	password = txt
	if user == "PunchUI" and password == "cake" then
		scr:addText( "centerPanel", "result", 10, 60, math.huge, nil, "Correct Password!" )
	else
		scr:addText( "centerPanel", "result", 10, 60, math.huge, nil, "Wrong login data!\n{g}Try the following...\nUsername: 'PunchUI'\nPassword: 'cake'" )
	end
end

function quit()
	local commands = {}
	commands[1] = { txt = "Yes", key = "y", event = love.event.quit }
	commands[2] = { txt = "No", key = "n" }
	scr:newMsgBox( "Really quit?", "Answering yes will close the app.", nil, nil, nil, commands)
end

function love.update( dt )
	ui:update( dt )
end

function love.draw()
	ui:draw()
end

function love.keypressed( key, unicode )
	ui:keypressed( key, unicode )
end

function love.textinput( letter )
	ui:textinput( letter )
end
