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

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <roleplay>

#pragma newdecls required

ConVar voice;

public Plugin myinfo = 
{
	name = "[Roleplay] Local Talk",
	author = "Benito",
	description = "",
	version = VERSION,
	url = URL
};

public void OnPluginStart()
{
	voice = CreateConVar("rp_voice_distance", "500", "Distance de voix maximale");
	AutoExecConfig(true, "rp_localtalk");
}

public void rp_OnLicenceLoaded(bool licenceValid)
{
	if(!licenceValid)
		UnloadPlugin();
}

public void OnMapStart()
{
	CreateTimer(1.0, CheckMicro, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
	rp_SetClientBool(client, b_isTeamTalking, false);
}	

public Action CheckMicro(Handle timer)
{
	float distance = GetConVarFloat(voice);
	LoopClients(sender)
	{
		if(IsClientValid(sender) && !rp_GetClientBool(sender, b_IsMuteVocal))
		{
			if(rp_GetClientInt(sender, i_timeJail) != 0)
				continue;
			if(rp_GetClientBool(sender, b_IsOnCall))	
			{
				int receiverCall = rp_GetClientInt(sender, i_PhoneCallReceiver);
				if(IsClientValid(receiverCall))
					SetListenOverride(receiverCall, sender, Listen_Yes);
				continue;
			}
				
			LoopClients(receiver)
			{
				if(IsClientValid(receiver))
				{						
					if(Distance(sender, receiver) <= distance)
						SetListenOverride(receiver, sender, Listen_Yes);
					else
						SetListenOverride(receiver, sender, Listen_No);	
				}
			}
		}
	}
}