fs = require 'fs'
{resolve, dirname, extname} = require 'path'

class Util

  escapeRegExp: (string) ->
    if string == null
      return null
    return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");

  replaceAll: (find, replace, str) ->
    if not str?
      return null
    if not replace?
      return str
    return str.replace(new RegExp(@escapeRegExp(find), 'g'), replace);

  # If the file begins with ./ it will be redirected to the given cwd directory.
  # This method accepts also path arrays.
  # e.g.
  #
  # dir(["./a.txt", "b.txt"], "path")
  # returns:
  # ["path/a.txt", "b.txt"]
  #
  dir: (paths, cwd) ->
    if paths instanceof Array
      ret = []
      for path in paths
        ret.push @dir path, cwd
      return ret
    else
      if (paths.indexOf('./') == 0) or (paths.indexOf('.\\') == 0)
        return @replaceAll '\\', '/', resolve(cwd + '/' + paths)
      else if (paths.indexOf('../') == 0) or (paths.indexOf('..\\') == 0)
        return @replaceAll '\\', '/', resolve(cwd + '/../' + paths)
      else
        return paths

  # Obtains the file name from the given full filepath.
  getFileName: (fullpath)->
    if fullpath?
      matcher = /(.*:)((.*)(\\|\/))*/ig
      return fullpath.replace matcher, ""
    return null

  # Obtains the file directory from the given full filepath.
  getFilePath: (fullpath)->
    if not fillpath?
      return null
    return  @replaceAll(@getFileName(fullpath), "", fullpath)


  # Copies the file content from one to another
  # e.g copyFile("full_path/a.txt", "full_path/b.txt") will create new file b.txt with content copied from a.txt
  # This method accepts only full filepaths.
  copyFile: (sources, targets) ->
    if targets instanceof Array
      if targets[0]?
        return @copyFile sources, targets[0]
      return 0
    else
      if sources instanceof Array
        for source in sources
          fs.createReadStream (resolve source)
            .pipe fs.createWriteStream (resolve targets)
        return sources.length
      else
        return @copyFile [sources], targets

  # Works like bash command: cp
  # This method accepts only full filepaths.
  cp: (sources, targets) ->
    if targets instanceof Array
      ret = 0
      for target in targets
        ret += @cp sources, target
      return ret
    else
      if sources instanceof Array
        for source in sources
          isDir = false
          try
            stat = fs.statSync(targets)
            isDir = stat.isDirectory()
          catch e
            isDir = false
          if not isDir
            @copyFile source, targets
          else
            @copyFile source, targets + '/' + (@getFileName source)
        return sources.length
      else
        return @cp [sources], targets

  # Creates the given directory/-ies.
  mkdir: (paths) ->
    if paths instanceof Array
      ret = ''
      for path in paths
        fs.mkdir path
        ret += 'Directory created \"'+path+'\"\n'
      return ret
    else
      return @mkdir [paths]

  # Removes the given directory/-ies.
  rmdir: (paths) ->
    if paths instanceof Array
      ret = ''
      for path in paths
        fs.rmdir path
        ret += 'Directory removed \"'+path+'\"\n'
      return ret
    else
      return @mkdir [paths]

  # Removes the given directory/-ies.
  rename: (oldpath, newpath) ->
    fs.rename oldpath, newpath
    return 'File/directory renamed: '+oldpath+'\n'

module.exports =
  new Util()