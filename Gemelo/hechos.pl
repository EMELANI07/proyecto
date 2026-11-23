% solo datos. El “ahora” es un hecho en milisegundos (no el reloj del sistema).
:- module(hechos, [
    ahora/1,
    lote/3,
    animal/2,
    documento/4,
    postor/2,
    latencia/2,
    puja/6,
    reserva/3,
    evento/4,
    rango/3,
    lectura/4,
    escalon/1,
    precio_vigente/2,
    cargar_escenario_base/0
]).

:- dynamic ahora/1.
:- dynamic lote/3.
:- dynamic animal/2.
:- dynamic documento/4.
:- dynamic postor/2.
:- dynamic latencia/2.
:- dynamic puja/6.
:- dynamic reserva/3.
:- dynamic evento/4.
:- dynamic rango/3.
:- dynamic lectura/4.
:- dynamic escalon/1.
:- dynamic precio_vigente/2.

limpiar_hechos :-
    retractall(ahora(_)),
    retractall(lote(_, _, _)),
    retractall(animal(_, _)),
    retractall(documento(_, _, _, _)),
    retractall(postor(_, _)),
    retractall(latencia(_, _)),
    retractall(puja(_, _, _, _, _, _)),
    retractall(reserva(_, _, _)),
    retractall(evento(_, _, _, _)),
    retractall(rango(_, _, _)),
    retractall(lectura(_, _, _, _)),
    retractall(escalon(_)),
    retractall(precio_vigente(_, _)).

% documento(Tipo, Arete, Emisor, Vigencia)
% evento(Seq, Lote, Suceso, Ms)
cargar_escenario_base :-
    limpiar_hechos,
    assertz(escalon(2)),
    assertz(ahora(120000)),

    assertz(rango(peso_lote_kg, 120, 20000)),

    % Lotes:
    % l2 -> Situación 3 (reserva y báscula)
    % l4 -> Situación 1 (martillazo, sala vs remoto escalón anterior vs remoto tras adjudicar)
    % l5 -> Situación 4 (retiro con puja líder, llamada "a las dos", reinicio y hueco de bitácora)
    % l6 -> Situación 5 (salida del corral: documentos y vigencias por animal)
    assertz(lote(l2, vendedora_ana, 1)),
    assertz(lote(l4, vendedor_luis, 2)),
    assertz(lote(l5, vendedor_carlos, 3)),
    assertz(lote(l6, comprador_sofia, 4)),

    % Postores (5 en sala, 3 remotos)
    assertz(postor(s1, sala)),
    assertz(postor(s2, sala)),
    assertz(postor(s3, sala)),
    assertz(postor(s4, sala)),
    assertz(postor(s5, sala)),
    assertz(postor(r1, remoto)),
    assertz(postor(r2, remoto)),
    assertz(postor(r3, remoto)),

    % Supuesto de latencia de remotos (ms)
    assertz(latencia(r1, 1500)),
    assertz(latencia(r2, 2200)),
    assertz(latencia(r3, 1800)),

    % --- Situación 3: Lote 2 (reserva y báscula) ---
    assertz(precio_vigente(l2, 60)),
    assertz(reserva(l2, 24000, 0)),
    assertz(reserva(l2, 21000, 45000)), % Baja la reserva en pleno remate
    assertz(lectura(l2, peso_lote_kg, 350, 46000)),
    assertz(puja(p201, s1, l2, 62, 47000, 47000)),
    assertz(evento(1, l2, abierto, 40000)),
    assertz(evento(2, l2, llamada, 48000)),

    % --- Situación 1: Lote 4 (martillazo / escalones / remotos) ---
    assertz(precio_vigente(l4, 54)),
    assertz(reserva(l4, 15000, 0)),
    assertz(lectura(l4, peso_lote_kg, 400, 58000)),
    % s2 puja por escalón vigente (54) al llegar a "a las tres" (60000)
    assertz(puja(p401, s2, l4, 54, 60000, 60000)),
    % r1 puja por escalón anterior (52) con reloj cliente atrasado (57000) pero llega en 60000
    assertz(puja(p402, r1, l4, 52, 57000, 60000)),
    % r2 manda puja 2000 ms después de adjudicado (62000)
    assertz(puja(p403, r2, l4, 56, 59800, 62000)),
    assertz(evento(3, l4, abierto, 55000)),
    assertz(evento(4, l4, llamada, 60000)),
    assertz(evento(5, l4, adjudicado, 60000)),

    % --- Situación 4: Lote 5 (retiro con puja líder, "a las dos", reinicio y hueco) ---
    % Nota: faltan seq 7 y 8 (hueco de bitácora) antes de seq 9 (reinicio)
    assertz(precio_vigente(l5, 50)),
    assertz(reserva(l5, 12000, 0)),
    assertz(lectura(l5, peso_lote_kg, 360, 72000)),
    assertz(puja(p501, r3, l5, 50, desconocida, 73000)),
    assertz(evento(6, l5, abierto, 70000)),
    assertz(evento(9, l5, reinicio, 76000)),

    % --- Situación 5: Lote 6 (animales y documentos por animal) ---
    assertz(animal(sin_001, l6)),
    assertz(documento(arete, sin_001, siniiga, vigente_2027)),
    assertz(documento(sanitario, sin_001, senasica_l6, vigente_2027)),
    assertz(documento(transito, sin_001, estado_son, vigente_2027)),

    assertz(animal(sin_002, l6)),
    assertz(documento(arete, sin_002, siniiga, vigente_2027)),
    assertz(documento(sanitario, sin_002, senasica_l6, vigente_2027)),
    assertz(documento(transito, sin_002, estado_son, desconocida)), % vigencia no legible -> no_se_sabe

    assertz(animal(sin_003, l6)),
    assertz(documento(arete, sin_003, siniiga, vigente_2027)),
    assertz(documento(sanitario, sin_003, senasica_otro_lote, vigente_2027)). % falta transito y certificado es de otro lote

:- initialization(cargar_escenario_base).
