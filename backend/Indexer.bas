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
	Try
		Dim tmID As String
		tmID=req.GetParameter("tmid")
		resp.ContentType = "text/html"
		If File.Exists(File.DirApp,"db") = False Then
			File.MakeDir(File.DirApp,"db")
		End If
		If File.Exists(File.Combine(File.DirApp,"db"),tmID&".db") Then
			resp.Write("indexed")
			Return 
		End If
		Dim segments As List=TMX.importedListQuick(File.Combine(File.DirApp,"TM"),tmID&".tmx")
		Dim tm As TMDB
		tm.Initialize(File.Combine(File.DirApp,"db"),tmID&".db")
		tm.PutSegments(segments)
		resp.Write("success")
	Catch
		Log(LastException)
		resp.Write("failed")
	End Try
End Sub
