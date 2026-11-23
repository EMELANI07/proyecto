* *Escala del gemelo:* Ejemplo con 4–6 lotes, postores en sala y remotos, 1 martillero (supuesto del ejercicio; cifras de referencia del original: 100–300 lotes, 1–3 min por lote, 1–3 s de retraso remoto, ~200 kg/becerro, 150 lotes, 80 postores [60 sala, 20 remotos], 1 martillero).

* *Reloj lógico:* ahora(Ms) en milisegundos, sin reloj del sistema.

* *Frontera y reserva:* >= (mayor o igual) cumple la reserva total en pesos; < no la cumple; sin peso válido o sin lectura da no_se_sabe. La reserva se registra como total en pesos.

* *Escalón y desempate:* Escalón base configurable (escalon/1). Empate en precio por kilo se resuelve por menor instante de llegada (Llegada más temprana) y, si coincide, por orden lexicográfico de Id de puja.

* *Remotos y desconexión:* La hora de emisión del cliente remoto no es confiable si es desconocida o supera un margen; la llegada al servidor gobierna el orden. Si una puja llega después de conexion_perdida en el lote, no obliga; si hay hueco en bitácora o emisión desconocida que impida ubicarla, da no_se_sabe.

* *Retiro y reinicio:* Un lote puede pasar a retirado antes de adjudicarse; si hay hueco en la bitácora alrededor de un reinicio o llamada ("a las dos" / "a las tres"), decide/3 genera las historias compatibles mediante backtracking.

* *Documentos por animal:* Cada animal requiere arete, sanitario y transito con vigencia conocida (vigente(...) / distinta de desconocida); desconocida produce no_se_sabe (nunca si), y faltante produce no.
