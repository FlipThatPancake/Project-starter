// Midea report design system — page loader controller.
// Pairs with the #page-loader markup (04-page-structure.md "Page loader
// recipe") and the #page-loader CSS in components.css.
//
// Usage: <script src="assets/loader.js" defer></script>
// Contract:
//   setProgress(pct) — switch to determinate mode and set the ring to pct (0-100)
//   done()           — fade the overlay out, then remove it from the DOM
//
// Default behavior (no other wiring needed): waits for window 'load', jumps
// to 100%, then fades out. Call setProgress() yourself first if you have real
// progress to report (e.g. counting decoded <img> elements).
(function () {
  const loader = document.getElementById('page-loader');
  if (!loader) return;

  function setProgress(pct) {
    loader.classList.add('determinate');
    loader.style.setProperty('--pct', pct);
  }

  function done() {
    loader.classList.add('done');
  }

  loader.addEventListener('transitionend', () => {
    if (loader.classList.contains('done')) loader.remove();
  });

  window.addEventListener('load', () => {
    setProgress(100);
    setTimeout(done, 250);
  });

  window.MideaLoader = { setProgress, done };
})();
