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
char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Armurier", 
	author = "Benito", 
	description = "Métier Armurier", 
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_armurier.log");
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];		
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_armurier` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `16` int(100) NOT NULL, \
	  `17` int(100) NOT NULL, \
	  `18` int(100) NOT NULL, \
	  `19` int(100) NOT NULL, \
	  `20` int(100) NOT NULL, \
	  `21` int(100) NOT NULL, \
	  `22` int(100) NOT NULL, \
	  `23` int(100) NOT NULL, \
	  `24` int(100) NOT NULL, \
	  `25` int(100) NOT NULL, \
	  `26` int(100) NOT NULL, \
	  `27` int(100) NOT NULL, \
	  `28` int(100) NOT NULL, \
	  `29` int(100) NOT NULL, \
	  `30` int(100) NOT NULL, \
	  `31` int(100) NOT NULL, \
	  `32` int(100) NOT NULL, \
	  `33` int(100) NOT NULL, \
	  `34` int(100) NOT NULL, \
	  `35` int(100) NOT NULL, \
	  `36` int(100) NOT NULL, \
	  `37` int(100) NOT NULL, \
	  `38` int(100) NOT NULL, \
	  `39` int(100) NOT NULL, \
	  `40` int(100) NOT NULL, \
	  `41` int(100) NOT NULL, \
	  `42` int(100) NOT NULL, \
	  `43` int(100) NOT NULL, \
	  `44` int(100) NOT NULL, \
	  `45` int(100) NOT NULL, \
	  `46` int(100) NOT NULL, \
	  `47` int(100) NOT NULL, \
	  `48` int(100) NOT NULL, \
	  `49` int(100) NOT NULL, \
	  `56` int(100) NOT NULL, \
	  `57` int(100) NOT NULL, \
	  `58` int(100) NOT NULL, \
	  `59` int(100) NOT NULL, \
	  `64` int(100) NOT NULL, \
	  `65` int(100) NOT NULL, \
	  `66` int(100) NOT NULL, \
	  `70` int(100) NOT NULL, \
	  `75` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public void RP_OnPlayerDisconnect(int client)
{
	if(!IsClientInGame(client))
		return;
}

public void OnMapStart()
{
	PrecacheModel("models/props_survival/upgrades/upgrade_dz_armor_helmet.mdl", true);
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
	
	char buffer[4096];
	Format(STRING(buffer), 
	"INSERT IGNORE INTO `rp_armurier` ( \
	  `Id`, \
	  `steamid`, \
	  `playername`, \
	  `16`, \
	  `17`, \
	  `18`, \
	  `19`, \
	  `20`, \
	  `21`, \
	  `22`, \
	  `23`, \
	  `24`, \
	  `25`, \
	  `26`, \
	  `27`, \
	  `28`, \
	  `29`, \
	  `30`, \
	  `31`, \
	  `32`, \
	  `33`, \
	  `34`, \
	  `35`, \
	  `36`, \
	  `37`, \
	  `38`, \
	  `39`, \
	  `40`, \
	  `41`, \
	  `42`, \
	  `43`, \
	  `44`, \
	  `45`, \
	  `46`, \
	  `47`, \
	  `48`, \
	  `49`, \
	  `56`, \
	  `57`, \
	  `58`, \
	  `59`, \
	  `64`, \
	  `65`, \
	  `66`, \
	  `70`, \
	  `75`, \
	  `timestamp`\
	  ) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

/***************************************************************************************

								P L U G I N  -  S Q L

***************************************************************************************/

public void LoadSQL(int client) 
{
	if(!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_armurier WHERE steamid = '%s';", steamID[client]);
	rp_GetDatabase().Query(QueryCallback, buffer, GetClientUserId(client));
}

public void QueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		for (int i = 0; i <= MAXITEMS; i++)
		{
			char item_jobid[64];
			rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
			
			if(StrEqual(item_jobid, "6"))
			{
				char item_string[10];
				IntToString(i, STRING(item_string));
				
				rp_ClientGiveItem(client, i, SQL_FetchIntByName(Results, item_string));
			}	
		}	
	}
} 

/***************************************************************************************

						P L U G I N  -  G L O B A L  F O R W A R D

***************************************************************************************/

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	if(StrEqual(model, "models/weapons/w_axe_dropped.mdl"))
	{
		int iMelee = GivePlayerItem(client, "weapon_axe");
		EquipPlayerWeapon(client, iMelee);
		RemoveEdict(target);
		CPrintToChat(client, "%s Vous avez ramassé une hache.", TEAM);
	}
	else if(StrEqual(model, "models/weapons/w_hammer_dropped.mdl"))		
	{
		int iMelee = GivePlayerItem(client, "weapon_hammer");
		EquipPlayerWeapon(client, iMelee);
		RemoveEdict(target);
		
		CPrintToChat(client, "%s Vous avez ramassé un marteau.", TEAM);
	}
	else if(StrEqual(model, "models/weapons/w_spanner_dropped.mdl"))
	{
		int iMelee = GivePlayerItem(client, "weapon_spanner");
		EquipPlayerWeapon(client, iMelee);
		RemoveEdict(target);
		
		CPrintToChat(client, "%s Vous avez ramassé une clé à molette.", TEAM);
	}	
	
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	
	if(StrEqual(entityName, "Armurerie"))
	{
		int nbArmu;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 6 && !rp_GetClientBool(i, b_isAfk))
				nbArmu++;
		}
		if(nbArmu == 0 || nbArmu == 1 && rp_GetClientInt(client, i_Job) == 6 || rp_GetClientInt(client, i_Job) == 6 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un armurier.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un armurier.");
		}	
	}
}	

public Action RP_OnPlayerBuild(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Job) == 6)
	{
		menu.SetTitle("Build - Armurier");
		menu.AddItem("", "En Développement", ITEMDRAW_DISABLED);
	}	
}	

public Action RP_OnPlayerInventory(int client, Menu menu)
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "6"))
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
	if(StrEqual(info, "16") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, StringToInt(info), rp_GetClientItem(client, StringToInt(info)) - 1);
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_armurier` SET `%s` = '%i' WHERE `steamid` = '%s';", info, rp_GetClientItem(client, StringToInt(info)), steamID[client]);	
				
				int wepID = GivePlayerItem(client, "weapon_hkp2000");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un p2000.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un p2000.", client);
			}	
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);		
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "17") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, StringToInt(info), rp_GetClientItem(client, StringToInt(info)) - 1);
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_armurier` SET `%s` = '%i' WHERE `steamid` = '%s';", info, rp_GetClientItem(client, StringToInt(info)), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_usp_silencer");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un usp.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un usp.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "18") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, pistol_glock18, rp_GetClientItem(client, pistol_glock18) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, pistol_glock18), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_glock");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un glock-18.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un glock-18.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "19") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, pistol_p250, rp_GetClientItem(client, pistol_p250) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, pistol_p250), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_p250");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un p250.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un p250.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "20") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, pistol_fiveseven, rp_GetClientItem(client, pistol_fiveseven) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, pistol_fiveseven), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_fiveseven");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un five-seven.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un five-seven.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}	
	else if(StrEqual(info, "21") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, pistol_tec9, rp_GetClientItem(client, pistol_tec9) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, pistol_tec9), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_tec9");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un tec-9.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un tec-9.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "22") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, pistol_cz75, rp_GetClientItem(client, pistol_cz75) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, pistol_cz75), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_cz75a");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un cz-75.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un cz-75.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "23") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, pistol_dualberettas, rp_GetClientItem(client, pistol_dualberettas) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, pistol_dualberettas), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_elite");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}des Dual-berettas.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise des Dual-berettas.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "24") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, pistol_deagle, rp_GetClientItem(client, pistol_deagle) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, pistol_deagle), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_deagle");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un deagle.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un deagle.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "25") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
			{
				rp_ClientGiveItem(client, pistol_revolver, rp_GetClientItem(client, pistol_revolver) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, pistol_revolver), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_revolver");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un revolver.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un revolver.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "26") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, smg_mp9, rp_GetClientItem(client, smg_mp9) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, smg_mp9), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_mp9");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une mp9.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une mp9.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "27") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, smg_mac10, rp_GetClientItem(client, smg_mac10) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, smg_mac10), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_mac10");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une mac-10.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une mac-10.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "28") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, smg_ppbizon, rp_GetClientItem(client, smg_ppbizon) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, smg_ppbizon), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_bizon");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une pp-bizon.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une pp-bizon.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "29") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, smg_mp7, rp_GetClientItem(client, smg_mp7) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, smg_mp7), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_mp7");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une mp7.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une mp7.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "30") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, smg_ump45, rp_GetClientItem(client, smg_ump45) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, smg_ump45), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_ump45");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une ump45.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une ump45.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "31") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, smg_p90, rp_GetClientItem(client, smg_p90) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, smg_p90), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_p90");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une p90.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une p90.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "32") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, smg_mp5sd, rp_GetClientItem(client, smg_mp5sd) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, smg_mp5sd), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_mp5sd");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une mp5-sd.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une mp5-sd.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "33") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_famas, rp_GetClientItem(client, rifle_famas) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_famas), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_famas");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une famas.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une famas.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "34") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_galilar, rp_GetClientItem(client, rifle_galilar) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_galilar), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_galilar");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une galilar.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une galilar.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "35") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_m4a4, rp_GetClientItem(client, rifle_m4a4) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_m4a4), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_m4a1");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une m4a4.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une m4a4.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "36") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_m4a1s, rp_GetClientItem(client, rifle_m4a1s) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_m4a1s), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_m4a1_silencer");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une m4a1-s.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une m4a1-s.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "37") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_ak47, rp_GetClientItem(client, rifle_ak47) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_ak47), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_ak47");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une ak-47.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une ak-47.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "38") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_aug, rp_GetClientItem(client, rifle_aug) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_aug), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_aug");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une aug.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une aug.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "39") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_sg553, rp_GetClientItem(client, rifle_sg553) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_sg553), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_sg553");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une sg553.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une sg553.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "40") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_ssg08, rp_GetClientItem(client, rifle_ssg08) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_ssg08), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_ssg08");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une ssg08.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une ssg08.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "41") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_awp, rp_GetClientItem(client, rifle_awp) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_awp), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_awp");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une awp.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une awp.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "42") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_scar20, rp_GetClientItem(client, rifle_scar20) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_scar20), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_scar20");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une scar-20.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une scar-20.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "43") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, rifle_g3sg1, rp_GetClientItem(client, rifle_g3sg1) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, rifle_g3sg1), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_g3sg1");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un g3sg1.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un g3sg1.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "44") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, heavy_nova, rp_GetClientItem(client, heavy_nova) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, heavy_nova), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_nova");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une nova.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une nova.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "45") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, heavy_xm1014, rp_GetClientItem(client, heavy_xm1014) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, heavy_xm1014), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_xm1014");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un xm1014.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un xm1014.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "46") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, heavy_mag7, rp_GetClientItem(client, heavy_mag7) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, heavy_mag7), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_mag7");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}un mag7.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise un mag7.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "47") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, heavy_sawedoff, rp_GetClientItem(client, heavy_sawedoff) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, heavy_sawedoff), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_sawedoff");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une sawedoff.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une sawedoff.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "48") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, heavy_m249, rp_GetClientItem(client, heavy_m249) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, heavy_m249), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_m249");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une m249.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une m249.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "49") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			{
				rp_ClientGiveItem(client, heavy_negev, rp_GetClientItem(client, heavy_negev) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, heavy_negev), steamID[client]);
					
				int wepID = GivePlayerItem(client, "weapon_negev");
				rp_SetClientAmmo(client, wepID, 0, 0);
					
				CPrintToChat(client, "%s Vous utilisez {lightblue}une negev.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une negev.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "56") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_kevlar, rp_GetClientItem(client, gear_kevlar) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, gear_kevlar), steamID[client]);
					
			GivePlayerItem(client, "prop_weapon_upgrade_armor_helmet");
					
			CPrintToChat(client, "%s Vous utilisez {lightblue}un kevlar.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un kevlar.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "57") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_helmet, rp_GetClientItem(client, gear_helmet) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, gear_helmet), steamID[client]);
					
			GivePlayerItem(client, "prop_weapon_upgrade_helmet");
					
			CPrintToChat(client, "%s Vous utilisez {lightblue}un casque.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un casque.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "58") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_zeus, rp_GetClientItem(client, gear_zeus) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, gear_zeus), steamID[client]);
					
			int wepID = GivePlayerItem(client, "weapon_taser");
			rp_SetClientAmmo(client, wepID, 0, 0);
					
			CPrintToChat(client, "%s Vous utilisez {lightblue}un zeus x27.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un zeus x27.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "59") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_assaultsuit, rp_GetClientItem(client, gear_assaultsuit) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, gear_assaultsuit), steamID[client]);
					
			GivePlayerItem(client, "prop_weapon_refill_heavyarmor");
					
			CPrintToChat(client, "%s Vous utilisez {lightblue}une armure lourde.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une armure lourde.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "64") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_axe, rp_GetClientItem(client, gear_axe) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, gear_axe), steamID[client]);
					
			int iMelee = GivePlayerItem(client, "weapon_axe");
			EquipPlayerWeapon(client, iMelee);
					
			CPrintToChat(client, "%s Vous utilisez {lightblue}une hache.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une hache.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "65") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_hammer, rp_GetClientItem(client, gear_hammer) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, gear_hammer), steamID[client]);
			
			int iMelee = GivePlayerItem(client, "weapon_hammer");
			EquipPlayerWeapon(client, iMelee);
					
			CPrintToChat(client, "%s Vous utilisez {lightblue}un marteau.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un marteau.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "66") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_wrench, rp_GetClientItem(client, gear_wrench) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, gear_wrench), steamID[client]);
			
			int iMelee = GivePlayerItem(client, "weapon_spanner");
			EquipPlayerWeapon(client, iMelee);
					
			CPrintToChat(client, "%s Vous utilisez {lightblue}une clé à molette.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une clé à molette.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "70") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			int weapon = Client_GetActiveWeapon(client);
			char weaponName[64];
			Entity_GetClassName(weapon, STRING(weaponName));
			
			if(rp_canSetAmmo(client, weapon))
			{
				rp_ClientGiveItem(client, i_munition, rp_GetClientItem(client, i_munition) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, i_munition), steamID[client]);
				
				RemoveEdict(weapon);
						
				int ent = GivePlayerItem(client, weaponName);
				Entity_SetName(ent, weaponName);
				
				CPrintToChat(client, "%s Vous utilisez {lightblue}des munitions.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise des munitions.", client);
			}
			else
				CPrintToChat(client, "%s Les munitions doivent être utilisées sur une arme.", TEAM);			
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "75") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			int weapon = Client_GetActiveWeapon(client);
			
			if(rp_canSetAmmo(client, weapon))
			{		
				int ammo = Weapon_GetPrimaryClip(weapon);
				if( ammo >= 5000 ) 
				{
					CPrintToChat(client, "%s Vous avez déjà 5000 balles.", TEAM);
				}
				else
				{
					rp_ClientGiveItem(client, i_sanandreas, rp_GetClientItem(client, i_sanandreas) - 1);
					UpdateSQL_Item(rp_GetDatabase(), "rp_armurier", info, rp_GetClientItem(client, i_sanandreas), steamID[client]);
					
					ammo += 1000;
					if( ammo > 5000 )
						ammo = 5000;
					Weapon_SetPrimaryClip(weapon, ammo);
					
					CPrintToChat(client, "%s Votre arme a maintenant %i balles", TEAM, ammo);
					LogToFile(logFile, "Le joueur %N a utilise un san andreas.", client);
				}	
			}
			else
				CPrintToChat(client, "%s Les munitions doivent être utilisées sur une arme.", TEAM);	
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);						
	}
	
	FakeClientCommand(client, "rp");
}

/***************************************************************************************

								P L U G I N  - N P C

***************************************************************************************/

Menu NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Armurier");
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
			SellArmory(client, client);	
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action RP_OnPlayerSell(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 6)
	{
		menu.AddItem("item", "Vendre un objet");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "item"))
		SellArmory(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellArmory(int client, int target)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Items Disponibles");
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "6"))
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
						rp_SetJobCapital(6, rp_GetJobCapital(6) + prix / 2);
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
						rp_SetJobCapital(6, rp_GetJobCapital(6) + prix / 2);
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
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_armurier` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
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