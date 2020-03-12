#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <roleplay>
#include <cstrike>
#include <multicolors>
#include <unixtime_sourcemod>
#include <devzones>

#pragma newdecls required

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"
#define HIDE_RADAR_CSGO 1<<12

Handle timerAFK[MAXPLAYERS + 1] = { null, ... };
Handle g_hTimerHUD[MAXPLAYERS+1] = { null, ... };

Database g_DB;
char dbconfig[] = "roleplay";

public Plugin myinfo = 
{
	name = "[Roleplay] Hud", 
	author = "Benito", 
	description = "Système d'hud pour les joueurs", 
	version = "1.0", 
	url = "www.revolution-asso.eu"
};
 
public void OnPluginStart() 
{	
	if(rp_licensing_isValid())
	{
		RegConsoleCmd("menu", Cmd_Menu);	
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();	
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
	CreateTimer(1.0, setHudOptions, client);
}	

public Action setHudOptions(Handle Timer, int client) {
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
}

public void OnClientPutInServer(int client) {	
	g_hTimerHUD[client] = CreateTimer(1.0, updateHUD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
	rp_SetClientBool(client, b_isAfk, false);
}

public void OnClientDisconnect(int client) {
	rp_SetClientBool(client, b_isAfk, false);
	rp_SetClientBool(client, b_menuOpen, false);
	TrashTimer(timerAFK[client], true);
}	

public Action OnClientCommand(int client) {
	ResetAFK(client);
	
	return Plugin_Continue;
}

public void OnClientSettingsChanged(int client) {
	ResetAFK(client);
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
	
	if (!rp_GetClientBool(client, b_menuOpen))
	{
		rp_SetClientBool(client, b_menuOpen, true);
		CPrintToChat(client, "%s Votre hud a été réaffiché.", NAME);
	}
	else
	{
		rp_SetClientBool(client, b_menuOpen, false);
		CPrintToChat(client, "%s Votre hud a été caché.", NAME);
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
			if (!rp_GetClientBool(client, b_menuOpen) && !rp_GetClientBool(client, b_isAfk))
			{
				if (rp_GetClientInt(client, i_timeJail) > 0)
					rp_SetClientInt(client, i_timeJail, rp_GetClientInt(client, i_timeJail) - 1);
				
				if (rp_GetClientInt(client, i_VipTime) > 0)
					rp_SetClientInt(client, i_VipTime, rp_GetClientInt(client, i_VipTime) - 1);
					
				if(rp_GetClientInt(client, i_countDrogue) > 3)
				{
					ForcePlayerSuicide(client);
					CPrintToChat(client, "%s Vous avez fait une overdose !", NAME);
				}	
					
				char Clantag[32], name[32], grade[32], groupename[64];
				
				GetJobName(rp_GetClientInt(client, i_Job), name, sizeof(name));
				GetGradeName(rp_GetClientInt(client, i_Grade), rp_GetClientInt(client, i_Job), grade, sizeof(grade));
				
				int aim = GetAimEnt(client, true);
				if(IsValidEntity(aim) && IsClientValid(aim))
				{
					//int vie = GetClientHealth(aim);
					
					//char jobName_Target[128], gradeName_Target[64];
					
					//GetJobName(jobID_target, jobName_Target, sizeof(jobName_Target));
				      	//GetGradeName(gradeID_target, jobID_target, gradeName_Target, sizeof(gradeName_Target));
					
					char strName[32];
					GetClientName(aim, strName, sizeof(strName));
					
					
					/*if (jobID_target == 0)
					{
						Format(HudTarget, sizeof(HudTarget), "%s (%iHP)\nNiveau: %i\nMétier: %s\nGroupe:", strName, vie, level_target, jobName_Target);
						PrintHintText(client, HudTarget);
					}	
					else
					{
						Format(HudTarget, sizeof(HudTarget), "%s (%iHP)\nNiveau: %i\nMétier: %s (%s)\nGroupe:", strName, vie, level_target, jobName_Target, gradeName_Target);
						PrintHintText(client, HudTarget);
					}	*/
				}				
				
				if(rp_GetClientInt(client, i_timeJail) > 0)
				{
					CS_SetClientClanTag(client, "★ PRISON ★");
					
					char JailRestant[64];
					StringTime(rp_GetClientInt(client, i_timeJail), JailRestant, sizeof(JailRestant));
					Format(JailRestant, sizeof(JailRestant), "★ Jail restant %s", JailRestant);
					
					PrintHintText(client, JailRestant);
				}
				else if(rp_GetClientInt(client, i_timeJail) > 1 && rp_GetClientInt(client, i_timeJail) < 5)
				{
					PrintHintText(client, "Peine de prison terminé !\nVous allez être libéré ...");
					//TeleportJobs(client, jobID);
				}	
				else if (rp_GetClientBool(client, b_isAfk))
				{	
					CS_SetClientClanTag(client, "★ AFK ★");
					PrintHintText(client, "★ Vous êtes AFK ★");
				}	
				else
				{
					if (rp_GetClientInt(client, i_Job) == 0)
					{			
						//Format(Clantag, sizeof(Clantag), "%s", jobName);	
						CS_SetClientClanTag(client, Clantag);
					}
					else if(rp_GetClientInt(client, i_Job) == 1 && GetClientTeam(client) == CS_TEAM_T)
					{
						CS_SetClientClanTag(client, "Sans Emploi");												
					}	
					else
					{			
						if(rp_GetClientInt(client, i_Job) == 1)
							Format(Clantag, sizeof(Clantag), "%s", grade);	
						else
							Format(Clantag, sizeof(Clantag), "%s (%s)", grade, name);		
							
						CS_SetClientClanTag(client, Clantag);
					}					
				}	
				
				Panel panel = new Panel();
				char strText[128];
				
				panel.SetTitle("Roleplay - Hud (V 1.0)");			
				panel.DrawText("");
				panel.DrawText("");
				
				
			       int iYear, iMonth, iDay, iHour, iMinute, iSecond;
			    
			       UnixToTime(GetTime(), iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_WEST);
				
				Format(strText, sizeof(strText), "Temps  : %02d/%02d/%d %02d:%02d:%02d" , iDay, iMonth, iYear, iHour, iMinute, iSecond);
				panel.DrawText(strText);	
				
				Format(strText, sizeof(strText), "Argent : %i$\nBanque : %i$", rp_GetClientInt(client, i_Money), rp_GetClientInt(client, i_Bank));
				panel.DrawText(strText);
				
				if (rp_GetClientInt(client, i_Job) == 0)
				{
					Format(strText, sizeof(strText), "Job : Sans Emploi");
					panel.DrawText(strText);
				}	
				else 
				{
					Format(strText, sizeof(strText), "Job   : %s (%s)", grade, name);
					panel.DrawText(strText);
				}
							
				if(rp_GetClientInt(client, i_Grade) == 1)
				{
					Format(strText, sizeof(strText), "Capital : %i$", rp_GetJobCapital(rp_GetClientInt(client, i_Job)));
					panel.DrawText(strText);
				}
				
				if(rp_GetClientInt(client, i_Group) != 0)
				{
					GetGroupeName(g_DB, client, groupename, sizeof(groupename));
					Format(strText, sizeof(strText), "Gang  : %s", groupename);
					panel.DrawText(strText);
				}
				
				Format(strText, sizeof(strText), "Level    : %i", rp_GetClientInt(client, i_Level));
				panel.DrawText(strText);
				
				Format(strText, sizeof(strText), "Salaire  : %i$", rp_GetClientInt(client, i_Salaire));
				panel.DrawText(strText);

				char zonename[128];
				Zone_getMostRecentActiveZone(client, zonename);
				
				if(StrEqual(zonename, ""))
					Format(strText, sizeof(strText), "Zone : en Ville");
				else
					Format(strText, sizeof(strText), "Zone : %s", zonename);				
				
				panel.DrawText(strText);	
				
				panel.Send(client, Handler_NullCancel, 1);
			}
		}	
		else if (!IsClientValid(client)) {
			TrashTimer(g_hTimerHUD[client], true);
		}
	}
}

void showAllHudMessages(int client) {
	showHudMsg(client, "Revolution-Team\nwww.revolution-asso.eu", 0, 188, 212, 0.01, 0.01, 1.05);
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

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	if(!IsValidEntity(client))
		return Plugin_Handled;
		
	if(buttons != 0) {
		if(rp_GetClientInt(client, i_LastButton) != buttons)
			ResetAFK(client);
		rp_SetClientInt(client, i_LastButton, buttons);
		//curIAng[client] = angles;
	}
	
	return Plugin_Continue;
}	

int ResetAFK(int client) 
{	
	if(IsClientValid(client)) 
	{
		if(rp_GetClientBool(client, b_isAfk)) 
			PrintHintText(client, "Re-bonjour %N.", client);
		
		rp_SetClientBool(client, b_isAfk, false);
		if(timerAFK[client] != null) 
		{
			if(CloseHandle(timerAFK[client]))
				timerAFK[client] = null;
		}
		timerAFK[client] = CreateTimer(GetConVarFloat(FindConVar("rp_temps_afk")), SetAFK, client);
	}
}

public Action SetAFK(Handle timer, any client) {
	if(IsClientValid(client)) {
		if(GetConVarFloat(FindConVar("rp_temps_afk")) != 0.0)
			rp_SetClientBool(client, b_isAfk, true);
	}
	timerAFK[client] = null;
}