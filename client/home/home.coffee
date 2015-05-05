

Home = BaseRoute.extend

	template: 'home'

Router.route '/', controller: Home

greetDay = ->
	h = moment().hour()
	return "Good morning!" if 0 <= h < 12
	return "Good afternoon!" if 12 <= h < 17
	return "Good evening!" if 17 <= h <= 24

acquiaintedKey = 'milkyway.acquainted' 

Template.home.events
	'click .introduction': -> Visuals.push 'whatnext'

[
	
	name: 'greeting'
	text: ['Hi!', 'Hello!', 'Greetings!', greetDay()]
	dismiss: 1.5
	continue: if localStorage?[acquiaintedKey] then 'whatnext' else 'intro'
	pushed: ->
		$('html').addClass 'presentation'
,
	name: 'intro'
	continue: 'ilovemeteor'
	dismiss: 2.3
,
	name: 'ilovemeteor'
	dismiss: 2.3
	continue: 'evolution'
,
	name: 'evolution'
	dismiss: 3
	text: "Meteor is an inescapable evolution of internet architecture..."
	continue: 'bestthing'
,
	name: 'bestthing'
	dismiss: 3
	text: "... and it's the best thing to have ever happened to developers."
	continue: 'happycat'
,
	name: 'happycat'
	dismiss: 4
	continue: 'thankyou'
,
	name: 'thankyou'
	dismiss: 4
	text: ['Thank you for building the best development framework in the world!']
	continue: 'principles'
,
	name: 'principles'
	dismiss: 4
	continue: 'ihelp'
,
	name: 'ihelp'
	text: 'Most of all, I want to help Meteor <em>grow</em> and <em>succeed</em>.'
	dismiss: 5.2
	continue: 'galaxy'
,
	name: "galaxy"
	text: "Galaxy is a priority for you right now."
	dismiss: 3
	continue: 'galaxy2'
,
	name: "galaxy2"
	text: "So I've decided to build something just for you!"
	dismiss: 2
	continue: 'galaxy3'
,
	name: "galaxy3"
	text: "... to help imagine what it might be like to use Galaxy"
	dismiss: 3
	continue: 'galaxy4'
,
	name: 'galaxy4'
	text: "... and to demonstrate my ability."
	dismiss: 2
	continue: 'galaxy5'
,
	name: 'galaxy5'
	text: "This app was designed and built in less than four days."
	dismiss: 3
	continue: 'whatnext'
,
	name: 'whatnext'
	question: ["Where can I take you now?", "Where shall we go next?", "Your wish. My command."]
	response:
		choices:
			"Galaxy Concept": 'demo'
			"Design Notes": 'notes'
			"About Zhenya": 'about'
			"That wasn't a real Meteor developer": "meteordev"
			"Let's get reacquainted?": 'repeat'
	continue:
		meteordev: 'meteordev'
		demo: 'feedback'
		about: 'about'
		notes: 'notes'
		repeat: 'intro'
	pushed: ->
		$('html').addClass 'presentation'
	before: ->
		if not localStorage[acquiaintedKey]
			localStorage[acquiaintedKey] = new Date()
,
	name: 'notes'
	text: "The goals were:"
	dismiss: 1.6
	continue: 'notes1'
,
	name: 'notes1'
	text: "<em>1.</em> To visualize app deployment across continents"
	dismiss: 3
	continue: 'notes1.1'
,
	name: 'notes1.1'
	text: "<em>1.1</em> Visualize where developers should purchase availability to help highest latency traffic"
	dismiss: 3
	continue: 'notes2'
,
	name: 'notes2'
	text: "<em>2.</em> To demonstrate design and dev ability"
	dismiss: 3
	continue: 'notes3'
,
	name: 'notes3'
	text: "<em>3.</em> To deliver as much eye-candy, as quickly as possible"
	dismiss: 3
	continue: 'notes4'
,
	name: 'notes4'
	text: "Inspiration drawn from:<br>Meteor.com<br>AWS<br>dashboard.heroku.com<br>d3.js samples"
	dismiss: 3
	continue: 'whatnext'
,
	name: 'pronounce'
	text: 'Just find a Russian-speaker, they can help :)'
	dismiss: 3
	continue: 'about'
,
	name: 'about'
	question: ["What would you like to see?", "Feel free to look around!", "What would you like to know?"]
	response:
		choices:
			"Zhenya's CV": 'cv'
			"A nice sample of codewriting style": 'slider'
			"Source to this app (more messy)": 'milkyway'
			"zhenya.co": 'web'
			"Learn to pronounce 'Zhenya'": 'pronounce'
			"Back": 'back'
	continue: 
		cv: "about"
		slider: 'about'
		web: 'about'
		milkyway: 'about'
		pronounce: 'pronounce'
		back: 'whatnext'


	dismissed: (resp) ->
		urls =
			cv: "http://zhenya.co/cv"
			slider: "http://github.com/zhenyasav/slider"
			web: "http://zhenya.co"
			milkyway: "http://github.com/zhenyasav/milkyway"

		window.open urls[resp] if resp of urls
,
	name: 'meteordev'
	dismiss: 5
	continue: 'whatnext'
,
	name: 'feedback'
	text: "Bugs? Questions? Feedback?<br>Please drop me a line!<br><a href='mailto:eugeneas@gmail.com'>eugeneas@gmail.com</a><br>I'll be happy to hear from you!"
	dismiss: 3
	continue: 'galaxylogo'
,
	name: 'galaxylogo'
	dismiss: 1.6
	dismissed: (resp) ->
		Meteor.setTimeout ->
			$('html').removeClass 'presentation'
		, 350
	

].map (v) -> Visuals.add v

Meteor.startup ->
	if (new Iron.Url(window.location.href))?.pathname is '/'
		Visuals.push 'greeting'