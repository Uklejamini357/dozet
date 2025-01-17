GM.VaultFolder = "zombiesurvival_vault"
GM.SkillTreeVersion = 1
GM.DozetSeason = 2
GM.OldSeason = 1

function GM:ShouldSaveVault(pl)
	-- Always push accumulated points in to the vault if we have any.
	if pl:IsBot() then return false end

	if self.PointSaving > 0 and pl.PointsVault ~= nil then
		return true
	end

	if pl:GetZSXP() > 0 or pl:GetZSSPUsed() > 0 or pl:GetZSRemortLevel() > 0 then
		return true
	end

	return false
end

function GM:ShouldLoadVault(pl)
	return not pl:IsBot()
end

--[[function GM:ShouldUseVault(pl)
	return not self.ZombieEscape and not self:IsClassicMode()
end]]

function GM:GetVaultFile(pl, xp)
	local steamid = pl:SteamID64() or "invalid"
	local d = ""
	if xp then
		d = "_ACH_XP"
	end

	return self.VaultFolder..d.."/"..steamid:sub(-2).."/"..steamid..d..".txt"
end

function GM:SaveAllVaults()
	for _, pl in pairs(player.GetAll()) do
		self:SaveVault(pl)
	end
end

function GM:InitializeVault(pl)
	pl.PointsVault = 0
	pl:SetZSXP(0)
end

function GM:LoadVault(pl)
	if not self:ShouldLoadVault(pl) then return end

	local filename = self:GetVaultFile(pl)
	if file.Exists(filename, "DATA") then
		local contents = file.Read(filename, "DATA")
		if contents and #contents > 0 then
			contents = Deserialize(contents)
			if contents then
				pl.PointsVault = contents.Points
				local remort = contents.RemortLevel
				if contents.RemortLevel then
					pl:SetZSRemortLevel(remort)
				end
				if contents.XP then
					pl:SetZSXP(contents.XP)
				end
				if contents.UnlockedSkills then
					pl:SetUnlockedSkills(util.DecompressBitTable(contents.UnlockedSkills), true)
				end
				if contents.DesiredActiveSkills then
					pl:SetDesiredActiveSkills(util.DecompressBitTable(contents.DesiredActiveSkills), true)
				end
				if contents.NextSkillReset then
					pl.NextSkillReset = contents.NextSkillReset
				end
				if not contents.Version or contents.Version < self.SkillTreeVersion then
					pl:SkillsReset()
					pl.SkillsRefunded = true
				end
				if contents.UpgradableSkills then
					pl:SetUpgradeSkills(util.DecompressBitTable(contents.UpgradableSkills), true)
				end
				if contents.MeleeMastery then
					pl.MeleeMastery = contents.MeleeMastery
				end
				if contents.GunMastery then
					pl.GunMastery = contents.GunMastery
				end
				if contents.MedicMastery then
					pl.MedicMastery = contents.MedicMastery
				end
				if contents.Zban then
					pl.Zban = contents.Zban
				end
				if contents.AchXP then
					pl:SetDCoins(contents.AchXP)
				end
				pl.Season = (contents.Season or 1)

				pl.SkillVersion = self.SkillTreeVersion
			end
		end
	end
	local filename = self:GetVaultFile(pl, true)
	if file.Exists(filename, "DATA") then
		local contents = file.Read(filename, "DATA")
		if contents and #contents > 0 then
			contents = Deserialize(contents)
			if contents then
				if contents.AchXP then
					pl:SetDCoins(contents.AchXP)
				end
				pl.SkillVersion = self.SkillTreeVersion
			end
		end
	end

	pl.PointsVault = pl.PointsVault or 0
end

function GM:PlayerReadyVault(pl)
	local unlocked = pl:GetUnlockedSkills()
	local desired = pl:GetDesiredActiveSkills()
	local active = pl:GetActiveSkills()

	net.Start("zs_skills_init")
	self:WriteSkillBits(unlocked)
	self:WriteSkillBits(desired)

	-- Send this if any key exists.
	for k in pairs(active) do
		net.WriteBool(true)
		self:WriteSkillBits(active)
		net.Send(pl)

		return
	end

	net.WriteBool(false)
	net.Send(pl)

	if pl.NextSkillReset then
		local time = os.time()
		if time < pl.NextSkillReset then
			net.Start("zs_skills_nextreset")
			net.WriteUInt(pl.NextSkillReset - time, 32)
			net.Send(pl)
		end
	end
end

function GM:SaveVault(pl)
	if not self:ShouldSaveVault(pl) then return end
	local remort =pl:GetZSRemortLevel()
	if self.DozetSeason ~= (pl.Season or 1) then
		remort = remort/3
		if remort <= 2 then
			remort = 0
		end
	end
	local tosave = {
		Points = math.floor(pl.PointsVault),
		XP = pl:GetZSXP(),
		RemortLevel = remort,
		DesiredActiveSkills = util.CompressBitTable(pl:GetDesiredActiveSkills()),
		UnlockedSkills = util.CompressBitTable(pl:GetUnlockedSkills()),
		Version = pl.SkillVersion or self.SkillTreeVersion,
		MedicMastery = pl.MedicMastery,
		MeleeMastery = pl.MeleeMastery,
		GunMastery = pl.GunMastery,
		Zban = (pl.Zban or false),
		AchXP = pl:GetDCoins(),
		Season = self.DozetSeason
	}
	local tosavexp = {
		AchXP = pl:GetDCoins()
	}

	if pl.NextSkillReset and os.time() < pl.NextSkillReset then
		tosave.NextSkillReset = pl.NextSkillReset
	end

	if tosave.Points and self.PointSavingLimit > 0 and tosave.Points > self.PointSavingLimit then
		tosave.Points = self.PointSavingLimit
	end

	local filename = self:GetVaultFile(pl)
	local filenamexp = self:GetVaultFile(pl,true)
	file.CreateDir(string.GetPathFromFilename(filename))
	file.Write(filename, Serialize(tosave))

	file.CreateDir(string.GetPathFromFilename(filenamexp))
	file.Write(filenamexp, Serialize(tosavexp))
end
local num = 1

function GM:SaveWinRate()
	local DaData = self.Da
	local tosave = {
		Winrate = math.floor(self:GetWinRate() or 0),
		ZSRage = math.floor(self:GetRage() or 0),
		Da = (#DaData <= 1200 and DaData or {"mmm", "what", "yes", "ммм", "да", "что", "obed", "обед", "уютненько", "Я", "I", "you", "ты", "амням", "санбой", "пророк"}),
		DailySecs = math.floor(self.DailySecs or os.time() +86400),
		DailyNum = math.floor(self.DailyNum or 1),
		LastDaily = (self.LastDaily or 1)
	}
	num = math.max(1,(self.DailyNum or 1)%7)
	if self.DailySecs and os.time() > self.DailySecs then
		tosave.LastDaily = num
		tosave.DailyNum = math.floor(self.DailyNum or 1) + 1
		tosave.DailySecs = os.time() + 86400
	end

	local filename = "system_balance.txt"
	file.CreateDir(string.GetPathFromFilename(filename))
	file.Write(filename, Serialize(tosave))
end
function GM:LoadWinRate()

	local filename = "system_balance.txt"
	if file.Exists(filename, "DATA") then
		local contents = file.Read(filename, "DATA")
		if contents and #contents > 0 then
			contents = Deserialize(contents)
			if contents then
				if contents.Winrate then
					self:SetWinRate(contents.Winrate or 1)
				end
				if contents.ZSRage then
					self:SetRage(contents.ZSRage or 1)
				end
				if contents.Da then
					self.Da = contents.Da or {"mmm"}
				end
				if contents.DailySecs then
					self.DailySecs = contents.DailySecs or 0
				end
				if contents.LastDaily then
					self.LastDaily = contents.LastDaily or 1
					self:SetLDaily(contents.LastDaily or 1)
				end
				if contents.DailyNum then
					self.DailyNum = contents.DailyNum or 1
					SetGlobalInt("dailynum", self.DailyNum)
				end
				
			end
		end
	end
end
