-- cmake .. -DCMAKE_BUILD_TYPE=Release -DTINYSPLINE_ENABLE_LUA=True  -DLUA_INCLUDE_DIR=/usr/include/lua5.1 -DLUA_LIBRARY=/usr/lib/arm-linux-gnueabihf/liblua5.1.so.0
-- cmake --build .
print(_VERSION)

if not string.find(package.cpath,"/home/we/dust/code/aaspline/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/aaspline/lib/?.so"
end
local ts = require("tinysplinelua53")
local MusicUtil = require "musicutil"

engine.name="PolyPerc"
curves={step=0}
points={1,32,128,32}
pos={1,32}

function init()

  notes = MusicUtil.generate_scale_of_length(24, 5, 48)

  clock.run(function()
    while true do
      clock.sleep(1/15)
      redraw()
    end
  end)
  
  curves.step=0
  clock.run(function()
      while true do
        clock.sync(1/4)
        curves.step=curves.step+1
        if curves.step > 128 then
          curves.step=1 
        end
        local spoints=points_to_spline(add_point(points,pos))
        local y=util.clamp(math.floor(spoints[curves.step][2]),1,64)
        local note_ind=util.clamp(math.floor(util.linlin(1,64,1,#notes+1,65-y)),1,#notes)
        print(y,notes[note_ind])
        engine.hz(MusicUtil.note_num_to_freq(notes[note_ind]))
      end
  end)
end

function enc(k,d)
  if k==2 then
    pos[1]=pos[1]+d
    if pos[1]>128 then
      pos[1]=128
    elseif pos[1]<1 then
      pos[1]=1
    end
    spoints=points_to_spline(points)
    pos[2]=spoints[pos[1]][2]
  elseif k==3 then
    pos[2]=pos[2]-d
    if pos[2]>64*2 then
      pos[2]=64*2
    elseif pos[2]<1-64 then
      pos[2]=1-64
    end
  end
end


function key(k,z)
  if k==2 and z==1 then
    points=add_point(points,pos)
  end
end

function points_to_spline(p)
  cubic=3
  if #p==4 then
    cubic=1
  elseif #p==6 then
    cubic=2
  end
  local spline = ts.BSpline(#p/2,2,cubic,ts.CLAMPED)
  spline.control_points=p
  beziers = spline:derive():to_beziers()
  spline_points={}
  for i=0,127 do
    -- table.insert(spline_points,beziers(i/127).result)
    table.insert(spline_points,spline:eval(i/127).result)
  end
  return spline_points
end

function add_point(ps,p)
  local ps2={}
  local inserted=false
  for i=1,#ps,2 do
    if (p[1]<ps[i] or p[1]==ps[i]) and not inserted then
     table.insert(ps2, p[1])
     table.insert(ps2, p[2])
     inserted=true
     if p[1]<ps[i] then
      table.insert(ps2,ps[i])
      table.insert(ps2,ps[i+1])
      end
    else
      table.insert(ps2,ps[i])
      table.insert(ps2,ps[i+1])
   end
  end
  return ps2
end

function redraw()
  screen.clear()

  screen.level(1)
  screen.move(curves.step,1)
  screen.line(curves.step,64)
  screen.stroke()


  local spoints=points_to_spline(add_point(points,pos))
  for i,point in ipairs(spoints) do
    ps={math.floor(point[1]),math.floor(point[2])}
    if i > 1 then 
      screen.level(7)
      screen.pixel(ps[1],ps[2])
      screen.fill()
      -- screen.line(ps[1],ps[2])
      -- screen.stroke()
      -- screen.move(ps[1],ps[2])
    end
  end

  local placed={}
  local placedcur=false
  for i,point in ipairs(spoints) do
    ps={math.floor(point[1]),math.floor(point[2])}
    for j=1,#points,2 do
      if (points[j]==ps[1] or pos[1]==ps[1]) and placed[ps[1]]==nil then
        if pos[1]==ps[1] and not placedcur then
          screen.level(0)
          screen.circle(ps[1],ps[2],3)
          screen.fill()
          screen.level(7)
          screen.circle(ps[1],ps[2],3)
          screen.stroke()
          placedcur=true
        end
        if points[j]==ps[1] then
          screen.level(7)
          screen.circle(ps[1],ps[2],2)
          screen.fill()
          placed[ps[1]]=true
        end
      end
    end
  end

  screen.update()
end




-- -- Create a cubic spline with 7 control points in 2D using
-- -- a clamped knot vector. This call is equivalent to:
-- -- spline = ts.BSpline(7, 2, 3, ts.CLAMPED)
-- spline = ts.BSpline(3,2,1)

-- -- Setup control points.
-- ctrlp = spline.control_points
-- ctrlp[1]  = 32 -- x0
-- ctrlp[2]  = 1  -- y0
-- ctrlp[3]  = 48 -- x0
-- ctrlp[4]  = 1  -- y0
-- -- ctrlp[5]  = -1.5  -- x2
-- -- ctrlp[6]  =  0.0  -- y2
-- -- ctrlp[7]  = -1.25 -- x3
-- -- ctrlp[8]  =  0.5  -- y3
-- -- ctrlp[9]  = -0.75 -- x4
-- -- ctrlp[10] =  0.75 -- y4
-- -- ctrlp[11] =  0.0  -- x5
-- -- ctrlp[12] =  0.5  -- y5
-- -- ctrlp[13] =  0.5  -- x6
-- -- ctrlp[14] =  0.0  -- y6
-- spline.control_points = ctrlp

-- -- Evaluate `spline` at u = 0.4 using 'eval'.
-- result = spline:eval(0.25).result
-- print("x = ", result[1], "y = ", result[2]);

-- -- Derive `spline` and subdivide it into a sequence of Bezier curves.
-- beziers = spline:derive():to_beziers()
-- print(beziers)
-- -- Evaluate `beziers` at u = 0.3 using '()' instead of 'eval'.
-- result = beziers(0.5).result
-- print("num results: "..#result)
-- print("x = ", result[1], "y = ", result[2]);

