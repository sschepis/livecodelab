#jslint browser: true, devel: true 
#global $ 

# The user can issue multiple solid fill and gradient fill commands
# and they are all painted on top of each other according to the
# order they have been issued in.
# So for example you can have one gradient and then
# a second one painted over it that uses some transparency.
#
# This is why solid and gradient fills are all kept in an array
# and each time the user issues one of the two commands, an
# element is added to the array.
#
# Both solid and gradient fills are stored as elements in the
# array, all elements are the same and accommodate for a description
# that either case (solid/gradient).
#
# The background/gradients are drawn on a separate 2D canvas
# and we avoid repainting that canvas over and over if the
# painting commands stay the same (i.e. colors of their
# arguments and the order of the commands) across frames.
#
# For quickly determining whether the order/content of the commands
# has changed across frames,
# a string is kept that represents the whole stack of commands
# issued in the current frame, and similarly the "previous frame"
# string representation is also kept.
# So it's kind of like a simplified JSON representation if you will.
#
# If the strings are the same across frames, then the 2D layer of
# the background is not repainted, otherwise the array is iterated
# and each background/gradient is painted anew.
#
# Note that we are not trying to be too clever here - for example
# a solid fill effectively invalidates the contents of the previous
# elements of the array, so we could discard those when such
# a command is issued.
createBackgroundPainter = (eventRouter, canvasForBackground, liveCodeLabCoreInstance) ->
  "use strict"
  gradStack = []
  defaultGradientColor1 = orange
  defaultGradientColor2 = red
  defaultGradientColor3 = black
  whichDefaultBackground = undefined
  currentGradientStackValue = ""
  previousGradientStackValue = 0
  BackgroundPainter = {}
  canvasForBackground = document.createElement("canvas")  unless canvasForBackground
  BackgroundPainter.canvasForBackground = canvasForBackground
  
  # the canvas background for the time being is only going to contain
  # gradients, so we can get away with creating a really tiny canvas and
  # stretch it. The advantage is that the fill operations are a lot faster.
  # We should try to use CSS instead of canvas, as in some browsers canvas
  # is not accelerated just as well as CSS.
  # backGroundFraction specifies what fraction of the window the background canvas
  # is going to be.
  backGroundFraction = 1 / 15
  
  canvasForBackground.width = Math.floor(window.innerWidth * backGroundFraction)
  canvasForBackground.height = Math.floor(window.innerHeight * backGroundFraction)
  BackgroundPainter.backgroundSceneContext = canvasForBackground.getContext("2d")
  
  # This needs to be global so it can be run by the draw function
  BackgroundPainter.simpleGradient = (a, b, c, d) ->
    currentGradientStackValue =
      currentGradientStackValue + " " + a + "" + b + "" + c + "" + d + "null "
    gradStack.push
      gradStacka: liveCodeLabCoreInstance.ColourFunctions.color(a)
      gradStackb: liveCodeLabCoreInstance.ColourFunctions.color(b)
      gradStackc: liveCodeLabCoreInstance.ColourFunctions.color(c)
      gradStackd: liveCodeLabCoreInstance.ColourFunctions.color(d)
      solid: null


  
  # This needs to be global so it can be run by the draw function
  BackgroundPainter.background = ->
    
    # [todo] should the screen be cleared when you invoke
    # the background command? (In processing it's not)
    a = liveCodeLabCoreInstance.ColourFunctions.color(
      arguments[0], arguments[1], arguments[2], arguments[3])
    currentGradientStackValue =
      currentGradientStackValue + " null null null null " + a + " "
    gradStack.push
      gradStacka: `undefined`
      gradStackb: `undefined`
      gradStackc: `undefined`
      gradStackd: `undefined`
      solid: a


  BackgroundPainter.paintARandomBackground = ->
    if whichDefaultBackground is `undefined`
      whichDefaultBackground = Math.floor(Math.random() * 5)
    else
      whichDefaultBackground = (whichDefaultBackground + 1) % 5
    switch whichDefaultBackground
      when 0
        defaultGradientColor1 = orange
        defaultGradientColor2 = red
        defaultGradientColor3 = black
        $("#fakeStartingBlinkingCursor").css "color", "white"
      when 1
        defaultGradientColor1 = white
        defaultGradientColor2 = khaki
        defaultGradientColor3 = peachpuff
        $("#fakeStartingBlinkingCursor").css "color", "LightPink"
      when 2
        defaultGradientColor1 = lightsteelblue
        defaultGradientColor2 = lightcyan
        defaultGradientColor3 = paleturquoise
        $("#fakeStartingBlinkingCursor").css "color", "CadetBlue"
      when 3
        defaultGradientColor1 = silver
        defaultGradientColor2 = lightgrey
        defaultGradientColor3 = gainsboro
        $("#fakeStartingBlinkingCursor").css "color", "white"
      when 4
        defaultGradientColor1 = liveCodeLabCoreInstance.ColourFunctions.color(155,255,155)
        defaultGradientColor2 = liveCodeLabCoreInstance.ColourFunctions.color(155,255,155)
        defaultGradientColor3 = liveCodeLabCoreInstance.ColourFunctions.color(155,255,155)
        $("#fakeStartingBlinkingCursor").css "color", "DarkOliveGreen"
    
    # in theory we should wait for the next frame to repaing the background,
    # but there would be a problem with that: livecodelab goes to sleep when
    # the program is empty and the big cursor blinks. And yet, when the
    # user clicks the reset button, we want the background to change randomly
    # so we make an exceptio to the rule here and we update the background
    # right now without waiting for the next frame.
    # Note this is not wasted time anyways because the repaint won't happen
    # again later if the background hasn't changed.
    BackgroundPainter.resetGradientStack()
    BackgroundPainter.simpleGradientUpdateIfChanged()

  BackgroundPainter.resetGradientStack = ->
    currentGradientStackValue = ""
    
    # we could be more efficient and
    # reuse the previous stack elements
    # but I don't think it matters here
    gradStack = []
    BackgroundPainter.simpleGradient \
      defaultGradientColor1, defaultGradientColor2, defaultGradientColor3

  BackgroundPainter.simpleGradientUpdateIfChanged = ->
    diagonal = undefined
    radgrad = undefined
    scanningGradStack = undefined

    # some shorthands
    canvasForBackground = BackgroundPainter.canvasForBackground
    color = liveCodeLabCoreInstance.ColourFunctions.color

    if currentGradientStackValue isnt previousGradientStackValue      
      #alert('repainting the background');
      previousGradientStackValue = currentGradientStackValue
      diagonal =
        Math.sqrt(Math.pow(canvasForBackground.width / 2, 2) +
        Math.pow(canvasForBackground.height / 2, 2))
      scanningGradStack = 0
      while scanningGradStack < gradStack.length
        if gradStack[scanningGradStack].gradStacka isnt `undefined`
          radgrad = BackgroundPainter.backgroundSceneContext.createLinearGradient(
            canvasForBackground.width / 2,
            0,
            canvasForBackground.width / 2,
            canvasForBackground.height)
          radgrad.addColorStop 0, color.toString(gradStack[scanningGradStack].gradStacka)
          radgrad.addColorStop 0.5,color.toString(gradStack[scanningGradStack].gradStackb)
          radgrad.addColorStop 1, color.toString(gradStack[scanningGradStack].gradStackc)
          BackgroundPainter.backgroundSceneContext.globalAlpha = 1.0
          BackgroundPainter.backgroundSceneContext.fillStyle = radgrad
          BackgroundPainter.backgroundSceneContext.fillRect \
            0, 0, canvasForBackground.width, canvasForBackground.height
        else
          BackgroundPainter.backgroundSceneContext.globalAlpha = 1.0
          BackgroundPainter.backgroundSceneContext.fillStyle =
            color.toString(gradStack[scanningGradStack].solid)
          BackgroundPainter.backgroundSceneContext.fillRect \
            0, 0, canvasForBackground.width, canvasForBackground.height
        scanningGradStack++

  
  # This needs to be global so it can be run by the draw function
  window.simpleGradient = BackgroundPainter.simpleGradient
  
  # This needs to be global so it can be run by the draw function
  window.background = BackgroundPainter.background
  BackgroundPainter