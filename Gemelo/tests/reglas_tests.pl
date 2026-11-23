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
