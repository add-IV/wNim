## Basic types definition for wNim.

type
  wSize* = tuple
    ## A data structure contains integer width and height.
    width: int
    height: int

  wPoint* = tuple
    ## A data structure contains integer x and y.
    x: int
    y: int

  wRect* = tuple
    ## A data structure contains x, y, width, and height.
    x: int
    y: int
    width: int
    height: int

  wDirection* = tuple
    ## A data structure contains left, up, right, down.
    left: int
    up: int
    right: int
    down: int

  wError* = object of Exception
    ## Base of exception use in wNim.

  wCommandID* = distinct int
    ## A integer number used in menus or GUI controls as the ID.

  wStyle* = int64
    ## The wNim window style type. It simply combine of windows' style and exstyle.

  wColor* = int32
    ## Representing a combination of Red, Green, and Blue (RGB) intensity values.
    ## Same as windows' COLORREF.

  wTime* = Time
    ## Represents a point in time.

const
  wDefault* = int32.low.int
    ## Used in wNim as default value.
  wDefaultFloat* = NaN
    ## Used in wNim as default float value.
  wDefaultColor: wColor = 0xFFFFFFFF'i32
    ## Used in wNim as default color.
  wDefaultPoint*: wPoint = (wDefault, wDefault)
    ## Used in wNim as default point.
  wDefaultPosition*: wPoint = (wDefault, wDefault)
    ## Used in wNim as default position.
  wDefaultSize*: wSize = (wDefault, wDefault)
    ## Used in wNim as default size.
  wDefaultRect*: wRect = (wDefault, wDefault, wDefault, wDefault)
    ## Used in wNim as default rect.
  wDefaultTime*: wTime = wTime int64.low
    ## Used in wNim as default time.
  wDefaultID*: wCommandID = wCommandID(-1)
    ## Used in wNim as default command ID.
  wNotFound* = -1

  # Direction
  wLeft* = 0x0010
  wRight* = 0x0020
  wUp* = 0x0040
  wDown* = 0x0080
  wTop* = wUp
  wBottom* = wDown
  wNorth* = wUp
  wSouth* = wDown
  wWest* = wLeft
  wEast* = wRight
  wHorizontal* = wLeft
  wVertical* = wUp
  wBoth* = wHorizontal or wVertical
  wCenter* = wLeft or wRight
  wMiddle* = wUp or wDown


converter converterIntEnumTowCommandID*(x: int|enum): wCommandID = wCommandID x
  ## We usually use the enum for where need a command ID. see the examples.

type
  wId* = enum
    ## Predefined names to use as menus or controls ID.
    wIdLowest = 4999, wIdOpen, wIdClose, wIdNew, wIdSave, wIdSaveAS, wIdRevert,
      wIdExit, wIdUndo, wIdRedo, wIdHelp, wIdPrint, wIdPrintSetup, wIdPreview,
      wIdAbout, wIdHelpContents, wIdHelpCommands, wIdHelpProcedures, wIdCloseAll,
      wIdDelete, wIdProperties, wIdReplace

    wIdCut = 5030, wIdCopy, wIdPaste, wIdClear, wIdFind, wIdDuplicate,
      wIdSelectAll

    wIdFile1 = 5050, wIdFile2, wIdFile3, wIdFile4, wIdFile5, wIdFile6, wIdFile7,
      wIdFile8, wIdFile9

    wIdOk = 5100, wIdCancel, wIdApply, wIdYes, wIdNo, wIdStatic, wIdForward,
      wIdBackward, wIdDefault, wIdMore, wIdSetup, wIdReset, wIdContextHelp,
      wIdYesToAll, wIdNoToAll, wIdAbort, wIdRetry, wIdIgnore, wIdContinue,
      wIdTryAgain

    wIdSystemMenu = 5200, wIdCloseFrame, wIdMoveFrame, wIdResizeFrame,
      wIdMaximizeFrame, wIdIconizeFrame, wIdRestoreFrame

    wIdHighest = 5999, wIdUser

when not defined(wnimdoc):
  # Mutually recursive types are only possible within a single type section.
  # So we collect all type definition in this module.
  type
    wEventHandler = proc (event: wEvent)
    wEventNeatHandler = proc ()

    wApp* = ref object of RootObj
      mInstance: HANDLE
      mTopLevelWindowList: seq[wWindow]
      mWindowTable: Table[HWND, wWindow]
      mGDIStockSeq: seq[wGdiObject]
      mPropagationSet: HashSet[UINT]
      mMessageCountTable: CountTable[UINT]
      mExitCode: uint
      mAccelExists: bool

    wEvent* = ref object of RootObj
      mWindow: wWindow
      mOrigin: HWND
      mMsg: UINT
      mId: wCommandID
      mWparam: WPARAM
      mLparam: LPARAM
      mUserData: int
      mSkip: bool
      mPropagationLevel: int
      mResult: LRESULT
      mKeyStatus: array[256, int8] # use int8 so that we can test if it < 0
      mMousePos: wPoint
      mClientPos: wPoint

    wMouseEvent* = ref object of wEvent
    wKeyEvent* = ref object of wEvent
    wSizeEvent* = ref object of wEvent
    wMoveEvent* = ref object of wEvent
    wScrollWinEvent* = ref object of wEvent
    wOtherEvent* = ref object of wEvent
    wContextMenuEvent* = ref object of wEvent
    wCommandEvent* = ref object of wEvent
    wNavigationEvent* = ref object of wEvent
    wSetCursorEvent* = ref object of wEvent
    wTrayEvent* = ref object of wEvent
    wStatusBarEvent* = ref object of wCommandEvent
    wListEvent* = ref object of wCommandEvent
      mIndex: int
      mCol: int
      mText: string
    wTreeEvent* = ref object of wCommandEvent
      mTreeCtrl: wTreeCtrl
      mHandle: HTREEITEM
      mOldHandle: HTREEITEM
      mText: string
      mInsertMark: int
      mPoint: wPoint
    wScrollEvent* = ref object of wCommandEvent
    wSpinEvent* = ref object of wCommandEvent
    wHyperLinkEvent* = ref object of wCommandEvent

    wScrollData = object
      kind: int
      orientation: int

    wResizable* = ref object of RootObj
      mLeft: Variable
      mRight: Variable
      mTop: Variable
      mBottom: Variable

    wResizer* = ref object of RootObj
      mSolver: Solver
      mObjects: HashSet[wResizable]

    wEventConnection = tuple
      msg: UINT
      id: wCommandID
      handler: wEventHandler
      neatHandler: wEventNeatHandler
      userData: int
      undeletable: bool

    wAcceleratorTable* = ref object of RootObj
      mHandle: HACCEL
      mAccels: seq[ACCEL]
      mModified: bool

    wSizingInfo = ref object
      border: wDirection
      dragging: bool
      ready: tuple[up, down, left, right: bool]
      offset: wDirection
      connection: tuple[move, up, down: wEventConnection]

    wDraggableInfo = ref object
      enable: bool
      inClient: bool
      dragging: bool
      startMousePos: wPoint
      startPos: wPoint
      connection: tuple[move, down, up: wEventConnection]

    wWindow* = ref object of wResizable
      mHwnd: HWND
      mParent: wWindow
      mChildren: seq[wWindow]
      mMargin: wDirection
      mStatusBar: wStatusBar
      mToolBar: wToolBar
      mFont: wFont
      mBackgroundColor: wColor
      mForegroundColor: wColor
      mBackgroundBrush: wBrush
      mCursor: wCursor
      mOverrideCursor: wCursor
      mSystemConnectionTable: Table[UINT, DoublyLinkedList[wEventConnection]]
      mConnectionTable: Table[UINT, DoublyLinkedList[wEventConnection]]
      mAcceleratorTable: wAcceleratorTable
      mSaveFocus: wWindow
      mFocusable: bool
      mMaxSize: wSize
      mMinSize: wSize
      mDummyParent: HWND
      mMouseInWindow: bool
      mSizingInfo: wSizingInfo
      mDraggableInfo: wDraggableInfo

    wFrame* = ref object of wWindow
      mMenuBar: wMenuBar
      mIcon: wIcon
      mDisableList: seq[wWindow]
      mTrayIcon: wIcon
      mTrayToolTip: string
      mTrayIconAdded: bool
      mTrayConn: wEventConnection
      mCreateConn: wEventConnection

    wPanel* = ref object of wWindow

    wControl* = ref object of wWindow

    wStatusBar* = ref object of wControl
      mFiledNumbers: int
      mWidths: array[256, int32]

    wToolBarTool* = ref object of RootObj
      mBitmap: wBitmap
      mShortHelp: string
      mLongHelp: string
      mMenu: wMenu

    wToolBar* = ref object of wControl
      mTools: seq[wToolBarTool]

    wButton* = ref object of wControl
      mImgData: BUTTON_IMAGELIST
      mDefault: bool
      mMenu: wMenu

    wStaticText* = ref object of wControl

    wStaticBitmap* = ref object of wControl
      mBitmap: wBitmap

    wStaticLine* = ref object of wControl

    wCheckBox* = ref object of wControl

    wRadioButton* = ref object of wControl

    wStaticBox* = ref object of wControl

    wComboBox* = ref object of wControl
      mEdit: wTextCtrl
      mList: wWindow
      mOldEditProc: WNDPROC
      mInitData: ptr UncheckedArray[string]
      mInitCount: int

    wTextCtrl* = ref object of wControl
      mRich: bool
      mDisableTextEvent: bool
      mBestSize: wSize
      mCommandConn: wEventConnection

    wNoteBook* = ref object of wControl
      mImageList: wImageList
      mSelection: int
      mPages: seq[wPanel]

    wSpinCtrl* = ref object of wControl
      mUpdownHwnd: HWND
      mUpdownWidth: int

    wSpinButton* = ref object of wControl

    wSlider* = ref object of wControl
      mReversed: bool
      mMax: int
      mMin: int
      mDragging: bool

    wScrollBar* = ref object of wControl
      mPageSize: int
      mRange: int

    wGauge* = ref object of wControl
      mTaskBar: ptr ITaskbarList3

    wCalendarCtrl* = ref object of wControl

    wDatePickerCtrl* = ref object of wControl

    wTimePickerCtrl* = ref object of wDatePickerCtrl

    wListBox* = ref object of wControl
      mInitData: ptr UncheckedArray[string]
      mInitCount: int

    wListCtrl* = ref object of wControl
      mColCount: int
      mImageListNormal: wImageList
      mImageListSmall: wImageList
      mImageListState: wImageList
      mAlternateRowColor: wColor
      mTextCtrl: wTextCtrl
      mDragging: bool

    wTreeCtrl* = ref object of wControl
      mImageListNormal: wImageList
      mImageListState: wImageList
      mOwnsImageListNormal: bool
      mOwnsImageListState: bool
      mInSortChildren: bool
      mDataTable: Table[HTREEITEM, int]
      mTextCtrl: wTextCtrl
      mEnableInsertMark: bool
      mDragging: bool
      mCurrentInsertMark: int
      mCurrentInsertItem: HTREEITEM

    wTreeItem* = object
      mHandle: HTREEITEM
      mTreeCtrl: wTreeCtrl

    wHyperLinkCtrl* = ref object of wControl

    wSplitter* = ref object of wControl
      mIsVertical: bool
      mSize: int
      mDragging: bool
      mResizing: bool
      mPanel1: wPanel
      mPanel2: wPanel
      mMin1: int
      mMin2: int
      mPosOffset: wPoint
      mInPanelMargin: bool
      mSystemConnections: seq[tuple[win: wWindow, conn: wEventConnection]]
      mConnections: seq[tuple[win: wWindow, conn: wEventConnection]]
      mAttach1: bool
      mAttach2: bool

    # wToolTip* = ref wToolTipObj
    # wToolTipObj = object of wControlObj

    wMenuBase* = ref object of RootObj
      mHmenu: HMENU

    wMenu* = ref object of wMenuBase
      mBitmap: wBitmap
      mItemList: seq[wMenuItem]
      mParentMenuCountTable: CountTable[wMenuBase]

    wMenuBar* = ref object of wMenuBase
      mMenuList: seq[wMenu]
      mParentFrameSet: HashSet[wFrame]

    wMenuItemKind* = enum
      wMenuItemNormal
      wMenuItemSeparator
      wMenuItemCheck
      wMenuItemRadio
      wMenuItemSubMenu

    wMenuItem* = ref object of RootObj
      mId: wCommandID
      mKind: wMenuItemKind
      mText: string
      mHelp: string
      mBitmap: wBitmap
      mSubmenu: wMenu
      mParentMenu: wMenu

    wImage* = ref object of RootObj
      mGdipBmp: ptr GpBitmap

    wImageList* = ref object of RootObj
      mHandle: HIMAGELIST

    wGdiObject* = ref object of RootObj
      mHandle: HANDLE

    wFont* = ref object of wGdiObject
      mPointSize: float
      mFamily: int
      mWeight: int
      mItalic: bool
      mUnderline: bool
      mFaceName: string
      mEncoding: int

    wPen* = ref object of wGdiObject
      mColor: wColor
      mStyle: DWORD
      mWidth: int

    wBrush* = ref object of wGdiObject
      mColor: wColor
      mStyle: DWORD

    wBitmap* = ref object of wGdiObject
      mWidth: int
      mHeight: int
      mDepth: int

    wIcon* = ref object of wGdiObject
      mWidth: int
      mHeight: int

    wCursor* = ref object of wGdiObject
      mDeletable: bool
      mIconResource: bool

    # device context type is "object" not "ref object"

    wDC* = object of RootObj
      mHdc: HDC
      mTextBackgroundColor: wColor
      mTextForegroundColor: wColor
      mFont: wFont
      mPen: wPen
      mBrush: wBrush
      mBackground: wBrush
      mBitmap: wBitmap
      mScale: tuple[x, y: float]
      mCanvas: wWindow
      mhOldFont: HANDLE
      mhOldPen: HANDLE
      mhOldBrush: HANDLE
      mhOldBitmap: HANDLE

    wMemoryDC* = object of wDC

    wWindowDC* = object of wDC

    wScreenDC* = object of wDC

    wClientDC* = object of wDC

    wPaintDC* = object of wDC
      mPs: PAINTSTRUCT

    wMessageDialog* = ref object of RootObj
      mHook: HHOOK
      mParent: wWindow
      mMessage: string
      mCaption: string
      mStyle: wStyle
      mLabelText: Table[INT, string]

    wDirDialog* = ref object of RootObj
      mParent: wWindow
      mMessage: string
      mPath: string
      mStyle: wStyle

    wFileDialog* = ref object of RootObj
      mParent: wWindow
      mMessage: string
      mDefaultDir: string
      mDefaultFile: string
      mWildcard: string
      mStyle: wStyle
      mFilterIndex: int
      mPath: string
      mPaths: seq[string]

    wColorDialog* = ref object of RootObj
      mParent: wWindow
      mColor: wColor
      mStyle: wStyle
      mCustomColor: array[16, wColor]

  proc `==`*(x: wCommandID, y: wCommandID): bool {.borrow.}
  proc `$`*(x: wCommandID): string {.borrow.}
  proc hash*(o: ref object): Hash {.inline.} = hash(cast[int](o))

