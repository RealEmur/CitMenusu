#include <sourcemod>
#include <sdktools>
#include <warden>


public Plugin myinfo = 
{
	name = "Çit Menü", 
	author = "Emur", 
	description = "Çit", 
	version = "1.0", 
	url = "www.pluginmerkezi.com"
};

int CitSecimi[MAXPLAYERS + 1] =  { -1, ... };
static char CitNames[][] = 
{
	"Çit 1", 
	"Çit 2", 
	"Çit 3", 
	"Çit 4", 
	"Çit 5", 
	"Kutu", 
	"Varil"
}

static char CitPaths[][] = 
{
	"models/props_wasteland/interior_fence002c.mdl", 
	"models/props_c17/fence01a.mdl", 
	"models/props_urban/fence001_256.mdl", 
	"models/props_urban/wood_fence002_256.mdl", 
	"models/props_urban/ornate_fence_a.mdl", 
	"models/props_crates/static_crate_40.mdl", 
	"models/props_c17/oildrum_static.mdl"
}
public void OnPluginStart()
{
	//Bu kısma gerek yok sunucuda yetki verirken rahatlık olsun diye yapayım dedim.
	RegAdminCmd("sm_cit", command_cits, ADMFLAG_ROOT);
	RegConsoleCmd("sm_cit", command_cit);
}

public void OnMapStart()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	if(!(StrContains(map, "jb_") != -1 || StrContains(map, "jailbreak_") != -1 || StrContains(map, "ba_") != -1))
		SetFailState("[CT'YE HIZ] Bu eklenti sadece JB Modunda çalışabilir.");
	for (int i = 0; i <= 6; i++)
	{
		PrecacheModel(CitPaths[i], true);
	}
}

public Action command_cit(int client, int args)
{
	if(warden_iswarden(client))
	{
		CitSecimi[client] = 0;
		CitMenu(client).Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public Action command_cits(int client, int args)
{
	if(!warden_iswarden(client))
	{
		CitSecimi[client] = 0;
		CitMenu(client).Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

Menu CitMenu(int client)
{
	Menu menu = new Menu(menu_cit);
	menu.SetTitle("Çit Menüsü");
	char sCit[64];
	Format(sCit, sizeof(sCit), "Model: %s", CitNames[CitSecimi[client]]);
	menu.AddItem("", sCit);
	menu.AddItem("", CitSecimi[client] <= 4 ? "Çit Koy" : "Model Koy");
	menu.AddItem("", CitSecimi[client] <= 4 ? "Çiti Sil" : "Modeli Sil");
	menu.AddItem("", "Bütün Çitleri Sil");
	return menu;
}

public int menu_cit(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		switch (item)
		{
			case 0:
			{
				CitSecimi[client]++;
				if (CitSecimi[client] > 6)
					CitSecimi[client] = 0;
				CitMenu(client).Display(client, MENU_TIME_FOREVER);
			}
			case 1:
			{
				if (GetCitCount() < 30)
				{
					float Coord[3];
					GetAimCoords(client, Coord);
					if(CitSecimi[client] == 0)
						Coord[2] += 70;
					else if (CitSecimi[client] == 1)
						Coord[2] += 50;
					else if(CitSecimi[client] == 4)
						Coord[2] += 70;
					int Ent = CreateEntityByName("prop_physics_override");
					if (IsValidEntity(Ent))
					{
						DispatchKeyValue(Ent, "physdamagescale", "0.0");
						SetEntPropString(Ent, Prop_Data, "m_iName", "cit");
						
						DispatchKeyValue(Ent, "model", CitPaths[CitSecimi[client]]);
						
						DispatchSpawn(Ent);
						SetEntityMoveType(Ent, MOVETYPE_PUSH);
						float vAngles[3] = 0.0;
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", vAngles);
						float iView[3] = 0.0;
						GetClientEyeAngles(client, iView);
						vAngles[1] = iView[1];
						TeleportEntity(Ent, Coord, vAngles, NULL_VECTOR);
					}
				}
				else
					PrintToChat(client, "[SM] \x01En fazla \x0230 adet \x01çit kullanabilirsin!");
				CitMenu(client).Display(client, MENU_TIME_FOREVER);
			}
			case 2:
			{
				int ent = GetClientAimTarget(client, false);
				if (IsValidCit(ent))
					RemoveEntity(ent);
				else
					PrintToChat(client, "[SM] \x01Bir çiti hedef almıyorsun. Aimini sikiyim.");
				CitMenu(client).Display(client, MENU_TIME_FOREVER);
			}
			case 3:
			{
				ClearCits();
				PrintToChat(client, "[SM] \x01Bütün çitler silindi.");
				CitMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int GetCitCount()
{
	int CitCount = 0;
	for (int i = MaxClients + 1; i < GetMaxEntities(); i++)
	{
		if (IsValidCit(i))
			CitCount++;
	}
	return CitCount;
}

public void ClearCits()
{
	for (int i = MaxClients + 1; i < GetMaxEntities(); i++)
	{
		if (IsValidCit(i))
			RemoveEntity(i);
	}
}

public bool IsValidCit(int ent)
{
	if (IsValidEdict(ent) && IsValidEntity(ent))
	{
		char ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(ent, Prop_Data, "m_iName", ModelName, sizeof(ModelName));
		if (StrEqual(ModelName, "cit"))
			return true;
	}
	return false;
}


public void GetAimCoords(int client, float vector[3])
{
	float vAngles[3];
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
		TR_GetEndPosition(vector, trace);
	trace.Close();
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
} 