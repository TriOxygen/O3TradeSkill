local addon, ns = ...
local O3 = O3
local UI = O3.UI

local ReagentItem = UI.Panel:extend({
	offset = {2, 2, nil, nil},
	height = 28,
	update = function (self, reagentName, reagentTexture, reagentCount, playerReagentCount)
		self.name:SetText(reagentName)
		self.icon:setTexture(reagentTexture)
		if (reagentCount <= playerReagentCount) then
			self.name:SetTextColor(1,1,1)
			self.count:SetTextColor(1,1,1)
		else
			self.name:SetTextColor(0.5,0.5,0.5)
			self.count:SetTextColor(1,0,0)
		end
		self.count:SetText(reagentCount..'/'..playerReagentCount)

	end,
	createRegions = function (self)
		self.icon = UI.IconButton:instance({
			width = self.height-2,
			height = self.height-2,
			offset = {2, nil, nil, nil},
			parentFrame = self.frame,
			onEnter = function (icon)
				GameTooltip:SetOwner(icon.frame, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(GetTradeSkillReagentItemLink(self.detailPanel.id, self.id))
				GameTooltip:Show()
			end,
			onLeave = function (icon)
				GameTooltip:Hide()
				ResetCursor()
			end,
		})
		self.count = self:createFontString({
			justifyH = 'RIGHT',
			width = 40,
			offset = {nil, 2, 0, 0},
		})
		self.name = self:createFontString({
			justifyH = 'LEFT',
			offset = {nil, nil, 0, 0},
		})
		self.name:SetPoint('LEFT', self.icon.frame, 'RIGHT', 4, 0)
		self.name:SetPoint('RIGHT', self.count, 'LEFT', 4, 0)
	end,
	postInit = function (self)
		self.frame:Hide()
	end,
})

ns.TradeSkillDetail = UI.Panel:extend({
	offset = {0, 0, 0, 0},
	toolbarHeight = 26,
	reagents = {},
	numAvailable = 1,
	createRegions = function (self)
		self:createToolbar()
		self:createDescription()
		self:createReagents(8)
	end,
	createReagents = function (self, amount)
		self:createPanel({
			parentFrame = self.frame,
			offset = {2, 2, nil, 2},
			style = function (wrapperPanel)
				wrapperPanel:createTexture({
					layer = 'BACKGROUND',
					subLayer = -7,
					file = O3.Media:texture('Background'),
					tile = true,
					color = {147/255, 153/255, 159/255, 0.95},
					offset = {1,1,1,1},
				})
				wrapperPanel:createOutline({
					layer = 'BORDER',
					gradient = 'VERTICAL',
					color = {1, 1, 1, 0.03 },
					colorEnd = {1, 1, 1, 0.05 },
					offset = {1, 1, 1, 1},
					-- width = 2,
					-- height = 2,
				})
				wrapperPanel:createOutline({
					layer = 'BORDER',
					gradient = 'VERTICAL',
					color = {0, 0, 0, 1 },
					colorEnd = {0, 0, 0, 1 },
					offset = {0, 0, 0, 0 },
				})
			end,			
			createRegions = function (wrapperPanel)
				for i = 1, amount do
					local reagentItem = ReagentItem:instance({
						id = i,
						detailPanel = self,
						parentFrame = wrapperPanel.frame
					})
					if i == 1 then
						reagentItem:point('TOP', 0, -2)
					else
						reagentItem:point('TOP', self.reagents[i-1].frame, 'BOTTOM', 0, 0)
					end
					self.reagents[i] = reagentItem
				end
			end,
			postInit = function (wrapperPanel)
				wrapperPanel:point('TOP', self.description, 'BOTTOM', 0, 0)
			end,
		})
	end,
	createDescription = function (self)
		self.icon = UI.IconButton:instance({
			width = 48,
			height = 48,
			offset = {2, nil, self.toolbarHeight+2, nil},
			parentFrame = self.frame,
			onEnter = function (icon)
				GameTooltip:SetOwner(icon.frame, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(GetTradeSkillItemLink(self.id))
				GameTooltip:Show()
			end,
			onLeave = function (icon)
				GameTooltip:Hide()
				ResetCursor()
			end,
		})
		self.details = self:createFontString({
			offset = {nil, 2, nil, nil},
			justifyH = 'LEFT',
			justifyV = 'TOP',
		})
		self.details:SetPoint('TOPLEFT',  self.icon.frame, 'TOPRIGHT', 4, 0)
		self.details:SetPoint('BOTTOMLEFT',  self.icon.frame, 'BOTTOMRIGHT', 4, 0)

		self.description = self:createFontString({
			height = 100,
			offset = {2, 2, nil, nil},
			justifyH = 'LEFT',
			justifyV = 'TOP',
		})
		self.description:SetPoint('TOP',  self.icon.frame, 'BOTTOM', 0, -4)
	end,
	update = function (self, id)
		id = id or self.id
		if (not id) then
			return
		end
		local texture = GetTradeSkillIcon(id)
		local toolName, hasTool = GetTradeSkillTools(id)
		local skillName, skillType, numAvailable, isExpanded, serviceType, numSkillUps, indentLevel, showProgressBar, currentRank, maxRank, startingRank = GetTradeSkillInfo(id)
		local cooldown = math.ceil(GetTradeSkillCooldown(id) or 0)
		if not skillName then
			return
		end
		self.numAvailable = numAvailable
		self.icon:setTexture(texture)
		local detail = '|cffffff00'..skillName..'|r\n'
		if toolName then
			local color 
			if hasTool then
				color = '|cffffffff'
			else
				color = '|cffff0000'
			end
			detail = detail ..'Requires : '..color..toolName..'|r\n'
		end
		if cooldown > 0 then
			local hours = math.floor(cooldown/3600)
			local minutes = math.floor(cooldown/60)-(hours*60)
			local seconds = cooldown % 60
			detail = detail..'Cooldown : |cffff0000'..hours..' hours, '..minutes..' minutes, '..seconds..' seconds|r\n'
		end

		self.details:SetText(detail)
		self.description:SetText(GetTradeSkillDescription(id))

		self:setReagents(id)
		self.id = id
	end,
	setReagents = function (self, id)
		local numReagents = GetTradeSkillNumReagents(id)
		for reagentIndex = 1, 8 do
			local reagentItem = self.reagents[reagentIndex]
			if (reagentIndex <= numReagents) then
				local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, reagentIndex)
				reagentItem:update(reagentName, reagentTexture, reagentCount, playerReagentCount)
				reagentItem:show()
			else
				reagentItem:hide()
			end
		end	
	end,
	createToolbar = function (self)
		O3.UI.Toolbar:instance({
			parentFrame = self.frame,
			offset = {0, 0, 0, nil},
			height = self.toolbarHeight,
			createRegions = function (toolbar)
				self.craftAllButton = O3.UI.Button:instance({
					parentFrame = self.frame,
					color = {0.1, 0.9, 0.1, 1},
					offset = {2, nil, 2, nil},
					text = 'Craft all',
					width = 90,
					height = toolbar.height-4,
					postInit = function (craftAllButton)
					end,
					onClick = function (craftAllButton)
						DoTradeSkill(self.id, self.numAvailable)
					end
				})
				self.craftCount = O3.UI.EditBox:instance({
					parentFrame = self.frame,
					width = 40,
					height = toolbar.height-4,
					numeric = true,
					value = 1,
					postInit = function (craftCount)
						craftCount:point('LEFT', self.craftAllButton.frame, 'RIGHT', 20, 0)
					end,
				})
				self.craftButton = O3.UI.Button:instance({
					parentFrame = self.frame,
					color = {0.1, 0.9, 0.1, 1},
					text = 'Craft',
					width = 90,
					height = toolbar.height-4,
					postInit = function (craftButton)
						craftButton:point('LEFT', self.craftCount.frame, 'RIGHT', 2, 0)
					end,
					onClick = function (craftButton)
						DoTradeSkill(self.id, self.craftCount.frame:GetNumber() or 1)
					end
				})
				self.close = O3.UI.GlyphButton:instance({
					parentFrame = toolbar.frame,
					width = 20,
					height = 20,
					text = '',
					offset = {nil, 2, nil, nil},
					onClick = function ()
						self.parentPanel:hide()
						self.parent:setDouble(false)
					end,
				})
			end
		})	
	end,
})