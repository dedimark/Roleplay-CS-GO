#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <roleplay>
#include <multicolors>
#include <devzones>

#pragma newdecls required

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"

Database g_DB;
char dbconfig[] = "roleplay";

public Plugin myinfo = 
{
	name = "[Roleplay] Jobs - Out", 
	author = "Benito", 
	description = "Sortir les joueurs ", 
	version = "1.0", 
	url = "www.revolution-asso.eu"
};

public void OnPluginStart() 
{
	if(rp_licensing_isValid())
	{
		RegConsoleCmd("out", Command_Out);
		RegConsoleCmd("exclure", Command_Out);
		RegConsoleCmd("virer", Command_Out);		
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("Database failure: %s", error);
	} 
        else 
        {
		db.SetCharset("utf8");
		g_DB = db;
		
		char createTableQuery[4096];
		Format(createTableQuery, sizeof(createTableQuery), 
		"CREATE TABLE IF NOT EXISTS `rp_out` ( \
		`Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	       `pos_x` float NOT NULL, \
		`pos_y` float NOT NULL, \
		`pos_z` float NOT NULL, \
	       `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	         PRIMARY KEY (`Id`), \
	         UNIQUE KEY `Id` (`Id`) \
	         )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, createTableQuery);
		
		Format(createTableQuery, sizeof(createTableQuery), 
		"CREATE TABLE IF NOT EXISTS `rp_spawns` ( \
		`Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	       `pos_x` float NOT NULL, \
		`pos_y` float NOT NULL, \
		`pos_z` float NOT NULL, \
	       `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	         PRIMARY KEY (`Id`), \
	         UNIQUE KEY `Id` (`Id`) \
	         )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, createTableQuery);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_ClientSendToSpawn", ClientSendToSpawn);
}

public int ClientSendToSpawn(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(!IsClientValid(client))
		return -1;
	Spawn(client);
	
	return -1;
}

public void rp_OnClientSpawn(int client)
{
	if (rp_GetClientInt(client, i_timeJail) > 0)
		TeleportEntity(client, view_as<float>({ 1307.694702, 1422.525756, -191.968750}), NULL_VECTOR, NULL_VECTOR);
	else
		Spawn(client);
}

public void rp_OnClientDeath(int attacker, int client, const char[] weapon, bool headshot)
{
	if(!IsModelPrecached("sprites/blueglow1.vmt"))
		PrecacheModel("sprites/blueglow1.vmt");
	int ent = CreateEntityByName("env_sprite");
	DispatchKeyValue(ent, "renderamt", "255");
	DispatchKeyValue(ent, "rendercolor", "255 255 255");
	DispatchKeyValue(ent, "rendermode", "3");
	DispatchKeyValue(ent, "model", "sprites/blueglow1.vmt");
	DispatchSpawn(ent);
	SetEntityModel(ent, "sprites/blueglow1.vmt");
	
	float position[3];
	GetClientAbsOrigin(client, position);
	position[2] += 32.0;
	TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
	
	if (rp_GetClientInt(client, i_timeJail) > 0)
		TeleportEntity(client, view_as<float>({ 1307.694702, 1422.525756, -191.968750}), NULL_VECTOR, NULL_VECTOR);
	else
		Spawn(client);
}

public Action Command_Out(int client, int args) 
{
	int aim = GetAimEnt(client, true);
	if(IsValidEntity(aim)) 
	{
		if (Distance(client, aim) <= 100)
		{
			if(isZoneProprietaire(client))
				Out(client, aim);
			else
				CPrintToChat(client, "%s Vous n'êtes pas dans votre zone appropriée / vous n'avez pas la permission.", NAME);
		}	
		else
			CPrintToChat(client, "%s Vous devez vous rapprocher de la personne.", NAME);		
	}
	else
		CPrintToChat(client, "%s Vous devez viser une personne.", NAME);
}

int Out(int client, int target) {
	char buff[256];
	Format(buff, sizeof(buff), "SELECT pos_x, pos_y, pos_z FROM rp_out WHERE Id = %i;", rp_GetClientInt(client, i_Job));
	DBResultSet query = SQL_Query(g_DB, buff);
	
	float position[3];
	
	if(query)
	{
		while (query.FetchRow())
		{
			position[0] = query.FetchFloat(0);
			position[1] = query.FetchFloat(1);
			position[2] = query.FetchFloat(2);
		}	
	}
	delete query;
	
	TeleportEntity(target, position, NULL_VECTOR, NULL_VECTOR);
}	

int Spawn(int client) {
	char buff[256];
	Format(buff, sizeof(buff), "SELECT pos_x, pos_y, pos_z FROM rp_spawns WHERE Id = %i;", rp_GetClientInt(client, i_Job));
	DBResultSet query = SQL_Query(g_DB, buff);
	
	float position[3];
	
	if(query)
	{
		while (query.FetchRow())
		{
			position[0] = query.FetchFloat(0);
			position[1] = query.FetchFloat(1);
			position[2] = query.FetchFloat(2);
		}	
	}
	delete query;
	
	TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}

stock bool isZoneProprietaire(int client)
{
	int jobid = rp_GetClientInt(client, i_Job);
	char zone[128];
	Zone_getMostRecentActiveZone(client, zone);
	
	if(jobid == 1 && StrContains(zone, "R.V.P.D") != -1)
		return true;
	else if(jobid == 2 && StrContains(zone, "Japonaise") != -1)
		return true;
	else if(jobid == 3 && StrContains(zone, "18th") != -1)
		return true;	
	else if(jobid == 4 && StrContains(zone, "Hôpital") != -1)
		return true;	
	else if(jobid == 5 && StrEqual(zone, "Mairie"))
		return true;	
	else if(jobid == 6 && StrContains(zone, "Armu") != -1)
		return true;
	else if(jobid == 7 && StrEqual(zone, "Justice"))
		return true;
	else if(jobid == 8 && StrContains(zone, "immo") != -1)
		return true;
	else if(jobid == 9 && StrContains(zone, "dealer") != -1)
		return true;
	else if(jobid == 10 && StrContains(zone, "tech") != -1)
		return true;	
	else if(jobid == 11 && StrContains(zone, "banque") != -1)
		return true;
	else if(jobid == 12 && StrContains(zone, "Assassin") != -1)
		return true;
	else if(jobid == 13 && StrEqual(zone, "Marché Noir"))
		return true;	
	else if(jobid == 14 && StrEqual(zone, "Tabac"))
		return true;	
	else if(jobid == 15 && StrEqual(zone, "McDonald's"))
		return true;	
	else
		return false;
}		