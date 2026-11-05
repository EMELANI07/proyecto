# Anexo — Bitácora de uso de LLM (Claude)
Estrada Rodriguez Melani · Proyecto #65: Subasta de ganado o productos · Temas selectos de programación concurrente (Erlang/OTP) · Tecnológico Nacional de México, campus Tijuana
Este documento registra el uso de un modelo de lenguaje (Claude, de Anthropic) como herramienta de apoyo durante la elaboración del proyecto #65 en Erlang/OTP. Se documentan los prompts utilizados (resumidos), los resultados obtenidos y una reflexión crítica sobre su utilidad y sus limitaciones.

> Nota para completar antes de entregar: los campos marcados con [COMPLETAR] deben llenarse con lo que realmente hiciste. No dejes afirmaciones que no sean ciertas.

## 1. Herramienta utilizada

* Modelo: Claude (Anthropic), mediante la aplicación web/móvil de Claude.
* Uso principal: interpretar la rúbrica y el enunciado del proyecto, proponer el diseño OTP (procesos y supervisores), generar borradores de código Erlang, escribir pruebas, y explicar paso a paso cómo ejecutar el sistema.
* Uso que requiere advertencia: a diferencia de un uso solo de consulta, Claude sí generó borradores del código Erlang del proyecto (simulador, API con Cowboy, pruebas y una página HTML provisional). Ese código fue compilado y probado por Claude en su propio entorno de ejecución (Erlang/OTP 25, con Cowboy, Ranch, Cowlib y Recon descargados desde GitHub en las mismas versiones que pide rebar.config). No es el mismo entorno que el del proyecto (OTP 27 con rebar3), por lo que fue necesario reproducirlo y comprobarlo por mi cuenta: [COMPLETAR: dónde y cuándo lo ejecuté yo, por ejemplo en mi VM o en mi equipo].
* Uso que NO se le dio: no se utilizaron cifras ni datos del dominio (precios por kilo, pesos, tiempos de subasta) sin marcarlos como supuestos. La interfaz con Google Stitch y las capturas, Loom y Asciinema de la demo son trabajo propio: [COMPLETAR: confirmar].

## 2. Registro de prompts y resultados

### Prompt 1 — Interpretar la rúbrica y qué entregar

*Prompt utilizado (resumido):* Adjunté la rúbrica de la demo (PDF) y los enlaces del repositorio del profesor, y pedí ayuda para saber qué debía entregar y qué poner en el repositorio, incluyendo Loom, Gist y Asciinema.
Resultado obtenido: Una lista de lo que evalúa la rúbrica (solución en Erlang, montaje en VM, demostración, UIX con Google Stitch, manual en Gist, calidad del código, integración y argumentación), una estructura sugerida de repositorio, una plantilla de manual para el Gist y un prompt para Google Stitch.

Reflexión: Claude no pudo abrir el repositorio del profesor porque GitHub bloquea el acceso automatizado, así que su primera respuesta asumía el enunciado. Fue necesario pegarle el README y el código base para que la respuesta se ajustara al proyecto real. Esto muestra que el modelo puede responder con seguridad aparente sobre algo que no pudo leer.

### Prompt 2 — Entender qué pide realmente el proyecto

*Prompt utilizado (resumido):* Pegué el README del proyecto 65 y los archivos de la plantilla, y expliqué que no entendía qué debía hacer: si solo eran pruebas y una presentación.
Resultado obtenido: Se aclaró que la plantilla estaba vacía (un gen_server con ping y un supervisor) y que el trabajo consistía en modelar el dominio. Se propuso un diseño OTP: un gen_statem por lote (abierto, última llamada, adjudicado, retirado), una bitácora de eventos como fuente de verdad, un supervisor dinámico de lotes y una estrategia rest_for_one. Se justificó cada decisión frente a los casos difíciles del enunciado (puja en el último instante, puja remota tardía, retiro de lote, reinicio del sistema).

Reflexión: Fue útil para convertir un enunciado largo en un plan. El código de esta primera propuesta tenía un error (usaba keep_state_data, que no es un valor de retorno válido de gen_statem, y hacía que cualquier puja rechazada matara el proceso del lote). Se detectó hasta que Claude lo compiló y lo ejecutó en el siguiente paso. Sin esa prueba, el error habría llegado a la demo.

### Prompt 3 — Simulador del escenario

*Prompt utilizado (resumido):* Pedí empezar con el simulador, siguiendo el orden propuesto.
Resultado obtenido: Un simulador de 150 lotes, 60 postores en sala, 20 remotos y un martillero, con fallas inyectadas (postores remotos que se desconectan, lote retirado a media subasta, remoto que pierde conexión en su puja ganadora, procesos de lote eliminados con kill y una puja remota posterior a la adjudicación) y una auditoría automática de la bitácora con cuatro invariantes. Se agregaron pruebas eunit.

Reflexión: El simulador permitió generar evidencia verificable para la prueba de caos. Los precios base (35 a 54 pesos por kilo) y los pesos (150 a 249 kg) son datos inventados para la simulación y se registran como supuestos propios; las cifras reales deben verificarse en una fuente vigente antes de citarlas: [COMPLETAR: fuente que consulté].

### Prompt 4 — API con Cowboy, WebSocket y métricas

*Prompt utilizado (resumido):* Pedí continuar con la API de Cowboy y el WebSocket.
Resultado obtenido: Endpoints REST para lotes, pujas y bitácora, un WebSocket /ws/subasta que transmite los eventos en vivo, un endpoint /metrics en formato Prometheus, un módulo JSON propio, una página HTML provisional y pruebas de integración. Claude descargó las dependencias desde GitHub para poder compilar y probar la aplicación real, y verificó el WebSocket con un cliente de prueba.

Reflexión: Al probar se encontró un segundo error: las respuestas 413 (cuerpo demasiado grande) dejaban conexiones colgadas, y se corrigió. También se verificó la validación de entradas y que un nombre de postor con código HTML se trate como texto. La prueba de caos mostró una limitación real: al matar la bitácora, el supervisor la reinicia y el WebSocket sigue funcionando, pero se pierden los lotes porque la bitácora vive en ETS (memoria). La mejora pendiente es persistirla en disco (disk_log o dets).

### Prompt 5 — No poder abrir la página

*Prompt utilizado (resumido):* Reporté que al abrir el HTML solo aparecía "reconectando…" y pedí una explicación paso a paso.
Resultado obtenido: Se explicó que la página necesita el servidor de Erlang en ejecución (rebar3 shell) y que debe abrirse en http://localhost:8080, no con doble clic sobre el archivo.

Reflexión: Fue una aclaración sencilla pero necesaria. Reforzó que debo entender la arquitectura (navegador, Cowboy, procesos OTP) y no solo copiar archivos.

## 4. Qué verifiqué yo personalmente

[*] Copié el código al repositorio y ejecuté rebar3 compile y rebar3 eunit en mi entorno.
[*] Ejecuté el simulador (p65_simulador:correr()) y revisé el resultado.
[*] Abrí la interfaz en el navegador con el servidor en ejecución.
[ ] Realicé la prueba de caos y registré qué maté, qué esperaba y qué ocurrió.
[ ] Comprobé las cifras del enunciado contra una fuente vigente.
[ ] Diseñé las pantallas en Google Stitch y las conecté a la API.
[*] Puedo explicar con mis palabras por qué se eligió un proceso por lote, una bitácora separada y rest_for_one.

## 5. Reflexión crítica general
¿La herramienta fue útil? Sí. Claude funcionó como apoyo para interpretar la rúbrica, convertir el enunciado en un diseño OTP, generar borradores de código y pruebas, y explicar la ejecución. Probar el código antes de entregarlo permitió detectar errores que una revisión de lectura no habría encontrado.
¿Hubo errores o limitaciones? Hubo errores o problemas con instalar el erl y rebar3.

1. Respondió inicialmente sin poder leer el repositorio del profesor y tuvo que corregirse cuando se le proporcionó el enunciado.
2. Su primer código tenía un error de gen_statem que solo apareció al ejecutarlo; un segundo error apareció en la API (respuesta 413).
3. Probó en OTP 25 y no en OTP 27 con rebar3; la compatibilidad debe confirmarse en el entorno real.
4. Los datos del dominio de la simulación son supuestos, no cifras verificadas.
5. El diseño tiene una limitación conocida: la bitácora en ETS no sobrevive a la caída del nodo.

Conclusión del uso de la herramienta: Claude se utilizó como apoyo para diseñar, programar y probar, pero el contenido generado no sustituye la comprensión del proyecto. El código fue revisado, ejecutado y adaptado antes de la entrega, y debo ser capaz de explicarlo y defenderlo en la demostración: Realice la prueba en maquina virtual de awsacademy, mostrando que se pudo completar correctamente sobre como funciona la puja y los resultados dependiendo de los resultados.
