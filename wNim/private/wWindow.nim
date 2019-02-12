#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2018 Ward
#
#====================================================================

## *wWindow* is the base for all windows and represents any visible object on
## screen.
#
## :Superclass:
##   `wResizable <wResizable.html>`_
#
## :Subclasses:
##   `wFrame <wFrame.html>`_
##   `wPanel <wPanel.html>`_
##   `wControl <wControl.html>`_
#
## :Seealso:
##   `wEvent <wEvent.html>`_
#
## :Styles:
##   ==============================  =============================================================
##   Styles                          Description
##   ==============================  =============================================================
##   wBorderSimple                   Displays a thin border around the window.
##   wBorderSunken                   Displays a sunken border.
##   wBorderRaised                   Displays a raised border.
##   wBorderStatic                   Displays a border suitable for a static control.
##   wBorderDouble                   Displays a double border.
##   wTransparentWindow              The window is transparent.
##   wDoubleBuffered                 The window is double-buffered.
##   wVScroll                        Use this style to enable a vertical scrollbar.
##   wHScroll                        Use this style to enable a horizontal scrollbar.
##   wClipChildren                   Use this style to eliminate flicker caused by the background being repainted, then children being painted over them.
##   wHideTaskbar                    Use this style to hide the taskbar item (top-level window only).
##   wInvisible                      The window is initially invisible (child window is visible by default).
##   wPopup                          The window is a pop-up window (WS_POPUP).
##   wPopupWindow                    The window is a pop-up window (WS_POPUPWINDOW).
##   ==============================  =============================================================
#
## :Events:
##   - `wMouseEvent <wMouseEvent.html>`_
##   - `wKeyEvent <wKeyEvent.html>`_
##   - `wSizeEvent <wSizeEvent.html>`_
##   - `wMoveEvent <wMoveEvent.html>`_
##   - `wSetCursorEvent <wSetCursorEvent.html>`_
##   - `wContextMenuEvent <wContextMenuEvent.html>`_
##   - `wScrollWinEvent <wScrollWinEvent.html>`_
##   - `wDragDropEvent <wDragDropEvent.html>`_

# forward declarations
proc getScrollInfo(self: wScrollBar): SCROLLINFO
proc setScrollPos*(self: wScrollBar, position: int)

const
  wBorderSimple* = WS_BORDER
  wBorderSunken* = WS_EX_CLIENTEDGE shl 32
  wBorderRaised* = WS_EX_WINDOWEDGE shl 32
  wBorderStatic* = WS_EX_STATICEDGE shl 32
  wBorderDouble* = WS_EX_DLGMODALFRAME shl 32
  wTransparentWindow* = WS_EX_TRANSPARENT shl 32
  wDoubleBuffered* = WS_EX_COMPOSITED shl 32
  wVScroll* = WS_VSCROLL
  wHScroll* = WS_HSCROLL
  wClipChildren* = WS_CLIPCHILDREN
  wHideTaskbar* = 0x10000000 shl 32
  wInvisible* = 0x20000000 shl 32
  wPopup* = int64 cast[uint32](WS_POPUP) # WS_POPUP is 0x80000000L
  wPopupWindow* = int64 cast[uint32](WS_POPUPWINDOW)

const
  wModShift* = MOD_SHIFT
  wModCtrl* = MOD_CONTROL
  wModAlt* = MOD_ALT
  wModWin* = MOD_WIN

method getWindowRect(self: wWindow, sizeOnly = false): wRect {.base.} =
  var rect: RECT
  GetWindowRect(self.mHwnd, rect)

  result.width = (rect.right - rect.left)
  result.height = (rect.bottom - rect.top)

  if not sizeOnly:
    if self.mParent != nil:
      ScreenToClient(self.mParent.mHwnd, cast[ptr POINT](addr rect))

    result.x = rect.left
    result.y = rect.top

method setWindowRect(self: wWindow, x, y, width, height, flag = 0)
    {.base, inline.} =
  # must use SWP_NOACTIVATE or window will steal focus after setsize
  SetWindowPos(self.mHwnd, 0, x, y, width, height,
    UINT(flag or SWP_NOZORDER or SWP_NOREPOSITION or SWP_NOACTIVATE))

proc setWindowSize(self: wWindow, width, height: int) {.inline.} =
  self.setWindowRect(0, 0, width, height, SWP_NOMOVE)

proc setWindowPos(self: wWindow, x, y: int) {.inline.} =
  self.setWindowRect(x, y, 0, 0, SWP_NOSIZE)

method getClientSize*(self: wWindow): wSize {.base, property.} =
  ## Returns the size of the window 'client area' in pixels.
  var r: RECT
  GetClientRect(self.mHwnd, r)
  result.width = r.right - r.left - (self.mMargin.left + self.mMargin.right)
  result.height = r.bottom - r.top - (self.mMargin.up + self.mMargin.down)

  if self.mToolBar != nil:
    let rect = self.mToolBar.getWindowRect()
    case toolBarDirection(self.mToolBar.mHwnd)
    of wTop, wBottom:
      result.height -= rect.height

    of wRight:
      result.width -= rect.width

    of wLeft:
      result.width -= rect.width + rect.x

    else: discard

  if self.mRebar != nil:
    let rect = self.mRebar.getWindowRect()
    result.height -= rect.height

  if self.mStatusBar != nil:
    let rect = self.mStatusBar.getWindowRect(sizeOnly=true)
    result.height -= rect.height

method getClientAreaOrigin*(self: wWindow): wPoint {.base, property.} =
  ## Gets the origin of the client area of the window relative to the window
  ## top left corner (the client area may be shifted because of the borders,
  ## scrollbars, other decorations...).
  result.x = self.mMargin.left
  result.y = self.mMargin.up
  if self.mToolBar != nil:
    let rect = self.mToolBar.getWindowRect()
    case toolBarDirection(self.mToolBar.mHwnd)
    of wTop:
      result.y += rect.height + rect.y
    of wLeft:
      result.x += rect.width + rect.x
    else: discard

  if self.mRebar != nil:
    let rect = self.mRebar.getWindowRect()
    result.y += rect.height + rect.y

proc adjustForParentClientOriginAdd(self: wWindow, x, y: var int) =
  if self.mParent != nil:
    let point = self.mParent.getClientAreaOrigin()
    x += point.x
    y += point.y

proc adjustForParentClientOriginSub(self: wWindow, x, y: var int) =
  if self.mParent != nil:
    let point = self.mParent.getClientAreaOrigin()
    x -= point.x
    y -= point.y

proc getMargin*(self: wWindow): wDirection {.validate, property, inline.} =
  ## Gets the margin setting of the window.
  ## Margin is the extra space around the client area..
  result = self.mMargin

proc setMarginX*(self: wWindow, margin: int) {.validate, property, inline.}=
  ## Sets the x-axis margin..
  self.mMargin.left = margin
  self.mMargin.right = margin

proc setMarginY*(self: wWindow, margin: int) {.validate, property, inline.}=
  ## Sets the y-axis margin.
  self.mMargin.up = margin
  self.mMargin.down = margin

proc setMargin*(self: wWindow, margin: int) {.validate, property, inline.}=
  ## Sets the window margins to the same value.
  self.mMargin = (margin, margin, margin, margin)

proc setMargin*(self: wWindow, margin: wDirection) {.validate, property, inline.}=
  ## Sets the window margins.
  self.mMargin = margin

proc setMarginLeft*(self: wWindow, margin: int) {.validate, property, inline.} =
  ## Sets the left margin
  self.mMargin.left = margin

proc setMarginUp*(self: wWindow, margin: int) {.validate, property, inline.} =
  ## Sets the up margin
  self.mMargin.up = margin

proc setMarginRight*(self: wWindow, margin: int) {.validate, property, inline.} =
  ## Sets the right margin
  self.mMargin.right = margin

proc setMarginDown*(self: wWindow, margin: int) {.validate, property, inline.} =
  ## Sets the down margin
  self.mMargin.down = margin

proc close*(self: wWindow) {.validate, inline.} =
  ## This function simply generates a wEvent_Close whose handler usually tries
  ## to close the window.
  SendMessage(self.mHwnd, WM_CLOSE, 0, 0)

proc delete*(self: wWindow) {.validate, inline.} =
  ## Destroys the window.
  DestroyWindow(self.mHwnd)

proc destroy*(self: wWindow) {.validate, inline.} =
  ## Destroys the window. The same as delete().
  self.delete()

method release(self: wWindow) {.base, inline.} =
  # override this if a window need extra code to release the resource
  # delete only destroy the window
  # really resoruce clear is in WM_NCDESTROY
  discard

method trigger(self: wWindow) {.base, inline.} =
  # override this if a window need extra init after window create.
  # similar to WM_CREATE.
  discard

proc move*(self: wWindow, x: int, y: int) {.validate.} =
  ## Moves the window to the given position.
  ## wDefault to indicate not to change.
  var
    xx = x
    yy = y

  self.adjustForParentClientOriginAdd(xx, yy)

  if x == wDefault or y == wDefault:
    let rect = self.getWindowRect()
    if x == wDefault: xx = rect.x
    if y == wDefault: yy = rect.y

  self.setWindowPos(xx, yy)

proc move*(self: wWindow, pos: wPoint) {.validate, inline.} =
  ## Moves the window to the given position.
  ## wDefault to indicate not to change.
  move(self, pos.x, pos.y)

proc setPosition*(self: wWindow, pos: wPoint) {.validate, property, inline.} =
  ## Moves the window to the specified position. The same as move().
  ## wDefault to indicate not to change.
  move(self, pos.x, pos.y)

proc setPosition*(self: wWindow, x: int, y: int) {.validate, property, inline.} =
  ## Moves the window to the specified position. The same as move().
  ## wDefault to indicate not to change.
  move(self, x, y)

proc setSize*(self: wWindow, width: int, height: int) {.validate, property.} =
  ## Sets the size of the window in pixels.
  ## wDefault to indicate not to change.
  var
    ww = width
    hh = height

  if width == wDefault or height == wDefault:
    let rect = self.getWindowRect()
    if width == wDefault: ww = rect.width
    if height == wDefault: hh = rect.height

  self.setWindowSize(ww, hh)

proc setSize*(self: wWindow, x: int, y: int, width: int, height: int)
    {.validate, property.} =
  ## Sets the size of the window in pixels.
  ## wDefault to indicate not to change.
  var
    xx = x
    yy = y
    ww = width
    hh = height

  self.adjustForParentClientOriginAdd(xx, yy)

  if x == wDefault or y == wDefault or width == wDefault or height == wDefault:
    let rect = self.getWindowRect()
    if x == wDefault: xx = rect.x
    if y == wDefault: yy = rect.y
    if width == wDefault: ww = rect.width
    if height == wDefault: hh = rect.height

  self.setWindowRect(xx, yy, ww, hh)

proc setSize*(self: wWindow, size: wSize) {.validate, property, inline.} =
  ## Sets the size of the window in pixels.
  ## wDefault to indicate not to change.
  self.setSize(size.width, size.height)

proc setSize*(self: wWindow, point: wPoint, size: wSize)
    {.validate, property, inline.} =
  ## Sets the size of the window in pixels.
  ## wDefault to indicate not to change.
  self.setSize(point.x, point.y, size.width, size.height)

proc setSize*(self: wWindow, rect: wRect) {.validate, property, inline.} =
  ## Sets the size of the window in pixels.
  ## wDefault to indicate not to change.
  self.setSize(rect.x, rect.y, rect.width, rect.height)

proc getSize*(self: wWindow): wSize {.validate, property, inline.} =
  ## Returns the size of the entire window in pixels.
  let rect = self.getWindowRect(sizeOnly=true)
  result.width = rect.width
  result.height = rect.height

proc getRect*(self: wWindow): wRect {.validate, property.} =
  ## Returns the position and size of the window as a wRect object.
  result = self.getWindowRect()
  self.adjustForParentClientOriginSub(result.x, result.y)

proc getPosition*(self: wWindow): wPoint {.validate, property.} =
  ## Gets the position of the window in pixels.
  let rect = self.getWindowRect()
  result.x = rect.x
  result.y = rect.y
  self.adjustForParentClientOriginSub(result.x, result.y)

method getDefaultSize*(self: wWindow): wSize {.base, property, inline.} =
  ## Returns the system suggested size of a window (usually used for GUI controls).
  # window's default size is it's parent's clientSize, or 0, 0 by default
  if self.mParent != nil:
    result = self.mParent.getClientSize()

proc getClientMargin*(self: wWindow, direction: int): int {.validate, property.} =
  ## Returns the client margin of the specified direction.
  ## This function basically exists for wNim's layout DSL.
  result = case direction
  of wLeft:
    self.getClientAreaOrigin().x
  of wTop:
    self.getClientAreaOrigin().y
  of wRight:
    self.getSize().width - self.getClientSize().width - self.getClientAreaOrigin().x
  of wBottom:
    self.getSize().height - self.getClientSize().height - self.getClientAreaOrigin().y
  else: 0

proc getClientMargins*(self: wWindow): tuple[left, top, right, bottom: int]
    {.validate, property.} =
  ## Returns client margin of all the direction.
  let pos = self.getClientAreaOrigin()
  let size = self.getSize()
  let clientSize = self.getClientSize()

  result.left = pos.x
  result.top = pos.y
  result.right = size.width - clientSize.width - pos.x
  result.bottom = size.height - clientSize.height - pos.y

proc clientToWindow(self: wWindow, size: wSize): wSize {.validate.} =
  let
    clientSize = self.getClientSize()
    windowSize = self.getSize()

  result = size

  if size.width != wDefault:
    result.width += windowSize.width - clientSize.width

  if size.height != wDefault:
    result.height += windowSize.height - clientSize.height

method getBestSize*(self: wWindow): wSize {.base, property.} =
  ## Returns the best acceptable minimal size for the window
  ## (usually used for GUI controls).
  if self.mChildren.len == 0:
    result = self.getSize()
  else:
    var width, height: int = 0
    for child in self.mChildren:
      let rect = child.getRect()
      width = max(width, rect.x + rect.width)
      height = max(height, rect.y + rect.height)
    result = self.clientToWindow((width, height))

proc fit*(self: wWindow) {.validate, inline.} =
  ## Sizes the window to fit its best size.
  self.setSize(self.getBestSize())

proc suit*(self: wWindow) {.validate, inline.} =
  ## Sizes the window to suit its default size.
  self.setSize(self.getDefaultSize())

proc setClientSize*(self: wWindow, size: wSize) {.validate, property.} =
  ## This sets the size of the window client area in pixels.
  for i in 1..4:
    let clientSize = self.getClientSize()
    if (clientSize.width == size.width or size.width == wDefault) and
        (clientSize.height == size.height or size.height == wDefault):
      break
    self.setSize(self.clientToWindow(size))

proc setClientSize*(self: wWindow, width: int, height: int) {.validate, property.} =
  ## This sets the size of the window client area in pixels.
  self.setClientSize((width, height))

proc contain*(self: wWindow, windows: varargs[wWindow, wWindow]) {.validate.} =
  ## Sizes the window to contain all the specified windows.
  ## Basically used by staticbox control.
  var width, height: int
  var x, y = int.high

  for i in 0..<windows.len:
    let win = windows[i]
    wValidate(win)
    let pos = win.getPosition()
    x = min(x, pos.x)
    y = min(y, pos.y)

  for i in 0..<windows.len:
    let win = windows[i]
    let rect = win.getRect()

    width = max(width, rect.x + rect.width - x)
    height = max(height, rect.y + rect.height - y)

  let margins = self.getClientMargins()
  x -= margins.left
  y -= margins.top
  width += margins.left + margins.right
  height += margins.top + margins.bottom
  self.setSize(x, y, width, height)

proc setMinSize*(self: wWindow, size: wSize) {.validate, property.} =
  ## Sets the minimum size of the window.
  self.mMinSize = size
  var
    currentSize = self.getSize()
    adjustSize = wDefaultSize

  if currentSize.width < size.width: adjustSize.width = size.width
  if currentSize.height < size.height: adjustSize.height = size.height
  if adjustSize != wDefaultSize: self.setSize(adjustSize)

proc setMinSize*(self: wWindow, x: int, y: int) {.validate, property, inline.} =
  ## Sets the minimum size of the window.
  self.setMinSize((x, y))

proc getMinSize*(self: wWindow): wSize {.validate, property, inline.} =
  ## Returns the minimum size of the window.
  result = self.mMinSize

proc setMaxSize*(self: wWindow, size: wSize) {.validate, property.} =
  ## Sets the maximum size of the window.
  self.mMaxSize = size
  var
    currentSize = self.getSize()
    adjustSize = wDefaultSize

  if currentSize.width > size.width: adjustSize.width = size.width
  if currentSize.height > size.height: adjustSize.height = size.height
  if adjustSize != wDefaultSize: self.setSize(adjustSize)

proc setMaxSize*(self: wWindow, x: int, y: int) {.validate, property, inline.} =
  ## Sets the maximum size of the window.
  self.setMaxSize((x, y))

proc getMaxSize*(self: wWindow): wSize {.validate, property, inline.} =
  ## Returns the maximum size of the window.
  result = self.mMaxSize

proc setMinClientSize*(self: wWindow, size: wSize) {.validate, property, inline.} =
  ## Sets the minimum client size of the window.
  self.setMinSize(self.clientToWindow(size))

proc setMinClientSize*(self: wWindow, x: int, y: int) {.validate, property, inline.} =
  ## Sets the minimum client size of the window.
  self.setMinSize(self.clientToWindow((x, y)))

proc setMaxClientSize*(self: wWindow, size: wSize) {.validate, property, inline.} =
  ## Sets the maximum client size of the window
  self.setMaxSize(self.clientToWindow(size))

proc setMaxClientSize*(self: wWindow, x: int, y: int) {.validate, property, inline.} =
  ## Sets the maximum client size of the window
  self.setMaxSize(self.clientToWindow((x, y)))

proc screenToClient*(self: wWindow, pos: wPoint): wPoint {.validate.} =
  ## Converts from screen to client window coordinates.
  var p: POINT
  p.x = pos.x
  p.y = pos.y
  ScreenToClient(self.mHwnd, p)
  let point = self.getClientAreaOrigin()
  result.x = (if pos.x != wDefault: int(p.x - point.x) else: wDefault)
  result.y = (if pos.y != wDefault: int(p.y - point.y) else: wDefault)

proc clientToScreen*(self: wWindow, pos: wPoint): wPoint {.validate.} =
  ## Converts to screen coordinates from coordinates relative to this window.
  var p: POINT
  let point = self.getClientAreaOrigin()
  p.x = int32(pos.x + point.x)
  p.y = int32(pos.y + point.y)
  ClientToScreen(self.mHwnd, p)
  result.x = (if pos.x != wDefault: p.x.int else: wDefault)
  result.y = (if pos.y != wDefault: p.y.int else: wDefault)

proc getWindowStyle*(self: wWindow): wStyle {.validate, property.} =
  ## Gets the wNim's window style.
  ## It simply combine of windows' style and exstyle.
  result = towStyle(DWORD GetWindowLongPtr(self.mHwnd, GWL_STYLE),
    DWORD GetWindowLongPtr(self.mHwnd, GWL_EXSTYLE))

proc setWindowStyle*(self: wWindow, style: wStyle) {.validate, property.} =
  ## Sets the style of the window.
  let
    msStyle = LONG_PTR(style and 0xFFFFFFFF)
    exStyle = LONG_PTR(style shr 32)

  SetWindowLongPtr(self.mHwnd, GWL_STYLE, msStyle)
  SetWindowLongPtr(self.mHwnd, GWL_EXSTYLE, exStyle)

proc addWindowStyle*(self: wWindow, style: wStyle) {.validate, inline.} =
  ## Add the specified style but don't change other styles.
  self.setWindowStyle(self.getWindowStyle() or style)

proc clearWindowStyle*(self: wWindow, style: wStyle) {.validate, inline.} =
  ## Clear the specified style but don't change other styles.
  self.setWindowStyle(self.getWindowStyle() and (not style))

proc refresh*(self: wWindow, eraseBackground = true) {.validate.} =
  ## Redraws the contents of the window.
  InvalidateRect(self.mHwnd, nil, eraseBackground)

proc refresh*(self: wWindow, eraseBackground = true, rect: wRect) {.validate.} =
  ## Redraws the contents of the given rectangle: only the area inside it will
  ## be repainted.
  var r = rect.toRECT()
  InvalidateRect(self.mHwnd, r, eraseBackground)

method show*(self: wWindow, flag = true) {.base, inline.} =
  ## Shows or hides the window.
  ShowWindow(self.mHwnd, if flag: SW_SHOWNORMAL else: SW_HIDE)

proc hide*(self: wWindow) {.validate, inline.} =
  ## Hides the window.
  self.show(false)

proc isShownOnScreen*(self: wWindow): bool {.validate, inline.} =
  ## Returns true if the window is physically visible on the screen.
  ## i.e. it is shown and all its parents up to the toplevel window are shown
  ## as well.
  result = bool IsWindowVisible(self.mHwnd)

proc isShown*(self: wWindow): bool {.validate.} =
  ## Returns true if the window is shown, false if it has been hidden.
  if (GetWindowLongPtr(self.mHwnd, GWL_STYLE).DWORD and WS_VISIBLE) == 0:
    result = false
  else:
    result = true

proc enable*(self: wWindow, flag = true) {.validate, inline.} =
  ## Enable or disable the window for user input.
  EnableWindow(self.mHwnd, if flag: 1 else: 0)

proc disable*(self: wWindow) {.validate, inline.} =
  ## Disables the window.
  self.enable(false)

proc isEnabled*(self: wWindow): bool {.validate, inline.} =
  ## Returns true if the window is enabled.
  result = bool IsWindowEnabled(self.mHwnd)

proc setFocus*(self: wWindow) {.validate.} =
  ## This sets the window to receive keyboard input.
  # draw focus rect
  if self.mParent != nil:
    SendMessage(self.mParent.mHwnd, WM_UPDATEUISTATE,
      MAKEWPARAM(UIS_CLEAR, UISF_HIDEFOCUS), 0)

  if GetFocus() == self.mHwnd:
    discard SendMessage(self.mHwnd, WM_SETFOCUS, self.mHwnd, 0) # a compiler bug here
  else:
    SetFocus(self.mHwnd)

proc isFocusable*(self: wWindow): bool {.validate, inline.} =
  ## Can this window itself have focus?
  if IsWindowVisible(self.mHwnd) != 0 and IsWindowEnabled(self.mHwnd) != 0 and
      self.mFocusable:

    result = true

proc captureMouse*(self: wWindow) {.validate, inline.} =
  ## Directs all mouse input to this window.
  SetCapture(self.mHwnd)

proc releaseMouse*(self: wWindow) {.validate, inline.} =
  ## Releases mouse input captured with CaptureMouse().
  ReleaseCapture()

proc hasCapture*(self: wWindow): bool {.validate, inline.} =
  ## Returns true if this window has the current mouse capture.
  result = (self.mHwnd == GetCapture())

proc getHandle*(self: wWindow): HANDLE {.validate, property, inline.} =
  ## Returns the system HWND of this window.
  result = self.mHwnd

proc getParent*(self: wWindow): wWindow {.validate, property, inline.} =
  ## Returns the parent of the window.
  result = self.mParent

proc getForegroundColor*(self: wWindow): wColor {.validate, property, inline.} =
  ## Returns the foreground color of the window.
  result = self.mForegroundColor

proc getBackgroundColor*(self: wWindow): wColor {.validate, property, inline.} =
  ## Returns the background color of the window.
  result = self.mBackgroundColor

proc getFont*(self: wWindow): wFont {.validate, property, inline.} =
  ## Returns the font for this window.
  result = self.mFont

proc getStatusBar*(self: wWindow): wStatusBar {.validate, property, inline.} =
  ## Returns the status bar currently associated with the window.
  result = self.mStatusBar

proc getId*(self: wWindow): wCommandID {.validate, property, inline.} =
  ## Returns the identifier of the window.
  result = wCommandID GetWindowLongPtr(self.mHwnd, GWLP_ID)

proc getTitle*(self: wWindow): string {.validate, property.} =
  ## Returns the title of the window.
  var
    maxLen = GetWindowTextLength(self.mHwnd) + 1
    title = T(maxLen + 2)

  title.setLen(GetWindowText(self.mHwnd, &title, maxLen))
  result = $title

proc getLabel*(self: wWindow): string {.validate, property, inline.} =
  ## Returns the label of the window. The same as getTitle().
  result = self.getTitle()

proc getChildren*(self: wWindow): seq[wWindow] {.validate, property, inline.} =
  ## Returns a seq of the window's children.
  result = self.mChildren

proc getTopParent*(self: wWindow): wWindow {.validate, property.} =
  ## Returns the first top level parent of the given window.
  result = self
  while result.mParent != nil:
    result = result.mParent

proc getNextSibling*(self: wWindow): wWindow {.validate, property.} =
  ## Returns the next window after this one among the parent's children.
  if self.mParent != nil:
    for i, win in self.mParent.mChildren:
      if win == self:
        if i + 1 < self.mParent.mChildren.len:
          result = self.mParent.mChildren[i + 1]
        break

proc getPrevSibling*(self: wWindow): wWindow {.validate, property.} =
  ## Returns the previous window before this one among the parent's children.
  if self.mParent != nil:
    for i, win in self.mParent.mChildren:
      if win == self:
        if i > 0:
          result = self.mParent.mChildren[i - 1]
        break

proc isDescendant*(self: wWindow, win: wWindow): bool {.validate.} =
  ## Check if the specified window is a descendant of this one.
  wValidate(win)
  var win = win
  while win != nil:
    if win == self: return true
    win = win.mParent

proc isTopLevel*(self: wWindow): bool {.validate.} =
  ## Returns true if the given window is a top-level one.
  result = self.mParent == nil

proc setParent*(self: wWindow, parent: wWindow): bool
    {.validate, property, discardable.} =
  ## Set the window's parent, i.e. the window will be removed from its current
  ## parent window and then re-inserted into another.
  ## Warning: this is a dangerous action and some control may work incorrectly
  ## after changing the parent.
  wValidate(parent)
  if self.mParent != nil and SetParent(self.mHwnd, parent.mHwnd) != 0:
    let index = self.mParent.mChildren.find(self)
    if index != -1:
      self.mParent.mChildren.delete(index)

    self.mParent = parent
    parent.mChildren.add(self)
    return true

proc reparent*(self: wWindow, parent: wWindow): bool
    {.validate, inline, discardable.} =
  ## Reparents the window. The same as setParent().
  wValidate(parent)
  self.setParent(parent)

method setForegroundColor*(self: wWindow, color: wColor)
    {.base, property, inline.} =
  ## Sets the foreground color of the window.
  self.mForegroundColor = color

method setBackgroundColor*(self: wWindow, color: wColor) {.base, property.} =
  ## Sets the background color of the window.
  self.mBackgroundColor = color
  self.mBackgroundBrush = Brush(color)
  SetClassLongPtr(self.mHwnd, GCL_HBRBACKGROUND,
    cast[LONG_PTR](self.mBackgroundBrush.mHandle))
  self.refresh()

proc setId*(self: wWindow, id: wCommandID)  {.validate, property, inline.} =
  ## Sets the identifier of the window.
  SetWindowLongPtr(self.mHwnd, GWLP_ID, int id)

proc setTitle*(self: wWindow, title: string) {.validate, property, inline.} =
  ## Sets the window's title.
  wValidate(title)
  SetWindowText(self.mHwnd, title)

proc setLabel*(self: wWindow, label: string) {.validate, property, inline.} =
  ## Sets the window's label. The same as setTitle().
  wValidate(label)
  SetWindowText(self.mHwnd, label)

proc setFont*(self: wWindow, font: wFont) {.validate, property.} =
  ## Sets the font for this window.
  wValidate(font)
  self.mFont = font
  SendMessage(self.mHwnd, WM_SETFONT, font.mHandle, 1)

proc setTransparent*(self: wWindow, alpha: range[0..255]) {.validate, property.} =
  # Set the window to be translucent. A value of 0 sets the window to be fully
  # transparent.
  SetWindowLongPtr(self.mHwnd, GWL_EXSTYLE,
    WS_EX_LAYERED or GetWindowLongPtr(self.mHwnd, GWL_EXSTYLE))

  SetLayeredWindowAttributes(self.mHwnd, 0, alpha, LWA_ALPHA)

proc getTransparent*(self: wWindow): int {.validate, property.} =
  ## Get the alpha value of a transparent window. Return -1 if failed.
  var alpha: byte
  if GetLayeredWindowAttributes(self.mHwnd, nil, &alpha, nil) == 0: return -1
  result = int alpha

proc setAcceleratorTable*(self: wWindow, accel: wAcceleratorTable)
    {.validate, property, inline.} =
  ## Sets the accelerator table for this window.
  wValidate(accel)

  # always check that is there an accelerator needs to be translated in main loop
  # seems do no harm. however, only check it on necessary is more clever.
  wAppAccelOn()

  self.mAcceleratorTable = accel

proc getAcceleratorTable*(self: wWindow): wAcceleratorTable
    {.validate, property, inline.} =
  ## Gets the accelerator table for this window.
  result = self.mAcceleratorTable

proc setCursorImpl(self: wWindow, cursor: wCursor, override = false) =
  var cursorChanged = true
  if override:
    if self.mOverrideCursor == cursor: cursorChanged = false
    elif self.mOverrideCursor != nil and cursor != nil and
      self.mOverrideCursor.mHandle == cursor.mHandle: cursorChanged = false

    self.mOverrideCursor = cursor
  else:
    # cursor and mCursor won't be nil here
    if self.mCursor.mHandle == cursor.mHandle and self.mOverrideCursor == nil:
      cursorChanged = false

    self.mCursor = cursor
    self.mOverrideCursor = nil
  if not cursorChanged: return

  # If mouse is captured, cursor should change immediately.
  # Otherwise, if there is a window under the mouse point,
  # sent WM_SETCURSOR to it again to decide what cursor it should use.
  var hWnd = 0
  if self.hasCapture():
    hWnd = self.mHwnd

  else:
    let win = wFindWindowAtPoint()
    if win != nil:
      hWnd = win.mHwnd

  if hWnd != 0:
    SendMessage(hWnd, WM_SETCURSOR, WPARAM hWnd, MAKELPARAM(HTCLIENT, WM_MOUSEMOVE))

proc setCursor*(self: wWindow, cursor: wCursor) =
  ## Sets the window's cursor. The cursor may be wNilCursor, in which case the
  ## window cursor will be reset. Notice that the window cursor also sets it for
  ## the children of the window implicitly.
  ## Set children's cursor to wDefaultCursor can restore the children's default
  ## cursor. For example, if you change a frame's cursor, the textctrl in the
  ## frame will uses the cursor too. To avoid it, you can set textctrl's cursor
  ## to wDefaultCursor.
  wValidate(cursor)
  self.setCursorImpl(cursor, override=false)

proc setOverrideCursor(self: wWindow, cursor: wCursor) =
  # Sets a temporary cursor to override the default one.
  # Is this need to be public?
  self.setCursorImpl(cursor, override=true)

proc getCursor*(self: wWindow): wCursor =
  ## Return the cursor associated with this window.
  result = self.mCursor

proc toBar(orientation: int): int {.inline.} =
  assert orientation in {wHorizontal, wVertical}
  result = if orientation == wHorizontal: SB_HORZ else: SB_VERT

proc getScrollInfo(self: wWindow, orientation: int): SCROLLINFO =
  result = SCROLLINFO(
    cbSize: sizeof(SCROLLINFO),
    fMask: SIF_ALL)
  GetScrollInfo(self.mHwnd, orientation.toBar, &result)

proc setScrollbar*(self: wWindow, orientation: int, position: Natural,
    pageSize: Positive, range: Positive) {.validate, property.} =
  ## Sets the scrollbar properties of a built-in scrollbar .
  ## Orientation should be wHorizontal or wVertical
  var info = SCROLLINFO(
    cbSize: sizeof(SCROLLINFO),
    fMask: SIF_POS or SIF_PAGE or SIF_RANGE,
    nPos: int32 position,
    nPage: int32 pageSize,
    nMin: 0,
    nMax: int32 range)
  SetScrollInfo(self.mHwnd, orientation.toBar, &info, true) # true for redraw

proc showScrollBar*(self: wWindow, orientation: int, flag = true)
    {.validate, inline.} =
  ## Shows the built-in scrollbar.
  ShowScrollBar(self.mHwnd, orientation.toBar, if flag: 1 else: 0)

proc enableScrollBar*(self: wWindow, orientation: int, flag = true)
    {.validate, inline.} =
  ## Enable or disable the built-in scrollbar.
  EnableScrollBar(self.mHwnd, orientation.toBar,
    if flag: ESB_ENABLE_BOTH else: ESB_DISABLE_BOTH)

proc setScrollPos*(self: wWindow, orientation: int, position: int)  {.validate.} =
  ## Sets the position of the scrollbar.
  var info = SCROLLINFO(
    cbSize: sizeof(SCROLLINFO),
    fMask: SIF_POS,
    nPos: int32 position)
  SetScrollInfo(self.mHwnd, orientation.toBar, &info, true)

proc getScrollRange*(self: wWindow, orientation: int): int
    {.validate, property, inline.} =
  ## Returns the built-in scrollbar range.
  let info = self.getScrollInfo(orientation)
  result = int info.nMax

proc getPageSize*(self: wWindow, orientation: int): int
    {.validate, property, inline.} =
  ## Returns the built-in scrollbar page size.
  let info = self.getScrollInfo(orientation)
  result = int info.nPage

proc getScrollPos*(self: wWindow, orientation: int): int
    {.validate, property, inline.} =
  ## Returns the built-in scrollbar position.
  let info = self.getScrollInfo(orientation)
  result = int info.nPos

proc center*(self: wWindow, direction = wBoth) {.validate.} =
  ## Centers the window. *direction* is a bitwise combination of
  ## wHorizontal and wVertical.
  if (direction and wBoth) == 0: return # nothing to do

  if self.mParent == nil:
    centerWindow(self.mHwnd, inScreen=false, direction=direction)

  else:
    var rect = self.getWindowRect()
    let size = self.mParent.getClientSize()
    let point = self.mParent.getClientAreaOrigin()

    if (direction and wHorizontal) != 0:
      rect.x = (size.width - rect.width) div 2 + point.x

    if (direction and wVertical) != 0:
      rect.y = (size.height - rect.height) div 2 + point.y

    self.setWindowPos(rect.x, rect.y)

proc popupMenu*(self: wWindow, menu: wMenu, pos: wPoint = wDefaultPoint)
    {.validate.} =
  ## Pops up the given menu at the specified coordinates.
  wValidate(menu)
  var pos = self.clientToScreen(pos)
  if pos.x == wDefault or pos.y == wDefault:
    pos = wGetMousePosition()

  # Q135788, so when you click outside the popup menu, the popup menu disappears correctly.
  if self.isTopLevel():
    SetForegroundWindow(self.mHwnd)

  TrackPopupMenu(menu.mHmenu, TPM_RECURSE or TPM_RIGHTBUTTON,
    pos.x, pos.y, 0, self.mHwnd, nil)

  if self.isTopLevel():
    PostMessage(self.mHwnd, WM_NULL, 0, 0)

proc popupMenu*(self: wWindow, menu: wMenu, x, y: int) {.validate, inline.} =
  ## Pops up the given menu at the specified coordinates.
  self.popupMenu(menu, (x, y))

proc startTimer*(self: wWindow, seconds: float, id = 1) {.validate, inline.} =
  ## Start a timer. It generates wEvent_Timer event to the window.
  ## In the event handler, use event.timerId to get the timer id.
  SetTimer(self.mHwnd, UINT_PTR id, UINT(seconds * 1000), nil)

proc stopTimer*(self: wWindow, id = 1) {.validate, inline.} =
  ## Stop the timer.
  KillTimer(self.mHwnd, UINT_PTR id)

proc registerHotKey*(self: wWindow, id: int, modifiers: int,
    keyCode: int): bool {.validate, inline, discardable.} =
  ## Registers a system wide hotkey. Every time the user presses the hotkey
  ## registered here, this window will receive a wEvent_HotKey event.
  ## Modifiers is a bitwise combination of wModShift, wModCtrl, wModAlt, wModWin.
  result = RegisterHotKey(self.mHwnd, id, modifiers, keyCode) != 0

proc unregisterHotKey*(self: wWindow, id: int): bool
    {.validate, inline, discardable.} =
  ## Unregisters a system wide hotkey.
  result = UnregisterHotKey(self.mHwnd, id) != 0

proc setDoubleBuffered*(self: wWindow, on = true) {.validate, property.} =
  ## Turn on or off double buffering of the window.
  var exStyle = GetWindowLongPtr(self.mHwnd, GWL_STYLE)
  exStyle =
    if on:
      exStyle or WS_EX_COMPOSITED
    else:
      exStyle and (not WS_EX_COMPOSITED)
  SetWindowLongPtr(self.mHwnd, GWL_EXSTYLE, exStyle)

proc getDoubleBuffered*(self: wWindow): bool {.validate, property.} =
  ## Returns true if the window contents is double-buffered by the system
  result = (GetWindowLongPtr(self.mHwnd, GWL_STYLE) and WS_EX_COMPOSITED) != 0


iterator children*(self: wWindow): wWindow {.validate.} =
  ## Iterates over each window's child.
  for child in self.mChildren:
    yield child

iterator siblings*(self: wWindow): wWindow {.validate.} =
  ## Iterates over each window's sibling.
  if self.mParent != nil:
    for child in self.mParent.mChildren:
      if child != self:
        yield child

proc processEvent*(self: wWindow, event: wEvent): bool {.validate, discardable.} =
  ## Processes an event, searching event tables and calling event handler.
  ## Returned true if a suitable event handler function was found and executed
  ## and the function did not call wEvent.skip.
  let id = event.mId
  let msg = event.mMsg
  var processed = false
  defer: result = processed

  proc errorHandler() =
    let err = getCurrentException()
    var caption = "Error: unhandled exception"
    var msg = ""
    when not defined(release):
      msg.add(getStackTrace())
      msg.add "\n"
    msg.add(err.msg)
    msg.add " ["
    msg.add(err.name)
    msg.add "]"
    MessageBox(self.mHwnd, msg, caption, MB_OK or MB_ICONSTOP)

  proc callHandler(connection: wEventConnection) =
    if connection.id == 0 or connection.id == id:
      try:
        if not connection.handler.isNil:
          connection.handler(event)
          processed = not event.mSkip

        elif not connection.neatHandler.isNil:
          connection.neatHandler()
          processed = true

      except:
        errorHandler()
        processed = false

  self.mSystemConnectionTable.withValue(msg, list):
    # always invoke every system event handler
    # so we don't break even the event is processed
    # notice: use list instead of seq here,
    # because handler may modify list by disconnect
    for node in list.nodes: # FIFO
      let connection = node.value
      connection.callHandler()

  # system event never block following event
  processed = false

  var this = self
  while true:
    this.mConnectionTable.withValue(msg, list):
      for node in list.rnodes: # FILO
        let connection = node.value
        # make sure we clear the skip state before every callHandler
        event.mSkip = false
        connection.callHandler()
        # pass event to next handler only if not processed
        if processed: break

    this = this.mParent
    if this == nil or processed or event.shouldPropagate() == false:
      break
    else:
      event.mPropagationLevel.dec

proc queueEvent*(self: wWindow, event: wEvent) {.validate.} =
  ## Queue event for a later processing.
  wValidate(event)
  PostMessage(self.mHwnd, event.mMsg, event.mWparam, event.mLparam)

proc processMessage(self: wWindow, msg: UINT, wParam: WPARAM, lParam: LPARAM,
    ret: var LRESULT, origin: HWND): bool {.discardable.} =
  # Use internally, generate the event object and process it.
  if wAppHasMessage(msg):
    let event = Event(window=self, msg=msg, wParam=wParam, lParam=lParam,
      origin=origin)
    result = self.processEvent(event)
    ret = event.mResult

proc processMessage(self: wWindow, msg: UINT, wParam: WPARAM, lParam: LPARAM,
    ret: var LRESULT): bool {.inline, discardable.} =
  # Use internally, ignore origin means origin is self.mHwnd.
  result = self.processMessage(msg, wParam, lParam, ret, self.mHwnd)

proc processMessage(self: wWindow, msg: UINT, wParam: WPARAM = 0,
    lParam: LPARAM = 0): bool {.validate, inline, discardable.} =
  # use internally, the same but ignore the return value.
  var dummy: LRESULT
  result = self.processMessage(msg, wParam, lParam, dummy)

method processNotify(self: wWindow, code: INT, id: UINT_PTR, lParam: LPARAM,
    ret: var LRESULT): bool {.base.} =
  # subclass can override this to process the nofity message
  discard

proc scrollEventTranslate(wParam: WPARAM, info: SCROLLINFO, position: var INT,
    isControl: bool): UINT {.inline.} =

  result = case LOWORD(wparam)
    of SB_TOP:
      position = 0
      if isControl: wEvent_ScrollTop else: wEvent_ScrollWinTop
    of SB_BOTTOM:
      position = info.nMax
      if isControl: wEvent_ScrollBottom else: wEvent_ScrollWinBottom
    of SB_LINEUP:
      position.dec
      if isControl: wEvent_ScrollLineUp else: wEvent_ScrollWinLineUp
    of SB_LINEDOWN:
      position.inc
      if isControl: wEvent_ScrollLineDown else: wEvent_ScrollWinLineDown
    of SB_PAGEUP:
      position.dec info.nPage
      if isControl: wEvent_ScrollPageUp else: wEvent_ScrollWinPageUp
    of SB_PAGEDOWN:
      position.inc info.nPage
      if isControl: wEvent_ScrollPageDown else: wEvent_ScrollWinPageDown
    of SB_THUMBPOSITION:
      position = info.nTrackPos
      if isControl: wEvent_ScrollThumbRelease else: wEvent_ScrollWinThumbRelease
    of SB_THUMBTRACK:
      position = info.nTrackPos
      if isControl: wEvent_ScrollThumbTrack else: wEvent_ScrollWinThumbTrack
    of SB_ENDSCROLL:
      if isControl: wEvent_ScrollChanged else: wEvent_ScrollWinChanged
    else: 0

proc wScroll_DoScrollImpl(self: wWindow, orientation: int, wParam: WPARAM,
    isControl: bool, processed: var bool) =
  # handle WM_VSCROLL and WM_HSCROLL for both standard scroll bar and scroll
  # bar control
  var
    info =
      if isControl:
        wScrollBar(self).getScrollInfo()
      else:
        self.getScrollInfo(orientation)

    position = info.nPos
    eventKind = scrollEventTranslate(wParam, info, position, isControl)

  # The really max position is nMax - nPage + 1
  let maxPos = info.nMax - info.nPage + 1
  if position < 0: position = 0
  if position > maxPos: position = maxPos

  if position != info.nPos:
    if isControl:
      wScrollBar(self).setScrollPos(position)
    else:
      self.setScrollPos(orientation, position)

  # No more check the position to decide sending event or not.
  # It means: the behavior is more like wSlider, and simpler code.
  # Whatever we get from system, we send to the user.

  if eventKind != 0:
    var
      scrollData = wScrollData(kind: eventKind, orientation: orientation)
      dataPtr = cast[LPARAM](&scrollData)

    # sent wEvent_ScrollWin/wEvent_ScrollBar first, if this is processed,
    # skip other event
    let defaultKind = if isControl: wEvent_ScrollBar else: wEvent_ScrollWin
    if not self.processMessage(defaultKind, wParam, dataPtr):
      self.processMessage(eventKind, wParam, dataPtr)


proc EventConnection(msg: UINT, id: wCommandID = 0, handler: wEventHandler = nil,
    neatHandler: wEventNeatHandler = nil, userData = 0,
    undeletable = false): wEventConnection {.inline.} =

  result = (msg: msg, id: id, handler: handler, neatHandler: neatHandler,
    userData: userData, undeletable: undeletable)

proc systemConnect(self: wWindow, msg: UINT, handler: wEventHandler): wEventConnection {.discardable.} =
  # Used internally: a default behavior cannot be changed by user
  var connection = EventConnection(msg=msg, handler=handler, undeletable=true)
  self.mSystemConnectionTable.mgetOrPut(msg, initDoublyLinkedList[wEventConnection]()).append(connection)
  wAppIncMessage(msg)
  result = connection

proc hardConnect(self: wWindow, msg: UINT, handler: wEventHandler): wEventConnection {.discardable.} =
  # Used internally: a default behavior can be changed by user but cannot be deleted
  var connection = EventConnection(msg=msg, handler=handler, undeletable=true)
  self.mConnectionTable.mgetOrPut(msg, initDoublyLinkedList[wEventConnection]()).append(connection)
  wAppIncMessage(msg)
  result = connection

proc connect*(self: wWindow, msg: UINT, handler: wEventHandler,
    userData: int = 0): wEventConnection {.validate, discardable.} =
  ## Connects the given event type with the event handler defined as "proc (event: wEvent)".
  var connection = EventConnection(msg=msg, handler=handler, userData=userData, undeletable=false)
  self.mConnectionTable.mgetOrPut(msg, initDoublyLinkedList[wEventConnection]()).append(connection)
  wAppIncMessage(msg)
  result = connection

proc connect*(self: wWindow, msg: UINT, handler: wEventNeatHandler,
    userData: int = 0): wEventConnection {.validate, discardable.} =
  ## Connects the given event type with the event handler defined as "proc ()".
  var connection = EventConnection(msg=msg, neatHandler=handler, userData=userData, undeletable=false)
  self.mConnectionTable.mgetOrPut(msg, initDoublyLinkedList[wEventConnection]()).append(connection)
  wAppIncMessage(msg)
  result = connection

proc connect*(self: wWindow, msg: UINT, id: wCommandID, handler: wEventHandler,
    userData: int = 0): wEventConnection {.validate, discardable.} =
  ## Connects the given event type and specified ID with the event handler defined as "proc (event: wEvent)".
  var connection = EventConnection(msg=msg, id=id, handler=handler, userData=userData, undeletable=false)
  self.mConnectionTable.mgetOrPut(msg, initDoublyLinkedList[wEventConnection]()).append(connection)
  wAppIncMessage(msg)
  result = connection

proc connect*(self: wWindow, msg: UINT, id: wCommandID, handler: wEventNeatHandler,
    userData: int = 0): wEventConnection {.validate, discardable.} =
  ## Connects the given event type and specified ID with the event handler defined as "proc ()".
  var connection = EventConnection(msg=msg, id=id, neatHandler=handler, userData=userData, undeletable=false)
  self.mConnectionTable.mgetOrPut(msg, initDoublyLinkedList[wEventConnection]()).append(connection)
  wAppIncMessage(msg)
  result = connection

proc getCommandEvent(window: wWindow): UINT =
  if window of wFrame:
    result = wEvent_Menu
  elif window of wButton:
    result = wEvent_Button
  elif window of wCheckBox:
    result = wEvent_CheckBox
  elif window of wRadioButton:
    result = wEvent_RadioButton
  elif window of wToolBar:
    result = wEvent_Tool
  else:
    assert true

proc connect*(self: wWindow, id: wCommandID, handler: wEventHandler,
    userData: int = 0): wEventConnection {.validate, discardable.} =
  ## Connects the specified ID with the event handler defined as
  ## "proc (event: wEvent)".
  assert id.ord != 0
  result = connect(self, self.getCommandEvent(), id, handler, userData)

proc connect*(self: wWindow, id: wCommandID, handler: wEventNeatHandler,
    userData: int = 0): wEventConnection {.validate, discardable.} =
  ## Connects the specified ID with the event handler defined as "proc ()".
  assert id.ord != 0
  result = connect(self, self.getCommandEvent(), id, handler, userData)

proc disconnect*(self: wWindow, msg: UINT, limit = -1) {.validate.} =
  ## Disconnects the given event type from the event handler.
  var count = 0
  self.mConnectionTable.withValue(msg, list):
    for node in list.rnodes:
      if not node.value.undeletable:
        list.remove(node)
        wAppDecMessage(msg)
        count.inc
        if limit >= 0 and count >= limit: break

proc disconnect*(self: wWindow, msg: UINT, id: wCommandID, limit = -1)
    {.validate.} =
  ## Disconnects the given event type and specified ID from the event handler.
  var count = 0
  self.mConnectionTable.withValue(msg, list):
    for node in list.rnodes:
      if node.value.id == id and not node.value.undeletable:
        list.remove(node)
        wAppDecMessage(msg)
        count.inc
        if limit >= 0 and count >= limit: break

proc disconnect*(self: wWindow, id: wCommandID, limit = -1) {.validate.} =
  ## Disconnects the specified ID from the event handler.
  self.disconnect(self.getCommandEvent(), id, limit)

proc systemDisconnect(self: wWindow, connection: wEventConnection) =
  # Used internally, disconnects the specified connection that returned by
  ## systemConnect().
  let msg = connection.msg
  self.mSystemConnectionTable.withValue(msg, list):
    for node in list.nodes:
      if node.value == connection:
        list.remove(node)
        wAppDecMessage(msg)

proc disconnect*(self: wWindow, connection: wEventConnection) =
  ## Disconnects the specified token that returned by connect().
  let msg = connection.msg
  self.mConnectionTable.withValue(msg, list):
    for node in list.nodes:
      if node.value == connection:
        list.remove(node)
        wAppDecMessage(msg)

proc `.`*(self: wWindow, msg: UINT, handler: wEventHandler): wEventConnection
    {.inline, discardable.} =
  ## Symbol alias for connect.
  result = self.connect(msg, handler)

proc `.`*(self: wWindow, msg: UINT, handler: wEventNeatHandler): wEventConnection
    {.inline, discardable.} =
  ## Symbol alias for connect.
  result = self.connect(msg, handler)

proc `.`*(self: wWindow, id: wCommandID, handler: wEventHandler): wEventConnection
    {.inline, discardable.} =
  ## Symbol alias for connect.
  result = self.connect(id, handler)

proc `.`*(self: wWindow, id: wCommandID, handler: wEventNeatHandler): wEventConnection
    {.inline, discardable.} =
  ## Symbol alias for connect.
  result = self.connect(id, handler)

proc setDraggable*(self: wWindow, flag = true, inClient = true)
    {.validate, property.} =
  ## Allow a child window to be moved using the mouse.
  ## If inClient is true, the window is limited inside the client area.
  ## When a window is dragging by user, it receive wEvent_Dragging event.
  if self.mParent == nil: return

  # connect event handler dynamically.
  # the good point is these codes can be discard when deadCodeElim turned on.

  # use hardConnect instead of systemConnect to block the default mouse handler
  # during dragging

  if self.mDraggableInfo == nil:
    new(self.mDraggableInfo)
  else:
    self.disconnect(self.mDraggableInfo.connection.move)
    self.disconnect(self.mDraggableInfo.connection.up)
    self.disconnect(self.mDraggableInfo.connection.down)

  let info = self.mDraggableInfo
  info.enable = flag
  info.inClient = inClient

  proc shouldStartDragging(start: wPoint, current: wPoint): bool =
    if (abs(start.x - current.x) > int GetSystemMetrics(SM_CXDRAG)) or
        (abs(start.y - current.y) > int GetSystemMetrics(SM_CYDRAG)):
      return true

  info.connection.down = self.hardConnect(wEvent_LeftDown) do (event: wEvent):
    info.startMousePos = event.getMouseScreenPos()
    event.skip

  info.connection.move = self.hardConnect(wEvent_MouseMove) do (event: wEvent):
    var processed = false
    defer: event.skip(if processed: false else: true)

    # do nothing when a window is still sizing.
    if self.mSizingInfo != nil:
      let info = self.mSizingInfo
      if info.ready.up or info.ready.down or info.ready.left or
          info.ready.right or info.dragging:
        return

    # checking event.leftDown is enough to know dragging or not
    if info.enable and event.leftDown and not info.dragging and
        shouldStartDragging(info.startMousePos, event.getMouseScreenPos()):
      info.startPos = self.getPosition()
      info.startMousePos = event.getMouseScreenPos()

      let event = Event(window=self, msg=wEvent_Dragging, 0,
        MAKELPARAM(info.startPos.x, info.startPos.y))

      if not self.processEvent(event) or event.isAllowed:
        self.captureMouse()
        self.setOverrideCursor(wSizeAllCursor)
        info.dragging = true
        processed = true

    elif info.dragging:
      var newPos = info.startPos + event.getMouseScreenPos() - info.startMousePos
      var currentRect = self.getRect()
      var clientSize = self.mParent.getClientSize()

      if info.inClient:
        newPos.x = newPos.x.clamp(0, clientSize.width - currentRect.width)
        newPos.y = newPos.y.clamp(0, clientSize.height - currentRect.height)

      if (currentRect.x, currentRect.y) != newPos:
        let event = Event(window=self, msg=wEvent_Dragging, 0,
          MAKELPARAM(newPos.x, newPos.y))

        if not self.processEvent(event) or event.isAllowed:
          self.move(newPos)
          processed = true

  info.connection.up = self.hardConnect(wEvent_LeftUp) do (event: wEvent):
    var processed = false
    defer: event.skip(if processed: false else: true)

    if info.dragging:
      info.dragging = false
      self.setOverrideCursor(nil)
      self.releaseMouse()
      processed = true

proc setSizingBorder*(self: wWindow, direction: wDirection)
    {.validate, property.} =
  ## Allow a child window to be changed size using the mouse.
  ## When a window is sizing by user, it receive wEvent_Sizing event.
  if self.mParent == nil: return

  # connect event handler dynamically.
  # See setDraggable()

  if self.mSizingInfo == nil:
    new(self.mSizingInfo)
  else:
    self.disconnect(self.mSizingInfo.connection.move)
    self.disconnect(self.mSizingInfo.connection.up)
    self.disconnect(self.mSizingInfo.connection.down)

  let info = self.mSizingInfo
  info.border = direction

  info.connection.move = self.hardConnect(wEvent_MouseMove) do (event: wEvent):
    var processed = false
    defer: event.skip(if processed: false else: true)

    if info.border == (0, 0, 0, 0): return

    if info.dragging:
      var newPos = self.mParent.screenToClient(event.getMouseScreenPos())
      var currentRect = self.getRect()
      var clientSize = self.mParent.getClientSize()
      var newRect = currentRect

      proc satisfied(): bool =
        # use min, max because the window maybe already out of client area
        if newRect.x < min(currentRect.x, 0): return false
        if newRect.y < min(currentRect.y, 0): return false

        if newRect.x + newRect.width > max(clientSize.width,
          currentRect.x + currentRect.width): return false

        if newRect.y + newRect.height > max(clientSize.height,
          currentRect.y + currentRect.height): return false

        if self.mMinSize != wDefaultSize:
          if newRect.width < self.mMinSize.width or
            newRect.height < self.mMinSize.height: return false

        if self.mMaxSize != wDefaultSize:
          if newRect.width > self.mMaxSize.width or
            newRect.height > self.mMaxSize.height: return false
        return true

      if info.ready.down:
        newRect.height = newPos.y - currentRect.y + info.offset.down
        if not satisfied(): newRect.height = currentRect.height

      if info.ready.right:
        newRect.width = newPos.x - currentRect.x + info.offset.right
        if not satisfied(): newRect.width = currentRect.width

      if info.ready.up:
        newRect.y = newPos.y - info.offset.up
        newRect.height = currentRect.height - (newRect.y - currentRect.y)
        if not satisfied():
          newRect.y = currentRect.y
          newRect.height = currentRect.height

      if info.ready.left:
        newRect.x = newPos.x - info.offset.left
        newRect.width = currentRect.width - (newRect.x - currentRect.x)
        if not satisfied():
          newRect.x = currentRect.x
          newRect.width = currentRect.width

      if newRect != currentRect:
        let event = Event(window=self, msg=wEvent_Sizing,
          MAKEWPARAM(newRect.width, newRect.height),
          MAKELPARAM(newRect.x, newRect.y))

        if not self.processEvent(event) or event.isAllowed:
          self.setSize(newRect)
          processed = true

    elif not event.leftDown:
      var rect: RECT
      GetWindowRect(self.mHwnd, rect)
      var mousePos = event.getMouseScreenPos()

      info.ready.up = info.border.up > 0 and
        mousePos.y in rect.top..(rect.top + info.border.up)

      info.ready.down = info.border.down > 0 and
        mousePos.y in (rect.bottom - info.border.down)..rect.bottom

      info.ready.left = info.border.left > 0 and
        mousePos.x in rect.left..(rect.left + info.border.left)

      info.ready.right = info.border.right > 0 and
        mousePos.x in (rect.right - info.border.right)..rect.right

      let vertical = info.ready.up or info.ready.down
      let horizontal = info.ready.left or info.ready.right
      if vertical and horizontal:
        self.setOverrideCursor(wSizeAllCursor)
      elif vertical:
        self.setOverrideCursor(wSizeNsCursor)
      elif horizontal:
        self.setOverrideCursor(wSizeWeCursor)
      else:
        self.setOverrideCursor(nil)

      # just collect information, no need to block?
      # so dont set processed = true

  info.connection.down = self.hardConnect(wEvent_LeftDown) do (event: wEvent):
    var processed = false
    defer: event.skip(if processed: false else: true)

    if info.ready.up or info.ready.down or info.ready.left or info.ready.right:
      let event = Event(window=self, msg=wEvent_Sizing)
      if not self.processEvent(event) or event.isAllowed:
        self.captureMouse()
        info.dragging = true

        var rect: RECT
        GetWindowRect(self.mHwnd, rect)
        var mousePos = event.getMouseScreenPos()

        info.offset.left = mousePos.x - rect.left
        info.offset.up = mousePos.y - rect.top
        info.offset.right = rect.right - mousePos.x
        info.offset.down = rect.bottom - mousePos.y
        processed = true

  info.connection.up = self.hardConnect(wEvent_LeftUp) do (event: wEvent):
    var processed = false
    defer: event.skip(if processed: false else: true)

    if info.dragging:
      info.dragging = false
      self.releaseMouse()
      processed = true

proc setDropTarget*(self: wWindow, flag = true) {.validate, property.} =
  ## Register the window as a drop target, or revoke it. The window will recieve
  ## wDragDropEvent during a drag-and-drop operation.
  if self.mDropTarget.lpVtbl != nil:
    RevokeDragDrop(self.mHwnd)
    self.mDropTarget.lpVtbl = nil

  if flag:
    self.mDropTarget.lpVtbl = &self.mDropTarget.vtbl
    self.mDropTarget.self = self

    let pDropTarget = cast[LPDROPTARGET](&self.mDropTarget)

    self.mDropTarget.vtbl.AddRef = proc(self: ptr IUnknown): ULONG {.stdcall.} =
      discard

    self.mDropTarget.vtbl.Release = proc(self: ptr IUnknown): ULONG {.stdcall.} =
      discard

    self.mDropTarget.vtbl.QueryInterface = proc(self: ptr IUnknown, riid: REFIID,
        ppvObject: ptr pointer): HRESULT {.stdcall.} =
      return E_NOINTERFACE

    self.mDropTarget.vtbl.DragEnter = proc(self: ptr IDropTarget,
        pDataObj: ptr IDataObject, grfKeyState: DWORD, pt: POINTL,
        pdwEffect: ptr DWORD): HRESULT {.stdcall.} =
      let pDropTarget = cast[ptr wDropTarget](self)
      pDropTarget.effect = DROPEFFECT_NONE
      defer: pdwEffect[] = pDropTarget.effect

      let win = pDropTarget.self
      let event = wDragDropEvent Event(window=win, msg=wEvent_DragEnter)
      event.mDataObject = DataObject(pDataObj)
      event.mEffect = pDropTarget.effect

      if win.processEvent(event):
        pDropTarget.effect = event.mEffect

    self.mDropTarget.vtbl.DragOver = proc(self: ptr IDropTarget, grfKeyState: DWORD,
        pt: POINTL, pdwEffect: ptr DWORD): HRESULT {.stdcall.} =
      let pDropTarget = cast[ptr wDropTarget](self)
      defer: pdwEffect[] = pDropTarget.effect

      let win = pDropTarget.self
      let event = wDragDropEvent Event(window=win, msg=wEvent_DragOver)
      event.mEffect = pDropTarget.effect

      if win.processEvent(event):
        pDropTarget.effect = event.mEffect

    self.mDropTarget.vtbl.DragLeave = proc(self: ptr IDropTarget): HRESULT {.stdcall.} =
      let pDropTarget = cast[ptr wDropTarget](self)
      let win = pDropTarget.self
      win.processEvent(Event(window=win, msg=wEvent_DragLeave))

    self.mDropTarget.vtbl.Drop = proc(self: ptr IDropTarget, pDataObj: ptr IDataObject,
        grfKeyState: DWORD, pt: POINTL, pdwEffect: ptr DWORD): HRESULT {.stdcall.} =
      let pDropTarget = cast[ptr wDropTarget](self)
      defer: pdwEffect[] = pDropTarget.effect

      let win = pDropTarget.self
      let event = wDragDropEvent Event(window=win, msg=wEvent_Drop)
      event.mDataObject = DataObject(pDataObj)
      event.mEffect = pDropTarget.effect

      if win.processEvent(event):
        pDropTarget.effect = event.mEffect

    RegisterDragDrop(self.mHwnd, pDropTarget)

proc getToolTip*(self: wWindow): string {.validate, property.} =
  ## Get the text of the associated tooltip or empty string if none.
  if self.mTipHwnd != 0:
    var buffer = T(65536)
    var toolInfo = TOOLINFO(
      cbSize: sizeof(TOOLINFO),
      hwnd: self.mHwnd,
      uId: cast[UINT_PTR](self.mHwnd),
      lpszText: &buffer)

    SendMessage(self.mTipHwnd, TTM_GETTEXT, 65536, &toolInfo)
    buffer.nullTerminate
    result = $buffer

proc setToolTip*(self: wWindow, tip: string) {.validate, property.} =
  ## Attach a tooltip to the window.
  if self.mTipHwnd != 0:
    DestroyWindow(self.mTipHwnd)

  if tip.len != 0:
    self.mTipHwnd = CreateWindowEx(0, TOOLTIPS_CLASS, nil,
      WS_POPUP or TTS_NOPREFIX or TTS_ALWAYSTIP, CW_USEDEFAULT, CW_USEDEFAULT,
      CW_USEDEFAULT, CW_USEDEFAULT, self.mHwnd, 0, wAppGetInstance(), nil)

    SetWindowPos(self.mTipHwnd, HWND_TOPMOST,0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)

    SendMessage(self.mTipHwnd, TTM_ACTIVATE, TRUE, 0)

    var toolInfo = TOOLINFO(
      cbSize: sizeof(TOOLINFO),
      hwnd: self.mHwnd,
      uFlags: TTF_IDISHWND or TTF_SUBCLASS,
      uId: cast[UINT_PTR](self.mHwnd),
      lpszText: T(tip))

    SendMessage(self.mTipHwnd, TTM_ADDTOOL, 0, &toolInfo)

proc unsetToolTip*(self: wWindow) {.validate, inline.} =
  ## Unset any existing tooltip.
  self.setToolTip("")

proc setToolTip*(self: wWindow, maxWidth = wDefault, autoPop = wDefault,
    delay = wDefault, reshow = wDefault) {.validate, property.} =
  ## Sets the parameters of the associated tooltip. -1 to restore the default.
  if self.mTipHwnd == 0: return

  if maxWidth != wDefault:
    SendMessage(self.mTipHwnd, TTM_SETMAXTIPWIDTH, 0, maxWidth)

  if autoPop != wDefault:
    SendMessage(self.mTipHwnd, TTM_SETDELAYTIME, TTDT_AUTOPOP, autoPop and 0xffff)

  if delay != wDefault:
    SendMessage(self.mTipHwnd, TTM_SETDELAYTIME, TTDT_INITIAL, delay and 0xffff)

  if reshow != wDefault:
    SendMessage(self.mTipHwnd, TTM_SETDELAYTIME, TTDT_RESHOW, reshow and 0xffff)


proc wWindow_DoMouseMove(event: wEvent) =
  let self = event.mWindow

  # we only handle WM_MOUSEMOVE if it's not from child window
  if self.mHwnd != event.mOrigin:
    return

  if not self.mMouseInWindow:
    # it would be wrong to assume that just because we get a mouse move
    # event that the mouse is inside the window: although this is usually
    # true, it is not if we had captured the mouse, so we need to check
    # the mouse coordinates here
    if not self.hasCapture() or isMouseInWindow(self.mHwnd):
      self.mMouseInWindow = true
      self.processMessage(wEvent_MouseEnter, event.mWparam, event.mLparam)

      var lpEventTrack = TTRACKMOUSEEVENT(
        cbSize: sizeof(TTRACKMOUSEEVENT),
        dwFlags: TME_LEAVE,
        dwHoverTime: HOVER_DEFAULT,
        hwndTrack: self.mHwnd)
      TrackMouseEvent(&lpEventTrack)

  else:
    # Windows doesn't send WM_MOUSELEAVE if the mouse has been captured so
    # send it here if we are using native mouse leave tracking
    if self.hasCapture() and not isMouseInWindow(self.mHwnd):
      self.processMessage(wEvent_MouseLeave, event.mWparam, event.mLparam)

proc wWindow_DoMouseLeave(event: wEvent) =
  event.mWindow.mMouseInWindow = false

proc wWindow_DoSize(event: wEvent) =
  case int event.wParam:
  of SIZE_RESTORED:
    event.window.processMessage(wEvent_Size, event.wParam, event.lParam)
  of SIZE_MINIMIZED:
    event.window.processMessage(wEvent_Minimize, event.wParam, event.lParam)
  of SIZE_MAXIMIZED:
    event.window.processMessage(wEvent_Maximize, event.wParam, event.lParam)
    event.window.processMessage(wEvent_Size, event.wParam, event.lParam)
  else: discard # don't care about SIZE_MAXHIDE, SIZE_MAXSHOW, etc

proc wWindow_DoGetMinMaxInfo(event: wEvent) =
  let self = event.mWindow
  if self.mMinSize != wDefaultSize or self.mMaxSize != wDefaultSize:
    var pInfo: PMINMAXINFO = cast[PMINMAXINFO](event.mLparam)
    if self.mMinSize.width != wDefault: pInfo.ptMinTrackSize.x = self.mMinSize.width
    if self.mMinSize.height != wDefault: pInfo.ptMinTrackSize.y = self.mMinSize.height
    if self.mMaxSize.width != wDefault: pInfo.ptMaxTrackSize.x = self.mMaxSize.width
    if self.mMaxSize.height != wDefault: pInfo.ptMaxTrackSize.y = self.mMaxSize.height

proc wWindow_DoScroll(event: wEvent) =
  var processed = false
  if event.mLparam == 0: # means the standard scroll bar
    let orientation = if event.mMsg == WM_VSCROLL: wVertical else: wHorizontal
    event.mWindow.wScroll_DoScrollImpl(orientation, event.wParam,
      isControl=false, processed)

proc wWindow_DoDestroy(event: wEvent) =
  event.mWindow.processMessage(wEvent_Destroy)

  # always post a WM_QUIT message to mainloop
  # GetMessage won't end because it check wAppHasTopLevelWindow()
  # PostQuitMessage(0)

  # use our own wEvent_AppQuit here, because PostQuitMessage indicates system
  # the thread wishes to terminate. It disables the further creation of windows
  # (MessageBox etc).
  PostMessage(0, wEvent_AppQuit, 0, 0)

proc wWindow_DoNcDestroy(event: wEvent) =
  let self = event.mWindow
  if self.mDummyParent != 0:
    DestroyWindow(self.mDummyParent)
    self.mDummyParent = 0

  if self.mTipHwnd != 0:
    DestroyWindow(self.mTipHwnd)
    self.mTipHwnd = 0

  self.release()
  wAppWindowDelete(self)
  if self.mParent != nil:
    let index = self.mParent.mChildren.find(self)
    if index != -1:
      self.mParent.mChildren.delete(index)

proc wWindow_OnCommand(event: wEvent) =
  let self = event.mWindow
  var processed = false
  defer: event.skip(if processed: false else: true)

  # wParam (high word) == 0: menu, == 1: accelerator
  # we only handle accelerator here.
  # typically, a accelerator table is associated with a frame.
  # however, maybe there is some exception (editor?)
  # So we handle this at wWindow level.
  if event.lParam == 0 and HIWORD(event.wParam) == 1:
    let id = LOWORD(event.wParam)
    processed = self.processMessage(wEvent_Menu, WPARAM id, 0, event.mResult)

proc wWindow_OnNotify(event: wEvent) =
  let self = event.mWindow
  var processed = false
  defer: event.skip(if processed: false else: true)

  let pNMHDR = cast[LPNMHDR](event.mLparam)
  var win = wAppWindowFindByHwnd(pNMHDR.hwndFrom)
  if win == nil:
    win = self # by default, handle it ourselves

  processed = win.processNotify(cast[INT](pNMHDR.code), pNMHDR.idFrom,
    event.mLparam, event.mResult)

proc wWindow_OnClose(event: wEvent) =
  let self = event.mWindow
  let closeEvent = Event(window=self, msg=wEvent_Close)
  if not self.processEvent(closeEvent) or closeEvent.isAllowed:
    # DefWindowProc for this event just a DestroyWindow()
    self.delete()

proc wWindow_OnCtlColor(event: wEvent) =
  var processed = false
  defer: event.skip(if processed: false else: true)

  # here lparam.HANDLE maybe a subwindow of our wWindow
  # so need to find our wWindow to get the color setting
  let
    hdc = HDC event.mWparam
    hwnd = HANDLE event.mLparam
    win = wAppWindowFindByHwnd(hwnd)

  if win != nil and win.mBackgroundBrush != nil:

    if win.mBackgroundColor != wDefaultColor:
      SetBkColor(hdc, win.mBackgroundColor)

    if win.mForegroundColor != wDefaultColor:
      SetTextColor(hdc, win.mForegroundColor)

    event.mResult = LRESULT win.mBackgroundBrush.mHandle
    processed = true

proc wWindow_OnSetCursor(event: wEvent) =
  var processed = false
  defer:
    # MSDN: If an application processes this message, it should return TRUE.
    if processed: event.result = TRUE
    event.skip(if processed: false else: true)

  # Windows system sent WM_SETCURSOR to parent before processing by default.
  # So we need to check wParam, otherwise, the message will "propagate" to
  # parent's handle.
  #
  # There are 3 situation to deal with
  # 1. This window has a custom cursor or override cursor -> just show it.
  # 2. This window don't have a custom cursor. Becasue all window's mCursor
  #    is set to wNilCursor by default. In this situation, find custom cursor
  #    of ancestor if possible. This behavior is like what system usually do.
  # 3. This window has it's own cursor setting. For example, an editor control.
  #    To deal with this, set this mCursor to wDefaultCursor. Here we just do
  #    nothing but try to let the control's wndproc do it's job.
  #    (avoid return TRUE in acestor's handler, so we check wParam).
  #
  # Before all of that, using wEvent_SetCursor to ask the cursor.

  if HWND(event.wParam) == event.window.mHwnd and LOWORD(event.lParam) == HTCLIENT:
    var hCursor: HCURSOR = 0
    let event = Event(window=event.window, msg=wEvent_SetCursor)
    if event.window.processEvent(event) and event.getCursor() != nil:
      hCursor = event.getCursor().mHandle

    if hCursor == 0:
      let tmpCursor = event.window.mOverrideCursor
      if tmpCursor != nil and tmpCursor.isCustomCursor:
        hCursor = tmpCursor.mHandle

    if hCursor == 0:
      let cursor = event.window.mCursor
      if cursor.isCustomCursor:
        hCursor = cursor.mHandle

      elif cursor.isNilCursor:
        var win = event.window.mParent
        while win != nil:
          if win.mCursor.isCustomCursor:
            hCursor = win.mCursor.mHandle
            break
          win = win.mParent

    if hCursor != 0:
      SetCursor(hCursor)
      processed = true

proc wWndProc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT
    {.stdcall.} =
  # assign to WNDCLASSEX.lpfnWndProc to invoke event handler

  let self = wAppWindowFindByHwnd(hwnd)
  if self != nil:
    if self.processMessage(msg, wParam, lParam, result):
      return result

  return DefWindowProc(hwnd, msg, wParam, lParam)

proc wSubProc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM,
    uIdSubclass: UINT_PTR, dwRefData: DWORD_PTR): LRESULT {.stdcall.} =

  let self = cast[wWindow](dwRefData)
  if self.processMessage(msg, wparam, lparam, result):
    return

  if msg == WM_NCDESTROY:
    RemoveWindowSubclass(hwnd, wSubProc, uIdSubclass)

  return DefSubclassProc(hwnd, msg, wParam, lParam)

proc final*(self: wWindow) =
  ## Default finalizer for wWindow.
  # Just don't need do anything. WM_NCDESTROY does a lot.
  discard

proc initBase(self: wWindow) =
  self.wResizable.init()
  self.mConnectionTable = initTable[UINT, DoublyLinkedList[wEventConnection]]()
  self.mSystemConnectionTable = initTable[UINT, DoublyLinkedList[wEventConnection]]()
  self.mChildren = @[]
  self.mMaxSize = wDefaultSize
  self.mMinSize = wDefaultSize
  self.mCursor = wNilCursor

proc initVerbosely(self: wWindow, parent: wWindow = nil, id: wCommandID = 0,
    title = "", pos = wDefaultPoint, size = wDefaultSize, style: wStyle = 0,
    bgColor: wColor = wDefaultColor, fgColor: wColor = wDefaultColor,
    className = "wWindow", owner: wWindow = nil,  regist = true) =
  # use internally
  self.initBase()
  self.mParent = parent

  var
    bgColor = bgColor
    fgColor = fgColor

  if parent.isNil:
    if bgColor == wDefaultColor: bgColor = wWhite
    if fgColor == wDefaultColor: fgColor = wBlack
  else:
    if bgColor == wDefaultColor: bgColor = parent.mBackgroundColor
    if fgColor == wDefaultColor: fgColor = parent.mForegroundColor

  self.mBackgroundBrush = Brush(bgColor)
  self.mBackgroundColor = bgColor
  self.mForegroundColor = fgColor

  proc unusedClassName(base: string): string =
    var
      count = 1
      wc: WNDCLASSEX

    while true:
      result = base & $count
      count.inc
      if GetClassInfoEx(wAppGetInstance(), result, wc) == 0: break

  var className = className
  if regist:
    className = unusedClassName(className)
    var wc: WNDCLASSEX
    wc.cbSize = sizeof(wc)
    wc.style = CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
    wc.lpfnWndProc = wWndProc
    wc.hInstance = wAppGetInstance()
    wc.hCursor = LoadCursor(0, IDC_ARROW)
    wc.hbrBackground = self.mBackgroundBrush.mHandle
    wc.lpszClassName = className

    if RegisterClassEx(wc) == 0:
      raise newException(wError, className & " class register failure")

  let
    isHideTaskbar = (style and wHideTaskbar) != 0
    isInvisible = (style and wInvisible) != 0

  var
    msStyle = cast[DWORD](style and 0xFFFFFFFF)
    # here need cast because int64 style maybe > int32.high
    exStyle = DWORD(style shr 32 and 0x0FFFFFFF)
    # we use 0x10000000 to 0x80000000 as wNim's style, so must clear it

    x = pos.x
    y = pos.y
    parentHwnd: HWND
    size = size

  if parent.isNil:
    if owner != nil:
      parentHwnd = owner.mHwnd

    elif isHideTaskbar:
      # create a dummy parent window wiht WS_EX_TOOLWINDOW will hide the taskbar
      # button
      parentHwnd = CreateWindowEx(WS_EX_TOOLWINDOW, className, nil,
        0, 0, 0, 0, 0, parentHwnd, 0, wAppGetInstance(), nil)
      self.mDummyParent = parentHwnd

    msStyle = msStyle and (not WS_VISIBLE.DWORD) or WS_CLIPCHILDREN

  else:
    parentHwnd = parent.mHwnd
    msStyle = msStyle or WS_CHILD or WS_VISIBLE

    if pos.x == wDefault: x = 0
    if pos.y == wDefault: y = 0
    self.adjustForParentClientOriginAdd(x, y)

  if isInvisible:
    msStyle = msStyle and (not WS_VISIBLE)

  var initWidth = if size.width != wDefault: size.width else: 0
  var initHeight = if size.height != wDefault: size.height else: 0

  self.mHwnd = CreateWindowEx(exStyle, className, title, msStyle, x, y,
    initWidth, initHeight, parentHwnd, int id, wAppGetInstance(), cast[LPVOID](self))

  if self.mHwnd == 0:
    raise newException(wError, className & " window creation failure")

  wAppWindowAdd(self)
  if parent.isNil:
    wAppTopLevelWindowAdd(self)
  else:
    self.mFont = parent.mFont
    parent.mChildren.add(self)

  # preapre something after window creating but before set size.
  # aka WM_CREATE for wnim window.
  self.trigger()

  if self.mFont == nil: self.mFont = wDefaultFont
  SendMessage(self.mHwnd, WM_SETFONT, self.mFont.mHandle, 1)

  # set size after window create and font setting ok
  # because getDefaultSize usually use font to calculate size
  if size.width == wDefault or size.height == wDefault:
    let defaultSize = self.getDefaultSize()
    if size.width == wDefault: size.width = defaultSize.width
    if size.height == wDefault: size.height = defaultSize.height

  self.setSize(size)
  UpdateWindow(self.mHwnd)

  # use Do for system event handle, On for default behavior handle
  # the different is: system event handle shouldn't modify the event object
  self.systemConnect(WM_MOUSEMOVE, wWindow_DoMouseMove)
  self.systemConnect(WM_MOUSELEAVE, wWindow_DoMouseLeave)
  self.systemConnect(WM_SIZE, wWindow_DoSize)
  self.systemConnect(WM_DESTROY, wWindow_DoDestroy)
  self.systemConnect(WM_NCDESTROY, wWindow_DoNcDestroy)

  self.systemConnect(WM_GETMINMAXINFO, wWindow_DoGetMinMaxInfo)
  if regist: # let GUI controls handle scroll by themself
    self.systemConnect(WM_VSCROLL, wWindow_DoScroll)
    self.systemConnect(WM_HSCROLL, wWindow_DoScroll)

  self.hardConnect(WM_COMMAND, wWindow_OnCommand)
  self.hardConnect(WM_NOTIFY, wWindow_OnNotify)
  self.hardConnect(WM_CLOSE, wWindow_OnClose)
  self.hardConnect(WM_CTLCOLORBTN, wWindow_OnCtlColor)
  self.hardConnect(WM_CTLCOLOREDIT, wWindow_OnCtlColor)
  self.hardConnect(WM_CTLCOLORSTATIC, wWindow_OnCtlColor)
  self.hardConnect(WM_CTLCOLORLISTBOX, wWindow_OnCtlColor)
  self.hardConnect(WM_SETCURSOR, wWindow_OnSetCursor)

proc init*(self: wWindow, hWnd: HWND) {.validate.} =
  ## Initializer.
  self.initBase()
  self.mHwnd = hWnd
  self.mParent = wAppWindowFindByHwnd(GetParent(hwnd))
  self.mBackgroundColor = wDefaultColor
  self.mForegroundColor = wDefaultColor

  let hFont = cast[HANDLE](SendMessage(self.mHwnd, WM_GETFONT, 0, 0))
  if hFont != 0:
    self.mFont = Font(hFont)
  else:
    self.mFont = wNormalFont

  wAppWindowAdd(self)
  if self.mParent == nil:
    wAppTopLevelWindowAdd(self)
  else:
    self.mParent.mChildren.add(self)

  self.systemConnect(WM_MOUSEMOVE, wWindow_DoMouseMove)
  self.systemConnect(WM_MOUSELEAVE, wWindow_DoMouseLeave)
  self.systemConnect(WM_DESTROY, wWindow_DoDestroy)
  self.systemConnect(WM_NCDESTROY, wWindow_DoNcDestroy)
  # dont' WM_VSCROLL/WM_HSCROLL, we let subwindow handle it's own scroll

  SetWindowSubclass(hwnd, wSubProc, cast[UINT_PTR](self), cast[DWORD_PTR](self))

proc Window*(hWnd: HWND): wWindow {.discardable.} =
  ## Subclassed constructor
  new(result, final)
  result.init(hwnd)

proc init*(self: wWindow, parent: wWindow = nil, id: wCommandID = 0,
    pos = wDefaultPoint, size = wDefaultSize, style: wStyle = 0,
    className = "wWindow") {.validate, inline.} =
  ## Initializer.
  self.initVerbosely(parent=parent, id=id, pos=pos, size=size, style=style,
    className=className)

proc Window*(parent: wWindow = nil, id: wCommandID = 0,
    pos = wDefaultPoint, size = wDefaultSize, style: wStyle = 0,
    className = "wWindow"): wWindow {.inline, discardable.} =
  ## Constructs a window.
  # make all wWindow and subclass as discardable, because sometimes we just want
  # a window there and don't do anything about it. Especially for controls.
  new(result, final)
  result.init(parent, id, pos, size, style, className)
