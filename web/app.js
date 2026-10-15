/* ==========================================================
   Graph M4ker — contenido y comportamiento
   Para agregar un método: añade un objeto al arreglo METODOS.
   ========================================================== */

const CONCEPTOS = [
  {
    titulo: '¿Qué es un grafo?',
    texto: 'Un grafo es una estructura que representa relaciones entre objetos. Los objetos se llaman nodos (o vértices) y las relaciones entre ellos se llaman aristas.',
    video: '',   // pega aquí el enlace de YouTube si hay uno
    imagen: ''   // ruta a una imagen, por ejemplo 'img/grafo.png'
  },
  {
    titulo: '¿Para qué sirven?',
    texto: 'Sirven para modelar redes: rutas entre ciudades, conexiones entre computadoras, relaciones entre personas, dependencias entre tareas. Permiten responder preguntas como cuál es el camino más corto o cómo asignar recursos al menor costo.',
    video: '',
    imagen: ''
  },
  {
    titulo: 'Concepto matemático de un grafo',
    texto: 'Formalmente, un grafo es un par G = (V, E), donde V es un conjunto de vértices y E es un conjunto de aristas, cada una formada por un par de vértices de V.',
    video: '',
    imagen: ''
  },
  {
    titulo: 'Tipos de grafos',
    texto: 'Dirigidos y no dirigidos, ponderados y no ponderados, simples y multigrafos, conexos y no conexos, bipartitos, árboles, entre otros.',
    video: '',
    imagen: ''
  }
];

const METODOS = [
  {
    id: 'graph',
    nombre: 'Graph Maker',
    descripcion: 'Construye y edita grafos: agrega nodos y aristas y observa el resultado.',
    video: '',
    url: ''   // si el método tiene su propia página, ej. 'metodos/graph.html'
  },
  {
    id: 'assign',
    nombre: 'Assignation Algorithm',
    descripcion: 'Asigna tareas a recursos buscando el menor costo total.',
    video: '',
    url: ''
  },
  {
    id: 'johnson',
    nombre: 'Johnson Algorithm',
    descripcion: 'Descripción pendiente.',
    video: '',
    url: ''
  },
  {
    id: 'selection',
    nombre: 'Selection Sort',
    descripcion: 'Ordena una lista seleccionando en cada paso el menor elemento restante.',
    video: '',
    url: ''
  },
  {
    id: 'insertion',
    nombre: 'Insertion Sort',
    descripcion: 'Ordena insertando cada elemento en su posición dentro de la parte ya ordenada.',
    video: '',
    url: ''
  }
];

/* ---------- Piezas reutilizables ---------- */

const ICONO_YT = (w, h) =>
  `<svg class="yt-icon" width="${w}" height="${h}" viewBox="0 0 28 20" aria-hidden="true">
     <rect width="28" height="20" rx="6" fill="#E62117"></rect>
     <path d="M11.5 6v8l7-4z" fill="#FFFFFF"></path></svg>`;

const ICONO_GRAFO_ANCHO =
  `<svg width="96" height="72" viewBox="0 0 96 72" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" aria-hidden="true">
     <path d="M18 52L46 18L78 40L18 52M46 18L52 60"></path>
     <circle cx="18" cy="52" r="7" fill="var(--ph)"></circle><circle cx="46" cy="18" r="7" fill="var(--ph)"></circle>
     <circle cx="78" cy="40" r="7" fill="var(--ph)"></circle><circle cx="52" cy="60" r="7" fill="var(--ph)"></circle></svg>`;

const ICONO_GRAFO_CUADRADO =
  `<svg width="72" height="72" viewBox="0 0 72 72" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" aria-hidden="true">
     <path d="M16 50L36 18L56 48M16 50h40"></path>
     <circle cx="16" cy="50" r="6" fill="var(--ph)"></circle><circle cx="36" cy="18" r="6" fill="var(--ph)"></circle>
     <circle cx="56" cy="48" r="6" fill="var(--ph)"></circle></svg>`;

const ICONO_MAS =
  `<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M8 2v12M2 8h12"></path></svg>`;

const ICONO_ATRAS =
  `<svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13.5 4.5L7 11l6.5 6.5"></path></svg>`;

/* ---------- Construcción del DOM ---------- */

function htmlConcepto(c, i) {
  const imagen = c.imagen
    ? `<img src="${c.imagen}" alt="${c.titulo}">`
    : ICONO_GRAFO_ANCHO;
  const video = c.video
    ? `<a class="yt" href="${c.video}" target="_blank" rel="noopener">${ICONO_YT(28, 20)} Ver video</a>`
    : '';
  return `
    <div class="acc" data-acc="${i}">
      <button class="acc-head" aria-expanded="false" aria-controls="acc-cuerpo-${i}">
        <span class="acc-sign" aria-hidden="true">${ICONO_MAS}</span>
        <span class="acc-title">${c.titulo}</span>
      </button>
      <div class="acc-body" id="acc-cuerpo-${i}">
        <div class="acc-clip">
          <div class="acc-inner">
            <div class="acc-copy">
              <p class="acc-text">${c.texto}</p>
              ${video}
            </div>
            <div class="ph ph-wide" role="img" aria-label="Imagen ilustrativa">${imagen}</div>
          </div>
        </div>
      </div>
    </div>`;
}

function htmlTarjeta(m) {
  const abrir = m.url
    ? `<a class="open-btn" href="${m.url}">Abrir</a>`
    : `<button class="open-btn" data-abrir="${m.id}">Abrir</button>`;
  const video = m.video
    ? `<a class="yt yt-round" href="${m.video}" target="_blank" rel="noopener" aria-label="Ver video en YouTube">${ICONO_YT(24, 17)}</a>`
    : '';
  return `
    <article class="card" data-card="${m.id}">
      <button class="card-head" aria-expanded="false">
        <span class="ph ph-sq" aria-hidden="true">${ICONO_GRAFO_CUADRADO}</span>
        <span class="card-name">${m.nombre}</span>
      </button>
      <div class="card-more">
        <div class="card-clip">
          <div class="card-inner">
            <p class="card-desc">${m.descripcion}</p>
            <div class="card-actions">${abrir}${video}</div>
          </div>
        </div>
      </div>
    </article>`;
}

function htmlPagina(m) {
  const botones = [
    '<circle cx="11" cy="11" r="7"></circle>',
    '<path d="M4 18L18 4"></path>',
    '<rect x="4" y="4" width="14" height="14" rx="3"></rect>',
    '<path d="M7 4.5v13l11-6.5z"></path>'
  ].map((forma, i) =>
    `<button class="dock-btn" aria-label="Acción ${i + 1}">
       <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${forma}</svg>
     </button>`).join('');

  return `
    <section class="page" id="${m.id}" aria-label="${m.nombre}" inert>
      <nav class="nav">
        <button class="back" data-volver>${ICONO_ATRAS} Inicio</button>
      </nav>
      <div class="wrap page-body">
        <h2 class="page-title">${m.nombre}</h2>
        <p class="page-sub">${m.descripcion}</p>
        <div class="work">
          <div class="canvas">Área de trabajo</div>
          <aside class="side">
            <span class="side-label">Panel</span>
            <div class="skel"></div><div class="skel"></div>
            <div class="skel short"></div><div class="skel"></div>
          </aside>
        </div>
      </div>
      <div class="dock">${botones}</div>
    </section>`;
}

document.getElementById('conceptos').innerHTML = CONCEPTOS.map(htmlConcepto).join('');
document.getElementById('tarjetas').innerHTML = METODOS.map(htmlTarjeta).join('');
document.getElementById('paginas').innerHTML = METODOS.filter(m => !m.url).map(htmlPagina).join('');

/* ---------- Comportamiento ---------- */

const raiz = document.getElementById('inicio');

// Acordeón: uno abierto a la vez
document.querySelectorAll('.acc').forEach(acc => {
  acc.querySelector('.acc-head').addEventListener('click', () => {
    const abrir = !acc.classList.contains('is-open');
    document.querySelectorAll('.acc').forEach(o => {
      o.classList.remove('is-open');
      o.querySelector('.acc-head').setAttribute('aria-expanded', 'false');
    });
    if (abrir) {
      acc.classList.add('is-open');
      acc.querySelector('.acc-head').setAttribute('aria-expanded', 'true');
    }
  });
});

// Tarjetas: el primer clic las expande; con la tarjeta abierta, el clic abre la página
function abrirPagina(id) { location.hash = '#' + id; }

document.querySelectorAll('.card').forEach(card => {
  const id = card.dataset.card;
  const metodo = METODOS.find(m => m.id === id);
  card.querySelector('.card-head').addEventListener('click', () => {
    if (card.classList.contains('is-open')) {
      if (metodo.url) location.href = metodo.url; else abrirPagina(id);
      return;
    }
    document.querySelectorAll('.card').forEach(o => {
      o.classList.remove('is-open');
      o.querySelector('.card-head').setAttribute('aria-expanded', 'false');
    });
    card.classList.add('is-open');
    card.querySelector('.card-head').setAttribute('aria-expanded', 'true');
  });
});

document.querySelectorAll('[data-abrir]').forEach(b =>
  b.addEventListener('click', () => abrirPagina(b.dataset.abrir)));

document.querySelectorAll('[data-volver]').forEach(b =>
  b.addEventListener('click', () => { location.hash = ''; }));

// La URL (#johnson) decide qué página está activa: el botón "atrás" del navegador funciona
function sincronizar() {
  const id = location.hash.slice(1);
  let activa = null;
  document.querySelectorAll('.page').forEach(p => {
    const esta = p.id === id;
    p.classList.toggle('is-active', esta);
    p.toggleAttribute('inert', !esta);
    if (esta) activa = p;
  });
  raiz.classList.toggle('is-pushed', !!activa);
  raiz.toggleAttribute('inert', !!activa);
  if (activa) activa.querySelector('.back').focus({ preventScroll: true });
}
window.addEventListener('hashchange', sincronizar);
sincronizar();

document.addEventListener('keydown', e => {
  if (e.key === 'Escape' && location.hash) location.hash = '';
});
