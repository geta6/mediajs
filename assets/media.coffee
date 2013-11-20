'use strict'

# ===================================
# API
# ===================================

$api =
  logout: ->
    return $.ajax 'https://api.geta6.net/session/delete',
      type: 'POST'
      beforeSend: ->

  account: ->
    return $.ajax 'https://api.geta6.net/account/me.json',
      type: 'GET'
      dataType: 'jsonp'
      beforeSend: ->

  search: (data = {}) ->
    return $.ajax 'https://api.geta6.net/content/search.json',
      type: 'GET'
      data: data
      dataType: 'jsonp'
      beforeSend: ->

  browse: (data = {}) ->
    unless data.path
      throw Error 'no path'
    return $.ajax 'https://api.geta6.net/content/browse.json',
      type: 'GET'
      data: data
      dataType: 'jsonp'
      beforeSend: ->

# ===================================
# UI
# ===================================

ui =
  animationTime: 240

  dialog: (message, done) ->
    media.accountView.changetab 'logout'
    $el = $ '#ui-dialog'
    $el.find('p').text message
    $el.css 'visibility', 'visible'
    $box = $el.find('.ui-dialog-keydriver').focus()
    $box.on 'blur keyup', (event) ->
      $box.focus()
      if event?.keyCode?
        if event.keyCode is 27
          $el.find('.btn-default').trigger 'click'
        if event.keyCode is 13
          $el.find('.btn-primary').trigger 'click'
    $el.find('.btn-primary').one 'click', ->
      $box.off 'blur keyup'
      done()
    $el.find('.btn-default').one 'click', ->
      $box.off 'blur keyup'
      $el.css 'visibility', 'hidden'
      media.accountView.changetab media.accountView.pretab

  spinner: (active = no) ->
    if active
      ($ '.ui-spinner').addClass 'ui-spinner-active'
    else
      ($ '.ui-spinner').removeClass 'ui-spinner-active'

  progress: (active = no) ->
    $progress = $ '.ui-progress'
    if active
      $progress.addClass('ui-progress-active').stop().animate
        top: 0
      , ui.animationTime
    else
      $progress.stop().animate
        top: -1 * $progress.height()
      , ui.animationTime, ->
        $progress.removeClass 'ui-progress-active'

  slideFade: ($el, makeVisible = no, callback = ->) ->
    if makeVisible
      $el
        .stop()
        .animate(opacity: 1, {duration: ui.animationTime, queue: no})
        .slideDown ui.animationTime, callback
    else
      $el
        .stop()
        .animate(opacity: 0, {duration: ui.animationTime, queue: no})
        .slideUp ui.animationTime, callback

  _datetimeUpdate: null

  datetimeUpdate: ->
    clearInterval ui._datetimeUpdate
    ui._datetimeUpdate = setInterval ->
      ($ 'time').each (i, el) ->
        $el = $ el
        $el.html moment($el.attr 'datetime').fromNow()
    , 1000 * 10

  datetime: (date) ->
    date = moment date
    ui.datetimeUpdate()
    return ($ '<time>')
      .addClass('ui-datetime')
      .attr('datetime', date.toISOString())
      .attr('title', date.format('YYYY-MM-DD HH:mm:ss'))
      .text(date.fromNow())

  filesize: (size, unit = 0) ->
    units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
    size = size / 1024 while size > 1024 when ++unit
    return "#{(Math.max size, 0.1).toFixed(1)} #{units[unit]}"

  typename: (name) ->
    return switch name
      when 'd' then 'Directory'
      when '.mp4' then 'Video'
      when '.mp3' then 'Music'
      when '.pdf' then 'Book'
      else 'Unknown'

  sortdef: (rev = no, def) ->
    unless rev
      return switch def
        when '+time' then '.js-item-order-time-asc'
        when '-time' then '.js-item-order-time-dsc'
        when '+name' then '.js-item-order-name-asc'
        when '-name' then '.js-item-order-name-dsc'
    else
      return switch def
        when '.js-item-order-time-asc' then '+time'
        when '.js-item-order-time-dsc' then '-time'
        when '.js-item-order-name-asc' then '+name'
        when '.js-item-order-name-dsc' then '-name'

# ===================================
# Backbone::Content
# ===================================

class Player extends Backbone.Model

class PlayerView extends Backbone.View

  tagName: 'div'

  template: _.template ($ '#tmpl-player').html()

  events:
    'click .image': 'clickImage'
    'mousemove .image': 'hoverImage'

  initialize: ->
    @$el.addClass 'item item-player'

  render: ->
    @$el.html @template @model.toJSON()
    switch @model.get 'type'
      when '.mp4'
        $el = @$ 'video'
        $el.mediaelementplayer(enableAutosize: yes)
      when '.mp3'
        $el = @$ 'audio'
        $el.mediaelementplayer(enableAutosize: yes)
    return @

  hoverImage: (event) ->
    $el = $ event.currentTarget
    width = $el.width()
    offset = event.offsetX
    if offset < width / 2
      $el.css 'cursor', 'w-resize'
    else
      $el.css 'cursor', 'e-resize'

  clickImage: (event) ->
    width = ($ event.currentTarget).width()
    offset = event.offsetX
    if offset < width / 2 then @bookPrev() else @bookNext()

  bookPrev: ->
    $img = @$ '.image'
    src = $img.attr 'data-src'
    page = parseInt $img.attr 'data-page'
    return if page < 2
    $img.attr 'src', "#{src}&page=#{page - 1}"
    $img.attr 'data-page', "#{page - 1}"

  bookNext: ->
    $img = @$ '.image'
    src = $img.attr 'data-src'
    page = parseInt $img.attr 'data-page'
    $img.attr 'src', "#{src}&page=#{page + 1}"
    $img.attr 'data-page', "#{page + 1}"


# ===================================
# Backbone::Content
# ===================================

class Content extends Backbone.Model

class ContentView extends Backbone.View

  tagName: 'div'

  template: _.template ($ '#tmpl-content').html()

  events:
    'click .item-icon': 'navigateBrowseFile'
    'click .item-body-header-title': 'navigateBrowseFile'
    'click .item-body-header-series': 'navigateBrowseDir'

  bindigns: {}

  initialize: ->
    @$el.addClass 'item'

  render: ->
    @$el.html @template @model.toJSON()
    return @

  navigateBrowseDir: ->
    (path = (@model.get 'path').split '/').pop()
    path[i] = encodeURIComponent p for p, i in path
    $app.navigate "/browse/#{path.join '/'}", yes

  navigateBrowseFile: ->
    path = (@model.get 'path').split '/'
    path[i] = encodeURIComponent p for p, i in path
    $app.navigate "/browse/#{path.join '/'}", yes


class Contents extends Backbone.Collection

  model: Content

  prequery: ''

  inspect: {}

  inspectData: (@inspect) ->
    query = JSON.stringify media.query
    if @prequery isnt query
      @trigger 'inspect'
      @prequery = query


class ContentsView extends Backbone.View

  $sidebar =
    el: null
    dl: null
    offset: 0
    sticky: no

  el: $ '#content'

  template: _.template ($ '#tmpl-contents').html()
  template_player: _.template ($ '#tmpl-player').html()

  events:
    'click .js-item-stat-series': 'navigateTargetSeries'
    'click .js-item-stat-artist': 'navigateTargetArtist'
    'click .js-item-order': 'changeOrder'

  initialize: (@collection) ->
    @$el.html @template() # @collection.toJSON()
    @listenTo @collection, 'add', @append
    @listenTo @collection, 'reset', @clear
    @listenTo @collection, 'inspect', @update
    @listenTo media.account, 'change', @accountUpdate
    @accountUpdate()

    $sidebar.el = @$ '.item-side-container'
    $sidebar.dl = @$ '.item-side-container-dummy'
    $sidebar.offset = $sidebar.el.offset().top
    $sidebar.sticky = no
    @sidebarSticky $win.height(), $doc.height()

    @render()

  render: ->
    for el, i in @$ '.js-item-order' when el = $ el
      if media.query.sort is el.attr 'data-order'
        el.addClass 'item-side-entry-active'
        (@$ '.ui-selectbox-candidate').css top: -1 * i * el.height()
      else
        el.removeClass 'item-side-entry-active'
    (@$ '.js-item-order-place').html (@$ '.item-side-entry-active').html()

  update: ->
    data = @collection.inspect
    @renderPlayer data.target if data.target? and data.target.type isnt 'd'
    @renderSidebar()

  renderPlayer: (data) ->
    view = new PlayerView(model: new Player data).render()
    (@$ '.item-main').append view.el

  renderSidebar: ->
    data = @collection.inspect
    $el = @$ '.item-side'
    ($el.find '.js-item-stat').empty()
    hides = ['at', 'size', 'count', 'type', 'artist', 'series', 'track', 'disk']
    shows = []
    embed = (key, val) ->
      unless val is null
        shows.push key
        ($el.find ".js-item-stat-#{key} .js-item-stat").append val
    ui.slideFade ($el.find '.item-stat'), no, =>
      if data.target?.id?
        embed 'at', ui.datetime data.target.created
        embed 'type', ui.typename data.target.type
        if data.target.type is 'd'
          embed 'count', data.match
        else
          embed 'size', ui.filesize data.target.size
          embed k, v for k, v of data.target.details
      else
        embed 'count', data.match
      for show, i in shows
        if -1 < hides.indexOf show
          hides.splice (hides.indexOf show), 1
        ($el.find ".js-item-stat-#{show}").show()
      for hide in hides
        ($el.find ".js-item-stat-#{hide}").hide()
      ui.slideFade ($el.find '.item-stat'), on

  clear: ->
    (@$ '.item-main').empty()

  append: (content) ->
    view = new ContentView(model: content).render()
    (@$ '.item-main').append view.el

  navigateTargetSeries: ->
    $app.navigate "/browse/#{@collection.inspect.target.parent}", yes

  navigateTargetArtist: ->
    $app.navigate "/browse/Music/#{@collection.inspect.target.details.artist}", yes

  changeOrder: (event) ->
    sort = ($ event.currentTarget).attr 'data-order'
    if sort isnt media.query.sort
      media.query.sort = sort
      @render()
      $app.refresh()

  sidebarSticky: (winheight, docheight) ->
    height = $sidebar.el.outerHeight()
    if window.scrollY <= $sidebar.offset or height + $sidebar.offset >= winheight
      $sidebar.dl.css 'height', 0
      if $sidebar.sticky
        $sidebar.sticky = no
        $sidebar.el.css position: 'static'
    else
      $sidebar.dl.css 'height', height
      unless $sidebar.sticky
        $sidebar.sticky = yes
        $sidebar.el.css { position: 'fixed', top: 0 }
    # @$sidebarSticky
    # console.log winheight, docheight

  accountUpdate: ->
    @$el.find('.js-item-user-icon').css 'background-image', "url(#{media.account.get 'icon'})"
    @$el.find('.js-item-user-name').text media.account.get 'name'

# ===================================
# Backbone::Account
# ===================================

class Account extends Backbone.Model

  defaults:
    id: null
    name: null
    icon: null
    updated: null
    created: null
    callback: no

class AccountView extends Backbone.View

  el: $ '#account'

  template: _.template ($ '#tmpl-account').html()

  events:
    'click .js-navi-home': 'backToIndex'
    'click .js-navi-mail': 'backToIndex'
    'click .js-navi-help': 'backToIndex'
    'click .js-navi-conf': 'backToIndex'
    'click .js-navi-logout': 'dialogLogout'
    'submit .js-navi-search': 'submitSearch'

  pretab: null
  curtab: null

  initialize: ->
    @$el.html @template @model.toJSON()
    @listenTo @model, 'change', @render
    @model.trigger 'change'

  render: ->

  changetab: (name) ->
    @pretab = @curtab
    @curtab = name
    (@$ '.js-navi').removeClass 'navi-active'
    (@$ ".js-navi-#{name}").parent('td').addClass 'navi-active'

  backToIndex: ->
    $app.navigate '/', yes

  dialogLogout: ->
    ui.dialog 'Are you sure you want to log out?', =>
      $app.navigate '/logout', yes

  submitSearch: (event) ->
    event.preventDefault()
    query = ($ event.currentTarget).find('input').val()
    $app.navigate "/search/#{encodeURIComponent query}", yes


# ===================================
# Backbone::Application
# ===================================

class Application extends Backbone.Router

  fetching: no

  routes:
    'search(/*path)': 'search'
    'browse(/*path)': 'browse'
    'login': 'login'
    'logout': 'logout'
    '': 'index'

  initialize: ->
    $.when($api.account())
      .then (user) =>
        media.auth = yes
        Backbone.history.start pushState: on
        @navigate location.pathname, yes
        media.account.set user
        $ =>
          media.accountView = new AccountView model: media.account
          media.contentsView = new ContentsView media.contents
      .fail (err) =>
        media.auth = no
        Backbone.history.start pushState: on
        @navigate '/login', yes
        callback = "#{location.protocol}//#{location.hostname}"
        callback = "#{callback}:#{location.port}" if location.port isnt 80
        media.account.set 'callback', callback
        $ =>
          media.accountView = new AccountView model: media.account
          media.contentsView = new ContentsView media.contents

  refresh: ->
    Backbone.history.stop()
    Backbone.history.start pushState: on

  fetch: (query, done = ->) ->
    unless @fetching
      @fetching = yes
      ui.progress on
      $.when($api[@current] query)
        .then (browse) =>
          media.contents.inspectData browse
          for result in browse.results
            media.contents.add new Content result
          ui.progress off
          @fetching = no
          done() if typeof done is 'function'
        .fail (err) =>
          console.error err
          ui.progress off
          @fetching = no
          done() if typeof done is 'function'

  loadNext: ->
    if media.contents.inspect?.query_next? and !@fetching and $api[@current]?
      @fetch media.contents.inspect.query_next

  login: ->
    return @navigate('/', yes) if media.auth

  logout: ->
    return @navigate '/login', yes unless media.auth
    callback = "#{location.protocol}//#{location.hostname}"
    callback = "#{callback}:#{location.port}" if location.port isnt 80
    callback = ($ '<input>').attr('name', 'callback').val(callback)
    form = ($ '<form>')
      .attr('method', 'post')
      .attr('action', 'https://api.geta6.net/session/delete')
      .append(callback)
    form.submit()

  browse: (path) ->
    @current = 'browse'
    media.query.q = ''
    media.query.path = path
    media.contents.reset()
    @fetch media.query, ->
      media.accountView.changetab 'home'

  search: (path) ->
    @current = 'search'
    media.query.q = path
    media.query.path = ''
    media.contents.reset()
    @fetch media.query, ->
      ($ '.js-navi-search input').val path
      media.accountView.changetab 'home'

  index: ->
    @search ''

# from localstorage
storage =
  get: (key) ->
    if window.localStorage?
      return window.localStorage.getItem key
    return no
  set: (key, val) ->
    if window.localStorage?
      return window.localStorage.setItem key, val
    return no

media =
  account: new Account
  content: new Content
  contents: new Contents
  accountView: null
  contentsView: null
  query:
    type: 'f'
    limit: storage.get('limit') || 25
    skip: 0
    sort: storage.get('sort') || '-time'
    filter: storage.get('filter') || 'safe'

$win = $ window
$doc = $ document
$app = new Application()

$win.on 'resize scroll', (event) ->
  winheight = $win.height()
  docheight = $doc.height()
  if docheight < window.scrollY + winheight + 200
    $app.loadNext()
  if media.contentsView
    media.contentsView.sidebarSticky winheight, docheight
