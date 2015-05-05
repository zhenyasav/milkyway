
Config = AppRoute.extend
	
	template: 'config'

Router.route '/apps/:id/config', controller: Config

Template.config.helpers
	
	cmOptions: ->
		mode: 
			name: 'javascript'
			json: true
		viewportMargin: Infinity
		lineNumbers: true

	config: -> @pending?.config ? @config


Template.config.onRendered ->

	cm = @$('.CodeMirror')?[0]?.CodeMirror

	@onClick = (e) =>
		if not $(e.target).closest('.config').length
			cm?.focus?()
			cm?.setCursor cm.lineCount(), 0

	@$ '.config'
	.closest '.container'
	.on 'click', @onClick

	data = null

	@autorun =>
		if newData = Template.currentData()
			if not data?._id? or not newData?._id? or data._id isnt newData._id or (data?.pending?.config and not newData?.pending?.config)
				data = newData
				config = data?.pending?.config ? data?.config
				if cm.getValue() isnt config
					cm.setValue config

	cm.on 'change', (doc) =>
		code = doc.getValue()
		data?.setConfig? code

	
		


Template.config.onDestroyed ->

	if @onClick
		el = @$ '.config'
		.closest '.container'
		el.off 'click', @onClick