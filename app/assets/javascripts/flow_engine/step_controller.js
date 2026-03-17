// Stimulus controller for step forms — prevents double-submit
// data-controller="step"
(function() {
  if (typeof window.Stimulus !== 'undefined') {
    window.Stimulus.register("step", class extends window.Stimulus.Controller {
      static targets = ["form", "submit"]

      connect() {
        if (this.hasFormTarget) {
          this.formTarget.addEventListener('submit', this.disableSubmit.bind(this));
        }
      }

      disableSubmit() {
        if (this.hasSubmitTarget) {
          this.submitTarget.disabled = true;
          this.submitTarget.value = 'Submitting...';
        }
      }
    });
  }
})();
