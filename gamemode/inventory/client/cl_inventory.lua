GM.ZSInventory = {}

INVCAT_TRINKETS = 1
INVCAT_COMPONENTS = 2
INVCAT_CONSUMABLES = 3
INVCAT_WEAPONS = 4

local meta = FindMetaTable("Player")
function meta:GetInventoryItems()
	return GAMEMODE.ZSInventory
end

function meta:HasInventoryItem(item)
	return GAMEMODE.ZSInventory[item] and GAMEMODE.ZSInventory[item] > 0
end

net.Receive("zs_inventoryitem", function()
	local item = net.ReadString()
	local count = net.ReadInt(5)
	local prevcount = GAMEMODE.ZSInventory[item] or 0

	GAMEMODE.ZSInventory[item] = count

	if GAMEMODE.InventoryMenu and GAMEMODE.InventoryMenu:IsValid() then
		if count > prevcount then
			GAMEMODE:InventoryAddGridItem(item, GAMEMODE:GetInventoryItemType(item))
		else
			GAMEMODE:InventoryRemoveGridItem(item)
		end
	end

	if MySelf and MySelf:IsValid() then
		MySelf:ApplyTrinkets()
	end
end)
net.Receive("zs_upgradeitem", function()
	local item = net.ReadString()
	local count = net.ReadInt(5)
	local prevcount = GAMEMODE.ZSInventory[item] or 0

	GAMEMODE.ZSInventory[item] = count

	if GAMEMODE.InventoryMenu and GAMEMODE.InventoryMenu:IsValid() then
		if count > prevcount then
			GAMEMODE:InventoryAddGridItem(item, GAMEMODE:GetInventoryItemType(item))
		else
			GAMEMODE:InventoryRemoveGridItem(item)
		end
	end

	if MySelf and MySelf:IsValid() then
		MySelf:ApplyTrinkets()
	end
end)


net.Receive("zs_wipeinventory", function()
	GAMEMODE.ZSInventory = {}

	if GAMEMODE.InventoryMenu and GAMEMODE.InventoryMenu:IsValid() then
		GAMEMODE:InventoryWipeGrid()
	end

	MySelf:ApplyTrinkets()
end)

local function TryCraftWithComponent(me)
	net.Start("zs_trycraft")
		net.WriteString(me.Item)
		net.WriteString(me.WeaponCraft)
	net.SendToServer()
end
local function TryGetItemWithComponent(me)
	net.Start("zs_trygetitem")
		net.WriteString(me.Item)
	net.SendToServer()
end

local function ItemPanelDoClick(self)
	local item = self.Item
	if not item then return end

	local viewer = GAMEMODE.InventoryMenu.Viewer
	local shoptbl
	local category, sweptable = self.Category
	if category == INVCAT_WEAPONS then
		sweptable = weapons.Get( item )
	else
		sweptable = GAMEMODE.ZSInventoryItemData[ item ]
	end

	local screenscale = BetterScreenScale()

	if self.On then
		self.On = false

		GAMEMODE.InventoryMenu.SelInv = false
		GAMEMODE.InventoryMenu.Category = false
		GAMEMODE:DoAltSelectedItemUpdate()
		return
	else
		for _, v in pairs( self:GetParent():GetChildren() ) do
			v.On = false
		end
		self.On = true

		GAMEMODE.InventoryMenu.SelInv = item
		GAMEMODE.InventoryMenu.Category = category

		GAMEMODE:DoAltSelectedItemUpdate()
	end

	for i = 1, 3 do
		local crab, cral = viewer.m_CraftBtns[ i ][ 1 ], viewer.m_CraftBtns[ i ][ 2 ]

		crab:SetVisible( false )
		cral:SetVisible( false )
	end

	local assembles = {}
	for k,v in pairs( GAMEMODE.Assemblies ) do
		if v[1] == item then
			assembles[ v[ 2 ] ] = k
		end
	end

	local count = 0
	for k,v in pairs( assembles ) do
		count = count + 1

		local crab, cral = viewer.m_CraftBtns[ count ][ 1 ], viewer.m_CraftBtns[ count ][ 2 ]
		local iitype = GAMEMODE:GetInventoryItemType( k ) ~= -1

		crab.Item = item
		crab.WeaponCraft = k
		crab.DoClick = TryCraftWithComponent
		crab:SetPos( viewer:GetWide() / 2 - crab:GetWide() / 2, ( viewer:GetTall() - 33 * screenscale ) - ( count - 1 ) * 33 * screenscale )
		crab:SetVisible( true )

		cral:SetText( ( iitype and GAMEMODE.ZSInventoryItemData[ k ] or weapons.Get( k ) ).PrintName )
		cral:SetPos( crab:GetWide() / 2 - cral:GetWide() / 2, ( crab:GetTall() * 0.5 - cral:GetTall() * 0.5 ) )
		cral:SetContentAlignment( 5 )
		cral:SetVisible( true )
	end



	if count > 0 then
		viewer.m_CraftWith:SetPos( viewer:GetWide() / 2 - viewer.m_CraftWith:GetWide() / 2, ( viewer:GetTall() - 33 * screenscale ) - 33 * count * screenscale )
		viewer.m_CraftWith:SetContentAlignment( 5 )
		viewer.m_CraftWith:SetVisible( true )
	else
		viewer.m_CraftWith:SetVisible( false )
	end


	GAMEMODE:SupplyItemViewerDetail( viewer, sweptable, { SWEP = self.Item } )
end

local categorycolors = {
	[ INVCAT_TRINKETS ] = { COLOR_RED, COLOR_DARKRED },
	[ INVCAT_COMPONENTS ] = { COLOR_BLUE, COLOR_DARKBLUE },
	[ INVCAT_CONSUMABLES ] = { COLOR_YELLOW, COLOR_DARKYELLOW }
}
local colBG = Color( 10, 10, 10, 252 )
local colBGH = Color( 200, 200, 200, 5 )
local blur = Material( "pp/blurscreen" )
local function TrinketPanelPaint( self, w, h )
	if categorycolors[ self.Category ] then
		draw.RoundedBox( 2, 0, 0, w, h, ( self.Depressed or self.On ) and categorycolors[ self.Category ][ 1 ] or categorycolors[ self.Category ][ 2 ]  )
	end
	
	draw.RoundedBox( 2, 2, 2, w - 4, h - 4, colBG )
	
	if self.On or self.Hovered then
		draw.RoundedBox( 2, 2, 2, w - 4, h - 4, colBGH )
	end

	if self.SWEP then
		draw.SimpleText( self.SWEP.PrintName, "ZSHUDFontTiny", w/2, h/2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )	
	end

	return true
end

function GM:CreateInventoryElements()
	local screenscale = BetterScreenScale()
	local viewer = self.InventoryMenu.Viewer 

	local craftbtns = {}
	for i = 1, 3 do
		local craftb = vgui.Create( "DButton", viewer )
		craftb:SetText( "" )
		craftb:SetSize( viewer:GetWide() / 1.15, 27 * screenscale )
		craftb:SetVisible(false)

		local namelab = EasyLabel( craftb, "...", "ZSBodyTextFont", COLOR_WHITE )
		namelab:SetWide( craftb:GetWide() )
		namelab:SetVisible( false )

		craftbtns[i] = { craftb, namelab }
	end
	local itembtns = {}
	for i = 1, 3 do
		local craftb = vgui.Create( "DButton", viewer )
		craftb:SetText( "" )
		craftb:SetSize( viewer:GetWide() / 1.15, 27 * screenscale )
		craftb:SetVisible(false)

		local namelab = EasyLabel( craftb, "...", "ZSBodyTextFont", COLOR_WHITE )
		namelab:SetWide( craftb:GetWide() )
		namelab:SetVisible( false )

		itembtns[i] = { craftb, namelab }
	end
	viewer.m_CraftBtns = craftbtns
	viewer.m_ItemBtns = itembtns

	local craftwith = EasyLabel( viewer, "Craft With...", "ZSBodyTextFontBig", COLOR_WHITE )
	craftwith:SetSize( viewer:GetWide() / 1.15, 27 * screenscale )
	craftwith:SetVisible( false )
	viewer.m_CraftWith = craftwith
	local itemwith = EasyLabel( viewer, "Get item...", "ZSBodyTextFontBig", COLOR_WHITE )
	itemwith:SetSize( viewer:GetWide() / 1.15, 27 * screenscale )
	itemwith:SetVisible( false )
	viewer.m_ItemWith = itemwith
end

function GM:InventoryAddGridItem( item, category )
	local screenscale = BetterScreenScale()
	local grid = self.InventoryMenu.Grids[ self:GetInventoryItemType( item ) ]
	local types = nodes

	if grid and grid:IsValid() then
		local itempan = vgui.Create("DButton")
		itempan:SetText( "" )
		itempan.Paint = TrinketPanelPaint

		itempan.Item = item
		itempan.SWEP = self.ZSInventoryItemData[ item ]
		itempan.DoClick = ItemPanelDoClick
		itempan.Category = category

		grid:AddItem( itempan )
		grid:SortByMember( "Category" )

		local mdlframe = vgui.Create("DPanel", itempan)
		mdlframe:SetSize( (category ~= INVCAT_TRINKETS and (125 * screenscale) or (35 * screenscale)), 35 * screenscale )
		mdlframe:Center()
		mdlframe:SetPos((category ~= INVCAT_TRINKETS and (25 * screenscale) or (70 * screenscale)),screenscale)
		mdlframe:SetMouseInputEnabled( false )
		mdlframe.Paint = function() end

		local trintier = EasyLabel( itempan, "", "ZSHUDFontSmaller", COLOR_WHITE )
		trintier:CenterHorizontal( 0.8 )
		trintier:CenterVertical( 0.8 )


		local icon = GAMEMODE.ZSInventoryItemData[item].Icon or "weapon_zs_trinket"
		local kitbl = killicon.Get(category == INVCAT_TRINKETS and icon or "weapon_zs_craftables")
		if kitbl then
			self:AttachKillicon(kitbl, itempan, mdlframe)
		end
	end
end

function GM:InventoryRemoveGridItem( item )
	for i, grid in pairs( self.InventoryMenu.Grids ) do
		for k, v in pairs( grid:GetChildren() ) do
			if v.Item == item then
				grid:RemoveItem( v )
				break
			end
		end

		grid:SortByMember( "Name" )
	end

	if self.InventoryMenu.SelInv == item then
		if self.m_InvViewer and self.m_InvViewer:IsValid() and self.InventoryMenu.SelInv then
			self.m_InvViewer:SetVisible( false )
		end

		self.InventoryMenu.SelInv = nil
		self:DoAltSelectedItemUpdate()
	end
end

function GM:InventoryWipeGrid()
	for i, grid in pairs( self.InventoryMenu.Grids ) do
		for k, v in pairs( grid:GetChildren() ) do
			grid:RemoveItem( v )
		end
	end

	if self.m_InvViewer and self.m_InvViewer:IsValid() then
		self.m_InvViewer:SetVisible( false )
	end

	self.InventoryMenu.SelInv = nil
	self:DoAltSelectedItemUpdate()
end

local NextRefresh = 0
local RefreshTime = 0.1
function GM:OpenInventory()
	if self.InventoryMenu and self.InventoryMenu:IsValid() then
		self.InventoryMenu:SetVisible( true )

		if self.Inv_NearestFrame and self.Inv_NearestFrame:IsValid() then
			self.Inv_NearestFrame:SetVisible( true )
		end

		if self.m_InvViewer and self.m_InvViewer:IsValid() and self.InventoryMenu.SelInv then
			self.m_InvViewer:SetVisible( true )
		end
		
		return
	end

	local screenscale = BetterScreenScale()
	local w, h = 700 * screenscale, 700 * screenscale

	local frame = vgui.Create( "DFrame" )
	frame:SetSize( w, h )
	frame:Center()
	frame:SetTitle( "" )
	frame.Grids = {}

	self.InventoryMenu = frame

	if frame.btnClose and frame.btnClose:IsValid() then frame.btnClose:SetVisible( false ) end
	if frame.btnMinim and frame.btnMinim:IsValid() then frame.btnMinim:SetVisible( false ) end
	if frame.btnMaxim and frame.btnMaxim:IsValid() then frame.btnMaxim:SetVisible( false ) end
	local quickstats = {}
--[[	for i=1,4 do
		local hpstat = vgui.Create("DLabel", bottomleftup)
		hpstat:SetFont("ZSHUDFontTiny")
		hpstat:SetTextColor(COLOR_WHITE)
		hpstat:SetContentAlignment(8)
		hpstat:Dock(TOP)
		hpstat:SizeToContents()
		hpstat:SetText("---")
		table.insert(quickstats, hpstat)
	end]]
	self.QuickStats = quickstats
	local topspace = vgui.Create( "DPanel", frame )
	topspace:Dock( TOP )
	topspace:DockMargin( 4 * screenscale, 4 * screenscale, 4 * screenscale, 4 * screenscale )
	topspace:SetTall( 40 * screenscale )
	topspace:SetMouseInputEnabled( false )

	local bottomspace = vgui.Create( "DPanel", frame )
	bottomspace:Dock( BOTTOM )
	bottomspace:DockMargin( 4 * screenscale, 4 * screenscale, 4 * screenscale, 4 * screenscale )
	bottomspace:SetTall( 20 * screenscale )

	local title = EasyLabel( topspace, translate.Get( "inv_title" ), "ZSHUDFontSmall", COLOR_WHITE )
	title:Dock( FILL )
	title:SetContentAlignment( 5 )
	
	--local stats = EasyLabel( frame, "Some", "ZSHUDFontSmall", Color(221,70,70) )
	--stats:SetContentAlignment( 0 )

	local invprop = vgui.Create( "DPropertySheet", frame )
	invprop:Dock( FILL )
	invprop:SetWide( frame:GetWide() - 320 * screenscale )
	invprop:DockMargin( 2 * screenscale, 2 * screenscale, 2 * screenscale, 2 * screenscale )
	
	for i, con in pairs( self.ZSInventoryCategories ) do
		local itemframe = vgui.Create( "DScrollPanel", invprop )
		itemframe:Dock( FILL )
		itemframe:DockMargin( 4 * screenscale, 4 * screenscale, 4 * screenscale, 4 * screenscale )

		local invgrid = vgui.Create( "DGrid", itemframe )
		invgrid:Dock( FILL )
		invgrid:DockMargin( 2 * screenscale, 2 * screenscale, 2 * screenscale, 2 * screenscale )
		invgrid:SetCols( 2 )
		invgrid:SetColWide( 179 * screenscale )
		invgrid:SetRowHeight( 74 * screenscale )
		invgrid.Think = function( sf )
			for i, item in pairs( sf:GetItems() ) do
				if item and item:IsValid() and not item.Grided then
					item:SetWide( sf:GetColWide() - 4 * screenscale )
					item:SetTall( sf:GetRowHeight() - 4 * screenscale )
					item.Grided = true
				end
			end
		end

		itemframe.Grid = invgrid

		self.InventoryMenu.Grids[ i ] = invgrid

		invprop:AddSheet( con, itemframe )
	end

	self.InventoryMenu.Grid = invprop:GetActiveTab():GetPanel().Grid

	local scroller = invprop:GetChildren()[ 1 ]
	local dragbase = scroller:GetChildren()[ 1 ]
	local tabs = dragbase:GetChildren()
	
	self:ConfigureMenuTabs( tabs, 32 * screenscale, function( tab )
		self.InventoryMenu.Grid = tab:GetPanel().Grid
	end )

	for item, count in pairs( self.ZSInventory ) do
		if count > 0 then
			for i = 1, count do
				self:InventoryAddGridItem( item, self:GetInventoryItemType( item ) )
			end
		end
	end

	self:CreateItemInfoViewer( frame, invprop, topspace, bottomspace )
	self:CreateInventoryElements()
	--self:UpdateQuickStatsInventory()
end
function GM:UpdateQuickStatsInventory()
	local skillmodifiers = {}
	local gm_modifiers = GAMEMODE.SkillModifiers
	for skillid in pairs(table.ToAssoc(MySelf:GetInventoryItems())) do
		local modifiers = gm_modifiers[skillid]
		if modifiers then
			for modid, amount in pairs(modifiers) do
				skillmodifiers[modid] = (skillmodifiers[modid] or 0) + amount
			end
		end
	end

	for i=1,4 do
		local prefix = i == 1 and translate.Get("skill_add_health") or i == 2 and translate.Get("skill_add_speed") or i == 4 and translate.Get("skill_add_bloodarmor") or translate.Get("skill_add_worth")
		local val = i == 2 and SPEED_NORMAL or i == 1 and 100 or i == 4 and 25 or 135
		self.QuickStats[i]:SetText(prefix .. " : " .. (val + (skillmodifiers[i] or 0)))
	end
end