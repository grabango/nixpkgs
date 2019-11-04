ninjaBuildPhase() {
    runHook preBuild

    local buildCores=1

    # Parallel building is enabled by default.
    if [ "${enableParallelBuilding-1}" ]; then
        buildCores="$NIX_BUILD_CORES"
    fi

    local flagsArray=(
        -j$buildCores -l$NIX_BUILD_CORES
        ${ninjaFlags[@]+"${ninjaFlags[@]}"}
    )

    echoCmd 'build flags' "${flagsArray[@]}"
    ninja "${flagsArray[@]}"

    runHook postBuild
}

if [ -z "${dontUseNinjaBuild-}" -a -z "${buildPhase-}" ]; then
    buildPhase=ninjaBuildPhase
fi

ninjaInstallPhase() {
    runHook preInstall

    # shellcheck disable=SC2086
    local flagsArray=(
        ${ninjaFlags[@]+"${ninjaFlags[@]}"}
        "${installTargets[@]-install}"
    )

    echoCmd 'install flags' "${flagsArray[@]}"
    ninja "${flagsArray[@]}"

    runHook postInstall
}

if [ -z "${dontUseNinjaInstall-}" -a -z "${installPhase-}" ]; then
    installPhase=ninjaInstallPhase
fi

ninjaCheckPhase() {
    runHook preCheck

    if [ -z "${checkTarget:-}" ]; then
        if ninja -t query test >/dev/null 2>&1; then
            checkTarget=test
        fi
    fi

    if [ -z "${checkTarget:-}" ]; then
        echo "no test target found in ninja, doing nothing"
    else
        local buildCores=1

        if [ "${enableParallelChecking-1}" ]; then
            buildCores="$NIX_BUILD_CORES"
        fi

        local flagsArray=(
            -j$buildCores -l$NIX_BUILD_CORES
            ${ninjaFlags[@]+"${ninjaFlags[@]}"}
            $checkTarget
        )

        echoCmd 'check flags' "${flagsArray[@]}"
        ninja "${flagsArray[@]}"
    fi

    runHook postCheck
}

if [ -z "${dontUseNinjaCheck-}" -a -z "${checkPhase-}" ]; then
    checkPhase=ninjaCheckPhase
fi
