#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <multicolors>
#include <roleplay>

#define MAXGROUPES 250
#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"

#pragma newdecls required

Database g_DB;
char dbconfig[] = "roleplay";
char logFile[PLATFORM_MAX_PATH];
char steamID[MAXPLAYERS + 1][32];
char definedName[MAXPLAYERS + 1][64];

bool canDefine[MAXPLAYERS + 1] = false;

int groupeData[MAXGROUPES + 1][int_groupe_data];

public Plugin myinfo = 
{
	name = "[Roleplay] Groupe",
	author = "Benito",
	description = "Système de groupes",
	version = "1.0",
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{	
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/rp_groupes.log");
		Database.Connect(GotDatabase, dbconfig);
		
		RegConsoleCmd("creategroupe", Cmd_Groupe);
	}
	else
		UnloadPlugin();
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
		Format(buffer, sizeof(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_groupes` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `groupename` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `owner` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `level` int(100) NOT NULL, \
		  `membres` int(100) NOT NULL, \
		  `maxmembres` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `groupename` (`groupename`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	
		Format(buffer, sizeof(buffer), 
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
	}
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	char buffer[2048];
	Format(buffer, sizeof(buffer), "INSERT IGNORE INTO `rp_clientgroupe` (`Id`, `steamid`, `playername`, `groupeid`, `timestamp`) VALUES (NULL, '%s', '%s', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadGroupes(client);
}

public void SQLCALLBACK_LoadGroupes(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(buffer, sizeof(buffer), "SELECT groupeid FROM rp_clientgroupe WHERE steamid = '%s'", steamID[client]);
	LogToFile(logFile, buffer);
	g_DB.Query(SQLLoadGroupesQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadGroupesQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Group, SQL_FetchIntByName(Results, "groupeid"));
	}
} 

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}

public Action rp_SayOnPublic(int client, char[]arg, char[] cmd, int args)
{
	if(canDefine[client])
	{
		if(strlen(arg) > 64)
		{
			CPrintToChat(client, "%s Votre nom de group est trop long ! Réessayez.", NAME);
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
	Format(buffer, sizeof(buffer), "Créer %s", definedName[client]);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(StrEqual(info, "oui")) 
		{
			char buffer[2048];
			Format(buffer, sizeof(buffer), "INSERT IGNORE INTO `rp_groupes` (`Id`, `groupename`, `owner`, `level`, `membres`, `maxmembres`, `timestamp`) VALUES (NULL, '%s', '%s', '1', '1', '25', CURRENT_TIMESTAMP);", definedName[client], steamID[client]);
			g_DB.Query(SQLErrorCheckCallback, buffer);
			
			int idgroup;
			
			Format(buffer, sizeof(buffer), "SELECT Id FROM rp_groupes WHERE owner = '%s';", steamID[client]);
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
			
			CPrintToChat(client, "%s Votre groupe %s a été créé avec succès.", NAME, definedName[client]);
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

public int rp_HandlerMenuRoleplay(int client, char[] info)
{
	if(StrEqual(info, "gang"))
		BuildMenuGroupe(client);
}	

int BuildMenuGroupe(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoBuildMenuGroupe);
	menu.SetTitle("Gangs - Roleplay");
	if(isGangOwner(client))
		menu.AddItem("remote", "Gérer mon gang");
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
		menu.GetItem(param, info, sizeof(info));
		
		if(StrEqual(info, "remote"))
			GererGang(client);
		else if(StrEqual(info, "left"))
		{
			if(IsClientValid(client))
			{
				char groupename[64];
				GetGroupeName(g_DB, client, groupename, sizeof(groupename));
				
				groupeData[rp_GetClientInt(client, i_Group)][i_Membres]--;
				UpdateGroupeMembres(g_DB, groupeData[rp_GetClientInt(client, i_Group)][i_Membres], rp_GetClientInt(client, i_Group));
				
				rp_SetClientInt(client, i_Group, 0);
				CPrintToChat(client, "%s Vous avez quitté %s", NAME, groupename);
				SetSQL_Int(g_DB, "rp_clientgroupe", "groupeid", rp_GetClientInt(client, i_Group), steamID[client]);
				rp_SetClientBool(client, b_menuOpen, false);
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

bool isGangOwner(int client)
{
	char buffer[1024];
	Format(buffer, sizeof(buffer), "SELECT owner FROM rp_groupes WHERE Id = %i;", rp_GetClientInt(client, i_Group));
	DBResultSet query = SQL_Query(g_DB, buffer);			
	if(query)
	{
		while (query.FetchRow())
		{
			char owner[32];
			query.FetchString(0, owner, sizeof(owner));
			
			if(StrEqual(owner, steamID[client]))
				return true;
		}	
	}
	delete query;
	
	return false;
}

int GetGangMembres(int client)
{
	int value;
	
	char buffer[1024];
	Format(buffer, sizeof(buffer), "SELECT membres FROM rp_groupes WHERE Id = %i;", rp_GetClientInt(client, i_Group));
	DBResultSet query = SQL_Query(g_DB, buffer);			
	if(query)
	{
		while (query.FetchRow())
		{
			value = query.FetchInt(0);
		}	
	}
	delete query;
	
	return groupeData[rp_GetClientInt(client, i_Group)][i_Membres] = value;
}

int GetGangMaxMembres(int client)
{
	int value;
	
	char buffer[1024];
	Format(buffer, sizeof(buffer), "SELECT maxmembres FROM rp_groupes WHERE Id = %i;", rp_GetClientInt(client, i_Group));
	DBResultSet query = SQL_Query(g_DB, buffer);			
	if(query)
	{
		while (query.FetchRow())
		{
			value = query.FetchInt(0);
		}	
	}
	delete query;
	
	return groupeData[rp_GetClientInt(client, i_Group)][i_MaxMembers] = value;
}

int GererGang(int client)
{
	char groupename[64], strText[64];
	GetGroupeName(g_DB, client, groupename, sizeof(groupename));
	
	Menu menu = new Menu(DoGererGang);
	menu.SetTitle(groupename);
	Format(strText, sizeof(strText), "Membres: %i", GetGangMembres(client));
	menu.AddItem("getlistmembres", strText);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoGererGang(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, info, sizeof(info));
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
					GetClientName(i, name, sizeof(name));
					Format(strIndex, sizeof(strIndex), "%i", i);
					if(i != client)
						menu1.AddItem(strIndex, name);	
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
		menu.GetItem(param, info, sizeof(info));
		int joueur = StringToInt(info);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu GererSub = new Menu(DoMenuActionMembre);		
		Format(strMenu, sizeof(strMenu), "%N :", joueur);
		GererSub.SetTitle(strMenu);
		
		Format(strMenu, sizeof(strMenu), "virer|%i", joueur);
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
		menu.GetItem(param, info, sizeof(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		int joueur = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "virer"))
		{		
			char groupename[64];
			GetGroupeName(g_DB, client, groupename, sizeof(groupename));
			
			rp_SetClientInt(joueur, i_Group, 0);
			CPrintToChat(client, "%s Vous avez viré %N", NAME, joueur);
			SetSQL_Int(g_DB, "rp_clientgroupe", "groupeid", rp_GetClientInt(joueur, i_Group), steamID[joueur]);
			
			if(IsClientValid(joueur))
				CPrintToChat(joueur, "%s %N vous a viré du gang %s", NAME, client, groupename);
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

public Action rp_OnClientInteract(int client, int aim, char[] entName, char[] entModel, char[] entClassName)
{
	if(StrContains(entClassName, "player") != -1)
	{
		if(isGangOwner(client))
		{
			InvitationGroup(client, aim);
		}	
	}	
}	

int InvitationGroup(int client, int aim)
{
	char strInfo[64];
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoInvitationGroup);
	Format(strInfo, sizeof(strInfo), "Intéraction avec %N", aim);
	menu.SetTitle(strInfo);
	Format(strInfo, sizeof(strInfo), "gang|%i", aim);
	menu.AddItem(strInfo, "Gang");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoInvitationGroup(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select) 
	{
		char info[64], buffer[2][64];
		menu.GetItem(param, info, sizeof(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		int joueur = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "gang")) 
		{
			if(GetGangMembres(client) != GetGangMaxMembres(client))
			{
				char strText[64], strIndex[64];
				char groupename[64];
				GetGroupeName(g_DB, client, groupename, sizeof(groupename));
				
				Menu menu1 = new Menu(DoInvitationGroupSub1);
				menu1.SetTitle(groupename);
				
				Format(strText, sizeof(strText), "Inviter %N", joueur);
				Format(strIndex, sizeof(strIndex), "invitation|%i", joueur);
				if(rp_GetClientInt(joueur, i_Group) == 0)
					menu1.AddItem(strIndex, strText);
				else
					menu1.AddItem(strIndex, strText, ITEMDRAW_DISABLED);	
				
				Format(strText, sizeof(strText), "Virer %N", joueur);
				Format(strIndex, sizeof(strIndex), "virer|%i", joueur);			
				if(rp_GetClientInt(joueur, i_Group) == rp_GetClientInt(client, i_Group))
					menu1.AddItem(strIndex, strText);
				else
					menu1.AddItem(strIndex, strText, ITEMDRAW_DISABLED);	
				menu1.ExitButton = true;
				menu1.Display(client, MENU_TIME_FOREVER);
			}
			else
				CPrintToChat(client, "%s Vous avez atteint la limite des membres.", NAME);
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
		menu.GetItem(param, info, sizeof(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		int joueur = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "invitation")) 
		{
			char strText[64], strIndex[64];
			char groupename[64];
			GetGroupeName(g_DB, client, groupename, sizeof(groupename));
			
			rp_SetClientBool(joueur, b_menuOpen, true);
			Menu menu1 = new Menu(DoInvitationGroupFinal);
			Format(strText, sizeof(strText), "Invitation de %N", client);
			menu1.SetTitle(groupename);
			
			Format(strText, sizeof(strText), "Rejoindre %s", groupename);
			menu1.AddItem("", strText, ITEMDRAW_DISABLED);
			
			Format(strIndex, sizeof(strIndex), "accepter|%i", client);
			menu1.AddItem(strIndex, "Accepter");
			
			Format(strIndex, sizeof(strIndex), "refuser|%i", client);
			menu1.AddItem(strIndex, "Refuser");
				
			menu1.ExitButton = true;
			menu1.Display(joueur, MENU_TIME_FOREVER);
		}
		else if(StrEqual(buffer[0], "virer")) 
		{
			char groupename[64];
			GetGroupeName(g_DB, client, groupename, sizeof(groupename));
			
			rp_SetClientInt(joueur, i_Group, 0);
			CPrintToChat(client, "%s Vous avez viré %N", NAME, joueur);
			SetSQL_Int(g_DB, "rp_clientgroupe", "groupeid", rp_GetClientInt(joueur, i_Group), steamID[joueur]);
			
			groupeData[rp_GetClientInt(client, i_Group)][i_Membres]--;
			UpdateGroupeMembres(g_DB, groupeData[rp_GetClientInt(client, i_Group)][i_Membres], rp_GetClientInt(client, i_Group));
			
			if(IsClientValid(joueur))
				CPrintToChat(joueur, "%s %N vous a viré du gang %s", NAME, client, groupename);
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
		menu.GetItem(param, info, sizeof(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		int joueur = StringToInt(buffer[1]);
		
		char groupename[64];
		GetGroupeName(g_DB, joueur, groupename, sizeof(groupename));
		
		if(StrEqual(buffer[0], "accepter")) 
		{
			rp_SetClientInt(client, i_Group, rp_GetClientInt(joueur, i_Group));
			SetSQL_Int(g_DB, "rp_clientgroupe", "groupeid", rp_GetClientInt(client, i_Group), steamID[client]);
			groupeData[rp_GetClientInt(joueur, i_Group)][i_Membres]++;
			UpdateGroupeMembres(g_DB, groupeData[rp_GetClientInt(client, i_Group)][i_Membres], rp_GetClientInt(client, i_Group));
			
			CPrintToChat(client, "%s Vous avez accepter l'invitation de %N pour rejoindre %s.", NAME, joueur, groupename);
			CPrintToChat(joueur, "%s %N a accepter votre invitation.", NAME, client);
			rp_SetClientBool(client, b_menuOpen, false);
		}
		else if(StrEqual(buffer[0], "refuser")) 
		{
			CPrintToChat(client, "%s Vous avez refuser l'invitation de %N pour rejoindre %s.", NAME, joueur, groupename);
			CPrintToChat(joueur, "%s %N a refuser votre invitation.", NAME, client);
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