% Aqui viviran todas las decisiones del dominio.
:- module(reglas, [
    decide/3,
    decide_publica/3,
    situacion/3,
    huecos_bitacora/1,
    huecos_bitacora_lote/2,
    precio_kilo_minimo_reserva/3,
    que_falta_para_cambiar/3,
    condicion_cumple/3,
    lotes_no_pueden_salir/1,
    hipotesis_retraso/4,
    registrar_puja/4,
    registrar_evento/3,
    avanzar_reloj/2,
    reiniciar_escenario/0,
    evaluar_puja/3,
    etapa_lote/2,
    resumen_decision/2,
    texto_requisito/2
]).

:- encoding(utf8).

:- use_module(hechos).
:- use_module(library(lists)).

% -------------------------------------------------------------------------
% 1. Condiciones tri-valuadas: si | no | no_se_sabe
% -------------------------------------------------------------------------

condicion_cumple(puja_en_escalon_vigente(PujaId), Estado, Evidencia) :-
    puja(PujaId, Postor, Lote, Precio, Emision, Llegada),
    (   precio_vigente(Lote, Vigente)
    ->  (   Precio =:= Vigente
        ->  Estado = si,
            Evidencia = [precio_coincide_con_escalon_vigente(PujaId, Precio, Vigente)]
        ;   Precio < Vigente,
            postor(Postor, remoto)
        ->  Estado = no,
            Evidencia = [puja_remota_por_escalon_anterior(PujaId, postor(Postor), precio(Precio), escalon_vigente(Vigente), emision(Emision), llegada(Llegada))]
        ;   Estado = no,
            Evidencia = [precio_no_vigente(PujaId, precio(Precio), escalon_vigente(Vigente))]
        )
    ;   Estado = no_se_sabe,
        Evidencia = [sin_escalon_vigente_registrado(Lote)]
    ).

condicion_cumple(puja_antes_de_adjudicar(PujaId), Estado, Evidencia) :-
    puja(PujaId, _, Lote, _, _, Llegada),
    (   evento(_, Lote, adjudicado, MsAdj)
    ->  (   Llegada =< MsAdj
        ->  Estado = si,
            Evidencia = [llegada_antes_o_en_adjudicacion(PujaId, Llegada, MsAdj)]
        ;   Estado = no,
            Evidencia = [llegada_posterior_a_adjudicacion(PujaId, llegada(Llegada), adjudicado_en(MsAdj))]
        )
    ;   Estado = si,
        Evidencia = [lote_aun_no_adjudicado(Lote)]
    ).

condicion_cumple(puja_antes_desconexion(PujaId), Estado, Evidencia) :-
    puja(PujaId, _, Lote, _, Emision, Llegada),
    huecos_bitacora_lote(Lote, HuecosLote),
    (   evento(_, Lote, conexion_perdida, MsCorte)
    ->  (   Llegada < MsCorte
        ->  Estado = si,
            Evidencia = [llegada_antes_de_caida(PujaId, Llegada, MsCorte)]
        ;   Llegada > MsCorte
        ->  Estado = no,
            Evidencia = [llegada_posterior_a_caida(PujaId, Llegada, MsCorte)]
        ;   Estado = no_se_sabe,
            Evidencia = [llegada_en_limite_conexion(PujaId, Llegada, MsCorte)]
        )
    ;   (   Emision == desconocida
        ;   HuecosLote \== []
        )
    ->  Estado = no_se_sabe,
        Evidencia = [confirmacion_o_bitacora_incompleta(PujaId, emision(Emision), huecos_lote(HuecosLote))]
    ;   Estado = si,
        Evidencia = [sin_desconexion_registrada(PujaId, Llegada)]
    ).

condicion_cumple(peso_valido(Lote), Estado, Evidencia) :-
    rango(peso_lote_kg, Min, Max),
    findall(lectura(V, M), lectura(Lote, peso_lote_kg, V, M), Lecturas),
    (   Lecturas == []
    ->  Estado = no_se_sabe,
        Evidencia = [sin_lectura_bascula_espera_peso(Lote)]
    ;   findall(V, (member(lectura(V, _), Lecturas), number(V), V >= Min, V =< Max), Validos),
        (   Validos == []
        ->  Estado = no_se_sabe,
            Evidencia = [lecturas_fuera_de_rango_espera_peso(Lote, Lecturas, rango(Min, Max))]
        ;   sort(Validos, Unicos),
            (   length(Unicos, 1)
            ->  [PesoUnico] = Unicos,
                Estado = si,
                Evidencia = [peso_confirmado(Lote, PesoUnico, rango(Min, Max))]
            ;   Estado = no_se_sabe,
                Evidencia = [lecturas_no_coinciden_espera_peso(Lote, Unicos)]
            )
        )
    ).

condicion_cumple(reserva_cubierta(Lote, PrecioPorKilo, Instante), Estado, Evidencia) :-
    condicion_cumple(peso_valido(Lote), EstadoPeso, EvPeso),
    (   EstadoPeso \= si
    ->  Estado = no_se_sabe,
        Evidencia = [reserva_pendiente_de_peso(Lote) | EvPeso]
    ;   EvPeso = [peso_confirmado(_, Peso, _)],
        reserva_vigente(Lote, Instante, MontoReserva, Desde),
        Total is Peso * PrecioPorKilo,
        (   Total >= MontoReserva
        ->  Estado = si,
            Evidencia = [total_cubre_reserva(Lote, total(Total), reserva(MontoReserva), desde(Desde))]
        ;   Estado = no,
            Evidencia = [total_menor_a_reserva(Lote, total(Total), reserva(MontoReserva), desde(Desde))]
        )
    ).

condicion_cumple(documentos_lote(Lote), Estado, Evidencia) :-
    findall(Arete, animal(Arete, Lote), Animales),
    (   Animales == []
    ->  Estado = no,
        Evidencia = [lote_sin_animales(Lote)]
    ;   evaluar_animales(Animales, Detalles),
        combinar_documentos(Detalles, Estado, Evidencia)
    ).

evaluar_animales([], []).
evaluar_animales([Arete | Resto], [animal_doc(Arete, EstadoA, EvsA) | R2]) :-
    findall(doc(Tipo, Emisor, Vig), documento(Tipo, Arete, Emisor, Vig), Docs),
    evaluar_docs_animal(Arete, [arete, sanitario, transito], Docs, EstadoA, EvsA),
    evaluar_animales(Resto, R2).

evaluar_docs_animal(Arete, Tipos, Docs, Estado, Evs) :-
    findall(E-Ev,
            (   member(Tipo, Tipos),
                evaluar_doc(Arete, Tipo, Docs, E, Ev)
            ),
            Pares),
    pairs_keys_values(Pares, Estados, ListasEv),
    append(ListasEv, Evs),
    peor_estado(Estados, Estado).

evaluar_doc(Arete, Tipo, Docs, Estado, Evs) :-
    (   memberchk(doc(Tipo, Emisor, Vig), Docs)
    ->  (   Vig == desconocida
        ->  Estado = no_se_sabe,
            Evs = [vigencia_desconocida(animal(Arete), doc(Tipo), emisor(Emisor))]
        ;   Estado = si,
            Evs = []
        )
    ;   Estado = no,
        Evs = [falta_documento(animal(Arete), doc(Tipo))]
    ).

% Un faltante cierto (no) domina a una vigencia desconocida (no_se_sabe).
peor_estado(Estados, Estado) :-
    (   memberchk(no, Estados)
    ->  Estado = no
    ;   memberchk(no_se_sabe, Estados)
    ->  Estado = no_se_sabe
    ;   Estado = si
    ).

combinar_documentos(Detalles, Estado, Evidencia) :-
    findall(Item,
            (member(animal_doc(_, no, Evs), Detalles), member(Item, Evs)),
            Faltantes),
    findall(Item,
            (member(animal_doc(_, no_se_sabe, Evs), Detalles), member(Item, Evs)),
            Desconocidos),
    (   Faltantes \= []
    ->  Estado = no,
        Evidencia = Faltantes
    ;   Desconocidos \= []
    ->  Estado = no_se_sabe,
        Evidencia = Desconocidos
    ;   Estado = si,
        Evidencia = [documentos_completos_y_vigentes]
    ).

reserva_vigente(Lote, Instante, Monto, Desde) :-
    findall(d(D, M), (reserva(Lote, M, D), D =< Instante), Cand),
    Cand \= [],
    max_desde(Cand, d(Desde, Monto)).

max_desde([X], X) :- !.
max_desde([d(D1, M1), d(D2, M2) | Resto], Max) :-
    (   D1 >= D2
    ->  max_desde([d(D1, M1) | Resto], Max)
    ;   max_desde([d(D2, M2) | Resto], Max)
    ).

% -------------------------------------------------------------------------
% 2. Bitácora y huecos
% -------------------------------------------------------------------------

% huecos_bitacora(-Huecos): numeros de secuencia faltantes en toda la bitacora.
huecos_bitacora(Huecos) :-
    huecos_con_vecinos(Gaps),
    findall(Falt, member(hueco(Falt, _, _), Gaps), Listas),
    append(Listas, Huecos).

% huecos_bitacora_lote(+Lote, -Huecos): solo los huecos que tocan al lote.
% Supuesto declarado (SUPUESTOS.md): un hueco afecta a un lote si el evento
% inmediatamente anterior o el inmediatamente posterior al hueco es de ese lote.
% Un hueco entre eventos de otros lotes no invalida las pujas de este lote.
huecos_bitacora_lote(Lote, Huecos) :-
    huecos_con_vecinos(Gaps),
    findall(Falt,
            (   member(hueco(Falt, LoteAntes, LoteDespues), Gaps),
                (   LoteAntes == Lote
                ->  true
                ;   LoteDespues == Lote
                )
            ),
            Listas),
    append(Listas, Huecos).

% huecos_con_vecinos(-Gaps): Gaps = [hueco(Faltantes, LoteAntes, LoteDespues)]
huecos_con_vecinos(Gaps) :-
    findall(Seq-Lote, evento(Seq, Lote, _, _), Raw),
    sort(1, @<, Raw, Ordenados),
    buscar_huecos(Ordenados, Gaps).

buscar_huecos([], []).
buscar_huecos([Primero | Resto], Gaps) :-
    buscar_huecos_(Resto, Primero, Gaps).

buscar_huecos_([], _, []).
buscar_huecos_([B-LB | Resto], A-LA, Gaps) :-
    Sig is A + 1,
    (   B > Sig
    ->  Fin is B - 1,
        numlist(Sig, Fin, Falt),
        Gaps = [hueco(Falt, LA, LB) | GResto]
    ;   Gaps = GResto
    ),
    buscar_huecos_(Resto, B-LB, GResto).

% -------------------------------------------------------------------------
% 3. situacion(?Entidad, ?Situacion, -Evidencia)
% -------------------------------------------------------------------------

situacion(PujaId, Situacion, Evidencia) :-
    puja(PujaId, Postor, Lote, Precio, Emision, Llegada),
    (   Situacion = puja_remota_escalon_anterior,
        condicion_cumple(puja_en_escalon_vigente(PujaId), no, EvEsc),
        postor(Postor, remoto),
        Evidencia = [lote(Lote), postor(Postor), emision(Emision), llegada(Llegada) | EvEsc]
    ;   Situacion = puja_fuera_de_tiempo_post_adjudicacion,
        condicion_cumple(puja_antes_de_adjudicar(PujaId), no, EvAdj),
        Evidencia = [lote(Lote), postor(Postor), precio(Precio) | EvAdj]
    ;   Situacion = puja_en_duda,
        condicion_cumple(puja_antes_desconexion(PujaId), no_se_sabe, EvConn),
        Evidencia = [lote(Lote), postor(Postor), precio(Precio) | EvConn]
    ;   Situacion = puja_no_obliga_por_desconexion,
        condicion_cumple(puja_antes_desconexion(PujaId), no, EvConn),
        Evidencia = [lote(Lote), postor(Postor), precio(Precio) | EvConn]
    ).

situacion(Lote, Situacion, Evidencia) :-
    lote(Lote, _, _),
    (   Situacion = no_puede_salir_del_corral,
        condicion_cumple(documentos_lote(Lote), EstadoDocs, EvDocs),
        EstadoDocs \= si,
        Evidencia = [estado_documentos(EstadoDocs) | EvDocs]
    ;   Situacion = puede_salir_del_corral,
        condicion_cumple(documentos_lote(Lote), si, EvDocs),
        Evidencia = EvDocs
    ).

% -------------------------------------------------------------------------
% 4. decide(+Lote, -Decision, -Explicacion) con historias en huecos
% -------------------------------------------------------------------------

decide(Lote, Decision, Explicacion) :-
    (   \+ lote(Lote, _, _)
    ->  Decision = invalido(lote_inexistente(Lote)),
        Explicacion = [error(lote_no_registrado(Lote))]
    ;   huecos_bitacora_lote(Lote, Huecos),
        Huecos \== [],
        evento(_, Lote, reinicio, MsReinicio)
    ->  % Historias compatibles ante hueco + reinicio (Situación 4)
        (   Decision = secuencia_etapas([abierto, llamada_a_las_dos, retirado], sin_ganador),
            Explicacion = [
                historia_compatible(retirada_antes_de_cierre_y_reinicio),
                reinicio_registrado(MsReinicio),
                huecos_en_bitacora(Huecos),
                favorece(vendedor_por_retiro_antes_de_adjudicar),
                afecta(postor_lider_sin_compromiso_final),
                registro_que_decide(evento_retiro_o_llamada_a_las_tres_con_seq_faltante)
            ]
        ;   Decision = secuencia_etapas([abierto, llamada_a_las_dos, llamada_a_las_tres, adjudicado_o_disputado], revision_requerida),
            Explicacion = [
                historia_compatible(llamada_a_las_tres_antes_de_retiro),
                reinicio_registrado(MsReinicio),
                huecos_en_bitacora(Huecos),
                favorece(postor_lider_si_cerro_antes_del_retiro),
                afecta(vendedor_si_retiro_fue_tardio),
                registro_que_decide(evento_retiro_o_llamada_a_las_tres_con_seq_faltante)
            ]
        )
    ;   decide_sin_hueco_critico(Lote, Decision, Explicacion)
    ).

decide_sin_hueco_critico(Lote, Decision, Explicacion) :-
    findall(p(Lleg, Precio, Id, Postor),
            (   puja(Id, Postor, Lote, Precio, _, Lleg),
                condicion_cumple(puja_antes_de_adjudicar(Id), si, _),
                condicion_cumple(puja_en_escalon_vigente(Id), si, _),
                condicion_cumple(puja_antes_desconexion(Id), si, _)
            ),
            Validas),
    findall(Id,
            (   puja(Id, _, Lote, _, _, _),
                once(puja_rechazada(Id))
            ),
            Rechazadas),
    (   Validas == []
    ->  Decision = secuencia_etapas([abierto, sin_venta], sin_ganador),
        Explicacion = [motivo(sin_pujas_validas), pujas_rechazadas_o_fuera_de_tiempo(Rechazadas)]
    ;   ordenar_pujas(Validas, [Gan | Resto]),
        Gan = p(LlegGan, PrecioGan, IdGan, PostorGan),
        postor(PostorGan, ModGan),
        condicion_cumple(reserva_cubierta(Lote, PrecioGan, LlegGan), EstadoRes, EvRes),
        (   EstadoRes == si
        ->  Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado], ganador(PostorGan, puja(IdGan), precio_kilo(PrecioGan))),
            Explicacion = [
                ganador_unico(PostorGan),
                modalidad(ModGan),
                puja_ganadora(IdGan, PrecioGan, llegada(LlegGan)),
                desempate(mayor_precio_luego_menor_llegada_luego_id),
                pujas_no_aceptadas_o_tardias(Rechazadas),
                otras_pujas_validas(Resto),
                reserva_estado(si)
                | EvRes
            ]
        ;   EstadoRes == no_se_sabe
        ->  Decision = en_duda(ultima_llamada_espera_peso, sin_ganador),
            Explicacion = [
                puja_lider(IdGan, PostorGan, PrecioGan),
                pujas_no_aceptadas_o_tardias(Rechazadas),
                reserva_estado(no_se_sabe)
                | EvRes
            ]
        ;   Decision = secuencia_etapas([abierto, ultima_llamada, sin_venta], sin_ganador),
            Explicacion = [
                motivo(no_alcanza_reserva_vigente),
                puja_mas_alta_sin_adjudicar(IdGan, PostorGan, PrecioGan),
                pujas_no_aceptadas_o_tardias(Rechazadas),
                reserva_estado(no)
                | EvRes
            ]
        )
    ).

% Una puja rechazada puede incumplir varias condiciones; se cuenta una sola vez.
puja_rechazada(Id) :-
    (   condicion_cumple(puja_antes_de_adjudicar(Id), no, _)
    ;   condicion_cumple(puja_en_escalon_vigente(Id), no, _)
    ;   condicion_cumple(puja_antes_desconexion(Id), no, _)
    ).

ordenar_pujas(Pujas, Ordenadas) :-
    predsort(cmp_puja, Pujas, Ordenadas).

cmp_puja(Ord, p(L1, P1, I1, _), p(L2, P2, I2, _)) :-
    (   P1 > P2 -> Ord = (<)
    ;   P1 < P2 -> Ord = (>)
    ;   L1 < L2 -> Ord = (<)
    ;   L1 > L2 -> Ord = (>)
    ;   I1 @=< I2 -> Ord = (<)
    ;   Ord = (>)
    ).

decide_publica(Lote, Decision, ExpPublica) :-
    decide(Lote, Decision, ExpCompleta),
    filtrar_publica(ExpCompleta, ExpPublica).

filtrar_publica([], []).
filtrar_publica([Item | Resto], Filtrada) :-
    (   Item = reserva_estado(_)
    ;   Item = total_cubre_reserva(_, _, _, _)
    ;   Item = total_menor_a_reserva(_, _, _, _)
    ;   Item = reserva_pendiente_de_peso(_)
    ),
    !,
    filtrar_publica(Resto, Filtrada).
filtrar_publica([Item | Resto], [Item | Filtrada]) :-
    filtrar_publica(Resto, Filtrada).

% -------------------------------------------------------------------------
% 5. Preguntas inversas e hipótesis sobre las mismas reglas
% -------------------------------------------------------------------------

precio_kilo_minimo_reserva(Lote, Instante, PrecioMinimo) :-
    condicion_cumple(peso_valido(Lote), si, [peso_confirmado(_, Peso, _)]),
    reserva_vigente(Lote, Instante, MontoReserva, _),
    PrecioMinimo is MontoReserva / Peso.

lotes_no_pueden_salir(Lotes) :-
    findall(Lote, situacion(Lote, no_puede_salir_del_corral, _), Lotes).

hipotesis_retraso(PujaId, NuevaLlegada, Decision, Explicacion) :-
    puja(PujaId, Postor, Lote, Precio, Emision, _),
    retract(puja(PujaId, Postor, Lote, Precio, Emision, _)),
    assertz(puja(PujaId, Postor, Lote, Precio, Emision, NuevaLlegada)),
    (   decide(Lote, Decision, Explicacion)
    ->  true
    ;   true
    ),
    cargar_escenario_base.

que_falta_para_cambiar(Lote, Decision, Requisitos) :-
    decide(Lote, Decision, _),
    findall(Req,
            (   (   Decision = secuencia_etapas([abierto, ultima_llamada, sin_venta], _)
                ->  Req = puja_o_peso_que_alcance_reserva_vigente(Lote)
                )
            ;   (   Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado], _)
                ->  Req = puja_mayor_antes_de_adjudicar(Lote)
                )
            ;   (   Decision = secuencia_etapas([abierto, llamada_a_las_dos, retirado], _)
                ->  Req = registrar_evento_faltante_en_bitacora_antes_de_reinicio(Lote)
                )
            ;   (   Decision = secuencia_etapas([abierto, llamada_a_las_dos, llamada_a_las_tres, adjudicado_o_disputado], _)
                ->  Req = verificar_orden_exacto_entre_llamada_a_las_tres_y_retiro(Lote)
                )
            ;   (   Decision = en_duda(_, _)
                ->  Req = completar_lectura_o_bitacora(Lote)
                )
            ),
            Requisitos).

% -------------------------------------------------------------------------
% 6. Operaciones sobre el estado (las usa la API; toda la validacion vive aqui)
% -------------------------------------------------------------------------
% Las escrituras compuestas (leer y luego asertar) se serializan con un mutex
% porque el servidor HTTP atiende cada peticion en su propio hilo.

reiniciar_escenario :-
    with_mutex(gemelo_estado, cargar_escenario_base).

% avanzar_reloj(+DeltaMs, -NuevoAhora): el reloj logico solo avanza por esta via.
avanzar_reloj(Delta, Resultado) :-
    with_mutex(gemelo_estado, avanzar_reloj_(Delta, Resultado)).

avanzar_reloj_(Delta, Resultado) :-
    (   \+ ( integer(Delta), Delta >= 0 )
    ->  Resultado = error(delta_invalido(Delta))
    ;   retract(ahora(Antes)),
        Nuevo is Antes + Delta,
        assertz(ahora(Nuevo)),
        Resultado = ahora(Nuevo)
    ).

% registrar_puja(+Postor, +Lote, +Precio, -Resultado)
%   Resultado = resultado(Id, Veredicto, Evidencia) | error(Motivo)
% La llegada es ahora(Ms). La emision del postor remoto es un supuesto:
% llegada menos su latencia declarada; si no hay latencia queda desconocida.
% La puja se guarda siempre (tambien las rechazadas) para que la bitacora
% muestre lo ocurrido; decide/3 ya sabe ignorar las que no son validas.
registrar_puja(Postor, Lote, Precio, Resultado) :-
    with_mutex(gemelo_estado, registrar_puja_(Postor, Lote, Precio, Resultado)).

registrar_puja_(Postor, Lote, Precio, Resultado) :-
    (   \+ lote(Lote, _, _)
    ->  Resultado = error(lote_no_registrado(Lote))
    ;   \+ postor(Postor, _)
    ->  Resultado = error(postor_no_registrado(Postor))
    ;   \+ ( number(Precio), Precio > 0 )
    ->  Resultado = error(precio_invalido(Precio))
    ;   ahora(Llegada),
        postor(Postor, Modalidad),
        emision_supuesta(Postor, Modalidad, Llegada, Emision),
        siguiente_id_puja(Id),
        assertz(puja(Id, Postor, Lote, Precio, Emision, Llegada)),
        evaluar_puja(Id, Veredicto, Evidencia),
        Resultado = resultado(Id, Veredicto, Evidencia)
    ).

emision_supuesta(_, sala, Llegada, Llegada) :- !.
emision_supuesta(Postor, remoto, Llegada, Emision) :-
    (   latencia(Postor, Latencia)
    ->  Emision is Llegada - Latencia
    ;   Emision = desconocida
    ).

siguiente_id_puja(Id) :-
    findall(N,
            (   puja(Existente, _, _, _, _, _),
                atom_concat(web, Digitos, Existente),
                atom_number(Digitos, N)
            ),
            Ns),
    (   Ns == []
    ->  Max = 0
    ;   max_list(Ns, Max)
    ),
    Siguiente is Max + 1,
    atom_concat(web, Siguiente, Id).

% evaluar_puja(+Id, -Veredicto, -Evidencia)
%   rechazada : alguna condicion da no
%   en_duda   : ninguna da no, pero alguna da no_se_sabe
%   valida    : las tres condiciones dan si
evaluar_puja(Id, Veredicto, Evidencia) :-
    findall(Estado-Ev,
            (   member(Condicion, [ puja_antes_de_adjudicar(Id),
                                    puja_en_escalon_vigente(Id),
                                    puja_antes_desconexion(Id) ]),
                condicion_cumple(Condicion, Estado, Ev)
            ),
            Pares),
    (   evidencia_de(no, Pares, Nos), Nos \== []
    ->  Veredicto = rechazada, Evidencia = Nos
    ;   evidencia_de(no_se_sabe, Pares, Dudas), Dudas \== []
    ->  Veredicto = en_duda, Evidencia = Dudas
    ;   evidencia_de(si, Pares, Sis),
        Veredicto = valida, Evidencia = Sis
    ).

evidencia_de(Estado, Pares, Evidencia) :-
    findall(E, (member(Estado-Ev, Pares), member(E, Ev)), Evidencia).

% registrar_evento(+Lote, +Suceso, -Resultado)
%   Resultado = evento(Seq, Lote, Suceso, Ms) | error(Motivo)
% El numero de secuencia es el siguiente al mayor; no rellena huecos.
registrar_evento(Lote, Suceso, Resultado) :-
    with_mutex(gemelo_estado, registrar_evento_(Lote, Suceso, Resultado)).

registrar_evento_(Lote, Suceso, Resultado) :-
    (   \+ lote(Lote, _, _)
    ->  Resultado = error(lote_no_registrado(Lote))
    ;   \+ memberchk(Suceso, [abierto, llamada, adjudicado, retirado, reinicio, conexion_perdida])
    ->  Resultado = error(suceso_no_permitido(Suceso))
    ;   Suceso == adjudicado,
        evento(_, Lote, adjudicado, _)
    ->  Resultado = error(lote_ya_adjudicado(Lote))
    ;   ahora(Ms),
        findall(S, evento(S, _, _, _), Seqs),
        (   Seqs == []
        ->  Max = 0
        ;   max_list(Seqs, Max)
        ),
        Seq is Max + 1,
        assertz(evento(Seq, Lote, Suceso, Ms)),
        Resultado = evento(Seq, Lote, Suceso, Ms)
    ).

% etapa_lote(+Lote, -Suceso): ultimo evento registrado del lote (por secuencia).
etapa_lote(Lote, Suceso) :-
    findall(Seq-S, evento(Seq, Lote, S, _), Pares),
    (   Pares == []
    ->  Suceso = sin_eventos
    ;   max_member(_-Suceso, Pares)
    ).

% -------------------------------------------------------------------------
% 7. Textos para mostrar (la interfaz no interpreta terminos de Prolog)
% -------------------------------------------------------------------------

resumen_decision(secuencia_etapas(_, ganador(Postor, puja(Id), precio_kilo(Kilo))), Texto) :- !,
    format(atom(Texto), 'Adjudicado a ~w con la puja ~w a $~w/kg.', [Postor, Id, Kilo]).
resumen_decision(secuencia_etapas([abierto, sin_venta], sin_ganador), Texto) :- !,
    Texto = 'Sin venta: ninguna puja es válida.'.
resumen_decision(secuencia_etapas([abierto, ultima_llamada, sin_venta], sin_ganador), Texto) :- !,
    Texto = 'Sin venta: la puja más alta no alcanza la reserva vigente.'.
resumen_decision(secuencia_etapas([abierto, llamada_a_las_dos, retirado], sin_ganador), Texto) :- !,
    Texto = 'Historia A: el lote se retiró antes del cierre; no hay ganador.'.
resumen_decision(secuencia_etapas(_, revision_requerida), Texto) :- !,
    Texto = 'Historia B: la llamada a las tres pudo cerrar antes del retiro; requiere revisión.'.
resumen_decision(en_duda(_, _), Texto) :- !,
    Texto = 'En duda: falta confirmar el peso o completar la bitácora.'.
resumen_decision(invalido(_), Texto) :- !,
    Texto = 'Lote no registrado.'.
resumen_decision(_, 'Sin resumen disponible.').

texto_requisito(puja_o_peso_que_alcance_reserva_vigente(L), T) :- !,
    format(atom(T), 'Una puja o un peso que alcance la reserva vigente de ~w.', [L]).
texto_requisito(puja_mayor_antes_de_adjudicar(L), T) :- !,
    format(atom(T), 'Una puja válida de mayor precio antes de adjudicar ~w.', [L]).
texto_requisito(registrar_evento_faltante_en_bitacora_antes_de_reinicio(L), T) :- !,
    format(atom(T), 'Recuperar el evento faltante de la bitácora de ~w (antes del reinicio).', [L]).
texto_requisito(verificar_orden_exacto_entre_llamada_a_las_tres_y_retiro(L), T) :- !,
    format(atom(T), 'Verificar el orden exacto entre la llamada a las tres y el retiro en ~w.', [L]).
texto_requisito(completar_lectura_o_bitacora(L), T) :- !,
    format(atom(T), 'Completar la lectura de báscula o la bitácora de ~w.', [L]).
texto_requisito(Otro, T) :-
    term_to_atom(Otro, T).
