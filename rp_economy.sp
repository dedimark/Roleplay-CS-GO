#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <cstrike>
#include <multicolors>
#include <emitsoundany>
#include <roleplay>

#pragma newdecls required

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"

char 
	logFile[PLATFORM_MAX_PATH],
	steamID[MAXPLAYERS+1][32],
	dbconfig[] = "roleplay";
int 
	g_iStartMoney = 300;

Database g_DB;

public Plugin myinfo = 
{
	name = "[Roleplay] Economy", 
	author = "Benito", 
	description = "Système de Monaie & Banque", 
	version = "1.0", 
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		LoadTranslations("rp_economy.phrases");
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/rp_economy.log");
		rp_SetLogFile(logFile, "roleplay", "rp_economy");
		
		RegConsoleCmd("rp_argent", cmdMoney);
		RegConsoleCmd("rp_giveargent", cmdGiveMoney);
		RegConsoleCmd("rp_givebank", cmdGiveBankedMoney);
		RegConsoleCmd("rp_dev", Cmd_GiveMny);
		
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}

public Action Cmd_GiveMny(int client, int args)
{
	if(IsClientValid(client))
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 5000);
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
		Format(buffer, sizeof(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_economy` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `money` int(11) NOT NULL, \
		  `bank` int(11) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnMapStart() 
{	
	CreateTimer(10.0, AutoUpdateSQL, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
	
	char playerip[64];
	GetClientIP(client, playerip, sizeof(playerip));
	float ip = StringToFloat(playerip);
	rp_SetClientFloat(client, fl_PlayerIP, ip);
}

public Action cmdMoney(int client, int args) 
{	
	CPrintToChat(client, "%s %T", "MoneyAmount", LANG_SERVER, NAME, rp_GetClientInt(client, i_Money));
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	char buffer[2048];
	Format(buffer, sizeof(buffer), "INSERT IGNORE INTO `rp_economy` (`Id`, `steamid`, `playername`, `money`, `bank`, `timestamp`) VALUES (NULL, '%s', '%s', '%i', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername, g_iStartMoney);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadEconomy(client);
}

public void SQLCALLBACK_LoadEconomy(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(buffer, sizeof(buffer), "SELECT money, bank FROM rp_economy WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(SQLLoadMoneyQueryCallback, buffer, GetClientUserId(client));
}

public void forceCurrencyAndNameUpdateQuery(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	char buffer[512];
	Format(buffer, sizeof(buffer), "UPDATE rp_economy SET money = %i, bank = %i, playername = '%s' WHERE steamid = '%s';", rp_GetClientInt(client, i_Money), rp_GetClientInt(client, i_Bank), clean_playername, steamID[client]);
	g_DB.Query(SQLErrorCheckCallback, buffer);
}

public Action cmdGiveMoney(int client, int args) 
{	
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		if (args < 2) {
			ReplyToCommand(client, "%T", "GiveMoneyInvalid", LANG_SERVER);
			return Plugin_Handled;
		}
		
		char buffer[64];
		GetCmdArg(2, buffer, sizeof(buffer));
		
		int tempCurrency = StringToInt(buffer);
		if (tempCurrency < -100000 || tempCurrency > 100000) {
			ReplyToCommand(client, "%T", "InvalidValue");
			return Plugin_Handled;
		}
		
		char pattern[MAX_NAME_LENGTH + 8];
		char buffer2[MAX_NAME_LENGTH + 8];
		GetCmdArg(1, pattern, sizeof(pattern));
		int targets[64];
		bool ml = false;
		
		int count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, buffer2, sizeof(buffer2), ml);
		
		
		if (count <= 0)
			ReplyToCommand(client, "%T", "InvalidTarget", LANG_SERVER);
		else {
			for (int i = 0; i < count; i++) {
				int target = targets[i];
				rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) + tempCurrency);
			}
		}
	}
	else
		CPrintToChat(client, "%s %T", "NoAcces", LANG_SERVER, NAME);
	return Plugin_Handled;
}

public Action cmdGiveBankedMoney(int client, int args) {
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		if (args < 2) {
			ReplyToCommand(client, "%T", "GiveBankInvalid", LANG_SERVER);
			return Plugin_Handled;
		}
		
		char buffer[64];
		GetCmdArg(2, buffer, sizeof(buffer));
		
		int tempCurrency = StringToInt(buffer);
		if (tempCurrency < -100000 || tempCurrency > 100000) {
			ReplyToCommand(client, "%T", "InvalidValue");
			return Plugin_Handled;
		}
		
		char pattern[MAX_NAME_LENGTH + 8];
		char buffer2[MAX_NAME_LENGTH + 8];
		GetCmdArg(1, pattern, sizeof(pattern));
		int targets[64];
		bool ml = false;
		
		int count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, buffer2, sizeof(buffer2), ml);
		
		
		if (count <= 0)
			ReplyToCommand(client, "%T", "InvalidTarget", LANG_SERVER);
		else {
			for (int i = 0; i < count; i++) {
				int target = targets[i];
				rp_SetClientInt(target, i_Bank, rp_GetClientInt(target, i_Bank) + tempCurrency);
			}
		}
	}
	else
		CPrintToChat(client, "%s %T", "NoAcces", LANG_SERVER, NAME);
	
	return Plugin_Handled;
}

public void SQLLoadMoneyQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Money, SQL_FetchIntByName(Results, "money"));
		if(rp_GetClientInt(client, i_Money) < 0)
			rp_SetClientInt(client, i_Money, 0);
		
		rp_SetClientInt(client, i_Bank, SQL_FetchIntByName(Results, "bank"));
		if(rp_GetClientInt(client, i_Bank) < 0)
			rp_SetClientInt(client, i_Bank, 0);
	}
} 

public Action AutoUpdateSQL(Handle timer, int client) 
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientValid(i)) 
		{
			forceCurrencyAndNameUpdateQuery(i);
		}
		else
			return Plugin_Handled;
	}
			
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	if(!IsClientInGame(client))
		return;

	rp_SetClientBool(client, b_inUse, false);
}

public Action rp_OnClientInteract(int client, int aim, char[] entName, char[] entModel, char[] entClassName)
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
	
	Format(buffer, sizeof(buffer), "%T", "Bank Title", LANG_SERVER);
	menu.SetTitle(buffer);
	
	if(rp_GetClientInt(client, i_Money) > 0)
	{
		Format(buffer, sizeof(buffer), "%T", "Deposit", LANG_SERVER);
		menu.AddItem("deposer", buffer);
	}	
	else 
	{
		Format(buffer, sizeof(buffer), "%T", "Deposit", LANG_SERVER);
		menu.AddItem("deposer", buffer, ITEMDRAW_DISABLED);
	}	
	
	Format(buffer, sizeof(buffer), "%T", "Withdraw", LANG_SERVER);
	menu.AddItem("retirer", buffer);

	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int DoMenuBanque(Menu menu, MenuAction action, int client, int param) {
	
	if(action == MenuAction_Select) {
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		
		if(StrEqual(info, "deposer")) 
		{
			if(rp_GetClientInt(client, i_Money) <= 0)
				CPrintToChat(client, "%s %T", "InsufficientMoney", LANG_SERVER, NAME);	
			
			MenuDepose(client);
		}
		else if(StrEqual(info, "retirer")) {
			if(rp_GetClientInt(client, i_Bank) <= 0)
				CPrintToChat(client, "%s %T", "InsufficientBank", LANG_SERVER, NAME);		
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
	Format(buffer, sizeof(buffer), "%T", "DepositAmount", LANG_SERVER);
	menu.SetTitle(buffer);
	if(rp_GetClientInt(client, i_Money) >= 1)
	{
		Format(buffer, sizeof(buffer), "%T", "AllMoneyDeposit", LANG_SERVER);
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
	menu.SetTitle("%T", "WithdrawAmount", LANG_SERVER);
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
		Format(buffer, sizeof(buffer), "%T", "AllMoneyRetract", LANG_SERVER);
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
		menu.GetItem(param, info, sizeof(info));
		
		int sommeDepose = StringToInt(info, 10);
		
		if(sommeDepose < 0)
			CPrintToChat(client, "%s %T", "Overdraft", LANG_SERVER, NAME);		
		if(StrEqual(info, "all"))
		{
			CPrintToChat(client, "%s %T %i$", "Crediting",  LANG_SERVER, NAME, rp_GetClientInt(client, i_Money));	
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + rp_GetClientInt(client, i_Money));		
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - rp_GetClientInt(client, i_Money));
		}
		else if(rp_GetClientInt(client, i_Money) >= sommeDepose)
		{
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + sommeDepose);		
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - sommeDepose);
			CPrintToChat(client, "%s %T %i$", "Crediting",  LANG_SERVER, NAME, sommeDepose);
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
		menu.GetItem(param, info, sizeof(info));

		int sommeRetire = StringToInt(info, 10);
		if(sommeRetire > rp_GetClientInt(client, i_Bank))
			CPrintToChat(client, "%s %T", "InsufficientRequestedMoney", LANG_SERVER, NAME);	
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
		CPrintToChat(client, "%s %T %i$.", "Debited", LANG_SERVER, NAME, sommeRetire);
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

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}