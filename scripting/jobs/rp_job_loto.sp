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
char steamID[MAXPLAYERS + 1][32];

int cagnotte;
int countGrattage[MAXPLAYERS + 1][3];
int countWin[3];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Loto", 
	author = "Benito", 
	description = "Métier Loto", 
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_loto.log");
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_loto` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `99` int(100) NOT NULL, \
	  `100` int(100) NOT NULL, \
	  `101` int(100) NOT NULL, \
	  `102` int(100) NOT NULL, \
	  `103` int(100) NOT NULL, \
	  `104` int(100) NOT NULL, \
	  `105` int(100) NOT NULL, \
	  `106` int(100) NOT NULL, \
	  `107` int(100) NOT NULL, \
	  `108` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
	
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_loto_cagnotte` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `cagnotte` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public void OnMapStart()
{
	char buffer[512];
	Format(STRING(buffer), "SELECT cagnotte FROM rp_loto_cagnotte");
	rp_GetDatabase().Query(LoadCagnotteCallBackSQL, buffer);
}	

public void LoadCagnotteCallBackSQL(Database db, DBResultSet Results, const char[] error, any data) 
{	
	while (Results.FetchRow()) 
	{
		cagnotte = SQL_FetchIntByName(Results, "cagnotte");
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
	SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_loto` (`Id`, `steamid`, `playername`, `99`, `100`, `101`, `102`, `103`, `104`, `105`, `106`, `107`, `108`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_loto WHERE steamid = '%s'", steamID[client]);
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
			
			if(StrEqual(item_jobid, "16"))
			{
				char item_string[10];
				IntToString(i, STRING(item_string));
				
				rp_ClientGiveItem(client, i, SQL_FetchIntByName(Results, item_string));
			}	
		}	
	}
}

public Action RP_OnPlayerInventory(int client, Menu menu)
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "16"))
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
	float vitality = rp_GetClientFloat(client, fl_Vitality);
	
	if (StrEqual(info, "99") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (cagnotte >= 1000)
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
				
				countGrattage[client][0]++;
				
				int nombre;
				if (countGrattage[client][0] > 142)
					nombre = GetRandomInt(40, 60);
				else if (vitality < 5.0)
					nombre = GetRandomInt(0, 95);
				else if (vitality < 25.0)
					nombre = GetRandomInt(0, 90);
				else if (vitality < 50.0)
					nombre = GetRandomInt(0, 85);
				else if (vitality < 70.0)
					nombre = GetRandomInt(0, 80);
				else if (vitality < 99.0)
					nombre = GetRandomInt(0, 75);
				else
					nombre = GetRandomInt(0, 70);
				
				if (nombre == 42 || nombre == 69)
				{
					if (countWin[0] > 100 || GetRandomInt(1, 2) == 2)
					{
						countWin[0] = 0;
						countGrattage[client][0] = 0;				
						rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 1000);
						cagnotte -= 500;
						EmitCashSound(client, 1000);
						CPrintToChat(client, "%s Vous avez gratté un ticket, vous avez gagné \x061000$ !", TEAM);
						LogToFile(logFile, "Le joueur %N a gratte un ticket et a gagne 1000$.", client);
						
						PrecacheSound("ui/item_drop4_mythical.wav");
						EmitSoundToClient(client, "ui/item_drop4_mythical.wav", client, _, _, _, 1.0);
					}
					else 
						CPrintToChat(client, "%s Vous avez gratté un ticket, vous avez perdu.", TEAM);
				}
				else if (nombre >= 37 && nombre <= 42)
				{
					int montant = GetRandomInt(6, 50);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + montant);
					cagnotte -= montant;
					EmitCashSound(client, montant);
					CPrintToChat(client, "%s Vous avez gratté un ticket, vous avez gagné \x06%i$ !", TEAM, montant);
					LogToFile(logFile, "Le joueur %N a gratte un ticket et a gagne %i$.", client, montant);
				}
				else
					CPrintToChat(client, "%s Vous avez gratté un ticket, vous avez perdu.", TEAM);
			}
			else
				CPrintToChat(client, "%s La loterie n'est pas assez élévée, conservez votre ticket a gratter.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if (StrEqual(info, "101") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (cagnotte >= 10000)
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
				
				countGrattage[client][1]++;
				
				int nombre;
				if (countGrattage[client][1] > 160)
					nombre = GetRandomInt(40, 60);
				else if (vitality < 5.0)
					nombre = GetRandomInt(0, 125);
				else if (vitality < 25.0)
					nombre = GetRandomInt(0, 120);
				else if (vitality < 50.0)
					nombre = GetRandomInt(0, 115);
				else if (vitality < 70.0)
					nombre = GetRandomInt(0, 110);
				else if (vitality < 99.0)
					nombre = GetRandomInt(0, 105);
				else
					nombre = GetRandomInt(0, 100);
				
				if (nombre == 42 || nombre == 69)
				{
					if (countWin[1] > 100 || GetRandomInt(1, 3) == 2)
					{
						countWin[1] = 0;
						countGrattage[client][1] = 0;
						
						rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 10000);
						cagnotte -= 5000;
						EmitCashSound(client, 10000);
						CPrintToChat(client, "%s Vous avez joué au rapido, vous avez gagné \x0610000$ !", TEAM);
						LogToFile(logFile, "Le joueur %N a joue au rapido et a gagne 10000$.", client);
						
						PrecacheSound("ui/item_drop4_mythical.wav");
						EmitSoundToClient(client, "ui/item_drop4_mythical.wav", client, _, _, _, 1.0);
					}
					else 
						CPrintToChat(client, "%s Vous avez joué au Rapido, vous avez perdu.", TEAM);
				}
				else if (nombre >= 37 && nombre <= 42)
				{
					int montant = GetRandomInt(80, 160);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + montant);
					cagnotte -= montant;
					EmitCashSound(client, montant);
					CPrintToChat(client, "%s Vous avez joué au rapido, vous avez gagné \x06%i$ !", TEAM, montant);
					LogToFile(logFile, "Le joueur %N a joué au rapido et a gagne %i$.", client, montant);
				}
				else
					CPrintToChat(client, "%s Vous avez joué au Rapido, vous avez perdu.", TEAM);
			}
			else
				CPrintToChat(client, "%s La loterie n'est pas assez élévée, conservez votre Rapido.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if (StrEqual(info, "100") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (cagnotte >= 100000)
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
				
				countGrattage[client][2]++;
				
				int nombre;
				if (countGrattage[client][2] > 185)
					nombre = GetRandomInt(40, 60);
				else if (vitality < 5.0)
					nombre = GetRandomInt(0, 145);
				else if (vitality < 25.0)
					nombre = GetRandomInt(0, 140);
				else if (vitality < 50.0)
					nombre = GetRandomInt(0, 135);
				else if (vitality < 70.0)
					nombre = GetRandomInt(0, 130);
				else if (vitality < 99.0)
					nombre = GetRandomInt(0, 125);
				else
					nombre = GetRandomInt(0, 120);
				
				if (nombre == 42 || nombre == 69)
				{
					if (countWin[2] > 100 || GetRandomInt(1, 4) == 2)
					{
						countWin[2] = 0;
						countGrattage[client][2] = 0;
						
						rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 100000);
						cagnotte -= 50000;
						EmitCashSound(client, 100000);
						CPrintToChat(client, "%s Vous avez joué au Loto, vous avez gagné \x06100000$ !", TEAM);
						LogToFile(logFile, "Le joueur %N a joue au Loto et a gagne 100000$.", client);
						
						PrecacheSound("ui/item_drop4_mythical.wav");
						EmitSoundToClient(client, "ui/item_drop4_mythical.wav", client, _, _, _, 1.0);
					}
					else CPrintToChat(client, "%s Vous avez joué au Loto, vous avez perdu.", TEAM);
				}
				else if (nombre >= 37 && nombre <= 42)
				{
					int montant = GetRandomInt(800, 1750);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + montant);
					cagnotte -= montant;
					EmitCashSound(client, montant);
					CPrintToChat(client, "%s Vous avez joué au Loto, vous avez gagné \x06%i$ !", TEAM, montant);
					LogToFile(logFile, "Le joueur %N a joué au Loto et a gagne %i$.", client, montant);
				}
				else
					CPrintToChat(client, "%s Vous avez joué au Loto, vous avez perdu.", TEAM);
			}
			else
				CPrintToChat(client, "%s La loterie n'est pas assez élévée, conservez votre Loto.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if (StrEqual(info, "103") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if (StrEqual(info, "104") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}	
	else if (StrEqual(info, "105") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if (StrEqual(info, "106") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if (StrEqual(info, "107") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if (StrEqual(info, "108") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
}

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	if(StrContains(model, "casino_slotmachine.mdl") != -1)
		MenuCasino1(client);
		
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	
	if(StrEqual(entityName, "Loto") && Distance(client, target) <= 80.0)
	{
		int nbLoto;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 16 && !rp_GetClientBool(i, b_isAfk))
				nbLoto++;
		}
		if(nbLoto == 0 || nbLoto == 1 && rp_GetClientInt(client, i_Job) == 16 || rp_GetClientInt(client, i_Job) == 16 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un loto.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un loto.");
		}
	}	
}	

Menu MenuCasino1(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu casino1 = new Menu(DoMenuCasino1);
	casino1.SetTitle("Casino - Loterie [1]");
	casino1.AddItem("", "Tentez votre chance.", ITEMDRAW_DISABLED);
	casino1.AddItem("10", "Miser 10$");
	casino1.AddItem("50", "Miser 50$");
	casino1.AddItem("100", "Miser 100$");
	casino1.AddItem("info", "Voir les LOTS");
	casino1.ExitButton = true;
	casino1.Display(client, MENU_TIME_FOREVER);
}	


public int DoMenuCasino1(Menu casino1, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		casino1.GetItem(param, STRING(info));
		if (StrEqual(info, "10"))
		{
			if (rp_GetClientInt(client, i_Money) > 10)
			{
				int bonus = GetRandomInt(1, 20);
				if (bonus < 2)
				{
					CPrintToChat(client, "%s Bravo vous avez gagné 20$", TEAM);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 20);
					rp_SetJobCapital(16, rp_GetJobCapital(16) - 20);
				}
				else
				{
					CPrintToChat(client, "%s Perdu , Ce sera pour une prochaine fois !", TEAM);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - 10);
					rp_SetJobCapital(16, rp_GetJobCapital(16) + 10);
				}
			}
			else
			{
				CPrintToChat(client, "%s Vous n'avez pas assez d'argent sur vous !", TEAM);
			}
		}
		else if (StrEqual(info, "50"))
		{
			if (rp_GetClientInt(client, i_Money) > 50)
			{
				int bonus = GetRandomInt(1, 50);
				if (bonus < 2)
				{
					CPrintToChat(client, "%s Bravo vous avez gagné 100$ !", TEAM);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 100);
					rp_SetJobCapital(16, rp_GetJobCapital(16) - 100);
				}
				else
				{
					CPrintToChat(client, "%s Perdu , Ce sera pour une prochaine fois !", TEAM);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - 50);
					rp_SetJobCapital(16, rp_GetJobCapital(16) + 50);
				}
			}
			else
			{
				CPrintToChat(client, "%s Vous n'avez pas assez d'argent sur vous !", TEAM);
			}
		}
		else if (StrEqual(info, "100"))
		{
			if (rp_GetClientInt(client, i_Money) > 100)
			{
				int bonus = GetRandomInt(1, 50);
				if (bonus < 2)
				{
					CPrintToChat(client, "%s Bravo vous avez gagné 200$ !", TEAM);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 100);
					rp_SetJobCapital(16, rp_GetJobCapital(16) - 100);
				}
				else if (bonus == 3)
				{
					CPrintToChat(client, "%s Bravo vous avez gagné 1000$ !", TEAM);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 900);
					rp_SetJobCapital(16, rp_GetJobCapital(16) - 900);
				}
				else
				{
					CPrintToChat(client, "%s Perdu , Ce sera pour une prochaine fois !", TEAM);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - 100);
					rp_SetJobCapital(16, rp_GetJobCapital(16) + 100);
				}
			}
			else
			{
				CPrintToChat(client, "%s Vous n'avez pas assez d'argent sur vous !", TEAM);
			}
		}
		else if (StrEqual(info, "info"))
		{
			Panel infocasino1 = new Panel();
			infocasino1.SetTitle("~~~~~~~~~ - MACHINE 1 - ~~~~~~~~~");
			infocasino1.DrawText("Les lots de la machine 1 sont ci-dessous\n\n- 20$ pour une mise de 10$\n- 100$ pour une mise de 50$\n- 1000$ ou 200$ pour une mise de 100$\n");
			infocasino1.DrawItem("Retour");
			infocasino1.Send(client, Casino1Exit, -1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete casino1;
}	

public int Casino1Exit(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		MenuCasino1(client);
	}
	else if (action == MenuAction_Cancel)
	{
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

/***************** NPC SYSTEM *****************/

int NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Loto");
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
			SellLoto(client, client);		
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
	if(rp_GetClientInt(client, i_Job) == 16)
	{
		menu.AddItem("item", "Vendre un objet");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "ticket"))
		SellLoto(client, target);		
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellLoto(int client, int target)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Items Disponibles");
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "16"))
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
						rp_SetJobCapital(16, rp_GetJobCapital(16) + prix / 2);
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
						rp_SetJobCapital(16, rp_GetJobCapital(16) + prix / 2);
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
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
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