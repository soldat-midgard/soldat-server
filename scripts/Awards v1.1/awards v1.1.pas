//
//  Awards  v 1.1   -   by zyxstand
//

{	Awards INFO

	Requirements/Limitations/Specifications:
	 - Compatible with all game modes
	 - Bots might not be counted for some awards and may cause glitches!
	 - Server may not stay at 0 seconds remaining (ie: could not find next map)
	 - Stats won't be displayed when map changes due to vote or /map command

	AdminCommands
	 - "/showawards 0" disables showing awards at end of round (stats will still be collected)
	 - "/showawards 1" enables showing awards at end of round
	 - "/showawards" simply indicates whether showing awards is enabled

	Description
	At the end of the match, the following nominations are awarded to players
	and displayed for everyone to see:
		Positive awards:
			Flagrunner (most caps - CTF/INF only)
			Deadliest (Most kills) *1
			The Professional(highest k/d) *1
			Mr. Aggressive (engaged the most in short-distance-combat) *2
			Streak Master (most kills in one life)
			Survivor (longest time without dying)
		Neutral awards:
			Chatty Cat (most chat) *2
			Vulture (most kills with victim having had < 30% health
			Demolition Expert (most kills using explosives: m79, law, grenade, cluster)
			Close Combat (most close-ranged kills)
			Chuck Norris (most kills using hands)
		Negative awards:
			Spawnkill Award (most kills with victim having been alive < 3 sec)
			Campmaster (longest cumulitive time not moving (far) - excludes AFK)
			Kamkikaze (most suicides - excludes EndOfRound suicides in survival mode)
			Spray Award:  Most off-screen kills (min. distance for sniper extended)

		*1:  only accounts for players with k/d > 1.2
		*2:  doesn't count individual times, but rather how many intervals it occurred
}

{	VERSION INFO

	------ TODO for v1.2 -> v1.3 ------
		[ ] - Use data collected to create award-rankings etc.


	------ TODO for v1.1 -> v1.2 ------
		[ ] - Show one award per player - show 10 awards max (both chosen by significances/difficulty)
		[ ] - Implement statistical features to give award only for very outstanding performance
			[ ] - Calculate standard deviation
			[ ] - Organize awards list by highest standard deviation
		[ ] - Implement statistical information gathering to improve awarding.


	------ changelog v1.0 -> v1.1 ------

		[x] - Breadwinner -> change to 'Flagrunner'
		[x] - Aggressive -> only count medium-range damage
		[x] - Campmaster -> don't count for flagger
		[x] - Suicide Award -> change to 'Kamikaze'
		[x] - Suicide Award -> don't count survival end-of-round kills

		[x] - Vulture:  most kills where victim had <30% health
		[x] - Demolition Expert:  most kills using explosives (m79, law, grenade, cluster)
		[x] - Spray Award:  most off-screen kills (min. distance for sniper extended)
		[x] - Close Combat:  most short-distance kills
		[x] - Chuck Norris:  most kills using hands

		[x] - Chatty Cat was awarded incorrectly

}


const

Vult_health = 45;  // 30% of 150(max)
Spra_max = 660;
Spra_max_sniper = 660*2;
Clos_min = 150;


var

NL: String;  //  \r\n

ShowAwards: Boolean;  // admin bool
TimeSinceEnd: Byte;
Highest_ID: Byte;  // 2.7.0 will be automatic - stores the highest player-ID
EndOfGameReached: Boolean;
IsSurvival: Boolean;
PlayedFromStart: Array[1..32] of Boolean;	// true if player was present for the entire round (for statistical purposes ONLY)

// as of version 1.1:
Vult_count: Array[1..32] of Integer;		// +1 for killing someone who has < 30% health
  Vult_good: Array[1..32] of Array[1..32] of Boolean;		// checks if you've done damage to an enemy with enemy > 30% health
Demo_count: Array[1..32] of Integer;		// +1 for killing someone with explosives (M79, LAW, grenade, cluster)
Spra_count: Array[1..32] of Integer;		// +1 for killing someone outside Spra_max range (or Spra_max_sniper for barrett)
Clos_count: Array[1..32] of Integer;		// +1 for killing someone within Clos_min range
Chuc_count: Array[1..32] of Integer;		// +1 for killing someone with hands

// as of version 1.0:
Suic_count: Array[1..32] of Integer;		// +1 for self kills
  Suic_deaths: Array[1..32] of Integer;		// NOTE: added v1.1 - number of deaths on last suicide (for survival check)
Aggr_count: Array[1..32] of Integer;		// +1 for every 4-second interval hurt/hurting
  Aggr_check: Array[1..32] of Boolean;		// reset every 4 seconds
  Aggr_times: Array[1..32] of Integer;		// stores how many intervals have passed
Stre_count: Array[1..32] of Integer; 		// stores longest kill Stre_count
  Stre_current: Array[1..32] of Integer;	// stores current Stre_count
Surv_count: Array[1..32] of Integer;		// stores longest time alive
  Surv_spawn: Array[1..32] of Integer;		// stores a player's last spawn-time (for calculations in  Surv_count and Spawnkill Award)
Chat_count: Array[1..32] of Integer;		// +1 for every 10-second interval chatted
  Chat_check: Array[1..32] of Boolean;		// reset every 10 seconds
  Chat_times: Array[1..32] of Integer;		// stores how many intervals have passed
SpKi_count:  Array[1..32] of Integer;		// stores the number of SpKi_count committed by a player
Camp_count:  Array[1..32] of Integer;		// +1 for every 3-second interval camping
  Camp_X, Camp_Y: Array[1..32] of Single;	// stores the last recorded position of a player (updated every second)
  Camp_spwnX: Array[1..32] of Single;		// stores Y position when spawned - player is AFK IFF Camp_Y = SpawnY
											// update in 2.7.0 where user inputs can be read (more reliable AFK)


function Divide(num, den: Integer): Single;
begin
	if (den <> 0) then Result := num / den else Result := -1;
end;

{
function Abs(num: Single): Single;
begin
	if (num < 0) then Result := -num else Result := num;
end;
}

procedure HigherID(ID: Byte);
begin
	if (ID > Highest_ID) then Highest_ID := ID;
end;

procedure LowerID(ID: Byte);
var i: Byte;
begin
	if (ID = Highest_ID) then
	begin
		for i := ID - 1 downto 1 do  // count down to find the next highest ID
		begin
			if (GetPlayerStat(i, 'Active')) then
			begin
				Highest_ID := i;  // when found, set it and break loop
				break;
			end;
		end;
		if (Highest_ID = ID) then Highest_ID := 0;  // if not found (ie: no more players in game) set to 0
	end;
end;


function GetDistance(X1,Y1,X2,Y2: Single): Single;  // will be added in 2.7.0
var difX, difY: Single;
begin
	difX := X2-X1;
	difY := Y2-Y1;
	Result := sqrt(difX*difX + difY*difY);
end;

procedure ResetVulture(ID: Byte);
var i: Byte;
begin
	for i := 1 to highest_ID do
	begin
		Vult_good[i][ID] := true;
	end;
end;

procedure ResetStats(ID: Byte);
begin

	// as of v1.1
	ResetVulture(ID);
	Vult_count[ID] := 0;
	Demo_count[ID] := 0;
	Spra_count[ID] := 0;
	Clos_count[ID] := 0;
	Chuc_count[ID] := 0;
	Suic_deaths[ID] := 0;

	// as of v1.0
	Suic_count[ID] := 0;
	Aggr_count[ID] := 0;
	Aggr_times[ID] := 0;
	Aggr_check[ID] := false;
	Stre_count[ID] := 0;
	Stre_current[ID] := 0;
	Surv_count[ID] := 0;
	Surv_spawn[ID] := TimeLeft;
	Chat_count[ID] := 0;
	Chat_times[ID] := 0;
	Chat_check[ID] := false;
	SpKi_count[ID] := 0;
	Camp_count[ID] := 0;
	Camp_X[ID] := 0;
	Camp_Y[ID] := 0;
	Camp_spwnX[ID] := 0;

end;

procedure ResetAllStats();
var i: Byte;
begin
	for i := 1 to 32 do
	begin
		ResetStats(i);
		PlayedFromStart[i] := true;
	end;
end;

procedure StartSurvivor(ID: Byte);
begin
	Surv_spawn[ID] := TimeLeft
end;

procedure EndSurvivor(ID: Byte);
var TimeAlive: Integer;
begin
	if (Surv_spawn[ID] <> -1) then  // should never be set to -1 at this point
	begin
		TimeAlive := Surv_spawn[ID] - TimeLeft;
		if (TimeAlive > Surv_count[ID]) then Surv_count[ID] := TimeAlive;
	end;
end;

procedure AddStreak(ID: Byte);
begin
	Stre_current[ID] := Stre_current[ID] + 1;
end;

procedure EndStreak(ID:Byte);
begin
	if (Stre_current[ID] > Stre_count[ID]) then Stre_count[ID] := Stre_current[ID];
	Stre_current[ID] := 0;
end;

procedure DoVulture(Killer,Victim: Byte);
begin
	if (Vult_good[Killer][Victim]) then Vult_count[Killer] := Vult_count[Killer] + 1;
end;

procedure DoDemolition(ID: Byte; Weapon: String);
begin
	if (Weapon = 'M79') or (Weapon = 'LAW') or (Weapon = 'Frag Grenade') or (Weapon = 'Cluster Grenade') then Demo_count[ID] := Demo_count[ID] + 1;
end;

procedure DoSprayer(Killer: Byte; Distance: Single; Weapon: String);
begin
	if (Distance > iif(Weapon = 'Barrett M82A1', Spra_max_sniper, Spra_max)) then Spra_count[Killer] := Spra_count[Killer] + 1;
end;

procedure DoCloseCombat(Killer: Byte; Distance: Single);
begin
	if (Distance < Clos_min) then Clos_count[Killer] := Clos_count[Killer] + 1;
end;

procedure AddSuicide(ID: Byte);
begin
	Suic_count[ID] := Suic_count[ID] + 1;
end;

procedure DoChuckNorris(ID: Byte; Weapon: String);
begin
	if Weapon = 'Hands' then Chuc_count[ID] := Chuc_count[ID] + 1;
end;

procedure CheckSuicide(ID: Byte);
begin
	if (IsSurvival) then if GetPlayerStat(ID,'Deaths') < Suic_deaths[ID] then Suic_count[ID] := Suic_count[ID] - 1;
end;

procedure DoAggressive(ID: Byte; Distance: Single);
begin
	if (not Aggr_check[ID]) and (Distance < 450) then  // a bit more than 70% of 640 (screen width)
	begin
		Aggr_count[ID] := Aggr_count[ID] + 1;
		Aggr_check[ID] := true;
	end;
end;

procedure AddAggressiveTime();
var i: Byte;
begin
	for i := 1 to Highest_ID do if (GetPlayerStat(i, 'Active') and GetPlayerStat(i, 'Team') <> 5) then
	begin
		Aggr_times[i] := Aggr_times[i] + 1;
		Aggr_check[i] := false;
	end;
end;

procedure Chatting(ID: Byte);
begin
	if (not Chat_check[ID]) then
	begin
		Chat_check[ID] := true;
		Chat_count[ID] := Chat_count[ID] + 1;
	end;
end;

procedure AddChatTime();
var i: Byte;
begin
	for i := 1 to Highest_ID do if (GetPlayerStat(i, 'Active')) then
	begin
		Chat_times[i] := Chat_times[i] + 1;
		Chat_check[i] := false;
	end;
end;

procedure SpawnKill(Killer, Victim: Byte);
begin
	if (Surv_spawn[Victim] <> -1) then
	begin
		if (Surv_spawn[Victim] - TimeLeft <= 3) then SpKi_count[Killer] := SpKi_count[Killer] + 1;
	end;
end;

{ // problem:  GetPlayerXY gives old XY
procedure SetAFK(ID: Byte);
var Y: Single;
begin
	GetPlayerXY(ID,Camp_spwnX[ID], Y);
end;
}

procedure DoCamp();
var i: Byte;  currentX, currentY: Single;
X, Y: Single;
begin
	for i := 1 to Highest_ID do if ((GetPlayerStat(i, 'Active')) and (GetPlayerStat(i, 'Alive')) and (not GetPlayerStat(i, 'Flagger')) and GetPlayerStat(i, 'Team') <> 5) then
	begin
		GetPlayerXY(i, currentX, currentY);
		//difX := Camp_spwnX[i] - currentX;
		// Camp_spwnX will not be used because XY positions during OnPlayerRespawn are old
		//if ((Abs(Camp_spwnX[i] - currentX) > 45) and 
		if (GetDistance(currentX, currentY, Camp_X[i], Camp_Y[i])) < 50 then Camp_count[i] := Camp_count[i] + 1;
		Camp_X[i] := currentX;
		Camp_Y[i] := currentY;
	end;
	GetPlayerXY(5, X, Y);
end;

procedure ShowStats();
var
	i: Byte;
	output: String;
	count: Integer;
	count2: Single;
	caps,  kill,  prof,  aggr,  stre,  surv,  chat,  SpKi,  camp,  suic,  vult,  demo,  spra,  clos,  chuc   : Byte;     // Player ID with highest count
	ccaps, ckill,               cstre, csurv,        cSpKi, ccamp, csuic, cvult, cdemo, cspra, cclos, cchuc  : Integer;  // value of highest count (Integer)
	              cprof, caggr,               cchat                                                          : Single;   // value of highest count (Single)
	kills,deaths: Integer;
begin
	caps:=0;kill:=0;prof:=0;aggr:=0;stre:=0;surv:=0;chat:=0;SpKi:=0;camp:=0;suic:=0;vult:=0;demo:=0;spra:=0;clos:=0;chuc:=0;
	ccaps:=0;ckill:=0;cprof:=0;caggr:=0;cstre:=0;csurv:=0;cchat:=0;cSpKi:=0;ccamp:=0;csuic:=0;cvult:=0;cdemo:=0;cspra:=0;cclos:=0;cchuc:=0;
	
	for i := 1 to Highest_ID do if GetPlayerStat(i, 'Active') then
	begin
		kills := GetPlayerStat(i, 'Kills');
		deaths := GetPlayerStat(i, 'Deaths');
		
		count := GetPlayerStat(i, 'Flags');
		  if ((count > ccaps) and (count > 1)) then begin ccaps := count;  caps := i;  end;
		count := kills;
		  if (count > ckill) then begin ckill := count;  kill := i;  end;
		//count2 := iif(kills > 5, Divide(kills, deaths)if(deaths > 0, kills / deaths, 999999), 0);  // only counts k/d if more than 5 kills
		if (kills > 5) then
		begin
			count2 := Divide(kills, deaths);
			if (count2 = -1) then count2 := 99999;
		end else count2 := 0;
		  if ((count2 > cprof) and (count2 >= 2)) then begin cprof := count2;  prof := i;  end;
		if (Aggr_times[i] > 30) then count2 := Divide(Aggr_count[i], Aggr_times[i]) else count2 := 0;
		  if ((count2 > caggr) and (count2 > 0.2))then begin caggr := count2;  aggr := i;  end;
		count := Stre_count[i];  // min: 5 kills
		  if ((count > cstre) and (count >= 5)) then begin cstre := count;  stre := i;  end;
		count := Surv_count[i];  // min 30 seconds
		  if ((count > csurv) and (count >= 30)) then begin csurv := count;  surv := i;  end;
		if ((Chat_times[i] > 10) and (count2 > 0.25)) then count2 := Divide(Chat_count[i], Chat_times[i]) else count2 := 0;
		  if (count2 > cchat)then begin cchat := count2;  chat := i;  end;
		count := SpKi_count[i];
		  if ((count > cSpKi) and (count > 5)) then begin cSpKi := count;  SpKi := i;  end;
		count := Camp_count[i];
		  if ((count > ccamp) and (count > 20)) then begin ccamp := count;  camp := i;  end;
		count := Suic_count[i];
		  if ((count > csuic) and (count > 5)) then begin csuic:= count;  suic := i;  end;
		count := Vult_count[i];
		  if ((count > cvult) and (count > 7)) then begin cvult:= count;  vult := i;  end;
		count := Demo_count[i];
		  if ((count > cdemo) and (count > 7)) then begin cdemo := count;  demo := i;  end;
		count := Spra_count[i];
		  if ((count > cspra) and (count > 7)) then begin cspra := count;  spra := i;  end;
	end;
	
	output := '';
	if (caps > 0) then output := output + 'Flag Runner:  ' + IDToName(caps) + NL;
	if (kill > 0) then output := output + 'Deadliest:  ' + IDToName(kill) + NL;
	if (prof > 0) then output := output + 'The Professional:  ' + IDToName(prof) + NL + NL;
	if (aggr > 0) then output := output + 'Mr. Aggr_count:  ' + IDToName(aggr) + NL;
	if (stre > 0) then output := output + 'Streak Master:  ' + IDToName(stre) + NL;
	if (surv > 0) then output := output + 'Survivor:  ' + IDToName(surv) + NL;
	if (chat > 0) then output := output + 'Chatty-Cat:  ' + IDToName(chat) + NL;
	if (SpKi > 0) then output := output + 'Spawnkill Jerk:  ' + IDToName(SpKi) + NL;
	if (camp > 0) then output := output + 'Loves-To-Camp:  ' + IDToName(camp) + NL;
	if (suic > 0) then output := output + 'Kamikaze:  ' + IDToName(suic) + NL;
	if (vult > 0) then output := output + 'Vulture:  ' + IDToName(vult) + NL;
	if (demo > 0) then output := output + 'Demolition Expert:  ' + IDToName(demo) + NL;
	if (spra > 0) then output := output + 'Spray Award:  ' + IDToName(spra) + NL;
	if (clos > 0) then output := output + 'Close Combat:  ' + IDToName(clos) + NL;
	if (chuc > 0) then output := output + 'Chuck Norris:  ' + IDToName(chuc) + NL;
	
	if (output <> '') then output := '  - - - AWARDS - - -  ' + NL + output else output := 'No Awards';
	
	DrawText(0,output,300,$FFC000,0.12,50,100);  // gold color
end;

procedure EndOfGame();
var i: byte;
begin
	if (not EndOfGameReached) then
	begin
		for i := 1 to Highest_ID do if (GetPlayerStat(i, 'Active')) then
		begin
			EndStreak(i);
			if (GetPlayerStat(i, 'Team') <> 5) then EndSurvivor(i);
		end;
		EndOfGameReached := true;
	end;
end;





procedure ActivateServer();
var i: Byte;
begin

//	Command('/addbot1 Kruger');  // TEMP
//	Command('/addbot2 Poncho');  // TEMP

	IsSurvival := iif(Command('/survival') = 0, false, true);
	NL := chr(13)+chr(10);
	TimeSinceEnd := 0;
	ShowAwards := true;
	Highest_ID := 0;
	EndOfGameReached := false;
	for i := 1 to 32 do if GetPlayerStat(i, 'Active') then Highest_ID := i else break;

	ResetAllStats();
	
end;

procedure OnFlagScore(ID, TeamFlag: byte);

begin
	if ((GameStyle = 3) or (GameStyle = 5)) then  // CTF, INF
	begin
		if ((AlphaScore >= ScoreLimit) or (BravoScore >= ScoreLimit)) then EndOfGame();
	end else if ((GameStyle = 2) or (GameStyle = 6)) then  // TDM, HTF
	begin
		if ((AlphaScore >= ScoreLimit) or (BravoScore >= ScoreLimit)
		or (CharlieScore >= ScoreLimit) or (DeltaScore >= ScoreLimit)) then EndOfGame();
	end;

end;

procedure OnMapChange(NewMap: String);
begin
	TimeSinceEnd := 0;
	ResetAllStats();
	EndOfGameReached := false;
end;

procedure AppOnIdle(Ticks: Integer);
begin
	if (TimeLeft = 0) then
	begin
		EndOfGame();
	end;
	if (EndOfGameReached) then
	begin
		TimeSinceEnd := TimeSinceEnd + 1;
	end;
	
	if ((TimeSinceEnd = 2) and (ShowAwards)) then ShowStats();
	
	if (Ticks mod (60 * 10) = 0) then AddChatTime();  // manages chat intervals (called every 10 seconds)
	if (not Paused) then
	begin
		if (Ticks mod (60 * 3) = 0) then DoCamp();  // manages camp
		if (Ticks mod (60 * 4) = 0) then AddAggressiveTime();  // manages aggressive intervals
	end;
end;

procedure OnJoinTeam(ID, Team: byte);
begin
	if (Team = 5) then PlayedFromStart[ID] := false;
end;

procedure OnJoinGame(ID, Team: Byte);
begin
	HigherID(ID);
	Surv_spawn[ID] := -1;
	if (Team = 5) then PlayedFromStart[ID] := false;
end;

procedure OnLeaveGame(ID, Team: Byte;Kicked: boolean);
begin
	LowerID(ID);
	ResetStats(ID);
	PlayedFromStart[ID] := false;
end;

function OnCommand(ID: Byte; Text: string): boolean;
var TextL:String;
// X,Y:Single; // TEMP
begin
	Text := trim(Text);
	TextL := lowercase(Text);
	
{	
	// TEMP:
	if TextL = '/pos' then
	begin
		GetPlayerXY(ID, X, Y);
		WriteConsole(ID, ' - X: ' + inttostr(round(X)) + '  Y: ' + inttostr(round(Y)), $FFC000);
	end;
}	
	if TextL = '/showawards' then WriteConsole(ID, iif(ShowAwards, 'Awards is ON [*]', 'Awards is OFF [*]'), $FFC000);
	if TextL = '/showawards 1' then
	begin
		ShowAwards := true;
		WriteConsole(ID, 'Awards is ON [*]', $FFC000);
	end;
	if TextL = '/showawards 0' then
	begin
		ShowAwards := false;
		WriteConsole(ID, 'Awards is OFF [*]', $FFC000);
	end;
	
	result := false;
	
end;

procedure OnPlayerRespawn(ID: Byte);
var i:byte;
begin
	StartSurvivor(ID);
	CheckSuicide(ID);
	ResetVulture(ID);
	//SetAFK(ID);
end;


function OnPlayerDamage(Victim,Shooter: Byte; Damage: Integer): Integer;
var X1,Y1,X2,Y2,Distance:Single;
begin
	GetPlayerXY(Shooter,X1,Y1);
	GetPlayerXY(Victim,X2,Y2);
	Distance := GetDistance(X1,Y1,X2,Y2);
	DoAggressive(Shooter, Distance);
	DoAggressive(Victim, Distance);
	
	if GetPlayerStat(Victim,'Health') > Vult_health then Vult_good[Shooter][Victim] := false;
	
	result := Damage;
end;


procedure OnPlayerKill(Killer, Victim: Byte;  Weapon: String);  // Weapon will be byte in 2.7.0
var X1,Y1,X2,Y2,Distance:Single;
begin
	GetPlayerXY(Killer,X1,Y1);
	GetPlayerXY(Victim,X2,Y2);
	Distance := GetDistance(X1,Y1,X2,Y2);
	if (Killer = Victim) then AddSuicide(Killer) else begin
		AddStreak(Killer);
		DoVulture(Killer, Victim);
		SpawnKill(Killer, Victim);
		if ((GameStyle = 0) or (GameStyle = 1) or (GameStyle = 4)) then  // DM, PM, RMB
		if (GetPlayerStat(Killer, 'Kills') >= ScoreLimit) then EndOfGame();
	end;
	DoDemolition(Killer, Weapon);
	DoSprayer(Killer, Distance, Weapon);
	DoCloseCombat(Killer, Distance);
	DoChuckNorris(Killer, Weapon);
	EndStreak(Victim);
	EndSurvivor(Victim);
end;

procedure OnPlayerSpeak(ID: Byte; Text: string);
begin
	Chatting(ID);
end;


