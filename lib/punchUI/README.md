PunchUI
=======

A simple User Interface library for the [Löve2D](http://love2d.org/) engine. No mouse needed - just keyboard controlled.

Update: Mouse control is now optionally available, by calling ui:mousemoved( love.mouse.getPosition() ) once a frame and ui:mousepressed(x, y, button) inside the love.mousepressed event.

Features:
---------
  - no mouse needed
  - resizes content to panel size automatically
  - multiline input box, including password functionality.
  - add actions which are assigned to keys (keys are displayed next to action name)
  - (todo!) tooltip if you press shift + function key
  - message boxes, with header, text and multiple possible answers
  - word wrap
  - multi-colour text boxes
  - drop-down menus
  
Example is included in 'main.lua'. Install Love2D, go to the folder and run:
```love .```

License:
---------
Released under the MIT license, see "License.txt".

Credits:
---------

  - This library uses Kikito's awesome [middleclass](https://github.com/kikito/middleclass) library.
