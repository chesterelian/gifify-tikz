# ------------------------------------------------------------------------------
# Settings
# ------------------------------------------------------------------------------

filename    = "tex/stretch.tex"
placeholder = "LENGTH"
start       = 1
end         = 2

# Note: Units are CENTIseconds, not milliseconds!

duration    = 100 # duration of animation
delay       = 5 # delay between frames
firstFreeze = 100 # how long to freeze the first frame
lastFreeze  = 100 # how long to freeze the last frame

# ------------------------------------------------------------------------------
# DON'T FUCK WITH THE CODE BELOW UNLESS YOU KNOW WHAT YOU'RE DOING.
# ------------------------------------------------------------------------------

fs = require 'fs'
{ exec, execSync } = require('child_process')

# Read entire file into string.
file = fs.readFileSync(filename, "utf8")

# Get gifify script
gifify = file.match(/%\s*GIFIFY\s+BEGIN\s*((?:%\s*.*\s*|\s*)+)%\s*GIFIFY\s+END/)
console.log "Your script is:\n#{gifify[1]}"

# Store gifify script as array of lines
#gifify = (line.replace(/^\s*%\s*|\s*$/, "") for line in gifify[1].split("\n"))
gifify = gifify[1].split(/\s*(?:%\s*)+/)
console.log gifify

for line in gifify
  if line.match(/^\s*$/)
    continue
  match = line.match(/(fps|freeze|param)\s*=\s*(.*)/)
  if match is null
    console.error "Invalid syntax (will be ignored): #{line}"
  else
    [dummy, key, value, ...] = match
    if key is "fps"
      if value.match(/^\d+$/)
        delay = Math.floor(100 / value)
        console.log "You requested #{value} fps. 
          I can give you #{Math.floor(100 / delay)} fps."
      else
        console.error "fps error: #{value} is not an integer.
          fps will default to 5."
    else if key is "freeze"
      if value.match(/^\d+$/)
        firstFreeze = lastFreeze = value
      else if value.match(/^\d+\s+\d+$/)
        [firstFreeze, lastFreeze] = value.split(/\s+/)
      else
        console.error "freeze error: #{value} is not an integer.
          freeze will default to 100."
      console.log "First frame will freeze for #{firstFreeze} centiseconds."
      console.log "Last frame will freeze for #{lastFreeze} centiseconds."
    else if key is "param"
      console.log ""

# Think: Riemann sums. Number of intervals needed is n, so number of frames
# needed is n + 1.
n = Math.ceil(duration / delay)
step = (end - start) / n
params = ((start + i * step).toFixed(4) for i in [0...n]).concat(end)

console.log "Frames to render: #{n + 1}"

frame = (i) -> filename.replace(/\.tex$/, "_frame#{i}.png")

poop = ->
  for param, i in params
    bub = file.replace(placeholder, param)
    fs.writeFileSync("bub#{param}.tex", bub, "utf8", (err) -> console.log(err) if err)

    console.log "Rendering frame #{i}..."
    execSync "
      pdflatex bub#{param}.tex;
      convert -density 600x600 -quality 90 -resize 200x200 bub#{param}.pdf #{frame(i)};
    "

  console.log "Prepending #{Math.round(firstFreeze / delay)} first frames."
  console.log "Appending #{Math.round(lastFreeze / delay)} last frames."

  input = [
    (frame(0) for [0...Math.round(firstFreeze / delay)])...
    (frame(i) for i in [0..n])...
    (frame(n) for [0...Math.round(lastFreeze / delay)])...
  ].join(" ")

  output = filename.replace(/tex$/, "gif")

  console.log "Rendering final GIF..."
  execSync "
    rm bub*;
    convert -delay #{delay} -loop 0 #{input} #{output};
  "
