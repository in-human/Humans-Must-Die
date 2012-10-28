Crafty.c "WorkBench",
  init: ->
    @requires "2D, Canvas, Mouse"
    @trace = []

    drawing = false

    @bind "MouseDown", (e) =>
      drawing = true
      @getPointFromMouse e
      @bind "MouseMove", @getPointFromMouse

    @bind "MouseUp", (e) =>
      if drawing
        drawing = false
        @unbind "MouseMove", @getPointFromMouse
        @checkPoints()

    @bind "Draw", (obj) =>
      @_draw obj.ctx, obj.pos

  _draw: (ctx, pos) ->
    return if @trace.length is 0
    ctx.strokeStyle = "rgb(163, 163, 163)"
    ctx.lineWidth = 2
    ctx.beginPath()
    ctx.moveTo @trace[0][0], @trace[0][1]
    if @trace.length > 1
      ctx.lineTo @trace[i][0], @trace[i][1] for i in [1..@trace.length-1]
    ctx.stroke()

  getPointFromMouse: (e) ->
    pos = Crafty.DOM.translate(e.clientX, e.clientY)
    point = [pos.x, pos.y]
    @trace.push point

  checkPoints: ->
    if @trace.length >= 20
      begin = @trace[0]
      end = @trace[@trace.length-1]

      # If the end point is closed to the begin point
      if Crafty.math.distance(begin[0], begin[1], end[0], end[1]) <= 50
        # Reduce the number of points until <=8
        points = @trace
        value = 3
        while points.length > 8
          #points = @trace
          i = 0
          while i < points.length
            pointA = points[(i-1+points.length)%points.length]
            pointB = points[i]
            pointC = points[(i+1)%points.length]

            A = ( pointC[0] * (pointA[1] - pointB[1]) +
                                    pointA[0] * (pointB[1] - pointC[1]) +
                                    pointB[0] * (pointC[1] - pointA[1]) ) / 2.0
            if Crafty.math.abs(A) <= value
              points.splice(i, 1)
            i++
          value += 7

        # Divide polygon if necessary
        solution = @triangulate points

        # Find the min x, max x, min y, max y
        minX = points[0][0]
        minY = points[0][1]
        maxX = points[0][0]
        maxY = points[0][1]
        for i in [1..points.length-1]
          if (points[i][0] < minX)
                  minX = points[i][0]
          else if (points[i][0] > maxX)
                  maxX = points[i][0]
          if (points[i][1] < minY)
                  minY = points[i][1]
          else if (points[i][1] > maxY)
                  maxY = points[i][1]

        #Relative points to x and y
        for i in [0..points.length-1]
          points[i][0] -= minX
          points[i][1] -= minY

        # Create the asteroid
        ###Crafty.e("Canvas, LanAsteroid")
        .attr
                x: minX-2
                y: minY-2
                w: maxX - minX + 4
                h: maxY - minY + 4
                z: 1
                points: points###
        anAsteroid = Crafty.e("Asteroid")
        anAsteroid.attr(
                        x: minX
                        y: minY
                        w: maxX - minX
                        h: maxY - minY)
        if solution.length <= 1
          anAsteroid.createPoly(points, minX, minY)
        else
          for s in solution
            p = []
            p.push points[i] for i in s
            anAsteroid.createPoly(p)
        anAsteroid.impulse(Crafty.math.randomInt(-50, -100), Crafty.math.randomInt(-50, 50))
        console.log anAsteroid


    # Set to default value
    @trace = []
    #@points = []

    # Change the workbench
    @trigger "Change"
