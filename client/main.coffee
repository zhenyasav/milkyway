
Template.menu_items.helpers
	
	selected: -> 
		endsWith = new RegExp @value.replace(/\./g, '\\.') + "$"
		'selected' if endsWith.test(new Iron.Url(Router.current()?.url).pathname)


Template.main.events

	'click': (e) ->

		toggleSideBar = (button, sidebar) ->
			if $(e.target).closest(button).length
				$(sidebar).toggleClass 'showing'
			else if not $(e.target).closest(sidebar).length or $(e.target).closest(sidebar + ' a').length
				$(sidebar).removeClass 'showing'

		toggleSideBar '.container .header .menu.button', '.menu.right'
		toggleSideBar '.container .header .nav.button', '.menu.left'
