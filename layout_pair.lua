local LayoutPair = {}
LayoutPair.__index = LayoutPair

local function toSet(values)
  local result = {}
  for _, value in ipairs(values or {}) do
    result[value] = true
  end
  return result
end

function LayoutPair.new(options)
  local self = setmetatable({}, LayoutPair)

  self.leftApps = toSet(options.leftApps)
  self.rightApps = toSet(options.rightApps)
  self.raiseBehindApps = toSet(options.raiseBehindApps)
  self.leftLabel = options.leftLabel or "Left"
  self.missingMessage = options.missingMessage or "Open both layout applications first"
  self.initialSplit = options.initialSplit or 0.5
  self.minimumSplit = options.minimumSplit or 0.25
  self.maximumSplit = options.maximumSplit or 0.75
  self.gap = options.gap or 0

  self.active = false
  self.leftID = nil
  self.rightID = nil
  self.screen = nil
  self.split = self.initialSplit
  self.zoomedID = nil
  self.lastFocusedID = nil

  self.appWatcher = hs.application.watcher.new(function(...)
    self:_handleAppEvent(...)
  end)
  self.appWatcher:start()

  return self
end

function LayoutPair:_findWindow(appNames)
  for _, window in ipairs(hs.window.orderedWindows()) do
    local app = window:application()
    if app and appNames[app:name()] and window:isStandard() then
      return window
    end
  end
end

function LayoutPair:_windows()
  if not self.active then
    return nil, nil
  end

  local left = self.leftID and hs.window.get(self.leftID)
  local right = self.rightID and hs.window.get(self.rightID)
  return left, right
end

function LayoutPair:_clear()
  self.active = false
  self.leftID = nil
  self.rightID = nil
  self.screen = nil
  self.zoomedID = nil
  self.lastFocusedID = nil
end

function LayoutPair:_resolve(showAlert)
  local left, right = self:_windows()
  if left and right then
    return left, right
  end

  self:_clear()
  if showAlert then
    hs.alert.show("Pair mode ended: a paired window is unavailable")
  end
  return nil, nil
end

function LayoutPair:_apply()
  if not self.active then
    hs.alert.show("Pair mode is off")
    return false
  end

  local left, right = self:_resolve(true)
  if not left then
    return false
  end

  local frame = (self.screen or left:screen()):frame()
  local availableWidth = frame.w - self.gap
  local leftWidth = math.floor(availableWidth * self.split)

  left:setFrame({
    x = frame.x,
    y = frame.y,
    w = leftWidth,
    h = frame.h,
  }, 0)
  right:setFrame({
    x = frame.x + leftWidth + self.gap,
    y = frame.y,
    w = availableWidth - leftWidth,
    h = frame.h,
  }, 0)

  self.zoomedID = nil
  return true
end

function LayoutPair:_bringForward(preferredID)
  local left, right = self:_resolve(true)
  if not left then
    return false
  end

  if self.zoomedID then
    local zoomed = hs.window.get(self.zoomedID)
    if zoomed then
      self.lastFocusedID = zoomed:id()
      zoomed:focus()
      return true
    end
  end

  local activeWindow = preferredID == right:id() and right or left
  local partnerWindow = activeWindow:id() == left:id() and right or left
  self.lastFocusedID = activeWindow:id()
  activeWindow:focus()
  partnerWindow:raise()
  return true
end

function LayoutPair:_raiseBehind(frontWindow, left, right)
  local preferredID = self.zoomedID or self.lastFocusedID
  if preferredID == left:id() then
    right:raise()
    left:raise()
  else
    left:raise()
    right:raise()
  end
  frontWindow:raise()
end

function LayoutPair:_activate()
  local left = self:_findWindow(self.leftApps)
  local right = self:_findWindow(self.rightApps)

  if not left or not right then
    hs.alert.show(self.missingMessage)
    return
  end

  local focused = hs.window.focusedWindow()
  self.active = true
  self.leftID = left:id()
  self.rightID = right:id()
  self.screen = focused and focused:screen() or left:screen()
  self.zoomedID = nil
  self.lastFocusedID = left:id()
  if focused and focused:id() == right:id() then
    self.lastFocusedID = right:id()
  end

  self:_apply()
  self:_bringForward(self.lastFocusedID)
  hs.alert.show("Pair mode on")
end

function LayoutPair:toggle()
  if not self.active then
    self:_activate()
    return
  end

  local left, right = self:_windows()
  if not left or not right then
    self:_clear()
    self:_activate()
    return
  end

  if self.zoomedID then
    local preferredID = self.zoomedID
    if self:_apply() then
      self:_bringForward(preferredID)
    end
    return
  end

  local focused = hs.window.focusedWindow()
  local focusedID = focused and focused:id()
  local pairIsFocused = focusedID == left:id() or focusedID == right:id()

  if not pairIsFocused then
    self:_bringForward(self.lastFocusedID)
    return
  end

  self:_clear()
  hs.alert.show("Pair mode off")
end

function LayoutPair:adjustSplit(delta)
  self.split = math.max(
    self.minimumSplit,
    math.min(self.maximumSplit, self.split + delta)
  )

  if self:_apply() then
    local percentage = math.floor(self.split * 100 + 0.5)
    hs.alert.show(string.format("%s %d%%", self.leftLabel, percentage))
  end
end

function LayoutPair:toggleZoom()
  local left, right = self:_windows()
  local focused = hs.window.focusedWindow()

  if not focused then
    hs.alert.show("No focused window")
    return
  end

  if not left or not right then
    if self.active then
      self:_clear()
    end
    focused:maximize(0)
    return
  end

  local focusedID = focused:id()
  if focusedID ~= left:id() and focusedID ~= right:id() then
    focused:maximize(0)
    return
  end

  if self.zoomedID == focusedID then
    self:_apply()
    self:_bringForward(focusedID)
    return
  end

  if self.zoomedID then
    self:_apply()
  end

  self.zoomedID = focusedID
  self.lastFocusedID = focusedID
  focused:setFrame((self.screen or focused:screen()):frame(), 0)
  focused:raise()
  focused:focus()
end

function LayoutPair:_handleAppEvent(_, event, app)
  if event ~= hs.application.watcher.activated
      or not self.active
      or not app then
    return
  end

  local left, right = self:_windows()
  if not left or not right then
    self:_clear()
    return
  end

  local appFocusedWindow = app:focusedWindow()
  if self.raiseBehindApps[app:name()] then
    if appFocusedWindow then
      self:_raiseBehind(appFocusedWindow, left, right)
    end
    return
  end

  if self.zoomedID then
    return
  end

  local leftApp = left:application()
  local rightApp = right:application()
  local activatedPID = app:pid()
  local activeWindow

  if leftApp and activatedPID == leftApp:pid() then
    activeWindow = left
  elseif rightApp and activatedPID == rightApp:pid() then
    activeWindow = right
  else
    return
  end

  if not appFocusedWindow or appFocusedWindow:id() ~= activeWindow:id() then
    return
  end

  self.lastFocusedID = activeWindow:id()
  local partnerWindow = activeWindow:id() == left:id() and right or left
  partnerWindow:raise()
end

return LayoutPair
