local addon, ns = ...
local O3 = O3

O3:module({
	name = 'TradeSkill',
	readable = 'Trade Skill',
	weight = 96,
	config = {
		enabled = true,
		font = O3.Media:font('Normal'),
		fontSize = 12,
		fontStyle = 'THINOUTLINE',
		autoLoot = false,
		xOffset = 0,
		yOffset = 100,
		anchor = 'CENTER',
		anchorTo = 'CENTER',
	},        
	events = {
		TRADE_SKILL_SHOW = true,
	},
	settings = {
	},
	TRADE_SKILL_SHOW = function (self)
		if (not self.tradeSkillWindow) then
			self.tradeSkillWindow = ns.TradeSkillWindow:instance({
				handler = self
			})
		end
		self.tradeSkillWindow:show()
	end,
	postInit = function (self)
		if (not IsAddOnLoaded("Blizzard_TradeSkillUI")) then
			LoadAddOn("Blizzard_TradeSkillUI")
		end
		TradeSkillFrame_Show = DoNothing
		O3:destroy(TradeSkillFrame)
		
		-- O3:destroy(StationeryPopupFrame)
		-- O3:destroy(OpenMailFrame)
	end,
})
