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
for (const link of document.querySelectorAll('.shot')) {
  link.addEventListener('click', event => {
    if (typeof dialog.showModal !== 'function' || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    largeImage.src = link.href;
    largeImage.alt = link.querySelector('img').alt;
    document.querySelector('#image-caption').textContent = link.dataset.caption;
    dialog.showModal();
  });
}
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
