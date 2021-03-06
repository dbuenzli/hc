(*---------------------------------------------------------------------------
   Copyright (c) 2021 The hc programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open Webs
open Webs_html

module type T = sig
  val id : string
  val name : string
  val synopsis : string
  val prefix : string
  val serve : Http.req -> (Http.resp, Http.resp) result
end

let src_root = "https://erratique.ch/repos/hc/tree/examples/"

let link ~href:r text = El.a ~at:At.[href r] [El.txt text]

let inline_style s = El.style [El.unsafe_raw s]

let page ?style ~id ~title:t content =
  let root = String.equal t "Hc examples" in
  let title = if not root then Printf.sprintf "%s – Hc examples" t else t in
  let scripts = ["/hc-page.js"] in
  let more_head =
    let more_style = Option.fold ~none:El.void ~some:inline_style style in
    El.splice [ inline_style Style.base; more_style ]
  in
  let h1 =
    let links =
      if root then El.void else
      let src = src_root ^ (String.uncapitalize_ascii id ^ ".ml") in
      let src_link = link ~href:src "src" in
      El.splice [El.sp; El.small [src_link; El.sp; link ~href:"/" "up"]]
    in
    El.h1 [El.txt title; links]
  in
  let body = El.body [ h1; El.splice content] in
  let page = El.page ~title ~scripts ~more_head body in
  El.to_string ~doc_type:true page

let part content = El.to_string ~doc_type:false (El.splice content)

let table ?(headers = []) rows =
  let th txt = El.th [El.txt txt] in
  let td d = El.td [d] in
  let tr r = El.tr (List.map td r) in
  let headers = List.map th headers in
  let rows = List.map tr rows in
  let head = match headers with [] -> El.void | hs -> El.thead [El.tr hs] in
  El.table [ head; El.tbody rows]

let description contents = El.div ~at:At.[class' "description"] contents

let c_field = "field"
let c_button = "button"

let _button typ ?(at = []) label =
  El.button ~at:At.(class' c_button :: type' typ :: at)
    [ El.span ~at:At.[class' "spinner"; v "aria-hidden" "true"] [];
      El.span [El.txt label]; ]

let submit ?at label = _button "submit" ?at label
let button ?at label = _button "button" ?at label

let input_field ?(autocomplete = false) ?(at = []) ~type':t ~name:n fv =
  let size = max 20 (String.length fv + 4) in
  let at = (At.v "size" (string_of_int size)) :: at in
  let at = At.if' (not autocomplete) (At.autocomplete "off") :: at in
  El.input ~at:At.(class' c_field :: type' t :: name n :: value fv :: at) ()

let field ?(at = []) fv =
  El.span ~at:At.(class' c_field :: at) fv

type urlf = string
let urlf r = Http.Path.encode (Http.Req.service_path r) ^ "/"
let uf urlf fmt = Printf.sprintf ("%s" ^^ fmt) urlf

let req_decode req dec = try Ok (dec req) with
| Failure explain -> Http.Resp.bad_request_400 ~explain ()

let req_decode_query req dec = match Http.Req.to_query req with
| Error _ as e -> e
| Ok q ->
    try Ok (dec req q) with
    | Failure explain -> Http.Resp.bad_request_400 ~explain ()

let starts_with ~prefix s =
  let len_a = String.length prefix in
  let len_s = String.length s in
  if len_a > len_s then false else
  let max_idx_a = len_a - 1 in
  let rec loop i =
    if i > max_idx_a then true else
    if String.get prefix i <> String.get s i then false else loop (i + 1)
  in
  loop 0

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
