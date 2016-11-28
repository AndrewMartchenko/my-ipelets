

label = "Fillet"

about = [[
Create fillets in a polyline or polygon
]]

function get_curve(obj)

   if obj:type() ~= "path" then return end

   local shape = obj:shape()
   -- if selection is a group or is not a curve or has less than two segments
   if (#shape ~= 1 or shape[1].type ~= "curve" or #shape[1] < 2) then return end
   
   local m = obj:matrix()
   local curve = shape[1]

   for i=1,#curve do
      for j=1,#curve[i] do
	 curve[i][j] = m*curve[i][j]
      end
      if curve[i].type == "arc" then
	 curve[i].arc = m*curve[i].arc
      end
   end


   -- if curve is closed and ends are not touching
   if curve.closed and curve[1][1] ~= curve[#curve][#curve[#curve]] then
      -- create segment to join the ends of the curve
      curve[#curve+1] = {type="segment", curve[#curve][2],curve[1][1]}
      -- duplicate the first segment
      curve[#curve+1] = {type="segment", curve[1][1],curve[1][2]}
   end
   
   return curve
end

function create_fillets(curve,r)
   local s11,s12,s21,s22
   local n1,n2
   local change_made = false
   local x1, x2, c
   local arc

   local i=1
   while i < #curve do
      if curve[i].type=="segment" and curve[i+1].type=="segment" then
	 -- normals of line segments with length equal to r
	 n1 = r*ipe.LineThrough(curve[i][1],curve[i][2]):normal()
	 n2 = r*ipe.LineThrough(curve[i+1][1],curve[i+1][2]):normal()

	 -- line segments translated by +/- the respective normals
	 s11 = ipe.Segment(curve[i][1]+n1,curve[i][2]+n1)
	 s12 = ipe.Segment(curve[i][1]-n1,curve[i][2]-n1)
	 s21 = ipe.Segment(curve[i+1][1]+n2,curve[i+1][2]+n2)
	 s22 = ipe.Segment(curve[i+1][1]-n2,curve[i+1][2]-n2)


	 -- find the intersection point c of any two of the translated line segments
	 if s11:intersects(s21) then
	    c = s11:intersects(s21)
	 elseif s11:intersects(s22) then
	    c = s11:intersects(s22)
	 elseif s12:intersects(s21) then
	    c = s12:intersects(s21)
	 elseif s12:intersects(s22) then
	    c = s12:intersects(s22)
	 else
	    c = nil
	 end

	 if c then
	    x1 = ipe.Segment(curve[i][1],curve[i][2]):project(c)
	    x2 = ipe.Segment(curve[i+1][1],curve[i+1][2]):project(c)

	    -- if projection failed, then arc needs to replace the whole line segment
	    if x1==nil then x1 = curve[i][1] end
	    if x2==nil then x2 = curve[i+1][2] end
	       
	       
	    arc = ipe.Arc(ipe.Matrix(r, 0, 0, r, c.x, c.y),x1,x2)
	    if #arc:intersect(ipe.Segment(c,curve[i][2]))==0 then
	       arc = ipe.Arc(ipe.Matrix(-r, 0, 0, r, c.x, c.y),x1,x2)
	    end

	    -- create arc at position i+1
	    table.insert(curve, i+1, {type="arc", x1,x2,arc=arc})

	    -- resize the line segments either side of the arc
	    curve[i][2] = x1
	    curve[i+2][1] = x2

	    -- if line segments now have zero lenth then remove them from the table
	    if curve[i][1]==curve[i][2] then
	       table.remove(curve, i)
	       i=i-1
	    end
	    if curve[i+2][1]==curve[i+2][2] then
	       table.remove(curve, i+2)
	       i=i-1
	    end

	    
	    i=i+1
	    change_made=true
	 end
      end
      i=i+1
   end

   -- if curve is closed and ends are not touching
   if curve.closed and curve[1][1] ~= curve[#curve][#curve[#curve]] then
      curve[1][1] = curve[#curve][1]
      table.remove(curve, #curve)
   end

   if change_made then
      return curve
   else
      return
   end
end

function create_curves(model,curves)
   local path
   for i,curve in ipairs(curves) do
      path = ipe.Path(model.attributes, { curve } )
      model:creation("create fillets in poygon or polyline", path)
   end
end


function run(model)

   local page = model:page()
   local prim = page:primarySelection()
   if not prim then model.ui:explain("no selection") return end


   local str = model:getString("Enter fillet radius in pts")
   if not str or str:match("^%s*$") then return end
   local r = tonumber(str)
   if r<=0 then return end


   local curve, fillet
   local curves={}
   for i, obj, sel, layer in page:objects() do
      if sel then
	 curve = get_curve(obj)
	 if curve then

	    fillet = create_fillets(curve,r)
	    if fillet then curves[#curves+1]=fillet end
	 end
      end
   end
   create_curves(model,curves)
end


----------------------------------------------------------------------
shortcuts.ipelet_1_fillet = "Shift+f"
