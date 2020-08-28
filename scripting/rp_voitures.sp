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
#include <multicolors>
#include <roleplay>
#include <emitsoundany>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  D E F I N E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#define MAXENTITIES 2048

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
bool isExitVehicleConfirm[MAXPLAYERS + 1];

int passagerCar[MAXPLAYERS + 1];

float curIAng[MAXPLAYERS + 1][3];

char steamID[MAXPLAYERS + 1][32];
char dbconfig[] = "roleplay";

Database g_DB;

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/

public Plugin myinfo = 
{
	name = "[Roleplay] Voitures",
	author = "Benito",
	description = "Système de voitures",
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
		RegConsoleCmd("rp_voiture", Cmd_Voiture);
		RegConsoleCmd("startcar", DemarrageMoteur);
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("DatabaseError", error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		char buffer[4096];
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_garage` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `carID` int(3) COLLATE utf8_bin NOT NULL, \
		  `r` int(3) NOT NULL, \
		  `g` int(3) NOT NULL, \
		  `b` int(3) NOT NULL, \
		  `fuel` int(3) NOT NULL, \
		  `health` int(10) NOT NULL, \
		  `km` int(9) NOT NULL, \
		  `stat` int(1) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}	
}

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  N A T I V E

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void rp_OnClientSpawn(int client)
{
	isExitVehicleConfirm[client] = false;
	rp_SetClientInt(client, i_garage, 0);
}	

public void rp_OnClientDisconnect(int client)
{
	if(IsClientInGame(client))
	{
		int vehicle = GetVehicle(client);
		if(vehicle != -1)
			ExitVehicle(client, vehicle, true);
	}
	
	if(rp_GetClientInt(client, i_garage) > 0)
	{
		for(new i = MaxClients; i <= MAXENTITIES; i++)
		{
			if(IsValidEntity(i))
			{
				char entClass[64], entName[64];
				Entity_GetClassName(i, STRING(entClass));
				
				if(StrEqual(entClass, "prop_vehicle_driveable"))
				{
					Entity_GetName(i, entName, sizeof(entName));
					if(StrContains(entName, steamID[client]) != -1)
					{
						AcceptEntityInput(i, "TurnOff");
						AcceptEntityInput(i, "ClearParent");
						AcceptEntityInput(i, "Kill");
					}
				}
			}
		}
	}
}	

public void OnEntityDestroyed(int ent)
{ 
	if(IsValidEntity(ent))
	{
		char entClass[64];
		Entity_GetClassName(ent, STRING(entClass));
		
		if(StrEqual(entClass, "prop_vehicle_driveable"))
		{
			int driver = GetDriver(ent);
			if(IsClientValid(driver))
				ExitVehicle(driver, ent, true);
			
			for(int i = 1; i <= MAXENTITIES; i++)
			{
				if(IsClientValid(i))
				{
					if(passagerCar[i] == ent)
						ExitVehiclePassager(i);
				}
			}
			
			LoopClients(i)
				if(IsPlayerAlive(i)) 
					TeleportEntity(i, NULL_VECTOR, curIAng[i], NULL_VECTOR);
		}
	}
}

public Action rp_OnWeaponFire(int client, int aim, const char[] weaponName)
{
	if(IsClientValid(client))
	{
		if(GetVehicle(client) != -1)
			return Plugin_Handled;
	}		
		
	return Plugin_Continue;
}		

public OnPreThinkPost(entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
	if(IsClientValid(client))
	{
		
		static wasInVehicle[MAXPLAYERS + 1];
		int voiture = GetVehicle(client);
		if(voiture == -1)
		{
			if(wasInVehicle[client] != 0)
			{
				if(IsValidEntity(wasInVehicle[client]))
					SendConVarValue(client, FindConVar("sv_client_predict"), "1");
				wasInVehicle[client] = 0;
			}
			return;
		}
		else
		{
			/*int prop = CreateEntityByName("prop_physics_override");
			if (IsValidEntity(prop))
			{
				char model[128];
				GetClientModel(client, STRING(model));
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "skin", "1");
				
				ActivateEntity(prop);
				DispatchSpawn(prop);
				
				int enteffects = GetEntProp(client, Prop_Send, "m_fEffects");
				enteffects &= ~32; // make player visible
				enteffects |= 1; // for bonemerge
				enteffects |= 128; // for bonemerge
				SetEntProp(client, Prop_Send, "m_fEffects", enteffects);
				
				SetEntProp(prop, Prop_Send, "m_fEffects", enteffects);
				
				char car_ent_name[128];
				Entity_GetName(entity, STRING(car_ent_name));
				
				SetVariantString(car_ent_name);
				AcceptEntityInput(prop, "SetParent", prop, prop, 0);
				SetVariantString("vehicle_driver_eyes");
				AcceptEntityInput(prop, "SetParentAttachment", prop, prop, 0);
			}*/
			
			int enteffects = GetEntProp(client, Prop_Send, "m_fEffects");
			enteffects &= ~32; // make player visible
			enteffects |= 1; // for bonemerge
			enteffects |= 128; // for bonemerge
			SetEntProp(client, Prop_Send, "m_fEffects", enteffects);
		}
				
		if(GetEntProp(voiture, Prop_Send, "m_bEnterAnimOn") == 1)
		{
			wasInVehicle[client] = voiture;
			
			float posY[3] = {0.0, 90.0, 0.0};
			TeleportEntity(client, NULL_VECTOR, posY, NULL_VECTOR);
			
			SetEntProp(voiture, Prop_Send, "m_bEnterAnimOn", 0);
			SetEntProp(voiture, Prop_Send, "m_nSequence", 0);
			//SetEntProp(voiture, Prop_Send, "m_flTurnOffKeepUpright", 0.0); // fait bug la vue
			
			LoopClients(i)
			{
				if(IsPlayerAlive(i))
				{
					if(i != client)
						TeleportEntity(i, NULL_VECTOR, curIAng[i], NULL_VECTOR);
				}
			}
			
			SendConVarValue(client, FindConVar("sv_client_predict"), "0");
		}
		else
			AcceptEntityInput(voiture, "TurnOn");
	}		
}

public Action rp_OnClientTakeDamage(int client, int attacker, int inflictor, float damage, int damagetype, const char[] weapon)
{
	if(isExitVehicleConfirm[client])
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	if(damagetype & DMG_VEHICLE)
	{
		char entClass[64];
		Entity_GetClassName(inflictor, STRING(entClass));
		
		if(StrEqual(entClass, "prop_vehicle_driveable"))
		{
			int driver = GetDriver(inflictor);
			if(IsClientValid(driver))
			{
				rp_SetVehicleInt(inflictor, car_health, rp_GetVehicleInt(inflictor, car_health) - RoundToFloor(damage * 1.6));
				
				if(client != driver) 
					attacker = driver;
				
				char entName[64];
				Entity_GetName(inflictor, STRING(entName));
				
				char carinfo[4][32];
				ExplodeString(entName, "|", carinfo, 4, 32);
				
				int id = StringToInt(carinfo[3]);
				UpdateSQL(g_DB, "UPDATE rp_garage SET vie = %i WHERE id = %i;", rp_GetVehicleInt(inflictor, car_health), id);
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}	

public Action Cmd_Voiture(int client, int args)
{
	if(IsClientValid(client))
	{
		char carname[32];
		GetCmdArg(1, STRING(carname));
		
		float eyeAngles[3], origin[3], angles[3];
		GetClientEyeAngles(client, eyeAngles);
		angles[1] = eyeAngles[1] - 90.0;
		GetClientEyePosition(client, origin);
		
		int carID = StringToInt(carname);
		
		SpawnVehicle(origin, angles, client, carID);		
	}	
}

void SpawnVehicle(float origin[3], float angles[3], int client=0, int carID, int matricule=0)
{
	int entVehicle = CreateEntityByName("prop_vehicle_driveable");
	char strName[128], modelDir[64], scriptDir[64];
	Format(STRING(strName), "%i|%s|%i|%i", entVehicle, steamID[client], matricule, carID);
	Entity_SetName(entVehicle, strName);
	
	KeyValues kv = new KeyValues("Vehicles");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/vehicles.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/vehicles.cfg NOT FOUND");
	}	
	
	char kv_carid[16];
	IntToString(carID, STRING(kv_carid));
	if(kv.JumpToKey(kv_carid))
	{	
		kv.GetString("model", STRING(modelDir));
		kv.GetString("script", STRING(scriptDir));
	}
	else
	{
		CPrintToChat(client, "%s %i Voiture introuvable.", TEAM, carID);
		delete kv;
		return;
	}	
	
	kv.Rewind();	
	delete kv;
	
	PrecacheModel(modelDir);
	DispatchKeyValue(entVehicle, "model", modelDir);
	DispatchKeyValue(entVehicle, "skin", "0");
	DispatchKeyValue(entVehicle, "vehiclescript", scriptDir);
	SetEntProp(entVehicle, Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
	//SetEntityRenderColor(entVehicle, couleur[0], couleur[1], couleur[2], 255);
	SetEntProp(entVehicle, Prop_Send, "m_CollisionGroup", 5);
	SetEntProp(entVehicle, Prop_Send, "m_usSolidFlags", 16);
	DispatchSpawn(entVehicle);
	ActivateEntity(entVehicle);
	
	SetEntProp(entVehicle, Prop_Data, "m_nNextThinkTick", -1);
	SDKHook(entVehicle, SDKHook_Think, OnPreThinkPost);
	
	rp_SetVehicleInt(entVehicle, car_fueltype, Vehicle_GetFuelType(carID));
	rp_SetVehicleInt(entVehicle, car_health, 100);
	rp_SetVehicleInt(entVehicle, car_fuel, Vehicle_GetMaxFuel(carID));
	rp_SetVehicleInt(entVehicle, car_km, 0);
	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_garage` (`Id`, `steamid`, `playername`, `carID`, `r`, `g`, `b`, `fuel`, `health`, `km`, `stat`, `timestamp`) VALUES (NULL, '%s', '%s', '%i', '255', '255', '255', '%i', '100', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername, carID, Vehicle_GetMaxFuel(carID));
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	// Check espace pour spawn voiture
	float minHull[3], maxHull[3], temp;
	GetEntPropVector(entVehicle, Prop_Send, "m_vecMins", minHull);
	GetEntPropVector(entVehicle, Prop_Send, "m_vecMaxs", maxHull);
	temp = minHull[0];
	minHull[0] = minHull[1];
	minHull[1] = temp;
	temp = maxHull[0];
	maxHull[0] = maxHull[1];
	maxHull[1] = temp;
	if(client == 0)
		TR_TraceHull(origin, origin, minHull, maxHull, MASK_SOLID);
	else
		TR_TraceHullFilter(origin, origin, minHull, maxHull, MASK_SOLID, RayDontHitClient, client);
	
	if(TR_DidHit())
	{
		CPrintToChat(client, "%s La voiture n'a pas la place de sortir ici.", TEAM);
		AcceptEntityInput(entVehicle, "KillHierarchy");
		AcceptEntityInput(entVehicle, "Kill");
		return;
	}
	
	TeleportEntity(entVehicle, origin, angles, NULL_VECTOR);
}

void ExitVehicle(int client, int vehicle, bool force=false)
{
	float exitPoint[3];
	if(!force)
	{
		if(!IsExitClear(client, vehicle, 90.0, exitPoint)
		&& !IsExitClear(client, vehicle, -90.0, exitPoint)
		&& !IsExitClear(client, vehicle, 0.0, exitPoint)
		&& !IsExitClear(client, vehicle, 180.0, exitPoint))
		{
			float clientEye[3], clientMinHull[3], clientMaxHull[3],
			traceEnd[3], collisionPoint[3], vehicleEdge[3];
			
			GetClientEyePosition(client, clientEye);
			GetEntPropVector(client, Prop_Send, "m_vecMins", clientMinHull);
			GetEntPropVector(client, Prop_Send, "m_vecMaxs", clientMaxHull);
			
			traceEnd = clientEye;
			traceEnd[2] += 500.0;
			
			TR_TraceHullFilter(clientEye, traceEnd, clientMinHull, clientMaxHull, MASK_PLAYERSOLID, DontHitClientOrVehicle, client);
			
			if(TR_DidHit())
				TR_GetEndPosition(collisionPoint);
			else
				collisionPoint = traceEnd;
			
			TR_TraceHull(collisionPoint, clientEye, clientMinHull, clientMaxHull, MASK_PLAYERSOLID);
			TR_GetEndPosition(vehicleEdge);
			
			if(GetVectorDistance(vehicleEdge, collisionPoint) >= 100.0)
			{
				exitPoint = vehicleEdge;
				exitPoint[2] += 100.0;
				
				if(TR_PointOutsideWorld(exitPoint))
				{
					CPrintToChat(client, "%s Vous n'avez pas assez de place pour sortir.", TEAM);
					return;
				}
			}
			else
			{
				CPrintToChat(client, "%s Vous n'avez pas assez de place pour sortir.", TEAM);
				return;
			}
		}
	}
	else
	{
		GetClientAbsOrigin(client, exitPoint);
		exitPoint[2] += 100;
	}
	
	AcceptEntityInput(client, "ClearParent");
	SetEntPropEnt(client, Prop_Send, "m_hVehicle", -1);
	SetEntPropEnt(vehicle, Prop_Send, "m_hPlayer", -1);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
	
	int hud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	hud &= ~1;
	hud &= ~256;
	hud &= ~1024;
	SetEntProp(client, Prop_Send, "m_iHideHUD", hud);
	
	int entEffects = GetEntProp(client, Prop_Send, "m_fEffects");
	entEffects &= ~32;
	SetEntProp(client, Prop_Send, "m_fEffects", entEffects);
	SetEntProp(vehicle, Prop_Send, "m_nSpeed", 0);
	SetEntPropFloat(vehicle, Prop_Send, "m_flThrottle", 0.0);
	AcceptEntityInput(vehicle, "TurnOff");
	
	float exitAng[3];
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", exitAng);
	exitAng[0] = 0.0;
	exitAng[1] += 90.0;
	exitAng[2] = 0.0;
	TeleportEntity(client, exitPoint, exitAng, NULL_VECTOR);
	
	// Remettre arme :
	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	RemovePlayerItem(client, knife);
	AcceptEntityInput(knife, "Kill");
	knife = GivePlayerItem(client, "weapon_fists");
	EquipPlayerWeapon(client, knife);
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", knife);
	ChangeEdictState(client, FindDataMapInfo(client, "m_hActiveWeapon"));
	
	// Bug ejection
	CreateTimer(1.0, DebugExitVehicle, client);
	//CreateTimer(0.3, UnFreeze, client);
	
	Client_SetThirdPersonMode(client, false);
}

int ExitVehiclePassager(int client)
{
	AcceptEntityInput(client, "ClearParent");
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
	Client_SetThirdPersonMode(client, false);
	//isInvincible[client] = false;
	
	passagerCar[client] = 0;
}

bool IsExitClear(int client, int vehicle, float direction, float exitpoint[3])
{
	float clientEye[3], vehicleAngle[3], clientMinHull[3], clientMaxHull[3],
	directionVec[3], traceEnd[3], collisionPoint[3], vehicleEdge[3];
	
	GetClientEyePosition(client, clientEye);
	GetEntPropVector(vehicle, Prop_Data, "m_angRotation", vehicleAngle);
	GetEntPropVector(client, Prop_Send, "m_vecMins", clientMinHull);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", clientMaxHull);
	
	vehicleAngle[0] = 0.0;
	vehicleAngle[1] += direction;
	vehicleAngle[2] = 0.0;
	
	GetAngleVectors(vehicleAngle, NULL_VECTOR, directionVec, NULL_VECTOR);
	ScaleVector(directionVec, -500.0);
	AddVectors(clientEye, directionVec, traceEnd);
	TR_TraceHullFilter(clientEye, traceEnd, clientMinHull, clientMaxHull, MASK_PLAYERSOLID, DontHitClientOrVehicle, client);
	
	if(TR_DidHit())
		TR_GetEndPosition(collisionPoint);
	else
		collisionPoint = traceEnd;
	
	TR_TraceHull(collisionPoint, clientEye, clientMinHull, clientMaxHull, MASK_PLAYERSOLID);
	TR_GetEndPosition(vehicleEdge);
	
	if(GetVectorDistance(vehicleEdge, collisionPoint) >= 100.0)
	{
		MakeVectorFromPoints(vehicleEdge, collisionPoint, directionVec);
		NormalizeVector(directionVec, directionVec);
		ScaleVector(directionVec, 100.0);
		AddVectors(vehicleEdge, directionVec, exitpoint);
		
		if(TR_PointOutsideWorld(exitpoint))
			return false;
		else
			return true;
	}
	else
		return false;
}

public bool DontHitClientOrVehicle(int entity, int contentsMask, any data)
{
	return entity != data && entity != GetVehicle(data);
}	

public Action DebugExitVehicle(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		TeleportEntity(client, position, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
		//isInvincible[client] = false;
	}
}

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	int voiture = GetVehicle(client);
	if(IsValidEntity(voiture) && GetEntProp(voiture, Prop_Data, "m_nSpeed") == 0)
	{
		ExitVehicle(client, voiture);
		return Plugin_Handled;
	}
	
	if(passagerCar[client] != 0 && IsValidEntity(passagerCar[client]))
	{
		if(GetEntProp(passagerCar[client], Prop_Data, "m_nSpeed") == 0)
			ExitVehiclePassager(client);
		else 
			PrintHintText(client, "Vous devez arrêter la voiture pour sortir.");
		return Plugin_Handled;
	}
	
	if(StrEqual(entClassName, "prop_vehicle_driveable"))
	{
		if(Distance(client, aim) > 150.0)
			return Plugin_Handled;
			
		if(rp_GetVehicleInt(aim, car_health) > 0)
		{
			if(StrContains(entName, steamID[client]) != -1)
			{
				AcceptEntityInput(aim, "Unlock");
				AcceptEntityInput(aim, "use", client);
				AcceptEntityInput(aim, "Lock");
				AcceptEntityInput(aim, "TurnOn");
				
				if(GetVehicle(client) != -1)
				{
					Client_SetObserverTarget(client, 0);
					Client_SetObserverMode(client, OBS_MODE_DEATHCAM, false);
					Client_SetDrawViewModel(client, false);
				}
				
				/*if(rp_GetClientInt(client, i_Job) == 1 && StrContains(entName, "police", false) != -1)
				{
					Menu CoffreCarPolice = new Menu(DoMenuCoffreCarPolice);
					CoffreCarPolice.SetTitle("Coffre du Police Cruiser :");
					CoffreCarPolice.AddItem("taser", "Recharger le taser");
					if(rp_GetClientInt(client, i_Grade) <= 6)
					{
						CoffreCarPolice.AddItem("1|weapon_usp_silencer", "Arme : USP");
						CoffreCarPolice.AddItem("0|weapon_nova", "Arme : Nova");
					}
					if(rp_GetClientInt(client, i_Grade) <= 5)
						CoffreCarPolice.AddItem("0|weapon_ssg08", "Arme : SSG08");
					if(rp_GetClientInt(client, i_Grade) <= 4)
					{
						if(Client_GetArmor(client) < 150)
							CoffreCarPolice.AddItem("kevlar", "Gilet pare-balles");
						else CoffreCarPolice.AddItem("", "Gilet pare-balles", ITEMDRAW_DISABLED);
					}
					CoffreCarPolice.ExitButton = true;
					CoffreCarPolice.Display(client, 15);
				}*/
			}
			/*else if(rp_GetClientInt(client, i_Job) == 1 && rp_GetClientInt(client, i_Grade) <= 5)
			{
				Menu GererVoiture = new Menu(DoMenuGererVoiture);
				GererVoiture.SetTitle("Coffre du Police Cruiser :");
				
				char strMenu[32];
				if(IsClientValid(GetDriver(aim)))
				{
					if(rp_GetClientInt(client, i_Job) < GetDriver(aim))
					{
						Format(STRING(strMenu), "conducteur|%i", aim);
						GererVoiture.AddItem(strMenu, "Sortir le conducteur");
						if(StrContains(entName, "police") == -1)
						{
							Format(STRING(strMenu), "fourriere|%i", aim);
							GererVoiture.AddItem(strMenu, "Mettre la voiture en fourrière");
						}
					}
				}
				
				GererVoiture.ExitButton = true;
				GererVoiture.Display(client, 15);
			}*/
			else if(IsClientValid(GetEntPropEnt(aim, Prop_Send, "m_hPlayer")))
			{
				PrecacheSoundAny("doors/default_locked.wav");
				EmitSoundToClientAny(client, "doors/default_locked.wav", client, _, _, _, 0.8);
				
				int count;
				LoopClients(i)
				{
					if(passagerCar[i] == aim)
						count++;
				}
				
				char carinfo[4][32];
				ExplodeString(entName, "|", carinfo, 4, 32);
				
				/*
				carinfo[0] = entity
				carinfo[1] = owner steamID
				carinfo[2] = licence plate
				carinfo[3] = brand model						
				*/
				
				int carID = StringToInt(carinfo[3]);
		
				int place = Vehicle_GetMaxSeats(carID);
				if(count <= place)
				{
					Menu mVoiture = CreateMenu(DoMenuVoiture);
					mVoiture.SetTitle("%N veut rentrer dans votre voiture, accepter ?", client);
					char strMenu[32];
					Format(STRING(strMenu), "oui|%i", client);
					mVoiture.AddItem(strMenu, "Oui.");
					Format(STRING(strMenu), "non|%i", client);
					mVoiture.AddItem(strMenu, "Non.");
					
					mVoiture.ExitButton = true;
					mVoiture.Display(GetDriver(aim), 30);
				}
				else CPrintToChat(client, "%s Il n'y a plus de place dans la voiture.", TEAM);
			}
			else
			{
				PrintHintText(client, "Vous n'avez pas les clés de cette voiture.");
				PrecacheSoundAny("doors/default_locked.wav");
				EmitSoundToClientAny(client, "doors/default_locked.wav", client, _, _, _, 0.8);
			}
		}
		else
		{
			CPrintToChat(client, "%s Votre voiture est en panne, amenez-la au concessionnaire pour la réparer.", TEAM);
			PrintHintText(client, "Cette voiture est en panne.");
		}
	}
	
	return Plugin_Continue;
}	

//public Action rp_OnRunCmd(int client, int &buttons, int &impulse, int &weapon)
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	int voiture = GetVehicle(client);
	if(IsValidEntity(voiture))
	{
		if(buttons & IN_FORWARD || buttons & IN_BACK)
		{
			char entClassName[64];
			Entity_GetClassName(voiture, STRING(entClassName));
			if(StrEqual(entClassName, "prop_vehicle_driveable"))
			{
				if(GetEntProp(voiture, Prop_Data, "m_nSpeed") > 0)
				{
					rp_SetVehicleInt(voiture, car_fuel, rp_GetVehicleInt(voiture, car_fuel) - 1);
					rp_SetVehicleInt(voiture, car_km, rp_GetVehicleInt(voiture, car_km) + 1);
					
					char entName[64];
					Entity_GetName(voiture, STRING(entName));
					
					char carinfo[4][32];
					ExplodeString(entName, "|", carinfo, 4, 32);
					
					int carID = StringToInt(carinfo[3]);
					UpdateSQL(g_DB, "UPDATE rp_garage SET essence = %i, km = %i, vie = %i WHERE steamid = '%s' AND carID = %i;", rp_GetVehicleInt(voiture, car_fuel), rp_GetVehicleInt(voiture, car_km), rp_GetVehicleInt(voiture, car_health), steamID[client], carID);
				}
				else if(buttons & IN_USE) 
					PrintHintText(client, "Vous devez arrêter la voiture pour sortir.");
			}
		}
	}
	
	return Plugin_Continue;
}	

public int DoMenuVoiture(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[2][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 32);
		// buffer[0] : choix
		int joueur = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "oui"))
		{
			int voiture = GetVehicle(client);
			if(IsValidEntity(voiture))
			{
				char entName[64];
				Entity_GetName(voiture, STRING(entName));
				
				float position[3];
				GetEntPropVector(voiture, Prop_Send, "m_vecOrigin", position);
				position[2] += 160.0;
				TeleportEntity(joueur, position, NULL_VECTOR, NULL_VECTOR);
				
				SetVariantString(entName);
				AcceptEntityInput(joueur, "SetParent");
				
				//PlayerState(joueur, 1);
				SetEntityMoveType(joueur, MOVETYPE_NONE);
				
				Client_SetObserverTarget(joueur, voiture);
				Client_SetObserverMode(joueur, OBS_MODE_DEATHCAM, false);
				Client_SetDrawViewModel(joueur, true);
				Client_SetFOV(joueur, 120);
				
				SetEntPropFloat(joueur, Prop_Send, "m_flModelScale", 0.1);
				//isInvincible[joueur] = true;
				SetEntProp(joueur, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
				
				passagerCar[joueur] = voiture;
			}
		}
		else 
			CPrintToChat(joueur, "%s {grey}%N {white}a refusé de vous ouvrir sa voiture.", TEAM, client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action ExitVehicleConfirm(Handle timer, any client)
{
	if(IsClientValid(client)) 
		isExitVehicleConfirm[client] = false;
}

public Action DemarrageMoteur(client, args)
{
	if (IsClientValid(client))
	{
		int voiture = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		
		if (voiture != -1)
		{
			AcceptEntityInput(voiture, "TurnOn", -1, -1, 0);
			CPrintToChat(client, "%s : Moteur: {red}ON !", TEAM);
		}
		else
		{
			CPrintToChat(client, "%s : Vous devez être dans une voiture !", TEAM);
		}
	}
}

/*public int OnThink(int entity)
{
	int Driver = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
	
	if (0 < Driver)
	{
		int car = GetEntPropEnt(Driver, Prop_Send, "m_hVehicle");
		
		if (entity != car)
		{
			ExitVehicle(Driver, car, false);
		}
	}
	
	float ang[3];
	
	if (IsValidEntity(ViewEnt[entity]))
	{
		if (Driver > 0)
		{
			if (IsClientInGame(Driver) && IsPlayerAlive(Driver))
			{
				SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
				SetEntPropFloat(entity, Prop_Data, "m_flTurnOffKeepUpright", 1.0);
				
				SetClientViewEntity(Driver, ViewEnt[entity]);
				Driving[Driver] = true;
				
				new t = cars_type[entity];
				if (car_driver_view[t] == 1)
				{
					if (Cars_Driver_Prop[entity] == -1)
					{
						new prop = CreateEntityByName("prop_physics_override");
						if (IsValidEntity(prop))
						{
							char model[128];
							GetClientModel(Driver, model, sizeof(model));
							DispatchKeyValue(prop, "model", model);
							DispatchKeyValue(prop, "skin", "1");
							
							ActivateEntity(prop);
							DispatchSpawn(prop);
							
							new enteffects = GetEntProp(Driver, Prop_Send, "m_fEffects");
							enteffects &= ~32; // make player visible
							enteffects |= 1; // for bonemerge
							enteffects |= 128; // for bonemerge
							SetEntProp(Driver, Prop_Send, "m_fEffects", enteffects);
							
							SetEntProp(prop, Prop_Send, "m_fEffects", enteffects);
							
							char car_ent_name[128];
							GetTargetName(entity, car_ent_name, sizeof(car_ent_name));
							
							SetVariantString(car_ent_name);
							AcceptEntityInput(prop, "SetParent", prop, prop, 0);
							SetVariantString("vehicle_driver_eyes");
							AcceptEntityInput(prop, "SetParentAttachment", prop, prop, 0);
							Cars_Driver_Prop[entity] = prop;
						}
					}
				}
				new car_index = g_CarIndex[entity];
				new max = g_CarLightQuantity[car_index];
				if ((max > 0))
				{
					decl light;
					if (CarOn[entity])
					{
						light = g_CarLights[car_index][2];
						if (IsValidEntity(light))
						{
							AcceptEntityInput(light, "ShowSprite");
							if ((buttons2 & IN_BACK) && !(buttons2 & IN_JUMP))
							{
								SetVariantInt(255);
								AcceptEntityInput(light, "ColorGreenValue");
								SetVariantInt(255);
								AcceptEntityInput(light, "ColorBlueValue");
							}
							else
							{
								SetVariantInt(0);
								AcceptEntityInput(light, "ColorGreenValue");
								SetVariantInt(0);
								AcceptEntityInput(light, "ColorBlueValue");
							}
						}
						light = g_CarLights[car_index][3];
						if (IsValidEntity(light))
						{
							AcceptEntityInput(light, "ShowSprite");
							if ((buttons2 & IN_BACK) && !(buttons2 & IN_JUMP))
							{
								SetVariantInt(255);
								AcceptEntityInput(light, "ColorGreenValue");
								SetVariantInt(255);
								AcceptEntityInput(light, "ColorBlueValue");
							}
							else
							{
								SetVariantInt(0);
								AcceptEntityInput(light, "ColorGreenValue");
								SetVariantInt(0);
								AcceptEntityInput(light, "ColorBlueValue");
							}
						}
					}
					if (buttons2 & IN_JUMP)
					{
						light = g_CarLights[car_index][0];
						if (IsValidEntity(light))
						{
							AcceptEntityInput(light, "ShowSprite");
						}
						light = g_CarLights[car_index][1];
						if (IsValidEntity(light))
						{
							AcceptEntityInput(light, "ShowSprite");
						}
					}
					else
					{
						light = g_CarLights[car_index][0];
						if (IsValidEntity(light))
						{
							AcceptEntityInput(light, "HideSprite");
						}
						light = g_CarLights[car_index][1];
						if (IsValidEntity(light))
						{
							AcceptEntityInput(light, "HideSprite");
						}
					}
				}
				else Cars_Driver_Prop[entity] = -1;
			}
		}
	}
	
	if (GetEntProp(entity, Prop_Send, "m_bEnterAnimOn") == 1)
	{
		for (new players = 1; players <= MaxClients; players++)
		{
			if (IsClientInGame(players) && IsPlayerAlive(players))
			{
				if (players != Driver)
				{
					TeleportEntity(players, NULL_VECTOR, CurrentEyeAngle[players], NULL_VECTOR);
				}
			}
		}
		
		SetEntProp(entity, Prop_Send, "m_nSequence", 0);
		CarHorn[Driver] = false;
		SetEntProp(entity, Prop_Send, "m_bEnterAnimOn", 0);
		SetEntProp(entity, Prop_Send, "m_nSequence", 0);
		
		SetEntityMoveType(Driver, MOVETYPE_WALK);
		SetEntProp(Driver, Prop_Send, "m_CollisionGroup", 5, 4);
		
		char targetName[100];
		
		float sprite_rgb[3];
		sprite_rgb[0] = 0.0;
		sprite_rgb[1] = 0.0;
		sprite_rgb[2] = 0.0;
		
		GetTargetName(entity, targetName, sizeof(targetName));
		
		new sprite = CreateEntityByName("env_sprite");
		
		PrecacheModel("materials/sprites/dot.vmt", true);
		
		DispatchKeyValue(sprite, "model", "materials/sprites/dot.vmt");
		DispatchKeyValue(sprite, "renderamt", "0");
		DispatchKeyValue(sprite, "renderamt", "0");
		DispatchKeyValueVector(sprite, "rendercolor", sprite_rgb);
		
		DispatchSpawn(sprite);
		
		float vec[3];
		GetClientAbsOrigin(Driver, vec);
		GetClientAbsAngles(Driver, ang);
		
		TeleportEntity(sprite, vec, ang, NULL_VECTOR);
		
		SetClientViewEntity(Driver, sprite);
		
		SetVariantString("!activator");
		AcceptEntityInput(sprite, "SetParent", Driver);
		
		SetVariantString(targetName);
		AcceptEntityInput(Driver, "SetParent");
		
		SetVariantString("vehicle_driver_eyes");
		AcceptEntityInput(Driver, "SetParentAttachment");
		
		ViewEnt[entity] = sprite;
	}
}
*/