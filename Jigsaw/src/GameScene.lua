require("Image")

local fail_effect = "fail_effect.wav"
local sucess_effect = "sucess_effect.wav"

local GameScene = class("GameScene", function ()
	return cc.Scene:create()
end)

function GameScene:create()
    local scene = GameScene.new();
    
    scene:addChild(scene:createBackground())
    scene:addChild(scene:createMenu())
    scene:addChild(scene:createScore())
    
    scene:resetGame();
    
	return scene;
end

function GameScene:ctor()
    self.row = 5
    self.col = 4
    self.stepNum = 100

    self.state = nil
    
    self.previewSprite = nil
    self.gridLayer = nil
    self.gridInterval = 0
    self.stepLabel = nil
    self.step = 0
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()

    self:initGoalTable(self.row, self.col)
end

function GameScene:initGoalTable(row, col)
    self.goalTable = {}
    self.goalTable[1] = - 1
    for i = 2, row * col + 1 do
        self.goalTable[i] = i - 1
    end
end

function GameScene:playEffect(fileName)
	cc.SimpleAudioEngine:getInstance():playEffect(fileName)
end

function GameScene:createBackground()
    local bgLayer = cc.Layer:create()
    
	local bgSprite = cc.Sprite:create("background.png")
	bgSprite:setAnchorPoint(0.5, 0.5)
	
	local size = cc.Director:getInstance():getWinSize()
    bgSprite:setPosition(size.width / 2, size.height / 2)
    
    bgLayer:addChild(bgSprite)
    
    local power = cc.Label:createWithTTF("Powerd by cocos2d-x", "fonts/Marker Felt.ttf", 36)
    power:setAnchorPoint(0, 1)
    power:setPosition(65, size.height)
    bgLayer:addChild(power)
    return bgLayer
end

function GameScene:createMenu()
    local layerMenu = cc.Layer:create()
    
    local function menuCallbackStart()
        self:startGame()
    end
    
    local function menuCallbackReset()
        self:resetGame()
    end
	
    self.menuStartItem = cc.MenuItemImage:create("menuStart1.png", "menuStart2.png")
    local itemWidth = self.menuStartItem:getContentSize().width
    local itemHeight = self.menuStartItem:getContentSize().height
    
    self.menuStartItem:setAnchorPoint(1, 1)
    self.menuStartItem:setPosition(self.visibleSize.width, self.visibleSize.height)
    self.menuStartItem:registerScriptTapHandler(menuCallbackStart)
    
    self.menuRestartItem = cc.MenuItemImage:create("menuReset1.png", "menuReset2.png")
    self.menuRestartItem:setAnchorPoint(1, 1)
    self.menuRestartItem:setPosition(self.visibleSize.width, self.visibleSize.height)
    self.menuRestartItem:registerScriptTapHandler(menuCallbackReset)
    
    local menuTools = cc.Menu:create(self.menuStartItem, self.menuRestartItem)
    
    menuTools:setPosition(self.origin.x, self.origin.y)
    layerMenu:addChild(menuTools)
	
    return layerMenu
end

function GameScene:createScore()
    self.stepLabel = cc.Label:createWithTTF("Steps:0","fonts/Marker Felt.ttf", 48)
    
    return self.stepLabel
end

function GameScene:resetGame()
    -- choose a png
    self.fileName = "christmas.png";
    
    -- shown preview
    if self.previewSprite ~= nil then
        self.previewSprite:removeFromParent()
        self.previewSprite = nil
    end
    
    self.previewSprite = cc.Sprite:create(self.fileName)
    self.previewSprite:setAnchorPoint(0, 1)
    self.previewSprite:setScale(0.315)
    self.previewSprite:setPosition(65, self.origin.y + self.visibleSize.height - 65)
    self:addChild(self.previewSprite)
    
    self.gridRect = {x = 0, y = 0, width = 640, height = 800}
    self.gridOrigin = {x = (800 - self.gridRect.width) / 2, y = self.origin.y + 80}

    -- reset steps
    self.stepLabel:setAnchorPoint(0, 1)
    self.stepLabel:setPosition(self.visibleSize.width / 2 - 60, self.visibleSize.height - 65)
    self.step = 0
    self.stepLabel:setString("Steps:0")
    
    self.state = "ready"

    -- set start game buttuon title to start
    self.menuStartItem:setVisible(true)
    self.menuRestartItem:setVisible(false)
    
    local grids = {-1}
    for i = 2, self.row * self.col + 1 do
        grids[i] = i - 1
    end
    
    self:addChild(self:createGridLayer(grids))
end

function GameScene:startGame()
    self.state = "playing"
    
    -- set start game buttuon title to reset
    self.menuStartItem:setVisible(false)
    self.menuRestartItem:setVisible(true)
    
    self.randomOrderTable = Image.randomImageOrder(self.row, self.col, self.stepNum)
    self:addChild(self:createGridLayer(self.randomOrderTable))
end

function GameScene:getIndexByPoint(point)
    local region = {}
--    print("point is ", point.x ,point.y)
    for i = 1,self.row * self.col + 1 do
        if i == 1 then
            region.x = self.gridOrigin.x + (self.col - 1) * self.marginX
            region.y = self.gridOrigin.y + self.row * self.marginY
            region.right = region.x + self.marginX
            region.top = region.y  + self.marginY
        else
            region.x = self.gridOrigin.x + (i - 2) % self.col * self.marginX
            region.y = self.gridOrigin.y + (self.row - math.floor((i - 2) / self.col) - 1) * self.marginY
            region.right = region.x + self.marginX
            region.top = region.y  + self.marginY
        end
--        print("The ", i , " region is ", region.x , " ", region.y, " ", region.right, " ", region.top)
        if point.x >= region.x and point.y >= region.y and point.x <= region.right and point.y <= region.top then
            return i
        end
    end

    return -1
end

function GameScene:getSwitchIndex(index)
    if self.randomOrderTable == nil then
        return -1
    end
    if index == 1 then
--        print("current randomOrder ", self.randomOrderTable[self.col + 1], "col is ", self.col)
        if self.randomOrderTable[self.col + 1] == -1 then
            return self.col + 1
        end
    else
        -- left
        local leftIndex = index - 1
        if leftIndex % self.col ~= 1 and  self.randomOrderTable[leftIndex] == -1 then
            return leftIndex
        end

        -- bottomIndex
        local bottomIndex = index + self.col
        if bottomIndex <= self.row * self.col + 1 and self.randomOrderTable[bottomIndex] == -1  then
            return bottomIndex
        end

        -- rightIndex
        local rightIndex  = index + 1
        if ((self.col == 2 and rightIndex % 2 ~= 0) or (self.col ~= 2 and rightIndex % self.col ~= 2)) and self.randomOrderTable[rightIndex] == -1 then
            return rightIndex
        end

        -- topIndex
        local topIndex  = index - self.col
        if topIndex > 0 and self.randomOrderTable[topIndex] == -1 then
            return topIndex
        end

    end

    return -1
end

function GameScene:isSucess()
    if self.randomOrderTable == nil then
        return false
    end

    for i = 1, #self.randomOrderTable do
        if i == 1  then
            if self.randomOrderTable[i] ~= -1 then
                return false
            end
        elseif self.randomOrderTable[i] ~= i - 1 then
--            print("come in ", i)
            return false
        end
    end

    return true
end

function GameScene:popupSucessLayer()
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:pauseEventListenersForTarget(self, true)

    local colorLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 128))
    self:addChild(colorLayer, 99999)

    local function closePopUp(tag, sender)
        colorLayer:removeFromParent()
        eventDispatcher:resumeEventListenersForTarget(self, true)
        self:resetGame()
    end
    
    local winsize = cc.Director:getInstance():getWinSize()

    local successLabel = cc.Label:createWithTTF("Sucess!", "fonts/Marker Felt.ttf", 64)
    colorLayer:addChild(successLabel, 1)
    successLabel:setAnchorPoint(cc.p(0.5, 0.5))
    successLabel:setPosition( cc.p(winsize.width / 2, winsize.height / 2) )

    local stepsNum = string.format("Total Step Numbers:%d", self.step )
    local stepsLabel = cc.Label:createWithTTF(stepsNum, "fonts/Marker Felt.ttf", 32)
    stepsLabel:setAnchorPoint(cc.p(0.5, 0.5))
    stepsLabel:setPosition( cc.p(winsize.width / 2, winsize.height / 2 - successLabel:getContentSize().height - 20) )
    colorLayer:addChild(stepsLabel, 1)

    cc.MenuItemFont:setFontSize(60)
    local closeItem = cc.MenuItemFont:create("Close")
    closeItem:registerScriptTapHandler(closePopUp)
    closeItem:setPosition(winsize.width - 100, 50)
        
    local closeMenu = cc.Menu:create(closeItem)
    closeMenu:setAnchorPoint(cc.p(0.0, 0.0))
    closeMenu:setPosition(cc.p(0.0, 0.0))
        
    colorLayer:addChild(closeMenu)
end

function GameScene:createGridLayer(grids)
    -- delete gridLayer exist
    if self.gridLayer ~= nil then
        self.gridLayer:removeFromParent()
        self.gridLayer = nil
    end

    self.gridLayer = cc.Layer:create()
    self.randomSprite = {}

    -- get image frames
    local frames = Image.load(self.fileName, self.gridRect, self.row, self.col)
    self.marginX = self.gridRect.width / self.col
    self.marginY = self.gridRect.height / self.row
    
    -- draw them
    for i = 1, self.row * self.col + 1 do
        if grids[i] ~= -1 then
        
            ------------
            -- @type cc.Sprite:create()
            local sprite = frames[grids[i]]
            
            local pos = {x = 0, y = 0}
            
            if (i == 1) then
                pos.x = self.gridOrigin.x + (self.col - 1) * (self.marginX + self.gridInterval)
                pos.y = self.gridOrigin.y + self.row * (self.marginX + self.gridInterval)
            else
                pos.x = self.gridOrigin.x + (i - 2) % self.col * (self.marginX + self.gridInterval)
                pos.y = self.gridOrigin.y + (self.row - math.floor((i - 2) / self.col) - 1) * (self.marginY + self.gridInterval)
            end
            
            sprite:setAnchorPoint(0, 0)
            sprite:setPosition(pos)
            
            local size = sprite:getContentSize()
            self.gridLayer:addChild(sprite)
            self.randomSprite[i] = sprite
        else
            self.randomSprite[i] = nil
        end
    end

    local function onTouchBegan(touch, event)
        if self.randomOrderTable == nil then
            return false
        end
        local location = self.gridLayer:convertToNodeSpace(touch:getLocation())
        local index    = self:getIndexByPoint(location)
        if index == -1 then
            return false
        end
        local switchindex   = self:getSwitchIndex(index) 
        if switchindex == -1 then
--            print("can not switch,cur index is ", index)
            self:playEffect(fail_effect)
            return
        end

        --assert(self.randomSprite[index] ~= nil, "sprite is nil")
        
        self.step = self.step + 1
        self.stepLabel:setString("Steps:" .. self.step)
        self:playEffect(sucess_effect)
        if switchindex ~= 1 then
            self.randomSprite[index]:runAction(cc.MoveTo:create(0.2, cc.p(self.gridOrigin.x + (switchindex - 2) % self.col * self.marginX, self.gridOrigin.y + (self.row - math.floor((switchindex - 2) / self.col) - 1) * self.marginY)))
        else
            self.randomSprite[index]:runAction(cc.MoveTo:create(0.2, cc.p(self.gridOrigin.x + (self.col - 1) % self.col * self.marginX, self.gridOrigin.y + self.row * self.marginY)))
        end


        self.randomSprite[switchindex] = self.randomSprite[index]
        self.randomSprite[index] = nil

        self.randomOrderTable[switchindex] = self.randomOrderTable[index]
        self.randomOrderTable[index] = -1 

        if self:isSucess() then
            self:popupSucessLayer()
        end
        return false
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self.gridLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.gridLayer)
    
    return self.gridLayer
end

return GameScene;