#pragma semicolon 1

#include <sourcemod>
#include <roleplay>

public Plugin myinfo = 
{
	name = "[Roleplay] Système Licence", 
	author = "", 
	description = "Licencing Server", 
	version = "1.0", 
	url = "www.revolution-asso.eu"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	/*
		@Params -> void
		
		return true or false
	*/
	CreateNative("rp_licensing_isValid", Native_isValidLicense);
}

public int Native_isValidLicense(Handle plugin, int numParams) {
	int hostIP = GetConVarInt(FindConVar("hostip")), part[4];
	
	part[0] = (hostIP >> 24) & 0x000000FF;
	part[1] = (hostIP >> 16) & 0x000000FF;
	part[2] = (hostIP >> 8) & 0x000000FF;
	part[3] = hostIP & 0x000000FF;
	
	char netIP[64];
	Format(netIP, sizeof(netIP), "%d.%d.%d.%d", part[0], part[1], part[2], part[3]);
	
	char ipDedi[32] = "145.239.205.29";
	
	if(StrEqual(netIP, ipDedi))
		return true;
	else
		return false;
}
