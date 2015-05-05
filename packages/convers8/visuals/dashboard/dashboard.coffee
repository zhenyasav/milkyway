

getSinceLast = (time) ->
	t = Session.get 'time'
	if time?
		last = time?.getTime?()
		moment.duration Math.abs t - last


Template.time.helpers

	visible: -> @time?

	displayStyle: (units) -> 
		d = getSinceLast @time
		days = d.days()
		hours = d.hours()
		minutes = d.minutes()
		seconds = d.seconds()

		c = []
	
		switch units
			when 'days' 
				if days 
					c.push 'large' if @large
				else
					c.push 'hide'
			when 'hours'
				if not days
					if hours
						c.push 'large' if @large
					else
						c.push 'hide'

		c.join ' '


	sinceLast: (units) -> getSinceLast(@time)?[units]?()

	label: (units) ->
		if (val = getSinceLast(@time)?[units]?())?
			Utils.pluralize val, units


currentDuration = ->
	if u = Meteor.user()
		if (last = u?.profile?.responses?['last cigarette'])?
			t = Session.get 'time'
			moment.duration t - last

goalDuration = ->
	if (d = currentDuration())?
		if d.months() > 0
			moment.duration d.months() + 1, "months"
		else if d.weeks() > 0
			moment.duration d.weeks() + 1 + ' weeks'
		else if d.days() > 0
			moment.duration d.days() + 1, 'days'
		else if d.hours() > 0
			moment.duration d.hours() + 1, 'hours'
		else
			moment.duration 1, 'hours'

goalProgress = ->
	c = currentDuration()
	g = goalDuration()
	if c? and g?
		c / g

Template.dashboard.helpers

	goalVisible: -> Meteor.user?()?.profile?.responses?['last cigarette']?

	prog: -> goalProgress()
		
	formatProg: -> Math.floor 100 * goalProgress()

	lastCigarette: -> Meteor.user?()?.profile?.responses?['last cigarette']

	goal: ->
		g = goalDuration()?.humanize()
		if g
			l = g[g.length-1]
			if l is 's'
				g = Utils.singular g
			else
				g += "'s"
			g

Template.dashboard.events Utils.mobilizeEvents
	'click .button.craving': -> Visuals.push 'factoid(0.75), remedy'
	'click .button.givingin': -> Visuals.push 'factoid(0.75), breathe'

