local json = require("json")
local board = require("cardgame")

local _STATES = {LOADING = 1, MAIN_MENU = 2, DECK_BUILDER = 3}
local _state = _STATES.LOADING

local _resources = {}

local _transients = {}

local _layers = {}
_layers[1] = {}

local function toRefName(name)
    return name:lower():gsub("-","_"):gsub(" ","_")
end

function love.draw()
    for _,layer in pairs(_layers) do
        for _,part in pairs(layer) do
            part:draw()
        end
    end

    local mx,my = love.mouse.getPosition()
    --love.graphics.print("("..mx..","..my..")",0,0)
end

-- redo love.run

local _inits = {}

_inits[_STATES.LOADING] = function()
    local w,h = love.window.getMode()
    local logo = board.Object:new{
        drawable = _resources.images["logo"],
        x = w/2 - (_resources.images["logo"]:getWidth()/2),
        y = h/4 - (_resources.images["logo"]:getHeight()/2)
    }

    table.insert(_layers[1], logo)
    local loadingTextObj = love.graphics.newText(_resources.fonts["default32"], "Loading")
    local loadingText = board.Object:new{
        drawable = loadingTextObj,
        x = w/2 - loadingTextObj:getWidth()/2,
        y = 5*h/8 - loadingTextObj:getHeight()/2
    }
    _layers[1].loadingtext = loadingText

    -- load card data
    local cardData = love.filesystem.read("res/grotto.json")
    local cardJson = json.decode(cardData).cards
    _transients.thingsToLoad = {}
    _resources.cardImages = {}
    _resources.cardData = {}
    local i = 1
    for _,card in pairs(cardJson) do
        table.insert(_transients.thingsToLoad, function()
            local cardRefName = toRefName(card.name)
            _resources.cardImages[cardRefName] = love.graphics.newImage("res/images/cards/"..cardRefName..".png")
            _resources.cardData[cardRefName] = card

            i = i + 1

            local loadingTextUpdObj = love.graphics.newText(_resources.fonts["default32"], "Loading "..i.."/"..#cardJson)
            loadingText:setDrawable(loadingTextUpdObj)

            _layers[1].loadingtext = loadingText
        end)
    end

    table.insert(_transients.thingsToLoad, function()
        stateTransition(_STATES.MAIN_MENU)
    end)
end

local function buttonOnMouseEnter(self)
    self.colour = {r = 1, g = 0, b = 0}
end

local function buttonOnMouseLeave(self)
    self.colour = {r = 1, g = 1, b = 1}
end

_inits[_STATES.MAIN_MENU] = function()
    _layers[1] = {}
    _layers[2] = {} -- button layer

    local w,h = love.window.getMode()

    local logo = board.Object:new{
        drawable = _resources.images["logo"],
        x = w/2 - (_resources.images["logo"]:getWidth()/2),
        y = h/4 - (_resources.images["logo"]:getHeight()/2),
    }
    table.insert(_layers[1], logo)

    local playButtonText = love.graphics.newText(_resources.fonts["default32"], "Play Grotto Beasts")
    local playButton = board.Object:new{
        drawable = playButtonText,
        x = w/2 - playButtonText:getWidth()/2,
        y = h/2 - playButtonText:getHeight()/2+60,
        onMouseEnter = buttonOnMouseEnter,
        onMouseLeave = buttonOnMouseLeave
    }
    table.insert(_layers[2], playButton)

    local deckButtonText = love.graphics.newText(_resources.fonts["default32"], "Deck Builder")
    local deckButton = board.Object:new{
        drawable = deckButtonText,
        x = w/2 - deckButtonText:getWidth()/2,
        y = h/2 - deckButtonText:getHeight()/2+120,
        onMouseEnter = buttonOnMouseEnter,
        onMouseLeave = buttonOnMouseLeave,
        onLeftClick = function()
            stateTransition(_STATES.DECK_BUILDER)
        end
    }
    table.insert(_layers[2], deckButton)

    local exitButtonText = love.graphics.newText(_resources.fonts["default32"], "Exit")
    local exitButton = board.Object:new{
        drawable = exitButtonText,
        x = w/2 - exitButtonText:getWidth()/2,
        y = h/2 - exitButtonText:getHeight()/2+180,
        onMouseEnter = buttonOnMouseEnter,
        onMouseLeave = buttonOnMouseLeave
    }
    table.insert(_layers[2], exitButton)
end

_inits[_STATES.DECK_BUILDER] = function()
    _transients.scrollVel = 0
    _transients.deckFreq = {}
    local layerNames = {CARD_LIST = 1, FOCUSED_CARD = 2, DECK_ZONE = 3, DECK_FOREGROUND = 4, PICKED_CARD = 5, BUTTONS = 6}
    _transients.layerNames = layerNames
    _layers = {}
    _layers[layerNames.CARD_LIST] = {}
    _layers[layerNames.FOCUSED_CARD] = {}
    _layers[layerNames.DECK_ZONE] = {}
    _layers[layerNames.PICKED_CARD] = {}
    _layers[layerNames.BUTTONS] = {}
    _layers[layerNames.DECK_ZONE][1] = board.Card:new{
        draw = function()
            love.graphics.print("Deck", 350, 20)
            love.graphics.print("List",660,20)
            love.graphics.setColor(0.1,0.1,0.1)
            love.graphics.rectangle("fill", 350, 40, 300, 500)
        end
    }
    local i = 0
    for k,v in pairs(_resources.cardData) do
        local cardimg = board.Card:new{
            cardData = v,
            drawable = _resources.cardImages[k],
            x = 800,
            y = 50 + 80*i,
            sx = 0.07,
            sy = 0.07,
            onMouseEnter = function(self)
                local theCard = board.Card:new{
                    drawable = _resources.cardImages[k],
                    x = 20,
                    y = 20,
                    sx = 0.4,
                    sy = 0.4,
                    cardData = v
                }
                _layers[layerNames.FOCUSED_CARD][1] = theCard

                _layers[layerNames.FOCUSED_CARD][2] = board.Object:new{
                    drawable = love.graphics.newText(_resources.fonts["default"], v.name),
                    x = 20,
                    y = 450
                }

                _layers[layerNames.FOCUSED_CARD][3] = board.Object:new{
                    drawable = love.graphics.newText(_resources.fonts["default"], theCard:getStatsString()),
                    x = 20,
                    y = 470
                }
                _layers[layerNames.FOCUSED_CARD][4] = board.Object:new{
                    x = 20,
                    y = 490,
                    draw = function(self)
                        love.graphics.printf(v.cardtext or "", self.x, self.y, 350)
                    end
                }
            end,
            onLeftClick = function(self)
                local mx,my = love.mouse.getPosition()
                _layers[layerNames.PICKED_CARD].pickedCard = board.Card:new{
                    cardData = v,
                    x = mx,
                    y = my,
                    sx = 0.07,
                    sy = 0.07,
                    drawable = _resources.cardImages[k]
                }
            end,
            onLeftRelease = function(self)
                local mx,my = love.mouse.getPosition()
                if 350 <= mx and mx <= 350+300 and 40 <= my and my <= 40+500 then
                    -- put it in da DECK
                    if not _transients.deckFreq[self:getName()] then _transients.deckFreq[self:getName()] = 0 end
                    if _transients.deckFreq[self:getName()] < 3 then
                        _layers[layerNames.PICKED_CARD] = {}
                        _transients.deckFreq[self:getName()] = _transients.deckFreq[self:getName()] + 1
                        print("oh yeah babey!! swag!!!!")
                    else
                        print("ThERE IS TO OFUCKING MANY!!!!!"..self:getName())
                        _layers[layerNames.PICKED_CARD] = {}
                    end
                else
                    -- KILL
                    print("a")
                    _layers[layerNames.PICKED_CARD] = {}
                end
            end,
            draw = function(self)
                love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b)
                love.graphics.draw(self.drawable, self.x or 0, self.y or 0, 0, self.sx or 1, self.sy or 1)

                love.graphics.print(v.name or "?", self.x+60, self.y)
                love.graphics.print(self:getStatsString(), self.x+60, self.y+20)
                
            end
        }
        i=i+1
        table.insert(_layers[layerNames.CARD_LIST], cardimg)
    end

    local saveButtonText = love.graphics.newText(_resources.fonts["default"], "Save")
    local saveButton = board.Object:new{
        drawable = saveButtonText,
        x = 600,
        y = 600,
        onMouseEnter = buttonOnMouseEnter,
        onMouseLeave = buttonOnMouseLeave,
        onLeftClick = function(self)
            local data = json.encode(_transients.deckFreq)
            print(data)
            love.filesystem.write("deck.json", data)
        end
    }
    _layers[layerNames.BUTTONS][1] = saveButton

    local loadButtonText = love.graphics.newText(_resources.fonts["default"], "Load")
    local loadButton = board.Object:new{
        drawable = loadButtonText,
        x = 540,
        y = 600,
        onMouseEnter = buttonOnMouseEnter,
        onMouseLeave = buttonOnMouseLeave,
        onLeftClick = function(self)
            local data = love.filesystem.read("deck.json")
            _transients.deckFreq = json.decode(data)
        end
    }
    _layers[layerNames.BUTTONS][2] = loadButton
end

local _updates = {}

_updates[_STATES.LOADING] = function()
    local loader = table.remove(_transients.thingsToLoad,1)
    if loader then loader() end
    return
end

_updates[_STATES.MAIN_MENU] = function()
    for _,button in pairs(_layers[2]) do
        button:checkCollide()
    end
end

_updates[_STATES.DECK_BUILDER] = function()
    for _,card in pairs(_layers[1]) do
        card:checkCollide()
        local x,y = card:getPos()
        card:setPos(x,y+_transients.scrollVel)
    end

    for _,part in pairs(_layers[_transients.layerNames.BUTTONS]) do
        part:checkCollide()
    end

    _layers[_transients.layerNames.DECK_FOREGROUND] = {}
    local i = 0
    for card,freq in pairs(_transients.deckFreq) do
        for j=1,freq do
            local cardDisp = board.Object:new{
                drawable = _resources.cardImages[toRefName(card)],
                x = 360+55*(i%5),
                y = 50+75*math.floor(i/5),
                sx = 0.07,
                sy = 0.07
            }
            i = i + 1
            table.insert(_layers[_transients.layerNames.DECK_FOREGROUND], cardDisp)
            table.insert(_layers[_transients.layerNames.DECK_FOREGROUND], board.Object:new{
                drawable = love.graphics.newText(_resources.fonts["default"],card),
                x = 660,
                y = 50 + 15 * i
            })
        end
    end

    _transients.scrollVel = _transients.scrollVel * 0.8
    if math.abs(_transients.scrollVel) < 0.5 then _transients.scrollVel = 0 end

    if _layers[_transients.layerNames.PICKED_CARD].pickedCard then
        local mx,my = love.mouse.getPosition()
        _layers[_transients.layerNames.PICKED_CARD].pickedCard:setPos(mx,my)
    end
end

local _scrollCallbacks = {}
_scrollCallbacks[_STATES.DECK_BUILDER] = function(s)
    if not _transients.scrollVel then _transients.scrollVel = 0 end
    for k,v in pairs(_layers[1]) do
        _transients.scrollVel = _transients.scrollVel + s
    end
end

function stateTransition(state)
    _transients = {}
    if _inits[state] then _inits[state]() end
    _state = state
end

function love.load()
    _resources.images = {}
    _resources.fonts = {}

    _resources.images["logo"] = love.graphics.newImage("res/images/grottobeasts.png")

    _resources.fonts["default"] = love.graphics.newFont("res/fonts/NotoMono-Regular.ttf")
    _resources.fonts["default32"] = love.graphics.newFont("res/fonts/NotoMono-Regular.ttf", 32)
    love.graphics.setFont(_resources.fonts["default"])

    stateTransition(_STATES.LOADING)
end

function love.wheelmoved(x,y)
    if _scrollCallbacks[_state] then _scrollCallbacks[_state](y) end
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		--if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
        if _updates[_state] then _updates[_state](dt) end

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end