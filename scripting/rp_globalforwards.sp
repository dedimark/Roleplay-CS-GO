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
#pragma tabsize 0
#pragma newdecls required

/***************************************************************************************

							P L U G I N  -  I N C L U D E S

***************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <roleplay>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <emitsoundany>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
GlobalForward g_DeathForward;
GlobalForward g_SpawnForward;
GlobalForward g_ConnectForward;
GlobalForward g_DisconnectForward;
GlobalForward g_InteractForward;
GlobalForward g_DuckForward;
GlobalForward g_ReloadForward;
GlobalForward g_OnClientHurt;
GlobalForward g_OnClientTakeDamage;
GlobalForward g_OnWeaponFire;
int g_iTimerRespawn[66];


/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Global Forward",
	author = "Benito",
	description = "Global Event en forward pour les utilisation uniques",
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
	
	/*------------------------------------1------------------------------------*/
	g_DeathForward = new GlobalForward("RP_OnPlayerDeath", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	HookEvent("player_death", OnPlayerDeath);
	/*------------------------------------2------------------------------------*/
	g_SpawnForward = new GlobalForward("RP_OnPlayerSpawn", ET_Event, Param_Cell);
	HookEvent("player_spawn", OnPlayerSpawn);
	/*------------------------------------3------------------------------------*/
	g_ConnectForward = new GlobalForward("RP_OnPlayerConnect", ET_Event, Param_Cell);
	HookEvent("player_connect", OnPlayerConnect, EventHookMode_Pre);
	/*------------------------------------4------------------------------------*/
	g_DisconnectForward = new GlobalForward("RP_OnPlayerDisconnect", ET_Event, Param_Cell);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	/*------------------------------------5------------------------------------*/
	g_InteractForward = new GlobalForward("RP_OnPlayerInteract", ET_Event, Param_Cell, Param_Cell, Param_String, Param_String, Param_String);
	/*------------------------------------6------------------------------------*/
	g_OnClientHurt = new GlobalForward("RP_OnPlayerGetHurt", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
	/*------------------------------------7------------------------------------*/
	g_OnWeaponFire = new GlobalForward("RP_OnPlayerFire", ET_Event, Param_Cell, Param_Cell, Param_String);
	HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);
	/*------------------------------------8------------------------------------*/
	//g_OnClientTakeDamage = new GlobalForward("RP_OnPlayerTakeDamage", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	/*------------------------------------9------------------------------------*/
	g_DuckForward = new GlobalForward("RP_OnPlayerDuck", ET_Event, Param_Cell);
	/*------------------------------------10------------------------------------*/
	g_ReloadForward = new GlobalForward("RP_OnPlayerReload", ET_Event, Param_Cell);
	
	/*				DISABLED				*/
	
	HookEvent("player_changename", BlockEvent, EventHookMode_Pre);
	HookEvent("weapon_fire_on_empty", BlockEvent, EventHookMode_Pre);
	HookEvent("weapon_outofammo", BlockEvent, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre);	
	
	/*					COMMANDS				*/
	RegConsoleCmd("jointeam", Command_JoinTeam);
	RegConsoleCmd("calladmin", Cmd_CallAdmin);
	RegServerCmd("quit", OnDown);
	RegServerCmd("_restart", OnDown);
}

/***************************************************************************************

							P L U G I N  -  L I C E N C E

***************************************************************************************/
public void RP_OnLicenceLoaded(bool licenceValid)
{
	if(!licenceValid)
		UnloadPlugin();
}

/***************************************************************************************

							P L U G I N  -  M A P

***************************************************************************************/
public void OnMapStart()
{
	File_AddToDownloadsTable("models/");
	File_AddToDownloadsTable("materials/");
	File_AddToDownloadsTable("sound/roleplay");
	PrecacheModel("models/props_survival/upgrades/exojump.mdl");
	PrecacheModel("models/props_survival/jammer/jammer.mdl");
	PrecacheModel("models/props_survival/upgrades/parachutepack.mdl");
	PrecacheModel("models/props_survival/upgrades/upgrade_dz_helmet.mdl");
	KillWeapon();
}

public void OnMapEnd()
{
	char map[128];
	rp_GetCurrentMap(map);
	
	char translate[64];
    Format(STRING(translate), "%T", "MapStart", LANG_SERVER, map);		
	
	char hostname[128];
	GetConVarString(FindConVar("hostname"), STRING(hostname));
	
	/*				DISCORD A.P.I				*/
	DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
	hook.SlackMode = true;	
	hook.SetUsername("Roleplay");	
	
	MessageEmbed Embed = new MessageEmbed();	
	Embed.SetColor("#00fd29");
	Embed.SetTitle(hostname);
	Embed.SetTitleLink("https://vr-hosting.fr/");
	Embed.AddField("Message", translate, false);
	Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
	Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
	Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
	
	hook.Embed(Embed);	
	hook.Send();
	delete hook;
}

/*				DISABLED ACTIONS				*/
public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
} 

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	return Plugin_Handled;
}

public Action OnPlayerTeam(Event event, char[] name, bool dontBroadcast)
{
	dontBroadcast = true;
	event.BroadcastDisabled = true;
	return Plugin_Handled;
}

public Action Command_JoinTeam(int client, int args)
{
	return Plugin_Handled;
}

public Action BlockEvent(Event event, char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	//SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}

public void OnClientDisconnect(int client)
{
	//SDKUnhook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}	

public Action OnClientTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	Call_StartForward(g_OnClientTakeDamage);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushCell(inflictor);
	Call_PushFloat(damage);
	Call_PushCell(damagetype);
	Call_Finish();
 
	return Plugin_Continue;
}	
	
/*				WHEN A PLAYER DEATH				*/
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Action result;
	char weapon[64];
	event.GetString("weapon", STRING(weapon));
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker")); 

	if(attacker != 0 && attacker != client)
		CPrintToChatAll("%s %N à tué %N", TEAM, attacker, client);
	
	if(rp_GetClientInt(client, i_Money) >= MONTANT_MAX_MORT)
	{
        int random = GetRandomInt(MONTANT_MIN_MORT, MONTANT_MAX_MORT);
        PrecacheModel(MONEY_MDL, true);
        int ent = CreateEntityByName("prop_physics_override");
        DispatchKeyValue(ent, "solid", "6");
        DispatchKeyValue(ent, "model", MONEY_MDL);
        DispatchSpawn(ent);
		
		char strFormat[64];
        Format(STRING(strFormat), "billet|%i", random);
        Entity_SetName(ent, strFormat);
        
		float position[3];
		GetClientAbsOrigin(client, position);
		position[2] += 32.0;
        
        TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
        
        rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - random);
        CPrintToChat(client, "%s {green}%i${default} sont tombés de vos poches lors de votre mort.", TEAM, random);
        return Plugin_Continue;
    }
    
    g_iTimerRespawn[client] = 15;
    
    Call_StartForward(g_DeathForward);
	Call_PushCell(attacker);
	Call_PushCell(client);
	Call_PushCell(g_iTimerRespawn[client]);
	Call_Finish(result);
	
	CreateTimer(1.0, Timer_Respawn, client, 1);
	ClientCommand(client, "r_screenoverlay effects/black.vmt");
 
	return result;
}

/*				WHEN A PLAYER SPAWN IN MAP				*/
public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Action result;
	int client = GetClientOfUserId(event.GetInt("userid"));

	Call_StartForward(g_SpawnForward);
	Call_PushCell(client);
	Call_Finish(result);
	
	if(GetClientTeam(client) == CS_TEAM_CT && rp_GetClientInt(client, i_Job) != 1 || rp_GetClientInt(client, i_Job) != 7)
		ChangeClientTeam(client, CS_TEAM_T);
 
 	ClientCommand(client, "r_screenoverlay 0");
 	SetJobSkin(client, true);
 	
	return result;
}

public Action OnPlayerConnect(Event event, char[] name, bool dontBroadcast)
{
	Action result;
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	Call_StartForward(g_ConnectForward);
	Call_PushCell(client);
	Call_Finish(result);
 
	return result;
}	

public Action OnPlayerDisconnect(Event event, char[] name, bool dontBroadcast)
{
	Action result;
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	Call_StartForward(g_DisconnectForward);
	Call_PushCell(client);
	Call_Finish(result);
 
	return result;
}	

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{	
	if (!rp_GetClientBool(client, b_inUse) && buttons & IN_USE)
	{
		rp_SetClientBool(client, b_inUse, true);
		
		char entName[128], entClassName[64], entModel[128];		
		int target = GetClientAimTarget(client, false);
		
		if (target != -1 && IsValidEntity(target))
		{
			Entity_GetName(target, entName, sizeof(entName));
			Entity_GetModel(target, entModel, sizeof(entModel));
			Entity_GetClassName(target, entClassName, sizeof(entClassName));
		
			Call_StartForward(g_InteractForward);
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushString(entClassName);
			Call_PushString(entModel);			
			Call_PushString(entName);			
			Call_Finish();
		}
	}	
	else if(rp_GetClientBool(client, b_inUse) && !(buttons & IN_USE))
		rp_SetClientBool(client, b_inUse, false);
		
	if (!rp_GetClientBool(client, b_inReload) && buttons & IN_RELOAD)
	{
		rp_SetClientBool(client, b_inReload, true);
		
		Call_StartForward(g_ReloadForward);
		Call_PushCell(client);
		Call_Finish();
	}	
	else if(rp_GetClientBool(client, b_inReload) && !(buttons & IN_RELOAD))
		rp_SetClientBool(client, b_inReload, false);	
		
	if (!rp_GetClientBool(client, b_inDuck) && buttons & IN_DUCK)
	{
		rp_SetClientBool(client, b_inDuck, true);
		
		Call_StartForward(g_DuckForward);
		Call_PushCell(client);
		Call_Finish();
	}	
	else if(rp_GetClientBool(client, b_inDuck) && !(buttons & IN_DUCK))
		rp_SetClientBool(client, b_inDuck, false);
		
	if (buttons & IN_ATTACK2)
	{
		char buffer[128];
		
		int item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		// prevent log errors
		if(item == -1)
			return Plugin_Continue;
		
		GetEntityClassname(item, buffer, sizeof(buffer));
		
		if (StrEqual(buffer, "weapon_fists", false))
		{
			buttons &= ~IN_ATTACK2; //Don't press attack 2
			return Plugin_Changed;
		}		
	}
	
	return Plugin_Continue;
}	

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	char weaponName[64];
	event.GetString("weapon", STRING(weaponName));	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	Call_StartForward(g_OnClientHurt);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(event.GetInt("dmg_armor"));
	Call_PushCell(event.GetInt("dmg_health"));
	Call_PushString(weaponName);
	Call_Finish();
	
	return Plugin_Continue;
}

public Action OnWeaponFire(Event event, char[] name, bool dontBroadcast)
{
	char weaponName[32];
	event.GetString("weapon", STRING(weaponName));
	
	Call_StartForward(g_OnWeaponFire);
	Call_PushCell(event.GetInt("userid"));
	Call_PushCell(event.GetInt("aim"));
	Call_PushString(weaponName);
	Call_Finish();
	
	return Plugin_Continue;
}

public int KillWeapon()
{
	int maxent = GetMaxEntities();
	char entClass[65];
	
	for (int i = MaxClients; i <= maxent; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, STRING(entClass));
				
			if(StrContains(entClass, "weapon_", false) != -1)
			{
				RemoveEdict(i);
			}
		}
	}	
} 

public Action OnClientPreAdminCheck(int client)
{
	if (rp_GetClientInt(client, i_VipTime) != 0)
	{
		g_iTimerRespawn[client] = 10;
	}
	else if(IsBenito(client))
	{
		g_iTimerRespawn[client] = 0;
	}
	else
	{
		g_iTimerRespawn[client] = 15;
	}
	
	CreateTimer(1.0, Timer_Respawn, client, 1);
	
	if(client != 0)
	{
		char clientName[33];
		GetClientName(client, STRING(clientName));
			
		char translate[64];
    	Format(STRING(translate), "%T", "Join", LANG_SERVER, clientName);		
		
		char hostname[128];
		GetConVarString(FindConVar("hostname"), STRING(hostname));
		
		DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
		hook.SlackMode = true;	
		hook.SetUsername("Roleplay");	
		
		MessageEmbed Embed = new MessageEmbed();	
		Embed.SetColor("#00fd29");
		Embed.SetTitle(hostname);
		Embed.SetTitleLink("https://vr-hosting.fr/");
		Embed.AddField("Message", translate, false);
		Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
		Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
		Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
		
		hook.Embed(Embed);	
		hook.Send();
		delete hook;
	}
}

public Action Timer_Respawn(Handle timer, any client)
{	
	if (IsClientInGame(client) && !IsPlayerAlive(client))
	{
		if (0 < g_iTimerRespawn[client])
		{
			g_iTimerRespawn[client]--;
			if (g_iTimerRespawn[client] == 1)
			{
				PrintCenterText(client, "%T", "RespawnOneSecond", LANG_SERVER);
			}
			else
			{
				PrintCenterText(client, "%T", "RespawnIn", LANG_SERVER, g_iTimerRespawn[client]);
			}
		}
		else
		{
			CS_SwitchTeam(client, 2);
			CS_RespawnPlayer(client);
		}
	}
	else
	{	
		KillTimer(timer, false);
	}
	return view_as<Action>(0);
}

public Action Cmd_CallAdmin(int client, int args)
{
	if (client == 0)
	{
		char translate[128];
		Format(STRING(translate), "%T", "Command_NotAvailable", LANG_SERVER);
		PrintToServer(translate);
		return Plugin_Handled;
	}
	
	if(IsClientValid(client))
	{
		char translate[128];
    	Format(STRING(translate), "%T", "CallAdmin", LANG_SERVER, client);	
		
		char hostname[128];
		GetConVarString(FindConVar("hostname"), STRING(hostname));
		
		DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
		hook.SlackMode = true;	
		hook.SetUsername("Roleplay");	
		
		MessageEmbed Embed = new MessageEmbed();	
		Embed.SetColor("#00fd29");
		Embed.SetTitle(hostname);
		Embed.SetTitleLink("https://vr-hosting.fr/");
		Embed.AddField("Type", "@here", false);
		Embed.AddField("Message", translate, false);
		Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
		Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
		Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
		
		hook.Embed(Embed);	
		hook.Send();
		delete hook;
	}	
	
	return Plugin_Handled;
}

public Action OnDown(int args)
{
	LoopClients(i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
            ClientCommand(i, "retry");
		}
	}
}