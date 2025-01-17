INC_CLIENT()

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
local matBeam = Material("Effects/laser1", "smooth")
function ENT:Initialize()
	self:DrawShadow(false)
	self:SetRenderFX(kRenderFxDistort)

	self:SetRenderBounds(Vector(-128, -128, -128), Vector(128, 128, 200))

	self:SetModelScaleVector(Vector(1, 1, 1) * self.ModelScale)

	self.AmbientSound = CreateSound(self, "ambient/atmosphere/tunnel1.wav")
end

function ENT:Think()
	if EyePos():DistToSqr(self:GetPos()) <= 4900000 then -- 700^2
		self.AmbientSound:PlayEx(0.33, 75 + (self:GetSigilHealth() / self:GetSigilMaxHealth()) * 25)
	else
		self.AmbientSound:Stop()
	end
end

function ENT:OnRemove()
	self.AmbientSound:Stop()
end

ENT.NextEmit = 0
ENT.Rotation = math.random(360)

local matWhite = Material("models/debug/debugwhite")
local matGlow = Material("sprites/light_glow02_add")

local cDrawWhite = Color(0, 255, 255)
local cDraw = Color(125, 0, 0)

local math_sin = math.sin
local math_cos = math.cos
local math_abs = math.abs
local cam_Start3D = cam.Start3D
local cam_End3D = cam.End3D
local render_SetBlend = render.SetBlend
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_SetColorModulation = render.SetColorModulation
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_DrawQuadEasy = render.DrawQuadEasy
local render_DrawSprite = render.DrawSprite

function ENT:DrawTranslucent()
        local distance = MySelf:GetPos():Distance( self:GetPos() )
        local alpha = 255
        local at = self:GetPos():ToScreen()


        local ang = Angle( 0, 0, 0 )
        local up = Vector( 0, 0, 1 )
        local ringpos = self:GetPos()
        local frametime = FrameTime() * 500
        local ringsize = math.Clamp(948 / (GAMEMODE:GetWave() * 0.33),163,948)

        render.SetMaterial( matBeam )
        render.StartBeam( 20 )
        for i=1, 20 do
            render.AddBeam( ringpos + ang:Forward() * ringsize, 10, 10, Color( 255, 154, 154) )
            ang:RotateAroundAxis( up, 20 )
        end
            
        render.EndBeam()
	self:RemoveAllDecals()

	local scale = self.ModelScale

	local curtime = CurTime()
	local sat = math_abs(math_sin(curtime))
	local colsat = sat * 0.125
	local eyepos = EyePos()
	local eyeangles = EyeAngles()
	local forwardoffset = 16 * scale * self:GetForward()
	local rightoffset = 16 * scale * self:GetRight()
	local healthperc = self:GetSigilHealth() / self:GetSigilMaxHealth()
	local radius = (180 + math_cos(sat) * 40) * scale
	local whiteradius = (122 + math_sin(sat) * 32) * scale
	local up = self:GetUp()
	local spritepos = self:GetPos() + up
	local spritepos2 = self:WorldSpaceCenter()
	local corrupt = self:GetSigilCorrupted()
	local r, g, b
	if corrupt then
		r = colsat
		g = 0.3
		b = colsat
	else
		r = 0.20 + colsat
		g = 0 + colsat
		b = 0.2
	end

	r = r * healthperc
	g = g * healthperc
	b = b * healthperc
	render_SuppressEngineLighting(true)
	render_SetColorModulation(r ^ 0.5, g ^ 0.5, b ^ 0.5)

	self:SetModelScaleVector(Vector(1, 1, 1) * scale)

	self:DrawModel()

	render_SetColorModulation(r, g, b)

	render_ModelMaterialOverride(matWhite)
	render_SetBlend(0.1 * healthperc)

	self:DrawModel()

	render_SetColorModulation(r, g, b)

	self:SetModelScaleVector(Vector(0.1, 0.1, 0.9 * math.max(0.02, healthperc)) * scale)
	render_SetBlend(1)
	cam_Start3D(eyepos + forwardoffset + rightoffset, eyeangles)
	self:DrawModel()
	cam_End3D()
	cam_Start3D(eyepos + forwardoffset - rightoffset, eyeangles)
	self:DrawModel()
	cam_End3D()
	cam_Start3D(eyepos - forwardoffset + rightoffset, eyeangles)
	self:DrawModel()
	cam_End3D()
	cam_Start3D(eyepos - forwardoffset - rightoffset, eyeangles)
	self:DrawModel()
	cam_End3D()
	self:SetModelScaleVector(Vector(1, 1, 1) * scale)

	render_SetBlend(1)
	render_ModelMaterialOverride()
	render_SuppressEngineLighting(false)
	render_SetColorModulation(1, 1, 1)

	self.Rotation = self.Rotation + FrameTime() * 5
	if self.Rotation >= 360 then
		self.Rotation = self.Rotation - 360
	end

	cDraw.r = r * 255
	cDraw.g = g * 255
	cDraw.b = b * 255
	cDrawWhite.r = healthperc * 255
	cDrawWhite.g = cDrawWhite.r
	cDrawWhite.b = cDrawWhite.r

	render.SetMaterial(matGlow)
	if not corrupt then
		render_DrawQuadEasy(spritepos, up, whiteradius, whiteradius, cDrawWhite, self.Rotation)
		render_DrawQuadEasy(spritepos, up * -1, whiteradius, whiteradius, cDrawWhite, self.Rotation)
	end
	render_DrawQuadEasy(spritepos, up, radius, radius, cDraw, self.Rotation)
	render_DrawQuadEasy(spritepos, up * -1, radius, radius, cDraw, self.Rotation)
	render_DrawSprite(spritepos2, radius, radius * 2, cDraw)

	if curtime < self.NextEmit then return end
	self.NextEmit = curtime + 0.05

	local offset = VectorRand()
	offset.z = 0
	offset:Normalize()
	offset = math.Rand(-32, 32) * scale * offset
	offset.z = 1
	local pos = self:LocalToWorld(offset)

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(24, 32)

	local particle = emitter:Add(corrupt and "particle/smokesprites_0001" or "sprites/glow04_noz", pos)
	particle:SetDieTime(math.Rand(1.5, 4))
	particle:SetVelocity(Vector(0, 0, math.Rand(32, 64) * scale))
	particle:SetStartAlpha(0)
	particle:SetEndAlpha(255)
	particle:SetStartSize(math.Rand(2, 4) * (corrupt and 3 or 1) * scale)
	particle:SetEndSize(0)
	particle:SetRoll(math.Rand(0, 360))
	particle:SetRollDelta(math.Rand(-1, 1))
	particle:SetColor(r * 255, g * 255, b * 255)
	particle:SetCollide(true)

	emitter:Finish() emitter = nil collectgarbage("step", 64)
	
end
