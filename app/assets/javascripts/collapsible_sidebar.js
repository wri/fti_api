// Turbo-aware replacement for active_admin_sidebar.js from the active_admin_sidebar gem (styles still come from the gem).
onPageLoad(function() {
  const $content = $("#active_admin_content");
  if (!$("body").hasClass("index") || !$content.hasClass("collapsible_sidebar")) return;

  const $toggleBtn = $('<span class="sidebar_toggle_btn" title="Toggle sidebar"><span class="chevron"></span></span>');
  $content.find("#sidebar").prepend($toggleBtn);

  $toggleBtn.on("click", function() {
    const collapsed = !$content.hasClass("collapsed_sidebar");
    $.getJSON(window.location.href, { collapsed_sidebar: collapsed });
    $content.toggleClass("collapsed_sidebar", collapsed);
    $content.trigger(collapsed ? "collapsible_sidebar:collapsed" : "collapsible_sidebar:uncollapsed");
  });
});
