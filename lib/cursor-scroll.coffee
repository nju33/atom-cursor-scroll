{CompositeDisposable} = require 'atom'
Scroller = require './scroller'

module.exports =
  config:
    fieldSize:
      type: 'object'
      properties:
        x:
          title: 'X field size (%)'
          type: 'integer'
          default: 7.5
          minimum: 5
          maximum: 100
        y:
          title: 'Y field size (%)'
          type: 'integer'
          default: 25
          minimum: 5
          maximum: 50

  activate: (state) ->
    @subscription = new CompositeDisposable()

    @scroller = null

    @subscription.add atom.workspace.onWillDestroyPaneItem =>
      @removeEventListener()
      @scroller = null

    setTimeout =>
      @subscription.add atom.workspace.observeActivePaneItem (item) =>
        if item.uri? and item.uri is 'atom://config'
          return

        unless item?
          return

        @removeEventListener() if @scroller
        @scroller = new Scroller()
        @addEventListener item
    , 0

  deactivate: ->
    @subscription.dispose()
    @scroller.removeAllEventListener()

  addEventListener: (item) ->
    @scroller.set item
    @scroller.addAllEventListener()

  removeEventListener: ->
    @scroller?.removeAllEventListener()
