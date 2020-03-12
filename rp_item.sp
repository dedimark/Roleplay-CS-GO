#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <roleplay>

#pragma newdecls required

GlobalForward g_OnMenuInventory;
GlobalForward g_HandleOnMenuInventory;

int item[MAXPLAYERS + 1][item_list];

public Plugin myinfo = 
{
	name = "[Roleplay] Item",
	author = "Benito",
	description = "Système d'item pour le roleplay",
	version = "1.0",
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	g_OnMenuInventory = new GlobalForward("rp_MenuInventory", ET_Event, Param_Cell, Param_Cell);
	g_HandleOnMenuInventory = new GlobalForward("rp_HandlerMenuInventory", ET_Event, Param_Cell, Param_String);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_GetClientItem", GetClientItem);
	CreateNative("rp_SetClientItem", SetClientItem);
}

public int GetClientItem(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return item[client][view_as<item_list>(variable)];
}

public int SetClientItem(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	int value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return -1;
	
	return item[client][view_as<item_list>(variable)] = value;
}

public Action rp_MenuRoleplay(int client, Menu menu)
{
	menu.AddItem("inv", "Inventaire");
}

public int rp_HandlerMenuRoleplay(int client, char[] info)
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
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	
}	

public int DoBuildInventory(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, info, sizeof(info));
		
		Call_StartForward(g_HandleOnMenuInventory);
		Call_PushCell(client);
		Call_PushString(info);
		Call_Finish();		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}