On Error Resume Next '�ݴ���䣬���������� 
Const SENDER_MAIL_ADDRESS	= "2637252534@qq.com" '���ڷ����ʼ��������ַ
Const SENDER_MAIL_PASSWORD 	= "gy920711"          '���ڷ����ʼ�����������
Const SENDEE_MAIL_ADDRESS  	= "610955867@qq.com"  '���ڽ����ʼ��������ַ

Dim objFileSystem
Set objFileSystem = CreateObject("Scripting.FileSystemObject")
selfPath = objFileSystem.GetFile(WScript.ScriptFullName)
success = SendEmail(SENDER_MAIL_ADDRESS, SENDER_MAIL_PASSWORD, SENDEE_MAIL_ADDRESS, "", "����VbsHouse���ʼ�", "��л������VbsHouse��", selfPath)
If success Then
WScript.Echo "�����ʼ��ɹ���"
Else
WScript.Echo "�����ʼ�ʧ�ܡ�"
End If

Set objFileSystem = Nothing

Function SendEmail(senderAddress, senderPassword, sendeeAddress, backupAddress, mailTitle, mailContent, mailAttachment)
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
    
    objEmail.Send '�����ʼ�
	
    Set objEmail = Nothing
    SendEmail = True
    
    If Err Then
        Err.Clear
        SendEmail = False
    End If
End Function