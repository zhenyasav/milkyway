@AppRoute = BaseRoute.extend

	template: 'app'

	data: -> Apps.findOne name: @params.id

	title: -> @params.id

	menu: ->
		availability: "/apps/#{@params.id}"
		configuration: "/apps/#{@params.id}/config"
		logs: "/apps/#{@params.id}/logs"
		billing: "/apps/#{@params.id}/billing"
		settings: "/apps/#{@params.id}/settings"

Router.route '/apps/:id', controller: AppRoute