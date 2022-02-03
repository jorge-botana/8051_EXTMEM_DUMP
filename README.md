# 8051_EXTMEM_DUMP

Volcado de una memoria externa de hasta 64 KB conectada a un microcontrolador de
la familia MCS-51.

## Funcionamiento

Al accionar un pulsador normalmente abierto posicionado entre el pin P3.4/T0 del
microcontrolador y masa, se transmite por el puerto serie el contenido de una
zona de la memoria externa, siguiendo el siguiente esquema (sin el dibujo):

``0x0000: XX XX XX XX XX XX XX XX   Y Y Y Y Y Y Y Y   -------¡   __!__      ``  
``0x0008: XX XX XX XX XX XX XX XX   Y Y Y Y Y Y Y Y   P3.4/T0|--o     o--¡  ``  
``0x0010: XX XX XX XX XX XX XX XX   Y Y Y Y Y Y Y Y   -------!           |  ``  
``...                                                                    |  ``  
``0xFFE8: XX XX XX XX XX XX XX XX   Y Y Y Y Y Y Y Y                    -----``  
``0xFFF0: XX XX XX XX XX XX XX XX   Y Y Y Y Y Y Y Y                     --- ``  
``0xFFF8: XX XX XX XX XX XX XX XX   Y Y Y Y Y Y Y Y                      -  ``  

Donde se representa el valor HEX (XX) y ASCII (Y) de cada byte, indicando al
comienzo de cada fila la dirección del primer byte que muestra (el offset).

Cuando se recibe un carácter '1' por el puerto serie ya no se hace caso al
pulsador. El funcionamiento normal se recupera al recibir un carácter '2' por el
puerto serie.

## Configuración

Se han de establecer los siguientes parámetros al comienzo del archivo que
contiene el código fuente ``8051_EXTMEM_DUMP.asm``:

 - Dirección inicial del volcado
 - Número total de bytes volcados
 - Número de bytes representados en cada fila
 - Tipo de memoria externa (RAM o ROM)
 - Escritura inicial de un mensaje en la memoria externa (solo si es una RAM)
 - Cantidad de memoria ROM interna que tiene el microcontrolador

El oscilador ha de ser de 11,0592 MHz para el correcto funcionamiento de la
UART, que cuenta con la siguiente configuración:

 - Baudrate de 9600
 - 8 bits de datos
 - Sin bit de paridad
 - 1 bit de stop
 - Sin control de flujo

El oscilador también ha de tener la frecuencia indicada para funcione
correctamente el mecanismo antirrebotes que incluye el programa.

NOTA: Si se vuelca una memoria ROM externa, solo se podrá acceder a aquellas
      direcciones de memoria no disponibles en la memoria ROM interna del
      microcontrolador.

## Ensamblado

El binario se obtiene tras ensamblar el código fuente con un software como el
A51 (incluido en Keil uVision) o el ASEM-51 (incluido en Proteus).

## Demostración

Se adjuntan dos ejemplos de funcionamiento (uno por cada tipo de memoria
externa) con los siguientes circuitos integrados:

 - Microcontrolador MCS-51 AT89C52
 - Latch de 8 bits 74HC573
 - Memoria RAM externa 62256
 - Memoria ROM externa 27512

Se ha usado el software Proteus para realizar simulaciones. Al volcar una
memoria ROM externa, se debe cargar en ella una imagen binaria (se adjunta una
creada con el editor hexadecimal HxD, con un mensaje que comienza en la
dirección 0x8000) y además se debe activar en el microcontrolador la propiedad
avanzada de Proteus "Simulate Program Fetches". 

## Licencia

Este repositorio se distribuye bajo los términos de la licencia MIT, que se
encuentra en el archivo ``LICENSE.txt``.
