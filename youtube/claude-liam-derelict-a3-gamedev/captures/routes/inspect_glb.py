"""Print node transforms, triangle count, Y-up bounds and base colours for each GLB given on the command line."""
import json, struct, sys

def to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

for path in sys.argv[1:]:
    with open(path, "rb") as f:
        data = f.read()
    magic, version, _ = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "not a GLB"
    jlen, _ = struct.unpack_from("<II", data, 12)
    gl = json.loads(data[20:20 + jlen])
    print(f"== {path.split(chr(92))[-1]} (glTF v{version})")
    for n in gl["nodes"]:
        print(f"  node {n.get('name')}: translation={n.get('translation', [0, 0, 0])} "
              f"rotation={n.get('rotation', [0, 0, 0, 1])} scale={n.get('scale', [1, 1, 1])}")
    tris, mins, maxs = 0, [1e9] * 3, [-1e9] * 3
    for mesh in gl["meshes"]:
        for prim in mesh["primitives"]:
            assert prim.get("mode", 4) == 4, "non-triangle primitive"
            tris += gl["accessors"][prim["indices"]]["count"] // 3
            acc = gl["accessors"][prim["attributes"]["POSITION"]]
            mins = [min(a, b) for a, b in zip(mins, acc["min"])]
            maxs = [max(a, b) for a, b in zip(maxs, acc["max"])]
    size = [round(b - a, 4) for a, b in zip(mins, maxs)]
    print(f"  triangles={tris}  size(x,y,z Y-up)={size}  min={[round(v, 4) for v in mins]}  max={[round(v, 4) for v in maxs]}")
    for m in gl.get("materials", []):
        pbr = m.get("pbrMetallicRoughness", {})
        lin = pbr.get("baseColorFactor", [1, 1, 1, 1])[:3]
        print(f"  material {m['name']}: linear={[round(c, 4) for c in lin]} "
              f"sRGB={[round(to_srgb(c), 3) for c in lin]} metallic={pbr.get('metallicFactor', 1)} "
              f"roughness={round(pbr.get('roughnessFactor', 1), 3)}")
