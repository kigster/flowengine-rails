// Stimulus controller for progress bar animation
// data-controller="progress" data-progress-value="75"
(function() {
  if (typeof window.Stimulus !== 'undefined') {
    window.Stimulus.register("progress", class extends window.Stimulus.Controller {
      static values = { value: Number }

      connect() {
        const bar = this.element.querySelector('.fe-progress__bar');
        if (bar) {
          bar.style.transition = 'width 0.4s ease-in-out';
          bar.style.width = this.valueValue + '%';
        }
      }
    });
  }
})();
