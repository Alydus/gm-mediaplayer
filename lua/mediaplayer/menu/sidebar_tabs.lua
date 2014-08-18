local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.TabHeight = 43

function PANEL:Init()

	self:SetShowIcons( false )

	self:SetFadeTime( 0 )
	self:SetPadding( 0 )

	self.animFade = Derma_Anim( "Fade", self, self.CrossFade )

	self.Items = {}

end

function PANEL:Paint( w, h )

end

function PANEL:AddSheet( label, panel, material, NoStretchX, NoStretchY, Tooltip )

	if not IsValid( panel ) then return end

	local Sheet = {}

	Sheet.Name = label

	Sheet.Tab = vgui.Create( "MP.SidebarTab", self )
	Sheet.Tab:SetTooltip( Tooltip )
	Sheet.Tab:Setup( label, self, panel, material )

	Sheet.Panel = panel
	Sheet.Panel.NoStretchX = NoStretchX
	Sheet.Panel.NoStretchY = NoStretchY
	Sheet.Panel:SetPos( self:GetPadding(), self.TabHeight + self:GetPadding() )
	Sheet.Panel:SetVisible( false )

	panel:SetParent( self )

	table.insert( self.Items, Sheet )

	if not self:GetActiveTab() then
		self:SetActiveTab( Sheet.Tab )
		Sheet.Panel:SetVisible( true )
	end

	-- self.tabScroller:AddPanel( Sheet.Tab )

	return Sheet

end

function PANEL:PerformLayout()

	local ActiveTab = self:GetActiveTab()
	local Padding = self:GetPadding()

	if not ActiveTab then return end

	-- Update size now, so the height is definitiely right.
	ActiveTab:InvalidateLayout( true )

	local ActivePanel = ActiveTab:GetPanel()

	local numItems = #self.Items
	local tabWidth = ceil(self:GetWide() / numItems)

	local tab

	for k, v in pairs( self.Items ) do

		tab = v.Tab

		tab:SetSize( tabWidth, self.TabHeight )
		tab:SetPos( (k-1) * tabWidth )

		-- Handle tab panel visibility
		if tab:GetPanel() == ActivePanel then
			tab:GetPanel():SetVisible( true )
			tab:SetZPos( 100 )
		else
			tab:GetPanel():SetVisible( false )
			tab:SetZPos( 1 )
		end

		tab:ApplySchemeSettings()

	end

	ActivePanel:SetWide( self:GetWide() - Padding * 2 )
	ActivePanel:SetTall( (self:GetTall() - ActiveTab:GetTall() ) - Padding )

	ActivePanel:InvalidateLayout()

	-- Give the animation a chance
	self.animFade:Run()

end

derma.DefineControl( "MP.SidebarTabs", "", PANEL, "DPropertySheet" )


local SIDEBAR_TAB = {}

surface.CreateFont( "MP.TabTitle", {
	font = "Roboto Regular",
	size = 16,
	weight = 400
} )

SIDEBAR_TAB.BgColor = Color( 28, 100, 157 )
SIDEBAR_TAB.SelectedBorderColor = color_white
SIDEBAR_TAB.SelectedBorderHeight = 2

function SIDEBAR_TAB:Init()

	self.BaseClass.Init( self )

	self:SetFont( "MP.TabTitle" )
	self:SetContentAlignment( 5 )
	self:SetTextInset( 0, 0 )

end

function SIDEBAR_TAB:Paint( w, h )

	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h )

	if self:IsActive() then
		surface.SetDrawColor( self.SelectedBorderColor )
		surface.DrawRect( 0, h - self.SelectedBorderHeight, w, self.SelectedBorderHeight )
	end

end

function SIDEBAR_TAB:ApplySchemeSettings()

	self:SetTextInset( 0, 0 )

	DLabel.ApplySchemeSettings( self )

end

derma.DefineControl( "MP.SidebarTab", "", SIDEBAR_TAB, "DTab" )



local CURRENTLY_PLAYING_TAB = {}

AccessorFunc( CURRENTLY_PLAYING_TAB, "MediaPlayerId", "MediaPlayerId" )

function CURRENTLY_PLAYING_TAB:Init()

	self.PlaybackPanel = vgui.Create( "MP.Playback", self )
	self.PlaybackPanel:Dock( TOP )

	self.QueuePanel = vgui.Create( "MP.Queue", self )
	self.QueuePanel:Dock( FILL )

	hook.Add( MP.EVENTS.UI.MEDIA_PLAYER_CHANGED, self, self.OnMediaPlayerChanged )

end

function CURRENTLY_PLAYING_TAB:OnMediaPlayerChanged( mp )

	self:SetMediaPlayerId( mp:GetId() )

	if not self.MediaChangedHandle then
		-- set current media
		self.PlaybackPanel:OnMediaChanged( mp:GetMedia() )

		-- listen for any future media changes
		self.MediaChangedHandle = function(...) self.PlaybackPanel:OnMediaChanged(...) end
		mp:on( MP.EVENTS.MEDIA_CHANGED, self.MediaChangedHandle )
	end

	if not self.QueueChangedHandle then
		-- set current queue
		self.QueuePanel:OnQueueChanged( mp:GetMediaQueue() )

		-- listen for any future media changes
		self.QueueChangedHandle = function(...) self.QueuePanel:OnQueueChanged(...) end
		mp:on( MP.EVENTS.QUEUE_CHANGED, self.QueueChangedHandle )
	end

end

function CURRENTLY_PLAYING_TAB:OnRemove()

	hook.Remove( MP.EVENTS.UI.MEDIA_PLAYER_CHANGED, self )

	local mpId = self:GetMediaPlayerId()
	local mp = MediaPlayer.GetById( mpId )

	if mp then
		mp:removeListener( MP.EVENTS.MEDIA_CHANGED, self.MediaChangedHandle )
		mp:removeListener( MP.EVENTS.QUEUE_CHANGED, self.QueueChangedHandle )
	end

end

derma.DefineControl( "MP.CurrentlyPlayingTab", "", CURRENTLY_PLAYING_TAB, "Panel" )