AddCSLuaFile()

--SWEP.PrintName = "Kongol Axe"
--SWEP.Description = "A very heavy greataxe with no other special properties other than sheer damage output."
SWEP.PrintName = translate.Get("wep_kaxe")
SWEP.Description = translate.Get("wep_d_kaxe")



SWEP.Base = "weapon_zs_basemelee"

SWEP.ViewModel = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true

SWEP.HoldType = "melee2"

SWEP.MeleeDamage = 98
SWEP.MeleeRange = 75
SWEP.MeleeSize = 3
SWEP.MeleeKnockBack = 350

SWEP.Primary.Delay = 1.3

SWEP.WalkSpeed = SPEED_SLOWER

SWEP.SwingRotation = Angle(60, 0, -80)
SWEP.SwingOffset = Vector(0, -30, 0)
SWEP.SwingTime = 0.6
SWEP.SwingHoldType = "melee"

SWEP.CanDefend = true

SWEP.GodMode = nil


SWEP.HitDecal = "Manhackcut"

SWEP.Tier = 4
SWEP.MaxStock = 3

SWEP.AllowQualityWeapons = true

GAMEMODE:AttachWeaponModifier(SWEP, WEAPON_MODIFIER_FIRE_DELAY, -0.13)

function SWEP:SetPerc(perc)
	self:SetDTFloat(5, perc)
end

function SWEP:GetPerc()
	return self:GetDTFloat(5)
end



function SWEP:PlaySwingSound()
	self:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 75, math.random(40, 45))
end

function SWEP:PlayHitSound()
	self:EmitSound("weapons/melee/golf club/golf_hit-0"..math.random(4)..".ogg", 75, math.random(70, 75))
end

function SWEP:PlayHitFleshSound()
	self:EmitSound("physics/flesh/flesh_bloody_break.wav", 80, math.random(95, 105))
end
