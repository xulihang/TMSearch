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
		Dim tmID,page,keyword,target As String
		tmID=req.GetParameter("tmid")
		page=req.GetParameter("page")
		keyword=req.GetParameter("keyword")
		target=req.GetParameter("target")
		resp.ContentType = "application/json"
		resp.CharacterEncoding="UTF-8"
		Dim tm As TMDB
		If File.Exists(File.Combine(File.DirApp,"db"),tmID&".db")=False Then
			resp.SendError("404","not exist")
			Return
		End If
		tm.Initialize(File.Combine(File.DirApp,"db"),tmID&".db")
		Dim result As List=tm.GetMatchedListAsync(keyword,target,page)
		Dim json As JSONGenerator
		json.Initialize2(result)
		'Log(json.ToString)
		resp.Write(json.ToString)
	Catch
		Log(LastException)
		resp.SendError(500,LastException)
	End Try
End Sub