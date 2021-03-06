#SingleInstance,force
controls:={owner:"Owner (GitHub Username)",email:"Email",name:"Your Full Name"}
Gui,Add,Text,,Usage: Fill out the required information`nand then drag files (text based files only) into the window.`n
for a,b in ["owner","email","name"]{
	IniRead,value,Settings.ini,GitHub,%b%,0
	value:=value?value:""
	Gui,Add,Text,xm,% controls[b]
	Gui,Add,Edit,x+5 w250 v%b% gupdate,%value%
}
Gui,Add,Text,xm,Github Token
IniRead,token,Settings.ini,GitHub,token,0
token:=token?token:""
Gui,Add,Edit,xm w350 Password vtoken gupdate,%token%
Gui,Add,Text,xm,Repo To Update
IniRead,repo,Settings.ini,GitHub,repo,0
repo:=repo?repo:""
Gui,Add,Edit,x+5 w250 vrepo gupdate,%repo%
Gui,Add,Button,xm ggettoken,Get A Token
Gui,Show,,Github Information
return
gettoken:
Run,https://github.com/settings/applications
return
update:
Gui,Submit,Nohide
for a,b in ["owner","email","name","token","repo"]
	IniWrite,% %b%,Settings.ini,GitHub,%b%
return
GuiEscape:
GuiClose:
ExitApp
return
GuiDropFiles:
Gui,Submit,Nohide
git:=new github(owner,token)
InputBox,commitmsg,New Commit Message,Please enter a commit message for this commit
current_commit:=git.getref(repo)
if !(current_commit){
	git.CreateRepo(repo)
	git.CreateFile(repo,"README.md",";Readme.md","First Commit",name,email)
	Sleep,500
	current_commit:=git.getref(repo)
}
files:=[]
for a,b in StrSplit(A_GuiEvent,"`n"){
	SplitPath,b,filename
	if (filename="Settings.ini")
		continue
	FileRead,text,%b%
	blob:=git.blob(repo,text)
	files[filename]:=blob
}
tree:=git.Tree(repo,current_commit,files)
commit:=git.commit(repo,tree,current_commit,commitmsg)
git.ref(repo,commit) ;new commit value
return
class github{
	static url:="https://api.github.com",http:=[]
	__New(owner,token){
		this.http:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
		this.token:="?access_token=" token
		this.owner:=owner
		return this
	}
	sha(text){
		RegExMatch(this.http.ResponseText,"U)"Chr(34) "sha" Chr(34) ":(.*),",found)
		return Trim(found1,Chr(34))
	}
	getref(repo){
		;GET /repos/:owner/:repo/git/refs
		url:=this.url "/repos/" this.owner "/" repo "/git/refs" this.token
		return this.sha(this.Send("GET",url))
	}
	blob(repo,text){
		;POST /repos/:owner/:repo/git/blobs
		url:=this.url "/repos/" this.owner "/" repo "/git/blobs" this.token
		text:=utf8(text)
		json=
		(
		{"content":"%text%","encoding":"utf-8"}
		)
		return this.sha(this.Send("POST",url,json))
	}
	send(verb,url,data=""){
		this.http.Open(verb,url)
		this.http.send(data)
		return this.http.ResponseText
	}
	tree(repo,parent,blobs){
		;POST /repos/:owner/:repo/git/trees
		url:=this.url "/repos/" this.owner "/" repo "/git/trees" this.token
		json=
		(
		{"base_tree":"%parent%","tree":[
		)
		for a,blob in blobs{
			add={"path":"%a%","mode":"100644","type":"blob","sha":"%blob%"},
			json.=add
		}
		json:=Trim(json,",") "]}"
		return this.sha(this.Send("POST",url,json))
	}
	commit(repo,tree,parent,message="Updated the file"){
		url:=this.url "/repos/" this.owner "/" repo "/git/commits" this.token
		json=
		(
		{"message":"%message%","author":{"name": "Chad Wilson","email": "maestrith@gmail.com"},"parents":["%parent%"],"tree":"%tree%"}
		)
		return this.sha(this.Send("POST",url,json))
	}
	ref(repo,sha){
		url:=this.url "/repos/" this.owner "/" repo "/git/refs/heads/master" this.token
		this.http.Open("PATCH",url)
		json=
		(
		{"sha":"%sha%","force":true}
		)
		this.http.send(json)
		m("New Commit Created",this.http.ResponseText)
	}
	Limit(){
		url:=this.url "/rate_limit" this.token
		this.http.Open("GET",url)
		this.http.Send()
		m(this.http.ResponseText)
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
}
m(x*){
	for a,b in x
		list.=b "`n"
	msgbox %list%
}
utf8(info){
	info:=RegExReplace(info,"([" Chr(34) "\\])","\$1")
	for a,b in {"`n":"\n","`t":"\t","`r":""}
		StringReplace,info,info,%a%,%b%,All
	return info
}