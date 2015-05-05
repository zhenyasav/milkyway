searchTerm = new ReactiveVar null
selectedIndex = new ReactiveVar -1

Template.apps.helpers

	emName: -> @value?.emName ? @value?.name

	selected: (n) -> 'selected' if n is selectedIndex.get()

	apps: -> 
		term = searchTerm.get()

		term = term?.replace /\s+/g, ''

		apps = Apps.find().fetch()

		return apps if not term

		scores = (score for app in apps when (score = fuzzy app.name, term).score)
			
		scores = _.sortBy scores, (s) -> -s.score

		for s in scores
			name: s.term
			emName: s.highlightedTerm


Template.apps.events

	'blur .search input': (e) ->
		selectedIndex.set -1

	'keyup .search input': (e) ->

		sel = selectedIndex.get()
		apps = $(e.target).closest('.menu').find '.apps a'
		results = apps.length

		if e.keyCode is Utils.keys.down
			if sel < results - 1
				selectedIndex.set sel + 1
			
		else if e.keyCode is Utils.keys.up
			if sel > 0
				selectedIndex.set sel - 1
			
			e.target.selectionStart = e.target.value.length
		else
			if e.keyCode is Utils.keys.esc
				e.target.value = ''
				selectedIndex.set -1

			else if e.keyCode is Utils.keys.enter
				if results
					if url = apps[selectedIndex.get()]?.href
						url = new Iron.Url url
						Router.go url.pathname
						$('.menu.left').removeClass 'showing'

				e.target.value = ''
				$(e.target).blur()

			else
				selectedIndex.set 0

		searchTerm.set e.target.value
