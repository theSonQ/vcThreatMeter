local classColor = {
		WARRIOR = {0.9, 0, 0},        -- warrior
		RANGER = {0.45, 0.64, 0.01},  -- scout
		THIEF = {0, 0.64, 0.57},      -- rogue
		MAGE = {1, 0.5, 0},           -- mage
		AUGUR = {0.16, 0.55, 0.93},   -- priest
		KNIGHT = {1, 0.9, 0},         -- knight
		DRUID = {0, 0.49, 0},         -- druid
		WARDEN = {0.65, 0.42, 0.13},  -- warden
		GM = {0.93, 0.39, 0.70},      -- GM's are pink ;)
		UNKNOWN = {0.5, 0.5, 0.5},		-- uknown is gray
}

local vcThreatMeter_DefaultSettings = {
		["point"] = "CENTER",
		["relativePoint"] = "CENTER",
		["relativeTo"] = "UIParent",
		["offsetX"] = -400,
		["offsetY"] = 75,
}

local playerClass = {}		-- playerClass["Duppy] = "THEIF"


function vcThreatMeter_OnLoad(this)
	DEFAULT_CHAT_FRAME:AddMessage("vcThreatMeter loaded")

	this:RegisterEvent("SAVE_VARIABLES")
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("TARGET_HATE_LIST_UPDATED")
	this:RegisterEvent("UNIT_TARGET_CHANGED")
	this:RegisterEvent("PARTY_MEMBER_CHANGED")
	this:RegisterEvent("COMBATMETER_DAMAGE")
	this:RegisterEvent("COMBATMETER_HEAL")
	this:RegisterEvent("LOADING_END")
	this:RegisterEvent("EXCHANGECLASS_SUCCESS")

	SaveVariables("vcThreatMeter_Settings")  -- settings are saved to this table
end


-- local formattedNumber = (tostring(myNumber):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", ""))
local function CommaValue(amount)
	local formatted, k = math.floor(amount+0.5)
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if ( k == 0 ) then
			break
		end
	end
	return formatted
end


local function ClearThreatMeter()
	for j = 1, 6 do
		getglobal("vcThreatMeter_Bar" .. j):SetValue(0)
		getglobal("vcThreatMeter_Bar" .. j .. "TextLeft"):SetText("")
		getglobal("vcThreatMeter_Bar" .. j .. "TextRight"):SetText("")
	end
end


local function UpdateThreatMeter()
	--echo("Update ThreatMeter " .. GetTime())

	local hateList = {}
	local i, totalHate, greatestHate = 0, 0, 0
	local unitName, unitHate = "???", 0
	local pet = "pet"
	local aggroPeta = 0
	repeat
		i = i + 1
		unitName, unitHate, unitDamage = GetTargetHateList(i)

		if (not unitName) then
			vcThreatMeter:Hide()
			ClearThreatMeter()
			break;
		else
			hateList[i] = { unitName =unitName, unitHate = unitHate, unitDamage = unitDamage } --uzupelnianie tabeli aggro
			--@@@ jest pomysl, zrobic na podstawie tego addona inny jezeli nie siadzie dodanie do tego kilku funkcji
			--@@@ z ta roznica ze sort ma sie odbywac po obrazeniach *0.75 i sprawdzic czy inne elementy kodu beda pasowac do tego pomyslu
			if(UnitName("pet") == "Centaur Chiron") then --czy jest centek zeby TM nie pajacowal bez niego
				if (hateList[i].unitName == UnitName("player")) then -- czy moj nick zgadza sie z aktualnym nickiem listy
					aggroPeta = hateList[i].unitDamage * 0.75 --pomniejszenie aggro ze wzgledu na buff
					DEFAULT_CHAT_FRAME:AddMessage( "Aggro Centa: " .. string.format("%s", CommaValue(hateList[i].unitDamage)))
				end
			end
			totalHate = totalHate + unitHate

			if (greatestHate < unitHate) then
				greatestHate = unitHate
			end
			--DEFAULT_CHAT_FRAME:AddMessage(hateList[i].unitDamage)
			if(greatestHate - tonumber(aggroPeta) < 4000000 and UnitName("pet") == "Centaur Chiron" )  then --roznica miedzy najwiekszym aggro a centa/ sprawdz czy tonumber
				--DEFAULT_CHAT_FRAME:AddMessage("Ostrożnie! Cent Blisko Najwyzszego aggro")		--nie tnie stringa w dziwny sposob
				--SendChatMessage("Ostrożnie! Cent Blisko Najwyzszego aggro","SAY")
				if(greatestHate - tonumber(aggroPeta) > 0) then --tak wiem te warunki mozna polaczyc, ale tak bylo latwiej testowac 
					DEFAULT_CHAT_FRAME:AddMessage("Ostrożnie! Cent Blisko Najwyzszego aggro")
					--SendChatMessage("Ostrożnie! Cent Blisko Najwyzszego aggro","SAY")
					DEFAULT_CHAT_FRAME:AddMessage("Za " .. (greatestHate - tonumber(aggroPeta)) .. " przebicie aggro")
					SendChatMessage("Za " .. string.format("%s",CommaValue(greatestHate - tonumber(aggroPeta))) .. " przebicie aggro", "SAY") --czy ja tu czegos nie odjebalem?
				end
				
			end
			if(greatestHate <= tonumber(aggroPeta)) then SendChatMessage("No, i centaur wyjebany. Gratuluje.", "SAY")
			end --hehs
		end
	until (unitName == nil)

	if (#hateList > 0) then

		if ( not vcThreatMeter:IsVisible() ) then
			vcThreatMeter:Show()
		end

		-- sort threat list in descending order
		table.sort(hateList, function(a, b) return a.unitHate > b.unitHate end)

		-- display info
		for j = 1, 6 do
			local threatBar = getglobal("vcThreatMeter_Bar" .. j)
			local threatName = getglobal("vcThreatMeter_Bar" .. j .. "TextLeft")
			local threatPercentage = getglobal("vcThreatMeter_Bar" .. j .. "TextRight")

			if (type(hateList[j]) == "table" and totalHate > 0) then
				local hateValue = hateList[j].unitHate / totalHate

				-- adjust bar (0-100)
				threatBar:SetBarColor(unpack(classColor[playerClass[hateList[j].unitName]] or {0.5, 0.5, 0.5}))
				threatBar:SetValue(math.ceil(hateValue * 100))

				-- show player name
				--threatName:SetColor(unpack(classColor[playerClass[hateList[j].unitName]]))  -- color names
				threatName:SetText(hateList[j].unitName)

				-- show threat number and percentage
				threatPercentage:SetText(string.format("%s (%2d%%)", CommaValue(hateList[j].unitHate), math.ceil(hateValue * 100)))
			else
				threatName:SetText("")
				threatName:SetColor(1,1,1)
				threatPercentage:SetText("")
				threatBar:SetValue(0)
			end

		end

	end

end


local function UpdatePartyMemberInfo()
	if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
		--echo("Updating party info")
		for i = 1, 36 do
			local name = UnitName("raid" .. i)
			if name then
				playerClass[name] = UnitClassToken("raid" .. i)
			end
		end
	else
		--echo("Updating player info")
		local name = UnitName("player")
		if name then
			local class = UnitClassToken("player") or "UNKNOWN" -- strangely, name and class are sometimes nil after teleporting
			playerClass[name] = class
		end
	end
end



function vcThreatMeter_OnEvent(this, event)
	if ( event == "TARGET_HATE_LIST_UPDATED" ) then
		UpdateThreatMeter()

	elseif ( event == "UNIT_TARGET_CHANGED" and (arg1 == "player")) then
		if ( UnitExists("target") and not UnitIsDeadOrGhost("target") and UnitCanAttack("player", "target") ) then
			TargetHateListRequest()
		else
			vcThreatMeter:Hide()
		end

	elseif ( event == "COMBATMETER_DAMAGE" or event == "COMBATMETER_HEAL" ) then
			TargetHateListRequest()

	elseif ( event == "PARTY_MEMBER_CHANGED" or event == "EXCHANGECLASS_SUCCESS" ) then
		UpdatePartyMemberInfo()

	elseif ( event == "LOADING_END" ) then
		local name = UnitName("player")
		if name then
			playerClass[name] = UnitClassToken("player") or "UNKNOWN"
		end

	elseif ( event == "SAVE_VARIABLES" ) then
		local point, relativePoint, relativeTo, x, y = this:GetAnchor()

		assert(vcThreatMeter_Settings, "[vcThreatMeter:SAVE_VARIABLES] vcThreatMeter_Settings variable is nil!" )
		vcThreatMeter_Settings.point = point
		vcThreatMeter_Settings.relativePoint = relativePoint
		vcThreatMeter_Settings.relativeTo = relativeTo:GetName()
		vcThreatMeter_Settings.offsetX = x
		vcThreatMeter_Settings.offsetY = y

		DEFAULT_CHAT_FRAME:AddMessage("[vcThreatMeter] Saving settings.")

	elseif ( event == "VARIABLES_LOADED" ) then
		if not vcThreatMeter_Settings then
			vcThreatMeter_Settings = {}
			vcThreatMeter_Settings.point = vcThreatMeter_DefaultSettings.point
			vcThreatMeter_Settings.relativePoint =	vcThreatMeter_DefaultSettings.relativePoint
			vcThreatMeter_Settings.relativeTo =	vcThreatMeter_DefaultSettings.relativeTo
			vcThreatMeter_Settings.offsetX =	vcThreatMeter_DefaultSettings.offsetX
			vcThreatMeter_Settings.offsetY =	vcThreatMeter_DefaultSettings.offsetY

			DEFAULT_CHAT_FRAME:AddMessage("[vcThreatMeter] Loaded default settings.")
		end

		assert(vcThreatMeter_Settings, "[vcThreatMeter:VARIABLES_LOADED] - vcThreatMeter_Settings variable is nil!" )
		this:ClearAllAnchors()
		this:SetAnchor(vcThreatMeter_Settings.point, vcThreatMeter_Settings.relativePoint, vcThreatMeter_Settings.relativeTo, vcThreatMeter_Settings.offsetX, vcThreatMeter_Settings.offsetY)
	end

end




--[[
Test Macros
/run for i=1,6 do getglobal("vcThreatMeter_Bar"..i):SetValue(100) end
/run vcThreatMeter_Bar1TextLeft:SetText("Foooooobaaar"); vcThreatMeter_Bar1TextRight:SetText("10,000,000 (99%)")
/run vcThreatMeter:ClearAllAnchors(); vcThreatMeter:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", "ChatFrame1", 0, -5)
]]
