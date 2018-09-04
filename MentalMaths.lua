if _M then
-- Mental Maths

local Game = cimport "Game"
--[[
local UTF8 = cimport "utf8"
local Colour = cimport "Colour"
local Explosion = cimport "Explosion"
  ]]
cimport "Coordinates"

local function textAtAnchor(s,x,y,a)
    local w,h
    w,h = textSize(s)
    x,y = RectAnchorAt(x,y,w,h,a)
    pushStyle()
    textMode(CORNER)
    text(s,x,y)
    popStyle()
end

MentalMaths = class(Game)

function MentalMaths:init(u)
    Game.init(self,u)
    local m = self.options
    self.delay = 5
    self.type = 1
    self.num = 10
    self.ui = u
    self.orientation = LANDSCAPE_ANY
    local lm = self.ui:addMenu()
    lm:isChildOf(m)
    m:addItem({
    title = "Set delay",
    action = function()
        u:getNumberSpinner({
        action = function (n)
            self.delay = n
            return true
        end,
        value = self.delay
        })
        return true
    end
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
                    self.state = 4
                    return true
                end,
        highlight = function()
                    return self.level == v[2]
                end
    })
    end

    m:addItem({
    title = "Mute",
    action = function()
        self.mute = not self.mute
        return true
    end,
    highlight = function()
        return self.mute
    end
    })
    m:addItem({
        title = "Restart",
        action = function()
            self.state = 4
            return true
        end
    })
    local mt = u:addMenu()
    m:addSubMenu("Type",mt)
    self.types = {
    {"Multiply",
        function (s,x,y,a)
            textAtAnchor(s[1] .. " x " .. s[2],x,y,a)
        end,
        function (s)
            return s[1] .. " times " .. s[2]
        end,
        function (s,x,y,a)
            textAtAnchor(s[3],x,y,a)
        end,
        function(f)
            local t,n={},0
            for k=2,12 do
                for l=2,k do
                    if f(k,l) then
                        table.insert(t,{k,l,k*l})
                        n = n + 1
                    end
                end
            end
            return t,n
        end,
        {
            function(k,l)
                if k==10 or l==10 then
                    return false
                end
                return true
            end,
            function(k,l)
                if 10%k == 0 or 10%l == 0 then
                    return false
                end
                return true
            end,
            function(k,l)
                if 10%k == 0 or 10%l == 0 or (k < 5 and l < 5) then
                    return false
                end
                return true
            end,
        }
    },
    {"Add",
        function (s,x,y,a)
            textAtAnchor(s[1] .. " + " .. s[2],x,y,a)
        end,
        function (s)
            return s[1] .. " plus " .. s[2]
        end,
        function (s,x,y,a)
            textAtAnchor(s[3],x,y,a)
        end,
        function(f)
            local t,n={},0
            for k=11,99 do
                for l=11,k do
                    if f(k,l) then
                        table.insert(t,{k,l,k+l})
                        n = n + 1
                    end
                end
            end
            return t,n
        end,
        {
            function(k,l)
                if k%10 + l%10 > 9 then
                    return false
                end
                return true
            end,
            function(k,l)
                return true
            end,
            function(k,l)
                if k%10 + l%10 < 10 then
                    return false
                end
                return true
            end,
        }
    },
    {"Subtract",
        function (s,x,y,a)
            textAtAnchor(s[1] .. " - " .. s[2],x,y,a)
        end,
        function (s)
            return s[1] .. " minus " .. s[2]
        end,
        function (s,x,y,a)
            textAtAnchor(s[3],x,y,a)
        end,
        function(f)
            local t,n={},0
            for k=12,99 do
                for l=11,k-1 do
                    if f(k,l) then
                        table.insert(t,{k,l,k-l})
                        n = n + 1
                    end
                end
            end
            return t,n
        end,
        {
            function(k,l)
                if k%10 - l%10 < 0 then
                    return false
                end
                return true
            end,
            function(k,l)
                return true
            end,
            function(k,l)
                if k%10 - l%10 >= 0 then
                    return false
                end
                return true
            end,
        }
    },
    {"Divide",
        function (s,x,y,a)
            textAtAnchor(s[1] .. " ÷ " .. s[2],x,y,a)
        end,
        function (s)
            return s[1] .. " divided by " .. s[2]
        end,
        function (s,x,y,a)
            textAtAnchor(s[3],x,y,a)
        end,
        function(f)
            local t,n={},0
            for k=2,12 do
                for l=2,12 do
                    if f(k,l) then
                        table.insert(t,{k*l,l,k})
                        n = n + 1
                    end
                end
            end
            return t,n
        end,
        {
            function(k,l)
                if k==10 or l==10 then
                    return false
                end
                return true
            end,
            function(k,l)
                if 10%k == 0 or 10%l == 0 then
                    return false
                end
                return true
            end,
            function(k,l)
                if 10%k == 0 or 10%l == 0 or (k < 5 and l < 5) then
                    return false
                end
                return true
            end,
        }
    },
    {"Power",
        function (s,x,y,a)
            local w,h,tw,th,sw,sh
            pushStyle()
            tw,th = textSize(s[1])
            fontSize(.4*fontSize())
            sw,sh = textSize(s[2])
            w = tw + sw
            h = th
            popStyle()
            x,y = RectAnchorAt(x,y,w,h,a)
            pushStyle()
            textMode(CORNER)
            text(s[1],x,y)
            fontSize(.4*fontSize())
            text(s[2],x+tw,y+.6*th)
            popStyle()
        end,
        function (s)
            return s[1] .. " to the power of " .. s[2]
        end,
        function (s,x,y,a)
            textAtAnchor(s[3],x,y,a)
        end,
        function(f)
            local t,n={},0
            for k=2,31 do
                for l=2,3/math.log10(k) do
                    if f(k,l) then
                        table.insert(t,{k,l,math.floor(math.pow(k,l))})
                        n = n + 1
                    end
                end
            end
            return t,n
        end,
        {
            function(k,l)
                if l > 2 or k > 12 then
                    return false
                end
                return true
            end,
            function(k,l)
                if l > 3 or k > 12 then
                    return false
                end
                return true
            end,
            function(k,l)
                return true
            end,
        }
    },
    {"Inverse Power",
        function (s,x,y,a)
            textAtAnchor(s[3],x,y,a)
        end,
        function (s)
            return "write " .. s[3] .. " as a power"
        end,
        function (s,x,y,a)
            local w,h,tw,th,sw,sh
            pushStyle()
            tw,th = textSize(s[1])
            fontSize(.4*fontSize())
            sw,sh = textSize(s[2])
            w = tw + sw
            h = th
            popStyle()
            x,y = RectAnchorAt(x,y,w,h,a)
            pushStyle()
            textMode(CORNER)
            text(s[1],x,y)
            fontSize(.4*fontSize())
            text(s[2],x+tw,y+.6*th)
            popStyle()
        end,
        function(f)
            local t,n={},0
            for k=2,31 do
                for l=2,3/math.log10(k) do
                    if f(k,l) then
                        table.insert(t,{k,l,math.floor(math.pow(k,l))})
                        n = n + 1
                    end
                end
            end
            return t,n
        end,
        {
            function(k,l)
                if l > 2 or k > 12 then
                    return false
                end
                return true
            end,
            function(k,l)
                if l > 3 or k > 12 then
                    return false
                end
                return true
            end,
            function(k,l)
                return true
            end,
        }
    }
    }
    for k,v in ipairs(self.types) do
        mt:addItem({
        title = v[1],
        action = function()
            if self.type ~= k then
                self.type = k
                self.state = 4
            end
            return true
        end,
        highlight = function()
            return self.type == k
        end
        })
    end
    self.state = 4
end

-- This function gets called once every frame
function MentalMaths:draw()
    -- This sets a dark background color
    pushMatrix()
    pushStyle()
    TransformOrientation(self.orientation)
    local sw,sh = RectAnchorOf(Landscape,"size")
    fill(255, 255, 255, 255)
    if self.state == 1 then
        fontSize(250)
        self.types[self.type][2](self.problems[self.index[self.m]],sw/2,sh/2,"centre")
        if ElapsedTime - self.stime > self.delay then
            self.stime = ElapsedTime
            self.state = self:nextSum()
        end
        pushStyle()
        fontSize(50)
        textMode(CORNER)
        text("Timer:",10,20)
        text(self.delay - math.floor(ElapsedTime - self.stime),180,20)
        text("Count:",sw -250,20)
        text(self.m,sw - 70,20)
        popStyle()
    elseif self.state == 2 then
        fontSize(60)
        text("Tap for answers",sw/2,sh/2)
    elseif self.state == 3 then
        fontSize(60)
        local w,h = sw/4,sh/2
        local ew,lh = textSize(" = ")
        h = h + self.num * lh / 4
        local na = math.ceil(self.num/2)
        for k=1,self.num do
            self.types[self.type][2](self.problems[self.index[k]],w-ew/2,h,"east")
            textAtAnchor(" = ",w,h,"centre")
            self.types[self.type][4](self.problems[self.index[k]],w+ew/2,h,"west")
            h = h - lh
            if k == na then
                w = 3*sw/4
                h = sh/2 + self.num * lh / 4
            end
        end
    elseif self.state == 4 then
        fontSize(60)
        text("Tap to start",sw/2,sh/2)
    end
    popStyle()
    popMatrix()
end

function MentalMaths:nextSet(c)
    self.m = 0
    self.answers = {}
    local t,n = self.types[self.type][5](self.types[self.type][6][self.level])
    self.index = KnuthShuffle(n,true,self.num)
    self.problems = t
    self:nextSum()
    self.stime = ElapsedTime
end

function MentalMaths:activate()
    self.ui:supportedOrientations(self.orientation)
    self.ui:setOrientation(self.orientation)
    self.state = 4
end

function MentalMaths:nextSum()
    if self.m >= self.num then
        return 2
    end
    self.m = self.m + 1
    speech.rate = 0
    if not self.mute then
        speech.say(self.types[self.type][3](self.problems[self.index[self.m]]))
    end
    return 1
end

function MentalMaths:isTouchedBy(t)
    return true
end

function MentalMaths:processTouches(g)
    if g.type.ended then
        if self.state == 2 then
            self.state = 3
        elseif self.state == 3 then
            self.state = 4
        elseif self.state == 4 then
            self.state = 1
            self:nextSet()
        end
        g:reset()
    else
        g:noted()
    end
end

return MentalMaths
end
