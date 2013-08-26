do (require "source-map-support").install

request   = require "request"
jsdom     = require "jsdom"
async     = require "async"
fs        = require "fs"
iconv     = new (require "iconv").Iconv "windows-1250", "utf-8"
yaml      = require "js-yaml"
url       = require "url"

base_uri = "http://decyzje.uokik.gov.pl/nd_wz_um.nsf/WWW-wszystkie?OpenView"
delay    = 200

data_dir = __dirname + "/../terms"
if not fs.existsSync data_dir then fs.mkdirSync data_dir

save_term = (data) ->  
  path = data_dir + "/#{data._id}.yaml"
  fs.exists path, (exists) ->
    if not exists
      fs.writeFile path, yaml.safeDump data, (error) ->
        if error then throw error

scrape_list_page = (start) ->
  uri = base_uri + "&Start=" + start

  request 
    uri       : uri
    encoding  : null
    (error, response, body) ->
      console.log "\n\nScraping #{uri}"

      if error or (response.statusCode isnt 200)
        console.error "Failure :( #{uri}"

      jsdom.env
        html    : iconv.convert body
        scripts : [
          "https://raw.github.com/nbubna/HTML/0.9.4/dist/HTML.all.min.js"
        ]
        done    : (error, window) ->
          if error then throw error

          HTML  = window.HTML
          cells = HTML.body.form.table.only(0).find('td')
          if cells.length isnt 0
            cells.each (td) ->
              errors    = []
              
              _id    = parseInt td.b.only(0).textContent # number from the register
              console.log _id

              try
                original_uri = url.resolve uri, td.a.attributes.href.value
              catch e
                original_uri = ""
                errors.push e

              # Try to match term
              text = td
                .innerHTML
                .replace(/<br\s*\/?>/g, "\n")
                .replace(/<.*?>/g, "")
                .split("\n")
                .slice(3)                 # Drop first three lines
                .filter( (e) -> Boolean e.trim() ) # Drop empty
                .join("\n")
                .replace(/[ \t]+/, " ")
                .trim()
                .replace(/^["'«»‘’‚‛“”„‟‹›]/, '')        # remove opening parentheses
                .replace(/\(.*?\)$/, '')  # remove comment block
                .trim()
                .replace(/["'«»‘’‚‛“”„‟‹›]$/, '')        # remove closing parentheses
              
              console.log text

              data = { _id, original_uri, text }

              if errors.length then data.errors = errors # FIXME: empty object gets stored

              save_term data

            start += cells.length

            setTimeout (scrape_list_page.bind null, start), delay
          
          else # We have 'em all
            console.log "Done."

scrape_list_page 1