b2Vec2 = Box2D.Common.Math.b2Vec2
{b2BodyDef, b2Body, b2FixtureDef, b2Fixture, b2World, b2DebugDraw, b2ContactListener} = Box2D.Dynamics
{b2AABB, b2WorldManifold, Shapes: {b2MassData, b2PolygonShape, b2CircleShape}} = Box2D.Collision

Crafty.c "Movable",
  init: ->
    @requires "Box2D"
    @SCALE = Crafty.Box2D.SCALE

  impulse: (dirX, dirY, localPointX, localPointY) ->
    return if not @body?
    if arguments.length > 2
      localPoint =  @body.GetWorldPoint(new b2Vec2(arguments[2] / @SCALE, arguments[3] / @SCALE))
    else
      localPoint = @body.GetWorldCenter()
    @body.ApplyImpulse(new b2Vec2(dirX / @SCALE, dirY / @SCALE), localPoint)

  ### FIXME: Refactor this with impulse since they are the same ###
  push: (dirX, dirY, localPointX, localPointY) ->
    return if not @body?
    if arguments.length > 2
      localPoint =  @body.GetWorldPoint(new b2Vec2(arguments[2] / @SCALE, arguments[3] / @SCALE))
    else
      localPoint = @body.GetWorldCenter()
    @body.ApplyForce(new b2Vec2(dirX / @SCALE, dirY / @SCALE), localPoint)

  linearVelocity: ({x, y}) ->
    return if not @body?
    current = @body.GetLinearVelocity()
    return current if arguments.length is 0
    x = x ? current.x
    y = y ? current.y
    @body.SetLinearVelocity(new b2Vec2(x, y))