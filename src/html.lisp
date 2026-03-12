;;; -*- Mode: LISP; Base: 10; Syntax: ANSI-Common-Lisp; Package: LS-SERVER -*-
;;; Copyright (c) 2026 by Symbolics Pte. Ltd. All rights reserved.
;;; SPDX-License-identifier: MS-PL

(in-package #:ls-server)

;;; HTML generation utilities

;;; Lambda (λ) SVG favicon — the iconic Lisp symbol
(defparameter *favicon-svg*
  "data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 100 100%27%3E%3Ctext y=%2780%27 font-size=%2780%27 font-family=%27serif%27%3E%CE%BB%3C/text%3E%3C/svg%3E"
  "URL-encoded inline SVG data URI for the lambda favicon.")

(defun landing-page ()
  "Generate the landing page HTML with links to plots and tables index pages."
  (let ((data-frames (df:data-frame-symbols))
        (plots (list-plots)))
    (cl-who:with-html-output-to-string (s nil :prologue t :indent t)
      (:html
       (:head
        (:meta :charset "utf-8")
        (:title "Lisp-Stat Server")
        (:link :rel "icon" :type "image/svg+xml" :href *favicon-svg*)
        (:style (cl-who:str *index-css*)))
       (:body
        (:h1 "Lisp-Stat Server")
        (:nav :class "hub"
         (:a :href "/plots" :class "hub-card"
          (:h2 "Plots")
          (:p (cl-who:str (format nil "~D plot~:P available" (length plots)))))
         (:a :href "/tables" :class "hub-card"
          (:h2 "Tables")
          (:p (cl-who:str (format nil "~D data frame~:P available"
                                  (length data-frames)))))))))))

(defparameter *index-css*
  "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
         margin: 0; padding: 0; color: #333; background: #f5f5f5; }
h1 { padding: 1rem 2rem; margin: 0; background: #2c3e50; color: #fff; }
.hub { display: flex; gap: 2rem; padding: 2rem; justify-content: center; }
.hub-card { display: block; padding: 2rem 3rem; background: #fff; border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-decoration: none; color: #333;
            transition: box-shadow 0.2s; }
.hub-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.2); }
.hub-card h2 { margin: 0 0 0.5rem; color: #2c3e50; }
.hub-card p { margin: 0; color: #666; }
.container { display: flex; min-height: calc(100vh - 3.5rem); }
.sidebar { width: 240px; background: #2c3e50; color: #ecf0f1; padding: 1rem;
           overflow-y: auto; }
.sidebar h2 { margin: 0 0 1rem; font-size: 1.1rem; }
.sidebar ul { list-style: none; padding: 0; margin: 0; }
.sidebar li { margin: 0.3rem 0; }
.sidebar a { color: #ecf0f1; text-decoration: none; }
.sidebar a:hover { color: #3498db; }
.back-link { display: block; margin-bottom: 1rem; font-size: 0.9rem; color: #bdc3c7 !important; }
.content { flex: 1; padding: 2rem; }
.content h1 { background: none; color: #333; padding: 0; margin: 0 0 1.5rem; }
.card-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
             gap: 1rem; }
.card { display: block; padding: 1.5rem; background: #fff; border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-decoration: none; color: #333;
        transition: box-shadow 0.2s; }
.card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.2); }
.card h3 { margin: 0 0 0.5rem; color: #2c3e50; }
.card p { margin: 0; font-size: 0.9rem; }
.card p a { color: #3498db; }"
  "Shared CSS for index and landing pages.")

(defparameter *plots-spa-css*
  "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
         margin: 0; padding: 0; color: #333; background: #f5f5f5; }
.top-bar { padding: 0.6rem 1.5rem; background: #2c3e50; color: #fff;
           display: flex; align-items: center; gap: 1rem; }
.top-bar h1 { margin: 0; font-size: 1.2rem; }
.top-bar a { color: #bdc3c7; text-decoration: none; font-size: 0.9rem; }
.top-bar a:hover { color: #ecf0f1; }
.app { display: flex; height: calc(100vh - 2.8rem); }
.sidebar { width: 260px; min-width: 150px; background: #34495e; overflow-y: auto; padding: 0.5rem; }
.thumb-item { cursor: pointer; background: #fff; border-radius: 6px; margin-bottom: 0.5rem;
              border: 3px solid transparent; transition: border-color 0.15s; overflow: hidden; }
.thumb-item:hover { border-color: #3498db; }
.thumb-item.selected { border-color: #e74c3c; }
.thumb-label { padding: 0.3rem 0.5rem; font-size: 0.8rem; color: #2c3e50;
               font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.thumb-render { width: 100%; height: 150px; background: #fafafa; overflow: hidden; }
.thumb-render .loading { display: flex; align-items: center; justify-content: center;
                         height: 100%; color: #aaa; font-size: 0.8rem; }
.thumb-img { width: 100%; height: 100%; object-fit: contain; background: #fff; }
.main-panel { flex: 1; display: flex; align-items: center; justify-content: center;
              background: #fff; overflow: auto; }
.main-panel .empty { color: #aaa; font-size: 1.1rem; }
#main-plot { display: flex; align-items: center; justify-content: center; }
#context-menu { display: none; position: fixed; background: #fff; border: 1px solid #ccc;
                border-radius: 4px; box-shadow: 0 2px 8px rgba(0,0,0,0.15); z-index: 1000;
                min-width: 140px; }
#context-menu .menu-item { padding: 0.5rem 1rem; cursor: pointer; font-size: 0.9rem; }
#context-menu .menu-item:hover { background: #f0f0f0; }
#context-menu .menu-item.danger { color: #e74c3c; }
#context-menu .menu-item.danger:hover { background: #fdecea; }
.resize-handle { width: 5px; cursor: col-resize; background: #2c3e50;
                 transition: background 0.15s; flex-shrink: 0; }
.resize-handle:hover, .resize-handle.active { background: #3498db; }
.main-panel .vega-embed { position: relative; overflow: visible; }
.main-panel .vega-actions { z-index: 100; }"
  "CSS for the plots SPA page.")

(defun plots-index-page ()
  "Generate the plots SPA page with thumbnail sidebar and inline plot rendering.
Fetches plot specs via AJAX, renders thumbnails with Vega-Embed,
and loads full plots in the main panel on click (no page navigation)."
  (cl-who:with-html-output-to-string (s nil :prologue t :indent t)
    (:html
     (:head
      (:meta :charset "utf-8")
      (:title "Plots — Lisp-Stat Server")
       (:link :rel "icon" :type "image/svg+xml" :href *favicon-svg*)
      (:script :src "https://cdn.jsdelivr.net/npm/vega@6")
      (:script :src "https://cdn.jsdelivr.net/npm/vega-lite@6")
      (:script :src "https://cdn.jsdelivr.net/npm/vega-embed@7")
      (:style (cl-who:str *plots-spa-css*)))
     (:body
      (:div :class "top-bar"
       (:a :href "/" "← Home")
       (:h1 "Plots"))
      (:div :class "app"
       (:div :class "sidebar" :id "sidebar")
       (:div :class "resize-handle" :id "resize-handle")
       (:div :class "main-panel"
        (:div :id "main-plot"
         (:span :class "empty" "Select a plot"))))
      (:div :id "context-menu"
       (:div :class "menu-item danger" :id "delete-plot-btn" "Delete plot"))
      (:script
       (cl-who:str
        "var plotSpecs = {};
var selectedPlot = null;

function selectPlot(name) {
  var items = document.querySelectorAll('.thumb-item');
  items.forEach(function(el) { el.classList.remove('selected'); });
  var target = document.getElementById('thumb-' + name);
  if (target) target.classList.add('selected');
  selectedPlot = name;
  var mainEl = document.getElementById('main-plot');
  mainEl.innerHTML = '';
  if (plotSpecs[name]) {
    vegaEmbed(mainEl, plotSpecs[name], {
      actions: true,
      renderer: 'canvas',
      loader: { baseURL: window.location.origin, http: { headers: { 'Accept': 'application/vega-json' } } }
    });
  }
}

function renderThumbnail(name, spec) {
  var el = document.getElementById('render-' + name);
  if (!el) return;
  try {
    var vegaSpec = vegaLite.compile(spec).spec;
    var loader = vega.loader({
      baseURL: window.location.origin,
      http: { headers: { 'Accept': 'application/vega-json' } }
    });
    var view = new vega.View(vega.parse(vegaSpec), { loader: loader })
      .renderer('none').initialize();
    view.runAsync().then(function() {
      return view.toImageURL('png');
    }).then(function(url) {
      el.innerHTML = '<img src=\"' + url + '\" class=\"thumb-img\" />';
    }).catch(function() {
      el.innerHTML = '<div class=\"loading\">Error</div>';
    });
  } catch(e) {
    el.innerHTML = '<div class=\"loading\">Error</div>';
  }
}

fetch('/plot', { headers: { 'Accept': 'application/json' } })
  .then(function(r) { return r.json(); })
  .then(function(names) {
    var sidebar = document.getElementById('sidebar');
    if (names.length === 0) {
      sidebar.innerHTML = '<div style=\"color:#ecf0f1;padding:1rem\">No plots available.</div>';
      return;
    }
    names.forEach(function(name, i) {
      var item = document.createElement('div');
      item.className = 'thumb-item';
      item.id = 'thumb-' + name;
      item.onclick = function() { selectPlot(name); };
      item.oncontextmenu = function(e) { showContextMenu(e, name); };
      item.innerHTML = '<div class=\"thumb-label\">' + (i+1) + '. ' + name + '</div>' +
                       '<div class=\"thumb-render\" id=\"render-' + name + '\">' +
                       '<div class=\"loading\">Loading...</div></div>';
      sidebar.appendChild(item);
    });
    var loaded = 0;
    names.forEach(function(name) {
      fetch('/plot/' + encodeURIComponent(name), {
        headers: { 'Accept': 'application/vega-json' }
      })
        .then(function(r) { return r.json(); })
        .then(function(spec) {
          plotSpecs[name] = spec;
          renderThumbnail(name, spec);
          loaded++;
          if (loaded === 1) { selectPlot(name); }
        })
        .catch(function(err) {
          var el = document.getElementById('render-' + name);
          if (el) el.innerHTML = '<div class=\"loading\">Error</div>';
          console.error('Failed to load plot ' + name + ':', err);
        });
    });
  })
  .catch(function(err) {
    var sidebar = document.getElementById('sidebar');
    if (sidebar) sidebar.innerHTML = '<div style=\"color:#ecf0f1;padding:1rem\">Error loading plots.</div>';
    console.error('Failed to load plot list:', err);
  });

var contextTarget = null;
var ctxMenu = document.getElementById('context-menu');

document.addEventListener('click', function() {
  ctxMenu.style.display = 'none';
});

document.getElementById('delete-plot-btn').addEventListener('click', function(e) {
  e.stopPropagation();
  ctxMenu.style.display = 'none';
  if (!contextTarget) return;
  if (!confirm('Delete plot ' + contextTarget + '?')) return;
  fetch('/plot/' + encodeURIComponent(contextTarget), { method: 'DELETE' })
    .then(function(r) {
      if (r.ok) {
        var el = document.getElementById('thumb-' + contextTarget);
        if (el) el.remove();
        delete plotSpecs[contextTarget];
        if (selectedPlot === contextTarget) {
          document.getElementById('main-plot').innerHTML =
            '<span class=\"empty\">Select a plot</span>';
          selectedPlot = null;
        }
      }
    });
});

function showContextMenu(e, name) {
  e.preventDefault();
  e.stopPropagation();
  contextTarget = name;
  ctxMenu.style.left = e.clientX + 'px';
  ctxMenu.style.top = e.clientY + 'px';
  ctxMenu.style.display = 'block';
}

var resizeHandle = document.getElementById('resize-handle');
var sidebar = document.getElementById('sidebar');
var isResizing = false;

resizeHandle.addEventListener('mousedown', function(e) {
  isResizing = true;
  resizeHandle.classList.add('active');
  document.body.style.cursor = 'col-resize';
  document.body.style.userSelect = 'none';
  e.preventDefault();
});

document.addEventListener('mousemove', function(e) {
  if (!isResizing) return;
  var newWidth = e.clientX;
  var maxWidth = window.innerWidth * 0.5;
  if (newWidth < 150) newWidth = 150;
  if (newWidth > maxWidth) newWidth = maxWidth;
  sidebar.style.width = newWidth + 'px';
});

document.addEventListener('mouseup', function() {
  if (!isResizing) return;
  isResizing = false;
  resizeHandle.classList.remove('active');
  document.body.style.cursor = '';
  document.body.style.userSelect = '';
});"))))))

(defun tables-index-page ()
  "Generate the tables index page with a sidebar listing all data frames."
  (let ((data-frames (df:data-frame-symbols)))
    (cl-who:with-html-output-to-string (s nil :prologue t :indent t)
      (:html
       (:head
        (:meta :charset "utf-8")
        (:title "Tables — Lisp-Stat Server")
         (:link :rel "icon" :type "image/svg+xml" :href *favicon-svg*)
        (:style (cl-who:str *index-css*)))
       (:body
        (:div :class "container"
         (:nav :class "sidebar"
          (:h2 "Data Frames")
          (:a :href "/" :class "back-link" "← Home")
          (if data-frames
              (cl-who:htm
               (:ul
                (dolist (name data-frames)
                  (cl-who:htm
                   (:li (:a :href (format nil "/table/~A" name)
                            (cl-who:str name)))))))
              (cl-who:htm (:p "No data frames loaded."))))
         (:main :class "content"
          (:h1 "Data Frames")
          (if data-frames
              (cl-who:htm
               (:div :class "card-grid"
                (dolist (name data-frames)
                  (cl-who:htm
                   (:div :class "card"
                    (:h3 (cl-who:str name))
                    (:p
                     (:a :href (format nil "/table/~A" name) "View Table")
                     " | "
                     (:a :href (format nil "/data/~A" name)
                         "Download Data")))))))
              (cl-who:htm
               (:p "No data frames have been loaded yet."))))))))))


(defparameter *table-css*
  ".toolbar { padding: 0.5rem 0; display: flex; gap: 0.5rem; align-items: center; }
.toolbar button { padding: 0.4rem 1.2rem; border: 1px solid #ccc; border-radius: 4px;
                  cursor: pointer; font-size: 0.9rem; }
#save-btn { background: #2c3e50; color: #fff; }
#save-btn:hover { background: #34495e; }
#cancel-btn { background: #ecf0f1; }
#cancel-btn:hover { background: #dfe6e9; }
#status-msg { margin-left: 0.5rem; font-size: 0.85rem; color: #666; }
#status-msg.error { color: #e74c3c; }
#status-msg.success { color: #27ae60; }"
  "CSS for the table editor toolbar.")

(defun data-table-page (name &key documentation)
  "Generate HTML page with Handsontable for data frame NAME.
Uses Handsontable from CDN. Fetches data from /data/<name> as JSON.
Provides Save and Cancel buttons for batch editing.
When DOCUMENTATION is non-nil, displays it in a collapsible details element."
  (cl-who:with-html-output-to-string (s nil :prologue t :indent t)
    (:html
     (:head
      (:meta :charset "utf-8")
      (:title (cl-who:str (format nil "~A — Lisp-Stat" name)))
       (:link :rel "icon" :type "image/svg+xml" :href *favicon-svg*)
      (:link :rel "stylesheet"
             :href "https://cdn.jsdelivr.net/npm/handsontable/dist/handsontable.full.min.css")
      (:script :src "https://cdn.jsdelivr.net/npm/handsontable/dist/handsontable.full.min.js")
      (:style (cl-who:str *table-css*)))
     (:body
      (:h1 (cl-who:str name))
      (when documentation
        (cl-who:htm
         (:details :class "df-documentation"
          (:summary "Documentation")
          (:pre (cl-who:str documentation)))))
      (:div :class "toolbar"
       (:button :id "save-btn" :onclick "saveData()" "Save")
       (:button :id "cancel-btn" :onclick "cancelEdits()" "Cancel")
       (:span :id "status-msg"))
      (:div :id "data-table")
      (:script
       (cl-who:str
        (format nil "var originalRows, cols, hot;~%~
          fetch('/data/~A', { headers: { 'Accept': 'application/json' } })~%~
          .then(function(r) {~%~
            if (!r.ok) throw new Error('HTTP ' + r.status);~%~
            return r.json();~%~
          })~%~
          .then(function(data) {~%~
            cols = Object.keys(data[0]);~%~
            originalRows = data.map(function(row) {~%~
              return cols.map(function(c) { return row[c]; });~%~
            });~%~
            hot = new Handsontable(document.getElementById('data-table'), {~%~
              data: JSON.parse(JSON.stringify(originalRows)),~%~
              colHeaders: cols,~%~
              rowHeaders: true,~%~
              licenseKey: 'non-commercial-and-evaluation'~%~
            });~%~
          })~%~
          .catch(function(e) {~%~
            document.getElementById('data-table').innerHTML =~%~
              '<p style=\"color:#e74c3c;padding:1rem\">Error loading data: ' + e.message + '</p>';~%~
          });~%~
          function saveData() {~%~
            var rows = hot.getData();~%~
            var payload = rows.map(function(row) {~%~
              var obj = {};~%~
              cols.forEach(function(c, i) { obj[c] = row[i]; });~%~
              return obj;~%~
            });~%~
            fetch('/data/~A', {~%~
              method: 'PUT',~%~
              headers: { 'Content-Type': 'application/json' },~%~
              body: JSON.stringify(payload)~%~
            }).then(function(r) {~%~
              var msg = document.getElementById('status-msg');~%~
              if (r.ok) {~%~
                originalRows = JSON.parse(JSON.stringify(rows));~%~
                msg.textContent = 'Saved';~%~
                msg.className = 'success';~%~
              } else {~%~
                msg.textContent = 'Error saving';~%~
                msg.className = 'error';~%~
              }~%~
              setTimeout(function() { msg.textContent = ''; }, 3000);~%~
            });~%~
          }~%~
          function cancelEdits() {~%~
            hot.loadData(JSON.parse(JSON.stringify(originalRows)));~%~
            var msg = document.getElementById('status-msg');~%~
            msg.textContent = 'Reverted';~%~
            msg.className = '';~%~
            setTimeout(function() { msg.textContent = ''; }, 2000);~%~
          }" name name)))))))

(defun vega-embed-page (plot-name spec-json)
  "Generate a full HTML page with Vega-Embed for PLOT-NAME.
SPEC-JSON is the Vega-Lite spec as a JSON string.
Uses jsDelivr CDN for vega, vega-lite, and vega-embed.
Configures the Vega-Embed loader to send Accept: application/vega-json."
  (cl-who:with-html-output-to-string (s nil :prologue t :indent t)
    (:html
     (:head
      (:meta :charset "utf-8")
      (:title (cl-who:str (format nil "~A — Lisp-Stat" plot-name)))
       (:link :rel "icon" :type "image/svg+xml" :href *favicon-svg*)
      (:script :src "https://cdn.jsdelivr.net/npm/vega@5")
      (:script :src "https://cdn.jsdelivr.net/npm/vega-lite@5")
      (:script :src "https://cdn.jsdelivr.net/npm/vega-embed@6")
       (:style "body { background: #fff; }"))
     (:body
      (:div :id "vis")
      (:script
       (cl-who:str
        (format nil "var spec = ~A;~%vegaEmbed('#vis', spec, {~%  actions: true,~%  loader: {~%    baseURL: window.location.origin,~%    http: {~%      headers: {~%        'Accept': 'application/vega-json'~%      }~%    }~%  }~%});"
                spec-json)))))))
