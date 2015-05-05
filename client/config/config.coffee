Config = AppRoute.extend
	
	template: 'config'

Router.route '/apps/:id/config', controller: Config

Template.config.helpers
	
	cmOptions: ->
		mode: 'javascript'