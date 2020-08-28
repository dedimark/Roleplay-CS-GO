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
#include <smlib>
#include <multicolors>
#include <roleplay>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  D E F I N E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#define MAXGROUPES 256

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
Database g_DB;
char dbconfig[] = "roleplay";
char logFile[PLATFORM_MAX_PATH];
char steamID[MAXPLAYERS + 1][32];
char definedName[MAXPLAYERS + 1][64];
bool canDefine[MAXPLAYERS + 1] = false;

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Groupe",
	author = "Benito",
	description = "Système de groupes",
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
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_groupes.log");
		Database.Connect(GotDatabase, dbconfig);
		
		RegConsoleCmd("creategroupe", Cmd_Groupe);
		RegConsoleCmd("groupeinfo", Cmd_Info);
	}
	else
		UnloadPlugin();
}	

public Action Cmd_Info(int client, int args)
{
	char name[64];
	rp_GetGroupString(client, Sz_groupeName, name, 64);
	CPrintToChat(client, "✦ Gang: %s", name);		
	CPrintToChat(client, "✦ Leader: %N", rp_GetGroupInt(client, i_chef));	
	CPrintToChat(client, "✦ Membres: %i/%i", rp_GetGroupInt(client, i_membres), rp_GetGroupInt(client, i_maxMembres));	
	CPrintToChat(client, "✦ Points: %i", rp_GetGroupInt(client, i_pointClan));
	CPrintToChat(client, "✦ Argent: %i$", rp_GetGroupInt(client, i_money));
	rp_SetGroupInt(client, i_maxMembres, 75);
	BuildGroupHistorique(client);
}	

public Action Cmd_Groupe(int client, int args)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Panel panel = new Panel();
	panel.SetTitle("-----------_Groupes_-----------");
	panel.DrawText("Entrer le nom du groupe dans le chat.");
	panel.Send(client, Handler_NullCancel, 20);
	canDefine[client] = true; 
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
		"CREATE TABLE IF NOT EXISTS `rp_groupes` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `groupename` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `owner` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `level` int(100) NOT NULL, \
		  `membres` int(100) NOT NULL, \
		  `maxmembres` int(100) NOT NULL, \
		  `points` int(100) NOT NULL, \
		  `argent` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `groupename` (`groupename`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_clientgroupe` ( \
		   `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `groupeid` int(1) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
		
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_groupes_historique` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `note` varchar(2048) COLLATE utf8_bin NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		 UNIQUE KEY `note` (`note`) \
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
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_clientgroupe` (`Id`, `steamid`, `playername`, `groupeid`, `timestamp`) VALUES (NULL, '%s', '%s', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadGroupes(client);
}

public void SQLCALLBACK_LoadGroupes(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_clientgroupe WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(SQLLoadGroupesQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadGroupesQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Group, SQL_FetchIntByName(Results, "groupeid"));
		GetGroupe(client);
	}
} 

public void GetGroupe(int client) {
	char buff[256];
	Format(STRING(buff), "SELECT * FROM rp_groupes WHERE Id = %i;", rp_GetClientInt(client, i_Group));
	DBResultSet query = SQL_Query(g_DB, buff);
	
	if(query)
	{
		while (query.FetchRow())
		{
			char groupe[64];
			SQL_FetchStringByName(query, "groupename", STRING(groupe));
			rp_SetGroupString(client, Sz_groupeName, STRING(groupe));
			
			char owner[64];
			SQL_FetchStringByName(query, "owner", STRING(owner));
			rp_SetGroupInt(client, i_chef, Client_FindBySteamId(owner));
			
			rp_SetGroupInt(client, i_level, SQL_FetchIntByName(query, "level"));
			rp_SetGroupInt(client, i_membres, SQL_FetchIntByName(query, "membres"));
			rp_SetGroupInt(client, i_maxMembres, SQL_FetchIntByName(query, "maxmembres"));
			rp_SetGroupInt(client, i_pointClan, SQL_FetchIntByName(query, "points"));
			rp_SetGroupInt(client, i_money, SQL_FetchIntByName(query, "argent"));
		}	
	}
	delete query;
}

public Action rp_SayOnPublic(int client, const char[] arg, const char[] cmd, int args)
{
	if(canDefine[client])
	{
		if(strlen(arg) > 64)
		{
			CPrintToChat(client, "%s Le nom du gang est trop long ! Réessayez.", TEAM);
			return Plugin_Handled;
		}
		else if(strlen(arg) <= 64)
		{	
			strcopy(definedName[client], sizeof(definedName[]), arg);
			canDefine[client] = false;
			MenuGroupeStape1(client);
		}	
	}
	
	return Plugin_Continue;
}

int MenuGroupeStape1(int client)
{
	char buffer[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(DoGroupeStape1);
	Format(STRING(buffer), "Créer %s", definedName[client]);
	menu.SetTitle(buffer);
	menu.AddItem("oui", "Oui");
	menu.AddItem("non", "Non");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoGroupeStape1(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select) 
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "oui")) 
		{
			char buffer[2048];
			Format(STRING(buffer), "INSERT IGNORE INTO `rp_groupes` (`Id`, `groupename`, `owner`, `level`, `membres`, `maxmembres`, `points`, `argent`, `timestamp`) VALUES (NULL, '%s', '%s', '1', '1', '25', '0', '0', CURRENT_TIMESTAMP);", definedName[client], steamID[client]);
			g_DB.Query(SQLErrorCheckCallback, buffer);
			
			int idgroup;
			
			Format(STRING(buffer), "SELECT Id FROM rp_groupes WHERE owner = '%s';", steamID[client]);
			DBResultSet query = SQL_Query(g_DB, buffer);			
			if(query)
			{
				while (query.FetchRow())
				{
					idgroup = query.FetchInt(0);
				}	
			}
			delete query;
			
			rp_SetClientInt(client, i_Group, idgroup);
			
			CPrintToChat(client, "%s Votre groupe %s a été créé avec succès.", TEAM, definedName[client]);
		}
		else if(StrEqual(info, "non")) {
			delete menu;
			rp_SetClientBool(client, b_menuOpen, false);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action rp_MenuRoleplay(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Group) != 0)
		menu.AddItem("gang", "Gangs");
}	

public int rp_HandlerMenuRoleplay(int client, const char[] info)
{
	if(StrEqual(info, "gang"))
		BuildMenuGroupe(client);
}	

int BuildMenuGroupe(int client)
{
	char strFormat[128];
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(DoBuildMenuGroupe);
	menu.SetTitle("Gangs - Roleplay");
	
	char name[64];
	rp_GetGroupString(client, Sz_groupeName, name, 64);
	Format(STRING(strFormat), "✦ Gang: %s", name);
	menu.AddItem("", strFormat, ITEMDRAW_DISABLED);
	
	Format(STRING(strFormat), "✦ Leader: %N", rp_GetGroupInt(client, i_chef));
	menu.AddItem("", strFormat, ITEMDRAW_DISABLED);
	
	Format(STRING(strFormat), "✦ Membres: %i/%i", rp_GetGroupInt(client, i_membres), rp_GetGroupInt(client, i_maxMembres));
	menu.AddItem("", strFormat, ITEMDRAW_DISABLED);
	
	Format(STRING(strFormat), "✦ Argent: %i$", rp_GetGroupInt(client, i_money));
	menu.AddItem("", strFormat, ITEMDRAW_DISABLED);
	
	menu.AddItem("give", "Donner de l'argent");
	
	menu.AddItem("show", "Voir les gangs du serveur");
	menu.AddItem("history", "Voir les historiques");
	
	if(client == rp_GetGroupInt(client, i_chef))
	{
		menu.AddItem("remote", "Gérer");
		menu.AddItem("trade", "Transfert d'argent");
	}	
	else
		menu.AddItem("left", "Quitter");		
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoBuildMenuGroupe(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "remote"))
			GererGang(client);
		else if(StrEqual(info, "left"))
		{
			if(IsClientValid(client))
			{
				rp_SetGroupInt(client, i_membres, rp_GetGroupInt(client, i_membres) - 1);
				UpdateGang(g_DB, "membres", rp_GetGroupInt(client, i_membres), rp_GetClientInt(client, i_Group));
				
				char name[64];
				rp_GetGroupString(client, Sz_groupeName, name, 64);
				CPrintToChat(client, "%s Vous avez quitté %s", TEAM, name);
				rp_SetClientInt(client, i_Group, 0);
				SetSQL_Int(g_DB, "rp_clientgroupe", "groupeid", rp_GetClientInt(client, i_Group), steamID[client]);
				rp_SetClientBool(client, b_menuOpen, false);
			}
		}
		else if(StrEqual(info, "show"))
		{
			if(IsClientValid(client))
			{
				Menu menu1 = new Menu(ShowGroupes);
				menu1.SetTitle("Listes des gangs");
				
				char buffer[128], strIndex[16];
				Format(STRING(buffer), "SELECT * FROM rp_groupes;");
				DBResultSet query = SQL_Query(g_DB, buffer);			
				int count = SQL_GetRowCount(query);
				for(int i = 1; i <= count; i++)
				{
					if(query.FetchRow())
					{
						char name[256][64];
						SQL_FetchStringByName(query, "groupename", name[count], 64);
						menu1.AddItem(strIndex, name[count], ITEMDRAW_DISABLED);
					}
				}
				delete query;
				
				menu1.ExitButton = true;
				menu1.Display(client, MENU_TIME_FOREVER);
			}
		}
		else if(StrEqual(info, "give"))
		{
			if(IsClientValid(client))
			{
				Menu menu2 = new Menu(GroupeMoneyDeposit);
				menu2.SetTitle("Choisissez le montant");
				
				if(rp_GetClientInt(client, i_Bank) >= 1)
				{
					menu2.AddItem("all", "Tout déposer");
				}	
				if(rp_GetClientInt(client, i_Bank) >= 1)
					menu2.AddItem("1", "1$");
				if(rp_GetClientInt(client, i_Bank) >= 5)
					menu2.AddItem("5", "5$");
				if(rp_GetClientInt(client, i_Bank) >= 10)
					menu2.AddItem("10", "10$");
				if(rp_GetClientInt(client, i_Bank) >= 50)
					menu2.AddItem("50", "50$");
				if(rp_GetClientInt(client, i_Bank) >= 100)
					menu2.AddItem("100", "100$");
				if(rp_GetClientInt(client, i_Bank) >= 250)
					menu2.AddItem("250", "250$");
				if(rp_GetClientInt(client, i_Bank) >= 500)
					menu2.AddItem("500", "500$");
				if(rp_GetClientInt(client, i_Bank) >= 1000)
					menu2.AddItem("1000", "1000$");
				if(rp_GetClientInt(client, i_Bank) >= 2500)
					menu2.AddItem("2500", "2500$");
				if(rp_GetClientInt(client, i_Bank) >= 5000)
					menu2.AddItem("5000", "5000$");
				if(rp_GetClientInt(client, i_Bank) >= 10000)
					menu2.AddItem("10000", "10000$");
				if(rp_GetClientInt(client, i_Bank) >= 25000)
					menu2.AddItem("25000", "25000$");
				if(rp_GetClientInt(client, i_Bank) >= 50000)
					menu2.AddItem("50000", "50000$");
				if(rp_GetClientInt(client, i_Bank) == 0)
					menu2.AddItem("", "Vous n'avez pas d'argent", ITEMDRAW_DISABLED);	
					
				menu2.ExitButton = true;
				menu2.Display(client, MENU_TIME_FOREVER);
			}
		}
		else if(StrEqual(info, "history"))
		{	
			if(IsClientValid(client))
			{
				BuildGroupHistorique(client);
			}	
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int ShowHistoryDonations(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int ShowGroupes(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int GroupeMoneyDeposit(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{	
		char info[32];
		menu.GetItem(param, STRING(info));
		
		int sommeDepose = StringToInt(info, 10);
		
		if(sommeDepose < 0)
			CPrintToChat(client, "%s %T", "Overdraft", LANG_SERVER, TEAM);		
		if(StrEqual(info, "all"))
		{
			//CPrintToChat(client, "%s %T %i$", "Crediting",  LANG_SERVER, TEAM, rp_GetClientInt(client, i_Money));	
			rp_SetGroupInt(client, i_money, rp_GetGroupInt(client, i_money) + rp_GetClientInt(client, i_Bank));
			
			char name[64];
			rp_GetGroupString(client, Sz_groupeName, name, 64);			
			char note[2048];
			Format(STRING(note), "%N à transferer %i$ dans le gang %s", client, rp_GetClientInt(client, i_Bank), TEAM);
			SQLGROUPE_INSERT(g_DB, note, rp_GetClientInt(client, i_Group));
			
			rp_SetClientInt(client, i_Bank, 0);	
			UpdateGang(g_DB, "argent", rp_GetGroupInt(client, i_money), rp_GetClientInt(client, i_Group));
		}
		else if(rp_GetClientInt(client, i_Money) >= sommeDepose)
		{
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - sommeDepose);	
			rp_SetGroupInt(client, i_money, rp_GetGroupInt(client, i_money) + sommeDepose);			
			//CPrintToChat(client, "%s %T %i$", "Crediting",  LANG_SERVER, TEAM, sommeDepose);
			UpdateGang(g_DB, "argent", rp_GetGroupInt(client, i_money), rp_GetClientInt(client, i_Group));
			EmitCashSound(client, sommeDepose);
			BuildMenuGroupe(client);
			
			char name[64];
			rp_GetGroupString(client, Sz_groupeName, name, 64);			
			char note[2048];
			Format(STRING(note), "%N à transferer %i$ dans le gang %s", client, sommeDepose, TEAM);
			SQLGROUPE_INSERT(g_DB, note, rp_GetClientInt(client, i_Group));
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

int GererGang(int client)
{
	char groupename[64], strText[64];
	GetGroupeName(g_DB, client, STRING(groupename));
	
	Menu menu = new Menu(DoGererGang);
	menu.SetTitle(groupename);
	Format(STRING(strText), "Membres: %i", rp_GetGroupInt(client, i_membres));
	menu.AddItem("getlistmembres", strText);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoGererGang(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		if(StrEqual(info, "getlistmembres"))
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(rp_GetClientInt(i, i_Group) == rp_GetClientInt(client, i_Group))
				{
					rp_SetClientBool(client, b_menuOpen, true);
					Menu menu1 = new Menu(DoMenuGererMembre);
					menu1.SetTitle("Gérer un membre :");
					
					char name[64], strIndex[64];
					GetClientName(i, STRING(name));
					Format(STRING(strIndex), "%i", i);
					if(i != client)
						menu1.AddItem(strIndex, TEAM);	
					menu1.ExitButton = true;
					menu1.Display(client, MENU_TIME_FOREVER);
				}	
			}	
		}	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuGererMembre(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strMenu[64];
		menu.GetItem(param, STRING(info));
		int joueur = StringToInt(info);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu GererSub = new Menu(DoMenuActionMembre);		
		Format(STRING(strMenu), "%N :", joueur);
		GererSub.SetTitle(strMenu);
		
		Format(STRING(strMenu), "virer|%i", joueur);
		GererSub.AddItem(strMenu, "Virer");
		
		GererSub.ExitButton = true;
		GererSub.Display(client, MENU_TIME_FOREVER);	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuActionMembre(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32], buffer[2][64];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		int joueur = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "virer"))
		{		
			char groupename[64];
			GetGroupeName(g_DB, client, STRING(groupename));
			
			rp_SetClientInt(joueur, i_Group, 0);
			CPrintToChat(client, "%s Vous avez viré %N", TEAM, joueur);
			SetSQL_Int(g_DB, "rp_clientgroupe", "groupeid", rp_GetClientInt(joueur, i_Group), steamID[joueur]);
			
			if(IsClientValid(joueur))
				CPrintToChat(joueur, "%s %N vous a viré du gang %s", TEAM, client, groupename);
		}	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action rp_PushToInteraction(Menu menu, int client)
{
	menu.AddItem("gangs", "Gangs");
}	

public int rp_Handle_PushToInteraction(int client, const char[] info)
{
	int aim = GetClientAimTarget(client, false);
	if(StrEqual(info, "gangs"))
		InvitationGroup(client, aim);
}		

int InvitationGroup(int client, int aim)
{
	char strInfo[64];
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoInvitationGroup);
	Format(STRING(strInfo), "Intéraction avec %N", aim);
	menu.SetTitle(strInfo);
	Format(STRING(strInfo), "gang|%i", aim);
	menu.AddItem(strInfo, "Gang");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoInvitationGroup(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select) 
	{
		char info[64], buffer[2][64];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		int joueur = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "gang")) 
		{
			if(rp_GetGroupInt(client, i_membres) != rp_GetGroupInt(client, i_maxMembres))
			{
				char strText[64], strIndex[64];
				char groupename[64];
				GetGroupeName(g_DB, client, STRING(groupename));
				
				Menu menu1 = new Menu(DoInvitationGroupSub1);
				menu1.SetTitle(groupename);
				
				Format(STRING(strText), "Inviter %N", joueur);
				Format(STRING(strIndex), "invitation|%i", joueur);
				if(rp_GetClientInt(joueur, i_Group) == 0)
					menu1.AddItem(strIndex, strText);
				else
					menu1.AddItem(strIndex, strText, ITEMDRAW_DISABLED);	
				
				Format(STRING(strText), "Virer %N", joueur);
				Format(STRING(strIndex), "virer|%i", joueur);			
				if(rp_GetClientInt(joueur, i_Group) == rp_GetClientInt(client, i_Group))
					menu1.AddItem(strIndex, strText);
				else
					menu1.AddItem(strIndex, strText, ITEMDRAW_DISABLED);	
				menu1.ExitButton = true;
				menu1.Display(client, MENU_TIME_FOREVER);
			}
			else
				CPrintToChat(client, "%s Vous avez atteint la limite des membres.", TEAM);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoInvitationGroupSub1(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select) 
	{
		char info[64], buffer[2][64];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		int joueur = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "invitation")) 
		{
			char strText[64], strIndex[64];
			char groupename[64];
			GetGroupeName(g_DB, client, STRING(groupename));
			
			rp_SetClientBool(joueur, b_menuOpen, true);
			Menu menu1 = new Menu(DoInvitationGroupFinal);
			Format(STRING(strText), "Invitation de %N", client);
			menu1.SetTitle(groupename);
			
			Format(STRING(strText), "Rejoindre %s", groupename);
			menu1.AddItem("", strText, ITEMDRAW_DISABLED);
			
			Format(STRING(strIndex), "accepter|%i", client);
			menu1.AddItem(strIndex, "Accepter");
			
			Format(STRING(strIndex), "refuser|%i", client);
			menu1.AddItem(strIndex, "Refuser");
				
			menu1.ExitButton = true;
			menu1.Display(joueur, MENU_TIME_FOREVER);
		}
		else if(StrEqual(buffer[0], "virer")) 
		{
			char groupename[64];
			GetGroupeName(g_DB, client, STRING(groupename));
			
			rp_SetClientInt(joueur, i_Group, 0);
			CPrintToChat(client, "%s Vous avez viré %N", TEAM, joueur);
			SetSQL_Int(g_DB, "rp_clientgroupe", "groupeid", rp_GetClientInt(joueur, i_Group), steamID[joueur]);
			
			rp_SetGroupInt(client, i_membres, rp_GetGroupInt(client, i_membres) - 1);
			UpdateGang(g_DB, "membres", rp_GetGroupInt(client, i_membres), rp_GetClientInt(client, i_Group));
			
			if(IsClientValid(joueur))
				CPrintToChat(joueur, "%s %N vous a viré du gang %s", TEAM, client, rp_GetGroupInt(client, i_maxMembres));
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoInvitationGroupFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select) 
	{
		char info[64], buffer[2][64];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		int joueur = StringToInt(buffer[1]);
		
		char groupename[64];
		GetGroupeName(g_DB, joueur, STRING(groupename));
		
		char name[64];
		rp_GetGroupString(joueur, Sz_groupeName, name, 64);
		
		if(StrEqual(buffer[0], "accepter")) 
		{
			rp_SetClientInt(client, i_Group, rp_GetClientInt(joueur, i_Group));
			SetSQL_Int(g_DB, "rp_clientgroupe", "groupeid", rp_GetClientInt(client, i_Group), steamID[client]);
			rp_SetGroupInt(client, i_membres, rp_GetGroupInt(client, i_membres) + 1);
			UpdateGang(g_DB, "membres", rp_GetGroupInt(client, i_membres), rp_GetClientInt(client, i_Group));
			
			CPrintToChat(client, "%s Vous avez accepter l'invitation de %N pour rejoindre %s.", TEAM, joueur, TEAM);
			CPrintToChat(joueur, "%s %N a accepter votre invitation.", TEAM, client);
			rp_SetClientBool(client, b_menuOpen, false);
		}
		else if(StrEqual(buffer[0], "refuser")) 
		{
			CPrintToChat(client, "%s Vous avez refuser l'invitation de %N pour rejoindre %s.", TEAM, joueur, TEAM);
			CPrintToChat(joueur, "%s %N a refuser votre invitation.", TEAM, client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu BuildGroupHistorique(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(ShowHistoryDonations);
	
	char gang[64];
	rp_GetGroupString(client, Sz_groupeName, gang, 64);
	menu.SetTitle("Historiques %s", gang);
	
	/*char buffer[128];
	Format(STRING(buffer), "SELECT * FROM rp_groupes_historique WHERE Id = %i;", rp_GetClientInt(client, i_Group));
	DBResultSet query = SQL_Query(g_DB, buffer);			
	if(query.FetchRow())
	{
		int count = SQL_GetRowCount(query);
		for(int i = 1; i <= count; i++)
		{
			char name[100][2048];
			SQL_FetchStringByName(query, "note", TEAM[count], 2048);
			menu.AddItem("", TEAM[count], ITEMDRAW_DISABLED);
		}	
	}
	delete query;*/
	
	char buffer[128], strIndex[16];
	Format(STRING(buffer), "SELECT * FROM rp_groupes_historique WHERE Id = %i;", rp_GetClientInt(client, i_Group));
	DBResultSet query = SQL_Query(g_DB, buffer);			
	int count = SQL_GetRowCount(query);
	for(int i = 1; i <= count; i++)
	{
		if(query.FetchRow())
		{
			char name[256][64];
			SQL_FetchStringByName(query, "note", name[count], 64);
			menu.AddItem(strIndex, name[count], ITEMDRAW_DISABLED);
		}
	}
	delete query;
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	