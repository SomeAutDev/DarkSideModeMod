class TigerForm : PlayerPawn
{
	default
	{
		+DONTTHRUST
		+INVULNERABLE
		+NOSKIN
		+FRIGHTENING
		-PICKUP
		Height 30;
		Player.ViewHeight 30;
		Player.MorphWeapon "TigerClaws";
		
	}
	states
	{
		Spawn:
			TMID A -1;
			Loop;
		See:
			TMRN ABCDEF 4;
			Loop;
		Melee:
			Goto Missile;
		Missile:
			TMAT A 3;
			TMAT B 3;
			TMAT CDE 2;
			Goto Spawn;
	}
}
class RudeCar : Inventory //easter egg for when the player only has one powerup enabled, can only be spawned with summon command.
{
	Default //This powerup absolutely nothing.
	{
		Height 8;
		Inventory.Amount 0;
		Inventory.MaxAmount 69;
		Inventory.PickupMessage "$DSM_ESTEGG";
		Inventory.PickupSound "sltfku";
		+INVENTORY.KEEPDEPLETED;
	}
	states
	{
		Spawn:
			SLIF A -1;
			Stop;
	}
}
class PowerTiger : PowerMorph
{
	default
	{
		Inventory.MaxAmount 1;
		Powerup.Duration -30;
		PowerMorph.PlayerClass "TigerForm";
		PowerMorph.MorphStyle (MRF_UNDOBYDEATH|MRF_LOSEACTUALWEAPON|MRF_WHENINVULNERABLE|MRF_KEEPARMOR);
	}
}
class TigerMorph : PowerUpGiver //the powerup giver
{
	Default 
	{
		+INVENTORY.AUTOACTIVATE;
		Powerup.Type "PowerTiger";
		Inventory.PickupMessage "$DSM_TGRPOW";
		Inventory.PickupSound "TGROR";
	}
	states
	{
		Spawn:
			SITG A -1;
			Stop;
	}
}
class TigerClaws : Weapon
{
	Default
	{
		Weapon.Kickback 2;
		Weapon.SelectionOrder 10000;
		Weapon.SlotNumber 1;
		+WEAPON.MELEEWEAPON;
		+WEAPON.NOAUTOFIRE;
		+WEAPON.NOALERT;
		+WEAPON.DONTBOB;
		+WEAPON.CHEATNOTWEAPON;
		+INVENTORY.UNDROPPABLE
	}
	States
	{
	Ready:
		TNT1 A 1 A_WeaponReady;
		Loop;
	Select:
		TNT1 A 1 A_Raise;
		Loop;
	Deselect:
		TNT1 A 1 A_Lower;
		Loop;
	Fire:
		TGCG A 3;
		TGCG B 2 A_CustomPunch(100, false, CPF_NoTurn,"BulletPuff", 64, 0, 0, "","TGSTRK","skeleton/swing");
		TGCG C 1;
		TNT0 A 7;
		TGCG D 1 A_ReFire;
		Goto Ready;
	}
}