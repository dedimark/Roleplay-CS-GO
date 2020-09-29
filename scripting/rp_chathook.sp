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
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>
#include <basecomm>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
//char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];

bool g_bMayTalk[65];
GlobalForward g_OnSay;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Chat Hook", 
	author = "Benito", 
	description = "Chat Hooking", 
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
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_chathook.log");	
	
	/*------------------------------------1------------------------------------*/
	g_OnSay = new GlobalForward("RP_OnPlayerSay", ET_Event, Param_Cell, Param_String);	
	AddCommandListener(Say, "say");
	AddCommandListener(Say_Team, "say_team");
	/*-------------------------------------------------------------------------*/
		
	RegConsoleCmd("me", Message_Annonce);
	RegConsoleCmd("annonce", Message_Annonce);

	RegConsoleCmd("c", Message_Colocataire);
	RegConsoleCmd("coloc", Message_Colocataire);
	RegConsoleCmd("colloc", Message_Colocataire);
	
	RegConsoleCmd("t", Message_Team);
	RegConsoleCmd("team", Message_Team);
	
	RegConsoleCmd("m", Message_Couple);
	RegConsoleCmd("marie", Message_Couple);
	
	RegConsoleCmd("g", Message_Groupe);
	RegConsoleCmd("group", Message_Groupe);
	RegConsoleCmd("groupe", Message_Groupe);
	
	RegConsoleCmd("a", Message_Admin);
	RegConsoleCmd("admin", Message_Admin);	
	
	RegConsoleCmd("stopsound", Stopsound);
}

public void OnClientPostAdminCheck(int client) 
{
	g_bMayTalk[client] = true;
}

public Action Message_Annonce(int client, int args)
{
	if(IsClientValid(client))
	{
		char command[16];
		GetCmdArg(0, STRING(command));
		
		char arg[128];
		GetCmdArgString(STRING(arg));
		
		if(args < 1)
		{
			CPrintToChat(client, "%s Utilisation : {lightred}!%s <message>", TEAM, command);
			return Plugin_Handled;
		}
		
		if(!rp_GetClientBool(client, b_IsNoPyj)) 
		{
			CPrintToChat(client, "%s Vous n'avez pas le status {lightgreen}No-Pyj !", TEAM);
			return Plugin_Handled;
		}
		if(BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteGlobal)) 
		{
			CPrintToChat(client, "{default}[{lightred}MUTE{default}]: Vous avez été interdit d'utiliser le chat global.");
			return Plugin_Handled;
		}
		
		char name[64];
		GetClientName(client, STRING(name));
		
		CPrintToChatAll("{lightblue}%s{default} ({olive}ANNONCE{default}): %s", name, arg);
		LogToGame("[VRH-RP] [ANNONCES] %L: %s", client, arg);
		LogToFile(logFile, "[VRH-RP] [ANNONCES] %L: %s", client, arg);
	}	
	
	return Plugin_Handled;
}		

public Action Message_Colocataire(int client, int args)
{
	if(IsClientValid(client))
	{
		char command[16];
		GetCmdArg(0, STRING(command));
		
		char arg[128];
		GetCmdArgString(STRING(arg));
		
		if(args < 1)
		{
			CPrintToChat(client, "%s Utilisation : {lightred}!%s <message>", TEAM, command);
			return Plugin_Handled;
		}
		
		if(rp_GetClientInt(client, i_AppartCount) == 0) 
		{
			CPrintToChat(client, "%s Vous n'avez pas d'appartement.", TEAM);
			return Plugin_Handled;
		}
		if(BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteLocal)) 
		{
			CPrintToChat(client, "{default}[{lightred}MUTE{default}]: Vous avez été interdit d'utiliser le chat local.");
			return Plugin_Handled;
		}
		
		int appid_client = rp_GetClientInt(client, i_appartement);		
		LoopClients(j)
		{
			if(j == client)
				continue;
			
			int appid_coloc = rp_GetClientInt(j, i_appartement);
			
			if(appid_client == appid_coloc)
				CPrintToChatEx(j, client, "{lightblue}%N{default} ({purple}COLOC{default}): %s", client, arg);
			else
			{
				CPrintToChat(client, "%s Vous n'avez pas de colocataire.", TEAM);
				continue;
			}	
		}
		
		LogToGame("[VRH-RP] [CHAT-COLLOC] %L: %s", client, arg);
		LogToFile(logFile, "[VRH-RP] [CHAT-COLLOC] %L: %s", client, arg);
	}	
	
	return Plugin_Handled;
}

public Action Message_Team(int client, int args)
{
	if(IsClientValid(client))
	{
		char command[16];
		GetCmdArg(0, STRING(command));
		
		char arg[128];
		GetCmdArgString(STRING(arg));
		
		if(args < 1)
		{
			CPrintToChat(client, "%s Utilisation : {lightred}!%s <message>", TEAM, command);
			return Plugin_Handled;
		}
		
		if(rp_GetClientInt(client, i_Job) == 0) 
		{
			NoCommandAcces(client);
			return Plugin_Handled;
		}
		if(BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteLocal)) 
		{
			CPrintToChat(client, "{default}[{lightred}MUTE{default}]: Vous avez été interdit d'utiliser le chat local.");
			return Plugin_Handled;
		}

		LoopClients(i) 
		{
			if(rp_GetClientInt(client, i_Job) == rp_GetClientInt(i, i_Job)) 
			{
				CPrintToChatEx(i, client, "{lightblue}%N{default} ({orange}TEAM{default}): %s", client, arg);
			}
		}
		
		LogToGame("[VRH-RP] [CHAT-TEAM] %L: %s", client, arg);
		LogToFile(logFile, "[VRH-RP] [CHAT-TEAM] %L: %s", client, arg);
	}	
	
	return Plugin_Handled;
}	

public Action Message_Couple(int client, int args)
{
	if(IsClientValid(client))
	{
		char command[16];
		GetCmdArg(0, STRING(command));
		
		char arg[128];
		GetCmdArgString(STRING(arg));
		
		if(args < 1)
		{
			CPrintToChat(client, "%s Utilisation : {lightred}!%s <message>", TEAM, command);
			return Plugin_Handled;
		}
		
		int mari = rp_GetClientInt(client, i_MarriedTo);
		if(mari == 0) 
		{
			CPrintToChat(client, "%s Vous n'avez pas de conjoint.", TEAM);
			return Plugin_Handled;
		}
		
		CPrintToChatEx(mari, client, "{lightblue}%N{default} ({red}MARIÉ{default}): %s", client, arg);
		CPrintToChatEx(client, client, "{lightblue}%N{default} ({red}MARIÉ{default}): %s", client, arg);
		
		LogToGame("[VRH-RP] [CHAT-MARIE] %L: %s", client, arg);
		LogToFile(logFile, "[VRH-RP] [CHAT-MARIE] %L: %s", client, arg);
	}	
	
	return Plugin_Handled;
}	

public Action Message_Groupe(int client, int args)
{
	if(IsClientValid(client))
	{
		char command[16];
		GetCmdArg(0, STRING(command));
		
		char arg[128];
		GetCmdArgString(STRING(arg));
		
		if(args < 1)
		{
			CPrintToChat(client, "%s Utilisation : {lightred}!%s <message>", TEAM, command);
			return Plugin_Handled;
		}
		
		if(rp_GetClientInt(client, i_Group) == 0) 
		{
			CPrintToChat(client, "%s Vous n'êtes dans aucun group.", TEAM);
			return Plugin_Handled;
		}

		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Group) == rp_GetClientInt(client, i_Group)) 
			{
				CPrintToChatEx(i, client, "{lightblue}%N{default} ({red}GROUP{default}): %s", client, arg);
			}
		}
		
		LogToGame("[VRH-RP] [CHAT-GROUP] %L: %s", client, arg);
		LogToFile(logFile, "[VRH-RP] [CHAT-GROUP] %L: %s", client, arg);
	}	
	
	return Plugin_Handled;
}

public Action Message_Admin(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0) 
	{
		CPrintToChat(client, "%s Vous n'êtes pas admin.", TEAM);
		return Plugin_Handled;
	}
	
	if(IsClientValid(client))
	{
		char command[16];
		GetCmdArg(0, STRING(command));
		
		char arg[128];
		GetCmdArgString(STRING(arg));
		
		if(args < 1)
		{
			CPrintToChat(client, "%s Utilisation : {lightred}!%s <message>", TEAM, command);
			return Plugin_Handled;
		}

		CPrintToChatAll("{lightblue}%N{default} ({lightgreen}ADMIN{default}): %s", client, arg);
		
		LogToGame("[VRH-RP] [CHAT-GROUP] %L: %s", client, arg);
		LogToFile(logFile, "[VRH-RP] [CHAT-GROUP] %L: %s", client, arg);
	}	
	
	return Plugin_Handled;
}

public Action Stopsound(int client, int args)
{
	if(IsClientValid(client))
	{
		FakeClientCommand(client, "stopsound");
	}	
	
	return Plugin_Handled;
}

public Action Say_Team(int client, char[] Cmd, int args)
{
	return Plugin_Handled;
}

public Action Say(int client, char[] Cmd, int args)
{
	if(client > 0)
	{
		if(IsClientValid(client))
		{
			char arg[256];
			GetCmdArgString(STRING(arg));
			StripQuotes(arg);
			TrimString(arg);
			
			char strName[32];
			GetClientName(client, STRING(strName));
			
			#if defined CSS_SUPPORT
			if(StrContains(arg, "{default}") != -1)
				ReplaceString(STRING(strName), "{default}", "{white}");
			#endif
			
			if (strcmp(arg, " ") == 0 || strcmp(arg, "") == 0 || strlen(arg) == 0 || StrContains(arg, "!") == 0 || StrContains(arg, "/") == 0 || StrContains(arg, "@") == 0)
			{
				return Plugin_Handled;
			}
			
			char strPseudo[256];
			
			if(rp_GetClientBool(client, b_IsMuteGlobal)) 
			{
				PrintToChat(client, "\x04[\x02MUTE\x01]\x01: Vous avez été interdit d'utiliser le chat.");
				return Plugin_Stop;
			}
			else
			{						
				if(!rp_GetClientBool(client, b_Crayon)) 
				{
					char buffer[256];
					strcopy(STRING(buffer), arg);
					
					CRemoveTags(STRING(buffer));
					CRemoveTags(STRING(strName));
				}
				
				if(!g_bMayTalk[client]) 
				{
					CPrintToChat(client, "%s Vous devez attendre encore quelques secondes.", TEAM);
					return Plugin_Stop;
				}
				else
				{
					if(rp_GetClientInt(client, i_AdminLevel) >= 1)
					{				
						char rank[128];
						rp_GetClientString(client, sz_AdminTag, STRING(rank));
						
						Format(STRING(strPseudo), "{default}[%s{default}]{default}%s", rank, strName);
					}
					else
						Format(STRING(strPseudo), "{grey}%s", strName);
						
					CPrintToChatAll("%s {default}: %s", strPseudo, arg);	
				}	

				g_bMayTalk[client] = false;
				CreateTimer(5.0, AllowTalking, client);
			}	
			
			Call_StartForward(g_OnSay);
			Call_PushCell(client);
			Call_PushString(arg);
			Call_Finish();	
		}
	}
	
	return Plugin_Handled;
}


public Action AllowTalking(Handle timer, any client) 
{
	g_bMayTalk[client] = true;
}