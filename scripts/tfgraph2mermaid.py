#!/usr/bin/env python3
"""Turn `terraform graph` DOT output into a clean, colored diagram.

Reads Terraform's DOT graph on stdin and emits either a styled Mermaid
flowchart (default) or a styled Graphviz DOT — both showing only the cloud
resources and how they relate, grouped by module and colored by category,
with human-friendly labels and an embedded color legend.

Usage:
    terraform graph | tfgraph2mermaid.py [TITLE] [--format mermaid|dot]

Kept:    managed resources (aws_*, ...), grouped per module, their dependency
         edges, resource->module and module->module ("usa") wiring.
Dropped: variables, locals, outputs, providers and data sources.

Arrow convention: A --> B reads "A depends on B" (Terraform's own direction).
"""
import re
import sys

# Terraform's `terraform graph` DOT format changed between versions:
#   old (<=1.5):  "[root] aws_vpc.x (expand)" [label = "aws_vpc.x", shape = "box"]
#   new (>=1.6):  "aws_vpc.x" [label="aws_vpc.x"];
# Both are supported. clean() normalizes the address to the same canonical form.
NODE_OLD_RE = re.compile(r'^\s*"(\[root\][^"]*)"\s*\[label = "([^"]*)", shape = "(\w+)"\]')
NODE_NEW_RE = re.compile(r'^\s*"([^"\[][^"]*)"\s*\[label="([^"]*)"\]\s*;?\s*$')
EDGE_RE = re.compile(r'^\s*"([^"]+)"\s*->\s*"([^"]+)"')
BARE_MODULE_RE = re.compile(r"^module\.[^.]+$")

# category -> (mermaid fill, stroke, text) ; a colorblind-safe categorical set
STYLE = {
    "network":       ("#E3F2FD", "#1E88E5", "#0D47A1"),
    "compute":       ("#FFF3E0", "#FB8C00", "#E65100"),
    "data":          ("#E8F5E9", "#43A047", "#1B5E20"),
    "security":      ("#FCE4EC", "#E53935", "#B71C1C"),
    "observability": ("#F3E5F5", "#8E24AA", "#4A148C"),
    "other":         ("#ECEFF1", "#78909C", "#37474F"),
}
CAT_LABEL = {
    "network": "Rede", "compute": "Compute", "data": "Dados / Registro",
    "security": "Segurança / IAM", "observability": "Observabilidade", "other": "Outros",
}

# ordered: first match wins (security before compute so iam_* != compute)
CATEGORY_RULES = [
    ("network",       ["vpc", "subnet", "route", "internet_gateway", "nat_",
                        "_endpoint", "eip", "network_acl", "network_interface"]),
    ("security",      ["security_group", "iam_", "_iam", "kms", "acm",
                       "secretsmanager", "waf", "shield"]),
    ("observability", ["cloudwatch", "_logs", "log_group", "xray"]),
    ("data",          ["dynamodb", "s3_", "rds", "aurora", "elasticache",
                       "ecr", "efs", "sqs", "sns", "kinesis", "backup"]),
    ("compute",       ["ecs", "lambda", "instance", "autoscaling", "eks",
                       "fargate", "launch_template", "_lb", "alb", "elb", "batch"]),
]

# token -> nicely cased acronym for humanizing resource type names
ACRONYMS = {
    "vpc": "VPC", "ecs": "ECS", "ecr": "ECR", "iam": "IAM", "s3": "S3",
    "db": "DB", "rds": "RDS", "sqs": "SQS", "sns": "SNS", "kms": "KMS",
    "acm": "ACM", "waf": "WAF", "efs": "EFS", "eip": "EIP", "eks": "EKS",
    "ec2": "EC2", "elb": "ELB", "alb": "ALB", "ssm": "SSM", "acl": "ACL",
    "cidr": "CIDR", "dynamodb": "DynamoDB", "cloudwatch": "CloudWatch",
    "dns": "DNS", "tls": "TLS", "ssl": "SSL", "api": "API",
}
PROVIDER_PREFIXES = ("aws_", "google_", "azurerm_", "azuread_")


def clean(addr):
    addr = addr[len("[root] "):] if addr.startswith("[root] ") else addr
    return re.sub(r"\s*\((expand|close)\)$", "", addr)


def split_module(addr):
    m = re.match(r"^module\.([^.]+)\.(.+)$", addr)
    return (m.group(1), m.group(2)) if m else (None, addr)


def sanitize(addr):
    return "n_" + re.sub(r"[^0-9a-zA-Z]", "_", addr)


def is_managed_resource(addr):
    """Managed resource only — no var/local/output/provider/module-group/data source."""
    if addr.startswith(("var.", "local.", "provider[", "output.")):
        return False
    _, inner = split_module(addr)
    if inner.startswith(("var.", "local.", "output.", "data.")):
        return False
    if BARE_MODULE_RE.match(addr):
        return False
    return True


def categorize(inner):
    rtype = inner.split(".", 1)[0]
    for cat, keys in CATEGORY_RULES:
        if any(k in rtype for k in keys):
            return cat
    return "other"


def humanize(inner):
    """`aws_iam_role_policy.ecs_task_execution_policy` -> `IAM Role Policy - ecs_task_execution_policy`."""
    rtype, _, name = inner.partition(".")
    for p in PROVIDER_PREFIXES:
        if rtype.startswith(p):
            rtype = rtype[len(p):]
            break
    words = [ACRONYMS.get(tok, tok.capitalize()) for tok in rtype.split("_")]
    pretty = " ".join(words)
    return f"{pretty} - {name}" if name else pretty


def parse(dot):
    resources = {}   # addr -> (module, human_label, category)
    edges_raw = []
    for line in dot.splitlines():
        nm = NODE_OLD_RE.match(line) or NODE_NEW_RE.match(line)
        if nm:
            addr = clean(nm.group(1))
            if is_managed_resource(addr):
                mod, inner = split_module(addr)
                resources[addr] = (mod, humanize(inner), categorize(inner))
            continue
        em = EDGE_RE.match(line)
        if em:
            edges_raw.append((clean(em.group(1)), clean(em.group(2))))

    var_re = re.compile(r"^module\.([^.]+)\.var\.[^.]+$")
    # dep_edges: within one scope (solid); mod_edges: module->module ("usa");
    # input_edges: module->root resource ("usa"); rootuses: root resource->module.
    dep_edges, input_edges, mod_edges, rootuses = set(), set(), set(), set()
    for a, b in edges_raw:
        # Both endpoints are real resources (the new format wires these directly
        # across module boundaries; collapse cross-boundary edges to module level
        # so the picture matches the old format).
        if a in resources and b in resources:
            if a == b:
                continue
            sa, sb = resources[a][0], resources[b][0]
            if sa == sb:
                dep_edges.add((a, b))
            elif sa is not None and sb is not None:
                mod_edges.add((sa, sb))
            elif sa is not None:           # module resource -> root resource
                input_edges.add((sa, b))
            else:                          # root resource -> module resource
                rootuses.add((a, sb))
            continue
        # Old format only: cross-boundary wiring routed through var/module nodes.
        vm = var_re.match(a)
        if vm and b in resources and resources[b][0] is None:
            input_edges.add((vm.group(1), b))
        elif BARE_MODULE_RE.match(a) and BARE_MODULE_RE.match(b):
            an, bn = a.split(".", 1)[1], b.split(".", 1)[1]
            if an != bn:
                mod_edges.add((an, bn))

    root = sorted(a for a, r in resources.items() if r[0] is None)
    by_mod = {}
    for a, (mod, _, _) in resources.items():
        if mod is not None:
            by_mod.setdefault(mod, []).append(a)
    for m in by_mod:
        by_mod[m].sort()
    cats_present = [c for c in STYLE if any(r[2] == c for r in resources.values())]
    return (resources, root, by_mod, sorted(dep_edges), sorted(input_edges),
            sorted(mod_edges), sorted(rootuses), cats_present)


def emit_mermaid(title, resources, root, by_mod, dep_edges, input_edges, mod_edges, rootuses, cats):
    out = ["```mermaid", "flowchart LR"]
    for cat in STYLE:
        fill, stroke, text = STYLE[cat]
        out.append(f"  classDef {cat} fill:{fill},stroke:{stroke},color:{text};")

    def node(a):
        _, label, cat = resources[a]
        return f'    {sanitize(a)}["{label}"]:::{cat}'

    if root:
        out.append(f'  subgraph root["{title} · raiz"]')
        out += [node(a) for a in root]
        out.append("  end")
    for mod in sorted(by_mod):
        out.append(f'  subgraph mod_{sanitize(mod)}["Módulo - {mod}"]')
        out += [node(a) for a in by_mod[mod]]
        out.append("  end")

    for a, b in dep_edges:
        out.append(f"  {sanitize(a)} --> {sanitize(b)}")
    for a, b in mod_edges:                          # module -> module
        out.append(f"  mod_{sanitize(a)} ==>|usa| mod_{sanitize(b)}")
    for mod, res in input_edges:                    # module -> root resource
        out.append(f"  mod_{sanitize(mod)} -. usa .-> {sanitize(res)}")
    for res, mod in rootuses:                        # root resource -> module
        out.append(f"  {sanitize(res)} -. usa .-> mod_{sanitize(mod)}")

    # embedded color legend (only categories present)
    if cats:
        out.append('  subgraph legenda["Legenda"]')
        out.append("    direction LR")
        for c in cats:
            out.append(f'    leg_{c}["{CAT_LABEL[c]}"]:::{c}')
        out.append("  end")

    out.append('  style root fill:#FAFAFA,stroke:#E0E0E0;')
    for mod in sorted(by_mod):
        out.append(f'  style mod_{sanitize(mod)} fill:#FAFAFA,stroke:#CFD8DC;')
    out.append('  style legenda fill:#FFFFFF,stroke:#E0E0E0;')
    out.append("```")
    return "\n".join(out)


def emit_dot(title, resources, root, by_mod, dep_edges, input_edges, mod_edges, rootuses, cats):
    def sty(cat):
        fill, stroke, text = STYLE[cat]
        return f'fillcolor="{fill}", color="{stroke}", fontcolor="{text}"'

    out = [
        "digraph G {",
        "  compound=true; rankdir=LR; splines=true; nodesep=0.35; ranksep=0.7;",
        '  graph [fontname="Helvetica", bgcolor="transparent", style="rounded"];',
        '  node  [shape=box, style="rounded,filled", fontname="Helvetica", '
        'fontsize=10, penwidth=1.4, margin="0.12,0.06"];',
        '  edge  [color="#90A4AE", penwidth=1.1, arrowsize=0.7];',
    ]
    rep = {}

    def node_line(a):
        _, label, cat = resources[a]
        return f'    {sanitize(a)} [label="{label}", {sty(cat)}];'

    if root:
        out.append('  subgraph cluster_root {')
        out.append(f'    label="{title} · raiz"; style="rounded,filled"; '
                   'fillcolor="#FAFAFA"; color="#E0E0E0"; fontname="Helvetica-Bold";')
        out += [node_line(a) for a in root]
        out.append("  }")
    for mod in sorted(by_mod):
        out.append(f'  subgraph cluster_mod_{sanitize(mod)} {{')
        out.append(f'    label="Módulo - {mod}"; style="rounded,filled"; '
                   'fillcolor="#F5F5F5"; color="#CFD8DC"; fontname="Helvetica-Bold";')
        out += [node_line(a) for a in by_mod[mod]]
        out.append("  }")
        rep[mod] = sanitize(by_mod[mod][0])

    for a, b in dep_edges:
        out.append(f"  {sanitize(a)} -> {sanitize(b)};")
    for a, b in mod_edges:            # module -> module (prominent)
        out.append(f'  {rep[a]} -> {rep[b]} [ltail=cluster_mod_{sanitize(a)}, '
                   f'lhead=cluster_mod_{sanitize(b)}, label="usa", '
                   'color="#607D8B", fontcolor="#607D8B", penwidth=1.8, fontsize=9];')
    for mod, res in input_edges:      # module -> root resource
        out.append(f'  {rep[mod]} -> {sanitize(res)} [ltail=cluster_mod_{sanitize(mod)}, '
                   'style=dashed, color="#B0BEC5", label="usa", '
                   'fontcolor="#B0BEC5", fontsize=8];')
    for res, mod in rootuses:         # root resource -> module
        out.append(f'  {sanitize(res)} -> {rep[mod]} [lhead=cluster_mod_{sanitize(mod)}, '
                   'style=dashed, color="#B0BEC5", label="usa", '
                   'fontcolor="#B0BEC5", fontsize=8];')

    if cats:
        out.append('  subgraph cluster_legend {')
        out.append('    label="Legenda"; style="rounded,filled"; fillcolor="#FFFFFF"; '
                   'color="#E0E0E0"; fontname="Helvetica-Bold"; rank="sink";')
        for c in cats:
            out.append(f'    leg_{c} [label="{CAT_LABEL[c]}", {sty(c)}];')
        out.append("  }")

    out.append("}")
    return "\n".join(out)


def main():
    fmt = "mermaid"
    argv = sys.argv[1:]
    if "--format" in argv:
        i = argv.index("--format")
        fmt = argv[i + 1]
        del argv[i:i + 2]
    title = argv[0] if argv else "terraform"

    parsed = parse(sys.stdin.read())
    resources = parsed[0]
    if not resources:
        sys.stderr.write(
            "tfgraph2mermaid: no resources parsed from the graph — refusing to emit an "
            "empty diagram (unrecognized `terraform graph` format or empty config).\n")
        sys.exit(1)
    print(emit_dot(title, *parsed) if fmt == "dot" else emit_mermaid(title, *parsed))


if __name__ == "__main__":
    main()
