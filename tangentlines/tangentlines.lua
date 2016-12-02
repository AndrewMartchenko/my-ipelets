----------------------------------------------------------------------
-- Tangent Lines ipelet
----------------------------------------------------------------------
--[[

   This fle is part of the extensible drawing editor Ipe.
   Copyright (C) 1993-2016  Otfried Cheong

   Ipe is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   As a special exception, you have permission to link Ipe with the
   CGAL library and distribute executables, as long as you follow the
   requirements of the Gnu General Public License in regard to all of
   the software in the executable aside from CGAL.

   Ipe is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
   License for more details.

   You should have received a copy of the GNU General Public License
   along with Ipe; if not, you can find it at
   "http://www.gnu.org/copyleft/gpl.html", or write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

   --]]

   --[[
      TODO: make ipelet work with
      - splines
      --]]

      label = "Tangent Lines"


      about = [[
Draws tangent segments from a primary selected marker/circle/ellipse to all other selected markers, circles and ellipses.
By Andrew Martchenko
]]

A = ipe.Arc
S = ipe.Segment
V = ipe.Vector
M = ipe.Matrix
L = ipe.LineThrough

function create_objects(model, objects)

   if #objects>0 then
      local t = { label="tangent segments", 
		  pno=model.pno, 
		  vno=model.vno, 
		  layer=model:page():active(model.vno), 
		  objects=objects
      }
      t.undo = function (t, doc) 
	 for i = 1,#t.objects do
	    doc[t.pno]:remove(#doc[t.pno]) 
	 end
      end
      t.redo = function (t, doc) 
	 doc[t.pno]:deselectAll()
	 for _,obj in ipairs(t.objects) do
	    doc[t.pno]:insert(nil, obj.obj, obj.select, t.layer) 
	 end
	 doc[t.pno]:ensurePrimarySelection()
      end
      model:register(t)
   end
end

function make_segment(model, p1, p2)
   local shape = {type="curve", closed=false;
		  {type="segment"; p1, p2}}
   return ipe.Path(model.attributes, {shape} )
end


function get_object_type(obj)
   local matrix
   if obj:type()=="path" then
      if obj:shape()[1].type == "ellipse" then
	 matrix = obj:matrix()*obj:shape()[1][1]
	 return {type="ellipse", matrix=matrix}
      elseif obj:shape()[1].type == "curve" and obj:shape()[1][1].type == "arc" then
	 matrix = obj:matrix()*obj:shape()[1][1].arc:matrix()
	 return {type="ellipse", matrix=matrix}
      else
	 return {type=nil, matrix=nil}
      end
   elseif obj:type()=="reference" then
      return {type="reference", vector=obj:matrix()*obj:position()}
   end
end


function unit_circ_to_mark_tangent_points(m)
   local len = m:sqLen()
   if(len<=1) then return end -- there are no tagent lines in this case
   local r = math.sqrt(len - 1)
   local a1 = A(M(r,0,0,r,m.x,m.y))
   local a2 = A(M(1,0,0,1,0,0))
   return a1:intersect(a2)
   
end


function ellipse_to_mark_tangent_points(m, e)
   if m==nil then return end
   local ma=e:inverse()*m; -- undo affine transformations
   local p = unit_circ_to_mark_tangent_points(ma)
   -- redo affine transformation if tangent points exist
   if p~=nil then return e*p[1], e*p[2]
   else return end
end


function is_point_in_ellipse(p,e)
   if (e:inverse()*p):len() < 1 then return true
   else return false end
end

function ellipse_to_mark_tangent_segments(model, m, e)
   local p1,p2 = ellipse_to_mark_tangent_points(m, e)
   local segs = {}
   segs[1] = { obj=make_segment(model, m, p1), select = nil }
   segs[2] = { obj=make_segment(model, m, p2), select = nil }
   return segs
end

function remove_equal_points(pts)
   local i=1
   while i<=#pts-1 do
      -- print("i=",i)
      local kill = {}
      local j=i+1
      while j<=#pts do
	 if (pts[i]-pts[j]):len()<1e-9 then kill[#kill+1]=j end
	 j=j+1
      end
      if #kill~=0 then
	 table.insert(kill,1,i)

	 for k=#kill,1,-1 do
	    table.remove(pts,kill[k])
	 end
      else
	 i=i+1
      end
   end
end

function ellipse_to_ellipse_intersects(e1,e2)
   local ints1 = A(e1):intersect(A(e2))
   local ints2 = A(e2):intersect(A(e1))
   if #ints1<#ints2 then return ints1
   else return ints2 end
end

function ellipse_to_ellipse_tangent_segments(model, e1, e2)

   if e1==e2 then return {} end
   
   local p1, p2 = {},{}
   local pa,pb -- temporary points

   local arc1 = A(e1)
   local arc2 = A(e2)

   -- local ints = arc1:intersect(arc2)

   -- replace this function once arc1:intersect(arc2) is fixed
   local ints = ellipse_to_ellipse_intersects(e1,e2)
   -- print("before")
   -- for i=1,#ints do print(ints[i]) end
   remove_equal_points(ints)
   -- print("after")
   -- for i=1,#ints do print(ints[i]) end

   if #ints<=1 then -- ellipses are not intersecting
      if e1:translation()==e2:translation() then return {} end
      local l= L(e1:translation(),e2:translation())

      p1[1] = arc1:intersect(l)[1]
      -- from p1a find tangent points to e2, call these points p2[1] and p2[2]
      p2[1],p2[2] = ellipse_to_mark_tangent_points(p1[1],e2)
      -- from p2[1] and p2[2] find tangent points to e1, call them p1[1], p1[2], p1[3] and p1[4]
      p1[1],p1[3] = ellipse_to_mark_tangent_points(p2[1],e1)
      if p1[1]==nil then return {} end
      p1[2],p1[4] = ellipse_to_mark_tangent_points(p2[2],e1)

      p2[3], p2[4] = p2[1], p2[2]

   else
      local segs={}
      for i=1,#ints do

	 -- at intersection create a small circle
	 local circ = A(M({0.1,0,0,0.1,ints[i].x,ints[i].y}))

	 -- find intersects between small circle and ellipses
	 local cx1 = circ:intersect(arc1)
	 local cx2 = circ:intersect(arc2) 

	 -- set p1[i] and p2[i] to the points that are outside both ellipses
	 if is_point_in_ellipse(0.5*(cx1[1]+cx2[1]),e1)==false and
	    is_point_in_ellipse(0.5*(cx1[1]+cx2[1]),e2)==false then p1[i],p2[i] = cx1[1],cx2[1]
	 elseif is_point_in_ellipse(0.5*(cx1[1]+cx2[2]),e1)==false and
	    is_point_in_ellipse(0.5*(cx1[1]+cx2[2]),e2)==false then p1[i],p2[i] = cx1[1],cx2[2]
	 elseif is_point_in_ellipse(0.5*(cx1[2]+cx2[1]),e1)==false and
	    is_point_in_ellipse(0.5*(cx1[2]+cx2[1]),e2)==false then p1[i],p2[i] = cx1[2],cx2[1]
	 else p1[i],p2[i] = cx1[2],cx2[2] end


      end

   end
   
   if #ints==0 then -- if ellipses are not intersecting
      for i=1,20 do 
	 for j=1,#p1 do -- for all four possible tangent points
	    pa,pb = ellipse_to_mark_tangent_points(p1[j], e2)
	    -- if dot product of the current tangent with proposed path a is > than with path b then choose it.
	    if (p2[j]-p1[j])..(pa-p1[j]):normalized() > (p2[j]-p1[j])..(pb-p1[j]):normalized() then
	       p2[j] = pa else p2[j] = pb end
	 end
	 p1,p2,e1,e2 = p2,p1,e2,e1
      end
   else -- if ellipses are intersecting
      for i=1,20 do 
	 for j=1,#p1 do -- for all four possible tangent points
	    pa,pb = ellipse_to_mark_tangent_points(p1[j], e2)
	    local l = L(ints[j], p2[j]-(p1[j]-ints[j]))
	    if S(p1[j],pa):intersects(l) then p2[j]=pb else p2[j]=pa end
	 end
	 p1,p2,e1,e2 = p2,p1,e2,e1
      end
   end


   
   -- for i=1,20 do 
   --    for j=1,#p1 do -- for all four possible tangent points

   -- 	 if #ints==0 then -- if ellipses are not intersecting
   -- 	    -- if dot product of the current tangent with proposed path a is > than with path b then choose it.
   -- 	    if (p2[j]-p1[j])..(pa-p1[j]):normalized() > (p2[j]-p1[j])..(pb-p1[j]):normalized() then
   -- 	       p2[j] = pa else p2[j] = pb end
   -- 	 else -- if ellipses are intersecting
   -- 	    local l = L(ints[j], p2[j]-(p1[j]-ints[j]))
   -- 	    if S(p1[j],pa):intersects(l) then p2[j]=pb else p2[j]=pa end
   -- 	 end
   --    end

   --    -- swap all objects and repeat above steps
   --    p1,p2,e1,e2 = p2,p1,e2,e1
   -- end


   -- make the segments
   local segs={} -- these will be the segment objects for drawing
   local s={} -- these are the segments for finding intersect
   for i=1,#p1 do
	 s[#s+1] = S(p1[i],p2[i])
	 segs[#segs+1] = { obj = make_segment(model,p1[i], p2[i]), select = nil }		  
   end

   -- if only two segments, then there cannot be any intersects
   if #s==2 then return segs end

   -- else search intersecting segments and return
   for i=1,#s do
      for j=i,#s do
	 if s[i]:intersects(s[j]) then
	    segs[i].select = 2
	    segs[j].select = 2
	    return segs
	 end
      end
   end

   return segs
end

function print_selection_warning(model)
   model:warning("Must select at least two markers, circles, ellipses and/or arcs")
end

function table_concat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function run(model)

   local page = model:page()
   local prim = page:primarySelection()
   if not prim then print_selection_warning(model) return end
   local obj = page[prim]
   local p,s
   
   p = get_object_type(obj)

   local segs = {}
   local segments={}


   for i, obj, sel, layer in page:objects() do

      segs={}
      
      if sel and i~=prim then

	 s = get_object_type(obj)

	 if p.type=="reference" then
	    
	    if s.type=="reference" then
	       segs[1] = { obj = make_segment(model, p.vector, s.vector), select=nil}
	    elseif s.type=="ellipse" then
	       segs = ellipse_to_mark_tangent_segments(model, p.vector,s.matrix)
	    end
	    
	 elseif p.type=="ellipse" then
	    
	    if s.type=="reference" then
	       segs = ellipse_to_mark_tangent_segments(model, s.vector,p.matrix)
	    elseif s.type=="ellipse" then
	       segs = ellipse_to_ellipse_tangent_segments(model, p.matrix, s.matrix)
	    end
	    
	 end

      end
      segments = table_concat(segments,segs)
   end

   create_objects(model, segments)
   
end

shortcuts.ipelet_1_tangentlines = "Alt+t"
