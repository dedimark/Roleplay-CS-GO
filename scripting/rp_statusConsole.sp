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
#include <sdktools>
#include <PTaH>
#include <roleplay>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
ArrayList StatusArray;

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Console Status",
	description = "Change status style", 
	author = "Benito", 
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
		StatusArray = new ArrayList(512);
		PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);
	}
	else
		UnloadPlugin();
}

public void OnMapStart() {
	LoadConfig();
}

public void OnMapEnd() {
	StatusArray.Clear();
}

public Action ExecuteStringCommand(int client, char sCommandString[512])
{
	if (IsValidClient(client))
	{
		static char sMessage[512];
		strcopy(STRING(sMessage), sCommandString);
		TrimString(sMessage);
		
		if (StrContains(sMessage, "status") == 0 || StrEqual(sMessage, "status", false))
		{
			bool playerlist = false;
			for (int i = 0; i < StatusArray.Length; i++) {
				char buffer[512];
				StatusArray.GetString(i, STRING(buffer));
				if (StrContains(buffer, "{USERID}") != -1 && !playerlist) {
					LoopClients(j)
					{
						if (IsClientConnected(j) && !IsFakeClient(j) && !IsClientSourceTV(j))
						{
							buffer = "";
							StatusArray.GetString(i, STRING(buffer));
							Format(STRING(buffer), "%s", CheckMessageVariables(buffer, j));
							PrintToConsole(client, buffer);
						}
					}
					playerlist = true;
					continue;
				}
				Format(STRING(buffer), "%s", CheckMessageVariables(buffer, -2));
				PrintToConsole(client, buffer);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

char CheckMessageVariables(const char[] message, int client) {
	char buffer[128], sMessage[512];
	strcopy(STRING(sMessage), message);
	if (!IsValidClient(client) && client > -2)return sMessage;
	
	if (StrContains(sMessage, "{SERVER_IP}", false) != -1) {
		ReplaceString(STRING(sMessage), "{SERVER_IP}", GetServerIP());
	}
	if (StrContains(sMessage, "{AUTHOR}", false) != -1) {
		ReplaceString(STRING(sMessage), "{AUTHOR}", "MBK");
	}
	if (StrContains(sMessage, "{FORUM}", false) != -1) {
		ReplaceString(STRING(sMessage), "{FORUM}", FORUM_URL);
	}
	if (StrContains(sMessage, "{DISCORD}", false) != -1) {
		ReplaceString(STRING(sMessage), "{DISCORD}", DISCORD_URL);
	}
	if (StrContains(sMessage, "{SERVER_NAME}", false) != -1) {
		GetConVarString(FindConVar("hostname"), STRING(buffer));
		ReplaceString(STRING(sMessage), "{SERVER_NAME}", buffer);
	}
	if (StrContains(sMessage, "{CURRENT_MAP}", false) != -1) {
		rp_GetCurrentMap(buffer);
		ReplaceString(STRING(sMessage), "{CURRENT_MAP}", buffer);
	}
	if (StrContains(sMessage, "{PLAYER_COUNT}", false) != -1) {
		IntToString(GetPlayers(false), STRING(buffer));
		ReplaceString(STRING(sMessage), "{PLAYER_COUNT}", buffer);
	}
	if (StrContains(sMessage, "{CONNECTING_PLAYERS}", false) != -1) {
		IntToString(GetPlayers(true), STRING(buffer));
		ReplaceString(STRING(sMessage), "{CONNECTING_PLAYERS}", buffer);
	}
	if (StrContains(sMessage, "{MAXPLAYERS}", false) != -1) {
		IntToString(GetMaxHumanPlayers(), STRING(buffer));
		ReplaceString(STRING(sMessage), "{MAXPLAYERS}", buffer);
	}
	if (StrContains(sMessage, "{USERID}", false) != -1) {
		IntToString(GetClientUserId(client), STRING(buffer));
		ReplaceString(STRING(sMessage), "{USERID}", buffer);
	}
	if (StrContains(sMessage, "{PLAYERNAME}", false) != -1) {
		Format(STRING(buffer), "%N", client);
		ReplaceString(STRING(sMessage), "{PLAYERNAME}", buffer);
	}
	if (StrContains(sMessage, "{STEAM32}", false) != -1) {
		GetClientAuthId(client, AuthId_Steam2, STRING(buffer));
		ReplaceString(STRING(sMessage), "{STEAM32}", buffer);
	}
	if (StrContains(sMessage, "{CONNECTION_TIME}", false) != -1) {
		Format(STRING(buffer), "%s", FormatShortTime(RoundToFloor(GetClientTime(client))));
		ReplaceString(STRING(sMessage), "{CONNECTION_TIME}", buffer);
	}
	if (StrContains(sMessage, "{CLIENT_PING}", false) != -1) {
		Format(STRING(buffer), "%d", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPing", _, client));
		ReplaceString(STRING(sMessage), "{CLIENT_PING}", buffer);
	}
	if (StrContains(sMessage, "{CURRENT_DATE}", false) != -1) {
		FormatTime(STRING(buffer), "%d.%m.%Y");
		ReplaceString(STRING(sMessage), "{CURRENT_DATE}", buffer);
	}
	if (StrContains(sMessage, "{CURRENT_TIME}", false) != -1) {
		FormatTime(STRING(buffer), "%H:%M:%S");
		ReplaceString(STRING(sMessage), "{CURRENT_TIME}", buffer);
	}
	if (StrContains(sMessage, "{NEXTMAP}", false) != -1) {
		GetNextMap(STRING(buffer));
		ReplaceString(STRING(sMessage), "{NEXTMAP}", buffer);
	}
	return sMessage;
}

void LoadConfig()
{
	char inFile[PLATFORM_MAX_PATH];
	char line[512];
	
	BuildPath(Path_SM, STRING(inFile), "configs/roleplay_status.txt");
	
	Handle file = OpenFile(inFile, "rt");
	if (file != INVALID_HANDLE)
	{
		while (!IsEndOfFile(file))
		{
			if (!ReadFileLine(file, STRING(line))) {
				break;
			}
			
			TrimString(line);
			if (strlen(line) > 0)
			{
				//if (StrContains(line, "//") != -1)
					//continue;
				
				StatusArray.PushString(line);
			}
		}
		CloseHandle(file);
	}
}

int GetPlayers(bool connecting)
{
	int players;
	LoopClients(i)
	{
		if (connecting && IsClientConnected(i) && !IsClientInGame(i))players++;
		else if (!connecting && IsClientValid(i))players++;
	}
	return players;
}

char FormatShortTime(int time) {
	char Time[12];
	int g_iHours = 0;
	int g_iMinutes = 0;
	int g_iSeconds = time;
	
	while (g_iSeconds > 3600) {
		g_iHours++;
		g_iSeconds -= 3600;
	}
	while (g_iSeconds > 60) {
		g_iMinutes++;
		g_iSeconds -= 60;
	}
	if (g_iHours >= 1)Format(STRING(Time), "%d:%d:%d", g_iHours, g_iMinutes, g_iSeconds);
	else if (g_iMinutes >= 1)Format(STRING(Time), "  %d:%d", g_iMinutes, g_iSeconds);
	else Format(STRING(Time), "   %d", g_iSeconds);
	return Time;
}

char GetServerIP() {
	char NetIP[32];
	int pieces[4];
	int longip = FindConVar("hostip").IntValue;
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	
	Format(STRING(NetIP), "%d.%d.%d.%d:%d", pieces[0], pieces[1], pieces[2], pieces[3], FindConVar("hostport").IntValue);
	return NetIP;
}

bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsClientConnected(client) || IsFakeClient(client) || IsClientSourceTV(client))
		return false;
	
	return true;
}
