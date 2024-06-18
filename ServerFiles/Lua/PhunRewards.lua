return {
    current = {{
        hours = 3,
        repeating = true,
        item = "PhunMart.CheeseToken",
        qty = 1
    }, {
        hours = 1,
        kills = 3,
        item = "PhunMart.SilverDollar",
        qty = 1
    }},
    total = {{
        hours = 168,
        item = "PhunMart.TraiterToken",
        qty = 1
    }, {
        hours = 336,
        item = "PhunMart.TraiterToken",
        qty = 1
    }, {
        hours = 504,
        item = "PhunMart.TraiterToken",
        qty = 1
    }, {
        hours = 668,
        item = "PhunMart.TraiterToken",
        qty = 1
    }, {
        hours = 836,
        item = "PhunMart.TraiterToken",
        qty = 1
    }, {
        hours = 1004,
        item = "PhunMart.TraiterToken",
        qty = 1
    }, {
        hours = 1172,
        item = "PhunMart.TraiterToken",
        qty = 1
    }},
    drops = {
        zeds = {
            items = {{
                item = "PhunMart.SilverDollar",
                chance = 30,
                qty = {
                    min = 1,
                    max = 3
                }
            }, {
                item = "PhunMart.CheeseToken",
                chance = 10,
                qty = 1,
                zones = {
                    difficulty = 1
                }
            }, {
                item = "PhunMart.TraiterToken",
                chance = 10,
                qty = 2,
                zones = {
                    keys = {"WestPoint"}
                }
            }}
        },
        sprinters = {
            items = {{
                item = "PhunMart.SilverDollar",
                chance = 50,
                qty = {
                    min = 1,
                    max = 3
                }
            }, {
                item = "PhunMart.CheeseToken",
                chance = 30,
                qty = {
                    min = 1,
                    max = 2
                }
            }, {
                item = "PhunMart.TraiterToken",
                chance = 10,
                qty = 1
            }}

        }
    }
}
