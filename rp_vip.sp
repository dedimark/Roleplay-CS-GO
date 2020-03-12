#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <roleplay>
#include <smlib>

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"

#pragma newdecls required

char 
	logFile[PLATFORM_MAX_PATH],
	steamID[MAXPLAYERS+1][32],
	dbconfig[] = "roleplay";
	
Database g_DB;

public Plugin myinfo = 
{
	name = "[Roleplay] VIP",
	author = "Benito",
	description = "Système de VIP pour le serveur",
	version = "1.0",
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/rp_vip.log");		
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
		"CREATE TABLE IF NOT EXISTS `rp_vips` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `viptime` int(11) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
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
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	char buffer[2048];
	Format(buffer, sizeof(buffer), "INSERT IGNORE INTO `rp_vips` (`Id`, `steamid`, `playername`, `viptime`, `timestamp`) VALUES (NULL, '%s', '%s', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadVips(client);
}

public void SQLCALLBACK_LoadVips(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(buffer, sizeof(buffer), "SELECT viptime FROM rp_vips WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(SQLLoadVipQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadVipQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_VipTime, SQL_FetchIntByName(Results, "viptime"));
		if(rp_GetClientInt(client, i_VipTime) < 0)
			rp_SetClientInt(client, i_VipTime, 0);
	}
} 

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}