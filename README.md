Place camper.lua and JSON.lua inside auctionhelper addon folder and add `require('camper')` near the top of auctionhelper.lua [this line here](https://github.com/Ivaar/Windower-addons/blob/72e7144bbe4513458469375da909bc9de006f676/AuctionHelper/AuctionHelper.lua#L27)

//camp on 	-- turn on camping mode

//camp off	-- turn off camping mode

//camp add item_name stack price #quantity --must prefix quantity with # if not specified will not limit purchase quantity

//camp import file_name -- imports json bidlist profile

//camp export file_name -- exports to json using "pretty printing"

//camp exp file_name -- beta: exports to json, one item entry per new line

//camp rec on	-- record a profile by bidding on items on the auctionhouse normally or with //buy

//camp rec off	-- turn off profile recording

//camp display	-- display bidlist using a click-drag text box

//camp display off -- hide the bidlist

//camp qty [n]	--adjust the quantity for last entry added. (likely to be changed or merged with another command)

//camp inc [n]	--adjust the bid increment for last entry added.(same as above, need to make adding items easier)
