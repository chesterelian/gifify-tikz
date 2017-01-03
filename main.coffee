# ------------------------------------------------------------------------------
# Settings
# ------------------------------------------------------------------------------

filename    = "sandbox.tex"
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

# Think: Riemann sums. Number of intervals needed is n, so number of frames
# needed is n + 1.
n = Math.ceil(duration / delay)
step = (end - start) / n
params = ((start + i * step).toFixed(4) for i in [0...n]).concat(end)

console.log "Frames to render: #{n + 1}"

frame = (i) -> filename.replace(/\.tex$/, "_frame#{i}.png")

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
