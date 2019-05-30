//Multi HWID Blocker by Savage

function OnRequest(Ip, Hw: string; Port: Word; State: Byte; Forwarded: Boolean; Password: string): Integer;
var
	i: Byte;
begin
	Result := State;
	
	if State=1 then
	for i := 1 to 32 do
	if (Players[i].Active) and (Players[i].HWID=HW) then begin
		Result := 0;
		break;
	end;
end;

begin
	Game.OnRequest := @OnRequest;
end.