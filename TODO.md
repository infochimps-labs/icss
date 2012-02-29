# Proposed ICSS refactoring:

* one ICSS <=> one Dataset <=> one Catalog Entry


geo.lake_body_of_water                 	  
geo.ocean_body_of_water                	  
geo.river_body_of_water                	  
geo.sea_body_of_water                  	

### catalog_entry

Most of it moves to top-level:
* tags:         move to top-level attribute
* title:        disappears -- take from `protocol`
* description:  disappears -- take from `doc`
* owner:        stays in catalog_entry
* price:        attach to bulk data target

* messages:     only necessary to select among messages
* packages:     only necessary to select among packages

move to a new top-level section, `provenance`:

* license
* link -> becomes sources

moves *to* catalog_entry:

* `under_consideration` 
* `update_frequency` (?? def. doesn't feel like a top-level thing, but this feels weird too)


___________________________________________________________________________

Make the get_data part of culture/books/comics/grand_comics_db a three-liner

menu            	string	Either the actual menu or a URL of the menu.
accepts_reservations 	string 	"Either Yes/No, or a URL at which reservations can
be made."


tile_x                 	string                           	|	bounding_box            
tile_y                 	string                           	|	bounding_box            
