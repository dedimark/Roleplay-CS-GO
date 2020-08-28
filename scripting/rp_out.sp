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
#include <cstrike>
#include <sdkhooks>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>
#include <smlib>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Jobs - Out", 
	author = "Benito", 
	description = "Sortir les joueurs", 
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
		
		RegConsoleCmd("out", Command_Out);
		RegConsoleCmd("exclure", Command_Out);
		RegConsoleCmd("virer", Command_Out);	
		RegConsoleCmd("saveout", Command_SaveOut);
		RegConsoleCmd("savespawn", Command_SaveSpawn);
	}
	else
		UnloadPlugin();
}

public void OnMapStart()
{
	char map[128];
	rp_GetCurrentMap(map);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/", map);
}		

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_ClientSendToSpawn", ClientSendToSpawn);
}

public int ClientSendToSpawn(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(!IsClientValid(client))
		return -1;
	Spawn(client);
	
	return -1;
}

public void rp_OnClientSpawn(int client)
{
	if (rp_GetClientInt(client, i_timeJail) > 0)
		TeleportEntity(client, view_as<float>({ 1307.694702, 1422.525756, -191.968750}), NULL_VECTOR, NULL_VECTOR);
	else
		Spawn(client);
}

public Action Command_Out(int client, int args) 
{
	int aim = GetAimEnt(client, true);
	if(IsValidEntity(aim)) 
	{
		if (Distance(client, aim) <= 100)
		{
			if(isZoneProprietaire(client))
				Out(client, aim);
			else
				CPrintToChat(client, "%s Vous n'êtes pas dans votre zone appropriée / vous n'avez pas la permission.", TEAM);
		}	
		else
			CPrintToChat(client, "%s Vous devez vous rapprocher de la personne.", TEAM);		
	}
	else
		CPrintToChat(client, "%s Vous devez viser une personne.", TEAM);
}

int Out(int client, int target) {
	char map[128];
	rp_GetCurrentMap(map);
	
	KeyValues kv = new KeyValues("Out");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/out.cfg", map);
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/%s/out.cfg : NOT FOUND", map);
	}	
	
	char jobString[32];
	IntToString(rp_GetClientInt(client, i_Job), STRING(jobString));
	kv.JumpToKey(jobString);
	
	float position[3];
	position[0] = kv.GetFloat("pos_x");
	position[1] = kv.GetFloat("pos_y");
	position[2] = kv.GetFloat("pos_z");
	TeleportEntity(target, position, NULL_VECTOR, NULL_VECTOR);
	
	kv.Rewind();	
	delete kv;
}	

int Spawn(int client) {
	char map[128];
	rp_GetCurrentMap(map);
	
	KeyValues kv = new KeyValues("Spawn");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/spawn.cfg", map);
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/%s/spawn.cfg : NOT FOUND", map);
	}	
	
	char jobString[32];
	IntToString(rp_GetClientInt(client, i_Job), STRING(jobString));
	kv.JumpToKey(jobString);
	
	float position[3];
	position[0] = kv.GetFloat("pos_x");
	position[1] = kv.GetFloat("pos_y");
	position[2] = kv.GetFloat("pos_z");
	TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
	
	kv.Rewind();	
	delete kv;
}

public Action Command_SaveOut(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	else if (args < 1)
	{
		CPrintToChat(client, "%s Utilisation: !saveout <jobID>", TEAM);
		return Plugin_Handled;
	}
	
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		
		char arg[2];
		GetCmdArgString(STRING(arg));
		
		if(String_IsNumeric(arg))
		{	
			char map[128];
			GetCurrentMap(STRING(map));
			if (StrContains(map, "workshop") != -1) {
				char mapPart[3][64];
				ExplodeString(map, "/", mapPart, 3, 64);
				strcopy(STRING(map), mapPart[2]);
			}
			
			KeyValues kv = new KeyValues("Out");
			char sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/out.cfg", map);
			
			if(!kv.ImportFromFile(sPath))
			{
				delete kv;
				PrintToServer("configs/roleplay/%s/out.cfg : NOT FOUND", map);
			}	
			
			if(kv.JumpToKey(arg))
			{			
				kv.SetFloat("pos_x", position[0]);
				kv.SetFloat("pos_y", position[1]);
				kv.SetFloat("pos_z", position[2]);
				
				CPrintToChat(client, "%s Le spawnID %s a été enregistrée sous x:{green}%f{default},y:{green}%f{default},z:{green}%f", TEAM, arg, position[0], position[1], position[2]);
			}	
			else
			{
				CPrintToChat(client, "%s Le jobID indiqué n'éxiste pas", TEAM, arg);
				delete kv;
			}	
				
			kv.GoBack();
			kv.ExportToFile(sPath);	
			delete kv;	
		}	
		else
			CPrintToChat(client, "%s Vous devez écrire le jobID en chiffre", TEAM);
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", TEAM);
	
	return Plugin_Handled;
}	

public Action Command_SaveSpawn(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	else if (args < 1)
	{
		CPrintToChat(client, "%s Utilisation: !savespawn <jobID>", TEAM);
		return Plugin_Handled;
	}
	
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		
		char arg[5];
		GetCmdArgString(STRING(arg));
		
		if(String_IsNumeric(arg))
		{	
			char map[128];
			rp_GetCurrentMap(map);
			
			KeyValues kv = new KeyValues("Spawn");
			char sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, STRING(sPath), "configs/roleplay/%s/spawn.cfg", map);
			
			if(!kv.ImportFromFile(sPath))
			{
				delete kv;
				PrintToServer("configs/roleplay/%s/spawn.cfg : NOT FOUND", map);
			}	
			
			if(kv.JumpToKey(arg))
			{			
				kv.SetFloat("pos_x", position[0]);
				kv.SetFloat("pos_y", position[1]);
				kv.SetFloat("pos_z", position[2]);
				
				CPrintToChat(client, "%s Le spawnID %s a été enregistrée sous x:{green}%f{default},y:{green}%f{default},z:{green}%f", TEAM, arg, position[0], position[1], position[2]);
			}	
			else
			{
				CPrintToChat(client, "%s Le jobID indiqué n'éxiste pas", TEAM, arg);
				delete kv;
			}	
				
			kv.GoBack();
			kv.ExportToFile(sPath);	
			delete kv;	
		}	
		else
			CPrintToChat(client, "%s Vous devez écrire le jobID en chiffre", TEAM);
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", TEAM);
	
	return Plugin_Handled;
}