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
//*                       CORE MAIN METHODMAP                         *
//*********************************************************************

methodmap Player
{
	public Player(int player) {
		return view_as<Player>(player);
	}

	//=====================//
	// P R O P E R T I E S //
	//=====================//

	/**
	 * Returns the client's index.
	 *
	 * @return				Client's index.
	 */
	property int index {
		public get() {
			return view_as<int>(this);
		}
	}

	/**
	 * Retrieves the client's user id, which is an index incremented for every client
	 * that joins the server.
	 *
	 * @return				User id of the client.
	 * @error 				If the client is not connected or the index is invalid.
	 */
	property int UserId {
		public get() {
			return GetClientUserId(this.index);
		}
	}

	/**
	 * Returns the client's unique serial identifier.
	 *
	 * @return	Serial number.
	 * @error				Invalid client index, or client not connected.
	 */
	property int Serial {
		public get() {
			return GetClientSerial(this.index);
		}
	}

	/**
	 * Returns if a player is valid or not.
	 *
	 * @return				True if player is valid, false otherwise.
	 */
	property bool IsValid {
		public get() {
			return IsClientValid(this.index);
		}
	}

	/**
	 * Returns if a player is connected.
	 *
	 * @return				True if player is connected to the server, false otherwise.
	 */
	property bool IsConnected {
		public get() {
			return IsClientConnected(this.index);
		}
	}

	/**
	 * Returns if a player has entered the game.
	 *
	 * @return				True if player has entered the game, false otherwise.
	 * @error				Invalid client index.
	 */
	property bool InGame {
		public get() {
			return IsClientInGame(this.index);
		}
	}

	/**
	 * Returns if a client is timing out
	 *
	 * @return				True if client is timing out, false otherwise.
	 * @error				Invalid client index, client not connected, or fake client.
	 */
	property bool IsTimingOut {
		public get() {
			return IsClientTimingOut(this.index);
		}
	}

	/**
	 * Returns if a player is in the "kick queue" (i.e. the client will be kicked 
	 * shortly and thus they should not appear as valid).
	 *
	 * @return				True if in the kick queue, false otherwise.
	 * @error				Invalid client index.
	 */
	property bool InKickQueue {
		public get() {
			return IsClientInKickQueue(this.index);
		}
	}

	/**
	 * Returns if a player has been authenticated.
	 *
	 * @return				True if player has been authenticated, false otherwise.
	 */
	property bool IsAuthorized {
		public get() {
			return IsClientAuthorized(this.index);
		}
	}

	/**
	 * Returns if a player is a fake client.
	 *
	 * @return				True if player is a fake client, false otherwise.
	 */
	property bool IsFake {
		public get() {
			return IsFakeClient(this.index);
		}
	}

	/**
	 * Returns if a certain player is the SourceTV bot.
	 *
	 * @return				True if player is the SourceTV bot, false otherwise.
	 */
	property bool IsSourceTV {
		public get() {
			return IsClientSourceTV(this.index);
		}
	}

	/**
	 * Returns if a certain player is the Replay bot.
	 *
	 * @return				True if player is the Replay bot, false otherwise.
	 */
	property bool IsReplay {
		public get() {
			return IsClientReplay(this.index);
		}
	}

	/**
	 * Returns if a certain player is an observer/spectator.
	 *
	 * @return				True if player is an observer, false otherwise.
	 */
	property bool IsObserver {
		public get() {
			return IsClientObserver(this.index);
		}
	}

	/**
	 * Returns if the client is alive or dead.
	 *
	 * Note: This function was originally in SDKTools and was moved to core.
	 *
	 * @return				True if the client is alive, false otherwise.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property bool IsAlive {
		public get() {
			return IsPlayerAlive(this.index);
		}
	}

	/**
	 * Returns client access flags.  If the client is not an admin,
	 * the result is always 0.
	 * 
	 * @return				Flags
	 * @error				Invalid client index, or client not connected.
	 */
	property int FlagBits {
		public get() {
			return GetUserFlagBits(this.index);
		}
	}

	/**
	 * Retrieves a client's team index (and can also change the client's team).
	 *
	 * @return				Team index the client is on (mod specific).
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int Team {
		public get() {
			return GetClientTeam(this.index);
		}
		public set(int team) {
			ChangeClientTeam(this.index, team);
		}
	}

	/**
	 * Returns the client's health.
	 *
	 * @return				Health value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int Health {
		public get() {
			return GetClientHealth(this.index);
		}
	}

	/**
	 * Returns the client's death count.
	 *
	 * @return				Death count.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int Deaths {
		public get() {
			return GetClientDeaths(this.index);
		}
	}

	/**
	 * Returns the client's frag count.
	 *
	 * @return				Frag count.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int Frags {
		public get() {
			return GetClientFrags(this.index);
		}
	}

	/**
	 * Returns the client's armor.
	 *
	 * @return				Armor value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int Armor {
		public get() {
			return GetClientArmor(this.index);
		}
	}
	
	/**
	 * Returns or change the client's Admin Level.
	 *
	 * @return				adminLevel value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int AdminID {
		public get() {
			return rp_GetClientInt(this.index, i_AdminLevel);
		}
		public set(int level) {
            rp_SetClientInt(this.index, i_AdminLevel, level);
        }
	}
	
	/**
	 * Returns or change the client's Hud Statement.
	 *
	 * @return				menuOpen value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property bool menuOpen {
		public get() {
			return rp_GetClientBool(this.index, b_menuOpen);
		}
		public set(bool stat) {
            rp_SetClientBool(this.index, b_menuOpen, stat);
        }
	}
	
	/**
	 * Returns or change the client's Admin Level.
	 *
	 * @return				Armor value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int zoneID {
		public get() {
			return rp_GetClientInt(this.index, i_ByteZone);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_ByteZone, value);
        }
	}
	
	/**
	 * Returns or change the client's money.
	 *
	 * @return				money value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int money {
		public get() {
			return rp_GetClientInt(this.index, i_Money);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Money, value);
        }
	}
	
	/**
	 * Returns or change the client's bank.
	 *
	 * @return				bank value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int bank {
		public get() {
			return rp_GetClientInt(this.index, i_Bank);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Bank, value);
        }
	}
	
	/**
	 * Returns or change the client's job.
	 *
	 * @return				job value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int jobID {
		public get() {
			return rp_GetClientInt(this.index, i_Job);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Job, value);
        }
	}
	
	/**
	 * Returns or change the client's job gradeID.
	 *
	 * @return				grade value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int gradeID {
		public get() {
			return rp_GetClientInt(this.index, i_Grade);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Grade, value);
        }
	}
	
	/**
	 * Returns or change the client's gang groupe ID.
	 *
	 * @return				groupe value.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	property int gangID {
		public get() {
			return rp_GetClientInt(this.index, i_Group);
		}
		public set(int value) {
            rp_SetClientInt(this.index, i_Group, value);
        }
	}

	/**
	 * Returns the client's send data rate in bytes/sec.
	 *
	 * @return				Data rate.
	 * @error				Invalid client index, client not connected, or fake client.
	 */
	property int DataRate {
		public get() {
			return GetClientDataRate(this.index);
		}
	}

	/**
	 * Returns the client's connection time in seconds.
	 *
	 * @return				Connection time.
	 * @error				Invalid client index, client not connected, or fake client.
	 */
	property float ConnectionTime {
		public get() {
			return GetClientTime(this.index);
		}
	}

	//=====================//
	//  F U N C T I O N S  //
	//=====================//

	/**
	 * Returns the client's name.
	 *
	 * @param name			Buffer to store the client's name.
	 * @param maxlen		Maximum length of string buffer (includes NULL terminator).
	 * @return				True on success, false otherwise.
	 * @error				If the client is not connected an error will be thrown.
	 */
	public bool GetName(char[] name, int maxlen) {
		return GetClientName(this.index, name, maxlen);
	}

	/**
	 * Returns the client's Steam account ID.
	 *
	 * @param validate		Check backend validation status.
	 * 				DO NOT PASS FALSE UNLESS YOU UNDERSTAND THE CONSEQUENCES,
	 *			        You WILL KNOW if you need to use this, MOST WILL NOT.
	 * @return				Steam account ID or 0 if not available.
	 * @error				If the client is not connected or the index is invalid.
	 */
	public int GrabSteamAccountID(bool validate=true) {
		return GetSteamAccountID(this.index, validate);
	}

	/** 
	 * Sets access flags on a client using bits instead of flags.  If the
	 * client is not an admin, and flags not 0, a temporary, anonymous AdminId is given.
	 *
	 * @param flags			Bitstring of flags to set on client.
	 */
	public void SetFlagBits(int flags) {
	   SetUserFlagBits(this.index, flags);
	}

	/**
	 * Returns whether a user can target another user.
	 * This is a helper function for CanAdminTarget.
	 *
	 * @param target		Target player's index.
	 * @return				True if target is targettable by the player, false otherwise.
	 * @error				Invalid or unconnected player indexers.
	 */
	public bool CanTarget(int target) {
		return CanUserTarget(this.index, target);
	}

	/**
	 * Signals that a player has completed post-connection admin checks.
	 * Has no effect if the player has already had this event signalled.
	 *
	 * Note: This must be sent even if no admin id was assigned.
	 *
	 * @error				Invalid client index or client not in-game AND authorized.
	 */
	public void PostAdminCheck() {
		NotifyPostAdminCheck(this.index);
	}

	/**
	 * Returns the client's model name.
	 *
	 * @param model			Buffer to store the client's model name.
	 * @param maxlen		Maximum length of string buffer (includes NULL terminator).
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	public void GetModel(char[] model, int maxlen) {
		GetClientModel(this.index, model, maxlen);
	}

	/**
	 * Returns the client's weapon name.
	 *
	 * @param weapon		Buffer to store the client's weapon name.
	 * @param maxlen		Maximum length of string buffer (includes NULL terminator).
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	public void GetWeapon(char[] weapon, int maxlen) {
		GetClientWeapon(this.index, weapon, maxlen);
	}

	/**
	 * Returns the client's position angle.
	 *
	 * @param ang			Destination vector to store the client's position angle.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	public void GetAbsAngles(float ang[3]) {
	   GetClientAbsAngles(this.index, ang);
	}

	/**
	 * Returns the client's origin vector.
	 *
	 * @param vec			Destination vector to store the client's origin vector.
	 * @error				Invalid client index, client not in game, or no mod support.
	 */
	public void GetAbsOrigin(float vec[3]) {
		GetClientAbsOrigin(this.index, vec);
	}

	/**
	 * Changes a client's team through the mod's generic team changing function.
	 * On CS:S, this will kill the player.
	 *
	 * @param team			Mod-specific team index.
	 * @error				Invalid client index, client not connected, or lack of 
	 *						mod support.
	 */
	public void ChangeTeam(int team) {
		ChangeClientTeam(this.index, team);
	}

	/**
	 * Disconnects a client from the server as soon as the next frame starts.
	 *
	 * Note: Originally, KickClient() was immediate.  The delay was introduced 
	 * because despite warnings, plugins were using it in ways that would crash. 
	 * The new safe version can break cases that rely on immediate disconnects, 
	 * but ensures that plugins do not accidentally cause crashes.
	 *
	 * If you need immediate disconnects, use KickClientEx().
	 *
	 * Note: IsClientInKickQueue() will return true before the kick occurs.
	 *
	 * @param format		Optional formatting rules for disconnect reason.
	 *                      Note that a period is automatically appended to the string by the engine.
	 * @param ...			Variable number of format parameters.
	 * @error				Invalid client index, or client not connected.
	 */
	public void Kick(const char[] format="", any ...) {
		if (format[0] == '\0')
			KickClient(this.index, "No reason given");
		else {
			char message[256];
			VFormat(STRING(message), format, 3);
			KickClient(this.index, message);
		}
	}

	/**
	 * Immediately disconnects a client from the server.
	 *
	 * Kicking clients from certain events or callbacks may cause crashes.  If in 
	 * doubt, create a short (0.1 second) timer to kick the client in the next 
	 * available frame.
	 *
	 * @param format		Optional formatting rules for disconnect reason.
	 *                      Note that a period is automatically appended to the string by the engine.
	 * @param ...			Variable number of format parameters.
	 * @error				Invalid client index, or client not connected.
	 */
	public void KickEx(const char[] format="", any ...) {
		if (format[0] == '\0')
			KickClientEx(this.index, "No reason given");
		else {
			char message[256];
			VFormat(STRING(message), format, 3);
			KickClientEx(this.index, message);
		}
	}
	
	/**
	 * Print zoneText by ID.
	 */
	public void SetZoneName(char[] format) {
		rp_SetClientString(this.index, sz_Zone, format, 256);
	}	
}