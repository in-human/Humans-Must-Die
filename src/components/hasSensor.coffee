{b2Vec2} = Box2D.Common.Math

Crafty.c "HasSensor",
  init: ->
    @requires "Box2D"

  range: (radius, beginContact, endContact) ->
    @isSensor = true
    @circle radius

    # vertices = [[@r,@r]]
    # for i in [0...7]
    #   angle = Crafty.math.degToRad(i / 6.0 * 90)
    #   vertices[i+1] = [@r+radius*Math.cos(angle), @r+radius*Math.sin(angle)] 

    # @polygon vertices
    # @body.SetAngularVelocity(Crafty.math.degToRad(45));

    # Adjust the local so that it's centered at the entity's center.
    # Because we've just added a circle shape into the body, we could
    # just query the latest fixture and get the shape from it.
    shape = @body.GetFixtureList().GetShape()
    shape.SetLocalPosition new b2Vec2 @r / @scale, @r / @scale

    @onHit "Box2D", beginContact, endContact