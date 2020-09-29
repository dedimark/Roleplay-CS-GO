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

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Mc Donald's", 
	author = "Benito", 
	description = "Métier McDonald's", 
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
		
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/jobs/rp_job_mcdonalds.log");
	
	RegConsoleCmd("setfaim", Cmd_test);
}

public Action Cmd_test(int client, int args)
{
	rp_SetClientFloat(client, fl_Faim, 80.0);	
	
	return Plugin_Handled;
}	

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
		
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_mcdonalds` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `faim` float NOT NULL, \
	  `122` int(100) NOT NULL, \
	  `123` int(100) NOT NULL, \
	  `124` int(100) NOT NULL, \
	  `125` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_mcdonalds` (`Id`, `steamid`, `playername`, `faim`, `122`, `123`, `124`, `125`, `timestamp`) VALUES (NULL, '%s', '%s', '100.0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_mcdonalds WHERE steamid = '%s';", steamID[client]);
	rp_GetDatabase().Query(QueryCallback, buffer, GetClientUserId(client));
}

public void QueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientFloat(client, fl_Faim, SQL_FetchFloatByName(Results, "faim"));
		for (int i = 0; i <= MAXITEMS; i++)
		{
			char item_jobid[64];
			rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
			
			if(StrEqual(item_jobid, "10"))
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
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	
	if(StrContains(model, "nuke_snack_machine.mdl") != -1 || StrEqual(entityName, "McDonald's"))
	{
		int nbMcdo;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 15 && !rp_GetClientBool(i, b_isAfk))
				nbMcdo++;
		}
		if(nbMcdo == 0 || nbMcdo == 1 && rp_GetClientInt(client, i_Job) == 6 || rp_GetClientInt(client, i_Job) == 6 && rp_GetClientInt(client, i_Grade) <= 2)
		{
			if(StrContains(model, "nuke_snack_machine.mdl") != -1)
				MenuDistributeur(client);
			else
				NPC_MENU(client);
		}	
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un McDo.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un McDo.");
		}	
	}
}

Menu NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - McDonald's");
	menu.AddItem("item", "Acheter à manger");
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
			SellMcdo(client, client);	
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
	if(rp_GetClientInt(client, i_Job) == 15)
	{
		menu.AddItem("item", "Vendre un objet");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "item"))
		SellMcdo(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellMcdo(int client, int target)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Items Disponibles");
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "15"))
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
					
					rp_SetJobCapital(15, rp_GetJobCapital(15) + prix / 2);
					rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 4);
					if(vendeur != client)
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
					
					rp_SetJobCapital(15, rp_GetJobCapital(15) + prix / 2);
					rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 4);				
					if(vendeur != client)
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

public Action RP_OnPlayerInventory(int client, Menu menu)
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "15"))
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
	if(StrEqual(info, "122") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);	
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "123") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);	
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "124") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);	
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "125") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);	
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
}	

Menu MenuDistributeur(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuDistributeur);
	menu.SetTitle("Distributeur automatique :");
	if(rp_GetClientBool(client, b_isAmphetamine))
		menu.AddItem("", "Vous n'avez plus faim (amphétamine).", ITEMDRAW_DISABLED);
	else
	{
		if(rp_GetClientInt(client, i_Money) == 0)
			menu.AddItem("", "Vous n'avez pas d'argent sur vous.", ITEMDRAW_DISABLED);
			
		if(rp_GetClientFloat(client, fl_Faim) == 100.0)
			menu.AddItem("", "Vous n'avez plus faim.", ITEMDRAW_DISABLED);
			
		if(rp_GetClientInt(client, i_Money) >= 50 && rp_GetClientFloat(client, fl_Faim) < 100.0)
		{
			menu.AddItem("", "Barre de chocolat (50$)");
			menu.AddItem("", "Bonbons (50$)");
			menu.AddItem("", "Cola (50$)");
			menu.AddItem("", "Paquet de chips (50$)");
			menu.AddItem("", "Boisson énergisante (50$)");
			menu.AddItem("", "Sandwich Halal (50$)");
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuDistributeur(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		
		rp_SetClientFloat(client, fl_Faim, rp_GetClientFloat(client, fl_Faim) + 5.0);
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - 50);
		rp_SetJobCapital(15, rp_GetJobCapital(15) + 25);
		rp_SetJobCapital(5, rp_GetJobCapital(5) + 25);	
		EmitCashSound(client, -50);
		MenuDistributeur(client);
		
		CPrintToChat(client, "%s Votre faim a diminué.", TEAM);
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

public void OnGameFrame()
{
	LoopClients(client)
	{
		if(rp_GetClientFloat(client, fl_Faim) > 2.0 && rp_GetClientFloat(client, fl_Faim) < 1.0)
		{
			CPrintToChat(client, "%s Vous allez {lightred}mourir de faim{default} si vous ne mangez rien !", TEAM);
			PrintCenterText(client, "<font color='#F86900'>Vous avez trop faim !</font>");
		}
		
		/*if(rp_GetClientFloat(client, fl_Faim) > 0.0 && !rp_GetClientBool(client, b_isAfk) && !rp_GetClientBool(client, b_isAmphetamine) && GetVehicle(client) == -1)
			rp_SetClientFloat(client, fl_Faim, rp_GetClientFloat(client, fl_Faim) - 0.5);
		else if(rp_GetClientFloat(client, fl_Faim) == 0.0 && !rp_GetClientBool(client, b_isAfk))
		{
			ForcePlayerSuicide(client);
			CPrintToChat(client, "%s Vous êtes mort de faim.", TEAM);
			rp_SetClientFloat(client, fl_Faim, 5.0);		
		}*/
	}	
}		