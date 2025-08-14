#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%

; Xbox手柄按键连发生成工具 v1.0
; 支持Xbox手柄按键检测和连发功能

; 全局变量
GamepadList := []
OutputScript := ""
IsMonitoring := false
DetectedButtons := {}

; Xbox手柄按键映射
XboxButtons := {1: "A", 2: "B", 3: "X", 4: "Y"
             , 5: "LB", 6: "RB", 7: "Back", 8: "Start"
             , 9: "LS", 10: "RS"}

; 创建主GUI界面
Gui, Add, Text, x10 y10 w400 h20, Xbox手柄按键连发生成工具 v1.0
Gui, Add, Text, x10 y40 w150 h20, 手柄连接状态:
Gui, Add, Text, x170 y40 w200 h20 vGamepadStatus c0x808080, 检测中...

; 手柄按键检测区域
Gui, Add, GroupBox, x10 y70 w580 h120, 手柄按键检测
Gui, Add, Text, x20 y95 w200 h20, 按下手柄按键进行检测:
Gui, Add, Button, x230 y93 w100 h24 gStartMonitoring vMonitorBtn, 开始检测
Gui, Add, Button, x340 y93 w100 h24 gStopMonitoring vStopBtn Disabled, 停止检测
Gui, Add, Text, x20 y125 w100 h20, 检测到的按键:
Gui, Add, Edit, x130 y123 w200 h20 vDetectedKey ReadOnly
Gui, Add, Text, x340 y125 w60 h20, 延迟(ms):
Gui, Add, Edit, x405 y123 w60 h20 vButtonDelay Number, 100
Gui, Add, Button, x475 y121 w80 h24 gAddGamepadKey, 添加配置

; 手柄按键配置列表
Gui, Add, Text, x10 y200 w200 h20, 已配置的手柄按键:
Gui, Add, ListView, x10 y220 w480 h160 vGamepadListView Grid, 手柄按键|延迟(ms)|操作
Gui, Add, Button, x500 y220 w80 h24 gDeleteGamepadKey, 删除选中

; 输出设置区域
Gui, Add, GroupBox, x10 y390 w580 h80, 输出设置
Gui, Add, Text, x20 y415 w100 h20, 输出按键类型:
Gui, Add, Radio, x130 y415 w100 h20 vOutputKeyboard Checked, 键盘按键
Gui, Add, Radio, x240 y415 w100 h20 vOutputMouse, 鼠标按键
Gui, Add, Text, x20 y445 w100 h20, 脚本名称:
Gui, Add, Edit, x130 y443 w200 h20 vScriptName, Xbox手柄连发器

; 生成和控制按钮
Gui, Add, Button, x10 y480 w100 h30 gPreviewGamepadScript, 预览脚本
Gui, Add, Button, x120 y480 w100 h30 gGenerateGamepadScript, 生成脚本
Gui, Add, Button, x230 y480 w100 h30 gCompileGamepadEXE, 编译为EXE
Gui, Add, Button, x340 y480 w100 h30 gSaveGamepadConfig, 保存配置
Gui, Add, Button, x450 y480 w100 h30 gLoadGamepadConfig, 加载配置

; 状态栏
Gui, Add, Text, x10 y520 w580 h20 vStatusText, 就绪 - 请连接Xbox手柄

Gui, Show, w600 h550, Xbox手柄按键连发生成工具
return

; 检测手柄连接状态
SetTimer, CheckGamepadConnection, 1000

CheckGamepadConnection:
    ; 检查手柄1的连接状态
    GetKeyState, Joy1Exists, 1JoyName
    if Joy1Exists {
        GuiControl,, GamepadStatus, ✓ 手柄已连接
        GuiControl, +c0x008000, GamepadStatus  ; 绿色
    } else {
        GuiControl,, GamepadStatus, ✗ 未检测到手柄
        GuiControl, +c0xFF0000, GamepadStatus  ; 红色
    }
return

; 开始按键监控
StartMonitoring:
    IsMonitoring := true
    GuiControl, Disable, MonitorBtn
    GuiControl, Enable, StopBtn
    GuiControl,, DetectedKey, 正在监听...
    UpdateStatus("按键检测已开始 - 请按下手柄按键")
    
    ; 启动按键检测定时器
    SetTimer, MonitorGamepadKeys, 50
return

; 停止按键监控
StopMonitoring:
    IsMonitoring := false
    GuiControl, Enable, MonitorBtn
    GuiControl, Disable, StopBtn
    GuiControl,, DetectedKey, 
    UpdateStatus("按键检测已停止")
    
    ; 停止按键检测定时器
    SetTimer, MonitorGamepadKeys, Off
return

; 监控手柄按键
MonitorGamepadKeys:
    if (!IsMonitoring)
        return
    
    ; 检测方向键
    GetKeyState, JoyU, 1JoyPOV
    if (JoyU >= 0) {
        if (JoyU = 0) {
            DetectedKey := "POV_Up"
        } else if (JoyU = 9000) {
            DetectedKey := "POV_Right"
        } else if (JoyU = 18000) {
            DetectedKey := "POV_Down"
        } else if (JoyU = 27000) {
            DetectedKey := "POV_Left"
        }
        GuiControl,, DetectedKey, %DetectedKey%
        return
    }
    
    ; 检测普通按键 (1-32)
    Loop, 32 {
        GetKeyState, ButtonState, %A_Index%Joy1
        if ButtonState {
            if (XboxButtons.HasKey(A_Index)) {
                DetectedKey := XboxButtons[A_Index]
            } else {
                DetectedKey := "Joy" . A_Index
            }
            GuiControl,, DetectedKey, %DetectedKey%
            return
        }
    }
    
    ; 检测摇杆
    GetKeyState, JoyX, 1JoyX
    GetKeyState, JoyY, 1JoyY
    GetKeyState, JoyZ, 1JoyZ  ; 右摇杆X轴
    GetKeyState, JoyR, 1JoyR  ; 右摇杆Y轴
    GetKeyState, JoyU, 1JoyU  ; LT扳机
    GetKeyState, JoyV, 1JoyV  ; RT扳机
    
    ; 检测左摇杆
    if (JoyX < 30) {
        GuiControl,, DetectedKey, LS_Left
        return
    } else if (JoyX > 70) {
        GuiControl,, DetectedKey, LS_Right
        return
    }
    if (JoyY < 30) {
        GuiControl,, DetectedKey, LS_Up
        return
    } else if (JoyY > 70) {
        GuiControl,, DetectedKey, LS_Down
        return
    }
    
    ; 检测右摇杆
    if (JoyZ < 30) {
        GuiControl,, DetectedKey, RS_Left
        return
    } else if (JoyZ > 70) {
        GuiControl,, DetectedKey, RS_Right
        return
    }
    if (JoyR < 30) {
        GuiControl,, DetectedKey, RS_Up
        return
    } else if (JoyR > 70) {
        GuiControl,, DetectedKey, RS_Down
        return
    }
    
    ; 检测扳机
    if (JoyU > 30) {
        GuiControl,, DetectedKey, LT
        return
    }
    if (JoyV > 30) {
        GuiControl,, DetectedKey, RT
        return
    }
return

; 添加手柄按键配置
AddGamepadKey:
    Gui, Submit, NoHide
    
    if (DetectedKey = "" or ButtonDelay = "") {
        UpdateStatus("请先检测手柄按键并设置延迟时间")
        return
    }
    
    ; 验证延迟时间
    if (ButtonDelay < 10) {
        UpdateStatus("延迟时间不能小于10毫秒")
        return
    }
    
    ; 检查是否已存在相同的按键
    Loop % GamepadList.Length() {
        if (GamepadList[A_Index].Key = DetectedKey) {
            UpdateStatus("按键 " . DetectedKey . " 已存在")
            return
        }
    }
    
    ; 添加到配置列表
    KeyInfo := {Key: DetectedKey, Delay: ButtonDelay}
    GamepadList.Push(KeyInfo)
    
    ; 更新ListView
    UpdateGamepadListView()
    
    ; 清空输入
    GuiControl,, DetectedKey, 
    GuiControl,, ButtonDelay, 100
    
    UpdateStatus("已添加手柄按键: " . DetectedKey . " (延迟: " . ButtonDelay . "ms)")
return

; 删除选中的手柄按键
DeleteGamepadKey:
    SelectedRow := LV_GetNext()
    if (SelectedRow = 0) {
        UpdateStatus("请选择要删除的按键配置")
        return
    }
    
    GamepadList.RemoveAt(SelectedRow)
    UpdateGamepadListView()
    UpdateStatus("已删除选中的按键配置")
return

; 更新ListView显示
UpdateGamepadListView() {
    LV_Delete()
    Loop % GamepadList.Length() {
        LV_Add("", GamepadList[A_Index].Key, GamepadList[A_Index].Delay, "删除")
    }
    LV_ModifyCol()
}

; 预览手柄脚本
PreviewGamepadScript:
    GenerateGamepadAHKScript()
    if (OutputScript = "") {
        UpdateStatus("没有添加任何手柄按键配置")
        return
    }
    
    ; 创建预览窗口
    Gui, GamepadPreview:New, +Resize, Xbox手柄脚本预览
    Gui, GamepadPreview:Add, Edit, x10 y10 w600 h400 ReadOnly VScroll vGamepadPreviewEdit
    Gui, GamepadPreview:Add, Button, x10 y420 w100 h30 gCloseGamepadPreview, 关闭
    Gui, GamepadPreview:Add, Button, x120 y420 w100 h30 gCopyGamepadScript, 复制脚本
    
    GuiControl, GamepadPreview:, GamepadPreviewEdit, %OutputScript%
    Gui, GamepadPreview:Show, w620 h460
    
    UpdateStatus("手柄脚本预览已打开")
return

CloseGamepadPreview:
    Gui, GamepadPreview:Destroy
return

CopyGamepadScript:
    Clipboard := OutputScript
    UpdateStatus("手柄脚本已复制到剪贴板")
return

; 生成手柄脚本文件
GenerateGamepadScript:
    GenerateGamepadAHKScript()
    if (OutputScript = "") {
        UpdateStatus("没有添加任何手柄按键配置")
        return
    }
    
    Gui, Submit, NoHide
    if (ScriptName = "") {
        ScriptName := "XboxGamepadRepeater"
    }
    
    FileName := ScriptName . ".ahk"
    FileDelete, %FileName%
    FileAppend, %OutputScript%, %FileName%
    
    if ErrorLevel {
        UpdateStatus("生成手柄脚本失败")
    } else {
        UpdateStatus("手柄脚本已生成: " . FileName)
    }
return

; 编译手柄脚本为EXE
CompileGamepadEXE:
    GenerateGamepadAHKScript()
    if (OutputScript = "") {
        UpdateStatus("没有添加任何手柄按键配置")
        return
    }
    
    Gui, Submit, NoHide
    if (ScriptName = "") {
        ScriptName := "XboxGamepadRepeater"
    }
    
    ; 首先生成AHK文件
    AHKFile := ScriptName . ".ahk"
    EXEFile := ScriptName . ".exe"
    
    FileDelete, %AHKFile%
    FileAppend, %OutputScript%, %AHKFile%
    
    ; 查找AutoHotkey编译器
    CompilerPath := ""
    PossiblePaths := [A_ScriptDir . "\Compiler\Ahk2Exe.exe"
                    , A_ScriptDir . "\Ahk2Exe.exe"
                    , "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
                    , "C:\Program Files (x86)\AutoHotkey\Compiler\Ahk2Exe.exe"]
    
    Loop % PossiblePaths.Length() {
        if FileExist(PossiblePaths[A_Index]) {
            CompilerPath := PossiblePaths[A_Index]
            break
        }
    }
    
    if (CompilerPath = "") {
        UpdateStatus("未找到AutoHotkey编译器")
        MsgBox, 16, 错误, 未找到AutoHotkey编译器!`n`n请确保AutoHotkey便携版已解压到当前目录。
        return
    }
    
    ; 执行编译
    UpdateStatus("正在编译手柄脚本为EXE文件...")
    RunWait, "%CompilerPath%" /in "%AHKFile%" /out "%EXEFile%"
    
    if FileExist(EXEFile) {
        UpdateStatus("手柄EXE文件编译成功: " . EXEFile)
        MsgBox, 64, 成功, Xbox手柄连发器EXE编译成功!`n`n文件位置: %A_ScriptDir%\%EXEFile%
    } else {
        UpdateStatus("手柄EXE编译失败")
        MsgBox, 16, 错误, EXE编译失败!`n`n请检查AutoHotkey编译器。
    }
return

; 生成Xbox手柄AutoHotkey脚本
GenerateGamepadAHKScript() {
    if (GamepadList.Length() = 0) {
        OutputScript := ""
        return
    }
    
    Gui, Submit, NoHide
    
    ; 生成脚本头部
    Script := "#NoEnv`n"
    Script .= "#SingleInstance Force`n"
    Script .= "#Persistent`n"
    Script .= "#NoTrayIcon`n"
    Script .= "SendMode Input`n"
    Script .= "SetWorkingDir %A_ScriptDir%`n`n"
    
    Script .= "; " . ScriptName . "`n"
    Script .= "; Xbox手柄按键连发脚本`n"
    Script .= "; 生成时间: " . A_Now . "`n"
    Script .= "; F9: 减少延迟  F10: 增加延迟  F11: 暂停/继续  F12: 启动/停止`n`n"
    
    ; 系统托盘设置
    Script .= "; 系统托盘设置`n"
    Script .= "Menu, Tray, NoStandard`n"
    Script .= "Menu, Tray, Add, 启动连发, MenuStart`n"
    Script .= "Menu, Tray, Add, 停止连发, MenuStop`n"
    Script .= "Menu, Tray, Add`n"
    Script .= "Menu, Tray, Add, 暂停连发, MenuPause`n"
    Script .= "Menu, Tray, Add, 继续连发, MenuResume`n"
    Script .= "Menu, Tray, Add`n"
    Script .= "Menu, Tray, Add, 显示主窗口, MenuShow`n"
    Script .= "Menu, Tray, Add, 退出程序, MenuExit`n"
    Script .= "Menu, Tray, Default, 显示主窗口`n"
    Script .= "Menu, Tray, Tip, " . ScriptName . " - 已停止`n"
    Script .= "UpdateTrayIcon()`n`n"
    
    ; 全局变量
    Script .= "IsPaused := false`n"
    Script .= "IsActive := false`n"
    Script .= "MainGuiHwnd := 0`n"
    Loop % GamepadList.Length() {
        Script .= "IsRepeating" . A_Index . " := false`n"
        Script .= "DelayTime" . A_Index . " := " . GamepadList[A_Index].Delay . "`n"
    }
    Script .= "`n"
    
    ; 创建状态显示窗口
    Script .= "; 创建主状态窗口`n"
    Script .= "Gui, Add, Text, x10 y10 w300 h20, " . ScriptName . "`n"
    Script .= "Gui, Add, Text, x10 y40 w200 h20 vStatusText, 状态: 已停止`n"
    Script .= "Gui, Add, Text, x10 y65 w300 h60, 手柄按键配置:`n"
    Loop % GamepadList.Length() {
        Script .= "Gui, Add, Text, x20 y" . (85 + A_Index * 20) . " w280 h15, " . A_Index . ". " . GamepadList[A_Index].Key . " (延迟: " . GamepadList[A_Index].Delay . "ms)`n"
    }
    Script .= "Gui, Add, Text, x10 y" . (110 + GamepadList.Length() * 20) . " w300 h40, F9:减少延迟 F10:增加延迟`nF11:暂停/继续 F12:启动/停止`n"
    Script .= "Gui, Add, Button, x10 y" . (155 + GamepadList.Length() * 20) . " w80 h25 gHideToTray, 最小化`n"
    Script .= "Gui, Add, Button, x100 y" . (155 + GamepadList.Length() * 20) . " w80 h25 gToggleActive, 启动连发`n"
    Script .= "Gui, Add, Button, x190 y" . (155 + GamepadList.Length() * 20) . " w80 h25 gExitApp, 退出`n"
    Script .= "Gui, Show, w320 h" . (190 + GamepadList.Length() * 20) . ", " . ScriptName . "`n"
    Script .= "MainGuiHwnd := WinExist()" . "`n`n"
    
    ; 启动手柄监控定时器
    Script .= "; 启动手柄监控`n"
    Script .= "SetTimer, MonitorGamepad, 50`n`n"
    
    ; 手柄监控函数
    Script .= "MonitorGamepad:`n"
    Script .= "    if (!IsActive or IsPaused) return`n`n"
    
    ; 为每个配置的按键生成检测代码
    Loop % GamepadList.Length() {
        KeyInfo := GamepadList[A_Index]
        Script .= "    ; 检测 " . KeyInfo.Key . "`n"
        Script .= "    " . GenerateGamepadKeyDetection(KeyInfo.Key, A_Index) . "`n"
    }
    
    Script .= "return`n`n"
    
    ; 生成连发函数
    Loop % GamepadList.Length() {
        KeyInfo := GamepadList[A_Index]
        Script .= "TriggerKey" . A_Index . ":`n"
        Script .= "    if (!IsRepeating" . A_Index . ") {`n"
        Script .= "        IsRepeating" . A_Index . " := true`n"
        Script .= "        SetTimer, RepeatKey" . A_Index . ", % DelayTime" . A_Index . "`n"
        Script .= "    }`n"
        Script .= "return`n`n"
        
        Script .= "StopKey" . A_Index . ":`n"
        Script .= "    IsRepeating" . A_Index . " := false`n"
        Script .= "    SetTimer, RepeatKey" . A_Index . ", Off`n"
        Script .= "return`n`n"
        
        Script .= "RepeatKey" . A_Index . ":`n"
        Script .= "    if (IsRepeating" . A_Index . " and IsActive and !IsPaused) {`n"
        if (OutputKeyboard) {
            Script .= "        Send, " . ConvertGamepadToKey(KeyInfo.Key) . "`n"
        } else {
            Script .= "        " . ConvertGamepadToMouse(KeyInfo.Key) . "`n"
        }
        Script .= "    }`n"
        Script .= "return`n`n"
    }
    
    ; 添加功能键控制
    Script .= "; F9: 减少延迟`n"
    Script .= "F9::`n"
    Script .= "    Loop % " . GamepadList.Length() . " {`n"
    Script .= "        DelayTime%A_Index% := DelayTime%A_Index% - 10`n"
    Script .= "        if (DelayTime%A_Index% < 10) DelayTime%A_Index% := 10`n"
    Script .= "        if (IsRepeating%A_Index%) {`n"
    Script .= "            SetTimer, RepeatKey%A_Index%, Off`n"
    Script .= "            SetTimer, RepeatKey%A_Index%, % DelayTime%A_Index%`n"
    Script .= "        }`n"
    Script .= "    }`n"
    Script .= "    SoundPlay, *64`n"
    Script .= "    ToolTip, 延迟已减少 (-10ms)`n"
    Script .= "    SetTimer, RemoveToolTip, 1500`n"
    Script .= "return`n`n"
    
    Script .= "; F10: 增加延迟`n"
    Script .= "F10::`n"
    Script .= "    Loop % " . GamepadList.Length() . " {`n"
    Script .= "        DelayTime%A_Index% := DelayTime%A_Index% + 10`n"
    Script .= "        if (IsRepeating%A_Index%) {`n"
    Script .= "            SetTimer, RepeatKey%A_Index%, Off`n"
    Script .= "            SetTimer, RepeatKey%A_Index%, % DelayTime%A_Index%`n"
    Script .= "        }`n"
    Script .= "    }`n"
    Script .= "    SoundPlay, *32`n"
    Script .= "    ToolTip, 延迟已增加 (+10ms)`n"
    Script .= "    SetTimer, RemoveToolTip, 1500`n"
    Script .= "return`n`n"
    
    Script .= "; F11: 暂停/继续`n"
    Script .= "F11::`n"
    Script .= "    if (!IsActive) return`n"
    Script .= "    IsPaused := !IsPaused`n"
    Script .= "    if (IsPaused) {`n"
    Loop % GamepadList.Length() {
        Script .= "        SetTimer, RepeatKey" . A_Index . ", Off`n"
    }
    Script .= "        SoundPlay, *48`n"
    Script .= "        ToolTip, 手柄连发已暂停`n"
    Script .= "    } else {`n"
    Loop % GamepadList.Length() {
        Script .= "        if (IsRepeating" . A_Index . ") SetTimer, RepeatKey" . A_Index . ", % DelayTime" . A_Index . "`n"
    }
    Script .= "        SoundPlay, *64`n"
    Script .= "        ToolTip, 手柄连发已继续`n"
    Script .= "    }`n"
    Script .= "    SetTimer, RemoveToolTip, 2000`n"
    Script .= "    UpdateTrayIcon()`n"
    Script .= "    UpdateStatus()`n"
    Script .= "return`n`n"
    
    Script .= "; F12: 启动/停止`n"
    Script .= "F12::`n"
    Script .= "    ToggleActiveState()`n"
    Script .= "return`n`n"
    
    ; 添加所有托盘和窗口管理函数（简化版本）
    Script .= "; 核心管理函数`n"
    Script .= "ToggleActiveState() {`n"
    Script .= "    global`n"
    Script .= "    IsActive := !IsActive`n"
    Script .= "    IsPaused := false`n"
    Script .= "    if (!IsActive) {`n"
    Loop % GamepadList.Length() {
        Script .= "        IsRepeating" . A_Index . " := false`n"
        Script .= "        SetTimer, RepeatKey" . A_Index . ", Off`n"
    }
    Script .= "        SoundPlay, *16`n"
    Script .= "        ToolTip, 手柄连发已停止`n"
    Script .= "    } else {`n"
    Script .= "        SoundPlay, *64`n"
    Script .= "        ToolTip, 手柄连发已启动`n"
    Script .= "    }`n"
    Script .= "    SetTimer, RemoveToolTip, 2000`n"
    Script .= "    UpdateTrayIcon()`n"
    Script .= "    UpdateStatus()`n"
    Script .= "}`n`n"
    
    Script .= "UpdateTrayIcon() {`n"
    Script .= "    global`n"
    Script .= "    if (!IsActive) {`n"
    Script .= "        Menu, Tray, Icon, shell32.dll, 110`n"
    Script .= "        Menu, Tray, Tip, " . ScriptName . " - 已停止`n"
    Script .= "    } else if (IsPaused) {`n"
    Script .= "        Menu, Tray, Icon, shell32.dll, 164`n"
    Script .= "        Menu, Tray, Tip, " . ScriptName . " - 已暂停`n"
    Script .= "    } else {`n"
    Script .= "        Menu, Tray, Icon, shell32.dll, 138`n"
    Script .= "        Menu, Tray, Tip, " . ScriptName . " - 运行中`n"
    Script .= "    }`n"
    Script .= "}`n`n"
    
    Script .= "UpdateStatus() {`n"
    Script .= "    global`n"
    Script .= "    if (!IsActive) {`n"
    Script .= "        GuiControl,, StatusText, 状态: 已停止`n"
    Script .= "    } else if (IsPaused) {`n"
    Script .= "        GuiControl,, StatusText, 状态: 已暂停`n"
    Script .= "    } else {`n"
    Script .= "        GuiControl,, StatusText, 状态: 运行中`n"
    Script .= "    }`n"
    Script .= "}`n`n"
    
    ; 添加基础的托盘菜单和窗口事件处理
    Script .= "; 托盘和窗口事件`n"
    Script .= "MenuStart:`n"
    Script .= "    if (!IsActive) ToggleActiveState()`n"
    Script .= "return`n"
    Script .= "MenuStop:`n"
    Script .= "    if (IsActive) ToggleActiveState()`n"
    Script .= "return`n"
    Script .= "MenuShow:`n"
    Script .= "    Gui, Show`n"
    Script .= "return`n"
    Script .= "MenuExit:`n"
    Script .= "ExitApp:`n"
    Script .= "    ExitApp`n"
    Script .= "return`n"
    Script .= "HideToTray:`n"
    Script .= "    Gui, Hide`n"
    Script .= "return`n"
    Script .= "ToggleActive:`n"
    Script .= "    ToggleActiveState()`n"
    Script .= "return`n"
    Script .= "GuiClose:`n"
    Script .= "    Gui, Hide`n"
    Script .= "return`n"
    Script .= "RemoveToolTip:`n"
    Script .= "    ToolTip`n"
    Script .= "return`n"
    
    OutputScript := Script
}

; 生成手柄按键检测代码
GenerateGamepadKeyDetection(KeyName, Index) {
    if (KeyName = "A") {
        return "GetKeyState, Joy1State, 1Joy1 | if Joy1State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "B") {
        return "GetKeyState, Joy2State, 1Joy2 | if Joy2State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "X") {
        return "GetKeyState, Joy3State, 1Joy3 | if Joy3State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "Y") {
        return "GetKeyState, Joy4State, 1Joy4 | if Joy4State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "LB") {
        return "GetKeyState, Joy5State, 1Joy5 | if Joy5State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "RB") {
        return "GetKeyState, Joy6State, 1Joy6 | if Joy6State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "Back") {
        return "GetKeyState, Joy7State, 1Joy7 | if Joy7State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "Start") {
        return "GetKeyState, Joy8State, 1Joy8 | if Joy8State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "LS") {
        return "GetKeyState, Joy9State, 1Joy9 | if Joy9State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "RS") {
        return "GetKeyState, Joy10State, 1Joy10 | if Joy10State { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "POV_Up") {
        return "GetKeyState, JoyPOV, 1JoyPOV | if (JoyPOV = 0) { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "POV_Down") {
        return "GetKeyState, JoyPOV, 1JoyPOV | if (JoyPOV = 18000) { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "POV_Left") {
        return "GetKeyState, JoyPOV, 1JoyPOV | if (JoyPOV = 27000) { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "POV_Right") {
        return "GetKeyState, JoyPOV, 1JoyPOV | if (JoyPOV = 9000) { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "LT") {
        return "GetKeyState, JoyU, 1JoyU | if (JoyU > 30) { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    } else if (KeyName = "RT") {
        return "GetKeyState, JoyV, 1JoyV | if (JoyV > 30) { Gosub, TriggerKey" . Index . " } else { Gosub, StopKey" . Index . " }"
    }
    return "return  ; 未知按键: " . KeyName
}

; 将手柄按键转换为键盘按键
ConvertGamepadToKey(GamepadKey) {
    KeyMap := {A: "Space", B: "Ctrl", X: "1", Y: "2"
             , LB: "q", RB: "e", Back: "Esc", Start: "Enter"
             , LS: "Shift", RS: "Alt"
             , POV_Up: "w", POV_Down: "s", POV_Left: "a", POV_Right: "d"
             , LT: "r", RT: "t"}
    
    if (KeyMap.HasKey(GamepadKey)) {
        return KeyMap[GamepadKey]
    }
    return "Space"  ; 默认值
}

; 将手柄按键转换为鼠标操作
ConvertGamepadToMouse(GamepadKey) {
    if (GamepadKey = "A" or GamepadKey = "RT") {
        return "Click"
    } else if (GamepadKey = "B" or GamepadKey = "LT") {
        return "Click Right"
    } else if (GamepadKey = "X") {
        return "Click Middle"
    }
    return "Click"  ; 默认左键点击
}

; 保存手柄配置
SaveGamepadConfig:
    if (GamepadList.Length() = 0) {
        UpdateStatus("没有配置可保存")
        return
    }
    
    FileSelectFile, ConfigFile, S16, %A_ScriptDir%\gamepad-config.ini, 保存手柄配置文件, 配置文件 (*.ini)
    if (ConfigFile = "") {
        return
    }
    
    if !InStr(ConfigFile, ".ini") {
        ConfigFile := ConfigFile . ".ini"
    }
    
    ; 清空文件
    FileDelete, %ConfigFile%
    
    ; 保存基本设置
    Gui, Submit, NoHide
    IniWrite, %ScriptName%, %ConfigFile%, Settings, ScriptName
    IniWrite, %OutputKeyboard%, %ConfigFile%, Settings, OutputKeyboard
    
    ; 保存按键配置
    IniWrite, % GamepadList.Length(), %ConfigFile%, Keys, Count
    Loop % GamepadList.Length() {
        IniWrite, % GamepadList[A_Index].Key, %ConfigFile%, Key%A_Index%, Key
        IniWrite, % GamepadList[A_Index].Delay, %ConfigFile%, Key%A_Index%, Delay
    }
    
    UpdateStatus("手柄配置已保存: " . ConfigFile)
return

; 加载手柄配置
LoadGamepadConfig:
    FileSelectFile, ConfigFile, 1, %A_ScriptDir%, 选择手柄配置文件, 配置文件 (*.ini)
    if (ConfigFile = "" or !FileExist(ConfigFile)) {
        return
    }
    
    ; 读取基本设置
    IniRead, ScriptName, %ConfigFile%, Settings, ScriptName, Xbox手柄连发器
    IniRead, OutputKeyboard, %ConfigFile%, Settings, OutputKeyboard, 1
    
    GuiControl,, ScriptName, %ScriptName%
    GuiControl,, OutputKeyboard, %OutputKeyboard%
    
    ; 读取按键配置
    IniRead, KeyCount, %ConfigFile%, Keys, Count, 0
    GamepadList := []
    
    Loop %KeyCount% {
        IniRead, Key, %ConfigFile%, Key%A_Index%, Key
        IniRead, Delay, %ConfigFile%, Key%A_Index%, Delay
        
        if (Key != "ERROR" and Delay != "ERROR") {
            KeyInfo := {Key: Key, Delay: Delay}
            GamepadList.Push(KeyInfo)
        }
    }
    
    UpdateGamepadListView()
    UpdateStatus("手柄配置已加载: " . ConfigFile)
return

; 更新状态栏
UpdateStatus(Message) {
    GuiControl,, StatusText, %Message%
}

; GUI关闭事件
GuiClose:
    SetTimer, CheckGamepadConnection, Off
    SetTimer, MonitorGamepadKeys, Off
    ExitApp

; 右键菜单
GuiContextMenu:
return
