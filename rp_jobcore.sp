#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <roleplay>

#define MAXJOBS 15

#pragma newdecls required

Database g_DB;
char dbconfig[] = "roleplay";
char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];

int capital[MAXJOBS+1];

public Plugin myinfo = 
{
	name = "[Roleplay] Native Register", 
	author = "Benito", 
	description = "Enregistreur des natives", 
	version = "1.0", 
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/rp_jobcore.log");
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}	

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("%T: %s", "DatabaseError", LANG_SERVER, error);
	} 
        else 
        {
		db.SetCharset("utf8");
		g_DB = db;
		
		char buffer[4096];
		Format(buffer, sizeof(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_jobs` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `jobid` int(10) NOT NULL, \
		  `gradeid` int(10) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		LogToFile(logFile, buffer);
		g_DB.Query(SQLErrorCheckCallback, buffer);
		
		Format(buffer, sizeof(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_capitals` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `jobname` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `capital` int(10) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `jobname` (`jobname`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		LogToFile(logFile, buffer);
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_GetJobCapital", GetJobCapital);
	CreateNative("rp_SetJobCapital", SetJobCapital);
}

public int GetJobCapital(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	
	return capital[job];
}

public int SetJobCapital(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	int value = GetNativeCell(2);
	
	return capital[job] = value;
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	char buffer[2048];
	Format(buffer, sizeof(buffer), "INSERT IGNORE INTO `rp_jobs` (`Id`, `steamid`, `playername`, `jobid`, `gradeid`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadJobs(client);
}

public void SQLCALLBACK_LoadJobs(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(buffer, sizeof(buffer), "SELECT jobid, gradeid FROM rp_jobs WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(SQLLoadJobsQueryCallback, buffer, GetClientUserId(client));
	
	for(int i = 1; i <= MAXJOBS+1; i++)
	{
		Format(buffer, sizeof(buffer), "SELECT capital FROM rp_capitals WHERE Id = %i;", i);
		g_DB.Query(SQLLoadCapitalsQueryCallback, buffer, GetClientUserId(client));
	}	
}

public void SQLLoadJobsQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Job, SQL_FetchIntByName(Results, "jobid"));		
		rp_SetClientInt(client, i_Grade, SQL_FetchIntByName(Results, "gradeid"));
	}
} 

public void SQLLoadCapitalsQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	while (Results.FetchRow()) 
	{
		for(int i = 1; i <= MAXJOBS+1; i++)
		{
			if(i != MAXJOBS+1)
				capital[i] = SQL_FetchIntByName(Results, "capital");
		}		
	}
}