# Proposed ICSS refactoring:

* one ICSS <=> one Dataset <=> one Catalog Entry


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

