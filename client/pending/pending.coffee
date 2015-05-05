
Template.changesPending.helpers
	
	isPending: ->
		app = Template.parentData 1
		prop = String Template.currentData()
		app?.pending?[prop]?

Template.changesPending.events

	'click .save': ->
		app = Template.parentData 1
		app?.savePending? String Template.currentData()

	'click .cancel': -> 
		app = Template.parentData 1
		app?.discardPending? String Template.currentData()
