(local util {})

(fn util.add [a b] (+ a b))
(fn util.sub [a b] (- a b))
(fn util.opposite [operation]
  (if (= operation util.add) util.sub util.add))

(fn util.updateObject [object x y]
  (set object.x x)
  (set object.y y)
  (world:update object x y))

util