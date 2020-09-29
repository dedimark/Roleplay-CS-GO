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
#include <multicolors>
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char steamID[MAXPLAYERS + 1][32];	
int points[MAXPLAYERS + 1];
KeyValues kv;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/

public Plugin myinfo = 
{
	name = "[Roleplay] Voitures",
	author = "Benito",
	description = "Système de voitures",
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
	
	RegConsoleCmd("permis", Cmd_Permis);
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_permis` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `permis` int(1) NOT NULL, \
	  `points` int(50) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}


public void OnMapStart()
{
	kv = new KeyValues("Permis");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/permis.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/permis.cfg NOT FOUND");
	}
}	
/***************************************************************************************

							P L U G I N  -  N A T I V E

***************************************************************************************/

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public Action Cmd_Permis(int client, int args)
{
	if(IsClientValid(client))
	{
		if(!rp_GetClientBool(client, b_asPermis))
		{	
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menu = new Menu(MenuHandle_Questions);
			menu.SetTitle("Passer son permis");
			menu.AddItem("oui", "Oui");
			menu.AddItem("non", "Non");
			menu.ExitButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		}	
	}
}	

public int MenuHandle_Questions(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "oui"))
			StartQuestions(client);
		else
		{
			CPrintToChat(client, "%s Rouler sans permis est illégal.", TEAM);
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

Menu StartQuestions(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Panel panel = new Panel();
	
	if(kv.JumpToKey("1"))
	{	
		char question[128];
		kv.GetString("question", STRING(question));
		panel.SetTitle(question);
		
		int maxreponses = kv.GetNum("maxreponses");
		for (int i = 1; i <= maxreponses; i++)
		{	
			char nb[10];
			IntToString(i, STRING(nb));
			
			char types[32];
			kv.GetString(nb, STRING(types));
			
			panel.DrawItem(types);
		}	
	}	

	kv.Rewind();	
	delete kv;
	
	panel.Send(client, Handle_Questions1, 20);	 
	delete panel;
}	

public int Handle_Questions1(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		//switch(param)
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}