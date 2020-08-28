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
#include <roleplay>
#include <multicolors>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
bool g_bHoldup = false;
bool isComplice[MAXPLAYERS + 1];
int g_iTimerHoldup[66];
int nbBraqueurs;
ConVar HoldupTiming;
ConVar HoldupNeededCT;
ConVar Holdup_gain_min;
ConVar Holdup_gain_max;
ConVar Holdup_Timing;

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "Roleplay - Holdup",
	author = "Benito",
	description = "Roleplay - Holdup",
	version = VERSION,
	url = URL
};

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  E V E N T S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		GameCheck();
	
		RegConsoleCmd("holdup", Cmd_Holdup);
		HoldupTiming = CreateConVar("rp_holdup_refresh", "60", "Temps à attendre de rafraichissement pour un nouveau holdup");
		HoldupNeededCT = CreateConVar("rp_holdup_policiers", "2", "Nombres de policiers requis pour lancer un holdup");
		Holdup_gain_min = CreateConVar("rp_holdup_gain_min", "12000", "Nombre minimum qui se fera avec aléatoirement entre le maximum");
		Holdup_gain_max = CreateConVar("rp_holdup_gain_max", "15000", "Nombre maximum qui se fera avec aléatoirement entre le minimum");
		Holdup_Timing = CreateConVar("rp_holdup_timing", "150", "Temps max d'attente avant la fin du holdup");
		AutoExecConfig(true, "rp_holdup");
	}
	else
		UnloadPlugin();
}

public Action Cmd_Holdup(int client, int args)
{
	if (IsClientValid(client))
	{
		if (rp_GetClientInt(client, i_Job) == 2)
		{
			if (rp_GetClientInt(client, i_ByteZone) == 155 || rp_GetClientInt(client, i_ByteZone) == 144)
			{
				if (!g_bHoldup)
				{
					int CTCount;
					LoopClients(i)
					{
						if (rp_GetClientInt(i, i_Job) == 1)
						{
							if (!rp_GetClientBool(i, b_isAfk))
							{
								CTCount++;
							}
						}
					}
					if (CTCount >= GetConVarInt(HoldupNeededCT))
					{
						g_iTimerHoldup[client] = GetConVarInt(Holdup_Timing);
						SetEntityRenderColor(client, 255, 0, 0, 255);
						g_bHoldup = true;
						CreateTimer(1.0, Timer_Holdup, client, TIMER_REPEAT);
						
						char zone[64];
						if(rp_GetClientInt(client, i_ByteZone) == 155)
							Format(STRING(zone), "McDonald's");
						else if(rp_GetClientInt(client, i_ByteZone) == 144)
							Format(STRING(zone), "Dolce & Gabanna");		
								
						CPrintToChatAll("{lightred}─────────────────────────────────────────");
						CPrintToChatAll("           		{green}Holdup {yellow}%s          		", zone);
						CPrintToChatAll("           		{green}En cours          	                      ");
						CPrintToChatAll("{lightred}─────────────────────────────────────────");
						
						LoopClients(braqueurs)
						{
							if(rp_GetClientInt(braqueurs, i_Job) == rp_GetClientInt(client, i_Job) && rp_GetClientInt(braqueurs, i_ByteZone) == 144 || rp_GetClientInt(braqueurs, i_ByteZone) == 155)
							{
								SetEntityRenderColor(braqueurs, 255, 0, 0, 255);
								isComplice[braqueurs] = true;
								isComplice[client] = true;
								nbBraqueurs++;
							}
						}
						
						PrintHintTextToAll("HOLDUP : Les policiers tués ont la possibilité de revenir en tant que renfort.");
					}
					else
					{
						CPrintToChat(client, "%s %i policiers sont requis pour faire un holdup !", TEAM, GetConVarInt(HoldupNeededCT));
					}
				}
				else
				{
					CPrintToChat(client, "%s Ce holdup n'est pas encore disponible !", TEAM);
				}
			}
			else
			{
				CPrintToChat(client, "%s Vous n'êtes pas dans la bonne zone !", TEAM);
			}
		}
		else
		{
			CPrintToChat(client, "%s Votre job ne permet pas de faire de holdup !", TEAM);
		}
	}
	else
	{
		CPrintToChat(client, "%s Vous devez être en vie !", TEAM);
	}
	return Plugin_Handled;
}

public Action Timer_Holdup(Handle timer, any client)
{
	char zone[64];
	if(rp_GetClientInt(client, i_ByteZone) == 155)
		Format(STRING(zone), "McDonald's");
	else if(rp_GetClientInt(client, i_ByteZone) == 144)
		Format(STRING(zone), "Dolce & Gabanna");
	
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			if (rp_GetClientInt(client, i_ByteZone) == 155 || rp_GetClientInt(client, i_ByteZone) == 144)
			{
				if (0 < g_iTimerHoldup[client])
				{													
					g_iTimerHoldup[client]--;
					LoopClients(braqueurs)
						if(isComplice[braqueurs])
							PrintHintText(braqueurs, "<font color='#5eff00'>Holdup en cours</font> : <font color='#eaff00'>%i</font> secondes restantes...", g_iTimerHoldup[client]);
				}
				else
				{
					int iGain = GetRandomInt(GetConVarInt(Holdup_gain_min), GetConVarInt(Holdup_gain_max));
					
					
					CPrintToChatAll("{lightred}─────────────────────────────────────────");
					CPrintToChatAll("           		{green}Holdup {yellow}%s          	       ", zone);
					CPrintToChatAll("           			{green}Succès          	               ");
					CPrintToChatAll("           			{green}Braqueurs: {yellow}%i          	               ", nbBraqueurs);
					LoopClients(braqueurs)
					{
						if(isComplice[braqueurs])
						{
							rp_SetClientInt(braqueurs, i_Money, rp_GetClientInt(braqueurs, i_Money) + iGain / nbBraqueurs);
							SetEntityRenderColor(braqueurs, 255, 255, 255, 255);
							CPrintToChat(isComplice[braqueurs], "           		{green}Gain: {yellow}%i$          	                    ", iGain / nbBraqueurs);
							isComplice[braqueurs] = false;
						}	
					}
					CPrintToChatAll("{lightred}─────────────────────────────────────────");
					

					CreateTimer(GetConVarFloat(HoldupTiming), Timer_Holdup_Refresh);
					TrashTimer(timer, true);
				}
			}
			else
			{
				LoopClients(braqueurs)
					if(isComplice[braqueurs])
						SetEntityRenderColor(braqueurs, 255, 255, 255, 255);
				CPrintToChatAll("{lightred}─────────────────────────────────────────");
				CPrintToChatAll("           		{green}Holdup {yellow}%s          	       ", zone);
				CPrintToChatAll("           		{lightred}Échec          	                      ");
				CPrintToChatAll("           	{green}Braqueur Principal Hors Zone          	       ");
				CPrintToChatAll("{lightred}─────────────────────────────────────────");
				TrashTimer(timer, true);
				g_bHoldup = false;
			}
		}
		else
		{
			LoopClients(braqueurs)
				if(isComplice[braqueurs])
					SetEntityRenderColor(braqueurs, 255, 255, 255, 255);
			CPrintToChatAll("{lightred}─────────────────────────────────────────");
			CPrintToChatAll("           		{green}Holdup {yellow}%s          		", zone);
			CPrintToChatAll("           		{lightred}Échec          	                      ");
			CPrintToChatAll("           	{green}Braqueur Principal décédée          	       		");
			CPrintToChatAll("{lightred}─────────────────────────────────────────");
			TrashTimer(timer, true);
			g_bHoldup = false;
		}
	}
	else
	{
		LoopClients(braqueurs)
			if(isComplice[braqueurs])
				SetEntityRenderColor(braqueurs, 255, 255, 255, 255);
		CPrintToChatAll("{lightred}─────────────────────────────────────────");
		CPrintToChatAll("           		{green}Holdup {yellow}%s          		", zone);
		CPrintToChatAll("           		{lightred}Échec          	                      ");
		CPrintToChatAll("           	{green}Braqueur Principal déconnéctée          	       ");
		CPrintToChatAll("{lightred}─────────────────────────────────────────");
		TrashTimer(timer, true);
		g_bHoldup = false;
	}
}

public Action Timer_Holdup_Refresh(Handle timer)
{
	g_bHoldup = false;
	CPrintToChatAll("%s  {green}Les holdups sont à nouveau disponibles !", TEAM);
}