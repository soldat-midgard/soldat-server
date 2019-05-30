//Savage's MapListReader
//Core Version: 2.8.1
{Description: Tool for reading list of maps, also for searching. Result is divided into pages and displayed in BigText.
Hold "Crouch"(forward) or "Jump"(back) key to change page, You can also use "/page <number>", type "/page 0" to close.}

const
	const_MapList = 0; //Do not change it
	const_SortedMapList = 1; //Do not change it
	const_SearchResult = 2; //Do not change it
	
	const_CheckMapsExistence = False; //Works on compilation/When Sorted MapList is creating. Check if maps from mapslist.txt exists in maps directory
	const_RemoveNotExistingMaps = False; //Works on compilation/When Sorted MapList is creating. Removes not existing maps from mapslist.txt
	
	const_CheckForDuplicates = False; //Works on compilation/When Sorted MapList is creating. Check if there are duplicates in mapslist.txt
	const_RemoveDuplicates = False; //Works on compilation/When Sorted MapList is creating. Removes duplicates from mapslist.txt
	
	const_MapsPerPage = 25; //How many maps will be displayed on each page
	
	//BigText settings
	const_GeneratedPageLayer = 255;
	const_GeneratedPageColour = $FFFFFF;
	const_GeneratedPageScale = 0.05;
	const_GeneratedPagePosX = 320;
	const_GeneratedPagePosY = 70;
	
var
	GV_SortedMapList: TStringList;
	GV_SearchResult: array[1..32] of TStringList;
	GV_SearchPattern: array[1..32] of String;
	GV_CurrentPlayerPage: array[1..32] of array [const_MapList..const_SearchResult] of Integer;
	GV_MapListPages, GV_SortedMapListPages: Integer;
	GV_SearchResultPages: array[1..32] of Integer;
	GV_ShowMapID: array[1..32] of Boolean;
	GV_SortedMapListCreationDate: String;
	
procedure CreateSortedMapList(LoopMemory: Integer);
var
	i: Integer;
begin
	if LoopMemory = 0 then begin
		GV_SortedMapList := File.CreateStringList;
		GV_SortedMapListCreationDate := FormatDateTime('c', Now);
		GV_SortedMapList.Sorted := True;
		if (const_CheckForDuplicates = True) or (const_RemoveDuplicates = True) then
		GV_SortedMapList.Duplicates := DupError;
	end;
	
	try
		for i := LoopMemory to Game.MapsList.MapsCount-1 do begin
			if const_RemoveNotExistingMaps then begin
				if not File.Exists('maps/'+Game.MapsList[i]+'.pms') then begin
					WriteLn('MapListReader: Map not found: "'+Game.MapsList[i]+'" ID: "'+inttostr(i+1)+'"');
					Game.MapsList.RemoveMap(Game.MapsList[i]);
					CreateSortedMapList(i);
					exit;
				end;
			end else
			if (const_CheckMapsExistence = True) and (not File.Exists('maps/'+Game.MapsList[i]+'.pms')) then
			WriteLn('MapListReader: Map not found: "'+Game.MapsList[i]+'" ID: "'+inttostr(i+1)+'"');
			GV_SortedMapList.Add(Game.MapsList[i]);
		end;
		GV_SortedMapListPages := iif(GV_SortedMapList.Count mod const_MapsPerPage = 0, GV_SortedMapList.Count div const_MapsPerPage, GV_SortedMapList.Count div const_MapsPerPage + 1);
		WriteLn('MapListReader: Sorted MapList: Counted '+inttostr(GV_SortedMapListPages)+' '+iif(GV_SortedMapListPages = 1, 'page', 'pages')+' for '+inttostr(GV_SortedMapList.Count)+iif(GV_SortedMapList.Count = 1, ' map', ' maps'));
	except
		if const_RemoveDuplicates then begin
			WriteLn('MapListReader: Duplicate map detected: "'+Game.MapsList[i]+'" ID: "'+inttostr(i+1)+'"');
			Game.MapsList.RemoveMap(Game.MapsList[i]);
			if i <> Game.MapsList.MapsCount then
			CreateSortedMapList(i)
			else begin
				GV_SortedMapListPages := iif(GV_SortedMapList.Count mod const_MapsPerPage = 0, GV_SortedMapList.Count div const_MapsPerPage, GV_SortedMapList.Count div const_MapsPerPage + 1);
				WriteLn('MapListReader: Sorted MapList: Counted '+inttostr(GV_SortedMapListPages)+' '+iif(GV_SortedMapListPages = 1, 'page', 'pages')+' for '+inttostr(GV_SortedMapList.Count)+iif(GV_SortedMapList.Count = 1, ' map', ' maps'));
			end;
		end else
		begin
			WriteLn('MapListReader: Duplicate map detected: "'+Game.MapsList[i]+'" ID: "'+inttostr(i+1)+'"');
			if i <> Game.MapsList.MapsCount-1 then
			CreateSortedMapList(i+1)
			else begin
				GV_SortedMapListPages := iif(GV_SortedMapList.Count mod const_MapsPerPage = 0, GV_SortedMapList.Count div const_MapsPerPage, GV_SortedMapList.Count div const_MapsPerPage + 1);
				WriteLn('MapListReader: Sorted MapList: Counted '+inttostr(GV_SortedMapListPages)+' '+iif(GV_SortedMapListPages = 1, 'page', 'pages')+' for '+inttostr(GV_SortedMapList.Count)+iif(GV_SortedMapList.Count = 1, ' map', ' maps'));
			end;
		end;
	end;
end;

function OnAdminCommand(Player: TActivePlayer; Command: string): boolean;
begin
	Command := LowerCase(Command);
	
	//Built-in /addmap and /delmap
	
	if Command = '/createsortedmaplist' then
	CreateSortedMapList(0);
	
Result := False;
end;

procedure OnPlayerSpeak(Player: TActivePlayer; Text: String);
var
	i, StrToIntConv: Integer;
begin
	Text := LowerCase(Text);
	
	if Text = '!maplist' then begin
		GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := 0;
		GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
		GV_SearchResult[Player.ID].Clear;
		
		GV_CurrentPlayerPage[Player.ID][const_MapList] := 1;
		Player.WriteConsole('MapListReader: Hold "Crouch"(forward) or "Jump"(back) key to change page', const_GeneratedPageColour);
		Player.WriteConsole('You can also use "!page <number>", type "!page 0" to close', const_GeneratedPageColour);
	end;
	
	if Text = '!smaplist' then begin
		GV_CurrentPlayerPage[Player.ID][const_MapList] := 0;
		GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
		GV_SearchResult[Player.ID].Clear;
		
		GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := 1;
		Player.WriteConsole('MapListReader: Hold "Crouch"(forward) or "Jump"(back) key to change page', const_GeneratedPageColour);
		Player.WriteConsole('You can also use "!page <number>", type "!page 0" to close', const_GeneratedPageColour);
	end;
	
	if (Copy(Text, 1, 11) = '!searchmap ') and (Length(Text)>11) then begin
		Delete(Text, 1, 11);
		GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
		GV_SearchResult[Player.ID].Clear;
		for i := 0 to Game.MapsList.MapsCount-1 do
		if Pos(Text, LowerCase(Game.MapsList[i])) <> 0 then
		GV_SearchResult[Player.ID].Append(iif(GV_ShowMapID[Player.ID], inttostr(i+1)+': '+Game.MapsList[i], Game.MapsList[i]));
		if GV_SearchResult[Player.ID].Count = 0 then
		Player.WriteConsole('MapListReader: Lack of maps containing "'+Text+'"', $FF0000)
		else begin
			GV_SearchPattern[Player.ID] := Text;
			
			GV_SearchResultPages[Player.ID] := iif(GV_SearchResult[Player.ID].Count mod const_MapsPerPage = 0, GV_SearchResult[Player.ID].Count div const_MapsPerPage, GV_SearchResult[Player.ID].Count div const_MapsPerPage + 1);
			
			GV_CurrentPlayerPage[Player.ID][const_MapList] := 0;
			GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := 0;
			GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 1;
			Player.WriteConsole('MapListReader: Hold "Crouch"(forward) or "Jump"(back) key to change page', const_GeneratedPageColour);
			Player.WriteConsole('You can also use "!page <number>", type "!page 0" to close', const_GeneratedPageColour);
		end;
	end;
	
	if Text = '!showmapid' then
	if GV_ShowMapID[Player.ID] then begin
		GV_ShowMapID[Player.ID] := False
		Player.WriteConsole('MapListReader: ShowMapID OFF', $FF0000);
	end else
	begin
		GV_ShowMapID[Player.ID] := True;
		Player.WriteConsole('MapListReader: ShowMapID ON - You can see now map index from MapList in SearchResult, do it before searching', $00FF00);
		Player.WriteConsole('It doesn''t work for SortedMapList, index is 1 based, type "!showmapid" again to turn off', $0000FF);
	end;
	
	if (Copy(Text, 1, 6) = '!page ') and (Length(Text)>6) then
	if (GV_CurrentPlayerPage[Player.ID][const_MapList] <> 0) or (GV_CurrentPlayerPage[Player.ID][const_SortedMapList] <> 0) or (GV_CurrentPlayerPage[Player.ID][const_SearchResult] <> 0) then begin
		Delete(Text, 1, 6);
		try
			StrToIntConv := StrToInt(Text);
		except
			Player.WriteConsole('MapListReader: Invalid integer', $FF0000);
			exit;
		end;
		
		if GV_CurrentPlayerPage[Player.ID][const_MapList] <> 0 then
		if (StrToIntConv >= 0) and (StrToIntConv <= GV_MapListPages) then
		GV_CurrentPlayerPage[Player.ID][const_MapList] := StrToIntConv
		else
		Player.WriteConsole('MapListReader: MapList page has to be between 0 and '+inttostr(GV_MapListPages), $FF0000);
		
		if GV_CurrentPlayerPage[Player.ID][const_SortedMapList] <> 0 then
		if (StrToIntConv >= 0) and (StrToIntConv <= GV_SortedMapListPages) then
		GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := StrToIntConv
		else
		Player.WriteConsole('MapListReader: SortedMapList page has to be between 0 and '+inttostr(GV_SortedMapListPages), $FF0000);
		
		if GV_CurrentPlayerPage[Player.ID][const_SearchResult] <> 0 then
		if (StrToIntConv >= 0) and (StrToIntConv <= GV_SearchResultPages[Player.ID]) then begin
			if StrToIntConv = 0 then begin
				GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
				GV_SearchResult[Player.ID].Clear;
			end else
			GV_CurrentPlayerPage[Player.ID][const_SearchResult] := StrToIntConv;
		end else
		Player.WriteConsole('MapListReader: SearchResult page has to be between 0 and '+inttostr(GV_SearchResultPages[Player.ID]), $FF0000);
	end else
	Player.WriteConsole('MapListReader: Open MapList, SortedMapList or SearchResult first', $FF0000);
end;

function OnPlayerCommand(Player: TActivePlayer; Command: String): Boolean;
var
	i, StrToIntConv: Integer;
begin
	Command := LowerCase(Command);
	
	if Command = '/maplist' then begin
		GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := 0;
		GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
		GV_SearchResult[Player.ID].Clear;
		
		GV_CurrentPlayerPage[Player.ID][const_MapList] := 1;
		Player.WriteConsole('MapListReader: Hold "Crouch"(forward) or "Jump"(back) key to change page', const_GeneratedPageColour);
		Player.WriteConsole('You can also use "/page <number>", type "/page 0" to close', const_GeneratedPageColour);
	end;
	
	if Command = '/smaplist' then begin
		GV_CurrentPlayerPage[Player.ID][const_MapList] := 0;
		GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
		GV_SearchResult[Player.ID].Clear;
		
		GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := 1;
		Player.WriteConsole('MapListReader: Hold "Crouch"(forward) or "Jump"(back) key to change page', const_GeneratedPageColour);
		Player.WriteConsole('You can also use "/page <number>", type "/page 0" to close', const_GeneratedPageColour);
	end;
	
	if (Copy(Command, 1, 11) = '/searchmap ') and (Length(Command)>11) then begin
		Delete(Command, 1, 11);
		GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
		GV_SearchResult[Player.ID].Clear;
		for i := 0 to Game.MapsList.MapsCount-1 do
		if Pos(Command, LowerCase(Game.MapsList[i])) <> 0 then
		GV_SearchResult[Player.ID].Append(iif(GV_ShowMapID[Player.ID], inttostr(i+1)+': '+Game.MapsList[i], Game.MapsList[i]));
		if GV_SearchResult[Player.ID].Count = 0 then
		Player.WriteConsole('MapListReader: Lack of maps containing "'+Command+'"', $FF0000)
		else begin
			GV_SearchPattern[Player.ID] := Command;
			
			GV_SearchResultPages[Player.ID] := iif(GV_SearchResult[Player.ID].Count mod const_MapsPerPage = 0, GV_SearchResult[Player.ID].Count div const_MapsPerPage, GV_SearchResult[Player.ID].Count div const_MapsPerPage + 1);
			
			GV_CurrentPlayerPage[Player.ID][const_MapList] := 0;
			GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := 0;
			GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 1;
			Player.WriteConsole('MapListReader: Hold "Crouch"(forward) or "Jump"(back) key to change page', const_GeneratedPageColour);
			Player.WriteConsole('You can also use "/page <number>", type "/page 0" to close', const_GeneratedPageColour);
		end;
	end;
	
	if Command = '/showmapid' then
	if GV_ShowMapID[Player.ID] then begin
		GV_ShowMapID[Player.ID] := False
		Player.WriteConsole('MapListReader: ShowMapID OFF', $FF0000);
	end else
	begin
		GV_ShowMapID[Player.ID] := True;
		Player.WriteConsole('MapListReader: ShowMapID ON - You can see now map index from MapList in SearchResult, do it before searching', $00FF00);
		Player.WriteConsole('It doesn''t work for SortedMapList, index is 1 based, type "/showmapid" again to turn off', $0000FF);
	end;
	
	if (Copy(Command, 1, 6) = '/page ') and (Length(Command)>6) then
	if (GV_CurrentPlayerPage[Player.ID][const_MapList] <> 0) or (GV_CurrentPlayerPage[Player.ID][const_SortedMapList] <> 0) or (GV_CurrentPlayerPage[Player.ID][const_SearchResult] <> 0) then begin
		Delete(Command, 1, 6);
		try
			StrToIntConv := StrToInt(Command);
		except
			Player.WriteConsole('MapListReader: Invalid integer', $FF0000);
			exit;
		end;
		
		if GV_CurrentPlayerPage[Player.ID][const_MapList] <> 0 then
		if (StrToIntConv >= 0) and (StrToIntConv <= GV_MapListPages) then
		GV_CurrentPlayerPage[Player.ID][const_MapList] := StrToIntConv
		else
		Player.WriteConsole('MapListReader: MapList page has to be between 0 and '+inttostr(GV_MapListPages), $FF0000);
		
		if GV_CurrentPlayerPage[Player.ID][const_SortedMapList] <> 0 then
		if (StrToIntConv >= 0) and (StrToIntConv <= GV_SortedMapListPages) then
		GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := StrToIntConv
		else
		Player.WriteConsole('MapListReader: SortedMapList page has to be between 0 and '+inttostr(GV_SortedMapListPages), $FF0000);
		
		if GV_CurrentPlayerPage[Player.ID][const_SearchResult] <> 0 then
		if (StrToIntConv >= 0) and (StrToIntConv <= GV_SearchResultPages[Player.ID]) then begin
			if StrToIntConv = 0 then begin
				GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
				GV_SearchResult[Player.ID].Clear;
			end else
			GV_CurrentPlayerPage[Player.ID][const_SearchResult] := StrToIntConv;
		end else
		Player.WriteConsole('MapListReader: SearchResult page has to be between 0 and '+inttostr(GV_SearchResultPages[Player.ID]), $FF0000);
	end else
	Player.WriteConsole('MapListReader: Open MapList, SortedMapList or SearchResult first', $FF0000);
	
Result := False;
end;

procedure OnLeave(Player: TActivePlayer; Kicked: Boolean);
begin
	GV_CurrentPlayerPage[Player.ID][const_MapList] := 0;
	GV_CurrentPlayerPage[Player.ID][const_SortedMapList] := 0;
	GV_CurrentPlayerPage[Player.ID][const_SearchResult] := 0;
	GV_SearchResult[Player.ID].Clear;
	GV_ShowMapID[Player.ID] := False;
end;

procedure OnClockTick(Ticks: Integer);
var
	i: Byte;
	j: Integer;
	GeneratedPage: String;
begin
	GV_MapListPages := iif(Game.MapsList.MapsCount mod const_MapsPerPage = 0, Game.MapsList.MapsCount div const_MapsPerPage, Game.MapsList.MapsCount div const_MapsPerPage + 1);
	
	for i := 1 to 32 do begin
	
		if GV_CurrentPlayerPage[i][const_MapList] <> 0 then
		if GV_MapListPages <> 0 then begin
			
			if GV_CurrentPlayerPage[i][const_MapList] > GV_MapListPages then
			GV_CurrentPlayerPage[i][const_MapList] := GV_MapListPages;
			
			if (Players[i].KeyUp) and (GV_CurrentPlayerPage[i][const_MapList] > 1) then
			Dec(GV_CurrentPlayerPage[i][const_MapList], 1);
			
			if (Players[i].KeyCrouch) and (GV_CurrentPlayerPage[i][const_MapList] < GV_MapListPages) then
			Inc(GV_CurrentPlayerPage[i][const_MapList], 1);
			
			GeneratedPage := ' MapList: '+inttostr(Game.MapsList.MapsCount)+iif(Game.MapsList.MapsCount = 1, ' Map', ' Maps')+#10+' Page: '+inttostr(GV_CurrentPlayerPage[i][const_MapList])+' / '+inttostr(GV_MapListPages)+' Length: '+inttostr(iif(GV_CurrentPlayerPage[i][const_MapList]=GV_MapListPages, Game.MapsList.MapsCount-(GV_MapListPages-1)*const_MapsPerPage, const_MapsPerPage))+' / '+inttostr(const_MapsPerPage)+#10+' Current Map: '+Game.CurrentMap+#10+' ID: '+inttostr(Game.MapsList.CurrentMapId+1)+' Page: '+inttostr(iif((Game.MapsList.CurrentMapId+1) mod const_MapsPerPage = 0, (Game.MapsList.CurrentMapId+1) div const_MapsPerPage, (Game.MapsList.CurrentMapId+1) div const_MapsPerPage + 1))+#10#10;
			for j := (GV_CurrentPlayerPage[i][const_MapList]-1)*const_MapsPerPage to GV_CurrentPlayerPage[i][const_MapList]*const_MapsPerPage-1 do begin
				if Game.CurrentMap=Game.MapsList[j] then begin
					if GV_ShowMapID[i] then
					GeneratedPage := GeneratedPage+chr(149)+inttostr(j+1)+': '+Game.MapsList[j]+#10
					else
					GeneratedPage := GeneratedPage+chr(149)+Game.MapsList[j]+#10;
				end else
				begin
					if GV_ShowMapID[i] then
					GeneratedPage := GeneratedPage+' '+inttostr(j+1)+': '+Game.MapsList[j]+#10
					else
					GeneratedPage := GeneratedPage+' '+Game.MapsList[j]+#10;
				end;
				if j = Game.MapsList.MapsCount-1 then
				break;
			end;
			Players[i].BigText(const_GeneratedPageLayer, GeneratedPage, 120, const_GeneratedPageColour, const_GeneratedPageScale, const_GeneratedPagePosX, const_GeneratedPagePosY);
			
		end else Players[i].BigText(const_GeneratedPageLayer, 'Empty MapList', 120, const_GeneratedPageColour, const_GeneratedPageScale, const_GeneratedPagePosX, const_GeneratedPagePosY);
		
		if GV_CurrentPlayerPage[i][const_SortedMapList] <> 0 then
		if GV_SortedMapListPages <> 0 then begin
			
			if GV_CurrentPlayerPage[i][const_SortedMapList] > GV_SortedMapListPages then
			GV_CurrentPlayerPage[i][const_SortedMapList] := GV_SortedMapListPages;
			
			if (Players[i].KeyUp) and (GV_CurrentPlayerPage[i][const_SortedMapList] > 1) then
			Dec(GV_CurrentPlayerPage[i][const_SortedMapList], 1);
			
			if (Players[i].KeyCrouch) and (GV_CurrentPlayerPage[i][const_SortedMapList] < GV_SortedMapListPages) then
			Inc(GV_CurrentPlayerPage[i][const_SortedMapList], 1);
			
			GeneratedPage := ' SortedMapList: '+inttostr(GV_SortedMapList.Count)+iif(GV_SortedMapList.Count = 1, ' Map', ' Maps')+#10+' Page: '+inttostr(GV_CurrentPlayerPage[i][const_SortedMapList])+' / '+inttostr(GV_SortedMapListPages)+' Length: '+inttostr(iif(GV_CurrentPlayerPage[i][const_SortedMapList]=GV_SortedMapListPages, GV_SortedMapList.Count-(GV_SortedMapListPages-1)*const_MapsPerPage, const_MapsPerPage))+' / '+inttostr(const_MapsPerPage)+#10+' Created: '+GV_SortedMapListCreationDate+#10#10;
			for j := (GV_CurrentPlayerPage[i][const_SortedMapList]-1)*const_MapsPerPage to GV_CurrentPlayerPage[i][const_SortedMapList]*const_MapsPerPage-1 do begin
				if Game.CurrentMap=GV_SortedMapList[j] then
				GeneratedPage := GeneratedPage+chr(149)+GV_SortedMapList[j]+#10
				else
				GeneratedPage := GeneratedPage+' '+GV_SortedMapList[j]+#10;
				if j = GV_SortedMapList.Count-1 then
				break;
			end;
			Players[i].BigText(const_GeneratedPageLayer, GeneratedPage, 120, const_GeneratedPageColour, const_GeneratedPageScale, const_GeneratedPagePosX, const_GeneratedPagePosY);
			
		end else Players[i].BigText(const_GeneratedPageLayer, 'Empty SortedMapList', 120, const_GeneratedPageColour, const_GeneratedPageScale, const_GeneratedPagePosX, const_GeneratedPagePosY);
		
		if GV_CurrentPlayerPage[i][const_SearchResult] <> 0 then begin
		
			if (Players[i].KeyUp) and (GV_CurrentPlayerPage[i][const_SearchResult] > 1) then
			Dec(GV_CurrentPlayerPage[i][const_SearchResult], 1);
			
			if (Players[i].KeyCrouch) and (GV_CurrentPlayerPage[i][const_SearchResult] < GV_SearchResultPages[i]) then
			Inc(GV_CurrentPlayerPage[i][const_SearchResult], 1);
			
			GeneratedPage := ' SearchResult: '+inttostr(GV_SearchResult[i].Count)+iif(GV_SearchResult[i].Count = 1, ' Map', ' Maps')+#10+' Page: '+inttostr(GV_CurrentPlayerPage[i][const_SearchResult])+' / '+inttostr(GV_SearchResultPages[i])+' Length: '+inttostr(iif(GV_CurrentPlayerPage[i][const_SearchResult]=GV_SearchResultPages[i], GV_SearchResult[i].Count-(GV_SearchResultPages[i]-1)*const_MapsPerPage, const_MapsPerPage))+' / '+inttostr(const_MapsPerPage)+#10+' Search Pattern: '+GV_SearchPattern[i]+#10#10;
			for j := (GV_CurrentPlayerPage[i][const_SearchResult]-1)*const_MapsPerPage to GV_CurrentPlayerPage[i][const_SearchResult]*const_MapsPerPage-1 do begin
				if Game.CurrentMap=GV_SearchResult[i][j] then
				GeneratedPage := GeneratedPage+chr(149)+GV_SearchResult[i][j]+#10
				else
				GeneratedPage := GeneratedPage+' '+GV_SearchResult[i][j]+#10;
				if j = GV_SearchResult[i].Count-1 then
				break;
			end;
			Players[i].BigText(const_GeneratedPageLayer, GeneratedPage, 120, const_GeneratedPageColour, const_GeneratedPageScale, const_GeneratedPagePosX, const_GeneratedPagePosY);
			
		end;
		
	end;
	
end;

procedure Init;
var
	i: Byte;
begin
	CreateSortedMapList(0);
	
	GV_MapListPages := iif(Game.MapsList.MapsCount mod const_MapsPerPage = 0, Game.MapsList.MapsCount div const_MapsPerPage, Game.MapsList.MapsCount div const_MapsPerPage + 1);
	WriteLn('MapListReader: MapList: Counted '+inttostr(GV_MapListPages)+' '+iif(GV_MapListPages = 1, 'page', 'pages')+' for '+inttostr(Game.MapsList.MapsCount)+iif(Game.MapsList.MapsCount = 1, ' map', ' maps'));
	
	for i := 1 to 32 do begin
		GV_SearchResult[i] := File.CreateStringList;
		Players[i].OnSpeak := @OnPlayerSpeak;
		Players[i].OnCommand := @OnPlayerCommand;
	end;
	
	Game.OnLeave := @OnLeave;
	Game.OnAdminCommand := @OnAdminCommand;
	Game.TickThreshold := 5;
	Game.OnClockTick := @OnClockTick;
end;

begin
	Init;
end.