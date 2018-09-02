if _M then

local Game = cimport "Game"
local UTF8 = cimport "utf8"
local Colour = cimport "Colour"
local Explosion = cimport "Explosion"
cimport "Coordinates"
Hangman = class(Game)

function Hangman:init(f,u)
    Game.init(self,u)
    self.font = f
    self.ui = u
    self.kbd = u:declareKeyboard({
        name = f.name,
        type = "qwerty",
        width = RectAnchorOf(Portrait,"width")
        })
    self.kbd.resize = true
    self.padding = 10
    self.orientation = PORTRAIT_ANY
    local m = self.options
    local wm = self.ui:addMenu()
    wm:isChildOf(m)
    local lm = self.ui:addMenu()
    lm:isChildOf(m)
    m:addItem({
        title = "Choose Words",
        action = function(x,y)
            wm.active = not wm.active
            wm.x = x
            wm.y = y
        end,
        highlight = function()
            return wm.active
        end,
        deselect = function()
            wm.active = false
        end,
    })
    m:addItem({
        title = "Choose Level",
        action = function(x,y)
            lm.active = not lm.active
            lm.x = x
            lm.y = y
        end,
        highlight = function()
            return lm.active
        end,
        deselect = function()
            lm.active = false
        end,
    })
    for _,v in ipairs({
        {"Easy", 1},
        {"Medium", 2},
        {"Hard", 3}
    }) do
    lm:addItem({
        title = v[1],
        action = function()
                    self:setlevel(v[2])
                    self:restart()
                    return true
                end,
        highlight = function()
                    return self.level == v[2]
                end
    })
    end

    for k,_ in pairs(Words) do
        wm:addItem({
            title = k,
            action = function()
                self:setwordlist(k)
                self:restart()
                return true
            end,
            highlight = function()
                return self.wordlist == k
            end
        })
        self.wordlist = k
    end
    self.level = 1
end

function Hangman:activate()
    self.ui:supportedOrientations(self.orientation)
    self.ui:setOrientation(self.orientation)
    self.cwidth = self.font:charWidth("m")
    self.words = Words[self.wordlist]
    local l = 0
    local n = 0
    for k,v in ipairs(self.words) do
        l = l + 1
        n = math.max(n,v:len())
    end
    self.long = n * (self.cwidth + self.padding)
    while self.long > Portrait[3] do
        self.font.size = self.font.size - 5
        self.cwidth = self.font:charWidth("m")
        self.long = n * (self.cwidth + self.padding)
    end
    self.mwords = l
    self.word = ""
    self:newword()
    self.colour = Colour.svg.White
end

function Hangman:deactivate()
    self.ui:unuseKeyboard("qwerty")
end

function Hangman:newword()
    self.n = 1
    local w = self.word
    while w == self.word do
        w = self.words[math.random(1,self.mwords)]
    end
    self.word = w
    self.isguessed = false
    self.kbd:reactivateallkeys()
    self.letters = {}
    self.guessed = {}
    self.srettel = {}
    local k = 0
    local u = UTF8(w)
    for c in u:chars() do
        k = k + 1
        c = tonumber(c)
        table.insert(self.letters,c)
        if not self.srettel[c] then
            self.srettel[c] = {}
        end
        table.insert(self.srettel[c],k)
    end
    -- should automatically mark spaces as guessed
    self.wlen = k
    self.hanged = false
    self.hangedat = nil
    self.gtime = nil
    self.ui:useKeyboard("qwerty",
        function(k,v)
             self:checkletter(k) 
             self.kbd:deactivatekey(v)
             return false
            end
    )
    self.x = (WidthOf(Portrait)
             - self.wlen*(self.cwidth + self.padding))/2
    self.y = self.ui:keyboardtop() + 2*self.padding
end

Hangman.restart = Hangman.activate

function Hangman:draw()
    pushMatrix()
    pushStyle()
    textMode(CORNER)
    strokeWidth(10)
    lineCapMode(SQUARE)
    tint(self.colour)
    smooth()
    TransformOrientation(self.orientation)
    self:drawgallows()
    if self.isguessed then
        self.explosion:draw()
        if not self.explosion.active then
            self:newword()
        end
        return
    end
    if self.hanged then
        if not self.hangedat then
            for k,v in ipairs(self.letters) do
                self.guessed[k] = true
            end
            self.hangedat = ElapsedTime
        else
            if ElapsedTime - self.hangedat > 5 then
                self:newword()
            end
        end
    end
    local x,y = self.x,self.y
    local p = self.padding
    local hw = self.cwidth/2
    local cx
    local guessed = true
    for k,v in ipairs(self.letters) do
        if self.guessed[k] then
            cx = self.font:charWidth(string.char(v))/2
            self.font:write_utf8(v,x+hw-cx,y+p,self.colour)
        else
            guessed = false
            line(x,y,x+self.cwidth,y)
        end
        x = x + self.cwidth + p
    end
    if guessed 
        and not self.isguessed 
        and not self.hanged 
            then
                if not self.gtime then
                    self.gtime = ElapsedTime + 1
                    
                self.ui:unuseKeyboard("qwerty")
                elseif ElapsedTime > self.gtime then
                local lh = self.font:lineheight()
                local img = image(self.wlen*(self.cwidth + p),lh)
                local col = Colour.random("svg")
                setContext(img)
                resetMatrix()
                x = 0
                for k,v in ipairs(self.letters) do
                    cx = self.font:charWidth(string.char(v))/2
                    self.font:write_utf8(v,x+hw-cx,p,col)
                    x = x + self.cwidth + self.padding
                end
                setContext()
                self.explosion = Explosion({
                    image = img,
                    centre = vec2(WidthOf(Portrait)/2,self.y+lh/2),
                    trails = true
                })
                self.explosion:activate(2,7)
                self.isguessed = true
            end
    end
    popStyle()
    popMatrix()
end

function Hangman:checkletter(u)
    local l = u:firstchar()
    if self.srettel[l] then
        for k,v in ipairs(self.srettel[l]) do
            self.guessed[v] = true
        end
    else
        self.n = self.n + 1
        if self.n > 10 then
            self.hanged = true
        end
    end
end

function Hangman:drawgallows()
    local y = self.y + 2*self.padding
                 + self.font:lineheight()
    local h = RectAnchorOf(Portrait,"height") - y - self.padding
    local w = self.long/2
    local x = RectAnchorOf(Portrait,"width")/2 - w/2
    local t = 0
    if self.hangedat then
        t = math.min(4,(ElapsedTime - self.hangedat)^2)/4
    end
    local n = math.min(10,self.n)
    pushStyle()
    pushMatrix()
    translate(x,y)
    lineCapMode(PROJECT)
    strokeWidth(8)
    stroke(130, 78, 29, 255)
    for i = 1,n do
        Hangman.gallows[i](w,h,t)
    end
    popMatrix()
    popStyle()
end
    
Hangman.gallows = {
    function(w,h,t) line(0,0,w,0) end,
    function(w,h,t) line(w/4,0,w/4,h) end,
    function(w,h,t) line(w/4,h,3*w/4,h) end,
    function(w,h,t) line(w/4,7*h/8,w/4+h/8,h) end,
    function(w,h,t) line(3*w/4,h,3*w/4,(7-t)*h/8) end,
    function(w,h,t) strokeWidth(5)
    fill(0,0,0,0)
    stroke(130, 29, 86, 255)
    ellipseMode(RADIUS)
    ellipse(3*w/4,(6-t)*h/8,h/8)
    strokeWidth(8) end,
    function(w,h,t) line(3*w/4,(5-t)*h/8,3*w/4,(3-t)*h/8) end,
    function(w,h,t) line(3*w/4,(3-t)*h/8,3*w/4-h/8,(2-t)*h/8) end,
    function(w,h,t) line(3*w/4,(3-t)*h/8,3*w/4+h/8,(2-t)*h/8) end,
    function(w,h,t) line(3*w/4-h/8,(4-t)*h/8,3*w/4+h/8,(4-t)*h/8) end
}

return Hangman

end