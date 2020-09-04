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

#define PLUGIN_NAME "[Roleplay] Licencing Distribution"
#define PLUGIN_AUTHOR "Benito"
#define PrefixLicence "[VR-Hosting.fr]"

/***************************************************************************************

							P L U G I N  -  I N C L U D E S

***************************************************************************************/
#include <sourcemod>
#include <roleplay>
#include <multicolors>
#include <steamworks>
#include <autoexecconfig>

bool Licence = false;

ConVar cv_Token;

char g_cServerToken[128];
char g_cLicensingServer[128];

GlobalForward g_OnLicenceLoaded;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = "Licencing System", 
	version = "1.0", 
	url = "https://vr-hosting.fr/"
};


/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	GameCheck();
	rp_LoadTranslation();
	
	AutoExecConfig_SetFile("rp_licence");
	AutoExecConfig_SetCreateFile(true);
	
	cv_Token = AutoExecConfig_CreateConVar("rp_token", "ZzRPv9MvWGr46BtBo3i0v5DuVABFIBL0", "Token given with the software");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	LoadCvars();
	
	g_OnLicenceLoaded = new GlobalForward("Fwd_OnLicenceLoaded", ET_Event, Param_Cell);
}

public void OnMapStart()
{
	LoadCvars();
}

public void LoadCvars() 
{
	cv_Token.GetString(STRING(g_cServerToken));
	
	int hostIP = GetConVarInt(FindConVar("hostip")), part[4];
	int portserveur = GetConVarInt(FindConVar("hostport"));
	
	part[0] = (hostIP >> 24) & 0x000000FF;
	part[1] = (hostIP >> 16) & 0x000000FF;
	part[2] = (hostIP >> 8) & 0x000000FF;
	part[3] = hostIP & 0x000000FF;
	
	Format(STRING(g_cLicensingServer), "%i.%i.%i.%i:%i", part[0], part[1], part[2], part[3], portserveur);
	GetLicence();
}

public Action GetLicence()
{
	PrintToServer("Server: %s\n Token: %s", g_cLicensingServer, g_cServerToken);
	
	char[] sURL = "https://vr-hosting.fr/lib/licence.php";

	//Get handle
	Handle HTTPRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sURL);

	//Set timeout to 10 seconds
	bool setnetwork = SteamWorks_SetHTTPRequestNetworkActivityTimeout(HTTPRequest, 10);
    //Set a Get parameter, makes URL look like: http://localhost/web/data/licence.php?id=ZzRPv9MvWGr46BtBo3i0v5DuVABFIBL0&ip=192.168.0.1
	bool setparam = SteamWorks_SetHTTPRequestGetOrPostParameter(HTTPRequest, "id", g_cServerToken);
	bool setparam2 = SteamWorks_SetHTTPRequestGetOrPostParameter(HTTPRequest, "ip", g_cLicensingServer);
	//SteamWorks thing, set context value so we know what call we sent for the callback.
	bool setcontext = SteamWorks_SetHTTPRequestContextValue(HTTPRequest, 5);
	//Set callback function to get response data
	bool setcallback = SteamWorks_SetHTTPCallbacks(HTTPRequest, getCallback);

	if(!setnetwork || !setparam || !setparam2 || !setcontext || !setcallback) {
        PrintToServer("Error in setting request properties, cannot send request");
        CloseHandle(HTTPRequest);
        return Plugin_Handled;
    }

    //Initialize the request.
	bool sentrequest = SteamWorks_SendHTTPRequest(HTTPRequest);
	if(!sentrequest) {
		PrintToServer("Error in sending request, cannot send request");
		CloseHandle(HTTPRequest);
		return Plugin_Handled;
	}


	//Send the request to the front of the queue
	SteamWorks_PrioritizeHTTPRequest(HTTPRequest);
	return Plugin_Handled;
}

public getCallback(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any data1) 
{
    if(!bRequestSuccessful) {
        PrintToServer("There was an error in the request");
        CloseHandle(hRequest);
        return;
    }

    if(eStatusCode == k_EHTTPStatusCode200OK) {
        PrintToServer("The request returned new data, http code 200");
        CloseHandle(hRequest);
    } 
    else if(eStatusCode == k_EHTTPStatusCode304NotModified) 
    {
		PrintToServer("The request did not return new data, but did not error, http code 304");
		CloseHandle(hRequest);
		return;
    } 
    else if(eStatusCode == k_EHTTPStatusCode404NotFound) 
    {
		Licence = false;
		CreateTimer(15.0, Pub_LicenceNo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		char buffer[1024];
		Format(STRING(buffer), "@here Utilisation de la licence du script invalide.");
		
		char hostname[128];
		FindConVar("hostname").GetString(STRING(hostname));
		
		DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
		hook.SlackMode = true;	
		hook.SetUsername("Roleplay");	
		
		MessageEmbed Embed = new MessageEmbed();	
		Embed.SetColor("#00fd29");
		Embed.SetTitle(hostname);
		Embed.SetTitleLink("https://vr-hosting.fr/");
		Embed.AddField("Message", buffer, false);
		Embed.AddField("IP", g_cLicensingServer, false);
		Embed.AddField("TOKEN", g_cServerToken, false);		
		Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
		Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
		Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
		
		hook.Embed(Embed);	
		hook.Send();
		delete hook;
		

		PrintToServer("The requested URL could not be found, http code 404");
		CloseHandle(hRequest);
		return;
    } 
    else if(eStatusCode == k_EHTTPStatusCode500InternalServerError) 
    {
        PrintToServer("The requested URL had an internal error, http code 500");
        CloseHandle(hRequest);
        return;
        
    } 
    else if(eStatusCode == k_EHTTPStatusCode202Accepted)
    {
		Licence = true;
		char token[128], netIP[64];
		cv_Token.GetString(STRING(token));
		
		int hostIP = GetConVarInt(FindConVar("hostip")), part[4];
		int portserveur = GetConVarInt(FindConVar("hostport"));
			
		part[0] = (hostIP >> 24) & 0x000000FF;
		part[1] = (hostIP >> 16) & 0x000000FF;
		part[2] = (hostIP >> 8) & 0x000000FF;
		part[3] = hostIP & 0x000000FF;
			
		Format(STRING(netIP), "%i.%i.%i.%i:%i", part[0], part[1], part[2], part[3], portserveur);
		
		PrintToServer("-------------------------------------------");
		PrintToServer("----- Licensing Server: %s -----", netIP);
		PrintToServer("----- Found License: %s -----", token);
		PrintToServer("-------------------------------------------");
		PrintToServer("-------- Received License Response --------");
		PrintToServer("> Succes <");
		PrintToServer("-------------------------------------------");
		CloseHandle(hRequest);
		return;
	}
    else 
    {
		char errmessage[128];
		Format(errmessage, 128, "The requested returned with an unexpected HTTP Code %d", eStatusCode);
		PrintToServer(errmessage);
		CloseHandle(hRequest);
		return;
	}	
	
	Call_StartForward(g_OnLicenceLoaded);
	Call_PushCell(Licence);
	Call_Finish();	

	CloseHandle(hRequest);
} 

public Action Pub_LicenceNo(Handle Timer) {
	CPrintToChatAll("%s --==>>>> Licence du plugin %s (%s) créé par %s est non valable, veuillez contacter %s. <<<<==--", PrefixLicence, PLUGIN_NAME, VERSION, PLUGIN_AUTHOR, PLUGIN_AUTHOR);
}

public Action OnClientPreAdminCheck(int client)
{
	if(!Licence)
	{
		KickClient(client, "- Licence Invalide -\n Aller renouveller votre licence sur https://vr-hosting.fr/\nDiscord: https://discord.gg/JdaMCBA");
		return Plugin_Handled;
	}	
	
	return Plugin_Continue;
}	