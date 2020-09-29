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
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>
#include <smlib>
#include <unixtime_sourcemod>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char 
	logFile[PLATFORM_MAX_PATH],
	steamID[MAXPLAYERS + 1][32];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] VIP",
	author = "Benito",
	description = "Système de VIP",
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_vip.log");		
	
	RegConsoleCmd("rp_setvip", Command_SetVIP);
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_vips` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `viptime` int(11) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPostAdminCheck(int client) 
{	
	LoadVip(client);
}	

public void OnClientDisconnect(int client)
{
	UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vips` SET `viptime` = '%i' WHERE `steamid` = '%s';", rp_GetClientInt(client, i_VipTime), steamID[client]);
}

public void LoadVip(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_vips WHERE steamid = '%s'", steamID[client]);
	rp_GetDatabase().Query(SQLCallback, buffer, GetClientUserId(client));
}

public void SQLCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_VipTime, SQL_FetchIntByName(Results, "viptime"));
	}
} 

/******************************** SKINS STUFF ********************************/

public Action RP_OnPlayerRoleplay(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_VipTime) != 0)
		menu.AddItem("vip", "V.I.P");
}	

public int RP_OnPlayerRoleplayHandle(int client, const char[] info)
{
	if(StrEqual(info, "vip"))
		BuildMenuVIP(client);
}	

Menu BuildMenuVIP(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoBuildMenuVIP);
	menu.SetTitle("Roleplay - V.I.P");
	menu.AddItem("emotes", "Emotes");
	menu.AddItem("skins", "Skins");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoBuildMenuVIP(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "emotes"))
			FakeClientCommand(client, "sm_emotes");
		else if(StrEqual(info, "skins"))
			MenuSkinsVIP(client);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
		if (param == MenuCancel_ExitBack)
			FakeClientCommand(client, "rp");
	}
	else if (action == MenuAction_End)
		delete menu;
}	

Menu MenuSkinsVIP(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuSkinsVIP);
	menu.SetTitle("Roleplay - SKINS");
	menu.AddItem("player", "PlayerModels");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoMenuSkinsVIP(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "player"))
			SkinsPlayer(client);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
		if (param == MenuCancel_ExitBack)
			BuildMenuVIP(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}	

Menu SkinsPlayer(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSkinsPlayer);
	menu.SetTitle("Roleplay - Joueur");
	menu.AddItem("models/spiderman.mdl", "Spiderman");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoSkinsPlayer(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[128], buffer[1][128];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 1, 128);
		
		rp_SetClientString(client, sz_Skin, buffer[0], 128);
		rp_SetSkin(client, buffer[0]);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
		if (param == MenuCancel_ExitBack)
			MenuSkinsVIP(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}	

public Action Command_SetVIP(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	else if (args < 1)
	{
		CPrintToChat(client, "%s Utilisation: !rp_setvip <pseudo|Steam ID|IP> <temps en minutes|0 permanent>", TEAM);
		return Plugin_Handled;
	}
	
	char pseudo[256];
	GetCmdArg(1, STRING(pseudo));
	
	char strTime[256];
	GetCmdArg(2, STRING(strTime));
	int time = StringToInt(strTime);
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, pseudo, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
		
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				char playername[MAX_NAME_LENGTH + 8];
				GetClientName(joueur[i], STRING(playername));
				char clean_playername[MAX_NAME_LENGTH * 2 + 16];
				SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
				
				rp_SetClientInt(joueur[i], i_VipTime, time);
				
				char buffer[2048];
				Format(STRING(buffer), "INSERT IGNORE INTO `rp_vips` (`Id`, `steamid`, `playername`, `viptime`, `fuel`, `ak47-skin`, `smoke`, `timestamp`) VALUES (NULL, '%s', '%s', '%i', '0', 'none', 'none', CURRENT_TIMESTAMP);", steamID[joueur[i]], clean_playername, time);
				rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
				
				int calcul = GetTime() + rp_GetClientInt(joueur[i], i_VipTime);
				
				int iYear, iMonth, iDay, iHour, iMinute, iSecond;
				UnixToTime( calcul , iYear , iMonth , iDay , iHour , iMinute , iSecond , UT_TIMEZONE_CEST );
								
				if(client != joueur[i])
					CPrintToChat(joueur[i], "%s Vous êtes désormais {yellow}VIP {default}jusqu'au {green}%02d/%02d/%d {default}à {green}%02d:%02d:%02d" , TEAM, iDay, iMonth , iYear , iHour , iMinute , iSecond );	
				CPrintToChat(client, "%s Vous avez mit %N {yellow}VIP {default}jusqu'au {green}%02d/%02d/%d {default}à {green}%02d:%02d:%02d" , TEAM, iDay, iMonth , iYear , iHour , iMinute , iSecond );
						
				Format(STRING(buffer), "%02d/%02d/%d à %02d:%02d:%02d" , iDay, iMonth, iYear, iHour, iMinute, iSecond);
				
				char hostname[128];
				GetConVarString(FindConVar("hostname"), STRING(hostname));
				
				char playerName[128];
				GetClientName(joueur[i], STRING(playerName));
				
				DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
				hook.SlackMode = true;	
				hook.SetUsername("Roleplay");	
				
				MessageEmbed Embed = new MessageEmbed();	
				Embed.SetColor("#00fd29");
				Embed.SetTitle(hostname);
				Embed.SetTitleLink("https://vr-hosting.fr/");
				Embed.AddField("Message", "V.I.P", false);
				Embed.AddField("Joueur", playerName, false);
				Embed.AddField("Date", buffer, false);		
				Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
				Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
				Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
				
				hook.Embed(Embed);	
				hook.Send();
				delete hook;
			}
		}
	}
	
	return Plugin_Handled;
}	
	
	