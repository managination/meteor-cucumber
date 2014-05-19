
debug = -> console.log 'Cucumber -', arguments... if Cucumber.settings.debug


class Cucumber

  @run: -> @runner.run arguments...

  @_init: ->
    debug 'Settings', @settings
    @_initMirror()
    return unless @settings.enabled
    @_initRunner()
    @_initReporters()
    @_initWatchers()
    @_initStartup()

  @_initMirror: ->
    return unless @settings.mirror and !@settings.velocity
    debug 'Building mirror'
    @mirror = new Package.mirror.Mirror 'cucumber',
      cucumber:
        enabled: @settings.remote
        startup: false
        watch: false
        velocity: false
        tags: @settings.tags
        coffee: @settings.coffee
      selenium: _.extend {}, Meteor.settings.selenium,
        enabled: @settings.remote
        server:
          download: false
          start: false
        chrome:
          download: false

  @_initRunner: ->
    debug 'Building runner'
    @runner = if @settings.mirror and @settings.remote and !@settings.velocity
      if @mirror.isMirror
        debug 'Building mirror runner'
        new @Runner.Mirror @mirror
      else
        debug 'Building remote runner'
        new @Runner.Remote @mirror
    else
      debug 'Building local runner'
      new @Runner.Local @mirror

  @_initReporters: ->
    @reporters = {}
    @reporters.velocity = new @Reporter.Velocity if @settings.velocity

  @_initWatchers: ->
    return if @settings.velocity
    @watchers = rerun: new @Watcher.Rerun @settings.path
    if @settings.velocity
      @watchers.velocity = new @Watcher.Velocity @settings.path
    watcher.watch() for name, watcher of @watchers if @settings.watch

  @_initStartup: ->
    startup = Meteor.bindEnvironment (callback) =>
      debug 'Cucumber running startup'
      @runner.run callback
    if @settings.velocity
      return Package.velocity.Velocity.registerFramework 'cucumber',
        mirror: @settings.mirror, watch: 'features/**/*.{feature,js,coffee}',
        startup
    return unless @settings.startup
    if Package.webapp
      return startup() if Package.webapp.WebApp.httpServer?._handle?
      return Package.webapp.WebApp.onListening startup
    return startup() if Package.cucumber?
    Meteor.startup startup
