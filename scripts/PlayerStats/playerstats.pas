uses database;

const
	DB_ID = 2;
	DB_NAME = '/home/shared/PlayersDB.db';
	MSG_COLOR = $0080FF;

// Helper functions
function EscapeApostrophe(Source: String): String;
begin
	Result := ReplaceRegExpr('''', Source, '''''', False);
end;

// Procedures
procedure WriteStatToPlayerConsole(Player: TActivePlayer; name, kills, deaths, kd, caps: String);
begin
    Player.WriteConsole('==========', MSG_COLOR);
    Player.WriteConsole('Name: ' + name, MSG_COLOR);
    Player.WriteConsole('Kills: ' + kills, MSG_COLOR);
    Player.WriteConsole('Deaths: ' + deaths, MSG_COLOR);
    Player.WriteConsole('Caps: ' + caps, MSG_COLOR);
    Player.WriteConsole('KD: ' + KD, MSG_COLOR);
    Player.WriteConsole('===========', MSG_COLOR);
end;

procedure GetTopPlayers(Player: TActivePlayer); 
var
    i: byte;
    j: byte;
    currentPlayer: TActivePlayer;
    name: string;
    points: string;

begin
    if DB_Query(DB_ID, 'SELECT Name, Points from Players order by Points DESC Limit 5;') then
    begin
        for i := 1 to 32 do
        begin
            currentPlayer := Players[i];
            currentPlayer.WriteConsole('TOP Players', MSG_COLOR);
            currentPlayer.WriteConsole('==============', MSG_COLOR);
        end;

        j := 1;
        while DB_NextRow(DB_ID) do
        begin
            for i := 1 to 32 do
            begin
                currentPlayer := Players[i];
                name := DB_GetString(DB_ID, 0);
                points := DB_GetString(DB_ID, 1);

                currentPlayer.WriteConsole(intToStr(j) + ') ' + name + ': ' + points, MSG_COLOR);
            end;
            j := j + 1;
        end;
        DB_FinishQuery(DB_ID);
    end;
end;

procedure GetSelfStats(Player: TActivePlayer);
var
    i: Byte;
    kills: double;
    deaths: double;
    kd: string;
    kdRaw: double;
    caps: string;
    name: string;

begin
    if DB_Query(DB_ID, 'SELECT Name, Kills, Deaths, Points FROM Players WHERE Name = ''' + EscapeApostrophe(Player.Name) + ''' LIMIT 1;') then
    begin
        While DB_NextRow(DB_ID) do
        begin
            for i := 1 to 32 do
            begin
                name := DB_GetString(DB_ID, 0);
                kills := StrToFloat(DB_GetString(DB_ID, 1));
                deaths := StrToFloat(DB_GetString(DB_ID, 2));
                if deaths < 1 then
                    deaths := 1;

                kdRaw := kills/deaths;
                kd := FormatFloat('0.00', kdRaw);
                caps := DB_GetString(DB_ID, 3);
                WriteStatToPlayerConsole(Players[i], name, FormatFloat('0', kills), FormatFloat('0', deaths), kd, caps);
            end;
        end;
        DB_FinishQuery(DB_ID);
    end;
end;

procedure GetPlayerStats(Player: TActivePlayer; Text: string);
var
    kills: double;
    deaths: double;
    kd: string;
    kdRaw: double;
    caps: string;
    name: string;

begin
    if DB_Query(DB_ID, 'SELECT Name, Kills, Deaths FROM Players WHERE Name = ''' + EscapeApostrophe(Copy(Text, 8, Length(Text))) + ''' LIMIT 1;') then
    begin
        While DB_NextRow(DB_ID) do
        begin
            name := DB_GetString(DB_ID, 0);
            kills := StrToFloat(DB_GetString(DB_ID, 1));
            deaths := StrToFloat(DB_GetString(DB_ID, 2));
            if deaths < 1 then
                deaths := 1;

            kdRaw := kills/deaths;
            kd := FormatFloat('0.00', kdRaw);
            caps := DB_GetString(DB_ID, 3);
            WriteStatToPlayerConsole(Player, name, FormatFloat('0', kills), FormatFloat('0', deaths), kd, caps);
        end;
        DB_FinishQuery(DB_ID);
    end;
end;

// Event handling
procedure OnPlayerSpeak(Player: TActivePlayer; Text: string);
begin
    if (Copy(Text, 1, 7) = '!stats ') and (Copy(Text, 8, Length(Text)) <> Nil) then
        GetPlayerStats(Player, Text)
    else if (Copy(Text, 1, 6) = '!stats') and ((Copy(Text, 7, Length(Text)) = Nil) or (Copy(Text, 7, 8) = ' ')) then
        GetSelfStats(Player)
    else if(Copy(Text, 1, 4) = '!top') then
        GetTopPlayers(Player);
end;

procedure OnPlayerKill(Killer, Victim: TActivePlayer; BulletId: Byte);
begin
  if not DB_UPDATE(DB_ID, 'Update Players SET Kills = Kills + 1, Points = Points + 1 WHERE Name = ''' + EscapeApostrophe(Killer.Name) + ''' AND Hwid = ''' + EscapeApostrophe(Killer.HWID) + ''';') then 
    WriteLn('PlayersDB Error updating player kills and points: '+DB_Error); 

  if not DB_UPDATE(DB_ID, 'Update Players SET Deaths = Deaths + 1, Points = Points - 1 WHERE Name = ''' + EscapeApostrophe(Victim.Name) + ''' AND Hwid = ''' + EscapeApostrophe(Victim.HWID) + ''';') then 
    WriteLn('PlayersDB Error updating player deaths and points: '+DB_Error); 
end;

procedure OnFlagScore(Player: TActivePlayer; TeamFlag: byte);
begin
    if not DB_UPDATE(DB_ID, 'Update Players Set Points = Points + 3 WHERE Name = ''' + EscapeApostrophe(Player.Name) + ''' AND Hwid = ''' + EscapeApostrophe(Player.HWID) + ''';') then 
        WriteLn('PlayersDB Error updating score for flag grab: '+DB_Error);
end;

// Init proc
procedure Init;
var 
    i: Byte;
begin
    if File.Exists(DB_NAME) then 
    begin
        DatabaseOpen(DB_ID, DB_NAME, '', '', DB_Plugin_SQLite);
        for i := 1 to 32 do
        begin
            Players[i].OnSpeak := @OnPlayerSpeak;
            Players[i].OnKill := @OnPlayerKill;
            //Players[i].OnFlagScore := @OnFlagScore;
        end;
    end;
end;

begin
    Init;
end.