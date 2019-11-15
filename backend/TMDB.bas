B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private sql1 As SQL
	'Private ser As B4XSerializator
End Sub

'Initializes the store and sets the store file.
Public Sub Initialize (Dir As String, FileName As String)

	If sql1.IsInitialized Then sql1.Close
#if B4J
	sql1.InitializeSQLite(Dir, FileName, True)
#else
	sql1.Initialize(Dir, FileName, True)
#end if
	sql1.ExecNonQuery("PRAGMA journal_mode = wal")
End Sub

Public Sub PutSegments(segments As List)
	Dim tu As Map=segments.Get(0)
	Dim keys As List
	keys.Initialize
	For Each key As String In tu.Keys
		keys.Add(key)
	Next
	keys.Sort(True)
	createTable(keys)
	sql1.BeginTransaction
	For Each tu As Map In segments
		'sql1.ExecNonQuery2("INSERT OR REPLACE INTO main VALUES(?, ?)", Array (source,bytes))
		Dim values As List
		values.Initialize
		For Each key As String In keys
			Dim lang As String
			If key="note" Then
				lang="en"
			Else
				lang=key
			End If
			values.Add(getStringForIndex(tu.Get(key),lang))
		Next
		Dim ser As B4XSerializator
		Dim bytes() As Byte=ser.ConvertObjectToBytes(tu)
		values.Add(bytes)
		sql1.ExecNonQuery2("INSERT INTO idx VALUES("&getPlaceHolder(keys)&")", values)
	Next
	sql1.TransactionSuccessful
End Sub

Sub getPlaceHolder(keys As List) As String
	Dim sb As StringBuilder
	sb.Initialize
	For i=0 To keys.Size-1
		sb.Append("?")
		If i<>keys.Size-1 Then
			sb.Append(", ")
		End If
	Next
	sb.Append(", ?") ' for data
	Return sb.ToString
End Sub

Sub createTable(keys As List)
	Dim sb As StringBuilder
	sb.Initialize
	For i=0 To keys.Size-1
		sb.Append(keys.Get(i))
		If i<>keys.Size-1 Then
			sb.Append(", ")
		End If
	Next
	sb.Append(", data, notindexed=data")
	sql1.ExecNonQuery("CREATE VIRTUAL TABLE IF NOT EXISTS idx USING fts4("&sb.ToString&")")
End Sub

'Closes the store.
Public Sub Close
	sql1.Close
End Sub

Public Sub GetColumns As List
	Dim rs As ResultSet = sql1.ExecQuery2("SELECT data FROM idx WHERE rowid = 1", Null)
	Dim result As Map
	Dim ser As B4XSerializator
	result = ser.ConvertBytesToObject(rs.GetBlob2(0))
	Dim list1 As List
	list1.Initialize
	For Each key As String In result.Keys
		list1.Add(key)
	Next
	Return list1
End Sub

Public Sub GetMatchedListAsync(text As String,matchTarget As String,page As Int) As List
	'Dim maxLength As Int=text.Length*2
	Dim sqlStr As String
	Dim operator As String
	Dim words As List
	words.Initialize
	operator="AND"
	If text.StartsWith($"""$) And text.EndsWith($"""$) Then
		words.Add(text.ToLowerCase)
	Else
		words=getWordsForAll(text.ToLowerCase)
	End If
	text=getQuery(words,operator)
	
	sqlStr="SELECT data, rowid, quote(matchinfo(idx)) as rank FROM idx WHERE "&matchTarget&" MATCH '"&text&"' ORDER BY rank DESC LIMIT 15 OFFSET "&((page-1)*15)
	Log(sqlStr)
	Dim rs As ResultSet = sql1.ExecQuery2(sqlStr, Null)

	Dim resultList As List
	resultList.Initialize
	Do While rs.NextRow
		Dim result As Map
		Dim ser As B4XSerializator
		result = ser.ConvertBytesToObject(rs.GetBlob2(0))
		addHightlight(result,words,matchTarget)
		result.Put("rowid",rs.GetInt2(1))
		resultList.Add(result)
	Loop
	rs.Close
	'Log(resultList)
	Return resultList
End Sub

'Tests whether a key is available in the store.
Public Sub size As Int
	Dim rs As ResultSet = sql1.ExecQuery("SELECT count(rowid) FROM idx")
	Return rs.GetInt2(0)
End Sub
	

Sub getRange(startRowID As Int,endRowID As Int) As List
	startRowID=Max(1,startRowID)
	endRowID=Min(size,endRowID)
	Dim resultList As List
	resultList.Initialize
	For i = startRowID To endRowID
		Log(i)
		Dim rs As ResultSet = sql1.ExecQuery("SELECT data FROM idx WHERE rowid = "&i)
		Dim result As Map
		Dim ser As B4XSerializator
		result = ser.ConvertBytesToObject(rs.GetBlob2(0))
		resultList.Add(result)
	Next
	Return resultList
End Sub

Sub addHightlight(result As Map,words As List,matchTarget As String)
	If words.Size=1 Then
		Dim word As String = words.Get(0)
		If word.StartsWith($"""$) And word.EndsWith($"""$) Then
			words.Clear
			words.Add(word.SubString2(1,word.Length-1))
		End If
	End If
	For Each key As String In result.Keys
		If key=matchTarget Or matchTarget="idx" Then
			Dim text As String =result.Get(key)
			Dim sb As StringBuilder
			sb.Initialize
			Dim textSegments As List
			textSegments=splitByStrs(words,text)
			If textSegments.Size=1 Then
				Continue
			End If
			For Each textSegment As String In textSegments
				If words.IndexOf(textSegment.ToLowerCase)<>-1 Then
					sb.Append("<em>").Append(textSegment).Append("</em>")
				Else
					sb.Append(textSegment)
				End If
			Next
			result.Put(key,sb.ToString)
		End If
	Next
End Sub

Sub splitByStrs(words As List,text As String) As List
	For Each str As String In words
		Dim matcher As Matcher
		matcher=Regex.Matcher(str.ToLowerCase,text.ToLowerCase)
		Dim offset As Int=0
		Do While matcher.Find
			Dim startIndex,endIndex As Int
			startIndex=matcher.GetStart(0)+offset
			endIndex=matcher.GetEnd(0)+offset
			text=text.SubString2(0,endIndex)&"<--->"&text.SubString2(endIndex,text.Length)
			text=text.SubString2(0,startIndex)&"<--->"&text.SubString2(startIndex,text.Length)
			offset=offset+"<--->".Length*2
		Loop
	Next
	Dim result As List
	result.Initialize
	For Each str As String In Regex.Split("<--->",text)
		result.Add(str)
	Next
	Return result
End Sub

Sub getWordsForAll(text As String) As List
	Dim words As List
	words.Initialize
	words.AddAll(LanguageUtils.TokenizedList(text,"en"))
	words.AddAll(LanguageUtils.TokenizedList(text,"zh"))
	LanguageUtils.removeCharacters(words)
	LanguageUtils.removeMultiBytesWords(words)
	Return words
End Sub

Sub getQuery(words As List,operator As String) As String
	Utils.removeDuplicated(words)
	Dim sb As StringBuilder
	sb.Initialize
	For index =0 To words.Size-1
		Dim word As String=words.Get(index)
		If word.Trim<>"" Then
			sb.Append(word)
			If index<>words.Size-1 Then
				sb.Append(" "&operator&" ") ' AND OR NOT
			End If
		End If
	Next
	Return sb.ToString
End Sub

Sub getStringForIndex(source As String,lang As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim words As List=LanguageUtils.TokenizedList(source,lang)
	For index =0 To words.Size-1
		sb.Append(words.Get(index)).Append(" ")
	Next
	Return sb.ToString.Trim
End Sub