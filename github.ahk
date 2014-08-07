git:=new github("maestrith") ;creates the git object with the Owner name "maestrith"
;update this script
FileRead,text,%A_ScriptName%
git.update("AHK_Github",A_ScriptFullPath,text,"Working on the class")
;/update this script
/*
	;original creation of the repo
	git.CreateRepo("AHK_Github")
	git.CreateFile("AHK_Github",A_ScriptFullPath,text,"First Commit","Chad Wilson","maestrith@gmail.com")
*/
/*
	git.CreateRepo("Testing") ;creates a new repo with the name "Testing". There are other options that can be set.
	git.List("Testing") ;gets a list of commits from the Testing repo and saves it to commits.txt mostly for debugging and will probably be removed
	;-----Create a new file------
	Owner:=Repo:="Testing"
	filename:="Last Test.ahk",File_Contents:="This will be uploaded"
	Commit_Message:="This is the commit message"
	Name:="Chad Wilson",Email:="maestrith@gmail.com"
	git.CreateFile(Repo,Filename,File_Contents,Commit_Message,Name,Email)
	;/-----Create a new file------
	;/-----Update file-----
	;same info as above but change File_Contents
	commit:="Updated commit information"
	branch:="master" ;this value can be left blank for "master"
	git.update(owner,repo,filename,File_Contents,commit,branch)
	;/-----Update file-----
	git.update()
*/
class github{
	static url:="https://api.github.com",http:=[]
	__New(owner){
		FileRead,token,token.txt
		if !(token){
			m("A token is required.","Create a file called token.txt and place your token in it.")
			ExitApp
		}
		this.http:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
		this.token:="?access_token=" token
		this.owner:=owner
		return this
	}
	CreateRepo(name,description="Created with AHK Studio",homepage="",private="false",issues="false",wiki="true",downloads="true"){
		url:=this.url "/user/repos" this.token
		this.http.Open("POST",url)
		json=
		(
		{"name":"%name%","description":"%description%","homepage":"http://www.maestrith.com","private":%private%,"has_issues":%issues%,"has_wiki":%wiki%,"has_downloads":%downloads%}
		)
		this.http.Send(json)
		FileDelete,create.txt
		FileAppend,% this.http.ResponseText,create.txt
	}
	CreateFile(repo,filefullpath,text,commit="First Commit",realname="",email=""){
		SplitPath,filefullpath,filename
		url:=this.url "/repos/" this.owner "/" repo "/contents/" filename this.token,file:=this.encode(text)
		json=
		(
		{"message":"%commit%","committer":{"name":"%realname%","email":"%email%"},"content": "%file%"}
		)
		this.http.Open("PUT",url)
		this.http.send(json)
		RegExMatch(this.http.ResponseText,"U)"Chr(34) "sha" Chr(34) ":(.*),",found)
		sha:=Trim(found1,Chr(34))
		if sha
			IniWrite,%sha%,files.ini,%filefullpath%,sha
	}
	Update(repo,filefullpath,text,commit="Updated",branch="master"){
		SplitPath,filefullpath,filename
		IniRead,sha,files.ini,%filefullpath%,sha,0
		if !sha
			return m("File does not exist.  Please create the file first")
		url:=this.url "/repos/" this.owner "/" repo "/contents/" filename this.token
		text:=this.encode(text)
		json=
		(
		{"message":"%commit%","content":"%text%","sha":"%sha%","branch":"%branch%"}
		)
		this.http.Open("PUT",url)
		this.http.Send(json)
		RegExMatch(this.http.ResponseText,"U)"Chr(34) "sha" Chr(34) ":(.*),",found)
		if sha:=Trim(found1,Chr(34))
			IniWrite,%sha%,files.ini,%filename%,sha
		Else
			m("an error occured")
	}
	Encode(text){ ;original http://www.autohotkey.com/forum/viewtopic.php?p=238120#238120
		if text=""
			return
		cp:=0
		VarSetCapacity(rawdata,StrPut(text,"utf-8")),sz:=StrPut(text,&rawdata,"utf-8")-1
		DllCall("Crypt32.dll\CryptBinaryToString","ptr",&rawdata,"uint",sz,"uint",0x40000001,"ptr",0,"uint*",cp)
		VarSetCapacity(str,cp*(A_IsUnicode?2:1))
		DllCall("Crypt32.dll\CryptBinaryToString","ptr",&rawdata,"uint",sz,"uint",0x40000001,"str",str,"uint*",cp)
		return str
	}
	List(repo,sha=""){
		url:=this.url "/repos/" this.owner "/" repo "/commits"
		add:=sha?"/" sha this.token:this.token
		url.=add
		this.http.Open("GET",url)
		this.http.Send()
		FileDelete,commits.txt
		FileAppend,% this.http.ResponseText,commits.txt
		Run,commits.txt
	}
}
m(x*){
	for a,b in x
		list.=b "`n"
	msgbox %list%
}