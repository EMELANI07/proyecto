/* Utilidades compartidas por todas las pantallas.
 *
 * Este archivo NO contiene reglas ni umbrales: solo llama a la API de Prolog
 * (servidor.pl) y pinta lo que responde. Toda decision sale de reglas.pl.
 */
(function () {
  'use strict';

  var CLAVE_VISTA = 'gemelo_vista';
  var ACTIVO = ['text-primary', 'font-semibold'];
  var INACTIVO = ['text-on-surface-variant', 'hover:text-on-surface'];
  var cargador = null; // funcion de la pagina que pinta el estado
  var ultimoEstado = null;

  function esc(texto) {
    var mapa = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
    return String(texto === null || texto === undefined ? '' : texto)
      .replace(/[&<>"']/g, function (c) { return mapa[c]; });
  }

  function vista() {
    try {
      return localStorage.getItem(CLAVE_VISTA) === 'auditor' ? 'auditor' : 'publica';
    } catch (e) {
      return 'publica';
    }
  }

  function fijarVista(nueva) {
    try { localStorage.setItem(CLAVE_VISTA, nueva); } catch (e) { /* sin almacenamiento */ }
    pintarVista();
    recargar();
  }

  function pintarVista() {
    var pub = document.getElementById('vista-publica');
    var aud = document.getElementById('vista-auditor');
    if (!pub || !aud) return;
    var esAuditor = vista() === 'auditor';
    [[pub, !esAuditor], [aud, esAuditor]].forEach(function (par) {
      par[0].classList.remove('text-primary', 'font-semibold', 'text-on-surface');
      par[0].classList.add.apply(par[0].classList, par[1] ? ['text-primary', 'font-semibold'] : ['text-on-surface']);
    });
  }

  function formatoMs(ms) {
    return Number(ms).toLocaleString('es-MX') + ' ms';
  }

  function toast(mensaje, icono) {
    var el = document.getElementById('toast-global');
    if (!el) {
      el = document.createElement('div');
      el.id = 'toast-global';
      el.className = 'fixed bottom-24 left-1/2 -translate-x-1/2 bg-surface-bright text-on-surface px-4 py-3 rounded-xl shadow-2xl flex items-center gap-2 z-50 transition-opacity duration-300 opacity-0 pointer-events-none max-w-[92vw]';
      document.body.appendChild(el);
    }
    el.innerHTML = '<span class="material-symbols-outlined text-secondary text-[18px]">' +
      esc(icono || 'check_circle') + '</span><span class="font-label-code-sm text-label-code-sm">' +
      esc(mensaje) + '</span>';
    el.classList.remove('opacity-0', 'pointer-events-none');
    clearTimeout(el._t);
    el._t = setTimeout(function () { el.classList.add('opacity-0', 'pointer-events-none'); }, 3200);
  }

  async function api(ruta, opciones) {
    try {
      var r = await fetch(ruta, opciones);
      var datos = null;
      try { datos = await r.json(); } catch (e) { datos = null; }
      return { ok: r.ok, status: r.status, datos: datos };
    } catch (e) {
      return { ok: false, status: 0, datos: { error: 'No se pudo conectar con el servidor Prolog.' } };
    }
  }

  function enviar(ruta, cuerpo) {
    return api(ruta, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: cuerpo === undefined ? undefined : JSON.stringify(cuerpo)
    });
  }

  function pintarCabecera(estado) {
    var reloj = document.getElementById('reloj-ms');
    if (reloj) reloj.textContent = 'Reloj lógico: ' + formatoMs(estado.ahora_ms);
    var caja = document.getElementById('alerta-cabecera');
    var texto = document.getElementById('alerta-texto');
    if (caja && texto) {
      var huecos = estado.huecos_bitacora || [];
      if (huecos.length) {
        texto.textContent = 'Hueco en la bitácora: faltan #' + huecos.join(', #');
        caja.classList.remove('hidden');
      } else {
        caja.classList.add('hidden');
      }
    }
  }

  function marcarNav() {
    var actual = location.pathname.split('/').pop() || 'index.html';
    document.querySelectorAll('nav a[href]').forEach(function (a) {
      var destino = a.getAttribute('href');
      var esActual = destino === actual || (actual === '' && destino === 'index.html');
      a.classList.remove.apply(a.classList, ACTIVO.concat(INACTIVO));
      a.classList.add.apply(a.classList, esActual ? ACTIVO : INACTIVO);
      if (esActual) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current');
    });
  }

  async function cargarEstado() {
    var r = await api('/api/estado?vista=' + vista());
    if (!r.ok || !r.datos) return null;
    ultimoEstado = r.datos;
    pintarCabecera(r.datos);
    return r.datos;
  }

  async function recargar() {
    var estado = await cargarEstado();
    if (cargador) cargador(estado);
    return estado;
  }

  // alCargar(estado) pinta la pagina; si es null, el servidor no respondio.
  function iniciar(alCargar) {
    cargador = alCargar || null;
    function arrancar() {
      marcarNav();
      pintarVista();
      var pub = document.getElementById('vista-publica');
      var aud = document.getElementById('vista-auditor');
      if (pub) pub.addEventListener('click', function () { fijarVista('publica'); });
      if (aud) aud.addEventListener('click', function () { fijarVista('auditor'); });
      var sync = document.getElementById('btn-sync');
      if (sync) sync.addEventListener('click', function () {
        recargar().then(function (e) { toast(e ? 'Estado sincronizado con Prolog' : 'Sin respuesta del servidor', e ? 'sync' : 'error'); });
      });
      recargar();
    }
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', arrancar);
    else arrancar();
  }

  window.Gemelo = {
    esc: esc, vista: vista, fijarVista: fijarVista, formatoMs: formatoMs,
    toast: toast, api: api, enviar: enviar, recargar: recargar, iniciar: iniciar,
    estado: function () { return ultimoEstado; }
  };
})();
