#!/usr/bin/env python3
"""
Découpe chaque SVG de patient (design/patients/patient_<nom>.svg) en calques
séparés (assets/patients/<nom>_<calque>.svg) pour pouvoir les animer dans
Flutter (respiration, clignement, bouche qui parle, etc.).

Tous les calques gardent le même viewBox 1024x1024 : empilés au même
endroit, ils se superposent exactement comme le SVG d'origine.

Calques produits pour chaque patient :
  hair_back   cheveux longs derrière le corps (seulement si le SVG en a un)
  body        corps + cou (respire)
  head        oreilles, visage, joues, rides, nez (pivote sur le cou)
  brows       sourcils (se lèvent)
  eyes        yeux (clignent, regardent)
  mouth       bouche fermée (repos)
  mouth_open  bouche ouverte, générée à partir du tracé des lèvres d'origine
  hair        cheveux (au-dessus de tout)

Le bloc <metadata> (content credentials c2pa, ~10 Ko par fichier) n'est pas
recopié : il n'a aucune utilité dans l'app.

Usage :  python3 tools/split_patient_svgs.py
         (relance-le à chaque fois que tu modifies un SVG dans design/patients/)
"""
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

SVG = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG)


def q(tag):
    return f"{{{SVG}}}{tag}"


ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "patients"
OUT = ROOT / "assets" / "patients"

LIP_COLOR = "#B4614C"
MOUTH_DARK = "#5B2027"
TONGUE = "#D9707A"


def svg_wrap(content_xml, defs_by_id, extra_defs=""):
    """Assemble un SVG 1024x1024 avec uniquement les <defs> réellement utilisés."""
    used = set(re.findall(r"url\(#([^)]+)\)", content_xml))
    kept = "".join(
        strip_ns(ET.tostring(defs_by_id[i], encoding="unicode"))
        for i in defs_by_id
        if i in used
    )
    kept += extra_defs
    defs_xml = f"<defs>{kept}</defs>" if kept else ""
    return (
        f'<svg xmlns="{SVG}" viewBox="0 0 1024 1024" width="1024" height="1024">'
        f"{defs_xml}{content_xml}</svg>\n"
    )


def strip_ns(xml):
    return xml.replace(f' xmlns="{SVG}"', "")


def build_open_mouth(mouth_g):
    """Bouche ouverte : mêmes coins et même courbe supérieure que les lèvres."""
    lip = None
    for p in mouth_g.iter(q("path")):
        if p.get("stroke", "").upper() == LIP_COLOR:
            lip = p.get("d")
            break
    if lip is None:
        raise ValueError("tracé des lèvres introuvable dans #mouth")
    n = [float(v) for v in re.findall(r"-?\d+\.?\d*", lip)]
    x1, y1, cx, cy, x2, y2 = n[:6]
    w = x2 - x1
    depth = w * 0.95  # profondeur d'ouverture maximale
    ctrl = depth * 1.3  # le cubique atteint environ 0.75 * ctrl
    top = f"M{x1:g},{y1:g} Q{cx:g},{cy:g} {x2:g},{y2:g}"
    shape = f"{top} C{x2 - 2:g},{y2 + ctrl:.1f} {x1 + 2:g},{y1 + ctrl:.1f} {x1:g},{y1:g} Z"
    tongue_cy = y1 + depth * 0.62
    defs_xml = f'<clipPath id="clipMouthOpen"><path d="{shape}"/></clipPath>'
    xml = (
        '<g id="mouth-open">'
        f'<path d="{shape}" fill="{MOUTH_DARK}"/>'
        f'<ellipse cx="{(x1 + x2) / 2:g}" cy="{tongue_cy:.1f}" rx="{w * 0.27:.1f}" '
        f'ry="{depth * 0.2:.1f}" fill="{TONGUE}" clip-path="url(#clipMouthOpen)"/>'
        f'<path d="{shape}" fill="none" stroke="{LIP_COLOR}" stroke-width="7" '
        'stroke-linejoin="round" stroke-linecap="round"/>'
        "</g>"
    )
    return xml, defs_xml, y1


def process(src: Path):
    name = src.stem.replace("patient_", "")
    root = ET.parse(src).getroot()

    defs = root.find(q("defs"))
    defs_by_id = {d.get("id"): d for d in defs} if defs is not None else {}

    body = next(g for g in root.iter(q("g")) if g.get("id") == "patient-body")
    head = next(g for g in root.iter(q("g")) if g.get("id") == "patient-head")

    # éléments de premier niveau autres que defs/body/head : ex. #hair-back
    hair_back = []
    for child in root:
        tag = child.tag.split("}")[1]
        if tag in ("metadata", "title", "defs"):
            continue
        if child.get("id") == "hair-back":
            hair_back.append(child)
        elif child.get("id") not in ("patient-body", "patient-head"):
            print(f"  ! élément ignoré dans {src.name}: <{tag} id={child.get('id')}>")

    groups = {"head": [], "brows": [], "eyes": [], "mouth": [], "hair": []}
    for child in head:
        cid = child.get("id")
        if cid == "eyebrows":
            groups["brows"].append(child)
        elif cid == "eyes":
            groups["eyes"].append(child)
        elif cid == "mouth":
            groups["mouth"].append(child)
        elif cid == "hair":
            groups["hair"].append(child)
        else:  # oreilles, visage, ombre, joues, rides, nez...
            groups["head"].append(child)

    layers = {"body": [body], **groups}
    if hair_back:
        layers = {"hair_back": hair_back, **layers}
    layer_xml = {}
    for lname, elems in layers.items():
        layer_xml[lname] = strip_ns(
            "".join(ET.tostring(e, encoding="unicode") for e in elems)
        )

    mouth_open_xml, mouth_open_defs, mouth_y = build_open_mouth(groups["mouth"][0])
    layer_xml["mouth_open"] = mouth_open_xml
    extra_defs = {"mouth_open": mouth_open_defs}

    for lname, content in layer_xml.items():
        (OUT / f"{name}_{lname}.svg").write_text(
            svg_wrap(content, defs_by_id, extra_defs.get(lname, "")), encoding="utf-8"
        )

    # centre vertical des yeux = pivot du clignement, à reporter dans PatientLook
    eye_ys = [float(e.get("cy")) for e in groups["eyes"][0].iter(q("ellipse"))]
    eye_y = sum(eye_ys) / len(eye_ys)
    print(
        f"{name:14s} mouthY={mouth_y:.0f}  eyeY={eye_y:.0f}  "
        f"hairBack={'oui' if hair_back else 'non'}  ({len(layer_xml)} calques)"
    )


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    files = sorted(SRC.glob("patient_*.svg"))
    if not files:
        sys.exit(f"Aucun SVG trouvé dans {SRC}")
    for f in files:
        process(f)


if __name__ == "__main__":
    main()
