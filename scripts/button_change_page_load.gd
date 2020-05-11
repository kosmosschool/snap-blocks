extends KSButtonPressable


# button used to change the page to prev or next in the load screen
class_name ButtonChangePageLoad


enum PageDirection {NEXT, PREV}
export (PageDirection) var page_direction = PageDirection.NEXT


# overriding the parent function
func button_press(other_area: Area):
	.button_press(other_area)
	
	var load_screen = get_parent()
	load_screen.change_page(page_direction)
