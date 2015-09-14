colors =
  B: 'blue'
  P: 'purple'
  R: 'red'
  Y: 'yellow'
  ' ': null

## ASCII
##  R R
## B B P
ascii2balls = (ascii) ->
  ## Turn string into a 2D array of characters.
  ascii.replace(/\r\n/g, '\n').replace(/\r/g,'\n').split('\n')

stroke =
  color: 'black'
  width: 0.1
border_stroke =
  color: 'black'
  width: 0.2
border_fill = '#dddddd'

radius = 1
margin = 0.2
sqrt3 = Math.sqrt(3)

svg = svgballs = svgarrow = svgaim = svgshoot= null
balls = rowCount = null
xm = ym = null  ## center x/y coords are between 0 and xm/ym
xmin = xmax = ymin = ymax = null
keyangle = null

setBalls = (newBalls) ->
  balls = ((c for c in row) for row in newBalls) if newBalls?
  rowCount = ((1 for char in row when colors[char]?).length for row in balls)
  ym = balls.length - 1
  xm = (Math.max (row.length for row in balls)...) - 1
  ymin = -1 * radius
  ymax = (1 + ym * sqrt3) * radius
  xmin = -1 * radius
  xmax = (1 + xm) * radius

setBall = (x, y, color) ->
  if colors[balls[y][x]]?
    rowCount[y] -= 1
  balls[y][x] = color
  console.log "xyc"+[x,y,color,balls[y][x]]
  if colors[balls[y][x]]?
    rowCount[y] += 1

draw = () ->
  svg.viewbox xmin - margin, ymin - margin, xmax + margin, ymax + margin + 1.1
  ## xxx why +1.1?
  drawBalls()
  drawArrow keyangle
  drawTrajectory keyangle

drawBalls = () ->
  svgballs.clear()
  svgballs.rect(xmax-xmin, ymax-ymin).move(xmin, ymin).fill(border_fill).stroke(border_stroke)
  for row, y in balls
    for char, x in row
      color = colors[char]
      if color != null
        svgballs.circle(2*radius).center(x, y * sqrt3).stroke(stroke).fill(color)

arrow_stroke =
  color: 'black'
  width: 0.4
arrow_length = 2

drawArrow = (angle) ->
  x = xm / 2
  y = ym * sqrt3
  svgarrow.clear()
  svgarrow.line(x, y, x + arrow_length * Math.cos(angle), y - arrow_length * Math.sin(angle)).stroke(arrow_stroke)

#collides = (p, angle, q) ->
#  Math.abs((q[0] - p[0])*Math.sin(angle) + (q[1]-p[1])*Math.cos(angle)) <= 2*radius

collisionTime = (p, angle, q) ->
  d = (q[0] - p[0])*Math.sin(angle) + (q[1] - p[1])*Math.cos(angle)
  if Math.abs(d) <= 2*radius
    ((q[0] - p[0])*Math.cos(angle) - (q[1] - p[1])*Math.sin(angle)) - Math.sqrt(4*radius*radius-d*d)
  else
    null

findCollision = (p, p2, angle) ->
  yfloor = Math.floor(p2[1] / sqrt3)
  return null unless yfloor >= 0 and rowCount[yfloor] > 0
  xleft = xright = p[0]
  tmin = tminx = tminy = null
  for y in [Math.ceil(p[1]/sqrt3)..Math.floor(p2[1]/sqrt3)]
    xleft -= 1 while collisionTime(p, angle, [xleft-1, y*sqrt3])?
    xleft += 1 until collisionTime(p, angle, [xleft, y*sqrt3])?
    xright += 1 while collisionTime(p, angle, [xright+1,y*sqrt3])?
    xright -= 1 until collisionTime(p, angle, [xright,y*sqrt3])?
    for x in [xleft..xright]
      if colors[balls[y][x]]?
        t = collisionTime p, angle, [x,y*sqrt3]
        if t != null and (tmin == null or t < tmin)
          tmin = t
          tminx = x
          tminy = y * sqrt3
        if t? and (y+2)*sqrt3 < tminy
          break
  if tmin == null
    null
  else
    [tminx,tminy]
        
  #xrange = [Math.min(p[0],p2[0])..Math.min(2+Math.max(p[0],p2[0]),xm)]
  #slope = (Math.abs Math.sin angle) / Math.cos(angle)
  #tmin = tminx = tminy = null
  #for x in xrange
  #  y = p[1] + (x-p[0]) * slope
  #  yfloor = Math.floor(y / sqrt3)
  #  yrange = [Math.max(0, yfloor - 2) .. Math.min(ym, yfloor + 2)]
  #  for y in yrange
  #    #console.log x, y
  #    if colors[balls[y][x]]?
  #      t = collisionTime p, angle, [x,y*sqrt3]
  #      if t != null and (tmin == null or t < tmin)
  #        tmin = t
  #        tminx = x
  #        tminy = y * sqrt3
  #if tmin == null
  #  null
  #else
  #  [tminx,tminy]

ballTrajectory = (angle) ->
  x = xm / 2
  y = ym * sqrt3
  lst = []
  while y > 0
    lst.push [x,y]
    if angle < 0.5*Math.PI - 0.001
      x2 = xmax - radius
      y2 = y - (x2-x) * Math.tan angle
    else if angle > 0.5*Math.PI + 0.001
      x2 = xmin + radius
      y2 = y + (x-x2) * Math.tan angle
    else
      x2 = x
      y2 = 0
    if y2 <= 0
      x2 = x + (y)*(Math.cos(angle)/Math.abs(Math.sin(angle)))
      y2 = 0
    collide = findCollision [x, y], [x2, y2], angle
    if collide != null
      t = collisionTime [x,y], angle, collide
      [x, y] = [x + t*Math.cos(angle), y-t*Math.sin(angle)]
      break
    [x, y] = [x2, y2]
    angle = Math.PI-angle
  lst.push [x, y]
  [lst, collide]

#firstOccupiedRow = () ->
#  y1 = 0
#  y2 = n
#  while y1+1 < y2
#    y = (y1 + y2) // 2
#    if rowCount[y] == 0
#      y2 = y
#    else
#      y1 = y
#  if rowCount[y1] > 0
#    y1
#  else if rowCount[y2] > 0
#    y2
#  else
#    null

distance = (p, q) ->
  dx = p[0] - q[0]
  dy = p[1] - q[1]
  Math.sqrt dx * dx + dy * dy

#collides = (p, q, c) ->
#  d = distance p, q
#  cos = (q[0] - p[0]) / d
#  sin = (q[1] - p[1]) / d
#  Math.abs((c[0] - p[0])*sin + (c[1] - p[1])*cos) <= 2*radius
#  #Math.abs((q[0] - p[0])*Math.sin(alpha) + (q[1]-p[1])*Math.cos(alpha)) <= 2*radius
#
#collisionTime = (p, q, c) ->
#  d = distance p, q
#  cos = (q[0] - p[0]) / d
#  sin = (q[1] - p[1]) / d
#  ((c[0] - p[0])*cos - (c[1] - p[1])*sin) - Math.sqrt(4-d*d)
#  #d = ((q[0] - p[0])*Math.sin(alpha) + (q[1]-p[1])*Math.cos(alpha))
#  #((q[0] - p[0])*Math.cos(alpha) - (q[1] - p[1])*Math.sin(alpha)) - Math.sqrt(4-d*d)

lineShot = (p, alpha, q) ->
  x = p[0]
  y = p[1]
  perp = [-y, x]
  #normalize perp...
  yfloor = Math.floor(y / sqrt3)
  yrange = [yfloor - 2 .. yfloor + 2]

collisionDetect = (traj) ->
  for p, i in traj[...-1]
    q = traj[i+1]
    y = Math.floor q[1]/sqrt3 - 2
    if rowCount[y] > 0
      break
  #while y <= my and rowCount[y] > 0
  #  y += 1
  #y -= 1

trajectory_stroke =
  color: 'black'
  width: 0.1
  dasharray: [0.1, 0.1]

drawTrajectory = (angle) ->
  svgaim.clear()
  [bt, collide] = ballTrajectory(angle)
  last = bt[-1..-1][0]
  svgshoot = svgballs.circle(2*radius).center(xm / 2, ym * sqrt3).stroke(stroke).fill('purple')
  svgaim.polyline(bt).fill('none').stroke(trajectory_stroke)
  svgaim.circle(2*radius).center(last[0], last[1]).stroke(trajectory_stroke).fill(border_fill)
  if collide?
    svgaim.circle(radius/2).center(collide[0], collide[1]).stroke(stroke).fill('black')


shootBall = (angle) ->
  [bt, collide] = ballTrajectory(angle)
  if collide?
    rot = Math.acos((bt[bt.length-1][0]-collide[0])/2)
    rot2 = Math.round(rot*3/Math.PI)*Math.PI/3
    [x, y] = [Math.round(collide[0]+2*Math.cos(rot2)), Math.round((collide[1]+2*Math.sin(rot2))/sqrt3)]
  else
    [x, y] = [Math.round(bt[bt.length-1][0]/2)*2, Math.round(bt[bt.length-1][1]/sqrt3)]
  setBall(x, y, 'P')
  console.log "added"+[x,y]+" with color "+balls[y][x]
  i = 0
  shoot = ->
    i += 1
    if i < bt.length
      svgshoot.animate(1000*distance(bt[i-1],bt[i])/(ymax-ymin),'-').center(bt[i][0], bt[i][1]).after(shoot)
    else if collide?
      rot = Math.acos((bt[i-1][0]-collide[0])/2)
      rot2 = Math.round(rot*3/Math.PI)*Math.PI/3
      svgshoot.animate(50,'-').during (t) ->
        angle = rot + (rot2-rot)*t
        svgshoot.center(collide[0]+2*Math.cos(angle), collide[1]+2*Math.sin(angle))
    else
      svgshoot.animate(50,'-').center(Math.round(bt[i-1][0]/2)*2,bt[i-1][1])
  shoot()

neighbors = (x,y) ->
  ns = []
  ns.push [x-1,y-1] if x > 0  and y > 0  #and colors[balls[x-1][y-1]]?
  ns.push [x+1,y-1] if x < xm and y > 0  #and colors[balls[x+1][y-1]]?
  ns.push [x-1,y+1] if x > 0  and y < ym #and colors[balls[x-1][y-1]]?
  ns.push [x+1,y+1] if x < xm and y < ym #and colors[balls[x+1][y-1]]?
  ns.push [x+2,y  ] if x < xm-1          #and colors[balls[x+2][y  ]]?
  ns.push [x-2,y  ] if x > 1             #and colors[balls[x-2][y  ]]?
  ns
connectedComponent = (xy) ->
  color = balls[xy[1]][xy[0]]
  return unless color?
  seen = {}
  seen[xy] = true
  frontier = [xy]
  while frontier.length > 0
    xy = frontier.pop()
    for neighbor in neighbors xy...
      if balls[neighbor[1]][neighbor[0]] == color and not seen[neighbor]
        seen[neighbor] = true
        frontier.push neighbor
  key for own key of seen

keytimer = null
keycurrent = null
keyangle = 0.5*Math.PI
keyspeed = 0.01
keyspeedslow = 0.002
keyeps = 3 * keyspeed
keymin = 0 + keyeps
keymax = Math.PI - keyeps
keyinterval = 10

keymove = (dir, slow) ->
  clearInterval keytimer if keytimer?
  if dir != 0
    keytimer = setInterval () ->
      if slow
        keyangle += dir * keyspeedslow
      else
        keyangle += dir * keyspeed
      keyangle = keymin if keyangle < keymin
      keyangle = keymax if keyangle > keymax
      drawTrajectory keyangle
      drawArrow keyangle
    , keyinterval

keydown = (event) ->
  if event.keyIdentifier == keycurrent
    return false
  else
    keycurrent = event.keyIdentifier
  if event.keyIdentifier == 'Left'
    keymove +1, event.shiftKey
  else if event.keyIdentifier == 'Right'
    keymove -1, event.shiftKey
  else if event.keyIdentifier == 'U+0020'
    shootBall keyangle
  false

keyup = (event) ->
  keycurrent = null
  keymove 0
  false

test = () ->
  window.addEventListener 'keydown', keydown
  window.addEventListener 'keyup', keyup
  svg = SVG('surface')#.size width, height
  svgballs = svg.group()
  svgarrow = svg.group()
  svgaim = svg.group()
  #svgshoot = svg.group()
  setBalls ascii2balls '''
    B B B B B       B
     R R 
    P    
     R R R






      
  '''
  draw()

## Based on jolly.exe's code from http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
getParameterByName = (name) ->
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp "[\\?&]" + name + "=([^&#]*)"
  results = regex.exec location.search
  if results == null
    null
  else
    decodeURIComponent results[1].replace(/\+/g, " ")

window?.onload = () ->
  resize = ->
    surface = document.getElementById('surface')
    surface.style.height =
      Math.floor(window.innerHeight - surface.getBoundingClientRect().top - 50) + 'px'
  window.addEventListener 'resize', resize
  resize()

  test()
