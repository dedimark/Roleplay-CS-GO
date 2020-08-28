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
➤																					  ➤
➤							C O M P I L E  -  O P T I O N S							  ➤
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							P L U G I N  -  I N C L U D E S
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
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

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							G L O B A L  -  V A R S
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
char logFile[PLATFORM_MAX_PATH];
char dbconfig[] = "roleplay";
char steamID[MAXPLAYERS + 1][32];
Database g_DB;
int cagnotte;
int countGrattage[MAXPLAYERS + 1][3];
int countWin[3];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							P L U G I N  -  I N F O
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Loto", 
	author = "Benito", 
	description = "Métier Loto", 
	version = VERSION, 
	url = URL
};

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							P L U G I N  -  E V E N T S
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		GameCheck();
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_loto.log");
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
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_loto` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `ticketgratter` int(100) NOT NULL, \
		  `loto` int(100) NOT NULL, \
		  `rapido` int(100) NOT NULL, \
		  `lampetorche` int(100) NOT NULL, \
		  `peinture` int(100) NOT NULL, \
		  `graffiti1` int(100) NOT NULL, \
		  `graffiti2` int(100) NOT NULL, \
		  `graffiti3` int(100) NOT NULL, \
		  `graffiti4` int(100) NOT NULL, \
		  `graffiti5` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
		
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_loto_cagnotte` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `cagnotte` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnMapStart()
{
	char buffer[512];
	Format(STRING(buffer), "SELECT cagnotte FROM rp_loto_cagnotte");
	g_DB.Query(LoadCagnotteCallBackSQL, buffer);
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
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_loto` (`Id`, `steamid`, `playername`, `ticketgratter`, `loto`, `rapido`, `lampetorche`, `peinture`, `graffiti1`, `graffiti2`, `graffiti3`, `graffiti4`, `graffiti5`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	LoadLoto(client);
}

public Action rp_reloadData()
{
	LoopClients(i)
	{
		LoadLoto(i);
	}	
}	

public void LoadLoto(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_loto WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(LoadCallBackSQL, buffer, GetClientUserId(client));
}

public void LoadCallBackSQL(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientItem(client, i_ticketgratter, SQL_FetchIntByName(Results, "ticketgratter"));
		rp_SetClientItem(client, i_loto, SQL_FetchIntByName(Results, "loto"));
		rp_SetClientItem(client, i_rapido, SQL_FetchIntByName(Results, "rapido"));
		rp_SetClientItem(client, i_lampetorche, SQL_FetchIntByName(Results, "lampetorche"));
		rp_SetClientItem(client, i_peinture, SQL_FetchIntByName(Results, "peinture"));
		rp_SetClientItem(client, i_graffiti1, SQL_FetchIntByName(Results, "graffiti1"));
		rp_SetClientItem(client, i_graffiti2, SQL_FetchIntByName(Results, "graffiti2"));
		rp_SetClientItem(client, i_graffiti3, SQL_FetchIntByName(Results, "graffiti3"));
		rp_SetClientItem(client, i_graffiti4, SQL_FetchIntByName(Results, "graffiti4"));
		rp_SetClientItem(client, i_graffiti5, SQL_FetchIntByName(Results, "graffiti5"));
	}
}

public Action rp_MenuInventory(int client, Menu menu)
{
	char amount[128];
	
	if(rp_GetClientItem(client, i_ticketgratter) >= 1)
	{
		Format(STRING(amount), "Ticket à gratter [%i]", rp_GetClientItem(client, i_ticketgratter));
		menu.AddItem("ticketgratter", amount);
	}
	
	if(rp_GetClientItem(client, i_loto) >= 1)
	{
		Format(STRING(amount), "Loto [%i]", rp_GetClientItem(client, i_loto));
		menu.AddItem("loto", amount);
	}
	
	if(rp_GetClientItem(client, i_rapido) >= 1)
	{
		Format(STRING(amount), "Rapido [%i]", rp_GetClientItem(client, i_rapido));
		menu.AddItem("rapido", amount);
	}
	
	if(rp_GetClientItem(client, i_lampetorche) >= 1)
	{
		Format(STRING(amount), "Lampe torche [%i]", rp_GetClientItem(client, i_lampetorche));
		menu.AddItem("lampetorche", amount);
	}
	
	if(rp_GetClientItem(client, i_peinture) >= 1)
	{
		Format(STRING(amount), "Bombe de peinture [%i]", rp_GetClientItem(client, i_peinture));
		menu.AddItem("peinture", amount);
	}
	
	if(rp_GetClientItem(client, i_graffiti1) >= 1)
	{
		Format(STRING(amount), "Graffiti 1 [%i]", rp_GetClientItem(client, i_graffiti1));
		menu.AddItem("graffiti1", amount);
	}
	
	if(rp_GetClientItem(client, i_graffiti2) >= 1)
	{
		Format(STRING(amount), "Graffiti 2 [%i]", rp_GetClientItem(client, i_graffiti2));
		menu.AddItem("graffiti2", amount);
	}
	
	if(rp_GetClientItem(client, i_graffiti3) >= 1)
	{
		Format(STRING(amount), "Graffiti 3 [%i]", rp_GetClientItem(client, i_graffiti3));
		menu.AddItem("graffiti3", amount);
	}
	
	if(rp_GetClientItem(client, i_graffiti4) >= 1)
	{
		Format(STRING(amount), "Graffiti 4 [%i]", rp_GetClientItem(client, i_graffiti4));
		menu.AddItem("graffiti4", amount);
	}
	
	if(rp_GetClientItem(client, i_graffiti5) >= 1)
	{
		Format(STRING(amount), "Graffiti 5 [%i]", rp_GetClientItem(client, i_graffiti5));
		menu.AddItem("graffiti5", amount);
	}
}	
	
public int rp_HandlerMenuInventory(int client, char[] info)
{
	float vitality = rp_GetClientFloat(client, fl_Vitality);
	
	if (StrEqual(info, "ticketgratter") && IsPlayerAlive(client))
	{
		if (cagnotte >= 1000)
		{
			rp_SetClientItem(client, i_ticketgratter, rp_GetClientItem(client, i_ticketgratter) - 1);
			SetSQL_Int(g_DB, "rp_loto", info, rp_GetClientItem(client, i_ticketgratter), steamID[client]);
			
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
	else if (StrEqual(info, "rapido") && IsPlayerAlive(client))
	{
		if (cagnotte >= 10000)
		{
			rp_SetClientItem(client, i_rapido, rp_GetClientItem(client, i_rapido) - 1);
			SetSQL_Int(g_DB, "rp_loto", info, rp_GetClientItem(client, i_rapido), steamID[client]);
			
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
	else if (StrEqual(info, "loto") && IsPlayerAlive(client))
	{
		if (cagnotte >= 100000)
		{
			rp_SetClientItem(client, i_loto, rp_GetClientItem(client, i_loto) - 1);
			SetSQL_Int(g_DB, "rp_loto", info, rp_GetClientItem(client, i_loto), steamID[client]);
			
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
}

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrContains(entModel, "casino_slotmachine.mdl") != -1)
		MenuCasino1(client);	
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