
DefaultSystem = new LSystem({
    size: {value:12.27}
    angle: {value:4187.5}
  }
  ,"L : SS\nS : F-[F-Y[S(L]]\nY : [-|F-F+)Y]\n"
  ,12
  ,"click-and-drag-me!"
)

class InputHandler
  snapshot: null # lsystem params as they were was when joystick activated
  constructor: (@keystate, @joystick) ->
  update: (params) =>
    return if not @joystick.active
    if (@keystate.alt)
      params.size.value = Util.round(params.size.value + @joystick.dy(200), 2)
      params.size.growth += @joystick.dx(1000000)
    else
      params.angle.value = Util.round(params.angle.value + @joystick.dx(), 2)
      params.angle.growth += @joystick.dy()


#yes this is an outrageous name for a .. system ... manager. buh.
class SystemManager
  joystick:null
  keystate: null
  inputHandler: null
  renderer:null
  currentSystem:null
  constructor: (@canvas, @controls) ->
    @joystick = new Joystick(canvas)
    @keystate = new KeyState
    @inputHandler = new InputHandler(@keystate, @joystick)

    @joystick.onRelease = => location.hash = @currentSystem.toUrl()
    @joystick.onActivate = => @inputHandler.snapshot = _.clone(@currentSystem.params)

    @renderer = new Renderer(canvas)
    @currentSystem = LSystem.fromUrl() or DefaultSystem
    @init()

  syncLocation: -> location.hash = @currentSystem.toUrl()

  updateFromControls: ->

    @currentSystem = new LSystem(
      @uiControls.toJson(),
      $(@controls.rules).val(),
      parseInt($(@controls.iterations).val())
    )

  exportToPng: ->
    canvas = Util.control("c")
    [x,y] = [canvas.width / 2 , canvas.height / 2]

    b = @renderer.context.bounding
    c = $('<canvas></canvas>').attr({
      "width" : b.width()+30,
      "height": b.height()+30
    })[0]

    r = new Renderer(c)
    r.reset = (system) ->
      r.context.reset(system)
      r.context.state.x = (x-b.x1+15)
      r.context.state.y = (y-b.y1+15)

    r.render(@currentSystem)
    Util.openDataUrl(c.toDataURL("image/png"))

  init: ->
    @createBindings()
    @createControls()
    @syncControls()

  run: ->
    @inputHandler.update(@currentSystem.params)
    if @joystick.active and not @renderer.isDrawing
      @draw()
      @syncControls()
    setTimeout((() => @run()), 10)

  draw: ->
    t = @renderer.render(@currentSystem)
    #todo: get from bindings
    $("#rendered").html("#{t}ms")
    $("#segments").html("#{@currentSystem.elements().length}")

  createControls: ->
    @uiControls = new Controls(LSystem.defaultParams())
    @uiControls.create(@controls.container)

  syncControls: ->
    $(@controls.iterations).val(@currentSystem.iterations)
    $(@controls.rules).val(@currentSystem.rules)
    @uiControls.sync(@currentSystem.params)

  createBindings: ->
    document.onkeydown = (ev) =>
      if ev.keyCode == 13 and ev.ctrlKey
        @updateFromControls()
        @syncLocation()
      if ev.keyCode == 13 and ev.shiftKey
        @exportToPng()

    window.onhashchange = =>
      if location.hash != ""
        sys = LSystem.fromUrl()
        @currentSystem.merge(sys)
        @syncControls()
        @draw()

#===========================================