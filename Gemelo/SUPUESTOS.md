diff --git a/Gemelo/SUPUESTOS.md b/Gemelo/SUPUESTOS.md
index b118110..41ddc05 100644
--- a/Gemelo/SUPUESTOS.md
+++ b/Gemelo/SUPUESTOS.md
@@ -11,3 +11,9 @@
 * *Retiro y reinicio:* Un lote puede pasar a retirado antes de adjudicarse; si hay hueco en la bitácora alrededor de un reinicio o llamada ("a las dos" / "a las tres"), decide/3 genera las historias compatibles mediante backtracking.
 
 * *Documentos por animal:* Cada animal requiere arete, sanitario y transito con vigencia conocida (vigente(...) / distinta de desconocida); desconocida produce no_se_sabe (nunca si), y faltante produce no.
+
+* *Huecos de bitacora por lote:* Un hueco en la secuencia de eventos afecta a un lote solo si el evento inmediatamente anterior o el inmediatamente posterior al hueco pertenece a ese lote. Un hueco entre eventos de otros lotes no vuelve no_se_sabe las pujas de un lote sin hueco (huecos_bitacora_lote/2). huecos_bitacora/1 sigue dando la vista global.
+
+* *Escalon vigente del ejemplo l2:* precio_vigente(l2, 62) es un valor de ejemplo (supuesto del ejercicio, no una estadistica real); se fijo en 62 para que sea coherente con la puja p201 del mismo escenario.
+
+* *Documentos por animal (precedencia):* si un animal tiene un documento faltante y otro con vigencia desconocida, el estado del animal es no (el faltante es cierto); no_se_sabe solo aplica cuando no hay faltantes.
diff --git a/Gemelo/hechos.pl b/Gemelo/hechos.pl
index 3aeb4ce..588d571 100644
--- a/Gemelo/hechos.pl
+++ b/Gemelo/hechos.pl
@@ -1,4 +1,4 @@
-% solo datos. El “ahora” es un hecho en milisegundos (no el reloj del sistema).
+% Solo datos. El "ahora" es un hecho en milisegundos (no el reloj del sistema).
 :- module(hechos, [
     ahora/1,
     lote/3,
@@ -16,6 +16,8 @@
     cargar_escenario_base/0
 ]).
 
+:- encoding(utf8).
+
 :- dynamic ahora/1.
 :- dynamic lote/3.
 :- dynamic animal/2.
@@ -80,7 +82,8 @@ cargar_escenario_base :-
     assertz(latencia(r3, 1800)),
 
     % --- Situación 3: Lote 2 (reserva y báscula) ---
-    assertz(precio_vigente(l2, 60)),
+    % Escalon vigente de l2 al llegar p201 (47000 ms): 62 $/kg (supuesto del ejemplo).
+    assertz(precio_vigente(l2, 62)),
     assertz(reserva(l2, 24000, 0)),
     assertz(reserva(l2, 21000, 45000)), % Baja la reserva en pleno remate
     assertz(lectura(l2, peso_lote_kg, 350, 46000)),
diff --git a/Gemelo/reglas.pl b/Gemelo/reglas.pl
index e776039..c4c3169 100644
--- a/Gemelo/reglas.pl
+++ b/Gemelo/reglas.pl
@@ -1,9 +1,10 @@
-% aquí vivirán todas las decisiones del dominio
+% Aqui viviran todas las decisiones del dominio.
 :- module(reglas, [
     decide/3,
     decide_publica/3,
     situacion/3,
     huecos_bitacora/1,
+    huecos_bitacora_lote/2,
     precio_kilo_minimo_reserva/3,
     que_falta_para_cambiar/3,
     condicion_cumple/3,
@@ -11,6 +12,8 @@
     hipotesis_retraso/4
 ]).
 
+:- encoding(utf8).
+
 :- use_module(hechos).
 :- use_module(library(lists)).
 
@@ -50,6 +53,7 @@ condicion_cumple(puja_antes_de_adjudicar(PujaId), Estado, Evidencia) :-
 
 condicion_cumple(puja_antes_desconexion(PujaId), Estado, Evidencia) :-
     puja(PujaId, _, Lote, _, Emision, Llegada),
+    huecos_bitacora_lote(Lote, HuecosLote),
     (   evento(_, Lote, conexion_perdida, MsCorte)
     ->  (   Llegada < MsCorte
         ->  Estado = si,
@@ -61,10 +65,10 @@ condicion_cumple(puja_antes_desconexion(PujaId), Estado, Evidencia) :-
             Evidencia = [llegada_en_limite_conexion(PujaId, Llegada, MsCorte)]
         )
     ;   (   Emision == desconocida
-        ;   (huecos_bitacora(H), H \= [])
+        ;   HuecosLote \== []
         )
     ->  Estado = no_se_sabe,
-        Evidencia = [confirmacion_o_bitacora_incompleta(PujaId, emision(Emision))]
+        Evidencia = [confirmacion_o_bitacora_incompleta(PujaId, emision(Emision), huecos_lote(HuecosLote))]
     ;   Estado = si,
         Evidencia = [sin_desconexion_registrada(PujaId, Llegada)]
     ).
@@ -95,8 +99,7 @@ condicion_cumple(reserva_cubierta(Lote, PrecioPorKilo, Instante), Estado, Eviden
     (   EstadoPeso \= si
     ->  Estado = no_se_sabe,
         Evidencia = [reserva_pendiente_de_peso(Lote) | EvPeso]
-    ;   lectura(Lote, peso_lote_kg, Peso, _),
-        number(Peso), Peso > 0,
+    ;   EvPeso = [peso_confirmado(_, Peso, _)],
         reserva_vigente(Lote, Instante, MontoReserva, Desde),
         Total is Peso * PrecioPorKilo,
         (   Total >= MontoReserva
@@ -122,20 +125,35 @@ evaluar_animales([Arete | Resto], [animal_doc(Arete, EstadoA, EvsA) | R2]) :-
     evaluar_docs_animal(Arete, [arete, sanitario, transito], Docs, EstadoA, EvsA),
     evaluar_animales(Resto, R2).
 
-evaluar_docs_animal(_, [], _, si, []).
-evaluar_docs_animal(Arete, [Tipo | Resto], Docs, Estado, Evs) :-
-    (   member(doc(Tipo, Emisor, Vig), Docs)
+evaluar_docs_animal(Arete, Tipos, Docs, Estado, Evs) :-
+    findall(E-Ev,
+            (   member(Tipo, Tipos),
+                evaluar_doc(Arete, Tipo, Docs, E, Ev)
+            ),
+            Pares),
+    pairs_keys_values(Pares, Estados, ListasEv),
+    append(ListasEv, Evs),
+    peor_estado(Estados, Estado).
+
+evaluar_doc(Arete, Tipo, Docs, Estado, Evs) :-
+    (   memberchk(doc(Tipo, Emisor, Vig), Docs)
     ->  (   Vig == desconocida
         ->  Estado = no_se_sabe,
-            Evs = [vigencia_desconocida(animal(Arete), doc(Tipo), emisor(Emisor)) | EvResto],
-            evaluar_docs_animal(Arete, Resto, Docs, _, EvResto)
-        ;   evaluar_docs_animal(Arete, Resto, Docs, EstadoResto, EvResto),
-            Estado = EstadoResto,
-            Evs = EvResto
+            Evs = [vigencia_desconocida(animal(Arete), doc(Tipo), emisor(Emisor))]
+        ;   Estado = si,
+            Evs = []
         )
     ;   Estado = no,
-        Evs = [falta_documento(animal(Arete), doc(Tipo)) | EvResto],
-        evaluar_docs_animal(Arete, Resto, Docs, _, EvResto)
+        Evs = [falta_documento(animal(Arete), doc(Tipo))]
+    ).
+
+% Un faltante cierto (no) domina a una vigencia desconocida (no_se_sabe).
+peor_estado(Estados, Estado) :-
+    (   memberchk(no, Estados)
+    ->  Estado = no
+    ;   memberchk(no_se_sabe, Estados)
+    ->  Estado = no_se_sabe
+    ;   Estado = si
     ).
 
 combinar_documentos(Detalles, Estado, Evidencia) :-
@@ -171,22 +189,48 @@ max_desde([d(D1, M1), d(D2, M2) | Resto], Max) :-
 % 2. Bitácora y huecos
 % -------------------------------------------------------------------------
 
+% huecos_bitacora(-Huecos): numeros de secuencia faltantes en toda la bitacora.
 huecos_bitacora(Huecos) :-
-    findall(Seq, evento(Seq, _, _, _), Raw),
-    sort(Raw, Seqs),
-    buscar_huecos(Seqs, Huecos).
+    huecos_con_vecinos(Gaps),
+    findall(Falt, member(hueco(Falt, _, _), Gaps), Listas),
+    append(Listas, Huecos).
+
+% huecos_bitacora_lote(+Lote, -Huecos): solo los huecos que tocan al lote.
+% Supuesto declarado (SUPUESTOS.md): un hueco afecta a un lote si el evento
+% inmediatamente anterior o el inmediatamente posterior al hueco es de ese lote.
+% Un hueco entre eventos de otros lotes no invalida las pujas de este lote.
+huecos_bitacora_lote(Lote, Huecos) :-
+    huecos_con_vecinos(Gaps),
+    findall(Falt,
+            (   member(hueco(Falt, LoteAntes, LoteDespues), Gaps),
+                (   LoteAntes == Lote
+                ->  true
+                ;   LoteDespues == Lote
+                )
+            ),
+            Listas),
+    append(Listas, Huecos).
+
+% huecos_con_vecinos(-Gaps): Gaps = [hueco(Faltantes, LoteAntes, LoteDespues)]
+huecos_con_vecinos(Gaps) :-
+    findall(Seq-Lote, evento(Seq, Lote, _, _), Raw),
+    sort(1, @<, Raw, Ordenados),
+    buscar_huecos(Ordenados, Gaps).
 
 buscar_huecos([], []).
-buscar_huecos([_], []).
-buscar_huecos([A, B | Resto], Huecos) :-
+buscar_huecos([Primero | Resto], Gaps) :-
+    buscar_huecos_(Resto, Primero, Gaps).
+
+buscar_huecos_([], _, []).
+buscar_huecos_([B-LB | Resto], A-LA, Gaps) :-
     Sig is A + 1,
     (   B > Sig
     ->  Fin is B - 1,
         numlist(Sig, Fin, Falt),
-        append(Falt, HResto, Huecos),
-        buscar_huecos([B | Resto], HResto)
-    ;   buscar_huecos([B | Resto], Huecos)
-    ).
+        Gaps = [hueco(Falt, LA, LB) | GResto]
+    ;   Gaps = GResto
+    ),
+    buscar_huecos_(Resto, B-LB, GResto).
 
 % -------------------------------------------------------------------------
 % 3. situacion(?Entidad, ?Situacion, -Evidencia)
@@ -228,12 +272,11 @@ decide(Lote, Decision, Explicacion) :-
     (   \+ lote(Lote, _, _)
     ->  Decision = invalido(lote_inexistente(Lote)),
         Explicacion = [error(lote_no_registrado(Lote))]
-    ;   huecos_bitacora(Huecos),
-        member(_, Huecos),
+    ;   huecos_bitacora_lote(Lote, Huecos),
+        Huecos \== [],
         evento(_, Lote, reinicio, MsReinicio)
     ->  % Historias compatibles ante hueco + reinicio (Situación 4)
-        (   Historia = retirada_antes_de_cierre_y_reinicio,
-            Decision = secuencia_etapas([abierto, llamada_a_las_dos, retirado], sin_ganador),
+        (   Decision = secuencia_etapas([abierto, llamada_a_las_dos, retirado], sin_ganador),
             Explicacion = [
                 historia_compatible(retirada_antes_de_cierre_y_reinicio),
                 reinicio_registrado(MsReinicio),
@@ -242,8 +285,7 @@ decide(Lote, Decision, Explicacion) :-
                 afecta(postor_lider_sin_compromiso_final),
                 registro_que_decide(evento_retiro_o_llamada_a_las_tres_con_seq_faltante)
             ]
-        ;   Historia = llamada_a_las_tres_antes_de_retiro,
-            Decision = secuencia_etapas([abierto, llamada_a_las_dos, llamada_a_las_tres, adjudicado_o_disputado], revision_requerida),
+        ;   Decision = secuencia_etapas([abierto, llamada_a_las_dos, llamada_a_las_tres, adjudicado_o_disputado], revision_requerida),
             Explicacion = [
                 historia_compatible(llamada_a_las_tres_antes_de_retiro),
                 reinicio_registrado(MsReinicio),
@@ -266,10 +308,7 @@ decide_sin_hueco_critico(Lote, Decision, Explicacion) :-
             Validas),
     findall(Id,
             (   puja(Id, _, Lote, _, _, _),
-                (   condicion_cumple(puja_antes_de_adjudicar(Id), no, _)
-                ;   condicion_cumple(puja_en_escalon_vigente(Id), no, _)
-                ;   condicion_cumple(puja_antes_desconexion(Id), no, _)
-                )
+                once(puja_rechazada(Id))
             ),
             Rechazadas),
     (   Validas == []
@@ -310,6 +349,13 @@ decide_sin_hueco_critico(Lote, Decision, Explicacion) :-
         )
     ).
 
+% Una puja rechazada puede incumplir varias condiciones; se cuenta una sola vez.
+puja_rechazada(Id) :-
+    (   condicion_cumple(puja_antes_de_adjudicar(Id), no, _)
+    ;   condicion_cumple(puja_en_escalon_vigente(Id), no, _)
+    ;   condicion_cumple(puja_antes_desconexion(Id), no, _)
+    ).
+
 ordenar_pujas(Pujas, Ordenadas) :-
     predsort(cmp_puja, Pujas, Ordenadas).
 
@@ -343,8 +389,7 @@ filtrar_publica([Item | Resto], [Item | Filtrada]) :-
 % -------------------------------------------------------------------------
 
 precio_kilo_minimo_reserva(Lote, Instante, PrecioMinimo) :-
-    lectura(Lote, peso_lote_kg, Peso, _),
-    number(Peso), Peso > 0,
+    condicion_cumple(peso_valido(Lote), si, [peso_confirmado(_, Peso, _)]),
     reserva_vigente(Lote, Instante, MontoReserva, _),
     PrecioMinimo is MontoReserva / Peso.
 
diff --git a/Gemelo/servidor.pl b/Gemelo/servidor.pl
index 13460ff..ae6eb0f 100644
--- a/Gemelo/servidor.pl
+++ b/Gemelo/servidor.pl
@@ -1,14 +1,24 @@
+% Servidor HTTP del gemelo. No contiene reglas: solo expone lo que decide reglas.pl.
 :- module(servidor, [iniciar/0, iniciar/1]).
 
+:- encoding(utf8).
+
 :- use_module(library(http/thread_httpd)).
 :- use_module(library(http/http_dispatch)).
 :- use_module(library(http/http_json)).
 :- use_module(library(http/http_files)).
 :- use_module(library(http/http_parameters)).
+:- use_module(library(lists)).
 :- use_module(hechos).
 :- use_module(reglas).
 
-:- http_handler(root(.), http_reply_from_files('web', [index('index.html')]), [prefix]).
+% web/ se resuelve respecto a este archivo, no al directorio desde donde se lanza swipl.
+:- dynamic web_dir/1.
+:- prolog_load_context(directory, Dir),
+   directory_file_path(Dir, web, WebDir),
+   asserta(web_dir(WebDir)).
+
+:- http_handler(root(.), servir_web, [prefix]).
 :- http_handler(root('api/estado'), manejar_estado, []).
 :- http_handler(root('api/decision'), manejar_decision, []).
 
@@ -19,21 +29,51 @@ iniciar(Puerto) :-
     http_server(http_dispatch, [port(Puerto)]),
     format('Gemelo de subasta escuchando en http://localhost:~w~n', [Puerto]).
 
+servir_web(Request) :-
+    web_dir(Dir),
+    http_reply_from_files(Dir, [index('index.html')], Request).
+
+% -------------------------------------------------------------------------
+% Serializacion: JSON no representa terminos compuestos de Prolog.
+% Atomos, numeros y cadenas pasan igual; un termino compuesto viaja como texto.
+% -------------------------------------------------------------------------
+
+a_json(Term, Json) :-
+    (   is_list(Term)
+    ->  maplist(a_json, Term, Json)
+    ;   atomic(Term)
+    ->  Json = Term
+    ;   term_string(Term, Json)
+    ).
+
+% Un lote puede tener varias historias compatibles (Situacion 4); se devuelven todas.
+historias(Lote, Vista, Historias) :-
+    findall(H,
+            (   decide(Lote, Dec, ExpCompleta),
+                (   Vista == auditor
+                ->  Exp = ExpCompleta
+                ;   once(decide_publica(Lote, Dec, Exp))
+                ),
+                once(que_falta_para_cambiar(Lote, Dec, Falta)),
+                a_json(Dec, DecJ),
+                a_json(Exp, ExpJ),
+                a_json(Falta, FaltaJ),
+                H = _{decision: DecJ, explicacion: ExpJ, que_falta: FaltaJ}
+            ),
+            Historias).
+
 manejar_estado(_Request) :-
     ahora(Ahora),
     findall(_{
         id: Lote,
         vendedor: Vendedor,
         orden: Orden,
-        decision: Dec,
-        explicacion_publica: ExpPub,
-        explicacion_completa: ExpComp,
-        que_falta: Falta
+        historias_publicas: HistPub,
+        historias_auditor: HistAud
     }, (
         lote(Lote, Vendedor, Orden),
-        decide(Lote, Dec, ExpComp),
-        decide_publica(Lote, Dec, ExpPub),
-        que_falta_para_cambiar(Lote, Dec, Falta)
+        historias(Lote, publica, HistPub),
+        historias(Lote, auditor, HistAud)
     ), LotesJson),
     huecos_bitacora(Huecos),
     findall(_{seq: S, lote: L, suceso: Su, ms: M}, evento(S, L, Su, M), EventosJson),
@@ -49,17 +89,18 @@ manejar_decision(Request) :-
         lote(LoteAtom, [atom]),
         vista(VistaAtom, [atom, default(publica)])
     ]),
-    (   VistaAtom == auditor
-    ->  decide(LoteAtom, Dec, Exp)
-    ;   decide_publica(LoteAtom, Dec, Exp)
+    historias(LoteAtom, VistaAtom, Historias),
+    (   Historias = [Primera | _]
+    ->  true
+    ;   Primera = _{decision: null, explicacion: [], que_falta: []}
     ),
-    que_falta_para_cambiar(LoteAtom, Dec, Falta),
     reply_json_dict(_{
         lote: LoteAtom,
         vista: VistaAtom,
-        decision: Dec,
-        explicacion: Exp,
-        que_falta: Falta
+        decision: Primera.decision,
+        explicacion: Primera.explicacion,
+        que_falta: Primera.que_falta,
+        historias: Historias
     }).
 
 :- initialization(iniciar(8080), program).
diff --git a/Gemelo/tests/reglas_tests.pl b/Gemelo/tests/reglas_tests.pl
index 789d75e..1bd6e80 100644
--- a/Gemelo/tests/reglas_tests.pl
+++ b/Gemelo/tests/reglas_tests.pl
@@ -1,28 +1,20 @@
-% se escriben antes que las reglas.
-:- module(reglas_tests, [run_tests/0]).
+% Pruebas plunit del gemelo digital. Ejecutar desde Gemelo/ con:
+%   swipl -g run_tests -t halt tests/reglas_tests.pl
+:- encoding(utf8).
 
 :- use_module(library(plunit)).
 :- use_module('../hechos').
 :- use_module('../reglas').
 
-run_tests :-
-    run_tests([
-        sit1_martillazo_l4,
-        sit2_desconexion_compromiso,
-        sit3_reserva_bascula_l2,
-        sit4_retiro_hueco_l5,
-        sit5_corral_documentos_l6
-    ]).
-
 :- begin_tests(sit1_martillazo_l4).
 
 test(l4_adjudica_a_s2_y_rechaza_remotos) :-
     cargar_escenario_base,
     decide(l4, Decision, Explicacion),
-    assertion(Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado], ganador(s2, puja(p401), precio_kilo(54)))),
-    assertion(member(pujas_no_aceptadas_o_tardias(Rech), Explicacion)),
-    assertion(member(p402, Rech)),
-    assertion(member(p403, Rech)).
+    assertion(Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado],
+                                          ganador(s2, puja(p401), precio_kilo(54)))),
+    memberchk(pujas_no_aceptadas_o_tardias(Rech), Explicacion),
+    assertion(Rech == [p402, p403]).
 
 :- end_tests(sit1_martillazo_l4).
 
@@ -33,21 +25,37 @@ test(puja_con_emision_desconocida_da_en_duda) :-
     condicion_cumple(puja_antes_desconexion(p501), Estado, _),
     assertion(Estado == no_se_sabe).
 
+test(hueco_en_otro_lote_no_invalida_puja_de_l4) :-
+    cargar_escenario_base,
+    condicion_cumple(puja_antes_desconexion(p401), Estado, _),
+    assertion(Estado == si).
+
+test(hueco_de_bitacora_solo_toca_a_l5) :-
+    cargar_escenario_base,
+    huecos_bitacora_lote(l5, H5),
+    huecos_bitacora_lote(l4, H4),
+    huecos_bitacora_lote(l2, H2),
+    assertion(H5 == [7, 8]),
+    assertion(H4 == []),
+    assertion(H2 == []).
+
 :- end_tests(sit2_desconexion_compromiso).
 
 :- begin_tests(sit3_reserva_bascula_l2).
 
-test(l2_350kg_por_62_es_21700_no_cumple_reserva_24000_en_47000ms) :-
+% En 47000 ms rige la reserva de 21000 (vigente desde 45000 ms); la de 24000
+% ya no aplica. 350 kg * 62 = 21700 >= 21000, asi que se adjudica.
+test(l2_350kg_por_62_es_21700_cumple_reserva_21000_en_47000ms) :-
     cargar_escenario_base,
-    % En 47000 ms rige reserva de 24000 (la de 21000 rige desde 45000? No: 45000 =< 47000, así que rige 21000!)
-    % 350 * 62 = 21700 >= 21000 -> cumple reserva vigente desde 45000 ms
     decide(l2, Decision, _),
-    assertion(Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado], ganador(s1, puja(p201), precio_kilo(62)))).
+    assertion(Decision = secuencia_etapas([abierto, ultima_llamada, adjudicado],
+                                          ganador(s1, puja(p201), precio_kilo(62)))).
 
 test(precio_kilo_minimo_para_reserva_24000_en_350kg) :-
     cargar_escenario_base,
     precio_kilo_minimo_reserva(l2, 44000, Min),
-    assertion(Min > 68.5, Min < 68.6).
+    assertion(Min > 68.5),
+    assertion(Min < 68.6).
 
 :- end_tests(sit3_reserva_bascula_l2).
 
@@ -65,9 +73,9 @@ test(l5_con_hueco_y_reinicio_ofrece_mas_de_una_historia) :-
 test(l6_no_puede_salir_por_vigencia_desconocida_y_falta_documento) :-
     cargar_escenario_base,
     lotes_no_pueden_salir(Lotes),
-    assertion(member(l6, Lotes)),
+    assertion(memberchk(l6, Lotes)),
     condicion_cumple(documentos_lote(l6), Estado, Ev),
     assertion(Estado == no),
-    assertion(member(falta_documento(animal(sin_003), doc(transito)), Ev)).
+    assertion(memberchk(falta_documento(animal(sin_003), doc(transito)), Ev)).
 
 :- end_tests(sit5_corral_documentos_l6).
