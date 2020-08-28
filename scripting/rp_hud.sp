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
#pragma tabsize 0
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N C L U D E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <unixtime_sourcemod>
#include <roleplay>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  D E F I N E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#define HIDE_RADAR_CSGO 1<<12

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
Player joueur;

Handle g_hTimerHUD[MAXPLAYERS+1] = { null, ... };

Database g_DB;
char dbconfig[] = "roleplay";

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Hud", 
	author = "Benito", 
	description = "Système d'hud pour les joueurs", 
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
		RegConsoleCmd("menu", Cmd_Menu);	
		RegConsoleCmd("redrawhudforparticipant", Cmd_RedrawHud);
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();	
}

public void OnClientPostAdminCheck(int client)
{
    joueur = Player(client);
} 

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("DatabaseError", error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
	}	
}

public void rp_OnClientSpawn(int client)
{
	if(IsClientValid(client))
		CreateTimer(1.0, setHudOptions, client);
}	

public Action setHudOptions(Handle Timer, int client) {
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
}

public void OnClientPutInServer(int client) {	
	g_hTimerHUD[client] = CreateTimer(1.0, updateHUD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

public void rp_OnClientDisconnect(int client) {
	rp_SetClientBool(client, b_menuOpen, false);
	TrashTimer(g_hTimerHUD[client], true);
}

public Action Cmd_Menu(int client, int args)
{	
	if (client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	
	if(rp_GetEventType() != event_type_none)
	{
		CPrintToChat(client, "%s Impossible pendant un event.", TEAM);
	}
	else
	{	
		if (rp_GetClientBool(client, b_menuOpen))
		{
			rp_SetClientBool(client, b_menuOpen, false);
			CPrintToChat(client, "%s Votre hud a été réaffiché.", TEAM);
		}
		else
		{
			rp_SetClientBool(client, b_menuOpen, true);
			CPrintToChat(client, "%s Votre hud a été caché.", TEAM);
		}
	}	
	
	return Plugin_Handled;
}

public Action Cmd_RedrawHud(int client, int args)
{	
	if (client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	
	if(IsClientValid(client))
	{
		rp_SetClientBool(client, b_menuOpen, false);
		g_hTimerHUD[client] = CreateTimer(1.0, updateHUD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);		
	}
	
	return Plugin_Handled;
}

public void OnMapStart() 
{
	CreateTimer(1.0, updatePrintText, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action updatePrintText(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) {
		if (IsClientValid(client))	
			showAllHudMessages(client);
	}
}

public Action updateHUD(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) 
	{		
		if (IsClientValid(client))
		{			
			if(!rp_GetClientBool(client, b_isEventParticipant))
			{
				if (!rp_GetClientBool(client, b_menuOpen) && !rp_GetClientBool(client, b_isAfk))
				{					
					if(GetVehicle(client) == -1)
					{
						char name[64], grade[64], groupename[64];	
						
						GetJobName(rp_GetClientInt(client, i_Job), name);
						GetGradeName(rp_GetClientInt(client, i_Grade), rp_GetClientInt(client, i_Job), grade);
						
						int aim = GetAimEnt(client, true);
						if(IsValidEntity(aim))
						{
							char HudTarget[128];
							
							if(IsClientValid(aim))
							{
								Player target = Player(aim);
								
								char jobName_Target[64];
								GetJobName(target.jobID, jobName_Target);
							    
							    char gradeName_Target[64];
							    GetGradeName(target.gradeID, target.jobID, gradeName_Target);
								
								char strName[32], groupename_T[64];
								target.GetName(STRING(strName));
								GetGroupeName(g_DB, aim, STRING(groupename_T));
								
								if (target.jobID == 0)
								{
									if(rp_GetClientInt(aim, i_Group) == 0)
										Format(STRING(HudTarget), "%s (%iHP)\nMétier: Chômeur\nGang: Aucun", strName, target.Health);
									else
										Format(STRING(HudTarget), "%s (%iHP)\nMétier: Chômeur\nGang: %s", strName, target.Health, groupename_T);		
								}	
								else
								{
									if (rp_GetClientInt(aim, i_Job) == 1)
									{
										if(GetClientTeam(aim) == CS_TEAM_T)
										{
											if(rp_GetClientInt(aim, i_Group) == 0)
												Format(STRING(HudTarget), "%s (%iHP)\nMétier: Chômeur\nGang: Aucun", strName, target.Health);
											else	
												Format(STRING(HudTarget), "%s (%iHP)\nMétier: Chômeur\nGang: %s", strName, target.Health, groupename_T);		
										}
										else if(GetClientTeam(aim) == CS_TEAM_CT)
										{
											if(rp_GetClientInt(aim, i_Group) == 0)
												Format(STRING(HudTarget), "%s (%iHP)\nMétier: %s (%s)\nGang: Aucun", strName, target.Health, jobName_Target, gradeName_Target);
											else	
												Format(STRING(HudTarget), "%s (%iHP)\nMétier: %s (%s\nGang: %s", strName, target.Health, jobName_Target, gradeName_Target, groupename_T);	
										}
									}
									else 
									{
										if(rp_GetClientInt(aim, i_Group) == 0)
											Format(STRING(HudTarget), "%s (%iHP)\nMétier: %s (%s)\nGang: Aucun", strName, target.Health, jobName_Target, gradeName_Target);
										else	
											Format(STRING(HudTarget), "%s (%iHP)\nMétier: %s (%s\nGang: %s", strName, target.Health, jobName_Target, gradeName_Target, groupename_T);	
									}			
								}
								PrintHintText(client, HudTarget);
							}	
							
							char entName[64], entClass[64];
							Entity_GetName(aim, STRING(entName));
							Entity_GetClassName(aim, STRING(entClass));
							
							if(StrEqual(entClass, "prop_vehicle_driveable"))
							{
								char carinfo[4][32], brand[64];
								ExplodeString(entName, "|", carinfo, 4, 32);
								int owner = Client_FindBySteamId(carinfo[1]);
								GetVehicleInfo(aim, brand);
								
								if(IsClientValid(owner))
									PrintHintText(client, "Propriétaire: %N\n%s", owner, brand);
							}	
						}	
						
						Panel panel = new Panel();
						char strText[128];
							
						
						Format(STRING(strText), "VR Hosting - Roleplay (%s Magic)", VERSION);			
						panel.SetTitle(strText);			
						panel.DrawText("─────────────────────────");
						
						int iYear, iMonth, iDay, iHour, iMinute, iSecond;
					    
						UnixToTime(GetTime(), iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_CEST);
						
						Format(STRING(strText), "- Argent  : %i$", joueur.money);
						panel.DrawText(strText);
						
						Format(STRING(strText), "- Banque : %i$", joueur.bank);
						panel.DrawText(strText);
						
						panel.DrawText("                                  ");
						if (rp_GetClientInt(client, i_Job) == 0)
						{
							Format(STRING(strText), "- Job : Sans Emploi");
							panel.DrawText(strText);
						}	
						else 
						{
							Format(STRING(strText), "- Job   : %s (%s)", grade, name);
							panel.DrawText(strText);
						}
						
						if(rp_GetClientInt(client, i_Job) != 0)
							Format(STRING(strText), "- Salaire  : %i$", rp_GetClientInt(client, i_Salaire));
						else
							Format(STRING(strText), "- Allocation : %i$", rp_GetClientInt(client, i_Salaire));					
						panel.DrawText(strText);
									
						if(rp_GetClientInt(client, i_Grade) == 1)
						{
							Format(STRING(strText), "- Capital : %i$", rp_GetJobCapital(rp_GetClientInt(client, i_Job)));
							panel.DrawText(strText);
						}
						
						panel.DrawText("                                  ");
						if(rp_GetClientInt(client, i_Group) != 0)
						{
							GetGroupeName(g_DB, client, STRING(groupename));
							Format(STRING(strText), "- Gang  : %s", groupename);
							panel.DrawText(strText);
						}
		
						char zonename[128];
						rp_GetZoneName(client);
						rp_GetClientString(client, sz_Zone, STRING(zonename));
						
						Format(STRING(strText), "- Zone : %s", zonename);								
						panel.DrawText(strText);	
						
						Format(STRING(strText), "- Temps  : %02d/%02d/%d %02d:%02d:%02d" , iDay, iMonth, iYear, iHour, iMinute, iSecond);
						panel.DrawText(strText);	
						panel.DrawText("─────────────────────────");
						panel.Send(client, Handler_NullCancel, 1);
					}	
					else
					{
						int voiture = GetVehicle(client);
						int vitesse = GetEntProp(voiture, Prop_Data, "m_nSpeed");
						
						char brand[64], specs[64], horsepower[64], newton[64];
						GetVehicleInfo(voiture, brand, specs, horsepower, newton);
						
						Panel panel = new Panel();
						char strText[128];
									
						panel.SetTitle(brand);
						Format(STRING(strText), "────────────%iKM/H───────────", vitesse);
						panel.DrawText(strText);
						
						Format(STRING(strText), "- Specs : %s", specs);								
						panel.DrawText(strText);	
						
						Format(STRING(strText), "- Chevaux : %s", horsepower);								
						panel.DrawText(strText);	
						
						Format(STRING(strText), "- Couple : %s", newton);								
						panel.DrawText(strText);	
						
						if(rp_GetVehicleInt(voiture, car_fueltype) == 1) 
							Format(STRING(strText), "- Carburant : Essence(%iL)", rp_GetVehicleInt(voiture, car_fuel));
						else
							Format(STRING(strText), "- Carburant : Diesel(%iL)", rp_GetVehicleInt(voiture, car_fuel));						
						panel.DrawText(strText);

						Format(STRING(strText), "- KM's : %i", rp_GetVehicleInt(voiture, car_km));						
						panel.DrawText(strText);
						
						panel.DrawText("─────────────────────────");
						
						panel.Send(client, Handler_NullCancel, 1);
					}	
				}
			}
			else
				TrashTimer(g_hTimerHUD[client], true);			
		}	
		else if (!IsClientValid(client))
			TrashTimer(g_hTimerHUD[client], true);
	}
}

void showAllHudMessages(int client) {
	showHudMsg(client, "Roleplay CS:GO\nBy VR-Hosting.fr", 0, 188, 212, 0.01, 0.01, 1.05);
}

public void showHudMsg(int client, char[] message, int r, int g, int b, float x, float y, float timeout) {
	SetHudTextParams(x, y, timeout, r, g, b, 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, -1, message);
}

public bool isValidRef(int ref) {
	int index = EntRefToEntIndex(ref);
	if (index > MaxClients && IsValidEntity(index)) {
		return true;
	}
	return false;
}

stock int getClientViewClient(int client) {
	float m_vecOrigin[3];
	float m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	int pEntity = -1;
	if (TR_DidHit(tr)) {
		pEntity = TR_GetEntityIndex(tr);
		delete tr;
		if (!IsClientValid(client))
			return -1;
		if (!IsValidEntity(pEntity))
			return -1;
		if (!IsClientValid(pEntity))
			return -1;
		float playerPos[3];
		float entPos[3];
		GetClientAbsOrigin(client, playerPos);
		GetEntPropVector(pEntity, Prop_Data, "m_vecOrigin", entPos);
		if (GetVectorDistance(playerPos, entPos) > 500.0)
			return -1;
		return pEntity;
	}
	delete tr;
	return -1;
}