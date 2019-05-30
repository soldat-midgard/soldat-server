//Discord Script 1.0 by Savage

var
	_Timer: Integer;

procedure OnPlayerSpeak(Player: TActivePlayer; Text: String);
var
	TempStrL: TStringList;
begin
	if (Copy(Text, 1, 5) = '!msg ') and (Copy(Text, 6, Length(Text)) <> nil) then
		if _Timer = 0 then begin
			TempStrL := File.CreateStringList;
			TempStrL.Append(FloatToStr(Now));
			TempStrL.Append('['+Player.Name+'] '+Copy(Text, 6, Length(Text)));
			TempStrL.SaveToFile('maps/discord.pms');
			TempStrL.Free;
			_Timer := 3;
		end else Player.WriteConsole('To send next message You have to wait: '+IntToStr(_Timer)+'s', $FF0000);
end;

procedure Clock(Ticks: Integer);
begin
	if _Timer > 0 then
		Dec(_Timer, 1);
end;

procedure Init;
var
	i: Byte;
begin
	Game.OnClockTick := @Clock;
	for i := 1 to 32 do
		Players[i].OnSpeak := @OnPlayerSpeak;
end;

begin
	Init;
end.