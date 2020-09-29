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
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
int Time[time_data];
int nightBrush = -1;
int light_spot = -1;
int entFog = -1;

/***************************************************************************************

							P L U G I N  -  I N F O

****************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Temps",
	author = "Benito",
	description = "Système de temps [Jour & Nuit]",
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
	
	RegConsoleCmd("rp_time_set", Cmd_SetTime);
}

public Action Cmd_SetTime(int client, int args)
{
	char hour1[10];
	GetCmdArg(1, STRING(hour1));
	
	char hour2[10];
	GetCmdArg(2, STRING(hour2));
	
	rp_SetTime(i_hour1, StringToInt(hour1));
	rp_SetTime(i_hour2, StringToInt(hour2));
}	

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_time` ( \
	  `hour1` int(2) NOT NULL DEFAULT '0', \
	  `hour2` int(1) NOT NULL DEFAULT '1', \
	  `day` int(2) NOT NULL DEFAULT '9', \
	  `month` int(2) NOT NULL DEFAULT '2', \
	  `year` int(4) NOT NULL DEFAULT '2020' \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("rp_GetTime", Native_GetTime);
	CreateNative("rp_SetTime", Native_SetTime);
}

public int Native_GetTime(Handle plugin, int numParams) 
{
	time_data variable = GetNativeCell(1);
	return Time[view_as<time_data>(variable)];
}

public int Native_SetTime(Handle plugin, int numParams) 
{
	time_data variable = GetNativeCell(1);
	Time[variable] = GetNativeCell(2);
}

public void OnMapEnd()
{
	SaveHeure();
}

public void OnPluginEnd()
{
	SaveHeure();
}

public void OnMapStart()
{
	CreateTimer(1.0, GetHeure);
}

SaveHeure()
{
	UpdateSQL(rp_GetDatabase(), "UPDATE rp_time SET hour1 = %i, hour2 = %i, day = %i, month = %i, year = %i;", rp_GetTime(i_hour1), rp_GetTime(i_hour2), rp_GetTime(i_day), rp_GetTime(i_month), rp_GetTime(i_year));
}

public Action GetHeure(Handle Timer) 
{
	char entClass[64], entName[64];
	for(int i = MaxClients; i <= MAXENTITIES; i++)
	{
		if(IsValidEntity(i))
		{
			Entity_GetClassName(i, STRING(entClass));
			Entity_GetName(i, STRING(entName));
			if(StrEqual(entClass, "func_brush"))
			{
				if(StrEqual(entName, "night_skybox"))
					nightBrush = i; 
			}		
			else if(StrEqual(entClass, "light_spot"))
				light_spot = i;
			else if(StrEqual(entClass, "env_fog_controller"))
				entFog = i;	
		}		
	}
	
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_time;");
	rp_GetDatabase().Query(SQLCALLBACK, buffer);
}

public void SQLCALLBACK(Database db, DBResultSet Results, const char[] error, any data) 
{	
	while (Results.FetchRow()) 
	{
		rp_SetTime(i_hour1, SQL_FetchIntByName(Results, "hour1"));
		rp_SetTime(i_hour2, SQL_FetchIntByName(Results, "hour2"));
		rp_SetTime(i_day, SQL_FetchIntByName(Results, "day"));
		rp_SetTime(i_month, SQL_FetchIntByName(Results, "month"));
		rp_SetTime(i_year, SQL_FetchIntByName(Results, "year"));
		
		CreateTimer(1.0, TimerHorloge, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TimerHorloge(Handle timer)
{
	rp_SetTime(i_minute2, rp_GetTime(i_minute2) + 1);
	if(rp_GetTime(i_minute2) > 9)
	{
		rp_SetTime(i_minute2, 0);
		rp_SetTime(i_minute1, rp_GetTime(i_minute1) + 1);
		
		if(rp_GetTime(i_minute1) > 5 && rp_GetTime(i_minute2) >= 0)
		{
			rp_SetTime(i_minute1, 0);
			rp_SetTime(i_hour2, rp_GetTime(i_hour2) + 1);
			
			if(rp_GetTime(i_hour2) > 9)
			{
				rp_SetTime(i_hour2, 0);
				rp_SetTime(i_hour1, rp_GetTime(i_hour1) + 1);
			}
		}
	}
	
	if(rp_GetTime(i_hour1) >= 2 && rp_GetTime(i_hour2) >= 4)
	{
		rp_SetTime(i_hour1, 0);
		rp_SetTime(i_hour2, 0);
		rp_SetTime(i_day, rp_GetTime(i_day) + 1);
		
		rp_GiveSalaire();
	}
	if(rp_GetTime(i_month) == 2)
	{
		if(rp_GetTime(i_day) >= 28)
		{
			rp_SetTime(i_month, rp_GetTime(i_month) + 1);
			rp_SetTime(i_day, 1);
		}
	}
	else if(rp_GetTime(i_month) == 4 || rp_GetTime(i_month) == 6 || rp_GetTime(i_month) == 9 || rp_GetTime(i_month) == 11)
	{
		if(rp_GetTime(i_day) >= 30)
		{
			rp_SetTime(i_month, rp_GetTime(i_month) + 1);
			rp_SetTime(i_day, 1);
		}
	}
	else
	{
		if(rp_GetTime(i_day) >= 31)
		{
			rp_SetTime(i_month, rp_GetTime(i_month) + 1);
			rp_SetTime(i_day, 1);
		}
	}
	if(rp_GetTime(i_month) >= 12)
	{
		rp_SetTime(i_month, 1);
		rp_SetTime(i_year, rp_GetTime(i_year) + 1);
	}
	
	if(rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) > 0 && rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) <= 7
	|| rp_GetTime(i_hour1) > 1 && rp_GetTime(i_hour2) >= 9 || rp_GetTime(i_hour1) > 1 && rp_GetTime(i_hour2) < 4
	|| rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) == 0)
	{
		AcceptEntityInput(nightBrush, "Enable");
		//SetLightStyle(0, "g");
		//AcceptEntityInput(light_spot, "Enable");
	}	
	else if(rp_GetTime(i_hour1) != 0 && rp_GetTime(i_hour2) != 0)
		AcceptEntityInput(nightBrush, "Disable");
	
	if(rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) == 4 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "200");
	else if(rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) == 5 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "120");
	else if(rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) == 6 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "50");
	else if(rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) == 7 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "10");
	else if(rp_GetTime(i_hour1) == 1 && rp_GetTime(i_hour2) == 9 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "30");
	else if(rp_GetTime(i_hour1) == 2 && rp_GetTime(i_hour2) == 0 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "80");
	else if(rp_GetTime(i_hour1) == 2 && rp_GetTime(i_hour2) == 1 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "100");
	else if(rp_GetTime(i_hour1) == 2 && rp_GetTime(i_hour2) == 2 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "150");
	else if(rp_GetTime(i_hour1) == 2 && rp_GetTime(i_hour2) == 3 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "200");
	else if(rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) == 0 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)
		DispatchKeyValue(nightBrush, "renderamt", "255");
		
	if(rp_GetTime(i_hour1) == 1 && rp_GetTime(i_hour2) == 0 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)	
	{
		SetLightStyle(0, "v");
		if (entFog != -1) 
		{
			/*DispatchKeyValue(entFog, "fogenable", "1");
			DispatchKeyValue(entFog, "spawnflags", "1");
			DispatchKeyValue(entFog, "fogblend", "0");
			DispatchKeyValue(entFog, "fogcolor", "255 255 255");
			DispatchKeyValue(entFog, "fogcolor2", "255 255 255");
			DispatchKeyValueFloat(entFog, "fogstart", 128.0);
			DispatchKeyValueFloat(entFog, "fogend", 750.0);
			DispatchKeyValueFloat(entFog, "fogmaxdensity", 0.5);
			DispatchSpawn(entFog);*/
	        
			AcceptEntityInput(entFog, "TurnOn");
		}	
	}	
	else if(rp_GetTime(i_hour1) == 1 && rp_GetTime(i_hour2) == 3 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)	
		SetLightStyle(0, "y");	
	else if(rp_GetTime(i_hour1) == 1 && rp_GetTime(i_hour2) == 7 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)	
		SetLightStyle(0, "z");		
	else if(rp_GetTime(i_hour1) == 0 && rp_GetTime(i_hour2) == 1 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)	
		SetLightStyle(0, "f");		
	else if(rp_GetTime(i_hour1) == 2 && rp_GetTime(i_hour2) == 2 && rp_GetTime(i_minute1) == 0 && rp_GetTime(i_minute2) == 0)	
		SetLightStyle(0, "h");		
}