(local ripple (require :source.lib.ripple))
(local audio {})

(local sfx (ripple.newTag))
(set sfx.volume 0.2)

(local jump (ripple.newSound (love.audio.newSource "source/assets/jump.wav" "static") {:tags [sfx]}))
(local die (ripple.newSound (love.audio.newSource "source/assets/die.wav" "static") {:tags [sfx]}))
(local die2 (ripple.newSound (love.audio.newSource "source/assets/die2.wav" "static") {:tags [sfx]}))
(local bounce (ripple.newSound (love.audio.newSource "source/assets/bounce.wav" "static") {:tags [sfx]}))
(local jet (ripple.newSound (love.audio.newSource "source/assets/jet.wav" "static") {:tags [sfx]}))
(local button (ripple.newSound (love.audio.newSource "source/assets/button.wav" "static") {:tags [sfx]}))

(local sounds {: jump : die : die2 : bounce : jet : button})

(fn audio.play [sound options]
  (let [s (. sounds sound)]
    (s:play options)))

audio
