B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	If File.Exists(File.DirApp,"TM")=False Then
		File.MakeDir(File.DirApp,"TM")
	End If
	If req.Method <> "POST" Then
		resp.SendError(500, "method not supported.")
		Return
	End If
	resp.ContentType = "application/json"
	resp.CharacterEncoding="UTF-8"

	Dim parts As Map = req.GetMultipartData(Main.TempDir, 50*1000*1000*1000) 'byte
	Dim filePart As Part = parts.Get("file1")
	Dim tmID As String= Utils.UniqueID
	If filePart.SubmittedFilename.ToLowerCase.EndsWith(".zip") Then
		Dim outdirPath As String
		outdirPath=File.Combine(Main.TempDir,tmID)
		If File.Exists(outdirPath,"")=False Then
			File.MakeDir(outdirPath,"")
		End If
		Dim zip As zip4j
		zip.Initialize
		zip.unzip(filePart.TempFile,"",outdirPath)
		Dim hasTMX As Boolean=False
		For Each filename As String In File.ListFiles(outdirPath)
		    If filename.ToLowerCase.EndsWith(".tmx") Then
				hasTMX=True
				File.Copy(outdirPath,filename,File.Combine(File.DirApp,"TM"),tmID&".tmx")
				Exit
		    End If
		Next
		If hasTMX=False Then
			resp.Write("no tmx file")
			Return
		End If
	else if filePart.SubmittedFilename.ToLowerCase.EndsWith(".tmx") Then
		File.Copy(filePart.TempFile,"",File.Combine(File.DirApp,"TM"),tmID&".tmx")
	Else
		resp.Write("unsupported file")
		Return
	End If
	File.Delete("", filePart.TempFile)
	Dim result As Map
	result.Initialize
	result.Put("tmID",tmID)
	result.Put("name",filePart.SubmittedFilename)
	result.Put("preview",TMXPreview(File.Combine(File.DirApp,"/TM/"&tmID&".tmx")))
	Dim json As JSONGenerator
	json.Initialize(result)
	resp.Write(json.ToString)
End Sub

Sub TMXPreview(path As String) As String
	Try
		Dim previewSB As StringBuilder
		previewSB.Initialize
		Dim tmxString As String
		tmxString=File.ReadString(path,"")
		tmxString=XMLUtils.pickSmallerXML(tmxString,"tu","body")
		tmxString=XMLUtils.escapedText(tmxString,"seg","tmx")
		Dim tmxMap As Map
		tmxMap=XMLUtils.getXmlMap(tmxString)
		Dim tmxroot As Map
		tmxroot=tmxMap.Get("tmx")
		Dim body As Map
		body=tmxroot.Get("body")
		Dim tuList As List
		tuList=XMLUtils.GetElements(body,"tu")
		Dim i As Int
		For Each tu As Map In tuList
			previewSB.Append(i+1).Append(CRLF)
			Dim tuvList As List
			tuvList=XMLUtils.GetElements(tu,"tuv")
			For Each tuv As Map In tuvList
				Dim attributes As Map
				attributes=tuv.Get("Attributes")

				Dim lang As String
				If attributes.ContainsKey("lang") Then
					lang=attributes.Get("lang")
				else if attributes.ContainsKey("xml:lang") Then
					lang=attributes.Get("xml:lang")
				End If
				lang=lang.ToLowerCase
				previewSB.Append(lang).Append(": ").Append(tuv.Get("seg")).Append(CRLF)
			Next
			i=i+1
			If i=5 Then
				Exit
			End If
		Next
		Return previewSB.ToString
	Catch
		Return "Invalid file"
		Log(LastException)
	End Try
End Sub

