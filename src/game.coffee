class window.InHumanGame
  constructor: (settings) ->
    settings.debug ?= false

    @width = settings.width ? 600
    @height = settings.height ? 400

    # Crafty initalizations
    Crafty.init @width, @height
    Crafty.canvas.init()

    Crafty.Box2D.init settings.physics if settings.physics

    # Setting debug mode if required
    Crafty.Box2D.debug = settings.debug # debugDraw
    if settings.debug
      Crafty.modules 'crafty-debug-bar': 'release', ->
        Crafty.debugBar.show()

    # MAIN Game Settings
    Crafty.background 'black'

    tower = Crafty.e("Tower, Bullet").deploy(150, 150, 120, 3)

    asteroid = Crafty.e("Asteroid").attr
                x: 500
                y:30
                r:30
                bodyType: "dynamic"
                restitution: 1
                friction: .5

    asteroid.impulse(-30,0)

    # Crafty.e("Asteroid").attr
    #   x: 100
    #   y: 100
    #   r: 30
    #   bodyType: "dynamic"
    #   restitution: 1
    #   friction: .5

    rectangle = Crafty.e("Wall, Throwable").attr
                  x: 570
                  y: 0
                  w: 30
                  h: 400
                  bodyType: "dynamic"
