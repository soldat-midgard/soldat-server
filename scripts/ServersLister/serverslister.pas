//Servers Lister 1.0 for ShioN by Savage

procedure Clock(Ticks: Integer);
begin
	if Ticks mod(3600*5) = 0 then
		Players.WriteConsole('Join to our Discord Server: https://discord.gg/Jr8CFQu', Random(0, 16777215+1));
end;

procedure OnPlayerSpeak(Player: TActivePlayer; Text: String);
begin
	if LowerCase(Text) = '!servers' then begin
		
		Player.WriteConsole('Midgard Servers:', $CBCC00);

		Player.WriteConsole('Type !1v1 to forward to 1v1 server, Players: N/A, Current Map: N/A', $71CE94);

		Player.WriteConsole('Type !climb to forward to Climb server, Players: N/A, Current Map: N/A', $71CE94);

		Player.WriteConsole('Type !ctf to forward to CTF server, Players: N/A, Current Map: N/A', $71CE94);

		Player.WriteConsole('Type !bout to forward to Final Bout server, Players: N/A, Current Map: N/A', $71CE94);

		Player.WriteConsole('Type !htf to forward to HTF server, Players: N/A, Current Map: N/A', $71CE94);

		Player.WriteConsole('Type !runm to forward to Run Mode server, Players: N/A, Current Map: N/A', $71CE94);
		
		Player.WriteConsole('Type !zrpg to forward to ZRPG server, Players: N/A, Current Map: N/A', $71CE94);
		
	end;
	
	if LowerCase(Text) = '!1v1' then
		Player.ForwardTo('51.68.213.93', 23081, 'Forwarding to Midgard [1v1]');
		
	if LowerCase(Text) = '!ctf' then
		Player.ForwardTo('138.201.55.232', 25660, 'Forwarding to Midgard [CTF]');
		
	if LowerCase(Text) = '!bout' then
		Player.ForwardTo('162.221.187.210', 25020, 'Forwarding to Midgard [Final Bout]');
		
	if LowerCase(Text) = '!htf' then
		Player.ForwardTo('162.221.187.210', 25000, 'Forwarding to Midgard [HTF]');
		
	if LowerCase(Text) = '!runm' then
		Player.ForwardTo('51.68.213.93', 23080, 'Forwarding to Midgard [Run Mode]');
		
	if LowerCase(Text) = '!climb' then
		Player.ForwardTo('51.68.213.93', 23082, 'Forwarding to Midgard [Climb]');
		
	if LowerCase(Text) = '!zrpg' then
		Player.ForwardTo('51.68.213.93', 23083, 'Forwarding to Midgard [AlphaZRPG]');
		
end;

procedure Init;
var
	i: Byte;
begin
	for i := 1 to 32 do
		Players[i].OnSpeak := @OnPlayerSpeak;
		
	Game.OnClockTick := @Clock;
end;

begin
	Init;
end.