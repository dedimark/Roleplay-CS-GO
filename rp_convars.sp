#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <roleplay>

public Plugin myinfo = 
{
	name = "[Roleplay] Convars", 
	author = "Benito", 
	description = "Système de Monaie & Banque", 
	version = "1.0", 
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		CreateConVar("rp_temps_afk", "300", "Temps inactif AFK");	
		AutoExecConfig(true, "roleplay");
			
		HookUserMessage(GetUserMessageId("SayText2"), BlockSayText2, true);
		HookUserMessage(GetUserMessageId("TextMsg"), BlockTextMsg, true);
		HookUserMessage(GetUserMessageId("KillCam"), BlockKillCam, true);
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
		
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
		
		SetConVarInt(FindConVar("sv_show_team_equipment_prohibit"), 1);
		SetConVarInt(FindConVar("sv_teamid_overhead_always_prohibit"), 1);
	}
	else
		UnloadPlugin();
}

public Action BlockSayText2(UserMsg msgID, Handle pb, const int[] client, int clientNum, bool reliable, bool init)
{
	if(reliable) 
	{
		/*charmessage[PLATFORM_MAX_PATH];
		for(new i; i < PbGetRepeatedFieldCount(pb, "params"); i++)
        {
			PbReadString(pb, "params", message, sizeof(message), i);
			PrintToServer(">>>> SayText2 : %s\n", message);
        }*/
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action BlockTextMsg(UserMsg msgID, Handle pb, const int[] client, int clientNum, bool reliable, bool init)
{
	if(reliable)
	{
		char message[PLATFORM_MAX_PATH];
		PbReadString(pb, "params", message, sizeof(message), false);
		
		// PrintToServer(">>>> TextMsg : %s\n", message);
		
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
		|| StrContains(message, "-----") != -1)
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action BlockKillCam(UserMsg msgID, Handle pb, const client[], int clientNum, bool reliable, bool init)
{
	return Plugin_Handled;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
} 

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
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