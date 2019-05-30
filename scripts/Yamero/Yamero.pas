// Yamero! - script that punishes evil players who spawnkill and camp excessively.
const
	MinPlayers_Spawn = 4;    // anti-spawn will work if there are at least X players. setting it lower makes no real sense
	MinPlayers_Camp  = 4;    // anti-camp will work if there are at least X players
	MinPlayers_AFK   = 12;   // as above, but for anti-AFK. recommended value: your player slots limit
	
	Spawn_Warn = 5;    // spawnkill counter. a kill counts as a spawnkill if the victim lived for less than five seconds
	Spawn_Kill = 9;
	Spawn_Kick = 13;

	Camp_Warn = 10;    // camping "ticks". a tick is counted every three seconds, so 10 ticks = 30 seconds of camping
	Camp_Kill = 15;
	Camp_Kick = 30;

	AFK_Time = 25;    // seconds of not moving, counted only if near spawn point. up to 255 (max byte value).
	AFK_Spec = false;  // true - sets the player to spec team. false - kicks him out

	BanDuration = 3;  // minutes; set 0 to kick only

		// ------------------------------------ TODO: LOOK AT ONMAPCHANGE ------------------------------------

type tpl = record
	pSpawn, pCamp, pAFK,  // "bad points" for spawnkilling, camping, and being away from the keyboard
	warnSpawn, warnCamp,  // maximum warning level this ID has had. decreases by one on mapchange.
	lifespan:             // how long does the player live? (seconds)
		byte;
	lastSpawn, lastCamp:  // time (seconds) since last modification of point counters
		shortint;
	X, Y:                 // previous coordinates, used in anti-camp
		single;
end;

type tspawn = record
	x, y: single;
end;

var
	pl: array [1..32] of tpl;
	spawn: array [1..2] of array [0..25] of tspawn; // it's unlikely to have more than 25 spawn points for one team
	spawncount, ptsWarn, ptsKill, ptsKick: array [1..2] of byte;

procedure getspawnpoints(); // save spawnpoints' coordinates after map change
var i, team: byte;
begin
	spawncount[1] := 0;
	spawncount[2] := 0;
	for i := 1 to 254 do if (getspawnstat(i, 'Active') = true) then begin
		team := getspawnstat(i, 'Style');
		if (team <> 1) and (team <> 2) then continue;
		spawncount[team] := spawncount[team] + 1;
		spawn[team][spawncount[team]].x := getspawnstat(i, 'X');
		spawn[team][spawncount[team]].y := getspawnstat(i, 'Y');
	end;
end;

procedure activateserver();
var i: byte;
begin
	for i := 1 to 32 do begin  // resetting values on compilation
		pl[i].pSpawn := 0;   pl[i].lastSpawn := 0;   pl[i].warnSpawn := 0;   pl[i].lifespan := 0;         // spawnkill-related
		pl[i].pCamp  := 0;   pl[i].lastCamp  := 0;   pl[i].warnCamp  := 0;   pl[i].X := 0; pl[i].Y := 0;  // camping-related
	end;
	ptsWarn[1] := Spawn_Warn;   ptsKill[1] := Spawn_Kill;   ptsKick[1] := Spawn_Kick;
	ptsWarn[2] := Camp_warn;    ptsKill[2] := Camp_Kill;    ptsKick[2] := Camp_Kick;
	getspawnpoints();
end;

procedure checkpoints(id, module: byte); // module: 1 - spawn, 2 - camp, 3 - afk
var
	points, warning: byte;
	reason, nickname: string;
begin
	case (module) of
		1: begin
			points  := pl[id].pSpawn;
			warning := pl[id].warnSpawn;
			reason  := 'spawnkill';
		end;
		2: begin
			points  := pl[id].pCamp;
			warning := pl[id].warnCamp;
			reason  := 'camp';
		end;
		3: begin
			if (pl[id].pAFK >= AFK_Time) then begin
				writeconsole(0, idtoname(id) + ' marked as AFK.', $FFFF8888);
				if (AFK_Spec) then command('/setteam5 ' + inttostr(id)) else command('/kick ' + inttostr(id));
				pl[id].pAFK := 0;
			end;
			exit;
		end;
	end;
	if (points >= ptsKick[module]) and (warning = 2) then begin
		nickname := idtoname(id);
		writeconsole(id, 'You have been warned twice for excessive ' + reason + 'ing. Your fault.', $FFFF8888);
		if (BanDuration = 0) then command('/kick ' + inttostr(id)) else banplayerreason(id, BanDuration, ' ' + reason + 'ing');
		writeconsole(0, nickname + ' ' + iif(BanDuration=0, 'kicked', 'banned') + ' for ' + reason + 'ing.', $FFF8F35A);
		writeln(nickname + ' ' + iif(BanDuration=0, 'kicked', 'banned') + ' for ' + reason + 'ing.');
	end else if (points >= ptsKill[module]) and (warning = 1) then begin
		warning := 12; // after one second it'll be changed do 2
		command('/kill ' + inttostr(id));
		writeconsole(id, 'Seriously, stop ' + reason + 'ing. This is the last warning.', $FFF8F35A);
		writeconsole(0, idtoname(id) + ' punished for ' + reason + 'ing.', $FFF8F35A);
		writeln(idtoname(id) + ' punished for ' + reason + 'ing.');
	end else if (points >= ptsWarn[module]) and (warning = 0) then begin
		warning := 11; // after one second it'll be changed do 1
		writeconsole(id, 'Please stop ' + reason + 'ing, or else you''ll be kicked.', $FFF8F35A);
		//writeconsole(0, idtoname(id) + ' marked as ' + reason + 'er.', $FFF8F35A);
	end;
	case (module) of
		1: pl[id].warnSpawn := warning;
		2: pl[id].warnCamp  := warning;
	end;
end;

procedure antispawn(killer, victim: byte);
begin
	if (killer = victim) then exit;
	if (pl[victim].lifespan <= 2) then begin
		pl[killer].pSpawn := pl[killer].pSpawn + 1;
		pl[killer].lastSpawn := 30;
		checkpoints(killer, 1);
	end;
end;

function checkspawnpoints(team: byte; x, y: single): boolean; // returns true if (x, y) is near any of team's spawnpoint (or directly under it)
var i: byte;
begin
	result := false;
	for i := 1 to spawncount[team] do begin
		if (abs(spawn[team][i].x - x) <= 10) then if (spawn[team][i].y <= y) then begin
			result := true;
			exit;
		end;
	end;
end;

procedure anticamp(camper: byte); // contains both anticamp and antiAFK modules
var
	team: byte;
	newX, newY: single;
	onSpawn: boolean;
begin
	team := getplayerstat(camper, 'Team');
	if (team = 5) then exit;
	if (getplayerstat(camper, 'Flagger') = true) then exit;
	if (getplayerstat(camper, 'Human') = false)  then exit;
	getplayerxy(camper, newX, newY);
	onSpawn := checkspawnpoints(team, newX, newY);
	if (distance(newX, newY, pl[camper].X, pl[camper].Y) <= 40) then begin
		if (not onSpawn) then begin
			if (NumPlayers >= MinPlayers_Camp) then begin
				pl[camper].pCamp := pl[camper].pCamp + 1;  // one point for not moving
				if (getkeypress(camper, 'Crouch')) or (getkeypress(camper, 'Prone')) then pl[camper].pCamp := pl[camper].pCamp + 1;  // another point if crouching
				if (getplayerstat(camper, 'Primary') = 8) then pl[camper].pCamp := pl[camper].pCamp + 1; // and another point if holding the barrett
				pl[camper].lastCamp := 16;
				checkpoints(camper, 2);
			end;
		end else begin
			if (NumPlayers >= MinPlayers_AFK) then begin
				pl[camper].pAFK := pl[camper].pAFK + 3; // this procedure is triggered every 3 seconds, so we need to add 3 seconds to player's AFK counter
				checkpoints(camper, 3);
			end;
		end;
	end else begin
		if (pl[camper].pAFK > 0) then pl[camper].pAFK := 0; // the player moved, so he's not AFK anymore
	end;
	pl[camper].X := newX;
	pl[camper].Y := newY;
end;

procedure apponidle(ticks: integer);
var i: byte;
begin
	if (ticks mod 60 <> 0) then exit;  // compatibility with 60 Hz server
	for i := 1 to 32 do if (getplayerstat(i, 'Active') = true) and (getplayerstat(i, 'Alive') = true) then begin
		if (pl[i].lifespan < 10) then pl[i].lifespan  := pl[i].lifespan  + 1;  // counting time since respawn
		if (pl[i].lastSpawn > 0) then pl[i].lastSpawn := pl[i].lastSpawn - 1;  // time since last badpoint modification (antispawn)
		if (pl[i].lastCamp  > 0) then pl[i].lastCamp  := pl[i].lastCamp  - 1;  // as above, but for anticamp
		if (pl[i].lastSpawn = 0) then if (pl[i].pSpawn > 0) then begin
			pl[i].pSpawn := pl[i].pSpawn - 1;  // forgive the player if he hasn't spawnkilled for a while
			pl[i].lastSpawn := 12;
		end;
		if (pl[i].lastCamp = 0) then if (pl[i].pCamp > 0) then begin
			pl[i].pCamp := pl[i].pCamp - 1;    // as above, but for anticamp
			pl[i].lastCamp := 6;
		end;
		if (pl[i].warnSpawn > 10) then begin
			drawtext(i, 'Stop spawnkilling!', 300, $FFF8F35A, 0.25, 40, 300);
			pl[i].warnSpawn := pl[i].warnSpawn - 10;
		end;
		if (pl[i].warnCamp > 10) then begin
			drawtext(i, 'Stop camping!', 300, $FFF8F35A, 0.25, 80, 300);
			pl[i].warnCamp := pl[i].warnCamp - 10;
		end;
		if (ticks mod 180 = 0) then anticamp(i);
	end;
end;

procedure onleavegame(id, team: byte; kicked: boolean);  // reset values
begin
	pl[id].pSpawn := 0;   pl[id].lastSpawn := 0;   pl[id].warnSpawn := 0;   pl[id].lifespan := 0;
	pl[id].pCamp  := 0;   pl[id].lastCamp  := 0;   pl[id].warnCamp  := 0;   pl[id].X := 0; pl[id].Y := 0;
	pl[id].pAFK   := 0;
end;

procedure onplayerkill(killer, victim: byte; weapon: string);
begin
	if (NumPlayers >= MinPlayers_Spawn) then antispawn(killer, victim);  // check if it was a spawnkill
end;

procedure onplayerrespawn(id: byte);
begin
	pl[id].lifespan := 0;  // player just respawned, start counting his lifespan
end;

procedure onmapchange(newmap: string);  // forgive everyone a bit    // DECREASE POINTS HERE DOWN TO BASE LEVEL
var i: byte;
begin
	getspawnpoints();
	for i := 1 to 32 do begin
		pl[i].pSpawn := 0;   pl[i].lastSpawn := 0;   pl[i].warnSpawn := 0;   pl[i].lifespan := 0;
		pl[i].pCamp  := 0;   pl[i].lastCamp  := 0;   pl[i].warnCamp  := 0;   pl[i].X := 0; pl[i].Y := 0;
	end;
end;