$(document).ready(function() {
  function updateChart(elemId, checked) {
    const chart = Chartkick.charts['chart-1'].chart;
    const dataset = chart.data.datasets.find(
      x => x.label.replaceAll('&', '').replace(/\s/g, '').toLowerCase() === elemId.replaceAll('_', '')
    );
    if (dataset) {
      dataset.hidden = !checked;
      chart.update();
    }
  }

  setTimeout(function() {
    if (Chartkick && Chartkick.charts['chart-1']) {
      Chartkick.charts['chart-1'].redraw();
      setTimeout(updateColumnVisiblity, 100);
    }
  }, 50);

  setTimeout(function() {
    if (Chartkick && Chartkick.charts['chart-1']) {
      const chart = Chartkick.charts['chart-1'].chart;
      const oldOnClick = chart.legend.options.onClick;

      const newLegendClickHandler = function (e, legendItem, legend) {
        const id = legendItem.text.replaceAll(' & ', ' ').replaceAll(' ', '_').toLowerCase();
        const column = $(`.col-${id}`);

        $('#' + id).prop('checked', legendItem.hidden);
        column.toggleClass('hide', !legendItem.hidden);
        oldOnClick.apply(this, [e, legendItem, legend]);
      };
      chart.legend.options.onClick = newLegendClickHandler;
    }
  }, 1000)

  $(".observation-checkbox").on('change', function(event) {
    const elem = event.target;
    const column = $(`.col-${elem.id}`);
    column.toggleClass('hide', !elem.checked);
    localStorage.setItem(elem.id, elem.checked);
    updateChart(elem.id, elem.checked);
  });

  function updateColumnVisiblity() {
    if ($('.observation-attributes').length > 0) {
      const saveToLocalStorage = $('.observation-attributes').data('saveToLocalStorage');

      $('.observation-attributes').children().each((_idx, elem) => {
        const id = elem.id.split('-')[1];
        if (saveToLocalStorage) {
          const storage = localStorage.getItem(id);
          if (storage !== null) {
            if(storage === "true") {
              $('#' + id).prop("checked", true);
            } else {
              $('#' + id).prop("checked", false);
            }
          }
        }
        const column = $(`.col-${id}`);
        const checked = $('#' + id).prop('checked');
        column.toggleClass('hide', !checked);
        updateChart(id, checked);
      })
    }
  }

  updateColumnVisiblity();
});
