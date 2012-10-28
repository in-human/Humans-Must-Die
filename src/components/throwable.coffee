{b2Vec2} = Box2D.Common.Math
{b2MouseJointDef} = Box2D.Dynamics.Joints

Crafty.c "Throwable",
  init: ->
    @requires "Box2D, Mouse"

    @_ondrag = (e) =>
      pos = Crafty.DOM.translate e.clientX, e.clientY
      return false if pos.x is 0 and pos.y is 0
      if @mouseJoint?
        @mouseJoint.SetTarget(new b2Vec2(pos.x / @scale, pos.y / @scale))

    @_ondown = (e) =>
      return unless e.mouseButton is Crafty.mouseButtons.LEFT
      @_startDrag e

    @_onup = (e) =>
      if @_dragging
        {world} = Crafty.Box2D
        world.DestroyJoint(@mouseJoint)
        @mouseJoint = null

        Crafty.removeEvent @, Crafty.stage.elem, "mousemove", @_ondrag
        Crafty.removeEvent @, Crafty.stage.elem, "mouseup", @_onup
        @_dragging = false
        @trigger "StopDrag", e

    @enableDrag()

  _startDrag: (e) ->
    {DOM: {translate}, Box2D: {world}} = Crafty

    pos = translate(e.clientX, e.clientY)
    md = new b2MouseJointDef()
    md.bodyA = world.GetGroundBody()
    md.bodyB = @body
    md.target.Set pos.x / @scale, pos.y / @scale
    md.collideConnected = true
    md.maxForce = 300.0 * @body.GetMass()
    @mouseJoint = world.CreateJoint(md)
    @body.SetAwake true

    @_dragging = true

    Crafty.addEvent @, Crafty.stage.elem, "mousemove", @_ondrag
    Crafty.addEvent @, Crafty.stage.elem, "mouseup", @_onup
    @trigger "StartDrag", e

  stopDrag: ->
    Crafty.removeEvent @, Crafty.stage.elem, "mousemove", @_ondrag
    Crafty.removeEvent @, Crafty.stage.elem, "mouseup", @_onup
    @_dragging = false
    @trigger "StopDrag"
    @

  startDrag: ->
    @_startDrag Crafty.lastEvent unless @_dragging
    @

  enableDrag: ->
    @bind "MouseDown", @_ondown
    Crafty.addEvent @, Crafty.stage.elem, "mouseup", @_onup
    @

  disableDrag: ->
    @unbind "MouseDown", @_ondown
    @stopDrag()
    @

