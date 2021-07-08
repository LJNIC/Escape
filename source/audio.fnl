(local ripple (require :lib/ripple))
(local audio {})

(local sfx (ripple.newTag))
(set sfx.volume 0.2)

(local jumpSound (ripple.newSound (love.audio.newSource "assets/jump.wav" "static") {:tags [sfx]}))
(local dieSound (ripple.newSound (love.audio.newSource "assets/die.wav" "static") {:tags [sfx]}))
(local dieSound2 (ripple.newSound (love.audio.newSource "assets/die2.wav" "static") {:tags [sfx]}))
(local bounceSound (ripple.newSound (love.audio.newSource "assets/bounce.wav" "static") {:tags [sfx]}))
(local jetSound (ripple.newSound (love.audio.newSource "assets/jet.wav" "static") {:tags [sfx]}))

(local sounds {:jump jumpSound :die dieSound :die2 dieSound2 :bounce bounceSound :jet jetSound})

(fn audio.play [sound options]
  (let [s (. sounds sound)]
    (s:play options)))

audio
