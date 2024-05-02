local entities = require("entities")
local beholder = require("beholder")
local json = require("src.json")
local utf8 = require("utf8")

local pages = {}

local font = love.graphics.newFont("fonts/RisingSun-Heavy.otf", 16)
local subtitle = love.graphics.newFont("fonts/RisingSun-Heavy.otf", 32)
local title = love.graphics.newFont("fonts/RisingSun-Heavy.otf", 128)

local bee_speed_img = love.graphics.newImage("images/bee_speed.png")
local bee_capacity_img = love.graphics.newImage("images/bee_capacity.png")

local escape = false

local health = 10
local base_health = 10
local claimed = ""
local claimed_img = nil
local chest_hovered = false

local rb_speed = 1
local rb_capacity = 1

local function clouds()
    local clds = {}
    for i = 0, 4, 1 do
        table.insert(clds, entities.Cloud:new())
    end
    return clds
end

local function reverseEveryTwo(str)
    local result = ""
    for i = 1, #str, 2 do
        if i < #str then
            result = result .. str:sub(i+1, i+1) .. str:sub(i, i)
        else
            result = result .. str:sub(i, i)
        end
    end
    return result
end

local function grass()
    local grss = {}
    for i = 1, 10, 1 do
        table.insert(grss, entities.Grass:new())
    end
    return grss
end

local function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

local function simpleNumber(number)
    if number < 999 then
        return tostring(number)
    else
        local n1 = round(number / 1000, 1)
        if n1 < 999 then
            return tostring(n1) .. "k"
        else
            local n2 = round(n1 / 1000, 1)
            if n2 < 999 then
                return tostring(n2) .. "m"
            else
                local n3 = round(n2 / 1000, 1)
                if n3 < 999 then
                    return tostring(n3) .. "b"
                else
                    local n4 = round(n3 / 1000, 1)
                    return tostring(n4) .. "t"
                end
                
            end
        end
    end
end

local function bar_health(health)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 1100, 560, 100, 20)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.rectangle("fill", 1100, 560, (health * 100) / base_health, 20)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(simpleNumber(health), font, 1100, 560, 100, "center")
end

local function prob(t)
    local probs = {}
    for index, value in ipairs(t) do
        for i = 1, value.prob, 1 do
            table.insert(probs, value.object)
        end
    end
    return probs
end

local function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

local clds = clouds()
local grss = grass()
local _value = 1

local play = entities.Button:new("Play", function()
    beholder.trigger("page", pages.Game)
end)
local credits = entities.Button:new("Credits", function()
    beholder.trigger("page", pages.Credits)
end)
local quit = entities.Button:new("Quit", function()
    love.event.quit()
end)
local thanks = entities.Button:new("Thanks", function()
    beholder.trigger("page", pages.Thanks)
end)
-- local settings = entities.Button:new("Settings", function()
--     beholder.trigger("page", pages.Settings)
-- end)
local back = entities.Button:new("Back", function()
    beholder.trigger("page", pages.Menu)
end)
local backTtoC = entities.Button:new("Back", function()
    beholder.trigger("page", pages.Credits)
end)
local stat = entities.Button:new("Stats", function()
    beholder.trigger("page", pages.Stats)
end)
local backStoG = entities.Button:new("Back", function()
    beholder.trigger("page", pages.Game)
end)

local settings = entities.Button:new("Settings", function()
    escape = not escape
end)
settings.squared = true
local shop = entities.Button:new("Shop", function()
    beholder.trigger("page", pages.Shop)
end)
shop.squared = true
shop.shop = true

local money = 0
local _gem = 0

local price_speed = 1
local price_value = 1
local price_inventory = 1
local price_bee = 0

local color_speed = {1, 1, 1, 1}
local color_value = {1, 1, 1, 1}
local color_inventory = {1, 1, 1, 1}
local color_bee = {1, 1, 1, 1}
local color_rebirth = {1, 1, 1, 1}

local color_chest1 = {1, 1, 1, 1}
local color_chest2 = {1, 1, 1, 1}
local color_chest3 = {1, 1, 1, 1}

local flowers = {
    love.graphics.newImage("images/flower1.png"),
    love.graphics.newImage("images/flower2.png"),
    love.graphics.newImage("images/flower3.png"),
    love.graphics.newImage("images/flower4.png")
}
local function chose()
    return flowers[math.random(1, #flowers)]
end

local hive = love.graphics.newImage("images/hive.png")
local flower = chose()
local honey = love.graphics.newImage("images/honey.png") -- grand
local honey2 = love.graphics.newImage("images/honey2.png") -- petit
local gem = love.graphics.newImage("images/gem.png")

Bee = entities.Bee:new(100, 400)

local capacity = 0
local speed = 0

local claimed_list = {}

Bees = {}

local stat_honey = 0
local stat_flower = 0 -- stat_gem = stat_flower
local stat_rebirth = 0


local function addBee(bee)
    bee.speed = bee.speed * rb_speed
    bee.capacity = bee.capacity * rb_capacity
    table.insert(Bees, bee)
end

local reset = entities.Button:new("Reset", function()
    if not file_exists("BeeTycoon.dll") then
        return
    end
    local f = io.open("BeeTycoon.dll", "w+")
    f:write()
    f:close()
    price_speed = 1
    price_value = 1
    price_inventory = 1
    price_bee = 0
    Bees = {}
    rb_capacity = 1
    rb_speed = 1
    stat_honey = 0
    stat_flower = 0
    stat_rebirth = 0
    health = 10
    base_health = 10
    flower = chose()
    beholder.trigger("rebirth")
end)




local inc_speed = entities.Button:new("+1 speed", function()
    if money < price_speed then
        return
    end
    for index, bee in ipairs(Bees) do
        bee.speed = bee.speed + 1 
    end
    speed = speed + 1
    beholder.trigger("withdraw", price_speed)
    price_speed = price_speed * 3
end)
inc_speed.hover = function()
    if money < price_speed then
        color_speed = {1, 0, 0, 1}
    end
end
local inc_value = entities.Button:new("x2 value", function()
    if money < price_value then
        return
    end
    _value = _value * 2
    beholder.trigger("withdraw", price_value)
    price_value = price_value * 5
end)
inc_value.hover = function()
    if money < price_value then
        color_value = {1, 0, 0, 1}
    end
end
local inc_capacity = entities.Button:new("+1 capacity", function()
    if money < price_inventory then
        return
    end
    for index, bee in ipairs(Bees) do
        bee.capacity = bee.capacity + 1
    end
    capacity = capacity + 1
    beholder.trigger("withdraw", price_inventory)
    price_inventory = price_inventory * 2
end)
inc_capacity.hover = function()
    if money < price_inventory then
        color_inventory = {1, 0, 0, 1}
    end
end
local inc_bee = entities.Button:new("+1 bee", function()
    if _gem < price_bee then
        return
    end
    local b = entities.Bee:new(40, 360)
    b.target = 1150
    b.game = true
    b.speed = b.speed + speed
    b.capacity = b.capacity + capacity
    addBee(b)
    beholder.trigger("withdrawg", price_bee)
    price_bee = price_bee + 1
end)
inc_bee.hover = function()
    if _gem < price_bee then
        color_bee = {1, 0, 0, 1}
    end
end
local rebirth = entities.Button:new("Rebirth", function()
    if money < 1000000000000 then
        return
    end
    local f = io.open("BeeTycoon.dll", "w+")
    f:write()
    f:close()
    price_speed = 1
    price_value = 1
    price_inventory = 1
    price_bee = 0
    Bees = {}
    rb_capacity = rb_capacity + 1
    rb_speed = rb_speed + 1
    stat_honey = 0
    stat_flower = 0
    stat_rebirth = stat_rebirth + 1
    health = 10
    base_health = 10
    flower = chose()

    beholder.trigger("rebirth")
end)
rebirth.hover = function()
    if money < 1000000000000 then
        color_rebirth = {1, 0, 0, 1}
    end
end

local Escape = entities.Frame:new()
Escape.fd = function(x, y)
    love.graphics.print("Menu (Escape)", font, x + 50, y + 50)
    back.text = "Leave"
    back:draw(x + 50, y + 250)
    back.text = "Back"
    stat:draw(x + 50, y + 100)
    reset:draw(x + 50, y + 175)
end
Escape.fu = function()
    back:update()
    stat:update()
    reset:update()
end









pages.Menu = entities.Page:new()
pages.Menu.load = function()
    Bee.x = 100
    Bee.y = 400
    Bee.target = 1150
    escape = false
    Bee.game = false
    clds = clouds()
    grss = grass()
end
pages.Menu.draw = function()
    love.graphics.setColor(love.math.colorFromBytes(66, 147, 245))
    love.graphics.rectangle("fill", 0, 0, 1280, 540)
    love.graphics.setColor(love.math.colorFromBytes(77, 140, 50))
    love.graphics.rectangle("fill", 0, 540, 1280, 180)
    love.graphics.setColor(1, 1, 1, 1)
    for index, cloud in ipairs(clds) do
        cloud:draw()
    end
    for index, grs in ipairs(grss) do
        grs:draw()
    end
    love.graphics.print("BeeTycoon", title, 360, 100)
    love.graphics.print("Par Nolho et Artic", subtitle, 360, 260)
    play:draw(100, 100)
    -- settings:draw(100, 175)
    credits:draw(100, 175)
    quit:draw(100, 250)
    love.graphics.setColor(1, 1, 1, 1)
    Bee:draw()
end
pages.Menu.update = function()
    play:update()
    -- settings:update()
    credits:update()
    quit:update()
    Bee:go()
    if Bee.x >= Bee.target then
        Bee.target = 100
    elseif Bee.x <= Bee.target then
        Bee.target = 1150
    end
    for index, cloud in ipairs(clds) do
        cloud:update()
    end
end
pages.Menu.Inputs = {play, credits, quit} -- settings, 







pages.Game = entities.Page:new()
pages.Game.load = function()
    escape = false
    clds = clouds()
    grss = grass()
end
pages.Game.draw = function()
    love.graphics.setColor(love.math.colorFromBytes(66, 147, 245))
    love.graphics.rectangle("fill", 0, 0, 1280, 540)
    love.graphics.setColor(love.math.colorFromBytes(77, 140, 50))
    love.graphics.rectangle("fill", 0, 540, 1280, 180)
    inc_bee:draw(320, 600)
    inc_speed:draw(480, 600)
    inc_value:draw(640, 600)
    inc_capacity:draw(800, 600)
    rebirth:draw(160, 600)

    love.graphics.setColor(color_rebirth)
    love.graphics.print("1t Honey", font, 190, 675) -- rebirth
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(honey2, 160, 675)

    love.graphics.setColor(color_bee)
    love.graphics.print(simpleNumber(price_bee) .. " Gem", font, 355, 675) -- bee
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gem, 320, 670)

    love.graphics.setColor(color_speed)
    love.graphics.print(simpleNumber(price_speed) .. " Honey", font, 510, 675) -- speed
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(honey2, 480, 675)

    love.graphics.setColor(color_value)
    love.graphics.print(simpleNumber(price_value) .. " Honey", font, 670, 675) -- value
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(honey2, 640, 675)

    love.graphics.setColor(color_inventory)
    love.graphics.print(simpleNumber(price_inventory) .. " Honey", font, 830, 675) -- inventory
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(honey2, 800, 675)

    love.graphics.setColor(1, 1, 1, 1)
    for index, cloud in ipairs(clds) do
        cloud:draw()
    end
    for index, grs in ipairs(grss) do
        grs:draw()
    end
    love.graphics.scale(1.5, 1.5)
    love.graphics.draw(hive, 0, 210)
    love.graphics.scale(1/3, 1/3)
    love.graphics.draw(flower, 2220, 920)
    love.graphics.scale(2, 2)
    
    for index, bee in ipairs(Bees) do
        bee:draw()
    end
    love.graphics.draw(honey, 1080, 10)
    love.graphics.draw(gem, 900, 15)
    love.graphics.scale(1.5, 1.5)
    love.graphics.print(simpleNumber(money), font, 760, 12)
    love.graphics.print(simpleNumber(_gem), font, 630, 12)
    love.graphics.scale(2/3, 2/3)
    if escape then
        Escape:draw(100, 100, 230, 350)
    end
    bar_health(health)
    settings:draw(10, 10)
    shop:draw(50, 10)
end
pages.Game.update = function()
    for index, bee in ipairs(Bees) do
        bee:go()
        if bee.x >= 1150 then
            bee.target = 40
            for i = 1, bee.capacity, 1 do
                local h = entities.Honey:new()
                h.value = h.value * _value
                stat_honey = stat_honey + h.value
                bee:take(h)
                health = health - 1
                if health <= 0 then
                    flower = chose()
                    health = 2 * base_health + base_health
                    base_health = health
                    stat_flower = stat_flower + 1
                    beholder.trigger("gem")
                end
            end
        elseif bee.x <= 40 then
            bee.target = 1150
            bee:drop()
        end
    end
    inc_bee:update()
    inc_capacity:update()
    inc_value:update()
    inc_speed:update()
    rebirth:update()
    if not inc_bee.hovered then
        color_bee = {1, 1, 1, 1}
    end
    if not inc_capacity.hovered then
        color_inventory = {1, 1, 1, 1}
    end
    if not inc_value.hovered then
        color_value = {1, 1, 1, 1}
    end
    if not inc_speed.hovered then
        color_speed = {1, 1, 1, 1}        
    end
    if not rebirth.hovered then
        color_rebirth = {1, 1, 1, 1}
    end
    if escape then
        Escape:update()
    end
    for index, cloud in ipairs(clds) do
        cloud:update()
    end
    settings:update()
    shop:update()
end
pages.Game.Inputs = {inc_bee, inc_capacity, inc_value, inc_speed, rebirth, back, stat, reset, settings, shop}

beholder.observe("escape", function()
    escape = not escape
end)





pages.Credits = entities.Page:new()
pages.Credits.load = function()
    Bee.x = 100
    Bee.y = 400
    Bee.target = 1150
    clds = clouds()
    grss = grass()
    Bee.game = false
end
pages.Credits.draw = function()
    love.graphics.setColor(love.math.colorFromBytes(66, 147, 245))
    love.graphics.rectangle("fill", 0, 0, 1280, 540)
    love.graphics.setColor(love.math.colorFromBytes(77, 140, 50))
    love.graphics.rectangle("fill", 0, 540, 1280, 180)
    love.graphics.setColor(1, 1, 1, 1)
    for index, cloud in ipairs(clds) do
        cloud:draw()
    end
    for index, grs in ipairs(grss) do
        grs:draw()
    end
    love.graphics.print("Concepteur : Nolho", subtitle, 560, 100)
    love.graphics.print("Développeur : Artic", subtitle, 560, 150)
    love.graphics.print("Graphiste 2D : Nolho", subtitle, 560, 200)
    love.graphics.print("Pour la GameJam du serveur Les Sbires de Jhonny.", subtitle, 360, 300)
    back:draw(100, 100)
    thanks:draw(100, 175)
    love.graphics.setColor(1, 1, 1, 1)
    Bee:draw()
end
pages.Credits.update = function()
    back:update()
    thanks:update()
    Bee:go()
    if Bee.x >= Bee.target then
        Bee.target = 100
    elseif Bee.x <= Bee.target then
        Bee.target = 1150
    end
    for index, cloud in ipairs(clds) do
        cloud:update()
    end
end
pages.Credits.Inputs = {back, thanks}







pages.Thanks = entities.Page:new()
pages.Thanks.load = function()
    Bee.x = 100
    Bee.y = 400
    Bee.target = 1150
    escape = false
    clds = clouds()
    grss = grass()
    Bee.game = false
end
pages.Thanks.draw = function()
    love.graphics.setColor(love.math.colorFromBytes(66, 147, 245))
    love.graphics.rectangle("fill", 0, 0, 1280, 540)
    love.graphics.setColor(love.math.colorFromBytes(77, 140, 50))
    love.graphics.rectangle("fill", 0, 540, 1280, 180)
    love.graphics.setColor(1, 1, 1, 1)
    for index, cloud in ipairs(clds) do
        cloud:draw()
    end
    for index, grs in ipairs(grss) do
        grs:draw()
    end
    love.graphics.print("Love2d", subtitle, 560, 100)
    love.graphics.print("https://love2d.org", font, 560, 140)
    love.graphics.print("kikito (Enrique García Cota)", subtitle, 560, 200)
    love.graphics.print("https://github.com/kikito", font, 560, 240)
    love.graphics.print("rxi", subtitle, 560, 300)
    love.graphics.print("https://github.com/rxi", font, 560, 340)
    backTtoC:draw(100, 100)
    love.graphics.setColor(1, 1, 1, 1)
    Bee:draw()
end
pages.Thanks.update = function()
    backTtoC:update()
    Bee:go()
    if Bee.x >= Bee.target then
        Bee.target = 100
    elseif Bee.x <= 100 then
        Bee.target = 1150
    end
    for index, cloud in ipairs(clds) do
        cloud:update()
    end
end
pages.Thanks.Inputs = {backTtoC}







pages.Stats = entities.Page:new()
pages.Stats.load = function()
    Bee.x = 100
    Bee.y = 400
    Bee.target = 1150
    escape = false
    clds = clouds()
    grss = grass()
    Bee.game = false
end
pages.Stats.draw = function()
    love.graphics.setColor(love.math.colorFromBytes(66, 147, 245))
    love.graphics.rectangle("fill", 0, 0, 1280, 540)
    love.graphics.setColor(love.math.colorFromBytes(77, 140, 50))
    love.graphics.rectangle("fill", 0, 540, 1280, 180)
    love.graphics.setColor(1, 1, 1, 1)
    for index, cloud in ipairs(clds) do
        cloud:draw()
    end
    for index, grs in ipairs(grss) do
        grs:draw()
    end
    love.graphics.print("Rebirths : " .. simpleNumber(stat_rebirth), subtitle, 560, 100)
    love.graphics.print("Harvested honeys : " .. simpleNumber(stat_honey), subtitle, 560, 200)
    love.graphics.print("Defeated flowers : " .. simpleNumber(stat_flower), subtitle, 560, 300)
    love.graphics.print("Bees : " .. simpleNumber(#Bees), subtitle, 560, 400)
    backStoG:draw(100, 100)
    love.graphics.setColor(1, 1, 1, 1)
    Bee:draw()
end
pages.Stats.update = function()
    backStoG:update()
    Bee:go()
    if Bee.x >= Bee.target then
        Bee.target = 100
    elseif Bee.x <= 100 then
        Bee.target = 1150
    end
    for index, cloud in ipairs(clds) do
        cloud:update()
    end
end
pages.Stats.Inputs = {backStoG}





local bee2 = entities.Bee:new()
bee2.speed = (bee2.speed + speed) * 2
local bee3 = entities.Bee:new()
bee3.capacity = (bee3.capacity + capacity) * 2

-- 5k Honey
local pchest1 = prob({
    { object = { name = "1 Bee", n = 1, i = entities.Bee:new() },   prob = 1 },
    { object = { name = "1 Gem", n = 1, i = "gem" },                prob = 1 },
    { object = { name = "5k Honey", n = 5000, i = "money" },        prob = 12 },
    { object = { name = "2.5k Honey", n = 2500, i = "money" },      prob = 22 },
    { object = { name = "1k Honey", n = 1000, i = "money" },        prob = 32 },
    { object = { name = "Nothing", n = 0, i = "money" },            prob = 32 }
})
local chest1 = entities.Chest:new(pchest1, function(self)
    if money > 5000 then
        self.c = true
        beholder.trigger("withdraw", 5000)
    end
end)
chest1.hover = function()
    if money < price_speed then
        color_chest1 = {1, 0, 0, 1}
    end
end

-- 1 Gem
local pchest2 = prob({
    { object = { name = "1 Bee", n = 1, i = entities.Bee:new() },   prob = 10 },
    { object = { name = "25k Honey", n = 25000, i = "money" },      prob = 15 },
    { object = { name = "20k Honey", n = 20000, i = "money" },      prob = 20 },
    { object = { name = "10k Honey", n = 10000, i = "money" },      prob = 30 },
    { object = { name = "2 Gems", n = 2, i = "gem" },               prob = 10 },
    { object = { name = "1 Gem", n = 1, i = "gem" },                prob = 15 }
})
local chest2 = entities.Chest:new(pchest2, function(self)
    if _gem > 0 then
        self.c = true
        beholder.trigger("withdrawg", 1)
    end
end)
chest2.hover = function()
    if money < price_speed then
        color_chest2 = {1, 0, 0, 1}
    end
end

-- 5 Gem
local pchest3 = prob({
    { object = { name = "x2 speed", n = 2, i = "speed" },           prob = 1 },
    { object = { name = "x2 capacity", n = 2, i = "capacity" },     prob = 1 },
    { object = { name = "1 Bee (x2 speed)", n = 1, i = bee2 },      prob = 4 },
    { object = { name = "1 Bee (x2 capacity)", n = 2, i = bee3 },   prob = 4 },
    { object = { name = "1 Bee", n = 1, i = entities.Bee:new() },   prob = 15 },
    { object = { name = "50k Honey", n = 100000, i = "money" },     prob = 20 },
    { object = { name = "30k Honey", n = 30000, i = "money" },      prob = 25 },
    { object = { name = "10 Gems", n = 10, i = "gem" },             prob = 10 },
    { object = { name = "5 Gems", n = 5, i = "gem" },               prob = 20 }
})
local chest3 = entities.Chest:new(pchest3, function(self)
    if _gem > 4 then
        self.c = true
        beholder.trigger("withdrawg", 5)
    end
end)
chest3.hover = function()
    if money < price_speed then
        color_chest3 = {1, 0, 0, 1}
    end
end

pages.Shop = entities.Page:new()
pages.Shop.load = function()
    clds = clouds()
    grss = grass()
    claimed_img = nil
    claimed_list = {}
    claimed = ""
end
pages.Shop.draw = function()
    love.graphics.setColor(love.math.colorFromBytes(66, 147, 245))
    love.graphics.rectangle("fill", 0, 0, 1280, 540)
    love.graphics.setColor(love.math.colorFromBytes(77, 140, 50))
    love.graphics.rectangle("fill", 0, 540, 1280, 180)
    love.graphics.setColor(1, 1, 1, 1)
    for index, cloud in ipairs(clds) do
        cloud:draw()
    end
    for index, grs in ipairs(grss) do
        grs:draw()
    end
    backStoG:draw(100, 600)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(honey, 1080, 10)
    love.graphics.draw(gem, 900, 15)
    love.graphics.scale(1.5, 1.5)
    love.graphics.print(simpleNumber(money), font, 760, 12)
    love.graphics.print(simpleNumber(_gem), font, 630, 12)
    love.graphics.scale(2/3, 2/3)
    chest1:draw(300, 200)
    chest2:draw(600, 200)
    chest3:draw(900, 200)
    love.graphics.print("Left click : 1 chest", font, 10, 470)
    love.graphics.print("Shift + Left click : 10 chest", font, 10, 490)
    love.graphics.print("Tier 1 Chest", font, 300, 300)
    love.graphics.print("Tier 2 Chest", font, 600, 300)
    love.graphics.print("Tier 3 Chest", font, 900, 300)
    love.graphics.setColor(color_chest1)
    love.graphics.print("5k Honey", font, 335, 350)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setColor(color_chest2)
    love.graphics.print("1 Gem", font, 640, 350)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setColor(color_chest3)
    love.graphics.print("5 Gem", font, 940, 350)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.scale(2/3, 2/3)
    love.graphics.draw(honey, 445, 515)
    love.graphics.scale(1.5, 1.5)
    love.graphics.draw(gem, 600, 345)
    love.graphics.draw(gem, 900, 345)
    love.graphics.printf(claimed, subtitle, 0, 480, 1280, "center")
    if claimed_img then
        love.graphics.draw(claimed_img, (640 - subtitle:getWidth(claimed) / 2) - 30 - claimed_img:getWidth() / 2, 480) 
    end
    if #claimed_list > 0 and chest_hovered then
        local mX, mY = love.mouse.getPosition()
        love.graphics.setColor(0, 0, 0, .5)
        love.graphics.rectangle("fill", mX, mY, -200, -(25 + #claimed_list * 15))
        love.graphics.setColor(1, 1, 1, 1)
        for index, item in ipairs(claimed_list) do
            if claimed_list[item] > 1 then
                love.graphics.print(claimed_list[item] .. "x " .. item, font, mX - 190, mY - 10 - index * 16)
            else
                love.graphics.print(item, font, mX - 190, mY - 10 - index * 16)
            end
            
        end
        love.graphics.setColor(1, 1, 1, 1)
    elseif #claimed_list > 0 then
        claimed_list = {}
    end
end
pages.Shop.update = function()
    backStoG:update()
    chest1:update()
    chest2:update()
    chest3:update()
    if not chest1.hovered then
        color_chest1 = {1, 1, 1, 1}
    end
    if not chest2.hovered then
        color_chest2 = {1, 1, 1, 1}
    end
    if not chest3.hovered then
        color_chest3 = {1, 1, 1, 1}
    end
    for index, cloud in ipairs(clds) do
        cloud:update()
    end
    chest_hovered = chest1.hovered or chest2.hovered or chest3.hovered or chest3.hovered
end
pages.Shop.Inputs = {backStoG, chest1, chest2, chest3}







-- local vsync = entities.Input:new("", 100, 50)
-- vsync.value = "false"
-- local msaa = entities.Input:new("", 100, 50)
-- msaa.value = "0"
-- local fps = entities.Input:new("", 100, 50)
-- fps.value = "false"
-- local apply = entities.Button:new("Apply Changes", function()
--     local v = false
--     local m = nil
--     local s = false
--     if string.lower(vsync.value) == "true" then
--         v = true
--     end
--     m = tonumber(msaa.value)
--     if string.lower(fps.value) == "true" then
--         s = true
--     end
--     beholder.trigger("settings", {
--         love = {
--             vsync = v, msaa = m
--         },
--         game = {
--             fps = s
--         }
--     })
-- end)

-- pages.Settings = entities.Page:new()
-- pages.Settings.load = function()

-- end
-- pages.Settings.draw = function()
--     love.graphics.setBackgroundColor(love.math.colorFromBytes(10, 10, 10))
--     back:draw(100, 100)
--     apply:draw(100, 200)
--     love.graphics.setColor(1, 1, 1, 1)
--     love.graphics.print("vsync (true/false)", font, 300, 100)
--     vsync:draw(300, 130)
--     love.graphics.setColor(1, 1, 1, 1)
--     love.graphics.print("msaa (number)", font, 300, 200)
--     msaa:draw(300, 230)
--     love.graphics.setColor(1, 1, 1, 1)
--     love.graphics.print("Show FPS (true/false)", font, 300, 300)
--     fps:draw(300, 330)
-- end
-- pages.Settings.update = function()
--     back:update()
--     apply:update()
--     vsync:update()
--     msaa:update()
--     fps:update()
-- end
-- pages.Settings.Inputs = {back, apply, vsync, msaa, fps}

beholder.observe("mousepressed", function(x, y, button, page)
    if button == 1 then
        for index, value in ipairs(page.Inputs) do
            value:click(x, y)
        end
    end
    -- if button == 2 then
    --     for index, value in ipairs(page.Inputs) do
    --         if value.click2 then
    --             value:click2(x, y) 
    --         end
    --     end
    -- end
end)

beholder.observe("money", function(m)
    money = m
end)

beholder.observe("after", function(g)
    _gem = g
end)

beholder.observe("load", function()
    if not file_exists("BeeTycoon.dll") then
        return
    end
    local f = io.open("BeeTycoon.dll", "r")
    local content = f:read("a")
    if content ~= "" then
        local d = ""
        local decoded = reverseEveryTwo(content)
        for letters in decoded:gmatch(('.'):rep(3)) do
---@diagnostic disable-next-line: param-type-mismatch
            d = d .. utf8.char(tonumber(letters))
        end
        local data = json.decode(d)
        f:close()
        beholder.trigger("withdraw", -data.money)
        beholder.trigger("withdrawg", -data.gem)
        speed = data.speed
        capacity = data.capacity
        _value = data.value
        rb_speed = data.rb_speed
        rb_capacity = data.rb_capacity
        for index, bee in ipairs(data.bees) do
            local b = entities.Bee:new()
            b.speed = bee.speed
            b.capacity = bee.capacity
            b.target = bee.target
            b.game = true
            b.x = bee.x
            b.y = bee.y
            for index, honey in ipairs(bee.inventory) do
                local h = entities.Honey:new()
                h.value = honey
                b:take(h)
            end
            if bee.image == 1 then
                b.image = bee_speed_img
            elseif bee.image == 2 then
                b.image = bee_capacity_img
            end
            table.insert(Bees, b)
        end
        price_bee = data.price.bee
        price_speed = data.price.speed
        price_value = data.price.value
        price_inventory = data.price.inventory
        base_health = data.flower.base_health
        health = data.flower.health
        stat_flower = data.stat.flower
        stat_honey = data.stat.money
        stat_rebirth = data.stat.rebirth 
    end
end)

beholder.observe("save", function()
    if not file_exists("BeeTycoon.dll") then
        return
    end
    local bees = {}
    for index, bee in ipairs(Bees) do
        local inventory = {}
        local i = 0
        if bee.image == bee_speed_img then
            i = 1
        end
        if bee.image == bee_capacity_img then
            i = 2
        end
        for index, honey in ipairs(bee.inventory) do
            table.insert(inventory, honey.value)
        end
        table.insert(bees, {
            x = bee.x,
            y = bee.y,
            target = bee.target,
            speed = bee.speed,
            capacity = bee.capacity,
            inventory = inventory,
            image = i
        })
    end
    local f = io.open("BeeTycoon.dll", "w+")
    local j = json.encode({
        money = money,
        gem = _gem,
        value = _value,
        capacity = capacity,
        speed = speed,
        rb_speed = rb_speed,
        rb_capacity = rb_capacity,
        bees = bees,
        price = {
            bee = price_bee,
            speed = price_speed,
            value = price_value,
            inventory = price_inventory
        },
        flower = {
            base_health = base_health,
            health = health
        },
        stat = {
            flower = stat_flower,
            money = stat_honey,
            rebirth = stat_rebirth
        }
    })
    local codes = ""
    for index, value in utf8.codes(j) do
        codes = codes .. string.format("%03d", value)
    end
    f:write(reverseEveryTwo(codes))
    f:close()
end)

beholder.observe("claim", function(item, list)
    if list then
        if #claimed_list >= 10 then
            claimed_list = {}
        end
        if claimed_list[item.name] then
            claimed_list[item.name] = claimed_list[item.name] + 1
        else
            table.insert(claimed_list, item.name)
            claimed_list[item.name] = 1
        end
    else
        claimed = item.name
    end
    if (item.i == "speed") or (item.i == "capacity") then
        for index, bee in ipairs(Bees) do
            bee[item.i] = bee[item.i] * item.n
        end
        claimed_img = nil
    elseif (item.i == "money") or (item.i == "gem") then
        beholder.trigger("add", item.i, item.n)
        if item.i == "money" and item.n > 0 then
            claimed_img = love.graphics.newImage("images/honey.png")
        elseif item.n == 0 then
            claimed_img = nil
        else
            claimed_img = love.graphics.newImage("images/gem.png")
        end
    elseif item.name == "1 Bee (x2 speed)" then
        for i = 1, item.n, 1 do
            local b = entities.Bee:new()
            b.speed = (b.speed + speed) * 2
            b.capacity = b.capacity + capacity
            b.target = 1150
            b.game = true
            b.x = 40
            b.y = 360
            b.image = bee_speed_img
            addBee(b)
        end
        claimed_img = love.graphics.newImage("images/bee_speed.png")
    elseif item.name == "1 Bee (x2 capacity)" then
        for i = 1, item.n, 1 do
            local b = entities.Bee:new()
            b.speed = b.speed + speed
            b.capacity = (b.capacity + capacity) * 2
            b.target = 1150
            b.game = true
            b.x = 40
            b.y = 360
            b.image = bee_capacity_img
            addBee(b)
        end
        claimed_img = love.graphics.newImage("images/bee_capacity.png")
    else
        for i = 1, item.n, 1 do
            local b = entities.Bee:new()
            b.speed = b.speed + speed
            b.capacity = b.capacity + capacity
            b.target = 1150
            b.game = true
            b.x = 40
            b.y = 360
            addBee(b)
        end
        claimed_img = love.graphics.newImage("images/bee.png")
    end
    if list then
        claimed_img = nil
        claimed = ""
    end
end)

return pages
