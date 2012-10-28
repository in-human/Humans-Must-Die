Crafty.c "Tower",
  init: ->
    @addComponent "Box2D, HasSensor"
    @targets = []

    @onContact = ([{obj}]) =>
      @targets.push obj

    @endContact = (obj) =>
      # Remove the obj from the targets list
      @targets = (target for target in @targets when target[0] isnt obj[0]) 

  deploy: (x, y, range, damage) ->
    @attr
      x: x
      y: y
      r: 30
      bodyType: "kinematic"
      density: 1.0
      friction: 0.5
      restitution: 0.2
      damage: damage
    .range range, @onContact, @endContact

    @bind "EnterFrame", =>
      return if @targets.length is 0
      target = @targets[0]
      unless target?
        @targets.shift()
        target = @targets[0]

      target.hp -= @damage unless target.hp is NaN

      # If tower is not cicle, see http://www.iforce2d.net/b2dtut/rotate-to-angle
      # to rotate the entity to the target's location.

    @