:- module(servidor, [iniciar/0, iniciar/1]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_parameters)).
:- use_module(hechos).
:- use_module(reglas).

:- http_handler(root(.), http_reply_from_files('web', [index('index.html')]), [prefix]).
:- http_handler(root('api/estado'), manejar_estado, []).
:- http_handler(root('api/decision'), manejar_decision, []).

iniciar :-
    iniciar(8080).

iniciar(Puerto) :-
    http_server(http_dispatch, [port(Puerto)]),
    format('Gemelo de subasta escuchando en http://localhost:~w~n', [Puerto]).

manejar_estado(_Request) :-
    ahora(Ahora),
    findall(_{
        id: Lote,
        vendedor: Vendedor,
        orden: Orden,
        decision: Dec,
        explicacion_publica: ExpPub,
        explicacion_completa: ExpComp,
        que_falta: Falta
    }, (
        lote(Lote, Vendedor, Orden),
        decide(Lote, Dec, ExpComp),
        decide_publica(Lote, Dec, ExpPub),
        que_falta_para_cambiar(Lote, Dec, Falta)
    ), LotesJson),
    huecos_bitacora(Huecos),
    findall(_{seq: S, lote: L, suceso: Su, ms: M}, evento(S, L, Su, M), EventosJson),
    reply_json_dict(_{
        ahora_ms: Ahora,
        huecos_bitacora: Huecos,
        lotes: LotesJson,
        eventos: EventosJson
    }).

manejar_decision(Request) :-
    http_parameters(Request, [
        lote(LoteAtom, [atom]),
        vista(VistaAtom, [atom, default(publica)])
    ]),
    (   VistaAtom == auditor
    ->  decide(LoteAtom, Dec, Exp)
    ;   decide_publica(LoteAtom, Dec, Exp)
    ),
    que_falta_para_cambiar(LoteAtom, Dec, Falta),
    reply_json_dict(_{
        lote: LoteAtom,
        vista: VistaAtom,
        decision: Dec,
        explicacion: Exp,
        que_falta: Falta
    }).

:- initialization(iniciar(8080), program).
