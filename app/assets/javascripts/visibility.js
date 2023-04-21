$(document).ready(function() {
  function updateChart(elemId, checked) {
    const chart = Chartkick.charts['chart-1'].chart;
    const lookupId = elemId.replaceAll('_', '');
    const legendItem = chart.legend.legendItems.find(
      x => x.text.replaceAll('&', '').replace(/\s/g, '').toLowerCase() === lookupId
    );
    if (legendItem) {
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
        const id = legendItem.text.replaceAll(' & ', ' ').replaceAll(' ', '_').toLowerCase();
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
    localStorage.setItem(elem.id, elem.checked);
    updateChart(elem.id, elem.checked);
  });

  function updateColumnVisiblity() {
    if ($('.visible-columns').length > 0) {
      const saveToLocalStorage = $('.visible-columns').data('saveToLocalStorage');

      $('.visible-columns').children().each((_idx, elem) => {
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

  function getCursorPosition(canvas, event) {
    const rect = canvas.getBoundingClientRect()
    const x = event.clientX - rect.left
    const y = event.clientY - rect.top
    console.log("x: " + x + " y: " + y)
    console.log("clientX: " + event.clientX + " clientY: " + event.clientY);
}

const canvas = document.querySelector('#chart-1')
canvas.addEventListener('mousedown', function(e) {
    getCursorPosition(canvas, e)
})

  updateColumnVisiblity();
});
