function OnAdminCommand(Player: TActivePlayer; Command: string): boolean;
begin
	if Copy(Command, 1, 5) = '/say ' then begin
		Result := true;
		if Player <> nil then begin
			Players.WriteConsole('*ADMIN* [' + Player.Name + '] ' + Copy(Command, 6, length(Command)), $FFFF00);
			WriteLn('/say [' + Player.Name + '] ' + Copy(Command, 6, length(Command)));
		end else
		Players.WriteConsole('*SERVER* ' + Copy(Command, 6, length(Command)), $FFFF00);
	end;
end;

begin
	Game.OnAdminCommand := @OnAdminCommand;
end.