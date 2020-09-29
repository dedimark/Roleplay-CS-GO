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
//*                       CORE MAIN SQL                               *
//*********************************************************************

stock void SQLGROUPE_INSERT(Database db, char[] noteText, int groupeID)
{
	static char buffer[PLATFORM_MAX_PATH];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_groupes_historique` (`Id`, `note`, `timestamp`) VALUES ('%i', '%s', CURRENT_TIMESTAMP);", groupeID, noteText);
	SQL_FastQuery(db, buffer);
}

stock void UpdateSQL(Database db, const char[] format, any ...)
{
	static char buffer[PLATFORM_MAX_PATH];
	VFormat(STRING(buffer), format, 3);
	PrintToServer(buffer);
	SQL_FastQuery(db, buffer);
}

stock void UpdateSQL_Item(Database db, char[] table, char[] colonne, int valeur, char[] auth)
{
	static char buffer[PLATFORM_MAX_PATH];
	Format(STRING(buffer), "UPDATE %s SET %s = %i WHERE steamid = '%s';", table, colonne, valeur, auth);
	SQL_FastQuery(db, buffer);
}

stock void UpdateGang(Database db, char[] column, int valeur, int groupid)
{
	static char buffer[PLATFORM_MAX_PATH];
	Format(STRING(buffer), "UPDATE rp_groupes SET %s = %i WHERE Id = %i;", column, valeur, groupid);
	SQL_FastQuery(db, buffer);
}

stock void SetSQL_Int(Database db, char[] table, char[] colonne, int valeur, char[] auth)
{
	static char buffer[PLATFORM_MAX_PATH];
	Format(STRING(buffer), "UPDATE %s SET %s = %i WHERE steamid = '%s';", table, colonne, valeur, auth);
	SQL_FastQuery(db, buffer);
}

stock void Insert_rp_sell(Database db, char[] acheteur, char[] vendeur, char[] itemSelled, int prix_unite, int quantite)
{
	int seller = Client_FindBySteamId(vendeur);
	
	static char buffer[PLATFORM_MAX_PATH];
	Format(buffer, PLATFORM_MAX_PATH, "INSERT INTO `api_vente` (`Id`, `acheteur`, `vendeur`, `item`, `prix_unit`, `quantite`, `date`, `jobID`) VALUES (NULL, '%s', '%s', '%s', '%i', '%i', CURRENT_TIMESTAMP, '%i');", acheteur, vendeur, itemSelled, prix_unite, quantite, rp_GetClientInt(seller, i_Job));
	SQL_FastQuery(db, buffer);
}

stock void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}