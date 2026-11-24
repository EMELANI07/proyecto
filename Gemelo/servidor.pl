% Servidor HTTP del gemelo. No contiene reglas: solo expone lo que decide reglas.pl.
:- module(servidor, [iniciar/0, iniciar/1]).

:- encoding(utf8).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_client)).
:- use_module(library(lists)).
:- use_module(library(main)).
:- use_module(hechos).
:- use_module(reglas).

% web/ se resuelve respecto a este archivo, no al directorio desde donde se lanza swipl.
:- dynamic web_dir/1.
:- prolog_load_context(directory, Dir),
   directory_file_path(Dir, web, WebDir),
   asserta(web_dir(WebDir)).

:- http_handler(root(.), servir_web, [prefix]).
:- http_handler(root('api/estado'), manejar_estado, []).
:- http_handler(root('api/decision'), manejar_decision, []).
:- http_handler(root('api/puja'), manejar_puja, [method(post)]).
:- http_handler(root('api/evento'), manejar_evento, [method(post)]).
:- http_handler(root('api/reloj'), manejar_reloj, [method(post)]).
:- http_handler(root('api/reiniciar'), manejar_reiniciar, [method(post)]).

iniciar :-
    iniciar(8080).

iniciar(Puerto) :-
    http_server(http_dispatch, [port(Puerto)]),
    format('Gemelo de subasta escuchando en http://localhost:~w~n', [Puerto]).

servir_web(Request) :-
    web_dir(Dir),
    http_reply_from_files(Dir, [index('index.html')], Request).

% -------------------------------------------------------------------------
% Serializacion: JSON no representa terminos compuestos de Prolog.
% Atomos, numeros y cadenas pasan igual; un termino compuesto viaja como texto.
% -------------------------------------------------------------------------

a_json(Term, Json) :-
    (   is_list(Term)
    ->  maplist(a_json, Term, Json)
    ;   atomic(Term)
    ->  Json = Term
    ;   term_string(Term, Json)
    ).

% Un lote puede tener varias historias compatibles (Situacion 4); se devuelven todas.
% La vista publica sale de decide_publica/3: el filtrado lo hace Prolog, no el navegador.
historias(Lote, Vista, Historias) :-
    findall(H,
            (   decide(Lote, Dec, ExpCompleta),
                (   Vista == auditor
                ->  Exp = ExpCompleta
                ;   once(decide_publica(Lote, Dec, Exp))
                ),
                once(que_falta_para_cambiar(Lote, Dec, Falta)),
                (   etapa_lote(Lote, sin_eventos)
                ->  Resumen = 'Sin subasta registrada: este lote solo tiene datos de corral.'
                ;   resumen_decision(Dec, Resumen)
                ),
                maplist(texto_requisito, Falta, FaltaTxt),
                a_json(Dec, DecJ),
                a_json(Exp, ExpJ),
                H = _{resumen: Resumen, decision: DecJ, explicacion: ExpJ, que_falta: FaltaTxt}
            ),
            Historias).

vista_valida(auditor, auditor) :- !.
vista_valida(_, publica).

lote_json(Lote, Vendedor, Orden, Vista, Json) :-
    etapa_lote(Lote, Etapa),
    (   precio_vigente(Lote, Vigente) -> true ; Vigente = null ),
    historias(Lote, Vista, Historias),
    Base = _{id: Lote, vendedor: Vendedor, orden: Orden, etapa: Etapa,
             precio_vigente: Vigente, historias: Historias},
    (   Vista == auditor,
        ahora(Ahora),
        precio_kilo_minimo_reserva(Lote, Ahora, Minimo)
    ->  put_dict(reserva_minima_por_kilo, Base, Minimo, Json)
    ;   Json = Base
    ).

postor_json(Id, _{id: Id, modalidad: Modalidad, latencia_ms: Latencia}) :-
    postor(Id, Modalidad),
    (   latencia(Id, Latencia) -> true ; Latencia = null ).

puja_json(_{id: Id, postor: Postor, lote: Lote, precio: Precio,
            emision: Emision, llegada: Llegada,
            veredicto: Veredicto, evidencia: EvJ}) :-
    puja(Id, Postor, Lote, Precio, Emision, Llegada),
    evaluar_puja(Id, Veredicto, Evidencia),
    a_json(Evidencia, EvJ).

manejar_estado(Request) :-
    http_parameters(Request, [vista(VistaTxt, [atom, default(publica)])]),
    vista_valida(VistaTxt, Vista),
    ahora(Ahora),
    findall(L, (lote(Lote, Vend, Orden), lote_json(Lote, Vend, Orden, Vista, L)), LotesJson),
    findall(P, postor_json(_, P), PostoresJson),
    findall(J, puja_json(J), PujasJson),
    huecos_bitacora(Huecos),
    findall(_{seq: S, lote: L, suceso: Su, ms: M}, evento(S, L, Su, M), EventosJson),
    reply_json_dict(_{
        vista: Vista,
        ahora_ms: Ahora,
        huecos_bitacora: Huecos,
        lotes: LotesJson,
        postores: PostoresJson,
        pujas: PujasJson,
        eventos: EventosJson
    }).

% -------------------------------------------------------------------------
% Escritura: el cuerpo es JSON; toda la validacion la hace reglas.pl.
% -------------------------------------------------------------------------

leer_json(Request, Dict) :-
    catch(http_read_json_dict(Request, Dict, [value_string_as(atom)]), _, fail).

cuerpo_invalido(Mensaje) :-
    reply_json_dict(_{ok: false, error: Mensaje}, [status(400)]).

responder(error(Motivo)) :- !,
    a_json(Motivo, MotivoJ),
    reply_json_dict(_{ok: false, error: MotivoJ}, [status(422)]).
responder(resultado(Id, Veredicto, Evidencia)) :- !,
    a_json(Evidencia, EvJ),
    ahora(Ahora),
    reply_json_dict(_{ok: true, id: Id, veredicto: Veredicto, evidencia: EvJ, ahora_ms: Ahora}).
responder(evento(Seq, Lote, Suceso, Ms)) :- !,
    reply_json_dict(_{ok: true, seq: Seq, lote: Lote, suceso: Suceso, ms: Ms}).
responder(ahora(Ms)) :-
    reply_json_dict(_{ok: true, ahora_ms: Ms}).

manejar_puja(Request) :-
    (   leer_json(Request, D),
        get_dict(lote, D, Lote),
        get_dict(postor, D, Postor),
        get_dict(precio, D, Precio)
    ->  registrar_puja(Postor, Lote, Precio, Resultado),
        responder(Resultado)
    ;   cuerpo_invalido('Se espera JSON con lote, postor y precio')
    ).

manejar_evento(Request) :-
    (   leer_json(Request, D),
        get_dict(lote, D, Lote),
        get_dict(suceso, D, Suceso)
    ->  registrar_evento(Lote, Suceso, Resultado),
        responder(Resultado)
    ;   cuerpo_invalido('Se espera JSON con lote y suceso')
    ).

manejar_reloj(Request) :-
    (   leer_json(Request, D),
        get_dict(avanzar_ms, D, Delta)
    ->  avanzar_reloj(Delta, Resultado),
        responder(Resultado)
    ;   cuerpo_invalido('Se espera JSON con avanzar_ms')
    ).

descartar_cuerpo(Request) :-
    (   catch(http_read_data(Request, _, [to(atom)]), _, fail)
    ->  true
    ;   true
    ).

% Se consume el cuerpo aunque no se use: si quedara sin leer, en una conexion
% persistente se pegaria a la siguiente peticion y esta recibiria un 400.
manejar_reiniciar(Request) :-
    descartar_cuerpo(Request),
    reiniciar_escenario,
    ahora(Ms),
    reply_json_dict(_{ok: true, ahora_ms: Ms}).

manejar_decision(Request) :-
    http_parameters(Request, [
        lote(LoteAtom, [atom]),
        vista(VistaAtom, [atom, default(publica)])
    ]),
    vista_valida(VistaAtom, Vista),
    historias(LoteAtom, Vista, Historias),
    (   Historias = [Primera | _]
    ->  true
    ;   Primera = _{resumen: 'Sin resumen disponible.', decision: null, explicacion: [], que_falta: []}
    ),
    reply_json_dict(_{
        lote: LoteAtom,
        vista: Vista,
        resumen: Primera.resumen,
        decision: Primera.decision,
        explicacion: Primera.explicacion,
        que_falta: Primera.que_falta,
        historias: Historias
    }).

% Arranque: swipl servidor.pl [Puerto]
% Se queda escuchando sin necesitar terminal interactiva, asi que tambien
% funciona en segundo plano: nohup swipl servidor.pl > servidor.log 2>&1 &
:- initialization(main, main).

main(Argv) :-
    (   Argv = [PuertoTxt | _],
        atom_number(PuertoTxt, Puerto)
    ->  true
    ;   Puerto = 8080
    ),
    iniciar(Puerto),
    thread_get_message(_).
