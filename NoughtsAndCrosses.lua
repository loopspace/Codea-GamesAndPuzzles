if _M then
    local Game = cimport "Game"
    local _,Sentence,_ = unpack(cimport "Font")
    NoughtsAndCrosses = class(Game)

    function NoughtsAndCrosses:init(u)
        Game.init(self,u)
        self.ui = u
        self.grid = {0,0}
        self.grids = {
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
        }
        self.hgrid = nil
        self.turn = 0
        self.score = {0,0,0}
        self.ai = 0
        self.aimode = 0
        self.length = 0
        self.lengths = {}
        for k=1,81 do
            self.lengths[k] = 0
        end
        self.ngames = 0
        self.game = {}
        self.learning = {}
        self.weights = { {1,0,0,0}, {1,1,1,1}}
        local m = self.options
        local pa = self.ui:addMenu()
        local pt = self.ui:addMenu()
        m:addSubMenu("Player 1",pa)
        pa:addItem({
            title = "Human",
            action = function()
                self.ai = self.ai & 2
                return true
            end,
            highlight = function()
                return self.ai & 1 == 0
            end
        })
        pa:addSubMenu("Computer", pt)
        pt:addItem({
            title = "AI",
            action = function()
                self.ai = self.ai | 1
                self.aimode = self.aimode | 1
                return true
            end,
            highlight = function()
                return (self.ai & 1 == 1) and (self.aimode & 1 == 1)
            end
        })
        pt:addItem({
            title = "Random",
            action = function()
                self.ai = self.ai |1
                self.aimode = self.aimode & 2
                return true
            end,
            highlight = function()
                return (self.ai & 1 == 1) and (self.aimode & 1 == 0)
            end
        })
        pa = self.ui:addMenu()
        pt = self.ui:addMenu()
        m:addSubMenu("Player 2",pa)
        pa:addItem({
            title = "Human",
            action = function()
                self.ai = self.ai & 1
                return true
            end,
            highlight = function()
                return self.ai & 2 == 0
            end
        })
        pa:addSubMenu("Computer", pt)
        pt:addItem({
            title = "AI",
            action = function()
                self.ai = self.ai | 2
                self.aimode = self.aimode | 2
                return true
            end,
            highlight = function()
                return (self.ai & 2 == 2) and (self.aimode & 2 == 2)
            end
        })
        pt:addItem({
            title = "Random",
            action = function()
                self.ai = self.ai |2
                self.aimode = self.aimode & 1
                return true
            end,
            highlight = function()
                return (self.ai & 2 == 2) and (self.aimode & 2 == 0)
            end
        })
        m:addItem({
            title = "Autostart",
            action = function()
                self.auto = not self.auto
                return true
            end,
            highlight = function()
                return self.auto
            end
        })
        m:addItem({
            title = "Training Mode",
            action = function()
                self:restart()
                if self.train then

                    self.train = false
                else
                    self.ai = 3
                    self.train = true
                    self.auto = false
                end
                return true
            end,
            highlight = function()
                return self.train
            end
        })
        m:addItem({
            title = "Restart/New Game",
            action = function()
                self:restart()
                return true
            end
        })
        m:addItem({
            title = "Reset Scores",
            action = function()
                self:reset()
                return true
            end
        })
        m:addItem({
            title = "Save Training",
            action = function()
            self:saveTraining()
            return true
        end
        })
        m:addItem({
            title = "Load Training",
            action = function()
            self:loadTraining()
            return true
        end
        })
    end

    function NoughtsAndCrosses:draw()
        pushStyle()
        
        strokeWidth(5)
        lineCapMode(ROUND)
        stroke(198)
        
        pushMatrix()

        
        rectMode(CORNERS)
        
        translate(WIDTH/2,HEIGHT/2)
        local s = math.min(WIDTH,HEIGHT)/2 - 30
        local ss = s/3 - 30
        local i,j,k,r,c
        
        if self.hgrid ~= nil then
            i = self.hgrid%3 - 1
            j = self.hgrid//3 - 1
            pushMatrix()
            pushStyle()
            translate(2*i*s/3,2*j*s/3)
            noStroke()
            fill(230, 221, 88, 255)
            rect(-ss-10,-ss-10,ss+10,ss+10)
            popStyle()
            popMatrix()
        end
        
        if self.touchedSquare then
            i = self.touchedSquare[1]%3 - 1
            j = self.touchedSquare[1]//3 - 1
            pushMatrix()
            pushStyle()
            translate(2*i*s/3,2*j*s/3)
            i = self.touchedSquare[2]%3 - 1
            j = self.touchedSquare[2]//3 - 1
            translate(2*i*ss/3,2*j*ss/3)
            noStroke()
            fill(229, 87, 190, 255)
            rect(-ss/3-10,-ss/3-10,ss/3+10,ss/3+10)
            popStyle()
            popMatrix()
        end
        
        line(s/3,-s,s/3,s)
        line(-s/3,-s,-s/3,s)
        line(-s,s/3,s,s/3)
        line(-s,-s/3,s,-s/3)
        
        
        for i=-1,1 do
            for j=-1,1 do
                k = (i+1) + (j+1)*3
                if self.grid[1] & 2^k == 0 then
                    stroke(198)
                else
                    stroke(99)
                end
                pushMatrix()
                translate(2*i*s/3,2*j*s/3)
                line(ss/3,-ss,ss/3,ss)
                line(-ss/3,-ss,-ss/3,ss)
                line(-ss,ss/3,ss,ss/3)
                line(-ss,-ss/3,ss,-ss/3)

                popMatrix()
            end
        end
        
        stroke(255)
        noFill()
        for k,g in ipairs(self.grids) do
            pushMatrix()
            i = (k-1)%3 - 1
            j = (k-1)//3 - 1
            translate(2*i*s/3,2*j*s/3)
            r = self:checkGame(g)
            if r[1] & 2 == 2 then
                c = {}
                l = 0
                while r[2] ~= 0 do
                    if r[2] & 1 == 1 then
                        table.insert(c,l)
                    end
                    r[2] = r[2] >> 1
                    l = l + 1
                end
                pushStyle()
                strokeWidth(20)
                stroke(198,0,0)
                line((c[1]%3-1)*2*ss/3,(c[1]//3-1)*2*ss/3,(c[3]%3-1)*2*ss/3,(c[3]//3-1)*2*ss/3)
                popStyle()
            end
            for l=0,8 do
                if g[1] & 2^l ~=0 then
                    pushMatrix()
                    pushStyle()
                    if self.lastMove and self.lastMove[1] == k-1 and self.lastMove[2] == l then
                        stroke(198,0,0)
                    end
                    i = l%3 - 1
                    j = l//3 - 1
                    translate(2*i*ss/3,2*j*ss/3)
                    if g[2] & 2^l == 0 then
                        ellipse(0,0,ss/3-10)
                    else
                        line(-ss/3+10,-ss/3+10,ss/3-10,ss/3-10)
                        line(-ss/3+10,ss/3-10,ss/3-10,-ss/3+10)
                    end
                    popStyle()
                    popMatrix()
                end
            end
            popMatrix()
        end
        
        pushStyle()
        stroke(255)
        strokeWidth(15)
        for i=-1,1 do
            for j=-1,1 do
                k = (i+1) + (j+1)*3
                
                pushMatrix()
                translate(2*i*s/3,2*j*s/3)
                if self.grid[1] & 2^k ~= 0 then

                    if self.grid[2] & 2^k == 0 then
                        ellipse(0,0,s/3-10)
                    else
                        line(-s/3+17.5,-s/3+17.5,s/3-17.5,s/3-17.5)
                        line(-s/3+17.5,s/3-17.5,s/3-17.5,-s/3+17.5)
                    end
                elseif self.grid[2] & 2^k ~= 0 then
                    pushStyle()
                    noStroke()
                    fill(0,198)
                    rect(-s/3+10,-s/3+10,s/3-10,s/3-10)
                    popStyle()
                end
                popMatrix()
            end
        end
        popStyle()
        
        popMatrix()
        pushMatrix()
        local a
        if WIDTH > HEIGHT then
            translate(WIDTH,HEIGHT/2)
            a = 0
        else
            translate(WIDTH/2,HEIGHT)
            rotate(90)
            a = -90
        end
        translate(-1.5*ss/3,ss/3)
        if self.turn == 0 then
            pushStyle()
            noStroke()
            fill(230, 221, 88, 255)
            rect(-ss/3,-ss/3,ss/3,ss/3)
            popStyle()
        end
        ellipse(0,0,ss/3-10)
        pushMatrix()
        translate(-2*ss/3,0)
        rotate(a)
        fill(255, 255, 255, 255)
        fontSize(30)
        text(self.score[1])
        popMatrix()
        translate(0,-2*ss/3)
        if self.turn ~= 0 then
            pushStyle()
            noStroke()
            fill(230, 221, 88, 255)
            rect(-ss/3,-ss/3,ss/3,ss/3)
            popStyle()
        end
        line(-ss/3+10,-ss/3+10,ss/3-10,ss/3-10)
        line(-ss/3+10,ss/3-10,ss/3-10,-ss/3+10)
        pushMatrix()
        translate(-2*ss/3,0)
        rotate(a)
        text(self.score[2])
        popMatrix()
        translate(0,-2*ss/3)
        noFill()
        ellipse(0,0,ss/3-10)
        line(-ss/3+10,-ss/3+10,ss/3-10,ss/3-10)
        line(-ss/3+10,ss/3-10,ss/3-10,-ss/3+10)
        pushMatrix()
        translate(-2*ss/3,0)
        rotate(a)
        fill(255, 255, 255, 255)
        fontSize(30)
        text(self.score[3])
        popMatrix()

        popMatrix()
        popStyle()
        
        pushMatrix()
        local d,e
        if WIDTH > HEIGHT then
            d = vec2(0,1)
            e = vec2(1,0)
        else
            d = vec2(1,0)
            e = vec2(0,1)
        end
        m = 1
        for k,v in ipairs(self.lengths) do
            m = math.max(m,v)
        end
        lineCapMode(SQUARE)
        strokeWidth(1)
        stroke(127)
        for k=1,8 do
            line(50*k*d,50*k*d+120*e)
        end
        strokeWidth(5)
        for k,v in ipairs(self.lengths) do
            if k%5 == 0 then
                stroke(174)
            else
                stroke(87)
            end
            line((5*k+2.5)*d,(5*k+2.5)*d+100*v*e/m)
        end
        popMatrix()
        

        if self.train then
            if self.winner then
                self:restart()
            else
                if not self.paused then
                    while self.winner == nil do
                        local m = self:validMoves()
                        local k = self:chooseMove(m)
                        self:doMove(m[k])
                    end
                end
            end
        else
            if not self.paused then
                if self.ai & 2^self.turn ~= 0 then
                    local m = self:validMoves()
                    local k = self:chooseMove(m)
                    self:doMove(m[k])
                end
            end
        end
    end
    
    function NoughtsAndCrosses:isTouchedBy(t)
        --[[
        if not self.paused then
            if self.ai & 2^self.turn ~= 0 then
                local m = self:validMoves()
                local k = math.random(1,#m)
                self:doMove(m[k])
                return false
            end
        end
        --]]
        return not self.paused
    end
    
    function NoughtsAndCrosses:processTouches(g)
        local s = math.min(WIDTH,HEIGHT)/2 - 30
        local ss = s/3 - 30
        local tpt = g.touchesArr[1]:tovec2()
        tpt = tpt - vec2(WIDTH,HEIGHT)/2
        local sqr = (tpt/(2*s/3) + vec2(.5,.5))//1
        local ssqr = ((tpt - sqr*(2*s/3))/(2*ss/3) + vec2(.5,.5))//1
        local a = sqr.x + 3*sqr.y+4
        local b = ssqr.x+3*ssqr.y+4
        
        if self.hgrid ~= nil and self.hgrid ~= a then
            self.touchedSquare = nil
        elseif self.grid[1] & 2^a == 2^a then
            self.touchedSquare = nil
        elseif self.grids[a+1][1] & 2^b == 2^b then
            self.touchedSquare = nil
        else
            self.touchedSquare = {a,b}
        end
        
        
        g:noted()
        if g.type.ended then
            if self.touchedSquare then
                self:doMove(self.touchedSquare)
            end
            self.touchedSquare = nil
            g:reset()
        end
    end
    
    function NoughtsAndCrosses:doMove(s)
        self.lastMove = s
        self.length = self.length + 1
        local a,b = s[1],s[2]
        self.grids[a+1][1] = self.grids[a+1][1] + 2^b
        self.grids[a+1][2] = self.grids[a+1][2] + self.turn * 2^b
        
        if (self.grid[1] & 2^b) | (self.grid[2] & 2^b) == 2^b then
            self.hgrid = nil
        else
            self.hgrid = b
        end
        
        table.insert(self.game,self:getState())
        
        local r = self:checkGame(self.grids[a+1])
        if r[1] ~= 0 then
            if r[1] & 2 == 2 then
                self.grid[1] = self.grid[1] + 2^a
                self.grid[2] = self.grid[2] + self.turn * 2^a
            else
                self.grid[2] = self.grid[2] + 2^a
            end
            if a == b then
                self.hgrid = nil
            end
            r = self:checkGame(self.grid)
            if r[1] & 2 == 2 then
                if self.turn == 0 then
                    self.ui:addNotice({text = "Os win!",time = 1, fadeTime = .5})
                else
                    self.ui:addNotice({text = "Xs win!",time = 1, fadeTime = .5})
                end
                self.paused = true
                self.hgrid = nil
                self.winner = self.turn + 1
                self:updateScores()
                return
            elseif self:checkDraw(self.grid) then
                self.ui:addNotice({text = "It's a draw!",time = 1, fadeTime = .5})
                self.paused = true
                self.hgrid = nil
                self.winner = 3
                self:updateScores()
                return
            end
        end
        self.turn = self.turn ~ 1
    end
    
    local lines = {
        7,7 << 3, 7 << 6, 73, 73 << 1, 73 << 2, 1+16+256, 4+16+64
    }
    
    function NoughtsAndCrosses:checkGame(g)
        for k,v in ipairs(lines) do
            if g[1] & v == v then
                if g[2] & v == v then
                    return {3,v}
                end
                if g[2] & v == 0 then
                    return {2,v}
                end
            end
        end
        if g[1] == 511 then
            return {1}
        end
        return {0}
    end
    
    function NoughtsAndCrosses:checkDraw(g)
        local r = self:checkGame(g)
        if r[1] & 2 == 2 then
            return false
        end
        if r[1] == 1 then
            return true
        end
        for k,v in ipairs(lines) do
            if (g[1] & v) | (g[2] & v) ~= v then
                return false
            end
        end
        return true
    end
    
    function NoughtsAndCrosses:updateScores()
        if self.winner ~= nil then
            self.score[self.winner] = self.score[self.winner] + 1
            for k,v in ipairs(self.game) do
                if self.learning[v] == nil then
                    self.learning[v] = {0,0,0}
                end
                self.learning[v][self.winner] = self.learning[v][self.winner] + 1
            end
        end
        self.lengths[self.length] = self.lengths[self.length] + 1
        self.ngames = self.ngames + 1
        if self.auto then
            self:restart()
        end
    end
    
    function NoughtsAndCrosses:restart()
        self.grid = {0,0}
        self.grids = {
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
            {0,0},
        }
        self.hgrid = nil
        self.turn = 0
        self.paused = false
        self.winner = nil
        self.game = {}
        self.length = 0
        if self.ngames > 1000 and isRecording() then
            stopRecording()
        end
    end
    
    function NoughtsAndCrosses:reset()
        self:restart()
        self.score = {0,0,0}
        self.lengths = {}
        for k=1,81 do
            self.lengths[k] = 0
        end
        self.ngames = 0
    end
    
    function NoughtsAndCrosses:validMoves()
        local r = {}
        local t
        if self.hgrid then
            t = {self.hgrid+1}
        else
            t = {1,2,3,4,5,6,7,8,9}
        end
        for k,v in ipairs(t) do
            if self.grid[1] & 2^(v-1) == 0 then
                local n = self.grids[v][1]
                for l=0,8 do
                    if n & 2^l == 0 then
                        table.insert(r,{v-1,l})
                    end
                end
            end
        end
        return r
    end
    
    function NoughtsAndCrosses:getState(s,l)
        s = s or self.grids
        l =l or self.lastMove
        return json.encode({s, l})
    end
    
    function NoughtsAndCrosses:cloneState()
        local s = {}
        for k,v in ipairs(self.grids) do
            table.insert(s,{v[1], v[2]})
        end
        local l
        if self.lastMove ~= nil then
            l = {self.lastMove[1],self.lastMove[2]}
        end
        return s,l
    end
    
    function NoughtsAndCrosses:scoreState(s,l)
        local k = self:getState(s,l)
        if self.learning[k] == nil then
            return 1
        else
            return (  self.weights[1][1]*self.learning[k][self.turn+1] 
                    + self.weights[1][2]*self.learning[k][2-self.turn]
                    + self.weights[1][3]*self.learning[k][3]
                    + self.weights[1][4])/
                    ( self.weights[2][1]*self.learning[k][self.turn+1] 
                    + self.weights[2][2]*self.learning[k][2-self.turn]
                    + self.weights[2][3]*self.learning[k][3]
                    + self.weights[2][4])
        end
    end
    
    function NoughtsAndCrosses:chooseMove(m)
        if self.aimode & 2^self.turn == 0 then
            return math.random(#m)
        end
        local a,b
        local s,l = self:cloneState()
        local sc = {}
        local n = 0
        for k,v in ipairs(m) do
            l = v
            a,b = v[1],v[2]
            s[a+1][1] = s[a+1][1] + 2^b
            s[a+1][2] = s[a+1][2] + self.turn * 2^b
            n = n + self:scoreState(s,l)
            table.insert(sc,n)
            s[a+1][1] = s[a+1][1] - 2^b
            s[a+1][2] = s[a+1][2] - self.turn * 2^b
        end

        local m = math.random()*n
        local j = 1
        for k,v in ipairs(sc) do
            if v > m then
                j = k
                break
            end
        end
        return j
    end
    
    function NoughtsAndCrosses:saveTraining()
        local s = json.encode(self.learning)
        saveText("Documents:Noughts And Crosses",s)
    end
    
    function NoughtsAndCrosses:loadTraining()
        local s = readText("Documents:Noughts And Crosses")
        if s then
            self.learning = json.decode(s)
        end
    end

    
    return NoughtsAndCrosses
end