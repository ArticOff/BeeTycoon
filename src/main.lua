local beholder = require("beholder")
local entities = require("entities")
local pages = require("pages")
local utf8 = require("utf8")

local Game = entities.Game:new()
Game.page = pages.Menu

beholder.observe("page", function(page)
    Game.page = page
    Game:load()
end)

function love.load()
    love.keyboard.setKeyRepeat(true)
    beholder.trigger("load")
end

function love.draw()
    Game:draw()
    love.graphics.setColor(1, 1, 1, 1)
end

function love.update()
    Game:update()
end

function love.mousepressed(x, y, button)
    beholder.trigger("mousepressed", x, y, button, Game.page)
end

beholder.observe("drop", function(honeys)
    for index, honey in ipairs(honeys) do
        Game.money = Game.money + honey.value
    end
    beholder.trigger("money", Game.money)
end)

beholder.observe("withdraw", function(value)
    Game.money = Game.money - value
    beholder.trigger("money", Game.money)
end)

beholder.observe("withdrawg", function(value)
    Game.gem = Game.gem - value
    beholder.trigger("after", Game.gem)
end)

beholder.observe("gem", function()
    Game.gem = Game.gem + 1
    beholder.trigger("after", Game.gem)
end)

beholder.observe("rebirth", function()
    Game.gem = 0
    Game.money = 0
    beholder.trigger("money", Game.money)
    beholder.trigger("after", Game.gem)
end)

local text = ""

beholder.observe("empty", function()
    text = ""
end)

beholder.observe("add", function(type, number)
    Game[type] = Game[type] + number
    beholder.trigger("money", Game.money)
    beholder.trigger("after", Game.gem)
end)

function love.textinput(t)
    text = text .. t
    beholder.trigger("text", text)
end

function love.keypressed(key)
    if key == "backspace" then
        local byteoffset = utf8.offset(text, -1)

        if byteoffset then
            text = string.sub(text, 1, byteoffset - 1)
        end

        beholder.trigger("text", text)
    end
    if key == "return" then
        beholder.trigger("unfocus")
    end
    if key == "escape" then
        beholder.trigger("escape")
    end
    if key == "lshift" then
        beholder.trigger("lshift", true)
    end
end

function love.keyreleased(key)
    if key == "lshift" then
        beholder.trigger("lshift", false)
    end
end

function love.quit()
    beholder.trigger("save")
end

function love.errorhandler(message)
    love.event.quit()
    if string.find(message, "json.lua") then
        love.window.showMessageBox("Error", "An error occurred, delete BeeTycoon.dll content.", "error", false)
    else
        love.window.showMessageBox("Error", "An error occurred, please report to devs.", "error", false)
    end
end