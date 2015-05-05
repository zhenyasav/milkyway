Template.question.helpers
	question: ->
		if _.isArray @question
			_.sample @question
		else if typeof @question is 'string'
			@question

	responseTemplate: ->
		if @response.number?
			'numeric_response'
		else if @response.choices?
			'choice_response'

Template.numeric_response.rendered = ->
	@$ 'input'
	.focus()

Template.numeric_response.events

	'keyup input': (e) ->
		if e.keyCode is Utils.keys.enter
			$(e.target).blur()

	'change input': (e) ->
		val = $(e.target).val()
		if val?
			@respond? val

Template.choice_response.events Utils.mobilizeEvents

	'click a': (e) ->
		visual = Template.currentData()
		visual?.respond? @value if @value? and visual