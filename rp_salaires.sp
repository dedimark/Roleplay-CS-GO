#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <roleplay>

#pragma newdecls required

char dbconfig[] = "roleplay";
Database g_DB;

char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "[Roleplay] Salaire",
	author = "Benito",
	description = "Système salaire pour les métiers",
	version = "1.0",
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/rp_salaires.log");
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
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
		
		Format(buffer, sizeof(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_salaires` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `job` int(2) NOT NULL, \
		  `grade` int(1) NOT NULL, \
		  `salaire` int(100) NOT NULL DEFAULT '50', \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPostAdminCheck(int client) 
{	
	SQLCALLBACK_LoadSalaire(client);
}

public void SQLCALLBACK_LoadSalaire(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(buffer, sizeof(buffer), "SELECT salaire FROM rp_salaires WHERE grade = %i AND job = %i;", rp_GetClientInt(client, i_Grade), rp_GetClientInt(client, i_Job));
	LogToFile(logFile, buffer);
	g_DB.Query(SQLLoadAdminQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadAdminQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Salaire, SQL_FetchIntByName(Results, "salaire"));
		if(rp_GetClientInt(client, i_Salaire) < 0)
			rp_SetClientInt(client, i_Salaire, 0);
	}
} 

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_InitSalaire", InitSalaire);
}

public int InitSalaire(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(!IsClientValid(client))
		return -1;
	SQLCALLBACK_LoadSalaire(client);
	
	return -1;
}