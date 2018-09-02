if _M then

local Game = cimport "Game"
local Colour = cimport "Colour"
local _,Sentence,_ = unpack(cimport "Font")
local UTF8 = cimport "utf8"
local Explosion = cimport "Explosion"
cimport "Coordinates"
Anagram = class(Game)

function Anagram:init(f,lf,u)
    Game.init(self,u)
    self.ofont = f
    self.lfont = lf
    self.ui = u
    self.lh = f:lineheight()
    self.llh = lf:lineheight()
    self.colour = Colour.svg.White
    self.highlight = Colour.svg.Red
    self.score = 0
    self.scoret = Sentence(lf,"Score: ")
    self.scoret:setColour(Colour.svg.White)
    self.scoren = Sentence(lf,self.score)
    self.scoren:setColour(Colour.svg.White)
    self.orientation = LANDSCAPE_ANY
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

function Anagram:activate()
    self.ui:supportedOrientations(self.orientation)
    self.ui:setOrientation(self.orientation)
    self.wlist = {}
    self.words = {}
    local s
    self.ww = 0
    self.mwords = math.floor(HeightOf(Landscape)/self.llh)
    self.nwords = 0
    local words = Words[self.wordlist]
    local n = 0
    for k,v in ipairs(words) do
        n = n + 1
    end
    self.mwords = math.min(self.mwords,n)
    for i = 1,n do
        j = math.random(i,n)
        words[i],words[j] = words[j],words[i]
    end
    local st
    if n <= self.mwords then
        st = 1
    else
        st = math.random(1,n - self.mwords + 1)
    end
    if self.level == 1 then
    for i = st,st + self.mwords-1 do
        s = Sentence(self.lfont,words[i])
        s:prepare()
        s:setColour(Colour.svg.White)
        self.ww = math.max(self.ww,s.width)
        self.nwords = self.nwords + 1
        table.insert(self.wlist,s) 
        table.insert(self.words,words[i])
    end

    else
        self.nwords = self.mwords
        self.words = words
    end
    self.ww = WidthOf(Landscape) - self.ww - 10
    self.wordrect = {}
    for _,i in ipairs({1,2,4}) do
    self.wordrect[i] = Landscape[i]
    self.wordrect[3] = self.ww
    end
    self:newword()
end

function Anagram:newword()
    local nword = self.word
    while nword == self.word do
        nword = self.words[math.random(1,self.mwords)]
    end
    self.word = nword
    local s = Sentence(self.ofont,self.word)
    s:prepare()
    self.cw = s.width
    if self.cw > self.ww - 10 then
        self.font= self.ofont:clone({size = self.ofont.size
             * (self.ww-10)/self.cw})
    else
        self.font = self.ofont:clone()
    end
    s = Sentence(self.font,self.word)
    s:prepare()
    self.cw = s.width
    self.l = 0
    self.chars = {}
    local uword = UTF8(self.word)
    for c in uword:chars() do
        self.l = self.l + 1
        local l = self.l
        table.insert(self.chars,{c,l})
    end
    local j,wd,ch,l,it,cht
    wd = self.word
    while (wd == self.word) do
        for i = 1,self.l do
            j = math.random(i,self.l)
            self.chars[i],self.chars[j] = self.chars[j],self.chars[i]
        end
        wd = ""
        cht = {}
        for k,c in ipairs(self.chars) do
            ch,l = unpack(c)
            table.insert(cht,utf8dec(ch))
        end
        wd = table.concat(cht)
    end
    self.lh = self.font:lineheight()
    
    self.x = 0
    self.y = 0
    self.xx = {}
    self.guessed = false
    self.scoren:setString(self.score)
    self.safe = true
    self.rightcol = Colour.random("svg")
end

Anagram.restart = Anagram.activate

function Anagram:draw()
    pushMatrix()
    TransformOrientation(self.orientation)
    local x,y = RectAnchorOf(self.wordrect,"centre")
    if self.level == 1 then
        local h = HeightOf(Landscape)
        fill(255, 0, 0, 255)
        for k,v in ipairs(self.wlist) do
            h = h - self.llh
            v:draw(self.ww,h)
        end
    end
    local sx,sy
    sx,sy = self.scoret:draw(20,20)
    self.scoren:draw(sx,sy)
    if self.guessed then
        self.explosion:draw()
        if not self.explosion.active then
            self:newword()
        end
        return
    end
    x = x - self.cw/2
    local col = self.colour
    local letcol
    self.x = x
    self.y = y
    self.xx = {}
    local ch,l,it
    local right = false
    local s = {}
    for k,c in ipairs(self.chars) do
        ch,l = unpack(c)
        table.insert(s,utf8dec(ch))
    end
    s = table.concat(s)
    if s == self.word and not self.intouch then
        right = true
    end
    if right then
        col = self.rightcol
    end
    local lh = self.lh/2
    for k,c in ipairs(self.chars) do
        ch,l = unpack(c)
        if self.letter == k then
            letcol = self.highlight
        else
            letcol = col
        end
        x,y = self.font:write_utf8(ch,x,y,letcol)
        table.insert(self.xx,x)
    end

    if right and not self.guessed then
        local img = image(self.cw,self.lh)
        setContext(img)
        resetMatrix()
        x,y = 0,self.font.descent
        for k,c in ipairs(self.chars) do
            ch,l = unpack(c)
            x,y = self.font:write_utf8(ch,x,y,col)
        end
        setContext()
        self.guessed = true
        self.score = self.score + 1
            -- create new explosion
        self.explosion = Explosion({
            image = img,
            centre = vec2(RectAnchorOf(self.wordrect,"centre"))
                    + vec2(0,self.lh/2 - self.font.descent),
            trails = true
        })
        self.explosion:activate(2,7)
    end
    popMatrix()
end

function Anagram:isTouchedBy(touch)
    if self.guessed then
        return false
    end
    if self.intouch then
        return false
    end
    local v = vec2(touch.x,touch.y)
    v = OrientationInverse(self.orientation,v)
    if v.x < self.x then
        return false
    end
    if v.x > self.x + self.cw then
        return false
    end
    if v.y < self.y then
        return false
    end
    if v.y > self.y + self.lh then
        return false
    end
    self.intouch = true
    return true
end

function Anagram:processTouches(g)
    if g.updated then
    if g.num == 1 then
        local t = g.touchesArr[1]
        if self.guessed and t.touch.state == BEGAN then
            self:newword()
        else
        local letter = self.l
        local v = vec2(t.touch.x,t.touch.y)
        v = OrientationInverse(self.orientation,v)
        for k,x in ipairs(self.xx) do
            if v.x < x then
                letter = k
                break
            end
        end
        if letter == self.letter then
            self.safe = true
        elseif self.letter and self.safe then
            self.chars[letter],self.chars[self.letter] = 
                self.chars[self.letter], self.chars[letter]
            self.safe = false
            self.letter = letter
        end
        if not self.letter then
            self.letter = letter
        end
        if t.touch.state == ENDED then
            self.letter = nil
        end
            
    end
    end
    g:noted()
    end
    if g.type.ended then
        self.intouch = false
        g:reset()
    end
end

return Anagram

end