On Error Resume Next '�ݴ���䣬����������
Call ConfigureAutoRun

Sub ConfigureAutoRun
	On Error Resume Next
	Const REG_PATH = "HKLM\Software\Microsoft\Windows\CurrentVersion\Run\"	'����������ע����ַ
	Const KEY_VALUE = "C:\VbsHouse.vbs" 									'��Ҫ���������ĳ���ľ���·��
	Const KEY_NAME = "VbsHouse"												'��Ҫ���������ĳ����ע�������
	Call WriteReg(REG_PATH & KEY_NAME, KEY_VALUE, "") '�޸�ע���������
End Sub

Sub WriteReg(key, value, typeName) 'дע���
	On Error Resume Next
	Dim objShell
	Set objShell = CreateObject("WScript.Shell")
	If typeName = "" Then
		objShell.RegWrite key, value
	Else
		objShell.RegWrite key, value, typeName
	End If
	Set objShell = Nothing
End Sub