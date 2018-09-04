if _M then

Game = class()

function Game:init(u)
    self.wordlist = {}
    self.level = 1
    self.options = u:addMenu({})
end

function Game:draw()
end

function Game:initialise()
end

function Game:restart()
end

function Game:activate()
end

function Game:deactivate()
end

function Game:touchReceiver()
    return false
end

function Game:isTouchedBy(t)
    return false
end

function Game:processTouches(g)
end

function Game:setlevel(l)
    self.level = l
end

function Game:setwordlist(w)
    self.wordlist = w
end

return Game

end
