import Foundation

/// The English riddles (#551): the English tradition's own riddles told in our own words, written
/// apart from the Spanish ones, not translated. Twelve per tier; tiers 1-3 have answers with pictures.
/// Nothing about illness, death or fear, and no double meanings beyond a plain pun ("ears" of corn).
extension Riddles {
    static let english: [Riddle] = book(
        "en",
        [
            // Tier 1: very easy, two lines, pictures.
            r(
                1, "cat", ["I purr when I'm happy and I say meow,", "I nap in the sunshine. Can you name me now?"],
                "It chases mice."),
            r(1, "dog", ["I wag my tail when you come home,", "I bark at the door and chew on a bone."], "It says woof."),
            r(
                1, "bee", ["I buzz all day from flower to flower,", "and fill my hive with something sweet every hour."],
                "It lives in a hive."),
            r(
                1, "banana", ["I wear a yellow coat and a curvy shape;", "peel me first, and the monkeys think I'm great!"],
                "It grows in big bunches."),
            r(
                1, "moon", ["I'm round and silver up at night,", "and I borrow the sun's soft light."],
                "Sometimes it's full, sometimes just a sliver.", avoid: ["star"]),
            r(
                1, "strawberry", ["I'm red and sweet with seeds outside,", "under green leaves in the patch I hide."],
                "It's lovely with cream."),
            r(
                1, "clock", ["I have a face and two hands too,", "I tick all day and tell the time to you."],
                "It hangs on the wall."),
            r(
                1, "elephant", ["I'm big and gray with a trunk for a nose,", "and I never forget, or so the saying goes."],
                "It has big flapping ears."),
            r(
                1, "frog", ["I'm green and I hop beside the pond,", "I croak all night, and of flies I'm fond."],
                "It was a tadpole once."),
            r(
                1, "umbrella", ["When the rain comes down, up I go,", "to keep you dry from head to toe."],
                "You hold it by its handle."),
            r(
                1, "key", ["I'm small and metal and live on a ring;", "I open your door. What a useful thing!"],
                "You turn it in a lock."),
            r(
                1, "star", ["I twinkle high on a clear, dark night;", "make a wish when you see my light."],
                "Children sing a song about it twinkling.", avoid: ["moon"]),

            // Tier 2: easy, pictures.
            r(
                2, "butterfly",
                [
                    "I started small and liked to crawl,", "I slept a while, wrapped up in a shawl,",
                    "then woke with the brightest wings of all.",
                ],
                "It was a caterpillar first.", avoid: ["bee", "ladybug"]),
            r(
                2, "turtle", ["I'm slow, but once I won a race;", "my shell's my house and my own safe place."],
                "It can pull its head inside."),
            r(
                2, "watermelon",
                [
                    "I'm heavy and striped and green outside,", "slice me open and I'm pink inside,",
                    "and on summer picnics I'm the pride.",
                ],
                "You spit out its black seeds."),
            r(
                2, "orange", ["My name is the same as my bright color,", "peel me in pieces to share with another."],
                "Its juice is a breakfast drink.", avoid: ["lemon"]),
            r(
                2, "lion",
                [
                    "With a golden mane like a crown on my head,", "I'm king of the jungle, or so it's said,",
                    "but I'd rather nap in the shade instead.",
                ],
                "It roars."),
            r(
                2, "violin",
                [
                    "I'm tucked beneath your chin to play,", "a bow slides over me all day,",
                    "and I sing high notes in a sweet way.",
                ],
                "It's the fiddle at a country dance.", avoid: ["guitar"]),
            r(2, "book", ["I have a spine but not a bone,", "I tell you stories when you're alone."], "It has pages."),
            r(
                2, "chair",
                [
                    "I have four legs but never walk,", "I have a back but never talk,",
                    "pull me to the table when it's time to eat.",
                ],
                "You sit on it.", avoid: ["sofa"]),
            r(
                2, "house",
                ["I have a door and windows too,", "a roof on top to cover you,", "and inside, your family waits for you."],
                "It has an address."),
            r(
                2, "bread", ["I rise in a warm pan, but I have no feet,", "then I'm sliced for toast or a sandwich treat."],
                "The baker makes it every morning.", avoid: ["cake", "croissant"]),
            r(2, "egg", ["I must be broken before I'm used,", "scrambled or fried, whichever you choose."], "A hen lays it."),
            r(
                2, "airplane",
                [
                    "I have long wings but I never flap,", "I carry travelers over the map,",
                    "and land on a runway after my trip.",
                ],
                "It flies from the airport."),

            // Tier 3: medium, pictures.
            r(
                3, "train",
                [
                    "I run on tracks but I have no feet,", "I whistle at every crossing street,",
                    "and pull long cars in a line so neat.",
                ],
                "It stops at the station."),
            r(
                3, "bicycle",
                [
                    "I have two wheels and a little bell,", "push my pedals and I'll ride you well,",
                    "but stop, and I lean against the wall.",
                ],
                "It has a seat, handlebars and a chain."),
            r(
                3, "cheese",
                [
                    "I'm made from milk and I'm often yellow,", "mice think I'm a wonderful fellow,",
                    "slice me for sandwiches, soft or mellow.",
                ],
                "Some kinds are full of holes."),
            r(
                3, "honey",
                [
                    "I'm golden and sticky and sweet as can be,", "I'm made in a hive by a busy bee,",
                    "spread me on toast or stir me in tea.",
                ],
                "It comes in a jar with a dipper."),
            r(
                3, "piano",
                [
                    "I have many keys but open no doors,", "my black and white teeth never bite,",
                    "play me, and I'll sing all night.",
                ],
                "You sit on a bench to play it.", avoid: ["accordion"]),
            r(
                3, "trumpet",
                ["I'm made of shiny brass,", "you blow in me to start the fun,", "ta-ta-taa! The parade has begun."],
                "It has three valves to press."),
            r(
                3, "sunflower",
                [
                    "I'm tall and yellow and I turn my face", "to follow the sun from place to place,",
                    "and birds love the seeds in my middle space.",
                ],
                "Its seeds are a crunchy snack."),
            r(
                3, "cactus",
                [
                    "I live in the desert and rarely drink,", "I wear prickly spines instead of leaves,",
                    "so wave hello, but don't hug me, please.",
                ],
                "It stores water inside."),
            r(
                3, "tree",
                [
                    "I have bark but I never growl,", "I have rings but I wear no jewels,",
                    "and birds build their homes in my arms.",
                ],
                "Its leaves fall in autumn.", avoid: ["pine"]),
            r(
                3, "telephone",
                ["I ring but I'm not a bell,", "you speak to me, and I don't tell,", "I bring faraway voices close as well."],
                "You say hello when you pick it up."),
            r(
                3, "ladybug",
                [
                    "I'm tiny and red with polka dots,", "I crawl on leaves in garden spots,",
                    "and land on your hand to say hello.",
                ],
                "It's a small beetle with spots."),
            r(
                3, "suitcase",
                [
                    "Pack me with clothes before you go,", "I have a handle and wheels below,",
                    "and come home full of gifts to show.",
                ],
                "You take it on a trip."),

            // Tier 4: medium, words.
            r(
                4, "comb",
                [
                    "I have many teeth but I never bite,", "I go through your hair to set it right,",
                    "in the morning and at night.",
                ],
                "It fits in a pocket or a purse."),
            r(
                4, "towel",
                [
                    "The more I dry, the wetter I get,", "after your bath I'm your best bet,",
                    "then hang me on a hook to dry off yet.",
                ],
                "It's soft, and you wrap yourself in it."),
            r(
                4, "bottle",
                ["I have a neck but no head,", "I wear a cap but never go to bed,", "I hold your milk or water instead."],
                "You pour from it."),
            r(
                4, "corn",
                [
                    "I have ears but I cannot hear,", "I grow in tall rows in summer each year,",
                    "and I'm buttered and salted when supper is near.",
                ],
                "It grows on a tall green stalk."),
            r(
                4, "potato",
                [
                    "I have eyes but I cannot see,", "I grow in the dirt, not up a tree,",
                    "mash me or bake me for your dinner plate.",
                ],
                "French fries are made from it."),
            r(
                4, "snow",
                [
                    "I fall from the sky but I'm not rain,", "I'm white and cold on the window pane,",
                    "and children shape me into a man.",
                ],
                "It falls in winter.", avoid: ["cloud"]),
            r(
                4, "wind",
                [
                    "You cannot see me, but I bend the trees,", "I fly your kite and cool you with a breeze,",
                    "and I whistle at the door, if you please.",
                ],
                "It blows the leaves around."),
            r(
                4, "horse",
                [
                    "I wear iron shoes but never tie a lace,", "I gallop and trot at a lively pace,",
                    "and a cowboy rides me from place to place.",
                ],
                "It says neigh.", avoid: ["donkey"]),
            r(
                4, "owl",
                [
                    "I sleep all day and wake at night,", "I ask 'who-who' in the pale moonlight,",
                    "and turn my head almost all the way round.",
                ],
                "It's a bird with big round eyes."),
            r(
                4, "button",
                [
                    "I'm small and round with holes in me,", "I keep your coat closed, as you see,",
                    "sewn on tight with needle and thread.",
                ],
                "It goes through a little slit in your shirt."),
            r(
                4, "drum",
                ["Tap me, beat me, I don't mind,", "boom, boom, I keep the time,", "at the front of the band I march in line."],
                "You play it with two sticks."),
            r(
                4, "spoon",
                [
                    "I'm round at one end with a long thin handle,", "I stir your coffee and scoop your sugar,",
                    "and I dive into soup but I'm never hungry.",
                ],
                "It sits beside the fork and the knife."),

            // Tier 5: harder, four lines, words.
            r(
                5, "map",
                [
                    "I have cities but no houses,", "mountains but no trees,", "water but no fish,",
                    "and roads where no one walks.",
                ],
                "You unfold it to find your way."),
            r(
                5, "coin",
                [
                    "I have a head and a tail,", "but no body and no legs,", "I'm round and shiny in your pocket,",
                    "and I jingle with my friends.",
                ],
                "You can toss it to decide."),
            r(
                5, "glove",
                [
                    "I have a thumb and four fingers,", "but I'm not a hand at all,", "I keep your hand warm in winter,",
                    "and I always come in a pair.",
                ],
                "You wear it in the cold.", avoid: ["shoe"]),
            r(
                5, "lamp",
                [
                    "I have a shade but I'm not a tree,", "I fill the room but take no space,",
                    "flip my switch and I chase the dark,", "then rest when you go to bed.",
                ],
                "It sits on a table by the bed.", avoid: ["candle"]),
            r(
                5, "mountain",
                [
                    "I wear a white cap in the winter,", "I'm older than the oldest tree,", "climb me slowly, step by step,",
                    "and from my top the whole world you'll see.",
                ],
                "It's much taller than a hill."),
            r(
                5, "stamp",
                [
                    "I travel all around the world,", "but I stay in one corner the whole way,",
                    "I'm small and square and sticky on the back,",
                    "and I ride on your letters every day.",
                ],
                "The post office sells it.", avoid: ["letter"]),
            r(
                5, "pine",
                [
                    "I keep my needles all year round,", "but I never sew a single seam,",
                    "in December I wear lights and a star,",
                    "and I smell like a forest dream.",
                ],
                "It's green even in winter.", avoid: ["tree", "cactus"]),
            r(
                5, "shoe",
                [
                    "I have a tongue but cannot talk,", "I go wherever you walk,", "I'm tied with laces snug and tight,",
                    "and wait by the bed all night.",
                ],
                "It comes in a pair for your feet.", avoid: ["glove"]),
            r(
                5, "teapot",
                [
                    "I have a handle, a spout, and a lid,", "a round fat belly where the leaves are hid,",
                    "I pour you a cup at four o'clock,",
                    "and wear a cozy like a woolly sock.",
                ],
                "Tea is made in it."),
            r(
                5, "yarn",
                [
                    "I'm a ball, but nobody kicks me,", "the cat loves to chase me across the floor,",
                    "knitting needles click and clack with me,", "and I become a scarf, and more.",
                ],
                "You knit with it."),
            r(
                5, "rocket",
                [
                    "I count down from ten to one,", "then roar past the clouds and the sun,",
                    "I visit the moon and the stars at night,",
                    "riding on a tail of fire and light.",
                ],
                "Astronauts ride in it."),
            r(
                5, "sailboat",
                [
                    "I have no engine and no oars,", "the wind pushes me along the shores,",
                    "my white sheet fills up big and round,",
                    "and I cross the bay without a sound.",
                ],
                "Its sail catches the wind."),
        ])
}
