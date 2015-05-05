class @Visual

	@timeScale: 1000

	constructor: (o) ->
		_.extend @, o

		if @response?.choices in ['yes/no', 'no/yes']
			@response.choices =
				Yes: 'yes'
				No: 'no'

	template: ->
		if @question
			'question'
		else if @text
			'text'
		else
			@id()

	id: -> @names?()?[0]

	names: -> @name.split(',').map (n) -> n.trim()

	shown: -> Meteor.user?()?.profile?.shown?[@id()]

	rendered: ->
		@before?()
		
		if u = Meteor?.userId?()
			setter = {}
			setter["profile.shown.#{@id()}"] = new Date()
			Meteor?.users?.update? u, $set: setter 

		if n = Number @dismiss
			@dismissTimer = Utils.delay n * Visual.timeScale, => @next()

	dismissed: (response) ->

	aborted: ->
		Meteor.clearTimeout @dismissTimer if @dismissTimer?

	enabled: -> true

	respond: (response) -> @next response

	next: (r) -> 
		@dismissed r
		Visuals.next r

	transition: 'fade slide'


class Visual.Profile extends Visual

	enabled: -> not Meteor.user?()?.profile?.responses?[@id()]?

	respond: (response) ->
		if user = Meteor.user()
			setter = {}
			setter["profile.responses.#{@id()}"] = @responseValue?(response) ? response
			Meteor.users.update user._id, $set: setter

		super response

class Visual.Countdown extends Visual

	_counter: new ReactiveVar null

	counter: -> @_counter.get()

	rendered: ->
		super()
		@_counter.set Math.floor Number(@dismiss)/1000
		interval = Meteor.setInterval => 
			count = @_counter.get()
			if count > 0
				count--
				@_counter.set count
			else
				Meteor.clearInterval interval
		, 1000




Session.setDefault 'visuals-queue', []

@Visuals = 
	
	map: {}

	add: (v) ->
		throw 'visual must have a name' if not v?.name
		names = v.name.split(',').map (n) -> n?.trim()

		search = _.clone names
		while v not instanceof Visual and search.length
			n = search.shift()
			ctor = Visual[Utils.capitalize n]
			if typeof ctor is 'function'
				v = new ctor v

		v = new Visual v if v not instanceof Visual

		names.map (name) =>
			if name = name?.trim()
				@map[name] ?= []
				@map[name].push v 

	stack: new ReactiveVar []

	clear: ->
		@current()?.dismissed?()
		@current()?.aborted?()
		@stack.set []

	current: ->
		s = @stack.get()
		if s?.length
			s[s.length-1]
		else
			@map['default']?[0]

	push: (next) ->
		if next
			stack = @stack.get()
			nexts = next.split(',').reverse().map (n) -> n?.trim()
			probable = /(.+)\((\d+\.?\d+)\)/

			for n in nexts

				if probParts = probable.exec n
					nextName = probParts[1]
					nextProb = Number probParts[2]
				else
					nextName = n
					nextProb = 1

				console.warn nextName + " not found" if nextName not of @map

				if nextName of @map and Math.random() <= nextProb
					eligibles = @map[nextName]?.filter? (v) -> v?.enabled?()
					if eligibles.length
						unshown = _.filter eligibles, (v) -> not v?.shown()
						if unshown?.length
							stack.push justPushed = _.sample unshown
						else
							stack.push justPushed = _.min eligibles, (v) -> v?.shown()
						justPushed?.pushed?()

			@stack.set stack

	next: (response) ->
		c = @current()
		stack = @stack.get()
		stack.pop()

		if typeof c?.continue is 'string'
			next = c.continue
		else if response of (c?.continue ? {})
			next = c.continue[response]

		if next?
			@push next
		else
			@stack.set stack
		


Template.visualContent.rendered = ->
	@data?.rendered?()

Template.convers8.helpers
	visual: -> Visuals.current()
			

# [
# 	name: 'greeting'
# 	text: ["Hi there!", "Hello!", "Greetings!", "Howdy!"]
# 	dismiss: 1600
# 	continue: 'profile'
# ,
# 	name: 'dashboard, default'
# 	transition: 'fade'
# ,
# 	name: 'breathing'
# 	dismiss: 6000
# ,
# 	name: 'age, profile'
# 	question: ["How old are you?", "What is your age?"]
# 	response:
# 		choices:
# 			"Under 18": 'minor'
# 			"18-29": 'twenties'
# 			'30-49': 'middle'
# 			'50-69': 'elder'
# 			'70+': 'senior'
# 	continue: 'profile'
# ,
# 	name: 'smoker, profile'
# 	question: 'How long have you been a smoker?'
# 	response:
# 		choices:
# 			'Less than a year': 'year'
# 			'Less than two years': 'two'
# 			'Two to five years': 'five'
# 			'More than five years': 'morethanfive'
# 	continue: 'profile'
# ,
# 	name: 'last cigarette, profile'
# 	question: 'How long ago have you had your last cigarette?'
# 	response:
# 		choices:
# 			'Just now': 0
# 			'A few hours ago': 6
# 			'Yesterday': 24
# 			'A few days ago': 24 * 3
# 	responseValue: (v) -> moment().subtract(v, 'hours').toDate()
# 	continue: 'profile'
# ,
# 	name: 'daily packs, profile'
# 	question: 'How many cigarettes do you smoke daily?'
# 	response:
# 		choices:
# 			'One or two': 0.15
# 			'Half a pack': 0.5
# 			'A pack or more': 1.2
# 	continue: 'profile'
# ,
# 	name: 'enjoy gum, remedy'
# 	question: 'Do you enjoy chewing gum?'
# 	response:
# 		choices: 'yes/no'
# 	continue:
# 		yes: 'have gum'
# 		no: 'bummer(0.5), remedy'
# ,
# 	name: 'have gum, access'
# 	question: 'Do you have some gum around?'
# 	response:
# 		choices: 'yes/no'
# 	continue:
# 		yes: 'great(0.5), gum'
# 		no: 'bummer(0.5), remedy'
# ,
# 	name: 'gum, solution'
# 	question: "Will you try a piece of gum?"
# 	response:
# 		choices: 'yes/no'
# 	continue:
# 		yes: 'great'
# 		no: 'something else(0.7), remedy'
# ,
# 	name: 'enjoy coffee, remedy'
# 	question: 'Do you drink coffee?'
# 	response:
# 		choices: 'yes/no'
# 	continue: 
# 		yes: 'great(0.6), can have coffee'
# 		no: 'something else(0.7), remedy'
# ,
# 	name: 'can have coffee, access'
# 	question: 'Can you make or buy some coffee right now?'
# 	response:
# 		choices: 'yes/no'
# 	continue: 
# 		yes: 'great(0.2), coffee'
# 		no: 'bummer(0.9), something else(0.7), remedy'
# ,
# 	name: 'coffee, solution'
# 	question: ['How about a coffee then?', "Why not have a quick coffee instead?"]
# 	response:
# 		choices:
# 			"I'll have one!": 'yes'
# 			"Not right now": 'no'
# 	continue:
# 		yes: 'great'
# 		no: 'something else(0.6), remedy'
# ,
# 	name: 'something else'
# 	text: ["Ok, let's try something else...", "Hmm...", "I've got another idea!"]
# 	dismiss: 1000
# ,
# 	name: 'great'
# 	text: ['Sweet!', 'Great!', 'Fantastic!', 'Okay!', 'Cool!', 'Excellent!']
# 	dismiss: 1000
# ,
# 	name: 'bummer'
# 	text: ['Bummer.', 'Oh well...']
# 	dismiss: 1000
# ,
# 	name: 'want to breathe, remedy'
# 	question: ['How about a quick breather?', "Would you like to try a breathing excercise?"]
# 	response:
# 		choices: 'yes/no'
# 	continue:
# 		yes: 'great(0.6), breathe'
# 		no: 'something else(0.5), remedy'
# ,
# 	name: 'breathe'
# 	text: "Synchronize your breathing with the blue circle"
# 	dismiss: 7000
# 	continue: 'breathe deep'
# 	aborted: ->
# 		Session.set 'breathing', false
# 		@constructor::aborted?.call @
# 	rendered: ->
# 		@constructor::rendered?.call @
# 		Session.set 'breathing', true
# ,
# 	name: 'breathe deep'
# 	text: "Breathe deeply"
# 	dismiss: 3000
# 	continue: 'countdown'
# 	aborted: ->
# 		Session.set 'breathing', false
# 		@constructor::aborted?.call @
# ,
# 	name: 'countdown'
# 	dismiss: 20000
# 	continue: 'give in'
# 	aborted: ->
# 		Session.set 'breathing', false
# 		@constructor::aborted?.call @
# ,
# 	name: 'compliment'
# 	dismiss: 1600
# 	text: ["You're awesome!", "Right on!", "You're a hero!", "Your kids will thank you.", "You're very attractive."]
# ,
# 	name: 'go smoke'
# 	dismiss: 1600
# 	text: ["One more won't hurt, right?", "Nothing like a stogie!"]
# ,
# 	name: 'give in'
# 	question: ["How about it?", "Still craving?", "How about now?"]
# 	response:
# 		choices:
# 			'Give in': 'yes'
# 			'Hold out': 'no'
# 			'Keep breathing': 'breathe'
# 	continue:
# 		'no': 'compliment'
# 		'yes': 'go smoke'
# 		'breathe': 'countdown'
# 	aborted: ->
# 		Session.set 'breathing', false
# 		@constructor::aborted.call @

# 	dismissed: (r) ->
# 		if r isnt 'breathe'
# 			Session.set 'breathing', false
		
# 		if r is 'yes'
# 			Meteor.users.update Meteor.userId(),
# 				$set:
# 					'profile.responses.last cigarette': new Date()
# ,
# 	name: 'lifespan, factoid'
# 	text: 'Every cigarette you smoke reduces your lifespan by roughly 11 minutes'
# 	dismiss: 4000
# ,
# 	name: 'not alone, factoid'
# 	text: "You're not alone! 69% of smokers want to quit completely."
# 	dismiss: 4000
# ,
# 	name: 'lungs, factoid'
# 	text: 'It takes just one month after your last cigarette for your lung capacity to improve'
# 	dismiss: 4000
# ,
# 	name: 'cravings, factoid'
# 	text: "Cravings should subside within about 10 minutes, all you need is a good distraction!"
# 	dismiss: 4500

# ].map (v) -> Visuals.add v

# Visuals.push 'greeting'


