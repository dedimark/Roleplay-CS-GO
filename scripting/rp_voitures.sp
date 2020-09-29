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
#include <multicolors>
#include <roleplay>
#include <emitsoundany>
#include <halflife>

/***************************************************************************************

							P L U G I N  -  D E F I N E S

***************************************************************************************/
#define VEHICLE_TYPE_AIRBOAT_RAYCAST	8
#define COLLISION_GROUP_PLAYER			5
#define	MAX_LIGHTS						12
#define EF_NODRAW 						32
#define SOLID_VPHYSICS 					6
#define MAX_SEATS						4
#define KLAXON 							"vehicles/mustang_horn.mp3"

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
int passagerCar[MAXENTITIES + 1];
int CarLights[MAXENTITIES + 1][MAX_LIGHTS];
int CarLightsQuantity[MAXENTITIES + 1];
int car_lights[MAXENTITIES + 1];
int Cars_Driver_Prop[MAXENTITIES + 1];
int Car_Seats[MAXENTITIES + 1][MAX_SEATS + 1];
int lastCarFromPassenger[MAXPLAYERS + 1];

bool isExitVehicleConfirm[MAXPLAYERS + 1];
bool isPoliceCar[MAXENTITIES + 1];
bool asKey[MAXPLAYERS + 1][MAXENTITIES + 1];

char steamID[MAXPLAYERS + 1][32];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/

public Plugin myinfo = 
{
	name = "[Roleplay] Voitures",
	author = "Benito",
	description = "Système de voitures",
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
		
	RegConsoleCmd("rp_voiture", Cmd_Voiture);
	AddCommandListener(Cmd_LookAtWeapon, "+lookatweapon");
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_garage` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `carID` int(3) COLLATE utf8_bin NOT NULL, \
	  `r` int(3) NOT NULL, \
	  `g` int(3) NOT NULL, \
	  `b` int(3) NOT NULL, \
	  `fuel` float(50) NOT NULL, \
	  `health` float(50) NOT NULL, \
	  `km` float(50) NOT NULL, \
	  `stat` int(1) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

/***************************************************************************************

							P L U G I N  -  N A T I V E

***************************************************************************************/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("rp_GetClientKeyVehicle", Native_GetClientKeyVehicle);
	CreateNative("rp_SetClientKeyVehicle", Native_SetClientKeyVehicle);
}

public int Native_GetClientKeyVehicle(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int entID = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return false;
		
	if(asKey[client][entID])
		return true;
		
	return false;
}

public int Native_SetClientKeyVehicle(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int entID = GetNativeCell(2);
	bool value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return false;
	
	return asKey[client][entID] = value;
}

/***************************************************************************************/

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void RP_OnPlayerSpawn(int client)
{
	isExitVehicleConfirm[client] = false;
	rp_SetClientInt(client, i_garage, 0);
}	

public void RP_OnPlayerDisconnect(int client)
{
	if(IsClientInGame(client))
	{
		int vehicle = GetVehicle(client);
		if(vehicle != -1)
			ExitVehicle(client, vehicle, true);
	}
	
	if(rp_GetClientInt(client, i_garage) > 0)
	{
		for(int i = MaxClients; i <= MAXENTITIES; i++)
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
					{
						lastCarFromPassenger[i] = ent;
						ExitVehiclePassager(i);
					}	
				}
			}
		}
	}
}

public Action RP_OnPlayerFire(int client, int target, const char[] weapon)
{
	if(IsClientValid(client))
	{
		if(GetVehicle(client) != -1)
			return Plugin_Handled;
	}	

	if(IsValidEntity(target))
	{
		char entClass[64];
		Entity_GetClassName(target, STRING(entClass));
		
		if(StrEqual(entClass, "prop_vehicle_driveable") && !StrEqual(weapon, "knife"))
		{
			if(rp_GetVehicleFloat(target, car_health) > 0.0)
			{
				rp_SetVehicleFloat(target, car_health, rp_GetVehicleInt(target, car_health) - 0.05);
			}
			else 
			{
				AcceptEntityInput(target, "KillHierarchy");
				AcceptEntityInput(target, "Kill");
			}	
		}
	}	
		
	return Plugin_Continue;
}		

public OnPreThinkPost(entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
	if(IsClientValid(client))
	{
		int buttons = GetClientButtons(client);
		int mpg = GetEntProp(entity, Prop_Data, "m_nSpeed");
		
		if(mpg > 0)
		{
			rp_SetVehicleFloat(entity, car_km, rp_GetVehicleFloat(entity, car_km) + 0.001 / mpg);	
			if (buttons & IN_FORWARD)
			{
				float substract = 0.001 / mpg;
				rp_SetVehicleFloat(entity, car_fuel, rp_GetVehicleFloat(entity, car_fuel) - substract); // accelerate
			}
			else if (buttons & IN_BACK)
			{
				float substract = 0.0005 / mpg;
				rp_SetVehicleFloat(entity, car_fuel, rp_GetVehicleFloat(entity, car_fuel) - substract); // reverse
			}
		}	
		else
		{
			rp_SetVehicleFloat(entity, car_fuel, rp_GetVehicleFloat(entity, car_fuel) - 0.00001); // idle
		}
		
		if (buttons & IN_ATTACK)
		{
			PrecacheSound(KLAXON, true);
			EmitSoundToAll(KLAXON, entity, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT);
		}
		
		if (CarLightsQuantity[entity] > 0)
		{
			int light;
			
			light = CarLights[entity][2];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "ShowSprite");
			}
			light = CarLights[entity][3];
			if (IsValidEntity(light))
			{
				AcceptEntityInput(light, "ShowSprite");
			}
			
			if (buttons & IN_JUMP)
			{	
				light = CarLights[entity][0];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "ShowSprite");
				}
				light = CarLights[entity][1];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "ShowSprite");
				}
			}
			else
			{	
				light = CarLights[entity][0];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "HideSprite");
				}
				light = CarLights[entity][1];
				if (IsValidEntity(light))
				{
					AcceptEntityInput(light, "HideSprite");
				}
			}
		}
		
		if (Cars_Driver_Prop[entity] == -1)
		{
			int prop = CreateEntityByName("prop_physics_override");
			if(IsValidEntity(prop))
			{
				char model[128];
				GetClientModel(client, STRING(model));
				DispatchKeyValue(prop, "model", model);
				DispatchKeyValue(prop, "skin","0");
				ActivateEntity(prop);
				DispatchSpawn(prop);
                            
				int enteffects = GetEntProp(prop, Prop_Send, "m_fEffects");  
				enteffects |= 1;
				enteffects |= 128;
				enteffects |= 512;
				SetEntProp(prop, Prop_Send, "m_fEffects", enteffects);  
        
				char car_ent_name[128];
				//GetTargetName(entity, STRING(car_ent_name));
				Entity_GetName(entity, STRING(car_ent_name));
        
				SetVariantString(car_ent_name);
				AcceptEntityInput(prop, "SetParent", prop, prop, 0);
				SetVariantString("vehicle_driver_eyes");
				AcceptEntityInput(prop, "SetParentAttachment", prop, prop, 0);
				Cars_Driver_Prop[entity] = prop;
			}
		}
				
		if(GetEntProp(entity, Prop_Send, "m_bEnterAnimOn") == 1)
		{
			float posY[3] = {0.0, 90.0, 0.0};
			TeleportEntity(client, NULL_VECTOR, posY, NULL_VECTOR);
			
			SetEntProp(entity, Prop_Send, "m_bEnterAnimOn", 0);
			SetEntProp(entity, Prop_Send, "m_nSequence", 0);
			
			SendConVarValue(client, FindConVar("sv_client_predict"), "0");
		}
		else
			AcceptEntityInput(entity, "TurnOn");
	}		
}

public Action RP_OnPlayerTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
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
				rp_SetVehicleFloat(inflictor, car_health, rp_GetVehicleFloat(inflictor, car_health) - damage * 1.6);
				
				if(client != driver) 
					attacker = driver;
				
				char entName[64];
				Entity_GetName(inflictor, STRING(entName));
				
				char carinfo[4][32];
				ExplodeString(entName, "|", carinfo, 4, 32);
				
				int id = StringToInt(carinfo[3]);
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_garage` SET `vie` = %f WHERE `id` = %i;", rp_GetVehicleFloat(inflictor, car_health), id);
				
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
	char strName[128], modelDir[128], scriptDir[128];
	Format(STRING(strName), "%i|%i|%i", entVehicle, matricule, carID);
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
		
		Car_Seats[entVehicle][4] = -1;		
		
		if(kv.GetNum("policeCar") == 1)
			isPoliceCar[entVehicle] = true;
		else
			isPoliceCar[entVehicle] = false;	

		rp_SetVehicleInt(entVehicle, car_horsepower, kv.GetNum("horsepower"));
		rp_SetVehicleInt(entVehicle, car_maxPassager, kv.GetNum("seats"));
		rp_SetVehicleFloat(entVehicle, car_maxFuel, kv.GetFloat("maxfuel"));
		rp_SetVehicleFloat(entVehicle, car_fuel, kv.GetFloat("maxfuel"));
		rp_SetVehicleInt(entVehicle, car_fueltype, kv.GetNum("fueltype"));
		rp_SetVehicleInt(entVehicle, car_price, kv.GetNum("price"));
		asKey[client][entVehicle] = true;
		
		PrecacheModel(modelDir);
		DispatchKeyValue(entVehicle, "model", modelDir);
		int skin = GetRandomInt(0, 5);
		char skinStr[10];
		IntToString(skin, STRING(skinStr));
		DispatchKeyValue(entVehicle, "skin", skinStr);
		DispatchKeyValue(entVehicle, "vehiclescript", scriptDir);
		DispatchKeyValue(entVehicle, "targetname", strName);
		SetEntProp(entVehicle, Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
		SetEntProp(entVehicle, Prop_Send, "m_CollisionGroup", 5);
		SetEntProp(entVehicle, Prop_Send, "m_usSolidFlags", 16);
		
		int couleur[3];
		couleur[0] = GetRandomInt(0, 255);
		couleur[1] = GetRandomInt(0, 255);
		couleur[2] = GetRandomInt(0, 255);
		SetEntityRenderColor(entVehicle, couleur[0], couleur[1], couleur[2], 255);
	
		DispatchSpawn(entVehicle);
		ActivateEntity(entVehicle);
		
		SetEntProp(entVehicle, Prop_Data, "m_nNextThinkTick", -1);
		SDKHook(entVehicle, SDKHook_Think, OnPreThinkPost);
		
		rp_SetVehicleInt(entVehicle, car_owner, client);
		rp_SetVehicleInt(entVehicle, car_donateur, client);
		rp_SetVehicleFloat(entVehicle, car_health, 100.0);
		rp_SetVehicleFloat(entVehicle, car_km, 0.0);
		
		rp_SetVehicleInt(entVehicle, car_r, couleur[0]);
		rp_SetVehicleInt(entVehicle, car_g, couleur[1]);
		rp_SetVehicleInt(entVehicle, car_b, couleur[2]);
		rp_SetVehicleInt(entVehicle, car_a, 255);	
		
		car_lights[entVehicle] = 0;
		Cars_Driver_Prop[entVehicle] = -1;
		
		char playername[MAX_NAME_LENGTH + 8];
		GetClientName(client, STRING(playername));
		char clean_playername[MAX_NAME_LENGTH * 2 + 16];
		SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
		
		char buffer[2048];
		Format(STRING(buffer), "INSERT IGNORE INTO `rp_garage` (`Id`, `steamid`, `playername`, `carID`, `r`, `g`, `b`, `fuel`, `health`, `km`, `stat`, `timestamp`) VALUES (NULL, '%s', '%s', '%i', '%i', '%i', '%i', '%f', '100.0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername, carID, couleur[0], couleur[1], couleur[2], rp_GetVehicleFloat(entVehicle, car_maxFuel));
		rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
		
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
			
		char ent_name[16], light_index[16];
		Format(ent_name, 16, "%i", entVehicle);
		Format(light_index, 16, "%iLgt", entVehicle);
		
		int particle = rp_vehicle_particle(ent_name, _, origin);
		rp_SetVehicleInt(entVehicle, car_particle, particle);
	}
	else
	{
		CPrintToChat(client, "%s %i Voiture introuvable.", TEAM, carID);
		delete kv;
		return;
	}	
	kv.Rewind();	
	delete kv;
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
	SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	
	int hud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	hud &= ~HIDEHUD_WEAPONSELECTION;
	hud &= ~HIDEHUD_CROSSHAIR;
	hud &= ~HIDEHUD_INVEHICLE;
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
	int car = lastCarFromPassenger[client];
	if(Car_Seats[car][1] == client)
		Car_Seats[car][1] = -1;
	else if(Car_Seats[car][2] == client)
		Car_Seats[car][2] = -1;
	else if(Car_Seats[car][3] == client)
		Car_Seats[car][3] = -1;
	
	AcceptEntityInput(client, "ClearParent");
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	Client_SetThirdPersonMode(client, false);
	rp_SetClientBool(client, b_isInvincible, false);	
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
		rp_SetClientBool(client, b_isInvincible, false);
	}
}

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
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
			PrintHintText(client, "Vous devez arrêter le vehicule pour sortir.");
		return Plugin_Handled;
	}
	
	if(StrEqual(class, "prop_vehicle_driveable"))
	{
		if(Distance(client, target) > 150.0)
			return Plugin_Handled;
			
		if(rp_GetVehicleFloat(target, car_health) > 0.0)
		{
			if(asKey[client][target])
			{
				AcceptEntityInput(target, "Unlock");
				AcceptEntityInput(target, "use", client);
				AcceptEntityInput(target, "Lock");
				AcceptEntityInput(target, "TurnOn");
				
				if(GetVehicle(client) != -1)
				{
					Client_SetObserverTarget(client, 0);
					Client_SetObserverMode(client, OBS_MODE_DEATHCAM, false);
					Client_SetDrawViewModel(client, false);
					
					SetVariantString("vehicle_feet_passenger0");
					AcceptEntityInput(client, "SetParentAttachment", client, client, 0);
				}
				
				if(rp_GetClientInt(client, i_Job) == 1 && isPoliceCar[target])
				{
					rp_SetClientBool(client, b_menuOpen, true);
					Menu CoffreCarPolice = new Menu(DoMenuCoffreCarPolice);
					CoffreCarPolice.SetTitle("Coffre du Police Cruiser :");
					//CoffreCarPolice.AddItem("taser", "Recharger le taser");
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
				}
			}
			else if(rp_GetClientInt(client, i_Job) == 1 && rp_GetClientInt(client, i_Grade) <= 5)
			{
				Menu GererVoiture = new Menu(DoMenuGererVoiture);
				GererVoiture.SetTitle("Géstion voiture :");
				
				char strMenu[32];
				if(IsClientValid(GetDriver(target)))
				{
					if(rp_GetClientInt(client, i_Job) < GetDriver(target))
					{
						Format(STRING(strMenu), "conducteur|%i", target);
						GererVoiture.AddItem(strMenu, "Sortir le conducteur");
						if(StrContains(name, "police") == -1)
						{
							Format(STRING(strMenu), "fourriere|%i", target);
							GererVoiture.AddItem(strMenu, "Mettre la voiture en fourrière");
						}
					}
				}
				
				GererVoiture.ExitButton = true;
				GererVoiture.Display(client, 15);
			}
			else if(IsClientValid(GetEntPropEnt(target, Prop_Send, "m_hPlayer")))
			{
				PrecacheSoundAny("doors/default_locked.wav");
				EmitSoundToClientAny(client, "doors/default_locked.wav", client, _, _, _, 0.8);
				
				int count;
				LoopClients(i)
				{
					if(passagerCar[i] == target)
						count++;
				}
				
				if(count <= rp_GetVehicleInt(target, car_maxPassager))
				{
					rp_SetClientBool(GetDriver(target), b_menuOpen, true);
					Menu mVoiture = CreateMenu(DoMenuVoiture);
					mVoiture.SetTitle("%N souhaite entrer dans votre voiture.\nL'acceptez-vous ?", client);
					char strMenu[32];
					Format(STRING(strMenu), "oui|%i", client);
					mVoiture.AddItem(strMenu, "Accepter la demande");
					Format(STRING(strMenu), "non|%i", client);
					mVoiture.AddItem(strMenu, "Refuser la demande");
					mVoiture.AddItem(strMenu, "-----------------", ITEMDRAW_DISABLED);
					mVoiture.AddItem(strMenu, "Ignorer ce joueur");
					
					mVoiture.ExitButton = true;
					mVoiture.Display(GetDriver(target), 30);
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
			if(rp_GetVehicleFloat(target, car_health) == 0.0)
				CPrintToChat(client, "%s Votre voiture est en panne, amenez-la au concessionnaire pour la réparer.", TEAM);
			else if(rp_GetVehicleFloat(target, car_fuel) == 0.0)
				CPrintToChat(client, "%s Votre voiture est sur la réserve, rendez-vous à la pompe à essence la plus prêt.", TEAM);			
			PrintHintText(client, "Cette voiture est en panne.");
		}
	}
	
	return Plugin_Continue;
}	

public Action RP_OnPlayerDuck(int client)
{
	static bool isThird[MAXPLAYERS + 1] = false;
	int voiture = GetVehicle(client);
	if(voiture != -1)
	{
		if(!isThird[client])
		{
			isThird[client] = true;
			Client_SetObserverMode(client, OBS_MODE_ROAMING, true);
			Client_SetObserverMode(client, OBS_MODE_DEATHCAM, false);
						
			char tempName[64];
			IntToString(voiture, STRING(tempName));
			SetVariantString(tempName);
			AcceptEntityInput(client, "SetParent");
			
			SetVariantString("vehicle_driver_eyes");
			AcceptEntityInput(client, "SetParentAttachment");  
		}
		else 
		{
			isThird[client] = false;
			
			char tempName[64];
			IntToString(voiture, STRING(tempName));
			SetVariantString(tempName);
			AcceptEntityInput(client, "SetParent");
			
			SetVariantString("vehicle_3rd");
			AcceptEntityInput(client, "SetParentAttachment");    
		}
	}
}	

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	int voiture = GetVehicle(client);
	if(IsValidEntity(voiture))
	{
		if(buttons & IN_FORWARD || buttons & IN_BACK)
		{
			char entClassName[64], name[128];
			Entity_GetClassName(voiture, STRING(entClassName));
			Entity_GetName(voiture, STRING(name));
			if(StrEqual(entClassName, "prop_vehicle_driveable"))
			{
				if(GetEntProp(voiture, Prop_Data, "m_nSpeed") > 0)
				{
					char carinfo[4][32];
					ExplodeString(name, "|", carinfo, 4, 32);
					
					int carID = StringToInt(carinfo[3]);
					UpdateSQL(rp_GetDatabase(), "UPDATE `rp_garage` SET `essence` = '%f', `km` = '%f', `vie` = '%f' WHERE steamid = '%s' AND carID = '%i';", rp_GetVehicleFloat(voiture, car_fuel), rp_GetVehicleFloat(voiture, car_km), rp_GetVehicleFloat(voiture, car_health), steamID[client], carID);
				}
				else if(buttons & IN_USE) 
					PrintHintText(client, "Vous devez arrêter la voiture pour sortir.");
			}
		}	
	}
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
				
				if(Car_Seats[voiture][1] == -1)
				{
					Car_Seats[voiture][1] = joueur;
					SetVariantString("vehicle_feet_passenger1");
					AcceptEntityInput(client, "SetParentAttachment", client, client, 0);
				}	
				else if(Car_Seats[voiture][2] == -1)
				{
					Car_Seats[voiture][2] = joueur;
					SetVariantString("vehicle_feet_passenger2");
					AcceptEntityInput(client, "SetParentAttachment", client, client, 0);
				}
				else if(Car_Seats[voiture][3] == -1)
				{
					Car_Seats[voiture][3] = joueur;
					SetVariantString("vehicle_feet_passenger3");
					AcceptEntityInput(client, "SetParentAttachment", client, client, 0);
				}
				
				SetEntityMoveType(joueur, MOVETYPE_NONE);
				
				Client_SetObserverTarget(joueur, voiture);
				Client_SetObserverMode(joueur, OBS_MODE_DEATHCAM, false);
				Client_SetDrawViewModel(joueur, true);
				Client_SetFOV(joueur, 120);
				
				rp_SetClientBool(joueur, b_isInvincible, true);
				SetEntProp(joueur, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
				
				passagerCar[joueur] = voiture;
			}
		}
		else if(StrEqual(buffer[0], "non"))
			CPrintToChat(joueur, "%s {grey}%N {default}a refusé de vous ouvrir sa voiture.", TEAM, client);
		else
			rp_SetClientBool(client, b_menuOpen, false);			
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

public Action Cmd_LookAtWeapon(int client, const char[] command, int argc)
{
	if ((client > 0) && (IsClientInGame(client)))
	{
		if (IsPlayerAlive(client))
		{
			int voiture = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
			if (voiture != -1)
			{
				LightToggle(client);
			}
		}
	}
}

public void LightToggle(int client)
{
	int voiture = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	
	AcceptEntityInput(CarLights[voiture][6], "Toggle");
	AcceptEntityInput(CarLights[voiture][7], "Toggle");
	
	AcceptEntityInput(CarLights[voiture][0], "ToggleSprite");
	AcceptEntityInput(CarLights[voiture][1], "ToggleSprite");
	AcceptEntityInput(CarLights[voiture][2], "ToggleSprite");
	AcceptEntityInput(CarLights[voiture][3], "ToggleSprite");
	AcceptEntityInput(CarLights[voiture][4], "ToggleSprite");
	AcceptEntityInput(CarLights[voiture][5], "ToggleSprite");
	
	// Lightswitch Noise
	EmitSoundToAll("buttons/lightswitch2.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
}

public int DoMenuCoffreCarPolice(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "kevlar"))
		{
			Client_SetArmor(client, 150);
			CPrintToChat(client, "%s Vous avez récupéré un gilet pare-balles.", TEAM);
		}
		/*else if(StrEqual(info, "taser"))
		{
			hasTaser[client] = true;
			PrintHintText(client, "Taser rechargé !");
		}*/
		else
		{
			char buffer[2][64];
			ExplodeString(info, "|", buffer, 2, 64);
			int slot = StringToInt(buffer[0]);
			if(slot != 7)
			{
				if(GetPlayerWeaponSlot(client, slot) == -1)
				{
					char strFormat[64];
					if(StrContains(info, "silencer") != -1)
						Format(strFormat, sizeof(strFormat), "silencer|police|%s", steamID[client]);
					else
						Format(strFormat, sizeof(strFormat), "police|%s", steamID[client]);
					
					int weapon = GivePlayerItem(client, buffer[1]);
					SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
					ChangeEdictState(client, FindDataMapInfo(client, "m_hActiveWeapon"));
					Entity_SetName(weapon, strFormat);
				}
				else if(slot == 1)
					CPrintToChat(client, "%s Vous possédez déjà une arme de poing.", TEAM);
				else
					CPrintToChat(client, "%s Vous possédez déjà une arme lourde.", TEAM);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuGererVoiture(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[2][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2 , 32);
		// buffer[0] : choix
		int voiture = StringToInt(buffer[1]);
		
		if(IsValidEntity(voiture))
		{
			int driver = GetDriver(voiture);
			if(StrEqual(buffer[0], "conducteur"))
			{
				if(IsClientValid(driver))
				{
					ExitVehicle(driver, voiture, true);
					CPrintToChat(driver, "%s Vous avez été sorti de votre véhicule par {blue}%N{default}.", TEAM, client);
					CPrintToChat(client, "%s Vous avez été sorti {red}%N {default}du véhicule.", TEAM, driver);
				}
			}
			else if(StrEqual(buffer[0], "fourriere"))
			{
				if(IsClientValid(driver))
				{
					ExitVehicle(driver, voiture, true);
					
					char entName[64], buffer2[3][64];
					Entity_GetName(voiture, STRING(entName));
					ExplodeString(entName, "|", buffer2, 3, 64);
				
					int carID = StringToInt(buffer2[2]);						
					AcceptEntityInput(voiture, "Kill");				
					UpdateSQL(rp_GetDatabase(), "UPDATE `rp_garage` SET `stat` = '1' WHERE steamid = '%s' AND carID = '%i';", steamID[client], carID);
				}
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}