class DWGameplayHandler : EventHandler
{
	array <SlotController> allslotmachines; //get every slot machine
	bool noPlayers;
	bool noSlotMachines; // check if slot machines should be enabled
	override void WorldLoaded(WorldEvent e)
	{
		SlotPowerUpLibrary.GetInstance();
		if (SlotPowerUpLibrary.GetReadOnlyInstance().GetLibrarySize() < 1)
		{noSlotMachines = true;}
		PlayerInfo p = players[consoleplayer];
		if(p.IsTotallyFrozen()){noPlayers = true;}//check for players or if player is on title screen
	}
	override void WorldThingDied(WorldEvent e) 
    {
       if (e.thing && e.thing.bISMONSTER && e.thing.target && e.thing.target.player)
		{
			if(noSlotMachines){return;}
			if(e.thing.target.FindInventory('PowerTiger',true)) {return;} //Disable slot machines during tiger powerup.
			int soulreq = CVar.FindCVar('DW_SoulCount').GetInt();
			float soulmult = CVar.FindCVar('DW_SoulMult').GetFloat();
			int souls;
			e.thing.target.GiveInventory("DWBloodEnergy",e.thing.GetMaxHealth()*soulmult);
			souls = e.thing.target.CountInv("DWBloodEnergy");
			if (souls >= soulreq && e.thing.target.health > 0) //check if player is alive and has enough souls
			{
				int pslotnum = PlayerSlotCount(PlayerPawn(e.thing.target));
				if(pslotnum < 3)
				{
					AddSlotMachine(PlayerPawn(e.thing.target));
				}
				e.thing.target.TakeInventory("DWBloodEnergy",souls);
			}
		}
    }
	void AddSlotMachine(PlayerPawn p) //adds slot machine to player and array
	{
		SlotController sc = SlotController.Create(p,self);
		allslotmachines.Push(sc);
	}
	int PlayerSlotCount(PlayerPawn p)
	{
		array <SlotController> playerslots;
		for(int i = 0; i < allslotmachines.Size(); ++i)
		{
			if(allslotmachines[i].owner == p)
			{
				playerslots.Push(allslotmachines[i]);
			}
		}
		return playerslots.Size();
	}
	override void RenderOverlay (RenderEvent e)
	{	
		if (noPlayers) {return;}
		if (noSlotMachines){return;}
		PlayerPawn p = players[consoleplayer].mo;
		float cxpos = CVar.FindCVar("DW_SlotXOffset").GetFloat();
		float cypos = CVar.FindCVar("DW_SlotYOffset").GetFloat();
		int cscale = CVar.FindCVar("DW_SlotScale").GetInt();
		int soulmax = CVar.FindCVar("DW_SoulCount").GetInt();
		vector2 uiscale = (cscale,cscale);
		vector2 uipos = HudPos((cxpos,cypos),uiscale,51);
		//disable hud
		if (screenblocks > 11) {return;}
		if (AutoMapActive || p.health <= 0) {return;}
		array <SlotController> pslots;
		for(int i = 0; i < allslotmachines.Size(); ++i)
		{
			if(allslotmachines[i].owner == p)
			{
				pslots.Push(allslotmachines[i]);
			}
		}
		if (pslots.Size() <= 0) //check if player has slot machines
		{
			int soulcount = p.CountInv("DWBloodEnergy");
			DrawSoulCount("DWSLBR",uipos.x,uipos.y,cscale,soulcount,soulmax);
			return;
		}
		for (int i = 0; i < pslots.size(); ++i)
		{
			int offmul = (i * StackDir());
			textureid ic = TexMan.CheckForTexture("HUDSlotM");
			DrawUIcon(ic,uipos.x,uipos.y - ((32*cscale) * offmul),cscale,false);
			textureid slt1icon = pslots[i].slot1icon.texture; //get icon 
			DrawUIcon(slt1icon,((-34 * cscale) + uipos.x),uipos.y - ((32*cscale) * offmul),cscale,true);
			//Draw slot2
			textureid slt2icon = pslots[i].slot2icon.texture;
			DrawUIcon(slt2icon,uipos.x,uipos.y - ((32*cscale) * offmul),cscale,true);
			//Draw slot3
			textureid slt3icon = pslots[i].slot3icon.texture;
			DrawUIcon(slt3icon,((34 * cscale) + uipos.x),uipos.y - ((32*cscale) * offmul),cscale,true);
		}
	}
	ui void DrawSoulCount(string img,int hudx,int hudy,int scale,int cur,int max)
	{
		if (max <= 1) {return;}
		textureid ic = TexMan.CheckForTexture("DTHMTR"); //draw bar container
		DrawUIcon(ic,hudx,hudy,scale,false);
		textureid txt = TexMan.CheckForTexture(img);
		DrawUiBar(txt,cur,max,hudx,hudy - (2 * scale),scale);
	}
	ui vector2 HudPos(Vector2 pos,Vector2 hdscale,int exOffset)
	{
		Vector2 screen_size = (Screen.GetWidth(), Screen.GetHeight()); //get screen size
		exOffset = exOffset * hdscale.x;//sets extra boundaries for UI
		float fposx = (screen_size.x) * pos.x; //get screen percent
		fposx = clamp(fposx,exOffset,screen_size.x - exOffset);
		float fposy = screen_size.y * pos.y;  //get screen percent
		fposy = clamp(fposy,18 * hdscale.y,screen_size.y - (18 * hdscale.y));
		vector2 fpos = (fposx,fposy);
		return fpos; 
	}
	ui void DrawUiBar(textureid btxt,int amount,int max,float barx, int bary, int barscale) //draw bar
	{
		//get sprite size
		vector2 spr_sc = TexMan.GetScaledSize(btxt);
		int spr_w = spr_sc.x;
		int tw = spr_w * barscale; //true width
		int spr_h = spr_sc.y;
		int th = spr_h * barscale; //true height
		vector2 bardraw = GetBarSize((tw,th),amount,max);
		screen.SetClipRect(barx-(tw/2), bary, bardraw.x, bardraw.y);
		Screen.DrawTexture(btxt, false, barx-(tw/2), bary, DTA_KeepRatio, true,
        DTA_DestWidth, tw, DTA_DestHeight, th);
		screen.ClearClipRect();
	}
	ui void DrawUIcon(textureid txt,int hudx,int hudy,int scale,bool centered)
	{
		vector2 ic_size = TexMan.GetScaledSize(txt); //get sprite size
		int sprw = ic_size.x;
		int sprh = ic_size.y;
		Screen.DrawTexture(txt, false, hudx, hudy, DTA_KeepRatio, true,
        DTA_DestWidth, sprw*scale, DTA_DestHeight, sprh*scale,DTA_CenterOffset,centered);
	}
	ui vector2 GetBarSize(Vector2 barsize,int cur, int max)
	{
		vector2 size = barsize;
		double ratio = (cur * 1.0) / max;
		size.x = size.x * ratio;
		return size;
	}
	ui int StackDir() //determins the direction slot machines stack in
	{
		bool cdir = CVar.FindCVar("DW_SlotDir").GetBool();
		if (cdir){return 1;}
		else{return -1;}
	}
	override void PlayerDied(PlayerEvent e)
	{
		int psouls;
		psouls = players[e.PlayerNumber].mo.CountInv("DWBloodEnergy");
		players[e.PlayerNumber].mo.TakeInventory("DWBloodEnergy",psouls); //Remove all souls from inventory on death
	}

}