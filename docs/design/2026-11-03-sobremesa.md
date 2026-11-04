# Ludavela — referencias aplicadas (#579)

Estado: el propietario eligió crema actual, mesa jade plana y títulos sobre crema, conservando el abanico (2026-11-03). Las demás composiciones siguen en revisión. Epic #578; implementación paralela en #580 y #581 autorizada. No merge implícito.

## Abrir el estudio

- [Comparador interactivo](2026-11-03-sobremesa.html): inicio, carta y celebración; controles de crema, mesa, banda, apariencia, tamaño de texto e idioma.
- Capturas exportadas antes de la elección del propietario; conservadas como evidencia histórica.
- [Captura completa clara](sobremesa-579/proposal-overview.png).
- [Captura oscura, texto grande y EN](sobremesa-579/proposal-dark-large-en.png).
- Referencias externas consultadas: `/Users/igmarin/Downloads/cartoon references/`. No se copian al repositorio ni se incorporan a la app.

El HTML es una maqueta de diseño autónoma, no una nueva página de producto. Sus botones representados no ejecutan juegos. Los selectores sí cambian la comparación. Las imágenes se cargan del propio repositorio, sin red externa. Las capturas de iOS y las maquetas están identificadas por separado.

## Dirección y corrección del propietario

El propietario pidió conservar la interacción de las recomendaciones del inicio y cómo se marca cada día. Por ello, el contrato conserva todas las cartas recomendadas, sus accesos directos, las marcas de completado y el tablero de siete días con cartas. La siguiente partida no sustituye una carta recomendada ni cambia la selección del plan. El estudio no propone una racha ni una métrica nueva.

La variante de inicio del HTML conserva el abanico de tres cartas y coloca antes una acción crema con borde jade. No afirma ser la implementación exacta de #581. La versión implementable debe preservar la interacción del reparto actual; los cambios de posición de la acción y las demás composiciones siguen sujetos a revisión. Una maqueta no demuestra mayor retención o facilidad de uso.

## Referencia → rasgo → aplicación

| Archivo | Rasgo que se estudia | Aplicación concreta | Lo que se excluye |
|---|---|---|---|
| reference0.webp | Paleta limitada, crema/jade/mostaza, jerarquía editorial | Fondo, mesa, acción destacada y cartas | Personaje, composición y letras copiadas |
| reference2.jpg | Siluetas y formas geométricas planas | Masas de color tranquilas; posible bienvenida #584 | Personajes, trama detrás del texto |
| reference1.webp | Elasticidad y expresividad | Storyboard de reacción breve al tocar | Escenario, personajes, movimiento continuo |
| reference3.webp | Contornos y gesto amable | Celebración con un protagonista | Copia de poses, monocromo obligatorio |
| reference4.jpg | Objetos personificados y movimiento | Objetos familiares, entrada/salida breve | Escena, personajes y efectos fílmicos |
| reference5.jpg | Siluetas fuertes con expresión | Ilustración de carta grande y reconocible | Tema Halloween, caras en todos los objetos |

## Paleta de trabajo

| Función | Claro | Oscuro | Estado |
|---|---|---|---|
| Papel | #FFF1D0 | #211E1B | Conservar |
| Texto/marco | #2B2118 | #FFF1D0 | Conservar |
| Acción jade | #246456 | #78C4AE | Conservar |
| Marca mostaza | #E7AC45 | #E7AC45 | Relleno con texto espresso |
| Mesa plana | #DCE7D5 | #2D4A3F | Propuesta coordinada con #580 |
| Papel más claro | #FFF8E8 | Sin nueva variante | Sólo comparación; no aplicado por defecto |

Comparar cambiando una variable por vez sobre la misma maqueta. La variante oscura no utiliza el crema candidato como fondo. No alterar colores que codifican estímulos de juegos. Las comprobaciones matemáticas de contraste se hacen sobre pares reales en ContrastTests; la preferencia estética no sustituye esas pruebas.

## Componentes y dimensiones propuestas

- Carta: un marco exterior de 2pt, radio 18–20pt, sombra dura 3pt con opacidad 25%; eliminar el marco interior y la banda dominante en la variante recomendada.
- Ilustración: crecer dentro del espacio disponible, conservando silueta y nombre completo; referencia de catálogo 112–128pt, no tamaño fijo que bloquee Dynamic Type. El HTML agranda más la carta aislada para inspección y no prescribe una carta de 300pt en el catálogo.
- Título: SF Rounded semibold/bold sobre papel. Mantener estilos de texto nativos; no introducir reducciones nuevas de tipografía; el abanico conserva su altura fija actual de 164pt y `minimumScaleFactor(0.7)` cuando sean necesarios, verificando legibilidad y toque a tamaño real. La cuadrícula del catálogo crece con el texto, con filas completas y altura flexible.
- Encabezados: serif nativa `.largeTitle`/`.title`; instrucciones `.title2` como mínimo. HTML usa Georgia/system-ui para aproximar, no incluye una fuente nueva en la app.
- Acción principal: mínimo 100pt de altura; acento jade, nombre del juego cuando haga falta. Las cartas siguen siendo accesos directos, no decoración. Controles secundarios mínimo 60pt.
- Separación: 16–24pt entre regiones, 12–16pt entre cartas cuando no se use el reparto existente. No reducir objetivos para mostrar más contenido.
- Semana: siete ranuras; conservar orden del calendario local, cartas apiladas, señal de hoy y acceso al historial. Los días de la maqueta son ilustrativos; producción usa fechas reales.

## Estados que implementación debe cubrir

| Pantalla | Estado | Comportamiento requerido |
|---|---|---|
| Inicio | Día nuevo | Plan vigente visible; acción inicia el siguiente juego; cualquier carta inicia su juego |
| Inicio | Día parcial | Check en cada recomendación jugada, siguiente pendiente correcto, registro diario preservado |
| Inicio | Día completo | Mantener cierre del día y semana; no presentar terminado como pendiente |
| Inicio | Plan 2/3/5, ocultos, sin disponibles | Usar TodayRun/HandLayout existentes; no cambiar política; sin oclusión accidental de nombres o áreas de toque; el solapamiento intencional del abanico se conserva |
| Carta | Pendiente/completada | Check y etiqueta accesible; no depender sólo de color |
| Celebración | Partida intermedia | Siguiente juego correcto; volver y repetir conservan acceso |
| Celebración | Última partida | Cierre de día; no prometer siguiente inexistente |
| Celebración | Oferta de nivel | Aceptar o mantener disponibles; política intacta; prioridad visual secundaria |
| Todas | Oscuro/EN/ES/texto grande | Reflujo, contraste y contenido íntegro; capturas reales para certificar |

La maqueta de celebración muestra un estado intermedio de ejemplo. No implementa #583 ni demuestra todavía su comportamiento de oferta de nivel.

## Movimiento

Storyboard: llegada única de la carta → respuesta breve al toque → colocación en la semana al terminar. Acciones disponibles durante la entrada. Con Reduce Motion, mostrar estado final y marca sin desplazamiento ni rebote. Reutilizar comportamiento existente donde ya cumpla; no añadir animación periódica. El HTML presenta tres fotogramas estáticos: no es una grabación de animación validada.

## Copy de maqueta

| ES | EN | Estado |
|---|---|---|
| ¿Jugamos un rato? | Shall we play? | Mantener intención; revisar claves actuales |
| Tus juegos de hoy | Your games today | Ejemplo |
| Jugar ahora · Camino de Memoria | Play now · Memory Lane | Ejemplo; conservar nombre real del catálogo en implementación |
| ¡Qué buen rato! | That was lovely! | Ejemplo de celebración |
| Volver al inicio | Back to Home | Usar clave actual equivalente |

Los nombres ES de ejemplo del HTML no renombran juegos. La app conserva sus claves actuales y cualquier copy aprobado se añade EN/ES a Localizable.xcstrings en la PR correspondiente.

## Baseline y reproducibilidad

Commit de origen: `d53c28f042ef8c0ae1563619eaa32a1af036139c`. Build local-only de simulador con Xcode, esquema Ludavela; bundle `com.igmarin.MenteViva`. Dispositivos: iPhone 17 (72195EBD-F9B8-4648-839A-2EEBB6409F4A) e iPad Air 11 M4 (5B9ACF63-E565-4561-A1E9-DB265178D447), iOS 27. Capturas ES, tamaño de texto por defecto del dispositivo; modo claro salvo archivo `-dark` explícito. Barra de estado fijada a 9:41, batería100 para comparación.

Inicio: app sin modificar, lanzada con `-hasSeenOnboarding YES -appLanguage es`; no se borraron datos del usuario ni se usó un dispositivo físico. El plan real puede diferir de los juegos ficticios de las maquetas. La primera toma anticipada de SpringBoard se descartó y no sirve de evidencia.

Carta/celebración: fixture temporal de RootView que monta `GameCard(game: .memoryMatch)` y `CelebrationView(game: .memoryMatch, detail: "Encontraste todas las parejas.", onPlayAgain: {}, onNext: { _ in }, onHome: {})`. Componentes de producción intactos. No es una partida realmente completada ni una prueba de navegación. El fixture fue retirado; no forma parte del diff final.

## Evidencia y límites

Jev consultado realmente, respuesta `jev-1.14.0` en [023 request](../jev-json/023-visual-hierarchy.request.json) y [023 response](../jev-json/023-visual-hierarchy.response.json): recomienda refinar jerarquía y conservar paleta/comparar candidata. Es evidencia de criterio, no test de usabilidad; la elección del propietario se registra por separado.

Arte: reutiliza tetera, perro, manzana y girasol ya existentes en docs/design/art-samples. Su procedencia e incertidumbres permanecen en docs/art-prompts.md y docs/ip-clearance.md; esta exploración no afirma nueva autorización de uso. No se generó ni copió arte externo.

- [x] Tres maquetas aplicadas, variantes, matriz de referencias, estados y storyboard.
- [x] Juicio Jev real archivado.
- [x] Elección del propietario: crema actual, mesa jade plana, títulos sobre crema y abanico conservado; no aprueba las demás composiciones.
- [ ] Prueba de uso con participantes y dispositivos físicos: corresponde a #586.
- [ ] Validación integrada definitiva de #580/#581: responsabilidad de sus PRs y revisión principal.

Siguiente paso: revisar el comparador y las capturas de implementación #580/#581 manteniendo las interacciones solicitadas; validar las composiciones y la implementación pendientes.
