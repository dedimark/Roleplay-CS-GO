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

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  D E F I N E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#define MAXITEMS	512

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
GlobalForward g_OnMenuInventory;
GlobalForward g_HandleOnMenuInventory;

int item[MAXPLAYERS + 1][item_list];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Item",
	author = "Benito",
	description = "Système d'item pour le roleplay",
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
		g_OnMenuInventory = new GlobalForward("rp_MenuInventory", ET_Event, Param_Cell, Param_Cell);
		g_HandleOnMenuInventory = new GlobalForward("rp_HandlerMenuInventory", ET_Event, Param_Cell, Param_String);
		RegConsoleCmd("allitem", Cmd_GiveItems);
	}
	else
		UnloadPlugin();
}

public Action Cmd_GiveItems(int client, int args)
{
	if(IsBenito(client) && IsClientValid(client))
	{
		for(int i = 1; i <= MAXITEMS; i++)
			item[client][i] += 10;
	}	
}	

public void rp_OnClientSpawn(int client)
{
	rp_SetClientBool(client, b_canItem, true);
}	

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("rp_GetClientItem", GetClientItem);
	CreateNative("rp_SetClientItem", SetClientItem);
}

public int GetClientItem(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return item[client][view_as<item_list>(variable)];
}

public int SetClientItem(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	int value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return -1;
	
	return item[client][view_as<item_list>(variable)] = value;
}

public Action rp_MenuRoleplay(int client, Menu menu)
{
	if(rp_GetClientBool(client, b_canItem))
		menu.AddItem("inv", "Inventaire");
	else
		menu.AddItem("", "Inventaire", ITEMDRAW_DISABLED);	
}

public int rp_HandlerMenuRoleplay(int client, const char[] info)
{
	if(StrEqual(info, "inv"))
		BuildInventory(client);
}	

int BuildInventory(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);	
	Menu menu = new Menu(DoBuildInventory);	
	menu.SetTitle("Mon inventaire :");	
	Call_StartForward(g_OnMenuInventory);
	Call_PushCell(client);
	Call_PushCell(menu);
	Call_Finish();	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	
}	

public int DoBuildInventory(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		Call_StartForward(g_HandleOnMenuInventory);
		Call_PushCell(client);
		Call_PushString(info);
		Call_Finish();		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			FakeClientCommand(client, "rp");
	}
	else if(action == MenuAction_End)
		delete menu;
}