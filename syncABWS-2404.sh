#!/bin/bash

# --- Configuration ---
# Ensure startBB-2404.sh is in your PATH or provide the full path
AT_BIN="startBB-2404.sh"
PROJECT_ROOT=$(pwd)

# 1. Check if the Atelier B configuration file exists in the current directory
if [ ! -f "AtelierB" ]; then
    echo "Error: 'AtelierB' config file not found in $(pwd)."
    exit 1
fi

# 2. Helper function to run commands in bbach via stdin
run_bbach() {
    $AT_BIN <<EOF
$1
quit
EOF
}

echo "Starting Atelier B workspace synchronization..."

# 3. Get the list of currently registered projects (spl)
# We extract names and clean up the output
CURRENT_PROJECTS=$(run_bbach "spl" | grep "^  " | awk '{print $1}' | tr -d '\r')

# 4. Find actual project directories on disk
# Exclude system folders like bdb, Archives, and hidden folders like .git
ACTUAL_DIRS=$(find . -maxdepth 1 -type d ! -path . ! -name "bdb" ! -name "Archives" ! -name ".*" | sed 's|./||' | sort -u)

# --- PART A: PROJECT MANAGEMENT (Add and Remove) ---

for dir in $ACTUAL_DIRS; do
    PDB_DIR="$PROJECT_ROOT/$dir/bdp"
    LANG_DIR="$PROJECT_ROOT/$dir/lang"
    TEMP_LANG="$PROJECT_ROOT/$dir/lang-tmp"

    if echo "$CURRENT_PROJECTS" | grep -qw "$dir"; then
        echo ">> Project '$dir' is already registered."
    else
        echo ">> New project detected: '$dir'. Preparing registration..."
        
        # Shadowing: If lang directory exists (e.g. from Git clone), move it temporarily
        if [ -d "$LANG_DIR" ]; then
            echo "   [!] Moving existing lang to lang-tmp..."
            mv "$LANG_DIR" "$TEMP_LANG"
        fi
        
        # bbach requires directories to exist but expects them to be empty during creation
        echo "   [!] Creating empty bdp and lang directories..."
        mkdir -p "$PDB_DIR" "$LANG_DIR"

        # Register the project in the Atelier B database
        echo "   Registering project in Atelier B..."
        run_bbach "create_project $dir $PDB_DIR $LANG_DIR"

        # Restore original files (C implementations, etc.)
        if [ -d "$TEMP_LANG" ]; then
            echo "   [!] Restoring files from lang-tmp back to lang..."
            cp -rn "$TEMP_LANG"/* "$LANG_DIR/" 2>/dev/null
            rm -rf "$TEMP_LANG"
        fi
        echo "   Project '$dir' successfully integrated."
    fi
done

# Remove orphaned projects (registered in DB but missing from disk)
for proj in $CURRENT_PROJECTS; do
    if [ ! -d "$PROJECT_ROOT/$proj" ]; then
        echo ">> Project folder '$proj' not found. Removing from database (rp)..."
        run_bbach "rp $proj"
    fi
done

# --- REFRESH LIST ---
# Critical: Refresh the project list so PART B sees the newly created projects
echo "Refreshing project list for file synchronization..."
CURRENT_PROJECTS=$(run_bbach "spl" | grep "^  " | awk '{print $1}' | tr -d '\r')

# --- PART B: FILE SYNCHRONIZATION (sml/af/rc) ---

for proj in $ACTUAL_DIRS; do
    # Verify the project exists in the refreshed registered list
    if ! echo "$CURRENT_PROJECTS" | grep -qw "$proj"; then
        echo "Problem with the $proj!"
        continue
    fi
    
    echo "Syncing components for: $proj"
    
    REG_COMPONENTS=$(run_bbach "op $proj
sml" | grep -P "^( |\t)+" | awk '{print $1}' | tr -d '\r')

    SRC_DIR="$PROJECT_ROOT/$proj/src"
    if [ ! -d "$SRC_DIR" ]; then
        echo "   Warning: src directory not found. Skipping files."
        continue
    fi

    # Find B source files in the src directory
    DISK_FILES=$(find "$SRC_DIR" -maxdepth 1 -type f \( -name "*.mch" -o -name "*.ref" -o -name "*.imp" \) -exec basename {} \;)

    CMD_BATCH="op $proj"
    HAS_CHANGES=false

    # Add missing source files (af)
    for f in $DISK_FILES; do
        comp_name="${f%.*}"
        if ! echo "$REG_COMPONENTS" | grep -qw "$comp_name"; then
            echo "   [+] Adding new component: $f"
            CMD_BATCH="$CMD_BATCH
af $SRC_DIR/$f"
            HAS_CHANGES=true
        fi
    done

    # Remove components that are missing from disk (rc)
    for comp in $REG_COMPONENTS; do
        if [ -n "$comp" ] && [[ ! -f "$SRC_DIR/$comp.mch" && ! -f "$SRC_DIR/$comp.ref" && ! -f "$SRC_DIR/$comp.imp" ]]; then
            echo "   [-] Removing missing component: $comp"
            CMD_BATCH="$CMD_BATCH
rc $comp"
            HAS_CHANGES=true
        fi
    done

    # Execute batch command if changes were detected
    if [ "$HAS_CHANGES" = true ]; then
        run_bbach "$CMD_BATCH"
    else
        echo "   Components are up to date."
    fi
done

echo "-----------------------------------------------"
echo "Synchronization complete."
