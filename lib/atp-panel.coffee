###
  atom-pytest-terminal
  Copyright by isis97
  MIT licensed

  The panel, which manages all the terminal instances.
###

{$, View} = include 'atom-space-pen-views'
ATPOutputView = include 'atp-view'

module.exports =
class ATPPanel extends View
  @content: ->
    @div class: 'atp-panel inline-block', =>
      @span outlet: 'termStatusContainer', =>
        @span click: 'newTermClick', class: "atp-panel icon icon-plus"
      @span outlet: 'termStatusInfo', style: 'position:absolute;right:10%;'

  commandViews: []
  activeIndex: 0
  initialize: (serializeState) ->

    getSelectedText = () ->
      text = ''
      if window.getSelection
        text = window.getSelection().toString()
      else if document.selection and document.selection.type != "Control"
        text = document.selection.createRange().text
      return text

    atom.commands.add 'atom-workspace',
      'atom-pytest-terminal:context-copy-and-execute-output-selection': => @runInCurrentView (i) ->
        t = getSelectedText()
        atom.clipboard.write t
        i.onCommand t
      'atom-pytest-terminal:context-copy-output-selection': => @runInCurrentView (i) ->
        atom.clipboard.write getSelectedText()
      'atom-pytest-terminal:context-copy-raw-output': => @runInCurrentView (i) -> atom.clipboard.write(i.getRawOutput())
      'atom-pytest-terminal:context-copy-html-output': => @runInCurrentView (i) -> atom.clipboard.write(i.getHtmlOutput())
      'atom-pytest-terminal:new': => @newTermClick()
      'atom-pytest-terminal:toggle': => @toggle()
      'atom-pytest-terminal:next': => @activeNextCommandView()
      'atom-pytest-terminal:prev': => @activePrevCommandView()
      'atom-pytest-terminal:hide': => @runInCurrentView (i) -> i.close()
      'atom-pytest-terminal:destroy': =>  @runInCurrentView (i) ->
        i.destroy()
      'atom-pytest-terminal:compile': => @getForcedActiveCommandView().compile()
      'atom-pytest-terminal:toggle-autocompletion': => @runInCurrentView((i) -> i.toggleAutoCompletion())
      'atom-pytest-terminal:reload-config': => @runInCurrentView (i) ->
        i.clear()
        i.reloadSettings()
        i.clear()
      'atom-pytest-terminal:show-command-finder': => @runInCurrentView (i) ->
        i.getLocalCommandsMemdump()
      'atom-pytest-terminal:open-config': => @runInCurrentView (i) ->
        i.showSettings()
    @createCommandView()
    #@updateStatusBarTask()
    @attach()

  updateStatusBarTask: (instance, delay) ->
    if not delay?
      delay = 1000
    setTimeout () =>
      if instance?
        @updateStatusBar(instance)
      else
        @updateStatusBar(@commandViews[0])
      @updateStatusBarTask(instance, delay)
    ,delay

  updateStatusBar: (instance) ->
    if not instance?
      return
    @termStatusInfo.children().remove()
    @termStatusInfo.append(instance.parseTemplate (atom.config.get 'atom-pytest-terminal.statusBarText'), [], true )

  createCommandView: ->
    termStatus = $('<span class="atp-panel icon icon-terminal"></span>')
    commandOutputView = new ATPOutputView
    commandOutputView.statusIcon = termStatus
    commandOutputView.statusView = this
    @commandViews.push commandOutputView
    termStatus.click () =>
      commandOutputView.toggle()
    @termStatusContainer.append termStatus
    commandOutputView.init()
    @updateStatusBar commandOutputView
    return commandOutputView

  activeNextCommandView: ->
    @activeCommandView @activeIndex + 1

  activePrevCommandView: ->
    @activeCommandView @activeIndex - 1

  activeCommandView: (index) ->
    if index >= @commandViews.length
      index = 0
    if index < 0
      index = @commandViews.length - 1
    @updateStatusBar @commandViews[index]
    @commandViews[index] and @commandViews[index].open()

  getActiveCommandView: () ->
    return @commandViews[@activeIndex]

  runInCurrentView: (call) ->
    v = @getForcedActiveCommandView()
    if v?
      return call(v)
    return null

  getForcedActiveCommandView: () ->
    if @getActiveCommandView() != null && @getActiveCommandView() != undefined
      return @getActiveCommandView()
    ret = @activeCommandView(0)
    @toggle()
    return ret

  setActiveCommandView: (commandView) ->
    @activeIndex = @commandViews.indexOf commandView
    @updateStatusBar @commandViews[@activeIndex]

  removeCommandView: (commandView) ->
    index = @commandViews.indexOf commandView
    index >=0 and @commandViews.splice index, 1

  newTermClick: ->
    @createCommandView().toggle()

  attach: () ->
    # console.log 'panel attached!'
    atom.workspace.addBottomPanel(item: this, priority: 100)
    # statusBar.addLeftTile(item: this, priority: 100)

  destroyActiveTerm: ->
     @commandViews[@activeIndex]?.destroy()

  closeAll: ->
    for index in [@commandViews.length .. 0]
      o = @commandViews[index]
      if o?
        o.close()

  # Tear down any state and detach
  destroy: ->
    for index in [@commandViews.length .. 0]
      @removeCommandView @commandViews[index]
    @detach()

  toggle: ->
    @createCommandView() unless @commandViews[@activeIndex]?
    @updateStatusBar @commandViews[@activeIndex]
    @commandViews[@activeIndex].toggle()
