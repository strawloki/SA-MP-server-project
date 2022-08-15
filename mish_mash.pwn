// This is a comment
// uncomment the line below if you want to write a filterscript
//#define FILTERSCRIPT

#include <a_samp>
#include <sscanf2>
#include <YSI\y_ini>
#include <izcmd>

#define COLOR_JOBBLUE 0x3399FFFF
#define WHITE 0xFFFFFFFF
#define RED 0xbf0f0fFF
#define LBROWN 0x826b06FF
#define GREEN 0x7FFF00FF
#define LRED 0xFF4500FF
#define LBLUE 0xADD8E6FF
#define COLOR_POL 0x000099FF
#define COLOR_TAXI 0xFFCC00FF
#define YELLOW 0xFFFF00FF
#define DARK_GREY 0x708090FF
#define COLOR_FACT_ENROLL 0x9acd32FF
#define COLOR_TAXI 0xFFCC00FF
#define COLOR_VLBLUE 0x3399FFFF
#define GRAY 0x545859FF
#define DARK_BLUE 0x473d49FF
#define TEST_COL 0xf9f504FF


#define DIALOG_REGISTER 1
#define DIALOG_LOGIN 2
#define DIALOG_SUCCESS_1 3
#define DIALOG_SUCCESS_2 4
#define DIALOG_JAILTIME 5
#define DIALOG_POL_SANCTION 6
#define DIALOG_CPS_TEAM 7
#define PATH "/Users/%s.ini"


#define FACTION_CIVILIAN 0
#define FACTION_LSPD 1
#define FACTION_SFPD 2
#define FACTION_LVPD 3
#define FACTION_TAXI 4

#define VW_CPS 7533


new bool:copDeliverToLS[MAX_PLAYERS], bool:copDeliverToSF[MAX_PLAYERS], bool:copDeliverToLV[MAX_PLAYERS], playerJailTime[MAX_PLAYERS];
new gToSanction[MAX_PLAYERS] = -1;
new bool:gIsLookingForTaxi[MAX_PLAYERS] = false;
new bool:gOnFare[MAX_PLAYERS] = false;
new gTaxiDriverTimerID[MAX_PLAYERS];
new bool:workLocCP[MAX_PLAYERS];
new bool:onGamemode[MAX_PLAYERS];
new bool:gOnCPSLobby[MAX_PLAYERS];
new gCPSLobbyCount;
new bool:gPlayerVotedToStart[MAX_PLAYERS], bool:gCopCPtoBank[MAX_PLAYERS], gRobCPtoDropoff[MAX_PLAYERS];
new gPlayersVotedToStart;
new gCPSPlayerTeam[MAX_PLAYERS] = -1; //0 = cops, 1 = robbers, -1 default
new gCPSCopsCount, gCPSRobbersCount, gCPSRobbersInCP, bool:firstRobber[MAX_PLAYERS], gCPSLiveCops, gCPSLiveRobbers;
new gCPScars[100];
new gCPSskin[MAX_PLAYERS], Float:gCPShealth[MAX_PLAYERS], Float:gCPSarmour[MAX_PLAYERS];
new gPlayerTestSkin[MAX_PLAYERS];


//Drug dealer Variables

new bool:gDrugDealerToCarCP[MAX_PLAYERS];
new bool:gDrugDealerToDestCP[MAX_PLAYERS];
new gDrugDealerLScarID = -1;
new gDrugRowID = -1;
new gOfferDrugID[MAX_PLAYERS], gPlayerOfferAmount[MAX_PLAYERS], gPlayerOfferCost[MAX_PLAYERS];
new bool:gHasPendingOffer[MAX_PLAYERS];
//drug, amount, cost

//-------------------------------------PLAYER INFO ENUM & LOADING SYSTEM RELATED----------------------------------------------------------------
enum pInfo
{
    pPass,
    pCash,
    pAdmin,
    pKills,
    pDeaths,
    pFaction,
    pFactionRank,
    pPoliceArrests,
    pJob,
    pJailTime,
    pDrugDealerLSdelivs,
    pMarijuanaAmount,
    pCocaineAmount,
    pEcstacyAmount,
    pMethAmount,
    pKrokodilAmount,
    pCrackAmount,
    pDrugSupplierCool,
    pDrugAddiction
}
new PlayerInfo[MAX_PLAYERS][pInfo];


forward LoadUser_data(playerid,name[],value[]);
public LoadUser_data(playerid,name[],value[])
{
    INI_Int("Password",PlayerInfo[playerid][pPass]);
    INI_Int("Cash",PlayerInfo[playerid][pCash]);
    INI_Int("Admin",PlayerInfo[playerid][pAdmin]);
    INI_Int("Kills",PlayerInfo[playerid][pKills]);
    INI_Int("Deaths",PlayerInfo[playerid][pDeaths]);
    INI_Int("Faction", PlayerInfo[playerid][pFaction]);
    INI_Int("FactionRank", PlayerInfo[playerid][pFactionRank]);
    INI_Int("Police_Arrests", PlayerInfo[playerid][pPoliceArrests]);
    INI_Int("Job", PlayerInfo[playerid][pJob]);
    INI_Int("Jail_time", PlayerInfo[playerid][pJailTime]);
    INI_Int("DrugDealerLS_delivs", PlayerInfo[playerid][pDrugDealerLSdelivs]);
    INI_Int("Marijuana_amount", PlayerInfo[playerid][pMarijuanaAmount]);
    INI_Int("Cocaine_amount", PlayerInfo[playerid][pCocaineAmount]);
    INI_Int("Ecstacy_amount", PlayerInfo[playerid][pEcstacyAmount]);
    INI_Int("Meth_amount", PlayerInfo[playerid][pMethAmount]);
    INI_Int("Krokodil_amount", PlayerInfo[playerid][pKrokodilAmount]);
    INI_Int("Crack_amount", PlayerInfo[playerid][pCrackAmount]);
    INI_Int("Supplier_cooldown", PlayerInfo[playerid][pDrugSupplierCool]);
    INI_Int("PlayerDrugAddiction", PlayerInfo[playerid][pDrugAddiction]);
    return 1;
}

stock UserPath(playerid)
{
    new string[128],playername[MAX_PLAYER_NAME];
    GetPlayerName(playerid,playername,sizeof(playername));
    format(string,sizeof(string),PATH,playername);
    return string;
}

stock udb_hash(buf[]) {
    new length=strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n=0; n<length; n++)
    {
       s1 = (s1 + buf[n]) % 65521;
       s2 = (s2 + s1)     % 65521;
    }
    return (s2 << 16) + s1;
}



//------------------------------------------GENERAL JOB RELATED-------------------------------------------------------------------------

new bool:OnJob[MAX_PLAYERS];
enum Jobs
{
	JOB_UNEMPLOYED,
	JOB_DRUGDEALER = 1
}

new playerJob[Jobs];



//-----------------------------------------------------------------------------------------------------------------------------

//-----------------------------------------COPS AND ROBBERS RELATED------------------------------------------------------------

GetPlayerCPSTeam(player)
{
	return gCPSPlayerTeam[player];
}
forward ReleaseRobbers();
public ReleaseRobbers()
{
	for(new k = 0; k <= MAX_PLAYERS; k++)
	{
		if(!IsPlayerConnected(k)) continue;
		
		if(onGamemode[k])
		{
		    SendClientMessage(k, WHITE, "ReleaseRobbers reached. timer is done"); //DEBUG
		    if(GetPlayerCPSTeam(k) == 1)
		    {
		        SetPlayerPos(k, 1456.9622,-1009.9428,26.8438);
				SetPlayerInterior(k, 0);
				SetPlayerVirtualWorld(k, VW_CPS);
		        SendClientMessage(k, LBROWN, "You are now outside! Get to Ocean Docks as a whole to recieve your payment!");
		        SetPlayerCheckpoint(k, 2795.8799,-2529.8679,13.6291, 4.0);
		        gRobCPtoDropoff[k] = true;
		        
		    }
		    else if(GetPlayerCPSTeam(k) == 0)
		    {
		        SendMessageToCPS("The robbers are out of the bank! Get them!", 0, LBROWN);
		        DisablePlayerCheckpoint(k);

		    }
		    
		    //also send message to cops
		    else continue;
		}
	}
	
	return 1;
}


forward LoadCPScars();
public LoadCPScars()
{


	gCPScars[0] = CreateVehicle(596, 1574.2417, -1710.2268, 5.6122, 0, -1, -1, -1); //LSPD cruiser 01
	gCPScars[1] = CreateVehicle(596, 1578.2881,-1710.5026,5.6118, 0, -1, -1, -1); //2
	gCPScars[2] = CreateVehicle(596, 1583.3069,-1710.7852,5.6122, 0, -1, -1, -1); //3
	gCPScars[3] =  CreateVehicle(596, 1587.4552,-1710.2450,5.6117, 0, -1, -1, -1); //4
	gCPScars[4] =  CreateVehicle(523, 1569.9818,-1710.6219,5.4613, 0, -1, -1, -1); //HPV-100 1
	gCPScars[5] =  CreateVehicle(523, 1566.8430,-1710.2568,5.4555, 0, -1, -1, -1); //2
	gCPScars[6] =  CreateVehicle(523, 1563.6534,-1710.2148,5.4614, 0, -1, -1, -1); //3
	gCPScars[7] =  CreateVehicle(523, 1560.5071,-1710.0652,5.4616, 0, -1, -1, -1); //4
	gCPScars[8] =  CreateVehicle(497, 1569.4172,-1641.6417,28.5800, 0, -1, -1, -1); //LSPD heli
	gCPScars[9] =  CreateVehicle(427, 1559.4506,-1696.1320,6.0229, 133.8910, -1, -1, -1);  //Enforcer 1
	gCPScars[10] = CreateVehicle(427, 1571.6390,-1694.2380,6.0225, 179.0, -1, -1, -1);  //2
	gCPScars[11] =  CreateVehicle(601, 1600.6863,-1710.0192,5.6494, 0, -1, -1, -1); //SWAT 1
	gCPScars[12] = CreateVehicle(405, 1461.2388,-1039.1923,23.6112, 270.0, -1, -1, -1); //Sentinel
	gCPScars[13] = CreateVehicle(482, 1472.2046,-1028.7682,23.8600, 270.0, -1, -1, -1); //Burrito
	gCPScars[14] = CreateVehicle(468, 1500.1842,-1021.0579,23.4973, 95.9, -1, -1, -1); //Sanchez
	gCPScars[15] = CreateVehicle(521, 1098.3809,-1775.5804,12.9106, 90.0, -1, -1, -1); //fcr-900
	gCPScars[16] = CreateVehicle(560, 1062.5562,-1757.8948,13.1215, 270.0, -1, -1, -1); //Sultan
    gCPScars[17] = CreateVehicle(401, 1630.1322,-1107.6489,23.6853, 270.0, -1, -1, -1); //Bravura
	gCPScars[18] = CreateVehicle(402, 1078.0110,-1754.9359,13.2261, 270.0, -1, -1, -1); //Buffalo
	gCPScars[19] = CreateVehicle(405, 1099.0432,-1769.8618,13.2218, 270.0, -1, -1, -1); //Sentinel
	gCPScars[20] = CreateVehicle(422, 1620.9915,-1098.6835,23.8914, 270.0, -1, -1, -1); //Bobcat
	gCPScars[21] = CreateVehicle(424, 1648.1508,-1135.8783,23.6877, 270.0, -1, -1, -1); //Bf-inj
	gCPScars[22] = CreateVehicle(458, 1629.4270,-1089.1115,23.7848, 270.0, -1, -1, -1); //Solair
	gCPScars[23] = CreateVehicle(415, 2094.7109,-1982.9490,13.3175, 360.0, -1, -1, -1); //Cheetah
	gCPScars[24] = CreateVehicle(412, 2231.1963,-1994.7498,13.3846, 0, -1, -1, -1); //Voodoo
	gCPScars[25] = CreateVehicle(492, 2230.3628,-1753.0978,13.1723, 360.0, -1, -1, -1); //Greenwood
	gCPScars[26] = CreateVehicle(400, 1084.2764,-1775.4249,13.4371, 270.0, -1, -1, -1); //Landstalker
	gCPScars[27] = CreateVehicle(561, 1098.6614,-1763.6830,13.1639, 270.0, -1, -1, -1); //Stratum

	
    for(new veh = 0; veh <= sizeof(gCPScars); veh++)
	{
	    SetVehicleVirtualWorld(gCPScars[veh], VW_CPS);
	}


	return 1;
}

stock SendMessageToCPS(message[128], team, colour)
{
	
	switch(team)
	{
	    case 0: //cops
	    {

			new string[128];
			format(string, 128, "%s", message);
			for(new cop = 0; cop <= MAX_PLAYERS; cop++)
			{
				if(!onGamemode[cop]) continue;
			
				if(GetPlayerCPSTeam(cop) == 0)
				{
			 	   SendClientMessage(cop, colour, string);
			 	   return 1;
				}
			}
		}
	
		case 1: //robbers
		{

		
	    	new string[128];
	    	format(string, 128, "%s", message);
	    
	    	for(new rob = 0; rob <= MAX_PLAYERS; rob++)
  			{
   				if(!onGamemode[rob]) continue;

				if(GetPlayerCPSTeam(rob) == 1)
				{
				    SendClientMessage(rob, colour, string);
				    return 1;
				}
			}
		}
		case 2: //both
		{
		    new string[128];
			format(string, 128, "%s", message);
			
			for(new all = 0; all <= MAX_PLAYERS; all++)
			{
				if(onGamemode[all])
				{
					SendClientMessage(all, colour, string);
					return 1;
				}
			}
		}
		

	}
	return 1;
}

PickSkinCPS(teamid)
{
    new copSkins[8] =
	{
		280,
		281,
		282,
		284,
		285,
		265,
		266,
		267

	};

	new robberSkins[9] =
	{
		19,
		21,
		22,
		23,
		28,
		29,
		30,
		136,
		137
	};

	new skinid, slot;
	switch(teamid)
	{
	    case 0: //cops
	    {
	        slot = random(sizeof(copSkins));
	        skinid = copSkins[slot];
	    }
	    case 1: //robbers
	    {
	        slot = random(sizeof(robberSkins));
	        skinid = robberSkins[slot];
	    
	    }
	    default:
		{
			skinid = 0;
		}
	}
	return skinid;
}

stock DestroyCPScars()
{
    for(new car = 0; car <= sizeof(gCPScars); car++)
	{
	    DestroyVehicle(gCPScars[car]);
	    
	    if(car == sizeof(gCPScars)) return 1;
 	}
	return 1;
	
}

EndCPS()
{
    	gCPSLobbyCount = 0;
		gPlayersVotedToStart = 0;
		gCPSCopsCount = 0;
		gCPSRobbersCount = 0;
		gCPSRobbersInCP = 0;
		gCPSLiveCops = 0;
		gCPSLiveRobbers = 0;



	    for(new k = 0; k <= MAX_PLAYERS; k++)
	    {
	        if(k == MAX_PLAYERS)
	        {
	            DestroyCPScars();
	            continue;
	        }

	        gOnCPSLobby[k] = false;
			gPlayerVotedToStart[k] = false;
			gCopCPtoBank[k] = false;
			gRobCPtoDropoff[k] = false;
			gCPSPlayerTeam[k] = -1;
			firstRobber[k] = false;

			if(onGamemode[k])
			{
			    onGamemode[k] = false;
				SetPlayerPos(k, 1310.2595,-1367.2544,13.5261);
				SetPlayerVirtualWorld(k, 0);
				SetPlayerSkin(k, gCPSskin[k]);
				SetPlayerHealth(k, gCPShealth[k]);
				SetPlayerArmour(k, gCPSarmour[k]);
				
				DisablePlayerCheckpoint(k);

			}

		}
		return 1;
}


RobberEnterCPS(robber)
{
	gCPSRobbersInCP++;
	
	if(gCPSRobbersInCP == 1)
	{
	    SendClientMessage(robber, GREEN, " * You have entered the checkpoint first and you'll recieve a bonus!");
	    firstRobber[robber] = true;
	    new name[MAX_PLAYER_NAME], msg[128];
	    GetPlayerName(robber, name, sizeof(name));
	    format(msg, 128, " * Robber %s has entered the checkpoint first and will recieve a reward.", name);
	    
	    new copMsg[128];
	    format(copMsg, 128, "Robber %s has managed to escape!", name);
	    
	    SendMessageToCPS(msg, 1, GREEN);
	    SendMessageToCPS(copMsg, 0, RED);
	
	}
	
	if(gCPSRobbersInCP == gCPSLiveRobbers)
	{
	    //make reward first using function.
	
	    //reset variables and reward
		gCPSLobbyCount = 0;
		gPlayersVotedToStart = 0;
		gCPSCopsCount = 0;
		gCPSRobbersCount = 0;
		gCPSRobbersInCP = 0;
		gCPSLiveCops = 0;
		gCPSLiveRobbers = 0;
	    
		
		
	    for(new k = 0; k <= MAX_PLAYERS; k++)
	    {
	        if(k == MAX_PLAYERS)
	        {
	            DestroyCPScars();
	            continue;
	        }
	        
	        gOnCPSLobby[k] = false;
			gPlayerVotedToStart[k] = false;
			gCopCPtoBank[k] = false;
			gRobCPtoDropoff[k] = false;
			gCPSPlayerTeam[k] = -1;
			firstRobber[k] = false;
			
			if(onGamemode[k])
			{
			    onGamemode[k] = false;
				SetPlayerPos(k, 1310.2595,-1367.2544,13.5261);
				SetPlayerVirtualWorld(k, 0);
				SetPlayerSkin(k, gCPSskin[k]);
				SetPlayerHealth(k, gCPShealth[k]);
				SetPlayerArmour(k, gCPSarmour[k]);
				SendClientMessage(k, GREEN, " *** Gamemode is over! ***");
				DisablePlayerCheckpoint(k);
				
			}
			
		}
	
	}
	
	
	
	return 1;

}

InitiateCPSPlayers()
{

	for(new i = 0; i <= MAX_PLAYERS; i++)
	{
	  
	    if(onGamemode[i])
	    {
			switch(GetPlayerCPSTeam(i))
			{
			    case 0: //cops
			    {
			      
					
					SetPlayerSkin(i, PickSkinCPS(0));

					SetPlayerVirtualWorld(i, VW_CPS);
					SetPlayerInterior(i, 0);
					SetPlayerPos(i, 1568.8895,-1689.9803,6.2188); //lspd_spawn

					ResetPlayerWeapons(i);
					GivePlayerWeapon(i, 29, 500); //MP5
					GivePlayerWeapon(i, 3, 1); //Nightstick
					GivePlayerWeapon(i, 31, 150); //M4
					GivePlayerWeapon(i, 34, 35); //Sniper
					GivePlayerWeapon(i, 25, 15); //Shotgun
					SetPlayerHealth(i, 100.0);
					SetPlayerArmour(i, 100.0);

					SendClientMessage(i, LBROWN, "You have 45 seconds to get to the bank and stop them robbers!");
					SetPlayerCheckpoint(i, 1458.1301,-1033.8481,23.3833, 4.0);
					
					gCPSLiveCops = gCPSCopsCount;

					gCopCPtoBank[i] = true;

					
				
				}
				case 1: //robbers
				{
				    
  	     	 		SetPlayerSkin(i, PickSkinCPS(1));

		        	SetPlayerVirtualWorld(i, VW_CPS);
		        	SetPlayerPos(i, 2315.952880,-1.618174,26.742187); //bank_interior
		        	SetPlayerInterior(i, 0);

		        	ResetPlayerWeapons(i);
					GivePlayerWeapon(i, 28, 500); //uzi
					GivePlayerWeapon(i, 4, 1); //knife
					GivePlayerWeapon(i, 30, 100); //ak-47
					GivePlayerWeapon(i, 22, 175); //9mm
					GivePlayerWeapon(i, 18, 5); //molotov
					SetPlayerHealth(i, 100.0);
					SetPlayerArmour(i, 75.0);
					
					gCPSLiveRobbers = gCPSRobbersCount;
					
					
					SendClientMessage(i, LBROWN, "You are currently robbing the bank for 45 seconds. The police are on their way, so watch out when exiting!");
				
					
				}
			}
			
			
	    }
	}

	
	return 1;
}

LoadCPS()
{
	//Clean up lobby variables and related data?
	CallRemoteFunction("LoadCPScars", "");
	SetTimer("ReleaseRobbers", 45000, false); 
	InitiateCPSPlayers();
	
	return 1;
	
}

//-----------------------------------------------------------------------------------------------------------------------------

//------------------------------------------DRUGDEALER JOB RELATED-------------------------------------------------------------
AddPlayerDrugDeliverySkill(playerid)
{
	if(!IsPlayerConnected(playerid)) return 0;
	
	PlayerInfo[playerid][pDrugDealerLSdelivs]++;
	
    if(PlayerInfo[playerid][pDrugDealerLSdelivs] == 60)
    {
        SendClientMessage(playerid, LBLUE, " * Congratulations, you have reached skill 2 as a delivery driver. Keep working your way up to skill 5 for a bonus.");
    }
	else if(PlayerInfo[playerid][pDrugDealerLSdelivs] == 80)
	{
		SendClientMessage(playerid, LBLUE, " * Congratulations, you have reached skill 3 as a delivery driver. Keep working your way up to skill 5 for a bonus.");
	}
	else if(PlayerInfo[playerid][pDrugDealerLSdelivs] == 120)
	{
	 	SendClientMessage(playerid, LBLUE, " * Congratulations, you have reached skill 42 as a delivery driver. Keep working your way up to skill 5 for a bonus.");
	}
	else if(PlayerInfo[playerid][pDrugDealerLSdelivs] == 230)
	{
		SendClientMessage(playerid, LBLUE, " * Congratulations, you have reached skill 5 as a delivery driver. Keep working your way up to skill 5 for a bonus.");
	}
	
	return 1;

}

RemoveDrugFromPlayer(playerid, drugid, amount)
{
	switch(drugid)
	{
	    case 0:
	    {
	        if(amount == -1) PlayerInfo[playerid][pMarijuanaAmount] = 0;
	        else PlayerInfo[playerid][pMarijuanaAmount] -= amount;
		}
		case 1:
		{
		    if(amount == -1) PlayerInfo[playerid][pCocaineAmount] = 0;
	        else PlayerInfo[playerid][pMarijuanaAmount] -= amount;
		}
		case 2:
		{
		    if(amount == -1) PlayerInfo[playerid][pEcstacyAmount] = 0;
	        else PlayerInfo[playerid][pEcstacyAmount] -= amount;
		}
		case 3:
		{
		    if(amount == -1) PlayerInfo[playerid][pMethAmount] = 0;
	        else PlayerInfo[playerid][pMethAmount] -= amount;
		}
		case 4:
		{
		    if(amount == -1) PlayerInfo[playerid][pKrokodilAmount] = 0;
	        else PlayerInfo[playerid][pKrokodilAmount] -= amount;
		}
		case 5:
		{
		    if(amount == -1) PlayerInfo[playerid][pCrackAmount] = 0;
	        else PlayerInfo[playerid][pCrackAmount] -= amount;
		}
		default: return 0;
	}
	return 1;
}

stock WipePlayerDrugs(playerid)
{
	PlayerInfo[playerid][pMarijuanaAmount] = 0;
	PlayerInfo[playerid][pCocaineAmount] = 0;
	PlayerInfo[playerid][pEcstacyAmount] = 0;
	PlayerInfo[playerid][pMethAmount] = 0;
	PlayerInfo[playerid][pKrokodilAmount] = 0;
	PlayerInfo[playerid][pMethAmount] = 0;
	return 1;
}

HasPlayerDrug(playerid, drugid)
{
	new bool:status;
	switch(drugid)
	{
	    case 0:
	    {
	        if(PlayerInfo[playerid][pMarijuanaAmount] > 0) status = true;
	        else status = false;
	    }
	    case 1:
	    {
	        if(PlayerInfo[playerid][pCocaineAmount] > 0) status = true;
	        else status = false;
	    }
	    case 2:
	    {
	        if(PlayerInfo[playerid][pEcstacyAmount] > 0) status = true;
	        else status = false;
	    }
	    case 3:
	    {
            if(PlayerInfo[playerid][pMethAmount] > 0) status = true;
	        else status = false;
	    }
	    case 4:
	    {
	        if(PlayerInfo[playerid][pKrokodilAmount] > 0) status = true;
	        else status = false;
	    }
	    case 5:
	    {
	        if(PlayerInfo[playerid][pCrackAmount] > 0) status = true;
	        else status = false;
	    }
	    default: status = false;
	}
	return status;
}

AddPlayerAddiction(playerid, addiction)
{
	PlayerInfo[playerid][pDrugAddiction] += addiction;
	return 1;
}

ReturnDrugID(drug[])
{
	new drugid;
	if(!strcmp(drug, "marijuana", true)) drugid = 0;
	else if(!strcmp(drug, "cocaine", true)) drugid = 1;
	else if(!strcmp(drug, "ecstacy", true)) drugid = 2;
	else if(!strcmp(drug, "meth", true)) drugid = 3;
	else if(!strcmp(drug, "krokodil", true)) drugid = 4;
	else if(!strcmp(drug, "crack", true)) drugid = 5;
	else drugid = -1;

	return drugid;
}
ReturnDrugName(drugid)
{
	new drug[64];

	switch(drugid)
	{
	    case 0: format(drug, 64, "marijuana");
	    case 1: format(drug, 64, "cocaine");
		case 2: format(drug, 64, "ecstacy");
		case 3: format(drug, 64, "meth");
		case 4: format(drug, 64, "krokodil");
		case 5: format(drug, 64, "crack");
		default: format(drug, 64, "INVALID");
	}
	return drug;
}


SendPlayerOffer(playerid, buyerid, drugid, amount, cost) //also if seller has enough drugs
{
	new string[128], buyername[MAX_PLAYER_NAME], sellername[MAX_PLAYER_NAME];
	GetPlayerName(playerid, sellername, sizeof(sellername));
	GetPlayerName(buyerid, buyername, sizeof(buyername));
	
	format(string, 128, "You have sent %s an offer of %ig of %s", buyername, amount, ReturnDrugName(drugid));
	SendClientMessage(playerid, LBLUE, string);
	
	new string2[128];
	format(string2, 128, "Supplier %s send you an offer of %ig of %s, at a cost of $%i. Type /acceptdeal <id of seller> to accept. ", sellername, ReturnDrugName(drugid), amount,cost);
	SendClientMessage(buyerid, LBLUE, string2);

	return 1;

}
forward OnPlayerAcceptOffer(sellerid, buyerid, drugid, amount, cost);
public OnPlayerAcceptOffer(sellerid, buyerid, drugid, amount, cost)
{
	new string[128], buyername[MAX_PLAYER_NAME], sellername[MAX_PLAYER_NAME];
	GetPlayerName(sellerid, sellername, sizeof(sellername));
	GetPlayerName(buyerid, buyername, sizeof(buyername));
	
	format(string, 128, "You accepted %s's offer.", buyername);
	SendClientMessage(buyerid, LBLUE, string);

	new string2[128];
	format(string2, 128, "You sold %ig of %s to %s for %i.", amount, ReturnDrugName(drugid), sellername, cost);
	SendClientMessage(sellerid, LBLUE, string2);
	
	GivePlayerMoney(sellerid, cost);
	GivePlayerMoney(buyerid, -cost);
	
	switch(drugid)
	{
	    case 0: //marijuana
	    {
	        PlayerInfo[sellerid][pMarijuanaAmount] -= amount;
	        PlayerInfo[buyerid][pMarijuanaAmount] += amount;
	    }
	    case 1: //cocaine
	    {
	        PlayerInfo[sellerid][pCocaineAmount] -= amount;
	        PlayerInfo[buyerid][pCocaineAmount] += amount;
	    }
	    case 2: //ecstacy
	    {
	        PlayerInfo[sellerid][pEcstacyAmount] -= amount;
	        PlayerInfo[buyerid][pEcstacyAmount] += amount;
	    }
	    case 3: //meth
	    {
	        PlayerInfo[sellerid][pMethAmount] -= amount;
	        PlayerInfo[buyerid][pMethAmount] += amount;
	    }
	    case 4: //krokodil
	    {
	        PlayerInfo[sellerid][pKrokodilAmount] -= amount;
	        PlayerInfo[buyerid][pKrokodilAmount] += amount;
	    }
	    case 5: //crack
	 	{
	 	    PlayerInfo[sellerid][pCrackAmount] -= amount;
	        PlayerInfo[buyerid][pCrackAmount] += amount;
	    }
	}
	

	return 1;


}

IsPlayerDrugSupplier(playerid)
{
	new bool:status;
	
	if(PlayerInfo[playerid][pJob] == 2) status = true;
	
	else status = false;

	return status;
}

IsPlayerOnSupplyCool(playerid)
{
	new bool:status;
	if(PlayerInfo[playerid][pDrugSupplierCool] > 0) status = true;
	else status = false;
	
	return status;
}

forward DrugSupplierCooldown(playerid);
public  DrugSupplierCooldown(playerid)
{
	SendClientMessage(playerid, LBLUE, "Your have been granted access to buying drugs again.");
	PlayerInfo[playerid][pDrugSupplierCool] = 0;

	return 1;
}



ReturnDrugDealerSkill(playerid)
{
	new skill = 0;

	if(PlayerInfo[playerid][pDrugDealerLSdelivs] < 60) skill = 1;
	else if(PlayerInfo[playerid][pDrugDealerLSdelivs] > 60 && PlayerInfo[playerid][pDrugDealerLSdelivs] < 80)
	{
		skill = 2;
	}
	else if(PlayerInfo[playerid][pDrugDealerLSdelivs] > 80 && PlayerInfo[playerid][pDrugDealerLSdelivs] < 120)
	{
	 	skill = 3;
	}
	else if(PlayerInfo[playerid][pDrugDealerLSdelivs] > 120 && PlayerInfo[playerid][pDrugDealerLSdelivs] < 230)
	{
		skill = 4;
	}
	else if(PlayerInfo[playerid][pDrugDealerLSdelivs] > 230)
	{
		 skill = 5;
	}
	
	else skill = -1;


	return skill;
}

enum DrugsLocation
{
	JobID,
	LocName[128],
	Float:DrugsX,
	Float:DrugsY,
	Float:DrugsZ,
	Payment
}

new DrugsLocations[][DrugsLocation] =
{
	{0, "the Los Santos Docks area", 2632.8940,-2047.4041,13.5500, 431},
	{1, "the garages in Los Santos", 2334.5356,-1239.3452,22.2271, 420},
	{2, "the houses in Marina, Los Santos", 769.8719,-1471.2968,13.3321, 460},
	{3, "the Richman area, Los Santos", 688.5792,-921.5528,75.8848, 490}
};

enum DrugCarCoords
{
	Float:drugCarX,
	Float:drugCarY,
	Float:drugCarZ,
	Location[128]
}

new DrugLSCarLocations[][DrugCarCoords] =
{
	{2523.5803,-2655.8008,13.3655, "the Ocean Docks area."}, //Ocean Docks
	{2796.6567,-1584.6052,10.6540, "the East Beach area."}, //east beach
	{2382.3489,-1031.9370,53.4426, "the Las Colinas area."}, //las colinas
	{1577.8600,-1551.0952,13.2943, "the Commerce area."}  //commerce

};


new DrugLSCars[6] = 
{
	400,
	401,
	419,
	458,
	489,
	518
};

//new DrugLSCarsID[DrugLSCars];

//TODO: secondary drug delivery job where you buy merchendise and sell for a higher price to customers(customers are pre-programmed, eventually could use real-life players)

SpawnDrugDealerCar(player)
{
	//pick random veh model
	new randomPlayerVeh = random(sizeof(DrugLSCars));
 	new randomCarLoc = random(sizeof(DrugLSCarLocations));
 	new Float:CarX, Float:CarY, Float:CarZ;
 	
 	CarX = DrugLSCarLocations[randomCarLoc][drugCarX];
   	CarY = DrugLSCarLocations[randomCarLoc][drugCarY];
    CarZ = DrugLSCarLocations[randomCarLoc][drugCarZ];
 	 //DrugLSCarsID[randomPlayerVeh]
	gDrugDealerLScarID = CreateVehicle(DrugLSCars[randomPlayerVeh], CarX, CarY, CarZ, 0, -1, -1, -1);
    SetPlayerCheckpoint(player, CarX, CarY, CarZ, 4.20);
    
    new string[128];
    format(string, 128, "Get to the delivery car in %s.", DrugLSCarLocations[randomCarLoc][Location]);
    SendClientMessage(player, WHITE, string);
	gDrugDealerToCarCP[player] = true;
    
	return 1;
}

PickDrugDealerLoc(player, randLoc)
{
    
    new Float:DestX, Float:DestY, Float:DestZ;
   
    
    DestX = DrugsLocations[randLoc][DrugsX];
    DestY = DrugsLocations[randLoc][DrugsY];
    DestZ = DrugsLocations[randLoc][DrugsZ];
    
    SetPlayerCheckpoint(player, DestX, DestY, DestZ, 5.0);
    gDrugDealerToDestCP[player] = true;
    new string[128];
    format(string, 128, "Deliver the drugs to %s.", DrugsLocations[randLoc][LocName]);
    SendClientMessage(player, WHITE, string);
    
	return 1;
}

InitiateDrugDealerJob(player)
{
    if(IsPlayerInRangeOfPoint(player, 10.0, 2212.4729,-2044.7767,13.5469)) //Drug Dealer LS
    {
    	new randomLocation = random(sizeof(DrugsLocations));
        gDrugRowID = randomLocation;
        
        SpawnDrugDealerCar(player);
        OnJob[player] = true;
	
        
        
	//transfer destination code into a separate function as it is needed when the player gets in the drug car, DONE

	//implement cancel command, which erases drug vehicle

	// RNG of getting 1 star wanted level (10%?)

        
	//set player checkpoint to drug car's location, DONE


	//create a car with a global id, check if player gets in it via OnPlayerEnterVehicle function
		
    }


}

//------------------------------------------------------------------------------------------------------------------------------------------------

//-------------------------------TAXI RELATED-----------------------------------------------------------------------------------------------------

TaxTaxiFare(fare, oldCount, newCount, taxiDrv)
{
	//convert to minutes, 1min = 6$, +20$

	new toTax = newCount - oldCount;

	toTax = toTax / 60;

	new toPay = (toTax * 1) + 20;

	GivePlayerMoney(fare, -toPay);
	GivePlayerMoney(taxiDrv, toPay);
	new msg[128], msgToTaxiDrv[128];

	format(msg, 128, "You have been driven for %i minutes(1 min = $6) and have been charged %i (including taxi's base fare price.)", toTax, toPay);
	format(msgToTaxiDrv, 128, "You have been driving for %i minutes and have recieved %i dollars for your fare.", toTax, toPay);

	SendClientMessage(fare, COLOR_VLBLUE, msg);
	SendClientMessage(taxiDrv, COLOR_VLBLUE, msgToTaxiDrv);



	return 1;

}

new gTaxiOldSeconds[MAX_PLAYERS];
forward AcceptOrderChecks(taxiDriver, taxiAcceptant, taxiVehID);
public AcceptOrderChecks(taxiDriver, taxiAcceptant, taxiVehID)
{
	
	
	if(IsPlayerInVehicle(taxiAcceptant, taxiVehID))
	{
	    KillTimer(gTaxiDriverTimerID[taxiDriver]);
	    
	    gTaxiOldSeconds[taxiDriver] = GetSecondsSinceStartup();
	    
	    SendClientMessage(taxiDriver, COLOR_VLBLUE, "Your fare has entered the taxi, taxing has begun.");
		SendClientMessage(taxiAcceptant, COLOR_VLBLUE, "You have entered the taxi, taxing has begun.");
	}
	return 1;
	
}

//----------------------------------------------------------------------------------------------------------------------------------------------



//------------------LOAD FACTION FUNCTIONS------------------------------------------------------------------------------------------------------

LoadLSPD(rank, reciever)
{
	switch(rank)
	{
	    
  		case 1:
	    {
			SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 280);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
		}
		case 2:
		{
		    SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 280);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        
		}
		case 3:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
		}
		case 4:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
		}
		case 5:
		{
		 	SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		
		}
		case 6:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		}
		case 7:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 265);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		
		}
	}
	return 1;
}

LoadSFPD(rank, reciever)
{
	switch(rank)
	{

  		case 1:
	    {
			SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //sfpd downstairs
		    SetPlayerSkin(reciever, 281);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
		}
		case 2:
		{
		    SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 281);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun

		}
		case 3:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
		}
		case 4:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
		}
		case 5:
		{
		 	SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas

		}
		case 6:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		}
		case 7:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 265);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas

		}
	}
	return 1;
}
	
LoadLVPD(rank, reciever)
{
	switch(rank)
	{

  		case 1:
	    {
			SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //sfpd downstairs
		    SetPlayerSkin(reciever, 282);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
		}
		case 2:
		{
		    SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 282);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun

		}
		case 3:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
		}
		case 4:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
		}
		case 5:
		{
		 	SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas

		}
		case 6:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		}
		case 7:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 265);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas

		}
	}
	return 1;
}

LoadTaxi(player, rank)
{
	switch(rank)
	{
	    case 1:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 61);
	        
	    }
	    case 2:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 171);
	    }
	    case 3:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 189);
	    }
	    case 4:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 253);
	    }
	    case 5:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 255);
	    }
	    case 6:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 255);
	    }
	    case 7:
	    {
	    	SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 147);
	    
	    }
	}
	return 1;
}
//--------------------------------------------------------------------------------------------------------------------




//----------------------------------------FACTION SUBROUTINES-----------------------------------------------------
ReturnPlayerFaction(player)
{
	new n[64];
	switch(PlayerInfo[player][pFaction])
	{
	    case 0: format(n, sizeof(n), "Civilian");
	    case 1: format(n, sizeof(n), "LSPD");
	    case 2: format(n, sizeof(n), "SFPD");
	    case 3: format(n, sizeof(n), "LVPD");
	    case 4: format(n, sizeof(n), "Taxi Company");
	}
	return n;
}

IsPlayerFactionLeader(player)
{
	if(PlayerInfo[player][pFactionRank] == 7)
	{
	    return true;
	}

	return false;

}

GetPlayerFaction(factionee)
{
	return PlayerInfo[factionee][pFaction];
}

IsPlayerCop(player)
{
	if(GetPlayerFaction(player) == 1 || GetPlayerFaction(player) == 2 || GetPlayerFaction(player) == 3) return true;
	
	else return false;
}

JailPlayer(player, time, reasonText[])
{
	SetPlayerInterior(player, 18);
	SetPlayerPos(player, 1302.519897,-1.787510,1001.028259);
	ResetPlayerWeapons(player);
	
	new minutesToJail = time / 60000;
	new msg[128];
	format(msg, sizeof(msg), "Your jail time is %i minutes.\nReason: %s", minutesToJail, reasonText);

	ShowPlayerDialog(player, DIALOG_JAILTIME, DIALOG_STYLE_MSGBOX, "Jail time!", msg, "OK", "");
	SetTimerEx("UnjailPlayer", time, false, "i", player);
	
	return 1;
}

forward UnjailPlayer(toUnjail);
public UnjailPlayer(toUnjail)
{
	SetPlayerInterior(toUnjail, 0);
	PlayerInfo[toUnjail][pJailTime] = 0;
	SpawnPlayer(toUnjail);
	
	return 1;
}

Cuff(player)
{
	return SetPlayerSpecialAction(player, SPECIAL_ACTION_CUFFED);
}

Uncuff(player)
{
    SetPlayerSpecialAction(player, SPECIAL_ACTION_NONE);
}

//-----------------------------------------------------------------------------------------------------------------------

//-----------------------------------------SURVIVAL MINIGAME RELATED-----------------------------------------------------

//TODO:
/*
	*playtest
	*add several checkpoints
	*make /buygear only usable once
*/

#define SUR_VW 356
#define DIALOG_SURVIVAL_GEAR 7813


new gSurvivalLobbyCount = 0;
new gSurvivalVotes = 0;
new bool:gPlayerInSurvivalLobby[MAX_PLAYERS];
new bool:gPlayerVotedSurvival[MAX_PLAYERS];
new gPrevSurvivalPlayerMoney[MAX_PLAYERS] = 0;
new gPlayersInSurvivalCP = 0;
new gSurvivalPrevSkin[MAX_PLAYERS] = -1;
new gPlayerHealthSnacks[MAX_PLAYERS];
new bool:gSurvivalGameStarted = false;

new gIsPlayerInSurvCP[MAX_PLAYERS];
new gSurvivalCars[100];

forward LoadSurvivalCars();
public LoadSurvivalCars()
{
	SendMessageToSurvival("Loading Survival cars........", WHITE);
	
	gSurvivalCars[0] = CreateVehicle(412, -1786.4827,1204.9880,24.9604, 180.0, -1, -1, -1);
	gSurvivalCars[1] = CreateVehicle(439, -2490.0959,1138.4974,55.6229,359.9475, -1, -1, -1);
	gSurvivalCars[2] = CreateVehicle(587, -2408.3430,979.1905,45.0240,1.1177, -1, -1, -1);
	gSurvivalCars[3] = CreateVehicle(589, -1586.3759,937.3701,7.1967,91.3205, -1, -1, -1);
	gSurvivalCars[4] = CreateVehicle(585, -1762.9915,737.3493,30.6065,90.9851, -1, -1, -1);
	gSurvivalCars[5] = CreateVehicle(518, -1947.2578,584.8498,34.8035,0.5240, -1, -1, -1);
	gSurvivalCars[6] = CreateVehicle(415, -1978.9894,440.9478,26.6695,359.9996, -1, -1, -1);
	gSurvivalCars[7] = CreateVehicle(603, -1956.8422,269.5694,35.3074,35.0640, -1, -1, -1);
	gSurvivalCars[8] = CreateVehicle(579, -1994.1051,156.3608,27.4715,358.1671, -1, -1, -1);
	gSurvivalCars[9] = CreateVehicle(565, -2025.1576,125.4789,28.7050,1.0155, -1, -1, -1);
	gSurvivalCars[10] = CreateVehicle(541, -1820.0948,-176.9125,9.0235,89.8656, -1, -1 ,-1);
	gSurvivalCars[11] = CreateVehicle(540, -2755.3381,-311.6016,6.9011,4.4582, -1, -1, -1);
	gSurvivalCars[12] = CreateVehicle(551, -2753.0837,376.2677,3.9384,181.0530, -1, -1, -1);
	gSurvivalCars[13] = CreateVehicle(558, -2866.4058,1055.7938,32.0799,99.0474, -1, -1, -1);
	gSurvivalCars[14] = CreateVehicle(561, -1590.1301,104.4466,3.3636,135.9552, -1, -1, -1);
	gSurvivalCars[15] = CreateVehicle(522, -1697.0870,77.2000,3.1254,318.9018, -1, -1, -1);
	gSurvivalCars[16] = CreateVehicle(554, -551.2259,-187.0097,78.4909,270.1443, -1, -1, -1);
	gSurvivalCars[17] = CreateVehicle(426, -495.1321,-488.5710,25.2610,178.8637, -1, -1, -1);
	gSurvivalCars[18] = CreateVehicle(424, -1885.6962,-1680.4741,21.5315,270.9841, -1, -1, -1);
	gSurvivalCars[19] = CreateVehicle(451, -1862.2679,-1608.6786,21.4651,188.0174, -1, -1, -1);
	gSurvivalCars[20] = CreateVehicle(489, -2286.1653,-1656.6417,483.0680,138.5519, -1, -1, -1);
	gSurvivalCars[21] = CreateVehicle(468, -2312.6355,-1670.4630,482.4404,223.6146, -1, -1, -1);
	gSurvivalCars[22] = CreateVehicle(475, 247.0334,-157.1841,1.3800,93.3215, -1, -1, -1);
	gSurvivalCars[23] = CreateVehicle(496, 695.6075,-472.4158,16.0531,252.4491, -1, -1, -1);
	gSurvivalCars[24] = CreateVehicle(500, 2706.9529,-1.3705,31.3457,200.7870, -1, -1, -1);
	gSurvivalCars[25] = CreateVehicle(507, 2475.6943,-962.1490,80.0098,186.2777, -1, -1, -1);
	gSurvivalCars[26] = CreateVehicle(517, 2161.2048,-1196.6736,23.7302,92.2545, -1, -1, -1);
	gSurvivalCars[27] = CreateVehicle(468, 1955.1837,-1175.2244,19.7261,79.9609, -1, -1, -1);
	gSurvivalCars[28] = CreateVehicle(474, 2255.9473,-1417.6251,23.5960,92.1621, -1, -1, -1);
	gSurvivalCars[29] = CreateVehicle(492, 2508.3281,-1666.1389,13.1833,11.0314, -1, -1, -1);
	gSurvivalCars[30] = CreateVehicle(445, 2687.5588,-1672.3828,9.3230,359.3943, -1, -1, -1);
	gSurvivalCars[31] = CreateVehicle(461, 2788.8953,-2507.3076,13.2266,90.8719, -1, -1, -1);
	gSurvivalCars[32] = CreateVehicle(466, 1775.5453,-1924.8049,13.1278,1.2642, -1, -1, -1);
	gSurvivalCars[33] = CreateVehicle(534, 1841.1763,-1871.8574,13.1121,2.4290, -1, -1, -1);
	gSurvivalCars[34] = CreateVehicle(533, 1647.4253,-2257.7698,13.0390,89.3546, -1, -1, -1);
	gSurvivalCars[35] = CreateVehicle(536, 1483.0490,-1596.3296,13.1251,271.0939, -1, -1, -1);
	gSurvivalCars[36] = CreateVehicle(561, 1309.5002,-1391.6173,13.1245,90.0560, -1, -1, -1);
	gSurvivalCars[37] = CreateVehicle(536, 1219.4926,-1057.4553,30.8855,358.6302, -1, -1, -1);
	gSurvivalCars[38] = CreateVehicle(559, 1248.8621,-805.8727,83.7969,178.1958, -1, -1, -1);
	gSurvivalCars[39] = CreateVehicle(565, 542.8722,-1202.2756,44.1646,22.2066, -1, -1, -1);
	gSurvivalCars[40] = CreateVehicle(555, 498.1660,-1464.0353,17.4373,327.1373, -1, -1, -1);
	gSurvivalCars[41] = CreateVehicle(567, 378.4896,-1516.5729,32.5264,307.5201, -1, -1, -1);
	gSurvivalCars[42] = CreateVehicle(560, 294.2290,-1512.9049,24.2993,236.3191, -1, -1, -1);
	gSurvivalCars[43] = CreateVehicle(566, 366.1803,-2043.5482,7.4492,359.1453, -1, -1, -1);
	gSurvivalCars[44] = CreateVehicle(575, 845.0695,-1803.5112,13.0161,7.5915, -1, -1, -1);
	gSurvivalCars[45] = CreateVehicle(579, -73.4569,-1112.9579,1.0107,162.1338, -1, -1, -1);
	gSurvivalCars[46] = CreateVehicle(568, -380.4357,-1427.9581,25.6781,318.4227, -1, -1, -1);
	gSurvivalCars[47] = CreateVehicle(521, -365.8995,-1415.4453,25.2945,85.8607, -1, -1, -1);
	gSurvivalCars[48] = CreateVehicle(526, 1486.9927,702.8592,10.5096,94.5754, -1, -1, -1);
	gSurvivalCars[49] = CreateVehicle(542, 1057.1052,1048.7864,10.0179,348.2336, -1, -1, -1);
	gSurvivalCars[50] = CreateVehicle(549, 603.9490,1656.3281,6.6895,65.5289, -1, -1, -1);
	gSurvivalCars[51] = CreateVehicle(576, 909.4633,2424.3669,10.2937,164.4379, -1, -1, -1);
	gSurvivalCars[52] = CreateVehicle(411, 1049.0341,2342.5542,10.5474,177.9828, -1, -1, -1);
	gSurvivalCars[53] = CreateVehicle(580, 1415.9663,2608.6003,10.4680,90.0893, -1, -1, -1);
	gSurvivalCars[54] = CreateVehicle(581, 2481.6216,2778.1763,10.3417,88.5104, -1, -1, -1);
	gSurvivalCars[55] = CreateVehicle(603, 2790.1760,2626.7844,10.6576,198.9935, -1, -1, -1);
	gSurvivalCars[56] = CreateVehicle(426, 2131.4099,2339.1101,10.4149,89.6608, -1, -1, -1);
    gSurvivalCars[57] = CreateVehicle(436, 2044.8525,1915.5634,11.9079,180.8699, -1, -1, -1);
    gSurvivalCars[58] = CreateVehicle(445, 2152.3567,1679.1853,10.6230,353.3863, -1, -1, -1);
    gSurvivalCars[59] = CreateVehicle(463, 2182.8230,1285.9861,10.2122,182.3185, -1, -1, -1);
    gSurvivalCars[60] = CreateVehicle(477, 2825.6572,969.0869,10.5061,172.1649, -1, -1, -1);
    gSurvivalCars[61] = CreateVehicle(491, 2789.1563,921.0867,10.5063,124.7761, -1, -1, -1);
    gSurvivalCars[62] = CreateVehicle(507, 2824.8916,1305.4087,10.5903,357.3758, -1, -1, -1);
    gSurvivalCars[63] = CreateVehicle(516, -89.5300,1221.2908,19.5762,359.4444, -1, -1, -1);
    gSurvivalCars[64] = CreateVehicle(556, -703.8305,955.7837,12.7731,90.1904, -1, -1, -1);
    gSurvivalCars[65] = CreateVehicle(562, -680.0652,915.1363,11.7546,89.9376, -1, -1, -1);
    gSurvivalCars[66] = CreateVehicle(571, -2271.9282,2316.3242,4.1037,79.6484, -1, -1, -1);
    gSurvivalCars[67] = CreateVehicle(602, -2253.7007,2331.7092,4.6194,74.8433, -1, -1, -1);
    
    for(new i = 0; i<= sizeof(gSurvivalCars); i++)
    {
        //if(gSurvivalCars[i] == 0) SendMessageToSurvival("Survival vehicle not created.", WHITE);
        
        SetVehicleVirtualWorld(gSurvivalCars[i], SUR_VW);
    }
    
    SendMessageToSurvival("done loading the cars.", WHITE);
    
    return 1;
    
}

UnloadSurvivalCars()
{
	for(new i = 0; i<= sizeof(gSurvivalCars); i++)
	{
	    DestroyVehicle(gSurvivalCars[i]);
	}
	return 1;
}

UnloadSurvival()
{
	
	gSurvivalLobbyCount = 0;
 	gSurvivalVotes = 0;
    gPlayersInSurvivalCP = 0;
    gSurvivalGameStarted = false;
    
 	for(new i = 0; i <= MAX_PLAYERS; i++)
	{
	    if(!IsPlayerConnected(i)) continue;

	    if(gPlayerInSurvivalLobby[i])
	    {
	        gPlayerInSurvivalLobby[i] = false;
	        gPlayerVotedSurvival[i] = false;
	        SetPlayerInterior(i, 0);
	        SetPlayerVirtualWorld(i, 0);
	        ResetPlayerWeapons(i);
	        SetPlayerSkin(i, gSurvivalPrevSkin[i]);
        	SetPlayerPos(i, -2766.3821,375.5034,6.3347);
			SetPlayerInterior(i, 0);
		 	gPlayerHealthSnacks[i] = 0;
			
			GivePlayerMoney(i, -GetPlayerMoney(i));
			GivePlayerMoney(i, gPrevSurvivalPlayerMoney[i]);
			gPrevSurvivalPlayerMoney[i] = 0;
	    }
	}
	UnloadSurvivalCars();
	return 1;

}

SendMessageToSurvival(message[128], color)
{
    new string[128];
	format(string, 128, "%s", message);

	for(new i = 0; i <= MAX_PLAYERS; i++)
	{
	    if(!IsPlayerConnected(i)) continue;

	    if(gPlayerInSurvivalLobby[i])
	    {
	        SendClientMessage(i, color, string);

	    }
	}
	return 1;
}


enum survivalcoords
{
	Float:surX,
	Float:surY,
	Float:surZ
}
new Float:survivalCoords[][survivalcoords] =
{
	{-2540.2415,1136.3140,55.7266},
	{-1798.7838,1197.9987,25.1194},
	{-1497.9220,919.8745,7.1875},
	{-1784.2153,713.7225,34.8567},
	{-1940.2051,556.8486,35.1719},
	{-2031.0587,161.8751,28.8359},
	{-2031.0587,161.8751,28.8359},
	{-2720.7036,-318.1102,7.8438},
	{-2706.1970,369.1682,4.3875},
	{-2899.7590,1073.6864,32.1328},
	{-1558.8416,111.3188,3.5547},
	{-552.7134,-197.0690,78.4062},
	{-515.3021,-540.6796,25.5234},
	{-1896.4351,-1671.2855,23.0156},
	{-2288.1228,-1665.7891,482.6137},
	{261.5904,-158.7375,5.0786},
	{681.5408,-475.0035,16.5363},
	{2691.9497,-15.0029,34.0970},
	{2473.4412,-964.0037,80.1382},
	{2140.3423,-1191.6974,23.9922},
	{1968.1263,-1177.0712,20.0307},
	{2271.3933,-1436.9854,23.8281},
	{2495.2876,-1687.2169,13.5152},
	{2693.7515,-1701.6765,10.9857},
	{2788.8953,-2507.3076,13.2266},
	{1752.0430,-1961.1597,14.1172},
	{1685.2600,-2241.0044,13.5469},
	{1477.7562,-1623.4994,14.0469},
	{1309.9872,-1370.7134,13.5789},
	{1232.2998,-1023.2890,32.6016},
	{1264.3217,-815.3530,84.1406},
	{552.6069,-1199.9247,44.8315},
	{479.2357,-1487.9908,20.1607},
	{328.2646,-1514.8929,36.0391},
	{385.4960,-2084.1399,7.8359},
	{843.3406,-1842.1145,12.6088},
	{-70.2674,-1136.2909,1.0781},
	{-373.2191,-1444.9543,25.7266},
	{1476.8414,723.9108,10.8203},
	{1050.7263,1023.7306,11.0000},
	{577.5569,1691.6852,6.9922},
	{901.6373,2440.6133,10.8203},
	{1434.0551,2614.2058,11.3926},
	{2492.2786,2773.0730,10.8030},
	{2784.1079,2571.2358,10.8203},
	{2127.6787,2374.7935,10.8203},
	{2020.7778,1920.0138,12.3406},
	{2187.6360,1678.6256,11.1080},
	{2208.1448,1285.9285,10.8203},
	{2811.3533,900.9217,10.7578},
	{2838.6565,1291.1051,11.3906},
	{-86.8080,1229.1652,22.4403},
	{-686.1885,938.9379,13.6328},
	{-2233.6169,2327.4109,7.5469}

};

forward On3rdSurvivalTimeOver();
public On3rdSurvivalTimeOver()
{
	new reward = 35000;
	for(new i = 0; i <= MAX_PLAYERS; i++)
	{
	    if(!IsPlayerConnected(i)) continue;
	    
	    new msg[128];
	    if(gPlayerInSurvivalLobby[i])
	    {
	        if(gPlayersInSurvivalCP == 1)
	        {
	            GivePlayerMoney(i, reward);
	            format(msg, 128, "You are the winner! You get the full cut of $35.000");
	        	ShowPlayerDialog(i, 5326, DIALOG_STYLE_MSGBOX, "Winner!", msg, "OK", "");
				GivePlayerMoney(i, reward);
	        	
	        	break;
			}
			
			if(gIsPlayerInSurvCP[i])
			{

	        	reward = reward / gPlayersInSurvivalCP;
		        GivePlayerMoney(i, reward);


		        format(msg, 128, "You are part of the winners! Your cut is $%i.\nThere were %i players remaining; the reward is $35.000 split amount all participants.", reward);
		        ShowPlayerDialog(i, 5326, DIALOG_STYLE_MSGBOX, "Winner!", msg, "OK", "");
	        
	    	    
			}
			else
			{
			    ShowPlayerDialog(i, 5321, DIALOG_STYLE_MSGBOX, "Loser!", "You were not in the checkpoint within the time given and didn't get any reward as a result.", "OK", "");
			    DisablePlayerCheckpoint(i);
			    
			}
	    }
	}
	UnloadSurvival();
	return 1;
}
forward On2ndSurvivalTimeOver();
public On2ndSurvivalTimeOver()
{
	SendMessageToSurvival(" *** 10 SECONDS LEFT!!! ***", TEST_COL);
	SetTimer("On3rdSurvivalTimeOver", 10000, false);
	return 1;
}

forward On1stSurvivalTimerOver();
public On1stSurvivalTimerOver()
{
	SendMessageToSurvival(" ** 3 minutes are done, 2 minutes left to survive! **", RED);
	SetTimer("On3rdSurvivalTimeOver", (3 * 60000) - 10000, false);
	return 1;
}

new survivalSkins[] =
{
    3,
	6,
	84,
	21,
	22,
	23,
	29,
	30,
	47,
	48,
	59,
	60,
	83,
	112,
	113
};
LoadSurvival()
{
	
	SetTimer("On1stSurvivalTimerOver", 3 * 60000, false);
	SendMessageToSurvival("Loading survival........",WHITE);
	CallRemoteFunction("LoadSurvivalCars", "");
	
	for(new i = 0; i <= MAX_PLAYERS; i++)
	{
	    if(gPlayerInSurvivalLobby[i])
	    {
	    
	        SetPlayerInterior(i, 0);
	        ResetPlayerWeapons(i);
	        gSurvivalPrevSkin[i] = GetPlayerSkin(i);
			gPrevSurvivalPlayerMoney[i] = GetPlayerMoney(i);
			
			GivePlayerMoney(i, - GetPlayerMoney(i));
			GivePlayerMoney(i, 35000);
	        
	        SendMessageToSurvival("-------------------------------------", GREEN);
	        SendMessageToSurvival(" *** Game started! ***", GREEN);
	        SendMessageToSurvival("-------------------------------------", GREEN);
	        
			ShowPlayerDialog(i, 5824,DIALOG_STYLE_MSGBOX, "Objective", "Your objective is to remain alive for 5 minutes.\nYour reward will be divided between the number of players alive at the end; meaning the less players alive til the end, the higher the reward.\nYou can purchase gear for war using /buygear.\nYou can use Health Bars using /healthbar.", "OK", "");
			SetPlayerCheckpoint(i, 211.2593,1866.1700,13.1406, 10.0);
			
			
			new playerLoc = random(sizeof(survivalCoords));
			
			SetPlayerPos(i, survivalCoords[playerLoc][surX], survivalCoords[playerLoc][surY], survivalCoords[playerLoc][surZ]);
			SetPlayerVirtualWorld(i, SUR_VW);
			
			new playerSkin = random(sizeof(survivalSkins));
			SetPlayerSkin(i, survivalSkins[playerSkin]);
			
			
	    }
	    else SendClientMessage(i, WHITE, "Debug: You are not in the survival lobby apparently.");
	}
	
	 
	SendMessageToSurvival("Done loading survival.", WHITE);
	return 1;
}




PutPlayerInSurvivalLobby(playerid)
{
	//1727.2853	-1642.9451	20.2254
	SetPlayerPos(playerid, 1727.2853,	-1642.9451,	20.2254);
	SetPlayerInterior(playerid, 18);
	gSurvivalLobbyCount++;
	gPlayerInSurvivalLobby[playerid] = true;
	
	new msg[128], playerName[128];

	GetPlayerName(playerid, playerName, 128);
	format(msg, 128, "Player {f94204}%s {FFFF00}has entered the lobby. Players in the lobby currently: {f94204}%i.", playerName, gSurvivalLobbyCount);

	SendMessageToSurvival(msg, YELLOW);
	SendMessageToSurvival("All players must type /startsurvival to start the minigame.", DARK_BLUE);
	
	return 1;
}

ExitPlayerFromSurvivalLobby(playerid)
{

	gSurvivalLobbyCount--;
	
	
	if(gSurvivalLobbyCount == 0)
	{
	    
	    
	    new msg1[128], name[MAX_PLAYER_NAME];
	    GetPlayerName(playerid, name, sizeof(name));
	    
	    format(msg1, 128, "Player %s left the lobby. There are no players left in the lobby and the game may not continue.", name);
	    
	    ShowPlayerDialog(playerid, 4925, DIALOG_STYLE_MSGBOX, "Kicked out", msg1, "OK", "");
	    UnloadSurvival();
		return 1;
	}

	new msg[128], playerName[128];

	GetPlayerName(playerid, playerName, 128);
	format(msg, 128, "Player {f94204}%s {FFFF00}has left the lobby. Players in the lobby currently: {f94204}%i.", playerName, gSurvivalLobbyCount);
	SendMessageToSurvival(msg, YELLOW);
	
	if(gIsPlayerInSurvCP[playerid])
	{
	    gIsPlayerInSurvCP[playerid] = false;
	    gPlayersInSurvivalCP--;
	    format(msg, 128, "Player {f94204}%s was in the checkpoint but died.", playerName);
	    SendMessageToSurvival(msg, YELLOW);
	}

	
	SendMessageToSurvival("All players must type /startsurvival to start the minigame.", DARK_BLUE);
	
	gPlayerInSurvivalLobby[playerid] = false;
	gPlayerVotedSurvival[playerid] = false;
	gPlayerHealthSnacks[playerid] = 0;
	
	


	return 1;
}

OnSurvivalVote(playerid)
{
	
	if(gPlayerVotedSurvival[playerid])
	{
	    SendClientMessage(playerid, WHITE, "ERROR: You already voted to start the survival minigame.");
	}
	else
	{
 		gSurvivalVotes++;
 		gPlayerVotedSurvival[playerid] = true;
 		
 		new playerName[MAX_PLAYER_NAME];
		GetPlayerName(playerid, playerName, sizeof(playerName));

		new msg[128];
		format(msg, 128, "Player {f94204}%s {FFFF00}has voted to start the minigame. Votes needed to start the minigame: {f94204}%i", playerName, gSurvivalLobbyCount - gSurvivalVotes);

		SendMessageToSurvival(msg, YELLOW);
	}
	
	
	
	if(gSurvivalVotes == gSurvivalLobbyCount && !gSurvivalGameStarted)
	{
		gSurvivalGameStarted = true;
		SendMessageToSurvival("Game is cleared to start!", WHITE);
		
		//LoadSurvivalCars();
		
	    LoadSurvival();
	}
	return 1;

}



//-----------------------------------------------------------------------------------------------------------------------

//--------------------------------------------SERVER RELATED FUNCTIONS---------------------------------------------------
LoadMapIcons(playerid)
{
	SetPlayerMapIcon(playerid, 0, 1310.2595,-1367.2544,13.5261, 52, 0, MAPICON_GLOBAL);
	SetPlayerMapIcon(playerid, 1, -2766.3821,375.5034,6.3347, 36, 0, MAPICON_GLOBAL);
	
	return 1;
}

forward SkinTestOver(playerid, previousSkin);

public SkinTestOver(playerid, previousSkin)
{

  	gPlayerTestSkin[playerid] = false;
  	SetPlayerSkin(playerid, previousSkin);
  	SendClientMessage(playerid, LBLUE, " * Your test run is over.");
	return 1;
}
enum EntereableEnum //entrances to each building
{
	Float:enterX,
	Float:enterY,
	Float:enterZ
}

new EnterableEntities[][EntereableEnum] = //entrance coords
{
	//BUSSINESSES
	{2112.7048,-1214.2882,23.9670} //Name(id) : Suburban Los Santos(0)(interior id: 1),
	//------------------------------------
};

enum BuildingInteriorsData //interior of each building
{
	Float:interiorX,
	Float:interiorY,
	Float:interiorZ
}
new BuildingInteriors[][BuildingInteriorsData] = //coords of interiors
{
	{204.1174, -46.8047, 1001.8047} //Name(id) : Suburban Los Santos(0),
};
/*
LoadEntranceIcons()
{
	new Float: X, Float:Y, Float:Z;
	for(new i = 0; i <= sizeof(EnterableEntities); i++)
	{
	    X = EnterableEntities[i][interiorX];
	    Y = EnterableEntities[i][interiorY];
	    Z = EnterableEntities[i][interiorZ];
	 	CreatePickup(1239, 1, X, Y, Z, 0);
	}
	
	Create3DTextLabel("Sub Urban Los Santos\nType /enter to enter.", WHITE, EnterableEntities[0][interiorX], EnterableEntities[0][interiorY], EnterableEntities[0][interiorZ], 5.0, 0, 0); //LSPD frontdoor
	
	return 1;
}
*/
IsPlayerInRangeOfEntrance(playerid)
{
	new Float:playerX, Float:playerY, Float:playerZ;
	GetPlayerPos(playerid, playerX, playerY, playerZ);
	
	new id = -1;
	for(new i = 0; i <= sizeof(EnterableEntities); i++)
	{
	    if(IsPlayerInRangeOfPoint(playerid, 5.0, EnterableEntities[i][enterX], EnterableEntities[i][enterY], EnterableEntities[i][enterZ]))
	    {
			id = i;
			break;
	    }
	    else continue;
	}
	return id;
}
PutPlayerInBuilding(playerid, buildingid)
{
	switch(buildingid)
	{
	    case 0: //suburban ls
	    {
	        //put player in interior
	        SetPlayerInterior(playerid, 1);
	        SetPlayerPos(playerid, BuildingInteriors[buildingid][interiorX], BuildingInteriors[buildingid][interiorY], BuildingInteriors[buildingid][interiorZ]);

	    }
	    default: return 0;
	}
	return 1;
}
IsPlayerInRangeOfExit(playerid)
{
	new Float:playerX, Float:playerY, Float:playerZ;
	GetPlayerPos(playerid, playerX, playerY, playerZ);

	new id = -1;
	for(new i = 0; i <= sizeof(EnterableEntities); i++)
	{
	    if(IsPlayerInRangeOfPoint(playerid, 5.0, BuildingInteriors[i][interiorX], BuildingInteriors[i][interiorY], BuildingInteriors[i][interiorZ]))
	    {
			id = i;
			break;
	    }
	    else continue;
	}
	return id;
}

ExitPlayerFromBuilding(playerid, buildingid)
{
	SetPlayerPos(playerid, EnterableEntities[buildingid][enterX], EnterableEntities[buildingid][enterY], EnterableEntities[buildingid][enterZ]);
	SetPlayerInterior(playerid, 0);
	return 1;
}

IsPlayerInBuilding(playerid, buildingid)
{
	new bool:status;
	switch(buildingid)
	{
	    case 0:
	    {
			if(GetPlayerInterior(playerid) == 1) status = true; //suburban ls
			else status = false;
	    }
	    default: status = false;
	}
	return status;
}

stock RandomChance(proportion)
{
	new value = random(proportion);
	return value;
}

IsPlayerInRangeOfPlayer(player1, player2, Float:range) //is player 1 in range of player 2
{
//	new Float:p1X, Float:p1Y, Float:p1Z;
	new Float:p2X, Float:p2Y, Float:p2Z;
	
//	GetPlayerPos(player1, p1X, p1Y, p1Z);
	GetPlayerPos(player2, p2X, p2Y, p2Z);
	
	if(IsPlayerInRangeOfPoint(player1, range, p2X, p2Y, p2Z)) return true;
	return false;
}

IsPlayerServerAdmin(toCheck)
{
	if(PlayerInfo[toCheck][pAdmin] == 1) return true;

	else return false;
}

/*Credits to Dracoblue*/

new bool:srvAdmin[MAX_PLAYERS];
new bool:isWanted[MAX_PLAYERS];

GetWantedPlayersCount()
{
	new ammount;
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
		if(isWanted[i])
		{
		    ammount++;
		}
	}
	return ammount;
}

PlayerIp(playerid)
{
  new ip[16];
  GetPlayerIp(playerid, ip, sizeof(ip));
  return ip;
}

new gSecondsSinceStartup;
GetSecondsSinceStartup()
{
	return gSecondsSinceStartup / 60000;
}

forward AddSecond();
public AddSecond()
{
	gSecondsSinceStartup++;
}

new bool:customCheckpoint[MAX_PLAYERS], gCustCheckTimer[MAX_PLAYERS];
SetCheckpointToPlayer(toCheckpoint, toLocate)
{
	new Float:X, Float:Y, Float:Z;

	GetPlayerPos(toLocate, X, Y, Z);


	SetPlayerCheckpoint(toCheckpoint, X, Y, Z, 5.0);

	customCheckpoint[toCheckpoint] = true;



	gCustCheckTimer[toCheckpoint] = SetTimerEx("CustomCheckpoint", 1500, true, "ii", toCheckpoint, toLocate);
	
	return 1;
}
DisableCheckpointToPlayer(toDisable)
{
	DisablePlayerCheckpoint(toDisable);
	customCheckpoint[toDisable] = false;
	KillTimer(gCustCheckTimer[toDisable]);

	return 1;

}

forward CustomCheckpoint(toCheckpoint, toLocate);
public CustomCheckpoint(toCheckpoint, toLocate)
{
	if(customCheckpoint[toCheckpoint])
	{
    	new Float:X, Float:Y, Float:Z;
		GetPlayerPos(toLocate, X, Y, Z);
		SetPlayerCheckpoint(toCheckpoint, X, Y, Z, 5.0);
	}

	return 1;

}

ReturnPlayerJob(player)
{
	new job[64];

	switch(PlayerInfo[player][pJob])
	{
	    case 0: format(job, 64, "Unemployed");
	    case 1: format(job, 64, "Drug Dealer");
	    case 2: format(job, 64, "Drug Supplier");
	    default: format(job, 64, "INVALID");
	}
	return job;
}
GetPlayerJob(player)
{
	new jobID;
	
	for(new i = 0; i <= sizeof(playerJob); ++i)
	{
	    if(PlayerInfo[player][pJob] == i)
	    {
	        jobID = i;
	        break;
	    }
	}
	return jobID;
}

IsPlayerInRangeOfJob(player, job)
{

	new bool:status;
	
	if(job == 0) return status = false;
	
	switch(job)
	{
	    case 1: if(IsPlayerInRangeOfPoint(player, 15.0, 2212.4729,-2044.7767,13.5469)) return status = true;//drug dealer LS
	    case 2: if(IsPlayerInRangeOfPoint(player, 15.0, -2043.8435,1232.6671,31.6484)) return status = true; //supplier SF
	   
	}

	return status;

}
//-------------------------------------------------------------------------------------------------------------------------
main()
{
	print("\n----------------------------------");
	print("Mish Mash by strawloki");
	print("----------------------------------\n");
}



public OnGameModeInit()
{
	SetTimer("AddSecond", 1000, true);

	// Don't use these lines if it's a filterscript
	UsePlayerPedAnims();
    //LoadEntranceIcons();
	DisableInteriorEnterExits();
	
	AddStaticVehicle(411,-2645.0276,1379.1677,6.8913,270.2996,64,1); // SPAWN_SF_INFERNUS_01
	AddStaticVehicle(560,-2645.3958,1370.1592,6.8706,269.6046,9,39); // SPAWN_SF_SULTAN_01
	AddStaticVehicle(415,-2645.0789,1374.8688,6.9373,89.8730,36,1); // SPAWN_SF_CHEETAH_01
	AddStaticVehicle(522,-2645.5840,1366.5865,6.7400,87.3599,7,79); // SPAWN_SF_NRG500_01
	AddStaticVehicle(559,-2645.5061,1361.9836,6.8224,268.1624,58,8); // SPAWN_SF_JESTER_01
	AddStaticVehicle(521,-2617.4846,1377.7788,6.7076,183.6342,75,13); // SPAWN_FCR900_01
	AddStaticVehicle(596,1558.6707,-1710.3900,5.6141,357.3579,0,1); // MISHMASH_LS_LSPDHQ_POLICECAR01
	AddStaticVehicle(596,1570.3359,-1710.4628,5.6116,1.2785,0,1); // MISHMASH_LS_LSPDHQ_POLICECAR02
	AddStaticVehicle(596,1574.4202,-1710.1465,5.6107,2.5866,0,1); // MISHMASH_LS_LSPDHQ_POLICECAR03
	AddStaticVehicle(596,1578.9292,-1709.7583,5.6128,4.4820,0,1); // MISHMASH_LS_LSPDHQ_POLICECAR04
	AddStaticVehicle(523,1583.7445,-1710.2285,5.4633,357.2284,0,0); // MISHMASH_LS_LSPDHQ_HPV1000_01
	AddStaticVehicle(523,1587.7421,-1710.1182,5.4633,355.1857,0,0); // MISHMASH_LS_LSPDHQ_HPV1000_02
	AddStaticVehicle(523,1591.4536,-1710.1327,5.4626,0.7370,0,0); // MISHMASH_LS_LSPDHQ_HPV1000_03
	AddStaticVehicle(420,-2124.3982,-866.0760,31.8030,265.1079,6,1); // MISHMASH_TAXISF_TAXI01
	AddStaticVehicle(420,-2124.6978,-869.0810,31.8030,269.9733,6,1); // MISHMASH_TAXISF_TAXI02
	AddStaticVehicle(420,-2124.2422,-872.5120,31.8014,270.2090,6,1); // MISHMASH_TAXISF_TAXI03
	AddStaticVehicle(420,-2124.0051,-875.7546,31.8017,269.7689,6,1); // MISHMASH_TAXISF_TAXI04
	AddStaticVehicle(420,-2124.5066,-879.1544,31.8042,269.2123,6,1); // MISHMASH_TAXISF_TAXI05
	AddStaticVehicle(420,-2124.5066,-882.1359,31.8034,270.5925,6,1); // MISHMASH_TAXISF_TAXI06
	AddStaticVehicle(420,-2134.4375,-866.1369,31.8016,87.6846,6,1); // MISHMASH_TAXISF_TAXI07
	AddStaticVehicle(420,-2134.7202,-869.5505,31.8014,90.3331,6,1); // MISHMASH_TAXISF_TAXI08
	AddStaticVehicle(420,-2134.7368,-872.5688,31.8024,91.3299,6,1); // MISHMASH_TAXISF_TAXI09
	AddStaticVehicle(420,-2134.6128,-876.0925,31.8028,87.3045,6,1); // MISHMASH_TAXISF_TAXI10
	AddStaticVehicle(420,-2134.4070,-879.0130,31.8025,92.6012,6,1); // MISHMASH_TAXISF_TAXI11
	AddStaticVehicle(420,-2133.9014,-882.2913,31.8032,87.0873,6,1); // MISHMASH_TAXISF_TAXI12
	AddStaticVehicle(438,-2133.5977,-853.7712,32.0269,90.4232,6,76); // MISHMASH_TAXISF_CABBIE01
	AddStaticVehicle(438,-2133.7810,-850.4107,32.0260,89.5589,6,76); // MISHMASH_TAXISF_CABBIE02
	AddStaticVehicle(438,-2124.6963,-853.7400,32.0285,270.6587,6,76); // MISHMASH_TAXISF_CABBIE03
	AddStaticVehicle(438,-2124.8416,-850.4964,32.0287,271.0287,6,76); // MISHMASH_TAXISF_CABBIE04
	AddStaticVehicle(438,-2124.8770,-847.1948,32.0277,267.3840,6,76); // MISHMASH_TAXISF_CABBIE05
	AddStaticVehicle(438,-2133.9602,-847.5134,32.0272,90.1814,6,76); // MISHMASH_TAXISF_CABBIE06


	Create3DTextLabel("LSPD Headquarters", WHITE, 1553.7343,-1676.0154,16.1953, 5.0, 0, 0); //LSPD frontdoor
	CreatePickup(1239, 1, 1553.7343,-1676.0154,16.1953, 0);

	Create3DTextLabel("Cops and robbers minigame\nType /copsandrobbers to enter", WHITE, 1310.2595,-1367.2544,13.5261, 5.0, 0, 0); //cops and robbers ls
	CreatePickup(1239, 1, 1310.2595,-1367.2544,13.5261, 0); //cops and robbers ls
	
	Create3DTextLabel("Drug Supplier\nType /employhere to work here.", WHITE, -2043.8435,1232.6671,31.6484, 5.0, 0, 0); //Supplier SF
	CreatePickup(1239, 1, -2043.8435,1232.6671,31.6484, 0);

    Create3DTextLabel("Suburban Los Santos\nType /enter to enter\nEntry Fee: yes", WHITE, 1553.7343,-1676.0154,16.1953, 5.0, 0, 0); //Suburban LS
    CreatePickup(1239, 1, EnterableEntities[0][enterX], EnterableEntities[0][enterY], EnterableEntities[0][enterZ], 0);

    Create3DTextLabel("Survival Gamemode\nType /entersurvival to enter the minigame", WHITE, -2766.3821,375.5034,6.3347, 5.0, 0, 0); //Survival Minigame
    CreatePickup(1239, 1, -2766.3821,375.5034,6.3347, 0);
    
	SetGameModeText("Mish Mash");
	//AddPlayerClass(72, -2626.8721,1381.5051,7.1694,179.8942, 0, 0, 0, 0, 0, 0);
	return 1;
}

public OnGameModeExit()
{
	/*
	for(new i = 0; i<= GetPlayerPoolSize(); i++)
	{
		if(!IsPlayerConnected(i)) continue;
	    new INI:File = INI_Open(UserPath(i));
    	INI_SetTag(File,"data");
 		INI_WriteInt(File,"Cash",GetPlayerMoney(i));
    	INI_WriteInt(File,"Admin",PlayerInfo[i][pAdmin]);
 		INI_WriteInt(File,"Kills",PlayerInfo[i][pKills]);
    	INI_WriteInt(File,"Deaths",PlayerInfo[i][pDeaths]);
    	INI_WriteInt(File, "Faction", PlayerInfo[i][pFaction]);
    	INI_WriteInt(File, "FactionRank", PlayerInfo[i][pFactionRank]);
    	INI_Close(File);
    }
    */
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, -2681.6416,1399.5428,55.8125);
	SetPlayerCameraPos(playerid, -2681.6416,1399.5428,55.8125);
	SetPlayerCameraLookAt(playerid, -2681.6416,1399.5428,55.8125);
	return 1;
}

public OnPlayerConnect(playerid)
{
    new name[MAX_PLAYER_NAME], string2[23 + MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof(name));
	format(string2, sizeof(string2), "%s joined the server.", name);
	SendClientMessageToAll(0xFFFF00FF, string2);
	
	LoadMapIcons(playerid);
	
	if(fexist(UserPath(playerid)))
    {
        INI_ParseFile(UserPath(playerid), "LoadUser_%s", .bExtra = true, .extra = playerid);
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Login time", "Type your password to log in", "Login", "Disconnect");
    }
    else
    {
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "New Account", "Type your new password below.", "Confirm", "Disconnect");
    }
    
    
    
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{

    new name[MAX_PLAYER_NAME], string2[23 + MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof(name));
	format(string2, sizeof(string2), "%s has left the server.", name);
	SendClientMessageToAll(0xFFFF00FF, string2);
	
	//get player's weapons
	/*
	new weapon[13][2];
	
	for(new i = 0; i <= 12; i++)
	{
	    GetPlayerWeaponData(playerid, i, weapon[i][0], weapon[0][i]);
	}
	
	//-------------------------------------------
 */
	new INI:File = INI_Open(UserPath(playerid));
    INI_SetTag(File,"data");
    INI_WriteInt(File,"Cash",GetPlayerMoney(playerid));
    INI_WriteInt(File,"Admin",PlayerInfo[playerid][pAdmin]);
    INI_WriteInt(File,"Kills",PlayerInfo[playerid][pKills]);
    INI_WriteInt(File,"Deaths",PlayerInfo[playerid][pDeaths]);
    INI_WriteInt(File, "Faction", PlayerInfo[playerid][pFaction]);
    INI_WriteInt(File, "FactionRank", PlayerInfo[playerid][pFactionRank]);
    INI_WriteInt(File, "Police_Arrests", PlayerInfo[playerid][pPoliceArrests]);
    INI_WriteInt(File, "Job", PlayerInfo[playerid][pJob]);
    INI_WriteInt(File, "Jail_time", PlayerInfo[playerid][pJailTime]);
    INI_WriteInt(File, "DrugDealerLS_delivs", PlayerInfo[playerid][pDrugDealerLSdelivs]);
    INI_WriteInt(File, "Marijuana_amount", PlayerInfo[playerid][pMarijuanaAmount]);
    INI_WriteInt(File, "Cocaine_amount", PlayerInfo[playerid][pCocaineAmount]);
    INI_WriteInt(File, "Ecstacy_amount", PlayerInfo[playerid][pEcstacyAmount]);
    INI_WriteInt(File, "Meth_amount", PlayerInfo[playerid][pMethAmount]);
    INI_WriteInt(File, "Krokodil_amount", PlayerInfo[playerid][pKrokodilAmount]);
    INI_WriteInt(File, "Crack_amount", PlayerInfo[playerid][pCrackAmount]);
    INI_WriteInt(File, "Supplier_cooldown", PlayerInfo[playerid][pDrugSupplierCool]);
    INI_WriteInt(File, "PlayerDrugAddiction", PlayerInfo[playerid][pDrugAddiction]);
    INI_Close(File);
	
	
	if(onGamemode[playerid])
	{
		

	    if(gPlayerVotedToStart[playerid]) gPlayersVotedToStart--; //does it get reset too?

	    gOnCPSLobby[playerid] = false;
	    gCPSLobbyCount--;

	    if(gCPSPlayerTeam[playerid] == 0)//cops
	    {
	        gCPSPlayerTeam[playerid] = -1;
	        gCPSCopsCount--;
	        if(gCPSCopsCount == 0)
	        {
	            SendMessageToCPS(" * Team Cops is out of players and the game may not continue;", 2, LBLUE);
	            EndCPS();
	        }
	    }

	    if(gCPSPlayerTeam[playerid] == 1)//robbers
	    {
	        gCPSPlayerTeam[playerid] = -1;
	        gCPSRobbersCount--;
	        if(gCPSRobbersCount == 0)
	        {
	            SendMessageToCPS(" * Team Robbers is out of players and the game may not continue;", 2, LBLUE);
	            EndCPS();
	        }
	    }
	
        new msg[128];
		new pName[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pName, sizeof(pName));

		format(msg, sizeof(msg), "Player %s has disconnected. People in lobby: %i", pName, gCPSLobbyCount);
		onGamemode[playerid]= false;

		for(new k = 0; k <= MAX_PLAYERS; k++)
		{
		    if(!IsPlayerConnected(k)) continue;
		    if(!onGamemode[k]) continue;

		    if(onGamemode[k])
		    {
		        SendClientMessage(k, RED, msg);
		    }

		}
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(onGamemode[playerid])
	{
	    onGamemode[playerid] = false;
	
	    SetPlayerPos(playerid, 1310.2595,-1367.2544,13.5261);
		SetPlayerInterior(playerid, 0);
		SetPlayerVirtualWorld(playerid, 0);
	}

	switch(PlayerInfo[playerid][pFaction])
	{
	    case FACTION_LSPD:
	    {
	        LoadLSPD(PlayerInfo[playerid][pFactionRank], playerid);
		}
		case FACTION_SFPD:
		{
		    LoadSFPD(PlayerInfo[playerid][pFactionRank], playerid);
		}
		case FACTION_LVPD:
		{
		    LoadLVPD(PlayerInfo[playerid][pFactionRank], playerid);
		}
		case FACTION_TAXI:
		{
			LoadTaxi(playerid, PlayerInfo[playerid][pFactionRank]);
		}
		default: //civilian
		{
		    if(PlayerInfo[playerid][pJailTime] > 0)
    		{
        		SendClientMessage(playerid, RED, "You've still got jail time to serve.");
      	  		JailPlayer(playerid, PlayerInfo[playerid][pJailTime], "Jail sentence incomplete.");
      	  		SetPlayerColor(playerid, WHITE);
      	  		SetPlayerSkin(playerid, 72);
    		}
		
		    else
		    {
				SetPlayerColor(playerid, WHITE);
		    	SetPlayerPos(playerid, -2626.8721,1381.5051,7.1694);
		    	SetPlayerSkin(playerid, 72);
		    	GivePlayerWeapon(playerid, 10,1);
		    	GivePlayerWeapon(playerid, 28, 300);
		    }
		}
	        
	}
	
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{

	SetPlayerWantedLevel(killerid, GetPlayerWantedLevel(killerid) + 1);
	isWanted[killerid] = true;
	
	new msg[128], killerName[MAX_PLAYER_NAME], playerName[MAX_PLAYER_NAME];
	GetPlayerName(killerid, killerName, sizeof(killerName));
	GetPlayerName(playerid, playerName, sizeof(playerName));
	format(msg, sizeof(msg), "CRIMELOG: Player %s(ID %i) has committed a crime against player %s(ID %i).", killerName, killerid, playerName, playerid);
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    if(onGamemode[i]) continue;
	    
	    if(GetPlayerFaction(i) == 1 || GetPlayerFaction(i) == 2 || GetPlayerFaction(i) == 3)
	    {
	        SendClientMessage(i, COLOR_POL, msg);
	    }
	}

    PlayerInfo[killerid][pKills]++;
    PlayerInfo[playerid][pDeaths]++;
    
    if(onGamemode[playerid])
    {
        
        gOnCPSLobby[playerid] = false;
        gCPSLobbyCount--;
		gPlayerVotedToStart[playerid] = false;
		DisablePlayerCheckpoint(playerid);

        
        switch(GetPlayerCPSTeam(playerid))
        {
            case 0:
            {
				gCPSPlayerTeam[playerid] = -1;
				gCPSLiveCops--;
				
				

				SendClientMessage(playerid, GREEN, "You died during the Cops and Robbers minigame and have been kicked out.");
				
				if(GetPlayerCPSTeam(playerid) == GetPlayerCPSTeam(killerid))
				{
				    new msg1[128], killerName1[MAX_PLAYER_NAME], playerName1[MAX_PLAYER_NAME];
				    GetPlayerName(killerid, killerName1, sizeof(killerName1));
				    GetPlayerName(playerid, playerName1, sizeof(playerName1));
				    
				    format(msg1, 128, "Cop %s teamkilled cop %s and has been kicked out of the game.", killerName1, playerName1);
				    
				    SendMessageToCPS(msg1, 2, RED);
				    
				    onGamemode[killerid] = false;
        			gOnCPSLobby[killerid] = false;
        			gCPSLobbyCount--;
					gPlayerVotedToStart[killerid] = false;
					
					gCPSPlayerTeam[killerid] = -1;
					gCPSLiveCops--;

					SetPlayerPos(killerid, 1310.2595,-1367.2544,13.5261);
					SetPlayerInterior(killerid, 0);
					SetPlayerVirtualWorld(killerid, 0);
					
					new killerMsg[128];
					format(killerMsg, 128, "You have been kicked out of the minigame for teamkilling %s.", playerName1);
					
					SendClientMessage(killerid, RED, killerMsg);

				}
				else
				{
				    new msgToCops[128], killerName2[MAX_PLAYER_NAME], playerName2[MAX_PLAYER_NAME];
				    
				    GetPlayerName(killerid, killerName2, sizeof(killerName2));
				    GetPlayerName(playerid, playerName2, sizeof(playerName2));
				    
				    format(msgToCops, 128, "Robber %s has killed cop %s. %i cops remain.", killerName2, playerName2, gCPSLiveCops);
				    
				    SendMessageToCPS(msgToCops, 2, RED);
				    
				
				}


				
            }
            case 1:
            {
                gCPSPlayerTeam[playerid] = -1;
				gCPSLiveRobbers--;


				SendClientMessage(playerid, GREEN, "You died during the Cops and Robbers minigame and have been kicked out.");
				
				if(GetPlayerCPSTeam(playerid) == GetPlayerCPSTeam(killerid))
				{
				    new msg2[128], killerName3[MAX_PLAYER_NAME], playerName3[MAX_PLAYER_NAME];
				    GetPlayerName(killerid, killerName3, sizeof(killerName3));
				    GetPlayerName(playerid, playerName3, sizeof(playerName3));

				    format(msg2, 128, "Robber %s teamkilled robber %s and has been kicked out of the game.", killerName3, playerName3);

				    SendMessageToCPS(msg2, 2, RED);

				    onGamemode[killerid] = false;
        			gOnCPSLobby[killerid] = false;
        			gCPSLobbyCount--;
					gPlayerVotedToStart[killerid] = false;

					gCPSPlayerTeam[killerid] = -1;
					gCPSLiveCops--;

					SetPlayerPos(killerid, 1310.2595,-1367.2544,13.5261);
					SetPlayerInterior(killerid, 0);
					SetPlayerVirtualWorld(killerid, 0);

					new killerMsg[128];
					format(killerMsg, 128, "You have been kicked out of the minigame for teamkilling %s.", playerName3);

					SendClientMessage(killerid, RED, killerMsg);

				}
				else
				{
				    new msgToRobbers[128], killerName4[MAX_PLAYER_NAME], playerName4[MAX_PLAYER_NAME];

				    GetPlayerName(killerid, killerName4, sizeof(killerName4));
				    GetPlayerName(playerid, playerName4, sizeof(playerName4));

				    format(msgToRobbers, 128, "Cop %s has killed robber %s. %i robbers remain.", killerName4, playerName4, gCPSLiveRobbers);
				    
				    SendMessageToCPS(msgToRobbers, 2, RED);


				}
            }
        }
    }
    
    if(gPlayerInSurvivalLobby[playerid])
    {
		//get name and shit
        ExitPlayerFromSurvivalLobby(playerid);
    }
    
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	if(vehicleid == gDrugDealerLScarID)
	{
	    SendClientMessage(killerid, WHITE, "The delivery car is destroyed! You are fired!");
	    DisablePlayerCheckpoint(killerid);
	    gDrugRowID = -1;
	    gDrugDealerLScarID = -1;
	    OnJob[killerid] = false;
	}
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

/*public OnPlayerCommandText(playerid, cmdtext[])
{
	if (strcmp("/mycommand", cmdtext, true, 10) == 0)
	{
		// Do something here
		return 1;
	}
	return 0;
}
*/
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if(vehicleid == gDrugDealerLScarID)
	{
	    PickDrugDealerLoc(playerid, gDrugRowID);
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	if(customCheckpoint[playerid])
	{
	    customCheckpoint[playerid] = false;
	    SendClientMessage(playerid, GREEN, "You have reached your destination.");
	    DisablePlayerCheckpoint(playerid);
	}
	
	if(copDeliverToLS[playerid] || copDeliverToSF[playerid] || copDeliverToLV[playerid])
	{
	    SendClientMessage(playerid, GREEN, "You can now put the suspect into jail and have bad things happen to him in the showers.");
     	copDeliverToLS[playerid] = false;
     	copDeliverToSF[playerid] = false;
     	copDeliverToLV[playerid] = false;
     	DisablePlayerCheckpoint(playerid);
	}

	if(gOnFare[playerid])
	{
	    gOnFare[playerid] = false;
		DisablePlayerCheckpoint(playerid);
		
		SendClientMessage(playerid, COLOR_VLBLUE, "You have reached your customer.");

	}
	
	if(workLocCP[playerid])
	{
	    DisablePlayerCheckpoint(playerid);
	    workLocCP[playerid] = false;
	}
	
	if(gCopCPtoBank[playerid])
	{
	    DisablePlayerCheckpoint(playerid);
	    SendMessageToCPS(" * You are at the bank!", 0, LBLUE);
	    gCopCPtoBank[playerid] = false;
	}
	if(gRobCPtoDropoff[playerid])
	{
		DisablePlayerCheckpoint(playerid);
		gRobCPtoDropoff[playerid] = false;
		RobberEnterCPS(playerid);
		
	}
	
	if(gDrugDealerToCarCP[playerid])
	{

	    gDrugDealerToCarCP[playerid] = false;
	    DisablePlayerCheckpoint(playerid);
	}
	
	if(gDrugDealerToDestCP[playerid])
	{
	    if(IsPlayerInVehicle(playerid, gDrugDealerLScarID))
	    {
	        DestroyVehicle(gDrugDealerLScarID);
	        new string[128];
	        format(string, 128, "You have delivered the drugs successfully and earned $%i.", DrugsLocations[gDrugRowID][Payment]);
			GivePlayerMoney(playerid, DrugsLocations[gDrugRowID][Payment]);
			OnJob[playerid] = false;
			gDrugRowID = -1;
			gDrugDealerLScarID = -1;
			AddPlayerDrugDeliverySkill(playerid);

	        
	        SendClientMessage(playerid, WHITE, string);
	        DisablePlayerCheckpoint(playerid);
	        
	    }
	    else SendClientMessage(playerid, WHITE, "You are missing the delivery car.");
	   
	}
	if(gPlayerInSurvivalLobby[playerid])
	{
	    gIsPlayerInSurvCP[playerid] = true;
	    gPlayersInSurvivalCP++;
	    SendMessageToSurvival("You have entered the checkpoint. You are counted in for the reward.", GREEN);
	    DisablePlayerCheckpoint(playerid); //maybe remove?
	}
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	if(success)
	{
	    for(new i = 0; i <= MAX_PLAYERS; i++)
		{
		    if(strcmp(ip, PlayerIp(i), true) == 0)
			{
			    srvAdmin[i] = true;
			    SendClientMessage(i, WHITE, "Logged in as RCON admin.");
			    break;
			}
		}
	}
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch( dialogid )
    {
        case DIALOG_REGISTER:
        {
            if (!response) return Kick(playerid);
            if(response)
            {
                if(!strlen(inputtext)) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Wrong Password", "Try again.", "OK", "Cancel");
                new INI:File = INI_Open(UserPath(playerid));
                INI_SetTag(File,"data");
                INI_WriteInt(File,"Password",udb_hash(inputtext));
                INI_WriteInt(File,"Cash",0);
                INI_WriteInt(File,"Admin",0);
                INI_WriteInt(File,"Kills",0);
                INI_WriteInt(File,"Deaths",0);
                INI_WriteInt(File, "Faction", 0);
                INI_WriteInt(File, "FactionRank", 0);
                INI_Close(File);

                SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
                SpawnPlayer(playerid);
                ShowPlayerDialog(playerid, DIALOG_SUCCESS_1, DIALOG_STYLE_MSGBOX, "You actually got in", "Nice job, now relog.", "OK", "");
            }
        }

        case DIALOG_LOGIN:
        {
            if ( !response ) return Kick ( playerid );
            if( response )
            {
                if(udb_hash(inputtext) == PlayerInfo[playerid][pPass])
                {
                    INI_ParseFile(UserPath(playerid), "LoadUser_%s", .bExtra = true, .extra = playerid);
                    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);
                    PlayerInfo[playerid][pAdmin] = PlayerInfo[playerid][pAdmin];
                    PlayerInfo[playerid][pFaction] = PlayerInfo[playerid][pFaction];
                    PlayerInfo[playerid][pFactionRank] = PlayerInfo[playerid][pFactionRank];
                    PlayerInfo[playerid][pPoliceArrests] = PlayerInfo[playerid][pPoliceArrests];
                    PlayerInfo[playerid][pJob] = PlayerInfo[playerid][pJob];
                    PlayerInfo[playerid][pJailTime] = PlayerInfo[playerid][pJailTime];

                    
                }
                else
                {
                    ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Incorrect password", "Try again.", "OK", "Abort");
                }
                return 1;
            }
        }
        case DIALOG_POL_SANCTION:
        {
            if(response)
            {
                
                if(listitem == 0)
                {
					//attack on officer = 3
					
					new msg1[128], msg2[128], sancName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];
					
					GetPlayerName(gToSanction[playerid], sancName, sizeof(sancName));
					GetPlayerName(playerid, copName, sizeof(copName));
					
					format(msg1, sizeof(msg1), "Officer {000099}%s {FFFF00}has sanctioned you with the crime 'Attack on officer'.", copName);
					format(msg2, sizeof(msg2), "You have sanctioned  suspect {FF4500}%s {FFFF00}of the crime 'Attack on officer'.", sancName);
					SendClientMessage(gToSanction[playerid], YELLOW, msg1);
					SendClientMessage(playerid, YELLOW, msg2);
					
					SetPlayerWantedLevel(gToSanction[playerid], GetPlayerWantedLevel(gToSanction[playerid]) + 3);
					
					gToSanction[playerid] = -1;
                }
                else if(listitem == 1)
                {
                    //killing an officer, 5
                    
                    new msg1[128], msg2[128], sancName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];

					GetPlayerName(gToSanction[playerid], sancName, sizeof(sancName));
					GetPlayerName(playerid, copName, sizeof(copName));
					
					format(msg1, sizeof(msg1), "Officer {000099}%s {FFFF00}has sanctioned you with the crime 'Killing an officer'. ", copName);
					format(msg2, sizeof(msg2), "You have sanctioned  suspect {FF4500}%s {FFFF00}of the crime 'Killing an officer'.", sancName);
					SendClientMessage(gToSanction[playerid], YELLOW, msg1);
					SendClientMessage(playerid, YELLOW, msg2);
					
					SetPlayerWantedLevel(gToSanction[playerid], GetPlayerWantedLevel(gToSanction[playerid]) + 5);

					gToSanction[playerid] = -1;

                }
                else if(listitem == 2)
				{
				    new msg1[128], msg2[128], sancName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];

					GetPlayerName(gToSanction[playerid], sancName, sizeof(sancName));
					GetPlayerName(playerid, copName, sizeof(copName));

					format(msg1, sizeof(msg1), "Officer {000099}%s {FFFF00FF}has sanctioned you with the crime 'Unpaid fine'. ", copName);
					format(msg2, sizeof(msg2), "You have sanctioned  suspect {FF4500}%s {FFFF00FF}of the crime 'Unpaid fine'.", sancName);
					SendClientMessage(gToSanction[playerid], YELLOW, msg1);
					SendClientMessage(playerid, YELLOW, msg2);

					SetPlayerWantedLevel(gToSanction[playerid], GetPlayerWantedLevel(gToSanction[playerid]) + 2);

					gToSanction[playerid] = -1;
				
				}
				else if(listitem == 3)
				{
				    new msg1[128], msg2[128], sancName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];

					GetPlayerName(gToSanction[playerid], sancName, sizeof(sancName));
					GetPlayerName(playerid, copName, sizeof(copName));

					format(msg1, sizeof(msg1), "Officer {000099}%s {FFFF00FF}has sanctioned you with the crime 'Resisting Arrest'. ", copName);
					format(msg2, sizeof(msg2), "You have sanctioned  suspect {FF4500}%s {FFFF00FF}of the crime 'Resisting Arrest'.", sancName);
					SendClientMessage(gToSanction[playerid], YELLOW, msg1);
					SendClientMessage(playerid, YELLOW, msg2);

					SetPlayerWantedLevel(gToSanction[playerid], GetPlayerWantedLevel(gToSanction[playerid]) + 5);

					gToSanction[playerid] = -1;
				
				}
                
                
                
            }

		}
		case DIALOG_CPS_TEAM:
		{
		    
		
		    if(response) //button cops
		    {
	    	   if(gCPSRobbersCount == 0 && gCPSCopsCount == 1)
  		       {
				 SendClientMessage(playerid, LBLUE, "ERROR: There are no players in team robbers, you must join team robbers.");
				 ShowPlayerDialog(playerid, DIALOG_CPS_TEAM, DIALOG_STYLE_MSGBOX, "Choose team", "Click on one of the buttons down below to choose a team.", "Team Cops", "Team Robbers");
		       }
		       else
		       {
		       	gCPSPlayerTeam[playerid] = 0; //team cops
		       	new pName[MAX_PLAYER_NAME];
		       	new msg[128];
		       	GetPlayerName(playerid, pName, sizeof(pName));

				gCPSCopsCount++;
				format(msg, 128, "Player %s has joined team cops. Total cops: %i", pName, gCPSCopsCount);
				
				for(new p = 0; p <= MAX_PLAYERS; p++)
		       	{
				   if(!IsPlayerConnected(p)) continue;
				    
				   if(onGamemode[p])
				   {
				    	SendClientMessage(p, GREEN, msg);
				    	SendClientMessage(p, GREEN, "In order for the game to start, all players must type /start.");
				   }
				    
			   	}
		       
		      }
		    }
		    else //robbers
		    {
			   if(gCPSRobbersCount == 1 && gCPSCopsCount == 0)
			   {
			        SendClientMessage(playerid, LBLUE, "ERROR: There are no players in team cops, you must join team cops.");
			        ShowPlayerDialog(playerid, DIALOG_CPS_TEAM, DIALOG_STYLE_MSGBOX, "Choose team", "Click on one of the buttons down below to choose a team.", "Team Cops", "Team Robbers");
			        
			   }
		    
			   else
			   {
   			   	gCPSPlayerTeam[playerid] = 1;
		        
   			   	new pName[MAX_PLAYER_NAME];
		       	new msg[128];
		       	GetPlayerName(playerid, pName, sizeof(pName));

			   	gCPSRobbersCount++;

			  	format(msg, 128, "Player %s has joined team robbers. Total robbers: %i", pName, gCPSRobbersCount);

			   	for(new p = 0; p <= MAX_PLAYERS; p++)
		       	{
				   if(!IsPlayerConnected(p)) continue;

				   if(onGamemode[p])
				   {
				    	SendClientMessage(p, GREEN, msg);
				    	SendClientMessage(p, GREEN, "In order for the game to start, all players must type /start.");
				   }

			   	}
               }
		        
		    }
		
		}
		case 6969: //suburban ls
		{
		    if(response)
		    {
		        if(listitem == 0) //cj
		        {
		            new previousSkin = GetPlayerSkin(playerid);
		        
		            SetPlayerSkin(playerid, 0);
		            SetTimerEx("SkinTestOver", 30000, false, "ii", playerid, previousSkin);
		            ShowPlayerDialog(playerid, 901, DIALOG_STYLE_MSGBOX, "Information", "You have a 30 second test-run with your potential new skin. Make good use of it and decide wether you want to buy it or not.", "OK", "");
		            gPlayerTestSkin[playerid] = true;
		        }
		        else if(listitem == 1) //sweet
		        {
		            new previousSkin = GetPlayerSkin(playerid);

		            SetPlayerSkin(playerid, 270);
		            SetTimerEx("SkinTestOver", 30000, false, "ii", playerid, previousSkin);
		            ShowPlayerDialog(playerid, 901, DIALOG_STYLE_MSGBOX, "Information", "You have a 30 second test-run with your potential new skin. Make good use of it and decide wether you want to buy it or not.", "OK", "");
		            gPlayerTestSkin[playerid] = true;
		        }
		    }
		}
		case DIALOG_SURVIVAL_GEAR:
		{
		   
		
		    if(response)
		    {
		        new string[128];
				switch(listitem)
				{
				    case 0:
				    {
				        GivePlayerWeapon(playerid, 31, 24);
				        format(string, 128, "You have bought 24 bullets for {473d49}M4.");
				        SendClientMessage(playerid, GRAY, string);
				        GivePlayerMoney(playerid, -500);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				        
				    }
				    case 1:
				    {
				        GivePlayerWeapon(playerid, 24, 24);
				        format(string, 128, "You have bought 24 bullets for {473d49}Deagle.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -235);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
				    case 2:
				    {
                        GivePlayerWeapon(playerid, 8, 1);
				        format(string, 128, "You have bought a {473d49}Katana.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -1200);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
				    case 3:
				    {
				    	GivePlayerWeapon(playerid, 22, 11);
				        format(string, 128, "You have bought 11 bullets for {473d49}9mm Pistol.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -175);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
				    case 4:
				    {
				        GivePlayerWeapon(playerid, 25, 1);
				        format(string, 128, "You have bought 1 bullet for {473d49}Shotgun.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -50);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
				    case 5:
				    {
				        GivePlayerWeapon(playerid, 26, 4);
				        format(string, 128, "You have bought 4 bullets for {473d49}Sawn-Off Shotgun.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -152);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
				    case 6:
				    {
				        gPlayerHealthSnacks[playerid]++;
				        format(string, 128, "You have bought 1 {473d49}Health Bar.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -24);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
				    case 7:
				    {
				        GivePlayerWeapon(playerid, 27, 7);
				        format(string, 128, "You have bought 7 rounds for {473d49}Combat Shotgun.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -385);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
			     	case 8:
				    {
				        GivePlayerWeapon(playerid, 33, 33);
				        format(string, 128, "You have bought 1 round for {473d49}Rifle.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -48);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000", "Buy", "Exit");
				    }
			     	case 9:
				    {
				        GivePlayerWeapon(playerid, 46, 1);
				        format(string, 128, "You have bought a{473d49}Parachute.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -1200);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
			     	case 10:
				    {
				        GivePlayerWeapon(playerid, 16, 1);
				        format(string, 128, "You have bought 1{473d49}Grenade.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -1000);
				        ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }
			     	case 11:
				    {
						SetPlayerArmour(playerid, 100.0);
				        format(string, 128, "You have bought {473d49}Body Armour.");
				        SendClientMessage(playerid, GREEN, string);
				        GivePlayerMoney(playerid, -500);
			         	ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmor:\t$500", "Buy", "Exit");
				    }


				   

				}
		    }
		    
		}

    }
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}
CMD:veh(playerid, params[])
{
	new car, Vehicle;
	
	new Float:X, Float:Y, Float:Z;
	
	GetPlayerPos(playerid, Float:X, Float:Y, Float:Z);

	if(sscanf(params, "i", car)) SendClientMessage(playerid, LBLUE, "Missing parameters, dumbass.");
	
	else if(car < 400 || car > 611) SendClientMessage(playerid, LBLUE, "The parameter is too high, they didn't make that many models.");
	
	Vehicle = CreateVehicle(car, X, Y, Z, 0, -1, -1, -1);
	PutPlayerInVehicle(playerid, Vehicle, 0);
	return 1;
}

CMD:makeadmin(playerid, params[])
{
	new playerToAdmin;

	if(IsPlayerAdmin(playerid))
	{
	    if(sscanf(params, "i", playerToAdmin)) return SendClientMessage(playerid, LBLUE, "Missing parameters, dumbass.");
	    
	    else if(playerToAdmin < 0 || playerToAdmin > MAX_PLAYERS) return SendClientMessage(playerid, LBLUE, "Wat? IMPOSSIBUL!");
	    
		PlayerInfo[playerToAdmin][pAdmin] = 1;
		
		new name[MAX_PLAYER_NAME], string[MAX_PLAYER_NAME + 23];
		GetPlayerName(playerToAdmin, name,sizeof(name));
		format(string, sizeof(string), "%s is now admin.", name);
		
	    SendClientMessageToAll(LRED, string);
	}
	return 1;
}
CMD:money(playerid)
{
	GivePlayerMoney(playerid, 1000);
	return 1;
}


CMD:setfaction(playerid, params[])
{
	new Factionee, rank, factionid;
	
	if(PlayerInfo[playerid][pAdmin] == 1)
	{
	    if(sscanf(params, "iii", Factionee, factionid, rank)) return SendClientMessage(playerid, LBLUE, "Missing parameters, dumbass.\nUsage: /setfaction <player to enroll in faction> <factionid> <rank>");
	    
	    PlayerInfo[Factionee][pFaction] = factionid;
	    PlayerInfo[Factionee][pFactionRank] = rank;
	    
	    new message[128], enrollerName[MAX_PLAYER_NAME + 24];
	    GetPlayerName(playerid, enrollerName, sizeof(enrollerName));
	    format(message, sizeof(message), "You have been enrolled into faction %i with the rank %i by leader %s. Have fun or whatever.", factionid, rank, enrollerName);
	    
	    SendClientMessage(Factionee, GREEN, message);
	    
	}
	else return SendClientMessage(playerid, LBLUE, "What are you, like and admin or something?");

	return 1;
}

CMD:listwanted(playerid)
{
	if(GetPlayerFaction(playerid) == 0 || GetPlayerFaction(playerid) == 4)
	{
	    SendClientMessage(playerid, LBLUE, "ERROR: You aren't authorized to access that, dummy.");
	}
	
	

	new msg[128], wantedName[MAX_PLAYER_NAME];
	
	SendClientMessage(playerid, WHITE, "-----LIST OF WANTED PLAYERS-----");
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;

	    if(isWanted[i])
	    {
			GetPlayerName(i, wantedName, sizeof(wantedName));
			format(msg, sizeof(msg), "WANTED: %s\tID: %i", wantedName, i);
			SendClientMessage(playerid, LBLUE, msg);
		}
	}
	
	new msg2[128];
	format(msg, sizeof(msg), "Total wanted players on the server: %i", GetWantedPlayersCount());
	SendClientMessage(playerid, WHITE, msg2);
	
	

	return 1;
}

CMD:tp(playerid, params[])
{
	if(!IsPlayerServerAdmin(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: Only super-duper special admins can use that command.");
	
	new toTeleport;
	
	if(sscanf(params, "i", toTeleport)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /tp <id of player to teleport to>");
	
	new Float:X, Float:Y, Float:Z;
	
	GetPlayerPos(toTeleport, X, Y, Z);
	
	SetPlayerPos(playerid, X, Y, Z);
	


	return 1;
}

CMD:cptoplayer(playerid, params[])
{
	if(!IsPlayerServerAdmin(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: Only super-duper special admins can use that command.");

	new toCp;
	
	if(sscanf(params, "i", toCp))return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /cptoplayer <id of player to set a checkpoint to>");

	if(!IsPlayerConnected(toCp)) return SendClientMessage(playerid, LBLUE, "ERROR: The player you're trying to locate doesn't seem to exist on this server my man.");

	SetCheckpointToPlayer(playerid, toCp);
	return 1;
}

CMD:locatesuspect(playerid, params[])
{
	if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
	
	new toCp;
	
	if(sscanf(params, "i", toCp))return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /locatesuspect <id of player to set a checkpoint to>");
	
	if(!isWanted[toCp]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
	
	SetCheckpointToPlayer(playerid, toCp);
	
	new copName[MAX_PLAYER_NAME], suspectName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, copName, sizeof(copName));
	GetPlayerName(toCp, suspectName, sizeof(suspectName));
	
	new msg[128];
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    
	    if(IsPlayerCop(i)) 
	    {
	        format(msg, sizeof(msg), "ALL UNITS: Officer %s is locating suspect %s.", copName, suspectName);
	        SendClientMessage(i, COLOR_POL, msg);

	    }
	    
	}
	
	return 1;


}

CMD:testcuff(playerid)
{
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CUFFED);
	return 1;
}

CMD:stopanim(playerid)
{
	ClearAnimations(playerid);
	return 1;
}

CMD:stopac(playerid)
{
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	return 1;
}

CMD:pol(playerid, params[])
{
	if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
	
	new pol;
	
	if(sscanf(params, "i", pol)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /pol <player to ask to surrender>");
	
	if(!isWanted[pol]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
	
	new Float:crimX, Float:crimY, Float:crimZ;
	
	
	GetPlayerPos(pol, crimX, crimY, crimZ);
	
	if(IsPlayerInRangeOfPoint(playerid, crimX, crimY, crimZ, 25.0))
	{
	
		new msg[128], polMsg[128], polName[MAX_PLAYER_NAME], criminalName[MAX_PLAYER_NAME];
	
		GetPlayerName(playerid, polName, sizeof(polName));
		GetPlayerName(pol, criminalName, sizeof(criminalName));
	
		format(msg, sizeof(msg), "This is officer %s! Stop where you are and surrender, %s!", polName, criminalName);
		format(polMsg, sizeof(polMsg), "This is officer %s! Stop where you are and surrender, %s!{000066}[Get in the officer's car to surrender].", polName, criminalName);
	
		SendClientMessage(pol, YELLOW, polMsg);
		SendClientMessage(playerid, YELLOW, msg);
	}
	else SendClientMessage(playerid, LBLUE, "ERROR. You aren't in range of the specified player.");
	return 1;
}

CMD:arrest(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
    
   	new pol, city[1];

	if(sscanf(params, "si", city,pol)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /arrest <LS/SF/LV> <player to arrest>");

	if(!isWanted[pol]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
	

	
	if(strcmp(city, "ls", true) != 0)
	{
	    SetPlayerCheckpoint(playerid, 1568.6843,-1689.9703,6.2188, 5.0);
     	copDeliverToLS[playerid] = true;

		SendClientMessage(playerid, GREEN, "Deliver the suspect to the LSPD HQ parking lot.");
	}
	else if(strcmp(city, "sf", true) != 0)
	{
	    SetPlayerCheckpoint(playerid, -1591.0804,716.0178,-5.2422, 3.0);
     	copDeliverToSF[playerid] = true;

        SendClientMessage(playerid, GREEN, "Deliver the suspect to the SFPD HQ parking lot.");
	}
	else if(strcmp(city, "lv", true) != 0)
	{
	    SetPlayerCheckpoint(playerid, 2282.1343,2431.3362,3.2734, 3.0);
     	copDeliverToLV[playerid] = true;

		SendClientMessage(playerid, GREEN, "Deliver the suspect to the LVPD HQ parking lot.");
	
	}
	else
	{
		SendClientMessage(playerid, LBLUE, "ERROR: What city is THAT?\nMake sure the city name is something like 'ls'(in non-capical characters).");
	}
	return 1;
}
CMD:jail(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
    
    new toJail;
    
    if(sscanf(params, "i", toJail)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /jail <player to put in jail>");
    
    if(!isWanted[toJail]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
    
    

	if(IsPlayerInRangeOfPoint(playerid, 5.0, 1568.6843,-1689.9703,6.2188) || IsPlayerInRangeOfPoint(playerid, 5.0, -1591.0804,716.0178,-5.2422) || IsPlayerInRangeOfPoint(playerid, 5.0, 2282.1343,2431.3362,3.2734)) //LS
	{
	    if(IsPlayerInRangeOfPoint(toJail, 5.0, 1568.6843,-1689.9703,6.2188) || IsPlayerInRangeOfPoint(toJail, 5.0, -1591.0804,716.0178,-5.2422) || IsPlayerInRangeOfPoint(toJail, 5.0, 2282.1343,2431.3362,3.2734))
	    {
	        new wantedLevel;
	        
	        wantedLevel = GetPlayerWantedLevel(toJail);
	        
	        new milisecondsToJail = (wantedLevel * 20000) + 300000;
	        PlayerInfo[toJail][pJailTime] = milisecondsToJail;
	        new copPayment = (GetPlayerWantedLevel(toJail) * 100) + 125;
	        new copBonus = (PlayerInfo[playerid][pPoliceArrests] * 60) * 25 / 100;
	        
	        if(copBonus > 0)
	        {
	            new finalPayment = copPayment + copBonus;
	            GivePlayerMoney(playerid, finalPayment);
	            
	            new paymentStatement[128], wantedName[MAX_PLAYER_NAME];
	            GetPlayerName(toJail, wantedName, sizeof(wantedName));
	            format(paymentStatement, sizeof(paymentStatement), "Payment statement for arresting %s\n--------------------------------\nInitial income: $%i\nBonus: $%i\nTotal: $%i\n--------------------------------", wantedName, copPayment, copBonus, finalPayment);
	            SendClientMessage(playerid, DARK_GREY, paymentStatement);
	            
	            
			}
	        else
	        {
	            new paymentStatement[128], wantedName[MAX_PLAYER_NAME];
	            GetPlayerName(toJail, wantedName, sizeof(wantedName));
	            format(paymentStatement, sizeof(paymentStatement), "Payment statement for arresting %s\n--------------------------------\nInitial income: $%i\nBonus: $%i\nTotal: $%i\n--------------------------------", wantedName, copPayment, copBonus, copPayment);
	            SendClientMessage(playerid, DARK_GREY, paymentStatement);

	            GivePlayerMoney(playerid, copPayment);
	        }
			isWanted[toJail] = false;
			SetPlayerWantedLevel(toJail, 0);
			PlayerInfo[playerid][pPoliceArrests]++;
			Uncuff(toJail);
			JailPlayer(toJail, milisecondsToJail, "Arrested by police officer.");
			
	    }
	    else return SendClientMessage(playerid, LBLUE, "ERROR: Suspect specified isn't in range of any police precinct.");
	}
	else return SendClientMessage(playerid, LBLUE, "ERROR: YOU aren't in range of any police precinct.");
	return 1;
}

CMD:cuff(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
    

    new toCuff;

    if(sscanf(params, "i", toCuff)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /cuff <player to cuff>");
    if(!IsPlayerInRangeOfPlayer(playerid, toCuff, 5.0)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in range of the specified player.");

    if(!isWanted[toCuff]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");

	Cuff(toCuff);
	
	new msg[128], msg2[128], cuffedName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, copName, sizeof(copName));
	
	GetPlayerName(toCuff, cuffedName, sizeof(cuffedName));
	format(msg, sizeof(msg), "You have been cuffed by officer %s", copName);
	SendClientMessage(toCuff, RED, msg);


	format(msg2, sizeof(msg2), "You have cuffed suspect %s.", cuffedName);
	SendClientMessage(playerid, GREEN, msg2);

	return 1;
}

CMD:uncuff(playerid, params[])
{

    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");

    new toUncuff;

    if(sscanf(params, "i", toUncuff)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /uncuff <player to uncuff>");
    if(!IsPlayerInRangeOfPlayer(playerid, toUncuff, 5.0)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in range of the specified player.");
    
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
    
    new msg[128], msg2[128], uncuffName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];
    
    GetPlayerName(toUncuff, uncuffName, sizeof(uncuffName));
    GetPlayerName(playerid, copName, sizeof(copName));
    
	Uncuff(toUncuff);

	format(msg, sizeof(msg), "You have uncuffed suspect %s, make sure they don't run away or something.", uncuffName);
	
	format(msg2, sizeof(msg2), "Officer %s uncuffed you. Behave yourself now.", copName);
	
	SendClientMessage(playerid, LBLUE, msg);
    SendClientMessage(toUncuff, LBLUE, msg2);
	return 1;

}

CMD:stats(playerid)
{
	new stats[256];
	
	format(stats, sizeof(stats), "Kills: %i\nDeaths: %i\nFaction: %s\nFaction Rank: %i\nNumber of criminals arrested: %i\nAdmin: %i\nJob: %s\nJail Time(min): %i", PlayerInfo[playerid][pKills], PlayerInfo[playerid][pDeaths], ReturnPlayerFaction(playerid), PlayerInfo[playerid][pFactionRank], PlayerInfo[playerid][pPoliceArrests], PlayerInfo[playerid][pAdmin], ReturnPlayerJob(playerid), PlayerInfo[playerid][pJailTime] / 60000);
	ShowPlayerDialog(playerid, 13434, DIALOG_STYLE_MSGBOX, "Stats", stats, "OK", "");
	return 1;
}

CMD:sanction(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
    
    new toSanction;

    if(sscanf(params, "i", toSanction)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /sanction <player to sanction>");

   // if(!isWanted[toSanction]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
    
    new msg[128], sanctionName[MAX_PLAYER_NAME];
	GetPlayerName(toSanction, sanctionName, sizeof(sanctionName));
	
	format(msg, sizeof(msg), "Sanction suspect %s (ID: %i)", sanctionName, toSanction);
	
	ShowPlayerDialog(playerid, DIALOG_POL_SANCTION, DIALOG_STYLE_LIST, msg, "Attack on officer(3)\nKilling an officer(5)\nUnpaid Fine(2)\nResisting Arrest", "Sanction", "Cancel");
	
	gToSanction[playerid] = toSanction;
    
    return 1;
}

CMD:enroll(playerid, params[])
{
	if(!IsPlayerFactionLeader(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a faction leader.");
	
	new player, rank, faction;
	
	faction = GetPlayerFaction(playerid);
	
	if(sscanf(params, "ii", player, rank)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters.\nUsage: /enroll <player to enroll into faction> <rank>");
	
	//player already in faction
	
	if(GetPlayerFaction(player) != 0 ) return SendClientMessage(playerid, LBLUE, "ERROR: Player specified is already part of a faction.");
	if(rank >= 7) return SendClientMessage(playerid, LBLUE, "ERROR: Rank is too high(max 6) or you inputted rank 7(leader, and you cannot have 2 leaders at the same time).");
	
	PlayerInfo[player][pFaction] = faction;
	PlayerInfo[player][pFactionRank] = rank;
	
	new msg1[128], leadName[MAX_PLAYER_NAME], playerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, leadName, sizeof(leadName));
	GetPlayerName(player, playerName, sizeof(playerName));
	
	format(msg1, sizeof(msg1), "Leader %s has enrolled player %s in the faction with the rank %i. Contragulations!", leadName, playerName, rank);

	for(new i = 0; i <=MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    
	    if(GetPlayerFaction(i) == faction)
		{
		    SendClientMessage(i, COLOR_FACT_ENROLL, msg1);
		}
	}

	return 1;
}
CMD:promote(playerid, params[])
{
    if(!IsPlayerFactionLeader(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a faction leader.");
    
    new player, rank, faction;
    
    if(sscanf(params, "ii", player, rank)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters.\nUsage: /promote <player to promote> <new rank>");
    
    faction = GetPlayerFaction(playerid);
    
    if(GetPlayerFaction(player) != faction) return SendClientMessage(playerid, LBLUE, "ERROR: Player specified isn't in the same faction as the leader.");
    
    if(rank >= 7) return SendClientMessage(playerid, LBLUE, "ERROR: Rank is too high.");
    
    PlayerInfo[player][pFactionRank] = rank;
    
    new msg1[128], leadName[MAX_PLAYER_NAME], playerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, leadName, sizeof(leadName));
	GetPlayerName(player, playerName, sizeof(playerName));

	format(msg1, sizeof(msg1), "Leader %s has promoted player %s with the rank %i. Contragulations!", leadName, playerName, rank);

	for(new i = 0; i <=MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;

	    if(GetPlayerFaction(i) == faction)
		{
		    SendClientMessage(i, COLOR_FACT_ENROLL, msg1);
		}
	}
  
	return 1;

}

CMD:kickout(playerid, params[])
{
    if(!IsPlayerFactionLeader(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a faction leader.");
    //if(!IsPlayerServerAdmin(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a server admin.");

	new player, reason[256];
	
	if(sscanf(params, "is", player, reason)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters.\nUsage: /kickout <player to kick out> <reason(TEXT)>.");
	
	new faction = GetPlayerFaction(playerid);
	
	new msg[128], leadName[MAX_PLAYER_NAME], kickName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, leadName, sizeof(leadName));
	GetPlayerName(player, kickName, sizeof(kickName));
	
	format(msg, sizeof(msg), "Leader %s has kicked out player %s from the faction. Reason: '%s'", leadName, kickName, reason);
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    
		if(GetPlayerFaction(i) == faction)
		{
		    SendClientMessage(i, COLOR_FACT_ENROLL, msg);
		}
	}
	
	PlayerInfo[player][pFaction] = 0;
	PlayerInfo[player][pFactionRank] = 1;
	SpawnPlayer(player);
	
	return 1;
}

CMD:ordertaxi(playerid)
{
    if(gIsLookingForTaxi[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You already called for a taxi, wait for a response or cancer your order.");

	gIsLookingForTaxi[playerid] = true;

	SendClientMessage(playerid, COLOR_VLBLUE, "You have ordered a taxi, please wait for a response.");
	
	new msg[128], orderName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, orderName, sizeof(orderName));
	format(msg, 128, "Player %s is looking for a taxi. Type /acceptorder %i to accept their order.", orderName, playerid);
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    if(GetPlayerFaction(i) != 4) continue;
	    
	    if(GetPlayerFaction(i) == 4)
	    {
	        SendClientMessage(i, COLOR_VLBLUE, msg);
	    }
	}
	
	return 1;

}

CMD:acceptorder(playerid, params[])
{
    if(GetPlayerFaction(playerid) != 4) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't part of the Taxi faction.");
    
    if(gOnFare[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You've already accepted another fare.");
    
    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't driving a taxi.");
    
    if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
    {
         if(GetVehicleModel(GetPlayerVehicleID(playerid)) != 420) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't driving a proper taxi.");
    }

    new toAccept;
    
    if(sscanf(params, "i", toAccept)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /acceptorder <id of player to accept>");
    
    if(!gIsLookingForTaxi[toAccept]) return SendClientMessage(playerid, LBLUE, "ERROR: Player specified is not looking for a taxi.");

    
    SetCheckpointToPlayer(playerid, toAccept);
    gOnFare[playerid] = true;
    
    new msg1[128], msg2[128], orderName[MAX_PLAYER_NAME], taxiName[MAX_PLAYER_NAME];
    
    GetPlayerName(toAccept, orderName, sizeof(orderName));
    GetPlayerName(playerid, taxiName, sizeof(taxiName));
    
    format(msg1, sizeof(msg1), "Taxi driver %s has accepted your order, maintain your current position until they arrive.", taxiName);
    format(msg2, 128, "Taxi driver %s has accepted the order of client %s(ID: %i).", taxiName, orderName, toAccept);
    
    SendClientMessage(toAccept, COLOR_VLBLUE, msg1);
    
    for(new i = 0; i<= MAX_PLAYERS; ++i)
    {
        if(!IsPlayerConnected(i)) continue;
        if(GetPlayerFaction(i) != 4) continue;
    
        if(GetPlayerFaction(i) == 4)
        {
            SendClientMessage(i, COLOR_VLBLUE, msg2);
        }
    }
    gIsLookingForTaxi[toAccept] = false;
    
    
    new taxiVehID = GetPlayerVehicleID(playerid);
    gTaxiDriverTimerID[playerid] = SetTimerEx("AcceptOrderChecks", 1500, true, "iii", playerid, toAccept, taxiVehID);
    
    return 1;
    
    //do taxing on tickcount before & after
    
    
    

}

CMD:cancelorder(playerid, params[])
{
	if(!gIsLookingForTaxi[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You weren't looking for a taxi to begin with.");
	
	new taxi;
	if(sscanf(params, "i", taxi)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /cancerorder <id of taxi driver who accepter your order>");
	
	if(!gOnFare[taxi]) return SendClientMessage(playerid, LBLUE, "ERROR: That player isn't on a fare.");
	
	gIsLookingForTaxi[playerid] = false;
	gOnFare[taxi] = false;
	
	DisableCheckpointToPlayer(taxi);
	
	SendClientMessage(playerid, COLOR_VLBLUE, "You have cancelled your taxi order.");
	
	new msg[128], name[MAX_PLAYER_NAME];
	
	GetPlayerName(playerid, name, sizeof(name));
	
	format(msg, 128, "Player %s has cancelled their taxi order, you're off duty now.", name);
	
	SendClientMessage(taxi, COLOR_VLBLUE, msg);
	
	return 1;
	
	//ADD FOR DISCONNECT

	
}

CMD:endfare(playerid, params[])
{

    if(GetPlayerFaction(playerid) != 4) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't part of the Taxi faction.");
    
    new toEndFare;
    
    if(sscanf(params, "i", toEndFare)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /endfare <player to end fare with>");
    

  
    TaxTaxiFare(toEndFare, gTaxiOldSeconds[playerid], GetSecondsSinceStartup(), playerid);
  
	return 1;
	
}

CMD:employhere(playerid)
{
	if(PlayerInfo[playerid][pJob] != 0) return SendClientMessage(playerid, LBLUE, "ERROR: You are already employed somewhere.");

	
	if(IsPlayerInRangeOfJob(playerid, 1)) //Drug Dealer LS
	{
	    PlayerInfo[playerid][pJob] = 1;
	    
	    SendClientMessage(playerid, COLOR_JOBBLUE, "You have employed yourself as a drugdealer.");
	
	}
	
	else if(IsPlayerInRangeOfJob(playerid, 2))
	{
	    if(ReturnDrugDealerSkill(playerid) != 5) return SendClientMessage(playerid, LBLUE, "You need to have skill 5 as a drug dealer in Los Santos in order to take this job.");
	    PlayerInfo[playerid][pJob] = 2;
	    SendClientMessage(playerid, COLOR_JOBBLUE, "You have employed yourself as a drug supplier.");
	}
	else return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in range of any jobs.");
	    
	return 1;

}

CMD:quitjob(playerid)
{
	PlayerInfo[playerid][pJob] = playerJob[JOB_UNEMPLOYED];
    SendClientMessage(playerid, COLOR_JOBBLUE, "You are now jobless.");
	return 1;
}


CMD:work(playerid)
{
	if(OnJob[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You are already working.");

	switch(GetPlayerJob(playerid))
	{
	    case 0: return SendClientMessage(playerid, LBLUE, "ERROR: You aren't even employed.");
	    case 1:
		{
		    if(IsPlayerInRangeOfJob(playerid, 1))
		    {

				InitiateDrugDealerJob(playerid);
				OnJob[playerid] = true;
			}
			
			else
			{
			    SendClientMessage(playerid, WHITE, "You aren't even at the right location. Follow the misterious red dot on your map to get to that right location I was talking about.");
				SetPlayerCheckpoint(playerid, 2212.4729,-2044.7767,13.5469, 5.0);
				workLocCP[playerid] = true;

			    
			}
		}
		case 2:
		{
		    if(IsPlayerInRangeOfJob(playerid, 2))
		    {
		        SendClientMessage(playerid, LBLUE, " * Your job is to buy drugs at a set price and sell them on to customers around you. Use /buydrugs to buy drugs and /drugprices for the prices.");
		    }
		    else
		    {
		        SendClientMessage(playerid, WHITE, "Wrong location");
		    }
		}
		
	}
	
	return 1;
}

CMD:copsandrobbers(playerid)
{
	if(isWanted[playerid]) SendClientMessage(playerid, LBLUE, "ERROR: You can't join this minigame while wanted.");
	
	if(onGamemode[playerid]) SendClientMessage(playerid, LBLUE, "ERROR: You are already on a minigame.");
	
	if(IsPlayerInRangeOfPoint(playerid, 5.0, 1310.2595,-1367.2544,13.5261))
	{
	
		SetPlayerInterior(playerid, 11);
		SetPlayerPos(playerid, 501.980987,-69.150199,998.757812);
	
		gOnCPSLobby[playerid] = true;
		onGamemode[playerid] = true;
		gCPSLobbyCount++;
		
		gCPSskin[playerid] = GetPlayerSkin(playerid);
		GetPlayerHealth(playerid, gCPShealth[playerid]);
		GetPlayerArmour(playerid, gCPSarmour[playerid]);
	
		new pName[128];
		GetPlayerName(playerid, pName, 128);
		new msg[128];
		format(msg, 128, "%s has joined the lobby. People in the lobby currently: %i", pName, gCPSLobbyCount);
		SetPlayerHealth(playerid, 999.0);
	
		for(new i = 0; i<= MAX_PLAYERS; i++)
		{
			if(!IsPlayerConnected(i)) continue;

			if(gOnCPSLobby[i])
			{
			   SendClientMessage(i, GREEN, msg);

			}

		}
		ShowPlayerDialog(playerid, DIALOG_CPS_TEAM, DIALOG_STYLE_MSGBOX, "Choose team", "Click on one of the buttons down below to choose a team.", "Team Cops", "Team Robbers");
	
	}
	else SendClientMessage(playerid, LBLUE, "ERROR: You aren't at the right location."); //also set checkpoint to location pls

	return 1;
}

CMD:start(playerid)
{
	if(!onGamemode[playerid])
	{
		SendClientMessage(playerid, LBLUE, "ERROR: You aren't in a gamemode.");
		return 1;
	}
	
	if(gPlayerVotedToStart[playerid])
	{
		SendClientMessage(playerid, LBLUE, "ERROR: You already voted to start.");
		return 1;
	}
	
	if(gCPSLobbyCount < 2)
	{
	    SendClientMessage(playerid, LBLUE, "ERROR: There must be at least 2 players until the game can start.");
	    return 1;
	}
	
	
	
	gPlayerVotedToStart[playerid] = true;
	gPlayersVotedToStart++;

	new startMsg[128];
	new pName[128];
	GetPlayerName(playerid, pName, 128);
	
	format(startMsg, 128, "%s has voted to start the minigame. Votes needed to start the minigame: %i", pName, gCPSLobbyCount - gPlayersVotedToStart); //issue is here
	
	for(new i = 0; i<= MAX_PLAYERS; i++)
	{
		if(!IsPlayerConnected(i)) continue;
		
		if(gOnCPSLobby[i])
		{
		    SendClientMessage(i, GREEN, startMsg);
		
		}
	}
	
	//check if everyone typed start
	//check if number of teams are equal by 0
	
	//old contents of if statement below: gPlayersVotedToStart == gCPSLobbyCount
	if(gCPSLobbyCount - gPlayersVotedToStart == 0)
	{
		LoadCPS();
		
	}

	return 1;

}
CMD:cps(playerid)
{
	SetPlayerPos(playerid, 1310.2595,-1367.2544,13.5261);

	return 1;
}

CMD:exitcps(playerid)
{
	if(!onGamemode[playerid]) SendClientMessage(playerid, LBLUE, "ERROR: You aren't on a gamemode.");
	
	if(onGamemode[playerid])
	{
	    
	    
	    if(gPlayerVotedToStart[playerid])
		{
		 	gPlayersVotedToStart--;
		 	gPlayerVotedToStart[playerid] = false;
		}
	    
	    gCopCPtoBank[playerid] = false;
	    gRobCPtoDropoff[playerid] = false;
	    
	    gOnCPSLobby[playerid] = false;
	    gCPSLobbyCount--;
	    
	    if(gCPSPlayerTeam[playerid] == 0)//cops
	    {
	        gCPSPlayerTeam[playerid] = -1;
	        gCPSCopsCount--;
	        gCPSLiveCops--;
	        
	        if(gCPSCopsCount == 0)
	        {
	            SendMessageToCPS(" * Team Cops is out of players and the game may not continue;", 2, LBLUE);
	            EndCPS();
	            
	        }
	    }
	    
	    if(gCPSPlayerTeam[playerid] == 1)//robbers
	    {
	        gCPSPlayerTeam[playerid] = -1;
	        gCPSRobbersCount--;
	        gCPSLiveRobbers--;
	        
	        if(gCPSRobbersCount == 0)
	        {
	            SendMessageToCPS(" * Team Robbers is out of players and the game may not continue;", 2, LBLUE);
	            EndCPS();
	        }
	    }
	    
	    SetPlayerPos(playerid, 1310.2595,-1367.2544,13.5261);
	    SetPlayerSkin(playerid, gCPSskin[playerid]);
		SetPlayerHealth(playerid, gCPShealth[playerid]);
		SetPlayerArmour(playerid, gCPSarmour[playerid]);
	    SetPlayerInterior(playerid, 0);
	    DisablePlayerCheckpoint(playerid);
	    SetPlayerVirtualWorld(playerid, 0);
	    
	    SendClientMessage(playerid, LBLUE, "You have exited the gamemode.");
	    onGamemode[playerid]= false;
	    
	    new msg[128];
		new pName[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pName, sizeof(pName));
		
		format(msg, sizeof(msg), "Player %s has left the minigame. People in lobby: %i", pName, gCPSLobbyCount);

		for(new k = 0; k <= MAX_PLAYERS; k++)
		{
		    if(!IsPlayerConnected(k)) continue;
		    if(!onGamemode[k]) continue;
		    
		    if(onGamemode[k])
		    {
		        SendClientMessage(k, RED, msg);
		    }
		    
		}
	}

	return 1;
}

CMD:ongamemode(playerid)
{
	if(onGamemode[playerid])
	{
	    SendClientMessage(playerid, WHITE, "true");
	}
	else SendClientMessage(playerid, WHITE, "false");
	
	return 1;
}

CMD:showvw(playerid)
{
	new msg[128];
	format(msg, 128, "Current virtualworld: %i", GetPlayerVirtualWorld(playerid));
	SendClientMessage(playerid, WHITE, msg);
	return 1;
}

CMD:showcpsteam(playerid)
{
	new msg[128];
	
	format(msg, 128, "Current team: %i", GetPlayerCPSTeam(playerid));
	SendClientMessage(playerid, WHITE, msg);
	return 1;
}


CMD:removecp(playerid)
{
	DisablePlayerCheckpoint(playerid);
	return 1;
}
CMD:drags(playerid)
{
	SetPlayerPos(playerid, -2043.8435,1232.6671,31.6484);
	return 1;
}
CMD:drugsonme(playerid)
{
	new drugs[128];
	format(drugs, 128, "Marijuana: %ig\nCocaine: %ig\nEcstacy: %ig\nMeth: %ig\nKrokodil: %ig\nCrack: %ig", PlayerInfo[playerid][pMarijuanaAmount], PlayerInfo[playerid][pCocaineAmount], PlayerInfo[playerid][pEcstacyAmount], PlayerInfo[playerid][pMethAmount], PlayerInfo[playerid][pKrokodilAmount], PlayerInfo[playerid][pCrackAmount]);
	ShowPlayerDialog(playerid, 947, DIALOG_STYLE_MSGBOX, "Amount of drugs in grams", drugs, "OK", "");


	return 1;
}
CMD:skills(playerid)
{
	new skills[128];
	format(skills, 128, "Drug Dealer: %i\nDeliveries as Drug Dealer: %i", ReturnDrugDealerSkill(playerid), PlayerInfo[playerid][pDrugDealerLSdelivs]);
	ShowPlayerDialog(playerid, 4834, DIALOG_STYLE_MSGBOX, "Your job skills", skills, "OK", "");
	
	return 1;
}

CMD:buydrugs(playerid, params[])
{
	if(!IsPlayerDrugSupplier(playerid)) return SendClientMessage(playerid, RED, "You are not a drug supplier.");
	if(!IsPlayerInRangeOfJob(playerid, 2)) return SendClientMessage(playerid, RED, "You need to be near the supplying site in order to buy drugs."); //add checkpoint too lazy ass
	if(IsPlayerOnSupplyCool(playerid)) return SendClientMessage(playerid, RED, "You need to wait 6 minutes or less in order to buy drugs again.");
	new drug[32], amount;


	if(sscanf(params, "si", drug, amount)) return SendClientMessage(playerid, LBLUE, "Missing parameters. Usage: /buydrugs <drug()> <amount in g(intiger only)>");

	if(!strcmp(drug, "marijuana", true))
	{
	    new cost = 10 * amount;
	    if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, LBLUE, "You cannot affort this.");
	    PlayerInfo[playerid][pMarijuanaAmount] += amount;
	    
		//cost per gram = $10
	    
		GivePlayerMoney(playerid, -cost);
		new string[128];
		format(string, sizeof(string), " * You have bought %i grams of Marijuana at a cost of $%i.", amount, cost);
		SendClientMessage(playerid, LBLUE, string);
		SetTimerEx("DrugSupplierCooldown", 60000 * 6, false, "i", playerid);
		PlayerInfo[playerid][pDrugSupplierCool] = 60000 * 6;
	}
	else if(!strcmp(drug, "cocaine", true))
	{
	    new cost = 25 * amount;
	    if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, LBLUE, "You cannot affort this.");
	    PlayerInfo[playerid][pCocaineAmount] += amount;

		//cost per gram = $25
		
		
		GivePlayerMoney(playerid, -cost);
		new string[128];
		format(string, sizeof(string), " * You have bought %i grams of Cocaine at a cost of $%i.", amount, cost);
		SendClientMessage(playerid, LBLUE, string);
		SetTimerEx("DrugSupplierCooldown", 60000 * 6, false, "i", playerid);
		PlayerInfo[playerid][pDrugSupplierCool] = 60000 * 6;
		
	}
	else if(!strcmp(drug, "ecstacy", true))
	{
	    new cost = 45 * amount;
	    if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, LBLUE, "You cannot affort this.");
	    PlayerInfo[playerid][pEcstacyAmount] += amount;

		//cost per gram = $45

		
		GivePlayerMoney(playerid, -cost);
		new string[128];
		format(string, sizeof(string), " * You have bought %i grams of Ecstacy at a cost of $%i.", amount, cost);
		SendClientMessage(playerid, LBLUE, string);
		SetTimerEx("DrugSupplierCooldown", 60000 * 6, false, "i", playerid);
		PlayerInfo[playerid][pDrugSupplierCool] = 60000 * 6;

	}
	else if(!strcmp(drug, "meth", true))
	{
	    new cost = 65 * amount;
	    if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, LBLUE, "You cannot affort this.");
	    PlayerInfo[playerid][pMethAmount] += amount;

		//cost per gram = $65

		
		GivePlayerMoney(playerid, -cost);
		new string[128];
		format(string, sizeof(string), " * You have bought %i grams of Meth at a cost of $%i.", amount, cost);
		SendClientMessage(playerid, LBLUE, string);
		SetTimerEx("DrugSupplierCooldown", 60000 * 6, false, "i", playerid);
		PlayerInfo[playerid][pDrugSupplierCool] = 60000 * 6;

	}
	else if(!strcmp(drug, "krokodil", true))
	{
	    new cost = 85 * amount;
	    if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, LBLUE, "You cannot affort this.");
	    PlayerInfo[playerid][pKrokodilAmount] += amount;

		//cost per gram = $85

		
		GivePlayerMoney(playerid, -cost);
		new string[128];
		format(string, sizeof(string), " * You have bought %i grams of Krokodil at a cost of $%i.", amount, cost);
		SendClientMessage(playerid, LBLUE, string);
		SetTimerEx("DrugSupplierCooldown", 60000 * 6, false, "i", playerid);
		PlayerInfo[playerid][pDrugSupplierCool] = 60000 * 6;

	}
	else if(!strcmp(drug, "crack", true))
	{
	    new cost = 60 * amount;
	    if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, LBLUE, "You cannot affort this.");
	    PlayerInfo[playerid][pCrackAmount] += amount;

		//cost per gram = $60

		
		GivePlayerMoney(playerid, -cost);
		new string[128];
		format(string, sizeof(string), " * You have bought %i grams of Crack at a cost of $%i.", amount, cost);
		SendClientMessage(playerid, LBLUE, string);
		SetTimerEx("DrugSupplierCooldown", 60000 * 6, false, "i", playerid);
		PlayerInfo[playerid][pDrugSupplierCool] = 60000 * 6;

	}
	
	return 1;
}

CMD:selldrugs(playerid, params[])
{
	
	new buyerid, drug[24], amount;
	if(sscanf(params, "isi", buyerid, drug, amount)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing Parameters. Usage: /selldrugs <playerid> <drug> <amount>");
	if(!IsPlayerConnected(buyerid)) return SendClientMessage(playerid, LBLUE, "ERROR: Player isn't connected.");
	if(!IsPlayerInRangeOfPlayer(playerid, buyerid, 5.0)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in range of the specified player.");
	switch(ReturnDrugID(drug))
	{
	    case 0: //marijuana
	    {
	        new cost = amount * 10;
	        if(GetPlayerMoney(buyerid) < cost ) return SendClientMessage(playerid, RED, "The player cannot afford the deal.");
	        //playerid, buyerid, drug[], amount, cost
	        SendPlayerOffer(playerid, buyerid, ReturnDrugID(drug), amount, cost);
	        
	        gOfferDrugID[buyerid] = ReturnDrugID(drug);
	        gPlayerOfferAmount[buyerid] = amount;
	        gPlayerOfferCost[buyerid] = cost;
	        gHasPendingOffer[buyerid] = true;
	        
	    }
	    case 1:
	    {
	        new cost = amount * 10;
	        if(GetPlayerMoney(buyerid) < cost ) return SendClientMessage(playerid, RED, "The player cannot afford the deal.");
	        //playerid, buyerid, drug[], amount, cost
	        SendPlayerOffer(playerid, buyerid, ReturnDrugID(drug), amount, cost);
	        gOfferDrugID[buyerid] = ReturnDrugID(drug);
	        gPlayerOfferAmount[buyerid] = amount;
	        gPlayerOfferCost[buyerid] = cost;
	        gHasPendingOffer[buyerid] = true;
		}
         case 2:
	    {
	        new cost = amount * 10;
	        if(GetPlayerMoney(buyerid) < cost ) return SendClientMessage(playerid, RED, "The player cannot afford the deal.");
	        //playerid, buyerid, drug[], amount, cost
	        SendPlayerOffer(playerid, buyerid, ReturnDrugID(drug), amount, cost);
	        gOfferDrugID[buyerid] = ReturnDrugID(drug);
	        gPlayerOfferAmount[buyerid] = amount;
	        gPlayerOfferCost[buyerid] = cost;
	        gHasPendingOffer[buyerid] = true;
		}
		 case 3:
	    {
	        new cost = amount * 10;
	        if(GetPlayerMoney(buyerid) < cost ) return SendClientMessage(playerid, RED, "The player cannot afford the deal.");
	        //playerid, buyerid, drug[], amount, cost
	        SendPlayerOffer(playerid, buyerid, ReturnDrugID(drug), amount, cost);
	        gOfferDrugID[buyerid] = ReturnDrugID(drug);
	        gPlayerOfferAmount[buyerid] = amount;
	        gPlayerOfferCost[buyerid] = cost;
	        gHasPendingOffer[buyerid] = true;
		}
		 case 4:
	    {
	        new cost = amount * 10;
	        if(GetPlayerMoney(buyerid) < cost ) return SendClientMessage(playerid, RED, "The player cannot afford the deal.");
	        //playerid, buyerid, drug[], amount, cost
	        SendPlayerOffer(playerid, buyerid, ReturnDrugID(drug), amount, cost);
	        gOfferDrugID[buyerid] = ReturnDrugID(drug);
	        gPlayerOfferAmount[buyerid] = amount;
	        gPlayerOfferCost[buyerid] = cost;
	        gHasPendingOffer[buyerid] = true;
		}
	 	case 5:
	    {
	        new cost = amount * 10;
	        if(GetPlayerMoney(buyerid) < cost ) return SendClientMessage(playerid, RED, "The player cannot afford the deal.");
	        //playerid, buyerid, drug[], amount, cost
	        SendPlayerOffer(playerid, buyerid, ReturnDrugID(drug), amount, cost);
	        gOfferDrugID[buyerid] = ReturnDrugID(drug);
	        gPlayerOfferAmount[buyerid] = amount;
	        gPlayerOfferCost[buyerid] = cost;
	        gHasPendingOffer[buyerid] = true;
		}
	}
	
	return 1;
}
CMD:acceptdeal(playerid, params[])
{
	new idseller;
	if(sscanf(params, "i", idseller)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /acceptdeal <id of seller>.");
	//range, has offer to accept or not
	if(!gHasPendingOffer[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You don't have any pending offers.");
	if(!IsPlayerInRangeOfPlayer(playerid, idseller, 5.0)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in range of the specified player.");
	if(IsPlayerDrugSupplier(playerid)) return SendClientMessage(playerid, WHITE, "ERROR: You are a supplier, you cannot accept offers");
	if(!IsPlayerConnected(idseller)) return SendClientMessage(playerid, WHITE, "ERROR: Seller id speficied isn't connected right now.");
	if(!gHasPendingOffer[playerid]) return SendClientMessage(playerid, WHITE, "ERROR: You don't have any pending offers right now.");
	
	OnPlayerAcceptOffer(idseller, playerid, gOfferDrugID[playerid], gPlayerOfferAmount[playerid], gPlayerOfferCost[playerid]);
	gHasPendingOffer[playerid] = false;
	

	return 1;
}
CMD:usedrugs(playerid, params[])
{
	new drug[24], amount;
	if(sscanf(params, "si", drug, amount)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /usedrugs <drug name> <amount to use>.");
	
	switch(ReturnDrugID(drug))
	{
	    case 0:
	    {
			if(PlayerInfo[playerid][pMarijuanaAmount] < amount) return SendClientMessage(playerid, LBLUE, " * You don't have enough marijuana for that.");
	        new Float:health;
	        GetPlayerHealth(playerid, health);
	        
			SetPlayerHealth(playerid, health + (12 * amount));
			AddPlayerAddiction(playerid, 1);
			PlayerInfo[playerid][pMarijuanaAmount] -= amount;

			new string[128];
			format(string, 128, " * You took %ig of Marijuana and earned health points and a bit of addiction.", amount);
			SendClientMessage(playerid, LBLUE, string);
	        
	    }
	    case 1:
	    {
	        if(PlayerInfo[playerid][pMarijuanaAmount] < amount) return SendClientMessage(playerid, LBLUE, " * You don't have enough cocaine for that.");
	        new Float:health;
	        GetPlayerHealth(playerid, health);

			SetPlayerHealth(playerid, health + (20 * amount));
			AddPlayerAddiction(playerid, 5);
			PlayerInfo[playerid][pCocaineAmount] -= amount;

			new string[128];
			format(string, 128, " * You took %ig of Cocaine and earned health points and a bit of addiction.", amount);
			SendClientMessage(playerid, LBLUE, string);
	    }
	    case 2:
	    {
	        if(PlayerInfo[playerid][pEcstacyAmount] < amount) return SendClientMessage(playerid, LBLUE, " * You don't have enough ecstacy for that.");
	        new Float:health;
	        GetPlayerHealth(playerid, health);

			SetPlayerHealth(playerid, health + (17 * amount));
			AddPlayerAddiction(playerid, 4);
			PlayerInfo[playerid][pEcstacyAmount] -= amount;

			new string[128];
			format(string, 128, " * You took %ig of Ecstacy and earned health points and a bit of addiction.", amount);
			SendClientMessage(playerid, LBLUE, string);
	    }
	    case 3:
	    {
	        if(PlayerInfo[playerid][pMethAmount] < amount) return SendClientMessage(playerid, LBLUE, " * You don't have enough meth for that.");
	        new Float:health;
	        GetPlayerHealth(playerid, health);

			SetPlayerHealth(playerid, health + (15 * amount)); //change into hp and gram formula
			AddPlayerAddiction(playerid, 8);
			PlayerInfo[playerid][pMarijuanaAmount] -= amount;

			new string[128];
			format(string, 128, " * You took %ig of Meth and earned health points and a bit of addiction.", amount);
			SendClientMessage(playerid, LBLUE, string);
	    }
	    case 4:
	    {
	        if(PlayerInfo[playerid][pKrokodilAmount] < amount) return SendClientMessage(playerid, LBLUE, " * You don't have enough krokodil for that.");
	        new Float:health;
	        GetPlayerHealth(playerid, health);

			SetPlayerHealth(playerid, health + (24 * amount));
			AddPlayerAddiction(playerid, 12);
			PlayerInfo[playerid][pKrokodilAmount] -= amount;

			new string[128];
			format(string, 128, " * You took %ig of Krokodil and earned health points and a bit of addiction.", amount);
			SendClientMessage(playerid, LBLUE, string);
	    }
	    case 5:
	    {
	        if(PlayerInfo[playerid][pCrackAmount] < amount) return SendClientMessage(playerid, LBLUE, " * You don't have enough crack for that.");
	        new Float:health;
	        GetPlayerHealth(playerid, health);

			SetPlayerHealth(playerid, health  + (21 * amount));
			AddPlayerAddiction(playerid, 10);
			PlayerInfo[playerid][pCrackAmount] -= amount;

			new string[128];
			format(string, 128, " * You took %ig of Crack and earned health points and a bit of addiction.", amount);
			SendClientMessage(playerid, LBLUE, string);
	    }
	}
	
	return 1;
}

CMD:addictionlevels(playerid)
{
	new string[128];
	format(string, 128, "Current drug addiciton: %i/1000", PlayerInfo[playerid][pDrugAddiction]);
	ShowPlayerDialog(playerid, 6325, DIALOG_STYLE_MSGBOX, "Addiction levels", string, "OK", "");
	return 1;
}

CMD:frisk(playerid, params[]) //add range
{
	
	if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
	
	new friskid;
	if(sscanf(params, "i", friskid)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /frisk <id of player to frisk>");
	
	if(!IsPlayerInRangeOfPlayer(playerid, friskid, 5.0)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in range of the specified player.");
	new friskName[MAX_PLAYER_NAME], officerName[MAX_PLAYER_NAME], string[128], string2[128];
	GetPlayerName(friskid, friskName, sizeof(friskName));
	GetPlayerName(playerid, officerName, sizeof(officerName));
	format(string, 128, "You are frisking %s.", friskName);
	format(string2, 128, "Officer %s is frisking you for drugs and other illegal contraband.", officerName);
	
	SendClientMessage(playerid, LBLUE, string);
	SendClientMessage(friskid, LBLUE, string2);

	for(new i = 0; i <= 5; i++)
	{
	    if(HasPlayerDrug(playerid, i))
		{
			new string3[128], toFrisked[128];
			format(string3, 128, "Player has %s on hand.", ReturnDrugName(i));
			SendClientMessage(playerid, LBLUE, string3);
			
			format(toFrisked, 128, "Officer %s has found your %s.", officerName, ReturnDrugName(i));
			
			
			SendClientMessage(friskid, RED, toFrisked);
			break;
		}
		else continue;
	}

	return 1;
}
CMD:confiscatedrugs(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
    
    new toConfisc, drug[64];
    if(sscanf(params, "is", toConfisc, drug)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing paramters. Usage: /confiscatedrugs <id of player to confiscate all drugs of> <drug name>");
    if(!IsPlayerInRangeOfPlayer(playerid, toConfisc, 5.0)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in the range of the specified player.");
    
    
    new string[128], confiscName[MAX_PLAYER_NAME], officerName[MAX_PLAYER_NAME];
    new forConfisc[128];
    
	GetPlayerName(playerid, officerName, sizeof(officerName));
	GetPlayerName(toConfisc, confiscName, sizeof(confiscName));
	switch(ReturnDrugID(drug))
	{
	    case 0:
	    {
	        format(string, 128, "You have confiscated %s's marijuana.", confiscName);
	        format(forConfisc, 128, "Officer %s confiscated all of your marijuana.", officerName);
	        
	        SendClientMessage(playerid, LBLUE, string);
		    SendClientMessage(toConfisc, LBLUE, forConfisc);
			RemoveDrugFromPlayer(playerid, 0, -1);
			
	    }
	    case 1:
	    {
	        format(string, 128, "You have confiscated %s's cocaine.", confiscName);
	        format(forConfisc, 128, "Officer %s confiscated all of your cocaine.", officerName);

	        SendClientMessage(playerid, LBLUE, string);
		    SendClientMessage(toConfisc, LBLUE, forConfisc);
			RemoveDrugFromPlayer(playerid, 1, -1);
	    }
	    case 2:
	    {
	        format(string, 128, "You have confiscated %s's ecstacy.", confiscName);
	        format(forConfisc, 128, "Officer %s confiscated all of your ecstacy.", officerName);

	        SendClientMessage(playerid, LBLUE, string);
		    SendClientMessage(toConfisc, LBLUE, forConfisc);
			RemoveDrugFromPlayer(playerid, 2, -1);
	    }
	    case 3:
	    {
	        format(string, 128, "You have confiscated %s's meth.", confiscName);
	        format(forConfisc, 128, "Officer %s confiscated all of your meth.", officerName);

	        SendClientMessage(playerid, LBLUE, string);
		    SendClientMessage(toConfisc, LBLUE, forConfisc);
			RemoveDrugFromPlayer(playerid, 3, -1);
	    }
	    case 4:
	    {
	        format(string, 128, "You have confiscated %s's krokodil.", confiscName);
	        format(forConfisc, 128, "Officer %s confiscated all of your krokodil.", officerName);

	        SendClientMessage(playerid, LBLUE, string);
		    SendClientMessage(toConfisc, LBLUE, forConfisc);
			RemoveDrugFromPlayer(playerid, 4, -1);
	    }
	    case 5:
		{
		    format(string, 128, "You have confiscated %s's crack.", confiscName);
	        format(forConfisc, 128, "Officer %s confiscated all of your crack.", officerName);

	        SendClientMessage(playerid, LBLUE, string);
		    SendClientMessage(toConfisc, LBLUE, forConfisc);
			RemoveDrugFromPlayer(playerid, 5, -1);
		}
		default:
		{
		    SendClientMessage(playerid, LBLUE, "ERROR: Wrong type of drug specified. Parameters: 'marijuana', 'cocaine', 'ecstacy', 'meth', 'krokodil', 'crack'.");
		}
	    

	}
     
    
	return 1;
}

CMD:drg(playerid)
{
	SetPlayerPos(playerid, 2212.4729,-2044.7767,13.5469);
	return 1;
}

CMD:enter(playerid)
{
	if(IsPlayerInRangeOfEntrance(playerid) == -1) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in range of any entrances.");
	switch(IsPlayerInRangeOfEntrance(playerid))
	{
	    case 0: PutPlayerInBuilding(playerid, 0); //suburban LS
		default: SendClientMessage(playerid, LBLUE, "ERROR: You aren't in range of any entrances.");
	}
	return 1;
}
CMD:exit(playerid)
{
	if(IsPlayerInRangeOfExit(playerid) == -1) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in an interior.");
	
	ExitPlayerFromBuilding(playerid, IsPlayerInRangeOfExit(playerid));
	return 1;
}
CMD:testskins(playerid)
{
	ShowPlayerDialog(playerid, 6969, DIALOG_STYLE_LIST, "Skins available for purchase", "CJ\t$650\nSweet\t$700", "Try out", "Cancel");
	if(!IsPlayerInBuilding(playerid, 0)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in the Suburban Los Santos building.");
	return 1;
}
CMD:buyskin(playerid, params[])
{
	new skinid;
	if(sscanf(params, "i", skinid)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /buyskin <id of skin to buy> (you can test out the skins with /testskins)");
	if(!IsPlayerInBuilding(playerid, 0)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in the Suburban Los Santos building.");
	
	switch(skinid)
	{
	    case 0: //cj skin, cost $650
	    {
			SetPlayerSkin(playerid, 0);
			GivePlayerMoney(playerid, -650);
			SendClientMessage(playerid, GREEN, "You've bought the CJ skin for $650!");
			//save skin, check if player has enough money
	    }
	    case 1: //sweet skin, cost $700
	    {
	        SetPlayerSkin(playerid, 270);
			GivePlayerMoney(playerid, -700);
			SendClientMessage(playerid, GREEN, "You've bought the CJ skin for $650!");
	    }
	}

	return 1;
}

CMD:entersurvival(playerid)
{
	if(gPlayerInSurvivalLobby[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You are already in the survival minigame lobby.");
	PutPlayerInSurvivalLobby(playerid);
	return 1;
}
CMD:exitsurvival(playerid)
{
    if(!gPlayerInSurvivalLobby[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in the survival minigame lobby.");
	ExitPlayerFromSurvivalLobby(playerid);
	
	return 1;
}

CMD:startsurvival(playerid)
{
	if(!gPlayerInSurvivalLobby[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in a survival gamemode lobby.");
	OnSurvivalVote(playerid);
	return 1;
}

CMD:survival(playerid)
{
	SetPlayerPos(playerid, -2766.3821,375.5034,6.3347);
	return 1;
}

CMD:amiinsurvival(playerid)
{
	if(gPlayerInSurvivalLobby[playerid]) SendClientMessage(playerid, WHITE, "You are in the survival lobby");
	else SendClientMessage(playerid, WHITE, "You're not.");
	return 1;
}

CMD:buygear(playerid)
{
    if(!gPlayerInSurvivalLobby[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in the survival minigame lobby.");
    
    ShowPlayerDialog(playerid, DIALOG_SURVIVAL_GEAR, DIALOG_STYLE_LIST, "Gear available for purchase; Total budget: $35.000", "M4(x50 rounds):\t$500\nDeagle(x50 rounds):\t$235\nKatana:\t$1500\nPistol(x11 rounds):\t$175\nShotgun(1x round):\t$50\nSawn-off(4x rounds):\t$152\nHealth Bar(+0.25 hp):\t$25\nCombat Shotgun(7x rounds):\t$378\nRifle(1x round):\t$48\nParachute:\t$1200\nGrenade:\t$1000\nArmour:\t$500", "Buy", "Exit");

	return 1;
	
}
CMD:healthbar(playerid)
{
	if(!gPlayerInSurvivalLobby[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't in the survival minigame lobby.");
	if(gPlayerHealthSnacks[playerid] < 1) return SendClientMessage(playerid, RED, "You don't have any health bars.");
	
	new Float:health;
	GetPlayerHealth(playerid, health);
	
	SetPlayerHealth(playerid, (health + 0.25));
	
	gPlayerHealthSnacks[playerid]--;

	new string[128];
	format(string, 128, "You've eaten a {b40d0d}health bar {545859}and gained a quarter more health. Health bars left: {b40d0d}%i", gPlayerHealthSnacks[playerid]);
	
	SendClientMessage(playerid, GRAY, string);
	
	
	return 1;
}
