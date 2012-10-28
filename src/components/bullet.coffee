Crafty.c "Bullet",
  init: ->
    @requires "Box2D"
    @ammo = [] # a pool of bullets
    @actives = [] # bullets being used

    # Add some bullets into the pool
    for i in [0...20]
      bullet = Crafty.e("Box2D, Movable").attr
                      x: @x
                      y: @y
                      r: 3
                      bodyType: "dynamic"
                      isSensor: true
      bullet.isBullet = true
      bullet.body.SetActive false
      @ammo.push bullet

  getBullet: ->
    bullet = @ammo.pop()
    unless bullet?
      bullet = Crafty.e("Box2D, Movable").attr
                      x: @x
                      y: @y
                      r: 3
                      bodyType: "dynamic"
                      isSensor: true

      bullet.isBullet = true

    @actives.push bullet
    bullet

  freeBullet: (bullet) ->
    l = actives.length
    while l--
      array.slice l, 1

    @ammo.push bullet

  fire: (auto = false) ->
    @getBullet().impulse() unless auto
    else
      @bind "EnterFrame", ({frame}) =>
        if frame % 10 is 0 # the frequent
          @getBullet().impulse(200, 0)