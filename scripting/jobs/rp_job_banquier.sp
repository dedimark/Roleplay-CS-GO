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
#include <cstrike>
#include <sdkhooks>
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
	name = "[Roleplay] Job - Banquier", 
	author = "Benito", 
	description = "Métier Banquier", 
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_banquier.log");
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];		
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_banquier` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `cartebancaire` int(1) NOT NULL, \
	  `rib` int(1) NOT NULL, \
	  `saveitem` int(1) NOT NULL, \
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
	"INSERT IGNORE INTO `rp_banquier` ( \
	  `Id`, \
	  `steamid`, \
	  `playername`, \
	  `cartebancaire`, \
	  `rib`, \
	  `saveitem`, \
	  `timestamp`\
	  ) VALUES (NULL, '%s', '%s', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);	
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_banquier WHERE steamid = '%s';", steamID[client]);
	rp_GetDatabase().Query(QueryCallback, buffer, GetClientUserId(client));
}

public void QueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		if(SQL_FetchIntByName(Results, "cartebancaire") == 1)
			rp_SetClientBool(client, b_asCb, true);
		else
			rp_SetClientBool(client, b_asCb, false);	
			
		if(SQL_FetchIntByName(Results, "rib") == 1)
			rp_SetClientBool(client, b_asRib, true);
		else
			rp_SetClientBool(client, b_asRib, false);
		
		if(SQL_FetchIntByName(Results, "saveitem") == 1)
			rp_SetClientBool(client, b_asBankedItem, true);
		else
			rp_SetClientBool(client, b_asBankedItem, false);			
	}
}

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	
	if(StrEqual(entityName, "Banque"))
	{
		int nbBanquier;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 11 && !rp_GetClientBool(i, b_isAfk))
				nbBanquier++;
		}
		if(nbBanquier == 0 || nbBanquier == 1 && rp_GetClientInt(client, i_Job) == 11 || rp_GetClientInt(client, i_Job) == 11 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un banquier.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un banquier.");
		}	
	}
}

Menu NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Banque");
	
	menu.AddItem("compte", "Compte");
	menu.AddItem("other", "Autre");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "compte"))
			SellComptes(client, client);	
		else if(StrEqual(info, "other"))
			SellOthers(client, client);			
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
	if(rp_GetClientInt(client, i_Job) == 11)
	{
		menu.AddItem("compte", "Compte");
		menu.AddItem("other", "Autre");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "compte"))
		SellComptes(client, target);	
	else if(StrEqual(info, "other"))
		SellOthers(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellComptes(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Comptes Disponibles");

	prix = 500;
	Format(STRING(strFormat), "%i|%i|cartebancaire", target, prix);
	Format(STRING(strMenu), "Carte Bancaire (%i$)", prix);
	menu.AddItem(strFormat, strMenu, (rp_GetClientBool(target, b_asCb) == false)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);	
		
	prix = 500;
	Format(STRING(strFormat), "%i|%i|rib", target, prix);
	Format(STRING(strMenu), "Relevé d'Identité Bancaire (%i$)", prix);	
	menu.AddItem(strFormat, strMenu, (rp_GetClientBool(target, b_asRib) == false)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);	
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

Menu SellOthers(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Autres");

	prix =  500;
	Format(STRING(strFormat), "%i|%i|saveitem", target, prix);
	Format(STRING(strMenu), "Sauvegarde d'item (%i$)", prix);	
	menu.AddItem(strFormat, strMenu, (rp_GetClientBool(target, b_asBankedItem) == false)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);	
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoSell(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32], buffer[3][64], strQuantite[128], strFormat[64];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		
		ExplodeString(info, "|", buffer, 3, 64);
			
		int target = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[1]);

		/* MENU QUANTITE */
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
		if(StrEqual(buffer[2], "cb") && StrEqual(buffer[2], "rib") && StrEqual(buffer[2], "saveitem"))
		{
			Format(STRING(strQuantite), "%i|%i|%s|1", target, prix, buffer[2]);
			quantity.AddItem(strQuantite, "1");
		}
		else
		{		
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
		}	

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
		int prix = StringToInt(buffer[1]);
		int quantity = StringToInt(buffer[3]);
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		request.SetTitle("%N vous propose %i %s pour %i$, acheter ?", client, quantity, buffer[2], prix);
		
		Format(STRING(response), "%i|%i|%s|%i|oui", client, quantity, buffer[2], prix);				
		request.AddItem(response, "Payer en liquide.");
		
		Format(STRING(response), "%i|%i|%s|%i|cb", client, quantity, buffer[2], prix);
		request.AddItem(response, "Payer avec ma carte bleue.", rp_GetClientBool(target, b_asCb)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);	
				
		Format(STRING(response), "%i|%i|%s|%i|non", client, quantity, buffer[2], prix);
		request.AddItem(response, "Refuser l'achat.");
		
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
		char info[128], buffer[5][128];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 5, 128);
			
		int vendeur = StringToInt(buffer[0]);
		int prix = 500;
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
						rp_SetJobCapital(rp_GetClientInt(vendeur, i_Job), rp_GetJobCapital(rp_GetClientInt(vendeur, i_Job)) + prix / 4);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
						
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, buffer[2], prix);
					}
					else
					{
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);
						
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
						rp_SetJobCapital(rp_GetClientInt(vendeur, i_Job), rp_GetJobCapital(rp_GetClientInt(vendeur, i_Job)) + prix / 4);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
						
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, buffer[2], prix);
					}
					else
					{
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);
						
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
						
			if(StrEqual(buffer[2], "cartebancaire"))
			{
				rp_SetClientBool(client, b_asCb, true);	
				SetSQL_Int(rp_GetDatabase(), "rp_banquier", buffer[2], quantity, steamID[client]);
			}	
			else if(StrEqual(buffer[2], "rib")) 
			{
				rp_SetClientBool(client, b_asRib, true);	
				SetSQL_Int(rp_GetDatabase(), "rp_banquier", buffer[2], quantity, steamID[client]);
			}
			else if(StrEqual(buffer[2], "saveitem")) 
			{
				rp_SetClientBool(client, b_asBankedItem, true);	
				SetSQL_Int(rp_GetDatabase(), "rp_banquier", buffer[2], quantity, steamID[client]);
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