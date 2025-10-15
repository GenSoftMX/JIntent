#!/bin/bash
set -e

REPO="GenSoftMX/JIntent"

# --- Función: asegurar existencia de etiquetas ---
ensure_labels_exist() {
  local labels=("$@")

  for raw_label in "${labels[@]}"; do
    local label=$(echo "$raw_label" | xargs)
    [[ -z "$label" ]] && continue

    if ! gh label list --repo "$REPO" --limit 1000 | grep -qx "$label"; then
      echo "➕ Creando etiqueta: $label"
      gh label create "$label" --repo "$REPO" --description "Auto-generated label" >/dev/null 2>&1 || true
    fi
  done
}

# --- Función: verificar si ya existe un issue con el mismo título ---
issue_exists() {
  local title="$1"
  gh issue list --repo "$REPO" --limit 200 --json title --jq '.[] | select(.title=="'"$title"'")' | grep -q .
}

# --- Función: crear issue desde template ---
create_issue() {
  local template_file=$1
  local title=$(grep "^title:" "$template_file" | cut -d':' -f2- | xargs)
  local labels=$(grep "^labels:" "$template_file" | cut -d':' -f2- | tr -d "[]',")

  echo "🧩 Revisando issue: $title"

  # Saltar si ya existe
  if issue_exists "$title"; then
    echo "⚠️  Ya existe un issue con el título \"$title\", se omite."
    return
  fi

  # Procesar etiquetas
  read -ra label_array <<< "$labels"
  ensure_labels_exist "${label_array[@]}"

  echo "🚀 Creando issue: $title"

  # Crear issue
  gh issue create \
    --repo "$REPO" \
    --title "$title" \
    --body-file "$template_file" \
    $(printf -- "--label %s " "${label_array[@]}")
}

# --- Inicio del proceso ---
echo "📦 Creando issues en $REPO"

# Gate A1
if [[ -f ".github/ISSUE_TEMPLATE/gate-a1-review.md" ]]; then
  create_issue ".github/ISSUE_TEMPLATE/gate-a1-review.md"
fi

# Phase 1
for file in .github/ISSUE_TEMPLATE/phase1-*.md; do
  [[ -f "$file" ]] && create_issue "$file"
done

# Phase 2
for file in .github/ISSUE_TEMPLATE/phase2-*.md; do
  [[ -f "$file" ]] && create_issue "$file"
done

# Phase 3
for file in .github/ISSUE_TEMPLATE/phase3-*.md; do
  [[ -f "$file" ]] && create_issue "$file"
done

# Phase 4
for file in .github/ISSUE_TEMPLATE/phase4-*.md; do
  [[ -f "$file" ]] && create_issue "$file"
done

echo "✅ Todos los issues han sido verificados y creados (sin duplicados)."
