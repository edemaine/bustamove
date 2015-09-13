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

svg = svgballs = svgarrow = svgaim = null
balls = rowCount = null
xm = ym = null  ## center x/y coords are between 0 and xm/ym
xmin = xmax = ymin = ymax = null
keyangle = null

setBalls = (newBalls) ->
  balls = newBalls if newBalls?
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
  ball[y][x] = color
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

ballTrajectory = (angle) ->
  rayShoot = (x,y, angle) ->
    if angle < 0.5*Math.PI - 0.001
      x2 = xmax - radius
      y2 = y - (x2-x) * Math.tan angle
    else if angle > 0.5*Math.PI + 0.001
      x2 = xmin + radius
      y2 = y + (x-x2) * Math.tan angle
    else
      y2 = ymin
    if y2 > ymin
      [x2, y2, Math.PI - angle]
    else
      [x + (y-ymin)*(Math.cos(angle)/Math.abs Math.sin angle), ymin, angle]

  x = xm / 2
  y = ym * sqrt3
  lst = []
  while y > ymin
    lst.push [x,y]
    [x, y, angle] = rayShoot(x,y,angle)
  lst.push [x - (y-ymin)*Math.cos(angle)/Math.sin(angle), ymin]
  lst

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

collides = (p, q, c) ->
  d = distance p, q
  cos = (q[0] - p[0]) / d
  sin = (q[1] - p[1]) / d
  Math.abs((c[0] - p[0])*sin + (c[1] - p[1])*cos) <= 2*radius
  #Math.abs((q[0] - p[0])*Math.sin(alpha) + (q[1]-p[1])*Math.cos(alpha)) <= 2*radius

collisionTime = (p, q, c) ->
  d = distance p, q
  cos = (q[0] - p[0]) / d
  sin = (q[1] - p[1]) / d
  ((c[0] - p[0])*cos - (c[1] - p[1])*sin) - Math.sqrt(4-d*d)
  #d = ((q[0] - p[0])*Math.sin(alpha) + (q[1]-p[1])*Math.cos(alpha))
  #((q[0] - p[0])*Math.cos(alpha) - (q[1] - p[1])*Math.sin(alpha)) - Math.sqrt(4-d*d)

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
  svgaim.polyline(ballTrajectory(angle)).fill('none').stroke(trajectory_stroke)


keytimer = null
keycurrent = null
keyangle = 0.5*Math.PI
keyspeed = 0.01
keyeps = 3 * keyspeed
keymin = 0 + keyeps
keymax = Math.PI - keyeps
keyinterval = 10

keymove = (dir) ->
  clearInterval keytimer if keytimer?
  if dir != 0
    keytimer = setInterval () ->
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
    keymove +1
  else if event.keyIdentifier == 'Right'
    keymove -1
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
  setBalls ascii2balls '''
    B B B
     R R
    P P P






      B
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
