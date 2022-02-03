;-------------------------------------------------------------------------------
; 8051_EXTMEM_DUMP
;
; - Fichero que contiene el código fuente del programa.
;
;-------------------------------------------------------------------------------
; Copyright (c) 2022 Jorge Botana Mtz. de Ibarreta
;
; Este archivo se encuentra bajo los términos de la Licencia MIT. Debería
; haberse proporcionado una copia de ella junto a este fichero. Si no es así, se
; puede encontrar en el siguiente enlace:
;
;                                            https://opensource.org/licenses/MIT
;-------------------------------------------------------------------------------

;---------------------------------- SÍMBOLOS -----------------------------------

;-------------------------------------------------------------------------------
; Parámetros de configuración.
;-------------------------------------------------------------------------------

INIT_ADDR   EQU      0000h              ; Dirección de la memoria externa a
                                        ; partir de la cual se va a realizar el
                                        ; volcado.

N_BYTES     EQU       512               ; Número total de bytes que se van a
                                        ; volcar de la memoria externa. En caso
                                        ; de que se vayan a volcar los 64 KB,
                                        ; (65536 bytes), ha de introducirse un
                                        ; 0.

N_COLS      EQU        16               ; Número de bytes volcados que se van a
                                        ; representar en cada fila (máximo 99).

IS_RAM      EQU         1               ; Valor que especifica si la memoria
                                        ; externa es una RAM (1) o una ROM (0).

TEST_MODE   EQU         1               ; Valor que especifica, en caso de que
                                        ; la memoria externa sea una RAM, si el
                                        ; programa va a copiar en ella (1) o no
                                        ; (0) el mensaje de pruebas a partir de
                                        ; de la misma dirección donde va a
                                        ; comenzar el volcado.

UC_ROM      EQU      2000h              ; Valor que especifica, en caso de que
                                        ; la memoria externa sea una ROM, cual
                                        ; es su primera dirección accesible por
                                        ; el microcontrolador usado, determinada
                                        ; por la cantidad de memoria ROM interna
                                        ; que contiene este (esto se debe a que,
                                        ; estando a nivel alto el pin de acceso
                                        ; externo, los accesos a memoria de
                                        ; código se llevan a cabo dentro de la
                                        ; memoria ROM interna, a menos que la
                                        ; dirección accedida no exista dentro de
                                        ; la memoria ROM interna, en cuyo caso
                                        ; se accede a esa misma dirección en la
                                        ; memoria ROM externa).

;-------------------------------------------------------------------------------
; Definiciones adicionales.
;-------------------------------------------------------------------------------

BUFF        EQU        0Fh              ; Dirección inicial del puntero usado
                                        ; para almacenar temporalmente en la
                                        ; memoria RAM interna (en un buffer) los
                                        ; caracteres ASCII de una fila, para
                                        ; transmitirlos por el puerto serie a
                                        ; continuación de los caracteres HEX (se
                                        ; usan registros situados entre 00h y
                                        ; 07h, y la pila siempre va a caber
                                        ; entre 08h y 0Fh, pudiendo guardar los
                                        ; caracteres ASCII a continuación).

END_ADDR    EQU     INIT_ADDR + N_BYTES ; Dirección de la memoria externa donde
                                        ; finaliza el volcado.

;-------------------------------------------------------------------------------
; Comprobación de errores de configuración (precaución, algunos ensambladores
; aceptan valores de más de dos bytes, pero luego solo evalúan los dos últimos,
; interpretando por ejemplo un 65540 como un 4, y por esa razón con estos
; ensambladores no se puede comprobar en el programa si se introdujo
; erróneamente un valor superior a 65535, mientras que con otros ensambladores
; no es necesario hacerlo porque se generaría un error en el momento en el que
; se declara un símbolo con un valor prohibido).
;-------------------------------------------------------------------------------

IF      N_COLS < 1 OR N_COLS > 99
__ERROR__ "N_COLS must be between 1 and 99."
ENDIF ; N_COLS < 1 OR N_COLS > 99

IF      IS_RAM <> 0 AND IS_RAM <> 1
__ERROR__ "IS_RAM must be 0 or 1."
ENDIF ; IS_RAM <> 0 AND IS_RAM <> 1

IF      TEST_MODE <> 0 AND TEST_MODE <> 1
__ERROR__ "TEST_MODE must be 0 or 1."
ENDIF ; TEST_MODE <> 0 AND TEST_MODE <> 1

IF      INIT_ADDR > END_ADDR - 1
__ERROR__ "Overflows are not allowed (from 0xFFFF to 0x0000)."
ENDIF ; INIT_ADDR > END_ADDR - 1 

IF      INIT_ADDR < UC_ROM AND IS_RAM = 0
__ERROR__ "Unaddressable external ROM address."
ENDIF ; INIT_ADDR < UC_ROM AND IS_RAM = 0

;-------------------------------------------------------------------------------
; Caracteres HEX correspondientes a los dígitos de la dirección de la memoria
; externa a partir de la cual se va a realizar el volcado.
;-------------------------------------------------------------------------------

IF                  INIT_ADDR                                      /  4096 < 10
A_4096      EQU     INIT_ADDR                                      /  4096 + '0'
ELSE         ;      INIT_ADDR                                      /  4096 < 10
A_4096      EQU     INIT_ADDR                                      /  4096 + '7'
ENDIF        ;      INIT_ADDR                                      /  4096 < 10

IF                 (INIT_ADDR           MOD 4096)                  /   256 < 10
A_256       EQU    (INIT_ADDR           MOD 4096)                  /   256 + '0'
ELSE         ;     (INIT_ADDR           MOD 4096)                  /   256 < 10
A_256       EQU    (INIT_ADDR           MOD 4096)                  /   256 + '7'
ENDIF        ;     (INIT_ADDR           MOD 4096)                  /   256 < 10

IF                ((INIT_ADDR           MOD 4096) MOD 256)         /    16 < 10
A_16        EQU   ((INIT_ADDR           MOD 4096) MOD 256)         /    16 + '0'
ELSE         ;    ((INIT_ADDR           MOD 4096) MOD 256)         /    16 < 10
A_16        EQU   ((INIT_ADDR           MOD 4096) MOD 256)         /    16 + '7'
ENDIF        ;    ((INIT_ADDR           MOD 4096) MOD 256)         /    16 < 10

IF               (((INIT_ADDR           MOD 4096) MOD 256) MOD 16) /     1 < 10
A_1         EQU  (((INIT_ADDR           MOD 4096) MOD 256) MOD 16) /     1 + '0'
ELSE         ;   (((INIT_ADDR           MOD 4096) MOD 256) MOD 16) /     1 < 10
A_1         EQU  (((INIT_ADDR           MOD 4096) MOD 256) MOD 16) /     1 + '7'
ENDIF        ;   (((INIT_ADDR           MOD 4096) MOD 256) MOD 16) /     1 < 10

;-------------------------------------------------------------------------------
; Caracteres DEC correspondientes a los dígitos del número total de bytes que se
; van a volcar de la memoria externa.
;-------------------------------------------------------------------------------

B_10K       EQU      N_BYTES                                       / 10000 + '0'
B_1K        EQU     (N_BYTES MOD 10000)                            /  1000 + '0'
B_100       EQU    ((N_BYTES MOD 10000) MOD 1000)                  /   100 + '0'
B_10        EQU   (((N_BYTES MOD 10000) MOD 1000) MOD 100)         /    10 + '0'
B_1         EQU  ((((N_BYTES MOD 10000) MOD 1000) MOD 100) MOD 10) /     1 + '0'

;-------------------------------------------------------------------------------
; Caracteres DEC correspondientes a los dígitos del número de bytes volcados que
; se van a representar en cada fila.
;-------------------------------------------------------------------------------

C_10        EQU   (((N_COLS  MOD 10000) MOD 1000) MOD 100)         /    10 + '0'
C_1         EQU  ((((N_COLS  MOD 10000) MOD 1000) MOD 100) MOD 10) /     1 + '0'

;----------------------------- PROGRAMA PRINCIPAL ------------------------------

;-------------------------------------------------------------------------------
; Inicializa el programa:
;
; - Copia el mensaje de pruebas a la memoria externa, en caso de que sea una RAM
;   y que esta operación esté habilitada.
;
; - Configura los periféricos (los temporizadores / contadores y el puerto
;   serie).
;
; - Transmite por el puerto serie los mensajes iniciales que muestran la
;   configuración actual del programa.
;
; - Realiza en el lazo sin fin un polling de las banderas usadas para que,
;   cuando sean activadas, se lleven a cabo sus tareas asociadas (deshabilitar o
;   habilitar el pulsador y volcar la memoria externa).
;-------------------------------------------------------------------------------

IF      IS_RAM = 1 AND TEST_MODE = 1

STR_COPY:

    MOV DPTR,#TEST_MSG                  ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje de pruebas.

    MOV R7,DPH                          ; Guarda en R7 el DPH del DPTR, que
                                        ; contiene el MSB de la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje de pruebas.

    MOV R6,DPL                          ; Guarda en R6 el DPL del DPTR, que
                                        ; contiene el LSB de la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje de pruebas.

    MOV DPTR,#INIT_ADDR                 ; Carga en el DPTR la dirección de la
                                        ; memoria RAM externa a partir de la
                                        ; cual se va a copiar el mensaje de
                                        ; pruebas.

    MOV R5,DPH                          ; Guarda en R5 el DPH del DPTR, que
                                        ; contiene el MSB de la dirección de la
                                        ; memoria RAM externa a partir de la
                                        ; cual se va a copiar el mensaje de
                                        ; pruebas.

    MOV R4,DPL                          ; Guarda en R4 el DPL del DPTR, que
                                        ; contiene el LSB de la dirección de la
                                        ; memoria RAM externa a partir de la
                                        ; cual se va a copiar el mensaje de
                                        ; pruebas.

CHAR_COPY:

    MOV DPH,R7                          ; Restaura de R7 al DPH del DPTR el MSB
                                        ; de la dirección de la memoria de
                                        ; código del carácter actual del mensaje
                                        ; de pruebas que se va a copiar a la
                                        ; memoria RAM externa.

    MOV DPL,R6                          ; Restaura de R6 al DPL del DPTR el LSB
                                        ; de la dirección de la memoria de
                                        ; código del carácter actual del mensaje
                                        ; de pruebas que se va a copiar a la
                                        ; memoria RAM externa.

    CLR A                               ; Borra el acumulador para apuntar al
                                        ; carácter correcto en la siguiente
                                        ; instrucción.

    MOVC A,@A+DPTR                      ; Copia al acumulador el carácter actual
                                        ; del mensaje de pruebas.

    INC DPTR                            ; Incrementa el DPTR para apuntar al
                                        ; siguiente carácter del mensaje de
                                        ; pruebas en la memoria de código.

    MOV R7,DPH                          ; Guarda en R7 el DPH del DPTR, que
                                        ; contiene el MSB de la dirección de la
                                        ; memoria de código del siguiente
                                        ; carácter del mensaje de pruebas que se
                                        ; va a copiar a la memoria RAM externa.

    MOV R6,DPL                          ; Guarda en R6 el DPL del DPTR, que
                                        ; contiene el LSB de la dirección de la
                                        ; memoria de código del siguiente
                                        ; carácter del mensaje de pruebas que se
                                        ; va a copiar a la memoria RAM externa.

    MOV DPH,R5                          ; Restaura de R5 al DPH del DPTR el MSB
                                        ; de la dirección de la memoria RAM
                                        ; externa donde se va a copiar el
                                        ; carácter actual del mensaje de
                                        ; pruebas.

    MOV DPL,R4                          ; Restaura de R4 al DPL del DPTR el LSB
                                        ; de la dirección de la memoria RAM
                                        ; externa donde se va a copiar el
                                        ; carácter actual del mensaje de
                                        ; pruebas.

    MOVX @DPTR,A                        ; Copia a la memoria RAM externa el
                                        ; carácter actual del mensaje de
                                        ; pruebas, contenido en el acumulador.

    INC DPTR                            ; Incrementa el DPTR para apuntar adonde
                                        ; se copiará en la memoria RAM externa
                                        ; el siguiente carácter del mensaje de
                                        ; pruebas.

    MOV R5,DPH                          ; Guarda en R5 el DPH del DPTR, que
                                        ; contiene el MSB de la dirección de la
                                        ; memoria RAM externa donde se va copiar
                                        ; el siguiente carácter del mensaje de
                                        ; pruebas.

    MOV R4,DPL                          ; Guarda en R4 el DPL del DPTR, que
                                        ; contiene el LSB de la dirección de la
                                        ; memoria RAM externa donde se va copiar
                                        ; el siguiente carácter del mensaje de
                                        ; pruebas.

    CJNE A,#0,CHAR_COPY                 ; Repite el ciclo hasta copiar todos los
                                        ; caracteres del mensaje de pruebas, es
                                        ; decir, hasta leer el 0 que marca el
                                        ; final de la cadena de caracteres.

ENDIF ; IS_RAM = 1 AND TEST_MODE = 1

PERIPHERALS_SETUP:

    MOV TMOD,#00100110B                 ; Configura los temporizadores /
                                        ; contadores en modo 2 (8 bits con
                                        ; autorrecarga), el 0 como contador
                                        ; (usado por el pulsador, conectado al
                                        ; pin de entrada externa P3.4/T0) y el 1
                                        ; como temporizador (usado para generar
                                        ; el baudrate del puerto serie).

    MOV TH0,#-1                         ; Establece el valor de recarga del
                                        ; contador para que, al accionar el
                                        ; pulsador una sola vez, se active
                                        ; automáticamente la bandera de
                                        ; desbordamiento y se lleve a cabo el
                                        ; proceso de volcado de la memoria
                                        ; externa.

    MOV TL0,#-1                         ; Recarga manualmente el contador (solo
                                        ; es necesario hacerlo la primera vez,
                                        ; ya que cuenta con autorrecarga).

    MOV TH1,#-3                         ; Establece el valor de recarga del
                                        ; temporizador para obtener un baudrate
                                        ; de 9600 para el puerto serie.

    MOV TL1,#-3                         ; Recarga manualmente el temporizador
                                        ; (solo es necesario hacerlo la primera
                                        ; vez, ya que cuenta con autorrecarga).

    SETB TR0                            ; Habilita la ejecución del contador,
                                        ; para que incremente su cuenta al
                                        ; detectar un flanco de bajada en
                                        ; P3.4/T0, al accionar el pulsador.

    SETB TR1                            ; Habilita la ejecución del
                                        ; temporizador, comenzando la
                                        ; generación del baudrate del puerto
                                        ; serie.

    MOV SCON,#01010000B                 ; Configura el puerto serie en modo 1
                                        ; (UART de 8 bits) con el receptor
                                        ; habilitado.

INITIALIZATION:

    MOV DPTR,#SETUP_MSG                 ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que muestra la configuración
                                        ; actual del programa.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje que muestra la configuración
                                        ; actual del programa.

    MOV DPTR,#ADDR_MSG                  ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que muestra la dirección de la
                                        ; memoria externa a partir de la cual se
                                        ; va a realizar el volcado.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje que muestra la dirección de la
                                        ; memoria externa a partir de la cual se
                                        ; va a realizar el volcado.

    MOV DPTR,#BYTES_MSG                 ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que muestra el número total de
                                        ; bytes que se van a volcar de la
                                        ; memoria externa.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje que muestra el número total de
                                        ; bytes que se van a volcar de la
                                        ; memoria externa.

    MOV DPTR,#COLS_MSG                  ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que muestra el número de bytes
                                        ; volcados que se van a representar en
                                        ; cada fila.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje que muestra el número de bytes
                                        ; volcados que se van a representar en
                                        ; cada fila.

    MOV DPTR,#TYPE_MSG                  ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que especifica si la memoria
                                        ; externa es una RAM o una ROM.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje que especifica si la memoria
                                        ; externa es una RAM o una ROM.

IF      IS_RAM = 1

    MOV DPTR,#MODE_MSG                  ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que especifica si el programa
                                        ; ha copiado o no el mensaje de pruebas
                                        ; en la memoria RAM externa.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje que especifica si el programa
                                        ; ha copiado o no el mensaje de pruebas
                                        ; en la memoria RAM externa.

ENDIF ; IS_RAM = 1

    MOV DPTR,#READY_MSG                 ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que indica que el programa ya
                                        ; se ha inicializado.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje que indica que el programa ya
                                        ; se ha inicializado.

    ACALL CRLF_TX                       ; Transmite por el puerto serie una
                                        ; nueva línea adicional.

INFINITELY_LOOP:

    JB RI,CHAR_RX                       ; Inspecciona el estado de la bandera
                                        ; del puerto serie que se activa cuando
                                        ; se recibe un carácter, para
                                        ; posteriormente llevar a cabo la
                                        ; deshabilitación o habilitación del
                                        ; pulsador.

    JB TF0,EXTMEM_DUMP                  ; Inspecciona el estado de la bandera de
                                        ; desbordamiento del contador que se
                                        ; activa automáticamente cuando el
                                        ; pulsador es accionado, para
                                        ; posteriormente llevar a cabo el
                                        ; volcado de la memoria externa.

    SJMP INFINITELY_LOOP                ; Repite en bucle el lazo sin fin.

;-------------------------------------------------------------------------------
; Deshabilita o habilita el pulsador, si corresponde.
;-------------------------------------------------------------------------------

CHAR_RX:

    MOV A,SBUF                          ; Copia al acumulador el carácter
                                        ; recibido por el puerto serie,
                                        ; contenido en el SBUF.

    JNB TR0,ENABLE                      ; Inspecciona el estado de la bandera de
                                        ; habilitación del contador para
                                        ; determinar si el pulsador está
                                        ; deshabilitado o habilitado. Si está
                                        ; deshabilitado, el programa sigue en la
                                        ; siguiente instrucción para habilitar
                                        ; el pulsador si se ha recibido un
                                        ; carácter '2' por el puerto serie,
                                        ; mientras que si está habilitado el
                                        ; programa salta a la instrucción a
                                        ; partir de la cual se deshabilita el
                                        ; pulsador si se ha recibido un carácter
                                        ; '1' por el puerto serie.

DISABLE:

    CJNE A,#'1',RETURN                  ; Comprueba si se ha recibido un
                                        ; carácter '1' por el puerto serie. Si
                                        ; es así, se deshabilita el pulsador, y
                                        ; de no ser así se salta este proceso,
                                        ; al omitir las siguientes
                                        ; instrucciones.

    CLR TR0                             ; Deshabilita el pulsador al desactivar
                                        ; la bandera de habilitación del
                                        ; contador.

    MOV DPTR,#DIS_MSG                   ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que notifica de que el
                                        ; pulsador ha sido deshabilitado.

    SJMP NOTIFY                         ; Salta a la instrucción que notifica de
                                        ; los cambios.

ENABLE:

    CJNE A,#'2',RETURN                  ; Comprueba si se ha recibido un
                                        ; carácter '2' por el puerto serie. Si
                                        ; es así, se habilita el pulsador, y de
                                        ; no ser así se salta este proceso, al
                                        ; omitir las siguientes instrucciones.

    SETB TR0                            ; Habilita el pulsador al activar la
                                        ; bandera de habilitación del contador.

    MOV DPTR,#EN_MSG                    ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje que notifica de que el
                                        ; pulsador ha sido habilitado.

NOTIFY:

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje que notifica de que el
                                        ; pulsador ha sido deshabilitado o
                                        ; habilitado.

    ACALL CRLF_TX                       ; Transmite por el puerto serie una
                                        ; nueva línea adicional.

RETURN:

    CLR RI                              ; Desactiva manualmente la bandera de
                                        ; recepción del puerto serie para que
                                        ; las instrucciones anteriores no se
                                        ; ejecuten de nuevo tras regresar al
                                        ; lazo sin fin, a menos que se reciba
                                        ; otro carácter.

    AJMP INFINITELY_LOOP                ; Regresa al lazo sin fin.

;-------------------------------------------------------------------------------
; Realiza el volcado de la memoria externa al accionar el pulsador y luego
; espera a que este vuelva a la posición de reposo (es decir, sin accionar)
; antes de regresar a lazo sin fin, evitando de esa forma que se repita el
; proceso sin accionar el pulsador nuevamente, debido a los rebotes. Para ello
; se hace uso de un mecanismo antirrebotes que funciona realizando un muestreo
; cada 2 milisegundos (aproximadamente) del nivel del tensión del pin al que
; está conectado el pulsador (P3.4/T0), no finalizando hasta que detecte 8 veces
; seguidas un nivel de tensión alto (para que hayan desaparecido los rebotes).
;
; Delay de 2 milisegundos por software (con un oscilador de 11,0592 MHz):
;
; T_osc_cyc = 1 /  f_osc_cyc                    =
;           = 1 / [11,0592 * 10^6 (Hz*osc_cyc)] = 9,04 * 10^(-8) (s/osc_cyc)
;
; T_mch_cyc = 12 (osc_cyc/mch_cyc) * T_osc_cyc                  =
;           = 12 (osc_cyc/mch_cyc) * 9,04 * 10^(-8) (s/osc_cyc) = 1,08 * 10^(-6)
;                                                                    (s/mch_cyc)
;
; N_mch_cyc = 2 * 10^(-3) (s/del) / T_mch_cyc                  =
;           = 2 * 10^(-3) (s/del) / 1,08 * 10^(-6) (s/mch_cyc) = 1843,2
;                                                                  (mch_cyc/del)
;-------------------------------------------------------------------------------

EXTMEM_DUMP:

    MOV DPTR,#HEADER_MSG                ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje inicial del volcado de la
                                        ; memoria externa.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje inicial del volcado de la
                                        ; memoria externa.

    MOV DPTR,#INIT_ADDR                 ; Carga en el DPTR la dirección de la
                                        ; memoria externa a partir de la cual va
                                        ; a llevarse cabo el volcado.

ROW_TX:

    MOV R0,#BUFF                        ; Copia a R0 la dirección inicial del
                                        ; puntero que almacena temporalmente en
                                        ; un buffer en la memoria RAM interna
                                        ; los caracteres ASCII de la fila
                                        ; actual, para transmitirlos por el
                                        ; puerto serie a continuación de los
                                        ; caracteres HEX.

    MOV A,#'0'                          ; Copia al acumulador el carácter '0'.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter '0'.

    MOV A,#'x'                          ; Copia al acumulador el carácter 'x'.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter 'x'.

OFFSET_MSB_TX:

    MOV A,DPH                           ; Copia al acumulador el DPH del DPTR,
                                        ; que contiene el MSB de la dirección de
                                        ; offset de la fila actual.

    ACALL BYTE_TX                       ; Transmite por el puerto serie el MSB
                                        ; de la dirección de offset de la fila
                                        ; actual tras convertir sus nibbles a
                                        ; caracteres HEX (p.e. 4Ah -> '4A').

OFFSET_LSB_TX:

    MOV A,DPL                           ; Copia al acumulador el DPL del DPTR,
                                        ; que contiene el LSB de la dirección de
                                        ; offset de la fila actual.

    ACALL BYTE_TX                       ; Transmite por el puerto serie el LSB
                                        ; de la dirección de offset de la fila
                                        ; actual tras convertir sus nibbles a
                                        ; caracteres HEX (p.e. 07h -> '07').

    MOV A,#':'                          ; Copia al acumulador el carácter ':'.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter ':'.

HEX_STR_TX:

    ACALL BLANK_TX                      ; Transmite por el puerto serie un
                                        ; espacio en blanco para mantener una
                                        ; separación entre los bytes volcados.

    INC R0                              ; Incrementa R0 para almacenar el
                                        ; carácter ASCII actual en la siguiente
                                        ; posición del buffer.

    JNB F0,HEX_CHAR_TX                  ; Inspecciona la bandera que se activa
                                        ; cuando se vuelca el último byte
                                        ; deseado. Si está desactivada, el
                                        ; programa continúa volcando el
                                        ; siguiente byte, mientras que en caso
                                        ; contrario rellena con espacios en
                                        ; blanco el espacio restante de la
                                        ; última fila.

    ACALL BLANK_TX                      ; Transmite por el puerto serie un
                                        ; espacio en blanco en la posición
                                        ; donde iría el primer carácter HEX de
                                        ; un byte volcado.

    ACALL BLANK_TX                      ; Transmite por el puerto serie un
                                        ; espacio en blanco en la posición
                                        ; donde iría el segundo carácter HEX de
                                        ; un byte volcado.

    MOV @R0,A                           ; Guarda en el buffer el carácter del
                                        ; espacio en blanco que fue almacenado
                                        ; en el acumulador en la instrucción
                                        ; anterior.

    SJMP ASCII_STR_TX                   ; Salta las siguientes instrucciones.

HEX_CHAR_TX:

IF      IS_RAM = 1

    MOVX A,@DPTR                        ; Copia al acumulador el byte actual
                                        ; volcado de la memoria RAM externa.

ELSE  ; IS_RAM = 1

    CLR A                               ; Borra el acumulador para apuntar al
                                        ; carácter correcto en la siguiente
                                        ; instrucción.

    MOVC A,@A+DPTR                      ; Copia al acumulador el byte actual
                                        ; volcado de la memoria ROM externa.

ENDIF ; IS_RAM = 1

    MOV @R0,A                           ; Guarda en el buffer el byte actual
                                        ; volcado.

    ACALL BYTE_TX                       ; Transmite por el puerto serie los
                                        ; caracteres HEX correspondientes al
                                        ; byte actual volcado.

    INC DPTR                            ; Incrementa el DPTR para apuntar al
                                        ; siguiente byte de la memoria externa.

    MOV A,DPH                           ; Copia al acumulador el DPH del DPTR,
                                        ; que contiene el MSB de la dirección de
                                        ; la memoria externa que contiene el
                                        ; siguiente byte que se va a volcar.

    CJNE A,#HIGH(END_ADDR),ASCII_STR_TX ; Salta las siguientes instrucciones si
                                        ; se sabe con certeza que no se han
                                        ; volcado todos los bytes deseados.

    MOV A,DPL                           ; Copia al acumulador el DPL del DPTR,
                                        ; que contiene el LSB de la dirección de
                                        ; la memoria externa que contiene el
                                        ; siguiente byte que se va a volcar.

    CJNE A,#LOW(END_ADDR),ASCII_STR_TX  ; Salta la siguiente instrucción si no
                                        ; se han volcado todos los bytes
                                        ; deseados.

    SETB F0                             ; Activa una bandera si ya se ha
                                        ; volcado el último byte. Por ejemplo,
                                        ; si se van a volcar los primeros 256
                                        ; bytes, se vuelcan los bytes desde el 0
                                        ; hasta el 255, ambos incluidos, y este
                                        ; último es el 00FFh. Al incrementar el
                                        ; DPTR pasa a valer 0100h = 256, que
                                        ; corresponde al 257avo byte, que no se
                                        ; va a llegar a volcar porque se llega
                                        ; a este punto, donde se activa la
                                        ; bandera.

ASCII_STR_TX:

    CJNE R0,#BUFF+N_COLS,HEX_STR_TX     ; Repite el ciclo hasta completar la
                                        ; fila actual.

    ACALL BLANK_TX                      ; Transmite por el puerto serie un
                                        ; primer espacio en blanco para separar
                                        ; los caracteres HEX de los ASCII.

    ACALL BLANK_TX                      ; Transmite por el puerto serie un
                                        ; segundo espacio en blanco para separar
                                        ; los caracteres HEX de los ASCII.

    ACALL BLANK_TX                      ; Transmite por el puerto serie un
                                        ; tercer espacio en blanco para separar
                                        ; los caracteres HEX de los ASCII.

    ACALL BLANK_TX                      ; Transmite por el puerto serie un
                                        ; cuarto espacio en blanco para separar
                                        ; los caracteres HEX de los ASCII.

    MOV R0,#BUFF                        ; Restaura R0 a la posición inicial
                                        ; para, en la siguiente instrucción,
                                        ; apuntar al primer carácter ASCII
                                        ; almacenado.

ASCII_CHAR_TX:

    INC R0                              ; Incrementa R0 para restaurar el
                                        ; siguiente carácter ASCII almacenado.

    MOV A,@R0                           ; Restaura el carácter ASCII copiándolo
                                        ; al acumulador.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter ASCII restaurado.

    ACALL BLANK_TX                      ; Transmite por el puerto serie un
                                        ; espacio en blanco para mantener una
                                        ; separación con el siguiente carácter
                                        ; ASCII.

    CJNE R0,#BUFF+N_COLS,ASCII_CHAR_TX  ; Repite el ciclo hasta completar la
                                        ; fila.

    ACALL CRLF_TX                       ; Transmite por el puerto serie una
                                        ; nueva línea.

    JNB F0,ROW_TX                       ; Comprueba si la fila que se acaba de
                                        ; transmitir por el puerto serie era la
                                        ; última, para repetir el ciclo con la
                                        ; siguiente fila en caso de que no fuera
                                        ; así.

    CLR F0                              ; Borra la bandera tras terminar el
                                        ; volcado de la memoria externa. 

DEBOUNCE:

    MOV R3,#0                           ; Inicializa el contador de software del
                                        ; mecanismo antirrebotes del pulsador.

DELAY:

    MOV R7,#255                         ; Ejecuta 1 *   1 =   1 ciclo . N =    1

    MOV R6,#255                         ; Ejecuta 1 *   1 =   1 ciclo . N =    2

    MOV R5,#255                         ; Ejecuta 1 *   1 =   1 ciclo . N =    3

    MOV R4,#155                         ; Ejecuta 1 *   1 =   1 ciclo . N =    4

    DJNZ R7,$                           ; Ejecuta 2 * 255 = 510 ciclos. N =  514

    DJNZ R6,$                           ; Ejecuta 2 * 255 = 510 ciclos. N = 1024

    DJNZ R5,$                           ; Ejecuta 2 * 255 = 510 ciclos. N = 1534

    DJNZ R4,$                           ; Ejecuta 2 * 155 = 310 ciclos. N = 1844

    JB T0,INCREASE                      ; Lee el pin P3.4/T0 para, en función de
                                        ; su nivel de tensión, incrementar o
                                        ; reiniciar el contador de software.

    SJMP DEBOUNCE                       ; Reinicia el mecanismo antirrebotes si
                                        ; se lee un nivel bajo de tensión
                                        ; (pulsador accionado).

INCREASE:

    INC R3                              ; Incrementa el contador de software si
                                        ; se lee un nivel alto de tensión
                                        ; (pulsador sin accionar).

    CJNE R3,#8,DELAY                    ; Repite el ciclo hasta que se detecte
                                        ; un nivel alto de tensión por octava
                                        ; vez consecutiva, momento para el cual
                                        ; habrán desaparecido los rebotes tras
                                        ; haber soltado el pulsador.

FINALIZE:

    ACALL CRLF_TX                       ; Transmite por el puerto serie una
                                        ; nueva línea adicional.

    MOV DPTR,#FOOTER_MSG                ; Carga en el DPTR la dirección de la
                                        ; memoria de código donde comienza el
                                        ; mensaje final del volcado de la
                                        ; memoria externa.

    ACALL STR_TX                        ; Transmite por el puerto serie el
                                        ; mensaje final del volcado de la
                                        ; memoria externa.

    ACALL CRLF_TX                       ; Transmite por el puerto serie una
                                        ; nueva línea adicional.

    CLR TF0                             ; Desactiva manualmente la bandera de
                                        ; desbordamiento del contador para que
                                        ; las instrucciones anteriores no se
                                        ; ejecuten de nuevo tras regresar al
                                        ; lazo sin fin, a menos que el pulsador
                                        ; vuelva a ser accionado.

    AJMP INFINITELY_LOOP                ; Regresa al lazo sin fin.

;--------------------------------- SUBRUTINAS ----------------------------------

;-------------------------------------------------------------------------------
; Transmite por el puerto serie los caracteres HEX correspondientes a un byte
; contenido en el acumulador. Por ejemplo:
;
; <-  6A                                  Entrada (un byte)
;
; B = 6A                                  MOV B,A
; A = A6                                  SWAP A
; A = 06                                  ANL A,#00001111B
; B = 0A                                  ANL B,#00001111B
; A = '6'                                 MOVC A,@A+DPTR
; A = 0A                                  MOV A,B
; A = 'A'                                 MOVC A,@A+DPTR
;
; -> '6A'                                 Salida (dos caracteres HEX)
;-------------------------------------------------------------------------------

BYTE_TX:

    PUSH DPH                            ; Guarda en la pila el DPH del DPTR, ya
                                        ; que es necesario modificar su valor en
                                        ; las siguientes instrucciones y no se
                                        ; puede perder el valor que contiene
                                        ; actualmente, que es el MSB de la
                                        ; dirección de la memoria externa del
                                        ; byte que se está volcando.

    PUSH DPL                            ; Guarda en la pila el DPL del DPTR, ya
                                        ; que es necesario modificar su valor en
                                        ; las siguientes instrucciones y no se
                                        ; puede perder el valor que contiene
                                        ; actualmente, que es el LSB de la
                                        ; dirección de la memoria externa del
                                        ; byte que se está volcando.

    MOV B,A                             ; Copia al registro B el acumulador.

    SWAP A                              ; Intercambia los nibbles del
                                        ; acumulador.

    ANL A,#00001111B                    ; Borra del acumulador su nibble de
                                        ; mayor peso para que el acumulador pase
                                        ; a tomar el valor del nibble de mayor
                                        ; peso del byte original.

    ANL B,#00001111B                    ; Borra del registro B su nibble de
                                        ; mayor peso para que el registro B pase
                                        ; a tomar el valor del nibble de menor
                                        ; peso del byte original.

    MOV DPTR,#LUT                       ; Carga en el DPTR la dirección de la
                                        ; memoria de código a partir de la cual
                                        ; se sitúa una tabla de conversión.

    MOVC A,@A+DPTR                      ; Copia al acumulador el carácter HEX
                                        ; correspondiente al nibble de mayor
                                        ; peso del byte que se está volcando.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter HEX correspondiente al nibble
                                        ; de mayor peso del byte que se está
                                        ; volcando.

    MOV A,B                             ; Copia al acumulador el registro B.

    MOVC A,@A+DPTR                      ; Copia al acumulador el carácter HEX
                                        ; correspondiente al nibble de menor
                                        ; peso del byte que se está volcando.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter HEX correspondiente al nibble
                                        ; de menor peso del byte que se está
                                        ; volcando.

    POP DPL                             ; Restaura de la pila el DPL del DPTR,
                                        ; que contiene el LSB de la dirección de
                                        ; la memoria externa del byte que se
                                        ; está volcando.

    POP DPH                             ; Restaura de la pila el DPH del DPTR,
                                        ; que contiene el MSB de la dirección de
                                        ; la memoria externa del byte que se
                                        ; está volcando.

    RET                                 ; Retorna de la llamada a la subrutina.

;-------------------------------------------------------------------------------
; Transmite por el puerto serie la cadena de caracteres a la que apunta el DPTR
; y deja una línea en blanco.
;-------------------------------------------------------------------------------

STR_TX:

    CLR A                               ; Borra el acumulador para apuntar al
                                        ; carácter correcto en la siguiente
                                        ; instrucción.

    MOVC A,@A+DPTR                      ; Copia al acumulador el carácter actual
                                        ; de la cadena.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter actual de la cadena.

    INC DPTR                            ; Incrementa el DPTR para apuntar al
                                        ; siguiente carácter de la cadena.

    CJNE A,#0,STR_TX                    ; Comprueba si el siguiente carácter es
                                        ; el 0 que marca el final de la cadena,
                                        ; en cuyo caso el programa sigue en la
                                        ; siguiente instrucción. Si no es así,
                                        ; se repite el ciclo para transmitir el
                                        ; siguiente carácter.

    ACALL CRLF_TX                       ; Transmite por el puerto serie una
                                        ; primera nueva línea.

    ACALL CRLF_TX                       ; Transmite por el puerto serie una
                                        ; segunda nueva línea.

    RET                                 ; Retorna de la llamada a la subrutina.

;-------------------------------------------------------------------------------
; Transmite por el puerto serie un retorno de carro (CR) y una nueva línea (LF).
;-------------------------------------------------------------------------------

CRLF_TX:

    MOV A,#13                           ; Copia al acumulador el carácter del
                                        ; retorno de carro.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter del retorno de carro.

    MOV A,#10                           ; Copia al acumulador el carácter de la
                                        ; nueva línea.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter de la nueva línea.

    RET                                 ; Retorna de la llamada a la subrutina.

;-------------------------------------------------------------------------------
; Transmite por el puerto serie un espacio en blanco.
;-------------------------------------------------------------------------------

BLANK_TX:

    MOV A,#' '                          ; Copia al acumulador el carácter del
                                        ; espacio en blanco.

    ACALL CHAR_TX                       ; Transmite por el puerto serie el
                                        ; carácter del espacio en blanco.

    RET                                 ; Retorna de la llamada a la subrutina.

;-------------------------------------------------------------------------------
; Transmite por el puerto serie el carácter contenido en el acumulador.
;-------------------------------------------------------------------------------

CHAR_TX:

    MOV SBUF,A                          ; Copia al SBUF el carácter contenido en
                                        ; el acumulador.

    JNB TI,$                            ; Bloquea el programa hasta que la
                                        ; bandera de transmisión del puerto
                                        ; serie sea activada automáticamente,
                                        ; cuando la transmisión del carácter
                                        ; haya finalizado.

    CLR TI                              ; Desactiva manualmente la bandera de
                                        ; transmisión del puerto serie,
                                        ; dejándola preparada para transmitir el
                                        ; siguiente carácter.

    RET                                 ; Retorna de la llamada a la subrutina.

;------------------------ MENSAJES Y TABLA DE CONSULTA -------------------------

SETUP_MSG:  DB 'Current configuration:', 0

ADDR_MSG:   DB ' - Base address           : 0x',     A_4096, A_256, A_16, A_1, 0

IF      N_BYTES <> 0
BYTES_MSG:  DB ' - Total bytes            :  ', B_10K, B_1K, B_100, B_10, B_1, 0
ELSE  ; N_BYTES <> 0
BYTES_MSG:  DB ' - Total bytes            :  65536', 0
ENDIF ; N_BYTES <> 0

COLS_MSG:   DB ' - Columns per row        :     ',                  C_10, C_1, 0

IF      IS_RAM = 1
TYPE_MSG:   DB ' - External memory type   :    RAM', 0
ELSE  ; IS_RAM = 1
TYPE_MSG:   DB ' - External memory type   :    ROM', 0
ENDIF ; IS RAM = 1

IF      IS_RAM = 1
IF      TEST_MODE = 1
MODE_MSG:   DB ' - Preloaded test message :   True', 0
ELSE  ; TEST_MODE = 1
MODE_MSG:   DB ' - Preloaded test message :  False', 0
ENDIF ; TEST_MODE = 1
ENDIF ; IS_RAM = 1

READY_MSG:  DB 'Ready.', 0

HEADER_MSG: DB 'Dump of the external memory:', 0

TEST_MSG:   DB '---- TITLE -----'
            DB '                '
            DB '8051_EXTMEM_DUMP'
            DB '                '
            DB '                '
            DB '- DESCRIPTION --'
            DB '                '
            DB 'External memory '
            DB 'dump with a     '
            DB 'MCS-51 family uC'
            DB '                '
            DB '                '
            DB '---- VERSION ---'
            DB '                '
            DB '1.0.0           '
            DB '                '
            DB '                '
            DB '---- AUTHOR ----'
            DB '                '
            DB 'Jorge Botana    '
            DB 'Mtz. de Ibarreta'
            DB '                '
            DB '                '
            DB '--- LANGUAGE ---'
            DB '                '
            DB 'MCS-51 assembly '
            DB '                '
            DB '                '
            DB '--- LICENSE ----'
            DB '                '
            DB 'MIT             ', 0

FOOTER_MSG: DB 'Done.', 0

DIS_MSG:    DB '1 - Push-button disabled.', 0

EN_MSG:     DB '2 - Push-button enabled.', 0

LUT:        DB '0123456789ABCDEF'

;-------------------------------------------------------------------------------

END
