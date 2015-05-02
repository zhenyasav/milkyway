AppDetail = BaseRoute.extend
	
	template: 'appdetail'

	data: -> Apps.findOne name: @params.id

Router.route '/apps/:id', controller: AppDetail
