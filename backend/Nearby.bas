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
		sb.Append(head)
		Dim index As Int=0
		For Each tu As Map In result
			index=index+1
			sb.Append(index).Append("<br/>")
			For Each key As String In tu.Keys
				sb.Append(key).Append(": ").Append(tu.Get(key)).Append("<br/>")
			Next
			sb.Append("<br/>")
		Next
		sb.Append(tail)
		resp.Write(sb.ToString)
	Catch
		Log(LastException)
		resp.SendError(500,LastException)
	End Try
End Sub

Sub head As String
	Return $"<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh-CN" lang="zh-CN">
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />    
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>TMSearch</title></head>
  <body><p>"$
End Sub

Sub tail As String
	Return $"  </p></body>
</html>"$
End Sub