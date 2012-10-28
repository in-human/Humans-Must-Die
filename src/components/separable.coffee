{b2Segment} = Box2D.Collision
{b2Vec2} = Box2D.Common.Math
{b2World} = Box2D.Dynamics

Crafty.c "Separable"
  init: ->
    @requires "Box2D, Mouse"

    drawing = false

    @_onup = (e) ->
      drawing = false
      pos = Crafty.DOM.translate e.clientX, e.clientY
      @cutSegment.p2 = new b2Vec2 pos.x / @scale, pos.y / @scale
      laserFired = (fixture, point, output, fraction) =>
        ctx = Crafty.canvas.context
        ctx.strokeStyle = 'red'
        ctx.beginPath()
        ctx.arc(point.x*@scale, point.y*@scale, 2, 0, 2 * Math.PI, false)
        ctx.stroke()
      Crafty.Box2D.world.RayCast(laserFired,@cutSegment.p1,@cutSegment.p2)
      Crafty.Box2D.world.RayCast(laserFired,@cutSegment.p2,@cutSegment.p1)

    @_ondown = (e) ->
      drawing = true
      pos = Crafty.DOM.translate e.clientX, e.clientY
      return unless e.mouseButton is Crafty.mouseButtons.LEFT
      @cutSegment = new b2Segment()
      @cutSegment.p1 = new b2Vec2 pos.x / @scale, pos.y / @scale

    @_ondrag = (e) ->
      if drawing
        pos = Crafty.DOM.translate e.clientX, e.clientY
        ctx = Crafty.canvas.context
        ctx.clearRect(0, 0, 600, 400)
        ctx.strokeStyle = 'red'
        ctx.beginPath()
        ctx.moveTo @cutSegment.p1.x*@scale, @cutSegment.p1.y*@scale
        ctx.lineTo pos.x, pos.y
        ctx.stroke()


    Crafty.addEvent @, Crafty.stage.elem, "mousemove", @_ondrag
    Crafty.addEvent @, Crafty.stage.elem, "mouseup", @_onup
    Crafty.addEvent @, Crafty.stage.elem, "mousedown", @_ondown


  # laserFired: (fixture, point, output, fraction) ->
  #   console.log("POINT OUTPUT: " + point.x*@scale + " " + point.y*@scale)
  #   ctx = Crafty.canvas.context
  #   ctx.strokeStyle = 'red'
  #   ctx.beginPath()
  #   ctx.arc(point.x*@scale, point.y*@scale, 2, 0, 2 * Math.PI, false)
  #   ctx.stroke()
  #   console.log(@scale)






