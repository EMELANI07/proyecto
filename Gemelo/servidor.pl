% Servidor HTTP del gemelo. No contiene reglas: solo expone lo que decide reglas.pl.
:- module(servidor, [iniciar/0, iniciar/1]).

:- encoding(utf8).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_parameters)).
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
historias(Lote, Vista, Historias) :-
    findall(H,
            (   decide(Lote, Dec, ExpCompleta),
                (   Vista == auditor
                ->  Exp = ExpCompleta
                ;   once(decide_publica(Lote, Dec, Exp))
                ),
                once(que_falta_para_cambiar(Lote, Dec, Falta)),
                a_json(Dec, DecJ),
                a_json(Exp, ExpJ),
                a_json(Falta, FaltaJ),
                H = _{decision: DecJ, explicacion: ExpJ, que_falta: FaltaJ}
            ),
            Historias).

manejar_estado(_Request) :-
    ahora(Ahora),
    findall(_{
        id: Lote,
        vendedor: Vendedor,
        orden: Orden,
        historias_publicas: HistPub,
        historias_auditor: HistAud
    }, (
        lote(Lote, Vendedor, Orden),
        historias(Lote, publica, HistPub),
        historias(Lote, auditor, HistAud)
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
    historias(LoteAtom, VistaAtom, Historias),
    (   Historias = [Primera | _]
    ->  true
    ;   Primera = _{decision: null, explicacion: [], que_falta: []}
    ),
    reply_json_dict(_{
        lote: LoteAtom,
        vista: VistaAtom,
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
