//WhoIs 2.1 by Savage //Core Version: 2.8.1 (SC3)

const
	MSG_COLOR = $6495ed; //Color to display connected admins
	COUNT_TIME = 5; //Time needed to count connected admins
	
var
	Timer: Byte;
	AdminsList: TStringList;
	COUNT_TCP_ADMINS, COUNT_INGAME_ADMINS: Boolean;
	
procedure OnPlayerSpeak(Player: TActivePlayer; Text: String);
begin
	if Text = '!whois' then
		if Timer = 0 then begin
			Players.WriteConsole('WhoIs: Counting connected admins...', MSG_COLOR);
			Timer := COUNT_TIME;
			if COUNT_TCP_ADMINS then
				WriteLn('/clientlist (127.0.0.1)');
		end else
			Players.WriteConsole('WhoIs: Already counting - please wait...', MSG_COLOR);
end;

procedure OnTCPMessage(Ip: string; Port: Word; Text: string);
begin
	if (COUNT_TCP_ADMINS) and (Timer > 0) and (Copy(Text, 1, 1) = '[') and (Copy(Text, 3, 1) = ']') then
		AdminsList.Append(Text);
end;

procedure Clock(Ticks: Integer);
var
	i: Byte;
begin
	if Timer > 0 then begin
		Dec(Timer, 1);
		if Timer = 0 then begin
			
			if COUNT_TCP_ADMINS then
				if AdminsList.Count = 0 then
					Players.WriteConsole('WhoIs: There''s no TCP admin connected', MSG_COLOR)
				else begin
					if AdminsList.Count = 1 then
						Players.WriteConsole('WhoIs: There''s 1 TCP admin connected:', MSG_COLOR)
					else
						Players.WriteConsole('WhoIs: There''re '+IntToStr(AdminsList.Count)+' TCP admins connected:', MSG_COLOR);
						
					for i := 0 to AdminsList.Count-1 do
						Players.WriteConsole(AdminsList[i], MSG_COLOR);
					
					AdminsList.Clear;
				end;
			
			if COUNT_INGAME_ADMINS then begin
				for i := 1 to 32 do
					if players[i].IsAdmin then
						AdminsList.Append(players[i].Name);
							
				if AdminsList.Count = 0 then
					Players.WriteConsole('WhoIs: There''s no In-Game admin connected', MSG_COLOR)
				else begin
					if AdminsList.Count = 1 then
						Players.WriteConsole('WhoIs: There''s 1 In-Game admin connected:', MSG_COLOR)
					else
						Players.WriteConsole('WhoIs: There''re '+IntToStr(AdminsList.Count)+' In-Game admins connected:', MSG_COLOR);
						
					for i := 0 to AdminsList.Count-1 do
						Players.WriteConsole(AdminsList[i], MSG_COLOR);
					
					AdminsList.Clear;
				end;
			end;
			
		end;
	end;
end;

procedure Init;
var
	i: Byte;
begin
	COUNT_TCP_ADMINS := True;
	COUNT_INGAME_ADMINS := True;
	AdminsList := File.CreateStringList;
	
	for i := 1 to 32 do
		Players[i].OnSpeak := @OnPlayerSpeak;
		
	Game.OnTCPMessage := @OnTCPMessage;
	Game.OnClockTick := @Clock;
end;

begin
	Init;
end.