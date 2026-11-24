/* Pantalla "Lotes activos".
 * Pinta lo que responde /api/estado y manda acciones a la API; no decide nada.
 */
(function () {
  'use strict';
  var G = window.Gemelo;
  var esc = G.esc;
  var estado = null;
  var ultimo = null; // ultima respuesta de Prolog, para mostrarla con su motivo

  var ETAPAS = {
    abierto: 'Abierto', llamada: 'Llamada', adjudicado: 'Adjudicado', retirado: 'Retirado',
    reinicio: 'Reinicio', conexion_perdida: 'Conexión perdida', sin_eventos: 'Sin subasta'
  };
  var VEREDICTOS = {
    valida: { texto: 'Válida', clase: 'bg-secondary-container/20 text-secondary' },
    rechazada: { texto: 'Rechazada', clase: 'bg-error-container/40 text-error' },
    en_duda: { texto: 'En duda', clase: 'bg-primary-container/30 text-primary' }
  };

  function etiqueta(veredicto) {
    var v = VEREDICTOS[veredicto] || { texto: veredicto, clase: 'bg-surface-container-high text-on-surface' };
    return '<span class="px-space-xs py-0.5 rounded font-label-code-sm text-label-code-sm font-semibold shrink-0 ' +
      v.clase + '">' + esc(v.texto) + '</span>';
  }

  function listaEvidencia(items) {
    if (!items || !items.length) return '';
    return '<ul class="flex flex-col gap-0.5 mt-1">' + items.map(function (e) {
      return '<li class="font-label-code-sm text-label-code-sm text-on-surface-variant break-all">• ' + esc(e) + '</li>';
    }).join('') + '</ul>';
  }

  function pintarAlertaHuecos() {
    var caja = document.getElementById('alerta-huecos');
    var huecos = estado.huecos_bitacora || [];
    if (!huecos.length) { caja.classList.add('hidden'); caja.innerHTML = ''; return; }
    caja.classList.remove('hidden');
    caja.innerHTML =
      '<div class="flex items-center gap-space-xs">' +
      '<span class="material-symbols-outlined text-error text-[20px]">crisis_alert</span>' +
      '<h2 class="font-headline-sm text-headline-sm text-error uppercase tracking-wider">Hueco en la bitácora</h2></div>' +
      '<p class="font-body-sm text-body-sm text-on-surface">Faltan los eventos <strong>#' + esc(huecos.join(', #')) +
      '</strong>. Los lotes que tocan ese hueco quedan en duda hasta recuperarlos. ' +
      '<a class="text-primary underline" href="bitacora.html">Ver bitácora</a></p>';
  }

  function pintarReloj() {
    document.getElementById('reloj-valor').textContent = G.formatoMs(estado.ahora_ms);
    document.getElementById('vista-actual').textContent = estado.vista === 'auditor'
      ? 'Vista auditor: se muestran reservas y explicación completa.'
      : 'Vista pública: la reserva y su explicación están ocultas.';
  }

  function pintarUltimo() {
    var caja = document.getElementById('ultimo-resultado');
    if (!ultimo) { caja.classList.add('hidden'); return; }
    caja.classList.remove('hidden');
    caja.innerHTML =
      '<div class="flex items-center justify-between gap-space-xs">' +
      '<span class="font-label-code-sm text-label-code-sm text-on-surface-variant uppercase tracking-wider">Última respuesta de Prolog</span>' +
      (ultimo.veredicto ? etiqueta(ultimo.veredicto) : '') + '</div>' +
      '<p class="font-body-sm text-body-sm text-on-surface">' + esc(ultimo.titulo) + '</p>' +
      listaEvidencia(ultimo.lineas);
  }

  function opcionesPostores() {
    var sala = estado.postores.filter(function (p) { return p.modalidad === 'sala'; });
    var remotos = estado.postores.filter(function (p) { return p.modalidad === 'remoto'; });
    function opt(p) {
      var extra = p.latencia_ms === null ? '' : ' · latencia supuesta ' + p.latencia_ms + ' ms';
      return '<option value="' + esc(p.id) + '">' + esc(p.id) + ' (' + esc(p.modalidad) + extra + ')</option>';
    }
    return '<optgroup label="Sala">' + sala.map(opt).join('') + '</optgroup>' +
      '<optgroup label="Remotos">' + remotos.map(opt).join('') + '</optgroup>';
  }

  function pintarHistorias(lote) {
    var n = lote.historias.length;
    return lote.historias.map(function (h, i) {
      var titulo = n > 1 ? '<span class="font-label-code-sm text-label-code-sm text-primary font-bold">Historia ' + (i + 1) + ' de ' + n + '</span>' : '';
      var falta = (h.que_falta || []).map(function (t) {
        return '<li class="flex items-start gap-1.5"><span class="text-primary font-bold">•</span><span>' + esc(t) + '</span></li>';
      }).join('');
      return '<div class="bg-surface-container-low p-space-md rounded-xl flex flex-col gap-space-xs">' + titulo +
        '<p class="font-body-sm text-body-sm text-on-surface font-semibold">' + esc(h.resumen) + '</p>' +
        '<details><summary class="font-label-code-sm text-label-code-sm text-on-surface-variant cursor-pointer">Explicación de Prolog</summary>' +
        listaEvidencia(h.explicacion) + '</details>' +
        (falta ? '<div class="pt-space-xs"><span class="font-label-code-sm text-label-code-sm font-bold uppercase tracking-wider text-on-surface">Qué falta para que cambie</span>' +
          '<ul class="flex flex-col gap-1 text-on-surface-variant font-body-sm text-body-sm mt-1">' + falta + '</ul></div>' : '') +
        '</div>';
    }).join('');
  }

  function pintarReserva(lote) {
    if (lote.reserva_minima_por_kilo === undefined || lote.reserva_minima_por_kilo === null) return '';
    var v = Number(lote.reserva_minima_por_kilo);
    return '<div class="bg-surface-container-lowest p-space-sm rounded-xl flex items-center justify-between">' +
      '<span class="font-label-code-sm text-label-code-sm text-primary uppercase font-bold">Reserva (confidencial)</span>' +
      '<span class="font-label-code-lg text-label-code-lg text-on-surface">precio mínimo por kilo: $' + esc(v.toFixed(2)) + '</span></div>';
  }

  function pintarPujas(lote) {
    var pujas = estado.pujas.filter(function (p) { return p.lote === lote.id; }).reverse();
    if (!pujas.length) return '<p class="font-body-sm text-body-sm text-on-surface-variant">Aún no hay pujas en este lote.</p>';
    return '<ul class="flex flex-col gap-space-xs">' + pujas.map(function (p) {
      return '<li class="bg-surface-container-low p-space-xs rounded flex flex-col gap-0.5">' +
        '<div class="flex items-center justify-between gap-space-xs">' +
        '<span class="font-label-code-sm text-label-code-sm text-on-surface">' + esc(p.id) + ' · ' + esc(p.postor) + ' · $' + esc(p.precio) + '/kg</span>' +
        etiqueta(p.veredicto) + '</div>' +
        '<span class="font-label-code-sm text-label-code-sm text-on-surface-variant">llegada ' + esc(G.formatoMs(p.llegada)) + '</span>' +
        '<details><summary class="font-label-code-sm text-label-code-sm text-on-surface-variant cursor-pointer">Motivo</summary>' + listaEvidencia(p.evidencia) + '</details></li>';
    }).join('') + '</ul>';
  }

  function pintarControles(lote) {
    if (lote.precio_vigente === null || lote.precio_vigente === undefined) {
      return '<p class="font-body-sm text-body-sm text-on-surface-variant">Este lote solo tiene datos de corral; no hay subasta en curso.</p>';
    }
    function ev(suceso, texto, icono) {
      return '<button type="button" data-accion="evento" data-lote="' + esc(lote.id) + '" data-suceso="' + suceso + '" ' +
        'class="py-2 px-space-xs bg-surface-container-high hover:bg-surface-container-highest text-on-surface rounded font-label-code-sm text-label-code-sm font-semibold flex items-center justify-center gap-1 active:scale-95 transition-all">' +
        '<span class="material-symbols-outlined text-[16px]">' + icono + '</span>' + texto + '</button>';
    }
    return '<form data-form="puja" data-lote="' + esc(lote.id) + '" class="flex flex-col gap-space-xs bg-surface-container-high/60 p-space-sm rounded-xl">' +
      '<span class="font-label-code-sm text-label-code-sm font-bold uppercase tracking-wider text-on-surface">Pujar</span>' +
      '<div class="grid grid-cols-2 gap-space-xs">' +
      '<select name="postor" class="bg-surface-container-lowest text-on-surface rounded p-space-xs font-label-code-sm text-label-code-sm">' + opcionesPostores() + '</select>' +
      '<input name="precio" type="number" step="any" inputmode="decimal" value="' + esc(lote.precio_vigente) + '" aria-label="Precio por kilo" ' +
      'class="bg-surface-container-lowest text-on-surface rounded p-space-xs font-label-code-sm text-label-code-sm"></div>' +
      '<button type="submit" class="py-2.5 bg-primary hover:bg-primary-container text-on-primary rounded font-label-code-sm text-label-code-sm font-bold active:scale-95 transition-all shadow-md">Enviar puja a Prolog</button>' +
      '</form>' +
      '<div class="grid grid-cols-2 gap-space-xs">' +
      ev('llamada', 'Llamada', 'campaign') + ev('adjudicado', 'Adjudicar (martillazo)', 'gavel') +
      ev('conexion_perdida', 'Se cae la conexión', 'wifi_off') + ev('retirado', 'Retirar lote', 'logout') + '</div>';
  }

  function pintarLote(lote) {
    var vigente = lote.precio_vigente === null || lote.precio_vigente === undefined
      ? 'sin escalón' : '$' + esc(lote.precio_vigente) + '/kg';
    return '<article class="flex flex-col w-full bg-surface-container rounded-xl overflow-hidden shadow-lg" id="lote-' + esc(lote.id) + '">' +
      '<div class="p-space-md flex flex-col gap-space-md">' +
      '<div class="flex items-center justify-between gap-space-xs">' +
      '<div class="flex items-center gap-space-xs min-w-0">' +
      '<span class="bg-surface-container-lowest px-space-xs py-0.5 rounded font-label-code-sm text-label-code-sm text-primary font-bold">LOTE ' + esc(lote.id) + '</span>' +
      '<span class="font-label-code-sm text-label-code-sm text-on-surface-variant truncate">' + esc(lote.vendedor) + '</span></div>' +
      '<span class="bg-primary-container/30 text-primary px-space-xs py-0.5 rounded font-label-code-sm text-label-code-sm font-bold shrink-0">' +
      esc(ETAPAS[lote.etapa] || lote.etapa) + '</span></div>' +
      '<div class="flex items-baseline justify-between"><span class="font-label-code-sm text-label-code-sm text-on-surface-variant uppercase tracking-wider">Escalón vigente (ejemplo)</span>' +
      '<span class="font-metric-display text-metric-display text-primary">' + vigente + '</span></div>' +
      pintarReserva(lote) + pintarHistorias(lote) + pintarControles(lote) +
      '<div class="flex flex-col gap-space-xs"><span class="font-label-code-sm text-label-code-sm font-bold uppercase tracking-wider text-on-surface">Pujas del lote</span>' +
      pintarPujas(lote) + '</div></div></article>';
  }

  function pintar(nuevo) {
    var contenedor = document.getElementById('lotes');
    if (!nuevo) {
      contenedor.innerHTML = '<div class="bg-error-container/25 text-error p-space-md rounded-xl font-body-sm text-body-sm">' +
        'No hay respuesta del servidor Prolog. Revisa que servidor.pl siga corriendo.</div>';
      return;
    }
    estado = nuevo;
    pintarAlertaHuecos();
    pintarReloj();
    pintarUltimo();
    contenedor.innerHTML = estado.lotes.map(pintarLote).join('');
  }

  async function pujar(form) {
    var lote = form.dataset.lote;
    var postor = form.elements.postor.value;
    var precio = parseFloat(form.elements.precio.value);
    if (!isFinite(precio)) { G.toast('Escribe un monto para pujar', 'error'); return; }
    var r = await G.enviar('/api/puja', { lote: lote, postor: postor, precio: precio });
    if (!r.datos || r.datos.ok !== true) {
      var motivo = r.datos && r.datos.error ? r.datos.error : 'Error desconocido';
      ultimo = { titulo: 'Prolog no registró la puja: ' + motivo, lineas: [], veredicto: 'rechazada' };
      G.toast('Prolog rechazó la solicitud', 'error');
    } else {
      ultimo = {
        titulo: 'Puja ' + r.datos.id + ' de ' + postor + ' en ' + lote + ' a $' + precio + '/kg (llegada ' + G.formatoMs(r.datos.ahora_ms) + ')',
        lineas: r.datos.evidencia, veredicto: r.datos.veredicto
      };
      G.toast('Puja ' + r.datos.id + ': ' + (VEREDICTOS[r.datos.veredicto] || {}).texto, 'gavel');
    }
    await G.recargar();
  }

  async function evento(lote, suceso) {
    var r = await G.enviar('/api/evento', { lote: lote, suceso: suceso });
    if (r.datos && r.datos.ok === true) {
      ultimo = { titulo: 'Evento #' + r.datos.seq + ' registrado: ' + suceso + ' en ' + lote + ' a las ' + G.formatoMs(r.datos.ms), lineas: [], veredicto: null };
      G.toast('Evento #' + r.datos.seq + ' registrado', 'receipt_long');
    } else {
      var motivo = r.datos && r.datos.error ? r.datos.error : 'Error desconocido';
      ultimo = { titulo: 'Prolog no registró el evento: ' + motivo, lineas: [], veredicto: 'rechazada' };
      G.toast('Prolog rechazó el evento', 'error');
    }
    await G.recargar();
  }

  async function avanzar(ms) {
    var r = await G.enviar('/api/reloj', { avanzar_ms: ms });
    if (r.datos && r.datos.ok === true) G.toast('Reloj lógico: ' + G.formatoMs(r.datos.ahora_ms), 'schedule');
    await G.recargar();
  }

  async function reiniciar() {
    if (!window.confirm('Esto borra las pujas y eventos nuevos y vuelve al escenario base. ¿Continuar?')) return;
    await G.enviar('/api/reiniciar');
    ultimo = null;
    G.toast('Escenario base restaurado', 'restart_alt');
    await G.recargar();
  }

  function enlazar() {
    document.addEventListener('submit', function (e) {
      var form = e.target.closest ? e.target.closest('form[data-form="puja"]') : null;
      if (!form) return;
      e.preventDefault();
      pujar(form);
    });
    document.addEventListener('click', function (e) {
      var b = e.target.closest ? e.target.closest('[data-accion]') : null;
      if (!b) return;
      if (b.dataset.accion === 'evento') evento(b.dataset.lote, b.dataset.suceso);
      else if (b.dataset.accion === 'reloj') avanzar(parseInt(b.dataset.ms, 10));
      else if (b.dataset.accion === 'reiniciar') reiniciar();
    });
  }

  enlazar();
  G.iniciar(pintar);
})();
