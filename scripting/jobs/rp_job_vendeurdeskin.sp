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
char steamID[MAXPLAYERS + 1][32];
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
	GameCheck();
	rp_LoadTranslation();
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/jobs/rp_job_vendeurdeskin.log");
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_vendeurdeskin` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `78` int(100) NOT NULL, \
	  `79` int(100) NOT NULL, \
	  `80` int(100) NOT NULL, \
	  `81` int(100) NOT NULL, \
	  `82` int(100) NOT NULL, \
	  `83` int(100) NOT NULL, \
	  `84` int(100) NOT NULL, \
	  `85` int(100) NOT NULL, \
	  `86` int(100) NOT NULL, \
	  `87` int(100) NOT NULL, \
	  `88` int(100) NOT NULL, \
	  `89` int(100) NOT NULL, \
	  `90` int(100) NOT NULL, \
	  `91` int(100) NOT NULL, \
	  `92` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
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
	SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_vendeurdeskin` (`Id`, `steamid`, `playername`, `78`, `79`, `80`, `81`, `82`, `83`, `84`, `85`, `86`, `87`, `88`, `89`, `90`, `91`, `92`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_vendeurdeskin WHERE steamid = '%s'", steamID[client]);
	rp_GetDatabase().Query(CallBackSQL, buffer, GetClientUserId(client));
}

public void CallBackSQL(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		for (int i = 0; i <= MAXITEMS; i++)
		{
			char item_jobid[64];
			rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
			
			if(StrEqual(item_jobid, "14"))
			{
				char item_string[10];
				IntToString(i, STRING(item_string));
				
				rp_ClientGiveItem(client, i, SQL_FetchIntByName(Results, item_string));
			}	
		}	
	}
}

/************************************************/
/***************** Global Forwards *****************/

public Action RP_OnPlayerInventory(int client, Menu menu)
{	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "14"))
		{
			if(rp_GetClientItem(client, i) >= 1)
			{
				char item_name[64], item_handle[64];
				rp_GetItemData(i, item_type_name, STRING(item_name));
				Format(STRING(item_name), "%s [%i]", item_name, rp_GetClientItem(client, i));
				Format(STRING(item_handle), "%i", i);
				menu.AddItem(item_handle, item_name);
			}
		}
	}
}
	
public int RP_OnPlayerInventoryHandle(int client, char[] info)
{
	char currentSkin[256];
	rp_GetClientString(client, sz_Skin, currentSkin, 256);
	
	if(StrEqual(info, "78") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/l4d2/nick/nickv2.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/l4d2/nick/nickv2.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kuristaja/l4d2/nick/nickv2.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Nick.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Nick.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Nick{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "79") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/cso2/phoenix/phoenix.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/cso2/phoenix/phoenix.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/phoenix/phoenix.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Phoenix.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Phoenix.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Phoenix{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "80") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/cso2/miyu_schoolgirl/miyu.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/cso2/miyu_schoolgirl/miyu.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/miyu_schoolgirl/miyu.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Miyu.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Miyu.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Miyu{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "81") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/cso2/natalie/natalie.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/cso2/natalie/natalie.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kuristaja/cso2/natalie/natalie.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Natalia.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Natalia.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Natalia{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "82") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/l4d2/coach/coachv2.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/l4d2/coach/coachv2.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kuristaja/l4d2/coach/coachv2.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Coach.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Coach.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Coach{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "83") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kirby/kirbys_robber/kirbys_robber2.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kirby/kirbys_robber/kirbys_robber2.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kirby/kirbys_robber/kirbys_robber2.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue du {lightblue}Marseillais.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue du Marseillais.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue du {lightred}Marseillais{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "84") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kirby/leetkumla/leetkumla.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kirby/leetkumla/leetkumla.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kirby/leetkumla/leetkumla.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Leeti.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Leeti.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Leeti{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "85") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kodua/negan/negan.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kodua/negan/negan.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kodua/negan/negan.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Negan.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Negan.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Negan{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "86") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/eminem/cod2/captain_price.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/eminem/cod2/captain_price.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/eminem/cod2/captain_price.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Captain Price.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Captain Price.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Captain Price{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "87") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/ventoz/macri/macrii.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/ventoz/macri/macrii.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/ventoz/macri/macrii.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Macri.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Macri.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Macri{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "88") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/caleon1/sigrun_engel/sigrun_engel_v3.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/caleon1/sigrun_engel/sigrun_engel_v3.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/caleon1/sigrun_engel/sigrun_engel_v3.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Engel.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Engel.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Engel{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "89") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/kuristaja/trump/trump.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/kuristaja/trump/trump.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/kuristaja/trump/trump.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Donald Trump.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Donald Trump.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Donald Trump{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "90") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/voikanaa/gtaiv/niko.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/voikanaa/gtaiv/niko.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/voikanaa/gtaiv/niko.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Niko Bellic.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Niko Bellic.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Niko Bellic{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "91") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/natalya/zoeys/zoey_red.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/natalya/zoeys/zoey_red.mdl", 256);
				rp_SetSkin(client, "models/player/natalya/zoeys/zoey_red.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Zoey.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Zoey.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Zoey{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "92") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(!StrEqual(currentSkin, "models/player/custom_player/hekut/marcusreed/marcusreed.mdl"))
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
				rp_SetClientString(client, sz_Skin, "models/player/custom_player/hekut/marcusreed/marcusreed.mdl", 256);
				rp_SetSkin(client, "models/player/custom_player/hekut/marcusreed/marcusreed.mdl");
				
				CreateTimer(1.0, View3rd, client);
				
				CPrintToChat(client, "%s Vous portez désormais la tenue de {lightblue}Marcus Reed.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais la tenue de Marcus Reed.", client);
			}	
			else
				CPrintToChat(client, "%s Vous portez déjà la tenue de {lightred}Marcus Reed{default}.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
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

public void RP_OnPlayerDisconnect(int client) {
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
		
		menu.AddItem("skin1", "Nick", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin2", "Phoenix", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin3", "Miyu", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin4", "Natalia", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin5", "Coach", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin6", "Le Marseillais", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin7", "Leeti", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin8", "Negan", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin9", "Captain Price", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin10", "Macri", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin11", "Engel", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin12", "Donald Trump", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin13", "Niko Bellic", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin14", "Zoey", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		menu.AddItem("skin15", "Marcus Reed", (canTestSkin[client] == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);		
				
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

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	
	if(StrEqual(entityName, "Dolce & Gabbana") && Distance(client, target) <= 80.0)
	{
		int nbVds;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 14 && !rp_GetClientBool(i, b_isAfk))
				nbVds++;
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
	menu.AddItem("item", "Acheter un objet");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "item"))
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

public Action RP_OnPlayerSell(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 14)
	{
		menu.AddItem("item", "Vendre un objet");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "skin"))
		SellSkins(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellSkins(int client, int target)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Items Disponibles");
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "14"))
		{
			char item_name[64], item_handle[64], item_price[32];
			rp_GetItemData(i, item_type_name, STRING(item_name));
			rp_GetItemData(i, item_type_prix, STRING(item_price));
			Format(STRING(item_name), "%s [%s$]", item_name, item_price);
			Format(STRING(item_handle), "%i|%i|%i", target, StringToInt(item_price), i);
			menu.AddItem(item_handle, item_name);
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}			

public int DoSell(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], buffer[3][64], strQuantite[128], strFormat[64];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		
		ExplodeString(info, "|", buffer, 3, 64);
			
		int target = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[1]);
		int itemID = StringToInt(buffer[2]);

		/* MENU QUANTITE */
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
		for(int i = 1; i <= 10; i++)
		{			
			Format(STRING(strQuantite), "%i|%i|%i|%i", target, prix, itemID, i);
			Format(STRING(strFormat), "%i", i);
			quantity.AddItem(strQuantite, strFormat);
		}	
		Format(STRING(strQuantite), "%i|%i|%i|25", target, prix, itemID);
		quantity.AddItem(strQuantite, "25");
		Format(STRING(strQuantite), "%i|%i|%i|50", target, prix, itemID);
		quantity.AddItem(strQuantite, "50");
		Format(STRING(strQuantite), "%i|%i|%i|100", target, prix, itemID);
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
		int itemID = StringToInt(buffer[2]);
		int quantity = StringToInt(buffer[3]);
		int prix = StringToInt(buffer[1]) * quantity;
		
		char item_name[32];
		rp_GetItemData(itemID, item_type_name, STRING(item_name));
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		
		if(target != client)
			request.SetTitle("%N vous propose %i %s pour %i$, acheter ?", client, quantity, item_name, prix);	
		else
			request.SetTitle("Acheter %i %s pour %i$ ?", quantity, item_name, prix);				
				
		
		Format(STRING(response), "%i|%i|%i|%i|oui", client, quantity, itemID, prix);		
		request.AddItem(response, "Payer en liquide.");
		
		if(rp_GetClientBool(target, b_asCb))
		{
			Format(STRING(response), "%i|%i|%i|%i|cb", client, quantity, itemID, prix);			
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
		int itemID = StringToInt(buffer[2]);
		bool payCB;
		
		char item_name[32];
		rp_GetItemData(itemID, item_type_name, STRING(item_name));
		
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
						rp_SetJobCapital(14, rp_GetJobCapital(14) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);
					
					if(vendeur == client)
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, item_name, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, item_name, prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, item_name, vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, item_name, client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, item_name, prix, client);
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
						rp_SetJobCapital(14, rp_GetJobCapital(14) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);					
					
					if(vendeur == client)
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, item_name, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, item_name, prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, item_name, vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, item_name, client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, item_name, prix, client);
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
			
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) + quantity);
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
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

public void rp_RP_OnPlayerDisconnect(int client)
{
	rp_SetClientString(client, sz_Skin, "none", 256);
}	