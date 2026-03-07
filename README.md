<!-- PROJECT SHIELDS -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MS-PL License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]



<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/lisp-stat/lisp-stat">
    <img src="https://lisp-stat.dev/images/stats-image.svg" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">LS-Server</h3>

  <p align="center">
    HTTP server for the Lisp-Stat system
    <br />
    <a href="https://lisp-stat.dev/docs/"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/lisp-stat/ls-server/issues">Report Bug</a>
    ·
    <a href="https://github.com/lisp-stat/ls-server/issues">Request Feature</a>
  </p>
</p>



<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
    <li>
      <a href="#about-the-project">About the Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li>
      <a href="#api-endpoints">API Endpoints</a>
      <ul>
        <li><a href="#data-endpoints">Data Endpoints</a></li>
        <li><a href="#table-endpoints">Table Endpoints</a></li>
        <li><a href="#plot-endpoints">Plot Endpoints</a></li>
        <li><a href="#navigation">Navigation</a></li>
      </ul>
    </li>
    <li><a href="#code-structure">Code Structure</a></li>
    <li><a href="#configuration">Configuration</a></li>
    <li><a href="#testing">Testing</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About the Project

LS-Server is an HTTP server for the [Lisp-Stat](https://lisp-stat.dev/) system, based on the [Hunchentoot](https://edicl.github.io/hunchentoot/) HTTP server.  It provides four capabilities:

1. **Plot viewing** — serve plots created with the `plot/vega` system as interactive Vega-Embed pages, with a single-page application (SPA) plot gallery featuring PNG thumbnails and a sidebar navigator
2. **Data frame viewing and editing** — view data frames in an editable [Handsontable](https://handsontable.com/) grid with batch Save/Cancel editing
3. **CSV / JSON data serving** — serve data-frame contents in CSV, JSON, Vega-JSON, or s-expression format via Accept header content negotiation
4. **Vega-Lite spec serving** — serve Vega-Lite plot specifications for existing plots
5. **REPL integration** — when the server is running, `print-object` displays clickable URLs for data frames and plots

Content negotiation is used throughout: clients request specific formats via the `Accept` header, and the server responds with the best matching format.


### Built With

* [Hunchentoot](https://edicl.github.io/hunchentoot/) — HTTP server
* [Yason](https://github.com/phmarek/yason) — JSON encoding/decoding
* [CL-WHO](https://edicl.github.io/cl-who/) — HTML generation
* [CL-PPCRE](https://edicl.github.io/cl-ppcre/) — Regular expressions
* [data-frame](https://github.com/Lisp-Stat/data-frame) — Data frame library
* [dfio](https://github.com/Lisp-Stat/dfio) — Data frame I/O (CSV, etc.)
* [plot/vega](https://github.com/Lisp-Stat/plot) — Vega-Lite plot specifications


<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

* [SBCL](https://www.sbcl.org/) (Steel Bank Common Lisp)
* [Quicklisp](https://www.quicklisp.org/beta/) for dependency management

### Installation

1. Clone the repository into a directory ASDF knows about:
```sh
cd ~/common-lisp && \
git clone https://github.com/Lisp-Stat/ls-server.git
```

2. Reset the ASDF source-registry (from the REPL):
```lisp
(asdf:clear-source-registry)
```

3. Load the system and its dependencies:
```lisp
(ql:quickload :ls-server)
```


<!-- USAGE -->
## Usage

Start the server on the default port (20202):

```lisp
(ls-server:start-server)
```

Start on a custom port:

```lisp
(ls-server:start-server :port 8080)
```

Stop the server:

```lisp
(ls-server:stop-server)
```

Once started, open `http://localhost:20202/` in a browser to see the landing page with links to plots and data frames.

### REPL integration

When the server is running, `print-object` automatically appends URLs to data frame and plot output:

```lisp
LS-USER> mtcars
#<DATA-FRAME (32 observations of 11 variables)
Motor Trend Car Road Tests
http://localhost:20202/table/MTCARS>

LS-USER> my-plot
#<VEGA-PLOT "my-plot"
http://localhost:20202/plot/my-plot>
```

### Loading example data

Load the Lisp-Stat example datasets to have data frames available:

```lisp
(ql:quickload :lisp-stat)
(ls-user:setup)
```

This loads standard datasets like `mtcars` and `iris` which are then accessible through the server's data and table endpoints.


<!-- API ENDPOINTS -->
## API Endpoints

### Data Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/data` | JSON array of available data frame names |
| `GET` | `/data/<name>` | Data frame contents (format via `Accept` header) |
| `PUT` | `/data/<name>` | Replace data frame with JSON array of row objects |
| `PATCH` | `/data/<name>` | Update specific cells: `{"updates": [{"row": N, "column": "col", "value": V}]}` |

**Supported Accept types for GET /data/\<name\>:**

| Accept Header | Format |
|---------------|--------|
| `text/csv` (default) | CSV with header row |
| `application/json` | JSON array of row objects |
| `application/vega-json` | Vega row-oriented JSON |
| `text/s-expression` | S-expression (Lisp-readable) |
| (none or `*/*`) | CSV (default) |

### Table Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/table/<name>` | Interactive Handsontable HTML page for the data frame |

The table page displays the data-frame documentation (if any) in a collapsible section and loads data via the `/data/<name>` JSON endpoint.  Edits are made in the grid and submitted as a batch via Save/Cancel buttons.

### Plot Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/plot` | JSON array of available plot names |
| `GET` | `/plot/<name>` | Plot page (HTML with Vega-Embed or raw Vega-JSON spec) |
| `DELETE` | `/plot/<name>` | Remove plot from the plot registry |

**Supported Accept types for GET /plot/\<name\>:**

| Accept Header | Format |
|---------------|--------|
| `text/html` (default) | Full HTML page with embedded Vega-Embed viewer |
| `application/vega-json` | Raw Vega-Lite JSON specification |

### Navigation

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Landing page with links to plots and tables |
| `GET` | `/plots` | SPA plot gallery with thumbnail sidebar |
| `GET` | `/tables` | Data frames index page with sidebar |
| `GET` | `/health` | Health check endpoint (returns `{"status":"ok"}`) |


<!-- CODE STRUCTURE -->
## Code Structure

```
ls-server/
├── ls-server.asd           # ASDF system definition
├── src/
│   ├── pkgdcl.lisp         # Package declaration (exports)
│   ├── config.lisp         # Configuration parameters (*default-port*, logging, etc.)
│   ├── negotiation.lisp    # Accept header parsing & content negotiation
│   ├── server.lisp         # Server start/stop, *server*
│   ├── health.lisp         # Health check endpoint
│   ├── data-routes.lisp    # /data endpoints (GET/PUT/PATCH), Yason extensions
│   ├── html.lisp           # HTML page generators (landing, table, plot, index pages)
│   ├── plot-routes.lisp    # /plot endpoints (GET/DELETE), plot lookup
│   ├── table-routes.lisp   # /table endpoint
│   ├── landing-routes.lisp # /, /plots, /tables route handlers
│   └── print-extensions.lisp # print-object :around methods for REPL URLs
└── tests/
    ├── test-package.lisp   # Test package declaration
    ├── main.lisp           # Test runner, root suite
    ├── health-tests.lisp   # Health endpoint tests, test server helpers
    ├── server-tests.lisp   # Server lifecycle tests
    ├── negotiation-tests.lisp # Content negotiation unit tests
    ├── data-tests.lisp     # Data endpoint integration tests
    ├── plot-tests.lisp     # Plot endpoint integration tests
    ├── table-tests.lisp    # Table endpoint integration tests
    ├── landing-tests.lisp  # Landing & index page tests
    └── print-tests.lisp    # print-object URL extension tests
```


<!-- CONFIGURATION -->
## Configuration

All configuration parameters are defined in `src/config.lisp` and can be set before starting the server:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `*default-port*` | `20202` | Default port for the HTTP server |
| `*server-host*` | `"localhost"` | Hostname used in printed URLs |
| `*access-log-destination*` | `nil` | Hunchentoot access log destination (pathname string or `nil` for stderr) |
| `*message-log-destination*` | `nil` | Hunchentoot message log destination (pathname string or `nil` for stderr) |

Example — redirect logs to files:

```lisp
(setf ls-server:*access-log-destination* "/tmp/ls-access.log")
(setf ls-server:*message-log-destination* "/tmp/ls-messages.log")
(ls-server:start-server)
```


<!-- TESTING -->
## Testing

Run all tests:

```sh
sbcl --non-interactive \
  --eval '(ql:quickload :ls-server :silent t)' \
  --eval '(ql:quickload :clunit2 :silent t)' \
  --eval '(asdf:test-system "ls-server")'
```

Run a specific test suite:

```sh
sbcl --non-interactive \
  --eval '(ql:quickload :ls-server :silent t)' \
  --eval '(ql:quickload :clunit2 :silent t)' \
  --eval '(asdf:load-system :ls-server/tests)' \
  --eval '(let ((clunit:*test-output-stream* *standard-output*))
           (clunit:run-suite (quote ls-server-tests::data-suite) :report-progress t))'
```

The test framework is [clunit2](https://github.com/tgutu/clunit2).  Integration tests start a test server on port 20293 and use [Dexador](https://github.com/fukamachi/dexador) for HTTP requests.


## Resources

This system is part of the [Lisp-Stat](https://lisp-stat.dev/) project; that should be your first stop for information.  Also see the [resources](https://lisp-stat.dev/docs/resources) and [community](https://lisp-stat.dev/community) page for more information.

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create.  Any contributions you make are **greatly appreciated**.  Please see [CONTRIBUTING](CONTRIBUTING.md) for details on the code of conduct, and the process for submitting pull requests.

<!-- LICENSE -->
## License

Distributed under the MS-PL License.  See [LICENSE](LICENSE) for more information.



<!-- CONTACT -->
## Contact

Project Link: [https://github.com/lisp-stat/ls-server](https://github.com/lisp-stat/ls-server)



<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/lisp-stat/ls-server.svg?style=for-the-badge
[contributors-url]: https://github.com/lisp-stat/ls-server/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/lisp-stat/ls-server.svg?style=for-the-badge
[forks-url]: https://github.com/lisp-stat/ls-server/network/members
[stars-shield]: https://img.shields.io/github/stars/lisp-stat/ls-server.svg?style=for-the-badge
[stars-url]: https://github.com/lisp-stat/ls-server/stargazers
[issues-shield]: https://img.shields.io/github/issues/lisp-stat/ls-server.svg?style=for-the-badge
[issues-url]: https://github.com/lisp-stat/ls-server/issues
[license-shield]: https://img.shields.io/github/license/lisp-stat/ls-server.svg?style=for-the-badge
[license-url]: https://github.com/lisp-stat/ls-server/blob/master/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/company/symbolics/
