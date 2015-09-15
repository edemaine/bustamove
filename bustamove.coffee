colors =
  B: 'blue'
  P: 'purple'
  R: 'red'
  Y: 'yellow'
  ' ': null
blank = ' '

## ASCII
##  R R
## B B P
ascii2balls = (ascii) ->
  ## Turn string into a 2D array of characters.
  ascii.replace(/\r\n/g, '\n').replace(/\r/g,'\n').split('\n')

glueballs = (b1, brest...) ->
  ## glue horizontally. All rows must be same length, number of rows must be the same.
  if brest.length == 0
    balls = b1
  else
    balls = []
    b2 = glueballs(brest...)
    for i in [0...b1.length]
      balls.push b1[i]+b2[i]
  balls

repeatballs = (b, k) ->
  if k == 0
    ('' for r in b)
  else if k == 1
    b
  else
    glueballs(b,repeatballs(b, k-1))

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

svg = svgballs = svgarrow = svgaim = svgshoot = null
balls = rowCount = null
xm = ym = null  ## center x/y coords are between 0 and xm/ym
xmin = xmax = ymin = ymax = null
keyangle = null

ballseq = []

setBalls = (newBalls) ->
  balls = ((c for c in row) for row in newBalls) if newBalls?
  rowCount = ((1 for char in row when colors[char]?).length for row in balls)
  ym = balls.length - 1
  xm = (Math.max (row.length for row in balls)...) - 1
  for row in balls
    while row.length < xm
      row.push blank
  ymin = -1 * radius
  ymax = (1 + ym * sqrt3) * radius
  xmin = -1 * radius
  xmax = (1 + xm) * radius
  null

setBall = (x, y, color) ->
  if colors[balls[y][x]]?
    rowCount[y] -= 1
  balls[y][x] = color
  if colors[balls[y][x]]?
    rowCount[y] += 1

getBall = (x, y) -> balls[y][x]
isBall = (x, y) -> colors[balls[y][x]]?

getState = () ->
  commands = []
  current = null
  flush = () ->
    if current == blank
      current = '.'
    if count > 1
      commands.push "#{count}#{current}"
    else if count >= 1
      commands.push current
  for row, y in balls
    current = null
    count = 0
    parity = y % 2
    for char, x in row[parity..]
      continue unless x % 2 == 0
      if current != char
        flush()
        current = char
        count = 1
      else
        count += 1
    flush()
    ## Remove trailing blanks.
    if commands.length > 0 and commands[commands.length-1][-1..] == '.'
      commands.pop()
    commands.push '|'
  ## remove last |
  config = commands[...-1].join ''

  commands = []
  current = null
  count = 0
  for char in ballseq
    if current != char
      flush()
      current = char
      count = 1
    else
      count += 1
  flush()
  seq = commands.join ''

  "#config=#{config}&seq=#{seq}"

currentState = null

pushState = () ->
  #history.pushState null, 'play', "#config=#{getState()}"
  window.location.hash = currentState = getState()
  #console.log getState()

## Based on jolly.exe's code from http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
getParameterByName = (hash, name) ->
  hash = '#' + hash
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp "[#&]" + name + "=([^&#]*)"
  results = regex.exec hash
  if results == null
    null
  else
    decodeURIComponent results[1].replace(/\+/g, " ")

decompress = (compress, fill = '') ->
  return compress unless compress?
  out = ''
  count = ''
  for char in compress
    if '0' <= char <= '9'
      count += char
    else
      if char == '.'
        char = blank
      count = 1 if count == ''
      out += (char + fill).repeat count
      count = ''
  out

setState = (state) ->
  return if state == currentState
  seq = decompress getParameterByName state, 'seq'
  config = getParameterByName state, 'config'
  return false unless seq? and config?
  ballseq = (x for x in seq)
  rows =
    for row, y in config.split '|'
      row = (if y % 2 == 0 then '' else ' ') + decompress row, ' '
      while row[-1..] == ' '
        row = row[...-1]
      row
  currentState = state
  setBalls rows
  draw()
  true

loadState = () ->
  setState window.location.hash

draw = () ->
  svg.viewbox xmin - margin, ymin - margin, xmax + margin + 1.1, ymax + margin + 1.1
  ## xxx why +1.1?
  drawBalls()
  drawArrow keyangle
  #drawTrajectory keyangle
  newBall()
  drawTrajectory keyangle

makeCircle = (x, y, color) ->
  #circles[[x,y]] = svgballs.circle(2*radius).center(x, y * sqrt3).stroke(stroke).fill(colors[color])
  circles[[x,y]] = svgballs.image("img/ball_#{colors[color]}.png",2*radius,2*radius).center(x, y * sqrt3)
    .style('image-rendering', 'pixelated')

circles = {}
drawBalls = () ->
  svgballs.clear()
  svgballs.rect(xmax-xmin, ymax-ymin).move(xmin, ymin).fill(border_fill).stroke(border_stroke)
  for row, y in balls
    for char, x in row
      if colors[char]?
        makeCircle x, y, char

arrow_stroke =
  color: 'black'
  width: 0.4
arrow_length = 2

shotOrigin = () ->
  parity = (ym // 2) % 2    ## xxx why // 2??
  [(xm+1) // 2 + parity, ym * sqrt3]

drawArrow = (angle) ->
  [x, y] = shotOrigin()
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
      if isBall x, y
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
  #    if isBall x, y
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
  [x, y] = shotOrigin()
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
  return if svgshoot == null
  [bt, collide] = ballTrajectory(angle)
  last = bt[-1..-1][0]
  svgaim.polyline(bt).fill('none').stroke(trajectory_stroke)
  svgaim.circle(2*radius).center(last[0], last[1]).stroke(trajectory_stroke).fill(border_fill)
  ## Black dots:
  #if collide?
  #  svgaim.circle(radius/2).center(collide[0], collide[1]).stroke(stroke).fill('black')

newBall = () ->
  if ballseq.length == 0
    ballseq.push 'P'
  [x, y] = shotOrigin()
  svgshoot = makeCircle x, Math.round(y / sqrt3), ballseq[ballseq.length-1]

shootBall = (angle) ->
  return if svgshoot == null
  [bt, collide] = ballTrajectory(angle)
  if collide?
    rot = Math.acos((bt[bt.length-1][0]-collide[0])/2)
    rot2 = Math.round(rot*3/Math.PI)*Math.PI/3
    [x, y] = [Math.round(collide[0]+2*Math.cos(rot2)), Math.round((collide[1]+2*Math.sin(rot2))/sqrt3)]
  else
    [x, y] = [Math.round(bt[bt.length-1][0]/2)*2, Math.round(bt[bt.length-1][1]/sqrt3)]
  setBall(x, y, ballseq.pop())
  circles[[x,y]] = localshoot = svgshoot
  svgshoot = null
  drawTrajectory keyangle

  explode = ->
    [cc, fall] = impact [x,y]
    a = null
    for ball in cc
      # xxx .radius(2) isn't working :-(
      a = circles[ball].animate(750).radius(2).opacity(0).after(circles[ball].remove)
      setBall ball[0], ball[1], blank
    delay = (500 * (2 - ball[0] / xm - ball[1] / ym) for ball in fall)
    mindelay = Math.min delay...
    delay = (d - mindelay for d in delay)
    for ball, i in fall
      a = circles[ball].animate(750,'<',delay[i]).opacity(0.5).center(ball[0], ball[1] + (ym+1)*sqrt3).after(circles[ball].remove)
      setBall ball[0], ball[1], blank
    later = () ->
      newBall()
      drawTrajectory keyangle
    if a == null
      later()
    else
      a.after later
    pushState()
  i = 0
  shoot = ->
    i += 1
    if i < bt.length
      localshoot.animate(1000*distance(bt[i-1],bt[i])/(ymax-ymin),'-').center(bt[i][0], bt[i][1]).after(shoot)
    else if collide?
      rot = Math.acos((bt[i-1][0]-collide[0])/2)
      rot2 = Math.round(rot*3/Math.PI)*Math.PI/3
      localshoot.animate(50,'-').during (t) ->
        angle = rot + (rot2-rot)*t
        localshoot.center(collide[0]+2*Math.cos(angle), collide[1]+2*Math.sin(angle))
      .after explode
    else
      localshoot.animate(50,'-').center(Math.round(bt[i-1][0]/2)*2,bt[i-1][1])
        .after explode
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

set2list = (set) -> (parseInt(x) for x in key.split(',')) for own key of set

bfs = (root, follow) ->
  seen = {}
  frontier = []
  for p in root
    seen[p] = true
    frontier.push p
  while frontier.length > 0
    p = frontier.pop()
    for neighbor in neighbors p...
      if not seen[neighbor] and follow neighbor
        seen[neighbor] = true
        frontier.push neighbor
  seen

connectedComponent = (root) ->
  color = balls[root[1]][root[0]]
  bfs [root], (p) -> balls[p[1]][p[0]] == color

connectedToTop = (gone) ->
  bfs ([x,0] for x in [0..xm] when isBall(x, 0) and [x,0] not of gone),
      (p) -> isBall(p...) and p not of gone

impact = (added) ->
  cc = connectedComponent added
  cclist = set2list cc
  if cclist.length > 2
    top = connectedToTop cc
    falling = []
    for p in cclist
      for neighbor in neighbors p...
        if isBall(neighbor...) and not (neighbor of cc or neighbor of top)
          falling.push neighbor
    fall = bfs falling, (p) -> isBall(p...) and not (p of cc or p of top)
    [cclist, set2list fall]
  else
    [[], []]

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

andLeftGadget = ascii2balls """
   B R          
  B R   B       
   B R B R R R R
  B B Y Y B B B 
   B B Y B B B B
  """

andMid3Gadget = ascii2balls """
        
        
   R R R
  B B B 
   B B B
  """

andMid4Gadget = ascii2balls """
          
          
   R R R R
  B B B B 
   B B B B
  """

andBlankGadget = ascii2balls '''
   B
  B 
   B
  B 
   B
  '''

andBlank3Gadget = repeatballs andBlankGadget, 3

andBlank4Gadget = repeatballs andBlankGadget, 4

andRightGadget = ascii2balls """
         R B B B
      B   R B B 
   R R B R B B B
  B B Y Y B B B 
   B B Y B B B B
  """

andWireGadget = orWireGadget = ascii2balls '''
   B Y B B Y B B
  B B Y Y Y B B 
   B B Y B B B B
  B B B Y B B B 
   B B Y B B B B
  '''

orLeftGadget = ascii2balls """
   R         B B
  B R   B B B B 
   B R B R R R R
  B B Y Y B B B 
   B B Y B B B B
  """

orMiddleGadget = ascii2balls """
                
  B B B B B B B 
   R R R R R R R
  B B B B B B B 
   B B B B B B B
  """

orRightGadget = ascii2balls """
           R B B
  B B B   R B B 
   R R B R B B B
  B B Y Y B B B 
   B B Y B B B B
  """

xoverGadget = ascii2balls '''
   R   B B           B B   R B
  R                         R 
   R                       R B
  B R R R R         R R R R B 
   R                       R B
  R                         R 
   R                       R B
  R                         R 
   R B B B R R R R R B B B R B
  B Y Y Y Y B B B B Y Y Y Y B 
   B B Y B B B B B B Y B B B B
  '''

xoverWireGadget = ascii2balls '''
   B Y B B Y B B
  B B Y Y Y B B 
   B B Y B B B B
  B B B Y B B B 
   B B Y B B B B
  B B B Y B B B 
   B B Y B B B B
  B B B Y B B B 
   B B Y B B B B
  B B B Y B B B 
   B B Y B B B B
  '''

splitLeftGadget = ascii2balls """
   B Y B B B B B
  B B Y Y Y Y Y 
   B B Y B B B B"""

splitMiddleGadget = ascii2balls '''
   B B B B B B B
  Y Y Y Y Y Y Y 
   B B B B B B B'''

splitRightGadget = ascii2balls '''
   B B B B Y B B
  Y Y Y Y Y B B 
   B B B B B B B'''

splitWireGadget = ascii2balls '''
   B Y B B Y B B
  B B Y Y Y B B 
   B B Y B B B B'''

splitNoGadget = ascii2balls '''
   B B B B B B B
  B B B B B B B 
   B B B B B B B'''

plugLeftGadget = ascii2balls '''
  B B B 
   B B B
  R R R '''

plugRightGadget = ascii2balls '''
  B B B B 
   B B B B
  R R R R '''

plugGadget = ascii2balls '''
  B B Y B B B B 
   B B Y R B B B
  R R R Y R R R '''

noplugGadget = ascii2balls '''
  B B B B B B B 
   B B B B B B B
  R R R R R R R '''

whitesp = "              \n"
setLine = "     B B      \n"
setGadget = ascii2balls setLine

nosetGadget = ascii2balls whitesp

blankGadget = ascii2balls whitesp

reduc2balls = (reduc) ->
  red = reduc.split '\n'
  rowtype = (row) ->
    return 'O' if 'O' in row
    return 'X' if 'X' in row
    return 'A' if 'A' in row
    return null
  typeheight =
    O: 5
    A: 5
    X: 11
  board = []
  setlayer = ascii2balls ""
  pluglayer = ascii2balls "\n\n"
  splitlayer = ascii2balls "\n\n"
  nplugs = 0
  console.log 
  for c in red[red.length-1]
    console.log parseInt(c)
    setlayer = glueballs(setlayer, setGadget, repeatballs(nosetGadget,parseInt(c)-1))
    pluglayer = glueballs(pluglayer, plugGadget, repeatballs(noplugGadget,parseInt(c)-1))
    if c == "1"
      splitlayer = glueballs(splitlayer, splitWireGadget)
    else
      splitlayer = glueballs(splitlayer, splitLeftGadget, repeatballs(splitMiddleGadget, parseInt(c)-2), splitRightGadget)
    nplugs += parseInt(c)
  board = pluglayer.concat setlayer
  board = splitlayer.concat board
  board = repeatballs(plugGadget, nplugs).concat board
  plugpos = [1..nplugs]
  #for i in [red.length-2..0]
  #  alayer = 
  #  for c in red[i]   
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board

init = (config) ->
  window.addEventListener 'keydown', keydown
  window.addEventListener 'keyup', keyup
  svg = SVG('surface')#.size width, height
  svgballs = svg.group()
  svgarrow = svg.group()
  svgaim = svg.group()
  #svgshoot = svg.group()
  sample = ascii2balls '''
    B B B B B       B
     R R 
    P    
     P R R
        B Y
         B





      
  '''
  board = []
  board = board.concat glueballs(plugLeftGadget, plugLeftGadget, plugGadget, plugRightGadget, plugRightGadget)
  board = board.concat glueballs(andBlank3Gadget, andLeftGadget, andMid4Gadget, andRightGadget)
#  board = board.concat(repeatballs andBlankGadget, 21)
  board = board.concat glueballs(plugLeftGadget, plugGadget, plugRightGadget, plugGadget)
  board = board.concat glueballs(orLeftGadget, orRightGadget, orWireGadget)
  board = board.concat glueballs(plugGadget, plugGadget, plugGadget)
  board = board.concat glueballs(xoverWireGadget, xoverGadget)
  board = board.concat glueballs(plugGadget, plugGadget, plugGadget)
  board = board.concat glueballs(splitLeftGadget, splitRightGadget, splitWireGadget)
  board = board.concat glueballs(plugGadget, noplugGadget, plugGadget)
  board = board.concat glueballs(setGadget, nosetGadget, setGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = board.concat glueballs(blankGadget, blankGadget, blankGadget)
  #board = sample
  someReduction = '''
    A
    AA
    WWOO
    WXXW
    WWXWW
    321
    '''
  board = reduc2balls(someReduction)
  ballseqstr = "BYYYBBBBRRRRRRBBBBBBBBYYYYYYBBBBBBBBRRRRRRBBBBBBBYYYYYYBBBBBBBBRRRRRRBBBBBBBBBYYYYYYYBBBBBBBRRRRRBBBBBYYYYYYBBBBBBRRRR"

  unless loadState()
    setBalls board
    ballseq = (ballseqstr[i] for i in [ballseqstr.length-1..0])
    #pushState()
    draw()

window?.onload = () ->
  resize = ->
    surface = document.getElementById('surface')
    surface.style.height =
      Math.floor(window.innerHeight - surface.getBoundingClientRect().top - 10) + 'px'
  window.addEventListener 'resize', resize
  resize()
  #window.addEventListener 'hashchange', loadState
  window.addEventListener 'popstate', loadState

  init()
