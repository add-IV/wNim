## This control allows the user to enter time.
##
## :Superclass:
##    wControl
##
## :Appearance:
##    .. image:: images/wTimePickerCtrl.png
##
## :Events:
##    ==============================  =============================================================
##    Events                          Description
##    ==============================  =============================================================
##    wEventTimeChanged               The selected time changed.
##    ==============================  =============================================================

proc getTime*(self: wTimePickerCtrl): tuple[hour, min, sec: int] {.validate, property.} =
  ## Returns the currently entered time as hours, minutes and seconds
  var st: SYSTEMTIME
  if GDT_VALID == SendMessage(mHwnd, DTM_GETSYSTEMTIME, 0, addr st):
    result.hour = st.wHour.int
    result.min = st.wMinute.int
    result.sec = st.wSecond.int

proc setTime*(self: wTimePickerCtrl, hour: int, min: int, sec: int) {.validate, property.} =
  ## Changes the current time of the control.
  var st: SYSTEMTIME
  GetLocalTime(addr st)
  st.wHour = hour.WORD
  st.wMinute = min.WORD
  st.wSecond = sec.WORD
  SendMessage(mHwnd, DTM_SETSYSTEMTIME, GDT_VALID, addr st)

proc setTime*(self: wTimePickerCtrl, time: tuple[hour, min, sec: int]) {.validate, property.} =
  ## Changes the current time of the control.
  setTime(time.hour, time.min, time.sec)

proc getValue*(self: wTimePickerCtrl): wTime {.validate, property.} =
  ## Returns the currently entered time.
  var st: SYSTEMTIME
  if GDT_VALID == SendMessage(mHwnd, DTM_GETSYSTEMTIME, 0, addr st):
    result = st.toTime()

proc setValue*(self: wTimePickerCtrl, time: wTime) {.validate, property.} =
  ## Changes the current value of the control.
  var st = time.toSystemTime()
  SendMessage(mHwnd, DTM_SETSYSTEMTIME, GDT_VALID, addr st)

proc TimePickerCtrl*(parent: wWindow, id: wCommandID = wDefaultID, time: wTime = wDefaultTime,
    pos: wPoint = wDefaultPoint, size: wSize = wDefaultSize, style: wStyle = 0): wTimePickerCtrl {.discardable.} =
  ## Creates the control.
  ## ==========  =================================================================================
  ## Parameters  Description
  ## ==========  =================================================================================
  ## parent      Parent window.
  ## id          The identifier for the control.
  ## time        The initial value of the control, if an invalid date (such as the default value) is used, the control is set to current time.
  ## pos         Initial position.
  ## size        Initial size. If left at default value, the control chooses its own best size.
  ## style       The window style, should be left at 0 as there are no special styles for this control in this version.
  wValidate(parent)
  new(result)
  result.wDatePickerCtrl.init(parent=parent, id=id, date=time, pos=pos, size=size, style=style or DTS_TIMEFORMAT)
