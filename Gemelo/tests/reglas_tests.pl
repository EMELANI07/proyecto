% se escriben antes que las reglas.
:- module(reglas_tests, [run_tests/0]).

:- use_module(library(plunit)).
:- use_module('../hechos').
:- use_module('../reglas').

run_tests :-
    run_tests([
        sit1_martillazo_l4,
        sit2_desconexion_compromiso,
        sit3_reserva_bascula_l2,
        sit4_retiro_hueco_l5,
        sit5_corral_documentos_l6
    ]).

:- begin_tests(sit1_martillazo_l4).

test(l4_adjudica_a_s2_y_rechaza_remotos) :-
    cargar_escenario_base,
    decide(l4, Decision, Explicacion),
    assertion(Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado], ganador(s2, puja(p401), precio_kilo(54)))),
    assertion(member(pujas_no_aceptadas_o_tardias(Rech), Explicacion)),
    assertion(member(p402, Rech)),
    assertion(member(p403, Rech)).

:- end_tests(sit1_martillazo_l4).

:- begin_tests(sit2_desconexion_compromiso).

test(puja_con_emision_desconocida_da_en_duda) :-
    cargar_escenario_base,
    condicion_cumple(puja_antes_desconexion(p501), Estado, _),
    assertion(Estado == no_se_sabe).

:- end_tests(sit2_desconexion_compromiso).

:- begin_tests(sit3_reserva_bascula_l2).

test(l2_350kg_por_62_es_21700_no_cumple_reserva_24000_en_47000ms) :-
    cargar_escenario_base,
    % En 47000 ms rige reserva de 24000 (la de 21000 rige desde 45000? No: 45000 =< 47000, así que rige 21000!)
    % 350 * 62 = 21700 >= 21000 -> cumple reserva vigente desde 45000 ms
    decide(l2, Decision, _),
    assertion(Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado], ganador(s1, puja(p201), precio_kilo(62)))).

test(precio_kilo_minimo_para_reserva_24000_en_350kg) :-
    cargar_escenario_base,
    precio_kilo_minimo_reserva(l2, 44000, Min),
    assertion(Min > 68.5, Min < 68.6).

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
    assertion(member(l6, Lotes)),
    condicion_cumple(documentos_lote(l6), Estado, Ev),
    assertion(Estado == no),
    assertion(member(falta_documento(animal(sin_003), doc(transito)), Ev)).

:- end_tests(sit5_corral_documentos_l6).
