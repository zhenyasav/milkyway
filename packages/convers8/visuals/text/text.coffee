
Template.text.helpers

	text: ->
		if _.isArray @text
			_.sample @text
		else if typeof @text is 'string'
			@text