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
#include <sdkhooks>
#include <smlib>
#include <unixtime_sourcemod>
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
Handle TimerRPT[MAXPLAYERS + 1] = { null, ... };
Handle timerAFK[MAXPLAYERS + 1] = { null, ... };

bool canUseMetro[MAXPLAYERS + 1] = { true, ...};

ConVar AfkTime;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Check Variables",
	author = "Benito",
	description = "Timer répétitif actionnant les fonctions des variables",
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
		
	AfkTime = CreateConVar("rp_temps_afk", "300", "Temps inactif AFK");	
	AutoExecConfig(true, "rp_afk");
}

public Action OnClientCommand(int client) 
{
	ResetAFK(client);
	
	return Plugin_Continue;
}

public void OnClientSettingsChanged(int client) 
{
	ResetAFK(client);
}

public void RP_OnPlayerDeath(int attacker, int victim, int respawnTime)
{
	if (rp_GetClientInt(victim, i_timeJail) > 0)
		TeleportEntity(victim, view_as<float>({ 1307.694702, 1422.525756, -191.968750}), NULL_VECTOR, NULL_VECTOR);
}

public void RP_OnPlayerSpawn(int client)
{
	int weapon;
	while((weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != -1)
	{
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
	
	int iMelee = GivePlayerItem(client, "weapon_fists");
	EquipPlayerWeapon(client, iMelee);
	
	/*if(GetClientTeam(client) == CS_TEAM_CT)
		CS_SwitchTeam(client, CS_TEAM_T);*/
		
	CheckCollision(client);	
}

public void OnClientPutInServer(int client) 
{	
	TimerRPT[client] = CreateTimer(1.0, update, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
	rp_SetClientFloat(client, fl_FrozenTime, 0.0);
	rp_SetClientBool(client, b_isAfk, false);
}

public void OnClientDisconnect(int client) 
{
	TrashTimer(TimerRPT[client], true);
	rp_SetClientBool(client, b_isAfk, false);
	TrashTimer(timerAFK[client], true);
}

public Action update(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) 
	{		
		if (IsClientValid(client))
		{						
			if(!rp_GetClientBool(client, b_isEventParticipant))
			{
				Client_SetScore(client, 0);
				Client_SetDeaths(client, 0);
				
				char grade[16], Clantag[32];
				//GetJobName(rp_GetClientInt(client, i_Job), job);
				GetGradeName(rp_GetClientInt(client, i_Grade), rp_GetClientInt(client, i_Job), STRING(grade));
				
				char map[128];
				rp_GetCurrentMap(map);
				
				if(StrContains(map, "rp_princeton_") != -1)
					if(MetroTechnicien(client) || MetroComico(client) || MetroPVP(client) || MetroAerien(client) || MetroMcdo(client))
						TeleportationMetro(client);
				
				if(rp_GetClientFloat(client, fl_FrozenTime) > 0.0)
				{
					rp_SetClientFloat(client, fl_FrozenTime, rp_GetClientFloat(client, fl_FrozenTime) - 1.0);
					SetEntityMoveType(client, MOVETYPE_NONE);				
				}
				else if(rp_GetClientFloat(client, fl_FrozenTime) < 1.0)
				{
					if(GetEntityMoveType(client) != MOVETYPE_NOCLIP)
						SetEntityMoveType(client, MOVETYPE_WALK);	
				}		
					
				int weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
				if(!IsValidEntity(weapon))
				{
					int iMelee = GivePlayerItem(client, "weapon_fists");
					EquipPlayerWeapon(client, iMelee);
				}
	
				if(rp_GetClientInt(client, i_timeJail) > 0)
				{
					rp_SetClientInt(client, i_timeJail, rp_GetClientInt(client, i_timeJail) - 1);
					char strTime[64];
					StringTime(rp_GetClientInt(client, i_timeJail), STRING(strTime));
					PrintHintText(client, "<font color='#0080ff'>Temps en prison</font> : %s", strTime);
					
					CS_SetClientClanTag(client, "★ PRISON ★");
					
					if(rp_GetClientInt(client, i_ByteZone) == 1)
						SetClientListeningFlags(client, VOICE_MUTED);
					else
						SetClientListeningFlags(client, VOICE_NORMAL);					
				}
				else if(rp_GetClientInt(client, i_timeJail) > 1 && rp_GetClientInt(client, i_timeJail) < 5)
				{
					PrintHintText(client, "Peine de prison terminé !\nVous allez être libéré ...");
					//TeleportJobs(client, jobID);
					SetClientListeningFlags(client, VOICE_NORMAL);
				}	
				else if (rp_GetClientBool(client, b_isAfk))
				{	
					CS_SetClientClanTag(client, "★ AFK ★");
					PrintHintText(client, "★ Vous êtes AFK ★");
				}	
				else
				{
					GetClanTag(rp_GetClientInt(client, i_Grade), rp_GetClientInt(client, i_Job), STRING(Clantag));
					
					if(GetClientTeam(client) == CS_TEAM_T)
					{
						if(rp_GetClientInt(client, i_Job) == 1)
							CS_SetClientClanTag(client, "Chômeur");			
						else
							CS_SetClientClanTag(client, Clantag);											
					}		
					else
						CS_SetClientClanTag(client, Clantag);			
				}	
					
				if (rp_GetClientInt(client, i_VipTime) > 0)
					rp_SetClientInt(client, i_VipTime, rp_GetClientInt(client, i_VipTime) - 1);
						
				if(rp_GetClientInt(client, i_countDrogue) > 3)
				{
					ForcePlayerSuicide(client);
					CPrintToChat(client, "%s Vous avez fait une overdose !", TEAM);
				}	
			}	
		}	
		else if (!IsClientValid(client)) {
			TrashTimer(TimerRPT[client], true);
		}
	}
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
		int iYear, iMonth, iDay, iHour, iMinute, iSecond;
		UnixToTime(GetTime(), iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_CEST);
		
		if(rp_GetClientBool(client, b_isAfk)) 
			PrintHintText(client, "Re-bonjour <font color='#eaff00'>%N</font>,\n nous sommes le <font color='#0091ff'>%02d/%02d/%d</font>, il est <font color='#0091ff'>%02d:%02d:%02d</font>", client, iDay, iMonth, iYear, iHour, iMinute, iSecond);
		
		rp_SetClientBool(client, b_isAfk, false);
		if(timerAFK[client] != null) 
		{
			if(CloseHandle(timerAFK[client]))
				timerAFK[client] = null;
		}
		timerAFK[client] = CreateTimer(GetConVarFloat(AfkTime), SetAFK, client);
	}
}

public Action SetAFK(Handle timer, any client) 
{
	if(IsClientValid(client)) 
	{
		if(GetConVarFloat(AfkTime) != 0.0)
			rp_SetClientBool(client, b_isAfk, true);
	}
	timerAFK[client] = null;
}

public void OnClientPostAdminCheck(int client)
{	
	CreateTimer(2.0, ClientConnectIntro, client);
}

public Action ClientConnectIntro(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		char phonenumber[32];  
		rp_GetPhoneData(client, phone_number, STRING(phonenumber));
		
		char query[100];
		Format(STRING(query), "SELECT * FROM rp_phone_history_messages WHERE phonenumber_receiver = '%s'", phonenumber);	 
		DBResultSet Results = SQL_Query(rp_GetDatabase(), query);
		
		int count;
		bool viewed;
		while(Results.FetchRow())
		{
			count++;
			viewed = SQL_FetchBoolByName(Results, "viewed");	
		}			
		delete Results;		
		
		CPrintToChat(client, "{darkred}*********************************");
		CPrintToChat(client, "{darkred}* {default}Bienvenue sur notre serveur Roleplay");
		CPrintToChat(client, "{darkred}* {default}By {green}.:{lightred}%s{green}:.", AUTHOR);
		
		if(rp_GetClientInt(client, i_VipTime) != 0)
		{
			int time = GetTime() + rp_GetClientInt(client, i_VipTime);
			
			int iYear, iMonth, iDay, iHour, iMinute, iSecond;		
			UnixToTime(time, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_CEST);						
			
			CPrintToChat(client, "{darkred}* {default}Vous êtes {yellow}V.I.P jusqu'au {green}%02d/%02d/%d {default}à {green}%02d:%02d:%02d", iDay, iMonth , iYear , iHour , iMinute , iSecond );
		}	
		
		if(!viewed && count != 0)
			CPrintToChat(client, "{darkred}* Vous avez reçu de nouveaux messages.");
		
		CPrintToChat(client, "{darkred}* {default}Discord: {lightblue}%s", DISCORD_URL);
		CPrintToChat(client, "{darkred}* {default}Forum: {lightblue}%s", FORUM_URL);	
		CPrintToChat(client, "{darkred}*********************************");
		
		PrecacheSoundAny(JOIN_SOUND);
		EmitSoundToClientAny(client, JOIN_SOUND, client, _, _, _, 1.0);
	}	
}

Menu TeleportationMetro(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoTeleportationMetro);
	menu.SetTitle("Choisir la destination");
	if(rp_GetClientInt(client, i_timeJail) >= 1)
		menu.AddItem("", "Vous n'avez pas accès au métro", ITEMDRAW_DISABLED);	
	else
	{
		if(canUseMetro[client])
		{
			if(!MetroComico(client))
				menu.AddItem("comico", "Station Commissariat");
			if(!MetroTechnicien(client))
				menu.AddItem("tech", "Station Technicien");	
			if(!MetroAerien(client))
				menu.AddItem("pvp", "Station PVP");		
			if(!MetroMcdo(client))	
				menu.AddItem("mcdo", "Station McDonald's");	
			if(!MetroPVP(client))
			{			
				if(rp_GetEventType() == event_type_none)
					menu.AddItem("event", "Station Event");
				else
					menu.AddItem("", "Station Event(Event en cours)", ITEMDRAW_DISABLED);				
			}	
		}
		else
			menu.AddItem("", "Patienter avant de reutiliser\nle métro", ITEMDRAW_DISABLED);	
	}		
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoTeleportationMetro(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		canUseMetro[client] = false;
		
		CreateTimer(5.0, ResetData, client);
		
		if(StrEqual(info, "comico"))
		{
			rp_SetClientBool(client, b_menuOpen, false);
			TeleportEntity(client, view_as<float>( { 2533.475097, 668.413818, -2399.968750 } ), NULL_VECTOR, NULL_VECTOR);	
			CPrintToChat(client, "%s Vous êtes arrivé à la station du commissariat.", TEAM);
		}
		else if(StrEqual(info, "tech"))
		{
			rp_SetClientBool(client, b_menuOpen, false);
			TeleportEntity(client, view_as<float>( { -3105.315429, -342.760345, -2399.968750 } ), NULL_VECTOR, NULL_VECTOR);	
			CPrintToChat(client, "%s Vous êtes arrivé à la station des techniciens.", TEAM);
		}
		else if(StrEqual(info, "pvp"))
		{
			rp_SetClientBool(client, b_menuOpen, false);
			TeleportEntity(client, view_as<float>( { -3227.135009, -9277.297851, -1751.968750 } ), NULL_VECTOR, NULL_VECTOR);	
			CPrintToChat(client, "%s Vous êtes arrivé à la station PvP.", TEAM);
		}
		else if(StrEqual(info, "mcdo"))
		{
			rp_SetClientBool(client, b_menuOpen, false);
			TeleportEntity(client, view_as<float>( { 166.780715, -4094.868408, -2271.968750 } ), NULL_VECTOR, NULL_VECTOR);	
			CPrintToChat(client, "%s Vous êtes arrivé à la station McDonald's.", TEAM);
		}
		else if(StrEqual(info, "event"))
		{
			rp_SetClientBool(client, b_menuOpen, false);
			TeleportEntity(client, view_as<float>( { 5021.028808, 11086.150390, -2311.968750 } ), NULL_VECTOR, NULL_VECTOR);	
			CPrintToChat(client, "%s Vous êtes arrivé à la station Event.", TEAM);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

bool MetroPVP(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 4742.858886 && position[0] <= 5172.858886 && position[1] >= 10933.493164 && position[1] <= 10988.493164 && position[2] >= -2314.968750 && position[2] <= -2194.968750)
	{
		return true;
	}	
	else 
		return false;
}

bool MetroTechnicien(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -3000.198486 && position[0] <= -2920.198486 && position[1] >= -638.590332 && position[1] <= -213.590332 && position[2] >= -2400.643554 && position[2] <= -2285.643554)
	{
		return true;
	}
	else 
		return false;
}

bool MetroComico(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= 2360.915039 && position[0] <= 2810.915039 && position[1] >= 491.952880 && position[1] <= 571.952880 && position[2] >= -2402.968750 && position[2] <= -2287.968750)
	{
		return true;
	}
	else 
		return false;
}

bool MetroAerien(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -4154.621093 && position[0] <= -3064.620849 && position[1] >= -9531.968750 && position[1] <= -9186.968750 && position[2] >= -1758.984252 && position[2] <= -1483.984252)
	{
		return true;
	}
	else 
		return false;
}

bool MetroMcdo(int client)
{
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	if (position[0] >= -131.755981 && position[0] <= 318.244018 && position[1] >= -4240.253417 && position[1] <= -4165.253417 && position[2] >= -2272.751464 && position[2] <= -2162.751464)
	{
		return true;
	}
	else 
		return false;
}

public Action ResetData(Handle timer, any client)
{
	if(IsClientValid(client))
		canUseMetro[client] = true;
}	

int CheckCollision(int client)
{
	/*
	0 COLLISION_GROUP_NONE
	1 COLLISION_GROUP_DEBRIS, Collides with nothing but world and static stuff
	2 COLLISION_GROUP_DEBRIS_TRIGGER, Same as debris, but hits triggers
	3 COLLISION_GROUP_INTERACTIVE_DEBRIS Collides with everything except other interactive debris or debris
	4 COLLISION_GROUP_INTERACTIVE Collides with everything except interactive debris or debris
	5 COLLISION_GROUP_PLAYER This is the default behavior expected for most prop_physics
	6 COLLISION_GROUP_BREAKABLE_GLASS,
	7 COLLISION_GROUP_VEHICLE,
	8 COLLISION_GROUP_PLAYER_MOVEMENT For HL2, same as Collision_Group_Player
	9 COLLISION_GROUP_NPC Generic NPC group
	10 COLLISION_GROUP_IN_VEHICLE For any entity inside a vehicle
	11 COLLISION_GROUP_WEAPON For any weapons that need collision detection
	12 COLLISION_GROUP_VEHICLE_CLIP Vehicle clip brush to restrict vehicle movement
	13 COLLISION_GROUP_PROJECTILE Projectiles!
	14 COLLISION_GROUP_DOOR_BLOCKER Blocks entities not permitted to get near moving doors
	15 COLLISION_GROUP_PASSABLE_DOOR Doors that the player shouldn't collide with
	16 COLLISION_GROUP_DISSOLVING Things that are dissolving are in this group
	17 COLLISION_GROUP_PUSHAWAY Nonsolid on client and server, pushaway in player code
	18 COLLISION_GROUP_NPC_ACTOR Used so NPCs in scripts ignore the player.
	*/
	if (IsClientValid(client))
	{
		if (GetEntProp(client, Prop_Data, "m_CollisionGroup") != 5)
			SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	}
}