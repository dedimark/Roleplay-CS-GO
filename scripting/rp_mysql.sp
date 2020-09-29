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
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char dbconfig[] = "";
char logFile[PLATFORM_MAX_PATH];
Database g_DB;
GlobalForward g_OnDatabaseConnected;
ConVar cv_dbconfig;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] MYSQL", 
	author = "Benito", 
	description = "Système MYSQL", 
	version = VERSION, 
	url = URL
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	cv_dbconfig = CreateConVar("rp_mysql_config", "roleplay", "Config connection located in databases.cfg");
	AutoExecConfig(true, "rp_mysql");
	
	cv_dbconfig.GetString(STRING(dbconfig));
	
	rp_LoadTranslation();
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_mysql.log");
	Database.Connect(GotDatabase, "roleplay");
	
	g_OnDatabaseConnected = new GlobalForward("RP_OnDatabaseLoaded", ET_Event, Param_Any);
}

public void RP_OnLicenceLoaded(bool licenceValid)
{
	if(!licenceValid)
		UnloadPlugin();
}	

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("SQL_DatabaseError", error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		Call_StartForward(g_OnDatabaseConnected);
		Call_PushCell(g_DB);
		Call_Finish();	
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_GetDatabase", GetDatabase);
	RegPluginLibrary("RP_MySQL");
}

public int GetDatabase(Handle plugin, int numParams) 
{
	return view_as<Database>(g_DB);
}