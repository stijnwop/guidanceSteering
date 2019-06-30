local mapping = Gui.CONFIGURATION_CLASS_MAPPING
if mapping["numberUpDown"] == nil then

	NumberUpDownElement = {}
	local NumberUpDownElement_mt = Class(NumberUpDownElement, GuiElement)

	function NumberUpDownElement:new(target, custom_mt)
		local self = GuiElement:new(target, custom_mt or NumberUpDownElement_mt)
		self:include(IndexChangeSubjectMixin)
		self:include(PlaySampleMixin)
		
		self.isChecked = false
		self.mouseEntered = false
		self.buttonLRChange = false
		
		self.value = 0
		self.increment = 1
		self.min = nil
		self.max = nil
		
		self.scrollDelayDuration = 300
		self.leftDelayTime = 0
		self.rightDelayTime = 0
		
		self.forceHighlight = false
		
		self.leftButtonElement = nil
		self.rightButtonElement = nil
		self.textElement = nil
		self.labelElement = nil
		
		return self
	end

	function NumberUpDownElement:loadFromXML(xmlFile, key)
		NumberUpDownElement:superClass().loadFromXML(self, xmlFile, key)
		
		print("Load xml")
		
		self:addCallback(xmlFile, key.."#onClick", "onClickCallback")
		self:addCallback(xmlFile, key.."#onFocus", "onFocusCallback")
		self:addCallback(xmlFile, key.."#onLeave", "onLeaveCallback")
		
		self.buttonLRChange = Utils.getNoNil(getXMLBool(xmlFile, key.."#buttonLRChange"), self.buttonLRChange)
		self:setIncrement(Utils.getNoNil(getXMLFloat(xmlFile, key.."#increment"), self.increment))
		self:setMin(getXMLFloat(xmlFile, key.."#min"))
		self:setMax(getXMLFloat(xmlFile, key.."#max"))
		
		
	end

	function NumberUpDownElement:loadProfile(profile, applyProfile)
		NumberUpDownElement:superClass().loadProfile(self, profile, applyProfile)
		
		self.buttonLRChange = profile:getBool("buttonLRChange", self.buttonLRChange)
		self:setIncrement(profile:getNumber("increment", self.increment))
		self:setMin(profile:getNumber("min", self.min))
		self:setMax(profile:getNumber("max", self.max))
		
	end

	function NumberUpDownElement:copyAttributes(src)
		NumberUpDownElement:superClass().copyAttributes(self, src)
		
		self.isChecked = src.isChecked
		self.buttonLRChange = src.buttonLRChange
		
		self.value = src.value
		self.increment = src.increment
		self.min = src.min
		self.max = src.max
		
		self.scrollDelayDuration = src.scrollDelayDuration
		
		self.onClickCallback = src.onClickCallback
		self.onLeaveCallback = src.onLeaveCallback
		self.onFocusCallback = src.onFocusCallback
		
		GuiMixin.cloneMixin(IndexChangeSubjectMixin, src, self)
		GuiMixin.cloneMixin(PlaySampleMixin, src, self)
		
	end

	function NumberUpDownElement:setForceHighlight(needForceHighlight)
		self.forceHighlight = needForceHighlight
	end

	function NumberUpDownElement:addElement(element)
		NumberUpDownElement:superClass().addElement(self, element)
		
		if table.getn(self.elements) == 1 then
			-- left
			self.leftButtonElement = element
			self.leftButtonElement.forceHighlight = true
			element:setHandleFocus(false)
			element.target = self
			element.onClickCallback = self.onLeftButtonClicked
			self:setDisabled(self.disabled)
		elseif table.getn(self.elements) == 2 then
			-- right button
			self.rightButtonElement = element
			self.rightButtonElement.forceHighlight = true
			element.target = self
			element:setHandleFocus(false)
			element.onClickCallback = self.onRightButtonClicked
			self:setDisabled(self.disabled)
		elseif table.getn(self.elements) == 3 then
			self.textElement = element
			self:updateTextElement()
		elseif table.getn(self.elements) == 4 then
			self.labelElement = element
		end
	end

	function NumberUpDownElement:onRightButtonClicked(steps, noFocus)
		if steps == nil then steps = 1 end
		if steps ~= nil and type(steps) ~= "number" then steps = 1 end
		for i = 1, steps do
			if self.max ~= nil and (self.value + self.increment) > self.max then
				self.value = self.max
			else
				self.value = self.value + self.increment
			end
			if self.value < 0.009 and self.value > -0.009 then
				self.value = 0
			end
		end
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.SLIDER)
		self:setSoundSuppressed(true)
		FocusManager:setFocus(self)
		self:setSoundSuppressed(false)
		self:updateTextElement()
		self:raiseCallback("onClickCallback", self.value, self)
		if (noFocus == nil or not noFocus) then
			if self.leftButtonElement ~= nil then
				self.leftButtonElement:onFocusEnter()
			end
			if self.rightButtonElement ~= nil then
				self.rightButtonElement:onFocusEnter()
			end
		end
	end

	function NumberUpDownElement:onLeftButtonClicked(steps, noFocus)
		
		if steps == nil then steps = 1 end
		if steps ~= nil and type(steps) ~= "number" then steps = 1 end
		for i = 1, steps do
			if self.min ~= nil and self.value - self.increment < self.min then
				self.value = self.min
			else
				self.value = self.value - self.increment
			end
			if self.value < 0.009 and self.value > -0.009 then
				self.value = 0
			end
		end
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.SLIDER)
		self:setSoundSuppressed(true)
		FocusManager:setFocus(self)
		self:setSoundSuppressed(false)
		self:updateTextElement()
		self:raiseCallback("onClickCallback", self.state, self)
		if (noFocus == nil or not noFocus) then
			if self.leftButtonElement ~= nil then
				self.leftButtonElement:onFocusEnter()
			end
			if self.rightButtonElement ~= nil then
				self.rightButtonElement:onFocusEnter()
			end
		end
	end

	function NumberUpDownElement:disableButtonSounds()
		if self.leftButtonElement ~= nil then
			self.leftButtonElement:disablePlaySample()
		end
		if self.rightButtonElement ~= nil then
			self.rightButtonElement:disablePlaySample()
		end
	end

	function NumberUpDownElement:setLabel(labelString)
		self.labelElement.setText(labelString)
	end

	function NumberUpDownElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
		if self:getIsActive() then
			if NumberUpDownElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
				eventUsed = true
			end
			
			if not eventUsed and not self.forceHighlight and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], nil) then
				if not self.mouseEntered and not self.focusActive then
					FocusManager:setHighlight(self)
					self.mouseEntered = true
				end
			else
				if self.mouseEntered and not self.focusActive then
					FocusManager:unsetHighlight(self)
					self.mouseEntered = false
				end
			end
			
		end
		return eventUsed
	end

	function NumberUpDownElement:inputEvent(action, value, eventUsed)
		eventUsed = NumberUpDownElement:superClass().inputEvent(self, action, value, eventUsed)
		
		if not eventUsed then
			if action == InputAction.MENU_AXIS_LEFT_RIGHT then
				if value < -g_analogStickHTolerance then
					eventUsed = true
					self:inputLeft(false)
				elseif value > g_analogStickHTolerance then
					eventUsed = true
					self:inputRight(false)
				end
			elseif action == InputAction.MENU_PAGE_PREV then
				eventUsed = true
				self:inputLeft(true)
			elseif action ==  InputAction.MENU_PAGE_NEXT then
				eventUsed = true
				self:inputRight(true)
			end
		end
		
		return eventUsed
	end

	function NumberUpDownElement:update(dt)
		if self.leftDelayTime ~= nil and self.leftDelayTime > 0 then
			self.leftDelayTime = self.leftDelayTime - dt
			if self.leftDelayTime < 0 then
				self.leftDelayTime = 0;
			end
		end
		if self.rightDelayTime ~= nil and self.rightDelayTime > 0 then
			self.rightDelayTime = self.rightDelayTime - dt
			if self.rightDelayTime < 0 then
				self.rightDelayTime = 0;
			end
		end
	end

	function NumberUpDownElement:inputLeft(isShoulderButton)
		if self.leftDelayTime == 0 then
			if self.buttonLRChange then
				if isShoulderButton then
					self.leftButtonElement:onFocusActivate()
					self.leftDelayTime = self.scrollDelayDuration
				end
			else
				self.leftButtonElement:onFocusActivate()
				self.leftDelayTime = self.scrollDelayDuration
			end
		end
	end

	function NumberUpDownElement:inputRight(isShoulderButton)
		if self.rightDelayTime == 0 then
			if self.buttonLRChange then
				if isShoulderButton then
					self.rightButtonElement:onFocusActivate()
					self.rightDelayTime = self.scrollDelayDuration
				end
			else
				self.rightButtonElement:onFocusActivate()
				self.rightDelayTime = self.scrollDelayDuration
			end
		end
	end

	function NumberUpDownElement:canReceiveFocus(element, direction)
		return not self.disabled and self:getIsVisible()
	end

	function NumberUpDownElement:onFocusLeave()
		NumberUpDownElement:superClass().onFocusLeave(self)
		
		self:raiseCallback("onLeaveCallback", self)
		
		if self.rightButtonElement ~= nil and self.rightButtonElement.state ~= GuiOverlay.STATE_NORMAL then
			self.rightButtonElement:onFocusLeave()
		end
		if self.leftButtonElement ~= nil and self.leftButtonElement.state ~= GuiOverlay.STATE_NORMAL then
			self.leftButtonElement:onFocusLeave()
		end
	end

	function NumberUpDownElement:onFocusEnter()
		NumberUpDownElement:superClass().onFocusEnter(self)
		
		if self.rightButtonElement ~= nil and self.rightButtonElement.state ~= GuiOverlay.STATE_FOCUSED then
			self.rightButtonElement:onFocusEnter()
		end
		if self.leftButtonElement ~= nil and self.leftButtonElement.state ~= GuiOverlay.STATE_FOCUSED then
			self.leftButtonElement:onFocusEnter()
		end
		self:raiseCallback("onFocusCallback", self)
		
	end

	function NumberUpDownElement:onHighlight()
		NumberUpDownElement:superClass().onHighlight(self)
		
		if self.rightButtonElement ~= nil and self.rightButtonElement:getOverlayState() == GuiOverlay.STATE_NORMAL then
			self.rightButtonElement:setOverlayState(GuiOverlay.STATE_HIGHLIGHTED)
		end
		if self.leftButtonElement ~= nil and self.leftButtonElement:getOverlayState() == GuiOverlay.STATE_NORMAL then
			self.leftButtonElement:setOverlayState(GuiOverlay.STATE_HIGHLIGHTED)
		end
	end

	function NumberUpDownElement:onHighlightRemove()
		NumberUpDownElement:superClass().onHighlightRemove(self)
		
		if self.rightButtonElement ~= nil and self.rightButtonElement:getOverlayState() == GuiOverlay.STATE_HIGHLIGHTED then
			self.rightButtonElement:setOverlayState(GuiOverlay.STATE_NORMAL)
		end
		if self.leftButtonElement ~= nil and self.leftButtonElement:getOverlayState() == GuiOverlay.STATE_HIGHLIGHTED then
			self.leftButtonElement:setOverlayState(GuiOverlay.STATE_NORMAL)
		end
	end

	function NumberUpDownElement:updateTextElement()
		if self.textElement ~= nil then
			if self.value ~= nil then
				self.textElement:setText(tostring(self.value))
			else
				self.textElement:setText("")
			end
		end
	end

	function NumberUpDownElement:getValue()
		return self.value
	end

	function NumberUpDownElement:setValue(value, forceEvent)
		if value ~= nil and type(value) == "number" then
			if self.min ~= nil then
				value = math.max(value, self.min)
			end
			if self.max ~= nil then
				value = math.min(value, self.max)
			end
			self.value = value
			self:updateTextElement()
			
			if forceEvent then
				self:raiseCallback("onClickCallback", self.state, self)
			end
		end
	end

	function NumberUpDownElement:getIncrement()
		return self.increment
	end

	function NumberUpDownElement:setIncrement(increment)
		if increment ~= nil and type(increment) == "number" and increment > 0 then
			self.increment = increment
		end
	end

	function NumberUpDownElement:getMin()
		return self.min
	end

	function NumberUpDownElement:setMin(minValue)
		if minValue ~= nil and type(minValue) == "number" and (self.max == nil or minValue < self.max) then
			self.min = minValue
			if self.value < minValue then
				self:setValue(self.min, true)
				self:updateTextElement()
			end
		else
			self.min = nil
		end
	end

	function NumberUpDownElement:getMax()
		return self.max
	end

	function NumberUpDownElement:setMax(maxValue)
		if maxValue ~= nil and type(maxValue) == "number" and (self.min == nil or maxValue > self.min) then
			self.max = maxValue
			if self.value > maxValue then
				self.value = maxValue
				self:updateTextElement()
			end
		else
			self.max = nil
		end
	end

	mapping["numberUpDown"] = NumberUpDownElement
end