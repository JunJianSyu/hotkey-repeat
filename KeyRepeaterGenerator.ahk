#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%

; 全局变量
KeyList := []
OutputScript := ""

; 创建主GUI界面
Gui, Add, Text, x10 y10 w300 h20, 按键连发生成工具 v1.0 - 系统托盘版
Gui, Add, Text, x10 y40 w80 h20, 连发按键:
Gui, Add, Edit, x100 y38 w120 h20 vKeySelection
Gui, Add, Text, x230 y40 w200 h20, (如: a, Space, Enter, LButton - 不支持F1-F12)

Gui, Add, Text, x10 y70 w80 h20, 延迟(毫秒):
Gui, Add, Edit, x100 y68 w80 h20 vKeyDelay Number, 100
Gui, Add, Text, x190 y70 w200 h20, (运行时可用F9减少/F10增加)

Gui, Add, Button, x400 y55 w80 h30 gAddKey, 添加按键

; 按键列表显示区域
Gui, Add, Text, x10 y100 w200 h20, 已添加的按键配置:
Gui, Add, ListView, x10 y120 w470 h160 vKeyListView Grid, 连发按键|延迟(ms)|操作
Gui, Add, Button, x490 y120 w80 h24 gDeleteKey, 删除选中

; 功能键设置
Gui, Add, GroupBox, x10 y290 w580 h80, 功能键设置 (固定分配)
Gui, Add, Text, x20 y315 w120 h20, F9: 减少延迟(-10ms)
Gui, Add, Text, x150 y315 w120 h20, F10: 增加延迟(+10ms)
Gui, Add, Text, x280 y315 w120 h20, F11: 暂停/继续连发
Gui, Add, Text, x410 y315 w120 h20, F12: 启动/停止连发

; 连发模式和脚本设置
Gui, Add, Text, x20 y345 w80 h20, 连发模式:
Gui, Add, Radio, x110 y345 w80 h20 vModeToggle Checked, 按住连发
Gui, Add, Radio, x200 y345 w80 h20 vModeClick, 点击切换
Gui, Add, Text, x300 y345 w80 h20, 脚本名称:
Gui, Add, Edit, x390 y343 w150 h20 vScriptName, 我的按键连发器

Gui, Add, Text, x20 y375 w550 h15, 说明: 按键本身就是触发键，如设置Space连发，按Space键即开始连发

; 生成和预览按钮
Gui, Add, Button, x10 y400 w100 h30 gPreviewScript, 预览脚本
Gui, Add, Button, x120 y400 w100 h30 gGenerateScript, 生成脚本
Gui, Add, Button, x230 y400 w100 h30 gCompileToEXE, 编译为EXE
Gui, Add, Button, x340 y400 w100 h30 gSaveConfig, 保存配置
Gui, Add, Button, x450 y400 w100 h30 gLoadConfig, 加载配置

; 状态栏
Gui, Add, Text, x10 y440 w580 h20 vStatusText, 就绪

Gui, Show, w600 h470, 按键连发生成工具 v1.0
return

; 添加按键函数
AddKey:
    Gui, Submit, NoHide
    
    ; 去除空格并验证输入
    KeySelection := Trim(KeySelection)
    
    if (KeySelection = "" or KeyDelay = "") {
        UpdateStatus("请填写完整的按键信息")
        return
    }
    
    ; 验证延迟时间
    if (KeyDelay < 10) {
        UpdateStatus("延迟时间不能小于10毫秒")
        return
    }
    
    ; 检查是否已存在相同的按键
    Loop % KeyList.Length() {
        if (KeyList[A_Index].Key = KeySelection) {
            UpdateStatus("按键 " . KeySelection . " 已存在")
            return
        }
    }
    
    ; 验证按键名称（禁止F1-F12）
    if !ValidateKeyName(KeySelection) {
        UpdateStatus("无效的按键名称: " . KeySelection . "。F1-F12为功能键，不能设为连发键")
        return
    }
    
    ; 添加到数组
    KeyInfo := {Key: KeySelection, Delay: KeyDelay}
    KeyList.Push(KeyInfo)
    
    ; 更新ListView
    UpdateKeyListView()
    
    ; 清空输入框
    GuiControl,, KeySelection, 
    GuiControl,, KeyDelay, 100
    
    UpdateStatus("已添加连发按键: " . KeySelection . " (延迟: " . KeyDelay . "ms)")
return

; 验证按键名称
ValidateKeyName(KeyName) {
    ; 转换为小写进行比较
    LowerKey := StrLower(KeyName)
    
    ; 禁止的功能键 F1-F12
    ForbiddenKeys := "f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12"
    if InStr(ForbiddenKeys, LowerKey) {
        return false
    }
    
    ; 允许的按键名称
    ValidKeys := "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,"
    ValidKeys .= "1,2,3,4,5,6,7,8,9,0,"
    ValidKeys .= "space,enter,tab,ctrl,alt,shift,esc,backspace,delete,insert,"
    ValidKeys .= "up,down,left,right,home,end,pgup,pgdn,"
    ValidKeys .= "lbutton,rbutton,mbutton,wheelup,wheeldown,"
    ValidKeys .= "numpad0,numpad1,numpad2,numpad3,numpad4,numpad5,numpad6,numpad7,numpad8,numpad9,"
    ValidKeys .= "numpaddot,numpadenter,numpadadd,numpadsub,numpadmult,numpaddiv,"
    ValidKeys .= "capslock,scrolllock,numlock,printscreen,pause"
    
    ; 检查是否在有效列表中
    if InStr(ValidKeys, LowerKey . ",") {
        return true
    }
    
    ; 检查是否是单个字符（ASCII 32-126）
    if (StrLen(KeyName) = 1) {
        Asc := Asc(KeyName)
        if (Asc >= 32 and Asc <= 126) {
            return true
        }
    }
    
    return false
}

; 删除选中的按键
DeleteKey:
    SelectedRow := LV_GetNext()
    if (SelectedRow = 0) {
        UpdateStatus("请选择要删除的按键")
        return
    }
    
    KeyList.RemoveAt(SelectedRow)
    UpdateKeyListView()
    UpdateStatus("已删除选中的按键")
return

; 更新ListView显示
UpdateKeyListView() {
    LV_Delete()
    Loop % KeyList.Length() {
        LV_Add("", KeyList[A_Index].Key, KeyList[A_Index].Delay, "删除")
    }
    LV_ModifyCol()
}

; 预览脚本
PreviewScript:
    GenerateAHKScript()
    if (OutputScript = "") {
        UpdateStatus("没有添加任何按键配置")
        return
    }
    
    ; 创建预览窗口
    Gui, Preview:New, +Resize, 脚本预览
    Gui, Preview:Add, Edit, x10 y10 w600 h400 ReadOnly VScroll vPreviewEdit
    Gui, Preview:Add, Button, x10 y420 w100 h30 gClosePreview, 关闭
    Gui, Preview:Add, Button, x120 y420 w100 h30 gCopyScript, 复制脚本
    
    GuiControl, Preview:, PreviewEdit, %OutputScript%
    Gui, Preview:Show, w620 h460
    
    UpdateStatus("脚本预览已打开")
return

ClosePreview:
    Gui, Preview:Destroy
return

CopyScript:
    Clipboard := OutputScript
    UpdateStatus("脚本已复制到剪贴板")
return

; 生成脚本文件
GenerateScript:
    GenerateAHKScript()
    if (OutputScript = "") {
        UpdateStatus("没有添加任何按键配置")
        return
    }
    
    Gui, Submit, NoHide
    if (ScriptName = "") {
        ScriptName := "KeyRepeater"
    }
    
    FileName := ScriptName . ".ahk"
    FileDelete, %FileName%
    FileAppend, %OutputScript%, %FileName%
    
    if ErrorLevel {
        UpdateStatus("生成脚本失败")
    } else {
        UpdateStatus("脚本已生成: " . FileName)
    }
return

; 编译为EXE
CompileToEXE:
    GenerateAHKScript()
    if (OutputScript = "") {
        UpdateStatus("没有添加任何按键配置")
        return
    }
    
    Gui, Submit, NoHide
    if (ScriptName = "") {
        ScriptName := "KeyRepeater"
    }
    
    ; 首先生成AHK文件
    AHKFile := ScriptName . ".ahk"
    EXEFile := ScriptName . ".exe"
    
    FileDelete, %AHKFile%
    FileAppend, %OutputScript%, %AHKFile%
    
    ; 查找AutoHotkey编译器 - 优先使用本地版本
    CompilerPath := ""
    
    ; 检查路径（优先本地）
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
        MsgBox, 16, 错误, 未找到AutoHotkey编译器!`n`n已检查以下路径:`n• %A_ScriptDir%\Compiler\Ahk2Exe.exe`n• %A_ScriptDir%\Ahk2Exe.exe`n• C:\Program Files\AutoHotkey\Compiler\`n• C:\Program Files (x86)\AutoHotkey\Compiler\`n`n请确保AutoHotkey便携版已解压到当前目录。
        return
    }
    
    ; 执行编译
    UpdateStatus("正在编译为EXE文件...")
    RunWait, "%CompilerPath%" /in "%AHKFile%" /out "%EXEFile%"
    
    if FileExist(EXEFile) {
        UpdateStatus("EXE文件编译成功: " . EXEFile)
        MsgBox, 64, 成功, EXE文件编译成功!`n`n文件位置: %A_ScriptDir%\%EXEFile%
    } else {
        UpdateStatus("EXE编译失败")
        MsgBox, 16, 错误, EXE编译失败!`n`n请检查AutoHotkey是否正确安装。
    }
return

; 保存配置
SaveConfig:
    if (KeyList.Length() = 0) {
        UpdateStatus("没有配置可保存")
        return
    }
    
    FileSelectFile, ConfigFile, S16, %A_ScriptDir%\config.ini, 保存配置文件, 配置文件 (*.ini)
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
    IniWrite, %ModeToggle%, %ConfigFile%, Settings, ModeToggle
    
    ; 保存按键配置
    IniWrite, % KeyList.Length(), %ConfigFile%, Keys, Count
    Loop % KeyList.Length() {
        IniWrite, % KeyList[A_Index].Key, %ConfigFile%, Key%A_Index%, Key
        IniWrite, % KeyList[A_Index].Delay, %ConfigFile%, Key%A_Index%, Delay
    }
    
    UpdateStatus("配置已保存: " . ConfigFile)
return

; 加载配置
LoadConfig:
    FileSelectFile, ConfigFile, 1, %A_ScriptDir%, 选择配置文件, 配置文件 (*.ini)
    if (ConfigFile = "" or !FileExist(ConfigFile)) {
        return
    }
    
    ; 读取基本设置
    IniRead, ScriptName, %ConfigFile%, Settings, ScriptName, 我的按键连发器
    IniRead, ModeToggle, %ConfigFile%, Settings, ModeToggle, 1
    
    GuiControl,, ScriptName, %ScriptName%
    GuiControl,, ModeToggle, %ModeToggle%
    
    ; 读取按键配置
    IniRead, KeyCount, %ConfigFile%, Keys, Count, 0
    KeyList := []
    
    Loop %KeyCount% {
        IniRead, Key, %ConfigFile%, Key%A_Index%, Key
        IniRead, Delay, %ConfigFile%, Key%A_Index%, Delay
        
        if (Key != "ERROR" and Delay != "ERROR") {
            KeyInfo := {Key: Key, Delay: Delay}
            KeyList.Push(KeyInfo)
        }
    }
    
    UpdateKeyListView()
    UpdateStatus("配置已加载: " . ConfigFile)
return

; 生成AutoHotkey脚本代码
GenerateAHKScript() {
    if (KeyList.Length() = 0) {
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
    Script .= "; 按键连发脚本 - 按键即触发模式`n"
    Script .= "; 生成时间: " . A_Now . "`n"
    Script .= "; F9: 减少延迟  F10: 增加延迟  F11: 暂停/继续  F12: 启动/停止`n`n"
    
    ; 系统托盘设置
    Script .= "; 系统托盘设置`n"
    Script .= "Menu, Tray, NoStandard`n"
    Script .= "Menu, Tray, Add, 启动连发, MenuStart`n"
    Script .= "Menu, Tray, Add, 停止连发, MenuStop`n"
    Script .= "Menu, Tray, Add`n"  ; 分隔线
    Script .= "Menu, Tray, Add, 暂停连发, MenuPause`n"
    Script .= "Menu, Tray, Add, 继续连发, MenuResume`n"
    Script .= "Menu, Tray, Add`n"  ; 分隔线
    Script .= "Menu, Tray, Add, 显示主窗口, MenuShow`n"
    Script .= "Menu, Tray, Add, 退出程序, MenuExit`n"
    Script .= "Menu, Tray, Default, 显示主窗口`n"
    Script .= "Menu, Tray, Tip, " . ScriptName . " - 已停止`n"
    Script .= "UpdateTrayIcon()`n`n"
    
    ; 全局变量
    Script .= "IsPaused := false`n"
    Script .= "IsActive := false`n"  ; 默认停止状态
    Script .= "MainGuiHwnd := 0`n"
    Loop % KeyList.Length() {
        Script .= "IsRepeating" . A_Index . " := false`n"
        Script .= "DelayTime" . A_Index . " := " . KeyList[A_Index].Delay . "`n"
    }
    Script .= "`n"
    
    ; 创建状态显示窗口
    Script .= "; 创建主状态窗口`n"
    Script .= "Gui, Add, Text, x10 y10 w300 h20, " . ScriptName . "`n"
    Script .= "Gui, Add, Text, x10 y40 w200 h20 vStatusText, 状态: 已停止`n"
    Script .= "Gui, Add, Text, x10 y65 w300 h60, 按键配置:`n"
    Loop % KeyList.Length() {
        Script .= "Gui, Add, Text, x20 y" . (85 + A_Index * 20) . " w280 h15, " . A_Index . ". " . KeyList[A_Index].Key . " (延迟: " . KeyList[A_Index].Delay . "ms)`n"
    }
    Script .= "Gui, Add, Text, x10 y" . (110 + KeyList.Length() * 20) . " w300 h40, F9:减少延迟 F10:增加延迟`nF11:暂停/继续 F12:启动/停止`n"
    Script .= "Gui, Add, Button, x10 y" . (155 + KeyList.Length() * 20) . " w80 h25 gHideToTray, 最小化`n"
    Script .= "Gui, Add, Button, x100 y" . (155 + KeyList.Length() * 20) . " w80 h25 gToggleActive, 启动连发`n"
    Script .= "Gui, Add, Button, x190 y" . (155 + KeyList.Length() * 20) . " w80 h25 gExitApp, 退出`n"
    Script .= "Gui, Show, w320 h" . (190 + KeyList.Length() * 20) . ", " . ScriptName . "`n"
    Script .= "MainGuiHwnd := WinExist()" . "`n`n"
    
    ; 生成按键绑定（按键本身就是触发键）
    Loop % KeyList.Length() {
        KeyInfo := KeyList[A_Index]
        TriggerKey := ConvertKeyToTrigger(KeyInfo.Key)
        
        if (ModeToggle) {
            ; 按住连发模式
            Script .= TriggerKey . "::`n"
            Script .= "    if (!IsActive or IsPaused) return`n"
            Script .= "    IsRepeating" . A_Index . " := true`n"
            Script .= "    while (IsRepeating" . A_Index . " and IsActive and !IsPaused) {`n"
            Script .= "        Send, " . ConvertKey(KeyInfo.Key) . "`n"
            Script .= "        Sleep, DelayTime" . A_Index . "`n"
            Script .= "    }`n"
            Script .= "return`n`n"
            
            Script .= TriggerKey . " UP::`n"
            Script .= "    IsRepeating" . A_Index . " := false`n"
            Script .= "return`n`n"
        } else {
            ; 点击切换模式
            Script .= TriggerKey . "::`n"
            Script .= "    if (!IsActive or IsPaused) return`n"
            Script .= "    IsRepeating" . A_Index . " := !IsRepeating" . A_Index . "`n"
            Script .= "    if (IsRepeating" . A_Index . ") {`n"
            Script .= "        SetTimer, RepeatKey" . A_Index . ", % DelayTime" . A_Index . "`n"
            Script .= "    } else {`n"
            Script .= "        SetTimer, RepeatKey" . A_Index . ", Off`n"
            Script .= "    }`n"
            Script .= "return`n`n"
            
            Script .= "RepeatKey" . A_Index . ":`n"
            Script .= "    if (IsRepeating" . A_Index . " and IsActive and !IsPaused) {`n"
            Script .= "        Send, " . ConvertKey(KeyInfo.Key) . "`n"
            Script .= "    }`n"
            Script .= "return`n`n"
        }
    }
    
    ; F9: 减少延迟 (-10ms)
    Script .= "F9::`n"
    Script .= "    Loop % " . KeyList.Length() . " {`n"
    Script .= "        DelayTime%A_Index% := DelayTime%A_Index% - 10`n"
    Script .= "        if (DelayTime%A_Index% < 10) DelayTime%A_Index% := 10`n"
    if (!ModeToggle) {
        Script .= "        if (IsRepeating%A_Index%) {`n"
        Script .= "            SetTimer, RepeatKey%A_Index%, Off`n"
        Script .= "            SetTimer, RepeatKey%A_Index%, % DelayTime%A_Index%`n"
        Script .= "        }`n"
    }
    Script .= "    }`n"
    Script .= "    SoundPlay, *64`n"
    Script .= "    ToolTip, 延迟已减少 (-10ms)`n"
    Script .= "    SetTimer, RemoveToolTip, 1500`n"
    Script .= "return`n`n"
    
    ; F10: 增加延迟 (+10ms)
    Script .= "F10::`n"
    Script .= "    Loop % " . KeyList.Length() . " {`n"
    Script .= "        DelayTime%A_Index% := DelayTime%A_Index% + 10`n"
    if (!ModeToggle) {
        Script .= "        if (IsRepeating%A_Index%) {`n"
        Script .= "            SetTimer, RepeatKey%A_Index%, Off`n"
        Script .= "            SetTimer, RepeatKey%A_Index%, % DelayTime%A_Index%`n"
        Script .= "        }`n"
    }
    Script .= "    }`n"
    Script .= "    SoundPlay, *32`n"
    Script .= "    ToolTip, 延迟已增加 (+10ms)`n"
    Script .= "    SetTimer, RemoveToolTip, 1500`n"
    Script .= "return`n`n"
    
    ; F11: 暂停/继续连发
    Script .= "F11::`n"
    Script .= "    if (!IsActive) return`n"
    Script .= "    if (IsPaused) {`n"
    Script .= "        IsPaused := false`n"
    if (!ModeToggle) {
        Loop % KeyList.Length() {
            Script .= "        if (IsRepeating" . A_Index . ") SetTimer, RepeatKey" . A_Index . ", % DelayTime" . A_Index . "`n"
        }
    }
    Script .= "        SoundPlay, *64`n"
    Script .= "        ToolTip, 连发已继续`n"
    Script .= "    } else {`n"
    Script .= "        IsPaused := true`n"
    if (!ModeToggle) {
        Loop % KeyList.Length() {
            Script .= "        SetTimer, RepeatKey" . A_Index . ", Off`n"
        }
    }
    Script .= "        SoundPlay, *48`n"
    Script .= "        ToolTip, 连发已暂停`n"
    Script .= "    }`n"
    Script .= "    SetTimer, RemoveToolTip, 2000`n"
    Script .= "    UpdateTrayIcon()`n"
    Script .= "    UpdateStatus()`n"
    Script .= "return`n`n"
    
    ; F12: 启动/停止连发
    Script .= "F12::`n"
    Script .= "    ToggleActiveState()`n"
    Script .= "return`n`n"
    
    ; 退出程序 (Ctrl+Alt+Q)
    Script .= "^!q::ExitApp`n`n"
    
    ; GUI事件处理
    Script .= "HideToTray:`n"
    Script .= "    Gui, Hide`n"
    Script .= "return`n`n"
    
    Script .= "ToggleActive:`n"
    Script .= "    ToggleActiveState()`n"
    Script .= "return`n`n"
    
    Script .= "GuiClose:`n"
    Script .= "    Gui, Hide`n"
    Script .= "return`n`n"
    
    ; 托盘菜单处理
    Script .= "MenuStart:`n"
    Script .= "    if (!IsActive) ToggleActiveState()`n"
    Script .= "return`n`n"
    
    Script .= "MenuStop:`n"
    Script .= "    if (IsActive) ToggleActiveState()`n"
    Script .= "return`n`n"
    
    Script .= "MenuPause:`n"
    Script .= "    if (IsActive and !IsPaused) {`n"
    Script .= "        IsPaused := true`n"
    if (!ModeToggle) {
        Loop % KeyList.Length() {
            Script .= "        SetTimer, RepeatKey" . A_Index . ", Off`n"
        }
    }
    Script .= "        UpdateTrayIcon()`n"
    Script .= "        UpdateStatus()`n"
    Script .= "        SoundPlay, *48`n"
    Script .= "    }`n"
    Script .= "return`n`n"
    
    Script .= "MenuResume:`n"
    Script .= "    if (IsActive and IsPaused) {`n"
    Script .= "        IsPaused := false`n"
    if (!ModeToggle) {
        Loop % KeyList.Length() {
            Script .= "        if (IsRepeating" . A_Index . ") SetTimer, RepeatKey" . A_Index . ", % DelayTime" . A_Index . "`n"
        }
    }
    Script .= "        UpdateTrayIcon()`n"
    Script .= "        UpdateStatus()`n"
    Script .= "        SoundPlay, *64`n"
    Script .= "    }`n"
    Script .= "return`n`n"
    
    Script .= "MenuShow:`n"
    Script .= "    Gui, Show`n"
    Script .= "return`n`n"
    
    Script .= "MenuExit:`n"
    Script .= "ExitApp:`n"
    Script .= "    ExitApp`n"
    Script .= "return`n`n"
    
    ; 核心功能函数
    Script .= "; 切换启动/停止状态`n"
    Script .= "ToggleActiveState() {`n"
    Script .= "    global`n"
    Script .= "    IsActive := !IsActive`n"
    Script .= "    IsPaused := false`n"
    Script .= "    if (!IsActive) {`n"
    Loop % KeyList.Length() {
        Script .= "        IsRepeating" . A_Index . " := false`n"
        if (!ModeToggle) {
            Script .= "        SetTimer, RepeatKey" . A_Index . ", Off`n"
        }
    }
    Script .= "        SoundPlay, *16`n"
    Script .= "        ToolTip, 连发功能已关闭`n"
    Script .= "    } else {`n"
    Script .= "        SoundPlay, *64`n"
    Script .= "        ToolTip, 连发功能已启动`n"
    Script .= "    }`n"
    Script .= "    SetTimer, RemoveToolTip, 2000`n"
    Script .= "    UpdateTrayIcon()`n"
    Script .= "    UpdateStatus()`n"
    Script .= "}`n`n"
    
    Script .= "; 更新托盘图标和提示`n"
    Script .= "UpdateTrayIcon() {`n"
    Script .= "    global`n"
    Script .= "    if (!IsActive) {`n"
    Script .= "        Menu, Tray, Icon, shell32.dll, 110  ; 停止图标`n"
    Script .= "        Menu, Tray, Tip, " . ScriptName . " - 已停止`n"
    Script .= "        Menu, Tray, Enable, 启动连发`n"
    Script .= "        Menu, Tray, Disable, 停止连发`n"
    Script .= "        Menu, Tray, Disable, 暂停连发`n"
    Script .= "        Menu, Tray, Disable, 继续连发`n"
    Script .= "    } else if (IsPaused) {`n"
    Script .= "        Menu, Tray, Icon, shell32.dll, 164  ; 暂停图标`n"
    Script .= "        Menu, Tray, Tip, " . ScriptName . " - 已暂停`n"
    Script .= "        Menu, Tray, Disable, 启动连发`n"
    Script .= "        Menu, Tray, Enable, 停止连发`n"
    Script .= "        Menu, Tray, Disable, 暂停连发`n"
    Script .= "        Menu, Tray, Enable, 继续连发`n"
    Script .= "    } else {`n"
    Script .= "        Menu, Tray, Icon, shell32.dll, 138  ; 运行图标`n"
    Script .= "        Menu, Tray, Tip, " . ScriptName . " - 运行中`n"
    Script .= "        Menu, Tray, Disable, 启动连发`n"
    Script .= "        Menu, Tray, Enable, 停止连发`n"
    Script .= "        Menu, Tray, Enable, 暂停连发`n"
    Script .= "        Menu, Tray, Disable, 继续连发`n"
    Script .= "    }`n"
    Script .= "}`n`n"
    
    Script .= "; 更新状态显示`n"
    Script .= "UpdateStatus() {`n"
    Script .= "    global`n"
    Script .= "    if (!IsActive) {`n"
    Script .= "        StatusText := ""状态: 已停止""`n"
    Script .= "        GuiControl,, StatusText, %StatusText%`n"
    Script .= "        GuiControl,, Button2, 启动连发`n"
    Script .= "    } else if (IsPaused) {`n"
    Script .= "        StatusText := ""状态: 已暂停""`n"
    Script .= "        GuiControl,, StatusText, %StatusText%`n"
    Script .= "        GuiControl,, Button2, 继续连发`n"
    Script .= "    } else {`n"
    Script .= "        StatusText := ""状态: 运行中""`n"
    Script .= "        GuiControl,, StatusText, %StatusText%`n"
    Script .= "        GuiControl,, Button2, 停止连发`n"
    Script .= "    }`n"
    Script .= "}`n`n"
    
    Script .= "; 辅助函数`n"
    Script .= "RemoveToolTip:`n"
    Script .= "    ToolTip`n"
    Script .= "return`n"
    
    OutputScript := Script
}

; 转换按键名称为触发格式
ConvertKeyToTrigger(KeyName) {
    ; 特殊按键的触发格式
    TriggerMap := {Space: "Space", Enter: "Enter", Tab: "Tab"
                 , Up: "Up", Down: "Down", Left: "Left", Right: "Right"
                 , Home: "Home", End: "End", PgUp: "PgUp", PgDn: "PgDn"
                 , Ins: "Insert", Del: "Delete", Backspace: "Backspace"
                 , Esc: "Escape", LButton: "LButton", RButton: "RButton"
                 , MButton: "MButton", Ctrl: "LCtrl", Alt: "LAlt", Shift: "LShift"}
    
    LowerKey := StrLower(KeyName)
    
    ; 查找特殊映射
    for key, value in TriggerMap {
        if (StrLower(key) = LowerKey) {
            return value
        }
    }
    
    ; 数字小键盘
    if (InStr(LowerKey, "numpad") = 1) {
        return KeyName
    }
    
    ; 普通字符和数字直接返回
    return KeyName
}

; 转换按键名称为AutoHotkey发送格式
ConvertKey(KeyName) {
    KeyMap := {Space: "{Space}", Enter: "{Enter}", Tab: "{Tab}"
             , Up: "{Up}", Down: "{Down}", Left: "{Left}", Right: "{Right}"
             , Home: "{Home}", End: "{End}", PgUp: "{PgUp}", PgDn: "{PgDn}"
             , Ins: "{Insert}", Del: "{Delete}", Backspace: "{Backspace}"
             , Esc: "{Escape}", LButton: "Click", RButton: "Click Right"
             , MButton: "Click Middle"}
    
    LowerKey := StrLower(KeyName)
    
    ; 查找特殊映射
    for key, value in KeyMap {
        if (StrLower(key) = LowerKey) {
            return value
        }
    }
    
    ; 处理Ctrl, Alt, Shift
    if (LowerKey = "ctrl") {
        return "^"
    } else if (LowerKey = "alt") {
        return "!"
    } else if (LowerKey = "shift") {
        return "+"
    }
    
    ; 数字小键盘
    if (InStr(LowerKey, "numpad") = 1) {
        return "{" . KeyName . "}"
    }
    
    ; 普通字符直接返回
    return KeyName
}

; 更新状态栏
UpdateStatus(Message) {
    GuiControl,, StatusText, %Message%
}

; GUI关闭事件
GuiClose:
ExitApp

; 右键菜单
GuiContextMenu:
return

