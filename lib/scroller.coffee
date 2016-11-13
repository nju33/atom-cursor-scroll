throttle = require 'lodash.throttle'

module.exports = class Scroller
  Object.defineProperty @prototype, 'cursor',
    get: ->
      @item.cursors[0]

  Object.defineProperty @prototype, 'cursorElement',
    get: ->
      @element.shadowRoot.querySelector('.cursors');

  Object.defineProperty @prototype, 'cursorLine',
    get: ->
      @element.shadowRoot.querySelector('.cursor-line');

  Object.defineProperty @prototype, 'atomStyles',
    get: ->
      @element.shadowRoot.querySelector('atom-styles');

  constructor: ->
    @item = null
    @element = null
    @width = 0
    @height = 0
    @xFieldSize = 0
    @yFieldSize = 0
    @style = null
    @fieldSize = atom.config.get 'cursor-scroll.fieldSize'
    @flags = top: false, bottom: false

    setTimeout =>
      commonStyle = document.createElement 'style'
      commonStyle.innerText = """
        .cursor-line,
        .cursors {
          transition: .2s cubic-bezier(0.455, 0.03, 0.515, 0.955);
        }
      """
      @atomStyles.appendChild commonStyle

      @style = document.createElement 'style'
      @atomStyles.appendChild @style
    , 100

    @handleMousemove = do =>
      scrolling = false
      proc = null

      scroll = (dir) =>
        switch dir
          when 'top' then @item.moveUp()
          when 'bottom' then @item.moveDown()

        if @flags[dir]
          proc[@procType] dir
        else
          @showElements()

      proc =
        slow: throttle scroll, 100
        normal: throttle scroll, 40
        fast: throttle scroll, 10

      throttle ({offsetX, offsetY}) =>
        if @isTopFieldInner offsetY, offsetX
          @procType = @getSpeed 'top', offsetY
          @hideElements()

          setTimeout =>
            {row, column} = @cursor.getScreenPosition()
            if not scrolling and row > 3
              @cursor.setScreenPosition [@item.firstVisibleScreenRow + 3, column]

            unless scrolling
              proc[@procType] 'top'
              scrolling = true
              @flags.top = true
          , 0
        else
          @flags.top = false
          scrolling = false

        if @isBottomFieldInner offsetY, offsetX
          @procType = @getSpeed 'bottom', offsetY
          @hideElements()

          setTimeout =>
            {row, column} = @cursor.getScreenPosition()
            lineCount = @item.buffer.getLineCount()
            if not scrolling and lineCount > @item.firstVisibleScreenRow + @item.rowsPerPage + 3
              @cursor.setScreenPosition [
                (@item.firstVisibleScreenRow - 3) + @item.rowsPerPage
                column
              ]

            unless scrolling
              proc[@procType] 'bottom'
              scrolling = true
              @flags.bottom = true
          , 0
        else
          @flags.bottom = false
          scrolling = false
      , 100

  getSpeed: (dir, y) ->
    console.log y
    console.log @yFieldSize * 0.1
    console.log @yFieldSize * 0.5
    if dir is 'top'
      if y < @yFieldSize * 0.1 then 'fast'
      else if y < @yFieldSize * 0.5 then 'normal'
      else 'slow'
    else if dir is 'bottom'
      if y > (@height - @yFieldSize * 0.1) then 'fast'
      else if y > (@height - @yFieldSize * 0.5) then 'normal'
      else 'slow'

  isTopFieldInner: (y, x) ->
    y < @yFieldSize and x > @width - @xFieldSize

  isBottomFieldInner: (y, x) ->
    y > @height - @yFieldSize and x > @width - @xFieldSize

  set: (item) ->
    @item = item
    @element = item.editorElement
    @parent = @element.parentElement
    @width = @element.clientWidth
    @height = @parent.clientHeight
    @xFieldSize = @width * (@fieldSize.x / 100)
    @yFieldSize = @height * (@fieldSize.y / 100)

  hideElements: ->
    @style.innerText = """
      .cursor-line,
      .cursors {
        transition: initial;
      }

      .cursors.cursors {
        opacity: 0;
      }
    """

  showElements: ->
    @style.innerText = ''

  addAllEventListener: ->
    @element.addEventListener 'mousemove', @handleMousemove

  removeAllEventListener: ->
    for dir in Object.keys @flags
      @flags[dir] = false
    @showElements()
    setTimeout =>
      @element.removeEventListener 'mousemove', @handleMousemove
    , 0
