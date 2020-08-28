/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://www.revolution-team.be - benitalpa1020@gmail.com
*/

//*********************************************************************
//*                       CORE MAIN VEHICLES                          *
//*********************************************************************

stock int Vehicle_GetMaxCars()
{
	int place;
	
	KeyValues kv = new KeyValues("Vehicles");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/vehicles.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/vehicles.cfg NOT FOUND");
	}	

	place = kv.GetNum("maxcars");
	
	kv.Rewind();	
	delete kv;
	
	return place;
}

stock int Vehicle_GetMaxSeats(int id)
{
	int place;
	
	KeyValues kv = new KeyValues("Vehicles");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/vehicles.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/vehicles.cfg NOT FOUND");
	}	

	char carid[16];
	IntToString(id, STRING(carid));
	
	if(kv.JumpToKey(carid))
	{	
		place = kv.GetNum("seats");
	}
	
	kv.Rewind();	
	delete kv;
	
	return place;
}

stock int Vehicle_Price(int id)
{
	int price;
	
	KeyValues kv = new KeyValues("Vehicles");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/vehicles.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/vehicles.cfg NOT FOUND");
	}	

	char carid[16];
	IntToString(id, STRING(carid));
	
	if(kv.JumpToKey(carid))
	{	
		price = kv.GetNum("price");
	}
	
	kv.Rewind();	
	delete kv;
	
	return price;
}

stock int Vehicle_GetMaxFuel(int id)
{
	int maxfuel;
	
	KeyValues kv = new KeyValues("Vehicles");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/vehicles.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/vehicles.cfg NOT FOUND");
	}	

	char carid[16];
	IntToString(id, STRING(carid));
	
	if(kv.JumpToKey(carid))
	{	
		maxfuel = kv.GetNum("maxfuel");
	}
	
	kv.Rewind();	
	delete kv;
	
	return maxfuel;
}

stock int Vehicle_GetFuelType(int id)
{
	int fueltype;
	
	KeyValues kv = new KeyValues("Vehicles");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/vehicles.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/vehicles.cfg NOT FOUND");
	}	

	char carid[16];
	IntToString(id, STRING(carid));
	
	if(kv.JumpToKey(carid))
	{	
		fueltype = kv.GetNum("fueltype");
	}
	
	kv.Rewind();	
	delete kv;
	
	return fueltype;
}

stock int Vehicle_GetName(int id, char carname[64])
{
	int fueltype;
	
	KeyValues kv = new KeyValues("Vehicles");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/vehicles.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/vehicles.cfg NOT FOUND");
	}	

	char carid[16];
	IntToString(id, STRING(carid));
	
	if(kv.JumpToKey(carid))
	{	
		kv.GetString("brand", STRING(carname));
	}
	
	kv.Rewind();	
	delete kv;
	
	return fueltype;
}

stock int GetVehicle(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hVehicle");
}	

stock int GetDriver(int ent)
{
	return GetEntPropEnt(ent, Prop_Send, "m_hPlayer");
}

stock void GetVehicleInfo(int ent = 0, char brand[64] = "", char specs[64] = "", char hp[64] = "", char nm[64] = "")
{
	char entName[128];
	Entity_GetName(ent, STRING(entName));
	
	char carinfo[4][32];
	ExplodeString(entName, "|", carinfo, 4, 32);
	
	KeyValues kv = new KeyValues("Vehicles");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/vehicles.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/vehicles.cfg NOT FOUND");
	}	

	if(kv.JumpToKey(carinfo[3]))
	{	
		kv.GetString("brand", STRING(brand));
		kv.GetString("specs", STRING(specs));
		kv.GetString("horsepower", STRING(hp));
		kv.GetString("nm", STRING(nm));
	}
	
	kv.Rewind();	
	delete kv;
}	