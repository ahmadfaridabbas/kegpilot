const image = document.querySelector('#view-image');
const nameLabel = document.querySelector('#view-name');
const viewAlt = {
  maintenance: 'KegPilot Maintenance tab with the two-column action grid',
  installed: 'KegPilot Installed tab listing formulae and casks with search and uninstall',
  updates: 'KegPilot Updates tab with installed to current versions and upgrade buttons',
  console: 'KegPilot Console streaming live output from a running command'
};
for (const button of document.querySelectorAll('[data-view]')) {
  button.addEventListener('click', () => {
    const name = button.querySelector('strong').textContent;
    const view = button.dataset.view;
    image.src = `assets/view-${view}.png`;
    image.alt = viewAlt[view] || name;
    if (nameLabel) nameLabel.textContent = name;
    for (const item of document.querySelectorAll('[data-view]')) {
      item.setAttribute('aria-pressed', String(item === button));
    }
    if (window.matchMedia('(max-width: 680px)').matches) {
      const preview = document.querySelector('.style-preview');
      const header = document.querySelector('.nav');
      const headerOffset = (header ? header.getBoundingClientRect().height : 0) + 12;
      const top = preview.getBoundingClientRect().top + window.scrollY - headerOffset;
      window.scrollTo({
        top,
        behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth'
      });
    }
  });
}
const dialog = document.querySelector('#image-dialog');
const largeImage = document.querySelector('#large-image');
const caption = document.querySelector('#image-caption');
const dialogPrev = document.querySelector('#dialog-prev');
const dialogNext = document.querySelector('#dialog-next');
const dialogDots = document.querySelector('#dialog-dots');
let dialogSlides = [];   // the group of .shot links the lightbox is navigating
let dialogIndex = 0;

function showDialogAt(i) {
  if (!dialogSlides.length) return;
  dialogIndex = Math.max(0, Math.min(dialogSlides.length - 1, i));
  const link = dialogSlides[dialogIndex];
  largeImage.src = link.href;
  largeImage.alt = link.querySelector('img').alt;
  caption.textContent = link.dataset.caption;
  dialogPrev.disabled = dialogIndex <= 0;
  dialogNext.disabled = dialogIndex >= dialogSlides.length - 1;
  Array.from(dialogDots.children).forEach((d, idx) =>
    d.setAttribute('aria-selected', String(idx === dialogIndex)));
}

function openDialog(group, index) {
  dialogSlides = group;
  // Rebuild dots to match this group.
  dialogDots.innerHTML = '';
  group.forEach((slide, idx) => {
    const dot = document.createElement('button');
    dot.type = 'button';
    dot.setAttribute('role', 'tab');
    const theme = (slide.dataset.caption || '').split('·').pop().trim();
    dot.setAttribute('aria-label', theme || `Image ${idx + 1}`);
    dot.addEventListener('click', () => showDialogAt(idx));
    dialogDots.appendChild(dot);
  });
  showDialogAt(index);
  if (typeof dialog.showModal === 'function') dialog.showModal();
}

for (const link of document.querySelectorAll('.shot')) {
  link.addEventListener('click', event => {
    if (typeof dialog.showModal !== 'function' || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    // Navigate within the clicked carousel's slides (or just this one if standalone).
    const carouselTrack = link.closest('.carousel-track');
    const group = carouselTrack ? Array.from(carouselTrack.querySelectorAll('.shot')) : [link];
    openDialog(group, group.indexOf(link));
  });
}
dialogPrev.addEventListener('click', () => showDialogAt(dialogIndex - 1));
dialogNext.addEventListener('click', () => showDialogAt(dialogIndex + 1));
dialog.addEventListener('keydown', e => {
  if (e.key === 'ArrowRight') { e.preventDefault(); showDialogAt(dialogIndex + 1); }
  else if (e.key === 'ArrowLeft') { e.preventDefault(); showDialogAt(dialogIndex - 1); }
});
document.querySelector('#close-dialog').addEventListener('click', () => dialog.close());
dialog.addEventListener('click', event => { if (event.target === dialog) { const r = dialog.getBoundingClientRect(); if (event.clientX < r.left || event.clientX > r.right || event.clientY < r.top || event.clientY > r.bottom) dialog.close(); } });

// GA4: track Download button clicks (safe no-op if gtag is unavailable/blocked).
for (const link of document.querySelectorAll('[data-track="download"]')) {
  link.addEventListener('click', () => {
    if (typeof window.gtag !== 'function') return;
    window.gtag('event', 'download', {
      location: link.dataset.location || 'unknown',
      file_name: (link.getAttribute('href') || '').split('/').pop()
    });
  });
}

// Theme carousels (Maintenance / Installed): dots + hover arrows + scroll sync.
for (const carousel of document.querySelectorAll('[data-carousel]')) {
  const track = carousel.querySelector('.carousel-track');
  const slides = Array.from(track.querySelectorAll('.carousel-slide'));
  const dotsWrap = carousel.querySelector('.carousel-dots');
  const prev = carousel.querySelector('.carousel-prev');
  const next = carousel.querySelector('.carousel-next');
  if (!track || !slides.length) continue;

  // Build one dot per slide, labelled by the slide's theme (from data-caption).
  const dots = slides.map((slide, i) => {
    const dot = document.createElement('button');
    dot.type = 'button';
    dot.setAttribute('role', 'tab');
    const theme = (slide.dataset.caption || '').split('·').pop().trim();
    dot.setAttribute('aria-label', theme || `Slide ${i + 1}`);
    dot.addEventListener('click', () => goTo(i));
    dotsWrap.appendChild(dot);
    return dot;
  });

  const current = () => Math.round(track.scrollLeft / track.clientWidth);
  function goTo(i) {
    const clamped = Math.max(0, Math.min(slides.length - 1, i));
    track.scrollTo({
      left: clamped * track.clientWidth,
      behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth'
    });
  }
  function sync() {
    const idx = current();
    dots.forEach((d, i) => d.setAttribute('aria-selected', String(i === idx)));
    if (prev) prev.disabled = idx <= 0;
    if (next) next.disabled = idx >= slides.length - 1;
  }

  if (prev) prev.addEventListener('click', () => goTo(current() - 1));
  if (next) next.addEventListener('click', () => goTo(current() + 1));

  let ticking = false;
  track.addEventListener('scroll', () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => { ticking = false; sync(); });
  }, { passive: true });
  // Keyboard arrows when the track is focused.
  track.addEventListener('keydown', e => {
    if (e.key === 'ArrowRight') { e.preventDefault(); goTo(current() + 1); }
    else if (e.key === 'ArrowLeft') { e.preventDefault(); goTo(current() - 1); }
  });
  window.addEventListener('resize', sync, { passive: true });
  sync();
}

// Header color adapts over light sections (e.g. the gallery), so text stays readable.
const nav = document.querySelector('.nav');
const lightSections = document.querySelectorAll('.gallery-section');
if (nav && lightSections.length) {
  let ticking = false;
  const updateNavTheme = () => {
    ticking = false;
    const navBottom = nav.getBoundingClientRect().bottom;
    let overLight = false;
    for (const section of lightSections) {
      const r = section.getBoundingClientRect();
      // The header overlaps this light section when the section has scrolled
      // up past the header's bottom edge but hasn't fully scrolled off.
      if (r.top <= navBottom && r.bottom >= navBottom) { overLight = true; break; }
    }
    nav.classList.toggle('nav--on-light', overLight);
  };
  const onScroll = () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(updateNavTheme);
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onScroll, { passive: true });
  updateNavTheme();
}
