if _M then
    
    local Game = cimport "Game"
    local Colour = cimport "Colour"
    cimport "Coordinates"
    Ladder = class(Game)
    
    function Ladder:init(u)
        Game.init(self,u)
        self.computer = {
            numbers = {},
            fnumbers = {},
            pnumbers = {},
            nnums = 0,
            fnums = 0,
            score = 0,
            wins = 0,
            active = true
        }
        self.player = {
            numbers = {},
            fnumbers = {},
            pnumbers = {},
            nnums = 0,
            fnums = 0,
            score = 0,
            wins = 0,
            active = true
        }
        self.max = 999
        self.padding = {l = 10,t = 5,r = 10,b = 5}
        self.linewidth = 5
        self.font = "Didot-Bold"
        self.fontsize = 50
        self.colour = Colour.svg.DarkGray
        self.tcolour = Colour.svg.White
        self.delay = 1
        local m = self.options
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
            title = "Monte Carlo",
            action = function()
            self.run = not self.run
            return true
        end,
            highlight = function()
            return self.run
        end
        })
        m:addItem({
            title = "New Game",
            action = function()
            for _,v in ipairs({"computer", "player"}) do
                self[v].games = self[v].games - 1
                self[v].wins = self.wins[v] - 1
                self[v].fnums = 0
            end
                self:restart()
            return true
        end
        })
        m:addItem({
            title = "Restart",
            action = function()
                self:activate()
            return true
        end
        })
        m:addItem({
            title = "Computer",
            action = function()
            self.computer.active = not self.computer.active
            return true
        end,
            highlight = function()
            return self.computer.active
        end
        })
        m:addItem({
            title = "Human",
            action = function()
            self.player.active = not self.player.active
            return true
        end,
            highlight = function()
            return self.player.active
        end
        })
    end
    
    function Ladder:activate()
        for _,v in ipairs({"computer", "player"}) do
            self[v].score = 0
            self[v].wins = -1
        end
        self.games = -1
        self.run = false
        self:restart()
    end
    
    function Ladder:restart()
        self.games = self.games + 1
        for _,v in ipairs({"computer","player"}) do
            self[v].score = self[v].score + self[v].fnums
            if self[v].fnums == 0 then
                self[v].wins = self[v].wins + 1
            end
            self[v].numbers = {}
            self[v].fnumbers = {}
            self[v].pnumbers = {}
            self[v].fnums = 0
            self[v].over = false
            self[v].lpos = false
        end
        self.nnums = 0
        self.number = false
        self:newNumber()
    end
    
    function Ladder:draw()
        if self.run then
            if not self.number then
                self:restart()
            elseif self.animate == 0 then
                self:newNumber()
            end
        end
        local lw = self.linewidth
        local cw,ch = RectAnchorOf(Screen,"centre")
        local pd = self.padding
        local s,tk
        pushMatrix()
        pushStyle()
        font(self.font)
        fontSize(self.fontsize)
        textMode(CORNER)
        rectMode(CORNER)
        local nw,nh = textSize(self.max)
        local bh = nh + pd.t + pd.b + lw
        local lh = bh*5 - lw/2
        for pk,pv in ipairs({"computer","player"}) do
            if self[pv].active then

                noStroke()
            tk = 2*pk-1
            fontSize(.5*self.fontsize)
            fill(self.tcolour)
            s = "Score: " .. self[pv].score .. "/" .. self[pv].wins .. "/" .. self.games
            text(s,tk*cw/2-nw,ch-lh-bh)
            fill(Colour.shade(self.tcolour,25))
            for i=1,10 do
                if self[pv].pnumbers[i] then
                    rect(tk*cw/2-nw/2,ch-lh+(i-1)*bh+pd.b,nw,nh)
                end
            end
                if pv == "player" and self[pv].lpos then
            fill(Colour.shade(self.tcolour,75))
                rect(tk*cw/2-nw/2,ch-lh+(self[pv].lpos-1)*bh+pd.b,nw,nh)
            end
        strokeWidth(lw)
        stroke(self.colour)
            fill(self.tcolour)
            line(tk*cw/2-nw/2-pd.l,ch-lh,tk*cw/2-nw/2-pd.l,ch+lh)
            line(tk*cw/2+nw/2+pd.r,ch-lh,tk*cw/2+nw/2+pd.r,ch+lh)
            lineCapMode(SQUARE)
            fontSize(self.fontsize)
            local tw
            for i=1,9 do
                line(tk*cw/2-nw/2-pd.l,ch-lh-lw/2+i*bh,tk*cw/2+nw/2+pd.l,ch-lh-lw/2+i*bh)
            end
            for i=1,10 do
                if self[pv].numbers[i] then
                    tw = textSize(self[pv].numbers[i])
                    text(self[pv].numbers[i],tk*cw/2+nw/2-tw,ch-lh+(i-1)*bh+pd.b)
                end
            end
            if self[pv].fnums ~= 0 then
                fontSize(.9*fontSize())
                fill(Colour.shade(self.tcolour,50))
                for k,v in ipairs(self[pv].fnumbers) do
                    tw = textSize(v)
                    text(v,tk*cw/2+nw/2+(tk-2)*(nw+pd.l+pd.r+lw)-tw,ch-lh+(k-1)*(bh-lw)+pd.b)
                end
                fill(Colour.shade(self.tcolour,100-50*self.animate))
            end
            
            if self.number then
                
                fontSize(2*(1-self.animate)*self.fontsize+self.animate*fontSize())
                text(self.number,(1-self.animate)*self[pv].numpos+self.animate*self[pv].fpos)
            end
            end
        end
        popStyle()
        popMatrix()
    end
    
    function Ladder:newNumber()
        if self.number then
            for k,v in ipairs({"computer","player"}) do
                if self[v].lpos then
                    self[v].numbers[self[v].lpos] = self.number
                else
                    table.insert(self[v].fnumbers,self.number)
                end
            end
        end
        self.computer.pnumbers = {}
        self.player.pnumbers = {}
        if self.nnums == 10 then
            self.number = false
            return
        end
        local lw = self.linewidth
        local cw,ch = RectAnchorOf(Screen,"centre")
        local pd = self.padding
        pushStyle()
        font(self.font)
        fontSize(2*self.fontsize)
        local tw,th = textSize(self.max)
        fontSize(self.fontsize)
        local nw,nh = textSize(self.max)
        local bh = nh + pd.t + pd.b + lw
        local lh = bh*5 - lw/2
        self.number = math.random(self.max)
        self.animate = 0
        self.computer.numpos = vec2(cw-tw/2,ch-th/2)
        self.player.numpos = vec2(cw-tw/2,ch-th/2)
        self.player.fpos = vec2(cw-tw/2,ch-th/2)
        self.player.lpos = false
        local p = self:placeNumber()
        if p then
            tw = textSize(self.number)
            self.computer.fpos = vec2(cw/2+nw/2-tw,ch-lh+(p-1)*bh+pd.b)
        else
            bh = bh - lw
            fontSize(.9*fontSize())
            tw = textSize(self.number)
            self.computer.fpos = vec2(cw/2-(nw/2+pd.l+pd.r+lw)-tw,ch-lh+self.computer.fnums*bh+pd.b)
            self.computer.fnums = self.computer.fnums + 1 
            self.computer.over = true
        end
        if self.player.over then
            fontSize(.9*self.fontsize)
            tw = textSize(self.number)
            self.player.fpos = vec2(3*cw/2+(3*nw/2+pd.l+pd.r+lw)-tw,ch-lh+self.player.fnums*bh+pd.b)
            self.player.fnums = self.player.fnums + 1
        end
        self.nnums = self.nnums + 1
        self.computer.lpos = p
        popStyle()
    end
    
    function Ladder:placeNumber()
        local c = self.number
        local nums,a,b,i,j,l
        if not self.player.over then
            nums = self.player.numbers
            a,b,i,j,l = 0,self.max+1,0,11
            for k=1,10 do
                if nums[k] then
                    if nums[k] < c then
                        a,i = nums[k],k
                    end
                    if nums[k] == c then
                        l = k
                    end
                    if nums[k] > c then
                        b,j = nums[k],k
                        break
                    end
                end
            end
            if j == i + 1 then
                self.player.over = true
            else
                for k=i+1,j-1 do
                    if k ~= l then
                        self.player.pnumbers[k] = true
                    end
                end
            end
        end
        if self.computer.over then
            return false
        end
        nums = self.computer.numbers
        a,b,i,j,l = 0,self.max+1,0,11
        for k=1,10 do
            if nums[k] then
                if nums[k] < c then
                    a,i = nums[k],k
                end
                if nums[k] == c then
                    l = k
                end
                if nums[k] > c then
                    b,j = nums[k],k
                    break
                end
            end
        end
        for k=i+1,j-1 do
            if k ~= l then
                self.computer.pnumbers[k] = true
            end
        end
        if l then
            if l==i+1 and j==l+1 then
                return false
            end
            if l==i+1 then
                return l+1
            end
            if j==l+1 then
                return l-1
            end
            if (j-l-1)/(l-i)*(c-a)/(b-c) < 1 then
                return l-1
            else
                return l+1
            end
        else
            if j==i+1 then
                return false
            end
            return math.floor((c-a)/(b-a)*(j-i-1))+i+1
        end
    end
    
    function Ladder:isTouchedBy(t)
        if self.run then
            return false
        end
        if self.player.active and self.number and not self.player.over then
            pushStyle()
            fontSize(2*self.fontsize)
            local tw,th = textSize(self.number)
            popStyle()
            local cw,ch = RectAnchorOf(Screen,"centre")
            t = vec2(t.x,t.y)
            if math.abs(t.x-cw) <= tw/2 
                and math.abs(t.y-ch) <= th/2 then
                self.player.offset = vec2(cw-tw/2,ch-th/2) - t
                return true
            else
                self.player.offset = false
                return false
            end
        end
        return true
    end
    
    function Ladder:processTouches(g)
        if self.player.active and not self.player.over then
            if self.player.offset then
                self.player.numpos = vec2(g.touchesArr[1].touch.x,g.touchesArr[1].touch.y) + self.player.offset
                local d,k,y = 2000,false,self.player.numpos.y
                pushStyle()
                font(self.font)
                fontSize(self.fontsize)
                local lw = self.linewidth
                local cw,ch = RectAnchorOf(Screen,"centre")
                local pd = self.padding
                local nw,nh = textSize(self.max)
                local bh = nh + pd.t + pd.b + lw
                local lh = bh*5 - lw/2
                local tw = textSize(self.number)
                popStyle()
                for i=1,10 do
                    if self.player.pnumbers[i] then
                        if math.abs(ch-lh+(i-1.5)*bh+pd.b-y) < d then
                            d = math.abs(ch-lh+(i-1.5)*bh+pd.b-y)
                            k = i
                        end
                    end
                end
                if k then
                    self.player.lpos = k
                    self.player.fpos = vec2(3*cw/2+nw/2-tw,ch-lh+(k-1)*bh+pd.b)
                end
            end
        end
        if g.type.ended then
            if not self.number then
                self:restart()
                g:reset()
            else
                if (self.player.over or not self.player.active)
                and (self.computer.over or not self.computer.active)
                    then
                    if g.type.tap and g.num == 2 then
                        local n = self.number
                        for k=self.nnums,10 do
                            table.insert(self.player.fnumbers,n)
                            self.player.fnums = self.player.fnums + 1
                            table.insert(self.computer.fnumbers,n)
                            self.computer.fnums = self.computer.fnums + 1
                            n = math.random(self.max)
                        end
                        self.nnums = 10
                        self.number = false
                        g:reset()
                    elseif g.type.finished then
                        tween(self.delay,self,{animate = 1},tween.easing.quad, function()  self:newNumber() end)
                        g:reset()
                    end
                elseif self.animate == 0 then
                    tween(self.delay,self,{animate = 1},tween.easing.quad, function() self:newNumber() end)
                    g:reset()
                end
            end
        end
        g:noted()
    end
    
    return Ladder
    
end
