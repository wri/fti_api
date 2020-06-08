(function() {
  var onDOMReady;

  onDOMReady = function () {

    $('.clear_filters_btn').off('click');
    $('.clear_filters_btn').click(function (evt) {
      $.ajax(this.href, {
        async: false,
        data: {
          clear_filters: true
        },
        type: 'POST'
      });


      var param, params, regex;
      params = window.location.search.slice(1).split('&');
      regex = /^(q\[|q%5B|q%5b|page|commit)/;
      if (typeof Turbolinks !== 'undefined') {
        Turbolinks.visit(window.location.href.split('?')[0] + '?' + ((function () {
          var i, len, results;
          results = [];
          for (i = 0, len = params.length; i < len; i++) {
            param = params[i];
            if (!param.match(regex)) {
              results.push(param);
            }
          }
          return results;
        })()).join('&'));
        return e.preventDefault();
      } else {
        return window.location.search = ((function () {
          var i, len, results;
          results = [];
          for (i = 0, len = params.length; i < len; i++) {
            param = params[i];
            if (!param.match(regex)) {
              results.push(param);
            }
          }
          return results;
        })()).join('&');
      }
    });

  }
  $(document).ready(onDOMReady).on('page:load turbolinks:load', onDOMReady);
}).call(this);;