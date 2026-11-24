* *Escala del gemelo:* Ejemplo con 4–6 lotes, postores en sala y remotos, 1 martillero (supuesto del ejercicio; cifras de referencia del original: 100–300 lotes, 1–3 min por lote, 1–3 s de retraso remoto, ~200 kg/becerro, 150 lotes, 80 postores [60 sala, 20 remotos], 1 martillero).

* *Reloj lógico:* ahora(Ms) en milisegundos, sin reloj del sistema.

* *Frontera y reserva:* >= (mayor o igual) cumple la reserva total en pesos; < no la cumple; sin peso válido o sin lectura da no_se_sabe. La reserva se registra como total en pesos.

* *Escalón y desempate:* Escalón base configurable (escalon/1). Empate en precio por kilo se resuelve por menor instante de llegada (Llegada más temprana) y, si coincide, por orden lexicográfico de Id de puja.

* *Remotos y desconexión:* La hora de emisión del cliente remoto no es confiable si es desconocida o supera un margen; la llegada al servidor gobierna el orden. Si una puja llega después de conexion_perdida en el lote, no obliga; si hay hueco en bitácora o emisión desconocida que impida ubicarla, da no_se_sabe.

* *Retiro y reinicio:* Un lote puede pasar a retirado antes de adjudicarse; si hay hueco en la bitácora alrededor de un reinicio o llamada ("a las dos" / "a las tres"), decide/3 genera las historias compatibles mediante backtracking.

* *Documentos por animal:* Cada animal requiere arete, sanitario y transito con vigencia conocida (vigente(...) / distinta de desconocida); desconocida produce no_se_sabe (nunca si), y faltante produce no.

* *Huecos de bitacora por lote:* Un hueco en la secuencia de eventos afecta a un lote solo si el evento inmediatamente anterior o el inmediatamente posterior al hueco pertenece a ese lote. Un hueco entre eventos de otros lotes no vuelve no_se_sabe las pujas de un lote sin hueco (huecos_bitacora_lote/2). huecos_bitacora/1 sigue dando la vista global.

* *Escalon vigente del ejemplo l2:* precio_vigente(l2, 62) es un valor de ejemplo (supuesto del ejercicio, no una estadistica real); se fijo en 62 para que sea coherente con la puja p201 del mismo escenario.

* *Documentos por animal (precedencia):* si un animal tiene un documento faltante y otro con vigencia desconocida, el estado del animal es no (el faltante es cierto); no_se_sabe solo aplica cuando no hay faltantes.

* *Pujas desde la interfaz:* cada puja y cada evento los valida Prolog (registrar_puja/4, registrar_evento/3 en reglas.pl); la llegada de la puja es siempre ahora(Ms). Para un postor remoto, la emision se supone como llegada menos su latencia declarada (latencia/2, valor de ejemplo); si no hay latencia queda desconocida. Las pujas rechazadas tambien se guardan para que la bitacora las muestre. El reloj logico solo avanza con /api/reloj; no hay reloj del sistema.

* *Pantallas de ejemplo:* Postores (remotos.html) y SINIIGA (corral.html) todavia muestran datos de muestra y lo indican en pantalla; Lotes y Bitacora si leen todo de Prolog. Las cifras de esos ejemplos no son estadisticas reales.
