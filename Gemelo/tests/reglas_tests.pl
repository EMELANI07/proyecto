% Pruebas plunit del gemelo digital. Ejecutar desde Gemelo/ con:
%   swipl -g run_tests -t halt tests/reglas_tests.pl
:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../hechos').
:- use_module('../reglas').

:- begin_tests(sit1_martillazo_l4).

test(l4_adjudica_a_s2_y_rechaza_remotos) :-
    cargar_escenario_base,
    decide(l4, Decision, Explicacion),
    assertion(Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado],
                                          ganador(s2, puja(p401), precio_kilo(54)))),
    memberchk(pujas_no_aceptadas_o_tardias(Rech), Explicacion),
    assertion(Rech == [p402, p403]).

:- end_tests(sit1_martillazo_l4).

:- begin_tests(sit2_desconexion_compromiso).

test(puja_con_emision_desconocida_da_en_duda) :-
    cargar_escenario_base,
    condicion_cumple(puja_antes_desconexion(p501), Estado, _),
    assertion(Estado == no_se_sabe).

test(hueco_en_otro_lote_no_invalida_puja_de_l4) :-
    cargar_escenario_base,
    condicion_cumple(puja_antes_desconexion(p401), Estado, _),
    assertion(Estado == si).

test(hueco_de_bitacora_solo_toca_a_l5) :-
    cargar_escenario_base,
    huecos_bitacora_lote(l5, H5),
    huecos_bitacora_lote(l4, H4),
    huecos_bitacora_lote(l2, H2),
    assertion(H5 == [7, 8]),
    assertion(H4 == []),
    assertion(H2 == []).

:- end_tests(sit2_desconexion_compromiso).

:- begin_tests(sit3_reserva_bascula_l2).

% En 47000 ms rige la reserva de 21000 (vigente desde 45000 ms); la de 24000
% ya no aplica. 350 kg * 62 = 21700 >= 21000, asi que se adjudica.
test(l2_350kg_por_62_es_21700_cumple_reserva_21000_en_47000ms) :-
    cargar_escenario_base,
    decide(l2, Decision, _),
    assertion(Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado],
                                          ganador(s1, puja(p201), precio_kilo(62)))).

test(precio_kilo_minimo_para_reserva_24000_en_350kg) :-
    cargar_escenario_base,
    precio_kilo_minimo_reserva(l2, 44000, Min),
    assertion(Min > 68.5),
    assertion(Min < 68.6).

:- end_tests(sit3_reserva_bascula_l2).

:- begin_tests(sit4_retiro_hueco_l5).

test(l5_con_hueco_y_reinicio_ofrece_mas_de_una_historia) :-
    cargar_escenario_base,
    findall(D, decide(l5, D, _), Decisiones),
    assertion(length(Decisiones, 2)).

:- end_tests(sit4_retiro_hueco_l5).

:- begin_tests(sit5_corral_documentos_l6).

test(l6_no_puede_salir_por_vigencia_desconocida_y_falta_documento) :-
    cargar_escenario_base,
    lotes_no_pueden_salir(Lotes),
    assertion(memberchk(l6, Lotes)),
    condicion_cumple(documentos_lote(l6), Estado, Ev),
    assertion(Estado == no),
    assertion(memberchk(falta_documento(animal(sin_003), doc(transito)), Ev)).

:- end_tests(sit5_corral_documentos_l6).

:- begin_tests(sit6_registro_de_pujas_y_eventos).

test(puja_en_escalon_vigente_de_l2_es_valida) :-
    cargar_escenario_base,
    registrar_puja(s2, l2, 62, R),
    assertion(R = resultado(web1, valida, _)).

test(puja_fuera_de_escalon_es_rechazada_con_motivo) :-
    cargar_escenario_base,
    registrar_puja(s2, l2, 64, R),
    R = resultado(Id, Veredicto, Ev),
    assertion(Veredicto == rechazada),
    assertion(memberchk(precio_no_vigente(Id, precio(64), escalon_vigente(62)), Ev)).

test(puja_remota_calcula_emision_con_la_latencia_declarada) :-
    cargar_escenario_base,
    registrar_puja(r1, l2, 62, resultado(Id, Veredicto, _)),
    puja(Id, r1, l2, 62, Emision, Llegada),
    assertion(Veredicto == valida),
    assertion(Llegada == 120000),
    assertion(Emision =:= 120000 - 1500).

test(puja_posterior_a_la_adjudicacion_se_rechaza_y_no_cambia_al_ganador_de_l4) :-
    cargar_escenario_base,
    registrar_puja(s3, l4, 54, resultado(Id, Veredicto, _)),
    assertion(Veredicto == rechazada),
    decide(l4, Decision, Explicacion),
    assertion(Decision = secuencia_etapas(_, ganador(s2, puja(p401), precio_kilo(54)))),
    memberchk(pujas_no_aceptadas_o_tardias(Rech), Explicacion),
    assertion(memberchk(Id, Rech)).

test(puja_en_lote_con_hueco_propio_queda_en_duda) :-
    cargar_escenario_base,
    registrar_puja(s1, l5, 50, resultado(_, Veredicto, _)),
    assertion(Veredicto == en_duda).

test(adjudicar_y_avanzar_el_reloj_cierra_el_lote_a_nuevas_pujas) :-
    cargar_escenario_base,
    registrar_evento(l2, adjudicado, E),
    assertion(E == evento(10, l2, adjudicado, 120000)),
    % mismo instante del martillazo: todavia cuenta (llegada =< adjudicacion)
    registrar_puja(s2, l2, 62, resultado(_, V1, _)),
    assertion(V1 == valida),
    avanzar_reloj(1000, Ahora),
    assertion(Ahora == ahora(121000)),
    registrar_puja(s2, l2, 62, resultado(_, V2, _)),
    assertion(V2 == rechazada).

test(no_se_puede_adjudicar_dos_veces) :-
    cargar_escenario_base,
    registrar_evento(l4, adjudicado, R),
    assertion(R == error(lote_ya_adjudicado(l4))).

test(conexion_perdida_deja_fuera_las_pujas_posteriores) :-
    cargar_escenario_base,
    registrar_evento(l2, conexion_perdida, _),
    avanzar_reloj(500, _),
    registrar_puja(r2, l2, 62, resultado(_, Veredicto, Ev)),
    assertion(Veredicto == rechazada),
    assertion(memberchk(llegada_posterior_a_caida(_, 120500, 120000), Ev)).

test(entradas_invalidas_devuelven_error) :-
    cargar_escenario_base,
    registrar_puja(s1, lote_x, 62, R1),
    registrar_puja(nadie, l2, 62, R2),
    registrar_puja(s1, l2, -1, R3),
    registrar_puja(s1, l2, abc, R4),
    registrar_evento(l2, inventado, R5),
    avanzar_reloj(-5, R6),
    avanzar_reloj(1.5, R7),
    assertion(R1 == error(lote_no_registrado(lote_x))),
    assertion(R2 == error(postor_no_registrado(nadie))),
    assertion(R3 == error(precio_invalido(-1))),
    assertion(R4 == error(precio_invalido(abc))),
    assertion(R5 == error(suceso_no_permitido(inventado))),
    assertion(R6 == error(delta_invalido(-5))),
    assertion(R7 == error(delta_invalido(1.5))).

test(etapa_actual_de_cada_lote) :-
    cargar_escenario_base,
    etapa_lote(l4, E4),
    etapa_lote(l5, E5),
    etapa_lote(l6, E6),
    assertion(E4 == adjudicado),
    assertion(E5 == reinicio),
    assertion(E6 == sin_eventos).

test(resumen_en_espanol_de_la_decision_de_l4) :-
    cargar_escenario_base,
    decide(l4, Decision, _),
    resumen_decision(Decision, Texto),
    assertion(Texto == 'Adjudicado a s2 con la puja p401 a $54/kg.').

:- end_tests(sit6_registro_de_pujas_y_eventos).
