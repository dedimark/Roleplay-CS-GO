/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://www.Last Fate-team.be - benitalpa1020@gmail.com
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
#include <cstrike>
#include <sdkhooks>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>
#include <smlib>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
char 
	logFile[PLATFORM_MAX_PATH],
	steamID[MAXPLAYERS + 1][32],
	model_ak47[MAXPLAYERS + 1][2048],
	smoketype[MAXPLAYERS + 1][128],
	dbconfig[] = "roleplay";
	
Handle timerJetpack[MAXPLAYERS + 1] = { null, ... };	

int timeJetpack[MAXPLAYERS + 1];
float countFuel[MAXPLAYERS + 1];

bool 
	inJetpack[MAXPLAYERS + 1],
	jetpackOn[MAXPLAYERS + 1],
	cmdJetpack[MAXPLAYERS + 1],
	activeJetpack[MAXPLAYERS + 1];
	
Database g_DB;

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] VIP",
	author = "Benito",
	description = "Système de VIP",
	version = VERSION,
	url = TEAM
};

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  E V E N T S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_vip.log");		
		Database.Connect(GotDatabase, dbconfig);
		
		RegConsoleCmd("+jetpack", Command_JetpackOn);
		RegConsoleCmd("-jetpack", Command_JetpackOff);
		RegConsoleCmd("rp_setvip", Command_SetVIP);
	}
	else
		UnloadPlugin();
}

/******************************** SQL ********************************/

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
		"CREATE TABLE IF NOT EXISTS `rp_vips` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `viptime` int(11) NOT NULL, \
		  `fuel` int(11) NOT NULL, \
		  `ak47-skin` varchar(2048) COLLATE utf8_bin NOT NULL, \
		  `smoke` varchar(128) COLLATE utf8_bin NOT NULL, \
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
	SQLCALLBACK_LoadVips(client);
}

public void SQLCALLBACK_LoadVips(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_vips WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(SQLLoadVipQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadVipQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_VipTime, SQL_FetchIntByName(Results, "viptime"));
			
		rp_SetClientInt(client, i_Fuel, SQL_FetchIntByName(Results, "fuel"));
		
		SQL_FetchStringByName(Results, "ak47-skin", model_ak47[client], 2048);
		SQL_FetchStringByName(Results, "smoke", smoketype[client], 128);
	}
} 

public void OnClientDisconnect(int client)
{
	SetSQL_Int(g_DB, "rp_vips", "viptime", rp_GetClientInt(client, i_VipTime), steamID[client]);
}	

/******************************** SKINS STUFF ********************************/

public Action rp_MenuRoleplay(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_VipTime) != 0)
		menu.AddItem("vip", "V.I.P");
}	

public int rp_HandlerMenuRoleplay(int client, const char[] info)
{
	if(StrEqual(info, "vip"))
		BuildMenuVIP(client);
}	

Menu BuildMenuVIP(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoBuildMenuVIP);
	menu.SetTitle("Last Fate - V.I.P");
	menu.AddItem("emotes", "Emotes");
	menu.AddItem("skins", "Skins");
	if(!rp_GetClientBool(client, b_isEventParticipant))
		menu.AddItem("jetpack", "Jetpack");
	else
		menu.AddItem("jetpack", "Jetpack [EVENT EN COURS]", ITEMDRAW_DISABLED);	
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
		else if(StrEqual(info, "jetpack"))
			MenuJetpack(client);
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
	menu.SetTitle("Last Fate - SKINS");
	menu.AddItem("weapon", "Armes");
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
		
		if(StrEqual(info, "weapon"))
			SkinsArme(client);
		else if(StrEqual(info, "player"))
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

Menu SkinsArme(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSkinsArme);
	menu.SetTitle("Last Fate - ARMES");
	menu.AddItem("royal", "AK-47 | Royal Guard");
	menu.AddItem("mag7", "MAG-7 | Freedom");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoSkinsArme(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "royal"))
		{
			//rp_SetWeaponSkin(client, "weapon_ak47", "models/weapons/v_ak47royalguard.mdl", "models/weapons/w_ak47royalguard.mdl", "models/weapons/w_ak47royalguard_dropped.mdl");
			model_ak47[client] = "models/weapons/v_ak47royalguard.mdl|models/weapons/w_ak47royalguard.mdl|models/weapons/w_ak47royalguard_dropped.mdl";
			UpdateSQL(g_DB, "UPDATE rp_vips SET ak47-skin = '%s' WHERE steamid = '%s';", model_ak47[client], steamID[client]);
		}
		else if(StrEqual(info, "mag7"))
		{
			//rp_SetWeaponSkin(client, "weapon_ak47", "models/weapons/v_shot_freedom.mdl", "models/weapons/w_shot_freedom.mdl", "models/weapons/w_shot_freedom_dropped.mdl");
			//model_ak47[client] = "models/weapons/v_ak47royalguard.mdl|models/weapons/w_ak47royalguard.mdl|models/weapons/w_ak47royalguard_dropped.mdl";
			//SetSQL_String(g_DB, "rp_vips", "ak47-skin", model_ak47[client], steamID[client]);
		}		
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

Menu SkinsPlayer(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSkinsPlayer);
	menu.SetTitle("Last Fate - Joueur");
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

Menu MenuJetpack(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuJetpack);
	menu.SetTitle("Last Fate - Jetpack");
	menu.AddItem("smoke", "Fumée Jetpack");
	if(activeJetpack[client])
		menu.AddItem("desactiverjetpack", "Désactiver le jetpack");
	else
		menu.AddItem("activerjetpack", "Activer le jetpack");
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoMenuJetpack(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "smoke"))
			MenuSmoke(client);
		else if(StrEqual(info, "desactiverjetpack"))
		{
			activeJetpack[client] = false;
			PrintHintText(client, "Jetpack désactivé.");			
		}
		else if(StrEqual(info, "activerjetpack"))
		{
			activeJetpack[client] = true;
			PrintHintText(client, "Jetpack activé.");
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
		if (param == MenuCancel_ExitBack)
			BuildMenuVIP(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuSmoke(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(DoMenuSmoke);
	menu.SetTitle("Last Fate - Fumée Jetpack");	
	menu.AddItem("dust_burning_engine_fire_glow", "Feu gloriphique");
	menu.AddItem("env_fire_tiny_smoke", "Feu");
	menu.AddItem("bank_steam", "Fumée blanche");
	menu.AddItem("confettib_A", "Confetti");
	menu.AddItem("env_sparks_e", "Etincelles");
	menu.AddItem("blood_pool", "Sang");	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuSmoke(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128];
		menu.GetItem(param, STRING(info));
				
		PrecacheSound("~UI/panorama/inventory_item_select_01.wav");
		EmitSoundToAll("~UI/panorama/inventory_item_select_01.wav", client, _, _, _, 0.5);
		
		smoketype[client] = info;
		UpdateSQL(g_DB, "UPDATE rp_vips SET smoke = '%s' WHERE steamid = '%s';", smoketype[client], steamID[client]);
		
		PrintHintText(client, "Votre fumée de jetpack est désormais differente.");
	}
	else if(action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
		if (param == MenuCancel_ExitBack)
			MenuJetpack(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public void rp_OnClientSpawn(int client)
{
	if(rp_GetClientInt(client, i_VipTime) >= 1)
		SetWeaponSkin(client);
}

public void OnClientPutInServer(int client)
{
	timeJetpack[client] = 4;
}	

int SetWeaponSkin(int client)
{
	char buffer[3][2048];
	ExplodeString(model_ak47[client], "|", buffer, 3, 2048);			
	if(!StrEqual(model_ak47[client], "none"))
	{					
		//rp_SetWeaponSkin(client, "weapon_ak47", buffer[0], buffer[1], buffer[2]);
	}
}	

/******************************** JETPACK ********************************/

public Action Command_JetpackOn(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	
	char arg[16];
	GetCmdArgString(STRING(arg));
	
	int buttons = GetClientButtons(client);
	if(buttons & IN_JUMP)
	{
		cmdJetpack[client] = true;
		InitJetpack(client);
	}
	else cmdJetpack[client] = false;
	
	return Plugin_Handled;
}

public Action Command_JetpackOff(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	
	char arg[16];
	GetCmdArgString(STRING(arg));
	
	cmdJetpack[client] = false;
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!inJetpack[client] && buttons & IN_JUMP && buttons & IN_USE)
	{
		inJetpack[client] = true;
		
		InitJetpack(client);
	}
}	

int InitJetpack(int client)
{
	if(IsClientValid(client))
	{
		if(activeJetpack[client])
		{
			if(IsVIP(client))
				jetpackOn[client] = true;
		}
		else 
			PrintHintText(client, "Votre jetpack est désactivé.");	
		
		if(jetpackOn[client])
		{
			if(IsValidEntity(client))
			{
				if(IsPlayerAlive(client))
				{
					if(!ADMIN_LEVEL_1(client) && rp_GetClientInt(client, i_Fuel) <= 0)
					{
						PrintHintText(client, "Vous ne possèdez plus de fuel.");		
						jetpackOn[client] = false;
						return;
					}
					else if(timeJetpack[client] == 0)
					{
						PrintHintText(client, "Le jetpack est surchauffé.");
						jetpackOn[client] = false;
						return;
					}
					else if(rp_GetClientBool(client, b_isTased))
					{
						PrintHintText(client, "Vous êtes éléctrocuté !");					
						jetpackOn[client] = false;
						return;
					}
					else if(rp_GetClientBool(client, b_isArrested))
					{
						PrintHintText(client, "Vous êtes en état d'arrestation !");					
						jetpackOn[client] = false;
						return;
					}
					
					if(timerJetpack[client] == null)
						timerJetpack[client] = CreateTimer(4.0, DesactiverJetpack, client);

					//LoadingBar("Jetpack", 4, 1.0);
					
					CreateTimer(0.1, DoJetpack, client);
				}
			}
		}
	}
}

public Action DoJetpack(Handle timer, any client)
{
	if(IsValidEntity(client) && IsPlayerAlive(client))
	{
		if(GetEntProp(client, Prop_Send, "m_iPlayerState") == 0)
		{
			int buttons = GetClientButtons(client);
			if(jetpackOn[client])
			{
				PrintHintText(client, "Fuel : %iL", rp_GetClientInt(client, i_Fuel));
				
				countFuel[client] += 0.1;
				float position[3], velocity[3], angle[3];
				GetClientAbsOrigin(client, position);
				
				if(!StrEqual(smoketype[client], "none"))
					rp_CreateParticle(position, smoketype[client], 1.0);
				
				position[2] += 32.0;
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
				GetClientEyeAngles(client, angle);
				if(velocity[2] < -1000.0)
					velocity[2] = -1000.0;
				velocity[2] += 110.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
				if(buttons & IN_JUMP && buttons & IN_USE
				|| buttons & IN_JUMP && cmdJetpack[client])
					CreateTimer(0.01, DoJetpack, client);
				else
				{
					jetpackOn[client] = false;
				}
			}
		}
	}
}

public Action DesactiverJetpack(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		if(timerJetpack[client] != INVALID_HANDLE)
			timerJetpack[client] = INVALID_HANDLE;
				
		PrecacheSound("ambient/machines/steam_release_2.wav");
		EmitSoundToAll("ambient/machines/steam_release_2.wav", client, _, _, _, 0.5);
		
		float min;
		switch(GetRandomInt(0, 3))
		{
			case 0:min = 0.0;
			case 1:min = 0.1;
			case 2:min = 0.2;
			case 3:min = 0.3;
		}
		if(countFuel[client] > min && countFuel[client] < 2.0)
			rp_SetClientInt(client, i_Fuel, rp_GetClientInt(client, i_Fuel) - 1);
		else if(countFuel[client] < 4.0)
			rp_SetClientInt(client, i_Fuel, rp_GetClientInt(client, i_Fuel) - 2);
		
		if(rp_GetClientInt(client, i_Fuel) < 0)
			rp_SetClientInt(client, i_Fuel, 0);
		
		SetSQL_Int(g_DB, "rp_vips", "fuel", rp_GetClientInt(client, i_Fuel), steamID[client]);
		
		countFuel[client] = 0.0;
		timeJetpack[client] = 0;
		jetpackOn[client] = false;
		CreateTimer(15.0, TimerCanJetpack, client);
	}
}

public Action TimerCanJetpack(Handle timer, any client)
{
	if(IsClientValid(client))
		timeJetpack[client] = 4;
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
				SQL_EscapeString(g_DB, playername, STRING(clean_playername));
				
				rp_SetClientInt(joueur[i], i_VipTime, time);
				
				char buffer[2048];
				Format(STRING(buffer), "INSERT IGNORE INTO `rp_vips` (`Id`, `steamid`, `playername`, `viptime`, `fuel`, `ak47-skin`, `smoke`, `timestamp`) VALUES (NULL, '%s', '%s', '%i', '0', 'none', 'none', CURRENT_TIMESTAMP);", steamID[joueur[i]], clean_playername, time);
				g_DB.Query(SQLErrorCheckCallback, buffer);
				
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
	
	