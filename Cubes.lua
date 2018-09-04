if _M then
local Game = cimport "Game"
-- cimport "MeshUtilities"
cimport "VecExt"
cimport "TouchUtilities"
cimport "NumberSpinner"
    cimport "ColourWheel"
local Colour = cimport "Colour"
local View = cimport "View"
local define_cube
local parse_moves
    local img = image(1,1)
    setContext(img)
    pushMatrix()
    popMatrix()
    setContext()
Cube = class(Game)

local fc = {
    Colour.svg.Red,
    Colour.svg.Purple,
    Colour.svg.Yellow,
    Colour.svg.White,
    Colour.svg.Green,
    Colour.svg.Blue,
    Colour.svg.Black
}
local rt = 1/math.sqrt(2)

local sr = {
    {vec4(rt,rt,0,0),{1,3,-2}},
    {vec4(rt,0,rt,0),{-3,2,1}},
    {vec4(rt,0,0,rt),{2,-1,3}}
}

function Cube:init(u,t)
        _G["stuff"] = "RPYWGB"
        parameter.watch("stuff")
    Game.init(self,u)
        self.ui = u
    self.size = 3
    self.cubes, self.sides = define_cubes(self.size)
    self.bkcolour = Colour.svg.DarkSlateGrey
    self.view = View()
    self.view.eye = vec3(0,0,5*self.size)
    self.toucher = {{t:registerHandler(self),t:registerHandler(self.view)}}
    self.moves = {}
    local m = self.options
    local pm = u:addMenu()
    pm:isChildOf(m)
    m:addItem({
        title = "Reset",
        action = function() self:restart() return true end
    })
    m:addItem({
        title = "Mix",
        action = function() self:mix() return true end
    })
    m:addItem({
        title = "Set number of sides",
        action = function()
            u:getNumberSpinner({
                value = self.size,
                maxdecs = 0,
                allowSignChange = false,
                action = function(n)
                    self.size = n
                    self.cubes, self.sides = define_cubes(n)
                    self.view.eye = vec3(0,0,5*self.size)
                    return true
                end
            })
            return true
        end
    })
        m:addItem({
            title = "Set face colours",
            action = function()
                self.settingColours = not self.settingColours
                return true
            end,
            highlight = function()
                return self.settingColours
            end
        })
    m:addItem({
        title = "Record Moves",
        action = function()
            self.record = not self.record
            return true
        end,
        highlight = function()
            return self.record
        end
    })
    m:addItem({
        title = "Undo last move",
        action = function()
            if self.last then
                self:rotateSide(self.last[1],4-self.last[2])
                self.last = nil
                if self.record then
                    table.remove(self.moves)
                end
            end
            return true
        end,
        highlight = function()
                if self.last then
                    return true
                end
                return false
            end
    })
    m:addItem({
        title = "Save moves",
        action = function()
            local s = {}
            for k,v in ipairs(self.moves) do
                table.insert(s,v[1] .. " " .. v[2])
            end
            pasteboard.copy(table.concat(s,"\n"))
            return true
        end
    })
    local mvs = parse_moves()
    if #mvs > 0 then
        m:addItem({
            title = "Play Moves",
            action = function(x,y)
                pm.active = not pm.active
                pm.x,pm.y = x,y
            end,
            highlight = function()
                return pm.active
            end,
            deselect = function()
                pm:deactivateDown()
            end
        })
        for k,v in ipairs(mvs) do
            pm:addItem({
                title = v[1],
                action = function()
                    if self.size ~= v[2] then
                        self.size = v[2]
                        self.cubes, self.sides = define_cubes(v[2])
                        self.view.eye = vec3(0,0,5*self.size)
                    else
                        self:restart()
                    end
                    self:playMoves(v[3])
                    return true
                end,
            })
        end
    end
    m:addItem({
        title = "Use Gravity",
        action = function()
            self.view:gravityOnOff()
            return true
        end,
        highlight = function()
            return self.view.useGravity
        end
    })
end

function Cube:restart()
    self.actions = {}
    local rt = {}
    local pt = {}
    for k,v in ipairs(self.cubes) do
        rt[k] = v[3]:make_slerp(vec4(1,0,0,0))
        pt[k] = v[2] - (self.size+1)/2
    end
    local st = ElapsedTime
    self.action = function(t)
        t = t - st
        if t < 3 then
            t = smootherstep(t,0,3) + 1
            for k,v in ipairs(self.cubes) do
                 v[2] = t*pt[k] + (self.size+1)/2
            end
        elseif t < 6 then
            t = smootherstep(t,3,6)
            for k,v in ipairs(self.cubes) do
                 v[3] = rt[k](t)
            end
        elseif t < 9 then
            t = smootherstep(t,9,6) + 1
            for k,v in ipairs(self.cubes) do
                 v[2] = t*pt[k] + (self.size+1)/2
            end
        elseif t > 12 then
            local n = self.size
            local s = {}
            for i=1,3*n do
                table.insert(s,{})
            end
            local sd
            for k,v in ipairs(self.cubes) do
                v[2] = pt[k] + (self.size+1)/2
                v[3] = vec4(1,0,0,0)
                sd = {}
                table.insert(s[v[2].x],k)
                table.insert(sd,v[2].x)
                table.insert(s[n+v[2].y],k)
                table.insert(sd,n+v[2].y)
                table.insert(s[2*n+v[2].z],k)
                table.insert(sd,2*n+v[2].z)
                v[4] = sd
            end
            self.sides = s
            return false
        end
        return true
    end
end

function Cube:mix()
    local m,n = math.random(1,3*self.size),math.random(10*(self.size-1),10*self.size)
    for k=1,n do
        m = math.random(m,m+3*self.size-2)%(3*self.size) + 1
        self:rotateSide(m,math.random(2,4)%4-1)
    end
end

function Cube:activate()
    self.actions = {}
    local n = self.size
    local s = {}
    for i=1,3*n do
        table.insert(s,{})
    end
    local sd
    for k,v in ipairs(self.cubes) do
        v[3] = vec4(1,0,0,0)
        sd = {}
        table.insert(s[v[2].x],k)
        table.insert(sd,v[2].x)
        table.insert(s[n+v[2].y],k)
        table.insert(sd,n+v[2].y)
        table.insert(s[2*n+v[2].z],k)
        table.insert(sd,2*n+v[2].z)
        v[4] = sd
    end
    self.sides = s
end

function Cube:touchReceiver()
    return self.toucher
end

function Cube:draw()
    background(self.bkcolour)
    self:update()
    self.view:draw()
    self.matrix = viewMatrix() * projectionMatrix()
    for k,v in ipairs(self.cubes) do
        pushMatrix()
        rotate(v[3])
        translate(v[2] - (self.size+1)/2)
        v[1]:draw()
        popMatrix()
    end
end

function Cube:rotateSide(s,t)
    table.insert(self.actions,{s,t})
end

function Cube:update()
    if self.action then
        if not self.action(ElapsedTime) then
            self.action = nil
        end
    else
        local a = table.remove(self.actions,1)
        if a then
            local st = ElapsedTime
            local r = {}
            local org = {}
            local ar = math.floor((a[1]-1)/self.size)+1
            for k,v in ipairs(self.sides[a[1]]) do
                org[k] = self.cubes[v][3]
                r[k] = sr[ar][1]:make_slerp()
            end

            self.action = function(t)
                t = t - st
                if t > 1 then
                    local nr = a[2]%4
                    if nr > 0 then
                        local p
                        for k,v in ipairs(self.sides[a[1]]) do
                            self.cubes[v][3] = sr[ar][1]^a[2] * org[k]
for r=1,nr do
                            for l,u in ipairs(self.cubes[v][4]) do
                                p = math.floor((u-.5)/self.size)+1
                                u = (u-1)%self.size
                                p = sr[ar][2][p]
                                if p > 0 then
                                    self.cubes[v][4][l] = (p-1)*self.size + u + 1
                                else
                                    self.cubes[v][4][l] = -p*self.size - u
                                end
                            end
                        end
end
                        local n = self.size
                        local s = {}
                        for i=1,3*n do
                            table.insert(s,{})
                        end
                        for k,v in ipairs(self.cubes) do
                            for l,u in ipairs(v[4]) do
                                table.insert(s[u],k)
                            end
                        end
                        self.sides = s
                    end
                    return false
                end
                t = smootherstep(t,0,1)*a[2]
                for k,v in ipairs(self.sides[a[1]]) do
                    self.cubes[v][3] = r[k](t) * org[k]
                end
                return true
            end
        end
    end
end

function Cube:processTouches(g)
    -- self.view:processTouches(g)
        if self.settingColours then
            if g.type.ended then
                local c,x,y,z
                x,y,z = self.tside.x,self.tside.y,self.tside.z
                for k,v in ipairs(self.sides[x]) do
                    for l,u in ipairs(self.sides[y]) do
                        if u == v then
                            for m,w in ipairs(self.sides[z]) do
                                if u == w then
                                    c = u
                                end
                            end
                        end
                    end
                end
                if c then
                    local n = self.plane[2]:cross(self.plane[3])
                    if z%self.size == 1 then
                        n = -n
                    end
                    n = n^(self.cubes[c][3]^"")
                    local sd
                    if math.abs(n.x) >= math.abs(n.y) and math.abs(n.x) >= math.abs(n.z) then
                        if n.x > 0 then
                            sd = 2
                        else
                            sd = 1
                        end
                    elseif math.abs(n.y) >= math.abs(n.z) then
                        if n.y > 0 then
                            sd = 4
                        else
                            sd = 3
                        end
                    else
                        if n.z > 0 then
                            sd = 6
                        else
                            sd = 5
                        end
                    end
                    self.ui:getColour(
                        fc[sd],
                        function(c)
                            fc[sd] = c
                            self:resetColours()
                            return true
                        end
                    )
                end
                g:reset()
                return
            end
            g:noted()
            return
        end
    if g.type.ended then
        local tc = screentoplane(g.touchesArr[1].touch,
                   self.plane[1],
                   self.plane[2],
                   self.plane[3],
                   self.matrix) - self.plane[1] - self.starttouch
        local x,y = tc:dot(self.plane[2]),tc:dot(self.plane[3])
        if vec2(x,y):lenSqr() < 1 then
            g:reset()
            return
        end
        local f,d

        if math.abs(y) > math.abs(x) then
            f = "x"
            if y > 0 then
                d = 1
            else
                d = -1
            end
        else
            f = "y"
            if x > 0 then
                d = 1
            else
                d = -1
            end
        end
-- print(self.tside,self.tdir,f,d)
        self.last = {self.tside[f],d*self.tdir[f]}
        if self.record then
            table.insert(self.moves,{self.tside[f],d*self.tdir[f]})
        end
        self:rotateSide(self.tside[f],d*self.tdir[f])
        g:reset()
    end
    g:noted()
end

-- This returns "true" if we claim the touch
function Cube:isTouchedBy(t)
    if self.action then
        return false
    end
    -- Compute the vector along the ray defined by the touch
    local n = screennormal(t,self.matrix)
    local plane,dir,face
    -- The next segments of code ask if the touch fell on one of the
    -- faces of the cube.  We use the normal vector to determine
    -- which faces are towards the viewer.  Then for each face that
    -- is towards the viewer, we test if the touch point was on that
    -- face.
    local o = -self.size/2*vec3(1,1,1)
    local x,y,z = vec3(self.size,0,0),vec3(0,self.size,0),vec3(0,0,self.size)
    if n.z > 0 then
        plane = {o + z,x,y}
        dir = vec2(-1,1)
            face = self.size*3
    else
        plane = {o,x,y}
        dir = vec2(1,-1)
            face = self.size*2+1
    end
    if self:touchFace(plane,t) then
        self.tside = vec3(self.tcube.x,self.tcube.y + self.size,face)
        self.tdir = dir
        return true
    end
    if n.y > 0 then
        plane = {o+y,z,x}
        dir = vec2(-1,1)
            face = self.size*2
    else
        plane = {o,z,x}
        dir = vec2(1,-1)
            face = self.size+1
    end
    if self:touchFace(plane,t) then
        self.tside = vec3(self.tcube.x + 2*self.size,self.tcube.y,face)
        self.tdir = dir
        return true
    end
    if n.x > 0 then
        plane = {o+x,y,z}
        dir = vec2(-1,1)
            face = self.size
    else
        plane = {o,y,z}
        dir = vec2(1,-1)
            face = 1
    end
    if self:touchFace(plane,t) then
        self.tside = vec3(self.tcube.x + self.size,self.tcube.y + 2*self.size,face)
        self.tdir = dir
        return true
    end
    return false
end

-- This tests if the touch point is on a particular face.
-- A face defines a plane in space and generically the touch line
-- will intersect that plane once.  We compute that point and
-- test if it is on the corresponding face.
-- If so, we save the plane as that will be our plane of movement
-- while this touch is active.
-- As the position and size are encoded in the matrix, when we test
-- coordinates we just need to test against the original cube where
-- the faces are [0,1]x[0,1]
function Cube:touchFace(plane,t)
    local tc = screentoplane(t,
                   plane[1],
                   plane[2],
                   plane[3],
                   self.matrix)
    tc = tc - plane[1] 
    if tc:dot(plane[2]) > 0 and tc:dot(plane[2]) < plane[2]:lenSqr() and
       tc:dot(plane[3]) > 0 and tc:dot(plane[3]) < plane[3]:lenSqr() then
        local n = self.size
        local i = math.floor(n*tc:dot(plane[2])/plane[2]:lenSqr())+1
        local j = math.floor(n*tc:dot(plane[3])/plane[3]:lenSqr())+1
        self.tcube = vec2(i,j)
        self.plane = plane
        self.starttouch = tc
        self.smatrix = self.matrix
        return true
    end
    return false
end

function define_cubes(n)
    local s = {}
    for i=1,3*n do
        table.insert(s,{})
    end
    local c = {}
    local f = {}
        local tf
    local ind = 0
    local sd
    local ki
    for i=1,n do
        f[1] = (i == 1 and 1) or 7
        f[2] = (i == n and 2) or 7
        for j=1,n do
            f[3] = (j == 1 and 3) or 7
            f[4] = (j == n and 4) or 7
            if i == 1 or i == n or j == 1 or j == n then
                ki = 1
            else
                ki = n - 1
            end
            for k=1,n,ki do
                f[5] = (k == 1 and 5) or 7
                f[6] = (k == n and 6) or 7
                ind = ind + 1
                sd = {}
                    tf = {}
                    for l,u in ipairs(f) do
                        table.insert(tf,u)
                    end
                table.insert(s[i],ind)
                table.insert(sd,i)
                table.insert(s[n+j],ind)
                table.insert(sd,n+j)
                table.insert(s[2*n+k],ind)
                table.insert(sd,2*n+k)
                table.insert(c,{define_cube(f),vec3(i,j,k),vec4(1,0,0,0),sd,tf})
            end
        end
    end
    return c,s
end

function define_cube(faces)
    local cube = mesh()
    local i = image(1,1)
    i:set(1,1,255,255,255,255)
    cube.shader = cimport "Border"
    cube.shader.width = .03
    cube.shader.antialias = .01
    cube.texture = i
    local corners = {}
    for l=0,7 do
        i,j,k=l%2,math.floor(l/2)%2,math.floor(l/4)%2
        table.insert(corners,vec3(i-.5,j-.5,k-.5))
    end
    local nrm = {vec3(1,0,0),vec3(0,1,0),vec3(0,0,1)}
    local tx = {{"y","z"},{"z","x"},{"x","y"}}
    local vertices = {}
    local colours = {}
        local cindices = {}
    local normals = {}
    local texc = {}
    local u
    for l=0,2 do
        for i=0,1 do
            for k=0,1 do
                for j=0,2 do
                    u = (i*2^l + ((j+k)%2)*2^((l+1)%3)
                    + (math.floor((j+k)/2)%2)*2^((l+2)%3)) + 1
                    table.insert(vertices,corners[u])
                    table.insert(colours,fc[faces[2*l+1+i]])
                    table.insert(normals,(i*2-1)*nrm[l+1])
                    table.insert(texc,vec2(corners[u][tx[l+1][1]]+.5,corners[u][tx[l+1][2]]+.5))
                end
            end
        end
    end
    
    cube.vertices = vertices
    cube.colors = colours
    cube.normals = normals
    cube.texCoords = texc
    return cube
end
    
    function set_colours(cube,faces)
        local colours = {}
        for l=0,2 do
            for i=0,1 do
                for k=0,1 do
                    for j=0,2 do
                        table.insert(colours,fc[faces[2*l+1+i]])
                    end
                end
            end
        end
        cube.colors = colours
    end
    
    function Cube:resetColours()
        for k,v in ipairs(self.cubes) do
            set_colours(v[1],v[5])
        end
    end

function Cube:playMoves(t)
    for k,v in ipairs(t) do
        self:rotateSide(v[1],v[2])
    end
end

local moves = {}
function parse_moves()
    local t = {}
    local i,j,m,s,a,b,c,d
    for k,v in ipairs(moves) do
        m = {}
        i = v:find("\n")
        m[1] = v:sub(1,i-1)
        j = v:find("\n",i+1)
        m[2] = tonumber(v:sub(i+1,j-1))
        m[3] = {}
        while v:find("\n",j+1) do
            i = j+1
            j = v:find("\n",i)
            s = v:sub(i,j-1)
            a,b = s:match("(%d+) (-?%d+)")
            a = tonumber(a)
            b = tonumber(b)
            if a == c then
                d = d + b
            else
                if c then
                    d = (d+1) % 4 -1
                    if d ~= 0 then
                        table.insert(m[3],{c,d})
                    end
                end
                c,d = a,b
            end
        end
        if c then
            d = (d+1) % 4 -1
            if d ~= 0 then
                table.insert(m[3],{c,d})
            end
        end
        table.insert(t,m)
    end
    return t
end

moves = {
[[
Norwegian Flag
9
27 -1
18 -1
27 1
5 -1
5 -1
27 -1
18 1
27 1
5 1
5 -1
18 -1
5 -1
18 1
18 1
18 -1
5 1
5 1
14 1
9 1
5 1
23 1
23 1
9 -1
23 -1
5 -1
4 -1
5 -1
6 -1
19 1
13 1
13 1
14 1
14 1
15 1
15 1
19 -1
24 1
23 1
22 1
15 -1
14 -1
13 -1
]]
}

return Cube

end
