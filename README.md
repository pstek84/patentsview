# PatentsView Data Table Modifications

This is R code used to setup a patent database in MySQL using [PatentsView data tables](https://patentsview.org/download/data-download-tables) from the USPTO. In some instances the PatentsView tables are modified, as stated below:

* __location__ table is geocoded using the Pelias coarse geocoder. Note that locations only geocoded at the country level (except for very small countries) should be removed.

* __assignee__ table adds Triple Helix classifications (University, Government, Industry) using a word list and USPTO assignee type.

Accuracy of both processes is around 90% or higher based on own random sample checks, however users should always check assignees and locations with large numbers of patents to avoid large errors in their research.
