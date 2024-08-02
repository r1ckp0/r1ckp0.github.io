"Escenas I" para violin y cinta es la primera obra que voy a entregar para ser evaluada.

El violinista tocara por encima de archivos de audio que se difundiran a la sala.

Los sonidos estan generados en SC y tambien he utilizado una grabacion en crudo. He colocado los codigos que he ido utilizando en una subcarpeta, la grabacion en crudo la he colocado en "capturas del secuenciador". Para replicar los sonidos tal cual estan en la obra seria necesario manipular un poco los códigos (alturas y duraciones principalmente), pero los núcleos de los sonidos se encuentran en los archivos.

Los sonidos grabados (y muchas veces también secuenciados) de SuperCollider ha sido colocados en un secuenciador para montarlos y mezclarlos. He aplicado compresion, reverb y ecualizacion con bastante moderacion. He intentado hacerlo mayoritariamente por buses. El unico efecto mas raro es un Spectral Gate, que en la mezcla podria confundirse con un filtro pasabajos, pero consigue una textura curiosa, solo fue usada para un sonido. Para el master he aplicado reverb, clipping y un limitador. Hay algunas capturas del secuenciador en la carpeta correspondiente.

Para la interpretacion utilizare SC como reproductor de archivos de audio y lo controlare con MobMuPlat, una aplicacion para moviles en la que puedes tener layouts personalizados y funciona internamente con PD. Estan los patches de MMP y SC en la carpeta "materiales para la interpretacion", pero basicamente MMP manda mensajes OSC de tipo boton (valores 0 y 1: 1 cuando se pulsa, 0 cuando se suelta) a SC con etiquetas que he definido previamente y las cuales son recibidas por los OSCdefs que ejecutaran una funcion cuando el valor de la etiqueta correspondiente sea 1. Incluyo la partitura en PDF, notas para el interprete y el rider tecnico. Seran necesarios los renders de audio, ubicados en otra subcapeta.

Los renders de audio son las partes de la cinta ya terminadas. La obra esta dividida en dos movimientos, el primer archivo le corresponde al primer movimiento, y los otros dos al segundo. La duracion aproximada es entre 7 y 8 minutos, dependiendo de la agogica del interprete. Hay informacion mas detallada sobre la interpretacion en las notas para el interprete y en el rider tecnico.


