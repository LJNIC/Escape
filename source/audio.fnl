(local ripple (require :lib/ripple))
(local audio {})

(local sfx (ripple.newTag))
(set sfx.volume 0.2)

(local jump-sound (ripple.newSound (love.audio.newSource "assets/jump.wav" "static") {:tags [sfx]}))
(local die-sound (ripple.newSound (love.audio.newSource "assets/die.wav" "static") {:tags [sfx]}))
(local die-sound2 (ripple.newSound (love.audio.newSource "assets/die2.wav" "static") {:tags [sfx]}))
(local bounce-sound (ripple.newSound (love.audio.newSource "assets/bounce.wav" "static") {:tags [sfx]}))
(local jet-sound (ripple.newSound (love.audio.newSource "assets/jet.wav" "static") {:tags [sfx]}))

(local sounds {:jump jump-sound :die die-sound :die2 die-sound2 :bounce bounce-sound :jet jet-sound})

(fn audio.play [sound options]
  (let [s (. sounds sound)]
    (s:play options)))

audio
