AddCSLuaFile()

SWEP.PrintName = "Eradicator"

SWEP.Base = "weapon_zs_zombie"

SWEP.MeleeDamage = 36
SWEP.SlowDownScale = 0

SWEP.AlertDelay = 3.5

function SWEP:Reload()
	self:SecondaryAttack()
end

function SWEP:PlayAlertSound()
	self:GetOwner():EmitSound("npc/combine_gunship/gunship_moan.wav", 75, math.random(70,75))
end
SWEP.PlayIdleSound = SWEP.PlayAlertSound

function SWEP:PlayAttackSound()
	self:EmitSound("npc/antlion_guard/angry"..math.random(3)..".wav", 75, math.random(75,80))
end
function SWEP:ApplyMeleeDamage(pl, trace, damage)
	if SERVER and pl:IsPlayer()  then
		local cursed = pl:GetStatus("hollowing")
		if (cursed) then 
			pl:AddHallow(self:GetOwner(), cursed.DieTime - CurTime() + 15)
		end
		if (not cursed) then 
			pl:AddHallow(pl:GetOwner(), 25)
		end
	end
	self.BaseClass.ApplyMeleeDamage(self, pl, trace, damage)
end
if not CLIENT then return end

function SWEP:ViewModelDrawn()
	render.ModelMaterialOverride(0)
end

local matSheet = Material("Models/charple/charple4_sheet.vtf")
function SWEP:PreDrawViewModel(vm)
	render.ModelMaterialOverride(matSheet)
end
