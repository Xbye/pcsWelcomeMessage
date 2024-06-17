#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION  "1.1"
#define DEBUG           false

#include <sourcemod>
#include <colors>

ArrayList a_FullyLoadedPlayers;

ConVar hCvar_everymap;
ConVar hCvar_lines;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Author only supports Left 4 Dead 2!");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
    name =          "Community Welcome Message",
    author =        "Xbye (SirPlease, Nolo001)",
    description =   "Displays the community welcome message.",
    version =       PLUGIN_VERSION,
    //url =         "URL"
};

public void OnPluginStart()
{
    a_FullyLoadedPlayers = new ArrayList(64);

    hCvar_everymap = 		CreateConVar("pcs_everymap", "1", "Print The Welcome Message Every Map? Otherwise, print only once on connection.", _, true, 0.0, true, 1.0);
    hCvar_lines    =        CreateConVar("pcs_lines", "2", "Print this many lines of text for the welcome message.", _, true, 0.0, true, 2.0);

    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("player_disconnect", PlayerQuit);

    LoadTranslations("pcswelcome.phrases");
    AutoExecConfig(true, "pcs.welcome");

}

public void Event_PlayerTeam(Event hEvent, const char[] eventName, bool dontBroadcast)
{
    int oldteam = hEvent.GetInt("oldteam");
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    if (client > 0 && client <= MaxClients && !IsFakeClient(client) && oldteam == 0)
    {
        #if DEBUG
            int team = hEvent.GetInt("team");
            PrintToServer("-----[%f] Fired player_team event for %N -- team: %i -- oldteam: %i", GetGameTime(), client, team, oldteam);
            //PrintToChatAll("-----[[%f] Fired player_team event for %N -- team: %i -- oldteam: %i", GetGameTime(), client, team, oldteam);
        #endif

        char clientAuth[32];
        if (!GetClientAuthId(client, AuthId_SteamID64, clientAuth, sizeof(clientAuth)))
            return;
    
        bool clientWasConnected = FindStringInArray(a_FullyLoadedPlayers, clientAuth) != -1 ? true : false;

        if (!clientWasConnected)
        {
            if (hCvar_lines.IntValue > 0)
                CPrintToChat(client, "%t", "WelcomeMsg1");

            if (hCvar_lines.IntValue > 1)
                CPrintToChat(client, "%t", "WelcomeMsg2");
            
            a_FullyLoadedPlayers.PushString(clientAuth);
        }
    }
}

public void PlayerQuit(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
    bool isBot = hEvent.GetBool("bot");

    if (isBot)
        return;

    char clientAuth[32];
    if (!GetClientAuthId(GetClientOfUserId(hEvent.GetInt("userid")), AuthId_SteamID64, clientAuth, sizeof(clientAuth)))
        return;

    int index = FindStringInArray(a_FullyLoadedPlayers, clientAuth);
    
    if (index != -1)
        a_FullyLoadedPlayers.Erase(index);
}


public void OnMapEnd()
{
    if(hCvar_everymap.BoolValue)
    {
        a_FullyLoadedPlayers.Clear();
    }
}