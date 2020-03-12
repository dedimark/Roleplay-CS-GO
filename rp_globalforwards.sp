#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>
#include <roleplay>
#include <multicolors>

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"

#pragma newdecls required

GlobalForward g_DeathForward;
GlobalForward g_SpawnForward;
GlobalForward g_ConnectForward;
GlobalForward g_DisconnectForward;
GlobalForward g_InteractForward;
GlobalForward g_OnSay;
GlobalForward g_OnSayTeam;
GlobalForward g_OnPlayerHurt;
GlobalForward g_OnWeaponFire;

public Plugin myinfo = 
{
	name = "[Roleplay] Global Forward",
	author = "Benito",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		g_DeathForward = new GlobalForward("rp_OnClientDeath", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);
		g_SpawnForward = new GlobalForward("rp_OnClientSpawn", ET_Event, Param_Cell);
		g_ConnectForward = new GlobalForward("rp_OnClientConnect", ET_Event, Param_Cell);
		g_DisconnectForward = new GlobalForward("rp_OnClientDisconnect", ET_Event, Param_Cell);
		g_InteractForward = new GlobalForward("rp_OnClientInteract", ET_Event, Param_Cell, Param_Cell, Param_String, Param_String, Param_String);
		g_OnSay = new GlobalForward("rp_SayOnPublic", ET_Event, Param_Cell, Param_String, Param_String, Param_Cell);
		g_OnSayTeam = new GlobalForward("rp_SayOnTeam", ET_Event, Param_Cell, Param_String, Param_String, Param_Cell);
		g_OnPlayerHurt = new GlobalForward("rp_OnClientTakeDamage", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
		g_OnWeaponFire = new GlobalForward("rp_OnWeaponFire", ET_Event, Param_Cell, Param_Cell, Param_String);
		HookEvent("player_death", OnPlayerDeath);
		HookEvent("player_spawn", OnPlayerSpawn);
		HookEvent("player_connect", OnPlayerConnect, EventHookMode_Pre);
		HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
		///HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre);
		HookEvent("teamplay_round_start", BlockEvent, EventHookMode_Pre);
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
		HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);
		AddCommandListener(Say, "say");
		AddCommandListener(Say_Team, "say_team");
		RegConsoleCmd("jointeam", Command_JoinTeam);
	}
	else
		UnloadPlugin();	
}

public Action Say(int client, char[] Cmd, int args)
{
	if(client > 0)
	{
		if(IsClientValid(client))
		{
			char arg[256];
			GetCmdArgString(arg, sizeof(arg));
			StripQuotes(arg);
			TrimString(arg);	

			char strName[32];
			GetClientName(client, strName, sizeof(strName));
			
			for(int i; i <= strlen(strName); i++)
			{
				if(StrContains(strName, "{") != -1)
					ReplaceString(strName, sizeof(strName), "{", "");
				else if(StrContains(strName, "}") != -1)
					ReplaceString(strName, sizeof(strName), "}", "");
				else 
					break;
			}
			
			if (strcmp(arg, " ") == 0 || strcmp(arg, "") == 0 || strlen(arg) == 0 || StrContains(arg, "!") == 0 || StrContains(arg, "/") == 0 || StrContains(arg, "@") == 0)
			{
				return Plugin_Handled;
			}
			else if(StrContains(arg, "{") != -1)
			{
				CPrintToChat(client, "%s Les caractères { et } spéciaux sont interdits.", NAME);
				return Plugin_Handled;
			}
			else if(rp_GetClientBool(client, b_isGag))
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à utiliser le chat.", NAME);
				
			Call_StartForward(g_OnSay);
			Call_PushCell(client);
			Call_PushString(arg);
			Call_PushString(Cmd);
			Call_PushCell(args);
			Call_Finish();	
		}
	}
	
	return Plugin_Handled;
}

public Action Say_Team(int client, char[] Cmd, int args)
{
	if(client > 0)
	{
		if(IsClientValid(client))
		{
			char arg[256];
			GetCmdArgString(arg, sizeof(arg));
			StripQuotes(arg);
			TrimString(arg);			
			
			char strName[32];
			GetClientName(client, strName, sizeof(strName));
			
			for(int i; i <= strlen(strName); i++)
			{
				if(StrContains(strName, "{") != -1)
					ReplaceString(strName, sizeof(strName), "{", "");
				else if(StrContains(strName, "}") != -1)
					ReplaceString(strName, sizeof(strName), "}", "");
				else 
					break;
			}
			
			if (strcmp(arg, " ") == 0 || strcmp(arg, "") == 0 || strlen(arg) == 0 || StrContains(arg, "!") == 0 || StrContains(arg, "/") == 0 || StrContains(arg, "@") == 0)
			{
				return Plugin_Handled;
			}
			else if(StrContains(arg, "{") != -1)
			{
				CPrintToChat(client, "%s Les caractères { et } spéciaux sont interdits.", NAME);
				return Plugin_Handled;
			}
			else if(rp_GetClientBool(client, b_isGag))
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à utiliser le chat.", NAME);
				
			Call_StartForward(g_OnSayTeam);
			Call_PushCell(client);
			Call_PushString(arg);
			Call_PushString(Cmd);
			Call_PushCell(args);
			Call_Finish();	
		}
	}
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	File_AddToDownloadsTable("models/");
	File_AddToDownloadsTable("materials/");
	File_AddToDownloadsTable("sound/roleplay");
	PrecacheModel("models/props_survival/upgrades/exojump.mdl");
	PrecacheModel("models/props_survival/jammer/jammer.mdl");
	PrecacheModel("models/props_survival/upgrades/parachutepack.mdl");
	PrecacheModel("models/props_survival/upgrades/upgrade_dz_helmet.mdl");
}	

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
} 

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	return Plugin_Handled;
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
	RegPluginLibrary("rp_globalforwards");
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	char weapon[64];
	Action result;
 
	event.GetString("weapon", weapon, sizeof(weapon));
 
	Call_StartForward(g_DeathForward);
	Call_PushCell(GetClientOfUserId(event.GetInt("attacker")));
	Call_PushCell(GetClientOfUserId(event.GetInt("userid")));
	Call_PushString(weapon);
	Call_PushCell(GetEventInt(event, "headshot"));
	Call_Finish(result);
 
	return result;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Action result;
	
	Call_StartForward(g_SpawnForward);
	Call_PushCell(GetClientOfUserId(event.GetInt("userid")));
	Call_Finish(result);
 
	return result;
}

public Action OnPlayerConnect(Event event, char[] name, bool dontBroadcast)
{
	Action result;
	
	Call_StartForward(g_ConnectForward);
	Call_PushCell(GetClientOfUserId(event.GetInt("userid")));
	Call_Finish(result);
 
	return result;
}	

public Action OnPlayerDisconnect(Event event, char[] name, bool dontBroadcast)
{
	Action result;
	
	Call_StartForward(g_DisconnectForward);
	Call_PushCell(GetClientOfUserId(event.GetInt("userid")));
	Call_Finish(result);
 
	return result;
}

public Action OnPlayerTeam(Event event, char[] name, bool dontBroadcast)
{
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

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{	
	if (!rp_GetClientBool(client, b_inUse) && buttons & IN_USE)
	{
		rp_SetClientBool(client, b_inUse, true);
		
		char entName[128], entClassName[64], entModel[128];		
		int aim = GetClientAimTarget(client, false);
		
		if (aim != -1 && IsValidEntity(aim))
		{
			Entity_GetName(aim, entName, sizeof(entName));
			Entity_GetModel(aim, entModel, sizeof(entModel));
			Entity_GetClassName(aim, entClassName, sizeof(entClassName));
		
			Call_StartForward(g_InteractForward);
			Call_PushCell(client);
			Call_PushCell(aim);
			Call_PushString(entName);
			Call_PushString(entModel);
			Call_PushString(entClassName);
			Call_Finish();
		}			
	}	
	else if(rp_GetClientBool(client, b_inUse) && !(buttons & IN_USE))
		rp_SetClientBool(client, b_inUse, false);
}	

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	char weaponName[64];
	event.GetString("weapon", weaponName, sizeof(weaponName));	
	
	Call_StartForward(g_OnPlayerHurt);
	Call_PushCell(event.GetInt("userid"));
	Call_PushCell(event.GetInt("attacker"));
	Call_PushCell(event.GetInt("dmg_health"));
	Call_PushCell(event.GetInt("dmg_armor"));
	Call_PushString(weaponName);
	Call_Finish();
	
	return Plugin_Continue;
}

public Action OnWeaponFire(Event event, char[] name, bool dontBroadcast)
{
	char weaponName[32];
	event.GetString("weapon", weaponName, sizeof(weaponName));
	
	Call_StartForward(g_OnWeaponFire);
	Call_PushCell(event.GetInt("userid"));
	Call_PushCell(event.GetInt("aim"));
	Call_PushString(weaponName);
	Call_Finish();
	
	return Plugin_Continue;
}