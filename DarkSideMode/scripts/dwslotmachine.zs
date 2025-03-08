class SlotController : Thinker
{
	DWGameplayHandler DWeh;
	PlayerPawn owner; //pointer to player
	int slot1Timer;
	SlotPowerUp slot1icon;
	bool slot1stopped;
	SlotPowerUp slot1items;
	int slot2Timer;
	SlotPowerUp slot2icon;
	bool slot2stopped;
	SlotPowerUp slot2items;
	int slot3Timer;
	SlotPowerUp slot3icon;
	SlotPowerUp slot3items;
	bool slot3stopped;
	int finalTimer;
	static SlotController Create(PlayerPawn pmo,DWGameplayHandler eh)
	{
		// don't create for voodoo dolls:
		if (!pmo || !pmo.player || !pmo.player.mo || pmo.player.mo != pmo)
		{
		  return null;
		}
		let sc = new('SlotController');
		sc.owner = pmo;
		sc.DWeh = eh;
		sc.Spin();
		return sc;
	}
	void Spin()
	{
		float randomnum = frandom(0.01,100.00);
		CVar cv_winchance = CVar.FindCVar('DW_WinChance');
		if (randomnum <= cv_winchance.GetFloat()) //check if the player wins
		{
			Win();
		}
		else{Lose();}
		SetTimers();
	}
	void Win()
	{
		slot1items = SlotPowerUpLibrary.GetReadOnlyInstance().GetRandomPowerPerc();
		if (slot1items.itemClassName == "RudeCar") //Player never wins rude car.
		{slot1items = SlotPowerUpLibrary.GetReadOnlyInstance().GetRandomPowerPerc(slot1items);}
		slot2items = slot1items;
		slot3items = slot1items;
	}
  void Lose()
  {
	//get random power for slot1
	slot1items = SlotPowerUpLibrary.GetReadOnlyInstance().GetRandomPowerUp();
	//get random power for slot2
	slot2items = SlotPowerUpLibrary.GetReadOnlyInstance().GetRandomPowerUp();
	//get random power for slot3
	if (slot1items == slot2items) //find a way to make it so slot 3 cannot be the same as 1 and 2 if 1 and 2 match
	{
		slot3items = SlotPowerUpLibrary.GetReadOnlyInstance().GetRandomPowerUp(slot1items);
	}
	else
	{
		slot3items = SlotPowerUpLibrary.GetReadOnlyInstance().GetRandomPowerUp();
	}
  }
  void SpinCheck(SlotPowerUp slot1, SlotPowerUp slot2,SlotPowerUp slot3) //check if the icons match
  {
	if (slot1 == slot2 && slot1 == slot3) //if they match
	{
		SlotPowerup reward = slot1;
		RewardReplace(reward.itemClassName);
		if (CVar.FindCVar('DW_RewFlash').GetBool())
		{
			let flashcolor = CVar.FindCVar('DW_RewColor').GetInt();
			owner.A_SetBlend(flashcolor, 0.9, 35);
		}
		WinSounds();
	}
  }
  void RewardReplace(string gift)
  {
	vector3 ppos = owner.pos;
	double pheight = owner.height;
	let mygift = Actor.Spawn(gift,(ppos.x + 0.01,ppos.y,ppos.z + (pheight/2)),ALLOW_REPLACE);
	owner.A_Recoil(-0.01); //give player a VERY slight push to get the powerup
  }
  void WinSounds()
  {
	CVar cv_sound = CVar.FindCVar('DW_WheelWinSounds');
	switch(cv_sound.GetInt())
	{
		case 0: //Doom
			owner.A_StartSound("sltdoom_win",CHAN_UI,CHANF_NOPAUSE|CHANF_MAYBE_LOCAL,1,ATTN_NONE,1.1);
		break;
		case 1: //NMH 2
			owner.A_StartSound("sltnmh2_win",CHAN_UI,CHANF_NOPAUSE|CHANF_MAYBE_LOCAL,1,ATTN_NONE);
		break;
		case 2: //NMH 3
			owner.A_StartSound("sltnmh3_win",CHAN_UI,CHANF_NOPAUSE|CHANF_MAYBE_LOCAL,1,ATTN_NONE);
		break;
	}
  }
  override void Tick()
  {
	if (owner.health <= 0){RemoveSlotMachine();}//check if player is alive
	if (!slot1stopped) //check if slot has stopped
	{
		slot1Timer -= 1;
		slot1icon = GetSlotTex(slot1items,slot1Timer,slot1icon);
		slot1stopped = TimerCheck(slot1Timer,"1");
	}
	if (!slot2stopped) //check if slot has stopped
	{
		slot2Timer -= 1;
		slot2icon = GetSlotTex(slot2items,slot2Timer,slot2icon);
		slot2stopped = TimerCheck(slot2Timer,"2");
	}
	if (!slot3stopped)
	{
		slot3Timer -= 1;
		slot3icon = GetSlotTex(slot3items,slot3Timer,slot3icon);
		slot3stopped = TimerCheck(slot3Timer,"3");
	}
	if (finaltimer > 0){finaltimer -= 1;} //final timer before slots get destroyed
	else {RemoveSlotMachine();} //Gives powerup if all 3 match
  }
  void SetTimers() //sets the timer for each slot to spin until they lock in 
  {
	self.slot1timer = 7;
	self.slot1stopped = false;
	self.slot2timer = 14;
	self.slot2stopped = false;
	self.slot3timer = 21;
	self.slot3stopped = false;
	self.finaltimer = 30;
  }

  void RemoveSlotMachine()
  {
	self.DWeh.allslotmachines.Delete(DWeh.allslotmachines.Find(self));
	self.Destroy();
  }
  bool TimerCheck(int timer,string slotindstr) //check if timer is out
  {
	if (timer > 0) {return false;}
	else
	{
		SlotSound(slotindstr);
		if (slotindstr == "3")
		{
			SpinCheck(slot1items,slot2items,slot3items); //Gives powerup if all 3 match
		}
		return true;
	}
  }
  SlotPowerUp GetSlotTex(SlotPowerUp sltpower,int timer,SlotPowerUp curicon) //get slot icon
  {
	SlotPowerUp cur_pwr;
	if (timer > 0)
	{
		if (curicon == null) 
		{cur_pwr = SlotPowerUpLibrary.GetReadOnlyInstance().GetRandomPowerUp();}
		else //prevent repeating frames during spinning animation
		{cur_pwr = SlotPowerUpLibrary.GetReadOnlyInstance().GetRandomPowerUp(curicon);}
		return cur_pwr;
		
	}
	else{return sltpower;}
  }
  
	void SlotSound(string sndtype) //play sound when slot locks
	{
		CVar cv_sltsound = CVar.FindCVar('DW_WheelSounds');
		string sndname;
		switch(cv_sltsound.GetInt())
		{
			case 0: //doom sounds
			sndname = "sltdoom_";
			//uses the same sound but increases pitch
			if (sndtype == "2") {owner.A_StartSound("sltdoom_1",CHAN_5,CHANF_NOPAUSE|CHANF_MAYBE_LOCAL,1,ATTN_NONE,1.5);
			return;}
			if (sndtype == "3") {owner.A_StartSound("sltdoom_1",CHAN_5,CHANF_NOPAUSE|CHANF_MAYBE_LOCAL,1,ATTN_NONE,1.8);
			return;}
			break;
			case 1: //nmh sounds
			sndname = "sltnmh3_";
			break;
			case 2: //no sounds
			return;
			break;
		}
		sndname.AppendFormat(sndtype);
		owner.A_StartSound(sndname,CHAN_5,CHANF_NOPAUSE|CHANF_MAYBE_LOCAL,1,ATTN_NONE);
	}
}

class DWBloodEnergy : Inventory //Gained from killing enemies
{
	
	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 100000;
		Inventory.ForbiddenTo "TigerMorph";
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.QUIET;
		+INVENTORY.PERSISTENTPOWER;
		+INVENTORY.KEEPDEPLETED;
		+INVENTORY.UNTOSSABLE;
	}
}
class SlotPowerUpLibrary : Thinker
{
	Array<SlotPowerUp> slotitems;
	int allpwerweights; 
	//percentage = itemWeight / allpwerweights
	SlotPowerUpLibrary Init()
	{
		ChangeStatNum(STAT_STATIC);
		//get datalump "slotpowers.txt"
		int slotPowerIndex = Wads.FindLump("slotpowers.txt",0);
		String slotPowerData = Wads.ReadLump(slotPowerIndex);
		allpwerweights = 0; //all power chance percentages
		Array<String> lines;
		slotPowerData.Split(lines, "\n");
		foreach (line : lines)
		{
			line.StripLeftRight();
			if (line == ""){continue;}
			Array<string> elements; line.Split(elements, ",");
			//get cvar to check if the powerup should be added to the list
			String spcvar = elements[0];
			spcvar.StripLeftRight();
			int cv_pow = CVar.FindCVar(spcvar).GetInt();
			if (cv_pow == 0){continue;} //checks if powerup is enabled
			//get chance of getting powerup
			int chance = cv_pow + allpwerweights;
			int chancemin = allpwerweights + 1;
			//find texturename
			String texture = elements[1];
			texture.StripLeftRight();
			//find classname
			String itemClassName = elements[2];
			itemClassName.StripLeftRight();
			self.slotItems.push(new("SlotPowerUp").Init(chancemin,chance,texture,itemClassName));
			allpwerweights += cv_pow;
		}
		if (slotItems.Size() == 1) //add rudecar to list if onoly one powerup is enabled
		{
			int chance = allpwerweights + 1;
			self.slotItems.push(new("SlotPowerUp").Init(chance,chance,"SLIFA0","RudeCar")); //add easter egg slot
		}
		return self;
	}
	Static SlotPowerUpLibrary GetInstance()
	{
		ThinkerIterator it = ThinkerIterator.Create("SlotPowerUpLibrary",STAT_STATIC);
		Thinker t = it.Next();
		if (t){return SlotPowerUpLibrary(t);}
		return new("SlotPowerUpLibrary").Init();
	}
	Static clearscope SlotPowerUpLibrary GetReadOnlyInstance()
	{
		ThinkerIterator it = ThinkerIterator.Create("SlotPowerUpLibrary",STAT_STATIC);
		Thinker t = it.Next();
		if (t){return SlotPowerUpLibrary(t);}
		return null;
	}
	//Get random powerup from Library
	clearscope SlotPowerUp GetRandomPowerup(SlotPowerUp banned = null)
	{
		Array<SlotPowerUp> itemlist; //get powerup list
		itemlist = slotitems;
		int bndindex;
		if (banned != null) //check if a powerup isnt banmed
		{
			bndindex = itemlist.Find(banned); //find index to remove
			itemlist.Delete(bndindex);
		}
		//get random powerup
		SlotPowerUp selectedPower = itemlist[ random(0, itemlist.Size() -1) ];
		return selectedPower;
	}
	clearscope SlotPowerUp GetRandomPowerPerc(SlotPowerUp banned = null)
	{
		Array<SlotPowerUp> itemlist; //get powerup list
		itemlist = slotitems;
		int bndindex;
		if (banned != null) //check if a powerup isnt banmed
		{
			bndindex = itemlist.Find(banned); //find index to remove
			itemlist.Delete(bndindex);
		}
		int choice = random(1,allpwerweights);
		SlotPowerUp selectedPower;
		for (int i = 0; i < slotitems.size(); ++i)
		{
			if (slotitems[i].itemChanceMin <= choice && slotitems[i].itemChanceMax >= choice)
			{selectedPower = slotitems[i];}
		}
		return selectedPower;
	}
	//get size of library
	clearscope int GetLibrarySize()
	{
		return slotitems.Size();
	}
}
//Power ups used by slot machine
class SlotPowerUp
{
	//required stuff to get the powerup
	TextureID texture;
	string itemClassName;
	int itemChanceMin;
	int itemChanceMax;
	
	SlotPowerUp Init(int itemChanceMin,int itemChanceMax,string texture, string itemClassName)
	{
		self.itemChanceMin = itemChanceMin;
		self.itemChanceMax = itemChanceMax;
		self.texture = TexMan.CheckForTexture(texture);
		self.itemClassName = itemClassName;
		return self;
	}
}
