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
#include <sdkhooks>
#include <smlib>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>
 
/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/

char logFile[PLATFORM_MAX_PATH];
char steamID[MAXPLAYERS + 1][64];
char dbconfig[] = "roleplay";

int g_iStartMoney = 300;

Database g_DB;

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Economy", 
	author = "Benito", 
	description = "Système de Monnaie & Banque", 
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
		GameCheck();
		
		LoadTranslations("rp_economy.phrases");
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_economy.log");
		rp_SetLogFile(logFile, "roleplay", "rp_economy");
		
		RegConsoleCmd("rp_giveargent", Cmd_GiveMoney);
		RegConsoleCmd("rp_givebank", Cmd_GiveBank);
		
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}	

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("%T: %s", "DatabaseError", LANG_SERVER, error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		char buffer[4096];
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_economy` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `money` int(100) NOT NULL, \
		  `bank` int(100) NOT NULL, \
		  `depenses` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	char steamID_64[64];
	GetClientAuthId(client, AuthId_SteamID64, STRING(steamID_64));	
	strcopy(steamID[client], sizeof(steamID[]), steamID_64);
	
	char playerip[64];
	GetClientIP(client, STRING(playerip));
	float ip = StringToFloat(playerip);
	rp_SetClientFloat(client, fl_PlayerIP, ip);
}

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_economy` (`Id`, `steamid`, `playername`, `money`, `bank`, `depenses`, `timestamp`) VALUES (NULL, '%s', '%s', '%i', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername, g_iStartMoney);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadEconomy(client);
}

public void SQLCALLBACK_LoadEconomy(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_economy WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(SQLLoadMoneyQueryCallback, buffer, GetClientUserId(client));
}

public void OnMapEnd()
{
	LoopClients(client)
		forceCurrencyAndNameUpdateQuery(client);
}

public void rp_OnClientDisconnect(int client)
{
	forceCurrencyAndNameUpdateQuery(client);
}	

public void forceCurrencyAndNameUpdateQuery(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[512];
	Format(STRING(buffer), "UPDATE rp_economy SET money = %i, bank = %i, playername = '%s', depenses = %i WHERE steamid = '%s';", rp_GetClientInt(client, i_Money), rp_GetClientInt(client, i_Bank), clean_playername, rp_GetClientInt(client, i_MoneySpent_Fines), steamID[client]);
	g_DB.Query(SQLErrorCheckCallback, buffer);
}

public Action Cmd_GiveMoney(int client, int args) 
{	
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		if (args < 2) 
		{
			ReplyToCommand(client, "%T", "GiveMoneyInvalid", LANG_SERVER);
			return Plugin_Handled;
		}
		
		char pseudo[256];
		GetCmdArg(1, STRING(pseudo));
		
		int joueur[MAXPLAYERS+1];
		joueur = FindJoueur(client, pseudo, true);
		
		if(joueur[0] == -1)
			return Plugin_Handled;
		
		char buffer[64];
		GetCmdArg(2, STRING(buffer));
		
		int tempCurrency = StringToInt(buffer);
		if (tempCurrency < -100000 || tempCurrency > 100000) 
		{
			ReplyToCommand(client, "%T", "InvalidValue", LANG_SERVER);
			return Plugin_Handled;
		}
		
		LoopClients(i)
		{
			if(IsClientValid(joueur[i]))
			{
				char translation[128];
				Format(STRING(translation), "%T", LANG_SERVER, tempCurrency);
				
				CPrintToChat(joueur[i], translation);
				rp_SetClientInt(joueur[i], i_Money, rp_GetClientInt(joueur[i], i_Money) + tempCurrency);
			}
		}
	}
	else
		CPrintToChat(client, "%s %T", "NoAcces", LANG_SERVER, TEAM);
	return Plugin_Handled;
}

public Action Cmd_GiveBank(int client, int args) 
{
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		if (args < 2) {
			ReplyToCommand(client, "%T", "GiveBankInvalid", LANG_SERVER);
			return Plugin_Handled;
		}
		
		char pseudo[256];
		GetCmdArg(1, STRING(pseudo));
		
		int joueur[MAXPLAYERS+1];
		joueur = FindJoueur(client, pseudo, true);
		
		if(joueur[0] == -1)
			return Plugin_Handled;
		
		char buffer[64];
		GetCmdArg(2, STRING(buffer));
		
		int tempCurrency = StringToInt(buffer);
		if (tempCurrency < -100000 || tempCurrency > 100000) 
		{
			ReplyToCommand(client, "%T", "InvalidValue", LANG_SERVER);
			return Plugin_Handled;
		}
				
		LoopClients(i)
		{
			if(IsClientValid(joueur[i]))
			{
				char translation[128];
				Format(STRING(translation), "%T", LANG_SERVER, tempCurrency);
				
				CPrintToChat(joueur[i], translation);
				rp_SetClientInt(joueur[i], i_Bank, rp_GetClientInt(joueur[i], i_Bank) + tempCurrency);
			}
		}
	}
	else
		NoCommandAcces(client);
	
	return Plugin_Handled;
}

public void SQLLoadMoneyQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Money, SQL_FetchIntByName(Results, "money"));
		
		rp_SetClientInt(client, i_Bank, SQL_FetchIntByName(Results, "bank"));
			
		rp_SetClientInt(client, i_MoneySpent_Fines, SQL_FetchIntByName(Results, "depenses"));
	}
} 

public void OnClientDisconnect(int client)
{
	if(!IsClientInGame(client))
		return;

	rp_SetClientBool(client, b_inUse, false);
}

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if (StrContains(entModel, "atm_wall_back.mdl") != -1 || StrContains(entModel, "atm01.mdl") != -1)
	{
		if (Distance(client, aim) <= 50.0)
			MenuBanque(client);
	}
}			

Menu MenuBanque(int client)
{	
	char buffer[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(DoMenuBanque);	
	
	Format(STRING(buffer), "%T", "Bank Title", LANG_SERVER);
	menu.SetTitle(buffer);
	
	if(rp_GetClientInt(client, i_Money) > 0)
	{
		Format(STRING(buffer), "%T", "Deposit", LANG_SERVER);
		menu.AddItem("deposer", buffer);
	}	
	else 
	{
		Format(STRING(buffer), "%T", "Deposit", LANG_SERVER);
		menu.AddItem("deposer", buffer, ITEMDRAW_DISABLED);
	}	
	
	Format(STRING(buffer), "%T", "Withdraw", LANG_SERVER);
	menu.AddItem("retirer", buffer);

	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int DoMenuBanque(Menu menu, MenuAction action, int client, int param) {
	
	if(action == MenuAction_Select) {
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "deposer")) 
		{
			if(rp_GetClientInt(client, i_Money) <= 0)
			{
				char translation[128];
				Format(STRING(translation), "%T", "InsufficientMoney", LANG_SERVER);			
				CPrintToChat(client, "%s %s", TEAM, translation);	
			}	
			
			MenuDepose(client);
		}
		else if(StrEqual(info, "retirer")) {
			if(rp_GetClientInt(client, i_Bank) <= 0)
			{
				char translation[128];
				Format(STRING(translation), "%T", "InsufficientBank", LANG_SERVER);			
				CPrintToChat(client, "%s %s", TEAM, translation);	
			}	
			else
				MenuRetire(client);
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

Menu MenuDepose(int client)
{
	char buffer[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(DoMenuDepose);
	Format(STRING(buffer), "%T", "DepositAmount", LANG_SERVER);
	menu.SetTitle(buffer);
	if(rp_GetClientInt(client, i_Money) >= 1)
	{
		Format(STRING(buffer), "%T", "AllMoneyDeposit", LANG_SERVER);
		menu.AddItem("all", buffer);
	}	
	if(rp_GetClientInt(client, i_Money) >= 1)
		menu.AddItem("1", "1$");
	if(rp_GetClientInt(client, i_Money) >= 5)
		menu.AddItem("5", "5$");
	if(rp_GetClientInt(client, i_Money) >= 10)
		menu.AddItem("10", "10$");
	if(rp_GetClientInt(client, i_Money) >= 50)
		menu.AddItem("50", "50$");
	if(rp_GetClientInt(client, i_Money) >= 100)
		menu.AddItem("100", "100$");
	if(rp_GetClientInt(client, i_Money) >= 250)
		menu.AddItem("250", "250$");
	if(rp_GetClientInt(client, i_Money) >= 500)
		menu.AddItem("500", "500$");
	if(rp_GetClientInt(client, i_Money) >= 1000)
		menu.AddItem("1000", "1000$");
	if(rp_GetClientInt(client, i_Money) >= 2500)
		menu.AddItem("2500", "2500$");
	if(rp_GetClientInt(client, i_Money) >= 5000)
		menu.AddItem("5000", "5000$");
	if(rp_GetClientInt(client, i_Money) >= 10000)
		menu.AddItem("10000", "10000$");
	if(rp_GetClientInt(client, i_Money) >= 25000)
		menu.AddItem("25000", "25000$");
	if(rp_GetClientInt(client, i_Money) >= 50000)
		menu.AddItem("50000", "50000$");
	
	menu.ExitButton = true;
	menu.Display(client, 30);	
}

Menu MenuRetire(int client)
{	
	char buffer[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(DoMenuRetirer);	
	Format(STRING(buffer), "%T", "WithdrawAmount", LANG_SERVER);
	menu.SetTitle(buffer);
	if(rp_GetClientInt(client, i_Bank) >= 1)
		menu.AddItem("1", "1$");
	if(rp_GetClientInt(client, i_Bank) >= 5)
		menu.AddItem("5", "5$");
	if(rp_GetClientInt(client, i_Bank) >= 10)
		menu.AddItem("10", "10$");
	if(rp_GetClientInt(client, i_Bank) >= 50)
		menu.AddItem("50", "50$");
	if(rp_GetClientInt(client, i_Bank) >= 100)
		menu.AddItem("100", "100$");
	if(rp_GetClientInt(client, i_Bank) >= 250)
		menu.AddItem("250", "250$");
	if(rp_GetClientInt(client, i_Bank) >= 500)
		menu.AddItem("500", "500$");
	if(rp_GetClientInt(client, i_Bank) >= 1000)
		menu.AddItem("1000", "1000$");
	if(rp_GetClientInt(client, i_Bank) >= 2500)
		menu.AddItem("2500", "2500$");
	if(rp_GetClientInt(client, i_Bank) >= 5000)
		menu.AddItem("5000", "5000$");
	if(rp_GetClientInt(client, i_Bank) >= 10000)
		menu.AddItem("10000", "10000$");
	if(rp_GetClientInt(client, i_Bank) >= 25000)
		menu.AddItem("25000", "25000$");
	if(rp_GetClientInt(client, i_Bank) >= 50000)
		menu.AddItem("50000", "50000$");
	if(rp_GetClientInt(client, i_Bank) >= 2)
	{
		Format(STRING(buffer), "%T", "AllMoneyRetract", LANG_SERVER);
		menu.AddItem("all", buffer, ITEMDRAW_DISABLED);
	}	
	
	menu.ExitButton = true;
	menu.Display(client, 30);	
}

public int DoMenuDepose(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		int sommeDepose = StringToInt(info, 10);
		
		if(sommeDepose < 0)
		{
			char buffer[128];
			Format(STRING(buffer), "%T", "Overdraft", LANG_SERVER);		
			CPrintToChat(client, "%s %s", TEAM, buffer);	
		}	
		if(StrEqual(info, "all"))
		{
			char buffer[128];
			Format(STRING(buffer), "%T", "Crediting", LANG_SERVER, rp_GetClientInt(client, i_Money));			
			CPrintToChat(client, "%s %s", TEAM, buffer);	
			
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + rp_GetClientInt(client, i_Money));		
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - rp_GetClientInt(client, i_Money));
		}
		else if(rp_GetClientInt(client, i_Money) >= sommeDepose)
		{
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + sommeDepose);		
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - sommeDepose);
			
			char buffer[128];
			Format(STRING(buffer), "%T", "Crediting", LANG_SERVER, sommeDepose);			
			CPrintToChat(client, "%s %s", TEAM, buffer);
			
			EmitCashSound(client, sommeDepose);
			MenuDepose(client);
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

public int DoMenuRetirer(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));

		int sommeRetire = StringToInt(info, 10);
		if(sommeRetire > rp_GetClientInt(client, i_Bank))
		{
			char buffer[128];
			Format(STRING(buffer), "%T", "InsufficientRequestedMoney", LANG_SERVER);
			CPrintToChat(client, "%s %s", TEAM, buffer);	
		}	
		if(StrEqual(info, "all"))
		{
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + rp_GetClientInt(client, i_Bank));
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - rp_GetClientInt(client, i_Bank));
		}
		else
		{
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + sommeRetire);
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - sommeRetire);
			
			MenuRetire(client);
		}
		
		char buffer[128];
		Format(STRING(buffer), "%T", "Debited", LANG_SERVER, sommeRetire);			
		CPrintToChat(client, "%s %s", TEAM, buffer);
		
		EmitCashSound(client, sommeRetire);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}