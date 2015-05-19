

Home = BaseRoute.extend

	template: 'home'

Router.route '/', controller: Home

greetDay = ->
	h = moment().hour()
	return "Good morning!" if 0 <= h < 12
	return "Good afternoon!" if 12 <= h < 17
	return "Good evening!" if 17 <= h <= 24

acquiaintedKey = 'milkyway.acquainted' 

skipIntro = ->
	Visuals.clear()
	Visuals.push 'whatnext'
	$('.home').removeClass 'show-hint'

cancelIntro = (e) ->
	if e.keyCode is Utils.keys.esc
		skipIntro()

Template.home.events
	'click .introduction': -> Visuals.push 'whatnext'

	'click .skip': -> skipIntro()
		
[
	
	name: 'greeting'
	text: ['Hi!', 'Hello!', 'Greetings!', greetDay()]
	dismiss: 1.5
	continue: if not /Chrome|Safari/.test navigator.userAgent then 'chrome-test' else if localStorage?[acquiaintedKey] then 'whatnext' else 'intro'
	pushed: ->
		$('html').addClass 'presentation'
,
	name: 'chrome-test'
	icon: 'ion-social-chrome-outline'
	question: "This site was only tested in Chrome and Safari.<br>Please consider using one of those browsers"
	response:
		choices:
			"Proceed": 'continue'
			"Get Chrome": 'chrome'
	continue:
		continue: if localStorage?[acquiaintedKey] then 'whatnext' else 'intro'
		chrome: 'chrome-test'
	dismissed: (resp) ->
		if resp is 'chrome'
			window.location = "http://www.google.com/chrome"
,
	name: 'intro'
	continue: 'ilovemeteor'
	dismiss: 2.3
	pushed: ->
		$(window).on 'keyup', cancelIntro
		$('.home').addClass 'show-hint'
,
	name: 'ilovemeteor'
	dismiss: 2.3
	continue: 'evolution'
	dismissed: ->
		$('.home').removeClass 'show-hint'
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
	icon: 'icon-tree large'
	text: 'Most of all, I want to help Meteor <em>grow</em> and <em>succeed</em>.'
	dismiss: 5.2
	continue: 'galaxy'
,
	name: "galaxy"
	text: "Galaxy is a priority right now."
	dismiss: 3
	continue: 'galaxy2'
,
	name: "galaxy2"
	text: "So I've decided to build something just for you"
	dismiss: 2.2
	continue: 'galaxy3'
,
	name: "galaxy3"
	text: "... to help imagine what it might be like to use Galaxy"
	dismiss: 3.2
	continue: 'galaxy4'
,
	name: 'galaxy4'
	text: "... and to demonstrate my ability."
	dismiss: 3
	continue: 'galaxy5'
,
	name: 'galaxy5'
	text: "This app was designed and built in about four days."
	dismiss: 3.2
	continue: 'whatnext'
,
	name: 'whatnext'
	question: ["Where can I take you now?", "Where to next?", "What can I do for you?"]
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
		$(window).off 'keyup', cancelIntro

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
	dismiss: 5
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
	dismiss: 4
	continue: 'whatnext'
,
	name: 'pronounce'
	text: 'Just find a Russian-speaker, they can help :)'
	dismiss: 3
	continue: 'about'
,
	name: 'about'
	question: ["What would you like to see?", "What would you like to know?", "How can I help?"]
	response:
		choices:
			"Zhenya's CV": 'cv'
			"A nice code sample": 'slider'
			"This app on GitHub": 'milkyway'
			"zhenya.co": 'web'
			"How to pronounce 'Zhenya'?": 'pronounce'
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
	dismiss: 3.5
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