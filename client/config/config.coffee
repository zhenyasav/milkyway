Config = AppRoute.extend
	
	template: 'config'

Router.route '/apps/:id/config', controller: Config