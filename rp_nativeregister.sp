#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <roleplay>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[Roleplay] Native Register", 
	author = "Benito", 
	description = "Enregistreur des natives", 
	version = "1.0", 
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
		PrintToServer("Licence Valid");
	else
		UnloadPlugin();	
}	

int data_int[MAXPLAYERS + 1][int_user_data];
bool data_bool[MAXPLAYERS + 1][bool_user_data];
float data_float[MAXPLAYERS + 1][float_user_data];	
char data_string[MAXPLAYERS + 1][sz_user_data][PLATFORM_MAX_PATH];
int groupe_int[MAXPLAYERS + 1][int_groupe_data];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_GetClientInt", GetIntData);
	CreateNative("rp_GetClientBool", GetBoolData);
	CreateNative("rp_GetClientFloat", GetFloatData);
	CreateNative("rp_GetClientString", GetStringData);
	
	CreateNative("rp_SetClientInt", SetIntData);
	CreateNative("rp_SetClientBool", SetBoolData);
	CreateNative("rp_SetClientFloat", SetFloatData);
	CreateNative("rp_SetClientString", SetClientStringData);
	
	CreateNative("rp_CloseHandle", Native_AltCloseHandle);
	
	CreateNative("rp_GetGroupeInt", GetGroupeData);
	CreateNative("rp_SetGroupeInt", SetGroupeData);
}

public int GetIntData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return data_int[client][view_as<int_user_data>(variable)];
}

public int GetBoolData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return data_bool[client][view_as<bool_user_data>(variable)];
}

public int GetFloatData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	float variable = view_as<float>(GetNativeCell(2));
	
	if(!IsClientValid(client))
		return -1;
	
	return data_float[client][view_as<float_user_data>(variable)];
}

public int GetStringData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
	
	if(!IsClientValid(client))
		return -1;
		
	SetNativeString(3, data_string[client][view_as<sz_user_data>(variable)], maxlen);
		
	return -1;
}

public int SetIntData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	int value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return -1;
	
	return data_int[client][view_as<int_user_data>(variable)] = value;
}

public int SetBoolData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	bool value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return -1;
		
	return data_bool[client][view_as<bool_user_data>(variable)] = value;	
}

public int SetFloatData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	char buffer[64];
	GetNativeString(3, buffer, sizeof(buffer));
	float value = view_as<float>(StringToFloat(buffer));
	
	if(!IsClientValid(client))
		return -1;
	
	return data_float[client][view_as<float_user_data>(variable)] = value;
}

public int SetClientStringData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
	
	if(!IsClientValid(client))
		return -1;
			
	GetNativeString(3, data_string[client][view_as<sz_user_data>(variable)], maxlen);
	return -1;
}

public int Native_AltCloseHandle(Handle plugin, int numParams)
{
	Handle hndl = view_as<Handle>(GetNativeCellRef(1));
	SetNativeCellRef(1, 0);   /* Zero out the variable by reference */
	return CloseHandle(hndl);
}

public int GetGroupeData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return groupe_int[client][view_as<int_groupe_data>(variable)];
}

public int SetGroupeData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int variable = GetNativeCell(2);
	int value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return -1;
	
	return groupe_int[client][view_as<int_groupe_data>(variable)] = value;
}