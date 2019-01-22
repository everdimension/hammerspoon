hs.loadSpoon('ControlEscape'):start() -- Load Hammerspoon bits from https://github.com/jasonrudolph/ControlEscape.spoon
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
