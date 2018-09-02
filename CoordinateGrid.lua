if _M then

local Game = cimport "Game"
local Explosion = cimport "Explosion"
cimport "Coordinates"
CoordinateGrid = class(Game)

function CoordinateGrid:init(t)
    t = t or {}
    Game.init(self,t.ui)
    self.width = t.width or 9
    self.height = t.height or 9
    self.random = t.random or false
    self.rlevel = t.randomLevel or .7
    self.setting = not self.random
    local sw,sh = RectAnchorOf(Landscape,"size")
    self.step = sh/(self.height + .5)
    self.grid = {
        sw - self.step*(self.width + .5),0,
        self.step*(self.height + .5),self.step*(self.width + .5)
    }
    self.user = {}
    self.given = {}
    self.per = {}
    self.rcolour = color(255, 0, 225, 255)
    self.wcolour = color(30, 120, 112, 255)
    self.options:addItem({
        title = "Setting",
        action = function()
                self:changeSetting()
                return true
                end,
        highlight = function()
                    return self.setting
                    end
    })
    local m = t.ui:addMenu({
        attach = false,
        menuOpts = {
            pos = function() return 0,0 end,
            anchor = "south west",
            direction = "x"
        }
    })
    m:addItem({
        title = "Set",
        action = function()
                self:changeSetting()
                return false
                end,
        highlight = function()
                    return self.setting
                    end
    })
    m:addItem({
        title = "Random",
        action = function()
                self.random = not self.random
                if self.setting and self.random then
                    self:changeSetting()
                end
                return false
                end,
        highlight = function()
            return self.random
            end
    })
    self.cmds = m
    self.ui = t.ui
    self.orientation = LANDSCAPE_ANY
end

function CoordinateGrid:activate()
    self.ui:supportedOrientations(self.orientation)
    self.ui:setOrientation(self.orientation)
    for i=1,self.width do
        self.user[i] = {}
        self.given[i] = {}
        for j=1,self.height do
            self.user[i][j] = false
            if self.random and (math.random() > self.rlevel) then
                self.given[i][j] = true
            else
                self.given[i][j] = false
            end
        end
    end
    local nm = self.width*self.height
    if self.setting then
        for k=1,nm do
            self.per[k] = k
        end
    else
        self.per = KnuthShuffle(nm,true)
    end
    self.cmds:activate()
end

function CoordinateGrid:deactivate()
    self.cmds:deactivate()
end

function CoordinateGrid:draw()
    pushMatrix()
    pushStyle()
    TransformOrientation(self.orientation)
    pushMatrix()
    translate(RectAnchorOf(self.grid,"south west"))
    local x,y = 3*self.step/2,3*self.step/2
    local w,h = RectAnchorOf(self.grid,"size")
    local n = 1
    local nw = 0
    lineCapMode(SQUARE)
    strokeWidth(4)
    stroke(127, 127, 127, 255)
    fill(255, 255, 255, 255)
    fontSize(40)
    textMode(CENTER)
    line(self.step/2,0,self.step/2,h)
    while (x < w) do
        line(x,0,x,h)
        text(n,x-self.step/2,20)
        x = x + self.step
        n = n + 1
    end
    n=1
    line(0,self.step/2,w,self.step/2)
    while (y < h) do
        line(0,y,w,y)
        text(n,20,y-self.step/2)
        y = y + self.step
        n = n + 1
    end
    translate(-self.step/2,-self.step/2)
    if self.explosion then
        popMatrix()
        self.explosion:draw()
        if not self.explosion.active then
            self:changeSetting()
            self.explosion = nil
        end
        popMatrix()
        return
    end
    noStroke()
    for k,v in ipairs(self.user) do
        for l,u in ipairs(v) do
            if u then
                if self.given[k][l] then
                    fill(self.rcolour)
                else
                    fill(self.wcolour)
                    nw = nw + 1
                end
                rect(k*self.step,l*self.step,self.step,self.step)
            end
        end
    end
    popMatrix()
    local coords = {}
    local s
    local nc = 0

    for i,v in ipairs(self.given) do
        for j,u in ipairs(v) do
            if u then
                s = "(" .. i .. "," .. j .. ")"
                if self.user[i][j] then
                    table.insert(coords,{s,self.rcolour})
                else
                    table.insert(coords,{s,self.wcolour})
                    nw = nw + 1
                end
                nc = nc + 1
            end
        end
    end
    fill(194, 194, 194, 255)
    if nc < 40 then
        fontSize(40)
    elseif nc < 73 then
        fontSize(30)
    else
        fontSize(25)
    end
    textMode(CORNER)
    local tx,ty = RectAnchorOf(Landscape,"north west")
    local tw,th = textSize("(0,0)")
    ty = ty - 55 - th
    tx = tx + 20
    local tty = ty
    for k,v in ipairs(self.per) do
        if coords[v] then
            fill(coords[v][2])
            text(coords[v][1],tx,ty)
            ty = ty - th
            if ty < 45 then
                ty = tty
                tx = tx + tw
            end
        end
    end

    if nw == 0 and not self.setting then
        local img = image(RectAnchorOf(self.grid,"size"))
        setContext(img)
        pushMatrix()
        translate(-self.step/2,-self.step/2)
        fill(self.rcolour)
        for k,v in ipairs(self.user) do
            for l,u in ipairs(v) do
                if u then
                    rect(k*self.step,l*self.step,self.step,self.step)
                end
            end
        end
        popMatrix()
        setContext()
        self.explosion = Explosion({
            image = img,
            centre = vec2(RectAnchorOf(self.grid,"centre")),
            trails = true
        })
        self.explosion:activate(1,5)
    end
    popStyle()
    popMatrix()
end

function CoordinateGrid:isTouchedBy(touch)
    local x,y = RectAnchorOf(self.grid,"south west")
    local w,h = RectAnchorOf(self.grid,"size")
    local v = vec2(touch.x,touch.y)
    v = OrientationInverse(self.orientation,v)
    if v.x < x then
        return false
    end
    if v.x > x + w then
        return false
    end
    if v.y < y then
        return false
    end
    if v.y > y + h then
        return false
    end
    return true
end

function CoordinateGrid:processTouches(g)
    if g.updated then
    local t = g.touchesArr[1]
    if t.touch.state == ENDED then
        local v = vec2(t.touch.x,t.touch.y)
        v = OrientationInverse(self.orientation,v)
        v = v - vec2(RectAnchorOf(self.grid,"south west"))
        v = v/self.step + vec2(.5,.5)
        v.x = math.floor(v.x)
        v.y = math.floor(v.y)
        self.user[v.x][v.y] = not self.user[v.x][v.y]
        if self.setting then
            self.given[v.x][v.y] = not self.given[v.x][v.y]
        end
    end
    end
    g:noted()
    if g.type.ended then
        g:reset()
    end
end

function CoordinateGrid:changeSetting()
    if self.setting then
        self.setting = false
        for k,v in ipairs(self.user) do
            for l,_ in ipairs(v) do
                self.user[k][l] = false
                if self.random and (math.random() > self.rlevel) then
                    self.given[k][l] = true
                end
            end
        end
        self.per = KnuthShuffle(#self.per,true)
    else
        if not self.random then
            self.setting = true
        end
        for k,_ in ipairs(self.per) do
            self.per[k] = k
        end
        for k,v in ipairs(self.user) do
            for l,_ in ipairs(v) do
                self.user[k][l] = false
                if self.random and (math.random() > self.rlevel) then
                    self.given[k][l] = true
                else
                    self.given[k][l] = false
                end
            end
        end
    end
end
        
return CoordinateGrid

end