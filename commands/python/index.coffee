vm = require 'vm'
os = require 'os'

module.exports =
  "pytestmethod":
    "description": "Get the python unittest method or class that the cursor is on"
    "variable": (state) -> state.getTestUnderCursor()
  "pythontest":
    "description": "Runs py.test on the python unittest method or class that the cursor is on."
    "command": (state, args)->
      testfile = state.parseTemplate "%(pytestmethod)"
      if testfile isnt "null" and testfile isnt ""
        return state.exec "python -m pytest " + testfile, null, state
      else
        return (state.consoleLabel 'error', "error") + (state.consoleText 'error', "Cannot run py.test on non Python file")
    "action": "pythontest"  # register command "atom-pytest-terminal:pythontest" that can be used for keymapping
