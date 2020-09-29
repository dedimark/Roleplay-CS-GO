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
#include <smlib>
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <roleplay>
#include <multicolors>
#include <emitsoundany>

/***************************************************************************************

							P L U G I N  -  D E F I N E S

***************************************************************************************/
#define COLOR_TASER			{15, 15, 255, 225}
#define COLOR_BLEU			{0, 128, 255, 255}

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
Handle timerTase[MAXPLAYERS + 1] =  { null, ... };
GlobalForward g_OnTased;
char logFile[PLATFORM_MAX_PATH];
char steamID[MAXPLAYERS + 1][32];
char lastModel[MAXPLAYERS + 1][128];

char g_szJailRaison[][][128] =  {
	{ "Garde à vue", "12", "12", "0", "0" }, 
	{ "Meurtre", "-1", "-1", "-1", "1" }, 
	{ "Agression physique", "1", "6", "250", "1" }, 
	{ "Intrusion propriété privée", "0", "3", "100", "0" }, 
	{ "Vol, tentative de vol", "0", "3", "50", "1" }, 
	{ "Fuite, refus d'obtempérer", "0", "6", "200", "0" }, 
	{ "Insultes, Irrespect", "1", "6", "250", "0" }, 
	{ "Trafic illégal", "0", "6", "100", "0" }, 
	{ "Nuisance sonore", "0", "6", "100", "0" }, 
	{ "Tir dans la rue", "0", "6", "100", "1" }, 
	{ "Conduite dangereuse", "0", "6", "150", "0" }, 
	{ "Mutinerie, évasion", "-2", "-2", "50", "1" }
};

bool canSwitchTeam[MAXPLAYERS+1] =  { true, ... };
float g_flLastPos[65][3];
int laserTaser;

enum jail_raison_type {
	jail_raison = 0, 
	jail_temps, 
	jail_temps_nopay, 
	jail_amende, 
	jail_simple, 
	
	jail_type_max
};

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Police", 
	author = "Benito", 
	description = "Métier Policier", 
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_police.log");
	
	g_OnTased = new GlobalForward("RP_OnPlayerTase", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_String, Param_String);
	
	RegConsoleCmd("taser", Command_Taser);
	RegConsoleCmd("tazer", Command_Taser);
	RegConsoleCmd("tazeur", Command_Taser);
	
	RegConsoleCmd("cop", Cmd_Cops);
	RegConsoleCmd("cops", Cmd_Cops);
	
	RegConsoleCmd("jail", Cmd_Jail);
	RegConsoleCmd("prison", Cmd_Jail);
	
	RegConsoleCmd("enjail", Cmd_InJail);
	RegConsoleCmd("injail", Cmd_InJail);
	RegConsoleCmd("jaillist", Cmd_InJail);
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_jails` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `timeJail` int(100) NOT NULL, \
	  `lastTimeJail` int(100) NOT NULL, \
	  `jailby` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `raison` int(20) NOT NULL, \
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

public void OnMapStart()
{
	//laserTaser = PrecacheModel("particle/beam_taser.vmt");	
	laserTaser = PrecacheModel("sprites/lgtning.vmt");
}

/* 	Commandes	*/

public Action Cmd_InJail(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}	
	else if(rp_GetClientInt(client, i_Job) != 1 && rp_GetClientInt(client, i_Job) != 7)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}	
	else if(rp_GetClientInt(client, i_ByteZone) != 1)
	{
		CPrintToChat(client, "%s Vous dêvez être dans le commissariat.", TEAM);
		return Plugin_Handled;
	}
	
	char tmp[256];	
	rp_SetClientBool(client, b_menuOpen, true);	
	Menu menu = new Menu(Handler_NullCancel);
	menu.SetTitle("Liste des joueurs en prison:");
	
	LoopClients(i) 
	{
		Format(STRING(tmp), "%N  - %.1f heures", i, rp_GetClientInt(i, i_timeJail) /60.0); // TODO REGLAGES
		menu.AddItem(tmp, tmp, ITEMDRAW_DISABLED);
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
		
	return Plugin_Handled;
}

public Action Cmd_Cops(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}	
		
	int job = rp_GetClientInt(client, i_Job);
	int grade = rp_GetClientInt(client, i_Grade);
	
	if(grade >= 4 && rp_GetClientInt(client, i_ByteZone) != 1)
	{
		CPrintToChat(client, "%s Vous dêvez être dans votre Q.G.", TEAM);			
		return Plugin_Handled;
	}		
	
	if(job == 1 || job == 7)	
	{
		if(canSwitchTeam[client])
		{
			if(GetClientTeam(client) == CS_TEAM_T)
			{
				GetClientModel(client, lastModel[client], sizeof(lastModel[]));				
				CS_SwitchTeam(client, CS_TEAM_CT);
				CPrintToChat(client, "%s Vous avez mit votre tenue de service.", TEAM);
				SetJobSkin(client, false);		
				
				rp_SetClientHealth(client, 500);
				Entity_SetMaxHealth(client, 500);
				rp_SetClientArmor(client, 250);
				rp_SetClientHelmet(client, true);
			}
			else if(GetClientTeam(client) == CS_TEAM_CT)
			{
				Entity_SetModel(client, lastModel[client]);
				CS_SwitchTeam(client, CS_TEAM_T);
				CPrintToChat(client, "%s Vous avez enlevé votre tenue de service.", TEAM);
				
				rp_SetClientHelmet(client, false);
				rp_SetClientHealth(client, 100);
				Entity_SetMaxHealth(client, 200);
			}
			else if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
			{
				return Plugin_Handled;
			}			
		
			if (job == 1)
			{
				if (grade <= 2)
					CreateTimer(30.0, EnableSwitchTeam, client, TIMER_FLAG_NO_MAPCHANGE);
				else if (grade == 3)
					CreateTimer(40.0, EnableSwitchTeam, client, TIMER_FLAG_NO_MAPCHANGE);
				else if (grade == 4)
					CreateTimer(50.0, EnableSwitchTeam, client, TIMER_FLAG_NO_MAPCHANGE);
				else if (grade == 5)
					CreateTimer(60.0, EnableSwitchTeam, client, TIMER_FLAG_NO_MAPCHANGE);
				else if (grade == 6)
					CreateTimer(120.0, EnableSwitchTeam, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			if (job == 7)
				CreateTimer(30.0, EnableSwitchTeam, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
			CPrintToChat(client, "%s Vous devez patienter avant de changer de tenue.", TEAM);
	}
	else
	{
		CPrintToChat(client, "%s L'uniforme est reservé aux forces de l'ordre.", TEAM);
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", TEAM);
	}	
		
	return Plugin_Handled;	
}

public Action EnableSwitchTeam(Handle timer, any client)
{
	if(IsClientValid(client))
		canSwitchTeam[client] = true;
}		

public Action Command_Taser(int client, int args)
{
	if(!IsClientValid(client)) 
		return Plugin_Handled;
	
	if(rp_GetClientInt(client, i_Job) == 1 && GetClientTeam(client) == CS_TEAM_CT || rp_GetClientInt(client, i_Job) == 1 && rp_GetClientInt(client, i_Grade) <= 5 && GetClientTeam(client) == CS_TEAM_T || rp_GetClientInt(client, i_Job) == 7)
	{
		if(rp_GetClientInt(client, i_ByteZone) == 777)
		{
			CPrintToChat(client, "%s Le taser est interdit en zone PVP.", TEAM);
			return Plugin_Handled;
		}
		
		int aim = GetAimEnt(client, false);
		if(IsValidEntity(aim))
		{
			if(aim <= MaxClients && GetEntityMoveType(aim) != MOVETYPE_NOCLIP)
			{
				if(rp_GetClientInt(client, i_Job) == rp_GetClientInt(aim, i_Job) && rp_GetClientInt(client, i_Grade) > rp_GetClientInt(aim, i_Grade))
				{
					CPrintToChat(client, "%s Vous n'êtes pas autorisé à taser un supérieur.", TEAM);
					aim = client;
				}
				
				int time;
				if(rp_GetClientInt(client, i_Grade) <= 3 && Distance(client, aim) <= 1000)
					time = 10;
				else if(rp_GetClientInt(client, i_Grade) == 4 && Distance(client, aim) <= 950)
					time = 8;
				else if(rp_GetClientInt(client, i_Grade) == 5 && Distance(client, aim) <= 900)
					time = 6;
				else return Plugin_Handled;
				
				if(!rp_GetClientBool(aim, b_isTased))
				{
					if(rp_GetClientBool(aim, b_isLubrifiant))
					{
						int nombre = GetRandomInt(1, 3);
						if(nombre == 1)
						{
							rp_SetClientBool(aim, b_isLubrifiant, false);
							CPrintToChat(aim, "%s Votre lubrifiant n'as pas fonctionné.", TEAM);
							Tase(client, aim, time);
						}	
						else
						{
							rp_SetClientBool(aim, b_isLubrifiant, false);
							CPrintToChat(client, "Vous avez raté votre cible. Réessayez.", TEAM);
							CPrintToChat(aim, "%s Votre lubrifiant a été consommé", TEAM);
						}												
					}
					else					
						Tase(client, aim, time);
				}	
				else
					CPrintToChat(client, "%s Cette personne est déjà taser.", TEAM);				
			}
			else if(aim > MaxClients)
			{
				char entClass[64], entModel[64], entName[64], buffer[2][64];
				Entity_GetClassName(aim, STRING(entClass));
				Entity_GetModel(aim, STRING(entModel));
				Entity_GetName(aim, STRING(entName));
				ExplodeString(entName, "|", buffer, 2, 64);		
				
				if(StrContains(entClass, "weapon_", false) != -1 && Distance(client, aim) <= 180)
				{
					if(StrContains(entName, "police", false) != -1)
						CPrintToChat(client, "%s Vous ne pouvez pas saisir une arme du service de police.", TEAM);
					else
					{										
						TE_Taser(client, aim);
						rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 10);
						rp_SetJobCapital(1, -10);
						rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 10);
						RemoveEdict(aim);
						CPrintToChat(client, "%s Vous avez saisi une arme.", TEAM);
						CPrintToChat(client, "%s Le Chef Police vous reverse une prime de 10$ pour cette saisie.", TEAM);
					}	
				}
				else
					CPrintToChat(client, "%s Vous dévez viser une entité.", TEAM);
					
				int reward;
				
				Call_StartForward(g_OnTased);
				Call_PushCell(client);
				Call_PushCell(aim);
				Call_PushCell(reward);
				Call_PushString(entClass);
				Call_PushString(entModel);
				Call_PushString(entName);
				Call_Finish();
				
				rp_SetJobCapital(1, -reward);
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + reward);		
				TE_Taser(client, aim);			
			}
		}
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande !", TEAM);	
	
	return Plugin_Handled;
}

void Tase(int client, int target, int time)
{
	if(!IsValidEntity(client) || !IsValidEntity(target))
		return;
	else if(GetEntityMoveType(target) == MOVETYPE_NOCLIP)
		return;
	
	SetEntityRenderColor(target, 0, 128, 255, 192);
	SetEntityMoveType(target, MOVETYPE_NONE);
	
	TE_Taser(client, target);
	
	ScreenFade(target, time/2, COLOR_TASER);
	
	if(timerTase[target] != null)
	{
		TrashTimer(timerTase[target], true);
		timerTase[target] = null;
	}
	
	timerTase[target] = CreateTimer(float(time), UnTase, target);
	rp_SetClientBool(target, b_isTased, true);
	rp_SetClientBool(target, b_canItem, false);
	
	CPrintToChat(client, "%s Vous avez tasé %N.", TEAM, target);
	CPrintToChat(target, "%s GZzzt !! Vous avez été tasé par %N.", TEAM, client);
	LogToGame("[TAZER] %L a tazé %N dans %d.", client, target, rp_GetClientInt(client, i_ByteZone));
}

int TE_Taser(int client, int target)
{
	if(IsValidEntity(client) && IsValidEntity(target))
	{
		PrecacheSoundAny("ambient/office/zap1.wav");
		EmitSoundToAllAny("ambient/office/zap1.wav", client, _, _, _, 1.0);
		PrecacheSoundAny("physics/body/body_medium_impact_hard6.wav");
		EmitSoundToAllAny("physics/body/body_medium_impact_hard6.wav", target, _, _, _, 1.0);
		
		TE_SetupBeamLaser(target, client, laserTaser, 0, 0, 0, 0.5, 2.0, 2.0, 3, 0.5, COLOR_BLEU, 0);
		TE_SendToAll(0.1);
		TE_SetupBeamLaser(client, target, laserTaser, 0, 0, 0, 0.5, 2.0, 2.0, 3, 0.5, COLOR_BLEU, 0);
		TE_SendToAll(0.1);
		
		float fTargetPos[3], fClientPos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", fTargetPos);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fClientPos);
		
		TE_SetupBeamPoints(fClientPos, fTargetPos, laserTaser, 0, 1, 0, 1.0, 20.0, 0.0, 2, 5.0, COLOR_BLEU, 3);
		TE_SendToAll(0.1);		
		
		SetEntityMoveType(target, MOVETYPE_NONE);
	}
}

public Action UnTase(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		timerTase[client] = null;
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		rp_SetDefaultClientColor(client);
		
		CreateTimer(5.0, ResetIsTased, client);
	}
}

public Action ResetIsTased(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		rp_SetClientBool(client, b_isTased, false);
		rp_SetClientBool(client, b_canItem, true);
	}	
}

public Action rp_OnClientTakeDamage(int client, int attacker, int inflictor, float damage, int damagetype, const char[] weapon)
{
	if(rp_GetClientInt(client, i_LastAgression) != 0)
	{
		rp_SetClientInt(attacker, i_LastAgression, client);
		CreateTimer(600.0, ResetData, attacker);
	}	
}	

public void RP_OnPlayerDeath(int attacker, int victim, int respawnTime)
{
	if(rp_GetClientInt(victim, i_LastKilled_Reverse) != 0)
	{
		if(attacker != victim)
		{
			rp_SetClientInt(victim, i_LastKilled_Reverse, attacker);
			CreateTimer(600.0, ResetData, victim);
		}	
	}
	
	if(rp_GetClientBool(victim, b_asMandat))
	{
		if(attacker != victim)
		{
			rp_SetJobPerqui(0);
			rp_SetClientBool(victim, b_asMandat, false);
			
			CPrintToChat(victim, "%s La perquisition est {lightred}annulée{default}, vous avez perdu le mandat.", TEAM);
			
			LoopClients(i)
			{
				if (i != victim && rp_GetClientInt(i, i_Job) == 1)
				{
					CPrintToChat(i, "%s Perquisition {lightred}annulée{default} ! Le responsable %N est mort.", TEAM, victim);
					PrintCenterText(i, "Perquisition annulée !!");
				}
				else if (rp_GetClientInt(i, i_Job) == rp_GetJobPerqui())
					CPrintToChat(i, "%s La perquisition de votre planque est terminée.", TEAM);
			}		
		}	
	}	
}	

public void rp_OnClientSpawn(int client)
{
	if(rp_GetClientInt(client, i_Job) == 1)
	{
		if(rp_GetClientInt(client, i_Grade) == 1)
			SetEntityHealth(client, 500);
		else if(rp_GetClientInt(client, i_Grade) == 2)
			SetEntityHealth(client, 450);	
		else if(rp_GetClientInt(client, i_Grade) == 3)
			SetEntityHealth(client, 400);	
		else if(rp_GetClientInt(client, i_Grade) == 4)
			SetEntityHealth(client, 350);
		else if(rp_GetClientInt(client, i_Grade) == 5)
			SetEntityHealth(client, 300);
		else if(rp_GetClientInt(client, i_Grade) == 6)
			SetEntityHealth(client, 250);
		
		rp_SetClientHelmet(client, false);			
		CS_SwitchTeam(client, CS_TEAM_T);
	}	
}	

public Action RP_OnPlayerTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{	
	if (damage > 0)
	{
		if(IsClientValid(client) && IsClientValid(attacker))
		{
			rp_SetClientInt(attacker, i_LastDangerousShot, client);
			CreateTimer(600.0, ResetData, attacker);
		}	
	}	
	
	return Plugin_Continue;
}

public Action ResetData(Handle timer, any client)
{
	if(rp_GetClientInt(client, i_LastDangerousShot) >= 1)
		rp_SetClientInt(client, i_LastDangerousShot, 0);
	
	if(rp_GetClientInt(client, i_LastKilled_Reverse) >= 1)
		rp_SetClientInt(client, i_LastKilled_Reverse, 0);
		
	if(rp_GetClientInt(client, i_LastAgression) >= 1)
		rp_SetClientInt(client, i_LastAgression, 0);	
		
	if(rp_GetClientInt(client, i_LastVolTime) >= 1)
		rp_SetClientInt(client, i_LastAgression, 0);	

	if(rp_GetClientInt(client, i_LastVolAmount) >= 1)
		rp_SetClientInt(client, i_LastVolAmount, 0);
		
	if(rp_GetClientInt(client, i_LastVolTarget) >= 1)
		rp_SetClientInt(client, i_LastVolTarget, 0);	
}	

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	if(StrEqual(entityName, "coffre_comico"))
		MenuArmuWCPD(client);	
		
	if (StrEqual(model, "models/props_interiors/paper_tray.mdl") && rp_GetClientInt(client, i_Job) == 1 || rp_GetClientInt(client, i_Job) == 7)
	{
		if (rp_GetClientInt(client, i_Grade) <= 5)
		{
			char buff3[3][64], jobName[32];
			ExplodeString(name, "|", buff3, 3, 64);
			// buff3[0] : mandat
			int jobPerqui = StringToInt(buff3[1]);
			// buff3[2] : steamid
			
			GetJobName(jobPerqui, STRING(jobName));
			
			if (!StrEqual(steamID[client], buff3[2]))
			{
				int joueur = Client_FindBySteamId(buff3[2]);
				CPrintToChat(client, "%s Vous avez ramassé le {yellow}mandat de perquisition{default} %s, demandé par %N.", TEAM, jobName, joueur);
			}
			else
				CPrintToChat(client, "%s Vous avez ramassé le {yellow}mandat de perquisition{default} %s.", TEAM, jobName);
			
			PrintHintText(client, "Vous avez le mandat de perquisition pour %s.", jobName);
			
			rp_SetClientBool(client, b_asMandat, true);
			rp_SetPerquisitionStat(jobPerqui, false);
			rp_SetJobPerqui(jobPerqui);
			
			CreateTimer(2160.0, ResetPerquisition, jobPerqui, TIMER_FLAG_NO_MAPCHANGE);
			rp_SetPerquisitionTime(180);			
			RemoveEdict(target);
			CreateTimer(0.08, DoGlowMandat, client);
		}
		else CPrintToChat(client, "%s Vous n'êtes pas autorisé à prendre un mandat de perquisition.", TEAM);
	}	
}	

Menu MenuArmuWCPD(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu ArmuWCPD = new Menu(DoMenuArmuWCPD);
	if(rp_GetClientInt(client, i_Job) == 1)
	{
		ArmuWCPD.SetTitle("Armurerie de Princeton :");
		
		ArmuWCPD.AddItem("1|weapon_usp_silencer", "USP-S");
		ArmuWCPD.AddItem("6|weapon_shield", "Bouclier");
		
		if(rp_GetClientInt(client, i_Grade) <= 6)
		{
			ArmuWCPD.AddItem("1|weapon_fiveseven", "Five-Seven");
			ArmuWCPD.AddItem("0|weapon_nova", "Nova");
		}
		if(rp_GetClientInt(client, i_Grade) <= 5)
		{
			ArmuWCPD.AddItem("0|weapon_m4a1_silencer", "Maverick M4A1 Carbine");
			ArmuWCPD.AddItem("0|weapon_mp7", "MP7");
		}
		if(rp_GetClientInt(client, i_Grade) <= 4)
		{
			ArmuWCPD.AddItem("0|weapon_aug", "AUG");
			ArmuWCPD.AddItem("1|weapon_p250", "P250");
			ArmuWCPD.AddItem("0|weapon_ssg08", "SSG08");
		}
		if(rp_GetClientInt(client, i_Grade) <= 3)
		{
			ArmuWCPD.AddItem("1|weapon_elite", "Dual Berettas");
			ArmuWCPD.AddItem("0|weapon_ump45", "UMP-45");
			ArmuWCPD.AddItem("0|weapon_sg553", "SG553");
		}
		if(rp_GetClientInt(client, i_Grade) <= 2)
		{
			ArmuWCPD.AddItem("1|weapon_deagle", "Desert Eagle");
			ArmuWCPD.AddItem("0|weapon_ak47", "AK47");
			ArmuWCPD.AddItem("0|weapon_awp", "AWP");
			ArmuWCPD.AddItem("0|weapon_m249", "M249");
			ArmuWCPD.AddItem("0|weapon_negev", "Negev");
		}
		ArmuWCPD.ExitButton = true;
		ArmuWCPD.Display(client, MENU_TIME_FOREVER);
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès au coffre de la police.", TEAM);
}

public int DoMenuArmuWCPD(Menu ArmuWCPD, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		ArmuWCPD.GetItem(param, STRING(info));
		
		char buffer[2][64];
		ExplodeString(info, "|", buffer, 2, 64);
		int slot = StringToInt(buffer[0]);
		if(slot != 7)
		{
			if(GetPlayerWeaponSlot(client, slot) == -1)
			{
				char strFormat[64];
				Format(STRING(strFormat), "POLICE");
				int weapon = GivePlayerItem(client, buffer[1]);
				SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
				ChangeEdictState(client, FindDataMapInfo(client, "m_hActiveWeapon"));
				Entity_SetName(weapon, strFormat);
			}
			else if(slot == 1)
				CPrintToChat(client, "%s Vous possédez déjà une arme de poing.", TEAM);
			else if(slot == 6)
				CPrintToChat(client, "%s Vous possédez déjà un bouclier.", TEAM);	
			else
				CPrintToChat(client, "%s Vous possédez déjà une arme lourde.", TEAM);
			rp_SetClientBool(client, b_menuOpen, false);	
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete ArmuWCPD;
}

public Action Cmd_Jail(int client, int args) 
{
	int job = rp_GetClientInt(client, i_Job);
	if(job == 1 || job == 7)
	{		
		int aim = GetAimEnt(client, false);
		if(IsValidEntity(aim))
		{
			if(aim <= MaxClients && GetEntityMoveType(aim) != MOVETYPE_NOCLIP)
			{
				char index[64];
				
				rp_SetClientBool(client, b_menuOpen, true);
				Menu menu = new Menu(ChoiseJail);
				menu.SetTitle("Jails");
				
				if(rp_GetClientInt(aim, i_timeJail) > 0)
				{
					Format(STRING(index), "-1|%d", aim);
					menu.AddItem(index, "Annuler la peine / Liberer");
					
					float abs[3];
					GetClientAbsAngles(aim, abs);
					
					g_flLastPos[aim] = abs;
				}	
				
				if(job == 1)
				{
					Format(STRING(index), "1|%i", aim);
					menu.AddItem(index, "Cellule №1");
					
					Format(STRING(index), "2|%i", aim);
					menu.AddItem(index, "Cellule №2");
					
					Format(STRING(index), "3|%i", aim);
					menu.AddItem(index, "Cellule №3");
					
					Format(STRING(index), "4|%i", aim);
					menu.AddItem(index, "Cellule №4");
					
					Format(STRING(index), "5|%i", aim);
					menu.AddItem(index, "Cellule №5");
					
					Format(STRING(index), "6|%i", aim);
					menu.AddItem(index, "Cellule №6");
				}
				else
				{
					Format(STRING(index), "7|%id", aim);
					menu.AddItem(index, "Cellule №1");
					
					Format(STRING(index), "8|%i", aim);
					menu.AddItem(index, "Cellule №2");
				}
					
				
				menu.ExitButton = true;
				menu.Display(client, MENU_TIME_FOREVER);
				StripWeapons(aim);
			}	
		}	
		else
			CPrintToChat(client, "%s Vous devez viser un joueur.", TEAM);	
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", TEAM);	
		
	return Plugin_Handled;
}

public int ChoiseJail(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		int target = StringToInt(buffer[1]);	
		int type = StringToInt(buffer[0]);
		
		if(type == -1)
		{
			rp_SetClientInt(target, i_timeJail, 0);
			rp_SetClientInt(target, i_timeJail_Last, 0);
			rp_SetClientInt(target, i_JailledBy, 0);
			
			CPrintToChat(client, "%s Vous avez libéré %N{default}.", TEAM, target);
			CPrintToChat(target, "%s %N {default}vous a libéré.", TEAM, client);
			
			LogToFile(logFile, "%N a libéré %N.", client, target);
			
			if(rp_GetClientInt(target, i_ByteZone) == 1 || rp_GetClientInt(target, i_ByteZone) == 7)
				rp_ClientSendToSpawn(target);
			else
				rp_ClientTeleport(target, g_flLastPos[target]);
		}
		else if(type == 1) // POLICE	
		{
			rp_ClientTeleport(target, view_as<float>(JAIL_POLICE_1));
		}
		else if(type == 2) // POLICE	
		{
			rp_ClientTeleport(target, view_as<float>(JAIL_POLICE_2));
		}
		else if(type == 3) // POLICE
		{
			rp_ClientTeleport(target, view_as<float>(JAIL_POLICE_3));
		}
		else if(type == 4) // POLICE
		{
			rp_ClientTeleport(target, view_as<float>(JAIL_POLICE_4));
		}
		else if(type == 5) // POLICE
		{
			rp_ClientTeleport(target, view_as<float>(JAIL_POLICE_5));
		}
		else if(type == 6) // POLICE	
		{
			rp_ClientTeleport(target, view_as<float>(JAIL_POLICE_6));
		}
		else if(type == 7) // JUSTICE
		{
			rp_ClientTeleport(target, view_as<float>(JAIL_TRIBUNAL_1));
		}
		else if(type == 8) // JUSTICE
		{
			rp_ClientTeleport(target,view_as<float>(JAIL_TRIBUNAL_2));
		}	

		BuildPeineSelection(client, target);
		
		CPrintToChat(target, "%s Vous avez été mis en prison, en attente de jugement par: %N", TEAM, client);
		CPrintToChat(client, "%s Vous avez mis: %N {default}en prison.", TEAM, target);
	}
	else if(action == MenuAction_Cancel)
	{
		rp_SetClientBool(client, b_menuOpen, false);
		delete menu;
	}
	else if(action == MenuAction_End)
	{
		rp_SetClientBool(client, b_menuOpen, false);
		delete menu;
	}
}	

void StripWeapons(int client) {
	
	int wepIdx;	
	for (int i = 0; i < 5; i++) 
	{
		if (i == CS_SLOT_KNIFE)
			continue;
		
		while ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1) 
		{		
			//if (canWeaponBeAddedInPoliceStore(wepIdx))
				//rp_WeaponMenu_Add(g_hBuyMenu, wepIdx, GetEntProp(wepIdx, Prop_Send, "m_OriginalOwnerXuidHigh"));
			
			RemovePlayerItem(client, wepIdx);
			RemoveEdict(wepIdx);
		}
	}
	
	FakeClientCommand(client, "use weapon_knife");
}

int BuildPeineSelection(int client, int target)
{
	Menu menu = new Menu(eventSetJailTime);
	
	char buffer[128], tmp2[256];
	Format(STRING(buffer), "Combien de temps doit rester %N?\n ", target);
	menu.SetTitle(buffer);
	
	Format(STRING(buffer), "-1_%d", target);
	menu.AddItem(buffer, "Annuler la peine / Liberer");
	
	if (rp_GetClientInt(target, i_timeJail) <= 6 * 60) 
	{
		for (int i = 0; i < sizeof(g_szJailRaison); i++) 
		{
			Format(STRING(tmp2), "%d_%d", i, target);
			menu.AddItem(tmp2, g_szJailRaison[i][jail_raison]);
		}
	}
	else 
	{
		Format(STRING(tmp2), "%d_%d", sizeof(g_szJailRaison) - 1, target);
		menu.AddItem(tmp2, g_szJailRaison[sizeof(g_szJailRaison) - 1][jail_raison]);
	}
	
	menu.ExitButton = true;	
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int eventSetJailTime(Menu menu, MenuAction action, int client, int param2) 
{
	char options[64], data[2][32];
	
	if (action == MenuAction_Select) 
	{	
		menu.GetItem(param2, options, 63);
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		
		int target = StringToInt(data[1]);
		int type = StringToInt(data[0]);
		int time_to_spend;
		int jobID = rp_GetClientInt(client, i_Job);
		//FORCE_Release(iTarget);
		
		if (type == -1) 
		{
			
			rp_SetClientInt(target, i_timeJail, 0);
			rp_SetClientInt(target, i_timeJail_Last, 0);
			rp_SetClientInt(target, i_JailledBy, 0);
			
			CPrintToChat(client, "%s Vous avez libéré %N{default}.", TEAM, target);
			CPrintToChat(target, "%s %N {default}vous a libéré.", TEAM, client);
			
			LogToFile(logFile, "%N a libéré %N.", client, target);
			
			if(rp_GetClientInt(target, i_ByteZone) == 1 || rp_GetClientInt(target, i_ByteZone) == 7)
				rp_ClientSendToSpawn(target);
			else
				rp_ClientTeleport(target, g_flLastPos[target]);
		}
		if (type == -2 || type == -3) {
			
			if (type == -3)
				rp_ClientTeleport(target, view_as<float>(JAIL_TRIBUNAL_1));
			else
				rp_ClientTeleport(target, view_as<float>(JAIL_TRIBUNAL_2));
			
			CPrintToChat(target, "%s Vous avez été mis en prison, en attente de jugement par: {lightblue}%N", TEAM, client);
			CPrintToChat(client, "%S Vous avez mis: {yellow}%N {default}dans la prison du Tribunal.", TEAM, target);
			
			LogToGame("[TSX-RP] [TRIBUNAL] %L a mis %L dans la prison du Tribunal.", client, target);
		}	
		
		if (StrEqual(g_szJailRaison[type][jail_raison], "Agression physique")) 
		{  // Agression physique
			if (rp_GetClientInt(target, i_LastAgression) + 30 < GetTime()) 
			{
				rp_SetClientInt(target, i_timeJail, 0);
				rp_SetClientInt(target, i_timeJail_Last, 0);
				rp_SetClientInt(target, i_JailledBy, 0);
				
				CPrintToChat(client, "%s {yellow}%N{default} a été libéré car il n'a pas commis d'agression.", target);
				CPrintToChat(target, "%s Vous avez été libéré car vous n'avez pas commis d'agression.");
				
				LogToGame("[TSX-RP] [JAIL] %L a été libéré car il n'avait pas commis d'agression", target);
				
				rp_ClientTeleport(target, g_flLastPos[target]);
			}
		}
		if (StrEqual(g_szJailRaison[type][jail_raison], "Tir dans la rue")) 
		{
			if (rp_GetClientInt(target, i_LastDangerousShot) + 30 < GetTime())
			{
				rp_SetClientInt(target, i_timeJail, 0);
				rp_SetClientInt(target, i_timeJail_Last, 0);
				rp_SetClientInt(target, i_JailledBy, 0);
				
				CPrintToChat(client, "%s %N{default} a été libéré car il n'a pas effectué de tir dangereux.", TEAM, target);
				CPrintToChat(target, "%s Vous avez été libéré car vous n'avez pas effectué de tir dangereux.", TEAM, client);
				
				LogToGame("[JAIL] %L a été libéré car il n'avait pas effectué de tir dangereux", target);
				
				rp_ClientTeleport(target, g_flLastPos[target]);
			}
		}		
		
		int amende = StringToInt(g_szJailRaison[type][jail_amende]);
		
		if (amende == -1) 
		{
			amende = rp_GetClientInt(target, i_KillJailDuration) * 50;
			
			if (amende == 0 && rp_GetClientInt(target, i_LastAgression) + 30 > GetTime())
				amende = StringToInt(g_szJailRaison[3][jail_amende]);
		}
		
		if (String_StartsWith(g_szJailRaison[type][jail_raison], "Vol")) 
		{
			if (rp_GetClientInt(target, i_LastVolTime) + 30 < GetTime()) 
			{
				rp_SetClientInt(target, i_timeJail, 0);
				rp_SetClientInt(target, i_timeJail_Last, 0);
				rp_SetClientInt(target, i_JailledBy, 0);
				
				CPrintToChat(client, "%s %N{default} a été libéré car il n'a pas commis de vol.", TEAM, target);
				CPrintToChat(target, "%s Vous avez été libéré car vous n'avez pas commis de vol.", TEAM, client);
				
				LogToGame("[JAIL] %L a été libéré car il n'avait pas commis de vol", target);
				
				rp_ClientTeleport(target, g_flLastPos[target]);
				return;
			}
			if (IsClientValid(rp_GetClientInt(target, i_LastVolTarget))) 
			{
				int tg = rp_GetClientInt(target, i_LastVolTarget);
				rp_SetClientInt(tg, i_Money, rp_GetClientInt(tg, i_Money) + rp_GetClientInt(target, i_LastVolAmount));
				rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - rp_GetClientInt(target, i_LastVolAmount));
				
				CPrintToChat(target, "%s Vous avez remboursé votre victime de %d$.", TEAM, rp_GetClientInt(target, i_LastVolAmount));
				CPrintToChat(tg, "%s Le voleur a été mis en prison. Vous avez été remboursé de %d$.", TEAM, rp_GetClientInt(target, i_LastVolAmount));
			}
			else 
			{
				amende += rp_GetClientInt(target, i_LastVolAmount); // Cas tentative de vol ou distrib...
			}
			
			CancelClientMenu(target, true);
		}
		
		if (rp_GetClientInt(target, i_Money) >= amende || ((rp_GetClientInt(target, i_Money) + rp_GetClientInt(target, i_Bank)) >= amende * 250 && amende <= 2500)) 
		{			
			rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) -amende);
			rp_SetJobCapital(jobID, rp_GetJobCapital(jobID) + (amende / 2));
			
			GetClientAuthId(client, AuthId_Engine, STRING(options), false);
				
			Insert_rp_sell(rp_GetDatabase(), steamID[target], steamID[client], "Caution", amende / 4, 0);
			
			time_to_spend = StringToInt(g_szJailRaison[type][jail_temps]);
			if (time_to_spend == -1) 
			{
				time_to_spend = rp_GetClientInt(target, i_KillJailDuration);
				if (time_to_spend == 0 && rp_GetClientInt(target, i_LastAgression) + 30 > GetTime())
					time_to_spend = StringToInt(g_szJailRaison[3][jail_temps]);
				
				for (int i = 1; i < MAXPLAYERS + 1; i++) 
				{
					if (!IsClientValid(i))
						continue;
					if (rp_GetClientInt(i, i_LastKilled_Reverse) != target)
						continue;
					CPrintToChat(i, "%sVotre assassin a été mis en prison.", TEAM);
				}
				time_to_spend /= 2;
			}
			
			
			if (amende > 0) 
			{				
				if (IsClientValid(target)) 
				{
					CPrintToChat(client, "%s Une amende de %i$ a été prélevée à %N{default}.", TEAM, amende, target);
					CPrintToChat(target, "%s Une caution de %i$ vous a été prelevée.", TEAM, amende);
				}
			}
		}
		else
		{
			time_to_spend = StringToInt(g_szJailRaison[type][jail_temps_nopay]);
			if (time_to_spend == -1) 
			{
				time_to_spend = rp_GetClientInt(target, i_KillJailDuration);
				if (time_to_spend == 0 && rp_GetClientInt(target, i_LastAgression) + 30 > GetTime())
					time_to_spend = StringToInt(g_szJailRaison[3][jail_temps_nopay]);
				
				for (int i = 1; i < MAXPLAYERS + 1; i++) 
				{
					if (!IsClientValid(i))
						continue;
					if (rp_GetClientInt(i, i_LastKilled_Reverse) != target)
						continue;
					CPrintToChat(i, "%s Votre assassin a été mis en prison.", TEAM);
				}
			}
			
			
			else if (rp_GetClientInt(target, i_Bank) >= amende && time_to_spend != -2) 
			{
				WantPayForLeaving(target, client, type, amende);
			}
		}
		
		if (time_to_spend < 0) 
		{
			int d = 6;
			
			if (rp_GetClientInt(target, i_ByteZone) == 1)
				d = 1;
			
			time_to_spend = rp_GetClientInt(target, i_timeJail) + (d * 60);
		}
		else 
		{
			rp_SetClientInt(target, i_jailTime_Reason, type);
			time_to_spend *= 60;
		}
		
		rp_SetClientInt(target, i_timeJail, time_to_spend);
		rp_SetClientInt(target, i_timeJail_Last, time_to_spend);

		UpdateSQL(rp_GetDatabase(), "UPDATE `rp_jails` SET `timeJail` = '%i', `lastTimeJail` = '%i', `jailby` = '%s', `raison` = '%i' WHERE 'steamid' = '%s';", time_to_spend, time_to_spend, steamID[client], type, steamID[target]);	 
		
		if (IsClientValid(client) && IsClientValid(target)) 
		{
			CPrintToChat(client, "%s %N {default}restera en prison %.1f heures pour \"%s\"", TEAM, target, time_to_spend / 60.0, g_szJailRaison[type][jail_raison]);
			CPrintToChat(target, "%s %N {default}vous a mis %.1f heures de prison pour \"%s\"", TEAM, client, time_to_spend / 60.0, g_szJailRaison[type][jail_raison]);
		}
		else 
		{
			CPrintToChat(client, "%s Le joueur s'est déconnecté mais il fera %.1f heures de prison", TEAM, time_to_spend / 60.0);
			
			SetSQL_Int(rp_GetDatabase(), "rp_jail", "timejail", rp_GetClientInt(target, i_timeJail), steamID[target]);
		}
		
		if (time_to_spend <= 1) {
			rp_ClientSendToSpawn(target);
		}
		StripWeapons(target);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

void WantPayForLeaving(int client, int police, int type, int amende) 
{	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(eventPayForLeaving);
	char tmp[256];
	Format(tmp, 255, "Vous avez été mis en prison pour \n %s\nUne caution de %i$ vous est demandé\n ", g_szJailRaison[type][jail_raison], amende);
	menu.SetTitle(tmp);
	
	Format(tmp, 255, "%i_%i_%i", police, type, amende);
	menu.AddItem(tmp, "Oui, je souhaite payer ma caution");
	
	Format(tmp, 255, "0_0_0");
	menu.AddItem(tmp, "Non, je veux rester plus longtemps");
	
	menu.ExitButton = true;	
	menu.Display(client, MENU_TIME_FOREVER);
}
public int eventPayForLeaving(Menu menu, MenuAction action, int client, int param2) 
{
	if (action == MenuAction_Select) 
	{
		char options[64], data[3][32];
		
		menu.GetItem(param2, options, 63);
		
		ExplodeString(options, "_", data, 2, 32);
		
		int target = StringToInt(data[0]);
		int type = StringToInt(data[1]);
		int amende = StringToInt(data[2]);
		int jobID = rp_GetClientInt(target, i_Job);
		
		if (target == 0 && type == 0 && amende == 0)
			return;
		
		if(rp_GetClientInt(client, i_Money) >= amende)
		{		
			int time_to_spend = 0;
			rp_SetClientInt(client, i_MoneySpent_Fines, rp_GetClientInt(client, i_MoneySpent_Fines) + amende);
			rp_SetClientInt(client, i_Money, -amende);
			rp_SetClientInt(target, i_Money, (amende / 4));
			rp_SetJobCapital(jobID, rp_GetJobCapital(jobID) + (amende / 4 * 3));
			
			GetClientAuthId(client, AuthId_Engine, STRING(options), false);
				
			time_to_spend = StringToInt(g_szJailRaison[type][jail_temps]);
			if (time_to_spend == -1) {
				time_to_spend = rp_GetClientInt(target, i_KillJailDuration);
				
				time_to_spend /= 2;
			}
			
			rp_ClientTeleport(client, g_flLastPos[client]);
			
			if (IsClientValid(target)) {
				CPrintToChat(target, "%s Une amende de %i$ a été prélevée à %N.", TEAM, amende, client);
				CPrintToChat(client, "%s Une caution de %i$ vous a été prelevée.", TEAM, amende);
			}
			
			time_to_spend *= 60;
			rp_SetClientInt(client, i_timeJail, time_to_spend);
			rp_SetClientInt(client, i_timeJail_Last, time_to_spend);
		}	
	}
	else if (action == MenuAction_End) 
	{
		delete menu;
	}
}

public Action RP_OnPlayerMetier(int client, Menu menu)
{
	if (rp_GetClientInt(client, i_Job) == 1)
	{
		menu.AddItem("infoprison", "Information des détenus");
		menu.AddItem("avisrecherche", "Avis de recherche");
		if (rp_GetClientInt(client, i_Grade) <= 5)
			menu.AddItem("perqui", "Mandat de perquisition");
		if (rp_GetClientBool(client, b_asMandat))
			menu.AddItem("finperqui", "Terminer la pequisition");
		if (rp_GetClientInt(client, i_Grade) <= 3)
			menu.AddItem("enquete", "Ouvrir un dossier");
		if (rp_GetClientInt(client, i_Grade) <= 2)
			menu.AddItem("police", "Gérer la police");
	}
}	

public int RP_OnPlayerMetierHandle(int client, const char[] info)
{
	if (StrEqual(info, "police"))
		MenuParamPolice(client);
	else if (StrEqual(info, "enquete"))
		MenuEnquete(client);
	else if (StrEqual(info, "avisrecherche"))
		MenuAvisRecherche(client);
	else if (StrEqual(info, "infoprison"))
		MenuInfoPrison(client);
	else if (StrEqual(info, "perqui"))
		MenuPerquisition(client);
	else if (StrEqual(info, "finperqui"))
	{
		rp_SetJobPerqui(0);
		rp_SetClientBool(client, b_asMandat, false);
		CPrintToChat(client, "%s La perquisition est \x06terminée\x01.", TEAM);
		LoopClients(i)
		{
			if (i != client && rp_GetClientInt(i, i_Job) == 1)
			{
				CPrintToChat(i, "%s Perquisition \x06terminée\x01 !", TEAM);
				PrintCenterText(i, "Perquisition terminée !!");
			}
			else if (rp_GetClientInt(i, i_Job) == rp_GetJobPerqui())
				CPrintToChat(i, "%s La perquisition de votre planque est terminée.", TEAM);
		}
	}	
}	

Menu MenuParamPolice(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuParamPolice);
	menu.SetTitle("Gérer la police :");
	
	char strFormat[64], strTime[32];
	StringTime(GetParamPolice(false, "meurtre"), STRING(strTime));
	Format(STRING(strFormat), "Meurtre : %i$ - %s", GetParamPolice(true, "meurtre"), strTime);
	menu.AddItem("meurtre", strFormat);
	StringTime(GetParamPolice(false, "agression"), STRING(strTime));
	Format(STRING(strFormat), "Agression : %i$ - %s", GetParamPolice(true, "agression"), strTime);
	menu.AddItem("agression", strFormat);
	StringTime(GetParamPolice(false, "vol"), STRING(strTime));
	Format(STRING(strFormat), "Vol : %i$ - %s", GetParamPolice(true, "vol"), strTime);
	menu.AddItem("vol", strFormat);
	StringTime(GetParamPolice(false, "intrusion"), STRING(strTime));
	Format(STRING(strFormat), "Intrusion : %i$ - %s", GetParamPolice(true, "intrusion"), strTime);
	menu.AddItem("intrusion", strFormat);
	StringTime(GetParamPolice(false, "refus"), STRING(strTime));
	Format(STRING(strFormat), "Refus d'optempérer : %i$ - %s", GetParamPolice(true, "refus"), strTime);
	menu.AddItem("refus", strFormat);
	StringTime(GetParamPolice(false, "permis"), STRING(strTime));
	Format(STRING(strFormat), "Défaut de permis : %i$ - %s", GetParamPolice(true, "permis"), strTime);
	menu.AddItem("permis", strFormat);
	StringTime(GetParamPolice(false, "stupefiant"), STRING(strTime));
	Format(STRING(strFormat), "Vente de stupéfiant : %i$ - %s", GetParamPolice(true, "stupefiant"), strTime);
	menu.AddItem("stupefiant", strFormat);
	StringTime(GetParamPolice(false, "arme"), STRING(strTime));
	Format(STRING(strFormat), "Possession d'arme illégal : %i$ - %s", GetParamPolice(true, "arme"), strTime);
	menu.AddItem("arme", strFormat);
	StringTime(GetParamPolice(false, "argent"), STRING(strTime));
	Format(STRING(strFormat), "Blanchiment d'argent : %i$ - %s", GetParamPolice(true, "argent"), strTime);
	menu.AddItem("argent", strFormat);
	StringTime(GetParamPolice(false, "sonore"), STRING(strTime));
	Format(STRING(strFormat), "Nuissance sonore : %i$ - %s", GetParamPolice(true, "sonore"), strTime);
	menu.AddItem("sonore", strFormat);
	StringTime(GetParamPolice(false, "outrage"), STRING(strTime));
	Format(STRING(strFormat), "Outrage à agent : %i$ - %s", GetParamPolice(true, "outrage"), strTime);
	menu.AddItem("outrage", strFormat);
	StringTime(GetParamPolice(false, "arnaque"), STRING(strTime));
	Format(STRING(strFormat), "Arnaque : %i$ - %s", GetParamPolice(true, "arnaque"), strTime);
	menu.AddItem("arnaque", strFormat);
	StringTime(GetParamPolice(false, "recele"), STRING(strTime));
	Format(STRING(strFormat), "Recèle : %i$ - %s", GetParamPolice(true, "recele"), strTime);
	menu.AddItem("recele", strFormat);
	StringTime(GetParamPolice(false, "evasion"), STRING(strTime));
	Format(STRING(strFormat), "Évasion : %i$ - %s", GetParamPolice(true, "evasion"), strTime);
	menu.AddItem("evasion", strFormat);
	StringTime(GetParamPolice(false, "gav"), STRING(strTime));
	Format(STRING(strFormat), "G.A.V. : %i$ - %s", GetParamPolice(true, "gav"), strTime);
	menu.AddItem("gav", strFormat);
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuParamPolice(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu1 = new Menu(DoMenuSelectParamPolice);
		
		char strFormat[64];
		if (StrEqual(info, "meurtre"))
			Format(STRING(strFormat), "Meurtre");
		else if (StrEqual(info, "agression"))
			Format(STRING(strFormat), "Agression");
		else if (StrEqual(info, "vol"))
			Format(STRING(strFormat), "Vol");
		else if (StrEqual(info, "intrusion"))
			Format(STRING(strFormat), "Intrusion");
		else if (StrEqual(info, "refus"))
			Format(STRING(strFormat), "Refus d'optempérer");
		else if (StrEqual(info, "permis"))
			Format(STRING(strFormat), "Défaut de permis");
		else if (StrEqual(info, "stupefiant"))
			Format(STRING(strFormat), "Vente de stupéfiant");
		else if (StrEqual(info, "arme"))
			Format(STRING(strFormat), "Vente d'arme illégal");
		else if (StrEqual(info, "argent"))
			Format(STRING(strFormat), "Blanchiement d'argent");
		else if (StrEqual(info, "sonore"))
			Format(STRING(strFormat), "Nuissance sonore");
		else if (StrEqual(info, "arnaque"))
			Format(STRING(strFormat), "Arnaque");
		else if (StrEqual(info, "recele"))
			Format(STRING(strFormat), "Recèle");
		else if (StrEqual(info, "evasion"))
			Format(STRING(strFormat), "Évasion");
		else if (StrEqual(info, "gav"))
			Format(STRING(strFormat), "G.A.V.");
		menu1.SetTitle("%s :", strFormat);
		
		int amende = GetParamPolice(true, info);
		int temps = GetParamPolice(false, info);
		if (amende == 0)
		{
			Format(STRING(strFormat), "%s|activeramende", info);
			menu1.AddItem(strFormat, "Activer l'amende");
		}
		else
		{
			Format(STRING(strFormat), "%s|desactiveramende", info);
			menu1.AddItem(strFormat, "Désactiver l'amende");
		}
		if (amende != 0)
		{
			Format(STRING(strFormat), "%s|changeramende", info);
			menu1.AddItem(strFormat, "Changer le montant de l'amende");
		}
		if (temps == 0)
		{
			Format(STRING(strFormat), "%s|activertemps", info);
			menu1.AddItem(strFormat, "Activer temps de détention");
		}
		else
		{
			Format(STRING(strFormat), "%s|desactivertemps", info);
			menu1.AddItem(strFormat, "Désactiver le temps de détention");
		}
		if (temps != 0)
		{
			Format(STRING(strFormat), "%s|changertemps", info);
			menu1.AddItem(strFormat, "Changer le temps de détention");
		}
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		//else if (param == MenuCancel_ExitBack)
			//MenuGererMetier(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuSelectParamPolice(Menu menu1, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32], buffer[2][32];
		menu1.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 32);
		// buffer[0] : motif
		// buffer[1] : choix
		
		if (StrEqual(buffer[1], "activeramende"))
		{
			SetParamPolice(true, buffer[0], 600);
			PrintHintText(client, "Amende activé.");
			LogToFile(logFile, "%N a activé l'amende %s.", client, buffer[0]);
			MenuParamPolice(client);
		}
		else if (StrEqual(buffer[1], "desactiveramende"))
		{
			SetParamPolice(true, buffer[0], 0);
			PrintHintText(client, "Amende désactivé.");
			LogToFile(logFile, "%N a désactivé l'amende %s.", client, buffer[0]);
			MenuParamPolice(client);
		}
		else if (StrEqual(buffer[1], "activertemps"))
		{
			SetParamPolice(false, buffer[0], 360);
			PrintHintText(client, "Temps de détention activé.");
			LogToFile(logFile, "%N a activé le temps de détention %s.", client, buffer[0]);
			MenuParamPolice(client);
		}
		else if (StrEqual(buffer[1], "desactivertemps"))
		{
			SetParamPolice(false, buffer[0], 0);
			PrintHintText(client, "Temps de détention désactivé.");
			LogToFile(logFile, "%N a désactivé le temps de détention %s.", client, buffer[0]);
			MenuParamPolice(client);
		}
		else if (StrEqual(buffer[1], "changeramende"))
			MenuModifierParamPolice(client, true, buffer[0]);
		else if (StrEqual(buffer[1], "changertemps"))
			MenuModifierParamPolice(client, false, buffer[0]);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			MenuParamPolice(client);
	}
	else if (action == MenuAction_End)
		delete menu1;
}

Menu MenuEnquete(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuEnquete);
	menu.SetTitle("Quel dossier voulez-vous ?");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			char name[32], strI[8];
			IntToString(i, STRING(strI));
			GetClientName(i, STRING(name));
			
			if (rp_GetClientInt(i, i_Job) == 2 && rp_GetClientInt(i, i_Grade) == 1)
				menu.AddItem("", name, ITEMDRAW_DISABLED);
			else 
				menu.AddItem(strI, name);
		}
	}
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuEnquete(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], strFormat[64];
		menu.GetItem(param, STRING(info));
		int id = StringToInt(info);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu1 = new Menu(DoMenuEnqueteFinal);
		menu1.SetTitle("Dossier de %N :", id);
		
		Format(STRING(strFormat), "Karma : %f", rp_GetClientFloat(id, fl_Vitality));
		menu1.AddItem("", strFormat, ITEMDRAW_DISABLED);
		
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		//else if (param == MenuCancel_ExitBack)
			//MenuGererMetier(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuEnqueteFinal(Menu menu1, MenuAction action, int client, int param)
{
	if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			MenuEnquete(client);
	}
	else if (action == MenuAction_End)
		delete menu1;
}

Menu MenuAvisRecherche(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuRecherche);
	menu.SetTitle("Avis de recherche :");
	if (rp_GetClientInt(client, i_Job) == 1 && rp_GetClientInt(client, i_Grade) <= 5 || rp_GetClientInt(client, i_Job) == 7)
		menu.AddItem("avis", "Lancer un avis de recherche");
	menu.AddItem("afficher", "Liste des suspects recherchés");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuRecherche(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if (StrEqual(info, "avis"))
		{
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menu1 = new Menu(DoMenuAvisRecherche);
			menu1.SetTitle("Quel suspect est recherché ?");
			
			bool count;
			char strInfo[16], strMenu[64], jobName[32];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientValid(i) && IsValidEntity(i))
				{
					count = true;
					GetJobName(rp_GetClientInt(i, i_Job), STRING(jobName));
					Format(STRING(strMenu), "%N (%s)", i, jobName);
					Format(STRING(strInfo), "%i", i);
					menu1.AddItem(strInfo, strMenu);
				}
			}
			if (!count)
				menu1.AddItem("", "Aucun suspect.", ITEMDRAW_DISABLED);
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(client, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "afficher"))
		{
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menu2 = new Menu(DoMenuAfficherRecherche);
			menu2.SetTitle("Liste des suspects recherchés :");
			
			int count;
			char strInfo[16], strMenu[64], jobName[24];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientValid(i) && IsValidEntity(i))
				{
					if (rp_GetClientBool(i, b_IsSearchByTribunal))
					{
						count++;
						Format(STRING(strMenu), "%N (%s)", i, jobName);
						Format(STRING(strInfo), "%i", i);
						if (rp_GetClientInt(client, i_Grade) <= 5)
							menu2.AddItem(strInfo, strMenu);
						else
							menu2.AddItem("", strMenu, ITEMDRAW_DISABLED);
					}
				}
			}
			if (count == 0)
				menu2.AddItem("", "Aucun avis de recherche.", ITEMDRAW_DISABLED);
			
			menu2.ExitBackButton = true;
			menu2.ExitButton = true;
			menu2.Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		//else if (param == MenuCancel_ExitBack)
		//	MenuGererMetier(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuAvisRecherche(Menu menu1, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu1.GetItem(param, STRING(info));
		
		int cible = StringToInt(info);
		if (IsClientValid(cible) && IsValidEntity(cible))
		{
			char jobName[32];
			GetJobName(rp_GetClientInt(cible, i_Job), STRING(jobName));
			
			rp_SetClientBool(cible, b_IsSearchByTribunal, true);
			CreateTimer(360.0, UnAvisRecherche, client);
			
			if (rp_GetClientInt(client, i_ByteZone) == 777)
				TeleportToBytzone(client, 777);
			
			CPrintToChat(client, "%s Vous avez lancé un avis de recherche sur \x02%N\x01.", TEAM, cible);
			CPrintToChat(cible, "%s Vous êtes recherché par le \x02service de Police\x01, cachez-vous !", TEAM);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientValid(i) && i != client)
				{
					if (rp_GetClientInt(i, i_Job) == 1)
						CPrintToChat(i, "%s A toutes les unités, le suspect \x02%N \x01(%s) est recherché par {orange}%N\x01.", TEAM, cible, jobName, client);
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		//else if (param == MenuCancel_ExitBack)
			//MenuGererMetier(client);
	}
	else if (action == MenuAction_End)
		delete menu1;
}

public Action UnAvisRecherche(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		if(rp_GetClientBool(client, b_IsSearchByTribunal))
		{
			rp_SetClientBool(client, b_IsSearchByTribunal, false);
			LogToFile(logFile, "Le joueur {yellow}%N {default}n'est plus recherché par la police.", client);
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientValid(i))
				{
					if(rp_GetClientInt(i, i_Job) == 1)
					{
						PrintCenterText(i, "<font color='#a35a00'>Suspect en fuite</font> <font color='#ff0000'>!</font>");
						CPrintToChat(i, "%s Le suspect {red}%N {default} s'est enfui, l'avis de recherche est {yellow}annulé{default}.", TEAM, client);
					}
				}
			}
		}
	}
}

public int DoMenuAfficherRecherche(Menu menu2, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu2.GetItem(param, STRING(info));
		
		int cible = StringToInt(info);
		if (IsClientValid(cible) && IsValidEntity(cible))
		{
			if (rp_GetClientBool(cible, b_IsSearchByTribunal))
			{
				char jobName[32], strMenu[32];
				GetJobName(rp_GetClientInt(cible, i_Job), STRING(jobName));
				
				rp_SetClientBool(client, b_menuOpen, true);
				Menu menu5 = new Menu(DoMenuModifierRecherche);
				
				menu5.SetTitle("Modifier l'avis de recherche de %N (%s) :", cible, jobName);
				Format(STRING(strMenu), "trouver|%i", cible);
				if (rp_GetClientInt(client, i_Job) == 1)
					menu5.AddItem(strMenu, "Le suspect a été arrêté.");
				else 
					menu5.AddItem(strMenu, "Le suspect a été trouvé.");
				Format(STRING(strMenu), "annuler|%i", cible);
				menu5.AddItem(strMenu, "Annuler l'avis de recherche.");
				menu5.ExitButton = true;
				menu5.Display(client, MENU_TIME_FOREVER);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			MenuAvisRecherche(client);
	}
	else if (action == MenuAction_End)
		delete menu2;
}

public int DoMenuModifierRecherche(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32], buffer[2][16];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 16);
		// buffer[0] : info
		int cible = StringToInt(buffer[1]);
		
		if (IsValidEntity(cible))
		{
			if (StrEqual(buffer[0], "trouver"))
			{
				rp_SetClientBool(cible, b_IsSearchByTribunal, false);			
				LogToFile(logFile, "Le joueur %N a trouver le suspect %N (avis de recherche).", client, cible);
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientValid(i) && i != client)
					{
						char zone[64];
						rp_GetClientString(client, sz_Zone, STRING(zone));
						
						if (rp_GetClientInt(i, i_Job) == 1)
							CPrintToChat(client, "%s Le suspect \x02%N \x01 a été trouvé par {orange}%N \x01 (%s), l'avis de recherche est suspendu.", TEAM, cible, client, zone);
					}
				}
			}
			else if (StrEqual(buffer[0], "annuler"))
			{
				rp_SetClientBool(cible, b_IsSearchByTribunal, false);
				LogToFile(logFile, "Le joueur %N a trouver le suspect %N (avis de recherche).", client, cible);
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientValid(i) && i != client)
					{
						if (rp_GetClientInt(i, i_Job) == 1)
						{
							CPrintToChat(client, "%s L'avis de recherche de %N est annulé.", TEAM, cible);
							PrintHintText(client, "L'avis de recherche de %N est annulé.", cible);
						}
					}
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

Menu MenuInfoPrison(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuInfoPrison);
	menu.SetTitle("Liste des détenus :");
	
	char strFormat[64], strMenu[128];
	bool count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			if (rp_GetClientInt(i, i_timeJail) > 0)
			{
				char casier[1024];
				rp_GetClientString(i, sz_Casier, STRING(casier));
				
				if (!StrEqual(casier, "none"))
				{
					char buffer[128][128];
					int len = ExplodeString(casier, "|", buffer, strlen(casier[i]), 128);
					
					char raison[64], buffer2[7][64];
					ExplodeString(buffer[len - 1], "*", buffer2, 7, 64);
					// buffer2[1] : motif
					// buffer2[2] : detail
					// buffer2[5] : steamid policier
					// buffer2[6] : pseudo policier
					
					if (StrContains(buffer2[2], "recidive", false) != -1)
						Format(STRING(raison), "meurtre avec récidive");
					else if (StrEqual(buffer2[1], "refus"))
						Format(STRING(raison), "refus d'optempérer");
					else if (StrEqual(buffer2[1], "permis"))
						Format(STRING(raison), "défaut de permis");
					else if (StrEqual(buffer2[1], "stupefiant"))
						Format(STRING(raison), "vente de stupéfiant");
					else if (StrEqual(buffer2[1], "arme"))
						Format(STRING(raison), "possession d'arme illégal");
					else if (StrEqual(buffer2[1], "argent"))
						Format(STRING(raison), "blanchiement d'argent");
					else if (StrEqual(buffer2[1], "sonore"))
						Format(STRING(raison), "nuissance sonore");
					else if (StrEqual(buffer2[1], "outrage"))
						Format(STRING(raison), "outrage à agent");
					else if (StrEqual(buffer2[1], "recele"))
						Format(STRING(raison), "recèle");
					else if (StrEqual(buffer2[1], "evasion"))
						Format(STRING(raison), "évasion");
					else if (StrEqual(buffer2[1], "gav"))
						Format(STRING(raison), "G.A.V.");
					else
						Format(STRING(raison), "%s", buffer2[1]);
					
					Format(STRING(strFormat), "%i|%s|%s", i, raison, buffer2[6]);
								
					char monthname[12];
					GetMonthName(rp_GetTime(i_month), STRING(monthname));		

					char strTime[128];
					StringTime(rp_GetClientInt(i, i_timeJail), STRING(strTime));
					
					Format(STRING(strMenu), "%N (%s) [%s]", i, raison, strTime);
					if (rp_GetClientInt(client, i_Grade) <= 3 || StrEqual(buffer[5], steamID[client]))
						menu.AddItem(strFormat, strMenu);
					else
						menu.AddItem("", strMenu, ITEMDRAW_DISABLED);
					count = true;
				}
			}
		}
	}
	if (!count)
		menu.AddItem("", "Aucun détenu.", ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuInfoPrison(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], buffer[3][32], strFormat[64], strTime[32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 3, 32);
		int detenu = StringToInt(buffer[0]);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu1 = new Menu(DoMenuDetailPrison);
		
		StringTime(rp_GetClientInt(detenu, i_timeJail), STRING(strTime));
		
		menu1.SetTitle("%N (%s) [%s]", detenu, buffer[1], strTime);
		Format(STRING(strFormat), "Mis en prison par : %s", buffer[2]);
		menu1.AddItem("", strFormat, ITEMDRAW_DISABLED);
		Format(STRING(strFormat), "liberer|%i|%s|%s", detenu, buffer[1], buffer[2]);
		menu1.AddItem(strFormat, "Libérer le déténu");
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		//else if (param == MenuCancel_ExitBack)
			//MenuGererMetier(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuDetailPrison(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], buffer[4][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 4, 32);	
		int detenu = StringToInt(buffer[1]);
		
		if (StrEqual(buffer[0], "liberer"))
		{
			rp_SetClientInt(detenu, i_timeJail, 0);
			rp_SetClientBool(detenu, b_canJail, true);
			
			if (IsClientValid(detenu))
			{
				SetClientListeningFlags(detenu, VOICE_NORMAL);
				//TeleportSortieJail(detenu);
				
				if (client != detenu)
				{
					CPrintToChat(detenu, "%s Vous avez été libéré de détention par %N.", TEAM, client);
					CPrintToChat(client, "%s Vous avez libéré de détention %N.", TEAM, detenu);
				}
				else
					CPrintToChat(detenu, "%s Vous vous êtes libéré de détention.", TEAM);
				LogToFile(logFile, "%N a libere %N.", client, detenu);
			}
		}
		rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			MenuInfoPrison(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

Menu MenuPerquisition(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuPerquisition);
	menu.SetTitle("Demander un mandat de perquisition :");
	
	char strIndex[32], jobname[64];
	for (int i = 2; i <= MAXJOBS; i++)
	{
		Format(STRING(strIndex), "%i", i);
		GetJobName(i, STRING(jobname));
		
		if (rp_CanPerquisition(i))
			menu.AddItem(strIndex, jobname);
		else 
			menu.AddItem("", jobname, ITEMDRAW_DISABLED);	
	}		
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuPerquisition(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], jobName[32];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu1 = new Menu(DoMenuAttente);
		if (StrEqual(info, "1"))
			jobName = "appartement";
		else
			GetJobName(StringToInt(info), STRING(jobName));
		menu1.SetTitle("Demande d'un mandat pour %s :", jobName);
		menu1.AddItem(info, "Le procureur étudie votre demande ...", ITEMDRAW_DISABLED);
		menu1.ExitButton = false;
		menu1.Display(client, MENU_TIME_FOREVER);
		
		DataPack pack = new DataPack();
		CreateDataTimer(GetRandomFloat(4.0, 10.0), CheckCanPerqui, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(client);
		pack.WriteString(info);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuAttente(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Cancel && param == MenuCancel_Exit)
	{
		rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action CheckCanPerqui(Handle timer, DataPack pack)
{
	char strFormat[8];
	pack.Reset();
	int client = pack.ReadCell();
	pack.ReadString(STRING(strFormat));
	int perqui = StringToInt(strFormat);
	
	if(!IsClientValid(client))
		return Plugin_Stop;
	
	rp_SetClientBool(client, b_menuOpen, false);
	
	if(!rp_CanPerquisition(perqui))
	{
		CPrintToChat(client, "%s Le procureur a {red}refusé{default} votre demande de perquisition.", TEAM);
		return Plugin_Stop;
	}
	else if(rp_GetJobPerqui() != 0)
	{
		CPrintToChat(client, "%s Le procureur a {red}refusé{default} votre demande de perquisition. Une perquistion à eu lieu récemment.", TEAM);
		return Plugin_Stop;
	}
	else if(rp_GetTime(i_hour2) < 6 && rp_GetTime(i_hour1) > 20)
	{
		CPrintToChat(client, "%s Le procureur a {red}refusé{default} votre demande de perquisition. L'heure réglementaire minimum est de 6h00 du matin à 20h00.", TEAM);
		return Plugin_Stop;
	}
	
	int count;
	LoopClients(i)
	{
		if(IsClientValid(i) && rp_GetClientInt(i, i_Job) == 1 && !rp_GetClientBool(i, b_isAfk))
			count++;
	}
	if(rp_GetClientInt(client, i_Grade) == 5 && count < 2
	|| rp_GetClientInt(client, i_Grade) == 4 && count < 1)
	{
		CPrintToChat(client, "%s Le procureur a {red}refusé{default} votre demande de perquisition. Il n'y a pas assez d'agent pour encadre une perquistion.", TEAM);
		return Plugin_Stop;
	}
	
	if(perqui == 7)
	{
		count = 0;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i) && rp_GetClientInt(i, i_Job) == 7 && !rp_GetClientBool(i, b_isAfk))
				count++;
		}
		if(count > 0)
		{
			CPrintToChat(client, "%s Le procureur a {red}refusé{default} votre demande de perquisition dans le Palais de Justice.", TEAM);
			return Plugin_Stop;
		}
	}
	
	char strName[32];
	Format(STRING(strName), "mandat|%i|%s", perqui, steamID[client]);	
	SpawnPropByName(client, "mandat", strName);
	
	CPrintToChat(client, "%s Le procureur {green}autorise{default} la perquisition, allez chercher le {yellow}mandat dans son bureau au Palais de Justice{default}.", TEAM);

	return Plugin_Continue;
}

Menu MenuModifierParamPolice(int client, bool type, char[] motif)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuModifierParamPolice);
	int amende = GetParamPolice(true, motif);
	int temps = GetParamPolice(false, motif);
	
	char strFormat[64];
	if (StrEqual(motif, "meurtre"))
		Format(STRING(strFormat), "Meurtre");
	else if (StrEqual(motif, "agression"))
		Format(STRING(strFormat), "Agression");
	else if (StrEqual(motif, "vol"))
		Format(STRING(strFormat), "Vol");
	else if (StrEqual(motif, "intrusion"))
		Format(STRING(strFormat), "Intrusion");
	else if (StrEqual(motif, "refus"))
		Format(STRING(strFormat), "Refus d'optempérer");
	else if (StrEqual(motif, "permis"))
		Format(STRING(strFormat), "Défaut de permis");
	else if (StrEqual(motif, "stupefiant"))
		Format(STRING(strFormat), "Vente de stupéfiant");
	else if (StrEqual(motif, "arme"))
		Format(STRING(strFormat), "Vente d'arme illégal");
	else if (StrEqual(motif, "argent"))
		Format(STRING(strFormat), "Blanchiement d'argent");
	else if (StrEqual(motif, "sonore"))
		Format(STRING(strFormat), "Nuissance sonore");
	else if (StrEqual(motif, "arnaque"))
		Format(STRING(strFormat), "Arnaque");
	else if (StrEqual(motif, "recele"))
		Format(STRING(strFormat), "Recèle");
	else if (StrEqual(motif, "evasion"))
		Format(STRING(strFormat), "Évasion");
	else if (StrEqual(motif, "gav"))
		Format(STRING(strFormat), "G.A.V.");
	
	if (type && amende > 0 || !type && temps > 0)
	{
		if (type)
			menu.SetTitle("%s [%i] :", strFormat, amende);
		else
		{
			char strTime[32];
			StringTime(temps, STRING(strTime));
			menu.SetTitle("%s [%i] :", strFormat, strTime);
		}
	}
	else
		menu.SetTitle("%s [désactivé] :", strFormat);
	
	char strMenu[64];
	if (type)
	{
		Format(STRING(strMenu), "%i|%s|30", type, motif);
		menu.AddItem(strMenu, "Ajouter 30$");
		Format(STRING(strMenu), "%i|%s|10", type, motif);
		menu.AddItem(strMenu, "Ajouter 10$");
		Format(STRING(strMenu), "%i|%s|1", type, motif);
		menu.AddItem(strMenu, "Ajouter 1$");
		if (amende >= 1)
		{
			Format(STRING(strMenu), "%i|%s|-1", type, motif);
			menu.AddItem(strMenu, "Retirer 1$");
		}
		if (amende >= 10)
		{
			Format(STRING(strMenu), "%i|%s|-10", type, motif);
			menu.AddItem(strMenu, "Retirer 10$");
		}
		if (amende >= 30)
		{
			Format(STRING(strMenu), "%i|%s|-30", type, motif);
			menu.AddItem(strMenu, "Retirer 30$");
		}
	}
	else
	{
		Format(STRING(strMenu), "%i|%s|30", type, motif);
		menu.AddItem(strMenu, "Ajouter 30 secondes");
		Format(STRING(strMenu), "%i|%s|10", type, motif);
		menu.AddItem(strMenu, "Ajouter 10 secondes");
		Format(STRING(strMenu), "%i|%s|1", type, motif);
		menu.AddItem(strMenu, "Ajouter 1 seconde");
		if (temps >= 1)
		{
			Format(STRING(strMenu), "%i|%s|-1", type, motif);
			menu.AddItem(strMenu, "Retirer 1 seconde");
		}
		if (temps >= 10)
		{
			Format(STRING(strMenu), "%i|%s|-10", type, motif);
			menu.AddItem(strMenu, "Retirer 10 secondes");
		}
		if (temps >= 30)
		{
			Format(STRING(strMenu), "%i|%s|-30", type, motif);
			menu.AddItem(strMenu, "Retirer 30 secondes");
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuModifierParamPolice(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32], buffer[3][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 3, 32);
		int type = StringToInt(buffer[0]);
		// buffer[1] : motif
		int montant = StringToInt(buffer[2]);
		if (type == 0)
		{
			montant += GetParamPolice(false, buffer[1]);
			SetParamPolice(false, buffer[1], montant);
			MenuModifierParamPolice(client, false, buffer[1]);
		}
		else
		{
			montant += GetParamPolice(true, buffer[1]);
			SetParamPolice(true, buffer[1], montant);
			MenuModifierParamPolice(client, true, buffer[1]);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			MenuParamPolice(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}