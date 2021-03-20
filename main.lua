local json = require("json")
local board = require("cardgame")

local _STATES = {LOADING = 1, MAIN_MENU = 2, DECK_BUILDER = 3}
local _state = _STATES.LOADING

local _resources = {}

local _transients = {}

local _layers = {}
_layers[1] = {}

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
            local cardRefName = card.name:lower():gsub("-","_"):gsub(" ","_")
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

_inits[_STATES.MAIN_MENU] = function()
    _layers[1] = {}
    _layers[2] = {} -- button layer

    local function buttonOnMouseEnter(self)
        self.colour = {r = 1, g = 0, b = 0}
    end

    local function buttonOnMouseLeave(self)
        self.colour = {r = 1, g = 1, b = 1}
    end

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
    _layers = {}
    _layers[1] = {}
    _layers[2] = {}
    local i = 0
    for k,v in pairs(_resources.cardImages) do
        local cardimg = board.Object:new{
            drawable = v,
            x = 50 + 90*(i%3),
            y = 50 + 140*math.floor(i/3),
            sx = 0.1,
            sy = 0.1,
            onMouseEnter = function(self)
                self.sx = 0.12
                self.sy = 0.12
            end,
            onMouseLeave = function(self)
                self.sx = 0.1
                self.sy = 0.1
            end
        }
        i=i+1
        table.insert(_layers[1], cardimg)
    end
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