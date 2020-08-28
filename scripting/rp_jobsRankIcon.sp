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
#include <sdkhooks>
#include <smlib>
#include <roleplay>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
int m_iOffsetLevel = -1;
int m_iLevel[MAXPLAYERS + 1];
int m_iRank[MAXPLAYERS + 1];

char steamID[MAXPLAYERS + 1][32];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Icons",
	author = "Benito",
	description = "Ranking & Level Icons",
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
		#if !defined CSS_SUPPORT
		m_iOffsetLevel = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicLevel");
		#endif
	}
	else
		UnloadPlugin();
}

public void OnMapStart()
{
	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
}	

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void rp_OnClientSpawn(int client)
{
	GetRankIcon(client);
	GetStaffIcon(client);
}	

public void OnClientPutInServer(int client) 
{	
	m_iLevel[client] = -1;
	m_iRank[client] = -1;
}

public void OnClientDisconnect(int client) 
{
	m_iLevel[client] = -1;
	m_iRank[client] = -1;
}

public void OnThinkPost(int m_iEntity)
{
	int m_iLevelTemp[MAXPLAYERS+1] = 0;
	GetEntDataArray(m_iEntity, m_iOffsetLevel, m_iLevelTemp, MAXPLAYERS+1);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(m_iLevel[i] != -1)
		{
			if(m_iLevel[i] != m_iLevelTemp[i])
			{
				SetEntData(m_iEntity, m_iOffsetLevel + (i * 4), m_iLevel[i]);
			}
		}
		
		SetEntData(m_iEntity, FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking")+(i*4), m_iRank[i]);
	}
}

stock int GetRankIcon(int client)
{
	KeyValues kv = new KeyValues("Ranks");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(rp_GetClientInt(client, i_Job), STRING(jobString));
	kv.JumpToKey(jobString);
	
	kv.JumpToKey("offset");
	m_iRank[client] = kv.GetNum("index");
	
	char sBuffer[PLATFORM_MAX_PATH];
	Format(STRING(sBuffer), "materials/panorama/images/icons/skillgroups/skillgroup%i.svg", m_iRank[client]);
	AddFileToDownloadsTable(sBuffer);
	
	kv.Rewind();
	delete kv;
}

stock int GetStaffIcon(int client)
{
	KeyValues kv = new KeyValues("Admin");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/admins.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/admins.cfg : NOT FOUND");
	}	
	
	kv.JumpToKey(steamID[client]);
	
	m_iLevel[client] = kv.GetNum("icon");
	
	char sBuffer[PLATFORM_MAX_PATH];
	Format(STRING(sBuffer), "materials/panorama/images/icons/xp/level%i.png", m_iLevel[client]);
	AddFileToDownloadsTable(sBuffer);
	
	kv.Rewind();
	delete kv;
}