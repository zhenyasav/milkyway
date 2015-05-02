Meteor.startup ->
	touch = 'ontouchstart' of window
	$ 'html'
	.toggleClass 'no-touch', not touch
	.toggleClass 'touch', touch