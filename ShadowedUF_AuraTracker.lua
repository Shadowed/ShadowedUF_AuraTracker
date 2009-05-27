local ShadowUF = ShadowUF
local AuraTracker = {}
ShadowUF:RegisterModule(AuraTracker, "AuraTracker", "AuraTracker")

function AuraTracker:OnInitialize()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(self, event, addon)
		if( IsAddOnLoaded("ShadowedUF_AuraTracker") ) then
			self:UnregisterEvent("ADDON_LOADED")
			for _, unit in pairs(ShadowUF.units) do
				if ( ShadowUF.db.profile.units[unit].AuraTracker == nil ) then
					ShadowUF.db.profile.units[unit].AuraTracker = { enabled = true }
				end
			end
		end
	end)
end

function AuraTracker:UnitEnabled(frame, unit)

	if ( not frame.visibility.AuraTracker ) then
		return
	end
	
	if ( not frame.CCFrame ) then
		frame.CCFrame = CreateFrame("Frame", nil, frame) 
		frame.CCFrame.icon = frame.CCFrame:CreateTexture(nil, "ARTWORK")
		frame.CCFrame.text = frame.CCFrame:CreateFontString(nil, "OVERLAY")
	end
	
	frame:RegisterUnitEvent("UNIT_AURA", self, "Scan")
	frame:RegisterUnitEvent("PLAYER_CHANGED_TARGET", self, "Scan")
	frame:RegisterUpdateFunc(self, "Scan")
	
end

function AuraTracker:UnitDisabled(frame, unit)
	frame:UnregisterAll(self)
end

function AuraTracker:LayoutApplied(self)
	AuraTracker:UpdateFrame(self)
	AuraTracker:Scan(self, self.unit)
end

function AuraTracker:ConfigurationLoaded(options)

	local enableAuras = {
		order = 4,
		name = "Enable aura tracker",
		arg = "AuraTracker.enabled",
		type = "toggle",
	}

	options.args.units.args.global.args.general.args.portrait.args.enableAuras = enableAuras
	for _, unit in pairs(ShadowUF.units) do
		options.args.units.args[unit].args.general.args.portrait.args.enableAuras = enableAuras
	end
	
end

local function UpdateText(self, elapsed)
	if (self.auraActive) then
		self.timeLeft = self.timeLeft - elapsed
		if (self.timeLeft <= 0) then
			self.icon:SetTexture("")
			self.text:SetText("")
		end	
		self.text:SetFormattedText("%.1f", self.timeLeft)
	end
end

function AuraTracker:UpdateFrame(frame)

	if ( not frame.CCFrame or not frame.portrait) then 
		return 
	end
	
	if ( not ShadowUF.db.profile.units[frame.unitType].AuraTracker.enabled or not frame.visibility.AuraTracker or not frame.visibility.portrait ) then
		frame.CCFrame:Hide()
	else
		frame.CCFrame:Show()
	end
	
	frame.CCFrame:SetAllPoints(frame.portrait)
	frame.CCFrame:SetScript("OnUpdate", UpdateText)
	frame.CCFrame:SetFrameStrata("HIGH")
	frame.CCFrame.icon:SetWidth(frame.portrait:GetWidth())
	frame.CCFrame.icon:SetHeight(frame.portrait:GetHeight())
	frame.CCFrame.icon:SetAllPoints(frame.CCFrame)
	frame.CCFrame.text:SetFont(ShadowUF.Layout.mediaPath.font, ShadowUF.db.profile.font.size+5, "OUTLINE")
	frame.CCFrame.text:SetTextColor(0,1,0)
	frame.CCFrame.text:SetAllPoints(frame.CCFrame)
	
end

function AuraTracker:Scan(frame)

	if ( not frame.CCFrame or not frame.portrait ) then return end
	local auraList = AuraTracker:GetAuras()
	local priority = 0
	local auraName, auraIcon, auraExpTime
	local index = 1
	
	
	--Buffs
	while ( true ) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitAura(frame.unit, index, "HELPFUL")
		if ( not name ) then break end
		
		if ( auraList[name] and auraList[name] >= priority ) then
			priority = auraList[name]
			auraName = name
			auraIcon = icon
			auraExpTime = expirationTime
		end
		
		index = index+1
	end
	
	index = 1
	
	--Debuffs 
	while ( true ) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitAura(frame.unit, index, "HARMFUL")
		if ( not name ) then break end
		
		if ( auraList[name] and auraList[name] >= priority ) then
			priority = auraList[name]
			auraName = name
			auraIcon = icon
			auraExpTime = expirationTime
		end
		
		index = index+1	
	end
	
	if ( auraName ) then -- If an aura is found, display it and set the time left!
		--frame.portrait:SetAlpha(0)
		frame.CCFrame.icon:SetTexture(auraIcon)
		frame.CCFrame.timeLeft = (auraExpTime - GetTime())
		frame.CCFrame.auraActive = true
	elseif ( not auraName and frame.CCFrame.auraActive ) then -- No aura found and one is shown? Kill it since it's no longer active!
		--frame.portrait:SetAlpha(1)
		frame.CCFrame.icon:SetTexture("")
		frame.CCFrame.text:SetText("")
		frame.CCFrame.auraActive = false
	end
	
end

function AuraTracker:GetAuras()
	return {
		--Spell Name			Priority (higher = more priority)
		--crowd control
		[GetSpellInfo(33786)] 	= 3, 	--Cyclone
		[GetSpellInfo(18658)] 	= 3,	--Hibernate
		[GetSpellInfo(14309)] 	= 3, 	--Freezing Trap Effect
		[GetSpellInfo(60210)]	= 3,	--Freezing arrow effect
		[GetSpellInfo(6770)]	= 3, 	--Sap
		[GetSpellInfo(2094)]	= 3, 	--Blind
		[GetSpellInfo(5782)]	= 3, 	--Fear
		[GetSpellInfo(47860)]	= 3,	--Death Coil Warlock
		[GetSpellInfo(6358)] 	= 3, 	--Seduction
		[GetSpellInfo(5484)] 	= 3, 	--Howl of Terror
		[GetSpellInfo(5246)] 	= 3, 	--Intimidating Shout
		[GetSpellInfo(8122)] 	= 3,	--Psychic Scream
		[GetSpellInfo(12826)] 	= 3,	--Polymorph
		[GetSpellInfo(28272)] 	= 3,	--Polymorph pig
		[GetSpellInfo(28271)] 	= 3,	--Polymorph turtle
		[GetSpellInfo(61305)] 	= 3,	--Polymorph black cat
		[GetSpellInfo(61025)] 	= 3,	--Polymorph serpent
		[GetSpellInfo(51514)]	= 3,	--Hex
		
		--roots
		[GetSpellInfo(53308)] 	= 3, 	--Entangling Roots
		[GetSpellInfo(42917)]	= 3,	--Frost Nova
		[GetSpellInfo(16979)] 	= 3, 	--Feral Charge
		[GetSpellInfo(13809)] 	= 1, 	--Frost Trap
		
		--Stuns and incapacitates
		[GetSpellInfo(8983)] 	= 3, 	--Bash
		[GetSpellInfo(1833)] 	= 3,	--Cheap Shot
		[GetSpellInfo(8643)] 	= 3, 	--Kidney Shot
		[GetSpellInfo(1776)]	= 3, 	--Gouge
		[GetSpellInfo(44572)]	= 3, 	--Deep Freeze
		[GetSpellInfo(49012)]	= 3, 	--Wyvern Sting
		[GetSpellInfo(19503)] 	= 3, 	--Scatter Shot
		[GetSpellInfo(49803)]	= 3, 	--Pounce
		[GetSpellInfo(49802)]	= 3, 	--Maim
		[GetSpellInfo(10308)]	= 3, 	--Hammer of Justice
		[GetSpellInfo(20066)] 	= 3, 	--Repentance
		[GetSpellInfo(46968)] 	= 3, 	--Shockwave
		[GetSpellInfo(49203)] 	= 3,	--Hungering Cold
		[GetSpellInfo(47481)]	= 3,	--Gnaw (dk pet stun)
		
		--Silences
		[GetSpellInfo(18469)] 	= 1,	--Improved Counterspell
		[GetSpellInfo(15487)] 	= 1, 	--Silence
		[GetSpellInfo(34490)] 	= 1, 	--Silencing Shot	
		[GetSpellInfo(18425)]	= 1,	--Improved Kick
		[GetSpellInfo(49916)]	= 1,	--Strangulate
		
		--Disarms
		[GetSpellInfo(676)] 	= 1, 	--Disarm
		[GetSpellInfo(51722)] 	= 1,	--Dismantle
		[GetSpellInfo(53359)] 	= 1,	--Chimera Shot - Scorpid	
				
		--Buffs
		[GetSpellInfo(1022)] 	= 1,	--Blessing of Protection
		[GetSpellInfo(10278)] 	= 1,	--Hand of Protection
		[GetSpellInfo(1044)] 	= 1, 	--Blessing of Freedom
		[GetSpellInfo(2825)] 	= 1, 	--Bloodlust
		[GetSpellInfo(32182)] 	= 1, 	--Heroism
		[GetSpellInfo(33206)] 	= 1, 	--Pain Suppression
		[GetSpellInfo(29166)] 	= 1,	--Innervate
		[GetSpellInfo(18708)]  	= 1,	--Fel Domination
		[GetSpellInfo(54428)]	= 1,	--Divine Plea
		[GetSpellInfo(31821)]	= 1,	--Aura mastery
		
		--immunities
		[GetSpellInfo(34692)] 	= 2, 	--The Beast Within
		[GetSpellInfo(45438)] 	= 2, 	--Ice Block
		[GetSpellInfo(642)] 	= 2,	--Divine Shield
		
	}
end
