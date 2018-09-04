if _M then

local Game = cimport "Game"
local Explosion = cimport "Explosion"
cimport "Coordinates"
cimport "RoundedRectangle"
SlidingPicture = class(Game)

function SlidingPicture:init(u)
    Game.init(self,u)
    self.bgcolour = color(40, 40, 50)
    self.aduration = .8
    self.rows = 4
    self.columns = 3
    self.opacity = 127

    self.wdp = RectAnchorOf(Portrait,"width")
    self.htp = RectAnchorOf(Portrait,"height")
    u:setPictureList({directory = "Documents",
        -- directory = "Games and Puzzles",
                camera = true,
                 filter = function(n,w,h) 
                    return math.min(w,h) > 500
                    end})
    self.ui = u
    self.msg = "Turn the iPad so that the picture is the right way up.  Tap the screen when you're done."
    local m = self.options
    local lm = self.ui:addMenu()
    lm:isChildOf(m)
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
    self:setlevel(1)
end

function SlidingPicture:activate()
    self.ui:supportedOrientations(ANY)
    self.ui:setOrientation(CurrentOrientation)
    self.active = true
    self.picture = nil
    self.aspect = nil
    self.ui:getPicture(
                function(i)
                    self.picture = i
                    return true
                end
            )
end

function SlidingPicture:deactivate()
    self.ui.picturebrowser:deactivate()
end

function SlidingPicture:setlevel(l)
    if l == 1 then
            self:setsize(3,2)
        elseif l == 2 then
            self:setsize(4,3)
        elseif l == 3 then
            self:setsize(6,4)
        else
            self:setsize(4,3)
        end
end

function SlidingPicture:setsize(r,c)
    self.rows = r
    self.columns = c
    self:setpicture()
end

function SlidingPicture:setpicture()
    if not self.picture or not self.aspect then
        return
    end
    self.ui:supportedOrientations(self.aspect)
    self.ui:setOrientation(self.aspect)
    self.mesh = mesh()
    self.fold, self.unfold = foldem(self.rows,self.columns)
    self.rwidth = self.htp/self.rows
    self.rheight = self.wdp/self.columns
    self.mesh.texture = self.picture
    local x,y
    local places = {}

    for i = 1,self.rows do
        x = (i-.5)*self.rwidth
        for j = 1,self.columns do
            y = (j-.5)*self.rheight
            table.insert(places,{x,y})
        end
    end
    self.places = places
    -- kth piece is in p[k]th place, start with blank at top left
    local pp = KnuthShuffle(self.rows*self.columns-1,false)
    while is_identity(pp) do
        pp = KnuthShuffle(self.rows*self.columns-1,false)
    end
    local p = {}
    local first = 1
    if self.aspect == PORTRAIT_UPSIDE_DOWN then
        first = 1
    elseif self.aspect == LANDSCAPE_LEFT then
        first = self.columns
    elseif self.aspect == PORTRAIT then
        first = self.rows*self.columns
    elseif self.aspect == LANDSCAPE_RIGHT then
        first = self.columns*(self.rows - 1) + 1
    end
    local u,l
        for k,v in ipairs(pp) do
            if k < first then
                l = k
            else
                l = k+1
            end
            if v < first then
                u = v
            else
                u = v+1
            end
            p[l] = u
        end
        p[first] = first
    self.gap = first
    -- kth place contains pi[k]th piece
    local pi = {}
    for k = 1,self.rows*self.columns do
        pi[p[k]] = k -- inverse of p
        self.mesh:addRect(
            places[p[k]][1],places[p[k]][2],self.rwidth,self.rheight)
    end
    self.p = p
    self.pi = pi
    --if SHOW_PICTURE then
        --self.mesh:setRectColor(first,255,255,255,self.opacity)
    --else
        self.mesh:setRectColor(first,0,0,0,0)
    --end
    local ij,l
    for k = 2,self.rows*self.columns do
        if k <= first then
            l = k - 1
        else
            l = k
        end
        ij = self.unfold(l)
        self.mesh:setRectTex(l,
                (ij[1]-1)/self.rows,
                (ij[2]-1)/self.columns,
                1/self.rows,
                1/self.columns
                )
    end
end


function SlidingPicture:draw()

    if self.guessed then
        self.explosion:draw()
        if not self.explosion.active then
            self.picture = nil
            self.aspect = nil
            self.guessed = nil
            self.p = nil
            self:activate()
        end
        return
    end
    pushMatrix()
    TransformOrientation(LANDSCAPE_LEFT)
    if self.animate then
        local t = (ElapsedTime - self.atime)/self.aduration
        local last
        if t > 1 then
            last = true
            t = 1
        end
        -- smooth out the motion
        t = (3 - 2*t)*t*t
        for k,v in ipairs(self.animate) do
            
            self.mesh:setRect(v[1],
                t*v[3][1] + (1-t)*v[2][1],
                t*v[3][2] + (1-t)*v[2][2],
                self.rwidth,
                self.rheight)
        end
        if last then
            self.animate = nil
        end
    elseif self.p and is_identity(self.p) then
        local img = image(RectAnchorOf(Screen,"width"),
                          RectAnchorOf(Screen,"height"))
        setContext(img)
        --TransformOrientation(LANDSCAPE_LEFT)
        self.mesh:draw()
        setContext()
        self.guessed = true
        self.explosion = Explosion({
            image = img,
            centre = vec2(RectAnchorOf(Screen,"centre")),
            trails = true
        })
        self.explosion:activate(1,5)
    end
    if self.aspect then
        self.mesh:draw()
        popMatrix()
    elseif self.picture then
        spriteMode(CORNER)
        sprite(self.picture,0,0)
        popMatrix()
        fontSize(40)
        font("AmericanTypewriter")
        textWrapWidth(RectAnchorOf(Screen,"width")/2)
        local w,h = textSize(self.msg)
        local x,y = RectAnchorOf(Screen,"centre")
        x,y = RectAnchorAt(x,y,w,h,"centre")
        fill(204, 179, 28, 255)
        RoundedRectangle(x,y,w,h,5)
        fill(0, 0, 0, 255)
        textMode(CORNER)
        text(self.msg,x+5,y+5)
    end
end

function SlidingPicture:isTouchedBy(t)
    if self.active == false then
        return false
    end
    return true
end
function SlidingPicture:processTouches(g)
    if self.animate then
        return
    end
    local t = g.touchesArr[1]
    local a = self.gap
    if t.touch.state == ENDED then
        if not self.aspect then
            self.aspect = CurrentOrientation
            g:reset()
            self:setpicture()
            return
        end
        local v = OrientationInverse(LANDSCAPE_LEFT,t.touch)

        local tpiece = {
            math.floor(v.x/self.rwidth) + 1,
            math.floor(v.y/self.rheight) + 1
        }
        self.tpiece = tpiece
        local d = loneline(self.unfold(self.p[a]),tpiece)
        if d and d:lenSqr() ~= 0 then
            local st = d:dot(vec2(self.columns,1))
            local m = self.fold(unpack(tpiece))
            local f = self.p[a] + st
            self.animate = {}
            table.insert(self.animate,
                {a,self.places[self.p[a]],self.places[m]}
            )
            local pr = self.p[a]
            for l=f,m,st do
            table.insert(self.animate,
                {self.pi[l],self.places[l],self.places[pr]})

            self.p[self.pi[pr]],self.pi[l],
                self.p[self.pi[l]],self.pi[pr] 
                    = self.p[self.pi[l]],
                        self.pi[pr],self.p[self.pi[pr]],self.pi[l]
                pr = l
            end

            self.atime = ElapsedTime
        end
    end
end

return SlidingPicture

end
