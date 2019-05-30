//PlayersDB 1.5 by Savage

uses database;

const
	DB_ID = 2;
	DB_NAME = '/home/shared/PlayersDB.db';
	MSG_COLOR = $6495ed;
	
function EscapeApostrophe(Source: String): String;
begin
	Result := ReplaceRegExpr('''', Source, '''''', False);
end;

function GetWord(Source: String; WordNumber: Integer): String;
var
	WordCounter, WordIndex, i: Integer;
begin
	if WordNumber > 0 then begin
		for i := 1 to Length(Source) do
			if WordIndex <> 0 then begin
				if Source[i] = ' ' then begin
					Inc(WordCounter, 1);
					if WordNumber = WordCounter then begin
						Result := Copy(Source, WordIndex, i-WordIndex);
						break;
					end else
						WordIndex := 0;
				end else
					if i = Length(Source) then begin
						Inc(WordCounter, 1);
						if WordNumber = WordCounter then
							Result := Copy(Source, WordIndex, i-WordIndex+1);
					end;
			end else
				if Source[i] = ' ' then
					continue
				else
					if i = Length(Source) then begin
						Inc(WordCounter, 1);
						if WordNumber = WordCounter then
							Result := Source[i];
					end else
						WordIndex := i;
	end else
		WriteLn('Warning: Function "GetWord" - Second parameter has to be higher than "0"');
end;

procedure OnJoin(Player: TActivePlayer; Team: TTeam);
begin
	if Player.Human then begin
		if Not DB_Query(DB_ID, 'SELECT Name, Hwid FROM Players WHERE Name = '''+EscapeApostrophe(Player.Name)+''' AND Hwid = '''+EscapeApostrophe(Player.HWID)+''' LIMIT 1;') then
			WriteLn('PlayersDB Error4: '+DB_Error)
		else begin
			if Not DB_NextRow(DB_ID) then begin
				if Not DB_Update(DB_ID, 'INSERT INTO Players(Name, Hwid, Entry) VALUES('''+EscapeApostrophe(Player.Name)+''', '''+EscapeApostrophe(Player.HWID)+''', 1);') then
					WriteLn('PlayersDB Error5: '+DB_Error);
			end else
				if Not DB_Update(DB_ID, 'UPDATE Players SET Entry = Entry +1 WHERE Name = '''+EscapeApostrophe(Player.Name)+''' AND Hwid = '''+EscapeApostrophe(Player.HWID)+''';') then
					WriteLn('PlayersDB Error6: '+DB_Error);
					
			DB_FinishQuery(DB_ID);
		end;
	end;
end;

function OnAdminCommand(Player: TActivePlayer; Command: string): boolean;
var
	TempID: Byte;
begin
Result := False;
if Player <> nil then begin//In-Game Admin
	
	if (GetWord(Command, 1) = '/checkhw') and (GetWord(Command, 2) <> nil) then
		if DB_Query(DB_ID, 'SELECT Name, Entry FROM Players WHERE Hwid = '''+EscapeApostrophe(GetWord(Command, 2))+''' ORDER BY Entry;') then begin
			While DB_NextRow(DB_ID) Do
				Player.WriteConsole(DB_GetString(DB_ID, 0)+': '+DB_GetString(DB_ID, 1), MSG_COLOR);
			DB_FinishQuery(DB_ID);
			Player.WriteConsole('Result for HWID "'+GetWord(Command, 2)+'" has been sorted by entries in ascending order', MSG_COLOR);
		end else
			Player.WriteConsole('PlayersDB Error7: '+DB_Error, MSG_COLOR);
			
	if (Copy(Command, 1, 11) = '/checknick ') and (Copy(Command, 12, Length(Command)) <> nil) then
		if DB_Query(DB_ID, 'SELECT Hwid, Entry FROM Players WHERE Name = '''+EscapeApostrophe(Copy(Command, 12, Length(Command)))+''' ORDER BY Entry;') then begin
			While DB_NextRow(DB_ID) Do
				Player.WriteConsole(DB_GetString(DB_ID, 0)+': '+DB_GetString(DB_ID, 1), MSG_COLOR);
			DB_FinishQuery(DB_ID);
			Player.WriteConsole('Result for Nick "'+Copy(Command, 12, Length(Command))+'" has been sorted by entries in ascending order', MSG_COLOR);
		end else
			Player.WriteConsole('PlayersDB Error8: '+DB_Error, MSG_COLOR);
			
	if (GetWord(Command, 1) = '/checkid') and (GetWord(Command, 2) <> nil) then begin
		try
			TempID := StrToInt(GetWord(Command, 2));
		except
			Player.WriteConsole('"'+GetWord(Command, 2)+'" is invalid integer', MSG_COLOR);
		end;
		if (TempID > 0) and (TempID < 33) then begin
			if DB_Query(DB_ID, 'SELECT Name, Entry FROM Players WHERE Hwid = '''+EscapeApostrophe(Players[TempID].HWID)+''' ORDER BY Entry;') then begin
				While DB_NextRow(DB_ID) Do
					Player.WriteConsole(DB_GetString(DB_ID, 0)+': '+DB_GetString(DB_ID, 1), MSG_COLOR);
				DB_FinishQuery(DB_ID);
				Player.WriteConsole('Result for HWID "'+Players[TempID].HWID+'" has been sorted by entries in ascending order', MSG_COLOR);
			end else
				Player.WriteConsole('PlayersDB Error9: '+DB_Error, MSG_COLOR);
		end else
			Player.WriteConsole('ID has to be from 1 to 32', MSG_COLOR);
	end;
	
end else
begin//TCP Admin
	
	if (GetWord(Command, 1) = '/checkhw') and (GetWord(Command, 2) <> nil) then
		if DB_Query(DB_ID, 'SELECT Name, Entry FROM Players WHERE Hwid = '''+EscapeApostrophe(GetWord(Command, 2))+''' ORDER BY Entry;') then begin
			While DB_NextRow(DB_ID) Do
				WriteLn(DB_GetString(DB_ID, 0)+': '+DB_GetString(DB_ID, 1));
			DB_FinishQuery(DB_ID);
			WriteLn('Result for HWID "'+GetWord(Command, 2)+'" has been sorted by entries in ascending order');
		end else
			WriteLn('PlayersDB Error10: '+DB_Error);
			
	if (Copy(Command, 1, 11) = '/checknick ') and (Copy(Command, 12, Length(Command)) <> nil) then
		if DB_Query(DB_ID, 'SELECT Hwid, Entry FROM Players WHERE Name = '''+EscapeApostrophe(Copy(Command, 12, Length(Command)))+''' ORDER BY Entry;') then begin
			While DB_NextRow(DB_ID) Do
				WriteLn(DB_GetString(DB_ID, 0)+': '+DB_GetString(DB_ID, 1));
			DB_FinishQuery(DB_ID);
			WriteLn('Result for Nick "'+Copy(Command, 12, Length(Command))+'" has been sorted by entries in ascending order');
		end else
			WriteLn('PlayersDB Error11: '+DB_Error);
			
	if (GetWord(Command, 1) = '/checkid') and (GetWord(Command, 2) <> nil) then begin
		try
			TempID := StrToInt(GetWord(Command, 2));
		except
			WriteLn('"'+GetWord(Command, 2)+'" is invalid integer');
		end;
		if (TempID > 0) and (TempID < 33) then begin
			if DB_Query(DB_ID, 'SELECT Name, Entry FROM Players WHERE Hwid = '''+EscapeApostrophe(Players[TempID].HWID)+''' ORDER BY Entry;') then begin
				While DB_NextRow(DB_ID) Do
					WriteLn(DB_GetString(DB_ID, 0)+': '+DB_GetString(DB_ID, 1));
				DB_FinishQuery(DB_ID);
				WriteLn('Result for HWID "'+Players[TempID].HWID+'" has been sorted by entries in ascending order');
			end else
				WriteLn('PlayersDB Error12: '+DB_Error);
		end else
			WriteLn('ID has to be from 1 to 32');
	end;
end;
end;

procedure Init;
var
	DBFile: TFileStream;
begin
	if not File.Exists(DB_NAME) then begin
		DBFile := File.CreateFileStream;
		DBFile.SaveToFile(DB_NAME);
		DBFile.Free;
		WriteLn('Database "'+DB_NAME+'" has been created');
		if DatabaseOpen(DB_ID, DB_NAME, '', '', DB_Plugin_SQLite) then
			DatabaseUpdate(DB_ID, 'CREATE TABLE Players(Id INTEGER PRIMARY KEY, Name TEXT, Hwid TEXT, Entry INTEGER);');
	end else
		DatabaseOpen(DB_ID, DB_NAME, '', '', DB_Plugin_SQLite);
	
	Game.OnJoin := @OnJoin;
	Game.OnAdminCommand := @OnAdminCommand;
end;

begin
	Init;
end.