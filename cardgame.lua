local board = {}

board.Object = {
    colour = {r = 1, g = 1, b = 1},
    x = 0,
    y = 0,
    sx = 1,
    sy = 1,
    isMouseIn = false,
    onMouseEnter = nil,
    onMouseLeave = nil,
    onLeftClick = nil,
    draw = function(self)
        if self.drawable then
            love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b)
            love.graphics.draw(self.drawable, self.x or 0, self.y or 0, 0, self.sx or 1, self.sy or 1)
        end
    end
}

function board.Object:new(arg)
    local ret = arg or {}
    setmetatable(ret, self)
    self.__index = self

    return ret
end

function board.Object:checkCollide()
    if not self.drawable then return end
    local mx, my = love.mouse.getPosition()
    --print("mouse is at ("..mx..","..my..")")
    if self.x <= mx and mx <= self.x + self.drawable:getWidth()*self.sx and self.y <= my and my <= self.y + self.drawable:getHeight()*self.sy then
        if not self.isMouseIn and self.onMouseEnter then
            self:onMouseEnter()
        end
        self.isMouseIn = true

        -- TODO change this so there's not click issues in between states
        if love.mouse.isDown(1) and self.onLeftClick then
            self:onLeftClick()
        elseif love.mouse.isDown(2) and self.onRightClick then
            self:onRightClick()
        end

        return true
    else
        if self.isMouseIn and self.onMouseLeave then
            self:onMouseLeave()
        end
        self.isMouseIn = false
        return false
    end
end

function board.Object:setDrawable(drawable)
    self.drawable = drawable
end

board.CardData = {
    name = "",
    health = 0,
    attack = 0,
    speed = 0,
    defence = 0,
    magic = 0,
    cardtext = ""
}

board.Card = board.Object:new{cardData = nil}

function board.Card:new(arg)
    local ret = arg or board.Object:new()
    setmetatable(ret, self)
    self.__index = self

    return ret
end

function board.Card:getName()
    return self.cardData.name or "?"
end

function board.Card:getHealth()
    return self.cardData.health or -1
end

function board.Card:getAttack()
    return self.cardData.attack or -1
end

function board.Card:getSpeed()
    return self.cardData.speed or -1
end

function board.Card:getDefence()
    return self.cardData.defence or -1
end

function board.Card:getMagic()
    return self.cardData.magic or -1
end

function board.Card:getCardText()
    return self.cardData.cardtext or ""
end

return board