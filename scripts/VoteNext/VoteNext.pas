//VoteNext by Savage

const
	voteperc = 55;
	votetime = 45;
	negmsg = $FF0000;
	posmsg = $00FF00;
	neumsg = $FFFFFF;
	layer = 20;
	delay = 150;
	scale = 0.1;
	posx = 320;
	posy = 0;
	
var
	timer: Integer;
	HWID,HWID2: TStringList;
	
function RoundUp(X: Single): Integer;
begin
	if (X - Trunc(X) <> 0) then
		Result := Trunc(X) + 1
	else
		Result := Trunc(X);
end;

procedure Vote;
var
	i: Byte;
begin
	HWID2.Clear;
	
	for i := 1 to 32 do
		if (Players[i].Active) and (Players[i].Human) and (Players[i].Team<>5) and (HWID2.IndexOf(Players[i].HWID)=-1) then
			HWID2.Append(Players[i].HWID);
		
	if (100 * HWID.Count / HWID2.Count >= voteperc) then begin
		Map.NextMap;
		Players.BigText(layer,'Next map ('+inttostr(HWID.Count)+'/'+inttostr(RoundUp(0.01*voteperc*HWID2.Count))+')'+chr(13)+chr(10)+Game.NextMap,delay,posmsg,scale,posx,posy);
		HWID.Clear;
		timer := -1;
	end else Players.BigText(layer,'Next map ('+inttostr(HWID.Count)+'/'+inttostr(RoundUp(0.01*voteperc*HWID2.Count))+')'+chr(13)+chr(10)+Game.NextMap,delay,neumsg,scale,posx,posy);
end;

procedure OnPlayerSpeak(Player: TActivePlayer; Text: string);
begin
	if (lowercase(Text)='!v') or (lowercase(Text)='!vote') or (lowercase(Text)='!votenext') then
		if HWID.IndexOf(Player.HWID)=-1 then begin
			if Player.Team<>5 then begin
			
				HWID.Append(Player.HWID);
				
				if timer<1 then
					timer := votetime;
					
				Vote;
				
			end else Player.WriteConsole('You can''t vote on spectator',negmsg);
		end else Player.WriteConsole('You''ve already voted',negmsg);
end;

procedure OnJoinTeam(Player: TActivePlayer; Team: TTeam);
var
	i: Byte;
begin
	if timer>0 then
		if Team.ID <> 5 then
			Vote
		else begin
		
			if HWID.IndexOf(Player.HWID)<>-1 then begin
				HWID.Delete(HWID.IndexOf(Player.HWID));
				for i := 1 to 32 do
					if (Players[i].Active) and (Players[i].Team<>5) and (Players[i].HWID=Player.HWID) then begin
						HWID.Append(Player.HWID);
						break;
					end;
			end;
			
			if HWID.Count>0 then
				Vote
			else begin
				Players.BigText(layer,'Next map ('+inttostr(HWID.Count)+'/'+inttostr(RoundUp(0.01*voteperc*HWID2.Count))+')'+chr(13)+chr(10)+Game.NextMap,delay,negmsg,scale,posx,posy);
				timer := -1;
			end;
			
		end;
end;

procedure OnLeaveGame(Player: TActivePlayer; Kicked: Boolean);
var
	i: Byte;
begin
	if timer>0 then begin
	
		if HWID.IndexOf(Player.HWID)<>-1 then begin
			HWID.Delete(HWID.IndexOf(Player.HWID));
			for i := 1 to 32 do
				if (Players[i].Active) and (i<>Player.ID) and (Players[i].Team<>5) and (Players[i].HWID=Player.HWID) then begin
					HWID.Append(Player.HWID);
					break;
				end;
		end;
		
		if HWID.Count>0 then begin
			
			HWID2.Clear;
			
			for i := 1 to 32 do
				if (Players[i].Active) and (Players[i].Human) and (i<>Player.ID) and (Players[i].Team<>5) and (HWID2.IndexOf(Players[i].HWID)=-1) then
					HWID2.Append(Players[i].HWID);
			
			if (100 * HWID.Count / HWID2.Count >= voteperc) then begin
				Map.NextMap;
				Players.BigText(layer,'Next map ('+inttostr(HWID.Count)+'/'+inttostr(RoundUp(0.01*voteperc*HWID2.Count))+')'+chr(13)+chr(10)+Game.NextMap,delay,posmsg,scale,posx,posy);
				HWID.Clear;
				timer := -1;
			end else Players.BigText(layer,'Next map ('+inttostr(HWID.Count)+'/'+inttostr(RoundUp(0.01*voteperc*HWID2.Count))+')'+chr(13)+chr(10)+Game.NextMap,delay,neumsg,scale,posx,posy);
			
		end else
		begin
			Players.BigText(layer,'Next map ('+inttostr(HWID.Count)+'/'+inttostr(RoundUp(0.01*voteperc*HWID2.Count))+')'+chr(13)+chr(10)+Game.NextMap,delay,negmsg,scale,posx,posy);
			timer := -1;
		end;
		
	end;
end;

procedure Clock(Ticks: Integer);
begin
	if timer>-1 then begin
		
		Dec(timer, 1);
		
		if timer>0 then
			Players.BigText(layer,'Next map ('+inttostr(HWID.Count)+'/'+inttostr(RoundUp(0.01*voteperc*HWID2.Count))+')'+chr(13)+chr(10)+Game.NextMap,delay,neumsg,scale,posx,posy);
			
		if timer=0 then begin
			Players.BigText(layer,'Next map ('+inttostr(HWID.Count)+'/'+inttostr(RoundUp(0.01*voteperc*HWID2.Count))+')'+chr(13)+chr(10)+Game.NextMap,delay,negmsg,scale,posx,posy);
			HWID.Clear;
		end;
		
	end;
end;

procedure Init;
var
	i: Byte;
begin
	HWID := File.CreateStringList;
	HWID2 := File.CreateStringList;
	
	for i := 1 to 32 do
		Players[i].OnSpeak := @OnPlayerSpeak;
		
	for i := 0 to 5 do
		Game.Teams[i].OnJoin := @OnJoinTeam;
		
	Game.OnLeave := @OnLeaveGame;
	Game.OnClockTick := @Clock;
end;

begin
	Init;
end.