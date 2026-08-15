-- hs.loadSpoon('ControlEscape'):start() -- Load Hammerspoon bits from https://github.com/jasonrudolph/ControlEscape.spoon
-- hs.loadSpoon('ModalMgr')
hs.loadSpoon('WinWin')

hs.alert.show("Hello World!")

-- resizeM modal environment
if spoon.WinWin then
    local keyCombo = {"cmd", "ctrl"}
    local moveKeyCombo = {"cmd", "ctrl", "shift"}
    local arrows = {
      up = { name = 'up', key = 'K' },
      down = { name = 'down', key = 'J' },
      left = { name = 'left', key = 'H' },
      right = { name = 'right', key = 'L' },
    }

    -- setup window move
    for key, arrow in pairs(arrows) do
      hs.hotkey.bind(moveKeyCombo, arrow.key, function()
        spoon.WinWin:stepMove(arrow.name)
      end)
    end

    -- setup window resizing
    for key, arrow in pairs(arrows) do
      hs.hotkey.bind(keyCombo, arrow.key, function()
        spoon.WinWin:stepResize(arrow.name)
      end)
    end

    hs.hotkey.bind(keyCombo, "R", function()
      local cwin = hs.window.focusedWindow()
      cwin:maximize(0)
    end)

end

-- special layouts
if (#hs.screen.allScreens() > 1)
then
  local secondaryScreen = hs.screen.allScreens()[2]:name()
  local windowLayout = {
      -- {"Atom",   nil, secondaryScreen, hs.layout.left40,  nil, nil},
      -- {"Google Chrome", nil, secondaryScreen, hs.layout.right60, nil, nil},
      {"Atom",   nil, secondaryScreen, hs.geometry.unitrect(0,0,0.45,1),  nil, nil},
      {"Google Chrome", nil, secondaryScreen, hs.geometry.unitrect(0.45,0,0.55,1), nil, nil},
  }

  hs.hotkey.bind({"ctrl", "alt", "cmd"}, 'J', function()
    hs.layout.apply(windowLayout)
    -- hs.alert.show(hs.window.focusedWindow():application():name())
  end)
end

hs.hotkey.bind({"ctrl", "cmd"}, 'f12', function()
  -- hs.alert.show("switch theme")
  hs.execute('~/darkmode.sh');
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "N", function()
  hs.notify.new({
    title = "Hammerspoon Test",
    informativeText = "This is a test notification"
  }):send()
end)

-- reload config
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
hs.alert.show("Config loaded")

-- sleep
hs.hotkey.bind({}, 'f10', function()
  hs.caffeinate.systemSleep()
end)

local function dismissVisibleBanners()
    local script = [[
        tell application "System Events"
            tell process "NotificationCenter"
                try
                    set _groups to groups of UI element 1 of scroll area 1 of group 1 of window "Notification Center"
                    
                    repeat with _group in _groups
                        set _actions to actions of _group
                        
                        repeat with _action in _actions
                            if description of _action is in {"Close All", "Close"} then
                                perform _action
                            end if
                        end repeat
                    end repeat
                end try
                
                key code 53 -- Escape as fallback
            end tell
        end tell
    ]]
    local ok, result = hs.osascript.applescript(script)
    print("ok:", ok, "result:", hs.inspect(result))
end


-- Bind this to a hotkey (e.g., Cmd + Shift + D)
hs.hotkey.bind({"cmd", "ctrl"}, "D", function()
    dismissVisibleBanners()
end)


-- turn off screen immediately
hs.hotkey.bind({"ctrl", "cmd"}, "q", function()
  hs.execute("/usr/bin/pmset displaysleepnow", false)
end)