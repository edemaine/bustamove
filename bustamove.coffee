colors =
  B: 'blue'
  P: 'purple'
  R: 'red'
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
balls = null
xm = ym = null

updateBalls = (newBalls) ->
  balls = newBalls if newBalls?
  ym = balls.length - 1
  xm = (Math.max (row.length for row in balls)...) - 1

drawBalls = (balls) ->
  ymin = -1 * radius
  ymax = (1 + ym * sqrt3) * radius
  xmin = -1 * radius
  xmax = (1 + xm) * radius
  svg.viewbox xmin - margin, ymin - margin, xmax + margin, ymax + margin + 1.1
  ## xxx why +1.1?
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
  xmin = -1 * radius
  xmax = (1 + xm) * radius
  ymin = -1 * radius
  rayShoot = (x,y, angle) ->
    if angle < 0.5*Math.PI - 0.001
      x2 = xmax
      y2 = y - (xmax-x)*Math.tan(angle)
    else if angle > 0.5*Math.PI + 0.001
      x2 = xmin
      y2 = y + (x-xmin)*Math.tan(angle)
    else
      y2 = ymin
    if y2 > ymin
      [x2, y2, Math.PI-angle]
    else
      [x + (y-ymin)*(Math.cos(angle)/Math.abs(Math.sin(angle))), ymin, angle]

  x = xm / 2
  y = ym * sqrt3
  lst = []
  while y>-1
    lst.push [x,y]
    [x, y, angle] = rayShoot(x,y,angle)
  lst.push [x - (y-ymin)*Math.cos(angle)/Math.sin(angle), ymin]
  lst

trajectory_stroke =
  color: 'black'
  width: 0.1

drawTrajectory = (angle) ->
  svgaim.clear()
  svgaim.polyline(ballTrajectory(angle)).fill('none').stroke(trajectory_stroke)


keytimer = null
keycurrent = null
keyangle = 0.5*Math.PI
keyspeed = 0.01
keyinterval = 50

keymove = (dir) ->
  clearInterval keytimer if keytimer?
  if dir != 0
    keytimer = setInterval () ->
      keyangle += dir * keyspeed
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
  updateBalls ascii2balls '''
    B B B
     R R
    P P P






      B
  '''
  drawBalls balls
  drawTrajectory keyangle
  drawArrow keyangle

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
