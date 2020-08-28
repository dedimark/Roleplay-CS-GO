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
char logFile[PLATFORM_MAX_PATH];
char steamID[MAXPLAYERS + 1][32];
char dbconfig[] = "roleplay";
Database g_DB;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Immobilier", 
	author = "Benito", 
	description = "Métier Immobilier", 
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
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_immo.log");
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
		"CREATE TABLE IF NOT EXISTS `rp_immobilier` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `appartID` int(100) NOT NULL, \
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
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_immobilier` (`Id`, `steamid`, `playername`, `appartID`, `timestamp`) VALUES (NULL, '%s', '%s', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	LoadAppartementsSQL(client);
}

public void LoadAppartementsSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_immobilier WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(LoadCallBackSQL, buffer, GetClientUserId(client));
}

public void LoadCallBackSQL(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_appartement, SQL_FetchIntByName(Results, "appartID"));
	}
}

/***************** NPC SYSTEM *****************/

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrEqual(entName, "Agent Immobilier"))
	{
		int nbImmo;
		LoopClients(i)
		{
			if(IsClientValid(i))
			{
				if(rp_GetClientInt(i, i_Job) == 8 && !rp_GetClientBool(i, b_isAfk))
					nbImmo++;
			}
		}
		if(nbImmo == 0 || nbImmo == 1 && rp_GetClientInt(client, i_Job) == 8 || rp_GetClientInt(client, i_Job) == 8 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un immoblier.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un immoblier.");
		}	
	}
}

int NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Immobilier");
	menu.AddItem("appartement", "Appartements");
	menu.AddItem("props", "Props");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "appartement"))
			SellAppartement(client, client);
		else if(StrEqual(info, "props"))
			SellProps(client, client);		
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
/***************** Global Forwards *****************/

public Action rp_MenuVendre(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 8)
	{
		rp_SetClientBool(client, b_menuOpen, true);
		menu.AddItem("appartement", "Appartements");
		menu.AddItem("props", "Props");
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "appartement"))
		SellAppartement(client, target);
	else if(StrEqual(info, "props"))
		SellProps(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellProps(int client, int target)
{
	int prix;
	char strFormat[64];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Props Disponibles");

	prix = rp_GetPrice("prop_faim");
	Format(STRING(strFormat), "%i|%i|Distributeur de bouffe", target, prix);
	menu.AddItem(strFormat, "Distributeur de nourriture");	
	
	prix = rp_GetPrice("prop_atm");
	Format(STRING(strFormat), "%i|%i|Distributeur de billet", target, prix);
	menu.AddItem(strFormat, "Distributeur de billet");	
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}			

Menu SellAppartement(int client, int target)
{
	LoopClients(i)
	{
		int prix;
		char strFormat[128], strMenu[128];
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu = new Menu(DoMenuQuantity);
		menu.SetTitle("Appartements Disponibles");
		
		if(rp_GetClientInt(target, i_appartement) == 0)
		{
			if(rp_GetClientInt(i, i_appartement) != 18)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_18");
				Format(STRING(strFormat), "%i|%i|appart_18", target, prix);
				Format(STRING(strMenu), "Appartement № 18 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
				
			if(rp_GetClientInt(i, i_appartement) != 17)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_17");
				Format(STRING(strFormat), "%i|%i|appart_17", target, prix);
				Format(STRING(strMenu), "Appartement № 17 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 15)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_15");
				Format(STRING(strFormat), "%i|%i|appart_15", target, prix);
				Format(STRING(strMenu), "Appartement № 15 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 16)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_16");
				Format(STRING(strFormat), "%i|%i|appart_16", target, prix);
				Format(STRING(strMenu), "Appartement № 16 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 31)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_31");
				Format(STRING(strFormat), "%i|%i|appart_31", target, prix);
				Format(STRING(strMenu), "Appartement № 31 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 32)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_32");
				Format(STRING(strFormat), "%i|%i|appart_32", target, prix);
				Format(STRING(strMenu), "Appartement № 32 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 33)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_33");
				Format(STRING(strFormat), "%i|%i|appart_33", target, prix);
				Format(STRING(strMenu), "Appartement № 33 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 34)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_34");
				Format(STRING(strFormat), "%i|%i|appart_34", target, prix);
				Format(STRING(strMenu), "Appartement № 34 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 35)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_35");
				Format(STRING(strFormat), "%i|%i|appart_35", target, prix);
				Format(STRING(strMenu), "Appartement № 35 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 41)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_41");
				Format(STRING(strFormat), "%i|%i|appart_41", target, prix);
				Format(STRING(strMenu), "Appartement № 41 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 42)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_42");
				Format(STRING(strFormat), "%i|%i|appart_42", target, prix);
				Format(STRING(strMenu), "Appartement № 42 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 43)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_43");
				Format(STRING(strFormat), "%i|%i|appart_43", target, prix);
				Format(STRING(strMenu), "Appartement № 43 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 44)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_44");
				Format(STRING(strFormat), "%i|%i|appart_44", target, prix);
				Format(STRING(strMenu), "Appartement № 44 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 13)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_13");
				Format(STRING(strFormat), "%i|%i|appart_13", target, prix);
				Format(STRING(strMenu), "Appartement № 13 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 14)
			{				
				prix = rp_GetAppartementPrice(g_DB, "appart_14");
				Format(STRING(strFormat), "%i|%i|appart_14", target, prix);
				Format(STRING(strMenu), "Appartement № 14 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 11)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_11");
				Format(STRING(strFormat), "%i|%i|appart_11", target, prix);
				Format(STRING(strMenu), "Appartement № 11 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}				
			
			if(rp_GetClientInt(i, i_appartement) != 12)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_12");
				Format(STRING(strFormat), "%i|%i|appart_12", target, prix);
				Format(STRING(strMenu), "Appartement № 12 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 38)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_38");
				Format(STRING(strFormat), "%i|%i|appart_38", target, prix);
				Format(STRING(strMenu), "Appartement № 38 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
				
			if(rp_GetClientInt(i, i_appartement) != 37)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_37");
				Format(STRING(strFormat), "%i|%i|appart_37", target, prix);
				Format(STRING(strMenu), "Appartement № 37 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
				
			if(rp_GetClientInt(i, i_appartement) != 36)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_36");
				Format(STRING(strFormat), "%i|%i|appart_36", target, prix);
				Format(STRING(strMenu), "Appartement № 36 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
				
			if(rp_GetClientInt(i, i_appartement) != 46)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_46");
				Format(STRING(strFormat), "%i|%i|appart_46", target, prix);
				Format(STRING(strMenu), "Appartement № 46 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	

			if(rp_GetClientInt(i, i_appartement) != 45)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_45");
				Format(STRING(strFormat), "%i|%i|appart_45", target, prix);
				Format(STRING(strMenu), "Appartement № 45 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
				
			if(rp_GetClientInt(i, i_appartement) != 48)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_48");
				Format(STRING(strFormat), "%i|%i|appart_48", target, prix);
				Format(STRING(strMenu), "Appartement № 48 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
				
			if(rp_GetClientInt(i, i_appartement) != 47)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_47");
				Format(STRING(strFormat), "%i|%i|appart_47", target, prix);
				Format(STRING(strMenu), "Appartement № 47 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 21)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_21");
				Format(STRING(strFormat), "%i|%i|appart_21", target, prix);
				Format(STRING(strMenu), "Appartement № 21 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 22)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_22");
				Format(STRING(strFormat), "%i|%i|appart_22", target, prix);
				Format(STRING(strMenu), "Appartement № 22 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	

			if(rp_GetClientInt(i, i_appartement) != 24)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_24");
				Format(STRING(strFormat), "%i|%i|appart_24", target, prix);
				Format(STRING(strMenu), "Appartement № 24 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
				
			if(rp_GetClientInt(i, i_appartement) != 23)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_23");
				Format(STRING(strFormat), "%i|%i|appart_23", target, prix);
				Format(STRING(strMenu), "Appartement № 23 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	

			if(rp_GetClientInt(i, i_appartement) != 27)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_27");
				Format(STRING(strFormat), "%i|%i|appart_27", target, prix);
				Format(STRING(strMenu), "Appartement № 27 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
				
			if(rp_GetClientInt(i, i_appartement) != 28)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_28");
				Format(STRING(strFormat), "%i|%i|appart_28", target, prix);
				Format(STRING(strMenu), "Appartement № 28 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 25)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_25");
				Format(STRING(strFormat), "%i|%i|appart_25", target, prix);
				Format(STRING(strMenu), "Appartement № 25 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	

			if(rp_GetClientInt(i, i_appartement) != 26)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_26");
				Format(STRING(strFormat), "%i|%i|appart_26", target, prix);
				Format(STRING(strMenu), "Appartement № 26 (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
			
			if(rp_GetClientInt(i, i_appartement) != 301)
			{
				prix = rp_GetAppartementPrice(g_DB, "appart_0301");
				Format(STRING(strFormat), "%i|%i|appart_0301", target, prix);
				Format(STRING(strMenu), "Villa (%i$)", prix);
				menu.AddItem(strFormat, strMenu);
			}	
		}
		else
		{
			if(client == target)
				menu.AddItem("", "Vous avez déjà un appartement", ITEMDRAW_DISABLED);	
			else
				menu.AddItem("", "Ce joueur à déjà un appartement", ITEMDRAW_DISABLED);				
		}	

		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);	
	}
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
		if (StrEqual(strAppart[0], "appart"))
		{
			if(StrEqual(buffer[2], "appart_0301"))
			{
				Format(STRING(strQuantite), "%i|%i|%s|-1", target, prix, buffer[2]);
				Format(STRING(strFormat), "Vendre la villa");
			}
			else
			{
				Format(STRING(strQuantite), "%i|%i|%s|-1", target, prix, buffer[2]);
				Format(STRING(strFormat), "Vendre l'appartement № %i", StringToInt(strAppart[1]));
			}			
			quantity.AddItem(strQuantite, strFormat);
		}
		else if (!StrEqual(strAppart[0], "appart"))
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
		char info[128], buffer[4][64], response[128], strAppart[2][32];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 4, 64);
		ExplodeString(buffer[2], "_", strAppart, 2, 32);
			
		int target = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[1]);
		int quantity = StringToInt(buffer[3]);
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		
		if(StrContains(buffer[2], "appart_") != -1)
		{
			if(target == client)
			{
				if(StrEqual(buffer[2], "appart_0301"))
					request.SetTitle("Acheter la villa pour %i$", prix);
				else
					request.SetTitle("Acheter l'appartement № %i pour %i$", StringToInt(strAppart[1]), prix);	
			}
			else
			{
				if(StrEqual(buffer[2], "appart_0301"))
					request.SetTitle("%N vous propose la villa pour %i$", client, prix);
				else
					request.SetTitle("%N vous propose l'appartement № %i pour %i$", client, StringToInt(strAppart[1]), prix);	
			}
		}	
		else
		{
			prix = StringToInt(buffer[1]) * quantity;
			if(target != client)
				request.SetTitle("%N vous propose %i %s pour %i$, acheter ?", client, quantity, buffer[2], prix);	
			else
				request.SetTitle("Acheter %i %s pour %i$ ?", quantity, buffer[2], prix);		
		}				
				
		
		if(StrContains(buffer[2], "appart_") != -1)
			Format(STRING(response), "%i|-1|%s|%i|oui", client, buffer[2], prix);	
		else
			Format(STRING(response), "%i|%i|%s|%i|oui", client, quantity, buffer[2], prix);		
		request.AddItem(response, "Payer en liquide.");
		
		if(rp_GetClientBool(target, b_asCb))
		{
			if(StrContains(buffer[2], "appart_") != -1)
				Format(STRING(response), "%i|-1|%s|%i|cb", client, buffer[2], prix);
			else
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
					
					if(client == vendeur)
					{
						rp_SetJobCapital(8, rp_GetJobCapital(8) + prix / 4);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 4);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);			
					
					if(StrContains(buffer[2], "appart_") != -1)
					{
						if(StrEqual(buffer[2], "appart_0301"))
						{
							if(vendeur == client)
							{
								CPrintToChat(client, "%s Vous avez acheté la villa pour %i$.", TEAM, prix);
								LogToFile(logFile, "Le joueur %N a achete la villa pour %i$.", client, prix);
							}
							else
							{
								CPrintToChat(client, "%s Vous avez acheté la villa à %N pour %i$.", TEAM, vendeur, prix);
								CPrintToChat(vendeur, "%s Vous avez vendu la villa à %N pour %i$.", TEAM, client, prix);
								LogToFile(logFile, "Le joueur %N a achete la villa à %N pour %i$.", client, vendeur, prix);
							}
						}
						else
						{
							if(client == vendeur)
							{
								CPrintToChat(client, "%s Vous avez acheté l'appartement № %i pour %i$.", TEAM, StringToInt(strAppart[1]), prix);
								LogToFile(logFile, "Le joueur %N a achete l'appartement № %i pour %i$.", client, StringToInt(strAppart[1]), prix);
							}
							else
							{
								CPrintToChat(client, "%s Vous avez acheté l'appartement № %i à %N pour %i$.", TEAM, StringToInt(strAppart[1]), vendeur, prix);
								CPrintToChat(vendeur, "%s Vous avez vendu l'appartement № %i à %N pour %i$.", TEAM, StringToInt(strAppart[1]), client, prix);
								LogToFile(logFile, "Le joueur %N a achete l'appartement № %i à %N pour %i$.", client, StringToInt(strAppart[1]), vendeur, prix);
							}
						}						
					}
					else	
					{
						if(client == vendeur)
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
					
					if(client == vendeur)
					{
						rp_SetJobCapital(8, rp_GetJobCapital(8) + prix / 4);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 4);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);					
					
					if(StrContains(buffer[2], "appart_") != -1)
					{
						if(client == vendeur)
						{
							CPrintToChat(client, "%s Vous avez acheté l'appartement № %i pour %i$.", TEAM, StringToInt(strAppart[1]), prix);
							LogToFile(logFile, "Le joueur %N a achete l'appartement № %i pour %i$.", client, StringToInt(strAppart[1]), prix);
						}
						else
						{
							CPrintToChat(client, "%s Vous avez acheté l'appartement № %i à %N pour %i$.", TEAM, StringToInt(strAppart[1]), vendeur, prix);
							CPrintToChat(vendeur, "%s Vous avez vendu l'appartement № %i à %N pour %i$.", TEAM, StringToInt(strAppart[1]), client, prix);
							LogToFile(logFile, "Le joueur %N a achete l'appartement № %i à %N pour %i$.", client, StringToInt(strAppart[1]), vendeur, prix);
						}
					}
					else	
					{
						if(client == vendeur)
						{
							CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
							CPrintToChat(vendeur, "%s Vous avez vendu %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
							LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, buffer[2], prix);
						}
						else
						{
							CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, buffer[2], vendeur, prix);
							CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, buffer[2], client, prix);
							LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, buffer[2], prix, client);
						}
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
			
			if(StrContains(buffer[2], "appart_") != -1)
			{
				if(StrEqual(buffer[2], "appart_0301"))
				{
					rp_SetClientInt(client, i_appartement, StringToInt(strAppart[1]));
					SetSQL_Int(g_DB, "rp_immobilier", "appartement", rp_GetClientInt(client, i_appartement), steamID[client]);
					
					char sql[1024];
					Format(sql, sizeof(sql), "UPDATE rp_appartements SET proprietaire = '%s' WHERE appartement = '%s';", steamID[client], buffer[2]);
					SQL_FastQuery(g_DB, sql);
					
					Format(sql, sizeof(sql), "UPDATE rp_appartements SET loyer = 604800 WHERE appartement = '%s';", buffer[2]);
					SQL_FastQuery(g_DB, sql);
					
					CPrintToChat(client, "%s vous possèdez désormais la villa, pour une semaine.", TEAM, StringToInt(strAppart[1]));
				}
				else
				{
					rp_SetClientInt(client, i_appartement, StringToInt(strAppart[1]));
					
					char sql[1024];
					Format(sql, sizeof(sql), "UPDATE rp_appartements SET proprietaire = '%s' WHERE appartement = '%s';", steamID[client], buffer[2]);
					SQL_FastQuery(g_DB, sql);
					
					CPrintToChat(client, "%s Vous possèdez désormais l'appartement № %i.", TEAM, StringToInt(strAppart[1]));
				}				
			}	
			else
			{			
				if(StrEqual(buffer[2], "prop_distributeur"))
				{
					rp_SetClientItem(client, immo_propfaim, rp_GetClientItem(client, immo_propfaim) + quantity);	
					SetSQL_Int(g_DB, "rp_dealer", buffer[2], rp_GetClientItem(client, immo_propfaim), steamID[client]);
				}
				else if(StrEqual(buffer[2], "prop_atm"))
				{
					rp_SetClientItem(client, immo_propatm, rp_GetClientItem(client, immo_propatm) + quantity);	
					SetSQL_Int(g_DB, "rp_immobilier", buffer[2], rp_GetClientItem(client, immo_propatm), steamID[client]);
				} 
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