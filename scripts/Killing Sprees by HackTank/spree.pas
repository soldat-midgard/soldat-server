{
Sprees by Hacktank
 /-------------------\
 |   Version 1.0.0   |
 \-------------------/
}

const
	toplist = 10; // How many places should the toplist save
	color = $3DF6E4; // Color of the spree messages
	minspree = 5; // Minimum number before starting to show messages
	showmessages = true; // Show NAME is on a killing spree and such messages
	killspermessage = 3; // Number of kills between showing the next highest message

var
	spree: array[1..32] of integer;
	lastmsg: array[1..32] of integer;
	topnames: array[1..toplist] of string;
	topsprees: array[1..toplist] of integer;
	spreemessages: array of string;

function xsplit(const source: string; const delimiter: string):TStringArray;
var i,x,d:integer; s:string;
begin
d:=length(delimiter);x:=0;i:=1;SetArrayLength(Result,1);
while(i<=length(source)) do begin s:=Copy(source,i,d); if(s=delimiter) then begin inc(i,d); inc(x,1); SetArrayLength(result,x+1);
end else begin result[x]:= result[x]+Copy(s,1,1);inc(i,1); end; end;
end;

function XJoin(ary: array of string; splitter: string): string;
var i: integer;
begin
result := ary[0];
for i := 1 to getarraylength(ary)-1 do begin
	result := result+splitter+ary[i];
	end;
end;

function CharMultiply(char: string; times: variant): string;
var u: integer;
begin
result := '';
for u := 1 to round(times) do begin
	result := (result + char);
	end;
end;

function IntToFloat(Num: integer): single;
begin
result := strtofloat(inttostr(num));
end;

procedure TextBox(ID: byte; inputraw: array of string; headline,ychar,xchar,corner: string; color: longint);
var i,max,allignlength: byte; ii,len: integer; alligncontent,alligntype: string; input: array of string;
begin
max := length(headline);
setarraylength(input,0);
ii := 0;
for i := 0 to getarraylength(inputraw)-1 do begin
	if inputraw[i] <> '' then begin
		ii := ii+1;
		setarraylength(input,ii);
		input[ii-1] := inputraw[i];
		if length(input[ii-1]) > max then max := length(input[ii-1]);
		end;
	end;
len := getarraylength(input);
for i := 0 to len-1 do begin
	if ((getpiece(input[i],' ',0) = 'center') OR (getpiece(input[i],' ',0) = 'right') OR (getpiece(input[i],' ',0) = 'left')) then begin
		alligntype := getpiece(input[i],' ',0);
		alligncontent := getpiece(input[i],alligntype+' ',1);
		allignlength := length(alligncontent);
		if alligntype = 'center' then input[i] := charmultiply(' ',(max-allignlength) div 2)+alligncontent;
		if alligntype = 'right' then input[i] := charmultiply(' ',(max-allignlength))+alligncontent;
		if alligntype = 'left' then input[i] := alligncontent+charmultiply(' ',(max-allignlength));
		end;
	if length(input[i]) > max then max := length(input[i]);
	end;	
writeconsole(ID,corner+charmultiply(xchar,(max-length(headline)) div 2)+headline+charmultiply(xchar,(max-length(headline)+0.4) div 2)+corner,color);
for i := 0 to len-1 do if input[i] <> '' then writeconsole(ID,ychar+input[i]+charmultiply(' ',max-length(input[i]))+ychar,color);
writeconsole(ID,corner+charmultiply(xchar,max)+corner,color);
end;

procedure LoadMessages();
begin
spreemessages := xsplit(readfile('scripts/'+scriptname+'/spreemessages.txt'),chr(13)+chr(10));
end;

procedure LoadSprees();
var spreefile: array of string; i: integer;
begin
spreefile := xsplit(readfile('scripts/'+scriptname+'/toplist.txt'),chr(13)+chr(10));
for i := 1 to toplist do begin
	if i <= getarraylength(spreefile)-1 then begin
		topsprees[i] := strtoint(getpiece(spreefile[i-1],' ',0));
		topnames[i] := getpiece(spreefile[i-1],getpiece(spreefile[i-1],' ',0)+' ',1);
		end else begin
			topsprees[i] := 0;
			topnames[i] := '';
			end;
	end;
end;

procedure SaveTopList();
var i: integer; output: array[1..toplist] of string;
begin
for i := 1 to toplist do begin
	output[i] := inttostr(topsprees[i])+' '+topnames[i];
	end;
writefile('scripts/'+scriptname+'/toplist.txt',xjoin(output,chr(13)+chr(10)))
end;

procedure CheckTop(ID: byte);
var i,np: integer;
begin
np := getstringindex(getplayerstat(ID,'name'),topnames);
for i := 1 to toplist do begin
	if (np=-1) then if spree[ID] > topsprees[i] then begin
		topsprees[i] := spree[ID];
		topnames[i] := getplayerstat(ID,'name');
		break;
		end;
	end;
if np > -1 then begin
	if np > 0 then if spree[ID] > topsprees[np] then begin
		topsprees[np+1] := topsprees[np];
		topnames[np+1] := topnames[np];
		topsprees[np] := spree[ID];
		topnames[np] := getplayerstat(ID,'name');
		exit;
		end;
	if spree[ID] > topsprees[np+1] then topsprees[np+1] := spree[ID];
	end;
end;

procedure ShowTopSprees(ID: byte);
var i: integer; output: array of string;
begin
setarraylength(output,toplist+2);
output[0] := 'Top '+inttostr(toplist)+' Sprees';
output[1] := 'center ----';
for i := 1 to toplist do begin
	if topsprees[i] > 0 then output[i+1] := topnames[i]+' : '+inttostr(topsprees[i]);
	end;
textbox(ID,output,' Top Sprees ','|','_','+',color);
end;

procedure SendMess(TargetID: byte);
var num,level: integer; curstr: string;
begin
num := spree[targetid];
level := round(0.1+(inttofloat(num)-killspermessage) / inttofloat(killspermessage));
if (num >= 4) AND (level >= 1) AND (level <= getarraylength(spreemessages)-1) AND (level <> lastmsg[targetid]) then begin
	if getpiece(spreemessages[level-1],'%NAME%',1) <> '' then curstr := getpiece(spreemessages[level-1],'%NAME%',0)+getplayerstat(targetid,'name')+getpiece(spreemessages[level-1],'%NAME%',1) else curstr := spreemessages[level-1];
	writeconsole(0,curstr,color);
	end;
lastmsg[targetid] := level;
end;

procedure ActivateServer();
begin
loadmessages();
loadsprees();
end;

function OnPlayerCommand(ID: byte; text: string): boolean;
begin
if (getpiece(text,' ',0)='/sprees') OR (getpiece(text,' ',0)='/spree') then showtopsprees(ID);
end;

procedure OnPlayerSpeak(ID: Byte; Text: string);
begin
if (getpiece(text,' ',0)='!sprees') OR (getpiece(text,' ',0)='!spree') then showtopsprees(ID);
end;

procedure OnMapChange(NewMap: String);
begin
savetoplist();
end;

procedure OnPlayerKill(Killer, Victim: byte;Weapon: string);
begin
if showmessages then if spree[victim] >= minspree then writeconsole(0,getplayerstat(victim,'name')+'''s '+inttostr(spree[victim])+' kill spree was ended by '+getplayerstat(killer,'name'),$FF0000);
spree[victim] := 0;
lastmsg[victim] := 0;
if killer <> victim then begin
	inc(spree[killer],1);
	if showmessages then sendmess(killer);
	if getplayerstat(killer,'human') then checktop(killer);
	end;
end;