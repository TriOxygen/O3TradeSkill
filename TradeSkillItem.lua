local addon, ns = ...
local O3 = O3

ns.TradeSkillItem = O3.UI.Panel:extend({
	height = 24,
	type = 'Button',
	offset = {2, 2, nil, nil},
	colors = {
		trivial = {0.5, 0.5, 0.5, 1},
		easy = {0.1, 0.5, 0.1, 1},
		medium = {0.8, 0.8, 0.1, 1},
		optimal = {1, 0.5, 0.1, 1},
		header = {1, 1, 1, 1},
		subheader = {1, 1, 1, 1},
	},
	expandClick = function (self)
	end,
	createRegions = function (self)
		self.expandButton = O3.UI.GlyphButton:instance({
			parent = self,
			parentFrame = self.frame,
			height = self.height,
			width = self.height,
			offset = {2, nil, 0, nil},
			fontSize = 10,
			bg = true,
			width = 16,
			height = 16,
			text = '',
			onClick = function (expandButton)
				self:expandClick(expandButton)
			end,
			postInit = function (expandButton)
				expandButton:hide()
			end,
		})
		self.panel = self:createPanel({
			offset = {18, 0, 0, 0},
			style = function (panel)
				panel.name = panel:createFontString({
					offset = {1, 78, nil, nil},
					height = 16,
					color = {0.9, 0.9, 0.1, 1},
					justifyV = 'MIDDLE',
					justifyH = 'LEFT',
					fontSize = 10,
				})
				panel.count = panel:createFontString({
					offset = {nil, 38, nil, nil},
					height = 16,
					width = 20,
					-- color = {0.9, 0.9, 0.1, 1},
					justifyV = 'MIDDLE',
					justifyH = 'RIGHT',
					fontSize = 10,
				})
				panel.numSkillups = panel:createFontString({
					offset = {nil, 58, nil, nil},
					height = 16,
					width = 20,
					-- color = {0.9, 0.9, 0.1, 1},
					justifyV = 'MIDDLE',
					justifyH = 'RIGHT',
					fontSize = 10,
				})
				panel.highlight = panel:createTexture({
					layer = 'ARTWORK',
					gradient = 'VERTICAL',
					color = {0,1,1,0.10},
					colorEnd = {0,0.5,0.5,0.20},
					offset = {1,1,1,1},
				})
				panel.highlight:Hide()
				panel.checkedLayer = panel:createTexture({
					layer = 'ARTWORK',
					gradient = 'VERTICAL',
					color = {0,1,0,0.20},
					colorEnd = {0,0.8,0,0.40},
					offset = {1,1,1,1},
				})
				panel.checkedLayer:Hide()
				panel.queueButton = O3.UI.GlyphButton:instance({
					parentFrame = panel.frame,
					bg = true,
					color = {0.5, 0.5, 0.1},
					offset = {nil, 18, 1, 1},
					width = 16,
					fontSize = 10,
					text = '',
					onClick = function (queueButton)
						--
					end,
					postInit = function (queueButton)
						queueButton:hide()
					end,
				})
				panel.craftButton = O3.UI.GlyphButton:instance({
					parentFrame = panel.frame,
					bg = true,
					color = {0.1, 1, 0.1},
					offset = {nil, 1, 1, 1},
					width = 16,
					fontSize = 10,
					text = '',
					onClick = function (craftButton)
						DoTradeSkill(self.id)
					end,
					postInit = function (craftButton)
						craftButton:hide()
					end,
				})
			end,
		})
		self.craftButton = self.panel.craftButton
		self.queueButton = self.panel.queueButton
		self.name = self.panel.name
		self.count = self.panel.count
		self.numSkillups = self.panel.numSkillups
	end,
	update = function (self, id)
		self.id = id
		local skillName, skillType, numAvailable, isExpanded, serviceType, numSkillUps, indentLevel, showProgressBar, currentRank, maxRank, startingRank = GetTradeSkillInfo(id)
		self.type = skillType
		self.frame:SetPoint('LEFT', indentLevel*16, 0)
		self.name:SetText(skillName)
		self.skillName = skillName
		if skillType == 'header' or skillType == 'subheader' then
			self.count:SetText('')
			self.queueButton:hide()
			self.craftButton:hide()
			self.expandButton:show()
			if isExpanded then
				self.expandButton.text:SetText('')
			else
				self.expandButton.text:SetText('')
			end
		else
			if skillType == 'optimal' and numSkillUps > 1 then
				self.numSkillups:SetText('+'..numSkillUps)
			else
				self.numSkillups:SetText('')
			end
			if (numAvailable > 0 ) then
				self.count:SetText(numAvailable)
				self.craftButton:show()
			else
				self.craftButton:hide()
				self.count:SetText('')
			end
			self.expandButton:hide()
			self.queueButton:show()
		end
		
		if (self.parent.selectedItemName and self.parent.selectedItemName == skillName) then
			self.panel.checkedLayer:Show()
		else
			self.panel.checkedLayer:Hide()
		end
		if self.colors[skillType] then
			self.name:SetTextColor(unpack(self.colors[skillType]))
			self.numSkillups:SetTextColor(unpack(self.colors[skillType]))
			self.count:SetTextColor(unpack(self.colors[skillType]))
		end
		self.isExpanded = isExpanded
		return true

	end,
	check = function (self, checked)
		if checked then
			self.panel.checkedLayer:Show()
		else
			self.panel.checkedLayer:Hide()
		end
	end,
	hook = function (self)
		self.frame:SetScript('OnEnter', function (frame)
			self.panel.highlight:Show()
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
			-- GameTooltip:SetMailItem(self.id)
			CursorUpdate(frame)
			GameTooltip:Show()

		
			if (self.onEnter) then
				self:onEnter()
			end
		end)
		self.frame:SetScript('OnLeave', function (frame)
			GameTooltip:Hide()
			ResetCursor()

			self.panel.highlight:Hide()
			if (self.onLeave) then
				self:onLeave()
			end
		end)
		self.frame:SetScript('OnClick', function (frame)
			if (self.onClick) then
				self:onClick()
			end
		end)
	end,	
})