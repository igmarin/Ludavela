import Foundation

/// The Spanish riddles (#551): Mexican oral tradition told in our own words, not copied from any book
/// or its order. Twelve per tier; tiers 1-3 have answers with pictures. Nothing about illness, death or
/// fear, and no double meanings.
extension Riddles {
    static let spanish: [Riddle] = book(
        "es",
        [
            // Tier 1: very easy, two lines, pictures.
            r(1, "cat", ["Con bigotes y colita,", "digo «miau» en la cocinita."], "Le gusta perseguir ratones."),
            r(1, "dog", ["Muevo la cola cuando llegas,", "ladro en la puerta y cuido tu casa entera."], "Dice «guau, guau»."),
            r(1, "bee", ["Zumbando de flor en flor,", "hago algo dulce con amor."], "Vive en una colmena."),
            r(
                1, "banana", ["Me visto de amarillo y me pelas despacito,", "soy curvo como la luna y dulce como un besito."],
                "Al chango le encanta."),
            r(
                1, "moon", ["Salgo de noche, redonda y plateada,", "y cuando sale el sol, me voy callada."],
                "Unos días está llena y otros parece un gajito.", avoid: ["star"]),
            r(
                1, "apple", ["Soy roja y redonda y crujo al morder,", "con mi rabito arriba me vas a ver."],
                "Hay rojas, verdes y amarillas.", avoid: ["peach"]),
            r(
                1, "clock", ["Tengo cara y dos manecillas,", "tic, tac, te digo la hora sin prisas."],
                "Cuelga en la pared de la sala."),
            r(
                1, "elephant", ["Soy grandote, gris y orejón,", "y mi nariz es una trompa, ¡qué narizón!"],
                "Es el animal de tierra más grande."),
            r(
                1, "turtle", ["Camino lento, lento, sin ninguna prisa,", "y llevo mi casa puesta como camisa."],
                "Se mete en su caparazón."),
            r(
                1, "umbrella", ["Cuando llueve, me abres sobre ti;", "cuando sale el sol, me cierras y me dejas ahí."],
                "Tiene mango y sirve para no mojarte."),
            r(1, "key", ["Chiquita soy, de metal y con dientes,", "abro la puerta para que entres."], "Cuelga del llavero."),
            r(
                1, "star", ["De noche brillo allá muy arriba,", "chiquita y con picos, ¿quién lo diría?"],
                "En los dibujos tiene cinco puntas.", avoid: ["moon"]),

            // Tier 2: easy, pictures.
            r(
                2, "frog", ["Verde, verde, en el charco vivo,", "doy saltitos y «croac» es lo que digo."],
                "Atrapa moscas con su lengua larga."),
            r(
                2, "butterfly",
                ["Fui gusanito y me fui a dormir,", "desperté con alas de mil colores", "y ahora paseo entre las flores."],
                "Primero fue oruga.", avoid: ["bee", "ladybug"]),
            r(
                2, "watermelon",
                ["Por fuera soy verde y rayada,", "por dentro roja y bien aguada,", "y en el calor soy la más buscada."],
                "Tiene muchas semillas negras."),
            r(
                2, "orange",
                ["Me llamo igual que mi color,", "redonda, jugosa y llena de sabor,", "y en el desayuno me exprimen con amor."],
                "Con ella se hace el jugo de la mañana.", avoid: ["lemon"]),
            r(
                2, "lion",
                ["Llevo melena como una corona,", "soy el rey de la selva y rujo fuerte,", "pero también me gusta la siesta."],
                "Su rugido se oye muy lejos."),
            r(
                2, "guitar",
                [
                    "Tengo seis cuerdas y un hoyo en la panza,", "me abrazas para tocarme,",
                    "y bajo la ventana canto la serenata.",
                ], "Se toca rasgueando las cuerdas.", avoid: ["violin"]),
            r(2, "book", ["Tengo hojas y no soy planta,", "te cuento historias sin garganta."], "Lo abres para leer."),
            r(
                2, "chair", ["Tengo cuatro patas y nunca camino;", "te sientas en mí cuando llega el vecino."],
                "Va junto a la mesa del comedor.", avoid: ["sofa"]),
            r(2, "house", ["Tengo techo, puerta y ventana,", "y en mí despierta tu familia cada mañana."], "Ahí vives tú."),
            r(
                2, "bread", ["Salgo del horno calientito,", "dorado, redondo y suavecito,", "y en la merienda soy lo más rico."],
                "Lo vende el panadero.", avoid: ["cake", "croissant"]),
            r(
                2, "egg", ["Soy blanco y liso, sin puerta ni ventana,", "y escondo un sol amarillo para tu mañana."],
                "Lo pone la gallina."),
            r(
                2, "airplane", ["Tengo alas pero no tengo plumas,", "vuelo alto entre las nubes", "y llevo gente de viaje."],
                "Despega y aterriza en el aeropuerto.", avoid: ["helicopter", "rocket"]),

            // Tier 3: medium, pictures.
            r(
                3, "train",
                [
                    "Soy largo como un gusano de fierro,", "corro por las vías de cerro en cerro,",
                    "y en cada estación digo «chu-chu».",
                ],
                "Tiene vagones y locomotora."),
            r(
                3, "bicycle",
                ["Tengo dos ruedas y un timbrecito,", "si tú pedaleas, corro un poquito,", "y si te paras, me caigo solito."],
                "Tiene asiento, manubrio y cadena."),
            r(
                3, "coffee",
                [
                    "Negrito y calientito en la mañana,", "en jarrito de barro me tomas con ganas,",
                    "y mi aroma despierta a toda la casa.",
                ],
                "Se hace con granos tostados y molidos.", avoid: ["chocolate"]),
            r(
                3, "honey",
                ["Dorada y espesa, dulce de verdad,", "me hacen unas obreras con alas", "que van de flor en flor sin parar."],
                "La hacen las abejas."),
            r(
                3, "piano", ["Tengo dientes blancos y negros", "y nunca muerdo a nadie;", "cuando me tocas, yo canto."],
                "Tiene muchas teclas.", avoid: ["accordion"]),
            r(
                3, "accordion",
                [
                    "Me estiro y me encojo al tocar,", "tengo botones y un fuelle para respirar,",
                    "y en la música norteña no me pueden faltar.",
                ],
                "Se toca abriéndolo y cerrándolo.", avoid: ["piano"]),
            r(
                3, "sunflower",
                ["Soy una flor grandota y amarilla,", "miro al sol desde que sale,", "y mis semillas son botana."],
                "Es más alta que un niño."),
            r(
                3, "cactus",
                [
                    "Vivo en el desierto y casi no bebo,", "tengo espinas en lugar de hojas,",
                    "y aunque no me abraces, te quiero.",
                ],
                "No lo toques, porque pica."),
            r(
                3, "tree", ["Tengo tronco y no soy elefante,", "tengo hojas y no soy libro,", "y doy sombra al caminante."],
                "Los pájaros hacen su nido en él.", avoid: ["pine"]),
            r(
                3, "telephone",
                ["Suena «riiing» y no es campana;", "me hablas aquí y te oyen allá,", "aunque tu hermana viva lejos."],
                "Contestas diciendo «¿Bueno?»."),
            r(
                3, "ladybug",
                [
                    "Chiquita y roja con puntitos negros,", "camino por las hojas del jardín",
                    "y, si abro mis alas, salgo volando.",
                ],
                "Es un insecto con lunares."),
            r(
                3, "suitcase",
                ["Me llenas de ropa antes del viaje,", "tengo asa y a veces rueditas,", "y regreso del viaje con regalitos."],
                "La llevas cuando sales de vacaciones."),

            // Tier 4: medium, words.
            r(
                4, "snail",
                [
                    "Llevo mi casa en la espalda,", "camino despacio y dejo un caminito brillante,",
                    "y saco mis cuernitos cuando llueve.",
                ],
                "Su casita es una concha en espiral.", avoid: ["turtle"]),
            r(
                4, "corn",
                [
                    "Tengo dientes amarillos y no muerdo,", "llevo barbas y no soy abuelo,",
                    "y en la esquina me venden en vaso o en palito.",
                ], "Crece en la milpa, envuelto en hojas."),
            r(
                4, "tortilla",
                [
                    "Redonda y plana, del comal salgo,", "caliente me doblas y me rellenas,",
                    "y en todas las comidas te acompaño.",
                ],
                "Con ella se hace un taco.", avoid: ["bread"]),
            r(
                4, "avocado",
                [
                    "Verde por fuera, con un hueso grandote,", "suave por dentro, cremoso y sabroso,",
                    "y sin mí no hay guacamole.",
                ],
                "Se pone en las tortas y en los tacos."),
            r(
                4, "hat",
                ["Te cubro la cabeza cuando hace sol,", "tengo ala pero no vuelo,", "y el charro me lleva grande y bordado."],
                "Te lo quitas para saludar."),
            r(
                4, "candle",
                [
                    "Alumbro con mi cabecita encendida,", "y mientras alumbro me hago chiquita;",
                    "en tu pastel me soplas y pides un deseo.",
                ],
                "Está hecha de cera.", avoid: ["lamp"]),
            r(
                4, "scissors",
                ["Tengo dos ojitos para tus dedos,", "abro y cierro mi boca de metal,", "y corto el papel en dos."],
                "La costurera las usa para cortar tela."),
            r(
                4, "needle", ["Tengo un ojo y no veo nada,", "llevo el hilo detrás de mí,", "y remiendo la ropa rota."],
                "Es delgadita y tiene punta."),
            r(
                4, "sun",
                [
                    "Salgo en la mañana sin que me llamen,", "caliento la tierra y seco la ropa,",
                    "y en la tarde me escondo tras el cerro.",
                ],
                "Es lo que más brilla en el día.", avoid: ["moon", "star"]),
            r(
                4, "rainbow",
                ["Después de la lluvia salgo en el cielo,", "con siete colores hago un puente,", "pero nadie lo puede cruzar."],
                "Tiene rojo, amarillo, verde, azul y morado."),
            r(
                4, "rooster",
                ["Me levanto antes que el sol,", "con mi cresta roja y mi canto", "despierto a todo el rancho: ¡kikirikí!"],
                "Es el papá de los pollitos."),
            r(
                4, "bell",
                [
                    "Tengo una lengua y no hablo;", "me jalan la cuerda y canto «talán, talán»,",
                    "y llamo a todo el pueblo a la plaza.",
                ],
                "Cuelga en el campanario."),

            // Tier 5: harder, four lines, words.
            r(
                5, "shadow",
                [
                    "Me pego a tus pies todo el día,", "si caminas, camino contigo,", "cuando cae la tarde me hago larga,",
                    "y de noche me voy sin despedirme.",
                ], "Es oscura y tiene tu forma."),
            r(
                5, "mirror",
                [
                    "Cuelgo en la pared del baño", "y te devuelvo la sonrisa;", "si levantas la mano izquierda,",
                    "yo levanto la otra, sin prisa.",
                ], "Te ves en él antes de peinarte."),
            r(
                5, "broom",
                [
                    "Bailo por el piso sin música,", "tengo barbas tiesas y un palo largo,", "me paseo por cada cuarto",
                    "y dejo todo limpio a mi paso.",
                ],
                "Con ella se barre el patio."),
            r(
                5, "pineapple",
                [
                    "Llevo corona y no soy reina,", "tengo escamas y no soy pez,", "por fuera pico un poquito",
                    "y por dentro soy dulce y amarilla.",
                ],
                "Va en los tacos al pastor."),
            r(
                5, "onion",
                [
                    "Tengo capas y más capas", "y una camisa de papel;", "en el guacamole y en la salsa me encuentras,",
                    "y al cortarme te pico los ojos.",
                ], "Va con el jitomate y el cilantro.", avoid: ["chili"]),
            r(
                5, "chili",
                [
                    "Soy verde o rojo, chiquito o grandote,", "en la salsa nunca falto,", "y si me muerdes sin cuidado,",
                    "¡echas lumbre por la boca!",
                ],
                "Pica mucho.", avoid: ["onion"]),
            r(
                5, "river",
                [
                    "Bajo de la sierra cantando,", "nunca me paro a descansar,", "los peces viven en mi casa,",
                    "y al final me encuentro con el mar.",
                ], "Tiene dos orillas y a veces un puente."),
            r(
                5, "letter",
                [
                    "Viajo lejos sin pies ni alas,", "llevo una estampilla en la esquina,", "guardo palabras de cariño",
                    "y me abres con alegría.",
                ], "La trae el cartero.", avoid: ["stamp", "book"]),
            r(
                5, "cloud",
                [
                    "Soy blanca como el algodón,", "paseo por el cielo sin camino,", "me pongo gris y pesada,",
                    "y entonces suelto agua para el campo.",
                ],
                "De ella cae la lluvia.", avoid: ["moon", "snow"]),
            r(
                5, "donkey",
                [
                    "Tengo orejas largas y paso firme,", "cargo la leña sin quejarme,", "digo «i-aah» por el camino",
                    "y soy amigo fiel del campesino.",
                ],
                "Se parece al caballo, pero es más chico.", avoid: ["horse"]),
            r(
                5, "pencil",
                [
                    "Soy de madera y no soy árbol,", "me sacan punta y me hago chiquito,", "escribo sin saber leer,",
                    "y mi gomita borra lo que no te gusta.",
                ],
                "Lo usas en la escuela para escribir."),
            r(
                5, "cow",
                [
                    "Vivo en el rancho y como pasto,", "tengo manchas como un mapa,", "digo «muu» desde temprano",
                    "y te doy leche para el café.",
                ],
                "Su bebé es el becerro."),
        ])
}
