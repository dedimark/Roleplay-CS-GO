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
#include <smlib>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							P L U G I N  -  D E F I N E S

***************************************************************************************/
#define MAXPOS 10
#define MAXZONE 256

/***************************************************************************************
 
							G L O B A L  -  V A R S

***************************************************************************************/
int g_Editing[MAXPLAYERS + 1];
int g_BeamSprite;
int g_HaloSprite;
float g_Positions[MAXPLAYERS + 1][2][3];

/***************************************************************************************

							P L U G I N  -  I N F O

****************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Zones & Byt",
	author = "Benito",
	description = "Système zoning pour le roleplay",
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
		
	RegConsoleCmd("rp_zoning", Cmd_Zoning);
	
	HookEventEx("round_start", Event_OnRoundStart);
}

public void Fwd_OnLicenceLoaded(bool licenceValid)
{
	if(!licenceValid)
		UnloadPlugin();
}

public void OnClientPostAdminCheck(int client) 
{
	g_Editing[client] = 0;
	rp_SetClientString(client, sz_Zone, "En Ville", 8);
	rp_SetClientInt(client, i_ByteZone, 0);
}

public Action Cmd_Zoning(int client, int args)
{
	rp_SetClientBool(client, b_menuOpen, true);
	g_Editing[client] = 0;
	
	Menu menu = new Menu(Handle_ZoneMenu);
	menu.SetTitle("Zones");
	menu.AddItem("create", "Create Zone");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handle_ZoneMenu(Menu menu, MenuAction action, int client, int param) 
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));	
		
		if(StrEqual(info, "create"))
			Menu_Edit(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu Menu_Edit(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuZoning);
	menu.SetTitle("Roleplay - Zoning");
	
	if (g_Editing[client] == 0)
		menu.AddItem("new", "Nouvelle");
	else
		menu.AddItem("restart", "Recommencer");
		
	if (g_Editing[client] > 0)
	{		
		if (g_Editing[client] == 2)
			menu.AddItem("edit", "Continue");
		else
			menu.AddItem("edit", "Pause");
			
		menu.AddItem("delete", "Cancel");	
		menu.AddItem("save", "Save");	
	}		
		
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuZoning(Menu menu, MenuAction action, int client, int param) 
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));	
		
		if(StrEqual(info, "new") || StrEqual(info, "restart"))
		{
			g_Editing[client] = 1;
			float pos[3];
			float ang[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, ang);
			TR_TraceRayFilter(pos, ang, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
			TR_GetEndPosition(g_Positions[client][0]);
			Menu_Edit(client);
		}	
		else if(StrEqual(info, "edit"))
		{
			// Pause
			if (g_Editing[client] == 2)
			{
				g_Editing[client] = 1;
			} 
			else 
			{
				DrawBeamBox(client);
				g_Editing[client] = 2;
				Menu_Edit(client);
			}
		}	
		else if(StrEqual(info, "delete"))
		{
			g_Editing[client] = 0;
		}
		else if(StrEqual(info, "save"))
		{
			g_Editing[client] = 2;
			CPrintToChat(client, "%s [first]: %f %f %f", TEAM, g_Positions[client][0][0], g_Positions[client][0][1], g_Positions[client][0][2]);
			CPrintToChat(client, "%s [two]: %f %f %f", TEAM, g_Positions[client][1][0], g_Positions[client][1][1], g_Positions[client][1][2]);
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
		
public void OnMapStart() 
{
	CheckIfIsInZone();
	g_BeamSprite = PrecacheModel("sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vmt");
}

public Action Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	CheckIfIsInZone();
}

stock void CheckIfIsInZone()
{	
	char map[128];
	rp_GetCurrentMap(map);
	
	KeyValues kv = new KeyValues("Zones");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/zones.cfg", map);
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/%s/zones.cfg : NOT FOUND", map);
	}	
		
	for (int zoneid = 1; zoneid <= MAXZONE; zoneid++)
	{		
		char kvZone[64];
		IntToString(zoneid, STRING(kvZone));
		if(kv.JumpToKey(kvZone))
		{		
			char zonename[64];
			kv.GetString("name", STRING(zonename));
			
			int bytezone = kv.GetNum("byteID");
			
			float kvPos0[MAXPOS][3];
			float kvPos1[MAXPOS][3];
				
			kv.GetVector("first", kvPos0[zoneid]);
			kv.GetVector("two", kvPos1[zoneid]);
			
			CreateZoneEntity(kvPos0[zoneid], kvPos1[zoneid], zonename, bytezone);
				
			kv.GoBack();		
		}	
	}
	
	kv.Rewind();	
	delete kv;
}

public int CreateZoneEntity(float fMins[3], float fMaxs[3], char sZoneName[64], int bytezone) 
{
	float fMiddle[3];
	int iEnt = CreateEntityByName("trigger_multiple");
	
	DispatchKeyValue(iEnt, "spawnflags", "64");
	//DispatchKeyValue(iEnt, "targetname", sZoneName);
	DispatchKeyValue(iEnt, "wait", "0");
	
	Format(STRING(sZoneName), "%s|%i", sZoneName, bytezone);
	Entity_SetName(iEnt, sZoneName);
	
	DispatchSpawn(iEnt);
	ActivateEntity(iEnt);
	
	GetMiddleOfABox(fMins, fMaxs, fMiddle);
	
	TeleportEntity(iEnt, fMiddle, NULL_VECTOR, NULL_VECTOR);
	PrecacheModel("models/error.mdl");
	SetEntityModel(iEnt, "models/error.mdl");
	
	// Have the mins always be negative
	fMins[0] = fMins[0] - fMiddle[0];
	if (fMins[0] > 0.0)
		fMins[0] *= -1.0;
	fMins[1] = fMins[1] - fMiddle[1];
	if (fMins[1] > 0.0)
		fMins[1] *= -1.0;
	fMins[2] = fMins[2] - fMiddle[2];
	if (fMins[2] > 0.0)
		fMins[2] *= -1.0;
	
	// And the maxs always be positive
	fMaxs[0] = fMaxs[0] - fMiddle[0];
	if (fMaxs[0] < 0.0)
		fMaxs[0] *= -1.0;
	fMaxs[1] = fMaxs[1] - fMiddle[1];
	if (fMaxs[1] < 0.0)
		fMaxs[1] *= -1.0;
	fMaxs[2] = fMaxs[2] - fMiddle[2];
	if (fMaxs[2] < 0.0)
		fMaxs[2] *= -1.0;
	
	SetEntPropVector(iEnt, Prop_Send, "m_vecMins", fMins);
	SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", fMaxs);
	SetEntProp(iEnt, Prop_Send, "m_nSolidType", 2);
	
	int iEffects = GetEntProp(iEnt, Prop_Send, "m_fEffects");
	iEffects |= 32;
	SetEntProp(iEnt, Prop_Send, "m_fEffects", iEffects);
	
	HookSingleEntityOutput(iEnt, "OnStartTouch", EntOut_OnStartTouch);
	HookSingleEntityOutput(iEnt, "OnEndTouch", EntOut_OnEndTouch);
}

public void EntOut_OnStartTouch(const char[] output, int caller, int activator, float delay) 
{
	if (activator < 1 || activator > MaxClients || !IsClientInGame(activator) || !IsPlayerAlive(activator))
		return;
	
	char sTargetName[256];
	GetEntPropString(caller, Prop_Data, "m_iName", STRING(sTargetName));
	
	char name[2][64];
	ExplodeString(sTargetName, "|", name, 2, 64);
	int byteID = StringToInt(name[1]);

	rp_SetClientString(activator, sz_Zone, name[0], sizeof(name[]));
	rp_SetClientInt(activator, i_ByteZone, byteID);
}

public void EntOut_OnEndTouch(const char[] output, int caller, int activator, float delay) 
{
	if (activator < 1 || activator > MaxClients || !IsClientInGame(activator) || !IsPlayerAlive(activator))
		return;

	char sTargetName[256];
	GetEntPropString(caller, Prop_Data, "m_iName", STRING(sTargetName));
	
	char name[2][64];
	ExplodeString(sTargetName, "|", name, 2, 64);
	int byteID = StringToInt(name[1]);

	rp_SetClientString(activator, sz_Zone, name[0], sizeof(name[]));
	rp_SetClientInt(activator, i_ByteZone, byteID);
}

stock void GetMiddleOfABox(const float vec1[3], const float vec2[3], float buffer[3]) {
	float mid[3];
	MakeVectorFromPoints(vec1, vec2, mid);
	mid[0] = mid[0] / 2.0;
	mid[1] = mid[1] / 2.0;
	mid[2] = mid[2] / 2.0;
	AddVectors(vec1, mid, buffer);
}

public void OnPluginEnd()
{
	RemoveZones();
}

stock void RemoveZones()
{
	// First remove any old zone triggers
	int iEnts = GetMaxEntities();
	char sClassName[64];
	for (int i = MaxClients; i < iEnts; i++)
	{
		if (IsValidEntity(i)
			 && IsValidEdict(i)
			 && GetEdictClassname(i, STRING(sClassName))
			 && StrContains(sClassName, "trigger_multiple") != -1)
		{
			UnhookSingleEntityOutput(i, "OnStartTouch", EntOut_OnStartTouch);
			UnhookSingleEntityOutput(i, "OnEndTouch", EntOut_OnEndTouch);
			AcceptEntityInput(i, "Kill");
		}
	}
} 

public bool TraceRayDontHitSelf(int entity, int mask, any data) 
{
	if (entity == data)
		return false;
	return true;
}

stock void DeleteZone(int zoneID)
{	
	char map[128];
	rp_GetCurrentMap(map);
	
	KeyValues kv = new KeyValues("Zones");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/zones.cfg", map);
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/%s/zones.cfg : NOT FOUND", map);
	}	
		
	char zone[10];
	IntToString(zoneID, STRING(zone));	
	kv.Remove(zone);
	
	kv.Rewind();	
	delete kv;
}

public void DrawBeamBox(int client) 
{
	int zColor[4];
	zColor[0] = 255;
	zColor[1] = 255;
	zColor[2] = 255;
	zColor[3] = 255;
	TE_SendBeamBoxToClient(client, g_Positions[client][1], g_Positions[client][0], g_BeamSprite, g_HaloSprite, 0, 30, 1.0, 5.0, 5.0, 2, 1.0, zColor, 0);
	CreateTimer(1.0, BeamBox, client, TIMER_REPEAT);
}

public Action BeamBox(Handle timer, any client) 
{
	if (IsClientInGame(client))
	{
		if (g_Editing[client] == 2)
		{
			int zColor[4];
			zColor[0] = 255;
			zColor[1] = 255;
			zColor[2] = 255;
			zColor[3] = 255;
			TE_SendBeamBoxToClient(client, g_Positions[client][1], g_Positions[client][0], g_BeamSprite, g_HaloSprite, 0, 30, 1.0, 5.0, 5.0, 2, 1.0, zColor, 0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

stock void TE_SendBeamBoxToClient(int client, float uppercorner[3], const float bottomcorner[3], int ModelIndex, int HaloIndex, int StartFrame, int FrameRate, float Life, float Width, float EndWidth, int FadeLength, float Amplitude, const int Color[4], int Speed) 
{
	// Create the additional corners of the box
	float tc1[3];
	AddVectors(tc1, uppercorner, tc1);
	tc1[0] = bottomcorner[0];
	
	float tc2[3];
	AddVectors(tc2, uppercorner, tc2);
	tc2[1] = bottomcorner[1];
	
	float tc3[3];
	AddVectors(tc3, uppercorner, tc3);
	tc3[2] = bottomcorner[2];
	
	float tc4[3];
	AddVectors(tc4, bottomcorner, tc4);
	tc4[0] = uppercorner[0];
	
	float tc5[3];
	AddVectors(tc5, bottomcorner, tc5);
	tc5[1] = uppercorner[1];
	
	float tc6[3];
	AddVectors(tc6, bottomcorner, tc6);
	tc6[2] = uppercorner[2];
	
	// Draw all the edges
	TE_SetupBeamPoints(uppercorner, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(uppercorner, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(uppercorner, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) 
{
	BeamBox_OnPlayerRunCmd(client);
}

public void BeamBox_OnPlayerRunCmd(int client) 
{
	if (g_Editing[client] == 1 || g_Editing[client] == 3)
	{
		float pos[3];
		float ang[3];
		int zColor[4];
		zColor[0] = 255;
		zColor[1] = 255;
		zColor[2] = 255;
		zColor[3] = 255;
		if (g_Editing[client] == 1)
		{
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, ang);
			TR_TraceRayFilter(pos, ang, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
			TR_GetEndPosition(g_Positions[client][1]);
		}
		TE_SendBeamBoxToClient(client, g_Positions[client][1], g_Positions[client][0], g_BeamSprite, g_HaloSprite, 0, 30, 0.1, 5.0, 5.0, 2, 1.0, zColor, 0);
	}
}