/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://vr-hosting.fr - benitalpa1020@gmail.com
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
#include <sdkhooks>
#include <smlib>
#include <unixtime_sourcemod>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
Database g_DB;

Handle Timer_AppartHUD[MAXPLAYERS+1] = { null, ... };

char dbconfig[] = "roleplay";
char logFile[PLATFORM_MAX_PATH];
char steamID[MAXPLAYERS + 1][32];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Système d'appartement",
	author = "Benito",
	description = "Système Appartement",
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
		GameCheck();
		
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_appartement.log");
		Database.Connect(GotDatabase, dbconfig);
		RegConsoleCmd("loyer", Cmd_Loyer);
	}
	else
		UnloadPlugin();
}	

public Action Cmd_Loyer(int client, int args)
{
	char strTime[64];
	StringTime(rp_GetClientInt(client, i_loyer), STRING(strTime));				
	CPrintToChat(client, "%s Loyer: %s", TEAM, strTime);
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
		"CREATE TABLE IF NOT EXISTS `rp_appartements` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `appartement` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `proprietaire` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `prix` int(100) NOT NULL, \
		  `loyer` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `appartement` (`appartement`) \
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
	LoadLoyer(client);
}

public void LoadLoyer(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT loyer FROM rp_appartements WHERE proprietaire = '%s'", steamID[client]);
	g_DB.Query(LoadLoyerCallback, buffer, GetClientUserId(client));
}

public void LoadLoyerCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_loyer, SQL_FetchIntByName(Results, "loyer"));
	}
}

public void OnClientPutInServer(int client) {	
	Timer_AppartHUD[client] = CreateTimer(1.0, update, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

public void OnClientDisconnect(int client)
{
	if(rp_GetClientInt(client, i_appartement) != 0)
	{
		if(rp_GetClientInt(client, i_appartement) == 301)
		{
			char sql[2048];
			Format(STRING(sql), "UPDATE rp_appartements SET loyer = %i WHERE appartement = 'appart_0301';", rp_GetClientInt(client, i_loyer));
			SQL_FastQuery(g_DB, sql);
		}
		else
		{		
			char strAppart[16];
			IntToString(rp_GetClientInt(client, i_appartement), STRING(strAppart));
			
			char appartement[32] = "appart_x";
			ReplaceString(STRING(appartement), "x", strAppart);
			
			char sql[2048];
			Format(STRING(sql), "UPDATE rp_appartements SET proprietaire = 'none' WHERE appartement = '%s';", appartement);
			SQL_FastQuery(g_DB, sql);
			
			rp_SetClientInt(client, i_appartement, 0);
		}	
	}	
	
	TrashTimer(Timer_AppartHUD[client], true);
}		

public Action update(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) 
	{		
		if (IsClientValid(client))
		{			
			if(rp_GetClientInt(client, i_loyer) > 0)
				rp_SetClientInt(client, i_loyer, rp_GetClientInt(client, i_loyer) - 1);
			
			int aim = GetAimEnt(client, false);
			
			char entName[64], HudMSG[128];
			
			if(IsValidEntity(aim))
				Entity_GetName(aim, STRING(entName));
		
			if(StrContains(entName, "appart_") != -1 || StrContains(entName, "InstanceAuto6-bbc_") != -1 && !StrEqual(entName, "appart_8") && Distance(client, aim) < 200)
			{
				char strAppart[2][64];		
				ExplodeString(entName, "_", strAppart, 2, 64);
				
				int owner = rp_GetAppartementOwner(g_DB, entName);
				
				if(owner == 0)
					Format(STRING(HudMSG), "Appartement: № <font color='#ff0000'>%i</font>\nPropriétaire: <font color='#c3ed05'>Aucun</font>", StringToInt(strAppart[1]));	
				else
				{
					if(client == owner && StrContains(entName, "appart_0301") != -1)
					{
						char strTime[64];
						StringTime(rp_GetClientInt(client, i_loyer), STRING(strTime));
						
						Format(STRING(HudMSG), "<font color='#ff0000'>Villa</font>\nPropriétaire: <font color='#c3ed05'>%N</font>\nLoyer: %s", owner, strTime);
					}	
					else
						Format(STRING(HudMSG), "Appartement: № <font color='#ff0000'>%i</font>\nPropriétaire: <font color='#c3ed05'>%N</font>", StringToInt(strAppart[1]), owner);	
				}	
					
				PrintHintText(client, HudMSG);	
			}	
		}	
		else if (!IsClientValid(client)) {
			TrashTimer(Timer_AppartHUD[client], true);
		}
	}
}