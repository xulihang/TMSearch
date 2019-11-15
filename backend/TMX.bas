﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.51
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private parser As SaxParser
	Private tuvs As List
	Private tus As List
	Private aSourceLang,aTargetLang As String
	Private numbers As Int
End Sub

Sub parse(dir As String,filename As String)
	tus.Initialize
	tuvs.Initialize
	parser.Initialize
	Dim in As InputStream
	in = File.OpenInput(dir, filename) 'This file was added with the file manager.
	parser.Parse(in, "Parser") '"Parser" is the events subs prefix.
	in.Close
	'Log("tus:"&tus)
End Sub

Sub Parser_StartElement (Uri As String, Name As String, Attributes As Attributes)
    If Name="tuv" Or Name="tu" Then
		Dim map1 As Map
		map1.Initialize
		Dim attr As Map
		attr.Initialize
		For i=0 To Attributes.Size-1
			attr.Put(Attributes.GetName(i),Attributes.GetValue(i))
		Next
		map1.Put("Attributes",attr)
		Select Name 
			Case "tuv"
				tuvs.Add(map1)
			Case "tu"
				tus.Add(map1)
		End Select
		
	End If
End Sub

Sub Parser_EndElement (Uri As String, Name As String, Text As StringBuilder)
	If Name="seg" Then
		numbers=numbers+1
		Dim map1 As Map = tuvs.Get(tuvs.Size-1)
		Dim Attributes As Map =map1.Get("Attributes")
		'Log(Attributes.GetValue2("","xml:lang"))
		Dim lang As String
		If Attributes.ContainsKey("xml:lang") Then
			lang=Attributes.Get("xml:lang")
		else if Attributes.ContainsKey("lang") Then
			lang=Attributes.Get("lang")
		End If
		'Log("lang: "&lang)
		If lang.StartsWith(aSourceLang) Or lang.StartsWith(aTargetLang) Then
			map1.Put("Text",Text.ToString)
		Else
			tuvs.RemoveAt(tuvs.Size-1)
		End If
		'Log(map1)
		'Log(numbers)
	else if Name="note" Then
		Dim map1 As Map = tus.Get(tus.Size-1)
		map1.Put("note",Text.ToString)
	Else if Name = "tu" Then
		Dim newList As List
		newList.Initialize
		newList.AddAll(tuvs)
		Dim map1 As Map = tus.Get(tus.Size-1)
		map1.Put("tuv",newList)
		tuvs.Clear
	End If
End Sub


Sub importedListQuick(dir As String,filename As String) As List
	Dim segments As List
	segments.Initialize
	parse(dir,filename)
	For Each tu As Map In tus
		Dim tuvList As List= tu.Get("tuv")
		Dim newtu As Map
		newtu.Initialize
		For Each tuv As Map In tuvList
			Dim Attributes As Map =tuv.Get("Attributes")
			'Log(Attributes.GetValue2("","xml:lang"))
			Dim lang As String
			If Attributes.ContainsKey("xml:lang") Then
				lang=Attributes.Get("xml:lang")
			else if Attributes.ContainsKey("lang") Then
				lang=Attributes.Get("lang")
			End If
			newtu.Put(lang,tuv.Get("Text"))
		Next

		If tu.ContainsKey("note") Then
			newtu.Put("note",tu.Get("note"))
		End If
		segments.Add(newtu)
	Next
	Return segments
End Sub
