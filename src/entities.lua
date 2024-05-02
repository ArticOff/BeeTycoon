local math = require("math")
local class = require("middleclass")
local beholder = require("beholder")

local function DegreeToRadian(x)
    return x * (math.pi / 180)
end

math.randomseed(os.time())
local lshift = false

beholder.observe("lshift", function(pressed)
    lshift = pressed
end)

local function truncate(statement, n)
    if #statement > n then
        return statement:sub(1, n) .. "..."
    else
        return statement
    end
end

local font = love.graphics.newFont("fonts/RisingSun-Heavy.otf", 16)
local honey = love.graphics.newImage("images/honey2.png")
local sbutton = love.graphics.newImage("images/settings.png")
local shbutton = love.graphics.newImage("images/shop.png")





-- Bee
local Bee = class("Bee")

function Bee:initialize(x, y)
    self.speed = 1
    self.capacity = 1
    self.inventory = {}
    self.image = love.graphics.newImage("images/bee.png")
    self.x = x
    self.y = y
    self.orientation = 0
    self._y = 0
    self._x = 1
    self.game = false
    self.target = 1150
end

function Bee:draw()
    if self.orientation == 180 then
        self._y = 32
    else
        self._y = 0
    end
    if self.game then
        self._x = self.x * 120 / 1150
    else
        self._x = 0
    end
    love.graphics.draw(
        self.image,
        self.x,
        (self.y + 5 * math.sin(self.x / 5) + self._y) + self._x, -- y = 5 * sin(x / 5)
        DegreeToRadian(self.orientation + 45)
    )
    for index, honey in ipairs(self.inventory) do
        love.graphics.draw(
            honey.image,
            self.x - 15,
            (self.y - index * 5) + (5 * math.sin(self.x / 5)) + self._x
        )
    end
end

function Bee:go()
    if self.target then
        if self.x < self.target then
            self.x = self.x + self.speed
            self.orientation = 0
        else
            self.x = self.x - self.speed
            self.orientation = 180
        end 
    end
end

function Bee:take(honey)
    if #self.inventory >= self.capacity then
        return
    end
    table.insert(self.inventory, honey)
end

function Bee:drop()
    beholder.trigger("drop", self.inventory)
    self.inventory = {}
end





-- Honey
local Honey = class("Honey")

function Honey:initialize()
    self.value = 1
    self.image = honey
    self.x = 0
    self.y = 0
end







-- Game
local Game = class("Game")

function Game:initialize()
    self.page = nil
    self.money = 0
    self.gem = 0
    self._showfps = false
end

function Game:draw()
    self.page:draw()
end

function Game:update(...)
    self.page:update(...)
end

function Game:load()
    self.page:load()
end





-- Page
local Page = class("Page")

function Page:initialize(f, f2)
    self.elements = f
    self.u = f2
    self.Inputs = {}
end

function Page:draw()
    self.elements()
end

function Page:update()
    if self.u then
        self.u() 
    end
end



-- Button
local Button = class("Button")

function Button:initialize(text, f)
    self.text = text
    self.x = nil
    self.y = nil
    self.image = love.graphics.newImage("images/button.png")
    self.width = nil
    self.height = nil
    self.f = f
    self.squared = false
    self.hover = nil
    self.hovered = false
end

function Button:draw(x, y)
    self.x = x
    self.y = y
    if self.squared then
        love.graphics.setColor(1, 1, 1, 1)
        if self.shop then
            love.graphics.draw(shbutton, self.x, self.y)
        else
            love.graphics.draw(sbutton, self.x, self.y) 
        end
        self.width = sbutton:getWidth()
        self.height = sbutton:getHeight()
    else
        self.width = self.image:getWidth()
        self.height = self.image:getHeight()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.image, self.x, self.y)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(self.text, font, self.x, self.y + (self.height - font:getHeight()) / 2, self.width, "center")
    end
end

function Button:click(x, y)
    if not (self.x or self.y) then
        return
    end
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        self.f()
    end 
end

function Button:update()
    if not (self.x and self.y) then
        return
    end
    local x, y = love.mouse.getPosition()
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        if self.hover then
            self.hover()
        end
        self.hovered = true
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
        self.hovered = false
    end
end







-- Input
local Input = class("Input")

function Input:initialize(placeholder, width, height)
    self.placeholder = placeholder
    self.value = ""
    self.x = nil
    self.y = nil
    self.width = width
    self.height = height
    self.focus = false -- si l'input est "focus"
    self.color = {1, 1, 1, 1}
    self.hover = false
    self.mX = nil
    self.MY = nil
end

function Input:draw(x, y)
    self.x = x
    self.y = y
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    if self.value == "" then
        love.graphics.setColor(0, 0, 0, .5)
        love.graphics.printf(self.placeholder, font, self.x, self.y + (self.height - font:getHeight()) / 2, self.width, "center")
    else
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(truncate(self.value, 10), font, self.x, self.y + (self.height - font:getHeight()) / 2, self.width, "center")
    end
    if self.hover and not (self.value == "") then
        love.graphics.setColor(0, 0, 0, .5)
        love.graphics.rectangle("fill", self.mX, self.mY, 200, -50)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(self.value, font, self.mX, self.mY - (self.height + font:getHeight()) / 2, 200, "center")
    end
end

function Input:click(x, y)
    if not (self.x and self.y) then
        return
    end
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        beholder.trigger("empty")
        self.focus = not self.focus
    else
        self.focus = false
    end
    if not self.focus then
        self.color = {1, 1, 1, 1}
    end
end

function Input:update()
    if not (self.x and self.y) then
        return
    end
    local x, y = love.mouse.getPosition()
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        self.hover = true
        self.mX, self.mY = x, y
        if self.focus then
            self.color = {.5, 1, .5, .5}
            love.mouse.setCursor(love.mouse.getSystemCursor("ibeam"))
        else
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        end
    else
        self.hover = false
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end
    beholder.observe("text", function(text)
        if self.focus then
            self.value = text
        end
    end)
    beholder.observe("unfocus", function()
        if self.focus then
            self.focus = false
            self.color = {1, 1, 1, 1}
        end
    end)
end





-- Frame
local Frame = class("Frame")
function Frame:initialize(fd, fu)
    self.fd = fd
    self.fu = fu
    self.x = nil
    self.y = nil
    self.width = nil
    self.height = nil
end

function Frame:draw(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    love.graphics.setColor(0, 0, 0, .5)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(1, 1, 1, 1)
    self.fd(x, y)
end

function Frame:update()
    if self.fu then
        self.fu() 
    end
end





-- Cloud
local Cloud = class("Cloud")
function Cloud:initialize()
    self.x = math.random(-50, 449)
    self.y = math.random(1, 100)
    self.speed = (math.random() / 3) - (math.random() / 3)
    self.image = love.graphics.newImage("images/cloud.png")
end

function Cloud:draw()
    love.graphics.scale(3, 3)
    love.graphics.draw(self.image, self.x, self.y)
    love.graphics.scale(1/3, 1/3)
end

function Cloud:update()
    self.x = self.x + self.speed
    if self.x >= 450 then
        self.x = -50
    elseif self.x <= -50 then
        self.x = 450
    end
end





-- Grass
local Grass = class("Grass")
function Grass:initialize()
    self.x = math.random(0, 1280)
    self.y = 508
    self.image = love.graphics.newImage("images/grass.png")
end

function Grass:draw()
    love.graphics.draw(self.image, self.x, self.y)
end






-- Chest
local Chest = class("Chest")
function Chest:initialize(items, f)
    self.items = items
    self.x = nil
    self.y = nil
    self.mX = nil
    self.mY = nil
    self.hover = nil
    self.hovered = false
    self.c = false
    self.f = f
    self.image = love.graphics.newImage("images/chest.png")
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.probs = {}
    for index, item in ipairs(self.items) do
        if self.probs[item.name] then
            self.probs[item.name] = self.probs[item.name] + 1
        else
            table.insert(self.probs, item.name)
            self.probs[item.name] = 1
        end
    end
end
function Chest:draw(x, y)
    self.x = x
    self.y = y
    love.graphics.draw(self.image, x, y)
    if self.hovered then
        love.graphics.setColor(0, 0, 0, .5)
        love.graphics.rectangle("fill", self.mX, self.mY, 200, -(25 + #self.probs * 15))
        love.graphics.setColor(1, 1, 1, 1)
        for index, item in ipairs(self.probs) do
            love.graphics.print(tostring(self.probs[item]) .. "% " .. item, font, self.mX + 10, self.mY - 10 - index * 16)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
end
function Chest:update()
    
    if not (self.x and self.y) then
        return
    end
    local x, y = love.mouse.getPosition()
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        self.mX = x
        self.mY = y
        if self.hover then
            self.hover()
        end
        self.hovered = true
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
        self.hovered = false
    end
    self.c = false
end
function Chest:click(x, y)
    if not (self.x or self.y) then
        return
    end
    if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
        if lshift then
            for i = 1, 10, 1 do
                self.f(self)
                if self.c then
                    local item = self.items[math.random(1, #self.items)]
                    beholder.trigger("claim", item, true) 
                end
                self.c = false 
            end
        else
            self.f(self)
            if self.c then
                local item = self.items[math.random(1, #self.items)]
                beholder.trigger("claim", item) 
            end
            self.c = false
        end
    end
end
-- function Chest:click2(x, y)
--     if not (self.x or self.y) then
--         return
--     end
--     if x > self.x and x < self.x + self.width and y > self.y and y < self.y + self.height then
--         for i = 1, 10, 1 do
--             self.f(self)
--             if self.c then
--                 local item = self.items[math.random(1, #self.items)]
--                 beholder.trigger("claim", item, true) 
--             end
--             self.c = false 
--         end
--     end
-- end





--[[
local i = 1

local function ephemeral(text, x, y)
    if i >= 10 then
        i = 1
        return
    end
    love.graphics.setColor(1, 1, 1, 1/i)
    love.graphics.print(text, font, x, y - i * 2)
    love.graphics.setColor(1, 1, 1, 1)
    i = i + .1
end
]]





local entities = {}

entities.Bee = Bee
entities.Honey = Honey
entities.Game = Game
entities.Page = Page
entities.Button = Button
entities.Input = Input
entities.Frame = Frame
entities.Cloud = Cloud
entities.Grass = Grass
entities.Chest = Chest

return entities
