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
#include <geoip>
#include <emitsoundany>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];
char phone_data[MAXPLAYERS + 1][rp_phone_type][128];
char indexedPhoneNumber[MAXPLAYERS + 1][12];

Handle callTimer[MAXPLAYERS + 1];

bool canAddContact[MAXPLAYERS + 1] = { false, ... };
bool canSendMessage[MAXPLAYERS + 1] =  { false, ... };
bool noDisturb[MAXPLAYERS + 1] =  { false, ... };

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] ?", 
	author = "Benito", 
	description = "?", 
	version = VERSION, 
	url = URL
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("rp_GetPhoneData", Native_GetPhoneData);
	CreateNative("rp_SetPhoneData", Native_SetPhoneData);
}

public int Native_GetPhoneData(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	rp_item_type variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
			
	SetNativeString(3, phone_data[client][variable], maxlen);
	return -1;
}

public int Native_SetPhoneData(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	rp_item_type variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
			
	GetNativeString(3, phone_data[client][variable], maxlen);
	return -1;
}

public void OnPluginStart()
{
	GameCheck();
	rp_LoadTranslation();
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_?.log");
			
	RegConsoleCmd("phone", Cmd_Phone);
	RegConsoleCmd("rp_phone", Cmd_Phone);
	RegConsoleCmd("appeler", Cmd_Phone);
	
	AddCommandListener(Say, "say");
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_phone` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `phonenumber` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `credit` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
	
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_phone_contact` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `phonenumber` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `contactnumber` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `contactnumber` (`contactnumber`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
	
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_phone_history_call` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `phonenumber_sender` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `phonenumber_receiver` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `respond` int(1) NOT NULL, \
	  `timecall` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
	
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_phone_history_messages` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `phonenumber_sender` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `phonenumber_receiver` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `message` varchar(256) COLLATE utf8_bin NOT NULL, \
	  `viewed` int(1) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
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
	
	int number;
	char phone_random[32], phone_final[32];
	for (int i = 1; i <= 8; i++) 
	{
		number = GetRandomInt(0, 8);
		Format(STRING(phone_random), "%s%i", phone_random, number);
	}		
	
	Format(STRING(phone_final), "0%i%s", GetPhoneCountryPrefix(client), phone_random);
	
	char query[512];
	Format(STRING(query), "SELECT * FROM rp_phone WHERE phonenumber = '%s'", phone_final);	 
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	int count;
	
	while(Results.FetchRow())
		count++;		
	delete Results;
	
	if(count == 0)
	{
		char buffer[2048];
		Format(STRING(buffer), "INSERT IGNORE INTO `rp_phone` (`Id`, `steamid`, `playername`, `phonenumber`, `credit`, `timestamp`) VALUES (NULL, '%s', '%s', '%s', '25', CURRENT_TIMESTAMP);", steamID[client], clean_playername, phone_final);
		rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);	
	}
	else
		OnClientPostAdminCheck(client);
	LoadSQL(client);
}

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_phone WHERE steamid = '%s'", steamID[client]);
	rp_GetDatabase().Query(QueryCallback, buffer, GetClientUserId(client));
}

public void QueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		char phonenumber[32];
		SQL_FetchStringByName(Results, "phonenumber", STRING(phonenumber));
		rp_SetPhoneData(client, phone_number, STRING(phonenumber));
		
		char credit[32];
		SQL_FetchStringByName(Results, "credit", STRING(credit));
		rp_SetPhoneData(client, phone_credit, STRING(credit));
	}
} 

public void OnClientPutInServer(int client)
{
	noDisturb[client] = false;
}	

/***************************************************************************************

							P L U G I N  -  C O M M A N D S

***************************************************************************************/

public Action Cmd_Phone(int client, int args)
{
	if(client == 0)
	{
		char translate[64];
		Format(STRING(translate), "%T", "Command_NoAcces", LANG_SERVER);
		PrintToServer(translate);
	}	
	
	if(IsClientValid(client))
	{
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu = new Menu(DrawPhoneHome);
		menu.SetTitle("Mon Téléphone");
		menu.AddItem("contact", "Mes contactes");
		menu.AddItem("stat", "Status");
		menu.AddItem("number", "Voir mon numéro");
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}

	GetPhoneCountryPrefix(client);
}	

public int DrawPhoneHome(Menu menu, MenuAction action, int client, int param) 
{	
	if(action == MenuAction_Select) 
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "contact")) 
		{
			DrawPhoneContacts(client);
		}
		else if(StrEqual(info, "stat")) 
		{
			DrawStatus(client);
		}
		else if(StrEqual(info, "number")) 
		{
			char phonenumber[32];
			rp_GetPhoneData(client, phone_number, STRING(phonenumber));
			FakeClientCommand(client, "rp_phone");
			
			CPrintToChat(client, "%s Votre numero de téléphone est: {lightgreen}%s", TEAM, phonenumber);
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

Menu DrawStatus(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DrawStatut_Handle);
	menu.SetTitle("Définir son status de visibilité");	
	
	if(!noDisturb[client])
		menu.AddItem("nodisturb", "Occupé");
	else
		menu.AddItem("normal", "En-Ligne");	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DrawStatut_Handle(Menu menu, MenuAction action, int client, int param) 
{	
	if(action == MenuAction_Select) 
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "nodistrub")) 
			noDisturb[client] = true;
		else
			noDisturb[client] = false;
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)			
			FakeClientCommand(client, "rp_phone");
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu DrawPhoneContacts(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DrawPhoneContacts_Handle);
	menu.SetTitle("Mes contactes");
	menu.AddItem("new", "Ajouter un contact.");
	
	char phonenumber[32];
	rp_GetPhoneData(client, phone_number, STRING(phonenumber));
	
	static int maxcontact;
	
	char query[100];
	Format(STRING(query), "SELECT * FROM rp_phone_contact WHERE phonenumber = '%s'", phonenumber);	 
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	while(Results.FetchRow())
	{
		maxcontact++;
		char phone_query[32], strMenu[128];
		SQL_FetchStringByName(Results, "contactnumber", STRING(phone_query));
		
		char phone_owner[64];
		GetPhoneNumberOwnerName(phone_query, STRING(phone_owner));
		
		Format(STRING(strMenu), "%s (%s)", phone_owner, phone_query);		
		menu.AddItem(phone_query, strMenu);	
	}			
	delete Results;
	
	if(maxcontact == 0)
		menu.AddItem("", "Vous n'avez aucun contact.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DrawPhoneContacts_Handle(Menu menu, MenuAction action, int client, int param) 
{	
	if(action == MenuAction_Select) 
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "new")) 
			AddNewContact(client);
		else
		{
			char strIndex[64];
			
			rp_SetClientBool(client, b_menuOpen, true);
			Menu submenu = new Menu(DrawContactOptions);
			submenu.SetTitle("Contact: %s", info);
			
			int target = GetPhoneNumberOwnerIndex(info);
			if(IsClientValid(target))
			{
				Format(STRING(strIndex), "call|%s", info);
				
				if(!noDisturb[target])
					submenu.AddItem(strIndex, "Appeler(Occupé)", ITEMDRAW_DISABLED);
				else
					submenu.AddItem(strIndex, "Appeler");				
			}	
			else
				submenu.AddItem("", "Appeler(Non Disponible)", ITEMDRAW_DISABLED);			
						
			Format(STRING(strIndex), "message|%s", info);
			submenu.AddItem(strIndex, "Envoyer un message");
			
			Format(STRING(strIndex), "viewmsg|%s", info);
			submenu.AddItem(strIndex, "Voir les messages");
			
			Format(STRING(strIndex), "delete|%s", info);
			submenu.AddItem(strIndex, "Supprimer");
			
			submenu.ExitBackButton = true;
			submenu.ExitButton = true;
			submenu.Display(client, MENU_TIME_FOREVER);
		}	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)			
			FakeClientCommand(client, "rp_phone");
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DrawContactOptions(Menu menu, MenuAction action, int client, int param) 
{	
	if(action == MenuAction_Select) 
	{
		char info[32], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		if(StrEqual(buffer[0], "call")) 
		{
			SendCallRequest(client, buffer[1]);
		}
		else if(StrEqual(buffer[0], "message")) 
		{
			SendNewMessage(client, buffer[1]);
		}
		else if(StrEqual(buffer[0], "viewmsg")) 
		{
			ViewAllMessagesByContact(client, buffer[1]);
		}
		else if(StrEqual(buffer[0], "delete")) 
		{
			char contact_name[64], phonenumber[32];  
			GetPhoneNumberOwnerName(buffer[1], STRING(contact_name));		
			rp_GetPhoneData(client, phone_number, STRING(phonenumber));
			rp_SetClientBool(client, b_menuOpen, false);			
			CPrintToChat(client, "%s Vous avez supprimé %s(%s) de vos contactes.", TEAM, contact_name, buffer[1]);		
			UpdateSQL(rp_GetDatabase(), "DELETE FROM rp_phone_contact WHERE phonenumber = '%s' AND contactnumber = '%s'", phonenumber, buffer[1]);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)			
			DrawPhoneContacts(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu AddNewContact(int client)
{
	canAddContact[client] = true;
	rp_SetClientBool(client, b_menuOpen, true);
	Panel panel = new Panel();
	panel.SetTitle("--------Contact--------");	
	panel.DrawText("Pour ajouter un nouveau contact");
	panel.DrawText("Notez dès à présent dans le tchat le numero de téléphone de votre correspondant");
	panel.DrawText("Veuillez notez a ne faire aucune erreur lors de l'insertion du numero dans le tchat");
	panel.DrawText("Sinon l'opérateur mobile ne trouvera pas son correspondant.");
	panel.Send(client, Handler_NullCancel, 60);
}

Menu SendNewMessage(int client, char[] indexPhone)
{
	Format(indexedPhoneNumber[client], sizeof(indexedPhoneNumber[]), "%s", indexPhone);
	canSendMessage[client] = true;
	rp_SetClientBool(client, b_menuOpen, true);
	Panel panel = new Panel();
	panel.SetTitle("--------Message--------");	
	panel.DrawText("Notez dès à présent dans le tchat le message que vous souhaitez envoyer à la personne.");
	panel.DrawText("Taille maximale du message: 64 charactères.");
	panel.Send(client, Handler_NullCancel, 60);
}

Menu ViewAllMessagesByContact(int client, char[] indexPhone)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(SendViewedMessage);
	menu.SetTitle("Messages (%s)", indexPhone);
	
	char phonenumber[32];  
	rp_GetPhoneData(client, phone_number, STRING(phonenumber));
	
	menu.AddItem("", "-----Envoyé-----", ITEMDRAW_DISABLED);
	
	char query[1024];
	Format(STRING(query), "SELECT * FROM rp_phone_history_messages WHERE phonenumber_sender = '%s' AND phonenumber_receiver = '%s'", phonenumber, indexPhone);	 
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	int countS;
	while(Results.FetchRow())
	{
		countS++;
		char message_query[32];
		SQL_FetchStringByName(Results, "message", STRING(message_query));
		
		char time_query[32];
		SQL_FetchStringByName(Results, "timestamp", STRING(time_query));
		
		bool viewed = SQL_FetchBoolByName(Results, "viewed");
		
		char strMenu[256];
		if(viewed)
		{
			Format(STRING(strMenu), "%s (VU | %s)", message_query, time_query);
			menu.AddItem("", strMenu, ITEMDRAW_DISABLED);
		}	
		else
		{
			Format(STRING(strMenu), "%s (NON VU | %s)", message_query, time_query);
			menu.AddItem("", strMenu, ITEMDRAW_DISABLED);
		}			
	}			
	delete Results;
	
	if(countS == 0)
		menu.AddItem("", "Repértoire vide", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "-----Reçu-----", ITEMDRAW_DISABLED);
	
	Format(STRING(query), "SELECT * FROM rp_phone_history_messages WHERE phonenumber_sender = '%s' AND phonenumber_receiver = '%s'", indexPhone, phonenumber);	 
	Results = SQL_Query(rp_GetDatabase(), query);
	
	int countR;
	while(Results.FetchRow())
	{
		countR++;
		int id = SQL_FetchIntByName(Results, "Id"); 
		
		char message_query[32];
		SQL_FetchStringByName(Results, "message", STRING(message_query));
		
		char time_query[32];
		SQL_FetchStringByName(Results, "timestamp", STRING(time_query));
		
		bool viewed = SQL_FetchBoolByName(Results, "viewed");
		
		char strMenu[256], strIndex[10];
		Format(STRING(strMenu), "%s (%s)", message_query, time_query);
		Format(STRING(strIndex), "%s|%i", indexPhone, id);
		
		if(viewed)
			menu.AddItem("", strMenu, ITEMDRAW_DISABLED);
		else
			menu.AddItem(strIndex, strMenu);		
	}			
	delete Results;
	
	if(countR == 0)
		menu.AddItem("", "Repértoire vide", ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SendViewedMessage(Menu menu, MenuAction action, int client, int param) 
{	
	if(action == MenuAction_Select) 
	{
		char info[32], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		int target_phone = GetPhoneNumberOwnerIndex(buffer[0]);
		if(IsClientValid(target_phone))
		{
			CPrintToChat(target_phone, "%s %N a vu votre message.", TEAM, client);
		}	
		
		UpdateSQL(rp_GetDatabase(), "UPDATE `rp_phone_history_messages` SET viewed = '1' WHERE Id = '%i';", StringToInt(info));
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)			
			DrawPhoneContacts(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu SendCallRequest(int client, char[] indexPhone)
{
	int target_phone = GetPhoneNumberOwnerIndex(indexPhone);
	PrecacheSoundAny(PHONE_SENDER);
	EmitSoundToClientAny(client, PHONE_SENDER, client, _, _, _, 0.5);
	
	PrecacheSoundAny(PHONE_RECEIVER);
	EmitSoundToClientAny(client, PHONE_RECEIVER, client, _, _, _, 0.5);
	
	DataPack dp = new DataPack();
	callTimer[client] = CreateDataTimer(1.0, CallRequest, dp, TIMER_REPEAT);
	dp.WriteCell(client);
	dp.WriteCell(target_phone);
}

public Action CallRequest(Handle timer, DataPack dp)
{
	dp.Reset();
	int client = dp.ReadCell();
	int target = dp.ReadCell();
	
	if(IsClientValid(client) && IsClientValid(target))
	{
		char strIndex[32];
		Menu menu = new Menu(PlayerCallStatus);
		menu.SetTitle("%N essaye de vous appeler", client);
		
		Format(STRING(strIndex), "yes|%i", client);
		menu.AddItem(strIndex, "Décrocher");
		
		Format(STRING(strIndex), "no|%i", client);
		menu.AddItem(strIndex, "Raccrocher");
		
		menu.ExitButton = false;
		menu.Display(target, MENU_TIME_FOREVER);
	}
	else
		callTimer[target] = null;
}

public int PlayerCallStatus(Menu menu, MenuAction action, int client, int param) 
{	
	if(action == MenuAction_Select) 
	{
		char info[32], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		int caller = StringToInt(buffer[1]);
		
		callTimer[client] = null;
		FakeClientCommand(client, "stopsound");
		FakeClientCommand(caller, "stopsound");
		
		if(StrEqual(info, "yes"))
		{
			CPrintToChat(caller, "%s Vous êtes désormais en-ligne avec votre correspondant.", TEAM);
			CPrintToChat(client, "%s Vous êtes désormais en-ligne avec votre correspondant.", TEAM);
			
			rp_SetClientBool(caller, b_IsOnCall, true);
			rp_SetClientBool(client, b_IsOnCall, true);
			
			rp_SetClientInt(caller, i_PhoneCallReceiver, client);
			rp_SetClientInt(client, i_PhoneCallReceiver, caller);
		}
		else
		{
			CPrintToChat(caller, "%s %N a raccrocher à votre appel.", TEAM, client);
			CPrintToChat(client, "%s Vous êtes désormais en-ligne avec votre correspondant.", TEAM);
		}		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)			
			DrawPhoneContacts(client);
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
		
		if(canAddContact[client])
		{
			if(!String_IsNumeric(arg))
			{
				CPrintToChat(client, "%s Le numero de téléphone doit être précisé en chiffre !", TEAM);
				return Plugin_Handled;
			}
			else
			{
				canAddContact[client] = false;
				rp_SetClientBool(client, b_menuOpen, false);
				
				char phonenumber[32];  
				rp_GetPhoneData(client, phone_number, STRING(phonenumber));			
				
				if(StrEqual(arg, phonenumber))
				{
					CPrintToChat(client, "%s Vous ne pouvez pas vous rajouter à vos contacts.", TEAM);
					return Plugin_Handled;
				}
				
				char query[512];
				Format(STRING(query), "SELECT * FROM rp_phone_contact WHERE contactnumber = '%s' AND phonenumber = '%s'", arg, phonenumber);	 
				DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
				
				if(Results.FetchRow())
				{
					CPrintToChat(client, "%s Le numero spécifié existe déjà dans vos contacts, réessayez s'il vous plaît.", TEAM);
					return Plugin_Handled;
				}			
				delete Results;
				
				DrawPhoneContacts(client);
				
				Format(STRING(query), "SELECT * FROM rp_phone WHERE phonenumber = '%s'", arg);	 
				Results = SQL_Query(rp_GetDatabase(), query);
				
				int count;
				if(Results.FetchRow())
					count++;	

				if(count == 0)
					CPrintToChat(client, "%s Le numero {lightred}%s{default} ne correspond à aucun joueur.", TEAM, arg);
				else
				{
					CPrintToChat(client, "%s Le numero {lightgreen}%s{default} a désormais été rajouté a vos contacts.", TEAM, arg);
					UpdateSQL(rp_GetDatabase(), "INSERT INTO `rp_phone_contact` (`Id`, `phonenumber`, `contactnumber`, `timestamp`) VALUES (NULL, '%s', '%s', CURRENT_TIMESTAMP);", phonenumber, arg);	
				}	
				
				delete Results;
			}
		}
		else if(canSendMessage[client])	
		{
			if(strlen(arg) > 64)
			{
				CPrintToChat(client, "%s Le message est trop long (4) !", TEAM);
				return Plugin_Handled;
			}
			else
			{			
				canSendMessage[client] = false;
				rp_SetClientBool(client, b_menuOpen, false);
				DrawPhoneContacts(client);
				
				int target_phone = GetPhoneNumberOwnerIndex(indexedPhoneNumber[client]);
				char phonenumber[32];  
				rp_GetPhoneData(client, phone_number, STRING(phonenumber));
				
				if(IsClientValid(target_phone))
				{
					CPrintToChat(target_phone, "%s Vous avez un nouveau message.", TEAM);
				}	
				
				CPrintToChat(client, "%s Vous avez envoyé un message au %s.", TEAM, indexedPhoneNumber[client]);				
				UpdateSQL(rp_GetDatabase(), "INSERT INTO `rp_phone_history_messages` (`Id`, `phonenumber_sender`, `phonenumber_receiver`, `message`, `viewed`, `timestamp`) VALUES (NULL, '%s', '%s', '%s', '0', CURRENT_TIMESTAMP);", phonenumber, indexedPhoneNumber[client], arg);
				indexedPhoneNumber[client] = "";
			}
		}
	}
	
	return Plugin_Handled;	
}

stock void GetPhoneNumberOwnerName(char[] phoneNumber, char[] name, int maxlen)
{
	char query[100];
	Format(STRING(query), "SELECT playername FROM rp_phone WHERE phonenumber = '%s'", phoneNumber);	 
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	if(Results.FetchRow())
	{
		char phone_name[64];
		Results.FetchString(0, STRING(phone_name));		
		strcopy(name, maxlen, phone_name);
	}			
	delete Results;
}	

stock int GetPhoneNumberOwnerIndex(char[] phoneNumber)
{
	int owner = -1;
	
	char query[100];
	Format(STRING(query), "SELECT steamid FROM rp_phone WHERE phonenumber = '%s'", phoneNumber);	 
	DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
	
	if(Results.FetchRow())
	{
		char auth[32];
		Results.FetchString(0, STRING(auth));
		owner = Client_FindBySteamId(auth);
	}			
	delete Results;
	
	return owner;
}	

stock int GetPhoneCountryPrefix(int client)
{
	char ip[16];
	GetClientIP(client, STRING(ip));	
	char fix[3];
	GeoipCode2(ip, fix);
	
	int phonePrefix;
	if(StrEqual(fix, "BE"))
		phonePrefix = 4;
	else if(StrEqual(fix, "FR"))
		phonePrefix = 6;
	else
		phonePrefix = 0;
		
	return phonePrefix;
}	