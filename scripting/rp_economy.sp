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

bool canSetItemPrice[MAXPLAYERS + 1] =  { false, ... };
int SetItemSellQuantity[MAXPLAYERS + 1];
int SetItemSellId[MAXPLAYERS + 1];

int g_iStartMoney = 300;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Economy", 
	author = "Benito", 
	description = "Système de Monnaie & Banque", 
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_economy.log");
	
	RegConsoleCmd("rp_money", Cmd_GiveMoney);
	RegConsoleCmd("rp_bank", Cmd_GiveBank);
	RegConsoleCmd("donner", Cmd_GivePlayer);
	RegConsoleCmd("give", Cmd_GivePlayer);
	AddCommandListener(Say, "say");
}	

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_economy` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `money` int(100) NOT NULL, \
	  `bank` int(100) NOT NULL, \
	  `depenses` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
	
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_bankitem` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `itemid` int(10) NOT NULL, \
	  `quantity` int(100) NOT NULL, \
	  PRIMARY KEY (`Id`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
	
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_hotelvente` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `vendeur` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `itemid` int(10) NOT NULL, \
	  `quantity` int(100) NOT NULL, \
	  `price` int(100) NOT NULL, \
	  PRIMARY KEY (`Id`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

/*public void OnPluginEnd()
{
	LoopClients(client)
		SaveClient(client);
}	*/

public void OnClientDisconnect(int client)
{
	SaveClient(client);
}

public void SaveClient(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
	
	UpdateSQL(rp_GetDatabase(), "UPDATE `rp_economy` SET `money` = '%i', `bank` = '%i', `playername` = '%s', `depenses` = '%i' WHERE `steamid` = '%s';", rp_GetClientInt(client, i_Money), rp_GetClientInt(client, i_Bank), clean_playername, rp_GetClientInt(client, i_MoneySpent_Fines), steamID[client]);
}

public void OnMapStart()
{
	CreateTimer(60.0, ClearDatabaseSells, _, TIMER_REPEAT);
}	

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
	
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
	SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_economy` (`Id`, `steamid`, `playername`, `money`, `bank`, `depenses`, `timestamp`) VALUES (NULL, '%s', '%s', '%i', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername, g_iStartMoney);
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_economy WHERE steamid = '%s'", steamID[client]);
	rp_GetDatabase().Query(QueryCallback, buffer, GetClientUserId(client));
}

public void QueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Money, SQL_FetchIntByName(Results, "money"));
		
		rp_SetClientInt(client, i_Bank, SQL_FetchIntByName(Results, "bank"));
			
		rp_SetClientInt(client, i_MoneySpent_Fines, SQL_FetchIntByName(Results, "depenses"));
	}
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
		
		char name[64];
		GetCmdArg(1, STRING(name));
		
		int joueur[MAXPLAYERS+1];
		joueur = FindJoueur(client, name, true);
		
		if(joueur[0] == -1)
			return Plugin_Handled;
		
		char amountStr[64];
		GetCmdArg(2, STRING(amountStr));
		
		if(!String_IsNumeric(amountStr))
		{
			CPrintToChat(client, "%s La somme doit être précisée en chiffre !", TEAM);
			return Plugin_Handled;
		}
		
		int amount = StringToInt(amountStr);
		
		LoopClients(i)
		{
			if(IsClientValid(joueur[i]))
			{
				CPrintToChat(client, "%s Vous avez give %i$ à %N!", TEAM, amount, joueur[i]);
				CPrintToChat(joueur[i], "%s Vous avez été give %i$ par %N", TEAM, amount, client);
				rp_SetClientInt(joueur[i], i_Money, rp_GetClientInt(joueur[i], i_Money) + amount);
				rp_SetJobCapital(5, rp_GetJobCapital(5) - amount);
			}
		}
	}
	else
		NoCommandAcces(client);
		
	return Plugin_Handled;
}

public Action Cmd_GiveBank(int client, int args) 
{
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		if (args < 2) 
		{
			ReplyToCommand(client, "%T", "GiveMoneyInvalid", LANG_SERVER);
			return Plugin_Handled;
		}
		
		char name[64];
		GetCmdArg(1, STRING(name));
		
		int joueur[MAXPLAYERS+1];
		joueur = FindJoueur(client, name, true);
		
		if(joueur[0] == -1)
			return Plugin_Handled;
		
		char amountStr[64];
		GetCmdArg(2, STRING(amountStr));
		
		if(!String_IsNumeric(amountStr))
		{
			CPrintToChat(client, "%s La somme doit être précisée en chiffre !", TEAM);
			return Plugin_Handled;
		}
		
		int amount = StringToInt(amountStr);
		
		LoopClients(i)
		{
			if(IsClientValid(joueur[i]))
			{
				CPrintToChat(client, "%s Vous avez give %i$ à %N!", TEAM, amount, joueur[i]);
				CPrintToChat(joueur[i], "%s Vous avez été give %i$ par %N", TEAM, amount, client);
				rp_SetClientInt(joueur[i], i_Bank, rp_GetClientInt(joueur[i], i_Bank) + amount);
				rp_SetJobCapital(5, rp_GetJobCapital(5) - amount);
			}
		}
	}
	else
		NoCommandAcces(client);
	
	return Plugin_Handled;
}

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	if (StrContains(model, "atm_wall_back.mdl") != -1 || StrContains(model, "atm01.mdl") != -1)
	{
		if (Distance(client, target) <= 50.0)
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
	
	Format(STRING(buffer), "%T", "Deposit", LANG_SERVER);
	menu.AddItem("deposer", buffer, (rp_GetClientInt(client, i_Money) > 0)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(STRING(buffer), "%T", "Withdraw", LANG_SERVER);
	menu.AddItem("retirer", buffer);
	
	Format(STRING(buffer), "%T", "BankItem", LANG_SERVER);
	menu.AddItem("bankitem", buffer, (rp_GetClientBool(client, b_asBankedItem) == true)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);	

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
				rp_SetClientBool(client, b_menuOpen, false);
			}	
			
			MenuDepose(client);
		}
		else if(StrEqual(info, "retirer")) 
		{
			if(rp_GetClientInt(client, i_Bank) <= 0)
			{
				char translation[128];
				Format(STRING(translation), "%T", "InsufficientBank", LANG_SERVER);			
				CPrintToChat(client, "%s %s", TEAM, translation);	
				rp_SetClientBool(client, b_menuOpen, false);
			}	
			else
				MenuRetire(client);
		}
		else if(StrEqual(info, "bankitem")) 
		{
			MenuItems(client);
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

Menu MenuItems(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_MenuItem);
	menu.SetTitle("Gestion de l'inventaire");
	menu.AddItem("deposit", "Déposer des objets");
	menu.AddItem("withdraw", "Retirer des objets");
	menu.AddItem("vente", "Hôtel des ventes");
	menu.AddItem("depot", "Dépot dans le capital");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int Handle_MenuItem(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));

		if(StrEqual(info, "deposit"))	
			MenuDepositItem(client);		
		else if(StrEqual(info, "withdraw"))
			MenuWithdrawItem(client);
		else if(StrEqual(info, "vente"))	
			MenuHotelVente(client);
		else if(StrEqual(info, "depot"))
			MenuCapital(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuItems(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuDepositItem(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_ItemDeposit_Quantity);
	menu.SetTitle("Que souhaitez-vous déposer?\nVotre coffre est rempli à %i%.", 10);
	
	char strIndex[10];
	
	int count;
	for (int i = 0; i <= MAXITEMS; i++)
	{		
		if(rp_GetClientItem(client, i) >= 1)
		{
			count++;
			char item_name[32];
			rp_GetItemData(i, item_type_name, STRING(item_name));
			Format(STRING(strIndex), "%i", i);
			menu.AddItem(strIndex, item_name);
		}
				
	}
	if(count == 0)
		menu.AddItem("", "Vous n'avez pas d'objet à déposer.", ITEMDRAW_DISABLED);		
		
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handle_ItemDeposit_Quantity(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], strFormat[32];
		menu.GetItem(param, STRING(info));

		Menu quantity = new Menu(Handle_ItemDeposit_Final);	
		quantity.SetTitle("Choisissez la quantité a déposer.");
		
		int itemID = StringToInt(info);
		
		if(rp_GetClientItem(client, itemID) >= 1)
		{
			Format(STRING(strFormat), "1|%i", itemID);
			quantity.AddItem(strFormat, "1");
		}
		
		if(rp_GetClientItem(client, itemID) >= 2)
		{
			Format(STRING(strFormat), "2|%i", itemID);
			quantity.AddItem(strFormat, "2");
		}
		
		if(rp_GetClientItem(client, itemID) >= 3)
		{
			Format(STRING(strFormat), "3|%i", itemID);
			quantity.AddItem(strFormat, "3");
		}
		
		if(rp_GetClientItem(client, itemID) >= 4)
		{
			Format(STRING(strFormat), "4|%i", itemID);
			quantity.AddItem(strFormat, "4");
		}
		
		if(rp_GetClientItem(client, itemID) >= 5)
		{
			Format(STRING(strFormat), "5|%i", itemID);
			quantity.AddItem(strFormat, "5");
		}
		
		if(rp_GetClientItem(client, itemID) >= 10)
		{
			Format(STRING(strFormat), "10|%i", itemID);
			quantity.AddItem(strFormat, "10");
		}
		
		if(rp_GetClientItem(client, itemID) >= 50)
		{
			Format(STRING(strFormat), "50|%i", itemID);
			quantity.AddItem(strFormat, "50");
		}
		
		if(rp_GetClientItem(client, itemID) >= 100)
		{
			Format(STRING(strFormat), "100|%i", itemID);
			quantity.AddItem(strFormat, "100");
		}
		
		if(rp_GetClientItem(client, itemID) >= 1)	
		{
			Format(STRING(strFormat), "%i|%i", rp_GetClientItem(client, itemID), itemID);
			quantity.AddItem(strFormat, "Tout");
		}	
		
		quantity.ExitBackButton = true;
		quantity.ExitButton = true;
		quantity.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuItems(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int Handle_ItemDeposit_Final(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[32], buffer[2][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 32);
		
		int item = StringToInt(buffer[1]);
		int itemQuantity = StringToInt(buffer[0]);
		
		rp_ClientGiveItem(client, item, rp_GetClientItem(client, item) - itemQuantity);
		
		char item_name[32];
		rp_GetItemData(item, item_type_name, STRING(item_name));
		
		CPrintToChat(client, "%s Vous avez déposé %i %s", TEAM, itemQuantity, item_name);
		
		char query[100];
		Format(STRING(query), "SELECT * FROM rp_bankitem WHERE steamid = '%s' AND itemid = %i", steamID[client], item);	 
		DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
		
		if(Results.FetchRow())
		{
			UpdateSQL(rp_GetDatabase(), "UPDATE rp_bankitem SET quantity = %i WHERE steamid = '%s' AND itemid = %i;", itemQuantity, steamID[client], item);	 				
		}
		else
			//UpdateSQL(rp_GetDatabase(), "INSERT INTO `rp_bankitem` (`Id`, `steamid`, `itemid`, `quantity`) VALUES (NULL, '%s', '%i', '%i');", steamID[client], item, itemQuantity);			
			UpdateSQL(rp_GetDatabase(), "INSERT INTO `rp_bankitem` (`Id`, `steamid`, `itemid`, `quantity`) VALUES (NULL, '%s', '%i', '%i');", steamID[client], item, itemQuantity);		
			
		delete Results;
		
		rp_SetClientBool(client, b_menuOpen, true);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);	
		else if(param == MenuCancel_ExitBack)	
			MenuDepositItem(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuWithdrawItem(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_ItemWithdraw_Quantity);
	menu.SetTitle("Que souhaitez-vous retirer?\nVotre coffre est rempli à %i%.", 10);
	
	char query[100];
	Format(STRING(query), "SELECT * FROM rp_bankitem WHERE steamid = '%s'", steamID[client]);	 
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	char strIndex[32], strName[64];
	
	int count;
	while(Results.FetchRow())
	{
		count++;
		int item_query = SQL_FetchIntByName(Results, "itemid");
		int item_quantity = SQL_FetchIntByName(Results, "quantity");
		
		char item_name[32];
		rp_GetItemData(item_query, item_type_name, STRING(item_name));
		Format(STRING(strIndex), "%i|%i", item_quantity, item_query);
		Format(STRING(strName), "%s [%i]", item_name, item_quantity);
		menu.AddItem(strIndex, strName);
	}			
	delete Results;
	
	if(count == 0)
		menu.AddItem("", "Aucun objet n'est stocké.", ITEMDRAW_DISABLED);	
		
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handle_ItemWithdraw_Quantity(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], strFormat[32], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);

		Menu quantity = new Menu(Handle_ItemWithdraw_Final);	
		quantity.SetTitle("Choisissez la quantité a retirer.");
		
		int itemID = StringToInt(buffer[1]);
		int itemQuantity = StringToInt(buffer[0]);
		
		if(itemQuantity >= 1)
		{
			Format(STRING(strFormat), "1|%i", itemID);
			quantity.AddItem(strFormat, "1");
		}
		
		if(itemQuantity >= 2)
		{
			Format(STRING(strFormat), "2|%i", itemID);
			quantity.AddItem(strFormat, "2");
		}
		
		if(itemQuantity >= 3)
		{
			Format(STRING(strFormat), "3|%i", itemID);
			quantity.AddItem(strFormat, "3");
		}
		
		if(itemQuantity >= 4)
		{
			Format(STRING(strFormat), "4|%i", itemID);
			quantity.AddItem(strFormat, "4");
		}
		
		if(itemQuantity >= 5)
		{
			Format(STRING(strFormat), "5|%i", itemID);
			quantity.AddItem(strFormat, "5");
		}
		
		if(itemQuantity >= 10)
		{
			Format(STRING(strFormat), "10|%i", itemID);
			quantity.AddItem(strFormat, "10");
		}
		
		if(itemQuantity >= 50)
		{
			Format(STRING(strFormat), "50|%i", itemID);
			quantity.AddItem(strFormat, "50");
		}
		
		if(itemQuantity >= 100)
		{
			Format(STRING(strFormat), "100|%i", itemID);
			quantity.AddItem(strFormat, "100");
		}
		
		if(itemQuantity >= 1)	
		{
			Format(STRING(strFormat), "%i|%i", itemQuantity, itemID);
			quantity.AddItem(strFormat, "Tout");
		}	
		
		quantity.ExitBackButton = true;
		quantity.ExitButton = true;
		quantity.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit) 
			rp_SetClientBool(client, b_menuOpen, false);		
		else if(param == MenuCancel_ExitBack)
			MenuItems(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int Handle_ItemWithdraw_Final(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[32], buffer[2][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 32);
		
		int item = StringToInt(buffer[1]);
		int itemQuantity = StringToInt(buffer[0]);
		
		rp_ClientGiveItem(client, item, rp_GetClientItem(client, item) + itemQuantity);
		
		char query[100];
		Format(STRING(query), "SELECT quantity FROM rp_bankitem WHERE steamid = '%s' AND itemid = '%i'", steamID[client], item);	 
		DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
		
		if(Results.FetchRow())
		{
			int query_quantity = Results.FetchInt(0);
			query_quantity -= itemQuantity;
			
			char item_name[32];
			rp_GetItemData(item, item_type_name, STRING(item_name));
		
			CPrintToChat(client, "%s Vous avez retiré %i %s", TEAM, itemQuantity, item_name);
		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_bankitem` SET `quantity` = '%i' WHERE `steamid` = '%s' AND `itemid` = '%i';", query_quantity, steamID[client], item);	
		}	
			
		delete Results;
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);	
		else if(param == MenuCancel_ExitBack)	
			MenuWithdrawItem(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuCapital(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_CapitalDepot);
	menu.SetTitle("Moyen d'envoi");
	menu.AddItem("money", "Cash", (rp_GetClientInt(client, i_Money) >= 1)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("bank", "Carte Bancaire", (rp_GetClientBool(client, b_asCb) == true && rp_GetClientInt(client, i_Bank) >= 1)? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handle_CapitalDepot(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));

		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu1 = new Menu(Handle_FinalCapital);
		menu1.SetTitle("Choisissez le montant");
		
		int money = rp_GetClientInt(client, i_Money);
		int bank = rp_GetClientInt(client, i_Bank);
		if(StrEqual(info, "money"))	
		{
			if(money >= 1)
				menu1.AddItem("1|money", "1$");
			if(money >= 5)
				menu1.AddItem("5", "5$");
			if(money >= 10)
				menu1.AddItem("10|money", "10$");
			if(money >= 50)
				menu1.AddItem("50|money", "50$");
			if(money >= 100)
				menu1.AddItem("100|money", "100$");
			if(money >= 250)
				menu1.AddItem("250|money", "250$");
			if(money >= 500)
				menu1.AddItem("500|money", "500$");
			if(money >= 1000)
				menu1.AddItem("1000|money", "1000$");
			if(money >= 2500)
				menu1.AddItem("2500|money", "2500$");
			if(money >= 5000)
				menu1.AddItem("5000|money", "5000$");
			if(money >= 10000)
				menu1.AddItem("10000|money", "10000$");
			if(money >= 25000)
				menu1.AddItem("25000|money", "25000$");
			if(money >= 50000)
				menu1.AddItem("50000|money", "50000$");
			if(money >= 2)
				menu1.AddItem("all|money", "Tout mon argent");	
		}		
		else if(StrEqual(info, "bank"))
		{
			if(bank >= 1)
				menu1.AddItem("1|bank", "1$");
			if(bank >= 5)
				menu1.AddItem("5|bank", "5$");
			if(bank >= 10)
				menu1.AddItem("10|bank", "10$");
			if(bank >= 50)
				menu1.AddItem("50|bank", "50$");
			if(bank >= 100)
				menu1.AddItem("100|bank", "100$");
			if(bank >= 250)
				menu1.AddItem("250|bank", "250$");
			if(bank >= 500)
				menu1.AddItem("500|bank", "500$");
			if(bank >= 1000)
				menu1.AddItem("1000|bank", "1000$");
			if(bank >= 2500)
				menu1.AddItem("2500|bank", "2500$");
			if(bank >= 5000)
				menu1.AddItem("5000|bank", "5000$");
			if(bank >= 10000)
				menu1.AddItem("10000|bank", "10000$");
			if(bank >= 25000)
				menu1.AddItem("25000|bank", "25000$");
			if(bank >= 50000)
				menu1.AddItem("50000|bank", "50000$");
			if(bank >= 2)
				menu1.AddItem("all|bank", "Tout mon argent");
		}	

		menu1.ExitButton = true;
		menu1.ExitBackButton = true;
		menu1.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuCapital(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int Handle_FinalCapital(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[32], buffer[2][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 32);		
		
		if(StrEqual(buffer[0], "all"))
		{
			if(StrEqual(buffer[1], "bank"))
			{
				CPrintToChat(client, "%s Le transfert de %i$ de votre compte bancaire vers le capital a été effectué avec succès.", TEAM, rp_GetClientInt(client, i_Bank));
				rp_SetClientInt(client, i_Bank, 0);
				rp_SetJobCapital(rp_GetClientInt(client, i_Job), rp_GetJobCapital(rp_GetClientInt(client, i_Job)) + rp_GetClientInt(client, i_Bank));
				LogToFile(logFile, "Le joueur %N a depose tout son argent vers son capital.", client);
			}	
			else
			{
				CPrintToChat(client, "%s Le transfert de %i$ vers le capital a été effectué avec succès.", TEAM, rp_GetClientInt(client, i_Money));
				rp_SetClientInt(client, i_Money, 0);
				rp_SetJobCapital(rp_GetClientInt(client, i_Job), rp_GetJobCapital(rp_GetClientInt(client, i_Job)) + rp_GetClientInt(client, i_Money));
				LogToFile(logFile, "Le joueur %N a depose tout son argent vers son capital.", client);
			}
		}
		else
		{
			int amount = StringToInt(buffer[0]);
			
			if(StrEqual(buffer[1], "bank"))
			{
				if(rp_GetClientInt(client, i_Bank) >= amount)
				{			
					rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - amount);
					rp_SetJobCapital(rp_GetClientInt(client, i_Job), rp_GetJobCapital(rp_GetClientInt(client, i_Job)) + amount);
					CPrintToChat(client, "%s Le transfert de %i$ de votre compte bancaire vers le capital a été effectué avec succès.", TEAM, amount);
					LogToFile(logFile, "Le joueur %N a depose %i$ de son compte bancaire vers son capital.", client, amount);
				}	
				else
					CPrintToChat(client, "%s Vous n'avez pas l'argent nécessaire pour le transfert.", TEAM);
			}	
			else 
			{
				if(rp_GetClientInt(client, i_Money) >= amount)
				{				
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - amount);
					rp_SetJobCapital(rp_GetClientInt(client, i_Job), rp_GetJobCapital(rp_GetClientInt(client, i_Job)) + amount);
					CPrintToChat(client, "%s Le transfert de %i$ vers le capital a été effectué avec succès.", TEAM, amount);
					LogToFile(logFile, "Le joueur %N a depose %i$ vers son capital.", client, amount);
				}	
				else
					CPrintToChat(client, "%s Vous n'avez pas l'argent nécessaire pour le transfert.", TEAM);
			}
		}
		
		MenuCapital(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);		
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuHotelVente(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_HotelVente);
	menu.SetTitle("Hôtel des ventes");
	menu.AddItem("buy", "Acheter un objet");
	menu.AddItem("sell", "Vendre un objet");
	
	char query[100];
	Format(STRING(query), "SELECT * FROM rp_hotelvente WHERE vendeur = '%s'", steamID[client]);	 
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	if(Results.FetchRow())
	{
		menu.AddItem("edit", "Modifier une vente");
	}			
	delete Results;
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int Handle_HotelVente(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));

		if(StrEqual(info, "buy"))
			MenuHotelVente_Buy(client);
		else if(StrEqual(info, "sell"))
			MenuHotelVente_Sell(client);
		else if(StrEqual(info, "edit"))
			MenuHotelVente_Edit(client);	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuItems(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuHotelVente_Buy(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_HotelVente_Buy);
	menu.SetTitle("Choisissez un objet à acheter.");
	
	char query[100];
	Format(STRING(query), "SELECT * FROM rp_hotelvente");	 
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	char strIndex[32], strName[64];
	
	int count;
	while(Results.FetchRow())
	{
		count++;
		char seller_id[32];
		SQL_FetchStringByName(Results, "vendeur", STRING(seller_id));
		int item = SQL_FetchIntByName(Results, "itemid");
		int quantity = SQL_FetchIntByName(Results, "quantity");
		int price = SQL_FetchIntByName(Results, "price");
		
		if(quantity >= 1)
		{
			char item_name[32];
			rp_GetItemData(item, item_type_name, STRING(item_name));
			Format(STRING(strIndex), "%i|%i|%i|%s", item, quantity, price, seller_id);
			Format(STRING(strName), "%s [%i$]", item_name, price);
			menu.AddItem(strIndex, strName);
		}	
	}			
	delete Results;
	
	if(count == 0)
		menu.AddItem("", "Aucun objet n'est disponible.", ITEMDRAW_DISABLED);	
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int Handle_HotelVente_Buy(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[128], buffer[4][128];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 4, 128);
		
		/*
			buffer[0] = item choisie
			buffer[1] = quantity de l'item disponible
			buffer[2] = prix de l'item
			buffer[3] = steamid du vendeur		
		*/
		
		int item = StringToInt(buffer[0]);
		int quantity = StringToInt(buffer[1]);
		int price = StringToInt(buffer[2]);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menuQuantity = new Menu(Handle_HotelVente_Buy_Method);	
		menuQuantity.SetTitle("Choisissez la quantité à acheter.");
				
		char strFormat[128];
		if(quantity >= 1)
		{
			Format(STRING(strFormat), "1|%i|%i|%s", item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "1");
		}
		
		if(quantity >= 2)
		{
			Format(STRING(strFormat), "2|%i|%i|%s", item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "2");
		}
		
		if(quantity >= 3)
		{
			Format(STRING(strFormat), "3|%i|%i|%s", item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "3");
		}
		
		if(quantity >= 4)
		{
			Format(STRING(strFormat), "4|%i|%i|%s", item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "4");
		}
		
		if(quantity >= 5)
		{
			Format(STRING(strFormat), "5|%i|%i|%s", item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "5");
		}
		
		if(quantity >= 10)
		{
			Format(STRING(strFormat), "10|%i|%i|%s", item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "10");
		}
		
		if(quantity >= 50)
		{
			Format(STRING(strFormat), "50|%i|%i|%s", item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "50");
		}
		
		if(quantity >= 100)
		{
			Format(STRING(strFormat), "100|%i|%i|%s", item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "100");
		}
		
		if(quantity >= 1)	
		{
			Format(STRING(strFormat), "%i|%i|%i|%s", quantity, item, price, buffer[3]);
			menuQuantity.AddItem(strFormat, "Tout");
		}	
		
		menuQuantity.ExitBackButton = true;
		menuQuantity.ExitButton = true;
		menuQuantity.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int Handle_HotelVente_Buy_Method(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[128], buffer[4][128];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 4, 128);
		
		/*
			buffer[0] = quantity d'item à acheter
			buffer[1] = item à acheter
			buffer[2] = prix de l'item
			buffer[3] = steamid du vendeur		
		*/
		
		int item = StringToInt(buffer[1]);
		int quantity = StringToInt(buffer[0]);
		int price = StringToInt(buffer[2]);
		
		char strFormat[128];
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu methodBuy = new Menu(Handle_HotelVente_Buy_Final);	
		methodBuy.SetTitle("Choisissez le moyen de paiement.");
		
		Format(STRING(strFormat), "cash|%i|%i|%i|%s", quantity, item, price, buffer[3]);
		methodBuy.AddItem(strFormat, "Cash");	
		
		if(rp_GetClientBool(client, b_asCb))
		{
			Format(STRING(strFormat), "cb|%i|%i|%i|%s", quantity, item, price, buffer[3]);
			methodBuy.AddItem(strFormat, "Carte Bancaire");		
		}	
		
		methodBuy.ExitBackButton = true;
		methodBuy.ExitButton = true;
		methodBuy.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Buy(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int Handle_HotelVente_Buy_Final(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[128], buffer[5][128];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 5, 128);
		
		/*
			buffer[0] = moyen de paiement
			buffer[1] = quantity d'item à acheter
			buffer[2] = item à acheter
			buffer[3] = prix de l'item
			buffer[4] = steamid du vendeur		
		*/
		
		int quantity = StringToInt(buffer[1]);
		int item = StringToInt(buffer[2]);		
		int price = StringToInt(buffer[3]);
		price = price * quantity;
		
		char item_name[64];
		rp_GetItemData(item, item_type_name, STRING(item_name));
		
		char query[1024];
		Format(STRING(query), "SELECT quantity FROM rp_hotelvente WHERE vendeur = '%s' AND itemid = '%i'", buffer[4], item);	 
		DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
		
		if(Results.FetchRow())
		{
			int query_quantity = Results.FetchInt(0);
			query_quantity -= quantity;	
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_hotelvente` SET `quantity` = '%i' WHERE `vendeur` = '%s' AND `itemid` = '%i';", query_quantity, buffer[4], item);	
		}	
			
		delete Results;

		if(StrEqual(buffer[0], "cb"))
		{
			if(rp_GetClientInt(client, i_Bank) >= price)
			{
				rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - price);
				CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$", TEAM, quantity, item_name, price);
				
				int vendeur = Client_FindBySteamId(buffer[4]);
				if(vendeur != -1 && vendeur != client)
				{
					CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$", TEAM, quantity, item_name, vendeur, price);
					
					rp_SetClientInt(vendeur, i_Bank, rp_GetClientInt(vendeur, i_Bank) + price);
					CPrintToChat(vendeur, "%s %N vous à acheté %i %s pour %i$", TEAM, client, quantity, item_name, price);
				}
				else
				{
					Format(STRING(query), "SELECT bank FROM rp_economy WHERE steamid = '%s'", buffer[4]);	 
					DBResultSet Results1 = SQL_Query(rp_GetDatabase(), query);
					
					if(Results1.FetchRow())
					{
						int query_money = Results1.FetchInt(0);
						query_money += price;	
						UpdateSQL(rp_GetDatabase(), "UPDATE `rp_economy` SET `bank` = '%i' WHERE `steamid` = '%s';", query_money, buffer[4]);
					}	
					else
						CPrintToChat(client, "%s Vendeur inconnu !", TEAM);
					delete Results1;	
						
					CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$", TEAM, quantity, item_name, price);	
				}
			}
			else
				CPrintToChat(client, "%s Vous n'avez pas assez d'argent en banque.", TEAM);
		}	
		else if(StrEqual(buffer[0], "cash"))
		{
			if(rp_GetClientInt(client, i_Money) >= price)
			{
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - price);
				
				int vendeur = Client_FindBySteamId(buffer[4]);
				if(vendeur != -1 && vendeur != client)
				{
					CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$", TEAM, quantity, item_name, vendeur, price);
					
					rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + price);
					CPrintToChat(vendeur, "%s %N vous à acheté %i %s pour %i$", TEAM, client, quantity, item_name, price);
				}
				else
				{
					Format(STRING(query), "SELECT money FROM rp_economy WHERE steamid = '%s'", buffer[4]);	 
					DBResultSet Results1 = SQL_Query(rp_GetDatabase(), query);
					
					if(Results1.FetchRow())
					{
						int query_money = Results1.FetchInt(0);
						query_money += price;	
						UpdateSQL(rp_GetDatabase(), "UPDATE `rp_economy` SET `money` = '%i' WHERE `steamid` = '%s';", query_money, buffer[4]);
					}	
					else
						CPrintToChat(client, "%s Vendeur inconnu !", TEAM);
					delete Results1;	
						
					CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$", TEAM, quantity, item_name, price);	
				}	
			}
			else
				CPrintToChat(client, "%s Vous n'avez pas assez d'argent.", TEAM);
		}		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Buy(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuHotelVente_Sell(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_HotelVente_Sell);
	menu.SetTitle("Choisissez un objet à vendre.");
	
	char strIndex[10];
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		if(rp_GetClientItem(client, i) >= 1)
		{
			char query[1024];
			Format(STRING(query), "SELECT * FROM rp_hotelvente WHERE vendeur = '%s' AND itemid = '%i'", steamID[client], i);
			DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
			
			if(!Results.FetchRow())
			{
				char item_name[32];
				rp_GetItemData(i, item_type_name, STRING(item_name));
				Format(STRING(strIndex), "%i", i);
				menu.AddItem(strIndex, item_name);
			}	
			delete Results;
		}	
	}	
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int Handle_HotelVente_Sell(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10];
		menu.GetItem(param, STRING(info));
		int itemid = StringToInt(info);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menuQuantity = new Menu(Handle_HotelVente_Sell_Price);	
		menuQuantity.SetTitle("Choisissez la quantité à vendre.");
				
		char strFormat[128];
		if(rp_GetClientItem(client, itemid) >= 1)
		{
			Format(STRING(strFormat), "1|%i", itemid);
			menuQuantity.AddItem(strFormat, "1");
		}
		
		if(rp_GetClientItem(client, itemid) >= 2)
		{
			Format(STRING(strFormat), "2|%i", itemid);
			menuQuantity.AddItem(strFormat, "2");
		}
		
		if(rp_GetClientItem(client, itemid) >= 3)
		{
			Format(STRING(strFormat), "3|%i", itemid);
			menuQuantity.AddItem(strFormat, "3");
		}
		
		if(rp_GetClientItem(client, itemid) >= 4)
		{
			Format(STRING(strFormat), "4|%i", itemid);
			menuQuantity.AddItem(strFormat, "4");
		}
		
		if(rp_GetClientItem(client, itemid) >= 5)
		{
			Format(STRING(strFormat), "5|%i", itemid);
			menuQuantity.AddItem(strFormat, "5");
		}
		
		if(rp_GetClientItem(client, itemid) >= 10)
		{
			Format(STRING(strFormat), "10|%i", itemid);
			menuQuantity.AddItem(strFormat, "10");
		}
		
		if(rp_GetClientItem(client, itemid) >= 50)
		{
			Format(STRING(strFormat), "50|%i", itemid);
			menuQuantity.AddItem(strFormat, "50");
		}
		
		if(rp_GetClientItem(client, itemid) >= 100)
		{
			Format(STRING(strFormat), "100|%i", itemid);
			menuQuantity.AddItem(strFormat, "100");
		}
		
		if(rp_GetClientItem(client, itemid) >= 1)	
		{
			Format(STRING(strFormat), "%i|%i", rp_GetClientItem(client, itemid), itemid);
			menuQuantity.AddItem(strFormat, "Tout");
		}	
		
		menuQuantity.ExitBackButton = true;
		menuQuantity.ExitButton = true;
		menuQuantity.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Sell(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int Handle_HotelVente_Sell_Price(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], buffer[2][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 32);
		
		int quantity = StringToInt(buffer[0]);
		int itemid = StringToInt(buffer[1]);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Panel panel = new Panel();
		panel.SetTitle("Prix");	
		panel.DrawText("Ecrivez dans le tchat le prix a attribuer à l'item\npour la vente.");
		panel.DrawText("                                  ");
		panel.DrawText("Lors d'un achat de votre item, le prix est multiplié par le nombre\nde quantité mit en vente.");
		panel.Send(client, Handler_NullCancel, 25);
		
		SetItemSellQuantity[client] = quantity;
		SetItemSellId[client] = itemid;
		canSetItemPrice[client] = true;
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Sell(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action Say(int client, char[] Cmd, int args)
{
	if(IsClientValid(client))
	{
		char arg[256];
		GetCmdArgString(STRING(arg));
		StripQuotes(arg);
		TrimString(arg);
		
		if(canSetItemPrice[client])
		{
			if(String_IsNumeric(arg))
			{
				int price = StringToInt(arg);
				MenuHotelVente_Sell_Final(client, price);
				canSetItemPrice[client] = false;
				rp_SetClientBool(client, b_menuOpen, false);
			}
			else 
				CPrintToChat(client, "%s Le prix doit être précisée en chiffre !", TEAM);
		}	
	}	
}

Menu MenuHotelVente_Sell_Final(int client, int price)
{	
	char query[1024];
	Format(STRING(query), "SELECT * FROM rp_hotelvente WHERE vendeur = '%s' AND itemid = '%i'", steamID[client], SetItemSellId[client]);
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
			
	char item_name[32];
	rp_GetItemData(SetItemSellId[client], item_type_name, STRING(item_name));
	
	if(!Results.FetchRow())
	{
		CPrintToChat(client, "%s Vous avez mit à vendre %i %s (Prix Unité %i).", TEAM, SetItemSellQuantity[client], item_name, price);
		UpdateSQL(rp_GetDatabase(), "INSERT INTO `rp_hotelvente` (`Id`, `vendeur`, `itemid`, `quantity`, `price`) VALUES (NULL, '%s', '%i', '%i', '%i');", steamID[client], SetItemSellId[client], SetItemSellQuantity[client], price);		
	}	
	else
	{
		CPrintToChat(client, "%s Vous avez changé le prix de %s en %i Prix Unité.", TEAM, item_name, price);
		UpdateSQL(rp_GetDatabase(), "UPDATE `rp_hotelvente` SET `price` = '%i' WHERE vendeur = '%s' AND itemid = '%i';", price, steamID[client], SetItemSellId[client]);	
	}	
	
	delete Results;
	
	rp_ClientGiveItem(client, SetItemSellId[client], rp_GetClientItem(client, SetItemSellId[client]) - SetItemSellQuantity[client]);
	
	SetItemSellQuantity[client] = 0;
	SetItemSellId[client] = 0;
}	

public Action ClearDatabaseSells(Handle Timer)
{
	char query[1024];
	Format(STRING(query), "SELECT * FROM rp_hotelvente");
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	while(Results.FetchRow())
	{
		int itemid = SQL_FetchIntByName(Results, "itemid");
		int quantity = SQL_FetchIntByName(Results, "quantity");
		
		if(quantity == 0)
		{
			UpdateSQL(rp_GetDatabase(), "DELETE FROM rp_hotelvente WHERE itemid = '%i'", itemid);
		}	
	}	
	delete Results;
	
	Format(STRING(query), "SELECT * FROM rp_bankitem");
	DBResultSet Results1 = SQL_Query(rp_GetDatabase(), query);
	
	while(Results1.FetchRow())
	{
		int itemid = SQL_FetchIntByName(Results1, "itemid");
		int quantity = SQL_FetchIntByName(Results1, "quantity");
		
		if(quantity == 0)
		{
			UpdateSQL(rp_GetDatabase(), "DELETE FROM rp_bankitem WHERE itemid = '%i'", itemid);
		}	
	}	
	delete Results1;
}		

public Action MenuHotelVente_Edit(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_HotelVente_EditType);
	menu.SetTitle("Choisissez un objet à modifier.");
	
	char strIndex[10];
	
	char query[1024];
	Format(STRING(query), "SELECT * FROM rp_hotelvente WHERE vendeur = '%s'", steamID[client]);
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	int count;
	while(Results.FetchRow())
	{
		count++;
		int itemid = SQL_FetchIntByName(Results, "itemid");
		int quantity = SQL_FetchIntByName(Results, "quantity");
		
		if(quantity >= 1)
		{		
			char item_name[32];
			rp_GetItemData(itemid, item_type_name, STRING(item_name));
			Format(STRING(strIndex), "%i", itemid);
			menu.AddItem(strIndex, item_name);
		}	
	}
	
	if(count == 0)
		menu.AddItem("", "Vous n'avez aucun objet en vente.", ITEMDRAW_DISABLED);	
	
	delete Results;
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int Handle_HotelVente_EditType(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], strIndex[32];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu1 = new Menu(Handle_HotelVente_EditType1);
		menu1.SetTitle("Choisissez le type à modifier.");
		
		Format(STRING(strIndex), "%i|prix", StringToInt(info));
		menu1.AddItem(strIndex, "Changer le Prix");
		
		Format(STRING(strIndex), "%i|quantity", StringToInt(info));
		menu1.AddItem(strIndex, "Changer la Quantité");
		
		Format(STRING(strIndex), "%i|retirer", StringToInt(info));
		menu1.AddItem(strIndex, "Retirer la Vente");
		
		menu1.ExitButton = true;
		menu1.ExitBackButton = true;
		menu1.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Sell(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int Handle_HotelVente_EditType1(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		if(StrEqual(buffer[1], "prix"))
			MenuHotelVente_Edit_Price(client, StringToInt(buffer[0]));
		else if(StrEqual(buffer[1], "quantity"))
			MenuHotelVente_Edit_Quantity(client, StringToInt(buffer[0]));
		else if(StrEqual(buffer[1], "retirer"))
			MenuHotelVente_Edit_Delete(client, StringToInt(buffer[0]));
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Sell(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action MenuHotelVente_Edit_Price(int client, int itemID)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Panel panel = new Panel();
	panel.SetTitle("--------Prix--------");	
	panel.DrawText("Ecrivez dans le tchat le prix a reattribuer à l'item\npour la vente.");
	panel.DrawText("                                  ");
	panel.DrawText("Lors d'un achat de votre item, le prix est multiplié par le nombre\nde quantité mit en vente.");
	panel.Send(client, Handler_NullCancel, 25);
	
	canSetItemPrice[client] = true;
	SetItemSellId[client] = itemID;
}

public Action MenuHotelVente_Edit_Quantity(int client, int itemID)
{
	CPrintToChat(client, "%i", itemID);
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Menu_Edit_Quantity_Type);	
	menu.SetTitle("Choisissez le type de quantité à modifier.");	
	
	char strFormat[32];
	
	Format(STRING(strFormat), "%i|+", itemID);
	menu.AddItem(strFormat, "Ajouter");
	
	Format(STRING(strFormat), "%i|-", itemID);
	menu.AddItem(strFormat, "Retirer");
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Edit_Quantity_Type(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		if(StrEqual(buffer[1], "+"))
			Menu_Edit_Quantity_Type_Plus(client, StringToInt(buffer[0]));
		else if(StrEqual(buffer[1], "-"))
			Menu_Edit_Quantity_Type_Minus(client, StringToInt(buffer[0]));
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Edit(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action Menu_Edit_Quantity_Type_Plus(int client, int itemID)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Quantity_Type_Plus_Final);	
	menu.SetTitle("Choisissez la quantité à ajouter.");	
	
	char strFormat[32];
	if(rp_GetClientItem(client, itemID) >= 1)
	{
		Format(STRING(strFormat), "1|%i", itemID);
		menu.AddItem(strFormat, "1");
	}
	
	if(rp_GetClientItem(client, itemID) >= 2)
	{
		Format(STRING(strFormat), "2|%i", itemID);
		menu.AddItem(strFormat, "2");
	}
	
	if(rp_GetClientItem(client, itemID) >= 3)
	{
		Format(STRING(strFormat), "3|%i", itemID);
		menu.AddItem(strFormat, "3");
	}
	
	if(rp_GetClientItem(client, itemID) >= 4)
	{
		Format(STRING(strFormat), "4|%i", itemID);
		menu.AddItem(strFormat, "4");
	}
	
	if(rp_GetClientItem(client, itemID) >= 5)
	{
		Format(STRING(strFormat), "5|%i", itemID);
		menu.AddItem(strFormat, "5");
	}
	
	if(rp_GetClientItem(client, itemID) >= 10)
	{
		Format(STRING(strFormat), "10|%i", itemID);
		menu.AddItem(strFormat, "10");
	}
	
	if(rp_GetClientItem(client, itemID) >= 50)
	{
		Format(STRING(strFormat), "50|%i", itemID);
		menu.AddItem(strFormat, "50");
	}
	
	if(rp_GetClientItem(client, itemID) >= 100)
	{
		Format(STRING(strFormat), "100|%i", itemID);
		menu.AddItem(strFormat, "100");
	}
	
	if(rp_GetClientItem(client, itemID) >= 1)	
	{
		Format(STRING(strFormat), "%i|%i", rp_GetClientItem(client, itemID), itemID);
		menu.AddItem(strFormat, "Tout");
	}
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Quantity_Type_Plus_Final(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		int quantity = StringToInt(buffer[0]);
		int itemID = StringToInt(buffer[1]);
		SetItemSellId[client] = itemID;
		
		rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - quantity);
		
		char query[1024];
		Format(STRING(query), "SELECT quantity FROM rp_hotelvente WHERE vendeur = '%s' AND itemid = '%i'", steamID[client], itemID);
		DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
		
		if(Results.FetchRow())
		{
			int query_quantity = Results.FetchInt(0);
			query_quantity += quantity;
			
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_hotelvente` SET `quantity` = '%i' WHERE vendeur = '%s' AND itemid = '%i';", query_quantity, steamID[client], itemID);
		}	
		delete Results;
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Edit(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action Menu_Edit_Quantity_Type_Minus(int client, int itemID)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Quantity_Type_Minus_Final);	
	menu.SetTitle("Choisissez la quantité à retirer.");

	char query[1024];
	Format(STRING(query), "SELECT quantity FROM rp_hotelvente WHERE vendeur = '%s' AND itemid = '%i'", steamID[client], itemID);
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	if(Results.FetchRow())
	{
		int query_quantity = Results.FetchInt(0);
	
		char strFormat[32];
		if(query_quantity >= 1)
		{
			Format(STRING(strFormat), "1|%i", itemID);
			menu.AddItem(strFormat, "1");
		}
		
		if(query_quantity >= 2)
		{
			Format(STRING(strFormat), "2|%i", itemID);
			menu.AddItem(strFormat, "2");
		}
		
		if(query_quantity >= 3)
		{
			Format(STRING(strFormat), "3|%i", itemID);
			menu.AddItem(strFormat, "3");
		}
		
		if(query_quantity >= 4)
		{
			Format(STRING(strFormat), "4|%i", itemID);
			menu.AddItem(strFormat, "4");
		}
		
		if(query_quantity >= 5)
		{
			Format(STRING(strFormat), "5|%i", itemID);
			menu.AddItem(strFormat, "5");
		}
		
		if(query_quantity >= 10)
		{
			Format(STRING(strFormat), "10|%i", itemID);
			menu.AddItem(strFormat, "10");
		}
		
		if(query_quantity >= 50)
		{
			Format(STRING(strFormat), "50|%i", itemID);
			menu.AddItem(strFormat, "50");
		}
		
		if(query_quantity >= 100)
		{
			Format(STRING(strFormat), "100|%i", itemID);
			menu.AddItem(strFormat, "100");
		}
		
		if(query_quantity >= 1)	
		{
			Format(STRING(strFormat), "%i|%i", query_quantity, itemID);
			menu.AddItem(strFormat, "Tout");
		}
	}	
	delete Results;	
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Quantity_Type_Minus_Final(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		int quantity = StringToInt(buffer[0]);
		int itemID = StringToInt(buffer[1]);
		SetItemSellId[client] = itemID;
		
		rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) + quantity);
		
		char query[1024];
		Format(STRING(query), "SELECT quantity FROM rp_hotelvente WHERE vendeur = '%s' AND itemid = '%i'", steamID[client], itemID);
		DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
		
		if(Results.FetchRow())
		{
			int query_quantity = Results.FetchInt(0);
			query_quantity -= quantity;
			
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_hotelvente` SET `quantity` = '%i' WHERE vendeur = '%s' AND itemid = '%i';", query_quantity, steamID[client], itemID);
		}	
		delete Results;
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Edit(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action MenuHotelVente_Edit_Delete(int client, int itemID)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(MenuHotelVente_Edit_Delete_Final);	
	menu.SetTitle("Confirmez votre choix.");	
	
	char strFormat[32];
	
	Format(STRING(strFormat), "%i|oui", itemID);
	menu.AddItem(strFormat, "Oui, Retirer");
	
	menu.AddItem("", "Non, Annuler");
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHotelVente_Edit_Delete_Final(Menu menu, MenuAction action, int client, int param)
{	
	if(action == MenuAction_Select)
	{
		char info[10], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		int itemID = StringToInt(buffer[0]);
		
		if(StrEqual(buffer[1], "oui"))
		{		
			char query[1024];
			Format(STRING(query), "SELECT quantity FROM rp_hotelvente WHERE vendeur = '%s' AND itemid = '%i'", steamID[client], itemID);
			DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
			
			if(Results.FetchRow())
			{
				int query_quantity = Results.FetchInt(0);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) + query_quantity);
				
				UpdateSQL(rp_GetDatabase(), "DELETE FROM rp_hotelvente WHERE vendeur = '%s' AND itemid = '%i'", steamID[client], itemID);
				
				char item_name[64];
				rp_GetItemData(itemID, item_type_name, STRING(item_name));
				
				CPrintToChat(client, "%s Vous avez retiré %s de l'hôtel des ventes.", TEAM, item_name);
			}	
			delete Results;
		}
		else
			rp_SetClientBool(client, b_menuOpen, false);		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuHotelVente_Edit(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action Cmd_GivePlayer(int client, int arg)
{
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}
	
	int target = GetClientAimTarget(client, true);
	if(!IsClientValid(target))
	{
		CPrintToChat(client, "%s Vous dêvez viser un joueur valide.", TEAM);
		return Plugin_Handled;
	}
	else if(arg < 1)
	{
		char args_cmd[32];
		GetCmdArg(0, STRING(args_cmd));
		CPrintToChat(client, "%s Utilisation: /%s <somme>.", TEAM, args_cmd);
		return Plugin_Handled;
	}
	
	char args[32];
	GetCmdArg(1, STRING(args));
	if(!String_IsNumeric(args))
	{
		CPrintToChat(client, "%s La somme doit être précisée en chiffre !", TEAM);
		return Plugin_Handled;
	}
	int amount = StringToInt(args);
		
	if(rp_GetClientInt(client, i_Money) >= amount)
	{
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - amount);
		rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) + amount);
		CPrintToChat(client, "%s Vous avez donnée %i$ à %N.", TEAM, amount, target);
		CPrintToChat(target, "%s %N vous a donner %i$.", TEAM, client, amount);
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas assez d'argent.", TEAM);
		
	return Plugin_Handled;
}		