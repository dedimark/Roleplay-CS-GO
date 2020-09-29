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
#include <cstrike>
#include <smlib>
#include <sdkhooks>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>
#include <emitsoundany>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
bool canBraquage = true;
bool canHack = true;
bool canCrochetage[MAXPLAYERS + 1];

bool canVol[MAXPLAYERS + 1];
ConVar cooldown_vol;

char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];	

int tempEnt[MAXPLAYERS + 1];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Braquages, Holdup, Hack, Vol...",
	author = "Benito",
	description = "Système de contrebandit",
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_vol.log");
	
	cooldown_vol = CreateConVar("rp_vol_cooldown", "25.0", "Cooldown for re-use an steal command");
	AutoExecConfig(true, "rp_illegal");
	
	RegConsoleCmd("vol", Cmd_Vol);
	RegConsoleCmd("volarme", Cmd_VolArme);
	//RegConsoleCmd("volitem", Cmd_VolItem);
	RegConsoleCmd("hack", Cmd_Hack);
	RegConsoleCmd("braquage", Cmd_Braquage);
	RegConsoleCmd("crocheter", Cmd_Crochetage);
	RegConsoleCmd("piedbiche", Cmd_PiedBiche);
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPutInServer(int client)
{
	canVol[client] = true;
}	

public void OnClientDisconnect(int client)
{
	canVol[client] = false;
}	

public Action Cmd_VolArme(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}	
	
	int target = GetAimEnt(client, false);
	if(rp_GetClientInt(client, i_Job) != 2 && rp_GetClientInt(client, i_Job) != 3)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsClientValid(target))
	{
		CPrintToChat(client, "%s Vous devez viser un joueur.", TEAM);
		return Plugin_Handled;
	}	
	else if(!canVol[client])
	{
		CPrintToChat(client, "%s Vous devez patienter {lightgreen}%0.3f{default} secondes afin de voler.", TEAM, GetConVarFloat(cooldown_vol));
		return Plugin_Handled;
	}			
	else if(rp_GetClientBool(target, b_isAfk))
	{
		CPrintToChat(client, "%s Vous ne pouvez pas voler une personne inactive.", TEAM);
		return Plugin_Handled;
	}
	else if(Distance(client, target) > 100.0)
	{
		CPrintToChat(client, "%s Vous devez vous rappocher.", TEAM);
		return Plugin_Handled;
	}
	else if(rp_GetClientInt(client, i_timeJail) > 0)
	{
		CPrintToChat(client, "%s Vous ne pouvez pas voler en prison.", TEAM);
		return Plugin_Handled;
	}
	
	if(rp_GetClientInt(client, i_Job) != rp_GetClientInt(target, i_Job) || rp_GetClientInt(client, i_Job) == rp_GetClientInt(target, i_Job) && rp_GetClientInt(client, i_Grade) < rp_GetClientInt(target, i_Grade))
	{
		rp_SetClientInt(client, i_LastVolTarget, target);
		rp_SetClientInt(target, i_LastVolTime, GetTime());
		
		int weapon = Client_GetActiveWeapon(target);
		char entClass[64];
		Entity_GetClassName(weapon, STRING(entClass));
		if(StrContains(entClass, "knife") != -1)
		{
			CPrintToChat(client, "%s Vous ne pouvez pas voler son couteau.", TEAM);
			return Plugin_Handled;
		}
		
		rp_SetClientInt(client, i_LastVolArme, weapon);
		
		PrintHintText(client, "Vous tentez de voler l'arme de %N, restez près de lui.", target);			
		
		rp_SetClientInt(client, i_LastVolArme, target);
		
		SetEntityRenderColor(client, 255, 20, 20, 192);
		CreateTimer(0.1, TimerFinVolArme, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	else
		CPrintToChat(client, "%s Vous ne pouvez pas voler un supérieur !", TEAM);
	
	return Plugin_Handled;
}

public Action Cmd_Hack(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}		
	
	if(canHack)
	{
		canHack = false;
		CreateTimer(360.0, ResetData, client);
	}
	else
		CPrintToChat(client, "%s Vous devez patienter afin de hacker les documents confidentiels.", TEAM);
	
	return Plugin_Handled;
}

public Action Cmd_Braquage(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}	

	if(canBraquage)
	{
		canBraquage = false;
		CreateTimer(720.0, ResetData, client);
	}	
	else
		CPrintToChat(client, "%s Vous devez patienter afin de braquer la banque.", TEAM);
	
	return Plugin_Handled;
}

public Action ResetData(Handle timer, any client)
{
	if(!canBraquage)
	{
		canBraquage = true;
		CPrintToChatAll("%s Les braquages sont de nouveau disponibles.", TEAM);
	}	
	if(!canHack)
	{
		canHack = true;
		CPrintToChatAll("%s Les hack's sont de nouveau disponibles.", TEAM);
	}	
}

/*	TIMER	*/

public Action TimerFinVolArme(Handle timer, any client)
{
	if(IsClientValid(client) && IsValidEntity(client))
	{
		rp_SetDefaultClientColor(client);
		
		char entityClassname[128];
		Entity_GetClassName(rp_GetClientInt(client, i_LastVolArme), STRING(entityClassname));
		
		if(IsValidEntity(rp_GetClientInt(client, i_LastVolArme)))
			rp_DeleteWeapon(client, rp_GetClientInt(client, i_LastVolArme));
		
		int arme = GivePlayerItem(client, entityClassname);
		SetEntityRenderMode(arme, RENDER_TRANSCOLOR);
		SetEntityRenderColor(arme, 255, 20, 20, 255);
		
		PrintHintText(client, "Vous avez volé l'arme de %N.", rp_GetClientInt(client, i_LastVolTarget));
		
		CPrintToChat(rp_GetClientInt(client, i_LastVolTarget), "%s Votre arme vient d'être {lightred}voler {default}de force.", TEAM);
		LogToFile(logFile, "Le joueur %N a volé une arme a %N.", client, rp_GetClientInt(client, i_LastVolTarget));
		return Plugin_Stop;
	}
	else
	{
		if(Distance(client, rp_GetClientInt(client, i_LastVolTarget)) >= 100.0)
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);			
							
			CPrintToChat(client, "%s Le vol de l'arme de %N a été interrompu.", TEAM, rp_GetClientInt(client, i_LastVolTarget));
			return Plugin_Stop;
		}
		else
			return Plugin_Continue;
	}
}

public Action Cmd_Vol(int client, int args)
{	
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}	
	
	int target = GetClientAimTarget(client, true);
	
	if(rp_GetClientInt(client, i_Job) != 2 && rp_GetClientInt(client, i_Job) != 3)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsClientValid(target))
	{
		CPrintToChat(client, "%s Vous devez viser un joueur.", TEAM);
		return Plugin_Handled;
	}
	else if(rp_GetClientInt(target, i_Job) == rp_GetClientInt(client, i_Job))
	{
		CPrintToChat(client, "%s Vous ne pouvez pas voler un collègue.", TEAM);
		return Plugin_Handled;
	}	
	else if(rp_GetClientBool(target, b_isAfk))
	{
		CPrintToChat(client, "%s Vous ne pouvez pas voler une personne inactive.", TEAM);
		return Plugin_Handled;
	}
	else if(Distance(client, target) > 100.0)
	{
		CPrintToChat(client, "%s Vous devez vous rappocher.", TEAM);
		return Plugin_Handled;
	}
	else if(rp_GetClientInt(client, i_timeJail) > 0)
	{
		CPrintToChat(client, "%s Vous ne pouvez pas voler en prison.", TEAM);
		return Plugin_Handled;
	}	
	else if(!canVol[client])
	{
		CPrintToChat(client, "%s Vous devez patienter {lightgreen}%0.3f{default} secondes afin de voler.", TEAM, GetConVarFloat(cooldown_vol));
		return Plugin_Handled;
	}
	
	static int RandomItem[MAXITEMS];
	int VOL_MAX, amount, money, job, prix;	
	money = rp_GetClientInt(target, i_Money);
	VOL_MAX = (money+rp_GetClientInt(target, i_Bank)) / 200;
	amount = GetRandomInt(1, VOL_MAX);
	
	if(VOL_MAX > 0 && money >= 1)
	{		
		CreateTimer(GetConVarFloat(cooldown_vol), CoolDownVol, client);
		
		CPrintToChat(client, "%s Vous avez volé %d$.", TEAM, amount);
		CPrintToChat(target, "%s Quelqu'un vous a volé %d$.", TEAM, amount);
		LogToFile(logFile, "%N a vole %i$ a %N", client, amount, target);
		
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + amount / 2);
		rp_SetJobCapital(rp_GetClientInt(client, i_Job), rp_GetJobCapital(rp_GetClientInt(client, i_Job)) + amount / 2);			
		
		rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - amount);
		
		canVol[client] = false;
		
		rp_SetClientInt(client, i_LastVolTarget, target);
		rp_SetClientInt(target, i_LastVolTime, GetTime());
		rp_SetClientInt(client, i_LastVolAmount, amount);
		rp_SetClientInt(target, i_LastVol, client);
	}
	else if(VOL_MAX > 0 && money <= 0 && rp_GetClientInt(client, i_Job) == 2 && !rp_GetClientBool(target, b_isClientNew))
	{
		amount = 0;
		int itemRDM = GetRandomInt(0, MAXITEMS);
		CreateTimer(GetConVarFloat(cooldown_vol), CoolDownVol, client);
		
		for(int i = 0; i < MAXITEMS; i++) 
		{			
			if( rp_GetClientItem(target, i) <= 0 )
				continue;
				
			char job_string[10];
			rp_GetItemData(i, item_type_job_id, STRING(job_string));
			job = StringToInt(job_string);
			if( job == 0|| job == 91 || job == 101 || job == 181 )
				continue;
			if( job == 51 && !(rp_GetClientItem(target, i) >= 1 && Math_GetRandomInt(0, 1) == 1) ) // TODO: Double vérif voiture
				continue;
			
			RandomItem[amount++] = i;
		}
		
		if(amount == 0) 
		{
			CPrintToChat(client, "%s Ce joueur n'a pas d'argent, ni d'item sur lui.", TEAM);
			return Plugin_Stop;
		}
		
		int i = RandomItem[ Math_GetRandomInt(0, (amount-1)) ];			
		char item_price[64];
		rp_GetItemData(i, item_type_prix, STRING(item_price));
		prix = StringToInt(item_price) / 2;
		
		rp_ClientGiveItem(target, i, -1);
		rp_ClientGiveItem(client, i, 1);
			
		char item_name[64];
		rp_GetItemData(itemRDM, item_type_name, STRING(item_name));
		
		CPrintToChat(client, "%s Vous avez volé 1 %s à %N", TEAM, item_name, target);
		CPrintToChat(target, "%s Un voleur vous a volé 1 %s", TEAM, item_name);
		LogToFile(logFile, "%N a vole 1 %s a %N", client, item_name, target);
		
		canVol[client] = false;
		rp_SetClientInt(client, i_LastVolTarget, target);
		rp_SetClientInt(target, i_LastVolTime, GetTime());
		rp_SetClientInt(target, i_LastVol, client);	
		
		rp_SetJobCapital(2, rp_GetJobCapital(2) + prix);
		rp_SetJobCapital(job, rp_GetJobCapital(job) - prix);
	}
	else 
	{
		CPrintToChat(client, "%s %N n'a pas d'argent sur lui.", TEAM, target);
	}		
	
	return Plugin_Handled;
}

/*public Action Cmd_VolItem(int client, int args)
{	
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}	
	
	int target = GetClientAimTarget(client, true);
	if(rp_GetClientInt(client, i_Job) != 2 || rp_GetClientInt(client, i_Job) != 3)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}	
	else if(rp_GetClientBool(target, b_isAfk))
	{
		CPrintToChat(client, "%s Vous ne pouvez pas voler une personne inactive.", TEAM);
		return Plugin_Handled;
	}
	else if(Distance(client, target) > 100.0)
	{
		CPrintToChat(client, "%s Vous devez vous rappocher.", TEAM);
		return Plugin_Handled;
	}
	else if(rp_GetClientInt(client, i_timeJail) > 0)
	{
		CPrintToChat(client, "%s Vous ne pouvez pas voler en prison.", TEAM);
		return Plugin_Handled;
	}	
	else if(!canVol[client])
	{
		CPrintToChat(client, "%s Vous devez patienter {lightgreen}%f{default} secondes afin de voler.", TEAM, GetConVarFloat(cooldown_vol));
		return Plugin_Handled;
	}
	
	int attempt_amount[MAXPLAYERS + 1];
	if(attempt_amount[client] == GetConVarInt(max_attemps_item))
	{
		CreateTimer(GetConVarFloat(cooldown_vol), CoolDownVol, client);		
		canVol[client] = false;
		CPrintToChat(client, "%s {lightred}Echèc, {default}Vous avez atteint la limite d'essaie, veuillez patienter {lightgreen}%f{default} secondes afin de voler.", TEAM, GetConVarFloat(cooldown_vol));
		attempt_amount[client] = 0;
		return Plugin_Handled;
	}
	
	if(IsClientValid(target))
	{
		int itemRDM = GetRandomInt(0, MAXITEMS);
		CreateTimer(GetConVarFloat(cooldown_vol), CoolDownVol, client);
		
		if(rp_GetClientItem(target, itemRDM) >= 1)
		{
			rp_ClientGiveItem(client, itemRDM, rp_GetClientItem(client, itemRDM) + 1);
			rp_ClientGiveItem(target, itemRDM, rp_GetClientItem(client, itemRDM) - 1);
			
			char item_name[64];
			rp_GetItemData(itemRDM, item_type_name, STRING(item_name));
			
			CPrintToChat(client, "%s Vous avez volé 1 %s à %N", TEAM, item_name, target);
			CPrintToChat(target, "%s Un voleur vous a volé 1 %s", TEAM, item_name);
			LogToFile(logFile, "%N a vole 1 %s a %N", client, item_name, target);
			
			canVol[client] = false;
			rp_SetClientInt(client, i_LastVolTarget, target);
			rp_SetClientInt(target, i_LastVolTime, GetTime());
		}	
		else
		{
			attempt_amount[client]++;
			FakeClientCommand(client, "volitem");
		}	
	}
	else
		CPrintToChat(client, "%s Vous dêvez viser un joueur valide.", TEAM);	
	
	return Plugin_Handled;
}*/	

public Action CoolDownVol(Handle timer, any client)
{
	rp_SetClientInt(client, i_LastVolAmount, 0);
	rp_SetClientInt(client, i_LastVolTarget, 0);
	rp_SetClientInt(client, i_LastVolTime, 0);
	rp_SetClientInt(client, i_LastVolArme, 0);
	
	canVol[client] = true;
	CPrintToChat(client, "%s Vous pouvez désormais voler.", TEAM);
}	

public Action Cmd_PiedBiche(int client, int args)
{
	int target = GetClientAimTarget(client, false);
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}	
	else if(rp_GetClientInt(client, i_Job) != 2 && rp_GetClientInt(client, i_Job) != 3)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}	
	else if(Distance(client, target) > 100.0)
	{
		CPrintToChat(client, "%s Vous devez vous rappocher.", TEAM);
		return Plugin_Handled;
	}
	else if(!rp_GetClientBool(client, b_asCrowbar))
	{
		CPrintToChat(client, "%s Vous n'avez pas de pied-de-biche.", TEAM);
		return Plugin_Handled;
	}
	else if(!canCrochetage[client])
	{
		CPrintToChat(client, "%s Vous dêvez patienter avant d'utiliser votre pied-de-biche.", TEAM);
		return Plugin_Handled;
	}
	else if(GetVehicle(client) != 0 && rp_GetClientInt(client, i_Job) == 3) 
	{
		CPrintToChat(client, "%s Impossible d'utiliser un pied-de-biche dans une voiture.", TEAM);
		return Plugin_Handled;
	}

	if(IsValidEntity(target))
	{
		char class[64], model[128], name[64];
		Entity_GetClassName(target, STRING(class));
		Entity_GetModel(target, STRING(model));
		Entity_GetName(target, STRING(name));
		
		if(rp_GetClientInt(client, i_Job) == 3)
		{
			if(StrEqual(class, "prop_vehicle_driveable"))
			{
				if(!Entity_IsLocked(target))
				{
					//LoadingBar(client, 10);
					PrecacheSoundAny("doors/door_locked2.wav");
					EmitSoundToAllAny("doors/door_locked2.wav", client, _, _, _, 1.0);
					
					tempEnt[client] = target;
					canCrochetage[client] = false;
					SetEntityRenderColor(client, 200, 0, 0, 255);
					CreateTimer(10.0, DoPiedDeBiche, client);
				}
				else
					CPrintToChat(client, "%s La voiture est déjà ouverte.", TEAM);
			}
			else
				CPrintToChat(client, "%s Vous dêvez viser une voiture.", TEAM);			
		}
		else
		{
			if(StrContains(model, "atm") != -1 || StrContains(name, "coffre_") != -1)
			{
				if(!Entity_IsLocked(target))
				{
					//LoadingBar(client, 10);
					PrecacheSoundAny("doors/door_locked2.wav");
					EmitSoundToAllAny("doors/door_locked2.wav", client, _, _, _, 1.0);
					
					tempEnt[client] = target;
					canCrochetage[client] = false;
					SetEntityRenderColor(client, 200, 0, 0, 255);
					CreateTimer(10.0, DoPiedDeBiche, client);
				}
				else
					CPrintToChat(client, "%s La voiture est déjà ouverte.", TEAM);
			}
			else
				CPrintToChat(client, "%s Vous dêvez viser un distributeur de billet ou bien un coffre d'armes.", TEAM);			
		}		
	}
	else
		CPrintToChat(client, "%s Vous dêvez viser une entité valide.", TEAM);

	return Plugin_Handled;
}

public Action DoPiedDeBiche(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		if(IsPlayerAlive(client))
		{
			canCrochetage[client] = true;
			
			SetEntityRenderColor(client, 255, 255, 255, 255);
			
			bool kit, crochetage;
			if(rp_GetClientInt(client, i_Grade) <= 2)
			{
				int nombre1 = GetRandomInt(0, 10);
				int nombre2 = GetRandomInt(0, 10);
				if(nombre1 <= 9)
					crochetage = true;
				else
					crochetage = false;
				if(nombre2 <= 9)
					kit = true;
				else
					kit = false;
			}
			else if(rp_GetClientInt(client, i_Grade) == 3)
			{
				int nombre1 = GetRandomInt(0, 10);
				int nombre2 = GetRandomInt(0, 10);
				if(nombre1 <= 8)
					crochetage = true;
				else
					crochetage = false;
				if(nombre2 <= 8)
					kit = true;
				else
					kit = false;
			}
			else if(rp_GetClientInt(client, i_Grade) == 4)
			{
				int nombre1 = GetRandomInt(0, 10);
				int nombre2 = GetRandomInt(0, 10);
				if(nombre1 <= 7)
					crochetage = true;
				else
					crochetage = false;
				if(nombre2 <= 7)
					kit = true;
				else
					kit = false;
			}
			else if(rp_GetClientInt(client, i_Grade) == 5)
			{
				int nombre1 = GetRandomInt(0, 10);
				int nombre2 = GetRandomInt(0, 10);
				if(nombre1 <= 6)
					crochetage = true;
				else
					crochetage = false;
				if(nombre2 <= 6)
					kit = true;
				else
					kit = false;
			}
			
			if(!crochetage)
				CPrintToChat(client, "%s Vous n'avez pas réussi à crocheter la porte.", TEAM);
			else
			{
				if(IsValidEntity(tempEnt[client]))
				{
					AcceptEntityInput(tempEnt[client], "Unlock");
					AcceptEntityInput(tempEnt[client], "Open");
					PrintHintText(client, "Porte crochetée !");
				}
			}
			if(!kit)
			{
				CPrintToChat(client, "%s Votre pied-de-biche s'est cassé, retournez en chercher un autre.", TEAM);
				PrintCenterText(client, "Kit de crochetage cassé !");
				rp_SetClientBool(client, b_asCrowbar, false);
			}
		}
	}
}

public Action Cmd_Crochetage(int client, int args)
{
	int target = GetClientAimTarget(client, false);
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}		
	else if(rp_GetClientInt(client, i_Job) != 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}	
	else if(Distance(client, target) > 100.0)
	{
		CPrintToChat(client, "%s Vous devez vous rappocher.", TEAM);
		return Plugin_Handled;
	}
	else if(rp_GetClientInt(client, i_KitCrochetage) == 0)
	{
		CPrintToChat(client, "%s Vous n'avez pas de kit de crochetage.", TEAM);
		return Plugin_Handled;
	}
	else if(!canCrochetage[client])
	{
		CPrintToChat(client, "%s Vous dêvez patienter avant d'utiliser votre pied-de-biche.", TEAM);
		return Plugin_Handled;
	}
	else if(GetVehicle(client) != 0 && rp_GetClientInt(client, i_Job) == 3) 
	{
		CPrintToChat(client, "%s Impossible d'utiliser un pied-de-biche dans une voiture.", TEAM);
		return Plugin_Handled;
	}

	if(IsValidEntity(target))
	{
		char class[64], name[128];
		Entity_GetClassName(target, STRING(class));
		Entity_GetName(target, STRING(name));
		
		if(StrContains(class, "door") != -1)
		{
			DataPack dp = new DataPack();
			CreateDataTimer(15.0, TryUnlockDoor, dp, TIMER_REPEAT);
			dp.WriteCell(client);
			dp.WriteCell(target);
			SetEntityRenderColor(client, 255, 20, 20, 192);
			
			if(StrContains(name, "STEAM_"))
			{
				int owner = Client_FindBySteamId(name);
				if(IsClientValid(owner))
					CPrintToChat(owner, "%s", TEAM);
			}	
		}
		else
			CPrintToChat(client, "%s Vous dêvez viser une porte.", TEAM);
	}
	else
		CPrintToChat(client, "%s Vous dêvez viser une entité valide.", TEAM);

	return Plugin_Handled;
}	

public Action TryUnlockDoor(Handle timer, DataPack dp)
{
	dp.Reset();
	int client = dp.ReadCell();
	int target = dp.ReadCell();
	
	int chance = GetRandomInt(1, 2);
	if(chance == 2)
	{
		Entity_UnLock(target);
		CPrintToChat(client, "%s Vous avez crocheté avec succès cette porte.", TEAM);
		
		EmitSoundToAllAny("UI/arm_bomb.wav", target);
	}
	else
	{
		rp_SetClientInt(client, i_KitCrochetage, rp_GetClientInt(client, i_KitCrochetage) - 1);
		CPrintToChat(client, "%s Votre kit de crochetage a cassé, réessayez plutard.", TEAM);
	}		
}	