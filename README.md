
Grid Cars - a competitive racing game
============================================

Ludum Dare 31 entry. Base game made in one weekend.

Multiplayer only! This game is intended as an "in-betweener" at LAN Parties.

All cars are grid based. You have 10 seconds to make your move. Your velocity is "saved" between moves -
so the faster you went last round, the further you can go this round!

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
You can create your own maps in any modeling program - we used Blender3D (export as .stl).

[Map making tutorial](http://www.indiedb.com/games/gridcars/tutorials/create-new-custom-maps)

Once you have a cool map, send it to us, so we can share it!
gridcars [at] gmail.com

Server Options:
----------------------
See the [SERVER_SETUP.md](SERVER_SETUP.md) for instructions on configuring your own server.

Credits:
----------------------
Ramona B. (Graphics)
Peter Z. (Additional Maps)
Broozar (Additional Maps)
Dudenheit (Programming)
Germanunkol (Programming)

Libraries Used:
----------------------
middleclass (kikito): https://github.com/kikito/middleclass
hump (vrld): http://vrld.github.io/hump/
PunchUI (Germanunkol): https://github.com/Germanunkol/PunchUI
Affair (Germanunkol): https://github.com/Germanunkol/Affair

Links + Download:
----------------------
There are binaries available at:
http://germanunkol.de/gridcars/

Also, the source code can be run directly with the [Löve2D engine](https://love2d.org/):
```bash
cd Path/To/GridCars
love .
```

License:
----------------------
Released under MIT license (see License.txt).
For the licenses of the libraries, check out the respective License files.
Beep sound from "jobro" on freesound.org: http://www.freesound.org/people/jobro/sounds/33788/ (Creative Commons)
