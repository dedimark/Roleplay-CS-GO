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
char dbconfig[] = "roleplay";
Database g_DB;

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
	if(rp_licensing_isValid())
	{
		GameCheck();
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_banquier.log");
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
		"CREATE TABLE IF NOT EXISTS `rp_banquier` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `cartebancaire` int(1) NOT NULL, \
		  `rib` int(1) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnClientDisconnect(int client)
{
	if(!IsClientInGame(client))
		return;
}

public void OnClientPutInServer(int client)
{	
	
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
	
	char buffer[4096];
	Format(STRING(buffer), 
	"INSERT IGNORE INTO `rp_banquier` ( \
	  `Id`, \
	  `steamid`, \
	  `playername`, \
	  `cartebancaire`, \
	  `rib`, \
	  `timestamp`\
	  ) VALUES (NULL, '%s', '%s', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);	
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadBanque(client);
}

public Action rp_reloadData()
{
	LoopClients(i)
	{
		SQLCALLBACK_LoadBanque(i);
	}	
}

public void SQLCALLBACK_LoadBanque(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_banquier WHERE steamid = '%s';", steamID[client]);
	g_DB.Query(SQLLoadTechQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadTechQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
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
	}
} 

public Action rp_MenuBuild(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Job) == 11)
	{
		menu.SetTitle("Build - Armurier");
		if(rp_GetClientInt(client, i_Job) == 11)
			menu.AddItem("imprimante", "Installer une imprimante");
	}	
}	

public Action rp_MenuVendre(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 11)
	{
		int prix;
		char strFormat[128], strMenu[128];
		
		rp_SetClientBool(client, b_menuOpen, true);
		
		prix = rp_GetPrice("cartebancaire");
		Format(STRING(strFormat), "%i|%i|cartebancaire", target, prix);
		Format(STRING(strMenu), "Carte Bancaire (%i$)", prix);
		
		if(rp_GetClientBool(target, b_asCb))
			menu.AddItem(strFormat, strMenu, ITEMDRAW_DISABLED);
		else
			menu.AddItem(strFormat, strMenu);
			
		prix = rp_GetPrice("rib");
		Format(STRING(strFormat), "%i|%i|rib", target, prix);
		Format(STRING(strMenu), "Relevé d'Identité Bancaire (%i$)", prix);
		
		if(rp_GetClientBool(target, b_asRib))
			menu.AddItem(strFormat, strMenu, ITEMDRAW_DISABLED);
		else
			menu.AddItem(strFormat, strMenu);	
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	char buffer[3][64], strQuantite[128], strIndex[128];
	ExplodeString(info, "|", buffer, 3, 64);
		
	int target = StringToInt(buffer[0]);
	int prix = StringToInt(buffer[1]);
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuQuantity);
	menu.SetTitle("Choisissez la quantité");
	if(!StrEqual(buffer[2], "cartebancaire") && !StrEqual(buffer[2], "rib"))
	{
		Format(STRING(strQuantite), "%i|%i|%s|1", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "1");
		Format(STRING(strQuantite), "%i|%i|%s|2", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "2");
		Format(STRING(strQuantite), "%i|%i|%s|3", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "3");
		Format(STRING(strQuantite), "%i|%i|%s|4", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "4");
		Format(STRING(strQuantite), "%i|%i|%s|5", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "5");
		Format(STRING(strQuantite), "%i|%i|%s|10", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "10");
		Format(STRING(strQuantite), "%i|%i|%s|25", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "25");
		Format(STRING(strQuantite), "%i|%i|%s|50", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "50");
		Format(STRING(strQuantite), "%i|%i|%s|100", target, prix, buffer[2]);
		menu.AddItem(strQuantite, "100");
	}	
	else
	{
		Format(STRING(strQuantite), "%i|%i|%s|1", target, prix, buffer[2]);
		Format(STRING(strIndex), "Vendre un/une %s", buffer[2]);
		menu.AddItem(strQuantite, strIndex);
	}	
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
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
		
		if(rp_GetClientBool(target, b_asCb))
		{
			Format(STRING(response), "%i|%i|%s|%i|cb", client, quantity, buffer[2], prix);
			request.AddItem(response, "Payer avec ma carte bleue.");
		}
				
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
		int prix = rp_GetPrice(buffer[2]);
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
					
					rp_SetJobCapital(rp_GetClientInt(vendeur, i_Job), rp_GetJobCapital(rp_GetClientInt(vendeur, i_Job)) + prix / 4);
					rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 4);
					rp_SetClientInt(vendeur, i_Bank, rp_GetClientInt(vendeur, i_Bank) + prix / 4);
					
					CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, buffer[2], vendeur, prix);
					CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, buffer[2], client, prix);
					LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, buffer[2], prix, client);
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
					
					
					PrecacheSound("+UI/panorama/inventory_new_item_accept_01.wav");
					EmitSoundToAll("+UI/panorama/inventory_new_item_accept_01.wav", client, _, _, _, 0.5);
				}
				else
				{
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
					
					rp_SetJobCapital(rp_GetClientInt(vendeur, i_Job), rp_GetJobCapital(rp_GetClientInt(vendeur, i_Job)) + prix / 4);
					rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 4);
					rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);
					
					CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, buffer[2], vendeur, prix);
					CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, buffer[2], client, prix);
					LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, buffer[2], prix, client);
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
				}
				else
				{
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
				SetSQL_Int(g_DB, "rp_banquier", buffer[2], quantity, steamID[client]);
			}	
			else if(StrEqual(buffer[2], "rib")) 
			{
				rp_SetClientBool(client, b_asRib, true);	
				SetSQL_Int(g_DB, "rp_banquier", buffer[2], quantity, steamID[client]);
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