type
	Pinger = record
			 Sum:	integer;
			 Count:	integer;
			 Max:	integer;
end;

var
	i, j, FoundID: integer;
	Maps, CMD: TstringArray;
	Go, TrackOrNot, online: boolean;
	VFor,Time: byte;
	Voted, playerShown, playerAdmin: array[1..32] of boolean;
	Player: array[1..32] of Pinger;
	//INI:
	GOOD, BAD: longint;
	Procent, InitTime, AddTime, AverageServerPingTime: integer;
	BotsVote, cmdTXT, MapslistTXT, AntyUnabalnce, NextmapON, ChangeTeamON, WhoisadminON, TrackON, RatioON, MapsON, MapON, TimeON, PingON, NextmapisON, AverageServerPing: string;

function Explode(Source: string; const Delimiter: string): array of string;
var
  Position, DelLength, ResLength: integer;
begin
	DelLength := Length(Delimiter);
	Source := Source + Delimiter;
	repeat
		Position := Pos(Delimiter, Source);
		SetArrayLength(Result, ResLength + 1);
		Result[ResLength] := Copy(Source, 1, Position - 1);
		ResLength := ResLength + 1;
		Delete(Source, 1, Position + DelLength - 1);
	until (Position = 0);
	SetArrayLength(Result, ResLength - 1);
end;

function LoadSettings(File: string): boolean;
begin
	try
		GOOD			:= StrtoInt(ReadINI(File,'Color','ColorGOOD','$00BFFF'));
		BAD				:= StrtoInt(ReadINI(File,'Color','ColorBAD','$ff0033'));
		Procent			:= StrtoInt(ReadINI(File,'Vote','VotePrecent','75'));
		InitTime		:= StrtoInt(ReadINI(File,'Vote','VoteTime','30'));
		AddTime			:= StrtoInt(ReadINI(File,'Vote','VoteTimeAdd','7'));
		BotsVote    	:= ReadINI(File,'Vote','BotsVote','false');
		MapslistTXT		:= ReadINI(File,'Paths','MapList','/mapslist.txt');
		cmdTXT     		:= ReadINI(File,'Paths','CommandsList','/scripts/Basic/commands.txt');
		AntyUnabalnce	:= ReadINI(File,'Other','AntyUnabalnce','ON');
		NextmapON		:= ReadINI(File,'Other','Nextmap','ON');
		ChangeTeamON	:= ReadINI(File,'Other','ChangeTeam','ON');
		WhoisadminON	:= ReadINI(File,'Other','Whoisadmin','ON');
		TrackON			:= ReadINI(File,'Other','Track','ON');
		RatioON			:= ReadINI(File,'Other','Ratio','ON');
		MapsON			:= ReadINI(File,'Other','Maps','ON');
		MapON			:= ReadINI(File,'Other','Map','ON');
		TimeON			:= ReadINI(File,'Other','Time','ON');
		PingON			:= ReadINI(File,'Other','Ping','ON');
		NextmapisON		:= ReadINI(File,'Other','Nextmapis','ON');
		AverageServerPing := ReadINI(File,'Other','AverageServerPing','ON');
		AverageServerPingTime := StrtoInt(ReadINI(File,'Other','AverageServerPingTime','2'));
	except
		Result := true;
	exit;
	end;
end;

procedure Ratio(ID: Integer);
var
	KD: Double;
begin
	if(GetPlayerStat(ID,'team')=5) then WriteConsole(0,GetPlayerStat(ID,'name')+', you are spectating',GOOD) else if(GetPlayerStat(ID,'deaths')=0) then WriteConsole(0,GetPlayerStat(ID,'name')+', your K:D is incalculable ('+intToStr(GetPlayerStat(ID,'kills'))+'/0) with '+inttostr(GetPlayerStat(id, 'flags'))+' caps.',GOOD) else begin
		KD := single(GetPlayerStat(ID,'kills'))/single(GetPlayerStat(ID,'deaths'));
		WriteConsole(0,GetPlayerStat(ID,'name')+', your K:D is '+FormatFloat('0.00',KD)+' ('+intToStr(GetPlayerStat(ID,'kills'))+'/'+IntToStr(GetPlayerStat(ID,'Deaths'))+') with '+IntToStr(GetPlayerStat(id, 'flags'))+' caps.',GOOD);
	end;
end;

Procedure AveragePing();
var
    totalping, i, Aping: integer;
begin
    if Numplayers > 0 then begin
		for i := 1 to 32 do begin
			totalping := totalping + GetPlayerStat(i,'Ping');
			Aping := totalping / NumPlayers;
			WriteConsole(i, 'Recent Average server ping is: '+inttostr(Aping)+'ms.', GOOD);
		end;
	end;
end;

Procedure UpdateMapslist(ID: byte);
var
	index : integer;
begin
	Maps := Explode(readfile(MapslistTXT), #13#10);
	index := (GetArrayLength(Maps)-1)
	for i:=0 to index do begin
		if (Maps[index-i] = '') then SetArrayLength(maps, index-i);
	end;
	if (ID <255) then WriteConsole(ID, 'Mapslist Updated', GOOD) else WriteLn('Mapslist Updated');
end;

Procedure UpdateCMD(ID: byte);
var
	index : integer;
begin
	CMD := Explode(readfile(cmdTXT), #13#10);
	index := (GetArrayLength(CMD)-1);
	for i:=0 to index do begin
		if (CMD[index-i] = '') then SetArrayLength(cmd, index-i);
	end;
	if (ID <255) then WriteConsole(ID, 'CMD list Updated', GOOD) else WriteLn('CMD list Updated');
end;

function StrToID(s: string): byte;
var i: byte;
begin
	Result := 254;
	try 
		if GetPlayerStat(StrToInt(s), 'active') then Result := StrToInt(s);
	except
		s := LowerCase(s);
		for i := 1 to 32 do if GetPlayerStat(i, 'active') then if ContainsString(LowerCase(IDToName(i)), s) then begin
			Result := i;
			break;
		end;
	end;
end;

Procedure CmdTrack(ID:byte; Text:string); 
begin
	FoundID := StrToID(Text);
	if FoundID = 254 then WriteConsole(ID,'Player not found ('+Text+')',BAD) else begin
		if Player[FoundID].Count > 0 then WriteConsole(ID,'Already tracking.',GOOD) else begin
			TrackOrNot := TRUE;
			Player[FoundID].Count := 5;
			WriteConsole(ID,'Tracking '+IdToName(FoundID)+' ...',GOOD);
			Player[FoundID].Max := GetPlayerStat(FoundID,'Ping');
			Player[FoundID].Sum := Player[FoundID].Max;
		end;
	end;
end;

procedure adminlist;
var
	AL: TStringArray;
	i, j: byte;
begin
	if FileExists('remote.txt') then begin
		SetArrayLength(AL, 1);
		AL := Explode(ReadFile('remote.txt'), chr(13) + chr(10));
		WriteConsole(0, 'Admins on the server:', GOOD);
		for i := 0 to ArrayHigh(AL) do for j := 1 to 32 do if (GetPlayerStat(j, 'Active') = true) and (GetPlayerStat(j, 'Human') = true) then if (GetPlayerStat(j, 'IP') = AL[i]) and (playerShown[j] = false) then begin
			WriteConsole(0, IDToName(IPToID(AL[i])), GOOD);
			online := true;
			playerShown[j] := true;
		end else if (playerAdmin[j] = true) and (playerShown[j] = false) then begin
			WriteConsole(0, IDToName(j), GOOD);
			online := true;
			playerShown[j] := true;
        end else if (i = ArrayHigh(AL)) and (online = false) then WriteConsole(0, 'There''s no admin here!', GOOD);
		online := false;
		for i := 1 to 32 do playerShown[i] := false;
	end else WriteConsole(0, 'File not found!', BAD);
end;

procedure ActivateServer();
var
	i: byte;
begin
	if LoadSettings('scripts/'+ ScriptName + '/settings.ini') then WriteLn(' [*] '+ ScriptName + ' -> Error while loading settings') else WriteLn(' [*] '+ ScriptName + ' -> Settings loaded successfully');
	WriteConsole(0, 'Basic v1.0.3 recompiled - successfully :)', $FFFFAA00);
	UpdateMapslist(255);
	UpdateCMD(255);
	for i := 1 to 32 do begin
		playerAdmin[i] := false;
		playerShown[i] := false;
	end;
	online := false;
end;

procedure AppOnIdle(Ticks: integer);
var
	i: byte;
begin
	if (LowerCase(AverageServerPing) = LowerCase('ON')) then if Ticks mod (3600 * AverageServerPingTime) = 0 then AveragePing();
	if Time > 0 then Time := Time - 1 else if Go then begin
		Go := false;
		for i := 1 to 32 do Voted[i] := false;
		VFor := 0;
		Time := 0;
		WriteConsole(0,'Map vote failed.',GOOD);
	end;
	if TrackOrNot then for i:=1 to 32 do if Player[i].Count > 0 then begin
		Player[i].Count := Player[i].Count - 1;
		Player[i].Sum := Player[i].Sum + GetPlayerStat(i,'ping');
		if GetPlayerStat(i,'ping') > Player[i].Max then Player[i].Max := GetPlayerStat(i,'ping');
		if Player[i].Count = 0 then begin
			WriteConsole(0,'Tracking result for '+IdToName(i)+': Average Ping: '+inttostr(Round(Player[i].Sum/6))+', Max Ping: '+inttostr(Player[i].Max),GOOD);
			for j:=1 to 32 do
			if Player[j].Count>0 then break else if i=32 then TrackOrNot := FALSE;
		end;
	end;
end;

procedure OnMapChange(NewMap: String);
var
	i: byte;
begin
	Go := false;
	for i := 1 to 32 do Voted[i] := false;
	VFor := 0;
	Time := 0;
end;

function OnPlayerCommand(ID: Byte; Text: string): boolean;
begin // saves successfully adminlogged players to variable
	if Text = '/adminlog ' + ReadINI('soldat.ini', 'NETWORK', 'Admin_Password', 'FAIL') then playerAdmin[ID] := true;
	Result := false;
end;

procedure OnPlayerSpeak(ID: byte; Text: string);
var
	i: byte;
	KD: double;
begin
	if (lowercase(NextmapisON) = lowercase('ON')) then if regExpMatch('^?(nextmap|nastepna|nastepnamapa)$',lowercase(Text)) then WriteConsole(0,'Next map is: '+NextMap, GOOD);
	if (lowercase(PingON) = lowercase('ON')) then if regExpMatch('^!(ping)$',lowercase(Text)) then WriteConsole(0,GetPlayerStat(ID,'Name')+'''s ping: '+IntToStr(GetPlayerStat(ID,'Ping')), GOOD);
	if (lowercase(TimeON) = lowercase('ON')) then if regExpMatch('^!(time|czas)$',lowercase(Text)) then WriteConsole(0,'Time on the server - '+FormatDate('hh:nn:ss'), GOOD);
	if (lowercase(MapON) = lowercase('ON')) then if regExpMatch('^!(map|mapa)$',lowercase(Text)) then WriteConsole(0,'Map: '+CurrentMap,GOOD);
	if (lowercase(MapsON) = lowercase('ON')) then if regExpMatch('^!(maps|mapy)$',lowercase(Text)) then for i:=0 to (GetArrayLength(Maps)-1) do WriteConsole(ID,''+Maps[i]+'                                                           ', GOOD);
	if regExpMatch('^!(cmd|cmds|command|commands)$',lowercase(Text)) then for i:=0 to (GetArrayLength(CMD)-1) do WriteConsole(ID,''+CMD[i]+'                                ', GOOD);
	if (lowercase(RatioON) = lowercase('ON')) then if regExpMatch('^!(ratio|rate|kd|kdratio|kdrate)$',lowercase(Text)) then Ratio(ID);
	if (lowercase(TrackON) = lowercase('ON')) then if regExpMatch('^!(track)$',lowercase(Text)) then CmdTrack(ID,inttostr(ID)) else if MaskCheck(Text,'!track *') then CmdTrack(ID,Copy(Text,8,Length(Text)));
	if (lowercase(WhoisadminON) = lowercase('ON')) then if regExpMatch('^!(whoisadmin|adminlist|adminsonline|onlineadmins|onlineadmin|adminonline|ktojestadmin)$',lowercase(Text)) then adminlist;
	if (lowercase(ChangeTeamON) = lowercase('ON')) then if regExpMatch('^!(s|specator|specators|5|joins|join s)$',lowercase(Text)) then Command('/setteam5 '+inttostr(ID));
	if (lowercase(ChangeTeamON) = lowercase('ON')) then if regExpMatch('^!(a|alpha|red|1|joina|join a)$',lowercase(Text)) then begin
		if (GameStyle = 2) or (GameStyle = 3) or (GameStyle = 5) or (GameStyle = 6) then begin
			if not (GetPlayerStat(ID, 'Team') = 1) then begin
				if (lowercase(AntyUnabalnce) = lowercase('ON')) then begin
					if (AlphaPlayers <= BravoPlayers) then begin
						Command('/setteam1 '+inttostr(ID));
					end else WriteConsole(ID,'You can now join the Alpha Team - AntyUnbalancing On!',BAD);
				end else
				begin
					Command('/setteam1 '+inttostr(ID));
				end;
			end else WriteConsole(ID,'You are already in the team alpha!',BAD);
		end;
	end;
	if (lowercase(ChangeTeamON) = lowercase('ON')) then if regExpMatch('^!(b|bravo|blue|2|joinb|join b)$',lowercase(Text)) then begin
		if (GameStyle = 2) or (GameStyle = 3) or (GameStyle = 5) or (GameStyle = 6) then begin
			if not (GetPlayerStat(ID, 'Team') = 2) then begin
				if (lowercase(AntyUnabalnce) = lowercase('ON')) then begin
					if (BravoPlayers <= AlphaPlayers) then begin
						Command('/setteam2 '+inttostr(ID));
					end else WriteConsole(ID,'You can now join the Bravo Team - AntyUnbalancing On!',BAD);
				end else
				begin
					Command('/setteam2 '+inttostr(ID));
				end;
			end else WriteConsole(ID,'You are already in the team bravo!',BAD);
		end;
	end;
	if (lowercase(NextmapON) = lowercase('ON')) then if RegExpMatch('^!(nextmap|mapvote|nextmapvote|mapnext)$',lowercase(Text)) then if Voted[ID] = false then begin
		if Go = false then Time := InitTime else Time := Time + AddTime;
		Go := true;
		Voted[ID] := true;
		VFor := VFor + 1;
		if (lowercase(BotsVote) = lowercase('true')) then begin
			if VFor / NumPlayers * 100 >= Procent then begin
				Go := false;
				for i := 1 to 32 do Voted[i] := false;
				VFor := 0;
				Time := 0;
				WriteConsole(0,'Map vote passed.',GOOD);
				Command('/nextmap');
			end else
			begin
				KD := single(100 * VFor) / single(NumPlayers);
				WriteConsole(0,'Voting percentage of needed people: '+FormatFloat('0',KD)+'% / ' + InttoStr(Procent) + '%.',GOOD);
			end;
		end else
		begin
			if (lowercase(BotsVote) = lowercase('false')) then begin
				if VFor / (NumPlayers-NumBots) * 100 >= Procent then begin
					Go := false;
					for i := 1 to 32 do Voted[i] := false;
					VFor := 0;
					Time := 0;
					WriteConsole(0,'Map vote passed.',GOOD);
					Command('/nextmap');
				end else
				begin
					KD := single(100 * VFor) / single(NumPlayers-NumBots);
					WriteConsole(0,'Voting percentage of needed people: '+FormatFloat('0',KD)+'% / ' + InttoStr(Procent) + '%.',GOOD);
				end;
			end;
		end;
	end else WriteConsole(ID,'You have already voted.',BAD);
end;

function OnCommand(ID: Byte; Text: string): boolean;
begin
	if (Text = '/reloadsettings') then begin
		if LoadSettings('scripts/'+ ScriptName + '/settings.ini') then WriteLn(' [*] '+ ScriptName + ' -> Error while loading settings') else WriteLn(' [*] '+ ScriptName + ' -> Settings loaded successfully');
		WriteConsole(ID,'Settings loaded successfully!',GOOD);
	end;
	Result := false;
end;

procedure OnLeaveGame(ID, Team: byte; Kicked: boolean);
var
	i: byte;
begin
	if Voted[ID] then begin
		Voted[ID] := false;
		VFor := VFor - 1;
	end else 
	begin
		if NumPlayers > 1 then if VFor / (NumPlayers - 1) * 100 >= Procent then begin
			Go := false;
			for i := 1 to 32 do Voted[i] := false;
			VFor := 0;
			Time := 0;
			WriteConsole(0,'Map vote passed.',GOOD);
			Command('/nextmap');
		end;
	end;
	if playerAdmin[ID] = true then playerAdmin[ID] := false;
end;