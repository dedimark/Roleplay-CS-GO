/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://www.lastfate.fr - benitalpa1020@gmail.com
*/

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							C O M P I L E  -  O P T I O N S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N C L U D E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <roleplay>

#define MAXJOBS 20

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
 
							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
char dbconfig[] = "roleplay";
Database g_DB;
Handle update_api[MAXPLAYERS + 1] = { null, ... };
char steamID[MAXPLAYERS + 1][32];
int playedTime[MAXPLAYERS + 1];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] API - DATA",
	author = "Benito",
	description = "Système A.P.I pour le panel RP",
	version = VERSION,
	url = URL
};

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  E V E N T S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		Database.Connect(GotDatabase, dbconfig);
		RegConsoleCmd("api_jobs", Cmd_Jobs);
	}	
	else
		UnloadPlugin();
}

public Action Cmd_Jobs(int client, int args)
{
	InsertToApiJobs();
}	

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("DatabaseError", error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		char buffer[4096];	
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `api_players` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `tokens` int(100) NOT NULL, \
		  `money` int(100) NOT NULL, \
		  `bank` int(100) NOT NULL, \
		  `salaire` int(100) NOT NULL, \
		  `adminlevel` int(2) NOT NULL, \
		  `vitality` int(100) NOT NULL, \
		  `kills` int(100) NOT NULL, \
		  `morts` int(100) NOT NULL, \
		  `tempsInGame` int(100) NOT NULL, \
		  `vipTime` int(100) NOT NULL, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
		
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `api_jobs` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `jobname` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `capital` int(100) NOT NULL, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`jobname`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
		
		
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `api_jobs_grade` ( \
		  `rankID` int(100) NOT NULL AUTO_INCREMENT, \
		  `jobID` int(2) NOT NULL, \
		  `gradeID` int(1) NOT NULL, \
		  `gradeName` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `drawJobName` int(1) NOT NULL, \
		  PRIMARY KEY (`rankID`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
		
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `api_vente` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `acheteur` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `vendeur` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `item` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `prix_unit` int(100) NOT NULL, \
		  `quantite` int(100) NOT NULL, \
		  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, \
		  `jobID` int(10) NOT NULL, \
		  PRIMARY KEY (`Id`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}

public void OnMapStart()
{
	//InsertToApiJobs();
}	

public void OnMapEnd()
{
	LoopClients(client)
		UpdateSQL(g_DB, "UPDATE api_players SET tempsInGame = %i WHERE steamid = '%s';", GetClientTime(client) + playedTime[client], steamID[client]);
}	

public void OnClientPostAdminCheck(int client) 
{	
	API_LOAD_SQL(client);
}

public void API_LOAD_SQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT tempsInGame FROM api_players WHERE steamid = '%s';", steamID[client]);
	g_DB.Query(SQLLoadDealerQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadDealerQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		playedTime[client] += SQL_FetchIntByName(Results, "tempsInGame");
	}
} 

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPutInServer(int client) {	
	update_api[client] = CreateTimer(10.0, updateSQL, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);		
	CreateTimer(5.0, InsertToDB, client, TIMER_FLAG_NO_MAPCHANGE);	
	//CreateTimer(1.0, UpgradePlayedTime, client, TIMER_REPEAT);
}

public Action UpgradePlayedTime(Handle Timer, any client)
{
	if (IsClientInGame(client))
	{
		playedTime[client]++;
	}
}	

public void rp_OnClientDisconnect(int client) {
	TrashTimer(update_api[client], true);
	UpdateSQL(g_DB, "UPDATE api_players SET tempsInGame = %i WHERE steamid = '%s';", GetClientTime(client) + playedTime[client], steamID[client]);		
}

public Action InsertToDB(Handle Timer) 
{
	LoopClients(client)
	{		
		if (IsClientValid(client))
		{			
			char name[64];
			GetClientName(client, STRING(name));
			
			char buffer[2048];
			Format(STRING(buffer), "INSERT IGNORE INTO `api_players` (`Id`, `steamid`, `playername`, `tokens`, `money`, `bank`, `salaire`, `adminlevel`, `vitality`, `kills`, `morts`, `tempsInGame`, `vipTime`) VALUES (NULL, '%s', '%s', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);", steamID[client], name);
			SQL_FastQuery(g_DB, buffer);
		}	
	}
}	

public Action updateSQL(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) 
	{		
		if (IsClientValid(client))
		{			
			int money = rp_GetClientInt(client, i_Money);
			int bank = rp_GetClientInt(client, i_Bank);
			int salaire = rp_GetClientInt(client, i_Salaire);
			int vipTime = rp_GetClientInt(client, i_VipTime);
			float vitality = rp_GetClientFloat(client, fl_Vitality);
			
			UpdateSQL(g_DB, "UPDATE api_players SET money = %i, bank = %i, salaire = %i, vitality = %i, vipTime = %i WHERE steamid = '%s';", money, bank, salaire, vitality, vipTime, steamID[client]);			
		}	
		else if (!IsClientValid(client))
			TrashTimer(update_api[client], true);
	}
}

public void rp_OnClientDeath(int attacker, int victim, const char[] weapon, bool headshot)
{
	UpdateSQL(g_DB, "UPDATE api_players SET morts = morts + 1 WHERE steamid = '%s';", steamID[victim]);
	UpdateSQL(g_DB, "UPDATE api_players SET kills = kills + 1 WHERE steamid = '%s';", steamID[attacker]);
}	

public void InsertToApiJobs()
{
	for(int i = 1; i <= MAXJOBS; i++)
	{
		KeyValues kv = new KeyValues("Jobs");

		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
		
		if(!kv.ImportFromFile(sPath))
		{
			delete kv;
			PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
		}	
		
		char jobString[32];
		IntToString(i, STRING(jobString));
		if(!kv.JumpToKey(jobString))
			return;
		kv.JumpToKey("jobname");
		
		char jobname[64];
		kv.GetString("name", STRING(jobname));
		kv.GoBack();
		
		kv.JumpToKey("capital");		
		int capital = kv.GetNum("total");
		kv.GoBack();
		
		char buffer[PLATFORM_MAX_PATH];
		Format(STRING(buffer), "INSERT IGNORE INTO `api_jobs` (`Id`, `jobname`, `capital`) VALUES ('%i', '%s', '%i');", i, jobname, capital);
		SQL_FastQuery(g_DB, buffer);
		
		kv.JumpToKey("grades");
		int maxgrades = kv.GetNum("max");
		kv.GoBack();
		
		char gradeName[16];
		for(int x = 1; x <= maxgrades; x++)
		{
			char gradeString[2];
			IntToString(x, STRING(gradeString));
			kv.JumpToKey(gradeString);
			kv.GetString("grade", STRING(gradeName));
			kv.GoBack();
			
			Format(STRING(buffer), "INSERT IGNORE INTO `api_jobs_grade` (`rankID`, `jobID`, `gradeID`, `gradeName`, `drawJobName`) VALUES ('', '%i', '%i', '%s', '1');", i, x, gradeName);
			SQL_FastQuery(g_DB, buffer);
		}	
		
		kv.Rewind();	
		delete kv;
	}
}	