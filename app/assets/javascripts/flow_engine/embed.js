// FlowEngine Embed Script
// Usage: <script src="/flow_engine/assets/flow_engine/embed.js"></script>
// Then:  FlowEngine.embed({ target: '#container', definitionId: 1, baseUrl: '/flow_engine' })
(function(global) {
  var FlowEngineEmbed = {
    embed: function(options) {
      var target = typeof options.target === 'string'
        ? document.querySelector(options.target)
        : options.target;

      if (!target) {
        console.error('FlowEngine: target element not found');
        return;
      }

      var baseUrl = options.baseUrl || '/flow_engine';
      var src = baseUrl + '/sessions/new?definition_id=' + options.definitionId + '&embed=true';

      var iframe = document.createElement('iframe');
      iframe.src = src;
      iframe.style.width = '100%';
      iframe.style.border = 'none';
      iframe.style.minHeight = '400px';
      iframe.setAttribute('frameborder', '0');

      target.appendChild(iframe);

      window.addEventListener('message', function(event) {
        if (event.data && event.data.type === 'flowengine:resize') {
          iframe.style.height = event.data.height + 'px';
        }
        if (event.data && event.data.type === 'flowengine:completed') {
          if (typeof options.onComplete === 'function') {
            options.onComplete(event.data);
          }
        }
      });

      return iframe;
    }
  };

  global.FlowEngineEmbed = FlowEngineEmbed;
})(window);
