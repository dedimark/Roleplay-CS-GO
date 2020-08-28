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

/***************************************************************************************

							C O M P I L E  -  O P T I O N S

***************************************************************************************/
#pragma semicolon 1
#pragma newdecls required

/***************************************************************************************

							P L U G I N  -  I N C L U D E S

***************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <cstrike>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char logFile[PLATFORM_MAX_PATH];
char dbconfig[] = "roleplay";
char steamID[MAXPLAYERS + 1][32];
Database g_DB;
Handle timerVestiaires[MAXPLAYERS+1] = { null, ... };
bool isInVestiaireMenu[MAXPLAYERS + 1] = false;
bool canTestSkin[MAXPLAYERS + 1] = true;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Vendeur de skin", 
	author = "Benito", 
	description = "Métier Vendeur de skin", 
	version = VERSION, 
	url = URL
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/jobs/rp_job_VendeurDeSkin.log");
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
		return;
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		char buffer[4096];
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_vendeurdeskin` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `skin1` int(100) NOT NULL, \
		  `skin2` int(100) NOT NULL, \
		  `skin3` int(100) NOT NULL, \
		  `skin4` int(100) NOT NULL, \
		  `skin5` int(100) NOT NULL, \
		  `skin6` int(100) NOT NULL, \
		  `skin7` int(100) NOT NULL, \
		  `skin8` int(100) NOT NULL, \
		  `skin9` int(100) NOT NULL, \
		  `skin10` int(100) NOT NULL, \
		  `skin11` int(100) NOT NULL, \
		  `skin12` int(100) NOT NULL, \
		  `skin13` int(100) NOT NULL, \
		  `skin14` int(100) NOT NULL, \
		  `skin15` int(100) NOT NULL, \
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
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_vendeurdeskin` (`Id`, `steamid`, `playername`, `skin1`, `skin2`, `skin3`, `skin4`, `skin5`, `skin6`, `skin7`, `skin8`, `skin9`, `skin10`, `skin11`, `skin12`, `skin13`, `skin14`, `skin15`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	LoadSkinsSQL(client);
}

public Action rp_reloadData()
{
	LoopClients(i)
	{
		LoadSkinsSQL(i);
	}	
}

public void LoadSkinsSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_vendeurdeskin WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(LoadCallBackSQL, buffer, GetClientUserId(client));
}

public void LoadCallBackSQL(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientItem(client, i_skin1, SQL_FetchIntByName(Results, "skin1"));
		rp_SetClientItem(client, i_skin2, SQL_FetchIntByName(Results, "skin2"));
		rp_SetClientItem(client, i_skin3, SQL_FetchIntByName(Results, "skin3"));
		rp_SetClientItem(client, i_skin4, SQL_FetchIntByName(Results, "skin4"));
		rp_SetClientItem(client, i_skin5, SQL_FetchIntByName(Results, "skin5"));
		rp_SetClientItem(client, i_skin6, SQL_FetchIntByName(Results, "skin6"));
		rp_SetClientItem(client, i_skin7, SQL_FetchIntByName(Results, "skin7"));
		rp_SetClientItem(client, i_skin8, SQL_FetchIntByName(Results, "skin8"));
		rp_SetClientItem(client, i_skin9, SQL_FetchIntByName(Results, "skin9"));
		rp_SetClientItem(client, i_skin10, SQL_FetchIntByName(Results, "skin10"));
		rp_SetClientItem(client, i_skin11, SQL_FetchIntByName(Results, "skin11"));
		rp_SetClientItem(client, i_skin12, SQL_FetchIntByName(Results, "skin12"));
		rp_SetClientItem(client, i_skin13, SQL_FetchIntByName(Results, "skin13"));
		rp_SetClientItem(client, i_skin14, SQL_FetchIntByName(Results, "skin14"));
		rp_SetClientItem(client, i_skin15, SQL_FetchIntByName(Results, "skin15"));
	}
}

/************************************************/
/***************** Global Forwards *****************/

public Action rp_MenuInventory(int client, Menu menu)
{
	char amount[128];
	
	//menu.AddItem("", "⁂ Skins ⁂", ITEMDRAW_DISABLED);
	
	if(rp_GetClientItem(client, i_skin1) >= 1)
	{
		Format(STRING(amount), "Nick [%i]", rp_GetClientItem(client, i_skin1));
		menu.AddItem("skin1", amount);
	}
	if(rp_GetClientItem(client, i_skin2) >= 1)
	{
		Format(STRING(amount), "Phoenix [%i]", rp_GetClientItem(client, i_skin2));
		menu.AddItem("skin2", amount);
	}
	if(rp_GetClientItem(client, i_skin3) >= 1)
	{
		Format(STRING(amount), "Miyu [%i]", rp_GetClientItem(client, i_skin3));
		menu.AddItem("skin3", amount);
	}
	if(rp_GetClientItem(client, i_skin4) >= 1)
	{
		Format(STRING(amount), "Natalia [%i]", rp_GetClientItem(client, i_skin4));
		menu.AddItem("skin4", amount);
	}
	if(rp_GetClientItem(client, i_skin5) >= 1)
	{
		Format(STRING(amount), "Coach [%i]", rp_GetClientItem(client, i_skin5));
		menu.AddItem("skin5", amount);
	}
	if(rp_GetClientItem(client, i_skin6) >= 1)
	{
		Format(STRING(amount), "Le Marseillais [%i]", rp_GetClientItem(client, i_skin6));
		menu.AddItem("skin6", amount);
	}
	if(rp_GetClientItem(client, i_skin7) >= 1)
	{
		Format(STRING(amount), "Leeti [%i]", rp_GetClientItem(client, i_skin7));
		menu.AddItem("skin7", amount);
	}
	if(rp_GetClientItem(client, i_skin8) >= 1)
	{
		Format(STRING(amount), "Negan [%i]", rp_GetClientItem(client, i_skin8));
		menu.AddItem("skin8", amount);
	}
	if(rp_GetClientItem(client, i_skin9) >= 1)
	{
		Format(STRING(amount), "Captain Price [%i]", rp_GetClientItem(client, i_skin9));
		menu.AddItem("skin9", amount);
	}
	if(rp_GetClientItem(client, i_skin10) >= 1)
	{
		Format(STRING(amount), "Macri [%i]", rp_GetClientItem(client, i_skin10));
		menu.AddItem("skin10", amount);
	}
	if(rp_GetClientItem(client, i_skin11) >= 1)
	{
		Format(STRING(amount), "Engel [%i]", rp_GetClientItem(client, i_skin11));
		menu.AddItem("skin11", amount);
	}
	if(rp_GetClientItem(client, i_skin12) >= 1)
	{
		Format(STRING(amount), "Donald Trump [%i]", rp_GetClientItem(client, i_skin12));
		menu.AddItem("skin12", amount);
	}
	if(rp_GetClientItem(client, i_skin13) >= 1)
	{
		Format(STRING(amount), "Niko Bellic [%i]", rp_GetClientItem(client, i_skin13));
		menu.AddItem("skin13", amount);
	}
	if(rp_GetClientItem(client, i_skin14) >= 1)
	{
		Format(STRING(amount), "Zoey [%i]", rp_GetClientItem(client, i_skin14));
		menu.AddItem("skin14", amount);
	}
	if(rp_GetClientItem(client, i_skin15) >= 1)
	{
		Format(STRING(amount), "Marcus Reed [%i]", rp_GetClientItem(client, i_skin15));
		menu.AddItem("skin15", amount);
	}
}	
	
public int rp_HandlerMenuInventory(int client, char[] info)
{
	char currentSkin[256];
	rp_GetClientString(client, sz_Skin, currentSkin, 256);
	
	if(StrEqual(info, "skin1") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/l4d2/nick/nickv2.mdl"))
		{
			rp_SetClientItem(client, i_skin1, rp_GetClientItem(client, i_skin1) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin1), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/l4d2/nick/nickv2.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kuristaja/l4d2/nick/nickv2.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Nick.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Nick.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Nick{default}.", TEAM);
	}
	else if(StrEqual(info, "skin2") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/cso2/phoenix/phoenix.mdl"))
		{
			rp_SetClientItem(client, i_skin2, rp_GetClientItem(client, i_skin2) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin2), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/cso2/phoenix/phoenix.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/phoenix/phoenix.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Phoenix.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Phoenix.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Phoenix{default}.", TEAM);
	}
	else if(StrEqual(info, "skin3") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/cso2/miyu_schoolgirl/miyu.mdl"))
		{
			rp_SetClientItem(client, i_skin3, rp_GetClientItem(client, i_skin3) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin3), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/cso2/miyu_schoolgirl/miyu.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/miyu_schoolgirl/miyu.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Miyu.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Miyu.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Miyu{default}.", TEAM);
	}
	else if(StrEqual(info, "skin4") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/cso2/natalie/natalie.mdl"))
		{
			rp_SetClientItem(client, i_skin4, rp_GetClientItem(client, i_skin4) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin4), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/cso2/natalie/natalie.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/natalie/natalie.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Natalia.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Natalia.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Natalia{default}.", TEAM);
	}
	else if(StrEqual(info, "skin5") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/l4d2/coach/coachv2.mdl"))
		{
			rp_SetClientItem(client, i_skin5, rp_GetClientItem(client, i_skin5) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin5), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/l4d2/coach/coachv2.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kuristaja/l4d2/coach/coachv2.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Coach.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Coach.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Coach{default}.", TEAM);
	}
	else if(StrEqual(info, "skin6") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kirby/kirbys_robber/kirbys_robber2.mdl"))
		{
			rp_SetClientItem(client, i_skin6, rp_GetClientItem(client, i_skin6) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin6), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kirby/kirbys_robber/kirbys_robber2.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kirby/kirbys_robber/kirbys_robber2.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue du {lightblue}Marseillais.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue du Marseillais.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue du {lightred}Marseillais{default}.", TEAM);
	}
	else if(StrEqual(info, "skin7") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kirby/leetkumla/leetkumla.mdl"))
		{
			rp_SetClientItem(client, i_skin7, rp_GetClientItem(client, i_skin7) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin7), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kirby/leetkumla/leetkumla.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kirby/leetkumla/leetkumla.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Leeti.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Leeti.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Leeti{default}.", TEAM);
	}
	else if(StrEqual(info, "skin8") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kodua/negan/negan.mdl"))
		{
			rp_SetClientItem(client, i_skin8, rp_GetClientItem(client, i_skin8) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin8), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kodua/negan/negan.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kodua/negan/negan.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Negan.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Negan.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Negan{default}.", TEAM);
	}
	else if(StrEqual(info, "skin9") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/eminem/cod2/captain_price.mdl"))
		{
			rp_SetClientItem(client, i_skin9, rp_GetClientItem(client, i_skin9) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin9), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/eminem/cod2/captain_price.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/eminem/cod2/captain_price.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Captain Price.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Captain Price.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Captain Price{default}.", TEAM);
	}
	else if(StrEqual(info, "skin10") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/ventoz/macri/macrii.mdl"))
		{
			rp_SetClientItem(client, i_skin10, rp_GetClientItem(client, i_skin10) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin10), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/ventoz/macri/macrii.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/ventoz/macri/macrii.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Macri.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Macri.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Macri{default}.", TEAM);
	}
	else if(StrEqual(info, "skin11") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/caleon1/sigrun_engel/sigrun_engel_v3.mdl"))
		{
			rp_SetClientItem(client, i_skin11, rp_GetClientItem(client, i_skin11) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin11), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/caleon1/sigrun_engel/sigrun_engel_v3.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/caleon1/sigrun_engel/sigrun_engel_v3.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Engel.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Engel.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Engel{default}.", TEAM);
	}
	else if(StrEqual(info, "skin12") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/trump/trump.mdl"))
		{
			rp_SetClientItem(client, i_skin12, rp_GetClientItem(client, i_skin12) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin12), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/trump/trump.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/kuristaja/trump/trump.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Donald Trump.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Donald Trump.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Donald Trump{default}.", TEAM);
	}
	else if(StrEqual(info, "skin13") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/voikanaa/gtaiv/niko.mdl"))
		{
			rp_SetClientItem(client, i_skin13, rp_GetClientItem(client, i_skin13) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin12), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/voikanaa/gtaiv/niko.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/voikanaa/gtaiv/niko.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Niko Bellic.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Niko Bellic.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Niko Bellic{default}.", TEAM);
	}
	else if(StrEqual(info, "skin14") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/natalya/zoeys/zoey_red.mdl"))
		{
			rp_SetClientItem(client, i_skin14, rp_GetClientItem(client, i_skin14) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin14), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/natalya/zoeys/zoey_red.mdl", 256);
			rp_SetSkin(client, "models/player/natalya/zoeys/zoey_red.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Zoey.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Zoey.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Zoey{default}.", TEAM);
	}
	else if(StrEqual(info, "skin15") && IsPlayerAlive(client))
	{
		if(!StrEqual(currentSkin, "models/player/custom_player/hekut/marcusreed/marcusreed.mdl"))
		{
			rp_SetClientItem(client, i_skin15, rp_GetClientItem(client, i_skin15) - 1);
			SetSQL_Int(g_DB, "rp_vendeurdeskin", info, rp_GetClientItem(client, i_skin15), steamID[client]);
				
			rp_SetClientString(client, sz_Skin, "models/player/custom_player/hekut/marcusreed/marcusreed.mdl", 256);
			rp_SetSkin(client, "models/player/custom_player/hekut/marcusreed/marcusreed.mdl");
			
			CreateTimer(1.0, View3rd, client);
			
			CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Marcus Reed.", TEAM);
			LogToFile(logFile, "Le joueur %N porte désormais la tenue de Marcus Reed.", client);
		}	
		else
			CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Marcus Reed{default}.", TEAM);
	}
}	

/************************************************/
/******************** TIMERS *******************/

public Action View3rd(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		if(!Client_IsInThirdPersonMode(client))
		{
			CreateTimer(5.0, View3rd, client);	
			Client_SetThirdPersonMode(client, true);
		}	
		else
			Client_SetThirdPersonMode(client, false);
	}
}	
/************************************************/
/******************** Vestiaires *******************/

public void OnClientPutInServer(int client) {	
	timerVestiaires[client] = CreateTimer(1.0, update, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

public void OnClientDisconnect(int client) {
	delete timerVestiaires[client];
}

public Action update(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) 
	{		
		if (IsClientValid(client))
		{			
			if(DolceGabanna_Vestiaires(client) && !isInVestiaireMenu[client])
				VestiairesMenu(client);
			
		}	
		else if (!IsClientValid(client)) {
			TrashTimer(timerVestiaires[client], true);
		}
	}
}

Menu VestiairesMenu(int client)
{
	if(DolceGabanna_Vestiaires(client))
	{
		rp_SetClientBool(client, b_menuOpen, true);
		isInVestiaireMenu[client] = true;
		Menu menu = new Menu(DoVestiairesMenu);
		menu.SetTitle("Dolce & Gabbana \n Test de Skins");
		
		if(canTestSkin[client])
		{
			menu.AddItem("skin1", "Nick");
			menu.AddItem("skin2", "Phoenix");
			menu.AddItem("skin3", "Miyu");
			menu.AddItem("skin4", "Natalia");
			menu.AddItem("skin5", "Coach");
			menu.AddItem("skin6", "Le Marseillais");
			menu.AddItem("skin7", "Leeti");
			menu.AddItem("skin8", "Negan");
			menu.AddItem("skin9", "Captain Price");
			menu.AddItem("skin10", "Macri");
			menu.AddItem("skin11", "Engel");
			menu.AddItem("skin12", "Donald Trump");
			menu.AddItem("skin13", "Niko Bellic");
			menu.AddItem("skin14", "Zoey");
			menu.AddItem("skin15", "Marcus Reed");
		}
		else
		{
			menu.AddItem("skin1", "Nick", ITEMDRAW_DISABLED);
			menu.AddItem("skin2", "Phoenix", ITEMDRAW_DISABLED);
			menu.AddItem("skin3", "Miyu", ITEMDRAW_DISABLED);
			menu.AddItem("skin4", "Natalia", ITEMDRAW_DISABLED);
			menu.AddItem("skin5", "Coach", ITEMDRAW_DISABLED);
			menu.AddItem("skin6", "Le Marseillais", ITEMDRAW_DISABLED);
			menu.AddItem("skin7", "Leeti", ITEMDRAW_DISABLED);
			menu.AddItem("skin8", "Negan", ITEMDRAW_DISABLED);
			menu.AddItem("skin9", "Captain Price", ITEMDRAW_DISABLED);
			menu.AddItem("skin10", "Macri", ITEMDRAW_DISABLED);
			menu.AddItem("skin11", "Engel", ITEMDRAW_DISABLED);
			menu.AddItem("skin12", "Donald Trump", ITEMDRAW_DISABLED);
			menu.AddItem("skin13", "Niko Bellic", ITEMDRAW_DISABLED);
			menu.AddItem("skin14", "Zoey", ITEMDRAW_DISABLED);
			menu.AddItem("skin15", "Marcus Reed", ITEMDRAW_DISABLED);
		}		
				
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
		rp_SetClientBool(client, b_menuOpen, false);
}	

public int DoVestiairesMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		char currentSkin[256];
		Entity_GetModel(client, currentSkin, sizeof(currentSkin));
		
		DataPack pack;
		CreateDataTimer(5.0, ResetData, pack);
		pack.WriteCell(client);
		pack.WriteString(currentSkin);
		
		if(StrEqual(info, "skin1") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kuristaja/l4d2/nick/nickv2.mdl");				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Nick.", TEAM);
		}
		else if(StrEqual(info, "skin2") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/phoenix/phoenix.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Phoenix.", TEAM);
		}
		else if(StrEqual(info, "skin3") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/miyu_schoolgirl/miyu.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Miyu.", TEAM);
		}
		else if(StrEqual(info, "skin4") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/natalie/natalie.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Natalya.", TEAM);
		}
		else if(StrEqual(info, "skin5") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kuristaja/l4d2/coach/coachv2.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Coach.", TEAM);
		}
		else if(StrEqual(info, "skin6") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kirby/kirbys_robber/kirbys_robber2.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue du {lightblue}Marseillais.", TEAM);
		}
		else if(StrEqual(info, "skin7") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kirby/leetkumla/leetkumla.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Leeti.", TEAM);
		}
		else if(StrEqual(info, "skin8") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kodua/negan/negan.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Negan.", TEAM);
		}
		else if(StrEqual(info, "skin9") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/eminem/cod2/captain_price.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Captain Price.", TEAM);
		}
		else if(StrEqual(info, "skin10") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/ventoz/macri/macrii.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Macri.", TEAM);
		}
		else if(StrEqual(info, "skin11") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/caleon1/sigrun_engel/sigrun_engel_v3.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Engel.", TEAM);
		}
		else if(StrEqual(info, "skin12") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/kuristaja/trump/trump.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Donald Trump.", TEAM);
		}
		else if(StrEqual(info, "skin13") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/voikanaa/gtaiv/niko.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Niko Bellic.", TEAM);
		}
		else if(StrEqual(info, "skin14") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/natalya/zoeys/zoey_red.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Zoey.", TEAM);
		}
		else if(StrEqual(info, "skin15") && IsPlayerAlive(client))
		{
			rp_SetSkin(client, "models/player/custom_player/hekut/marcusreed/marcusreed.mdl"); 				
			CreateTimer(1.0, View3rd, client);
			CPrintToChat(client, "%s Vous testez désormais la tenue de {lightblue}Marcus Reed.", TEAM);
		}
		isInVestiaireMenu[client] = false;
		canTestSkin[client] = false;
		CreateTimer(5.0, ReDrawTestSkin, client);	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
		{
			rp_SetClientBool(client, b_menuOpen, false);
			isInVestiaireMenu[client] = false;
		}	
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}	
}

public Action ResetData(Handle timer, DataPack pack)
{
	char model[128];
	int client;
	
	pack.Reset();
	client = pack.ReadCell();
	pack.ReadString(model, sizeof(model));
	
	SetEntityModel(client, model);
}

public Action ReDrawTestSkin(Handle timer, any client)
{
	canTestSkin[client] = true;
}

bool DolceGabanna_Vestiaires(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 1071.968750 && position[0] <= 1396.968750 && position[1] >= -6640.354492 && position[1] <= -6535.354492 && position[2] >= -2011.507812 && position[2] <= -1851.507812
	|| position[0] >= 529.451171 && position[0] <= 854.451171 && position[1] >= -6634.968750 && position[1] <= -6539.968750 && position[2] >= -2011.829101 && position[2] <= -1846.829101)
		return true;
	else 
		return false;
}

/***************** NPC SYSTEM *****************/

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrEqual(entName, "Dolce & Gabbana") && Distance(client, aim) <= 80.0)
	{
		int nbVds;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(rp_GetClientInt(i, i_Job) == 14 && !rp_GetClientBool(i, b_isAfk))
					nbVds++;
			}
		}
		if(nbVds == 0 || nbVds == 1 && rp_GetClientInt(client, i_Job) == 14 || rp_GetClientInt(client, i_Job) == 14 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un vendeur de skin.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un vendeur de skin.");
		}
	}
}

int NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Dolce & Gabbana");
	menu.AddItem("skins", "Skins");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "skins"))
			SellSkins(client, client);	
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}
	
/************************************************/
/***************** Global Vente *****************/

public Action rp_MenuVendre(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 14)
	{
		menu.AddItem("skin", "Skins");
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "skin"))
		SellSkins(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellSkins(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Skins Disponibles");

	prix = rp_GetPrice("skins");
	
	Format(STRING(strFormat), "%i|%i|Nick", target, prix);
	Format(STRING(strMenu), "[SKIN] Nick (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Phoenix", target, prix);
	Format(STRING(strMenu), "[SKIN] Phoenix (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Miyu", target, prix);
	Format(STRING(strMenu), "[SKIN] Miyu (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Natalia", target, prix);
	Format(STRING(strMenu), "[SKIN] Natalia (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Coach", target, prix);
	Format(STRING(strMenu), "[SKIN] Coach (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Le Marseillais", target, prix);
	Format(STRING(strMenu), "[SKIN] Le Marseillais (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Leeti", target, prix);
	Format(STRING(strMenu), "[SKIN] Leeti (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Negan", target, prix);
	Format(STRING(strMenu), "[SKIN] Negan (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Captain Price", target, prix);
	Format(STRING(strMenu), "[SKIN] Captain Price (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Macri", target, prix);
	Format(STRING(strMenu), "[SKIN] Macri (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Engel", target, prix);
	Format(STRING(strMenu), "[SKIN] Engel (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Donald Trump", target, prix);
	Format(STRING(strMenu), "[SKIN] Donald Trump (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Niko Bellic", target, prix);
	Format(STRING(strMenu), "[SKIN] Niko Bellic (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Zoey", target, prix);
	Format(STRING(strMenu), "[SKIN] Zoey (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	Format(STRING(strFormat), "%i|%i|Marcus Reed", target, prix);
	Format(STRING(strMenu), "[SKIN] Marcus Reed (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}			

public int DoSell(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32], buffer[3][64], strQuantite[128], strFormat[64], strAppart[2][32];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		
		ExplodeString(info, "|", buffer, 3, 64);
		ExplodeString(buffer[2], "_", strAppart, 2, 32);
			
		int target = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[1]);

		/* MENU QUANTITE */
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
		for(int i = 1; i <= 10; i++)
		{			
			Format(STRING(strQuantite), "%i|%i|%s|%i", target, prix, buffer[2], i);
			Format(STRING(strFormat), "%i", i);
			quantity.AddItem(strQuantite, strFormat);
		}	
		Format(STRING(strQuantite), "%i|%i|%s|25", target, prix, buffer[2]);
		quantity.AddItem(strQuantite, "25");
		Format(STRING(strQuantite), "%i|%i|%s|50", target, prix, buffer[2]);
		quantity.AddItem(strQuantite, "50");
		Format(STRING(strQuantite), "%i|%i|%s|100", target, prix, buffer[2]);
		quantity.AddItem(strQuantite, "100");

		quantity.ExitButton = true;
		quantity.Display(client, MENU_TIME_FOREVER);
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuQuantity(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[4][64], response[128];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 4, 64);
			
		int target = StringToInt(buffer[0]);
		int quantity = StringToInt(buffer[3]);
		int prix = StringToInt(buffer[1]) * quantity;
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		
		if(target != client)
			request.SetTitle("%N vous propose %i %s pour %i$, acheter ?", client, quantity, buffer[2], prix);	
		else
			request.SetTitle("Acheter %i %s pour %i$ ?", quantity, buffer[2], prix);				
				
		
		Format(STRING(response), "%i|%i|%s|%i|oui", client, quantity, buffer[2], prix);		
		request.AddItem(response, "Payer en liquide.");
		
		if(rp_GetClientBool(target, b_asCb))
		{
			Format(STRING(response), "%i|%i|%s|%i|cb", client, quantity, buffer[2], prix);			
			request.AddItem(response, "Payer avec ma carte bleue.");
		}
		
		request.AddItem("non", "Refuser l'achat.");
		
		request.ExitButton = false;
		request.Display(target, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else
	{
		if(action == MenuAction_End)
			delete menu;
	}
}	

public int FinalMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[5][128], strAppart[2][32];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 5, 128);
		ExplodeString(buffer[2], "_", strAppart, 2, 32);
			
		int vendeur = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[3]);
		int quantity = StringToInt(buffer[1]);
		bool payCB;
		
		if(StrEqual(buffer[4], "cb"))
			payCB = true;
			
		if(!StrEqual(buffer[4], "non"))
		{
			if(payCB)
			{
				if(rp_GetClientInt(client, i_Bank) >= prix)
				{
					rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - prix);
					
					if(vendeur == client)
					{
						rp_SetJobCapital(10, rp_GetJobCapital(10) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);
					
					if(vendeur == client)
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, buffer[2], prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, buffer[2], vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, buffer[2], client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, buffer[2], prix, client);
					}
					
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
				}
				else
				{
					if(client != vendeur)
						CPrintToChat(vendeur, "%s %N n'a pas assez d'argent en banque.", TEAM, client);
					CPrintToChat(client, "%s Vous n'avez pas assez d'argent en banque.", TEAM);
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
					return;
				}	
			}
			else
			{
				if(rp_GetClientInt(client, i_Money) >= prix)
				{
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - prix);
					
					if(vendeur == client)
					{
						rp_SetJobCapital(10, rp_GetJobCapital(10) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);					
					
					if(vendeur == client)
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, buffer[2], prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, buffer[2], vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, buffer[2], client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, buffer[2], prix, client);
					}
					
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
				}
				else
				{
					if(client != vendeur)
						CPrintToChat(vendeur, "%s %N n'a pas assez d'argent en liquide.", TEAM, client);
					CPrintToChat(client, "%s Vous n'avez pas assez d'argent en liquide.", TEAM);
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
					return;
				}
			}
			
			if(StrEqual(buffer[2], "Nick"))
			{
				rp_SetClientItem(client, i_skin1, rp_GetClientItem(client, i_skin1) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin1", rp_GetClientItem(client, i_skin1), steamID[client]);
			}	
			else if(StrEqual(buffer[2], "Phoenix"))
			{
				rp_SetClientItem(client, i_skin2, rp_GetClientItem(client, i_skin2) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin2", rp_GetClientItem(client, i_skin2), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Miyu"))
			{
				rp_SetClientItem(client, i_skin3, rp_GetClientItem(client, i_skin3) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin3", rp_GetClientItem(client, i_skin3), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Natalia"))
			{
				rp_SetClientItem(client, i_skin4, rp_GetClientItem(client, i_skin4) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin4", rp_GetClientItem(client, i_skin4), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Coach"))
			{
				rp_SetClientItem(client, i_skin5, rp_GetClientItem(client, i_skin5) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin5", rp_GetClientItem(client, i_skin5), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Le Marseillais"))
			{
				rp_SetClientItem(client, i_skin6, rp_GetClientItem(client, i_skin6) - 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin6", rp_GetClientItem(client, i_skin6), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Leeti"))
			{
				rp_SetClientItem(client, i_skin7, rp_GetClientItem(client, i_skin7) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin7", rp_GetClientItem(client, i_skin7), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Negan"))
			{
				rp_SetClientItem(client, i_skin8, rp_GetClientItem(client, i_skin8) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin8", rp_GetClientItem(client, i_skin8), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Captain Price"))
			{
				rp_SetClientItem(client, i_skin9, rp_GetClientItem(client, i_skin9) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin9", rp_GetClientItem(client, i_skin9), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Macri"))
			{
				rp_SetClientItem(client, i_skin10, rp_GetClientItem(client, i_skin10) - 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin10", rp_GetClientItem(client, i_skin10), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Engel"))
			{
				rp_SetClientItem(client, i_skin11, rp_GetClientItem(client, i_skin11) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin11", rp_GetClientItem(client, i_skin11), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Donald Trump"))
			{
				rp_SetClientItem(client, i_skin12, rp_GetClientItem(client, i_skin12) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin12", rp_GetClientItem(client, i_skin12), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Niko Bellic"))
			{
				rp_SetClientItem(client, i_skin13, rp_GetClientItem(client, i_skin13) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin13", rp_GetClientItem(client, i_skin13), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Zoey"))
			{
				rp_SetClientItem(client, i_skin14, rp_GetClientItem(client, i_skin14) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin14", rp_GetClientItem(client, i_skin14), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Marcus Reed"))
			{
				rp_SetClientItem(client, i_skin15, rp_GetClientItem(client, i_skin15) + 1);
				SetSQL_Int(g_DB, "rp_vendeurdeskin", "skin15", rp_GetClientItem(client, i_skin15), steamID[client]);
			}
		}
		else if(StrEqual(buffer[4], "non"))
		{
			if(client != vendeur)
			{
				CPrintToChat(vendeur, "%s %N a refusé votre offre.", TEAM, client);
				CPrintToChat(client, "%s Vous avez refusé la vente de %N.", TEAM, vendeur);
				
				rp_SetClientBool(vendeur, b_menuOpen, false);
				rp_SetClientBool(client, b_menuOpen, false);
			}
			else CPrintToChat(client, "%s Vous avez refusé le paiement.", TEAM);
		}
		if(!StrEqual(buffer[4], "non"))
		{
			rp_SetupRingPoint(client, vendeur);
		}		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else
	{
		if(action == MenuAction_End)
			delete menu;
	}
}
/************************************************/

public void rp_OnClientSpawn(int client)
{
	char skin[256];
	rp_GetClientString(client, sz_Skin, STRING(skin));
	
	if(StrEqual(skin, ""))
		rp_SetClientString(client, sz_Skin, "none", 256);
	else
		rp_SetSkin(client, skin);
	
	isInVestiaireMenu[client] = false;
	canTestSkin[client] = true;
}		

public void rp_OnClientDisconnect(int client)
{
	rp_SetClientString(client, sz_Skin, "none", 256);
}	