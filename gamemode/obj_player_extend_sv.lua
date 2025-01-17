local meta = FindMetaTable("Player")
local P_Team = meta.Team

local DMG_TAKE_BLEED = DMG_SLASH + DMG_CLUB + DMG_BULLET + DMG_BUCKSHOT + DMG_CRUSH
local function GetTaper(pl, str, mul, sep)
	local taper = 1
	if !sep then
		sep = "_"
	end
	for item,v in pairs(pl:GetInventoryItems()) do
		local g = string.Explode(sep,item)
		if table.HasValue(g,str) then
			taper = taper + mul * v
		end
	end
	return taper
end
function meta:ProcessDamage(dmginfo)
	if not self:IsValidLivingPlayer() then return end --??? Apparently player was null sometimes on server?

	local attacker, inflictor, dmgtype = dmginfo:GetAttacker(), dmginfo:GetInflictor(), dmginfo:GetDamageType()

	if not GAMEMODE:PlayerShouldTakeDamage(self, attacker) then return true end

	local dmgbypass = bit.band(dmgtype, DMG_DIRECT) ~= 0

	if self.DamageVulnerability and not dmgbypass then
		dmginfo:SetDamage(dmginfo:GetDamage() * self.DamageVulnerability)
	end
	if P_Team(self) == TEAM_HUMAN and attacker:IsValidLivingZombie() then
		self:GiveAchievementProgress("tanked", math.Round((dmginfo:GetDamage() or 1)))
		self:SetProgress(CurTime() + 0.97, "parasite_prog")
	end

	if attacker.AttackerForward and attacker.AttackerForward:IsValid() then
		dmginfo:SetAttacker(attacker.AttackerForward)
		attacker = attacker.AttackerForward

		if attacker:IsPlayer() and attacker:Team() == P_Team(self) and attacker ~= self then
			dmginfo:SetDamage(0)
		end
	end
	if table.HasValue({"prop_physics", "prop_physics_multiplier"}, inflictor) and !inflictor:GetPhysicsAttacker() then
		dmginfo:ScaleDamage(0)
	end
	if attacker.PBAttacker and attacker.PBAttacker:IsValid() then
		attacker = attacker.PBAttacker
	end

	if P_Team(self) == TEAM_UNDEAD then
		if self.SpawnProtection then
			dmginfo:SetDamage(1)
			dmginfo:ScaleDamage(0.1)
			dmginfo:SetDamageForce(vector_origin)
			return
		end
		if attacker:IsPlayer()and attacker.RedeemedOnce and attacker:IsSkillActive(SKILL_PHOENIX) then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.7)
		end
		if attacker:IsPlayer()and attacker:HasTrinket("soul_lime") and attacker:GetModel() == "models/ultrakill/v1_pm.mdl" then
			dmginfo:SetDamage(dmginfo:GetDamage() * 1.2)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * (1 - (math.Clamp(GAMEMODE:GetBalance() * 0.005,-2.5,0.7))))
		if self.m_zombiedef then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.75)
		end
		if self.m_Zombie_Bara1 then
				dmginfo:SetDamage(dmginfo:GetDamage() * 1.5)
		end
		if self.m_Zmain then
			dmginfo:SetDamage(dmginfo:GetDamage() * 2)
		end
		if attacker.r_return then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.9)
		end
		if self.m_Evo and math.random(3) == 1 then
			if attacker:IsPlayer() then
				GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
			end
			dmginfo:SetDamage(0)
			net.Start("zs_damageblock")
			net.Send(self)
		end

		local corrosion = self.Corrosion and self.Corrosion + 2 > CurTime()
		if self ~= attacker and not corrosion and not dmgbypass then
			dmginfo:SetDamage(dmginfo:GetDamage() * GAMEMODE:GetZombieDamageScale(dmginfo:GetDamagePosition(), self))
		end
		if attacker:IsValidLivingHuman() and attacker:IsSkillActive(SKILL_SIGILIBERATOR) then
            dmginfo:ScaleDamage(1.45)
		end
		if attacker:IsValidLivingHuman() and attacker:HasTrinket("a_flower") and (attacker:GetStatus("cursed")) then
            dmginfo:ScaleDamage(0.1)
		end
		if attacker:IsValidLivingHuman() and attacker:IsSkillActive(SKILL_AMULET_12) then
            dmginfo:ScaleDamage(0)
		end
		if attacker:IsValidLivingHuman() and attacker.ClanAvanguard and inflictor.Unarmed then
            dmginfo:ScaleDamage(1.25)
			if inflictor.IsMelee then
				dmginfo:ScaleDamage(1.25)
			end
		end
		--[[if attacker:IsValidLivingHuman() and inflictor == attacker:GetActiveWeapon() and inflictor.Tier <= 4 then
            dmginfo:ScaleDamage(0.65)
			if dmginfo:GetDamage() > self:Health() * 1.2 then
				attacker:TakeDamage(dmginfo:GetDamage() * 0.05)
			end
		end]]
		if attacker.IsLastHuman and attacker.ClanAnsableRevolution then
			dmginfo:ScaleDamage(1.70)
		end
		if attacker:IsPlayer() and attacker.IsLastHuman and attacker:IsSkillActive(SKILL_LAST_MAN) then
			dmginfo:ScaleDamage(1.15)
		elseif	attacker:IsPlayer() and !attacker.IsLastHuman and attacker:IsSkillActive(SKILL_LAST_MAN) then
			dmginfo:ScaleDamage(0.85)
		end
		if attacker:IsValidLivingHuman() and attacker.ClanMich and not inflictor.IsMelee then
            dmginfo:ScaleDamage(1.15)
		end
		if attacker:IsValidLivingHuman() and attacker:IsSkillActive(SKILL_AMULET_11) and attacker:Health() >= attacker:GetMaxHealth() then
            dmginfo:ScaleDamage(1.45)
		end
		if attacker:IsValidLivingHuman() and attacker:HasTrinket("antibaracat") and self:GetZombieClassTable().BaraCat then
            dmginfo:ScaleDamage(3)
		end
		if attacker:IsValidLivingHuman() and attacker:HasTrinket("cham_at") and self:GetZombieClassTable().BaraCat then
            dmginfo:ScaleDamage(3)
			self:AttachmentDamage(dmginfo:GetDamage(), attacker, inflictor, 4)
		end
		if GAMEMODE.ObjectiveMap then
			dmginfo:ScaleDamage(0.25)
		end
		if attacker:IsPlayer() and attacker:IsSkillActive(SKILL_AMULET_2) and (15 >= attacker:Health() or attacker:Health() <= (attacker:GetMaxHealth() * 0.1) )then
			dmginfo:ScaleDamage(2)
		end

		self.ShouldFlinch = true
		if self:GetZArmor() > 0 then
			local damage = dmginfo:GetDamage()
			if damage > 0 then
	
				local ratio = 1
				local absorb = math.min(self:GetZArmor(), damage * ratio)
				dmginfo:SetDamage(damage - absorb)
				self:SetZArmor(self:GetZArmor() - absorb)
				self.BloodDead = absorb
				if attacker:IsPlayer() then
					local points = damage / self:GetMaxHealth() * self:GetZombieClassTable().Points
					if POINTSMULTIPLIER then
						points = points * POINTSMULTIPLIER
					end
					if self.PointsMultiplier then
						points = points * self.PointsMultiplier
					end
					if self:GetMaxHealth() >= 250 then
						attacker.PointQueue = attacker.PointQueue + points/25
					end
					GAMEMODE:DamageFloater(attacker, self, dmginfo:GetDamagePosition() - Vector(0,0,-5), absorb, true)
				end
				if damage > 20 and damage - absorb <= 0 then
					self:EmitSound("physics/flesh/flesh_strider_impact_bullet3.wav", 55)
				end
			end
		end
		if attacker:IsValidLivingHuman() and attacker:IsSkillActive(SKILL_AMULET_15) then 
			local g = GetTaper(attacker, "curse", 0.06)
			dmginfo:SetDamage(dmginfo:GetDamage()*g)
		end
		if attacker:IsValidLivingHuman() and attacker:HasTrinket("sin_ego") then 
			local g = GetTaper(attacker, "ego", 0.04)
			dmginfo:SetDamage(dmginfo:GetDamage()*g)
		end
		if attacker:IsValidLivingHuman()  and self:GetZombieClassTable().FireBuff and attacker:HasTrinket("fire_at") then
			dmginfo:SetDamage(0)
			GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
		end
		if attacker:IsValidLivingHuman()  and self:GetZombieClassTable().ResistFrost and attacker:HasTrinket("acid_at") then
			dmginfo:SetDamage(0)
			GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
		end
		if attacker:IsValidLivingHuman()  and self:GetZombieClassTable().FireBuff and attacker:HasTrinket("acid_at") then
			dmginfo:ScaleDamage(2)
		end
		if attacker:IsValidLivingHuman()  and self:GetZombieClassTable().ResistFrost and attacker:HasTrinket("fire_at") then
			dmginfo:ScaleDamage(2)
		end
		if self:GetZombieClassTable().Boss and attacker:IsPlayer() then
			dmginfo:SetDamage(math.min(dmginfo:GetDamage(), (self:GetMaxHealth() * 0.09) * (inflictor.Tier or 1)))
		end
		if attacker:IsValidLivingHuman() and inflictor:IsValid() and inflictor == attacker:GetActiveWeapon() then
			local damage = dmginfo:GetDamage()
			local wep = attacker:GetActiveWeapon()
			local attackermaxhp = math.floor(attacker:GetMaxHealth() * ((attacker:IsSkillActive(SKILL_D_FRAIL) or attacker:IsSkillActive(SKILL_ABUSE)) and 0.44 or 1))
	
			--attacker.dpsmeter = damage
			if attacker:IsSkillActive(SKILL_VAMPIRISM) then
				attacker:SetNWFloat("vampirism_progress", attacker:GetNWFloat("vampirism_progress",value)+damage*0.09)
				if attacker:GetNWFloat("vampirism_progress",value) >= 620 then
					attacker:SetHealth(math.min(attacker:GetMaxHealth(),attacker:Health() + attacker:GetMaxHealth()*0.09))
				end
			end
			if attacker:IsSkillActive(SKILL_INF_POWER) then
				dmginfo:ScaleDamage(0.5 + #attacker:GetUnlockedSkills() * 0.006)
			end
			if damage >= 10000 then
				attacker:GiveAchievement("opm")
			end
			if attacker:HasTrinket("fire_at") and math.randomr(1,6,5,attacker) == 5 then
				attacker:SetProgress(attacker:GetProgress('fprog')+damage* 0.1, 'fprog')
			end
			if (attacker:IsSkillActive(SKILL_BOUNTYKILLER) or self:GetZombieClassTable().Boss or self:GetZombieClassTable().DemiBoss) and !self:GetZombieClassTable().CrowDa and !self:GetZombieClassTable().Skeletal then
				local mul = ((attacker:IsSkillActive(SKILL_BOUNTYKILLER) and 0.15 or 0) + (self:GetZombieClassTable().DemiBoss and 0.05 or self:GetZombieClassTable().Boss and 0.1 or 0))
				attacker:SetProgress(attacker:GetProgress('bprog')+damage*mul, 'bprog')
				local tbl = {"headshoter", "ind_buffer", "soulalteden", "ultra_at"}
				local hm = table.Random(tbl)
				if attacker:GetProgress('bprog') >= 1500 * (attacker:GetProgress('bprogmul')+1) and !attacker:HasTrinket(hm) then
					attacker:SetProgress(0, 'bprog')
					attacker:SetProgress(attacker:GetProgress('bprogmul')+1,'bprogmul') 
					local itype = "trinket_"..hm
					attacker:AddInventoryItem(itype)
					net.Start("zs_invitem")
					net.WriteString(itype)
				net.Send(attacker)
					attacker:SetPoints(attacker:GetPoints() + 50)
				end
			end
			dmginfo:SetDamage(dmginfo:GetDamage() * math.Clamp(attacker:GetModelScale() * attacker:GetModelScale(), 0.05, 5))
			if attacker:HasTrinket("soulalteden") then
				attacker.RandomDamage = attacker.RandomDamage + math.randomr(1,5,5,attacker)

				if attacker.RandomDamage >= 100 then
														local buff = {
															
							"holly",
							"medrifledefboost",
							"renegade",
							"strengthdartboost",
							"healdartboost",
							"sticky",
							"bloodlust"
						}
						attacker.RandomDamage = 0
						attacker:GiveStatus(buff[math.random(1, #buff)],math.random(10,50))

				end
			end
			if attacker:IsSkillActive(SKILL_OLD_GOD1) then
				if LASTHUMAN then
					dmginfo:ScaleDamage(1.75)
				end
				if self.Zmainer and !self:IsBot() then
					dmginfo:ScaleDamage(1.25)
				end
			end
			if attacker:IsSkillActive(SKILL_BARA_CURSED) and GAMEMODE:GetWave() >= 6 then
				dmginfo:ScaleDamage(1.45)
			end
			if wep.IsMelee then
				if attacker:IsSkillActive(SKILL_CHEAPKNUCKLE) and math.abs(self:GetForward():Angle().yaw - attacker:GetForward():Angle().yaw) <= 90 then
					self:AddLegDamage(12)
				end
				if attacker:HasTrinket("altsamsonsoul")  then
					local rot = attacker:GetStatus("strengthdartboost")
					if (rot) then 
						attacker:AddBloodlust(attacker:GetOwner(), rot.DieTime - CurTime() + dmginfo:GetDamage() * 0.05)
					end
					if (not rot) then 
						attacker:AddBloodlust(attacker:GetOwner(), dmginfo:GetDamage() * 0.09)
					end
				end
				if attacker:GetActiveWeapon().CanDefend and attacker:GetActiveWeapon():GetPerc() < 11 then
					attacker:GetActiveWeapon():SetPerc((attacker:GetActiveWeapon():GetPerc() or 0) + 1)
				end
				if attacker:GetTimerBERS() >= CurTime() and attacker:IsSkillActive(SKILL_BERSERK) then
					dmginfo:ScaleDamage(5)
				end


				if attacker.MeleeDamageToBloodArmorMul and attacker.MeleeDamageToBloodArmorMul > 0 and attacker:GetBloodArmor() < attacker.MaxBloodArmor and !attacker:IsSkillActive(SKILL_BLOODHACK) then
					attacker:SetBloodArmor(math.min(attacker.MaxBloodArmor, attacker:GetBloodArmor() + math.min(damage, self:Health()) * attacker.MeleeDamageToBloodArmorMul * attacker.BloodarmorGainMul))
				end


				if attacker:IsSkillActive(SKILL_HEAVYSTRIKES) and not self:GetZombieClassTable().Boss and (wep.IsFistWeapon and attacker:IsSkillActive(SKILL_CRITICALKNUCKLE) or wep.MeleeKnockBack > 0) then
					self.FallDamageHS = damage*0.45
					self.FallAttacker = attacker
				end
				if attacker:IsSkillActive(SKILL_BLOODYFISTS) and wep.Unarmed then
					self:AddBleedDamage(damage * 0.1, attacker)
					if  attacker:IsSkillActive(SKILL_DEFENDBLOOD) then
						attacker:AddBleedDamage(damage * 0.05, self)
					end
				end
				
				if attacker:HasTrinket("sin_lust") and math.abs(self:GetForward():Angle().yaw - attacker:GetForward():Angle().yaw) <= 90 then
					attacker:TakeSpecialDamage(damage * 0.05, DMG_SLASH, self, self:GetActiveWeapon())
                    dmginfo:SetDamage(damage * 2)
				end

	
				if attacker:IsSkillActive(SKILL_BLOODLUST) and attacker:GetPhantomHealth() > 0 and attacker:Health() < attackermaxhp then
					local toheal = math.min(attacker:GetPhantomHealth(), math.min(self:Health(), damage * 0.65))
					attacker:SetHealth(math.min(attacker:Health() + toheal, attackermaxhp))
					attacker:SetPhantomHealth(attacker:GetPhantomHealth() - toheal)
				end

				if attacker:HasTrinket("sharpkit") then
					dmginfo:SetDamage(dmginfo:GetDamage() * (1 + self:GetFlatLegDamage()/75))
				end
				if attacker:IsSkillActive(SKILL_BLOODLIFE) then
					dmginfo:SetDamage(dmginfo:GetDamage() + (attacker:GetBloodArmor() * 0.05))
				end

				if attacker:IsSkillActive(SKILL_PILLUCK) and math.random(1,10,1,attacker) == 1 then
					self.LuckFromKillYesOwner = attacker
					self.LuckFromKillYes = CurTime() + 0.5
				end
				

				if wep.Culinary and attacker:IsSkillActive(SKILL_MASTERCHEF) and math.random(1,5,1,attacker) == 1 then
					self.ChefMarkOwner = attacker
					self.ChefMarkTime = CurTime() + 1
				end
			end
		end
		if attacker:IsValidLivingHuman() then
			local damage = dmginfo:GetDamage()
			local wep = attacker:GetActiveWeapon()
			local midwave = GAMEMODE:GetWave() < GAMEMODE:GetNumberOfWaves() / 2 or GAMEMODE:GetWave() == GAMEMODE:GetNumberOfWaves() / 2 and GAMEMODE:GetWaveActive() and CurTime() < GAMEMODE:GetWaveEnd() - (GAMEMODE:GetWaveEnd() - GAMEMODE:GetWaveStart()) / 2
			--if wep and (wep.Tier or 1) < 4 and damage >= ((wep.IsMelee and wep.MeleeDamage or wep.Primary.Damage or 1) * (wep.Tier or 1)) and (GAMEMODE.DamageLock or GAMEMODE:GetWave() >= 5) then
			--	dmginfo:SetDamage(((wep.IsMelee and wep.MeleeDamage or wep.Primary.Damage or 1) * (wep.Tier or 1))/(!GAMEMODE.DamageLock and GAMEMODE:GetWave() * 0.5 or 1))
			--end
			local damage1 = damage
			attacker:SetDPS(attacker:GetDPS() + damage)
			timer.Create("DPS"..damage..attacker:Nick()..math.Rand(1,5)..damage*0.5, 1, 1, function() attacker:SetDPS(attacker:GetDPS() - damage1) end)
		end
		return not dmgbypass and self:CallZombieFunction1("ProcessDamage", dmginfo)
	end
	

	if self:IsSkillActive(SKILL_BLESSEDROD) and dmginfo:GetDamage() >= 30 and !dmgbypass then
		dmginfo:SetDamage(dmginfo:GetDamage() - 12)
	end
	if (((self:GetZSRemortLevel() / 4) or 0) + (self.AmuletPiece or 0)) < 0 then
		dmginfo:ScaleDamage(2 + ((self:GetZSRemortLevel() / 4) - (self.AmuletPiece or 0)))
	end


    truedogder = 30 - (self:GetWalkSpeed() / 15)
	rngdogde = math.max(0,math.randomr(1,math.max(truedogder,2),1,self))
 
	if self:IsSkillActive(SKILL_DODGE) and rngdogde == 1 and !dmgbypass then
		if attacker:IsPlayer() then
			GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
		end
		dmginfo:SetDamage(0)
		net.Start("zs_damageblock")
		net.Send(self)
    end
	if self:IsSkillActive(SKILL_HELPLIFER) and math.randomr(1,10,1,self) == 1 and dmginfo:GetDamage() >= self:Health() and !dmgbypass then
		dmginfo:SetDamage(0)
		if attacker:IsPlayer() then
			GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
		end
    end
		if self:IsSkillActive(SKILL_SKYHELP) then
		self:SetVelocity(VectorRand() * math.random(200,1700))
    end




    

	if self:IsSkillActive(SKILL_HOLY_MANTLE) and self.HolyMantle == 1 and not self:HasGodMode() then
		dmginfo:SetDamage(0)
		net.Start("zs_holymantle")
		net.Send(self)
		self.HolyMantle = self.HolyMantle - 1
		self:GiveStatus("hshield", 3, true)
		self.NextRegenerateMantle = CurTime() + math.max((27 - ((self.Luck + self.LuckAdd) / 3)) + GAMEMODE.GetWave() * 3,5)
		timer.Simple(0,function()
			self:GodEnable()
			end )
			timer.Simple(3,function()
				if self:IsValid() then self:GodDisable() end
			end )
			self:GiveAchievementProgress("godhelp", 1)
			if attacker:IsPlayer() then
				GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
			end

    end
	if self:IsSkillActive(SKILL_AMULET_14) then
		dmginfo:ScaleDamage(math.Clamp(self:Health()/self:GetMaxHealth(),2,0.55))
	end

	-- Opted for multiplicative.

	if attacker == self and dmgtype ~= DMG_CRUSH and dmgtype ~= DMG_FALL and self.SelfDamageMul then
		dmginfo:SetDamage(dmginfo:GetDamage() * self.SelfDamageMul)
	end
	if !dmgbypass and self:IsSkillActive(SKILL_GODHEART) then
		dmginfo:SetDamage(0)
	end
	if bit.band(dmgtype, DMG_ALWAYSGIB) ~= 0 and self.ExplosiveDamageTakenMul then
		dmginfo:SetDamage(dmginfo:GetDamage() * self.ExplosiveDamageTakenMul)
	end
	if bit.band(dmgtype, DMG_BURN) ~= 0 and self.FireDamageTakenMul then
		dmginfo:SetDamage(dmginfo:GetDamage() * self.FireDamageTakenMul)
	end


	if inflictor:IsValid() and (inflictor:IsPhysicsModel() or inflictor.IsPhysbox) and self:IsValidLivingHuman() then
		local damage = dmginfo:GetDamage()
		local forcedamp = self:HasTrinket("forcedamp")
		local noadj = attacker:IsValidLivingZombie() and attacker:GetZombieClassTable().NoAdjustPhysDamage

		if forcedamp or (attacker:IsValidLivingZombie() and not noadj) then
			damage = math.max(5, (math.log10(damage) * 26)-5)
		end
		if self.PhysicsDamageTakenMul then
			damage = damage * self.PhysicsDamageTakenMul
		end
		if damage >= 30 and not forcedamp and not noadj and inflictor ~= attacker then
			self:KnockDown(damage * 0.05)
		end

		dmginfo:SetDamage(damage)
	end
	if attacker:IsValid() and attacker:IsPlayer() and inflictor:IsValid() and self:GetActiveWeapon().IsMelee and self:GetActiveWeapon().Block then
		local xpadded = math.Clamp(dmginfo:GetDamage() * 0.25,0.05,10)
		dmginfo:SetDamage(dmginfo:GetDamage() * ((0.50 * (self.BlockMultiplier or 1)) * ( self:GetActiveWeapon().BlockMultiplierWeapon or 1)))
		if self:IsSkillActive(SKILL_AVOID_BLOCK) then
			net.Start("zs_xp_damage")
			net.WriteString(xpadded)
			net.Send(self)
			self:AddZSXP(xpadded)
		end
		if self:IsSkillActive(SKILL_TRUEBLOCK) and self:GetActiveWeapon().ParryTiming then 
           dmginfo:SetDamage(0)
			self:EmitSound("npc/strider/fire.wav", 120, 40)
	    elseif self:IsSkillActive(SKILL_TRUEBLOCK) and not self:GetActiveWeapon().ParryTiming then
			self:EmitSound("npc/turret_floor/active.wav", 120, 40)
		end
	end
	local mythrilchance = math.randomr(1,25,1,self)
	if self:IsSkillActive(SKILL_MYTHRIL) and mythrilchance == 1 and not self:GetStatus("hshield") and dmginfo:GetDamage() < 200 then
		xpadded = dmginfo:GetDamage() * 0.5
		net.Start("zs_xp_damage")
		net.WriteString(xpadded)
		net.Send(self)
		self:EmitSound("ambient/creatures/town_child_scream1.wav", 120, 40)
		self:AddZSXP(xpadded)
		dmginfo:SetDamage(0)
		if attacker:IsPlayer() then
			GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
		end
	end

	if self.DamageTakenMul and !dmgbypass then
		dmginfo:SetDamage(dmginfo:GetDamage() * self.DamageTakenMul)
	end
	if self:IsSkillActive(SKILL_DOSETHELP) then
		dmginfo:SetDamage(dmginfo:GetDamage() * (1 - GAMEMODE:GetWave() * 0.02))
	end
	if self:IsSkillActive(SKILL_SECONDCHANCE) and self.LetalSave and dmginfo:GetDamage() >= self:Health() then
		dmginfo:SetDamage(0)
		self.LetalSave = false
		self:SetHealth(self:GetMaxHealth()/2)
		if attacker:IsPlayer() then
			GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
		end
	end
	if self:IsSkillActive(SKILL_BERSERK) and self.BerserkerCharge and dmginfo:GetDamage() >= (self:Health() + (self:GetBloodArmor() * math.max(0.5 + self.BloodArmorDamageReductionAdd + (self:IsSkillActive(SKILL_IRONBLOOD) and self:Health() <= self:GetMaxHealth() * 0.5 and 0.25 or 0),(attacker:IsPlayer() and -1 or 0.05)))) then
		
		dmginfo:SetDamage(0)
		self:SetTimerBERS(CurTime())
		self.BerserkerCharge = false
		if attacker:IsPlayer() then
			GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
		end
	end
	if self:GetTimerBERS() >= CurTime() and self:IsSkillActive(SKILL_BERSERK) then
		dmginfo:SetDamage(0)
		if attacker:IsPlayer() then
			GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
		end
	end
	if self:IsSkillActive(SKILL_XPMULGOOD) and self.AddXPMulti > 0.20 then
        self.AddXPMulti = self.AddXPMulti - 0.05
	end

	if attacker:IsPlayer() and attacker:Team() == TEAM_UNDEAD and dmginfo:GetDamage() >= 1000 and !self:HasGodMode() then
		timer.Simple(2, function() if self:IsValid() and self:Team() == TEAM_HUMAN then self:GiveAchievement("onepieceisreal") end end)
	end


	if attacker:IsValid() and attacker:IsPlayer() and inflictor:IsValid() and attacker:Team() == TEAM_UNDEAD then
		if self:HasTrinket("soul_lime") and attacker:GetZombieClassTable().HeathMax then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
		end
		if attacker.Zban then
			dmginfo:SetDamage(0)
		end
		if attacker.Zmainer and self:IsSkillActive(SKILL_DOSET1) then
			dmginfo:ScaleDamage(0.75)
		end
		if attacker.Zmainer then
			dmginfo:ScaleDamage(0.67)
		end


		if inflictor == attacker:GetActiveWeapon() then
			if (GAMEMODE:GetBalance() * 0.05) >= 0.1 then
				dmginfo:SetDamage(dmginfo:GetDamage() * (1 + (math.Clamp(GAMEMODE:GetBalance() * 0.05,0.5,1.5))))
			end
			if self.ClanAnsableRevolution then
				dmginfo:SetDamage(dmginfo:GetDamage() - 7)
			end
			local damage = dmginfo:GetDamage()

			if self:IsBarricadeGhosting() then
				self:SetLegDamage(21 * (self.SlowEffTakenMul or 1))
			else
				local scale = inflictor.SlowDownScale or 1
				if damage >= 45 or scale > 1 then
					local dolegdamage = true
					if inflictor.SlowDownImmunityTime then
						if CurTime() < (self.SlowDownImmunityTime or 0) then
							dolegdamage = false
						else
							self.SlowDownImmunityTime = CurTime() + inflictor.SlowDownImmunityTime
						end
					end
					if dolegdamage then
						self:RawCapLegDamage(self:GetLegDamage() + CurTime() + damage * 0.04 * (inflictor.SlowDownScale or 1) * (self.SlowEffTakenMul or 1))
					end
				end
			end
			local amuletrng = math.randomr(1, math.max(2,10 / (self.CarefullMelody_DMG *0.5)),2,self)
			if self:IsSkillActive(SKILL_AMULET_1) and amuletrng == 2 then
				dmginfo:SetDamage(0)
				net.Start("zs_damageblock")
				net.Send(self)
				self.CarefullMelody_DMG = 0
				if attacker:IsPlayer() then
					GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
				end
			elseif self:IsSkillActive(SKILL_AMULET_1) and amuletrng ~= 1 then
				self.CarefullMelody_DMG = self.CarefullMelody_DMG + 1
			end
			if self:GetStatus("sigildef") and !self:IsSkillActive(SKILL_BERSERK) then
				dmginfo:ScaleDamage(0.76)
			end

			if bit.band(dmgtype, DMG_SLASH) ~= 0 or inflictor.IsMelee or self:GetActiveWeapon().ParryTiming and attacker:IsPlayer() then
				if self.BarbedArmor and self.BarbedArmor > 0 then
					attacker:TakeSpecialDamage(self.BarbedArmor, DMG_SLASH, self, self)
					attacker:AddArmDamage(self.BarbedArmor)
				end
				if self:IsSkillActive(SKILL_TRUEBLOCK) and self:GetActiveWeapon().ParryTiming then
			       attacker:TakeDamage(self:GetActiveWeapon().MeleeDamage * 6, self, self:GetActiveWeapon())
				end

				--[[if self:IsSkillActive(SKILL_UPLOAD) then
					timer.Simple(5, function()
						self:TakeSpecialDamage(dmginfo:GetDamage() * 0.5, DMG_ACID, attacker, self)
					end)
					dmginfo:SetDamage(0)
				end]]
				if self:HasTrinket("ttimes") then
					dmginfo:SetDamage(dmginfo:GetDamage() - 6)
				end
				if self:IsSkillActive(SKILL_FOLGA) then
					dmginfo:SetDamage(dmginfo:GetDamage() - 5)
				end
				if self:HasTrinket("altsamsonsoul")  then
					local rot = self:GetStatus("strengthdartboost")
					if (rot) then 
						self:AddBloodlust(attacker, rot.DieTime - CurTime() + dmginfo:GetDamage() * 0.1)
					end
					if (not rot) then 
						self:AddBloodlust(attacker, dmginfo:GetDamage() * 0.3)
					end
				end
				if attacker.m_Zombie_Bara and not self:IsSkillActive(SKILL_BARA_CURSED) and CurTime() >= (self.NextKnockdown or 0) then
					self:GiveStatus("knockdown",1)
					self.NextKnockdown = CurTime() + 1
					local vel = self:GetPos() - self:GetPos()
					vel.z = 0
					vel:Normalize()
					vel = vel * 2800
					vel.z = 1900
					self:SetVelocity(vel)
				end
				if attacker.m_Zombie_Bara1 then
					dmginfo:SetDamage(dmginfo:GetDamage() * 2)
				end
				if attacker.m_Why then
                   dmginfo:SetDamage(dmginfo:GetDamage() * 1.12)
				end
					
		
				if attacker:IsBot() and self:GetZSRemortLevel() >= 2 then
					dmginfo:ScaleDamage(1.25)
				elseif attacker:IsBot() and self:GetZSRemortLevel() < 2 then
					dmginfo:ScaleDamage(0.75)
				end

				if self:GetActiveWeapon().CanDefend and math.min(10,self:GetActiveWeapon():GetPerc()) > 0 and !dmgbypass then
					dmginfo:SetDamage(dmginfo:GetDamage() / self:GetActiveWeapon():GetPerc())
					self:GetActiveWeapon():SetPerc(self:GetActiveWeapon():GetPerc() - 1)
				end
				if self:GetActiveWeapon().ResistDamage then
					if math.abs(self:GetForward():Angle().yaw - attacker:GetForward():Angle().yaw) >= 90 and attacker:GetActiveWeapon() == inflictor then
						dmginfo:SetDamage((dmginfo:GetDamage() * 0.3) - (self:GetActiveWeapon().MeleeDamage * 0.3))
						attacker:TakeDamage(self:GetActiveWeapon().MeleeDamage * 15, self, self:GetActiveWeapon())
						local cursed = self:GetStatus("cursed")
						if (cursed) then 
							self:AddCursed(self, cursed.DieTime - CurTime() - 5)
						end
					else
						dmginfo:ScaleDamage(3)
					end
				end
				

				if self.BarbedArmorPercent and self.BarbedArmorPercent > 0 then
					attacker:TakeSpecialDamage(damage * self.BarbedArmorPercent, DMG_SLASH, self, self)
				end

				if self:HasTrinket("lazarussoul") and (not self.LastReactiveFlash or self.LastReactiveFlash + 40 < CurTime()) then
					attacker:ScreenFade(SCREENFADE.IN, nil, 1, 1)
					attacker:SetDSP(36)
					attacker:GiveStatus("disorientation", 1)
					attacker:GiveStatus("dimvision", 1)

					self:EmitSound("weapons/flashbang/flashbang_explode2.wav")

					local effectdata = EffectData()
						effectdata:SetOrigin(self:GetPos())
					util.Effect("HelicopterMegaBomb", effectdata)
				end

					self.LastReactiveFlash = CurTime()
					self.ReactiveFlashMessage = nil
				if self:HasTrinket("reactiveflasher") and (not self.LastReactiveFlash or self.LastReactiveFlash + 10 < CurTime()) then
					attacker:ScreenFade(SCREENFADE.IN, nil, 1, 1)
					attacker:SetDSP(36)
					attacker:GiveStatus("disorientation", 2)

					self:EmitSound("weapons/flashbang/flashbang_explode2.wav")

					local effectdata = EffectData()
						effectdata:SetOrigin(self:GetPos())
					util.Effect("HelicopterMegaBomb", effectdata)

					self.LastReactiveFlash = CurTime()
					self.ReactiveFlashMessage = nil
				elseif
				self:HasTrinket("bleaksoul") and (not self.LastBleakSoul or self.LastBleakSoul + 15 < CurTime()) then
					attacker:GiveStatus("dimvision", 7)
					attacker:SetGroundEntity(nil)
					attacker:SetLocalVelocity((attacker:GetPos() - self:GetPos()):GetNormalized() * 450 + Vector(0, 0, 140))

					self:EmitSound("ambient/creatures/town_child_scream1.wav", 70, 60)
					self:EmitSound("npc/stalker/go_alert2a.wav", 70, 45, 0.25)

					self.LastBleakSoul = CurTime()
					self.BleakSoulMessage = nil
				end
				if self:HasTrinket("eriosoul") and (not self.LastBleakSoul or self.LastBleakSoul + 2 < CurTime()) then
					attacker:GiveStatus("dimvision", 1)
					attacker:SetGroundEntity(nil)
					self.LastBleakSoul = CurTime()
					self.BleakSoulMessage = nil
				end

				local chance = math.randomr(1,100,5,self)

				if self:IsSkillActive(SKILL_TTIMES) and chance <= 5 then
					attacker:GiveStatus("dimvision", 1)
					net.Start("zs_damageblock")
					net.Send(self)

					self:EmitSound("ambient/creatures/town_child_scream1.wav", 120, 40)
					dmginfo:SetDamage(0)
					if attacker:IsPlayer() then
						GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
					end

				end


				local trinkett = math.randomr(1,100,8,self)
				if self:HasTrinket("ttimes") and trinkett <= 9 then
					attacker:GiveStatus("dimvision", 1)
					net.Start("zs_damageblock")
					net.Send(self)

					self:EmitSound("ambient/creatures/town_child_scream1.wav", 120, 60)
					dmginfo:SetDamage(0)
					if attacker:IsPlayer() then
						GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
					end

				end
				local slavec = math.randomr(1,10,1,self)
				if self:IsSkillActive(SKILL_SLAVEC) and slavec == 1 then
					attacker:GiveStatus("dimvision", 5)

					self:EmitSound("ambient/creatures/town_child_scream1.wav", 20, 10)
					self:GiveStatus("medrifledefboost", 10)

				end
		        if self:HasTrinket("lazarussoul") and (not self.LastBleakSoul or self.LastBleakSoul + 30 < CurTime()) then
					local g =attacker:GiveStatus("bleed")
					g:AddDamage(50, self)
					attacker:SetGroundEntity(nil)
					attacker:SetLocalVelocity((attacker:GetPos() - self:GetPos()):GetNormalized() * 450 + Vector(0, 0, 140))

					self:EmitSound("ambient/creatures/town_child_scream1.wav", 70, 60)
					self:EmitSound("npc/stalker/go_alert2a.wav", 70, 45, 0.25)

					self.LastBleakSoul = CurTime()
					self.BleakSoulMessage = nil
				end
				if self:HasTrinket("adrenaline") then
					local boost = self:GiveStatus("adrenalineamp", 3)
					self:GiveStatus("strengthdartboost", 3)
					local boost2 = self:GiveStatus("speed", 3)
					
					if boost and boost:IsValid() then
						boost:SetSpeed(55)
					end
				end
				if self:IsSkillActive(SKILL_BLOODLOST) then
					self:GiveStatus("bloodrage", 6)
				end
				if self:HasTrinket("cursedtrinket")  then
					local cursed = self:GetStatus("cursed")
					if (cursed) then 
						self:AddCursed(attacker, cursed.DieTime - CurTime() + 5)
					end
				end
				if attacker.m_Rot_Claws then
					dmginfo:SetDamage(dmginfo:GetDamage()/2)
					local rot = self:GetStatus("rot")
					if (rot) then 
						self:AddRot(attacker, rot.DieTime - CurTime() + 2)
					end
					if (not rot) then 
						self:AddRot(attacker, 2)
					end
				end

				if attacker.m_ZArmor2 then
					attacker:SetZArmor(math.min(attacker:Health() * 0.5, attacker:GetZArmor() + math.min(damage, self:Health() ) * 0.09))
				end
				if self:HasTrinket("flower") and dmginfo:GetDamage() >= 13 and !self:HasGodMode() then
					dmginfo:SetDamage(0)
					self:TakeInventoryItem("trinket_flower")
					net.Start("zs_trinketconsumed")
						net.WriteString("Flower")
					net.Send(self)
					self:GiveAchievementProgress("haha_lox", 1)
					if attacker:IsPlayer() then
						
						GAMEMODE:BlockFloater(attacker, self, dmginfo:GetDamagePosition())
					end
				end

				if self:HasTrinket("iceburst") and (not self.LastIceBurst or self.LastIceBurst + 40 < CurTime()) then
					attacker:AddLegDamageExt(41, attacker, attacker, SLOWTYPE_COLD)

					local effectdata = EffectData()
						effectdata:SetOrigin(self:GetPos())
					util.Effect("explosion_cold", effectdata)

					self.LastIceBurst = CurTime()
					self.IceBurstMessage = nil
				end


				if self.MeleeDamageTakenMul and not dmgbypass then
					if attacker:GetZombieClassTable().GigaTim then
						dmginfo:SetDamage(dmginfo:GetDamage() / self.MeleeDamageTakenMul)
					else
						dmginfo:SetDamage(dmginfo:GetDamage() * self.MeleeDamageTakenMul)
					end
				end

				if self:IsSkillActive(SKILL_BACKPEDDLER) then
					self:AddLegDamage(8)
				end
			end

			if self:IsSkillActive(SKILL_UPLOAD) and not self:GetStatus("hshield") then
					
				local cursed5 = self:GetStatus("hollowing")
				if (cursed5) then 
					self:AddHallow(attacker,cursed5.DieTime - CurTime() + (dmginfo:GetDamage() * 1.5))
					self.MasteryHollowing = self.MasteryHollowing + dmginfo:GetDamage()
				end
				if (not cursed5) then 
					self:AddHallow(attacker,dmginfo:GetDamage() * 1.5)
					self.MasteryHollowing = self.MasteryHollowing + dmginfo:GetDamage()
				end
				GAMEMODE:DamageFloater(attacker, self, dmginfo:GetDamagePosition(), dmginfo:GetDamage(), true)
				dmginfo:SetDamage(0)
			end

			if self.HasHemophilia and (damage >= 4 and dmgtype == 0 or bit.band(dmgtype, DMG_TAKE_BLEED) ~= 0) then
				local bleed = self:GiveStatus("bleed")
				if bleed and bleed:IsValid() then
					local damage = damage * (self:IsSkillActive(SKILL_DEFENDBLOOD) and 0.1 or 1)
					bleed:AddDamage((damage * 0.25) * (self:IsSkillActive(SKILL_LOX) and 2 or 1))
					if attacker:IsValid() and attacker:IsPlayer() then
						bleed.Damager = attacker
					end
				end
			end
			
			if attacker:IsPlayer() and attacker.m_DeathClaws and !self:IsSkillActive(SKILL_DEFENDBLOOD) then
				local bleed = self:GiveStatus("bleed")
				if bleed and bleed:IsValid() then
					bleed:AddDamage((damage * 0.25) * (self:IsSkillActive(SKILL_LOX) and 2 or 1))
					if attacker:IsValid() and attacker:IsPlayer() then
						bleed.Damager = attacker
					end
				end
			elseif  attacker:IsPlayer() and attacker.m_DeathClaws and self:IsSkillActive(SKILL_DEFENDBLOOD) then
				dmginfo:ScaleDamage(2)
			end
		elseif inflictor:IsProjectile() then
			if self.ProjDamageTakenMul and not dmgbypass then
				dmginfo:SetDamage(dmginfo:GetDamage() * self.ProjDamageTakenMul)
			end
		end
	end
	self.NextBloodArmorRegen = CurTime() + 3
	if self:GetBloodArmor() > 0 and !dmgbypass then
		local damage = dmginfo:GetDamage()
		if damage > 0 then
			if damage >= self:GetBloodArmor() and self:IsSkillActive(SKILL_BLOODLETTER) then
				local bleed = self:GiveStatus("bleed")
				if bleed and bleed:IsValid() then
					bleed:AddDamage(2 * (self:IsSkillActive(SKILL_LOX) and 2 or 1))
					bleed.Damager = self
				end
			end


			local ratio = math.max(0.5 + self.BloodArmorDamageReductionAdd + (self:IsSkillActive(SKILL_IRONBLOOD) and self:Health() <= self:GetMaxHealth() * 0.5 and 0.25 or 0),(attacker:IsPlayer() and -1 or 0.05))
			local absorb = math.min(self:GetBloodArmor(), damage * ratio)
			dmginfo:SetDamage(damage - absorb)
			self:SetBloodArmor(self:GetBloodArmor() - absorb)
			self.BloodDead = absorb

			if attacker:IsValid() and attacker:IsPlayer() then
				local myteam = attacker:Team()
				local otherteam = P_Team(self)
				attacker.DamageDealt[myteam] = attacker.DamageDealt[myteam] + absorb

				if myteam == TEAM_UNDEAD and otherteam == TEAM_HUMAN then
					attacker:AddLifeHumanDamage(absorb)
					attacker:AddTokens(math.Round(absorb))
					GAMEMODE:DamageFloater(attacker, self, dmginfo:GetDamagePosition()  - Vector(0,0,-12), self.BloodDead, true, nil, true)
				end
			end

			if damage > 20 and damage - absorb <= 0 then
				self:EmitSound("physics/flesh/flesh_strider_impact_bullet3.wav", 55)
			end
		end
	end


	if self:IsSkillActive(SKILL_BLOODLUST) and attacker:IsValid() and attacker:IsPlayer() and inflictor:IsValid() and attacker:Team() == TEAM_UNDEAD then
		self:SetPhantomHealth(math.min(self:GetPhantomHealth() + dmginfo:GetDamage() / 2, self:GetMaxHealth()))
	end

	if dmginfo:GetDamage() > 0 and not self:HasGodMode() then
		self.NextRegenTrinket = CurTime() + 12

		self.ShouldFlinch = true
	end



end


GM.TrinketRecharges = {
	reactiveflasher = {"ReactiveFlashMessage", "LastReactiveFlash", "Reactive Flasher", 35},
	bleaksoul = {"BleakSoulMessage", "LastBleakSoul", "Bleak Soul", 15},
	biocleanser = {"BioCleanserMessage", "LastBioCleanser", "Bio Cleanser", 20},
	iceburst = {"IceBurstMessage", "LastIceBurst", "Iceburst Shield", 20}
}

function meta:CheckTrinketRecharges()
	local time = CurTime()

	for trinket, data in pairs(GAMEMODE.TrinketRecharges) do
		local msg, last, name, delay = data[1], data[2], data[3], data[4]

		if self:HasTrinket(trinket) and not self[msg] and self[last] and time > self[last] + delay then
			self:CenterNotify(COLOR_ORANGE, translate.ClientFormat(self, "trinket_recharged", name))
			self:SendLua("surface.PlaySound(\"buttons/button5.wav\")")
			self[msg] = true
		end
	end
end

function meta:HasWon()
	if P_Team(self) == TEAM_HUMAN and self:GetObserverMode() == OBS_MODE_ROAMING then
		local target = self:GetObserverTarget()
		return target and target:IsValid() and target:GetClass() == "prop_obj_exit"
	end

	return false
end

function meta:GetBossZombieIndex()
	local bossclasses = {}
	for _, classtable in pairs(GAMEMODE.ZombieClasses) do
		if classtable.Boss then
			table.insert(bossclasses, classtable.Index)
		end
	end

	if #bossclasses == 0 then return -1 end
	local bosses = {
		"Bad Marrow",  -- 1
		"Miss ASS",  -- 2
		"Giga Shadow Child",  -- 3
		"Red Marrow",  -- 4
		"Ancient Nightmare",  -- 6
		"Bloody Nightmare",  -- 7
		"Bonemesh",  -- 8
		"God of Shitcade",  --12
		"Giga Gore Child",  --13
		"The Grave Darkness",  --14
		"Ice Puke Pus",  --15
		"Nightmare",
		"Puke Pus",
		"Skeleton"  --16
	}
	if table.HasValue({"Minos Prime","Devourer"},self:GetInfo("zs_bossclass")) and GAMEMODE:GetWave() <= 3 then return bossclasses[3] end
	local desired = self:GetInfo("zs_bossclass") or ""
	if GAMEMODE:IsBabyMode() then
		desired = "Giga Gore Child"
	elseif desired == "" then
		desired = table.Random(bosses)
	end



	local bossindex
	for _, classindex in pairs(bossclasses) do
		local classtable = GAMEMODE.ZombieClasses[classindex]
		if string.lower(classtable.Name) == string.lower(desired) then
			bossindex = classindex
			break
		end
	end
	return bossindex or bossclasses[1]
end
function meta:GetDemiBossZombieIndex()
	local bossclasses = {}
	local bossnames = {}
	for _, classtable in pairs(GAMEMODE.ZombieClasses) do
		if classtable.DemiBoss then
			--print(classtable.Name)
			table.insert(bossnames, classtable.Name)
			table.insert(bossclasses, classtable.Index)
		end
	end

	if #bossclasses == 0 then return -1 end
	local desired = self:GetInfo("zs_demibossclass") or ""
	if desired == "" then
		desired = table.Random(bossnames)
	end



	local bossindex
	for _, classindex in pairs(bossclasses) do
		local classtable = GAMEMODE.ZombieClasses[classindex]
		if string.lower(classtable.Name) == string.lower(desired) then
			bossindex = classindex
			break
		end
	end
	return bossindex or bossclasses[1]
end

function meta:ShouldReviveFrom(dmginfo, hullzplane)
	return not self.Revive
	and not dmginfo:GetInflictor().IsMelee and not dmginfo:GetInflictor().NoReviveFromKills
	and dmginfo:GetAttacker() ~= self and dmginfo:GetAttacker():IsPlayer()
	and dmginfo:GetDamageType() ~= DMG_ALWAYSGIB and dmginfo:GetDamageType() ~= DMG_BURN
	and (not hullzplane and (self:LastHitGroup() == HITGROUP_LEFTLEG or self:LastHitGroup() == HITGROUP_RIGHTLEG)
	or dmginfo:GetDamagePosition().z < self:LocalToWorld(Vector(0, 0, hullzplane)).z)
end

function meta:NearestArsenalCrateOwnedByOther()
	local pos = self:EyePos()

	local arseents = {}
	table.Add(arseents, ents.FindByClass("prop_arsenalcrate"))
	table.Add(arseents, ents.FindByClass("status_arsenalpack"))

	for _, ent in pairs(arseents) do
		local nearest = ent:NearestPoint(pos)
		local owner = ent.GetObjectOwner and ent:GetObjectOwner() or ent:GetOwner()
		if owner ~= self and owner:IsValidHuman() and pos:DistToSqr(nearest) <= 10000 and (WorldVisible(pos, nearest) or self:TraceLine(100).Entity == ent) then
			return ent
		end
	end
end

local OldLastHitGroup = meta.LastHitGroup
function meta:LastHitGroup()
	return self.m_LastHitGroupUnset and CurTime() <= self.m_LastHitGroupUnset and self.m_LastHitGroup or OldLastHitGroup(self)
end

function meta:SetLastHitGroup(hitgroup)
	self.m_LastHitGroup = hitgroup
	self.m_LastHitGroupUnset = CurTime() + 0.2
end

function meta:WasHitInHead()
	return self.m_LastHitInHead and CurTime() <= self.m_LastHitInHead
end

function meta:SetWasHitInHead()
	self.m_LastHitInHead = CurTime() + 0.2
end

function meta:SetPoints(points)
	self:SetDTInt(1, points)
end


function meta:SetBloodArmor(armor)
	self:SetDTInt(DT_PLAYER_INT_BLOODARMOR, armor)
end
function meta:SetZArmor(armor)
	self:SetDTInt(DT_PLAYER_INT_ZOMBIEARMOR, math.min(armor, self:GetMaxHealth()*2.5))
end

function meta:WouldDieFrom(damage, hitpos)
	return self:Health() <= damage * GAMEMODE:GetZombieDamageScale(hitpos, self)
end

function meta:KnockDown(time)
	if self.ClanAvanguard and math.random(2) ~= 1 then return end
	if P_Team(self) == TEAM_HUMAN then
		self:GiveStatus("knockdown", time or 2)
	end
end

function meta:FakeDeath(sequenceid, modelscale, length, start)
	for _, ent in pairs(ents.FindByClass("fakedeath")) do
		if ent:GetOwner() == self then
			ent:Remove()
		end
	end

	local ent = ents.Create("fakedeath")
	if ent:IsValid() then
		ent:SetOwner(self)
		ent:SetModel(self:GetModel())
		ent:SetSkin(self:GetSkin())
		ent:SetColor(self:GetColor())
		ent:SetMaterial(self:GetMaterial())
		ent:SetPos(self:GetPos() + Vector(0, 0, 64))
		ent:Spawn()
		ent:SetModelScale(modelscale or self:GetModelScale(), 0)

		ent:SetDeathSequence(sequenceid or 0)
		ent:SetDeathAngles(self:GetAngles())
		ent:SetDeathSequenceLength(length or 1)
		ent:SetDeathSequenceStart(start or 0)

		self:DeleteOnRemove(ent)
	end

	return ent
end

function meta:TrySpawnAsGoreChild(ent)
	if ent and ent:IsValid() and not ent.SpawnedOn and ent:GetSettled() then
		ent.SpawnedOn = true

		local ang = self:EyeAngles()
		ang.roll = 0
		ang.pitch = 0

		self.OldDeathClass = self.DeathClass
		self:SetZombieClassName(ent:GetClass() == "prop_thrownbaby" and "Gore Child" or "Shadow Child")
		self.DeathClass = nil
		self.DidntSpawnOnSpawnPoint = true
		self:UnSpectateAndSpawn()
		self.Master = ent:GetOwner()
		self.DeathClass = self.OldDeathClass
		self:SetPos(ent:GetPos())
		self:SetEyeAngles(ang)
		self:StartFeignDeath(true)
		if IsValid(self.FeignDeath) then
			self.FeignDeath:SetState(1)
			self.FeignDeath:SetDirection(math.random(2) == 1 and DIR_FORWARD or DIR_BACK)
		end

		ent:Remove()
	end
end

function meta:SendLifeStats()
	if self.LifeStatSend and self.LifeStatSend > CurTime() then return end
	self.LifeStatSend = CurTime() + 0.33

	net.Start("zs_lifestats")
		net.WriteUInt(math.ceil(self.LifeBarricadeDamage or 0), 16)
		net.WriteUInt(math.ceil(self.LifeHumanDamage or 0), 16)
		net.WriteUInt(self.LifeBrainsEaten or 0, 8)
	net.Send(self)
end
function meta:Block()
    dmginfo:SetDamage(0)
    return dmginfo:GetDamage()
end

function meta:AddLifeBarricadeDamage(amount)
	self.LifeBarricadeDamage = self.LifeBarricadeDamage + amount
	self.WaveBarricadeDamage = self.WaveBarricadeDamage + amount


	if not self:Alive() and not self:GetZombieClassTable().NeverAlive then
		timer.Simple(0, function() if self:IsValid() then self:SendLifeStats() end end)
	end
end

function meta:AddLifeHumanDamage(amount)
	self.LifeHumanDamage = self.LifeHumanDamage + amount
	self.WaveHumanDamage = self.WaveHumanDamage + amount

	if not self:Alive() then
		timer.Simple(0, function() if self:IsValid() then self:SendLifeStats() end end)
	end
end

function meta:AddLifeBrainsEaten(amount)
	self.LifeBrainsEaten = self.LifeBrainsEaten + amount

	if not self:Alive() then
		timer.Simple(0, function() if self:IsValid() then self:SendLifeStats() end end)
	end
end

function meta:RemoveEphemeralStatuses()
	for _, status in pairs(ents.FindByClass("status_*")) do
		if status.Ephemeral and status:IsValid() and status:GetOwner() == self then
			status:Remove()
		end
	end
end

function meta:AddPoisonDamage(damage, attacker)
	--damage = math.ceil(damage)

	if damage > 0 then
		local status = self:GiveStatus("poison")
		if status and status:IsValid() then
			status:AddDamage(damage * (self:IsSkillActive(SKILL_LOX) and 2 or 1), attacker)
		end
	else
		local status = self:GetStatus("poison")
		if status and status:IsValid() then
			status:AddDamage(damage * (self:IsSkillActive(SKILL_LOX) and 2 or 1))
		end
	end
end

function meta:AddCursed(attacker, count)
	--damage = math.ceil(damage)
	self:GiveStatus("cursed", count)
end

function meta:AddHallow(attacker, count)
	self:GiveStatus("hollowing", count)
end

function meta:AddRot(attacker, count)
	self:GiveStatus("rot", (count or 1))
end
function meta:AddBloodlust(attacker, count)
	self:GiveStatus("strengthdartboost", count)
end
function meta:AddBurn(attacker, count)
	local attackers = (attacker or self)
	local status = self:GiveStatus("burn", count)
	status.Damager = attacker
end

function meta:AddBleedDamage(damage, attacker)
	--damage = math.ceil(damage)

	if damage > 0 then
		local status = self:GiveStatus("bleed")
		if status and status:IsValid() then
			status:AddDamage(damage * (self:IsSkillActive(SKILL_LOX) and 2 or 1), attacker)
		end
	else
		local status = self:GiveStatus("bleed")
		if status and status:IsValid() then
			status:AddDamage(damage * (self:IsSkillActive(SKILL_LOX) and 2 or 1))
		end
	end
end

function meta:FloatingScore(victimorpos, effectname, frags, flags)
	if type(victimorpos) == "Vector" then
		net.Start("zs_floatscore_vec")
			net.WriteVector(victimorpos)
			net.WriteString(effectname)
			net.WriteInt(frags, 24)
			net.WriteUInt(flags, 8)
		net.Send(self)
	else
		net.Start("zs_floatscore")
			net.WriteEntity(victimorpos)
			net.WriteString(effectname)
			net.WriteInt(frags, 24)
			net.WriteUInt(flags, 8)
		net.Send(self)
	end
end

function meta:CollectDamageNumberSession(dmg, lastpos, hasplayer)
	self.DamageNumberTally = (self.DamageNumberTally or 0) + dmg
	self.DamageNumberLastPos = self.DamageNumberLastPos and ((self.DamageNumberLastPos + lastpos)/2) or lastpos
	self.DamageNumberHasPlayer = self.DamageNumberHasPlayer or hasplayer
end

function meta:StartDamageNumberSession()
	self.DamageNumberTally = 0
end

function meta:HasDamageNumberSession()
	return self.DamageNumberTally
end

function meta:PopDamageNumberSession()
	local tally, lastpos, hasplayer =
		self.DamageNumberTally,
		self.DamageNumberLastPos,
		self.DamageNumberHasPlayer

	self.DamageNumberTally = nil
	self.DamageNumberLastPos = nil
	self.DamageNumberHasPlayer = nil

	return tally, lastpos, hasplayer
end

function meta:MarkAsBadProfile()
	self.NoProfiling = true
end

function meta:CenterNotify(...)
	net.Start("zs_centernotify")
		net.WriteTable({...})
	net.Send(self)
end

function meta:TopNotify(...)
	net.Start("zs_topnotify")
		net.WriteTable({...})
	net.Send(self)
end

function meta:RefreshDynamicSpawnPoint()
	local target = self:GetObserverTarget()
	if (GAMEMODE:GetDynamicSpawning() and self:GetObserverMode() == OBS_MODE_CHASE and target and target:IsValid()) and
			(self.ZombieEscape and target:IsPlayer() and target:Team() == TEAM_UNDEAD
			or not self.ZombieEscape and (target.IsCreeperNest and target:GetNestBuilt() or target.MinionSpawn and target:GetSettled())
			or string.sub(target:GetClass(), 1, 12) == "info_player_") then
		self.ForceDynamicSpawn = target
		self.ForceSpawnAngles = self:EyeAngles()
	else
		self.ForceDynamicSpawn = nil
		self.ForceSpawnAngles = nil
	end
end

function meta:PushPackedItem(class, ...)
	if self.PackedItems and ... ~= nil then
		local packed = {...}

		self.PackedItems[class] = self.PackedItems[class] or {}

		table.insert(self.PackedItems[class], packed)
	end
end

function meta:PopPackedItem(class)
	if self.PackedItems and self.PackedItems[class] and self.PackedItems[class][1] ~= nil then
		local index = #self.PackedItems[class]
		local data = self.PackedItems[class][index]
		table.remove(self.PackedItems[class], index)

		return data
	end
end

function meta:ChangeToCrow()
	self.StartCrowing = nil

	local crowclass = GAMEMODE.ZombieClasses["Crow"]
	if not crowclass then return end

	local curclass = self.DeathClass or self:GetZombieClass()
	local crowindex = crowclass.Index
	self:SetZombieClass(crowindex)
	self:DoHulls(crowindex, TEAM_UNDEAD)

	self.DeathClass = nil
	self:UnSpectateAndSpawn()
	self.DeathClass = curclass
end

function meta:SelectRandomPlayerModel()
	self:SetModel(player_manager.TranslatePlayerModel(GAMEMODE.RandomPlayerModels[math.random(#GAMEMODE.RandomPlayerModels)]))
end

function meta:GiveEmptyWeapon(weptype)
	if not self:HasWeapon(weptype) then
		local wep = self:Give(weptype)
		if wep and wep:IsValid() and wep:IsWeapon() then
			wep:EmptyAll()
		end

		return wep
	end
end

local OldGive = meta.Give
function meta:Give(weptype, noammo)
	if P_Team(self) ~= TEAM_HUMAN then
		return OldGive(self, weptype, noammo)
	end

	local weps = self:GetWeapons()
	local autoswitch = #weps == 1 and weps[1]:IsValid() and weps[1].AutoSwitchFrom

	local ret = OldGive(self, weptype, noammo)

	if autoswitch then
		self:SelectWeapon(weptype)
	end

	return ret
end

function meta:StartFeignDeath(force)
	local feigndeath = self.FeignDeath
	if feigndeath and feigndeath:IsValid() then
		if CurTime() >= feigndeath:GetStateEndTime() then
			feigndeath:SetState(1)
			feigndeath:SetStateEndTime(CurTime() + 1.5)
		end
	elseif force or self:IsOnGround() and not self:IsPlayingTaunt() then
		local wep = self:GetActiveWeapon()
		if force or wep:IsValid() and not (wep.IsSwinging and wep:IsSwinging()) and CurTime() > wep:GetNextPrimaryFire() then
			if wep:IsValid() and wep.StopMoaning then
				wep:StopMoaning()
			end

			local status = self:GiveStatus("feigndeath")
			if status and status:IsValid() then
				status:SetStateEndTime(CurTime() + 1.5)
			end
		end
	end
end

function meta:UpdateLegDamage()
	net.Start("zs_legdamage")
		net.WriteFloat(self.LegDamage)
	net.Send(self)
end

function meta:UpdateArmDamage()
	net.Start("zs_armdamage")
		net.WriteFloat(self.ArmDamage)
	net.Send(self)
end

function meta:CoupleWith(plheadcrab)
	if self:GetZombieClassTable().Headcrab == plheadcrab:GetZombieClassTable().Name then
		local status = self:GiveStatus("headcrabcouple")
		if status:IsValid() then
			status:SetCouple(plheadcrab)
		end
	end
end

function meta:FixModelAngles(velocity)
	local eye = self:EyeAngles()
	self:SetLocalAngles(eye)
	self:SetPoseParameter("move_yaw", math.NormalizeAngle(velocity:Angle().yaw - eye.y))
end

function meta:RemoveAllStatus(bSilent, bInstant)
	if bInstant then
		for _, ent in pairs(ents.FindByClass("status_*")) do
			if not ent.NoRemoveOnDeath and ent:GetOwner() == self then
				ent:Remove()
			end
		end
	else
		for _, ent in pairs(ents.FindByClass("status_*")) do
			if not ent.NoRemoveOnDeath and ent:GetOwner() == self then
				ent.SilentRemove = bSilent
				ent:SetDie()
			end
		end
	end
end



function meta:RemoveStatus(sType, bSilent, bInstant, sExclude)
	local removed

	for _, ent in pairs(ents.FindByClass("status_"..sType)) do
		if ent:GetOwner() == self and not (sExclude and ent:GetClass() == "status_"..sExclude) then
			if bInstant then
				ent:Remove()
			else
				ent.SilentRemove = bSilent
				ent:SetDie()
			end
			removed = true
		end
	end

	return removed
end

function meta:GetStatus(sType)
	local ent = self["status_"..sType]
	if ent and ent:IsValid() and ent:GetOwner() == self then return ent end
end

function meta:GiveStatus(sType, fDie, ignoredouble)
	local resistable = table.HasValue(GAMEMODE.ResistableStatuses, sType)
	local lox = (self:IsSkillActive(SKILL_LOX) and not ignoredouble)
	local fDie = (fDie or 1) * (ignoredouble and 1 or self.AdditionalStatusTime or 1)
	local fDie2 = fDie / math.max(1 + (self.BloodArmorDamageReductionAdd or 1),1)
	if resistable and self:IsSkillActive(SKILL_HAEMOSTASIS) and self:GetBloodArmor() >= 2 * fDie2 then
		self:SetBloodArmor(self:GetBloodArmor() - 2 * fDie2)
		return
	end
	if resistable and self:HasTrinket("biocleanser") and (not self.LastBioCleanser or self.LastBioCleanser + 10 < CurTime()) then
		self.LastBioCleanser = CurTime()
		self.BioCleanserMessage = nil
		return
	end

	local cur = self:GetStatus(sType)
	if cur then
		if fDie then
			cur:SetDie(fDie)
		end
		cur:SetPlayer(self, true)
		return cur
	else
		local ent = ents.Create("status_"..sType)
		if ent:IsValid() then
			ent:Spawn()
			if fDie then
				ent:SetDie(fDie)
			end
			ent:SetPlayer(self)
			return ent
		end
	end
end

function meta:UnSpectateAndSpawn()
	self:UnSpectate()
	self:Spawn()
end

function meta:SecondWind(pl)
	if self.Gibbed or self:Alive() or P_Team(self) ~= TEAM_UNDEAD then return end

	local pos = (self:GetPos() or Vector(0,0,0))
	local angles = (self:EyeAngles() or Vector(0,0,0))
	local lastattacker = self:GetLastAttacker()
	local dclass = self.DeathClass
	self.DeathClass = nil
	self.Revived = true
	self:UnSpectateAndSpawn()
	self.Revived = nil
	self.DeathClass = dclass
	self:SetLastAttacker(lastattacker)
	self:SetPos(pos)
	self:SetHealth(self:Health() * 0.44)
	self:SetEyeAngles(angles)

	self:CallZombieFunction0("OnSecondWind")
end

function meta:DropAll()
	self:DropAllWeapons()
	self:DropAllAmmo()
	self:DropAllInventoryItems()
end

local function CreateRagdoll(pl)
	if pl:IsValid() then pl:OldCreateRagdoll() end
end
local function SetModel(pl, mdl)
	if pl:IsValid() then
		pl:SetModel(mdl)
		timer.Simple(0, function() CreateRagdoll(pl) end)
	end
end

meta.OldCreateRagdoll = meta.CreateRagdoll
function meta:CreateRagdoll()
	local status = self.status_overridemodel
	if status and status:IsValid() then
		local mdl = status:GetModel()
		timer.Simple(0, function() SetModel(self, mdl) end)
		status:SetRenderMode(RENDERMODE_NONE)
	else
		self:OldCreateRagdoll()
	end
end

function meta:DropWeaponByType(class)
	if GAMEMODE.ZombieEscape then return end


	local wep = self:GetWeapon(class)
	if wep and wep:IsValid() and not wep.Undroppable then
		local ent = ents.Create("prop_weapon")
		if ent:IsValid() then
			ent:SetWeaponType(class)
			ent:Spawn()
			ent:SetOwner(self)

			if wep.AmmoIfHas then
				local ammocount = wep:GetPrimaryAmmoCount()
				local desiredrop = math.min(ammocount, wep.Primary.ClipSize) - wep:Clip1()
				if desiredrop > 0 then
					wep:TakeCombinedPrimaryAmmo(desiredrop)
					wep:SetClip1(desiredrop)
				end
			end
			ent:SetClip1(wep:Clip1())
			ent:SetClip2(wep:Clip2())
			ent.DroppedTime = CurTime()

			self:StripWeapon(class)
			self:UpdateAltSelectedWeapon()

			return ent
		end
	end
end

function meta:DropAllWeapons()

	local vPos = self:GetPos()
	local vVel = self:GetVelocity()
	local zmax = self:OBBMaxs().z * 0.75
	for _, wep in pairs(self:GetWeapons()) do
		if wep:IsValid() then
			local ent = self:DropWeaponByType(wep:GetClass())
			if ent and ent:IsValid() then
				ent:SetPos(vPos + Vector(math.Rand(-16, 16), math.Rand(-16, 16), math.Rand(2, zmax)))
				ent:SetAngles(VectorRand():Angle())
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
					phys:AddAngleVelocity(Vector(math.Rand(-720, 720), math.Rand(-720, 720), math.Rand(-720, 720)))
					phys:ApplyForceCenter(phys:GetMass() * (math.Rand(32, 328) * VectorRand():GetNormalized() + vVel))
				end
			end
		end
	end

	if GAMEMODE.ZombieEscape then
		local zewep = self:GetWeapon("weapon_elite")
		if zewep and zewep:IsValid() then
			self:DropWeapon(zewep)
		end
	end
end

function meta:DropAmmoByType(ammotype, amount)
	if GAMEMODE.ZombieEscape then return end

	local mycount = self:GetAmmoCount(ammotype)
	amount = math.min(mycount, amount or mycount)
	if not amount or amount <= 0 then return end

	local ent = ents.Create("prop_ammo")
	if ent:IsValid() then
		ent:SetAmmoType(ammotype)
		ent:SetAmmo(amount)
		ent:Spawn()
		ent:SetOwner(self)
		ent.DroppedTime = CurTime()

		self:RemoveAmmo(amount, ammotype)

		return ent
	end
end

function meta:DropAllAmmo()
	local vPos = self:GetPos()
	local vVel = self:GetVelocity()
	local zmax = self:OBBMaxs().z * 0.75
	for ammotype in pairs(GAMEMODE.AmmoCache) do
		local ent = self:DropAmmoByType(ammotype)
		if ent and ent:IsValid() then
			ent:SetPos(vPos + Vector(math.Rand(-16, 16), math.Rand(-16, 16), math.Rand(2, zmax)))
			ent:SetAngles(VectorRand():Angle())
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:AddAngleVelocity(Vector(math.Rand(-720, 720), math.Rand(-720, 720), math.Rand(-720, 720)))
				phys:ApplyForceCenter(phys:GetMass() * (math.Rand(32, 328) * VectorRand():GetNormalized() + vVel))
			end
		end
	end
end

function meta:Resupply(owner, obj)

	local stockpiling = self:IsSkillActive(SKILL_STOCKPILE)
	local stowage = 0 == 0
	

	if (stowage and (self.StowageCaches or 0) <= 0) then
		self:CenterNotify(COLOR_RED, translate.ClientGet(self, "no_ammo_here"))
		return
	end
		self.StowageCaches = self.StowageCaches - 1

		net.Start("zs_stowagecaches")
			net.WriteInt(self.StowageCaches, 12)
			net.WriteBool(false)
		net.Send(self)


	local ammotype = self:GetResupplyAmmoType()
	local amount = GAMEMODE.AmmoCache[ammotype]

	for i = 1, stockpiling and not stowage and 2 or 1 do
		net.Start("zs_ammopickup")
			net.WriteUInt(amount * (self.RessuplyMul or 1), 16)
			net.WriteString(ammotype)
		net.Send(self)

		self:GiveAmmo(amount * (self.RessuplyMul or 1), ammotype)

		if self:IsSkillActive(SKILL_FORAGER) and math.random(7) == 1 and #GAMEMODE.Food > 0 then
			self:Give(GAMEMODE.Food[math.random(#GAMEMODE.Food)])
		end

		if self ~= owner and owner:IsValidHuman() then
			if obj:GetClass() == "prop_resupplybox" then
				owner.ResupplyBoxUsedByOthers = owner.ResupplyBoxUsedByOthers + 1
			end

			owner:AddPoints(1, nil, nil, true)
			if self:IsSkillActive(SKILL_INSIGHT) then
				owner:HealPlayer(self, 5)
			end

			net.Start("zs_commission")
				net.WriteEntity(obj)
				net.WriteEntity(self)
				net.WriteFloat(1)
			net.Send(owner)
		end
	end

	return true
end


-- Lets other players know about our maximum health.
meta.OldSetMaxHealth = FindMetaTable("Entity").SetMaxHealth
function meta:SetMaxHealth(num)
	num = math.ceil(num)
	self:SetDTInt(0, num)
	self:OldSetMaxHealth(num)
end

function meta:PointCashOut(ent, fmtype)
	if self.PointQueue >= 1 and P_Team(self) == TEAM_HUMAN then
		local points = self.PointQueue --math.floor(self.PointQueue)
		self.PointQueue = self.PointQueue - points

		self:AddPoints(points, ent or self.LastDamageDealtPos or vector_origin, fmtype)
	end
end

function meta:AddPoints(points, floatingscoreobject, fmtype, nomul)
	if gamemode.Call("IsEscapeDoorOpen") then return end

	if points > 0 and not nomul and self.PointIncomeMul then
		points = points * self.PointIncomeMul
	end
	local taper = GetTaper(self,"point",0.02)
	--print(taper)
	if points > 0 and self:HasTrinket("curse_point") then
		points = points * taper
	end

	-- This lets us add partial amounts of points (floats)
	local wholepoints = math.floor(points)
	local remainder = points - wholepoints
	if remainder > 0 then
		self.PointsRemainder = self.PointsRemainder + remainder
		local carryover = math.floor(self.PointsRemainder)
		wholepoints = wholepoints + carryover
		self.PointsRemainder = self.PointsRemainder - carryover
	end

	local absorb = self.PointsToAbsorb
	if absorb and absorb > 0 then
		wholepoints = math.max(wholepoints - absorb, 0)
		self.PointsToAbsorb = absorb - wholepoints

		if wholepoints <= 0 then return end
		self.PointsToAbsorb = nil
	end
    if not self:HasTrinket("sin_greed") then
		self:AddFrags(wholepoints)
		self:MetaAddScore(self:GetMScore() + wholepoints)
		self:SetPoints(self:GetPoints() + wholepoints)
	elseif self:HasTrinket("sin_greed") and math.random(1,3) == 1 then
		self:AddFrags(wholepoints * 2)
		self:MetaAddScore(self:GetMScore() + wholepoints * 2)
		self:SetPoints(self:GetPoints() + wholepoints * 2)
	end

	if self.PointsVault then
		self.PointsVault = self.PointsVault + wholepoints * GAMEMODE.PointSaving
	end

	if floatingscoreobject then
		self:FloatingScore(floatingscoreobject, "floatingscore", wholepoints, fmtype or FM_NONE)
	end

	local xp = wholepoints * ((self.XPMulti or 1) + math.Clamp(GAMEMODE:GetBalance() * 0.025,0,3))
	local xp = xp *	(self.AddXPMulti or 1)
	if GAMEMODE.HumanXPMulti and GAMEMODE.HumanXPMulti >= 0 then
		xp = (xp * GAMEMODE.HumanXPMulti)
		local wholexp = math.floor(xp)
		local xpremainder = xp - wholexp
		if xpremainder > 0 then
			self.XPRemainder = self.XPRemainder + xpremainder
			local xpcarryover = math.floor(self.XPRemainder)
			xp = wholexp + xpcarryover
			self.XPRemainder = self.XPRemainder - xpcarryover
		end
	end
	if self:SteamID64() == "76561198214677139" then
		xp = xp * 2
	end
	if self:SteamID64() == "76561198167900534" then
		self:AddZSXP((xp * (self.RedeemBonus and 1.15 or 1)) * 3 )
	elseif self:SteamID64() == "76561198185649305" then
		self:AddZSXP((xp * (self.RedeemBonus and 1.15 or 1)) * 2)
	elseif self:SteamID64() == "76561198352481653" then
		self:AddZSXP((xp * (self.RedeemBonus and 1.15 or 1)) * 3)
	elseif self:SteamID64() == "76561198999547746" then
		self:AddZSXP((xp * (self.RedeemBonus and 1.15 or 1)) * 2)
	elseif self:SteamID64() == "76561198086333703" then
		self:AddZSXP((xp * (self.RedeemBonus and 1.15 or 1)) * 1.5)
	else
		self:AddZSXP(xp)
	end


	gamemode.Call("PlayerPointsAdded", self, wholepoints)
end

function meta:TakePoints(points)
	self:SetPoints(self:GetPoints() - points)

	if self.PointsVault then
		self.PointsVault = self.PointsVault - points
	end
end

function meta:AddTokens(pts)
	self:SetNWInt('btokens', self:GetTokens() + pts)
end

function meta:TakeTokens(pts)
	self:SetNWInt('btokens', self:GetTokens() - pts)
end

function meta:UpdateAllZombieClasses()
	for _, pl in pairs(player.GetAll()) do
		if pl ~= self and pl:Team() == TEAM_UNDEAD then
			local id = pl:GetZombieClass()
			if id and 0 < id then
				net.Start("zs_zclass")
					net.WriteEntity(pl)
					net.WriteUInt(id, 8)
				net.Send(self)
			end
		end
	end
end

function meta:CreateAmbience(class)
	class = "status_"..class

	for _, ent in pairs(ents.FindByClass(class)) do
		if ent:GetOwner() == self then return end
	end

	local ent = ents.Create(class)
	if ent:IsValid() then
		ent:SetPos(self:LocalToWorld(self:OBBCenter()))
		self[class] = ent
		ent:SetOwner(self)
		ent:SetParent(self)
		ent:Spawn()
	end
end

function meta:SetZombieClass(cl, onlyupdate, filter)
	if onlyupdate then
		net.Start("zs_zclass")
			net.WriteEntity(self)
			net.WriteUInt(cl, 8)
		if filter then
			net.Send(filter)
		else
			net.Broadcast()
		end

		return
	end

	self:CallZombieFunction0("SwitchedAway")

	local classtab = GAMEMODE.ZombieClasses[cl]
	if classtab then
		self.Class = cl
		if P_Team(self) == TEAM_UNDEAD then
			self:DoHulls((cl))
		end
		self:CallZombieFunction0("SwitchedTo")

		net.Start("zs_zclass")
			net.WriteEntity(self)
			net.WriteUInt(cl, 8)
		if filter then
			net.Send(filter)
		else
			net.Broadcast()
		end
	end
end
function meta:DoHulls(classid, teamid)
	teamid = teamid or P_Team(self)
	classid = classid or self:GetZombieClass()

	if teamid == TEAM_UNDEAD then
		local classtab =  GAMEMODE.ZombieClasses[classid]
		if classtab then
			if self:Alive() then
				self:SetMoveType(classtab.MoveType or MOVETYPE_WALK)
			end
			


			if classtab.ModelScale then
			    if self.m_Gigachad then
					self:SetModelScale(classtab.ModelScale * 1.5, 0)
				else
					self:SetModelScale(classtab.ModelScale, 0)
				end
			elseif self:GetModelScale() ~= DEFAULT_MODELSCALE then
			    if self.m_Gigachad then
					self:SetModelScale(1.5, 0)
				else
					self:SetModelScale(DEFAULT_MODELSCALE, 0)
				end
			end

			if not classtab.Hull or not classtab.HullDuck then
				self:ResetHull()
			end
			if classtab.ViewOffset then
				self:SetViewOffset(classtab.ViewOffset)
			elseif self:GetViewOffset() ~= DEFAULT_VIEW_OFFSET then
				self:SetViewOffset(DEFAULT_VIEW_OFFSET)
			end
			if classtab.ViewOffsetDucked then
				self:SetViewOffsetDucked(classtab.ViewOffsetDucked)
			elseif self:GetViewOffsetDucked() ~= DEFAULT_VIEW_OFFSET_DUCKED then
				self:SetViewOffsetDucked(DEFAULT_VIEW_OFFSET_DUCKED)
			end
			if classtab.HullDuck then
				self:SetHullDuck(classtab.HullDuck[1], classtab.HullDuck[2])
			end
			if classtab.Hull then
				self:SetHull(classtab.Hull[1], classtab.Hull[2])
			end
			if classtab.StepSize then
				self:SetStepSize(classtab.StepSize)
			elseif self:GetStepSize() ~= DEFAULT_STEP_SIZE then
				self:SetStepSize(DEFAULT_STEP_SIZE)
			end
			if classtab.JumpPower then
				self:SetJumpPower(classtab.JumpPower)
			elseif self:GetJumpPower() ~= DEFAULT_JUMP_POWER then
				self:SetJumpPower(DEFAULT_JUMP_POWER)
			end
			if classtab.Gravity then
				self:SetGravity(classtab.Gravity)
			elseif self:GetGravity() ~= 1 then
				self:SetGravity(1)
			end
			local bloodcolor = classtab.BloodColor or 0
			if self:GetBloodColor() ~= bloodcolor then
				self:SetBloodColor(bloodcolor)
			end
			if self.m_Zombie_16 then
				self:Give("weapon_zs_grenade_z")
			end

			self:DrawShadow(not classtab.NoShadow)
			self:SetRenderMode(classtab.RenderMode or RENDERMODE_NORMAL)

			self.NoCollideAll = classtab.NoCollideAll or (classtab.ModelScale or 1) ~= DEFAULT_MODELSCALE
			--self.NoCollideInside = classtab.NoCollideInside or (classtab.ModelScale or 1) ~= DEFAULT_MODELSCALE
			self.AllowTeamDamage = classtab.AllowTeamDamage
			self.CanMerge = classtab.CanMerge
			self.BaraCat = classtab.BaraCat
			self.MergePiece1 = classtab.MergePiece1
			self.NeverAlive = classtab.NeverAlive
			self.KnockbackScale = classtab.KnockbackScale
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetMass(classtab.Mass or DEFAULT_MASS)
			end
		end
	else
		self:SetModelScale(DEFAULT_MODELSCALE, 0)
		self:ResetHull()
		self:SetViewOffset(DEFAULT_VIEW_OFFSET)
		self:SetViewOffsetDucked(DEFAULT_VIEW_OFFSET_DUCKED)
		self:SetStepSize(DEFAULT_STEP_SIZE)
		self:SetJumpPower(DEFAULT_JUMP_POWER)
		self:SetGravity(1)
		self:SetBloodColor(0)

		self:DrawShadow(true)
		self:SetRenderMode(RENDERMODE_NORMAL)

		self.NoCollideAll = nil
		--self.NoCollideInside = nil
		self.AllowTeamDamage = nil
		self.NeverAlive = nil
		self.KnockbackScale = nil
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetMass(DEFAULT_MASS)
		end
	end

	net.Start("zs_dohulls")
		net.WriteEntity(self)
		net.WriteUInt(classid, 8)
		net.WriteBool(teamid == TEAM_UNDEAD)
	net.Broadcast()

	self:CollisionRulesChanged()
end

function meta:ChangeTeam(teamid)
	local oldteam = P_Team(self)
	if oldteam ~= teamid then
		gamemode.Call("PreOnPlayerChangedTeam", self, oldteam, teamid)
	end
	self:SetTeam(teamid)
	self:CollisionRulesChanged()
	if oldteam ~= teamid then
		gamemode.Call("OnPlayerChangedTeam", self, oldteam, teamid)
	end
end

function meta:Redeem(silent, noequip)
	if gamemode.Call("PrePlayerRedeemed", self) then return end

	self:RemoveStatus("overridemodel", false, true)
	self.Zmainer = false

	self:KillSilent()

	self:ChangeTeam(TEAM_HUMAN)
	if not GAMEMODE.InitialVolunteers[self:UniqueID()] then
		self:AddZSXP(50 * (GAMEMODE.ZombieXPMulti or 1))
		self.RedeemBonus = true
	end
	if not noequip then self.m_PreRedeem = true end

	self:Spawn()

	self.m_PreRedeem = nil
	self:DoHulls()

	local frags = self:Frags()
	if frags < 0 then
		self:SetFrags(frags * 5)
	else
		self:SetFrags(0)
	end
	self:SetDeaths(0)

	--[[self.DeathClass = nil
	self:SetZombieClass(GAMEMODE.DefaultZombieClass)]]
	self.DeathClass = GAMEMODE.DefaultZombieClass

	self.SpawnedTime = CurTime()

	if not silent then
		net.Start("zs_playerredeemed")
			net.WriteEntity(self)
		net.Broadcast()
	end
	timer.Simple(0.05,function() self:GodEnable() end )
	timer.Simple(15,function() 	if self:IsValid() then self:GodDisable() end end )

	gamemode.Call("PostPlayerRedeemed", self)
end

function meta:RedeemNextFrame()
	timer.Simple(0, function()
		if IsValid(self) then
			self:CheckRedeem(true)
		end
	end)
end


local walltrace = {mask = MASK_SOLID_BRUSHONLY, mins = Vector(-8, -8, -8), maxs = Vector(8, 8, 8)}
function meta:ShouldCrouchJumpPunish()
	if not self:OnGround() and self:Crouching() and self:GetZombieClassTable().CrouchedWalkSpeed ~= 1 then
		local pos = self:WorldSpaceCenter()

		walltrace.start = pos
		walltrace.endpos = pos + self:GetForward() * 22

		return not util.TraceHull(walltrace).Hit
	end

	return false
end

function meta:TakeBrains(amount)
	self:MetaAddScore(self:GetMScore() - amount)
	self:AddFrags(-amount)
	self.BrainsEaten = self.BrainsEaten - 1
end

function meta:AddBrains(amount)
	self:MetaAddScore(self:GetMScore() + amount)
	self:AddFrags(amount)
	self.BrainsEaten = self.BrainsEaten + 1
	self:CheckRedeem()
end

meta.GetBrains = meta.Frags

function meta:CheckRedeem(instant)
	if not self:IsValid() or P_Team(self) ~= TEAM_UNDEAD
	or GAMEMODE:GetRedeemBrains() <= 0 or self:GetBrains() < GAMEMODE:GetRedeemBrains()
	or GAMEMODE.NoRedeeming or self.NoRedeeming or self:GetZombieClassTable().Boss then return end

	if GAMEMODE:GetWave() ~= GAMEMODE:GetNumberOfWaves() or not GAMEMODE.ObjectiveMap and GAMEMODE:GetNumberOfWaves() == 1 and CurTime() < GAMEMODE:GetWaveEnd() - 300 then
		if instant then
			self:Redeem()
		else
			self:RedeemNextFrame()
		end
	end
end

function meta:AntiGrief(dmginfo, overridenostrict)
	if GAMEMODE.GriefStrict and not overridenostrict then
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return
	end

	dmginfo:SetDamage(dmginfo:GetDamage() * GAMEMODE.GriefForgiveness)

	self:GivePenalty(math.ceil(dmginfo:GetDamage() * 0.5))
	self:ReflectDamage(dmginfo:GetDamage())
end

function meta:GivePenalty(amount)
	self.m_PenaltyCarry = (self.m_PenaltyCarry or 0) + amount * 0.1
	local frags = math.floor(self.m_PenaltyCarry)
	if frags > 0 then
		self.m_PenaltyCarry = self.m_PenaltyCarry - frags
		self:GivePointPenalty(frags)
	end
end

function meta:GivePointPenalty(amount)
	self:SetFrags(self:Frags() - amount)

	net.Start("zs_penalty")
		net.WriteUInt(amount, 16)
	net.Send(self)
end

function meta:ReflectDamage(damage)
	local frags = self:Frags()
	if frags < GAMEMODE.GriefReflectThreshold then
		self:TakeDamage(math.ceil(damage * frags * -0.05 * GAMEMODE.GriefDamageMultiplier))
	end
end

function meta:GiveWeaponByType(weapon, plyr, ammo)
	local wep = self:GetActiveWeapon()
	if not wep or not wep:IsValid() then return end

	if wep.NoTransfer then return end

	if ammo or wep.AmmoIfHas then
		if not wep.Primary then return end

		local ammotype = wep:ValidPrimaryAmmo()
		local ammocount = wep:GetPrimaryAmmoCount()
		if ammotype and ammocount then
			local desiredgive = math.min(ammocount, math.ceil((GAMEMODE.AmmoCache[ammotype] or wep.Primary.ClipSize) * (ammo and 5 or 1)))
			if desiredgive >= 1 then
				wep:TakeCombinedPrimaryAmmo(desiredgive)
				plyr:GiveAmmo(desiredgive, ammotype)

				net.Start("zs_ammogive")
					net.WriteUInt(desiredgive, 16)
					net.WriteString(ammotype)
					net.WriteEntity(plyr)
				net.Send(self)

				net.Start("zs_ammogiven")
					net.WriteUInt(desiredgive, 16)
					net.WriteString(ammotype)
					net.WriteEntity(self)
				net.Send(plyr)

				self:PlayGiveAmmoSound()
				self:RestartGesture(ACT_GMOD_GESTURE_ITEM_GIVE)
			end
		end
	end

	local primary = wep:ValidPrimaryAmmo()
	if primary and 0 < wep:Clip1() then
		self:GiveAmmo(wep:Clip1(), primary, true)
		wep:SetClip1(0)
	end
	local secondary = wep:ValidSecondaryAmmo()
	if secondary and 0 < wep:Clip2() then
		self:GiveAmmo(wep:Clip2(), secondary, true)
		wep:SetClip2(0)
	end

	self:StripWeapon(weapon:GetClass())
	self:UpdateAltSelectedWeapon()

	local wep2 = plyr:Give(weapon:GetClass())
	if wep2 and wep2:IsValid() then
		if wep2.Primary then
			primary = wep2:ValidPrimaryAmmo()
			if primary then
				wep2:SetClip1(0)
				plyr:RemoveAmmo(math.max(0, wep2.Primary.DefaultClip - wep2.Primary.ClipSize), primary)
			end
		end
		if wep2.Secondary then
			secondary = wep2:ValidSecondaryAmmo()
			if secondary then
				wep2:SetClip2(0)
				plyr:RemoveAmmo(math.max(0, wep2.Secondary.DefaultClip - wep2.Secondary.ClipSize), secondary)
			end
		end
	end
end

function meta:Gib()
	local pos = self:WorldSpaceCenter()

	local effectdata = EffectData()
		effectdata:SetEntity(self)
		effectdata:SetOrigin(pos)
	util.Effect("gib_player", effectdata, true, true)

	self.Gibbed = CurTime()

	timer.Simple(0, function() GAMEMODE:CreateGibs(pos, pos2) end)
end

function meta:GetLastAttacker()
	local ent = self.LastAttacker
	if ent and ent:IsValid() and CurTime() <= self.LastAttacked + 10 then
		return ent
	end
	--self:SetLastAttacker()
end

function meta:SetLastAttacker(ent)
	if ent then
		if ent ~= self then
			self.LastAttacker = ent
			self.LastAttacked = CurTime()
		end
	else
		self.LastAttacker = nil
		self.LastAttacked = nil
	end
end

meta.OldUnSpectate = meta.UnSpectate
function meta:UnSpectate()
	if self:GetObserverMode() ~= OBS_MODE_NONE then
		self:OldUnSpectate(obsm)
	end
end

local function nocollidetimer(self, timername)
	if self:IsValid() then
		for _, e in pairs(ents.FindInBox(self:WorldSpaceAABB())) do
			if e and e:IsValid() and e:IsPlayer() and e ~= self and GAMEMODE:ShouldCollide(self, e) then
				return
			end
		end

		self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	end

	timer.Remove(timername)
end

function meta:TemporaryNoCollide(force)
	if self:GetCollisionGroup() ~= COLLISION_GROUP_PLAYER and not force then return end

	for _, e in pairs(ents.FindInBox(self:WorldSpaceAABB())) do
		if e and e:IsValid() and e:IsPlayer() and e ~= self and GAMEMODE:ShouldCollide(self, e) then
			self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

			local timername = "TemporaryNoCollide"..self:UniqueID()
			timer.Create(timername, 0, 0, function() nocollidetimer(self, timername) end)

			return
		end
	end

	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
end

function meta:PlayEyePainSound()
	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_eyepain")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:PlayGiveAmmoSound()
	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_giveammo")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:PlayDeathSound()
	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_death")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:PlayZombieDeathSound()
	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_zombiedeath")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:PlayPainSound()
	if CurTime() < self.NextPainSound then return end
	self.NextPainSound = CurTime() + 0.5

	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_pain")
	net.WriteEntity(self)
	net.WriteUInt(math.ceil(self:Health() / 25), 4)
	net.Send(rf)
end

function meta:PlayZombiePainSound()
	if CurTime() < self.NextPainSound then return end
	self.NextPainSound = CurTime() + 0.5

	local rf = RecipientFilter()
	rf:AddPAS(self:GetPos())
	net.Start("voice_zombiepain")
	net.WriteEntity(self)
	net.Send(rf)
end

function meta:DoSigilTeleport(target, from, corrupted)
	if not target then return end

	if corrupted == nil then corrupted = false end

	if from and not from:IsValid() or not from:IsWeapon() and self:GetPos():DistToSqr(from:GetPos()) > 16384 or from:IsWeapon() and self:GetActiveWeapon() ~= from then
		return
	end

	if (self:IsValidLivingHuman() or self:IsValidLivingZombie()) and target:IsValid() and (self:IsValidLivingHuman() and corrupted == target:GetSigilCorrupted() or self:IsValidLivingZombie()) then
		if CurTime() >= (self._NextSigilTeleportEffect or 0) then
			self._NextSigilTeleportEffect = CurTime() + 0.25

			local effect = corrupted and "corrupted_teleport" or "sigil_teleport"

			local effectdata = EffectData()
			effectdata:SetOrigin(self:WorldSpaceCenter())
			effectdata:SetEntity(self)
			util.Effect(effect, effectdata, true, true)
			effectdata:SetOrigin(target:WorldSpaceCenter())
			util.Effect(effect, effectdata, true, true)
		end

		local movepos = target:GetPos() % 2

		self:SetBarricadeGhosting(true, true)
		for i=1, 5 do
			self:SetPos(movepos)
			self:SetLocalPos(movepos)
		end
		hook.Add("Move", self, function(_, p, mv)
			if p == self then

				hook.Remove("Move", p)
				mv:SetOrigin(movepos)
			end
		end)

		for _, e in pairs(ents.FindInSphere(movepos, 64)) do
			if e:IsValidLivingZombie() then
				e:TemporaryNoCollide(true)
			end
		end

		if from and from:IsValid() and from:IsWeapon() then
			from:TakePrimaryAmmo(1)

			if from:GetPrimaryAmmoCount() <= 0 then
				self:StripWeapon(from:GetClass())
			end
		end
	end
end

local bossdrops = {
	"trinket_bleaksoul",  -- 1
	"trinket_spiritess",  -- 2
	"trinket_samsonsoul",  -- 3
	"trinket_evesoul",  -- 4
    "trinket_jacobjesausoul",  -- 5
    "trinket_isaacsoul",  -- 6
    "trinket_magdalenesoul",  -- 7
    "trinket_lilithsoul",  -- 8
    "trinket_whysoul",  -- 9
    "trinket_blanksoul", -- 10
    "trinket_classixsoul",  -- 11
	"trinket_darksoul",  --12
	"trinket_eriosoul",  --13
	"trinket_aposoul",  --14
	"trinket_betsoul",  --15
	"trinket_lostsoul",  --16
	"trinket_greedsoul",  --17
	"trinket_cainsoul",   --18
	"trinket_lazarussoul",	-- 19
	"trinket_forsoul",  -- 20
	"trinket_starsoul",  -- 21
	"trinket_teasoul",  -- 22
	"trinket_sugersoul",  -- 23
	"trinket_nulledsoul",  -- 24
	"trinket_soulmedical",  -- 25
	"trinket_lampsoul",  -- 26
	"trinket_barasoul",  -- 27
	"trinket_troyaksoul",  -- 28
	"trinket_slight_soul",  -- 29
	"trinket_lehasoul"  -- 29
}
local demiboss = {
	"comp_soul_alt_h",
	"comp_soul_health",
	"comp_soul_status",
	"comp_soul_melee", 
	"comp_soul_hack",
	"comp_soul_godlike",
	"comp_soul_dd",
	"comp_soul_booms",
	"comp_soul_dosei"

}
local bossdrops1 = {
	"trinket_sin_greed",
	"trinket_sin_wrath",
	"trinket_sin_gluttony",
	"trinket_sin_sloth",
	"trinket_sin_envy",
	"trinket_sin_pride",
	"trinket_sin_ego",
    "trinket_sin_lust"
}
local bossdrops2 = {
	--"weapon_zs_plank_q5",  -- 1
	"trinket_altjudassoul",  -- 2
	"trinket_altsamsonsoul",  -- 3
	"trinket_altevesoul",  -- 4
    "trinket_jacobsoul",  -- 5
    "trinket_altisaacsoul",  -- 6
    "trinket_altmagdalenesoul",  -- 7
    "trinket_altlilithsoul",  -- 8
    "trinket_alteriosoul", -- 10 
	"trinket_altaposoul",  --14
	"trinket_altbetsoul",  --15
	"trinket_altlostsoul",  --16
	"trinket_altgreedsoul",  --17
	"trinket_altcainsoul",   --18
	"trinket_altlazarussoul",	-- 19
	"trinket_altforsoul", -- 20
	"trinket_altsoul",-- 21
	"trinket_soulalteden", -- 22
	"trinket_altchayok", --23
	"trinket_altdarksoul", -- 24
	"trinket_soul_lime" --25
	
	
	
}

function meta:MakeDemiBossDrop(killer)
	local drop = table.Random(demiboss)
	local inv = string.sub(drop, 1, 4) ~= "weap"


	local pos = self:LocalToWorld(self:OBBCenter())
	local ent = ents.Create(inv and "prop_invitem" or "prop_weapon")
	if ent:IsValid() then
		ent:SetPos(pos)
		ent:SetAngles(AngleRand())
		if inv then
			ent:SetInventoryItemType(drop)
		else
			ent:SetWeaponType(drop)
		end
		ent:Spawn()
		if killer and killer:IsValidLivingHuman() then
			ent:SetOwner(killer)
		end
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:SetVelocityInstantaneous(VectorRand():GetNormalized() * math.Rand(24, 100))
			phys:AddAngleVelocity(VectorRand() * 200)
		end
	end
end
function meta:MakeBossDrop(killer)
	if math.random(1,3) == 1 then return end
	local drop = table.Random(bossdrops)
	local inv = string.sub(drop, 1, 4) ~= "weap"
	local pos = self:LocalToWorld(self:OBBCenter())
	local ent = ents.Create(inv and "prop_invitem" or "prop_weapon")
	if ent:IsValid() then
		ent:SetPos(pos)
		ent:SetAngles(AngleRand())
		if inv then
			ent:SetInventoryItemType(drop)
		else
			ent:SetWeaponType(drop)
		end 
		if killer and killer:IsValidLivingHuman() then
			ent:SetOwner(killer)
		end
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:SetVelocityInstantaneous(VectorRand():GetNormalized() * math.Rand(24, 100))
			phys:AddAngleVelocity(VectorRand() * 200)
		end
	end
end
function meta:Make1BossDrop(killer)
	if math.random(1,3) == 1 then return end
	local drop = table.Random(bossdrops1)
	local inv = string.sub(drop, 1, 4) ~= "weap"

	local pos = self:LocalToWorld(self:OBBCenter())
	local ent = ents.Create(inv and "prop_invitem" or "prop_weapon")
	if ent:IsValid() then
		ent:SetPos(pos)
		ent:SetAngles(AngleRand())
		if inv then
			ent:SetInventoryItemType(drop)
		else
			ent:SetWeaponType(drop)
		end
		ent:Spawn()
		if killer and killer:IsValidLivingHuman() then
			ent:SetOwner(killer)
		end
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:SetVelocityInstantaneous(VectorRand():GetNormalized() * math.Rand(24, 100))
			phys:AddAngleVelocity(VectorRand() * 200)
		end
	end
end
function meta:Make2BossDrop(killer)
	if math.random(1,3) == 1 then return end
	local drop = table.Random(bossdrops2)
	local inv = string.sub(drop, 1, 4) ~= "weap"
	local pos = self:LocalToWorld(self:OBBCenter())
	local ent = ents.Create(inv and "prop_invitem" or "prop_weapon")
	if ent:IsValid() then
		ent:SetPos(pos)
		ent:SetAngles(AngleRand())
		if inv then
			ent:SetInventoryItemType(drop)
		else
			ent:SetWeaponType(drop)
		end
		if killer and killer:IsValidLivingHuman() then
			ent:SetOwner(killer)
		end
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:SetVelocityInstantaneous(VectorRand():GetNormalized() * math.Rand(24, 100))
			phys:AddAngleVelocity(VectorRand() * 200)
		end
	end
end

function meta:UpdateAltSelectedWeapon()
	net.Start("zs_updatealtselwep")
	net.Send(self)
end

function meta:SendDeployableLostMessage(deployable)
	local deployableclass = deployable:GetClass()
	local deployableinfo = GAMEMODE.DeployableInfo[deployableclass]

	net.Start("zs_deployablelost")
		net.WriteString(deployableinfo.Name)
		net.WriteString(deployableinfo.WepClass)
	net.Send(self)
end

function meta:SendDeployableClaimedMessage(deployable)
	local deployableclass = deployable:GetClass()
	local deployableinfo = GAMEMODE.DeployableInfo[deployableclass]

	net.Start("zs_deployableclaim")
		net.WriteString(deployableinfo.Name)
		net.WriteString(deployableinfo.WepClass)
	net.Send(self)
end

function meta:SendDeployableOutOfAmmoMessage(deployable)
	local deployableclass = deployable:GetClass()
	local deployableinfo = GAMEMODE.DeployableInfo[deployableclass]

	net.Start("zs_deployableout")
		net.WriteString(deployableinfo.Name)
		net.WriteString(deployableinfo.WepClass)
	net.Send(self)
end

function meta:GetRandomStartingItem()
	local pool = {}

	if self:IsSkillActive(SKILL_EQUIPPED) then
		pool[#pool + 1] = GAMEMODE.StarterTrinkets[math.random(#GAMEMODE.StarterTrinkets)]
	end


	if #pool > 0 then
		return pool[math.random(#pool)]
	end

end
function meta:GetRandomFood()
	local pool = {}


	if self:IsSkillActive(SKILL_PREPAREDNESS) and #GAMEMODE.Food > 0 then
		pool[#pool + 1] = GAMEMODE.Food[math.random(#GAMEMODE.Food)]
	end
	if #pool > 0 then
		return pool[math.random(#pool)]
	end

end
function meta:GetRandomStartingItem1()
	local pool2 = {}
	if self:IsSkillActive(SKILL_SOULNET) then
		pool2[#pool2 + 1] = GAMEMODE.StarterSoul[math.random(#GAMEMODE.StarterSoul)]
	end


	if #pool2 > 0 then
		return pool2[math.random(#pool2)]
	end
	

end
function meta:GetRandomStartingItem2()
	local pool3 = {}

	if self:IsSkillActive(SKILL_CLASSIX1) then
		pool3[#pool3 + 1] = GAMEMODE.Via[math.random(#GAMEMODE.Via)]
	end
	if #pool3 > 0 then
		return pool3[math.random(#pool3)]
	end

end

local function FindZapperTarget(pos, attacker)
	local target
	local targethealth = 99999
	local isheadcrab

	for k, ent in pairs(ents.FindInSphere(pos, 210)) do
		if ent:IsValidLivingZombie() and not ent:GetZombieClassTable().NeverAlive then
			isheadcrab = ent:IsHeadcrab()
			if (isheadcrab or ent:Health() < targethealth) and TrueVisibleFilters(pos, ent:NearestPoint(pos), self, ent) then
				targethealth = ent:Health()
				target = ent

				if isheadcrab then
					break
				end
			end
		end
	end

	return target
end
local function DoCryoArc(attacker, inflictor, pl, damage)
	if pl:IsPlayer() and pl:IsValidLivingZombie() then
		local pos = pl:LocalToWorld(Vector(0, 0, 12))
		local target = FindZapperTarget(pos, attacker)

		local shocked = {}
		if target then
			local effectdata = EffectData()
				effectdata:SetOrigin(target:WorldSpaceCenter())
				effectdata:SetStart(pos)
				effectdata:SetEntity(attacker:GetActiveWeapon())
			util.Effect("tracer_c_laser", effectdata)

			shocked[target] = true
			for i = 1, 3 do
				local tpos = target:WorldSpaceCenter()

				for k, ent in pairs(ents.FindInSphere(tpos, 210)) do
					if not shocked[ent] and ent:IsValidLivingZombie() and not ent:GetZombieClassTable().NeverAlive then
						if WorldVisible(tpos, ent:NearestPoint(tpos)) then
							shocked[ent] = true
							target = ent

							timer.Simple(i * 0.15, function()
								if not ent:IsValid() or not ent:IsValidLivingZombie() or not WorldVisible(tpos, ent:NearestPoint(tpos)) then return end

								target:TakeDamage(damage*i, attacker, inflictor)
								target:AttachmentDamage(damage*i, attacker, inflictor, SLOWTYPE_COLD)

								local worldspace = ent:WorldSpaceCenter()
								effectdata = EffectData()
									effectdata:SetOrigin(worldspace)
									effectdata:SetStart(tpos)
									effectdata:SetEntity(target)
								util.Effect("tracer_c_laser", effectdata)
							end)

							break
						end
					end
				end
			end
		end
	end
end
function meta:PulseResonance(attacker, inflictor)
	-- Weird things happen with multishot weapons..

	timer.Create("PulseResonance" .. attacker:UniqueID(), 0.06, 1, function()
		if not attacker:IsValid() or not self:IsValid() then return end

		attacker:SetProgress(0,'pprog')


		local pos = self:WorldSpaceCenter()
		pos.z = pos.z + 16

		if attacker:IsValidLivingHuman() and !attacker:IsSkillActive(SKILL_CRYO_LASER) then
			util.BlastDamagePlayer(inflictor, attacker, pos, 85 + 25 * (attacker.ExpDamageRadiusMul or 1), 75, DMG_ALWAYSGIB, 0.7)
			for _, ent in pairs(util.BlastAlloc(inflictor, attacker, pos, 85 + 25 * (attacker.ExpDamageRadiusMul or 1))) do
				if ent:IsValidLivingPlayer() and gamemode.Call("PlayerShouldTakeDamage", ent, attacker) then
					ent:AddLegDamageExt(5, attacker, inflictor, SLOWTYPE_PULSE)
				end
			end
			local effectdata = EffectData()
			effectdata:SetOrigin(pos)
			effectdata:SetNormal(attacker:GetShootPos())
		util.Effect("explosion_shockcore", effectdata)
		elseif attacker:IsValidLivingHuman() and attacker:IsSkillActive(SKILL_CRYO_LASER) then
			DoCryoArc(attacker, inflictor, self, attacker:GetProgress('pprog') + 120)
		end

	end)
end

function meta:CryogenicInduction(attacker, inflictor, damage)
	local formula = (165 + (35 * ((attacker:GetActiveWeapon() and (attacker:GetActiveWeapon().Tier or 1))-1) * (attacker:GetActiveWeapon() and (attacker:GetActiveWeapon().Tier or 1)))) * (attacker:GetIndChance() or 1)
	if attacker:GetProgress('iprog') < formula then return end
	if self:GetZombieClassTable().Boss then return end

	timer.Create("Cryogenic" .. attacker:UniqueID(), 0.06, 1, function()
		if not attacker:IsValid() or not self:IsValid() then return end
		local pos = self:WorldSpaceCenter()
		pos.z = pos.z + 16
		self:TakeSpecialDamage(self:Health() * 0.2 + 165 + attacker:GetProgress('iprog'), DMG_DIRECT, attacker, inflictor, pos)
		attacker:SetProgress((attacker:GetProgress('iprog') -formula)*0.1,'iprog')

		if attacker:IsValidLivingHuman() then
			util.BlastDamagePlayer(inflictor, attacker, pos, 85 + 25 * (attacker.ExpDamageRadiusMul or 1), self:GetMaxHealthEx() * 0.2, DMG_DROWN, 0.83, true)
			for _, ent in pairs(util.BlastAlloc(inflictor, attacker, pos, 100)) do
				if ent:IsValidLivingPlayer() and gamemode.Call("PlayerShouldTakeDamage", ent, attacker) then
					ent:AddLegDamageExt(6, attacker, inflictor, SLOWTYPE_COLD)
				end
			end
		end

		local effectdata = EffectData()
			effectdata:SetOrigin(pos)
			effectdata:SetNormal(attacker:GetShootPos())
		util.Effect("hit_ice", effectdata)
	end)
end
function meta:FireInduction(attacker, inflictor, damage)
	if not self:GetZombieClassTable().Boss then
		if math.random(20 * (attacker:GetActiveWeapon().Tier or 1) * (attacker:GetActiveWeapon().Primary.Numshots or 1) ) == 2 or attacker:GetProgress('fprog') >= ((15 * ((attacker:GetActiveWeapon().Tier or 1)+1))) * (attacker:GetIndChance() or 1) then
			attacker:SetProgress(0,'fprog')
			timer.Create("Fire_inder" .. attacker:UniqueID(), 0.1, 2, function()
				if not attacker:IsValid() or not self:IsValid() then return end

				local pos = self:WorldSpaceCenter()
				pos.z = pos.z + 16

				self:TakeSpecialDamage((self:Health() * 0.5)/math.max(1,GAMEMODE:GetWave()-3) + damage + attacker:GetProgress("fprog"), DMG_DIRECT, attacker, inflictor, pos)

				if attacker:IsValidLivingHuman() then
					util.BlastDamagePlayer(inflictor, attacker, pos, 85 + 25 * (attacker.ExpDamageRadiusMul or 1), (self:Health() * 0.07) + damage, DMG_BURN, 0.83, true)
				end

				local effectdata = EffectData()
					effectdata:SetOrigin(pos)
					effectdata:SetNormal(attacker:GetShootPos())
				util.Effect("hit_fire", effectdata)
			end)
		end
	end
end
function meta:ChamStorm(attacker, inflictor, damage)
		if attacker:GetProgress('cprog') >= 350 then
			attacker:SetProgress(0,'cprog')
			timer.Create("CHAAAAAMOMILEEE_inder" .. attacker:UniqueID(), 0.1, 2, function()
				if not attacker:IsValid() or not self:IsValid() then return end

				local pos = self:WorldSpaceCenter()
				pos.z = pos.z + 16

				self:TakeSpecialDamage(self:Health() * 0.5 + damage, DMG_DIRECT, attacker, inflictor, pos)

				if attacker:IsValidLivingHuman() then
					util.BlastDamagePlayer(inflictor, attacker, pos, 85 + 25 * (attacker.ExpDamageRadiusMul or 1), (self:Health() * 0.17) + damage, DMG_BURN, 0.83, true)
				end

				local effectdata = EffectData()
					effectdata:SetOrigin(pos)
					effectdata:SetNormal(attacker:GetShootPos())
				util.Effect("hit_romashka", effectdata)
			end)
		end
end

function meta:SetPhantomHealth(amount)
	self:SetDTFloat(DT_PLAYER_FLOAT_PHANTOMHEALTH, amount)
end

function meta:HasBarricadeExpert()
	return self:GetZSRemortLevel() > 0
end

function meta:BarricadeExpertPrecedence(otherpl)
	local mygrade, myexpert = self:GetZSRemortLevelGraded(), self:HasBarricadeExpert()
	local othergrade, otherexpert = otherpl:GetZSRemortLevelGraded(), otherpl:HasBarricadeExpert()

	if (myexpert and not otherexpert) or mygrade > othergrade then
		return 1
	elseif (not myexpert and not otherexpert) or (myexpert and mygrade == othergrade) then
		return 0
	end

	return -1
end
