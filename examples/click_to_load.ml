(*---------------------------------------------------------------------------
   Copyright (c) 2021 The hc programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open Webs
open Webs_html

let ( let* ) = Result.bind
let strf = Printf.sprintf
let paginate_list ?(per_page = 2) page_num (* one-based *) l =
  if per_page < 0 || page_num < 0 then None else
  let all = Array.of_list l in
  let len = Array.length all in
  let max = len - 1 in
  let first = (page_num - 1) * per_page in
  let last = min (page_num * per_page - 1) max in
  if first > max then None else
  let page = Array.to_list (Array.sub all first (last - first + 1)) in
  Some (page, last = max)

let id = __MODULE__
let name = "Click to load"
let synopsis = "Click to display more table rows."
let prefix = "click-to-load"
let description = Example.description [ El.txt
  "The last row table has a button. When the button is clicked
   the row is replaced by a sequence of rows requested from the server.
   The last row of that sequence has a button. When the button etc." ]

let style = {css|
tr td:nth-child(1) { width:15%; }
tr td:nth-child(2) { width:85%; }
tr.broken td:nth-child(1) { color: rgb(var(--redish)); }

tr.hc-in { opacity: 0; transform: translateY(calc(-1 * var(--size-half-line))) }
tr { transition: all var(--dur-short); }
|css}

let bookmark_row b =
  let status = if b.Bookmark.broken then "broken" else "alive" in
  El.tr ~at:At.[class' status]
    [ El.td [El.txt (String.capitalize_ascii status)];
      El.td [El.a ~at:At.[href b.Bookmark.link] [El.txt b.Bookmark.name]]]

let load_next urlf n =
  let r = Hc.request ~meth:`GET (Example.uf urlf "?page=%d" n) in
  let t = Hc.target "tr:up" and e = Hc.effect `Element in
  let more = Example.button ~at:[r; t; e] "More…" in
  El.tr [El.td ~at:At.[int "colspan" 3] [more]]

let bookmark_page_rows ?per_page urlf n =
  match paginate_list n (Bookmark.all ()) with
  | None -> []
  | Some (bs, last_page) ->
      let rows = List.rev_map bookmark_row bs in
      let rows = if last_page then rows else (load_next urlf (n + 1)) :: rows in
      List.rev rows

let table_headers =
  let cell txt = El.th [El.txt txt] in
  El.tr [cell "Status"; cell "Bookmark";]

let table_view ?updated rows =
  El.table [ El.thead [table_headers]; El.tbody rows]

let index urlf =
  let content = El.splice [table_view (bookmark_page_rows urlf 1)] in
  Example.page ~style ~id ~title:name [description; content]

let show_bookmark_table r =
  let urlf = Example.urlf r in
  let* `GET = Http.Req.allow Http.Meth.[get] r in
  let* q = Http.Req.to_query r in
  let* page = match Http.Query.find "page" q with
  | None -> Ok None
  | Some page ->
      try Ok (Some (int_of_string page)) with
      | Failure e -> Error (Http.Resp.v ~explain:e Http.bad_request_400)
  in
  match page with
  | None -> Ok (Http.Resp.html Http.ok_200 (index urlf))
  | Some page_num ->
      match bookmark_page_rows urlf page_num with
      | [] -> Http.Resp.not_found_404 ()
      | ps -> Ok (Http.Resp.html Http.ok_200 (Example.part ps))

let serve r = match Http.Req.path r with
| [""] -> show_bookmark_table r
| p -> Http.Resp.not_found_404 ()

(*---------------------------------------------------------------------------
   Copyright (c) 2021 The hc programmers

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
