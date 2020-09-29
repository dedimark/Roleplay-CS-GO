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
#include <sdkhooks>
#include <sdktools>
#include <roleplay>
#include <smlib>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif

/***************************************************************************************

							P L U G I N  -  D E F I N E S

***************************************************************************************/
#define HIDE_RADAR_CSGO 1<<12

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Game Cvars", 
	author = "Benito", 
	description = "Paramétrage des cvars optimisée pour le roleplay", 
	version = VERSION, 
	url = TEAM
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	GameCheck();
	rp_LoadTranslation();
	
	HookUserMessage(GetUserMessageId("SayText2"), BlockSayText2, true);
	HookUserMessage(GetUserMessageId("TextMsg"), BlockTextMsg, true);
	HookUserMessage(GetUserMessageId("KillCam"), BlockKillCam, true);
	
	HookEvent("round_start", Event_Disable, EventHookMode_Post);
	HookEvent("round_end", Event_Disable, EventHookMode_Post);
	HookEvent("cs_match_end_restart", Event_Disable, EventHookMode_PostNoCopy);
	HookEvent("announce_phase_end", Event_Disable, EventHookMode_PostNoCopy);
	HookEvent("buytime_ended", Event_Disable, EventHookMode_PostNoCopy);
	HookEvent("cs_intermission", Event_Disable, EventHookMode_PostNoCopy);
	HookEvent("round_announce_warmup", Event_Disable, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", Event_Disable, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("jointeam", Command_Block);
	RegConsoleCmd("explode", Command_Block);
	RegConsoleCmd("kill", Command_BlockKill);
	RegConsoleCmd("coverme", Command_Block);
	RegConsoleCmd("takepoint", Command_Block);
	RegConsoleCmd("holdpos", Command_Block);
	RegConsoleCmd("regroup", Command_Block);
	RegConsoleCmd("followme", Command_Block);
	RegConsoleCmd("takingfire", Command_Block);
	RegConsoleCmd("go", Command_Block);
	RegConsoleCmd("fallback", Command_Block);
	RegConsoleCmd("sticktog", Command_Block);
	RegConsoleCmd("cheer", Command_Block);
	RegConsoleCmd("compliment", Command_Block);
	RegConsoleCmd("thanks", Command_Block);
	RegConsoleCmd("getinpos", Command_Block);
	RegConsoleCmd("stormfront", Command_Block);
	RegConsoleCmd("report", Command_Block);
	RegConsoleCmd("roger", Command_Block);
	RegConsoleCmd("enemyspot", Command_Block);
	RegConsoleCmd("needbackup", Command_Block);
	RegConsoleCmd("sectorclear", Command_Block);
	RegConsoleCmd("inposition", Command_Block);
	RegConsoleCmd("reportingin", Command_Block);
	RegConsoleCmd("getout", Command_Block);
	RegConsoleCmd("negative", Command_Block);
	RegConsoleCmd("enemydown", Command_Block);
	RegConsoleCmd("rr", Command_ReloadPlugin);
	
	SetConVarInt(FindConVar("sv_show_team_equipment_prohibit"), 1);
	SetConVarInt(FindConVar("sv_teamid_overhead_always_prohibit"), 1);
	SetConVarInt(FindConVar("sv_allowdownload"), 1);
	SetConVarInt(FindConVar("sv_allowupload"), 1);
	SetConVarString(FindConVar("sv_downloadurl"), "https://fastdl.vr-hosting.fr/");
	SetConVarInt(FindConVar("sv_ignoregrenaderadio"), 1, false, false);
	SetConVarString(FindConVar("sv_server_graphic2"), "materials/revolution/images/graphic.png", true, true);
}

public void OnMapStart()
{
	SetConVarInt(FindConVar("sv_pure"), 0);
	CreateTimer(320.0, AutoMessages, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}	

public void OnConfigsExecuted()
{
	ServerCommand("mp_warmup_end");
	SetConVarInt(FindConVar("mp_autokick"), 0);
	SetConVarInt(FindConVar("mp_tkpunish"), 0);	
	SetConVarInt(FindConVar("mp_ignore_round_win_conditions"), 1);
	SetConVarInt(FindConVar("mp_roundtime"), 1, false, false);
	//SetConVarInt(FindConVar("mp_weapons_glow_on_ground"), 1, true, true);	
}

public Action BlockSayText2(UserMsg msgID, Protobuf pb, const int[] client, int clientNum, bool reliable, bool init)
{
	if(reliable) 
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action BlockTextMsg(UserMsg msgID, Protobuf pb, const int[] client, int clientNum, bool reliable, bool init)
{
	if(reliable)
	{
		char message[PLATFORM_MAX_PATH];
		PbReadString(pb, "params", STRING(message), false);
		
		if(StrContains(message, "Player_Cash_Award") != -1
		|| StrContains(message, "Team_Cash_Award") != -1
		|| StrContains(message, "Player_Point_Award") != -1
		|| StrContains(message, "Cstrike_TitlesTXT_Game_teammate_attack") != -1
		|| StrContains(message, "Chat_SavePlayer_") != -1
		|| StrContains(message, "Cstrike_game_join_") != -1
		|| StrContains(message, "SFUI_Notice_DM_BonusRespawn") != -1
		|| StrContains(message, "SFUI_Notice_DM_BonusSwitchTo") != -1
		|| StrContains(message, "SFUI_Notice_DM_BonusWeaponText") != -1
		|| StrContains(message, "SFUI_Notice_Got_Bomb") != -1
		|| StrContains(message, "Player_You_Are_") != -1
		|| StrContains(message, "SFUI_Notice_Match_Will_Start_Chat") != -1
		|| StrContains(message, "SFUI_Notice_Warmup_Has_Ended") != -1
		|| StrContains(message, "CSGO_Coach_Join_") != -1
		|| StrContains(message, "CSGO_No_Longer_Coach") != -1
		|| StrContains(message, "Player_You_Are_Now_Dominating") != -1
		|| StrContains(message, "Player_You_Are_Still_Dominating") != -1
		|| StrContains(message, "Player_On_Killing_Spree") != -1
		|| StrContains(message, "hostagerescuetime") != -1
		|| StrContains(message, "csgo_instr_explain_buymenu") != -1
		|| StrContains(message, "_Radio_") != -1
		|| StrContains(message, "Unknown command") != -1
		|| StrContains(message, "Damage") != -1
		|| StrContains(message, "attack", false) != -1
		|| StrContains(message, "teammate", false) != -1
		|| StrContains(message, "Player") != -1
		|| StrContains(message, "-----") != -1
		|| StrContains(message, "Fire_in_the_hole") != -1
		|| StrContains(message, "hole") != -1
		|| StrContains(message, "grenade") != -1
		|| StrContains(message, "in_the_hole") != -1)
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action BlockKillCam(UserMsg msgID, Protobuf pb, const client[], int clientNum, bool reliable, bool init)
{
	return Plugin_Handled;
}

public Action Event_Disable(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
} 

public Action Command_Block(int client, int args)
{
	return Plugin_Handled;
}	

public Action Command_BlockKill(int client, int args)
{
	PrintToConsole(client, "[RP] La tentative de suicide par commande est interdit !");
	
	return Plugin_Handled;
}	

public Action Command_ReloadPlugin(int client, int args)
{
	char plugin[256];
	GetCmdArgString(STRING(plugin));
	
	ServerCommand("sm plugins reload %s", plugin);
	
	if(!StrEqual(plugin, ""))
	{
		char hostname[128];
		GetConVarString(FindConVar("hostname"), STRING(hostname));
		
		DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
		hook.SlackMode = true;	
		hook.SetUsername("Roleplay");	
		
		MessageEmbed Embed = new MessageEmbed();	
		Embed.SetColor("#00fd29");
		Embed.SetTitle(hostname);
		Embed.SetTitleLink("https://vr-hosting.fr/");
		Embed.AddField("Message", "Restart Plugin", false);
		Embed.AddField("Plugin", plugin, false);
		Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
		Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
		Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
		
		hook.Embed(Embed);	
		hook.Send();
		delete hook;
	}	
	else
		ReplyToCommand(client, "Utilisation: !rr <plugin>");
}	

public Action AutoMessages(Handle Timer)
{
	int random = GetRandomInt(0, 5);	
	switch(random)
	{
		case 1:CPrintToChatAll("%s {darkred}* {default}Partenariat: {lightblue}LastFate.fr {darkred}*", TEAM);
		case 2:CPrintToChatAll("%s {darkred}* {default}Forum: {lightblue}%s {darkred}*", TEAM, FORUM_URL);
		case 3:CPrintToChatAll("%s {darkred}* {default}Discord: {lightblue}%s {darkred}*", TEAM, DISCORD_URL);
		case 4:CPrintToChatAll("%s {darkred}* {yellow}VIP: {green}3.50€{default}/mois {darkred}*", TEAM);
		case 5:CPrintToChatAll("%s {darkred}* {default}Version: {green}%s {darkred}*", TEAM, VERSION);
	}
}	

public void RP_OnPlayerSpawn(int client)
{
	CreateTimer(1.0, setHudOptions, client);
}	

public Action setHudOptions(Handle Timer, int client) {
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
}