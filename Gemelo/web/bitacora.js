/* Pantalla "Bitácora Seq".
 * Muestra los eventos y los huecos que reporta Prolog; no detecta nada por su cuenta.
 */
(function () {
  'use strict';
  var G = window.Gemelo;
  var esc = G.esc;
  var estado = null;
  var filtro = 'todos';

  var TEXTO_SUCESO = {
    abierto: 'Lote abierto a pujas.',
    llamada: 'Llamada del martillero.',
    adjudicado: 'Adjudicado (martillazo).',
    retirado: 'Lote retirado.',
    reinicio: 'Reinicio del registro.',
    conexion_perdida: 'Se perdió la conexión.'
  };
  var VEREDICTOS = {
    valida: { texto: 'Válida', clase: 'bg-secondary-container/20 text-secondary' },
    rechazada: { texto: 'Rechazada', clase: 'bg-error-container/40 text-error' },
    en_duda: { texto: 'En duda', clase: 'bg-primary-container/30 text-primary' }
  };

  function pintarMonitor() {
    var huecos = estado.huecos_bitacora || [];
    var seqs = estado.eventos.map(function (e) { return e.seq; });
    var ultima = seqs.length ? Math.max.apply(null, seqs) : null;
    var hayHuecos = huecos.length > 0;
    document.getElementById('monitor').innerHTML =
      '<div class="flex items-center justify-between gap-space-sm">' +
      '<div class="flex items-center gap-space-xs"><span class="material-symbols-outlined text-primary text-[20px]">receipt_long</span>' +
      '<h2 class="font-headline-sm text-headline-sm text-on-surface">Consistencia de la secuencia</h2></div>' +
      '<span class="px-space-xs py-0.5 rounded font-label-code-sm text-label-code-sm ' +
      (hayHuecos ? 'bg-error-container/40 text-error' : 'bg-secondary-container/20 text-secondary') + '">' +
      (hayHuecos ? 'CON HUECOS' : 'SIN HUECOS') + '</span></div>' +
      '<div class="grid grid-cols-3 gap-space-sm">' +
      cuadro('Última secuencia', ultima === null ? '—' : '#' + ultima) +
      cuadro('Eventos', String(seqs.length)) +
      cuadro('Faltantes', hayHuecos ? '#' + huecos.join(', #') : 'ninguno') + '</div>' +
      (hayHuecos ? '<p class="font-body-sm text-body-sm text-on-surface">Prolog detecta que faltan eventos en la secuencia. ' +
        'Los lotes cuyos eventos rodean el hueco quedan en duda; los demás no se ven afectados.</p>' : '');
  }

  function cuadro(titulo, valor) {
    return '<div class="bg-surface-container p-space-sm rounded-lg flex flex-col">' +
      '<span class="font-label-code-sm text-label-code-sm text-on-surface-variant">' + esc(titulo) + '</span>' +
      '<span class="font-label-code-lg text-label-code-lg text-primary font-bold break-all">' + esc(valor) + '</span></div>';
  }

  function pintarFiltros() {
    var opciones = ['todos'].concat(estado.lotes.map(function (l) { return l.id; }));
    document.getElementById('filtros').innerHTML = opciones.map(function (o) {
      var activo = o === filtro;
      return '<button type="button" data-filtro="' + esc(o) + '" class="px-space-sm py-1.5 rounded-lg font-label-code-sm text-label-code-sm shrink-0 active:scale-95 transition-all ' +
        (activo ? 'bg-primary text-on-primary font-semibold shadow-sm' : 'bg-surface-container-high text-on-surface hover:text-primary') + '">' +
        (o === 'todos' ? 'Todos' : 'Lote ' + esc(o)) + '</button>';
    }).join('');
  }

  function pintarLinea() {
    var items = [];
    estado.eventos.forEach(function (e) {
      if (filtro === 'todos' || e.lote === filtro) items.push({ seq: e.seq, evento: e });
    });
    // Los huecos no tienen lote: solo se muestran en la vista de todos.
    if (filtro === 'todos') {
      (estado.huecos_bitacora || []).forEach(function (s) { items.push({ seq: s, hueco: true }); });
    }
    items.sort(function (a, b) { return b.seq - a.seq; });
    var cont = document.getElementById('linea');
    if (!items.length) { cont.innerHTML = '<p class="font-body-sm text-body-sm text-on-surface-variant px-space-xs">Sin eventos para este filtro.</p>'; return; }
    cont.innerHTML = items.map(function (it) {
      if (it.hueco) {
        return '<article class="bg-error-container/25 p-space-sm rounded-xl flex items-center justify-between gap-space-xs">' +
          '<span class="px-space-xs py-0.5 rounded bg-surface-container-highest font-label-code-lg text-label-code-lg text-error font-bold">#' + esc(it.seq) + '</span>' +
          '<span class="font-body-sm text-body-sm text-error flex-1">Evento faltante: hueco en la bitácora.</span>' +
          '<span class="material-symbols-outlined text-error text-[18px]">warning</span></article>';
      }
      var e = it.evento;
      return '<article class="bg-surface-container p-space-sm rounded-xl flex flex-col gap-space-xs shadow-sm">' +
        '<div class="flex items-center justify-between gap-space-xs"><div class="flex items-center gap-space-xs min-w-0">' +
        '<span class="px-space-xs py-0.5 rounded bg-surface-container-highest font-label-code-lg text-label-code-lg text-primary font-bold">#' + esc(e.seq) + '</span>' +
        '<span class="px-1.5 py-0.5 rounded bg-tertiary-container/30 text-tertiary font-label-code-sm text-label-code-sm">Lote ' + esc(e.lote) + '</span>' +
        '<span class="font-label-code-sm text-label-code-sm text-on-surface-variant truncate">' + esc(G.formatoMs(e.ms)) + '</span></div>' +
        '<span class="font-label-code-sm text-label-code-sm text-secondary font-semibold shrink-0">' + esc(e.suceso) + '</span></div>' +
        '<p class="font-body-sm text-body-sm text-on-surface">' + esc(TEXTO_SUCESO[e.suceso] || e.suceso) + '</p></article>';
    }).join('');
  }

  function pintarPujas() {
    var pujas = estado.pujas.filter(function (p) { return filtro === 'todos' || p.lote === filtro; }).slice().reverse();
    var cont = document.getElementById('pujas');
    if (!pujas.length) { cont.innerHTML = '<p class="font-body-sm text-body-sm text-on-surface-variant px-space-xs">Sin pujas para este filtro.</p>'; return; }
    cont.innerHTML = pujas.map(function (p) {
      var v = VEREDICTOS[p.veredicto] || { texto: p.veredicto, clase: 'bg-surface-container-high text-on-surface' };
      return '<article class="bg-surface-container p-space-sm rounded-xl flex flex-col gap-space-xs">' +
        '<div class="flex items-center justify-between gap-space-xs">' +
        '<span class="font-label-code-lg text-label-code-lg text-primary font-bold">' + esc(p.id) + '</span>' +
        '<span class="px-space-xs py-0.5 rounded font-label-code-sm text-label-code-sm font-semibold ' + v.clase + '">' + esc(v.texto) + '</span></div>' +
        '<p class="font-body-sm text-body-sm text-on-surface">' + esc(p.postor) + ' en lote ' + esc(p.lote) + ' a $' + esc(p.precio) + '/kg</p>' +
        '<span class="font-label-code-sm text-label-code-sm text-on-surface-variant">emisión: ' + esc(typeof p.emision === 'number' ? G.formatoMs(p.emision) : p.emision) +
        ' · llegada: ' + esc(G.formatoMs(p.llegada)) + '</span>' +
        '<details><summary class="font-label-code-sm text-label-code-sm text-on-surface-variant cursor-pointer">Motivo de Prolog</summary>' +
        '<ul class="flex flex-col gap-0.5 mt-1">' + p.evidencia.map(function (x) {
          return '<li class="font-label-code-sm text-label-code-sm text-on-surface-variant break-all">• ' + esc(x) + '</li>';
        }).join('') + '</ul></details></article>';
    }).join('');
  }

  function pintar(nuevo) {
    if (!nuevo) {
      document.getElementById('monitor').innerHTML = '<p class="text-error font-body-sm text-body-sm">No hay respuesta del servidor Prolog.</p>';
      return;
    }
    estado = nuevo;
    pintarMonitor();
    pintarFiltros();
    pintarLinea();
    pintarPujas();
    document.getElementById('enlace-json').setAttribute('href', '/api/estado?vista=' + estado.vista);
  }

  document.addEventListener('click', function (e) {
    var b = e.target.closest ? e.target.closest('[data-filtro]') : null;
    if (!b || !estado) return;
    filtro = b.dataset.filtro;
    pintarFiltros();
    pintarLinea();
    pintarPujas();
  });

  G.iniciar(pintar);
})();
