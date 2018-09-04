if _M then
    
function KnuthShuffle(n,odd,m)
    local l
    local o = 0
    local p = {}
    m = m or n-1
    m = math.min(m,n-1)
    for k = 1,n do
        p[k] = k
    end
    for k = 1,m do
        l = math.random(k,n)
        if l ~= k then
            p[k],p[l] = p[l],p[k]
            o = 1 - o
        end
    end
    if not odd and o == 1 then
        p[1],p[2] = p[2],p[1]
    end
    return p
end

function lonedist(a,b)
    return math.abs(a[1] - b[1]) + math.abs(a[2] - b[2])
end

function loneline(a,b)
    if a[1] ~= b[1] and a[2] ~= b[2] then
        return false
    elseif a[1] == b[1] and a[2] == b[2] then
        return vec2(0,0)
    else
        return vec2(b[1] - a[1],b[2] - a[2]):normalize()
    end
end

function foldem(r,c)
    return function (i,j)
            return (i-1)*c + j
        end,
        function (k)
            return {math.floor((k-1)/c)%r + 1,(k-1)%c + 1}
        end
end

function is_identity(p)
    for k,v in ipairs(p) do
        if v ~= k then
            return false
        end
    end
    return true
end

cmodule.gexport {
    KnuthShuffle = KnuthShuffle,
    lonedist = lonedist,
    loneline = loneline,
    foldem = foldem,
    is_identity = is_identity
}

end
