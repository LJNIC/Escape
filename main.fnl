(let [batteries (require :source.lib.batteries)] (batteries:export))

(global vec2 (require :source.lib.vec2))
(global map functional.map)
(global reduce functional.reduce)

(global tile-width 8)

(local roomy (let [roomy (require :source.lib.roomy)] (roomy.new)))

(fn love.load []
  (roomy:hook)
  (roomy:enter (require :source.game)))
