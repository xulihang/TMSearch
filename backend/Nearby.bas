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
		Dim tmID,rowid As String
		tmID=req.GetParameter("tmid")
		rowid=req.GetParameter("rowid")
		resp.ContentType = "text/html"
		resp.CharacterEncoding="UTF-8"
		Dim tm As TMDB
		If File.Exists(File.Combine(File.DirApp,"db"),tmID&".db")=False Then
			resp.SendError("404","not exist")
			Return
		End If
		tm.Initialize(File.Combine(File.DirApp,"db"),tmID&".db")
		Dim result As List=tm.getRange(rowid-7,rowid+7)
		Dim sb As StringBuilder
		sb.Initialize
		Dim index As Int=0
		For Each tu As Map In result
			index=index+1
			sb.Append(index).Append("<br/>")
			For Each key As String In tu.Keys
				sb.Append(key).Append(": ").Append(tu.Get(key)).Append("<br/>")
			Next
			sb.Append("<br/>")
		Next
		resp.Write(sb.ToString)
	Catch
		Log(LastException)
		resp.SendError(500,LastException)
	End Try
End Sub