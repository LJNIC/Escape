(local util {})

(fn util.add [a b] (+ a b))
(fn util.sub [a b] (- a b))
(fn util.opposite [operation]
  (if (= operation util.add) util.sub util.add))

(fn util.updateObject [object x y]
  (set object.x x)
  (set object.y y)
  (world:update object x y))

(local colors {[0 0 1] 181 [1 0 0] 211 [0 1 0] 210 [1 1 0] 299 [0 1 1] 393 [1 0 1] 341})

(fn getTile [red green blue]
  (var id 400)
  (each [c tile (pairs colors)]
    (let [[r g b] c]
      (when (and (= red r) (= green g) (= blue b))
        (set id tile))))
  id)

(fn util.loadMap [path]
  (let [image (love.image.newImageData path)
        newMap {}]
    (for [x 0 (- (image:getWidth) 1)]
      (table.insert newMap [])
      (for [y 0 (- (image:getHeight) 1)]
        (table.insert (. newMap (+ 1 x)) (getTile (image:getPixel x y)))))
  newMap))

util