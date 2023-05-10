$(document).ready(function() {
  if ($('.visible-columns').length === 0) return;

  const page = $('.visible-columns').data('page');
  const saveToLocalStorage = $('.visible-columns').data('saveToLocalStorage');
  const localStorageKey = `${page}-columns`;

  function updateChart(elemId, checked) {
    if (!Chartkick || !Chartkick.charts['chart-1']) return;

    const chart = Chartkick.charts['chart-1'].chart;
    const dataset = chart.data.datasets.find(x => x.id === elemId);

    if (dataset) {
      const datasetIndex = chart.data.datasets.indexOf(dataset);
      const legendItem = chart.legend.legendItems.find(x => x.datasetIndex === datasetIndex);
      legendItem.hidden = !checked;

      if (checked) {
        chart.show(legendItem.datasetIndex);
      } else {
        chart.hide(legendItem.datasetIndex);
      }
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
        const dataset = chart.data.datasets[legendItem.datasetIndex];
        const id = dataset.id;
        const column = $(`.col-${id}`);

        $('#' + id).prop('checked', legendItem.hidden);
        column.toggleClass('hide', !legendItem.hidden);
        oldOnClick.apply(this, [e, legendItem, legend]);
      };
      chart.legend.options.onClick = newLegendClickHandler;
    }
  }, 1000)

  $(".visible-column__checkbox").on('change', function(event) {
    const elem = event.target;
    const column = $(`.col-${elem.id}`);

    column.toggleClass('hide', !elem.checked);
    if (saveToLocalStorage) {
      const savedColumns = JSON.parse(localStorage.getItem(localStorageKey) || "{}");
      localStorage.setItem(localStorageKey, JSON.stringify({ ...savedColumns, [elem.id]: elem.checked }));
    }

    updateChart(elem.id, elem.checked);
  });

  function updateColumnVisiblity() {
    const savedColumns = JSON.parse(localStorage.getItem(localStorageKey) || "null");

    $('.visible-columns').children().each((_idx, elem) => {
      const id = elem.id.split('-')[1];
      if (saveToLocalStorage && savedColumns) {
        const checked = savedColumns[id];
        if (checked !== null && checked !== undefined) {
          $('#' + id).prop("checked", checked);
        }
      }
      const column = $(`.col-${id}`);
      const checked = $('#' + id).prop('checked');
      column.toggleClass('hide', !checked);
      updateChart(id, checked);
    })
  }

  updateColumnVisiblity();
});
