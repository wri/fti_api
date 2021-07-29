$(document).ready(function() {
  function updateChart(elemId, checked) {
    const chart = Chartkick.charts['chart-1'].chart;
    const dataset = chart.data.datasets.find(
      x => x.label.replace('&', '').replace(' ', '').toLowerCase() === elemId.replace('_', '')
    );
    if (dataset) {
      dataset.hidden = !checked;
      chart.update();
    }
  }

  setTimeout(function() {
    const chart = Chartkick.charts['chart-1'].chart;
    const oldOnClick = chart.options.legend.onClick;
    const newLegendClickHandler = function (e, legendItem) {
      const id = legendItem.text.replace(' & ', ' ').replace(' ', '_').toLowerCase();
      const column = $(`.col-${id}`);
      $('#' + id).prop('checked', legendItem.hidden);
      column.toggleClass('hide', !legendItem.hidden);
      oldOnClick.apply(this, [e, legendItem]);
    };
    chart.options.legend.onClick = newLegendClickHandler;
  }, 100)

  $(".observation-checkbox").on('change', function(event) {
    const elem = event.target;
    const column = $(`.col-${elem.id}`);
    column.toggleClass('hide', !elem.checked);
    localStorage.setItem(elem.id, elem.checked);
    updateChart(elem.id, elem.checked);
  });

  if ($('.observation-attributes').length > 0) {
    $('.observation-attributes').children().each((_idx, elem) => {
      const id = elem.id.split('-')[1];
      const storage = localStorage.getItem(id);
      if (storage !== null) {
        if(storage === "true") {
          $('#' + id).prop("checked", true);
        } else {
          $('#' + id).prop("checked", false);
        }
      }
      const column = $(`.col-${id}`);
      const checked = $('#' + id).prop('checked');
      column.toggleClass('hide', !checked);
      updateChart(id, checked);
    })
  }
});
