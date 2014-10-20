local addon, ns = ...
local O3 = O3

ns.TradeSkillWindow = O3.UI.ItemListWindow:extend({
	name = 'O3TradeSkill',
	titleText = 'TradeSkill',
	managed = true,
	itemCount = 25,
	queueItems = {},
	width = 350,
	closeWithEscape = true,
	doubleWidth = 700,
	activeTradeSkill = null,
	settings = {
		itemsTopGap = 34,
		itemsBottomGap = 0,
		itemHeight = 16,
		fontSize = 10,
	},
	setInvSlotFilters = function (self)
		self.invSlots = {GetTradeSkillInvSlots()}
		for i=1, #self.invSlots do
			print(i, self.invSlots[i])
		end
	end,
	setSubClassFilters = function (self)
		self.subClasses = {GetTradeSkillSubClasses()}
		self.subCategories = {}
		for i=1, #self.subClasses do
			self.subCategories[i] = {GetTradeSkillSubCategories(i)}
			print(i, self.subClasses[i])
			for j=1, #self.subCategories[i] do
				print('...', j, self.subCategories[i][j])
			end
		end
	end,
	 
	onShow = function (self)
		self.handler:registerEvent('BAG_UPDATE', self)
		self.handler:registerEvent('TRADE_SKILL_UPDATE', self)
		self.handler:registerEvent('TRADE_SKILL_FILTER_UPDATE', self)
		self.handler:registerEvent('TRADE_SKILL_CLOSE', self)	
		self:TRADE_SKILL_UPDATE()
		-- self:setInvSlotFilters()
		-- self:setSubClassFilters()
	end,
	BAG_UPDATE = function (self)
		self:scrollTo()
		--self:getDetail()
	end,
	TRADE_SKILL_CLOSE = function (self)
		self.frame:Hide()
	end,
	createContent = function (self)
		local headerHeight = self.settings.headerHeight+self.settings.itemsTopGap
		local footerHeight = self.settings.footerHeight+self.settings.itemsBottomGap
		self.content = self:createPanel({
			width = self.doubleWidth/2,
			offset = {0, nil, headerHeight, footerHeight-1},
			style = function (self)
				self:createOutline({
					layer = 'BORDER',
					gradient = 'VERTICAL',
					color = {0, 0, 0, 1 },
					colorEnd = {0, 0, 0, 1 },
					offset = {0, 0, 0, 0 },
				})

			end,
		})

		self.rightPanel = self:createPanel({
			width = self.doubleWidth/2+1,
			offset = {nil, 0, headerHeight, footerHeight-1},
			style = function (rightPanel)
				self:createOutline({
					layer = 'BORDER',
					gradient = 'VERTICAL',
					color = {0, 0, 0, 1 },
					colorEnd = {0, 0, 0, 1 },
					offset = {0, 0, 0, 0 },
				})
			end,
			postInit = function (rightPanel)
				rightPanel.frame:Hide()
			end,
		})		
		self.contentFrame = self.content.frame
	end,
	updateBar = function (self)
		if (self.numItems > self.itemCount) then
			self.bar:show()
			self.content:setWidth(self.doubleWidth/2 - 12)
		else
			self.bar:hide()
			self.content:setWidth(self.doubleWidth/2)
		end
	end,

	onHide = function (self)
		CloseTradeSkill()
		self.handler:unregisterEvent('BAG_UPDATE', self)
		self.handler:unregisterEvent('TRADE_SKILL_UPDATE', self)
	end,
	getNumItems = function (self)
		self.numItems = GetNumTradeSkills()
	end,

	TRADE_SKILL_UPDATE = function (self)
		local tradeskillName, rank, maxRank = GetTradeSkillLine()
		local newNumItems = GetNumTradeSkills()
		if (self.activeTradeSkill ~= tradeskillName) or (newNumItems ~= self.numItems) then
			self.rightPanel:hide()
			self:setDouble(false)
		elseif (self.detailPanel) then
			self.detailPanel:update(GetTradeSkillSelectionIndex())
		end
		if newNumItems ~= self.numItems then
			self:scrollTo()
		end


		self.activeTradeSkill = tradeskillName
		self:updateProgressBar()
	end,
	TRADE_SKILL_FILTER_UPDATE = function (self)
		local newNumItems = GetNumTradeSkills()

		if (newNumItems ~= self.numItems) then
			self.rightPanel:hide()
			self:setDouble(false)
			self:scrollTo()
		elseif (self.detailPanel) then
			self.detailPanel:update()
		end
	end,
	createItem = function (self)
		local item = ns.TradeSkillItem:instance({
			parent = self,
			height = self.settings.itemHeight,
			parentFrame = self.content.frame,
			expandClick = function (item, expandButton)
				if (item.isExpanded) then
					expandButton.text:SetText('')
					CollapseTradeSkillSubClass(item.id)
				else
					expandButton.text:SetText('')
					ExpandTradeSkillSubClass(item.id)
				end
				self:scrollTo()				
			end,
			onClick = function (item)
				if item.type == 'header' or item.type == 'subheader' then
					return
				end
				if (self.selectedItem) then
					self.selectedItem:check(false)
				end
				self.selectedItemName = item.skillName
				self.selectedItem = item
				item:check(true)

				if (not self.detailPanel) then
					self.detailPanel = ns.TradeSkillDetail:instance({
						parent = self,
						parentPanel = self.rightPanel,
						parentFrame = self.rightPanel.frame
					})
				end
				self.detailPanel:update(item.id)
				SelectTradeSkill(item.id)
				self.detailPanel:show()
				self:setDouble(true)
			end,
		})
		item:hide()
		return item
	end,
	setDouble = function (self, double)
		if (double) then
			self:setWidth(self.doubleWidth)
			self.rightPanel:show()
		else
			self:setWidth(self.width)
			self.rightPanel:hide()
		end
	end,
	createProfessionButtons = function (self)

		local toolbar = O3.UI.Toolbar:instance({
			height = self.settings.itemsTopGap+2,
			parentFrame = self.frame,
			offset = {0, 0, self.settings.headerHeight-1, nil},
			createRegions = function (toolbar)

			end
		})	

		local firstProf, secondProf = GetProfessions()

		local profs = {firstProf, secondProf}

		local lastButton = nil

		for i = 1, #profs do
			local id = profs[i]
			local name, texture, rank, maxRank, numSpells, spelloffset, skillLine, rankModifier, specializationIndex, specializationOffset = GetProfessionInfo(id)
			local xSpacing = 20
			for j = 1, numSpells do 
				local spellName =  GetSpellBookItemName(j + spelloffset, 'profession')
				if spellName then
					local name, rank, texture = GetSpellInfo(spellName)
					local professionButton = O3.UI.IconButton:instance({
						template = 'SecureActionButtonTemplate',
						attributes = {
							type = 'spell',
							spell = spellName,
						},
						parentFrame = toolbar.frame,
						icon = texture,
						iconPath = '',
					})
					professionButton.id = id
					if lastButton then
						professionButton:point('TOPLEFT', lastButton.frame, 'TOPRIGHT', xSpacing, 0)
					else
						professionButton:point('TOPLEFT', 2, -2)
					end
					lastButton = professionButton
					xSpacing = 2
				end
				
			end
		end

		O3.UI.EditBox:instance({
			parentFrame = toolbar.frame,
			width = 100,
			offset = {nil, nil, 2, 2,},
			value = GetTradeSkillItemNameFilter(),
			onEnterPressed = function (editBox)
				SetTradeSkillItemNameFilter(editBox.frame:GetText())
				self:TRADE_SKILL_UPDATE()
			end,
			postInit = function (editBox)
				editBox:point('LEFT', lastButton.frame, 'RIGHT', 10, 0)
			end,
		})
	end,
	updateProgressBar = function (self)
		local tradeskillName, rank, maxRank = GetTradeSkillLine()
		self:setTitle('O3', tradeskillName)

		self.progressBar.frame:SetMinMaxValues(1, maxRank)
		self.progressBar.frame:SetValue(rank)
		self.progressBar.label:SetText(rank..'/'..maxRank)
	end,
	postCreate = function (self)
		self:createItems()
		self.bar = O3.UI.ScrollBar:instance({
			width = 11,
			parentFrame = self.content.frame,
			offset = {nil, -11, 0, 0},
		})

		-- self:createTexture({
		-- 	layer = 'BACKGROUND',
		-- 	subLayer = -7,
		-- 	file = O3.Media:texture('Background'),
		-- 	tile = true,
		-- 	color = {0.5, 0.5, 0.5, 0.5},
		-- 	offset = {1,1,1,1},
		-- })

		self.progressBar = O3.UI.Panel:instance({
			parentFrame = self.footer.frame,
			offset = {3, 3, 3, 3},
			type = 'StatusBar',
			style = function (progressBar)
				progressBar:createOutline({
					layer = 'BORDER',
					gradient = 'VERTICAL',
					color = {1, 1, 1, 0.1 },
					colorEnd = {1, 1, 1, 0.2 },
					offset = {1, 1, 1, 1 },
				})
				progressBar:createOutline({
					layer = 'BORDER',
					gradient = 'VERTICAL',
					color = {0, 0, 0, 1 },
					colorEnd = {0, 0, 0, 1 },
					offset = {0, 0, 0, 0 },
				})			
			end,
			createRegions = function (progressBar)
				progressBar.label = progressBar:createFontString({
					offset = {0, 0, 0, 0},

				})
			end,
			postInit = function (progressBar)
				progressBar.frame:SetStatusBarTexture(O3.Media:statusBar('Default'), 'BACKGROUND')
				progressBar.frame:SetStatusBarColor(0.2, 0.8, 0.1)
			end,
		})

		self._offset = 0
		self:createProfessionButtons()
	end,	
})
