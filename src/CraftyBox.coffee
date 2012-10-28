{b2Vec2} = Box2D.Common.Math
{b2BodyDef, b2Body, b2FixtureDef, b2Fixture, b2World, b2DebugDraw, b2ContactListener} = Box2D.Dynamics
{b2AABB, b2WorldManifold, b2Segment, Shapes: {b2MassData, b2PolygonShape, b2CircleShape}} = Box2D.Collision
{b2MouseJointDef} = Box2D.Dynamics.Joints

Crafty.c "Box2D", do ->
  _bodyTypes = ["static", "kinematic", "dynamic"]

  configureFixture = (fixDef, attrs) ->
    if attrs?
      fixDef.density = attrs.density if attrs.density?
      fixDef.friction = attrs.friction if attrs.friction?
      fixDef.isSensor = attrs.isSensor if attrs.isSensor?
      fixDef.restitution = attrs.restitution if attrs.restitution?
      fixDef.userData = attrs.userData if attrs.userData?
      fixDef.filter.categoryBits = attrs.filter.categoryBits if attrs.filter?.categoryBits?
      fixDef.filter.groupIndex = attrs.filter.groupIndex if attrs.filter?.groupIndex?
      fixDef.filter.maskBits = attrs.filter.maskBits if attrs.filter?.maskBits?

  init: ->
    @addComponent "2D"
    Crafty.Box2D.init() unless Crafty.Box2D.world?
    @scale = Crafty.Box2D.SCALE

    @bodyDef = new b2BodyDef
    @fixDef = new b2FixtureDef

    # How hard the body is to move
    @__defineSetter__ "density", (v) => @fixDef.density = v
    # How bouncy the body is
    @__defineSetter__ "restitution", (v) => @fixDef.restitution = v
    # How slippery the body is
    @__defineSetter__ "friction", (v) => @fixDef.friction = v
    # If this is true, the object can detect collisions but can move through other objects.
    @__defineSetter__ "isSensor", (v) => @fixDef.isSensor = v
    # A bitfield indicating the categories the body belongs to.
    @__defineSetter__ "categoryBits", (v) => @fixDev.filter.categoryBits = v
    # Any bodies with the same group index always collide (if the index is positive)
    # or never collide (if the index is negative), regardless of category/mask settings.
    @__defineSetter__ "groupIndex", (v) => @fixDev.filter.groupIndex = v
    # A bitfield indicating what categories the body collides with.
    @__defineSetter__ "maskBits", (v) => @fixDev.filter.maskBits = v
    @__defineSetter__ "isBullet", (v) => @body.IsBullet true

    ###
    Update the entity by using Box2D's attributes.
    ###
    @bind "EnterFrame", =>
      if @body? and @body.IsAwake()
        pos = @body.GetPosition()
        angle = Crafty.math.radToDeg @body.GetAngle()

        @x = pos.x*@scale if pos.x*@scale isnt @x
        @y = pos.y*@scale if pos.y*@scale isnt @y
        @rotation = angle if angle isnt @rotation

    ###
    Add this body to a list to be destroyed on the next step.
    This is to prevent destroying the bodies during collision.
    ###
    @bind "Remove", =>
      Crafty.Box2D.destroy @body if @body?

    # When using entity.attr, it triggers "Change" event with
    # the arguments. Note that "Change" event is also triggered
    # multiple places and thus we need to pick the right one.
    @bind "Change", ({x, y, w, h, r, vertices, bodyType}) =>
      if x? and y?
        @createBody x, y, bodyType

      if r?
        @circle r
        @w = @h = r * 2
      else if w? and h?
        @rectangle w, h
      else if vertices?
        @polygon vertices

  # Both a getter and setter for body's type.
  bodyType: (bodyType) ->
    return _bodyTypes[@body.GetType()] unless bodyType?
    @body.SetType(b2Body["b2_#{bodyType}Body"]) if bodyType in _bodyTypes
    @

  createBody: (x, y, type) ->
    @bodyDef ?= new b2BodyDef
    @bodyDef.type = b2Body["b2_#{type}Body"] if type in _bodyTypes
    @bodyDef.position.Set x / @scale, y / @scale
    @body = Crafty.Box2D.world.CreateBody @bodyDef
    @body.SetUserData @[0]
    @

  # APIs to attach a shape into entity's body
  circle: (radius, attrs) ->
    throw new Error "Require a body to add fixture to" unless @body?
    @fixDef ?= new b2FixtureDef
    configureFixture @fixDef, attrs
    @fixDef.shape = new b2CircleShape radius / @scale
    @fixDef.shape.SetLocalPosition new b2Vec2 radius / @scale, radius / @scale
    @body.CreateFixture @fixDef
    @
    
  rectangle: (w, h, attrs) ->
    throw new Error "Require a body to add fixture to" unless @body?
    @fixDef ?= new b2FixtureDef
    configureFixture @fixDef, attrs
    @fixDef.shape = new b2PolygonShape
    hW = w / @scale / 2
    hH = h / @scale / 2
    @fixDef.shape.SetAsOrientedBox hW, hH, new b2Vec2 hW, hH
    @body.CreateFixture @fixDef
    @

  # vertices = [vertex]
  # vertex = [x, y]
  # x, y = int/float
  polygon: (vertices, attrs) ->
    throw new Error "Require a body to add fixture to" unless @body?
    @fixDef ?= new b2FixtureDef
    configureFixture @fixDef, attrs
    @fixDef.shape = new b2PolygonShape
    polys = (new b2Vec2(x / @scale, y / @scale) for [x, y] in vertices)
    @fixDef.shape.SetAsArray polys, polys.length
    @body.CreateFixture @fixDef
    @

  ###
  #.hit
  @comp Box2D
  @sign public Boolean/Array hit(String component)
  @param component - Component to check collisions for
  @return `false if no collision. If a collision is detected, return an Array of
  objects that are colliding, with the type of collision, and the contact points.
  The contact points has at most two points for polygon and one for circle.
  ~~~
  [{
    obj: [entity],
    type: "Box2D",
    points: [Vector[, Vector]]
  }] 
  ###
  hit: (component) ->
    contactEdge = @body.GetContactList()
    # Return false if no collision at this frame
    return false unless contactEdge?

    otherEntity = Crafty contactEdge.other.GetUserData()

    return false unless otherEntity.has component
    # A contact edge happens as soon as the two AABBs are touching, not the fixtures.
    # We only care when the fixture are actually touching.
    return false unless contactEdge.contact.IsTouching()

    finalresult = []

    ## Getting the contact points through manifold
    manifold = new b2WorldManifold()
    contactEdge.contact.GetWorldManifold(manifold)
    contactPoints = manifold.m_points

    finalresult.push({obj: otherEntity, type: "Box2D", points: contactPoints})

    return finalresult

  ###
  #.onHit
  @comp Box2D
  @sign public this .onHit(String component, Function beginContact[, Function endContact])
  @param component - Component to check collisions for
  @param beginContact - Callback method to execute when collided with component, 
  @param endContact - Callback method executed once as soon as collision stops
  Invoke the callback(s) if collision detected through contact listener. We don't bind
  to EnterFrame, but let the contact listener in the Box2D world notify us.
  ###
  onHit: (component, beginContact, endContact) ->
    return @ unless component is "Box2D"

    @bind "BeginContact", ({target, points}) =>
      hitData = [{obj: target, type: "Box2D", points: points}]
      beginContact.call @, hitData

    if typeof endContact is "function"
      # This is only triggered once per contact, so just execute endContact callback.
      @bind "EndContact", (obj) =>
        endContact.call @, obj

    @


###
# #Crafty.Box2D
# @category Physics
# Dealing with Box2D
###
Crafty.extend
  Box2D: do ->
    ###
    PRIVATE
    ###

    _SCALE = 30

    ###
    # #Crafty.Box2D.world
    # @comp Crafty.Box2D
    # This will return the Box2D world object through a getter,
    # which is a container for bodies and joints.
    # It will have 0 gravity when initialized.
    # Gravity can be set through a setter:
    # Crafty.Box2D.gravity = {x: 0, y:10}
    ###
    _world = null

    ###
    A list of bodies to be destroyed in the next step. Usually during
    collision step, it's bad to destroy bodies. 
    ###
    _toBeRemoved = []

    ### 
    Setting up contact listener to notify the concerned entities based on
    the entify reference in their body's user data that we set during the
    construction of the body. We don't keep track of the contact but let 
    the entities handle the collision.
    ###
    _setContactListener = ->
      contactListener = new b2ContactListener
      contactListener.BeginContact = (contact) ->
        entityIdA = contact.GetFixtureA().GetBody().GetUserData()
        entityIdB = contact.GetFixtureB().GetBody().GetUserData()

        ## Getting the contact points through manifold
        manifold = new b2WorldManifold()
        contact.GetWorldManifold manifold
        contactPoints = manifold.m_points

        Crafty(entityIdA)?.trigger? "BeginContact",
              points: contactPoints
              target: Crafty(entityIdB)
        Crafty(entityIdB)?.trigger? "BeginContact", 
              points: contactPoints
              target: Crafty(entityIdA)

      contactListener.EndContact = (contact) ->
        entityIdA = contact.GetFixtureA().GetBody().GetUserData()
        entityIdB = contact.GetFixtureB().GetBody().GetUserData()
        Crafty(entityIdA)?.trigger? "EndContact", Crafty(entityIdB)
        Crafty(entityIdB)?.trigger? "EndContact", Crafty(entityIdA)

      # Called everytime a body feels an impulse from another body.
      # If object A hits object B which is connected to object C,
      # object C will feel the impulse from object A's initial hit
      # (because the impulse "bumps" object B which "bumps" object C).
      #
      # For example, if you have a ball rolling across the ground,
      # this creates an impulse (albeit tiny) for every frame, and 
      # PostSolve() will be fired every frame. If you have other 
      # objects touching the ground, those objects will feel an impulse
      # from the ground (which is "rumbled" by the ball rolling.)
      # 
      # void PostSolve(b2Contact contact, b2ContactImpulse impulse)
      contactListener.PostSolve = (contact, impulse) ->
        entityIdA = contact.GetFixtureA().GetBody().GetUserData()
        entityIdB = contact.GetFixtureB().GetBody().GetUserData()
        Crafty(entityIdA)?.trigger? "PostSolve",
          impulse: impulse
          target: Crafty(entityIdB)
        Crafty(entityIdB)?.trigger? "PostSolve",
          impulse: impulse
          target: Crafty(entityIdA)

      contactListener.PreSolve = (contact, oldManifold) ->


      _world.SetContactListener contactListener

    # Setting up debug draw. Setting @debug outside will trigger drawing
    _setDebugDraw = -> 
      if Crafty.support.canvas
        canvas = document.createElement "canvas"
        canvas.id = "Box2DCanvasDebug"
        canvas.width = Crafty.viewport.width
        canvas.height = Crafty.viewport.height
        canvas.style.position = 'absolute'
        canvas.style.left = "0px"
        canvas.style.top = "0px"

        Crafty.stage.elem.appendChild canvas

        debugDraw = new b2DebugDraw()
        debugDraw.SetSprite canvas.getContext '2d'
        debugDraw.SetDrawScale _SCALE
        debugDraw.SetFillAlpha 0.7
        debugDraw.SetLineThickness 1.0
        debugDraw.SetFlags b2DebugDraw.e_shapeBit | b2DebugDraw.e_joinBit
        _world.SetDebugDraw debugDraw


    ###
    PUBLIC
    ###

    ###
    # #Crafty.Box2D.debug
    # @comp Crafty.Box2D
    # This will determine whether to use Box2D's own debug Draw
    ###
    debug: false

    ###
    # #Crafty.Box2D.init
    # @comp Crafty.Box2D
    # @sign public void Crafty.Box2D.init(params)
    # @param options: An object contain settings for the world
    # Create a Box2D world. Must be called before any entities
    # with the Box2D component can be created
    ###
    init: ({gravityX, gravityY, scale, doSleep} = {}) ->
      gravityX ?= 0
      gravityY ?= 0
      _SCALE ?= 30
      doSleep ?= true

      _world = new b2World(new b2Vec2(gravityX, gravityY), doSleep)

      @__defineGetter__ 'world', () -> _world
      @__defineSetter__ 'gravity', (v) -> 
        _world.SetGravity new b2Vec2(v.x, v.y)
        body = _world.GetBodyList()
        while body?
          body.SetAwake(true)
          body = body.GetNext()

      @__defineGetter__ 'gravity', () -> _world.GetGravity()
      @__defineGetter__ 'SCALE', () -> _SCALE

      _setContactListener()

      # Update loop
      Crafty.bind "EnterFrame", =>
        _world.Step 1/Crafty.timer.getFPS(), 10, 10
        _world.DrawDebugData() if @debug
        _world.ClearForces()

        for body in _toBeRemoved
          _world.DestroyBody body
        _toBeRemoved = []

      _setDebugDraw()

    

    ###
    #Crafty.Box2D.destroy
    @comp Crafty.Box2D
    @sign public void Crafty.Box2D.destroy([b2Body body])
    @param body - The body to be destroyed. Destroy all if none
    Destroy all the bodies in the world. Internally, add to a list to destroy
    on the next step to avoid collision step.
    ###
    destroy: (body)->
      if body?
        _toBeRemoved.push body
      else
        body = _world.GetBodyList()
        while body?
          _toBeRemoved.push body
          body = body.GetNext()