
Grid Cars - a competitive racing game
============================================

Ludum Dare 31 entry. Made in one weekend.

Multiplayer only! This game is intended as an "in-betweener" at LAN Parties.

All cars are grid based. You have 10 seconds to make your move. Your velocity is "saved" between moves -
so the faster you went last round, the further you can go this round!
Careful: you WILL probably crash.

NOTE: In the main menu, press 'i' to enter ip address, then 'c' to connect.

Make sure to send us your custom maps if you make them!

Features:
---------------------
- Multiplayer!
- Custom maps!
- Absolutely no sounds.
- Full map really DOES fit onto one screen (zoom out to see) :P
- Configurable. Take the config.lua (see github link below) and put it in:
"%APPDATA%/LOVE/GridWars/ (Win)
~/.local/share/love/GridWars (Linux + Max)

CUSTOM MAPS:
----------------------
You can create your own maps in any modeling program - we used Blender3D (export as .stl). More detailed info might come later. Until then, use this to get you started:
- Download and import the maps found in the maps folder (see github link below)
- Put the entire map into one object (in case your modeller allows multiple)
- Put the roads themselves onto the z=0.0 layer
- Add a triangle at z=2.0 -> this defines the start line and direction
- Add lots of small triangles at z=3.0, these are the start positions.
Just check out the sample maps in the maps/ folder - it's pretty straight forward!

Once you have a cool map, send it to us, so we can share it!
gridcars [at] gmail.com

Credits:
----------------------
Ramona B. (Graphics)
Peter Z. (Additional Maps)
Dudenheit (Programming)
Germanunkol (Programming)

Libraries Used:
----------------------
middleclass (kikito): https://github.com/kikito/middleclass
hump (vrld): http://vrld.github.io/hump/
PunchUI (Germanunkol): https://github.com/Germanunkol/PunchUI

Disclaimer:
----------------------
Made in 72 hours or less...
However, we started a little early (half day) on the network library, because of time shift issues (we can't really work on monday, and the jam started at 3 in the morning, here. So we would otherwise only have had about 48 hours. Forgive us.)

Links + Download:
----------------------
Game (Win): 
http://germanunkol.de/gridcars/downloads/GridCars.zip

Game (Linux and Max - Install the love 2d engine from your repositories or from love2d.org):
http://germanunkol.de/gridcars/downloads/GridCars.love

Source code on Github: 
https://github.com/Germanunkol/Cars

Known Issues:
----------------------
Sometimes the map is not fully sent to the client. In this case (if the map is no closed loop on the client), simply reload the map on the server. This has never happened in the LAN, but has been seen when playing with other servers on the web.
