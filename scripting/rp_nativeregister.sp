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
#include <sdkhooks>
#include <smlib>
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/	
int data_int[MAXPLAYERS + 1][int_user_data];
int stock_item_int[stock_item_builded];
bool data_bool[MAXPLAYERS + 1][bool_user_data];
float data_float[MAXPLAYERS + 1][float_user_data];	
char data_string[MAXPLAYERS + 1][sz_user_data][PLATFORM_MAX_PATH];
int weapon_ball_type[MAXENTITIES + 1];
int event;
int vehicle_int[MAXENTITIES + 1][vehicle_data];
float vehicle_float[MAXENTITIES + 1][vehicle_data];
int appart_int[MAXAPPART + 1][appart_data];
char group_data[MAXITEMS+1][enum_group_data][128];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Native Register", 
	author = "Benito", 
	description = "Enregistreur des natives", 
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
}

public void RP_OnLicenceLoaded(bool licenceValid)
{
	if(!licenceValid)
		UnloadPlugin();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	MarkNativeAsOptional("rp_nativeregister");
	CreateNative("rp_GetClientInt", Native_GetIntData);
	CreateNative("rp_GetClientBool", Native_GetBoolData);
	CreateNative("rp_GetClientFloat", Native_GetFloatData);
	CreateNative("rp_GetClientString", Native_GetStringData);
	CreateNative("rp_GetGroupString", Native_GetGroupString);
	
	CreateNative("rp_SetClientInt", Native_SetIntData);
	CreateNative("rp_SetClientBool", Native_SetBoolData);
	CreateNative("rp_SetClientFloat", Native_SetFloatData);
	CreateNative("rp_SetClientString", Native_SetClientStringData);
	CreateNative("rp_SetGroupString", Native_SetGroupString);
	
	CreateNative("rp_SetWeaponBallType", Native_SetWeaponBallType);
	CreateNative("rp_GetWeaponBallType", Native_GetWeaponBallType);
	
	CreateNative("rp_SetEventType", Native_SetEventType);
	CreateNative("rp_GetEventType", Native_GetEventType);
	
	CreateNative("rp_SetStock", Native_SetStock);
	CreateNative("rp_GetStock", Native_GetStock);
	
	CreateNative("rp_GetVehicleInt", Native_GetVehicleInt);
	CreateNative("rp_SetVehicleInt", Native_SetVehicleInt);
	CreateNative("rp_GetVehicleFloat", Native_GetVehicleInt);
	CreateNative("rp_SetVehicleFloat", Native_SetVehicleInt);
	
	CreateNative("rp_GetAppartementInt", Native_GetAppartementInt);
	CreateNative("rp_SetAppartementInt", Native_SetAppartementInt);
}

public int Native_GetIntData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int_user_data variable = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return data_int[client][variable];
}

public int Native_GetBoolData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	bool_user_data variable = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return data_bool[client][variable];
}

public any Native_GetFloatData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	float_user_data variable = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return data_float[client][variable];
}

public int Native_GetStringData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	sz_user_data variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
	
	if(!IsClientValid(client))
		return -1;
		
	SetNativeString(3, data_string[client][variable], maxlen);
		
	return -1;
}

public int Native_SetIntData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int_user_data variable = GetNativeCell(2);
	int value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return -1;
	
	return data_int[client][variable] = value;
}

public int Native_SetBoolData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	bool_user_data variable = GetNativeCell(2);
	bool value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return -1;
		
	return data_bool[client][variable] = value;	
}

public any Native_SetFloatData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	float_user_data variable = GetNativeCell(2);
	
	char buffer[64];
	GetNativeString(3, STRING(buffer));
	float value = view_as<float>(StringToFloat(buffer));
	
	if(!IsClientValid(client))
		return -1;
	
	return data_float[client][variable] = view_as<float>(value);
}

public int Native_SetClientStringData(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	sz_user_data variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
	
	if(!IsClientValid(client))
		return -1;
			
	GetNativeString(3, data_string[client][variable], maxlen);
	return -1;
}

public int Native_SetWeaponBallType(Handle plugin, int numParams) {
	int wepID = GetNativeCell(1);
	enum_ball_type wepType = GetNativeCell(2);
	
	weapon_ball_type[wepID] = wepType;
}

public int Native_GetWeaponBallType(Handle plugin, int numParams) 
{
	int wepID = GetNativeCell(1);	

	return weapon_ball_type[wepID];
}

public int Native_SetGroupString(Handle plugin, int numParams) 
{
	int groupID = GetNativeCell(1);
	enum_group_data variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
			
	GetNativeString(3, group_data[groupID][variable], maxlen);
	return -1;
}

public int Native_GetGroupString(Handle plugin, int numParams) 
{
	int groupID = GetNativeCell(1);
	enum_group_data variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
			
	SetNativeString(3, group_data[groupID][variable], maxlen);
	return -1;
}

public int Native_SetEventType(Handle plugin, int numParams) 
{
	enum_ball_type wepType = GetNativeCell(1);
	event = wepType;
}

public int Native_GetEventType(Handle plugin, int numParams) 
{
	return event;
}

public int Native_SetStock(Handle plugin, int numParams) 
{
	stock_item_builded variable = GetNativeCell(1);
	int value = GetNativeCell(2);
	
	return stock_item_int[variable] = value;
}

public int Native_GetStock(Handle plugin, int numParams) 
{
	stock_item_builded variable = GetNativeCell(1);
	
	return stock_item_int[variable];
}

public int Native_GetVehicleInt(Handle plugin, int numParams) {
	int car = GetNativeCell(1);
	vehicle_data variable = GetNativeCell(2);
	
	if(!IsValidEntity(car))
		return -1;
		
	return vehicle_int[car][variable];	
}

public int Native_SetVehicleInt(Handle plugin, int numParams) {
	int car = GetNativeCell(1);
	vehicle_data variable = GetNativeCell(2);
	int value = GetNativeCell(3);
	
	if(!IsValidEntity(car))
		return -1;
	
	return vehicle_int[car][variable] = value;
}

public any Native_GetVehicleFloat(Handle plugin, int numParams) {
	int car = GetNativeCell(1);
	vehicle_data variable = GetNativeCell(2);
	
	if(!IsValidEntity(car))
		return -1;
		
	return vehicle_float[car][variable];
}

public any Native_SetVehicleFloat(Handle plugin, int numParams) {
	int car = GetNativeCell(1);
	vehicle_data variable = GetNativeCell(2);
	
	if(!IsValidEntity(car))
		return -1;
		
	char buffer[64];
	GetNativeString(3, STRING(buffer));
	float value = view_as<float>(StringToFloat(buffer));	
	
	return vehicle_float[car][variable] = value;
}

public int Native_GetAppartementInt(Handle plugin, int numParams) 
{
	int appid = GetNativeCell(1);
	appart_data variable = GetNativeCell(2);
		
	return appart_int[appid][variable];	
}

public int Native_SetAppartementInt(Handle plugin, int numParams) 
{
	int appid = GetNativeCell(1);
	appart_data variable = GetNativeCell(2);
	int value = GetNativeCell(3);
		
	return vehicle_int[appid][variable] = value;	
}